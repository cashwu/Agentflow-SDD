## Context

Cash 已擁有兩個 variant、十二個 workflow skills、安裝器、bundle 版本與 `openspec/` workflow 指引，但所有 artifact engine 操作仍跨越到外部 Spectra CLI。現行 live surface 共使用 `analyze`、`archive`、`drift`、`in-progress`、`instructions`、`list`、`new`、`park`、`search`、`status`、`sync`、`task`、`unpark` 與 `validate`；另外 regression test 會執行 `spectra update --force`。其中 `sync` 已不被目前安裝的 Spectra binary 支援，顯示 Cash instruction 與外部 runtime 已可獨立漂移。

這個 repository 沒有既有 application runtime；跨專案部署則已由 `install-cash-skills.fish`、`cash-skills.version` 與 `.cash-skills/receipt.tsv` 管理。新 CLI 必須沿用這個單一部署邊界、保留 `openspec/` 現有檔案，不建立 daemon、registry watcher 或第二套 artifact schema。

## Goals / Non-Goals

**Goals:**

- 讓所有 live Cash workflow 在未安裝 Spectra CLI 時仍可建立、驗證、分析、實作、封存與查詢 changes。
- 提供 repository-owned、可測試且隨 Cash bundle 原子部署的 project-local CLI。
- 保留 skills 已依賴的 command semantics 與 JSON 欄位，讓 namespace 遷移保持機械且可驗證。
- 將每個 artifact mutation 收斂到單一 workspace adapter，明確處理 path boundary、collision、partial failure 與 diagnostics。
- 從 canonical skill inventory、project guidance、設定與 live tests 移除 Spectra runtime ownership。

**Non-Goals:**

- 不改寫 `openspec/changes/archive/` 的歷史 provenance 或 command transcripts。
- 不提供 Spectra 的 `init`、`update`、`show`、`schemas`、`templates`、`feedback`、`schema`、`config`、`completion` 或 `demo` 等未被 Cash workflows 使用的完整產品相容層。
- 不保留向量模型、embedding index 或 semantic search；`cash search` 是 deterministic lexical retrieval。
- 不在這個 change 改變 Cash review-loop 的評分、signals、ledger 或 grader governance。
- 不建立 global installation、background updater 或 `$PATH` mutation。

## Decisions

### Project-local Python standard-library runtime

canonical runtime 放在 `.cash-skills/bin/cash` 與 `.cash-skills/lib/cash_cli/`，並在既有project root直接安裝一個空的`0644` `.cash-workspace.lock`，使用 Python 3.11+ standard library，禁止 production dependency lockfile與第三方 package。launcher與workspace lock是stable bootstrap objects：fresh install建立後，所有後續版本 MUST逐byte驗證launcher、逐byte/mode/identity驗證lock，且不得以rename替換任一inode；source若改變stable launcher bytes或lock baseline，installer以unsupported bootstrap migration失敗。launcher只含固定bootstrap protocol：以自身位置找到project root lock，先由`argv`把`new`、`task`、`in-progress`、`touched`、`park`、`unpark`、`sync`與`archive`分類為mutating families並直接取得exclusive advisory lock，其他已知read families取得shared lock；完成lock後才載入receipt、驗證bootstrap/runtime generation records及import library，並持有同一lock FD到process結束。未知command只取得shared lock後回報錯誤；launcher MUST NOT先shared再upgrade。

每個 canonical skill 先以 `git rev-parse --show-toplevel` 取得並驗證 project root，再呼叫該 root 下 `.cash-skills/bin/cash` 的絕對路徑；因此 nested cwd 不會在 CLI 啟動前解析錯誤，source repository 與 installer targets 仍使用同一 runtime，且不寫入 global `$PATH`。

選擇 Python 是因為 artifact parser、JSON encoding、atomic filesystem mutation 與 fixture tests 都需要可靠的標準函式庫；以 Fish 實作會把 JSON/YAML/Markdown parsing 分散到 shell 與外部文字工具。選擇 project-local runtime 而非 global binary，是為了讓 CLI 版本和 24 個 skills 由同一 receipt 綁定並可原子 rollback。

### Cash CLI 只實作被 workflow 消費的 command surface

