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

CLI SHALL 另提供不擴張上述command family集合的help表面。第一個argument為`--help`或`-h`時，CLI MUST在launcher完成既有的lock取得與receipt驗證之後、進入command dispatch之前輸出help並以exit 0結束；help MUST NOT繞過launcher的receipt gate，因此receipt缺失或無效時 MUST維持既有的`bootstrap_invalid`／`receipt_invalid`失敗而非輸出help。help flag不是command，`Project-local Cash CLI runtime`對unknown command的失敗規定僅適用於進入dispatch的token。第一個argument不是help flag時，CLI的dispatch目標、exit code、`error` code與JSON object結構 MUST與未提供該表面時相同。由top-level command dispatch產生的`missing_command`與`unknown_command` MUST維持既有的code、exit code與`error` object結構，但其`message` MUST指向help flag。該訊息 MUST NOT內嵌command清單——內嵌會使釘住該訊息的golden fixture成為第二份需手動同步的清單，與本requirement消除重複定義的目的相反；指向help的措辭是不隨dispatch table變動的穩定字串。由個別handler產生的其他`unknown_command`（例如未知的new mode或未知的discipline）MUST NOT受此規定影響。command清單 MUST只有help一個輸出處，且 MUST由dispatch table導出，MUST NOT另立靜態副本。`--json`時help MUST輸出單一JSON object，其`commands`欄位為排序後的dispatch table key陣列。

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
- **AND** 該dispatch層錯誤訊息指向help flag，且不內嵌command清單

#### Scenario: Help flag 列出全部 command

- **GIVEN** target的receipt有效且launcher可取得lock
- **WHEN** caller以`--help`或`-h`作為第一個argument執行CLI
- **THEN** CLI輸出dispatch table全部command並以exit 0結束
- **AND** CLI不進入command dispatch

##### Example: help 的兩種輸出形狀

- **GIVEN** caller位於receipt有效的workspace
- **WHEN** caller執行`.cash-skills/bin/cash --help --json`
- **THEN** CLI在stdout輸出單一JSON object，其`commands`為排序後的dispatch table key陣列
- **AND** 同一指令去除`--json`時輸出人類可讀文字

#### Scenario: Help 不繞過 receipt gate

- **GIVEN** target的`.cash-skills/receipt.tsv`缺失或內容無效
- **WHEN** caller以`--help`作為第一個argument執行CLI
- **THEN** CLI維持既有的`bootstrap_invalid`或`receipt_invalid`失敗
- **AND** CLI不輸出help

#### Scenario: 缺少 command 時指向 help

- **WHEN** caller不提供任何argument執行CLI
- **THEN** CLI以`missing_command`與既有exit code失敗
- **AND** 錯誤訊息指向help flag，且不內嵌command清單

#### Scenario: Handler 層的 unknown_command 不受影響

- **WHEN** caller執行`.cash-skills/bin/cash new bogus <artifact-id>`或`.cash-skills/bin/cash instructions --skill bogus`
- **THEN** CLI維持既有的`unknown_command` code、exit code與訊息語意
- **AND** 該訊息不包含top-level command清單，也不指向help flag

#### Scenario: Help flag 不改變其他位置的行為

- **WHEN** caller執行`.cash-skills/bin/cash list --help`
- **THEN** CLI將該argument交給`list` handler，dispatch目標與exit code與未提供help表面時相同
- **AND** CLI不輸出help

<!-- @trace
source: derive-version-assertion-and-add-cli-help
updated: 2026-07-25
code:
  - .cash-skills/lib/cash_cli/main.py
  - scripts/cash-cli/fixtures/negative-atomicity/error-contracts.json
  - scripts/cash-cli/tests/test_negative_atomicity.py
  - scripts/cash-cli/tests/test_runtime_and_errors.py
  - scripts/cash-skills/tests/skill-checks.fish
tests:
  - scripts/cash-cli/tests/test_negative_atomicity.py
  - scripts/cash-cli/tests/test_runtime_and_errors.py
  - scripts/cash-skills/tests/skill-checks.fish
  - scripts/cash-skills/tests/test_bundle_version_history.py
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

`search` SHALL 只讀取以 no-follow handle 開啟、經 `fstat` 確認且 identity 位於 root 內的 regular files，以 Unicode case-folded query tokens 比對 path、heading 與 body，並回傳 `path`、`title`、`excerpt` 與 normalized `score`。symlink file/directory、parent identity swap 與 root 外 target MUST 在讀取 body 前拒絕。相同 score MUST 依 project-relative path byte order 排序。合法 zero-result MUST 回傳空 `results` 且 exit 0。CLI MUST NOT 要求 vector model 或 index。

語料範圍 SHALL 由 `--scope` 控制，其值 MUST 為 `specs`、`active` 或 `all` 三者之一，未提供時 MUST 等同 `active`。`specs` MUST 只涵蓋 `openspec/specs/` 底下的文件；`active` MUST 涵蓋 `openspec/` 底下但排除位於 `openspec/changes/archive/` 之下、且其路徑中存在一個完整片段等於 `reviews` 的目錄之文件。此比對 MUST 以完整路徑片段進行，MUST NOT 以字串前綴或子字串比對，因此名稱僅包含 `reviews` 的目錄（例如 `code-reviews`）MUST NOT 被排除；`all` MUST 涵蓋 `openspec/` 底下全部文件而不作任何排除。`--scope` 提供了不在這三個列舉值內的值時 MUST 以 `invalid_scope` 與 exit 2 失敗。

排除 SHALL 在目錄走訪層剪枝，MUST NOT 以走訪後過濾實作。因此被排除的檔案 MUST NOT 被開啟或解碼，且封存 `reviews` 目錄下存在非 UTF-8 檔案時 `--scope active` 與 `--scope specs` MUST 仍 exit 0。`--scope specs` 在 `openspec/specs/` 不存在時 MUST 回傳空 `results` 且 exit 0，MUST NOT 以 execution error 失敗。

參數解析 SHALL 與旗標位置無關：解析器 MUST 辨識 `--limit` 與 `--scope` 為帶值旗標並同時略過旗標與其值，MUST 辨識 `--json` 為無值旗標，其餘不以 `--` 開頭的 token 才是位置參數。以單一連字號開頭的 token MUST 視為位置參數而非旗標，使自然語言 query 維持可用。帶值旗標後方的 token 若以 `-` 開頭，MUST 視為該旗標缺值，MUST NOT 吞掉該 token 當作值。位置參數 MUST 恰為一個；零個、多於一個、或出現未知的 `--` 開頭 token 時 MUST 以 `invalid_arguments` 與 exit 2 失敗。

`--limit` 未提供時 SHALL 採用預設值 `10`，MUST NOT 因其缺席而失敗。`--limit` 提供了但缺值、值非整數、或值不在 `1` 到 `100` 的閉區間內時 MUST 以 `invalid_limit` 與 exit 2 失敗，且缺值與值不合法兩種情形的 message MUST 不相同。空 query 與 unreadable/unsafe file MUST 失敗。

#### Scenario: Lexical ranking 穩定

- **GIVEN** 三個文件分別在 heading、body 與 path 命中相同 query token
- **WHEN** 執行 `search "archive safety" --limit 3 --json`
- **THEN** 結果依定義的 path/heading/body 權重排序
- **AND** 相同 score 依 path byte order 排序

#### Scenario: 無結果不是執行錯誤

- **WHEN** 合法 query 沒有命中任何文件
- **THEN** CLI 回傳 `{ "results": [] }`
- **AND** process exit code 為 0

#### Scenario: 旗標位置不改變 query 身分

- **GIVEN** 一個含多份文件的 workspace
- **WHEN** 分別執行 `search openspec --limit 5 --json` 與 `search --limit 5 openspec --json`
- **THEN** 兩次的 stdout 逐位元組相同

##### Example: 旗標前置與後置

| 指令 | 解析出的 query | 解析出的 limit |
| --- | --- | --- |
| `search openspec --limit 5` | `openspec` | `5` |
| `search --limit 5 openspec` | `openspec` | `5` |

#### Scenario: 位置參數數量不合法時失敗

