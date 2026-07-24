# cash-cli Specification

## Purpose

cash-cli capability.

## Requirements

### Requirement: Project-local Cash CLI runtime

系統 SHALL 在 `.cash-skills/bin/cash` 提供 repository-owned CLI launcher，在 `.cash-skills/lib/cash_cli/` 提供其實作，並在既有project root直接安裝空的`0644` `.cash-workspace.lock`。launcher與lock SHALL為stable bootstrap objects：fresh install後不得在一般upgrade以rename替換其inode，source bootstrap bytes drift MUST以unsupported migration失敗。launcher MUST在載入receipt或任何managed Python library前no-follow開啟lock，依`argv`將`new/task/in-progress/touched/park/unpark/sync/archive`直接分類為exclusive mutating families，其他已知families為shared reads；取得正確mode後才驗證receipt與import library，並持有同一FD到process結束。Launcher MUST NOT以shared→exclusive conversion啟動mutation；unknown command取得shared lock後失敗。launcher MUST 使用 Python 3.11+ standard library，MUST 以自身位置解析 library，且 MUST NOT 呼叫、載入或 fallback 到 Spectra binary。Canonical skills MUST先以`git rev-parse --show-toplevel`解析並驗證project root，再使用root下launcher的絕對路徑，因此nested cwd MUST在CLI啟動前獲得正確runtime。

#### Scenario: 未安裝 Spectra 仍可執行

- **GIVEN** project 已安裝 Cash bundle且PATH中不存在Spectra binary
- **WHEN** 呼叫 `.cash-skills/bin/cash list --json`
- **THEN** CLI從project-local runtime完成workspace discovery並回傳change清單
- **AND** process不嘗試執行任何Spectra command

#### Scenario: Python prerequisite 不符合

- **GIVEN** runtime解析到的Python版本低於3.11
- **WHEN** 呼叫任一Cash CLI command
- **THEN** command以execution error失敗並指出最低版本
- **AND** command不修改workspace

#### Scenario: Nested cwd 啟動 launcher

- **GIVEN** project root是`/repo`且目前目錄是`/repo/src/module`
- **WHEN** canonical skill執行Cash command
- **THEN** skill呼叫`/repo/.cash-skills/bin/cash`
- **AND** command完成workspace discovery

<!-- @trace
source: replace-spectra-cli-with-cash-cli
updated: 2026-07-24
code:
  - .agents/skills/
  - .agents/skills/spectra-analyze/
  - .agents/skills/spectra-apply/
  - .agents/skills/spectra-archive/
  - .agents/skills/spectra-ask/
  - .agents/skills/spectra-audit/
  - .agents/skills/spectra-commit/
  - .agents/skills/spectra-debug/
  - .agents/skills/spectra-discuss/
  - .agents/skills/spectra-drift/
  - .agents/skills/spectra-ingest/
  - .agents/skills/spectra-propose/
  - .agents/skills/spectra-verify/
  - .cash-skills/bin/cash
  - .cash-skills/lib/cash_cli/
  - .cash-skills/receipt.tsv
  - .cash-skills/state/
  - .cash-skills/state/snapshots/
  - .cash-skills/state/touched/
  - .claude/skills/
  - .claude/skills/spectra-analyze/
  - .claude/skills/spectra-apply/
  - .claude/skills/spectra-archive/
  - .claude/skills/spectra-ask/
  - .claude/skills/spectra-audit/
  - .claude/skills/spectra-commit/
  - .claude/skills/spectra-debug/
  - .claude/skills/spectra-discuss/
  - .claude/skills/spectra-drift/
  - .claude/skills/spectra-ingest/
  - .claude/skills/spectra-propose/
  - .claude/skills/spectra-verify/
  - .spectra/
  - scripts/cash-cli/fixtures/
  - scripts/cash-cli/tests/
  - scripts/cash-skills/legacy-spectra-digests.tsv
  - scripts/cash-skills/tests/skill-checks.fish
tests:
-->

### Requirement: Workspace 與設定邊界

Cash CLI SHALL驗證skill bootstrap傳入的Git root，並在direct invocation時從目前目錄向上尋找同時包含`.cash.yaml`與`openspec/config.yaml`的唯一project root。direct invocation向上解析到的root MUST等於launcher依自身位置解析並持有workspace lock的root；兩者不一致時 command MUST以execution error fail closed，MUST NOT以其中一個root的advisory lock保護另一個root的read或mutation。`cash_cli.workspace` MUST canonicalize root，所有read與mutation MUST以no-follow handle驗證regular file、parent identity及root containment，且 MUST拒絕unsafe change name、symlink file/directory、root外resolved path與ownership不明的mutation hard link。

所有commands MUST由launcher以no-follow開啟bundle-installed project-root workspace lock；lock缺失或identity/mode不符時 MUST零寫入execution error，command MUST NOT自行建立或修復。所有commands MUST以process-scoped advisory lock協作：read command從import前持有shared lock，mutating command從import前持有exclusive lock；handler MUST NOT轉換lock mode。process exit或crash MUST由OS釋放ownership，persistent lock-file不得被當成stale owner。mutator MUST透過單一adapter取得snapshot、transaction journal與recovery；reader在取得shared lock後若發現unfinished journal MUST以`recovery_required` fail closed，mutator則 MUST在開始新transaction前完成recovery。

bundle-versioned `cash_cli.config` parser MUST只接受UTF-8/LF。`.cash.yaml`只允許blank line、full-line `#` comment與unindented `key: value`；`locale`值 MUST符合`[A-Za-z][A-Za-z0-9_-]*`，`tdd/audit/parallel_tasks`值 MUST恰為lowercase `true`或`false`，且僅允許這四個不重複keys。`openspec/config.yaml`只允許`schema: spec-driven`、optional `context: |`及其two-space content lines、optional `rules:` mapping中的two-space artifact IDs與four-space `- ` rule items。兩者 MUST拒絕tabs、inline comments、其他maps/lists/block scalars、unknown/duplicate keys、錯誤型別或indentation。quotes、anchors、aliases、tags與flow collections MUST只在scalar或rule item **起始**位置被拒絕——該位置才會改變真正YAML parser的讀法；這些字元出現在文字中段 MUST被接受，因為plain scalar本就允許，拒絕它們會誤擋如`Mark independent tasks with [P]`的正常散文。legacy non-default`spec_dir` MUST fail closed。

#### Scenario: 從子目錄找到唯一 workspace

- **GIVEN** `/repo/.cash.yaml`與`/repo/openspec/config.yaml`存在
- **AND**目前目錄是`/repo/src/module`
- **WHEN** 呼叫Cash CLI
- **THEN** workspace root解析為`/repo`

#### Scenario: Launcher root 與 discovered root 不一致時 fail closed

- **GIVEN** 目前目錄位於project root `/repoB`，但caller執行的是`/repoA/.cash-skills/bin/cash`
- **WHEN** 該launcher持有`/repoA`的workspace lock後解析workspace
- **THEN** command以execution error失敗並指出root mismatch
- **AND** `/repoB`的workspace維持逐byte不變，且不被`/repoA`的lock保護

#### Scenario: Symlink boundary 被拒絕

- **GIVEN** 某個managed destination或其既有parent是指向project root外的symlink
- **WHEN** mutating command執行preflight
- **THEN** command以domain error失敗
- **AND** workspace維持逐byte不變

#### Scenario: Read command 不追隨 root 外 symlink

- **GIVEN** `openspec/specs/external.md`是指向project root外sentinel的symlink
- **WHEN** search或其他read command掃描artifacts
- **THEN** command拒絕該path且不讀取sentinel bytes
- **AND** output不包含root外excerpt

#### Scenario: Transaction recovery 封鎖新 mutation

- **GIVEN**先前transaction留下未完成journal且自動recovery再次失敗
- **WHEN** caller執行任一mutating command
- **THEN** command以exit 1失敗並指出journal path
- **AND** command不開始新的publication

#### Scenario: Crash lock 與 concurrent read

- **GIVEN**持有exclusive lock的process crash並留下unfinished journal
- **WHEN**下一個reader或mutator啟動
- **THEN**OS已釋放舊lock ownership，reader取得shared lock後回報`recovery_required`
- **AND**mutator取得exclusive lock後先執行recovery，不把lock file誤判為live owner

- **GIVEN**mutator正在多檔publication且持有exclusive lock
- **WHEN**reader嘗試讀取artifact
- **THEN**reader不得在transaction完成前取得shared lock
- **AND**reader不觀察partial state

##### Example: change name boundary

| Input | Expected |
| --- | --- |
| `add-login` | accepted |
| `../outside` | error: `unsafe_change_name` |
| `/absolute` | error: `unsafe_change_name` |
| `2026-07-23-demo` | error: `archive_style_active_name` |