CLI 保留現行 skills 使用的 subcommand 與旗標形狀，但 executable 改為 `.cash-skills/bin/cash`。實作範圍固定為：`list`、`status`、`instructions`、`new change`、`new artifact`、`task done`、`in-progress add`、`touched ensure`、`park`、`unpark`、`validate`、`analyze`、`drift`、`archive`、`sync` 與 `search`。未列出的 Spectra product commands 必須以 unknown-command error 失敗，不建立 pass-through 或 fallback。

替代方案是保留完整 Spectra command vocabulary；否決原因是它會把 migration 擴張成重做未被 Cash 使用的產品。

### 單一 workspace adapter 擁有 artifact state

`cash_cli.workspace` 驗證 launcher 傳入的 Git project root同時包含 `.cash.yaml` 與 `openspec/config.yaml`，並在直接CLI使用時允許從目前目錄向上找到同一root；它提供固定`openspec/` artifact root下的active changes、parked changes、archive、master specs與signals canonical paths。所有read與mutation paths都由這個adapter以no-follow語意解析：拒絕symlink file/directory、hard-link ownership不明的mutation target、root外resolved path與unsafe change name。`.cash.yaml`不提供`spec_dir`；若legacy config啟用non-default `spec_dir`，migration fail closed並要求獨立資料遷移。

launcher以no-follow開啟bundle已安裝的project-root `.cash-workspace.lock` regular file；檔案缺失或identity/mode不符時以execution error零寫入失敗，command不得為了取得lock而建立或修復它。Launcher在import前取得的shared或exclusive lock由workspace adapter沿用；handler不得轉換lock mode。OS在process exit/crash時自動釋放ownership，因此persistent lock-file本身不代表owner存活且不得造成stale-lock blockade。mutator在exclusive lock內記錄完整source/destination bytes、mode與identity snapshots，使用本次invocation以`O_EXCL`建立的same-directory temporary entries staging，並在第一次publication前重新驗證全部snapshots。多檔transaction在`.cash-skills/state/transactions/<token>/journal.json`保留rollback copies與publication ledger；正常failure必須回滾，rollback failure或process crash保留journal。下一個mutator取得exclusive lock後必須先完成recovery；reader取得shared lock後若看見未完成journal則以`recovery_required` fail closed，不讀取可能的partial state。這是唯一 adapter；command handlers不重複path joining、locking或直接mutation。

### Cash-owned artifact graph 與 instructions resources

`cash_cli.resources` 以 version-controlled Python data structures 定義 `spec-driven` DAG、proposal/design/specs/tasks templates、apply/TDD/audit instructions 與 Traditional Chinese locale。`status` 與 `instructions` 從同一份 graph 產生資料，禁止兩套獨立 dependency tables。`instructions apply`另以同一graph與task parser回傳完整consumer schema：

- `changeName`與`schemaName`是non-empty string；`changeDir`是位於project root內的normalized absolute string。
- `contextFiles`是object，key為artifact ID、value為root-contained absolute path或glob string；缺少的optional artifact不以`null`佔位。
- `progress`固定為`{total, complete, remaining}`三個non-negative integer，且`complete + remaining == total`。
- `tasks`是依文件順序排列的array，每筆固定為`{id: string, description: string, done: boolean, parallel: boolean}`；沒有tasks時為empty array。
- `missingArtifacts`是依DAG順序排列的artifact ID string array；`state: blocked`時為non-empty，`ready`與`all_done`時為empty。
- `state`固定為`blocked`、`ready`或`all_done`；`locale`與`instruction`是string。`preflight`在三種state都必須存在，canonical apply consumers不再使用optional-presence分支。
- `preflight`固定為`{status, missingFiles, driftedFiles, staleness}`；`status`為`clean`、`warnings`或`critical`，`missingFiles`每筆為`{path: string, source: string}`，`driftedFiles`每筆為project-relative path string，`staleness`為`{daysOld: non-negative integer, isStale: boolean}`。沒有finding時兩個arrays皆為empty array，欄位不得省略或改成`null`。

`openspec/config.yaml` 保留 `schema: spec-driven` 與 per-artifact context/rules；`.cash.yaml`只擁有`locale`、`tdd`、`audit`與`parallel_tasks` runtime toggles。artifact-level instructions除既有欄位外，固定回傳always-present的`context: string`與`rules: string[]`；沒有設定時分別為empty string與empty array，rules依文件順序。