- **WHEN** 執行不含任何位置參數的 `search --limit 5 --json`
- **THEN** CLI 以 `invalid_arguments` 與 exit 2 失敗
- **WHEN** 執行含兩個位置參數的 `search alpha beta --json`
- **THEN** CLI 以 `invalid_arguments` 與 exit 2 失敗
- **WHEN** 執行含未知旗標的 `search alpha --bogus --json`
- **THEN** CLI 以 `invalid_arguments` 與 exit 2 失敗

#### Scenario: 單一連字號開頭的 query 維持可用

- **WHEN** 執行以單一連字號開頭的 query
- **THEN** CLI 把該 token 視為位置參數而非旗標
- **AND** exit code 為 0

#### Scenario: limit 缺席採用預設值

- **WHEN** 執行未帶 `--limit` 的 `search openspec --json`
- **THEN** CLI exit 0
- **AND** `results` 的長度不超過 10

#### Scenario: limit 的缺值與不合法分別失敗

- **WHEN** 執行 `search openspec --limit --json`
- **THEN** CLI 以 `invalid_limit` 與 exit 2 失敗
- **AND** message 表明該旗標缺少值
- **WHEN** 執行 `search openspec --limit abc --json`
- **THEN** CLI 以 `invalid_limit` 與 exit 2 失敗
- **AND** message 表明該值不合法且與缺值情形的 message 不同
- **WHEN** 執行 `search openspec --limit 0 --json`
- **THEN** CLI 以 `invalid_limit` 與 exit 2 失敗

##### Example: limit 的四種輸入

| 指令片段 | 結果 | message 類別 |
| --- | --- | --- |
| 未帶 `--limit` | exit 0，最多 10 筆 | 不適用 |
| `--limit` 後方接 `--json` | `invalid_limit`，exit 2 | 缺值 |
| `--limit abc` | `invalid_limit`，exit 2 | 值不合法 |
| `--limit 0` | `invalid_limit`，exit 2 | 值不合法 |

#### Scenario: 預設語料排除封存的 review 檔案但保留封存決策脈絡

- **GIVEN** workspace 同時含 `openspec/specs/` 底下的 master spec、非封存 change 的 artifact、封存 change 的 `proposal.md` 與封存 change 的 `reviews/propose-r1.md`，且四者都命中同一個 query token
- **WHEN** 執行未帶 `--scope` 的 `search <token> --json`
- **THEN** `results` 不含任何位於封存 `reviews` 目錄底下的 `path`
- **AND** `results` 含該封存 change 的 `proposal.md`
- **WHEN** 對相同 workspace 執行 `search <token> --scope specs --json`
- **THEN** `results` 的每個 `path` 都位於 `openspec/specs/` 底下
- **WHEN** 對相同 workspace 以足以涵蓋全部命中文件的 `--limit` 執行 `search <token> --scope all --json`
- **THEN** `results` 為相同 `--limit` 下 `active` 結果的超集合
- **AND** `results` 至少含一個位於封存 `reviews` 目錄底下的 `path`
- **WHEN** 執行 `search <token> --scope bogus --json`
- **THEN** CLI 以 `invalid_scope` 與 exit 2 失敗

#### Scenario: 被排除的檔案不被開啟

- **GIVEN** 封存 change 的 `reviews` 目錄下存在一個非 UTF-8 檔案
- **WHEN** 執行未帶 `--scope` 的 `search <token> --json`
- **THEN** CLI exit 0 且不回報 `invalid_encoding`
- **WHEN** 對相同 workspace 執行 `search <token> --scope specs --json`
- **THEN** CLI exit 0 且不回報 `invalid_encoding`

#### Scenario: specs 範圍在目錄不存在時回空

- **GIVEN** 一個沒有 `openspec/specs/` 目錄的 workspace
- **WHEN** 執行 `search <token> --scope specs --json`
- **THEN** CLI 回傳 `{ "results": [] }` 且 exit 0

<!-- @trace
source: align-cli-skill-contracts
updated: 2026-07-25
code:
  - .agents/skills/cash-analyze/SKILL.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-discuss/SKILL.md
  - .agents/skills/cash-drift/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - .agents/skills/cash-propose/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .cash-skills/lib/cash_cli/commands/drift.py
  - .cash-skills/lib/cash_cli/commands/search.py
  - .cash-skills/lib/cash_cli/resources.py
  - .cash-skills/lib/cash_cli/workspace.py
  - .claude/skills/cash-drift/SKILL.md
  - .claude/skills/cash-propose/SKILL.md
  - scripts/cash-cli/tests/test_analyze_drift.py
  - scripts/cash-cli/tests/test_graph_instructions.py
  - scripts/cash-cli/tests/test_lexical_search.py
  - scripts/cash-skills/tests/skill-checks.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/cash-skills/variant-parity/cash-discuss.diff
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/cash-skills/variant-parity/cash-verify.diff
tests:
  - scripts/cash-cli/tests/cli-checks.fish
  - scripts/cash-cli/tests/test_analyze_drift.py
  - scripts/cash-cli/tests/test_graph_instructions.py
  - scripts/cash-cli/tests/test_lexical_search.py
  - scripts/cash-cli/tests/test_negative_atomicity.py
  - scripts/cash-skills/tests/skill-checks.fish
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

系統 SHALL以兩個套件治理Cash contract。`scripts/cash-cli/tests/cli-checks.fish` MUST治理Cash CLI的command dispatch、workspace/config boundary、artifact與touched-state lifecycle、validation/analysis/drift、lexical search、sync/archive transaction、error/atomicity與所有consumer JSON shapes。`scripts/cash-skills/tests/skill-checks.fish` MUST治理bundle version、直接／registry／batch installer分支、guidance migration、24-skill variant parity與live namespace residue。其在本套件內直接定義的bundle version規則 MUST限於單一LF終止；格式判定 MUST委派給runtime既有的版本解析函式而非在本套件重寫，使內容接受集合與installer的判定同源。該LF條款由本requirement擁有——MUST NOT以字面值釘住任何特定版本號，且 MUST NOT在本套件重新定義格式規則的內容——格式規則的權威來源維持在`Bundle 安裝與 runtime receipt`。嚴格遞增與相同版本的內容綁定 MUST維持由bundle version history contract test單一擁有，MUST NOT在本套件重複定義。該形狀驗證 MUST與呼叫bundle version history contract test落在同一個test group，使形狀與數值治理在同一次執行中同時成立。調升`cash-skills.version` MUST NOT因此需要修改`scripts/cash-skills/tests/skill-checks.fish`。兩套件 MUST在PATH刻意排除Spectra binary時通過，且 MUST NOT執行任何`spectra`command或`spectra update`。

#### Scenario: 兩套件在無 Spectra binary 時通過

- **GIVEN** PATH中不存在Spectra binary
- **WHEN** 執行`scripts/cash-cli/tests/cli-checks.fish`與`scripts/cash-skills/tests/skill-checks.fish`
- **THEN** 兩套件皆通過
- **AND** 沒有任何測試呼叫`spectra`command

#### Scenario: CLI 與 skill 治理範圍不重疊

- **WHEN** 檢視兩套件涵蓋的surface
- **THEN** CLI lifecycle/atomicity/JSON contract由`cli-checks.fish`治理
- **AND** bundle、installer、guidance、parity與namespace residue由`skill-checks.fish`治理

#### Scenario: 版本治理不以字面值釘住

- **GIVEN** `cash-skills.version`為任一嚴格高於`HEAD`版本的合法值
- **WHEN** 執行`scripts/cash-skills/tests/skill-checks.fish`的完整套件
- **THEN** 版本治理通過，且不因該值不等於任何特定數值而失敗
- **AND** 調升該版本後重新執行仍通過，且`scripts/cash-skills/tests/skill-checks.fish`逐byte未變

#### Scenario: 形狀驗證與數值治理同組執行

- **GIVEN** 版本檔的形狀驗證已加入套件
- **WHEN** 執行任一會觸發該形狀驗證的test group
- **THEN** 同一group也呼叫bundle version history contract test
- **AND** 形狀與數值兩層治理不會落在互不相交的group

#### Scenario: Source repository 無 receipt bootstrap

- **GIVEN** source repository沒有被忽略的`.cash-skills/receipt.tsv`
- **WHEN** 先觀察launcher的actionable failure，再執行`install-cash-skills.fish --self`與`.cash-skills/bin/cash validate --all`
- **THEN** self bootstrap只建立有效receipt，validate通過
- **AND** 測試完成後不留下receipt或其他target-specific state