<!-- @trace
source: replace-spectra-cli-with-cash-cli
updated: 2026-07-24
code:
  - .agents/skills/
  - .agents/skills/spectra-analyze/
  - .agents/skills/spectra-apply/
  - .agents/skills/spectra-archive/
  - .agents/skills/spectra-ask/
  - .agents/skills/spectra-audit/
  - .agents/skills/spectra-commit/
  - .agents/skills/spectra-debug/
  - .agents/skills/spectra-discuss/
  - .agents/skills/spectra-drift/
  - .agents/skills/spectra-ingest/
  - .agents/skills/spectra-propose/
  - .agents/skills/spectra-verify/
  - .cash-skills/bin/cash
  - .cash-skills/lib/cash_cli/
  - .cash-skills/receipt.tsv
  - .cash-skills/state/
  - .cash-skills/state/snapshots/
  - .cash-skills/state/touched/
  - .claude/skills/
  - .claude/skills/spectra-analyze/
  - .claude/skills/spectra-apply/
  - .claude/skills/spectra-archive/
  - .claude/skills/spectra-ask/
  - .claude/skills/spectra-audit/
  - .claude/skills/spectra-commit/
  - .claude/skills/spectra-debug/
  - .claude/skills/spectra-discuss/
  - .claude/skills/spectra-drift/
  - .claude/skills/spectra-ingest/
  - .claude/skills/spectra-propose/
  - .claude/skills/spectra-verify/
  - .spectra/
  - scripts/cash-cli/fixtures/
  - scripts/cash-cli/tests/
  - scripts/cash-skills/legacy-spectra-digests.tsv
  - scripts/cash-skills/tests/skill-checks.fish
tests:
-->

### Requirement: Cash workflow command surface

CLI SHALL 提供且僅需支援Cash workflows消費的`list`、`status`、`instructions`（含artifact-level、`instructions apply`與`instructions --skill <tdd|audit>`三種mode）、`new change`、`new artifact`、`task done`、`in-progress add`、`touched ensure`、`park`、`unpark`、`validate`（含single-change與`validate --all`）、`analyze`、`drift`、`archive`、`sync`與`search`command families。每個呼叫artifact engine的canonical Cash skill MUST 呼叫`.cash-skills/bin/cash`，MUST NOT包含可執行的`spectra`command或`Requires spectra CLI`相容性宣告。

#### Scenario: 支援的 command 被 dispatch

- **WHEN** caller提供上述任一已支援command與有效arguments
- **THEN** CLI dispatch到Cash-owned handler
- **AND** handler不經過外部CLI adapter

##### Example: discovery command dispatch

- **GIVEN** caller位於有效workspace
- **WHEN** caller執行`.cash-skills/bin/cash list --json`
- **THEN** discovery handler回傳單一`changes` JSON object

#### Scenario: 未治理 command 被拒絕

- **WHEN** caller執行`.cash-skills/bin/cash update`
- **THEN** CLI回傳`unknown_command`錯誤
- **AND** CLI不建立Spectra相容pass-through

<!-- @trace
source: replace-spectra-cli-with-cash-cli
updated: 2026-07-24
code:
  - .agents/skills/
  - .agents/skills/spectra-analyze/
  - .agents/skills/spectra-apply/
  - .agents/skills/spectra-archive/
  - .agents/skills/spectra-ask/
  - .agents/skills/spectra-audit/
  - .agents/skills/spectra-commit/
  - .agents/skills/spectra-debug/
  - .agents/skills/spectra-discuss/
  - .agents/skills/spectra-drift/
  - .agents/skills/spectra-ingest/
  - .agents/skills/spectra-propose/
  - .agents/skills/spectra-verify/
  - .cash-skills/bin/cash
  - .cash-skills/lib/cash_cli/
  - .cash-skills/receipt.tsv
  - .cash-skills/state/
  - .cash-skills/state/snapshots/
  - .cash-skills/state/touched/
  - .claude/skills/
  - .claude/skills/spectra-analyze/
  - .claude/skills/spectra-apply/
  - .claude/skills/spectra-archive/
  - .claude/skills/spectra-ask/
  - .claude/skills/spectra-audit/
  - .claude/skills/spectra-commit/
  - .claude/skills/spectra-debug/
  - .claude/skills/spectra-discuss/
  - .claude/skills/spectra-drift/
  - .claude/skills/spectra-ingest/
  - .claude/skills/spectra-propose/
  - .claude/skills/spectra-verify/
  - .spectra/
  - scripts/cash-cli/fixtures/
  - scripts/cash-cli/tests/
  - scripts/cash-skills/legacy-spectra-digests.tsv
  - scripts/cash-skills/tests/skill-checks.fish
tests:
-->

### Requirement: Artifact graph 與 instructions 使用單一來源

系統 SHALL以Cash-owned version-controlled resources定義`spec-driven` artifact DAG、proposal/design/specs/tasks templates、apply instruction、TDD discipline與audit discipline。`status`與`instructions` MUST從同一份graph取得dependency與output path，且`status --change <name> --json` MUST回傳`changeName`、`schemaName`、`isComplete`、`applyRequires`及`artifacts`。

`instructions apply --change <name> --json` MUST回傳下列完整shape：

- `changeName`與`schemaName` MUST為non-empty string；`changeDir` MUST為root-contained normalized absolute string。
- `contextFiles` MUST為artifact ID到root-contained absolute path或glob string的object；缺少的optional artifact MUST省略，不得以`null`佔位。
- `progress` MUST恰為`{total, complete, remaining}`三個non-negative integer，且`complete + remaining` MUST等於`total`。
- `tasks` MUST依文件順序包含`{id: string, description: string, done: boolean, parallel: boolean}`；沒有task時 MUST為empty array。
- `missingArtifacts` MUST為依DAG順序排列的artifact ID string array；`blocked`時 MUST為non-empty，`ready`與`all_done`時 MUST為empty array。
- `state` MUST為`blocked`、`ready`或`all_done`；`locale`與`instruction` MUST為string。
- `preflight` MUST在三種state皆存在且恰含`status`、`missingFiles`、`driftedFiles`與`staleness`；`status` MUST為`clean`、`warnings`或`critical`，`missingFiles`每筆 MUST為`{path: string, source: string}`，`driftedFiles`每筆 MUST為project-relative path string，`staleness` MUST為`{daysOld: non-negative integer, isStale: boolean}`。沒有finding時兩個array MUST存在且為empty array，不得省略或輸出`null`。

`list --json` MUST恰回傳`changes` array，`list --parked --json` MUST恰回傳`parked` array；每筆依name byte order且為`{name: string, status: string, summary: string, completedTasks: non-negative integer, totalTasks: non-negative integer}`。`status`的`artifacts` MUST依DAG順序且每筆恰為`{id: string, outputPath: string, status: "blocked"|"ready"|"done", missingDeps: string[]}`；`applyRequires`與所有empty arrays MUST存在且不得為`null`。artifact-level `instructions` MUST恰回傳`changeName/artifactId/schemaName/changeDir/outputPath/description/instruction/locale/template/context` strings及`rules/dependencies/unlocks` arrays；`context`缺失時 MUST為empty string，`rules`缺失時 MUST為empty array且有值時依文件順序，每個dependency或unlock MUST為`{id: string, done: boolean, path: string, description: string}`並保持stable order。

`instructions --skill <tdd|audit>` MUST從同一份Cash-owned resources回傳discipline text，且 MUST恰含`{skill: "tdd"|"audit", locale: string, instruction: string}`三個key，其中`instruction` MUST為non-empty string。此mode MUST NOT要求`--change`參數；`tdd`與`audit`以外的skill名 MUST以`unknown_command` error與exit 2失敗，MUST NOT回傳empty instruction。

#### Scenario: Proposal 解鎖 design 與 specs

- **GIVEN** change僅有有效`proposal.md`
- **WHEN** 執行`status --change demo --json`
- **THEN** `proposal`狀態為`done`
- **AND** `design`與`specs`狀態為`ready`
- **AND** `tasks`列出尚未滿足的dependency

#### Scenario: Instructions 與 status 不漂移

- **WHEN** 同一artifact的`instructions`回傳`outputPath`與`dependencies`
- **THEN** 其值與`status`使用的graph逐字一致

#### Scenario: Skill discipline instructions 不需 change

- **WHEN** 執行`instructions --skill tdd --json`且未提供`--change`
- **THEN** CLI回傳`{skill: "tdd", locale, instruction}`且`instruction`為non-empty
- **AND** 執行`instructions --skill unknown --json`時以`unknown_command`與exit 2失敗

#### Scenario: Apply instructions blocked 與 ready states

- **GIVEN**change缺少tasks artifact
- **WHEN**執行`instructions apply --change demo --json`
- **THEN**`state`為`blocked`且`contextFiles`與`missingArtifacts`指出缺口
- **AND**`preflight`仍存在，沒有project-file finding時使用clean與empty arrays

- **GIVEN**change具有pending tasks且preflight沒有critical finding
- **WHEN**執行相同command
- **THEN**`state`為`ready`且`progress`與`tasks`逐項對應checkbox