`cash_cli.config`是bundle-versioned parser，且只接受兩個明列的UTF-8/LF YAML subsets。`.cash.yaml`只允許blank line、full-line `#` comment及unindented `key: value`；`locale`值須符合`[A-Za-z][A-Za-z0-9_-]*`，`tdd/audit/parallel_tasks`值只接受lowercase `true`或`false`，四個keys皆不得重複。`openspec/config.yaml`只允許unindented `schema: spec-driven`、optional `context: |`後連續的two-space content lines，以及optional `rules:` mapping：artifact ID使用two-space key，rule使用four-space `- ` item並保持文件順序。兩種格式都允許blank/full-line comments，但拒絕tabs、inline comments、quotes、anchors、aliases、tags、flow collections、其他maps/lists/block scalars、unknown或duplicate keys與錯誤indentation，並指名path/field；它不宣稱為通用YAML implementation。

### Validation、analysis 與 drift 是可區分的 deterministic gates

`validate` 檢查 change name/path boundary、必要 artifact DAG、Markdown headings、spec delta operation、requirement/scenario structure、MODIFIED/REMOVED title identity、task checkbox/id 與 frontmatter/config shape。`analyze` 在已通過 parsing 的 artifacts 上輸出下列固定schema：

- `change_id`是string。
- `dimensions`依Coverage、Consistency、Ambiguity、Gaps順序輸出`{dimension: string, status: string, finding_count: non-negative integer}`。
- `findings`每筆為`{id: string, dimension: string, severity: "Critical"|"Warning"|"Suggestion", location: string, summary: string, recommendation: string}`。
- `artifacts_analyzed`與`artifacts_missing`是artifact ID string arrays；沒有finding或missing artifact時使用empty array，任何array不得以`null`代替。沒有足夠artifacts的dimension以`status: "Skipped (insufficient artifacts)"`表達，不得算作Clean。

`drift`以同一資料模型支援JSON與human-readable輸出。JSON固定包含：

- `change_id`與ISO `YYYY-MM-DD`格式的`created` string；`last_commit`是commit ID string或尚無commit時唯一允許的`null`。
- `dimensions`每筆固定為`{kind: string, status: string, score: non-negative integer, contributes_to_total: boolean}`。
- `broken_anchors`每筆固定為`{anchor: string, category: string, reason: string}`。
- `tasks_maybe_resolved`每筆固定為`{id: string, description: string, matching_commits: string[]}`；`tasks_blocked_external`每筆固定為`{id: string, description: string, paths: string[]}`。
- `commits_since_created`與`total_score`是non-negative integer，`severity`為`light`、`medium`或`heavy`，`primary_recommendation`是以Cash namespace開頭的non-empty command string。

上述arrays沒有項目時一律輸出empty array，不得省略或改成`null`。human-readable drift report MUST從同一object render，至少包含conclusion、dimensions、broken anchors、task collisions與primary recommendation，且不得產生JSON沒有的判定。計算只根據change metadata、tasks、declared impact paths與Git state，不以語意模型推測source intent。

三者不能互相遮蔽：parser或I/O error 是 execution error；deterministic contract violation 是 validation finding；尚無足夠資料是 skipped，不得回報 clean。

### Lexical search 取代向量搜尋

`search` 僅讀取固定`openspec/`目錄內以no-follow handle開啟、經`fstat`確認為regular file且resolved identity仍位於root內的文件；symlink file、symlink directory、parent identity swap或root外target必須拒絕且不得讀取excerpt。query正規化為Unicode case-folded tokens，對path、heading與body token matches加權排序，以normalized score、path、title與excerpt回傳最多`--limit`筆。相同score依project-relative path byte order排序。空query、無效limit與unreadable/unsafe file是error；合法但無結果回傳空`results`且exit 0。CLI不再產生`model_not_downloaded`、`index_not_built`或`vector_not_compiled`。

### Archive 與 sync 使用同一個 spec merge transaction

`sync <name>`先preflight全部delta specs及跨operation identity graph，再以固定phase套用：先對原identity執行MODIFIED與REMOVED、再加入ADDED、最後把仍存在的RENAMED source改為destination。相同source的MODIFIED+RENAMED是唯一合法的跨phase組合，結果為修改後內容使用新title；REMOVED+RENAMED、重複source operation、RENAMED destination與existing/ADDED title collision一律在publication前失敗。每個受影響requirement寫入`@trace`：`source`為change name、`updated`為當日、`code`取自proposal `## Impact`的affected-code paths、`tests`取自tasks明列的verification target paths；另寫`.cash-skills/state/sync/<name>.json`記錄delta/master input與result digests。相同delta與result digests的repeated sync是no-op；manifest或master mismatch必須fail closed。