<!-- @trace
source: derive-version-assertion-and-add-cli-help
updated: 2026-07-25
code:
  - .cash-skills/lib/cash_cli/main.py
  - scripts/cash-cli/fixtures/negative-atomicity/error-contracts.json
  - scripts/cash-cli/tests/test_negative_atomicity.py
  - scripts/cash-cli/tests/test_runtime_and_errors.py
  - scripts/cash-skills/tests/skill-checks.fish
tests:
  - scripts/cash-cli/tests/test_negative_atomicity.py
  - scripts/cash-cli/tests/test_runtime_and_errors.py
  - scripts/cash-skills/tests/skill-checks.fish
  - scripts/cash-skills/tests/test_bundle_version_history.py
-->

### Requirement: Bundle 安裝與 runtime receipt

`install-cash-skills.fish` SHALL將stable launcher/lock、replaceable runtime generation、24個Cash skills與`.cash-skills/receipt.tsv`視為同一versioned inventory。`cash-skills.version` MUST恰含一個`MAJOR.MINOR.PATCH`值，三個分量各符合`0|[1-9][0-9]*`，不得含前導零、prerelease或build suffix。版本排序 MUST以每個digit string的長度再以lexical bytes比較任意長度分量，不得轉換為fixed-width integer或float。任何replaceable runtime/skill bytes或contract mode改變 MUST調升bundle version；相同版本 MUST綁定first-parent history中的引入commit，後續相同版本內容漂移 MUST使contract test失敗。Stable bootstrap bytes不得隨一般bundle version改變，source drift MUST為execution error。

preflight MUST在任何target write前驗證Python 3.11+、source version及完整bootstrap/runtime/skill inventory、destination boundaries、legacy full-body digests、mode與config migration。direct、register與batch targets MUST各自是Git worktree top-level，且 MUST已有安全可讀、schema-valid的regular `openspec/config.yaml`；non-Git、Git子目錄target或missing/unsafe config MUST fail closed。`runtime_generation` MUST為replaceable runtime records依project-relative UTF-8 path bytes排序後，每筆以`<path>\t<lowercase-sha256>\t<four-digit-mode>\n`構成canonical UTF-8 stream的lowercase SHA-256。receipt MUST先記錄bundle version與runtime generation，再依canonical inventory順序為stable launcher/lock及每個replaceable runtime/skill path恰記一筆project-relative path、lowercase SHA-256及mode；stable records另 MUST記錄target-specific decimal `st_dev/st_ino`。launcher與installer取得stable lock後 MUST以`fstat`比對launcher/lock records、逐檔hash runtime records並重算generation，才可import runtime或分類current。invalid source version、generation或receipt的invalid version、欄位數、digest、mode、device/inode、path、順序、duplicate、missing或unknown record MUST在首次write前以execution error失敗，不得分類為missing、current、newer或conflict。launcher MUST為`0755`，lock與其他新建runtime/skill files MUST為`0644`。可刪除legacy standard skill MUST逐byte匹配`scripts/cash-skills/legacy-spectra-digests.tsv`的已知baseline且mode為`0644`。無法證明為已知baseline者（同名customization、unknown version或mode drift）MUST被保留、MUST NOT被刪除或修改，且 MUST NOT阻斷安裝：installer MUST繼續發布其餘managed inventory，並在該target的輸出逐筆列出被保留的path。只有可能導致刪除逃逸target邊界的形狀——symlink、hard link或目錄含額外內容——MUST在首次write前fail closed。legacy receipt migration只驗證舊schema實際記載的path與digest，MUST NOT以舊schema未記載的mode作為migration gate；managed skill的mode由本次transaction依contract mode正規化。

Fresh、legacy adoption與known-old migration MUST使用monotonic bootstrap。read-only preflight後，installer以`O_CREAT|O_EXCL`建立project-root lock、立即取得exclusive lock，並以`fstat`與pathname no-follow lookup重驗相同device/inode；遇到`EEXIST`的並發installer MUST開啟現存lock、等待exclusive lock、重驗pathname/FD identity後重新分類。Stable lock一旦建立 MUST NOT unlink或rename；stable launcher一旦atomic發佈亦 MUST NOT unlink或rename。failure只回滾replaceable runtime、skills、config、guidance、target版控排除設定與receipt，保留canonical `lock-only`或`lock+launcher` prefix；下一次installer MUST在同一lock inode上恢復。launcher-without-lock、bootstrap drift、unknown partial state或pathname/FD mismatch MUST fail closed。Existing current/upgrade/force/batch MUST持有同一FD到transaction/rollback完成。新receipt MUST最後發佈並從target `fstat`產生stable identity records。Journal recovery會改變target state，因此installer MUST在recovery之後才定案installation inputs的target snapshot、legacy candidate plan與版控排除設定plan；Journal的存在偵測 MUST在read-only preflight內完成且 MUST早於版本比較的`newer` early return；該偵測 MUST為純讀取，MUST NOT持鎖，也 MUST NOT解讀target config，並 MUST以no-follow的`lstat`判定形狀——`JOURNAL_PATH`非regular file（含symlink）時 MUST以execution error fail closed，MUST NOT靜默視為無journal。恢復 MUST緊接在`newer` early return之後，且 MUST早於全部三個提前返回的分類分支：`legacy receipt drift`、`receipt-less Cash skill inventory is partial`與`managed target drift`；未完成journal存在時，installer MUST NOT先以其中任何一個返回而略過恢復，即使半發布bytes落在receipt-managed path亦然，且該恢復 MUST NOT要求`--force`。journal的schema version不被本bundle辨識時 MUST以execution error fail closed，且diagnostic MUST指出需要版本相符或更新的installer；`newer`排除的判準是receipt版本，而receipt是transaction的最後一筆operation，因此較新bundle在publishing階段的崩潰不會被`newer`排除，跨版本journal MUST由此條而非`newer`排除來處理。被分類為`newer`的target MUST維持零寫入返回且 MUST NOT執行recovery，其journal留待版本相符或更新的installer處理。非dry-run、target未分類為`newer`且偵測到journal時，installer MUST先執行既有的launcher-without-lock檢查，再取得既存stable lock後才執行recovery；該次取鎖 MUST NOT建立不存在的lock，journal存在而stable lock不存在 MUST fail closed，MUST NOT以`O_CREAT|O_EXCL`建立新的lock inode。recovery回傳真與回傳偽兩個分支 MUST都關閉lock descriptor，同一process在任一時刻 MUST至多持有一個stable lock descriptor。Journal recovery造成的rollback寫入 MUST NOT被視為違反`current`、`newer`或`conflict`分類的零寫入契約：該零寫入契約自recovery完成後的重新分類起適用，因此recovery之後若仍存在與該journal無關的drift，installer MUST回報`Result: conflict`、exit 2，且自重新分類起零寫入。當recovery實際處理並清除journal時，installer MUST釋放stable lock並依recovery後的state重新分類，MUST NOT因recovery自身造成的target變更而以publication前revalidation不一致為由fail closed；外部併發在取得lock之後修改target時，publication前revalidation的既有fail-closed契約 MUST維持不變。該重新分類 MUST在同一lock inode上恢復，且同一份journal MUST NOT再次觸發重新分類；釋放lock的時間窗內由外部併發產生的另一份journal可再觸發一次重新分類，屬既有併發語意。偵測到未完成journal時，installer MUST在早於`newer` early return的偵測點輸出一句與分類無關的通用diagnostic，僅陳述target存在未完成的journal；該句 MUST在dry-run與real run皆出現，且 MUST與最終分類無關而一律出現，包含`current`與`newer`。分類為`newer`時，installer MUST於`newer` early return之前另外輸出一句newer專屬補充，指出該journal需要版本相符或更新的installer才會恢復；該補充 MUST NOT併入通用句，因為通用句在版本比較之前發出，把newer專屬語意寫進去會對絕大多數會被本次執行恢復的target給出錯誤指引。`--dry-run` MUST NOT執行recovery並 MUST維持零寫入。

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

- **WHEN**版本、全部receipt records、modes、guidance、target版控排除設定與legacy state都一致
- **THEN**installer回報`Result: current`且零寫入