<!-- @trace
source: replace-spectra-cli-with-cash-cli
updated: 2026-07-24
code:
  - .agents/skills/
  - .agents/skills/spectra-analyze/
  - .agents/skills/spectra-apply/
  - .agents/skills/spectra-archive/
  - .agents/skills/spectra-ask/
  - .agents/skills/spectra-audit/
  - .agents/skills/spectra-commit/
  - .agents/skills/spectra-debug/
  - .agents/skills/spectra-discuss/
  - .agents/skills/spectra-drift/
  - .agents/skills/spectra-ingest/
  - .agents/skills/spectra-propose/
  - .agents/skills/spectra-verify/
  - .cash-skills/bin/cash
  - .cash-skills/lib/cash_cli/
  - .cash-skills/receipt.tsv
  - .cash-skills/state/
  - .cash-skills/state/snapshots/
  - .cash-skills/state/touched/
  - .claude/skills/
  - .claude/skills/spectra-analyze/
  - .claude/skills/spectra-apply/
  - .claude/skills/spectra-archive/
  - .claude/skills/spectra-ask/
  - .claude/skills/spectra-audit/
  - .claude/skills/spectra-commit/
  - .claude/skills/spectra-debug/
  - .claude/skills/spectra-discuss/
  - .claude/skills/spectra-drift/
  - .claude/skills/spectra-ingest/
  - .claude/skills/spectra-propose/
  - .claude/skills/spectra-verify/
  - .spectra/
  - scripts/cash-cli/fixtures/
  - scripts/cash-cli/tests/
  - scripts/cash-skills/legacy-spectra-digests.tsv
  - scripts/cash-skills/tests/skill-checks.fish
tests:
-->

### Requirement: Change 與 artifact lifecycle

`new change` SHALL只在active、parked與archive identity均無collision時建立active change。`new artifact` MUST驗證artifact ID、capability slug、dependency readiness與stdin encoding後才建立檔案。

首次`in-progress add` MUST建立`.cash-skills/state/snapshots/<name>.json`，shape為`{version: 1, change: string, paths: [{path: string, worktree: string, index: string, mode: string, state: string}]}`。既有相同change且schema有效的snapshot表示resume，MUST為no-op且 MUST NOT重設baseline；identity/version不符或partial state MUST fail closed。snapshot MUST涵蓋porcelain-v2 staged-only、unstaged、added、deleted、renamed/copied雙端path、typechange、unmerged及untracked狀態，排除ignored paths，並以`absent`表示missing content。

`task done` MUST只標記唯一task，比較目前state與上次snapshot後寫入`.cash-skills/state/touched/<name>.json`：`{version: 1, change: string, legacy_import: null | {path: string, sha256: string, st_dev: non-negative integer, st_ino: positive integer}, touched: [{task_id: string, task_desc: string, files: string[]}], files: string[]}`。同task重跑 MUST union並stable-sort files；頂層`files` MUST恰為per-task files的stable union，後續update MUST保留`legacy_import`原值。只有成功寫入task attribution後才更新snapshot，且 MUST排除fingerprint未變的pre-existing dirty paths。

第一次Cash touched access MUST統一透過`touched ensure <name>`。Cash state缺失而legacy `.spectra/touched/<name>.json`存在時，只接受現行`{change, touched:[{task_id, task_desc, files}]}`shape；command MUST以no-follow FD驗證single-link regular identity與pathname/FD一致性，change、task ID、path或duplicate不合法時 MUST fail closed，合法mapping MUST建立Cash state並把legacy project-relative safe path、lowercase SHA-256及decimal `st_dev/st_ino`記入`legacy_import`。兩者皆缺失時 MUST建立`legacy_import: null`的合法empty Cash state。Cash state一旦存在即為唯一權威；後續ensure、`task done`、commit與archive lifecycle決策 MUST NOT再把legacy內容作為allowlist、attribution或merge輸入。`.spectra/snapshots/`是歷史spec snapshots，Cash runtime MUST NOT匯入或讀取。

`cash-commit` MUST在建立source allowlist前呼叫ensure，archive MUST在其transaction內執行相同ensure，因此upgrade後直接commit或archive不依賴先前`in-progress add`。archive成功後若`legacy_import`非null，唯一允許的legacy reread SHALL只服務destructive-cleanup identity check：在held parent-directory FD下no-follow開啟candidate，以`fstat`確認single-link regular file、`st_dev/st_ino`與記錄相同、digest相同，並在unlink前重驗pathname仍指向同一FD identity；全部成立才可移除。missing是no-op，任何identity/path/digest drift（包含相同path與bytes但不同inode）MUST保留原檔、在archive manifest記錄`legacy_cleanup: preserved_drift`並輸出diagnostic。Native Cash state旁後來出現但未被import的legacy檔 MUST NOT由Cash移除。

#### Scenario: 建立與完成 artifact lifecycle

- **GIVEN** workspace不存在`demo` identity
- **WHEN** caller依序建立change、proposal、specs與tasks並完成task `1`
- **THEN** active change位於`openspec/changes/demo/`
- **AND**只有task `1` checkbox由`[ ]`轉為`[x]`
- **AND** `status`反映完成後artifact與task狀態

#### Scenario: Collision 零寫入

- **GIVEN** `openspec/changes/.parked/demo/`已存在
- **WHEN** caller執行`new change demo`
- **THEN** command以`change_identity_collision`失敗
- **AND**不建立active `demo`目錄

#### Scenario: 多 task touched paths 累積

- **GIVEN**開始apply時`unrelated.txt`已dirty且之後fingerprint不變
- **WHEN**task 1修改`src/a.py`且task 2修改`src/b.py`
- **THEN**Cash touched allowlist只包含`src/a.py`與`src/b.py`
- **AND**`unrelated.txt`不進入cash-commit source allowlist

#### Scenario: Upgrade 後直接 commit 或 archive

- **GIVEN**change只有合法legacy touched state且尚未執行Cash `in-progress add`
- **WHEN**cash-commit建立source allowlist或archive開始transaction
- **THEN**它先以`touched ensure`建立等價Cash state
- **AND**malformed legacy資料在首次import前fail closed

#### Scenario: Imported touched 後續演進維持單一權威

- **GIVEN**legacy touched已由ensure匯入並記錄digest provenance
- **WHEN**後續`task done`更新Cash touched，接著再次ensure、commit或archive
- **THEN**所有source allowlist只依演進後的Cash state
- **AND**它不重新比較或合併保留的legacy bytes
- **AND**archive只刪除device/inode/path/digest皆仍相符的import來源
- **AND**相同path與bytes但不同inode或其他drift一律保留並記錄diagnostic

<!-- @trace
source: replace-spectra-cli-with-cash-cli
updated: 2026-07-24
code:
  - .agents/skills/
  - .agents/skills/spectra-analyze/
  - .agents/skills/spectra-apply/
  - .agents/skills/spectra-archive/
  - .agents/skills/spectra-ask/
  - .agents/skills/spectra-audit/
  - .agents/skills/spectra-commit/
  - .agents/skills/spectra-debug/
  - .agents/skills/spectra-discuss/
  - .agents/skills/spectra-drift/
  - .agents/skills/spectra-ingest/
  - .agents/skills/spectra-propose/
  - .agents/skills/spectra-verify/
  - .cash-skills/bin/cash
  - .cash-skills/lib/cash_cli/
  - .cash-skills/receipt.tsv
  - .cash-skills/state/
  - .cash-skills/state/snapshots/
  - .cash-skills/state/touched/
  - .claude/skills/
  - .claude/skills/spectra-analyze/
  - .claude/skills/spectra-apply/
  - .claude/skills/spectra-archive/
  - .claude/skills/spectra-ask/
  - .claude/skills/spectra-audit/
  - .claude/skills/spectra-commit/
  - .claude/skills/spectra-debug/
  - .claude/skills/spectra-discuss/
  - .claude/skills/spectra-drift/
  - .claude/skills/spectra-ingest/
  - .claude/skills/spectra-propose/
  - .claude/skills/spectra-verify/
  - .spectra/
  - scripts/cash-cli/fixtures/
  - scripts/cash-cli/tests/
  - scripts/cash-skills/legacy-spectra-digests.tsv
  - scripts/cash-skills/tests/skill-checks.fish
tests:
-->

### Requirement: Atomic park、sync 與 archive

`park`與`unpark` SHALL在完整identity與destination preflight後移動整個change directory。`park`、`unpark`與`archive` MUST在移動前確保destination的parent directory存在（必要時以root-contained、non-symlink語意建立），因此尚無`openspec/changes/.parked/`或`openspec/changes/archive/`的workspace首次操作 MUST成功，MUST NOT以缺少目錄的execution error失敗。`sync` SHALL先解析全部delta specs與跨operation identity graph，再依固定phase套用：MODIFIED與REMOVED作用於原identity，ADDED其次，RENAMED最後。相同source的MODIFIED+RENAMED SHALL產生修改內容的新title；REMOVED+RENAMED、duplicate source operation、RENAMED destination與existing/ADDED title collision MUST在publication前失敗。同一份delta中兩個以上RENAMED entry指向相同destination title MUST同樣在publication前以`requirement_collision`失敗，MUST NOT讓後者靜默覆蓋前者而使master spec遺失requirement。`validate` MUST以`operation_collision` finding獨立攔截相同的duplicate destination、destination與ADDED title collision及destination已存在於master spec三種情形，使archive前的validation gate與merge phase形成雙重防線。sync SHALL注入`@trace`：`source`取change name、`updated`取當日、`code`取proposal affected-code paths、`tests`取tasks verification target paths；publication MUST使用exclusive lock、全snapshot revalidation、rollback journal與recovery。sync MUST寫入delta/result digests manifest，相同input/output的repeated sync MUST為no-op，mismatch MUST fail closed。