`archive <name>`先執行workspace/config、identity、destination、journal與transaction safety preflight。預設再執行完整change validation；`--no-validate`只略過這個獨立domain gate，不得略過delta parse/title identity、sync preflight或任何filesystem safety check。`--mark-tasks-complete`在validation之後把remaining checkboxes staged進同一transaction，接著才執行sync與archive move；任何後續failure都回滾checkbox、master specs與change location。未帶`--skip-specs`時只在不存在有效sync manifest時執行一次sync，已同步時驗證後略過；帶`--skip-specs`時永不merge。Cash archive/commit skills不得再委派`spectra-sync-specs`，並在使用者拒絕sync時必須傳`--skip-specs`。archive成功後寫入archive內`archive-manifest.json`記錄change、delta、master與touched-state digests，再移動change並清理Cash-ownedstate。

### Cash-owned touched-state 追蹤 source allowlist

`in-progress add <name>`管理明確state machine。首次進入且沒有Cash snapshot時，它建立`.cash-skills/state/snapshots/<name>.json`，shape為`{version: 1, change: string, paths: [{path, worktree, index, mode, state}]}`；再次進入相同change是resume no-op，只驗證既有snapshot schema/identity而不得重設baseline，避免尚未`task done`的差異被吸收。change identity不符、unsupported version或partial state一律fail closed。

snapshot涵蓋Git porcelain-v2的staged-only、unstaged、added、deleted、renamed/copied雙端path、typechange、unmerged與untracked狀態；ignored paths排除。missing content使用明確`absent` fingerprint，所有paths正規化為project-relative no-follow identities。`task done`比較目前狀態與上次snapshot，把本task實際改變的paths記錄到`.cash-skills/state/touched/<name>.json`，完整shape為`{version: 1, change: string, legacy_import: null | {path: string, sha256: string, st_dev: non-negative integer, st_ino: positive integer}, touched: [{task_id: string, task_desc: string, files: string[]}], files: string[]}`；同task重跑union並stable-sort files，頂層`files`恰為所有task files的stable union，後續update保留`legacy_import`原值。成功記錄後才更新snapshot。pre-existing dirty但fingerprint未變的path不得納入。

第一次Cash touched access統一呼叫`touched ensure <name>`。Cash state缺失且存在`.spectra/touched/<name>.json`時，只接受現行`{change, touched:[{task_id, task_desc, files}]}`shape；以no-follow FD驗證change、task IDs、safe relative paths、duplicates、single-link regular identity與pathname/FD一致性後映射到Cash versioned schema，並把legacy project-relative safe path、lowercase SHA-256及decimal `st_dev/st_ino`寫入`legacy_import`。Cash與legacy皆缺失時建立`legacy_import: null`的合法empty state。Cash state一旦成功建立即為唯一權威：後續ensure、`task done`、commit allowlist與archive lifecycle決策只驗證或更新Cash state，legacy不得再作為allowlist、attribution或合併輸入。現有`.spectra/snapshots/`是歷史spec snapshots而非source tracking，Cash runtime MUST NOT匯入或讀取；它只作legacy history保留。

`cash-commit`在建立source allowlist前 MUST先呼叫ensure，`archive`則 MUST在自身transaction內執行相同ensure，因此upgrade後直接commit/archive不需要先跑`in-progress add`。archive成功後若`legacy_import`非null，唯一允許的legacy reread是destructive-cleanup identity check：在held parent-directory FD下no-follow開啟candidate，以`fstat`確認single-link regular file、`st_dev/st_ino`與記錄相同、digest相同，並在unlink前重驗pathname仍指向同一FD identity；全部成立才移除。missing是no-op，任何identity/path/digest drift（包括相同path與bytes但不同inode）都保留原檔、在archive manifest記錄`legacy_cleanup: preserved_drift`並輸出diagnostic，不影響已由Cash獨立治理的archive。Native Cash state旁後來出現的legacy檔沒有import provenance，永不由Cash移除。

### Installer transaction 同時治理 runtime、skills 與 legacy removal