- **WHEN**target receipt版本高於source
- **THEN**installer回報`Result: newer`且零寫入

- **WHEN**target managed path相對有效receipt drift且未授權`--force`
- **THEN**installer回報`Result: conflict`、exit 2且零寫入

#### Scenario: Upgrade 與 force 只收斂 managed inventory

- **GIVEN**target版本不高於source且所有preflight通過
- **WHEN**clean upgrade或授權`--force`執行
- **THEN**installer持有existing lock inode，只更新replaceable runtime generation、24個skills、Cash guidance、target版控排除設定、receipt與精確baseline legacy removals
- **AND**stable launcher與lock inode不變
- **AND**除target版控排除設定依`Target 版控排除保護`附加的行以外，其他project-owned bytes維持不變

#### Scenario: Dry run 與 background-free registry

- **WHEN**installer以`--dry-run`、`--list`、`--register`、`--unregister`或`--all`執行
- **THEN**dry-run不產生target或persistent writes，registry modes只執行明確要求的state change
- **AND**不建立daemon、LaunchAgent、scheduled repair、watcher或background process

#### Scenario: Publication failure 可恢復

- **GIVEN**全部preflight成功且第N個publication失敗
- **WHEN**installer進入failure handling
- **THEN**它依transaction journal回滾已發布managed paths
- **AND**rollback失敗時保留journal、回報exit 1並阻斷下一次mutation直到recovery完成

#### Scenario: Crash 後首次執行即完成恢復

- **GIVEN**前一次installer在publishing階段中止，target留有未完成的transaction journal且部分managed paths帶有已發布bytes
- **WHEN**下一次非dry-run installer在同一lock inode上執行
- **THEN**installer完成journal rollback、依recovery後的target state重新分類，並在同一次執行內完成該安裝
- **AND**它 MUST NOT以installation inputs在取得lock後改變為由失敗，亦 MUST NOT要求第二次執行才能完成恢復
- **AND**無並發installer介入、且recovery之後不存在與該journal無關的drift時，該次執行回報`update`而非`conflict`，且半發布bytes落在receipt-managed path時亦不需`--force`

#### Scenario: Receipt-less 與 legacy 崩潰同樣先恢復

- **GIVEN**target留有未完成的transaction journal，且其狀態會命中`receipt-less Cash skill inventory is partial`或`legacy receipt drift`其中一個提前返回分支
- **WHEN**下一次非dry-run installer評估該target
- **THEN**installer先完成journal recovery再重新分類，MUST NOT先以該分支返回而略過恢復
- **AND**恢復後的分類依recovery之後的target state決定

#### Scenario: Newer target 帶未完成 journal 仍零寫入

- **GIVEN**target的receipt版本高於incoming bundle，且留有未完成的transaction journal
- **WHEN**較舊的installer評估該target
- **THEN**installer回報`newer`且零寫入
- **AND**MUST NOT對該journal執行recovery，MUST NOT因其schema不被本bundle辨識而失敗
- **AND**通用diagnostic指出該target存在未完成的journal，且另有一句newer專屬補充指出需版本相符或更新的installer才會恢復

#### Scenario: Journal 存在而 stable lock 不存在則 fail closed

- **GIVEN**target留有未完成的transaction journal，但`.cash-workspace.lock`不存在
- **WHEN**installer執行恢復前置階段
- **THEN**installer以execution error fail closed
- **AND**MUST NOT以`O_CREAT|O_EXCL`建立新的lock inode而靜默修復該狀態

#### Scenario: Dry run 遇未完成 journal 不恢復但明示

- **GIVEN**target留有未完成的transaction journal
- **WHEN**installer以`--dry-run`評估該target
- **THEN**installer維持零寫入且不執行recovery
- **AND**diagnostic指出該target存在未完成的journal

#### Scenario: 版控排除設定 plan 取自 recovery 之後

- **GIVEN**中止的transaction其published operations包含target的版控排除設定寫入
- **WHEN**下一次installer完成journal recovery
- **THEN**版控排除設定的寫入plan由recovery之後的no-follow snapshot導出
- **AND**installer MUST NOT以recovery之前的snapshot內容覆寫該檔

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
source: harden-installer-mode-and-recovery
updated: 2026-07-25
code:
  - .cash-skills/lib/cash_cli/installer.py
  - scripts/cash-skills/tests/skill-checks.fish
  - scripts/cash-skills/tests/test_installer_runtime.py
tests:
  - scripts/cash-skills/tests/test_bundle_version_history.py
  - scripts/cash-skills/tests/test_installer_runtime.py
-->

### Requirement: Cash guidance deployment

Installer SHALL從source `AGENTS.md`與`CLAUDE.md`各擷取唯一、完整且no-follow snapshot的Cash block。對非`newer`、非`conflict`target，它 MUST建立或更新對應Cash block、移除一個合法legacy Spectra block、逐byte保留managed spans外內容與既有mode，並與runtime/skills/receipt共用transaction。Marker孤立、反序、重複、巢狀、非獨立行、post-preflight bytes/identity drift或parent swap MUST在publication前fail closed。

Managed marker的可接受形式 MUST為`<!-- `加marker名稱加`:`加`START`或`END`，其後可選一段以單一空白起始、不含`<`、`>`、CR與LF的字尾，再接` -->`。該字尾容忍 MUST對`CASH`與`SPECTRA`兩個名稱、`START`與`END`兩種種類一致適用——marker定位對名稱與種類泛化，只容忍其中一側會在另一側出現字尾時以完全相同的方式使整個target fail closed。字尾**內容** MUST NOT被解析、比較或用於marker定位的任何決策，且 MUST NOT放寬孤立、反序、重複、巢狀、非獨立行任一項判定。此限定僅及於marker定位；source側以字尾之有無為判準的禁令見下文，不受本段拘束。

字尾內同時排除`<`與`>` MUST維持，使字尾無法跨越註解的任一側界定符吞噬鄰接內容。行界的排除 MUST同時涵蓋CR與LF而非僅LF——只排除LF時，CR-only行界之後的project-owned bytes會被當作字尾而納入managed span，並在遷移時隨該span一併被替換或移除。排除`>`防止字尾越過結尾符號吞掉後續內容；排除`<`防止字尾向前吞掉同行稍前的另一個註解起始序列——後者會把原本落在managed span之外、受逐byte保留保護的bytes捲入span而在遷移時被刪除。

一份guidance中某個名稱的全部marker都獨立成行且都不帶字尾時，字尾容忍 MUST NOT改變該名稱所定位出的span起訖。此等價保證是逐檔而非逐marker：定位的判定建立在整份資料的匹配計數上，因此同一份檔案裡若另有一個帶字尾的同名marker，計數會改變而使原本可定位的那一對落入重複判定，該情形不在本保證範圍內。marker之前同行若有普通文字（不含註解起始序列）亦不在範圍內，理由是行首錨定不在本requirement的規範範圍。marker之前同行若是另一個註解起始序列，則由前一段的`<`排除規則處理，span起點仍落在合法marker處，屬本保證涵蓋範圍而非例外。

字尾容忍改變了「哪些bytes會被當作managed marker」。guidance中形似marker的散文或範例，因此會落入以下三個方向之一，三者皆為本requirement接受的結果：由原本被靜默忽略變成被判定為孤立而fail closed；由原本fail closed變成被當作真marker而其內容被替換或移除；以及由原本被忽略而**內容原樣保留**變成被當作真marker而內容被替換或移除。第三個方向 MUST被明確涵蓋而非視為前兩者的特例——它的前後兩次安裝都以相同狀態成功結束、exit code與分類結果皆不變，使用者沒有任何訊號，且`--dry-run`不提供byte-level預覽，因此它是三者中唯一不可被觀察到的資料移除。此列舉 MUST NOT被讀成窮舉。managed span以外的bytes逐byte保留契約在三個方向皆 MUST維持不變。

Source的canonical Cash block其start與end marker MUST NOT帶字尾。理由是source的Cash span會被逐byte當作canonical block寫入每一個target，若source marker帶字尾，該字尾會被散播到全部target；字尾容忍的目的是接納既有target上的legacy形式，不是讓source產出帶字尾的marker。source Cash marker帶字尾時 MUST在首次target write前fail closed。