`archive` MUST總是先執行workspace/config、identity、destination、journal及filesystem safety preflight。預設 MUST再執行完整change validation；`--no-validate`只略過此domain gate，MUST NOT略過delta parse/title identity、sync或safety preflight。`--mark-tasks-complete` MUST在validation後stage所有remaining checkbox，再與sync、manifest及archive move一同commit或rollback。未帶`--skip-specs`時驗證既有sync manifest或執行一次sync，帶`--skip-specs`時 MUST NOT merge；Cash workflows MUST NOT委派`spectra-sync-specs`。成功後 MUST寫入archive identity manifest、移動到`openspec/changes/archive/YYYY-MM-DD-<name>/`並清理Cash state。正常failure MUST回滾checkbox、master specs與change location；rollback failure MUST保留journal並阻斷後續mutation。

#### Scenario: MODIFIED title 不吻合時 sync 失敗

- **GIVEN** delta spec的MODIFIED title不存在於對應master spec
- **WHEN** 執行`sync demo`
- **THEN** command以`requirement_identity_mismatch`失敗
- **AND**所有master specs維持逐byte不變

#### Scenario: 兩個 RENAMED 指向同一 destination 時失敗

- **GIVEN** master spec含`Alpha`與`Beta`兩條requirement
- **AND** 同一份delta將兩者都rename為`Gamma`
- **WHEN** 執行`validate demo`與`sync demo`
- **THEN** `validate`回傳`operation_collision` finding與exit 2
- **AND** `sync`以`requirement_collision`失敗且exit 2
- **AND** master spec維持逐byte不變且仍保有兩條requirement

#### Scenario: 缺少 lifecycle 目的地父目錄時自動建立

- **GIVEN** workspace尚未存在`openspec/changes/archive/`或`openspec/changes/.parked/`
- **WHEN** caller首次執行`archive <name>`或`park <name>`
- **THEN** command建立所需父目錄並完成transaction
- **AND** command MUST NOT以缺少目錄的execution error失敗

#### Scenario: Archive transaction 成功

- **GIVEN** change已通過validation且archive destination不存在
- **WHEN** 執行`archive demo`
- **THEN**全部spec operations成功發布
- **AND**change移至當日date prefix的archive directory
- **AND**active identity不再存在

#### Scenario: Archive destination collision

- **GIVEN**目標archive directory已存在
- **WHEN**執行`archive demo`
- **THEN**command在任何spec publication前失敗
- **AND**active change與master specs均維持不變

#### Scenario: Sync 後 archive 不重複 merge

- **GIVEN**`sync demo`已成功且master digests仍符合sync manifest
- **WHEN**執行`archive demo`
- **THEN**archive驗證manifest後不再次套用delta operations
- **AND**master specs維持與sync後逐byte相同

#### Scenario: Explicit no-sync archive

- **GIVEN**使用者拒絕spec sync
- **WHEN**Cash workflow執行`archive demo --skip-specs`
- **THEN**archive不修改任何master spec
- **AND**change仍被移至archive destination

#### Scenario: Archive flags 共用 transaction

- **GIVEN**change有incomplete tasks且caller同時使用`--mark-tasks-complete --no-validate`
- **WHEN**archive通過不可略過的safety、delta parse及identity preflight
- **THEN**command略過獨立change validation後stage所有task checkboxes
- **AND**checkbox、spec merge、manifest與move在任一步失敗時一起rollback

<!-- @trace
source: replace-spectra-cli-with-cash-cli
updated: 2026-07-24
code:
  - .agents/skills/
  - .agents/skills/spectra-analyze/
  - .agents/skills/spectra-apply/
  - .agents/skills/spectra-archive/
  - .agents/skills/spectra-ask/
  - .agents/skills/spectra-audit/
  - .agents/skills/spectra-commit/
  - .agents/skills/spectra-debug/
  - .agents/skills/spectra-discuss/
  - .agents/skills/spectra-drift/
  - .agents/skills/spectra-ingest/
  - .agents/skills/spectra-propose/
  - .agents/skills/spectra-verify/
  - .cash-skills/bin/cash
  - .cash-skills/lib/cash_cli/
  - .cash-skills/receipt.tsv
  - .cash-skills/state/
  - .cash-skills/state/snapshots/
  - .cash-skills/state/touched/
  - .claude/skills/
  - .claude/skills/spectra-analyze/
  - .claude/skills/spectra-apply/
  - .claude/skills/spectra-archive/
  - .claude/skills/spectra-ask/
  - .claude/skills/spectra-audit/
  - .claude/skills/spectra-commit/
  - .claude/skills/spectra-debug/
  - .claude/skills/spectra-discuss/
  - .claude/skills/spectra-drift/
  - .claude/skills/spectra-ingest/
  - .claude/skills/spectra-propose/
  - .claude/skills/spectra-verify/
  - .spectra/
  - scripts/cash-cli/fixtures/
  - scripts/cash-cli/tests/
  - scripts/cash-skills/legacy-spectra-digests.tsv
  - scripts/cash-skills/tests/skill-checks.fish
tests:
-->

### Requirement: Deterministic validation、analysis 與 drift

`validate <name>` SHALL檢查workspace/config、artifact DAG、必要headings、delta operations、requirement/scenario structure、title identity、task IDs與checkboxes。`validate --all` MUST對每個active change套用相同檢查、依name byte order彙總結果，並在任一change有validation finding時回傳exit 2、任一change遇到execution error時回傳exit 1，全部通過時回傳exit 0。

`analyze` SHALL輸出：

- `change_id: string`。
- 依Coverage、Consistency、Ambiguity、Gaps順序排列的`dimensions`，每筆 MUST為`{dimension: string, status: string, finding_count: non-negative integer}`。
- `findings`，每筆 MUST為`{id: string, dimension: string, severity: "Critical"|"Warning"|"Suggestion", location: string, summary: string, recommendation: string}`。
- `artifacts_analyzed`與`artifacts_missing` artifact ID string arrays。

資料不足的dimension MUST以`status: "Skipped (insufficient artifacts)"`表示，不得標為Clean。沒有findings或missing artifacts時，對應array MUST存在且為empty array，不得省略或輸出`null`。

`drift` SHALL支援human與JSON output。JSON MUST包含`change_id: string`、`created: YYYY-MM-DD string`、`last_commit: string|null`、`commits_since_created: non-negative integer`、`total_score: non-negative integer`、`severity: "light"|"medium"|"heavy"`與Cash namespace的non-empty`primary_recommendation`。`dimensions`每筆 MUST為`{kind: string, status: string, score: non-negative integer, contributes_to_total: boolean}`；`broken_anchors`每筆 MUST為`{anchor: string, category: string, reason: string}`；`tasks_maybe_resolved`每筆 MUST為`{id: string, description: string, matching_commits: string[]}`；`tasks_blocked_external`每筆 MUST為`{id: string, description: string, paths: string[]}`。只有`last_commit`可在沒有commit時為`null`；所有arrays在沒有項目時 MUST為empty array。human output MUST從相同object render conclusion、dimensions、broken anchors、task collisions與primary recommendation，不得加入JSON不存在的判定。所有結果 SHALL只依change metadata、tasks、declared impact paths與Git state計算。

#### Scenario: Validation finding 與 execution error 可區分

- **GIVEN**一個可讀但缺少`#### Scenario:`的delta spec
- **WHEN**執行`validate demo`
- **THEN**command回傳validation finding與exit 2

- **GIVEN**Git executable無法啟動
- **WHEN**執行`drift demo --json`
- **THEN**command回傳execution error與exit 1
- **AND**不回傳`severity: none`

#### Scenario: Analysis 資料不足

- **GIVEN**change只有`proposal.md`
- **WHEN**執行`analyze demo --json`
- **THEN**需要其他artifacts的dimensions明確標為`Skipped (insufficient artifacts)`
- **AND**command不把缺少資料解讀為clean

<!-- @trace
source: replace-spectra-cli-with-cash-cli
updated: 2026-07-24
code:
  - .agents/skills/
  - .agents/skills/spectra-analyze/
  - .agents/skills/spectra-apply/
  - .agents/skills/spectra-archive/
  - .agents/skills/spectra-ask/
  - .agents/skills/spectra-audit/
  - .agents/skills/spectra-commit/
  - .agents/skills/spectra-debug/
  - .agents/skills/spectra-discuss/
  - .agents/skills/spectra-drift/
  - .agents/skills/spectra-ingest/
  - .agents/skills/spectra-propose/
  - .agents/skills/spectra-verify/
  - .cash-skills/bin/cash
  - .cash-skills/lib/cash_cli/
  - .cash-skills/receipt.tsv
  - .cash-skills/state/
  - .cash-skills/state/snapshots/
  - .cash-skills/state/touched/
  - .claude/skills/
  - .claude/skills/spectra-analyze/
  - .claude/skills/spectra-apply/
  - .claude/skills/spectra-archive/
  - .claude/skills/spectra-ask/
  - .claude/skills/spectra-audit/
  - .claude/skills/spectra-commit/
  - .claude/skills/spectra-debug/
  - .claude/skills/spectra-discuss/
  - .claude/skills/spectra-drift/
  - .claude/skills/spectra-ingest/
  - .claude/skills/spectra-propose/
  - .claude/skills/spectra-verify/
  - .spectra/
  - scripts/cash-cli/fixtures/
  - scripts/cash-cli/tests/
  - scripts/cash-skills/legacy-spectra-digests.tsv
  - scripts/cash-skills/tests/skill-checks.fish