`install-cash-skills.fish` 將stable launcher/lock、`.cash-skills/lib/cash_cli/` replaceable runtime generation、24個canonical Cash skills與receipt視為同一bundle inventory。`cash-skills.version`保持嚴格`MAJOR.MINOR.PATCH`：三個分量皆符合`0|[1-9][0-9]*`，不接受前導零、prerelease或build suffix；比較任意長度分量時先比digit length再比lexical bytes，不轉成fixed-width integer或float。任何replaceable runtime/skill bytes或contract mode改變都必須調升版本；相同版本仍綁定first-parent history中的引入commit。Stable bootstrap bytes不得隨一般bundle版本改變，其source drift是execution error而不是version bump。

preflight驗證Python 3.11+、source version與完整bootstrap/runtime/skill manifest、target boundaries、全部destination與`scripts/cash-skills/legacy-spectra-digests.tsv`列出的精確legacy body digest；同名但body drift、unknown version、symlink、hard link或額外內容一律conflict/fail closed。`runtime_generation`固定為replaceable runtime records依project-relative UTF-8 path bytes排序後，每筆以`<path>\t<lowercase-sha256>\t<four-digit-mode>\n`組成canonical UTF-8 stream的lowercase SHA-256。receipt先記錄bundle version與runtime generation，再依canonical inventory順序記錄stable launcher/lock及每個replaceable runtime/skill path的project-relative path、lowercase SHA-256與mode；stable records另記錄target-specific decimal `st_dev`與`st_ino`。launcher與installer持鎖後都以`fstat`比對stable identity、逐檔hash runtime records並重算generation，才可import或分類current。invalid version/generation、欄位數、digest、mode、device/inode、path、順序、duplicate、missing或unknown record一律在首次write前以execution error失敗，不得降級成missing/current/newer/conflict。

Fresh、legacy adoption與known-old migration都使用monotonic bootstrap。全部read-only preflight後，installer以`O_CREAT|O_EXCL`建立project-root lock、立即取得exclusive lock，並在持鎖後以`fstat`與pathname no-follow lookup重新確認相同device/inode；遇到`EEXIST`的並發installer必須no-follow開啟現存lock、等待取得exclusive lock、重驗pathname/FD identity後重新分類target。Stable lock一旦成功建立即永不unlink或rename；stable launcher一旦atomic發佈亦永不unlink或rename。正常failure只回滾replaceable runtime、skills、config、guidance與receipt，保留已發布的canonical stable prefix。下次installer可在相同lock inode上恢復`lock-only`或`lock+launcher`狀態；launcher-without-lock、bootstrap drift、未知partial state或pathname/FD identity mismatch一律fail closed。Existing current/upgrade/force/batch持有同一FD到transaction/rollback完成。新receipt在target publication完成後從target `fstat`產生bootstrap identity records，且最後才發佈。

Receipt-less legacy adoption明確承接舊24-skill target：當receipt與runtime缺失、stable prefix為absent、`lock-only`或`lock+launcher`，且24個canonical Cash `SKILL.md`全數為root-contained、non-symlink、single-link regular files，bytes及`0644` mode逐筆等於source時，installer保留skill bytes並由monotonic bootstrap transaction補齊launcher、runtime、config/guidance與新receipt。零個skills是fresh；介於1至23個、任何byte/mode/identity不同或unknown Cash runtime partial state在未帶`--force`時為conflict。Receipt-less完整新inventory仍可在stable lock下依全部bytes/modes相符條件認養。

已部署舊Cash bundle的known legacy receipt恰為25個LF-terminated records：第一筆`version<TAB><strict-MAJOR.MINOR.PATCH>`，其後依canonical 24-skill順序各一筆`sha256<TAB><lowercase-64-hex-digest><TAB><project-relative-path>`；它沒有mode、runtime、bootstrap或generation欄位。僅當receipt完整符合此schema、24個target skills逐筆符合且stable prefix absent或canonical recoverable時，installer才執行one-time bootstrap migration。failure回滾replaceable publications並還原old receipt，但 MUST保留已發布的stable lock/launcher；下一次direct或batch invocation在同一lock inode上恢復。old receipt drift、unknown/incomplete schema或bootstrap drift一律fail closed。dry-run使用同一判定但零寫入並回報would-update。

target preflight在首次write前要求target本身是Git worktree top-level，且既有`openspec/config.yaml`為安全、可讀、schema-valid的regular file；non-Git、Git子目錄target或missing/unsafe config在direct、register與batch modes皆fail closed。installer先以incoming parser驗證source config；target receipt/version/boundary必須在target config interpretation前判定，合法newer target零寫入返回且 MUST NOT由較舊incoming parser重新解讀target `.cash.yaml`。fresh、known-legacy、adoption、current與older target才以incoming bundle同版本`cash_cli.config` parser驗證target config。