全部marker相關的失敗診斷 MUST具名出問題的guidance檔案，且 MUST可區分該檔案屬source bundle或屬target，使失敗可被自助定位；source與target的guidance相對路徑取值相同，僅具名路徑不足以消歧，此義務涵蓋非獨立行、重複、孤立、反序、巢狀與source字尾全部判定。各既有診斷 MUST維持其既有語意，僅附加該標籤。

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

#### Scenario: 帶字尾的 marker 被辨識並收斂

- **GIVEN**target guidance中`CASH`或`SPECTRA`的start或end marker帶有一段符合本requirement所定義之可接受形式的字尾
- **WHEN**installer處理該target
- **THEN**installer辨識該marker並依既有收斂規則處理
- **AND**該target MUST NOT因該字尾而以marker重複、孤立或任何其他guidance理由fail closed
- **AND**字尾含`<`或`>`者不屬本scenario：僅一側如此時由`帶字尾 marker 違反判定仍 fail closed`涵蓋，兩側皆如此時該形式不被辨識為managed marker，由`Missing、Spectra-only 與 mixed guidance 收斂`的「沒有managed block」分支涵蓋
- **AND**同一份guidance中該名稱另有其他marker而使匹配計數落入重複或孤立判定者亦不屬本scenario，由`帶字尾 marker 違反判定仍 fail closed`涵蓋；此限定與本requirement等價保證段的逐檔判準一致

##### Example: 帶版本字尾的 legacy start marker

- **GIVEN**target guidance首行為`<!-- SPECTRA:START v1.0.2 -->`且檔案另含一個合法Cash block
- **WHEN**installer處理該target
- **THEN**legacy block被移除、Cash block被更新為canonical內容
- **AND**兩個managed span以外的bytes與檔案mode逐byte不變

##### Example: 帶字尾的 Cash marker 自我修復

- **GIVEN**target guidance的`CASH:START` marker帶有字尾
- **WHEN**installer處理該target
- **THEN**該span被替換為source的canonical Cash block，其marker不帶字尾
- **AND**installer MUST NOT因該字尾fail closed

#### Scenario: 字尾容忍不改變獨立成行無字尾 marker 的 span

- **GIVEN**guidance中`CASH`的全部marker都獨立成行且都不帶字尾
- **WHEN**installer定位該managed span
- **THEN**span起訖與字尾容忍導入前逐byte相同

#### Scenario: 帶字尾 marker 違反判定仍 fail closed

- **WHEN**帶字尾的marker孤立、反序、重複、巢狀或非獨立行
- **THEN**installer在首次target write前exit 1
- **AND**`--force`不繞過失敗

#### Scenario: 字尾不跨越註解界定符

- **GIVEN**guidance的某一行在合法Cash start marker之前另有一個註解起始序列，亦即該marker的前綴在同一行出現兩次而只由行尾單一個結尾符號收束
- **WHEN**installer定位該managed span
- **THEN**span起點落在合法marker處，與字尾容忍導入前相同
- **AND**該行稍前的bytes MUST維持在managed span之外，MUST NOT在遷移時被刪除

#### Scenario: 全部 marker 失敗診斷具名檔案

- **WHEN**任一guidance marker判定導致installer失敗
- **THEN**該診斷包含出問題的guidance檔案的project-root相對路徑
- **AND**該診斷可區分出問題的是source bundle的guidance或target的guidance
- **AND**非獨立行、重複、孤立與反序各既有診斷維持既有語意

##### Example: source 側的 marker 失敗具名

- **GIVEN**source的`AGENTS.md`其`CASH` marker違反非獨立行、重複、孤立或反序任一判定
- **WHEN**installer擷取canonical Cash block
- **THEN**installer在首次target write前exit 1
- **AND**該診斷同時包含source限定詞與相對路徑，與target側同一判定的診斷可區分

#### Scenario: Source canonical marker 不得帶字尾

- **GIVEN**source的`AGENTS.md`或`CLAUDE.md`其Cash start或end marker帶有字尾
- **WHEN**installer擷取canonical Cash block
- **THEN**installer在首次target write前exit 1
- **AND**該字尾 MUST NOT被寫入任何target

<!-- @trace
source: tolerate-versioned-legacy-guidance-marker
updated: 2026-07-25
code:
tests:
  - scripts/cash-skills/tests/skill-checks.fish
-->

### Requirement: Installer 與 legacy cleanup filesystem boundaries

Installer SHALL canonicalize既有target；一般direct、registry與batch模式 MUST拒絕空值、`/`、source repository、symlink target、root外destination及symlink/hard-link ownership不明的managed boundary。唯一source repository例外是明確`--self`模式，且該模式只能在已驗證source root內發布receipt。Publisher MUST以held no-follow parent directory handle、exclusive relative temporary basename、snapshot revalidation、明確mode與transaction journal完成publication/cleanup。Registry與`uninstall-spectra-plus-repair.fish` MUST保留既有HOME absolute/non-root、symlink及service identity fail-closed contract。Mode參數的分派 MUST依「該參數是否被提供」判定，MUST NOT依參數值的truthiness判定；空字串的`--target`、`--register`或`--unregister` MUST被視為該mode的invalid value並以caller-input error失敗，MUST NOT被重新解讀為batch mode或任何其他mode。該空值拒絕 MUST早於registry的讀取，也 MUST早於與mode相依的`--dry-run`及`--force`相容性檢查：空字串mode參數 MUST NOT讀取registry、MUST NOT對任何已註冊project執行安裝；即使registry或HOME本身不合法，diagnostic MUST指出mode參數值無效而非registry或HOME錯誤；空字串mode參數與`--dry-run`或`--force`併用時，diagnostic MUST指出該值無效而非指出缺少mode參數。與mode相依的`--dry-run`及`--force`相容性檢查本身 MUST對帶值mode參數使用同一存在性判準，對`store_true`的boolean mode flag則 MUST維持既有判準，使既有的caller-input守衛不因此失效。

#### Scenario: Target 與 HOME boundary fail closed

- **WHEN**target、managed parent、destination、receipt、config、guidance或HOME/registry boundary不安全
- **THEN**installer或cleanup在首次write與`launchctl`前失敗
- **AND**不讀寫root外target

#### Scenario: 空字串 mode 參數不得被重新解讀

- **GIVEN**registry至少已註冊一個project
- **WHEN**installer以`--target`、`--register`或`--unregister`接收空字串
- **THEN**installer以caller-input error失敗且零寫入
- **AND**它 MUST NOT讀取registry，也 MUST NOT對任何已註冊project執行安裝

#### Scenario: 空字串 mode 參數的診斷優先於 registry 錯誤

- **GIVEN**registry本身不合法而無法通過canonical檢查
- **WHEN**installer以`--register`或`--unregister`接收空字串
- **THEN**diagnostic指出mode參數值無效
- **AND**diagnostic MUST NOT指出registry或HOME錯誤

#### Scenario: 空字串 mode 參數與相容性 flag 併用的診斷

- **WHEN**installer以`--target`、`--register`或`--unregister`接收空字串，並同時帶`--dry-run`或`--force`
- **THEN**三者在兩種flag下的diagnostic皆指出該mode參數值無效
- **AND**diagnostic MUST NOT指出缺少mode參數，即使該mode參數不在該flag相容性檢查的運算元之列

#### Scenario: Boolean mode flag 的相容性守衛不受影響

- **WHEN**installer以`--list --dry-run`或以`--register <project> --force`執行
- **THEN**installer維持既有的caller-input error失敗且零寫入
- **AND**MUST NOT因mode分派改用存在性判準而改為接受該組合

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
source: harden-installer-mode-and-recovery
updated: 2026-07-25
code:
  - .cash-skills/lib/cash_cli/installer.py
  - scripts/cash-skills/tests/skill-checks.fish
  - scripts/cash-skills/tests/test_installer_runtime.py
tests:
  - scripts/cash-skills/tests/test_bundle_version_history.py
  - scripts/cash-skills/tests/test_installer_runtime.py
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

### Requirement: Target 版控排除保護

Installer 的direct、registry與batch模式 SHALL在preflight通過後、於同一transaction內確保target根目錄的`.gitignore`含有`.cash-skills/receipt.tsv`、`.cash-skills/state/`與`__pycache__/`三項規則。此保護存在的理由是receipt依既有contract記錄target-specific `st_dev/st_ino`，一旦被納入版控，任何inode不同的取得方式都會使該target的launcher以`receipt_invalid` fail closed。source-only `--self`不在本requirement範圍內。