tests:
-->

### Requirement: Deterministic lexical search

`search` SHALL只讀取固定`openspec/`範圍內以no-follow handle開啟、經`fstat`確認且identity位於root內的regular files，以Unicode case-folded query tokens比對path、heading與body，並回傳`path`、`title`、`excerpt`與normalized `score`。symlink file/directory、parent identity swap與root外target MUST在讀取body前拒絕。相同score MUST依project-relative path byte order排序。空query、invalid limit與unreadable/unsafe file MUST失敗；合法zero-result MUST回傳空`results`且exit 0。CLI MUST NOT要求vector model或index。

#### Scenario: Lexical ranking 穩定

- **GIVEN**三個文件分別在heading、body與path命中相同query token
- **WHEN**執行`search "archive safety" --limit 3 --json`
- **THEN**結果依定義的path/heading/body權重排序
- **AND**相同score依path byte order排序

#### Scenario: 無結果不是執行錯誤

- **WHEN**合法query沒有命中任何文件
- **THEN**CLI回傳`{ "results": [] }`
- **AND**process exit code為0

<!-- @trace
source: replace-spectra-cli-with-cash-cli
updated: 2026-07-24
code:
  - .agents/skills/
  - .agents/skills/spectra-analyze/
  - .agents/skills/spectra-apply/
  - .agents/skills/spectra-archive/
  - .agents/skills/spectra-ask/
  - .agents/skills/spectra-audit/
  - .agents/skills/spectra-commit/
  - .agents/skills/spectra-debug/
  - .agents/skills/spectra-discuss/
  - .agents/skills/spectra-drift/
  - .agents/skills/spectra-ingest/
  - .agents/skills/spectra-propose/
  - .agents/skills/spectra-verify/
  - .cash-skills/bin/cash
  - .cash-skills/lib/cash_cli/
  - .cash-skills/receipt.tsv
  - .cash-skills/state/
  - .cash-skills/state/snapshots/
  - .cash-skills/state/touched/
  - .claude/skills/
  - .claude/skills/spectra-analyze/
  - .claude/skills/spectra-apply/
  - .claude/skills/spectra-archive/
  - .claude/skills/spectra-ask/
  - .claude/skills/spectra-audit/
  - .claude/skills/spectra-commit/
  - .claude/skills/spectra-debug/
  - .claude/skills/spectra-discuss/
  - .claude/skills/spectra-drift/
  - .claude/skills/spectra-ingest/
  - .claude/skills/spectra-propose/
  - .claude/skills/spectra-verify/
  - .spectra/
  - scripts/cash-cli/fixtures/
  - scripts/cash-cli/tests/
  - scripts/cash-skills/legacy-spectra-digests.tsv
  - scripts/cash-skills/tests/skill-checks.fish
tests:
-->

### Requirement: 統一 JSON 與錯誤契約

所有`--json`成功路徑 SHALL在stdout輸出單一JSON object，使用UTF-8、`ensure_ascii=false`與stable key order。exit 0 MUST表示command完成；exit 2 MUST表示caller input、workspace/config/schema、validation finding、identity collision或domain precondition失敗；exit 1 MUST表示unexpected I/O、encoding、Git invocation或internal execution error。JSON failure MUST回傳含`code`與`message`的`error`object；execution error MUST NOT被折疊成empty result或pass。

#### Scenario: JSON domain error

- **WHEN** caller以`--json`建立已存在的change
- **THEN** stdout只包含一個`error`object
- **AND** `error.code`為`change_identity_collision`
- **AND** exit code為2

#### Scenario: Publication failure 清理 temporary state

- **GIVEN** atomic publication在replace階段發生I/O error
- **WHEN** mutating command結束
- **THEN** exit code為1
- **AND**原始managed files維持逐byte不變
- **AND**command-owned temporary files全部清除

<!-- @trace
source: replace-spectra-cli-with-cash-cli
updated: 2026-07-24
code:
  - .agents/skills/
  - .agents/skills/spectra-analyze/
  - .agents/skills/spectra-apply/
  - .agents/skills/spectra-archive/
  - .agents/skills/spectra-ask/
  - .agents/skills/spectra-audit/
  - .agents/skills/spectra-commit/
  - .agents/skills/spectra-debug/
  - .agents/skills/spectra-discuss/
  - .agents/skills/spectra-drift/
  - .agents/skills/spectra-ingest/
  - .agents/skills/spectra-propose/
  - .agents/skills/spectra-verify/
  - .cash-skills/bin/cash
  - .cash-skills/lib/cash_cli/
  - .cash-skills/receipt.tsv
  - .cash-skills/state/
  - .cash-skills/state/snapshots/
  - .cash-skills/state/touched/
  - .claude/skills/
  - .claude/skills/spectra-analyze/
  - .claude/skills/spectra-apply/
  - .claude/skills/spectra-archive/
  - .claude/skills/spectra-ask/
  - .claude/skills/spectra-audit/
  - .claude/skills/spectra-commit/
  - .claude/skills/spectra-debug/
  - .claude/skills/spectra-discuss/
  - .claude/skills/spectra-drift/
  - .claude/skills/spectra-ingest/
  - .claude/skills/spectra-propose/
  - .claude/skills/spectra-verify/
  - .spectra/
  - scripts/cash-cli/fixtures/
  - scripts/cash-cli/tests/
  - scripts/cash-skills/legacy-spectra-digests.tsv
  - scripts/cash-skills/tests/skill-checks.fish
tests:
-->

### Requirement: Cash 合約測試套件

系統 SHALL以兩個套件治理Cash contract。`scripts/cash-cli/tests/cli-checks.fish` MUST治理Cash CLI的command dispatch、workspace/config boundary、artifact與touched-state lifecycle、validation/analysis/drift、lexical search、sync/archive transaction、error/atomicity與所有consumer JSON shapes。`scripts/cash-skills/tests/skill-checks.fish` MUST治理bundle version、直接／registry／batch installer分支、guidance migration、24-skill variant parity與live namespace residue。兩套件 MUST在PATH刻意排除Spectra binary時通過，且 MUST NOT執行任何`spectra`command或`spectra update`。

#### Scenario: 兩套件在無 Spectra binary 時通過

- **GIVEN** PATH中不存在Spectra binary
- **WHEN** 執行`scripts/cash-cli/tests/cli-checks.fish`與`scripts/cash-skills/tests/skill-checks.fish`
- **THEN** 兩套件皆通過
- **AND** 沒有任何測試呼叫`spectra`command

#### Scenario: CLI 與 skill 治理範圍不重疊

- **WHEN** 檢視兩套件涵蓋的surface
- **THEN** CLI lifecycle/atomicity/JSON contract由`cli-checks.fish`治理
- **AND** bundle、installer、guidance、parity與namespace residue由`skill-checks.fish`治理

#### Scenario: Source repository 無 receipt bootstrap

- **GIVEN** source repository沒有被忽略的`.cash-skills/receipt.tsv`
- **WHEN** 先觀察launcher的actionable failure，再執行`install-cash-skills.fish --self`與`.cash-skills/bin/cash validate --all`
- **THEN** self bootstrap只建立有效receipt，validate通過
- **AND** 測試完成後不留下receipt或其他target-specific state

<!-- @trace
source: replace-spectra-cli-with-cash-cli
updated: 2026-07-24
code:
  - .agents/skills/
  - .agents/skills/spectra-analyze/
  - .agents/skills/spectra-apply/
  - .agents/skills/spectra-archive/
  - .agents/skills/spectra-ask/
  - .agents/skills/spectra-audit/
  - .agents/skills/spectra-commit/
  - .agents/skills/spectra-debug/
  - .agents/skills/spectra-discuss/
  - .agents/skills/spectra-drift/
  - .agents/skills/spectra-ingest/
  - .agents/skills/spectra-propose/
  - .agents/skills/spectra-verify/
  - .cash-skills/bin/cash
  - .cash-skills/lib/cash_cli/
  - .cash-skills/receipt.tsv
  - .cash-skills/state/
  - .cash-skills/state/snapshots/
  - .cash-skills/state/touched/
  - .claude/skills/
  - .claude/skills/spectra-analyze/
  - .claude/skills/spectra-apply/
  - .claude/skills/spectra-archive/
  - .claude/skills/spectra-ask/
  - .claude/skills/spectra-audit/
  - .claude/skills/spectra-commit/
  - .claude/skills/spectra-debug/
  - .claude/skills/spectra-discuss/
  - .claude/skills/spectra-drift/
  - .claude/skills/spectra-ingest/
  - .claude/skills/spectra-propose/
  - .claude/skills/spectra-verify/
  - .spectra/
  - scripts/cash-cli/fixtures/
  - scripts/cash-cli/tests/
  - scripts/cash-skills/legacy-spectra-digests.tsv
  - scripts/cash-skills/tests/skill-checks.fish
tests:
-->

### Requirement: Bundle 安裝與 runtime receipt