既有`.cash.yaml`是project-owned且不得覆寫，但 MUST以該parser及no-follow snapshot驗證allowed keys、duplicates、types與syntax；invalid existing config在首次write前execution error。若只有`.spectra.yaml`，僅允許uncommented `locale/tdd/audit/parallel_tasks`及optional `spec_dir: openspec`；任何其他active top-level/nested scalar、map或list，以及non-default `spec_dir`都fail closed。兩者都不存在時，installer先以同一parser驗證source canonical `.cash.yaml`，再逐byte複製baseline。既有`.spectra.yaml`不是Cash-owned，installer不刪除，但完成後沒有runtime或skill讀取它。可辨識的標準`spectra-*`skill directories只在完整digest ownership成立且整體transaction可提交時移除。

Source repository 以獨立的 `--self [--dry-run]` 模式解決ignored target receipt bootstrap。此模式從installer所在目錄解析唯一Git top-level，要求它同時包含source canonical `cash-skills.version`、`.cash-workspace.lock`、launcher、完整replaceable runtime、24個skills、`.cash.yaml`與有效`openspec/config.yaml`；以no-follow handle驗證regular/single-link identity、contract mode、pathname/FD一致性及canonical inventory，取得既有stable lock的exclusive FD後才分類receipt。Real run只以same-directory owned temporary與held parent FD原子建立或替換`.cash-skills/receipt.tsv`，receipt bytes仍使用一般target相同的version、runtime generation、path/digest/mode與stable `st_dev/st_ino` schema；`--dry-run`只回報`would-bootstrap`或`current`且零寫入。`--self`不得與`--target`、`--all`、registry modes或`--force`組合，也不得發布或改寫launcher、lock、runtime、skills、config、guidance或legacy內容；一般target modes仍拒絕source repository。Launcher在已辨識source layout且receipt缺失時維持`bootstrap_invalid`，receipt存在但內容驗證失敗時維持`receipt_invalid`；兩者皆為exit 1且diagnostic MUST包含從project root可執行的`./install-cash-skills.fish --self`修復指令。

### Namespace 完成條件區分 live surface 與歷史資料

live residue scan的include roots固定為`.agents/skills/cash-*/`、`.claude/skills/cash-*/`、`scripts/cash-skills/variant-parity/`、`install-cash-skills.fish`、`scripts/cash-skills/tests/`、`.cash-skills/`、`scripts/cash-cli/`、`AGENTS.md`、`CLAUDE.md`、`CASH-SKILLS.md`、`.cash.yaml`與`openspec/specs/` master specs；這些surface不得包含可執行的`spectra`CLI literal、`Requires spectra CLI`或未治理的`.spectra/`runtime read。active change artifacts/reviews、`openspec/changes/archive/`與signal occurrence history是migration/provenance資料，不屬runtime scan；installer/touched importer與digest manifest中的legacy detector literals另以窄path+context allowlist管理，不得執行Spectra binary或讀取未列出的state。

## Implementation Contract

### Behavior

- 未安裝 Spectra binary且從 project root執行任一 canonical Cash workflow時，所有必要 artifact operations仍由 `.cash-skills/bin/cash` 完成。
- 乾淨source clone可先執行`./install-cash-skills.fish --self`建立被忽略的target receipt，之後同一個launcher與receipt驗證路徑 MUST支援所有canonical Cash workflows；缺失或失效receipt的source diagnostic MUST指出該修復指令。
- CLI 只讀與 mutation commands都先解析 workspace與config；不存在、ambiguous或unsafe workspace時零寫入失敗。
- active change位於 `openspec/changes/<name>/`；parked change位於 `openspec/changes/.parked/<name>/`；archive位於 `openspec/changes/archive/YYYY-MM-DD-<name>/`。三者 identity互斥，collision不自動覆寫。
- 所有 JSON mode成功輸出單一 JSON object到 stdout；diagnostic輸出到 stderr。JSON序列化固定 `ensure_ascii=false` 並使用穩定 key order，fixture可逐 byte比較。

### Command interfaces and data shapes