判定 MUST在byte層進行：以`b"\n"`切行並逐行比對bytes，MUST NOT要求UTF-8。比對 MUST容忍行尾的`\r`，使CRLF檔案中的既有規則被正確辨識。判定 MUST為逐行精確比對，MUST NOT以前綴、萬用字元或路徑包含關係推論既有規則已涵蓋。

缺少的規則 MUST只附加至檔案尾端，附加時 MUST沿用檔案既有的行終止符；既有內容不含任何行終止符時 MUST使用`\n`；既有內容 MUST逐byte保留，MUST NOT重排、去重或刪除任何既有行。既有內容非空且未以行終止符結尾時 MUST先補一個行終止符再附加，此為逐byte保留的唯一例外；既有內容為空時 MUST NOT補行終止符。

`.gitignore`不存在時 MUST以`0644`建立並納入同一transaction；既有檔案的mode MUST保留。既有檔案為symlink、非regular file、hard link或無法安全讀取時 MUST在首次target write前以execution error失敗，且`--force` MUST NOT繞過。

`.gitignore` MUST納入installer的installation inputs：判定與寫入內容 MUST由同一份no-follow snapshot導出，該snapshot MUST納入post-lock與publication前的revalidation。post-lock revalidation不一致時 MUST重新分類；publication前revalidation不一致時 MUST以execution error fail closed。兩者皆 MUST NOT覆寫外部修改。

分類為`newer`或`conflict`的target MUST維持既有零寫入契約，本保護 MUST NOT對其寫入。三項規則皆已存在時該項目 MUST零寫入。`--dry-run` MUST執行相同判定與驗證並零寫入。transaction失敗時，新建或附加的`.gitignore` MUST依既有rollback契約還原。

Installer MUST以唯讀version-control index查詢偵測target的`.cash-skills/receipt.tsv`是否已被納入版控，MUST NOT以ignore查詢判定——本requirement生效後所有target的`.gitignore`都會命中該規則，ignore查詢對已追蹤檔案會給出相反答案。為真時 MUST輸出指出該狀態與建議動作的diagnostic至stderr，且 MUST NOT依target的結果分類決定是否輸出。查詢失敗時 MUST靜默略過該diagnostic。此diagnostic MUST NOT修改使用者的版控索引，且 MUST NOT改變target的結果分類或exit code。

#### Scenario: 全新 target 取得三項排除規則

- **GIVEN** target沒有`.gitignore`
- **WHEN** installer完成部署
- **THEN** `.gitignore`以`0644`建立且含`.cash-skills/receipt.tsv`、`.cash-skills/state/`與`__pycache__/`
- **AND** receipt不會被版控收錄

#### Scenario: 既有內容逐 byte 保留

- **GIVEN** target的`.gitignore`含使用者自訂規則且缺少其中一項所需規則
- **WHEN** installer完成部署
- **THEN** 既有內容逐byte不變且mode保留
- **AND** 只在檔案尾端多出缺少的那一項規則

#### Scenario: 既有內容無尾端行終止符

- **GIVEN** target的`.gitignore`以`node_modules`結尾且該行沒有行終止符
- **WHEN** installer附加缺少的規則
- **THEN** `node_modules`仍為完整且獨立的一行
- **AND** 附加的規則各自成行，不與既有內容黏連

#### Scenario: 規則齊備時零寫入

- **GIVEN** target的`.gitignore`已含全部三項規則且其餘managed inventory無變更
- **WHEN** installer執行
- **THEN** `.gitignore`零寫入
- **AND** target回報`current`

#### Scenario: 不安全的 .gitignore fail closed

- **WHEN** target的`.gitignore`為symlink、非regular file、hard link或無法安全讀取
- **THEN** installer在首次target write前以execution error失敗
- **AND** 帶`--force`同樣失敗且零寫入

#### Scenario: 編碼與行終止符不影響分類

- **GIVEN** target的`.gitignore`為CRLF或含非UTF-8的pathname bytes
- **WHEN** installer執行
- **THEN** 既有規則被正確判定
- **AND** target不因編碼或行終止符被分類為`failed`

#### Scenario: 兩個檢查點的外部修改處置

- **GIVEN** installer取得lock後、組裝transaction前有外部程序修改了target的`.gitignore`
- **WHEN** post-lock revalidation執行
- **THEN** installer重新分類該target
- **AND** 外部修改不被覆寫

- **GIVEN** installer組裝transaction後、publication前有外部程序修改了target的`.gitignore`
- **WHEN** publication前revalidation執行
- **THEN** installer以execution error fail closed
- **AND** 外部修改不被覆寫

#### Scenario: 已納入版控的 receipt 只回報不修改

- **GIVEN** target的`.cash-skills/receipt.tsv`已被納入版控
- **WHEN** installer執行
- **THEN** stderr輸出指出該狀態與建議動作的diagnostic
- **AND** 使用者的版控索引維持不變
- **AND** target的結果分類與exit code不因此改變

##### Example: 規則判定

| 既有行 | 對`.cash-skills/state/`的判定 |
| --- | --- |
| `.cash-skills/state/` | 已滿足 |
| `.cash-skills/state/` 後接 `\r` | 已滿足 |
| `.cash-skills/` | 不視為已滿足 |
| `.cash-skills/state` | 不視為已滿足 |
| `/.cash-skills/state/` | 不視為已滿足 |
| `*.tsv` | 不視為已滿足 |

<!-- @trace
source: guard-target-receipt-version-control
updated: 2026-07-24
code:
  - .cash-skills/lib/cash_cli/installer.py
  - scripts/cash-skills/tests/skill-checks.fish
  - scripts/cash-skills/tests/test_installer_runtime.py
tests:
  - scripts/cash-skills/tests/skill-checks.fish
  - scripts/cash-skills/tests/test_installer_runtime.py
-->

### Requirement: Drift 建議使用 variant 中立的 skill 名稱

本 requirement 細化 `Deterministic validation、analysis 與 drift` 對 `primary_recommendation` 的既有規定，只約束其字串形式，不重複定義該欄位的存在性或型別。

`drift` 的 `primary_recommendation` SHALL 只輸出 Cash skill 名稱與 change 名稱，MUST NOT 內嵌任一 agent variant 的 invocation 前綴字元。具體而言該欄位值 MUST NOT 含 `$` 字元，也 MUST NOT 含 `/` 字元。severity 到 skill 名稱的對應 MUST 維持既有語意：`light` 對應 `cash-apply`，`medium` 與 `heavy` 對應 `cash-ingest`。human output 的 primary recommendation 行 MUST 從相同欄位 render，MUST NOT 自行補上前綴。

此 requirement 只約束 CLI 的輸出；消費該欄位的 skill 文件之義務由 `cash-skill-workflows` 的對應 requirement 規範。

此 requirement 的理由是 CLI runtime 為兩個 variant 共用，任何 variant 專屬的 invocation 字面值都會使其中一個 variant 收到錯誤的指令建議。

#### Scenario: JSON 與 human output 都不含 variant 前綴

- **GIVEN** 一個 total score 落在 `light` 區間的 change
- **WHEN** 執行 `drift <name> --json`
- **THEN** `primary_recommendation` 為 `cash-apply <name>`
- **AND** 該字串不含 `$` 也不含 `/`
- **WHEN** 對相同 change 執行不帶 `--json` 的 `drift <name>`
- **THEN** 報告的 primary recommendation 行呈現相同的不含前綴字串

#### Scenario: 三個 severity 分支各自對應正確的 skill

- **GIVEN** 一個 total score 落在 `light` 區間的 change
- **WHEN** 執行 `drift <name> --json`
- **THEN** `primary_recommendation` 為 `cash-apply <name>`
- **GIVEN** 一個 total score 落在 `medium` 區間的 change
- **WHEN** 執行 `drift <name> --json`
- **THEN** `primary_recommendation` 為 `cash-ingest <name>`
- **GIVEN** 一個 total score 落在 `heavy` 區間的 change
- **WHEN** 執行 `drift <name> --json`
- **THEN** `primary_recommendation` 為 `cash-ingest <name>`