`install-cash-skills.fish` SHALL將stable launcher/lock、replaceable runtime generation、24個Cash skills與`.cash-skills/receipt.tsv`視為同一versioned inventory。`cash-skills.version` MUST恰含一個`MAJOR.MINOR.PATCH`值，三個分量各符合`0|[1-9][0-9]*`，不得含前導零、prerelease或build suffix。版本排序 MUST以每個digit string的長度再以lexical bytes比較任意長度分量，不得轉換為fixed-width integer或float。任何replaceable runtime/skill bytes或contract mode改變 MUST調升bundle version；相同版本 MUST綁定first-parent history中的引入commit，後續相同版本內容漂移 MUST使contract test失敗。Stable bootstrap bytes不得隨一般bundle version改變，source drift MUST為execution error。

preflight MUST在任何target write前驗證Python 3.11+、source version及完整bootstrap/runtime/skill inventory、destination boundaries、legacy full-body digests、mode與config migration。direct、register與batch targets MUST各自是Git worktree top-level，且 MUST已有安全可讀、schema-valid的regular `openspec/config.yaml`；non-Git、Git子目錄target或missing/unsafe config MUST fail closed。`runtime_generation` MUST為replaceable runtime records依project-relative UTF-8 path bytes排序後，每筆以`<path>\t<lowercase-sha256>\t<four-digit-mode>\n`構成canonical UTF-8 stream的lowercase SHA-256。receipt MUST先記錄bundle version與runtime generation，再依canonical inventory順序為stable launcher/lock及每個replaceable runtime/skill path恰記一筆project-relative path、lowercase SHA-256及mode；stable records另 MUST記錄target-specific decimal `st_dev/st_ino`。launcher與installer取得stable lock後 MUST以`fstat`比對launcher/lock records、逐檔hash runtime records並重算generation，才可import runtime或分類current。invalid source version、generation或receipt的invalid version、欄位數、digest、mode、device/inode、path、順序、duplicate、missing或unknown record MUST在首次write前以execution error失敗，不得分類為missing、current、newer或conflict。launcher MUST為`0755`，lock與其他新建runtime/skill files MUST為`0644`。可刪除legacy standard skill MUST逐byte匹配`scripts/cash-skills/legacy-spectra-digests.tsv`的已知baseline且mode為`0644`。無法證明為已知baseline者（同名customization、unknown version或mode drift）MUST被保留、MUST NOT被刪除或修改，且 MUST NOT阻斷安裝：installer MUST繼續發布其餘managed inventory，並在該target的輸出逐筆列出被保留的path。只有可能導致刪除逃逸target邊界的形狀——symlink、hard link或目錄含額外內容——MUST在首次write前fail closed。legacy receipt migration只驗證舊schema實際記載的path與digest，MUST NOT以舊schema未記載的mode作為migration gate；managed skill的mode由本次transaction依contract mode正規化。

Fresh、legacy adoption與known-old migration MUST使用monotonic bootstrap。read-only preflight後，installer以`O_CREAT|O_EXCL`建立project-root lock、立即取得exclusive lock，並以`fstat`與pathname no-follow lookup重驗相同device/inode；遇到`EEXIST`的並發installer MUST開啟現存lock、等待exclusive lock、重驗pathname/FD identity後重新分類。Stable lock一旦建立 MUST NOT unlink或rename；stable launcher一旦atomic發佈亦 MUST NOT unlink或rename。failure只回滾replaceable runtime、skills、config、guidance與receipt，保留canonical `lock-only`或`lock+launcher` prefix；下一次installer MUST在同一lock inode上恢復。launcher-without-lock、bootstrap drift、unknown partial state或pathname/FD mismatch MUST fail closed。Existing current/upgrade/force/batch MUST持有同一FD到transaction/rollback完成。新receipt MUST最後發佈並從target `fstat`產生stable identity records。

Receipt-less legacy adoption MUST在receipt與runtime缺失、stable prefix為absent、`lock-only`或`lock+launcher`，且24個canonical Cash skills全數為root-contained、non-symlink、single-link regular files、bytes與`0644` mode逐筆等於source時成立。installer SHALL保留skill bytes，並由monotonic bootstrap transaction補齊launcher、runtime、config/guidance與新receipt。零個skill是fresh；1至23個、任何byte/mode/identity不同或unknown Cash runtime partial state在未帶`--force`時 MUST conflict。Receipt-less完整新inventory則可在stable lock下依全部bytes/modes相符條件認養。

Known legacy receipt MUST嚴格限定為恰好25個LF-terminated records：第一筆`version<TAB><strict-MAJOR.MINOR.PATCH>`，其後依canonical 24-skill順序各一筆`sha256<TAB><lowercase-64-hex-digest><TAB><project-relative-path>`；它沒有mode、runtime、bootstrap或generation欄位。僅當receipt完整符合此schema、24個target skills逐筆相符且stable prefix absent或canonical recoverable時，installer才 SHALL執行one-time bootstrap migration。failure MUST回滾replaceable publications並還原old receipt，但 MUST保留已發布的stable lock/launcher；下一次direct或batch invocation MUST在相同lock inode恢復。old receipt drift、unknown/incomplete schema或bootstrap drift MUST fail closed。dry-run MUST使用同一判定、零寫入並回報would-update。

installer MUST先以incoming parser驗證source config，並在target config interpretation前先驗證target receipt/version/boundary；合法newer target MUST零寫入返回，且 MUST NOT由較舊incoming parser重新解讀target`.cash.yaml`。fresh、known-legacy、adoption、current與older target才使用incoming bundle parser。config deployment MUST採三分支：既有`.cash.yaml`視為project-owned，以該parser及no-follow snapshot驗證allowed keys、duplicates、types與syntax後逐byte保留，invalid existing config MUST在首次write前execution error；只有`.spectra.yaml`時 SHALL只接受uncommented `locale/tdd/audit/parallel_tasks`及optional `spec_dir: openspec`，任何其他active top-level/nested scalar、map、list或non-default`spec_dir` MUST fail closed；兩者皆不存在時 MUST先以同一parser驗證source canonical `.cash.yaml`，再逐byte複製baseline。installer MUST NOT刪除caller-owned`.spectra.yaml`。成功transaction MUST最後才發佈receipt；failure MUST回滾新建config與先前receipt，或維持兩者absent。

Installer SHALL提供source-only `--self [--dry-run]`模式。它 MUST從installer所在目錄解析唯一Git top-level，驗證canonical source version、stable launcher/lock、replaceable runtime generation、24個skills、`.cash.yaml`與`openspec/config.yaml`的no-follow identity、bytes及contract modes，並在既有stable lock的exclusive FD下分類或發布receipt。Real run MUST只以held receipt-parent FD與same-directory owned temporary原子建立或替換`.cash-skills/receipt.tsv`；receipt MUST使用一般target相同的version、generation、path/digest/mode與stable `st_dev/st_ino` schema。`--dry-run` MUST零寫入；current self receipt MUST零寫入。`--self` MUST NOT與`--target`、`--all`、`--register`、`--unregister`、`--list`或`--force`組合，MUST NOT發布或修改launcher、lock、runtime、skills、config、guidance或legacy內容。一般direct、registry與batch target modes仍 MUST拒絕source repository。已辨識source layout的launcher在receipt缺失時 MUST回報`bootstrap_invalid`，receipt存在但內容驗證失敗時 MUST回報`receipt_invalid`；兩者皆 MUST以exit 1失敗，JSON與non-JSON diagnostic都 MUST包含`./install-cash-skills.fish --self`，installed target diagnostic MUST NOT建議source-only指令。

#### Scenario: Fresh target 原子安裝

- **GIVEN**安全、是Git top-level、具有有效`openspec/config.yaml`且沒有Cash inventory/config的target
- **WHEN**執行installer
- **THEN**stable launcher/lock、runtime generation、24個skills、source canonical Cash config與receipt在同一transaction完成
- **AND**下一次相同版本安裝回報current且零寫入

#### Scenario: Source repository self bootstrap

- **GIVEN** canonical source repository缺少target-specific receipt，但stable lock、launcher、runtime、24個skills及configs安全且完整
- **WHEN** 執行`install-cash-skills.fish --self`
- **THEN** installer在existing lock inode的exclusive FD下只發布有效receipt並回報`Result: bootstrap`
- **AND** 後續source launcher可執行Cash commands，重複`--self`回報`Result: current`且零寫入

#### Scenario: Source self dry run 與模式互斥

- **WHEN** 執行`--self --dry-run`
- **THEN** installer執行相同preflight並回報`Result: would-bootstrap`或`Result: current`，但零寫入
- **WHEN** `--self`與target、batch、registry、list或force mode任一組合
- **THEN** installer以caller-input error失敗且零寫入

#### Scenario: Source launcher提供可行動診斷

- **GIVEN** 已辨識source layout且receipt缺失或無效
- **WHEN** 以JSON或non-JSON模式啟動launcher
- **THEN** launcher依receipt缺失或內容失效分別以`bootstrap_invalid`或`receipt_invalid`與exit 1失敗
- **AND** diagnostic指出從project root執行`./install-cash-skills.fish --self`

#### Scenario: Target prerequisite 不足

- **WHEN**direct、registered或batch target不是Git worktree top-level，或缺少安全有效的`openspec/config.yaml`
- **THEN**installer在首次target write前以execution error失敗
- **AND**不發佈runtime、skills、config、guidance或receipt

#### Scenario: Config 三分支