| Command family | Required interface | Success contract |
| --- | --- | --- |
| discovery | `.cash-skills/bin/cash list [--parked] --json` | active恰回傳`{changes: Change[]}`、parked恰回傳`{parked: Change[]}`；`Change`為`{name: string, status: string, summary: string, completedTasks: non-negative integer, totalTasks: non-negative integer}`，依name byte order排序，empty list為`[]`且沒有其他top-level key |
| DAG | `.cash-skills/bin/cash status --change <name> --json` | 恰回傳`changeName: string`、`schemaName: string`、`isComplete: boolean`、`applyRequires: string[]`與`artifacts: Artifact[]`；`Artifact`依DAG順序且恰為`{id: string, outputPath: string, status: "blocked"|"ready"|"done", missingDeps: string[]}`，empty arrays存在且不得為null |
| instructions | `.cash-skills/bin/cash instructions <artifact-id> --change <name> --json`、`instructions apply --change <name> --json`及`instructions --skill <tdd|audit>` | artifact恰回傳`changeName/artifactId/schemaName/changeDir/outputPath/description/instruction/locale/template/context` strings、`rules/dependencies/unlocks` arrays；`context`缺失時為`""`、`rules`缺失時為`[]`且依文件順序，每個dependency/unlock為`{id: string, done: boolean, path: string, description: string}`，stable order且empty為`[]`；apply依上文固定schema另含always-present `missingArtifacts`與`preflight`；skill mode回傳Cash-owned discipline text |
| creation | `.cash-skills/bin/cash new change <name> --agent <agent>`、`new artifact <id> [<capability>] --change <name> --stdin` | collision零寫入；artifact在schema允許且dependencies satisfied時才以stdin原文建立 |
| task state | `.cash-skills/bin/cash task done --change <name> <task-id> [--json]`、`in-progress add <name>`、`touched ensure <name>` | 只修改指定checkbox、snapshot、touched union或change metadata；ensure提供direct commit/archive的legacy lazy cutover；unknown/duplicate task id失敗，pre-existing unchanged dirty path不進allowlist |
| lifecycle | `.cash-skills/bin/cash park <name>`、`unpark <name>`、`sync <name>`、`archive <name> [--skip-specs] [--no-validate] [--mark-tasks-complete]` | identity與destination preflight後原子轉換；archive回報destination與spec merge摘要 |
| gates | `.cash-skills/bin/cash validate <name|--all>`、`analyze <name> --json`、`drift <name> [--json]` | validate以exit code區分pass/finding/error；analyze與drift逐欄符合上文固定element/null/empty schema，drift亦從同一object render human-readable report |
| retrieval | `.cash-skills/bin/cash search <query> --limit <n> --json` | 回傳 `{ "results": [{ "path", "title", "excerpt", "score" }] }`，結果只指向`openspec/` regular files |

### Error contract

- exit 0：command完成，包括合法empty list/search results與明確的insufficient-artifacts skipped analysis。
- exit 2：caller input、workspace/config/schema、validation finding、identity collision或domain precondition失敗。
- exit 1：unexpected I/O、encoding、Git invocation或internal execution error。
- `--json` failure在stdout輸出 `{ "error": { "code", "message", "path"? } }`；非JSON failure在stderr輸出單行 `error[<code>]: <message>`。execution error不得折疊成empty result或pass。
- source layout因receipt缺失產生的`bootstrap_invalid`及因receipt內容失效產生的`receipt_invalid`訊息都必須包含`./install-cash-skills.fish --self`；installed target不得被誤導使用source-only模式。
- mutation正常failure必須移除本次owned temporary entries並回滾已發布內容；rollback或crash recovery失敗必須保留transaction journal、回報exit 1且封鎖後續mutation，不得宣稱成功或靜默丟棄recoverable state。

### Acceptance criteria