##### Example: severity 對應

| severity | primary_recommendation |
| --- | --- |
| `light` | `cash-apply <name>` |
| `medium` | `cash-ingest <name>` |
| `heavy` | `cash-ingest <name>` |

<!-- @trace
source: align-cli-skill-contracts
updated: 2026-07-25
code:
  - .agents/skills/cash-analyze/SKILL.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-discuss/SKILL.md
  - .agents/skills/cash-drift/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - .agents/skills/cash-propose/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .cash-skills/lib/cash_cli/commands/drift.py
  - .cash-skills/lib/cash_cli/commands/search.py
  - .cash-skills/lib/cash_cli/resources.py
  - .cash-skills/lib/cash_cli/workspace.py
  - .claude/skills/cash-drift/SKILL.md
  - .claude/skills/cash-propose/SKILL.md
  - scripts/cash-cli/tests/test_analyze_drift.py
  - scripts/cash-cli/tests/test_graph_instructions.py
  - scripts/cash-cli/tests/test_lexical_search.py
  - scripts/cash-skills/tests/skill-checks.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/cash-skills/variant-parity/cash-discuss.diff
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/cash-skills/variant-parity/cash-verify.diff
tests:
  - scripts/cash-cli/tests/cli-checks.fish
  - scripts/cash-cli/tests/test_analyze_drift.py
  - scripts/cash-cli/tests/test_graph_instructions.py
  - scripts/cash-cli/tests/test_lexical_search.py
  - scripts/cash-cli/tests/test_negative_atomicity.py
  - scripts/cash-skills/tests/skill-checks.fish
-->

### Requirement: Proposal 模板段落集合由 Cash-owned resources 定義

本 requirement 細化 `Artifact graph 與 instructions 使用單一來源` 對 proposal template 的既有規定，列舉該 template 必須承載的段落與子結構，不重複定義 template 的來源歸屬。

`instructions proposal --change <name> --json` 回傳的 `template` SHALL 是 proposal 段落結構的唯一定義來源，且 MUST 依序包含 `## Summary`、`## Motivation`、`## Proposed Solution`、`## Non-Goals`、`## Alternatives Considered`、`## Capabilities`、`## Impact` 七個段落標題。

該 `template` MUST 同時承載兩組子結構：`## Capabilities` 之下 MUST 含 `### New Capabilities` 與 `### Modified Capabilities`；`## Impact` 之下 MUST 含 `- Affected specs:` 與 `- Affected code:`，且後者之下 MUST 含 `New`、`Modified`、`Removed` 三個標籤列，每個標籤後接冒號。此要求存在的理由是 `## Impact` 標題是 spec 合併產生 trace 時界定區段的依據，而三個標籤列是 impact 粒度提示計數 affected-code 條目的依據；兩者在形狀消失時皆為靜默降級而非報錯。

該 `template` 所含的段落標題 MUST 是 `validate` 對 `proposal.md` 所要求標題的超集合，使依該 `template` 產出的 proposal 必然滿足必要標題檢查。必要標題集合本身 MUST 維持只在 validation 層定義一次，MUST NOT 在 resources 層重複定義。

#### Scenario: 模板涵蓋全部必要標題

- **WHEN** 讀取 `instructions proposal --change <name> --json` 的 `template`
- **THEN** 該字串含有 `## Summary`、`## Capabilities` 與 `## Impact`
- **AND** 依該 `template` 填寫且未刪除任何段落標題的 proposal 通過 `validate <name>`

#### Scenario: 模板承載下游依賴的子結構

- **WHEN** 讀取 `instructions proposal --change <name> --json` 的 `template`
- **THEN** 該字串含有 `### New Capabilities` 與 `### Modified Capabilities`
- **AND** 該字串含有 `- Affected specs:` 與 `- Affected code:`
- **AND** 該字串在 `- Affected code:` 之下含有 `New`、`Modified` 與 `Removed` 三個標籤列，每個標籤後接冒號

#### Scenario: 模板段落順序穩定

- **WHEN** 對同一個 change 兩次讀取 `instructions proposal --change <name> --json`
- **THEN** 兩次的 `template` 逐位元組相同
- **AND** 七個段落標題的出現順序與本 requirement 列舉的順序一致

<!-- @trace
source: align-cli-skill-contracts
updated: 2026-07-25
code:
  - .agents/skills/cash-analyze/SKILL.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-discuss/SKILL.md
  - .agents/skills/cash-drift/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - .agents/skills/cash-propose/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .cash-skills/lib/cash_cli/commands/drift.py
  - .cash-skills/lib/cash_cli/commands/search.py
  - .cash-skills/lib/cash_cli/resources.py
  - .cash-skills/lib/cash_cli/workspace.py
  - .claude/skills/cash-drift/SKILL.md
  - .claude/skills/cash-propose/SKILL.md
  - scripts/cash-cli/tests/test_analyze_drift.py
  - scripts/cash-cli/tests/test_graph_instructions.py
  - scripts/cash-cli/tests/test_lexical_search.py
  - scripts/cash-skills/tests/skill-checks.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/cash-skills/variant-parity/cash-discuss.diff
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/cash-skills/variant-parity/cash-verify.diff
tests:
  - scripts/cash-cli/tests/cli-checks.fish
  - scripts/cash-cli/tests/test_analyze_drift.py
  - scripts/cash-cli/tests/test_graph_instructions.py
  - scripts/cash-cli/tests/test_lexical_search.py
  - scripts/cash-cli/tests/test_negative_atomicity.py
  - scripts/cash-skills/tests/skill-checks.fish
-->

### Requirement: Installer fault-injection hooks 治理

Installer的fault-injection hooks SHALL只在單一顯式開關之下生效。該開關為環境變數`CASH_INSTALL_TEST_HOOKS`，其值恰為`1`時hooks生效。開關未設定或值不為`1`時，installer MUST NOT讀取任何其他`CASH_INSTALL_*`變數，且分類、發布、diagnostic與exit code MUST與這些變數皆不存在時完全相同。該開關是縮小blast radius的機制，MUST NOT被視為authorization boundary：能設定其他hook變數的caller一律也能設定它。

已啟用hooks的設定驗證——hold path形狀、兩個hold path互異、release檔當下不存在、失敗注入序號可解析性——MUST在任何`acquire_lock`呼叫之前的preflight完成，使這些設定錯誤在首次target write之前fail closed；hold的等待點 MUST維持在既有位置。有一類形狀在preflight無法判定：release檔在preflight之後、等待點進入之前才出現，或到等待點才被換成symlink；這類 MUST在該hook的等待點以execution error中止、MUST NOT被當成解除訊號、MUST NOT提交任何transaction operation，但因等待點在`acquire_lock`之後，這類 MUST NOT主張在首次target write之前失敗。Hold協定 MUST受與其他installer寫入相同等級的identity約束：hold path MUST為absolute path，其parent MUST為既存且非symlink的directory；ready檔 MUST以exclusive、no-follow的建立語意產生；release檔的不存在性 MUST在preflight與各hook自身的等待點進入時各驗證一次；等待點進入時已存在的release檔 MUST以execution error中止，MUST NOT被當成解除訊號。release檔 MUST只在其為非symlink的regular file時被視為解除訊號。既存檔案或symlink MUST fail closed，MUST NOT被覆寫、截斷或被跟隨。Hold path MUST NOT被強制收斂到target之內，因為它是caller自有的協調通道，寫入target會把協調狀態帶進被安裝的project。at-most-once的記帳鍵 MUST為hook本身而非hold path：`CASH_INSTALL_HOLD_FILE`與`CASH_INSTALL_PUBLICATION_HOLD_FILE`是兩個獨立的hook，各自記帳互不影響。兩個hook同時啟用時其hold path MUST互異，相同時 MUST在preflight以execution error fail closed；記帳獨立不足以讓兩者共用一條路徑，因為第二個hook進入等待點時必然同時撞上「ready檔已存在」與「release檔在等待點已存在」兩條fail-closed規則。每個hold hook在單一process內 MUST至多等待一次。該hook已等待過之後，同一process內任何後續的installation attempt——包含重新分類造成的重新進入，以及batch mode對後續target的安裝——MUST完全跳過該hook，包含其等待與preflight的全部hold檔存在性檢查；ready檔與release檔皆在免除範圍內，installer MUST NOT因本process前一輪建立或解除的hold檔而失敗。路徑形狀檢查 MUST NOT被免除。失敗注入序號無法解析為integer時 MUST以execution error失敗，MUST NOT以未捕捉例外離開process。`CASH_INSTALL_CRASH_AFTER_COMMIT` MUST自實作移除，且 MUST NOT在實作、測試或使用者文件中作為可生效的environment variable name被讀取或設定；本requirement與change artifacts對該名稱的敘述性引用不在此限。