- **WHEN**target已有`.cash.yaml`
- **THEN**installer以Cash runtime同一parser驗證後逐byte保留它
- **AND**unknown key、duplicate、wrong type或malformed內容在首次write前以execution error失敗

- **WHEN**target只有受支援的`.spectra.yaml`
- **THEN**installer建立等價Cash config且不刪除legacy source
- **AND**其他active scalar/map/list、unknown key或non-default`spec_dir`在首次write前失敗

- **WHEN**target兩者皆無
- **THEN**installer逐byte建立source canonical`.cash.yaml`
- **AND**任何後續transaction failure回滾該新檔

#### Scenario: Newer target 不由舊 parser 重解

- **GIVEN**target有合法較新receipt及該版本合法、但incoming舊parser不認得的Cash config
- **WHEN**較舊installer評估target
- **THEN**installer在解析target config前回報newer且零寫入

#### Scenario: Known legacy receipt 建立 bootstrap

- **GIVEN**target具有嚴格舊schema receipt與逐筆相符的24個Cash skills，且沒有launcher與workspace lock
- **WHEN**real run或dry-run評估target
- **THEN**real run以exclusive新lock transaction建立stable bootstrap、runtime與新receipt，dry-run回報would-update且零寫入
- **AND**publication failure保留canonical stable prefix並回滾replaceable state，下一次在同一lock inode恢復
- **AND**並發安裝、old receipt drift與bootstrap collision依上述migration contract收斂或fail closed

#### Scenario: Receipt-less 24-skill legacy target 被認養

- **GIVEN**target沒有receipt/runtime，stable prefix為absent或canonical recoverable，且24個Cash skills的regular-file identity、bytes與`0644` mode全數等於source
- **WHEN**installer執行
- **THEN**installer保留skill bytes並以monotonic bootstrap transaction發佈launcher、runtime、config/guidance與新receipt
- **AND**partial、different或unsafe legacy inventory在未帶`--force`時為conflict且零寫入

#### Scenario: 未知 legacy skill 被保留且不阻斷安裝

- **GIVEN** target的某個`spectra-*` directory只含regular `SKILL.md`，但其bytes或mode不符已知baseline
- **WHEN** installer執行
- **THEN** 該directory與其內容維持逐byte與逐mode不變
- **AND** installer仍完成runtime、skills、config、guidance與receipt的發布
- **AND** 輸出逐筆列出被保留的legacy path

#### Scenario: 邊界不安全形狀仍 fail closed

- **WHEN** legacy candidate是symlink、其`SKILL.md`為hard link，或該directory含額外檔案
- **THEN** installer在首次target write前失敗
- **AND** `--force`不繞過此失敗

#### Scenario: Legacy receipt migration 不以 mode 為 gate

- **GIVEN** target具有舊schema receipt，其24個skill digest全部相符但檔案mode為`0600`
- **WHEN** installer評估該target
- **THEN** migration MUST NOT因mode不符而失敗
- **AND** 本次transaction把managed skills正規化為contract mode

#### Scenario: Legacy standard skills 安全移除

- **GIVEN**target內每個Cash替代範圍中的`spectra-*` directory只含identity相符的regular `SKILL.md`
- **WHEN**installer完成全部preflight並提交upgrade
- **THEN**這些legacy directories在同一transaction被移除
- **AND**未知內容、symlink或額外檔案會使整體transaction在首次write前失敗

#### Scenario: Installed launcher mode 可執行

- **WHEN**fresh、upgrade或force installation成功
- **THEN**target `.cash-skills/bin/cash` mode為`0755`
- **AND**contract test直接執行target launcher成功

#### Scenario: Strict SemVer 與任意長度排序

- **WHEN**source version缺失、多行、含前導零、prerelease、build suffix或不是三個分量
- **THEN**installer與dry-run皆在首次target write前以execution error失敗

- **WHEN**比較含有超過平台integer範圍的有效版本分量
- **THEN**installer依digit length與lexical bytes得到正確數值順序
- **AND**不發生overflow或floating-point rounding

#### Scenario: Invalid receipt fail closed

- **GIVEN**target receipt包含invalid version、欄位數、digest、mode、device/inode、generation、path、順序、duplicate、missing或unknown record
- **WHEN**installer評估target
- **THEN**installer以execution error失敗且零target write
- **AND**target不被分類為missing、current、newer或conflict

#### Scenario: Bundle 版本綁定內容

- **GIVEN**repository history包含`cash-skills.version`
- **WHEN**replaceable runtime/skill bytes或contract mode相對版本引入commit改變
- **THEN**contract suite要求目前版本嚴格遞增
- **AND**相同版本的內容或mode漂移使測試失敗
- **AND**stable launcher/lock source bytes改變時以unsupported bootstrap migration失敗而非一般version bump

#### Scenario: Receipt-less 完整新 inventory 被認養

- **GIVEN**target沒有receipt且stable launcher/lock與全部replaceable runtime/24個skills逐byte及mode等於source
- **WHEN**installer執行
- **THEN**installer先鎖定existing lock inode、保留stable bootstrap與managed bytes並發佈含runtime generation的receipt
- **AND**回報`Result: update`

#### Scenario: Current、newer 與 conflict 分類

- **WHEN**版本、全部receipt records、modes、guidance與legacy state都一致
- **THEN**installer回報`Result: current`且零寫入

- **WHEN**target receipt版本高於source
- **THEN**installer回報`Result: newer`且零寫入

- **WHEN**target managed path相對有效receipt drift且未授權`--force`
- **THEN**installer回報`Result: conflict`、exit 2且零寫入

#### Scenario: Upgrade 與 force 只收斂 managed inventory

- **GIVEN**target版本不高於source且所有preflight通過
- **WHEN**clean upgrade或授權`--force`執行
- **THEN**installer持有existing lock inode，只更新replaceable runtime generation、24個skills、Cash guidance、receipt與精確baseline legacy removals
- **AND**stable launcher與lock inode不變
- **AND**其他project-owned bytes維持不變

#### Scenario: Dry run 與 background-free registry

- **WHEN**installer以`--dry-run`、`--list`、`--register`、`--unregister`或`--all`執行
- **THEN**dry-run不產生target或persistent writes，registry modes只執行明確要求的state change
- **AND**不建立daemon、LaunchAgent、scheduled repair、watcher或background process

#### Scenario: Publication failure 可恢復

- **GIVEN**全部preflight成功且第N個publication失敗
- **WHEN**installer進入failure handling
- **THEN**它依transaction journal回滾已發布managed paths
- **AND**rollback失敗時保留journal、回報exit 1並阻斷下一次mutation直到recovery完成

#### Scenario: Install 與 launch 共用 stable lock

- **GIVEN**existing target正在執行Cash CLI並持有stable lock的shared FD
- **WHEN**installer嘗試upgrade runtime generation
- **THEN**installer在取得同一inode的exclusive lock前不得snapshot或publish managed destinations
- **AND**CLI process不載入mixed runtime generation

- **GIVEN**installer持有exclusive lock並正在publish多檔runtime generation
- **WHEN**新launcher process啟動
- **THEN**launcher在import library前等待同一lock
- **AND**取得shared lock後只載入receipt驗證過的完整generation

<!-- @trace
source: replace-spectra-cli-with-cash-cli
updated: 2026-07-24
code:
  - .agents/skills/
  - .agents/skills/spectra-analyze/
  - .agents/skills/spectra-apply/
  - .agents/skills/spectra-archive/
  - .agents/skills/spectra-ask/
  - .agents/skills/spectra-audit/
  - .agents/skills/spectra-commit/
  - .agents/skills/spectra-debug/
  - .agents/skills/spectra-discuss/
  - .agents/skills/spectra-drift/
  - .agents/skills/spectra-ingest/
  - .agents/skills/spectra-propose/
  - .agents/skills/spectra-verify/
  - .cash-skills/bin/cash
  - .cash-skills/lib/cash_cli/
  - .cash-skills/receipt.tsv
  - .cash-skills/state/
  - .cash-skills/state/snapshots/
  - .cash-skills/state/touched/
  - .claude/skills/
  - .claude/skills/spectra-analyze/
  - .claude/skills/spectra-apply/
  - .claude/skills/spectra-archive/
  - .claude/skills/spectra-ask/
  - .claude/skills/spectra-audit/
  - .claude/skills/spectra-commit/
  - .claude/skills/spectra-debug/
  - .claude/skills/spectra-discuss/
  - .claude/skills/spectra-drift/
  - .claude/skills/spectra-ingest/
  - .claude/skills/spectra-propose/
  - .claude/skills/spectra-verify/
  - .spectra/
  - scripts/cash-cli/fixtures/
  - scripts/cash-cli/tests/
  - scripts/cash-skills/legacy-spectra-digests.tsv
  - scripts/cash-skills/tests/skill-checks.fish
tests:
-->

### Requirement: Cash guidance deployment

Installer SHALL從source `AGENTS.md`與`CLAUDE.md`各擷取唯一、完整且no-follow snapshot的Cash block。對非`newer`、非`conflict`target，它 MUST建立或更新對應Cash block、移除一個合法legacy Spectra block、逐byte保留managed spans外內容與既有mode，並與runtime/skills/receipt共用transaction。Marker孤立、反序、重複、巢狀、非獨立行、post-preflight bytes/identity drift或parent swap MUST在publication前fail closed。