- 在PATH中刻意排除Spectra binary的isolated fixtures內，十二個Codex與十二個Claude Cash workflows引用的每一個CLI command shape及consumer-read JSON field都有passing contract test，且每個family至少一次從nested cwd透過skill定義的root bootstrap啟動。
- lifecycle fixture完成new → artifacts → task done → validate → sync/archive，並逐byte驗證master-spec merge、archive destination與JSON snapshots。
- negative fixtures覆蓋unsafe root、read/mutation symlink、hard link、post-preflight edit、parent/destination swap、duplicate identity、malformedconfig、unknowncommand、invalidspec title、archive collision、第N個replace failure、archive move failure、rollback failure、crash後lock release、read-during-publication、temporary ownership與Git execution error，且逐項證明exit class、diagnostic、recovery journal與可觀測state。
- installer tests覆蓋stable bootstrap source/target identity、receipt-less 24-skill adoption、known-old receipt migration、lock-only/lock+launcher recovery、rollback後同inode、concurrent loser reclassification、running/new launcher與upgrade concurrency、runtime generation receipt、Git-top-level/config preflight、existing Cash config同parser invalid matrix、fresh default-config install、legacy-config migration、same-version current、full-inventory adoption、upgrade、newer、partial conflict、dry-run、force、strict SemVer、任意長度版本排序、版本bump/history binding、invalid receipt全部shape、exact-digest legacy standard skill removal、同名customization/mode/hard-link拒絕、Python prerequisite failure與transaction rollback，並直接執行target launcher驗證`0755`。
- source-bootstrap tests從無receipt的source fixture驗證launcher actionable failure、`--self --dry-run`零寫入、`--self`只建立mode-aware receipt、重複執行current零寫入、非法mode組合與unsafe source boundary fail closed，並在移除測試期間合成的receipt後於本repository依序執行`--self`及`.cash-skills/bin/cash validate --all`。
- namespace scan對所有non-archive live files失敗於任何Cash workflow可執行的`spectra`command、`Requires spectra CLI`、`.spectra.yaml`runtime read或canonical `spectra-*` skill；只允許明列的legacy migration detector與歷史路徑。
- `fish scripts/cash-skills/tests/skill-checks.fish` 與 `fish scripts/cash-cli/tests/cli-checks.fish` 都通過；Cash CLI自己的 `validate --all` 通過後才允許移除 `.spectra.yaml` 與 canonical Spectra skills。

### Scope boundaries

本 change包含 project-local CLI、兩個Cash skill variants、installer/bundle receipt、Cash設定、live guidance/docs/tests與canonical standard Spectra skill移除。它不修改歷史archive、signal occurrence prose、review-loop決策算法，也不提供完整Spectra產品命令相容性。

## Risks / Trade-offs

- [Risk] Python runtime成為新的 prerequisite → installer在任何target write前驗證Python 3.11+並輸出可恢復diagnostic；production code不引入第三方packages。
- [Risk] 自建spec merge可能靜默遺失MODIFIED/REMOVED內容 → title identity在validate與sync preflight重複驗證，fixture覆蓋每種delta operation與零匹配failure。
- [Risk] 跨24個skills的namespace migration留下literal residue → 以完整inventory scan、Claude/Codex parity manifests與每個command shape contract matrix封鎖遺漏。
- [Risk] installer同時替換runtime與skills造成partial deployment → runtime、skills、legacy removals與receipt共用單一preflight/staging/rollback transaction。
- [Risk] source `--self`可能把未經版本治理的runtime變更重新綁定 → 此模式只根據canonical inventory產生receipt，bundle history contract test仍獨立要求replaceable bytes/mode變更調升版本；stable launcher/lock source drift仍由stable bootstrap history檢查拒絕。
- [Risk] lexical search降低跨語言semantic recall → 明確接受deterministic/offline trade-off，保留path/heading/body加權與zero-result contract，不偽裝semantic parity。
- [Risk] archive與sync改變master specs屬高風險mutation → 全部delta先parse、全檔staging成功後才publish；任何failure回復原始snapshots並保留active change。
- [Risk] 本次scope較大 → 以command contract matrix與逐task fixture對應保持單一原子cutover，不交付混用Cash/Spectra的中間狀態。

## Migration Plan

1. 先新增Cash runtime、resources與isolated contract fixtures；此階段canonical skills仍使用Spectra。
2. 完成CLI parity與negative tests後，將24個Cash skills、`.cash.yaml`與live docs一次切換到project-local command。
3. 擴充installer與receipt inventory，在fixtures驗證runtime/skills/config migration、source `--self` bootstrap與legacy removal transaction。
4. 執行完整namespace scan與Cash `validate --all`，再移除source `.spectra.yaml`、canonical standard `spectra-*` skills與`update --force` regression。
5. 使用不含Spectra binary的clean target執行fresh install與完整new-to-archive smoke test。
6. Rollback時以版本控制恢復前一bundle；installer以較高的新patch版本重新發布，不對已安裝targets執行receipt未治理的手動檔案回退。

## Open Questions

無。Python prerequisite、project-local invocation、parked storage、search trade-off與歷史邊界都在本設計中定案。