#### Scenario: 開關關閉時 hooks 完全無效

- **GIVEN**所有其他`CASH_INSTALL_*`變數皆已設定為會改變行為的值
- **WHEN**`CASH_INSTALL_TEST_HOOKS`未設定或其值不為`1`
- **THEN**installer的分類、發布與exit code與這些變數皆不存在時完全相同
- **AND**installer MUST NOT建立任何hold或ready檔

#### Scenario: Preflight 可判定的 hold 設定錯誤 fail closed

- **GIVEN**hooks開關已開啟，且該hold hook在本次process尚未等待過
- **WHEN**hold path不是absolute path、其parent不存在或為symlink、ready檔已存在、release檔在preflight已存在，或兩個hook的hold path相同
- **THEN**installer在首次target write前以execution error失敗
- **AND**既有檔案內容與symlink目標 MUST NOT被寫入或被截斷

#### Scenario: 等待點才可判定的 hold 形狀在等待點中止

- **GIVEN**hooks開關已開啟、preflight已通過，且該hold hook在本次process尚未等待過
- **WHEN**ready檔在preflight之後、該hook的等待點進入之前才出現，或release檔在preflight當下不存在而於等待點進入之前才出現，或該後出現的release檔為symlink
- **THEN**installer在該hook的等待點以execution error中止，且該release檔 MUST NOT被當成解除訊號
- **AND**該次執行 MUST NOT提交任何transaction operation，既有檔案內容與symlink目標 MUST NOT被寫入或被截斷

#### Scenario: 後續 installation attempt 不因自身 hold 檔而失敗

- **GIVEN**hooks開關已開啟且hold hook已在本次process等待過一次
- **WHEN**installer因重新分類而重新進入，或batch mode繼續安裝下一個已註冊target
- **THEN**installer MUST NOT再次等待該hold
- **AND**MUST NOT因本process前一輪建立的ready檔或解除等待所用的release檔而以execution error失敗

#### Scenario: 兩個 hold hook 各自記帳

- **GIVEN**hooks開關已開啟，兩個hold hook皆已設定且設在互異的hold path
- **WHEN**`CASH_INSTALL_HOLD_FILE`的hook已在本次process等待過一次，而`CASH_INSTALL_PUBLICATION_HOLD_FILE`的hook尚未等待過
- **THEN**publication hook仍正常等待，MUST NOT因另一個hook已等待過而被略過

#### Scenario: 失敗注入序號無法解析

- **GIVEN**hooks開關已開啟
- **WHEN**失敗注入序號不是可解析為integer的值
- **THEN**installer在首次target write前以execution error失敗
- **AND**MUST NOT以未捕捉例外離開process

<!-- @trace
source: harden-installer-mode-and-recovery
updated: 2026-07-25
code:
  - .cash-skills/lib/cash_cli/installer.py
  - scripts/cash-skills/tests/skill-checks.fish
  - scripts/cash-skills/tests/test_installer_runtime.py
tests:
  - scripts/cash-skills/tests/test_bundle_version_history.py
  - scripts/cash-skills/tests/test_installer_runtime.py
-->

### Requirement: Installer 進入點 interpreter 解析與 process 邊界

`install-cash-skills.fish` SHALL以自身已解析的absolute path決定source root，並SHALL選用候選清單中第一個通過最低版本探測的interpreter。候選清單 MUST依序為泛用名稱`python3`、`python`，其後才是版本化名稱`python3.14`、`python3.13`、`python3.12`、`python3.11`，使系統預設interpreter版本過舊但已安裝合格版本化interpreter的環境仍可安裝。泛用名稱 MUST排在版本化名稱之前：版本化名稱優先會改變既有可用環境的選擇結果，繞過該環境的toolchain shim，而本requirement只要求在泛用名稱不合格時提供備援。候選清單中沒有任何interpreter通過探測時 MUST以execution error失敗且零寫入。進入點 MUST以`exec`交棒給選定的interpreter，因此installer的Python process MUST NOT保留由該進入點建立的shell parent process，且Python process的exit status MUST直接成為該次invocation的exit status。交棒 MUST停用user site directory，MUST維持既有的library path注入與cwd隔離，且進入點 MUST NOT保留未被讀取的變數。

#### Scenario: 系統預設 interpreter 過舊但存在合格版本化 interpreter

- **GIVEN**泛用名稱`python3`與`python`皆解析到低於3.11的interpreter或不存在，而版本化名稱`python3.12`存在且滿足最低版本
- **WHEN**執行進入點
- **THEN**進入點選用`python3.12`並完成該次invocation
- **AND**MUST NOT以找不到合格interpreter為由失敗

#### Scenario: 泛用名稱合格時選擇結果不改變

- **GIVEN**泛用名稱`python3`解析到滿足最低版本的interpreter，且另有版本更新的版本化名稱可用
- **WHEN**執行進入點
- **THEN**進入點選用`python3`解析到的interpreter
- **AND**MUST NOT因存在版本更新的版本化名稱而改選它

#### Scenario: 無合格 interpreter

- **WHEN**候選清單中沒有任何interpreter通過最低版本探測
- **THEN**進入點以execution error失敗且零寫入

#### Scenario: 交棒不保留 shell parent 且停用 user site

- **WHEN**進入點交棒給選定的interpreter
- **THEN**installer的Python process的parent MUST為啟動該進入點的process，而非進入點自身
- **AND**該Python process MUST以停用user site directory的方式啟動，且既有library path注入 MUST仍然生效

<!-- @trace
source: harden-installer-mode-and-recovery
updated: 2026-07-25
code:
  - .cash-skills/lib/cash_cli/installer.py
  - scripts/cash-skills/tests/skill-checks.fish
  - scripts/cash-skills/tests/test_installer_runtime.py
tests:
  - scripts/cash-skills/tests/test_bundle_version_history.py
  - scripts/cash-skills/tests/test_installer_runtime.py
-->

### Requirement: Archive manifest 保留 touched 檔案清單

`archive` 寫入 `archive-manifest.json` 時 SHALL 額外記錄 `touched_files` 欄位，其值為封存當下 touched state 的 `files` 陣列，內容與順序逐字沿用該陣列，不另行重新排序或去重。沒有任何追蹤來源檔時，`touched_files` MUST 為空陣列而非省略該欄位。既有的 `touched_digest` 其計算輸入與計算方式 MUST 不變，`version`、`change`、`destination`、`specs_synced`、`delta_digests`、`master_digests` 與 `legacy_cleanup` 的值 MUST 不變。

#### Scenario: 有追蹤來源檔時記錄完整清單

- **GIVEN** change `demo-change` 的 touched state 其 `files` 為兩個來源檔路徑
- **WHEN** 執行 `archive demo-change`
- **THEN** 封存目錄下 `archive-manifest.json` 的 `touched_files` 逐字等於該 `files` 陣列
- **AND** `touched_digest` 等於以封存當下 touched 物件計算的既有結果

#### Scenario: 無追蹤來源檔時為空陣列

- **GIVEN** change `demo-change` 沒有任何 touched state
- **WHEN** 執行 `archive demo-change`
- **THEN** 封存目錄下 `archive-manifest.json` 含 `touched_files` 欄位
- **AND** 該欄位的值為空陣列

#### Scenario: 其他 manifest 欄位不受影響

- **WHEN** 執行 `archive demo-change`
- **THEN** `archive-manifest.json` 的 `version`、`change`、`destination`、`specs_synced`、`delta_digests`、`master_digests` 與 `legacy_cleanup` 與新增 `touched_files` 之前的結果相同

<!-- @trace
source: guard-post-archive-commit-allowlist
updated: 2026-07-25
code:
tests:
  - scripts/cash-cli/tests/cli-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->