#### Scenario: Missing、Spectra-only 與 mixed guidance 收斂

- **WHEN**target guidance missing、沒有managed block、只有一個合法Spectra block或同時有合法Cash/Spectra blocks
- **THEN**installer產生恰好一個canonical Cash block並移除合法Spectra block
- **AND**managed spans外bytes與既有mode保持不變，新建file mode為`0644`

#### Scenario: Guidance snapshot 與 parent identity 綁定

- **GIVEN**preflight記錄guidance no-follow handle的bytes、digest、mode與parent/destination identity
- **WHEN**temporary create與最後publication checkpoint執行
- **THEN**installer重新驗證全部snapshot與identity
- **AND**parent/destination被替換時不覆蓋新內容或root外sentinel

#### Scenario: Guidance marker malformed

- **WHEN**source或target Cash/Spectra markers孤立、反序、重複、巢狀或非獨立行
- **THEN**installer在首次target write前exit 1
- **AND**`--force`不繞過失敗

<!-- @trace
source: replace-spectra-cli-with-cash-cli
updated: 2026-07-24
code:
  - .agents/skills/
  - .agents/skills/spectra-analyze/
  - .agents/skills/spectra-apply/
  - .agents/skills/spectra-archive/
  - .agents/skills/spectra-ask/
  - .agents/skills/spectra-audit/
  - .agents/skills/spectra-commit/
  - .agents/skills/spectra-debug/
  - .agents/skills/spectra-discuss/
  - .agents/skills/spectra-drift/
  - .agents/skills/spectra-ingest/
  - .agents/skills/spectra-propose/
  - .agents/skills/spectra-verify/
  - .cash-skills/bin/cash
  - .cash-skills/lib/cash_cli/
  - .cash-skills/receipt.tsv
  - .cash-skills/state/
  - .cash-skills/state/snapshots/
  - .cash-skills/state/touched/
  - .claude/skills/
  - .claude/skills/spectra-analyze/
  - .claude/skills/spectra-apply/
  - .claude/skills/spectra-archive/
  - .claude/skills/spectra-ask/
  - .claude/skills/spectra-audit/
  - .claude/skills/spectra-commit/
  - .claude/skills/spectra-debug/
  - .claude/skills/spectra-discuss/
  - .claude/skills/spectra-drift/
  - .claude/skills/spectra-ingest/
  - .claude/skills/spectra-propose/
  - .claude/skills/spectra-verify/
  - .spectra/
  - scripts/cash-cli/fixtures/
  - scripts/cash-cli/tests/
  - scripts/cash-skills/legacy-spectra-digests.tsv
  - scripts/cash-skills/tests/skill-checks.fish
tests:
-->

### Requirement: Installer 與 legacy cleanup filesystem boundaries

Installer SHALL canonicalize既有target；一般direct、registry與batch模式 MUST拒絕空值、`/`、source repository、symlink target、root外destination及symlink/hard-link ownership不明的managed boundary。唯一source repository例外是明確`--self`模式，且該模式只能在已驗證source root內發布receipt。Publisher MUST以held no-follow parent directory handle、exclusive relative temporary basename、snapshot revalidation、明確mode與transaction journal完成publication/cleanup。Registry與`uninstall-spectra-plus-repair.fish` MUST保留既有HOME absolute/non-root、symlink及service identity fail-closed contract。

#### Scenario: Target 與 HOME boundary fail closed

- **WHEN**target、managed parent、destination、receipt、config、guidance或HOME/registry boundary不安全
- **THEN**installer或cleanup在首次write與`launchctl`前失敗
- **AND**不讀寫root外target

#### Scenario: Temporary ownership 與 mode preservation

- **GIVEN**publisher持有已驗證parent handle
- **WHEN**建立temporary entry並publish
- **THEN**temporary basename以exclusive create證明本次ownership
- **AND**publication設定contract mode並只清理本次owned entry

#### Scenario: Parent swap 與 rollback failure

- **WHEN**parent/destination在preflight後被替換，或rollback再次失敗
- **THEN**publisher不透過失效pathname執行cleanup或write
- **AND**保留transaction journal與可恢復diagnostic

<!-- @trace
source: replace-spectra-cli-with-cash-cli
updated: 2026-07-24
code:
  - .agents/skills/
  - .agents/skills/spectra-analyze/
  - .agents/skills/spectra-apply/
  - .agents/skills/spectra-archive/
  - .agents/skills/spectra-ask/
  - .agents/skills/spectra-audit/
  - .agents/skills/spectra-commit/
  - .agents/skills/spectra-debug/
  - .agents/skills/spectra-discuss/
  - .agents/skills/spectra-drift/
  - .agents/skills/spectra-ingest/
  - .agents/skills/spectra-propose/
  - .agents/skills/spectra-verify/
  - .cash-skills/bin/cash
  - .cash-skills/lib/cash_cli/
  - .cash-skills/receipt.tsv
  - .cash-skills/state/
  - .cash-skills/state/snapshots/
  - .cash-skills/state/touched/
  - .claude/skills/
  - .claude/skills/spectra-analyze/
  - .claude/skills/spectra-apply/
  - .claude/skills/spectra-archive/
  - .claude/skills/spectra-ask/
  - .claude/skills/spectra-audit/
  - .claude/skills/spectra-commit/
  - .claude/skills/spectra-debug/
  - .claude/skills/spectra-discuss/
  - .claude/skills/spectra-drift/
  - .claude/skills/spectra-ingest/
  - .claude/skills/spectra-propose/
  - .claude/skills/spectra-verify/
  - .spectra/
  - scripts/cash-cli/fixtures/
  - scripts/cash-cli/tests/
  - scripts/cash-skills/legacy-spectra-digests.tsv
  - scripts/cash-skills/tests/skill-checks.fish
tests:
-->

### Requirement: Live namespace 與歷史邊界

live scan SHALL只包含`.agents/skills/cash-*/`、`.claude/skills/cash-*/`、`scripts/cash-skills/variant-parity/`、`install-cash-skills.fish`、`scripts/cash-skills/tests/`、`.cash-skills/`、`scripts/cash-cli/`、`AGENTS.md`、`CLAUDE.md`、`CASH-SKILLS.md`、`.cash.yaml`與`openspec/specs/`。這些surface SHALL NOT包含可執行的Spectra CLI command、`Requires spectra CLI`或未治理的`.spectra/`runtime read。active migration change/reviews、`openspec/changes/archive/`與signal occurrence history SHALL保留provenance原文。Legacy migration code SHALL只在下列明列paths辨識`SPECTRA` markers、`.spectra.yaml`、`.spectra/touched`、`.spectra/snapshots`與`spectra-*`directories：`install-cash-skills.fish`、`uninstall-spectra-plus-repair.fish`、`scripts/cash-skills/legacy-spectra-digests.tsv`，以及`.cash-skills/lib/cash_cli/`中負責`touched ensure` legacy import的module；`.spectra.yaml`→`.cash.yaml` config migration亦限於`install-cash-skills.fish`。這些paths之外的live surface MUST NOT出現legacy literal，且以上任何path MUST NOT執行Spectra binary或讀取其他Spectra state。

#### Scenario: Live namespace residue scan

- **WHEN**contract test掃描所有non-archive live surfaces
- **THEN**任何可執行的`spectra`command、compatibility declaration或runtime config read使測試失敗
- **AND**明列的legacy detector literals不被誤判為runtime dependency

#### Scenario: 歷史 artifacts 不回寫

- **WHEN**namespace migration完成
- **THEN**`openspec/changes/archive/`內既有files維持逐byte不變
- **AND**signal occurrence中的歷史provenance不被重新命名

<!-- @trace
source: replace-spectra-cli-with-cash-cli
updated: 2026-07-24
code:
  - .agents/skills/
  - .agents/skills/spectra-analyze/
  - .agents/skills/spectra-apply/
  - .agents/skills/spectra-archive/
  - .agents/skills/spectra-ask/
  - .agents/skills/spectra-audit/
  - .agents/skills/spectra-commit/
  - .agents/skills/spectra-debug/
  - .agents/skills/spectra-discuss/
  - .agents/skills/spectra-drift/
  - .agents/skills/spectra-ingest/
  - .agents/skills/spectra-propose/
  - .agents/skills/spectra-verify/
  - .cash-skills/bin/cash
  - .cash-skills/lib/cash_cli/
  - .cash-skills/receipt.tsv
  - .cash-skills/state/
  - .cash-skills/state/snapshots/
  - .cash-skills/state/touched/
  - .claude/skills/
  - .claude/skills/spectra-analyze/
  - .claude/skills/spectra-apply/
  - .claude/skills/spectra-archive/
  - .claude/skills/spectra-ask/
  - .claude/skills/spectra-audit/
  - .claude/skills/spectra-commit/
  - .claude/skills/spectra-debug/
  - .claude/skills/spectra-discuss/
  - .claude/skills/spectra-drift/
  - .claude/skills/spectra-ingest/
  - .claude/skills/spectra-propose/
  - .claude/skills/spectra-verify/
  - .spectra/
  - scripts/cash-cli/fixtures/
  - scripts/cash-cli/tests/
  - scripts/cash-skills/legacy-spectra-digests.tsv
  - scripts/cash-skills/tests/skill-checks.fish
tests:
-->
