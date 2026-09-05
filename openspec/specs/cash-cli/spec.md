# cash-cli Specification

## Purpose

cash-cli capability.

## Requirements

### Requirement: Project-local Cash CLI runtime

系統 SHALL 在 `.cash-skills/bin/cash` 提供 repository-owned CLI launcher，在 `.cash-skills/lib/cash_cli/` 提供其實作，並在既有project root直接安裝空的`0644` `.cash-workspace.lock`。launcher與lock SHALL為stable bootstrap objects：workspace lock在fresh install後不得以unlink或rename替換其inode；launcher只有在 `受控 launcher bootstrap migration` requirement的bundle version、exact digest transition、exclusive lock與recoverable journal條件全部成立時才可替換，其他source bootstrap bytes drift MUST以unsupported migration失敗。launcher MUST在載入receipt或任何managed Python library前no-follow開啟lock，依`argv`將`new/task/in-progress/touched/park/unpark/sync/archive`直接分類為exclusive mutating families，其他已知families為shared reads；取得正確mode後才依manifest-presence優先序完成portable manifest或receipt中恰一個信任gate並import library，並持有同一FD到process結束。Launcher MUST NOT以shared→exclusive conversion啟動mutation；unknown command取得shared lock後失敗。launcher MUST 使用 Python 3.11+ standard library，MUST 以自身位置解析 library，且 MUST NOT 呼叫、載入或 fallback 到 Spectra binary。Canonical skills MUST先以`git rev-parse --show-toplevel`解析並驗證project root，再使用root下launcher的絕對路徑，因此nested cwd MUST在CLI啟動前獲得正確runtime。manifest-present時的gate、零寫入與verified-source import由 `Portable manifest 啟動信任模式` requirement定義；manifest缺失時既有receipt-only行為不變。

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
source: add-repo-vendored-cash-bundle
updated: 2026-07-29
code:
  - .cash-skills/bin/cash
  - .cash-skills/lib/cash_cli/installer.py
  - .cash-skills/manifest.tsv
  - scripts/cash-skills/tests/skill-checks.fish
  - scripts/cash-skills/tests/test_bundle_version_history.py
  - scripts/cash-skills/tests/test_init_receipt.py
  - scripts/cash-skills/tests/test_installer_runtime.py
tests:
  - scripts/cash-skills/tests/test_init_receipt.py
  - scripts/cash-skills/tests/test_installer_runtime.py
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

CLI SHALL 提供且僅需支援Cash workflows消費的`list`、`status`、`instructions`（含artifact-level、`instructions apply`與`instructions --skill <tdd|test-quality|audit>`三種mode）、`new change`、`new artifact`、`task done`、`in-progress add`、`touched ensure`、`touched record`、`park`、`unpark`、`validate`（含single-change與`validate --all`）、`analyze`、`drift`、`archive`、`sync`與`search`command families。每個呼叫artifact engine的canonical Cash skill MUST 呼叫`.cash-skills/bin/cash`，MUST NOT包含可執行的`spectra`command或`Requires spectra CLI`相容性宣告。

CLI SHALL 另提供不擴張上述command family集合的help表面。第一個argument為`--help`或`-h`時，CLI MUST在launcher完成既有lock取得與manifest-presence所選信任gate驗證之後、進入command dispatch之前輸出help並以exit 0結束；help MUST NOT繞過launcher的信任gate：manifest存在時必須完成portable gate且invalid manifest以`manifest_invalid`失敗，manifest缺失時receipt缺失或無效仍 MUST維持既有的`bootstrap_invalid`／`receipt_invalid`失敗，而非輸出help。help flag不是command，`Project-local Cash CLI runtime`對unknown command的失敗規定僅適用於進入dispatch的token。第一個argument不是help flag時，CLI的dispatch目標、exit code、`error` code與JSON object結構 MUST與未提供該表面時相同。由top-level command dispatch產生的`missing_command`與`unknown_command` MUST維持既有的code、exit code與`error` object結構，但其`message` MUST指向help flag。該訊息 MUST NOT內嵌command清單——內嵌會使釘住該訊息的golden fixture成為第二份需手動同步的清單，與本requirement消除重複定義的目的相反；指向help的措辭是不隨dispatch table變動的穩定字串。由個別handler產生的其他`unknown_command`（例如未知的new mode或未知的discipline）MUST NOT受此規定影響。command清單 MUST只有help一個輸出處，且 MUST由dispatch table導出，MUST NOT另立靜態副本。`--json`時help MUST輸出單一JSON object，其`commands`欄位為排序後的dispatch table key陣列。

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

- **GIVEN** target依manifest-presence優先序具有valid portable manifest或valid receipt，且launcher可取得lock
- **WHEN** caller以`--help`或`-h`作為第一個argument執行CLI
- **THEN** CLI輸出dispatch table全部command並以exit 0結束
- **AND** CLI不進入command dispatch

##### Example: help 的兩種輸出形狀

- **GIVEN** caller位於對應portable manifest或receipt gate有效的workspace
- **WHEN** caller執行`.cash-skills/bin/cash --help --json`
- **THEN** CLI在stdout輸出單一JSON object，其`commands`為排序後的dispatch table key陣列
- **AND** 同一指令去除`--json`時輸出人類可讀文字

#### Scenario: Help 不繞過啟動信任 gate

- **GIVEN** target的portable manifest存在但無效，或manifest缺失且receipt缺失或內容無效
- **WHEN** caller以`--help`作為第一個argument執行CLI
- **THEN** CLI依對應gate以`manifest_invalid`、`bootstrap_invalid`或`receipt_invalid`失敗
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
source: strengthen-cash-tdd-evidence
updated: 2026-08-24
code:
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .cash-skills/lib/cash_cli/installer.py
  - .cash-skills/lib/cash_cli/resources.py
  - .cash-skills/manifest.tsv
  - .claude/skills/cash-apply/SKILL.md
  - .claude/skills/cash-debug/SKILL.md
  - scripts/cash-cli/tests/test_discovery_contracts.py
  - scripts/cash-cli/tests/test_graph_instructions.py
  - scripts/cash-skills/tests/skill-checks.fish
tests:
-->

### Requirement: Artifact graph 與 instructions 使用單一來源

系統 SHALL以Cash-owned version-controlled resources定義`spec-driven` artifact DAG、proposal/design/specs/tasks templates、apply instruction、TDD discipline、test-quality discipline與audit discipline。`status`與`instructions` MUST從同一份graph取得dependency與output path，且`status --change <name> --json` MUST回傳`changeName`、`schemaName`、`isComplete`、`applyRequires`及`artifacts`。

`instructions apply --change <name> --json` MUST回傳下列完整shape：

- `changeName`與`schemaName` MUST為non-empty string；`changeDir` MUST為root-contained normalized absolute string。
- `contextFiles` MUST為artifact ID到root-contained absolute path或glob string的object；缺少的optional artifact MUST省略，不得以`null`佔位。
- `progress` MUST恰為`{total, complete, remaining}`三個non-negative integer，且`complete + remaining` MUST等於`total`。
- `tasks` MUST依文件順序包含`{id: string, description: string, done: boolean, parallel: boolean}`；沒有task時 MUST為empty array。
- `missingArtifacts` MUST為依DAG順序排列的artifact ID string array；`blocked`時 MUST為non-empty，`ready`與`all_done`時 MUST為empty array。
- `state` MUST為`blocked`、`ready`或`all_done`；`locale`與`instruction` MUST為string。
- `preflight` MUST在三種state皆存在且恰含`status`、`missingFiles`、`driftedFiles`與`staleness`；`status` MUST為`clean`、`warnings`或`critical`，`missingFiles`每筆 MUST為`{path: string, source: string}`，`driftedFiles`每筆 MUST為project-relative path string，`staleness` MUST為`{daysOld: non-negative integer, isStale: boolean}`。沒有finding時兩個array MUST存在且為empty array，不得省略或輸出`null`。

`list --json` MUST恰回傳`changes` array，`list --parked --json` MUST恰回傳`parked` array；每筆依name byte order且為`{name: string, status: string, summary: string, completedTasks: non-negative integer, totalTasks: non-negative integer}`。`status`的`artifacts` MUST依DAG順序且每筆恰為`{id: string, outputPath: string, status: "blocked"|"ready"|"done", missingDeps: string[]}`；`applyRequires`與所有empty arrays MUST存在且不得為`null`。artifact-level `instructions` MUST恰回傳`changeName/artifactId/schemaName/changeDir/outputPath/description/instruction/locale/template/context` strings及`rules/dependencies/unlocks` arrays；`context`缺失時 MUST為empty string，`rules`缺失時 MUST為empty array且有值時依文件順序，每個dependency或unlock MUST為`{id: string, done: boolean, path: string, description: string}`並保持stable order。

`instructions --skill <tdd|test-quality|audit>` MUST從同一份Cash-owned resources回傳discipline text，且 MUST恰含`{skill: "tdd"|"test-quality"|"audit", locale: string, instruction: string}`三個key，其中`instruction` MUST為non-empty string。此mode MUST NOT要求`--change`參數；三個列名以外的skill名 MUST以`unknown_command` error與exit 2失敗，MUST NOT回傳empty instruction。

`tasks` artifact resource 的description與template MUST要求每個checkbox task在同一行明列`delivery`、`verification`、`regression`、`success`與`red`五個欄位。`delivery` MUST列出具體project-root-relative delivery paths；`verification` MUST恰好命名一個primary test、CLI、analyzer或manual assertion；`regression` MUST命名相關regression targets，只有primary target已涵蓋完整相關範圍時 MAY填`N/A`並附上理由；`success` MUST只描述primary target可直接觀察的成功marker，不得混入regression、publication或task completion結果；`red` MUST在需要red phase時描述primary target可辨識的failure marker，不適用時填`N/A`並指明pure-refactor或remaining-task分類理由。欄位不得為空、`TBD`或`TODO`。

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

- **WHEN** 分別執行`instructions --skill tdd --json`、`instructions --skill test-quality --json`與`instructions --skill audit --json`且未提供`--change`
- **THEN** CLI分別回傳對應的`{skill, locale, instruction}`且`instruction`為non-empty
- **AND** 執行`instructions --skill unknown --json`時以`unknown_command`與exit 2失敗

#### Scenario: Tasks resource 產生可消費的 verification contract

- **WHEN** caller取得`instructions tasks --change demo --json`
- **THEN** `description`與`template`要求每個checkbox task同列`delivery`、`verification`、`regression`、`success`與`red`
- **AND** `verification`恰好命名primary target；`regression`命名相關targets，或以`N/A`說明primary已涵蓋完整相關範圍
- **AND** `success`只包含該primary target可直接觀察的marker，不包含regression或publication結果
- **AND** `red`不適用時必須以`N/A`附上分類理由，而非空值或placeholder

#### Scenario: Apply instructions blocked 與 ready states

- **GIVEN**change缺少tasks artifact
- **WHEN**執行`instructions apply --change demo --json`
- **THEN**`state`為`blocked`且`contextFiles`與`missingArtifacts`指出缺口
- **AND**`preflight`仍存在，沒有project-file finding時使用clean與empty arrays

- **GIVEN**change具有pending tasks且preflight沒有critical finding
- **WHEN**執行相同command
- **THEN**`state`為`ready`且`progress`與`tasks`逐項對應checkbox

<!-- @trace
source: strengthen-cash-tdd-evidence
updated: 2026-08-24
code:
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .cash-skills/lib/cash_cli/installer.py
  - .cash-skills/lib/cash_cli/resources.py
  - .cash-skills/manifest.tsv
  - .claude/skills/cash-apply/SKILL.md
  - .claude/skills/cash-debug/SKILL.md
  - scripts/cash-cli/tests/test_discovery_contracts.py
  - scripts/cash-cli/tests/test_graph_instructions.py
  - scripts/cash-skills/tests/skill-checks.fish
tests:
-->

### Requirement: Change 與 artifact lifecycle

`new change` SHALL只在active、parked與archive identity均無collision時建立active change。`new artifact` MUST驗證artifact ID、capability slug、dependency readiness與stdin encoding後才建立檔案。

首次`in-progress add` MUST建立`.cash-skills/state/snapshots/<name>.json`，shape為`{version: 1, change: string, paths: [{path: string, worktree: string, index: string, mode: string, state: string}]}`。既有相同change且schema有效的snapshot表示resume，MUST為no-op且 MUST NOT重設baseline；identity/version不符或partial state MUST fail closed。snapshot MUST涵蓋porcelain-v2 staged-only、unstaged、added、deleted、renamed/copied雙端path、typechange、unmerged及untracked狀態，排除ignored paths，並以`absent`表示missing content。

`task done` MUST只標記唯一task，預設比較目前state與上次snapshot後寫入`.cash-skills/state/touched/<name>.json`：`{version: 1, change: string, legacy_import: null | {path: string, sha256: string, st_dev: non-negative integer, st_ino: positive integer}, touched: [{task_id: string, task_desc: string, files: string[]}], files: string[]}`。同task重跑 MUST union並stable-sort files；頂層`files` MUST恰為per-task files的stable union，後續update MUST保留`legacy_import`原值。只有成功寫入task attribution後才更新snapshot，自動差分模式 MUST排除fingerprint未變的pre-existing dirty paths。

`task done --change <name> <task-id>` SHALL 支援重複的 `--path <path>`，或互斥的 `--no-files`，以明確指定本次任務歸屬；`[P]` 任務 MUST 使用其中一種，省略時以 `invalid_arguments` 拒絕。明確模式 MUST 只 union caller 指定的檔案，MUST NOT 加入 sibling 的工作樹差異；caller 負責以任務實作證據確認歸屬，CLI 的 dirty 檢查不代表能推導作者。每個 path MUST 是 canonical project-relative 且存在於目前非 ignored 的 dirty fingerprint 集合，包含 tracked deletion 與 rename 兩端；任一不合法 path MUST 在修改 tasks、touched 或 snapshot 前拒絕。已被另一任務記錄的 dirty 檔案 MAY 由本任務再次明確歸屬，以支援同檔案不同區域的平行修改。明確模式 MUST 只推進指定路徑的 snapshot，其他 baseline 保留；`--no-files` MUST 不吸收任何工作樹變更。checkbox、歸屬與 snapshot MUST 以同一 transaction 發布。

#### Scenario: 平行任務完成順序不影響歸屬

- **GIVEN** 任務 A 修改 `src/a.py`、任務 B 修改 `src/b.py`，兩者均已寫完
- **WHEN** 主 agent 以各自的 `--path` 清單依任意順序完成任務
- **THEN** A 的 files MUST 僅含 `src/a.py`，B 的 files MUST 僅含 `src/b.py`
- **AND** 頂層 files MUST 為兩者聯集，重跑不增加重複路徑

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

`@trace`的兩個路徑欄位 MUST自被治理的artifact形狀抽取，MUST NOT額外要求該形狀未規定的書寫慣例。`code`的抽取範圍 MUST限定為proposal `## Impact`的`- Affected code:`子清單，MUST NOT涵蓋`- Affected specs:`，使抽取範圍與本requirement既有的「`code`取proposal affected-code paths」定義一致。該範圍內 MUST同時接受backtick code span內的路徑與裸路徑token；裸路徑token的字元集 MUST限定為ASCII路徑字元，使以斜線分隔的非ASCII散文 MUST NOT被視為路徑；該字元集 MUST NOT含`,`、`;`、`(`、`)`、`:`、`=`等非路徑標點，使帶指令參數或test-id後綴的token MUST NOT被逐字寫入。同一個路徑以兩種形式出現時 MUST只計一次。`- Affected code:`子清單起點的定位 MUST容忍該標籤列的前後空白（含縮排）與colon之後的行內內容，MUST NOT要求整行與標籤逐字相等；命中的標籤列其colon之後的殘餘內容 MUST以與子清單其餘各行相同的方式收集路徑，使以`- Affected code: <path>`單行形式書寫的宣告 MUST NOT落空。`## Impact`標題列的定位 MUST同樣容忍尾隨空白。子清單的同層終止條件 MUST以與起點相同的正規化判定，使縮排書寫的`- Affected specs:`仍能終止`- Affected code:`的掃描範圍，MUST NOT因只放寬起點而使spec路徑重新進入`code`。粗體或其他markdown強調標記形式、以及全形冒號形式的標籤列 MUST NOT被視為子清單起點，使可容忍的書寫形狀維持可界定。

`tests`的抽取 MUST掃描驗證子句內每個code span的全部whitespace token，MUST NOT只判定第一個token，因此以直譯器或指令名稱起首的驗證子句 MUST仍能貢獻其中的測試路徑。其token判準 MUST為：canonical check script的裸檔名維持既有映射，且該映射 MUST在任何canonical化之前判定；其餘token MUST先要求全部字元屬於與`code`側相同的ASCII路徑字元集，不符者 MUST NOT進入`tests`，再經canonical化（剝除`./`前綴與結尾的`/`；以`/`起首或剝除後不含斜線的token MUST NOT進入`tests`），最後要求canonical化後的值滿足`/tests/`出現在其路徑中或其檔名以`test_`起首。僅以`.fish`或`.sh`副檔名為由 MUST NOT被視為測試路徑，因為交付腳本與測試腳本共用該副檔名，僅憑副檔名接受會使source交付路徑被記為測試證據。兩個欄位寫入trace的值 MUST皆為剝除`./`前綴後、不以`/`起首且不以`/`結尾的canonical repo-relative形式，且該值以`/`切分後的任一路徑段 MUST NOT為空字串、`.`或`..`，其第一段 MUST NOT以`~`起首。這三類拒絕條件涵蓋以`../`逃逸與以`~`為home-relative起點兩種指向repo之外的形式，以及含非canonical路徑段的形式，使其 MUST NOT進入任一欄位；`~`出現在第一段以外的位置屬合法檔名字元，MUST NOT因此被拒絕。該判定 MUST為拒絕而非解析：含`..`、`.`或空段的值 MUST NOT被解析或正規化為其實際指向的路徑後寫入，因為寫入trace的值 MUST能逐字對回來源artifact的宣告。

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

#### Scenario: Impact 以純文字路徑書寫仍產生 code trace

- **GIVEN** 某個change的proposal `## Impact`的`- Affected code:`子清單以不加backtick的純文字列出路徑
- **WHEN** 執行`sync`或`archive`
- **THEN** 產生的`@trace`的`code`欄位含該子清單列出的路徑
- **AND** 同一路徑同時以backtick與純文字出現時只列一次

#### Scenario: Affected specs 的路徑不進入 code trace

- **GIVEN** 某個change的proposal `## Impact`同時有`- Affected specs:`與`- Affected code:`兩個子清單
- **WHEN** 執行`sync`
- **THEN** `@trace`的`code`欄位只含`- Affected code:`子清單的路徑
- **AND** 只出現在`- Affected specs:`的路徑 MUST NOT出現在該欄位

#### Scenario: 以斜線分隔的非 ASCII 散文不進入 code trace

- **GIVEN** 某個change的proposal `- Affected code:`子清單含以純文字（非code span）書寫、以斜線分隔的非ASCII散文片語
- **WHEN** 執行`sync`
- **THEN** 該片語 MUST NOT出現在`@trace`的`code`欄位

#### Scenario: 驗證子句以直譯器起首仍產生 tests trace

- **GIVEN** 某個change的tasks驗證子句寫成直譯器或指令名稱在前、測試路徑在後的形式
- **WHEN** 執行`sync`或`archive`
- **THEN** 產生的`@trace`的`tests`欄位含該測試路徑
- **AND** 同一個code span內不滿足測試判準的其他token MUST NOT出現在該欄位

#### Scenario: 交付腳本不因副檔名被記為測試證據

- **GIVEN** 某個change的驗證子句含位於tests目錄之外、檔名不以`test_`起首、且以`.fish`或`.sh`結尾的交付腳本路徑
- **WHEN** 執行`sync`
- **THEN** 該路徑 MUST NOT出現在`@trace`的`tests`欄位

#### Scenario: 兩個欄位的非 canonical 形式皆被正規化

- **WHEN** 某個change以`./`起首書寫`- Affected code:`的路徑或驗證子句的測試路徑
- **THEN** 寫入`@trace`的值為剝除`./`後的repo-relative形式

- **WHEN** 該路徑以`/`結尾
- **THEN** 寫入`@trace`的值 MUST NOT以`/`結尾

#### Scenario: 指向 repo 之外的路徑不進入任一欄位

- **GIVEN** 某個change的`- Affected code:`子清單含以`../`起首的路徑與以`~/`起首的路徑
- **AND** 其tasks的驗證子句含以`../`起首的測試路徑與以`~/`起首的測試路徑
- **WHEN** 執行`sync`
- **THEN** 該兩個路徑 MUST NOT出現在`@trace`的`code`欄位
- **AND** 該兩個測試路徑 MUST NOT出現在`@trace`的`tests`欄位
- **AND** 同一子清單中第一段不以`~`起首、僅在後續路徑段含`~`的路徑仍出現在`code`欄位

#### Scenario: 含非 canonical 路徑段的值不進入 code

- **GIVEN** 某個change的`- Affected code:`子清單含路徑段為`.`的值或含內部連續斜線的值
- **WHEN** 執行`sync`
- **THEN** 兩者皆 MUST NOT出現在`@trace`的`code`欄位
- **AND** 該值解析或正規化後的形式同樣 MUST NOT出現在該欄位

#### Scenario: Affected code 標籤帶行內內容時仍定位子清單

- **GIVEN** 某個change的proposal把affected code宣告寫成`- Affected code:`後接同一行的路徑
- **WHEN** 執行`sync`
- **THEN** `@trace`的`code`欄位含該行列出的路徑

#### Scenario: Affected code 標籤帶前後空白時仍定位子清單

- **GIVEN** 某個change的proposal的`- Affected code:`標籤列帶尾隨空白或被縮排
- **WHEN** 執行`sync`
- **THEN** `@trace`的`code`欄位含該子清單列出的路徑

#### Scenario: 縮排書寫的兩個標籤仍維持範圍分隔

- **GIVEN** 某個change的proposal把`- Affected code:`與其後的`- Affected specs:`都以縮排書寫
- **WHEN** 執行`sync`
- **THEN** `@trace`的`code`欄位只含`- Affected code:`子清單的路徑
- **AND** 只出現在`- Affected specs:`的路徑 MUST NOT出現在該欄位

#### Scenario: Impact 標題列帶尾隨空白時仍定位子清單

- **GIVEN** 某個change的proposal的`## Impact`標題列帶尾隨空白
- **WHEN** 執行`sync`
- **THEN** `@trace`的`code`欄位含該標題之下`- Affected code:`子清單列出的路徑

#### Scenario: 粗體與全形冒號標籤不被視為子清單起點

- **GIVEN** 某個change的proposal把一個標籤列寫成`- **Affected code:**`、另一個寫成以全形冒號結尾的`- Affected code：`
- **AND** 同一份proposal另有一個以精確形狀書寫的`- Affected code:`子清單，且該子清單位於前述兩個標籤列**之後**
- **WHEN** 執行`sync`
- **THEN** 粗體標籤列與全形冒號標籤列之下所列的路徑 MUST NOT出現在`@trace`的`code`欄位
- **AND** 精確形狀子清單的路徑仍出現在該欄位，使「不容忍該兩種形式」與「整段抽取失效」可被區辨

<!-- @trace
source: harden-trace-path-containment-and-label-shape
updated: 2026-07-26
code:
  - .cash-skills/lib/cash_cli/spec_merge.py
  - scripts/cash-cli/tests/test_sync_archive_transaction.py
tests:
  - scripts/cash-cli/tests/cli-checks.fish
  - scripts/cash-cli/tests/test_sync_archive_transaction.py
  - scripts/cash-skills/tests/test_bundle_version_history.py
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

本 requirement的receipt publication與receipt-based direct／registry／batch語意適用於manifest缺失的target；manifest-present launcher、`--vendor`、source-only `--self`及approved launcher replacement分別由 `Portable manifest 啟動信任模式`、`Repo-vendored Cash bundle 發佈`與 `受控 launcher bootstrap migration` requirements治理。這些具名情境以其較窄契約優先，其餘既有receipt schema、inventory與fail-closed行為不變。

`install-cash-skills.fish` SHALL將stable launcher/lock、replaceable runtime generation、24個Cash skills與`.cash-skills/receipt.tsv`視為同一versioned inventory。`cash-skills.version` MUST恰含一個`MAJOR.MINOR.PATCH`值，三個分量各符合`0|[1-9][0-9]*`，不得含前導零、prerelease或build suffix。版本排序 MUST以每個digit string的長度再以lexical bytes比較任意長度分量，不得轉換為fixed-width integer或float。任何replaceable runtime/skill bytes或contract mode改變 MUST調升bundle version；相同版本 MUST綁定first-parent history中的引入commit，後續相同版本內容漂移 MUST使contract test失敗。Stable workspace-lock bytes不得隨bundle version改變；stable launcher bytes只有在bundle version嚴格調升且命中受控migration的exact transition時可改變，其他source drift MUST為execution error。

preflight MUST在任何target write前驗證Python 3.11+、source version及完整bootstrap/runtime/skill inventory、destination boundaries、legacy full-body digests、mode與config migration。direct、register與batch targets MUST各自是Git worktree top-level；non-Git或Git子目錄target MUST fail closed。target的`openspec/config.yaml`存在時 MUST為安全可讀、schema-valid的regular file；缺檔 MUST NOT fail closed。三種形態的判定順序 MUST為unsafe先於missing、missing先於invalid：symlink、非regular file或hard link MUST以execution error失敗，MUST NOT被視為missing而觸發建立；存在且安全的檔案才進schema驗證，invalid schema MUST在首次target write前以execution error失敗。unsafe與invalid兩種失敗 MUST NOT被`--force`繞過。形狀判定 MUST在任何open之前以no-follow `lstat` metadata完成，因為以read開啟FIFO會阻塞到出現writer為止；FIFO MUST以execution error失敗，MUST NOT阻塞。缺檔在三種target mode的後續處置不同：direct與batch mode MUST由config deployment在同一transaction內建立canonical baseline；`--register`只登錄專案而不執行安裝，因此 MUST接受缺檔的target並完成登錄，且 MUST NOT建立該檔。`runtime_generation` MUST為replaceable runtime records依project-relative UTF-8 path bytes排序後，每筆以`<path>\t<lowercase-sha256>\t<four-digit-mode>\n`構成canonical UTF-8 stream的lowercase SHA-256。receipt MUST先記錄bundle version與runtime generation，再依canonical inventory順序為stable launcher/lock及每個replaceable runtime/skill path恰記一筆project-relative path、lowercase SHA-256及mode；stable records另 MUST記錄target-specific decimal `st_dev/st_ino`。launcher與installer取得stable lock後 MUST以`fstat`比對launcher/lock records、逐檔hash runtime records並重算generation，才可import runtime或分類current。invalid source version、generation或receipt的invalid version、欄位數、digest、mode、device/inode、path、順序、duplicate、missing或unknown record MUST在首次write前以execution error失敗，不得分類為missing、current、newer或conflict。launcher MUST為`0755`，lock與其他新建runtime/skill files MUST為`0644`。可刪除legacy standard skill MUST逐byte匹配`scripts/cash-skills/legacy-spectra-digests.tsv`的已知baseline且mode為`0644`。無法證明為已知baseline者（同名customization、unknown version或mode drift）MUST被保留、MUST NOT被刪除或修改，且 MUST NOT阻斷安裝：installer MUST繼續發布其餘managed inventory，並在該target的輸出逐筆列出被保留的path。只有可能導致刪除逃逸target邊界的形狀——symlink、hard link或目錄含額外內容——MUST在首次write前fail closed。legacy receipt migration只驗證舊schema實際記載的path與digest，MUST NOT以舊schema未記載的mode作為migration gate；managed skill的mode由本次transaction依contract mode正規化。

Fresh、legacy adoption與known-old migration MUST使用monotonic bootstrap。read-only preflight後，installer以`O_CREAT|O_EXCL`建立project-root lock、立即取得exclusive lock，並以`fstat`與pathname no-follow lookup重驗相同device/inode；遇到`EEXIST`的並發installer MUST開啟現存lock、等待exclusive lock、重驗pathname/FD identity後重新分類。Stable lock一旦建立 MUST NOT unlink或rename；stable launcher除 `受控 launcher bootstrap migration` requirement明列的transactional replacement外，MUST NOT unlink或rename。一般receipt publication failure只回滾replaceable runtime、skills、config、guidance、target版控排除設定與receipt，保留canonical `lock-only`或`lock+launcher` prefix；受控launcher migration則依專用launcher／dynamic receipt journal與identity rebind契約rollback；下一次installer MUST在同一lock inode上恢復。launcher-without-lock、bootstrap drift、unknown partial state或pathname/FD mismatch MUST fail closed。Existing current/upgrade/force/batch MUST持有同一FD到transaction/rollback完成。新receipt MUST最後發佈並從target `fstat`產生stable identity records。Journal recovery會改變target state，因此installer MUST在recovery之後才定案installation inputs的target snapshot、legacy candidate plan與版控排除設定plan；Journal的存在偵測 MUST在read-only preflight內完成且 MUST早於版本比較的`newer` early return；該偵測 MUST為純讀取，MUST NOT持鎖，也 MUST NOT解讀target config，並 MUST以no-follow的`lstat`判定形狀——`JOURNAL_PATH`非regular file（含symlink）時 MUST以execution error fail closed，MUST NOT靜默視為無journal。恢復 MUST緊接在`newer` early return之後，且 MUST早於全部三個提前返回的分類分支：`legacy receipt drift`、`receipt-less Cash skill inventory is partial`與`managed target drift`；未完成journal存在時，installer MUST NOT先以其中任何一個返回而略過恢復，即使半發布bytes落在receipt-managed path亦然，且該恢復 MUST NOT要求`--force`。journal的schema version不被本bundle辨識時 MUST以execution error fail closed，且diagnostic MUST指出需要版本相符或更新的installer；`newer`排除的判準是receipt版本，而receipt是transaction的最後一筆operation，因此較新bundle在publishing階段的崩潰不會被`newer`排除，跨版本journal MUST由此條而非`newer`排除來處理。被分類為`newer`的target MUST維持零寫入返回且 MUST NOT執行recovery，其journal留待版本相符或更新的installer處理。非dry-run、target未分類為`newer`且偵測到journal時，installer MUST先執行既有的launcher-without-lock檢查，再取得既存stable lock後才執行recovery；該次取鎖 MUST NOT建立不存在的lock，journal存在而stable lock不存在 MUST fail closed，MUST NOT以`O_CREAT|O_EXCL`建立新的lock inode。recovery回傳真與回傳偽兩個分支 MUST都關閉lock descriptor，同一process在任一時刻 MUST至多持有一個stable lock descriptor。Journal recovery造成的rollback寫入 MUST NOT被視為違反`current`、`newer`或`conflict`分類的零寫入契約：該零寫入契約自recovery完成後的重新分類起適用，因此recovery之後若仍存在與該journal無關的drift，installer MUST回報`Result: conflict`、exit 2，且自重新分類起零寫入。當recovery實際處理並清除journal時，installer MUST釋放stable lock並依recovery後的state重新分類，MUST NOT因recovery自身造成的target變更而以publication前revalidation不一致為由fail closed；外部併發在取得lock之後修改target時，publication前revalidation的既有fail-closed契約 MUST維持不變。該重新分類 MUST在同一lock inode上恢復，且同一份journal MUST NOT再次觸發重新分類；釋放lock的時間窗內由外部併發產生的另一份journal可再觸發一次重新分類，屬既有併發語意。偵測到未完成journal時，installer MUST在早於`newer` early return的偵測點輸出一句與分類無關的通用diagnostic，僅陳述target存在未完成的journal；該句 MUST在dry-run與real run皆出現，且 MUST與最終分類無關而一律出現，包含`current`與`newer`。分類為`newer`時，installer MUST於`newer` early return之前另外輸出一句newer專屬補充，指出該journal需要版本相符或更新的installer才會恢復；該補充 MUST NOT併入通用句，因為通用句在版本比較之前發出，把newer專屬語意寫進去會對絕大多數會被本次執行恢復的target給出錯誤指引。`--dry-run` MUST NOT執行recovery並 MUST維持零寫入。

Receipt-less legacy adoption MUST在receipt與runtime缺失、stable prefix為absent、`lock-only`或`lock+launcher`，且24個canonical Cash skills全數為root-contained、non-symlink、single-link regular files、bytes與`0644` mode逐筆等於source時成立。installer SHALL保留skill bytes，並由monotonic bootstrap transaction補齊launcher、runtime、config/guidance與新receipt。零個skill是fresh；1至23個、任何byte/mode/identity不同或unknown Cash runtime partial state在未帶`--force`時 MUST conflict。Receipt-less完整新inventory則可在stable lock下依全部bytes/modes相符條件認養。

Known legacy receipt MUST嚴格限定為恰好25個LF-terminated records：第一筆`version<TAB><strict-MAJOR.MINOR.PATCH>`，其後依canonical 24-skill順序各一筆`sha256<TAB><lowercase-64-hex-digest><TAB><project-relative-path>`；它沒有mode、runtime、bootstrap或generation欄位。僅當receipt完整符合此schema、24個target skills逐筆相符且stable prefix absent或canonical recoverable時，installer才 SHALL執行one-time bootstrap migration。failure MUST回滾replaceable publications並還原old receipt，但 MUST保留已發布的stable lock/launcher；下一次direct或batch invocation MUST在相同lock inode恢復。old receipt drift、unknown/incomplete schema或bootstrap drift MUST fail closed。dry-run MUST使用同一判定、零寫入並回報would-update。

installer MUST先以incoming parser驗證source config，並在target config interpretation前先驗證target receipt/version/boundary；合法newer target MUST零寫入返回，且 MUST NOT由較舊incoming parser重新解讀target`.cash.yaml`。fresh、known-legacy、adoption、current與older target才使用incoming bundle parser。config deployment MUST採三分支：既有`.cash.yaml`視為project-owned，以該parser及no-follow snapshot驗證allowed keys、duplicates、types與syntax後逐byte保留，invalid existing config MUST在首次write前execution error；只有`.spectra.yaml`時 SHALL只接受uncommented `locale/tdd/audit/parallel_tasks`及optional `spec_dir: openspec`，任何其他active top-level/nested scalar、map、list或non-default`spec_dir` MUST fail closed；兩者皆不存在時 MUST先以同一parser驗證source canonical `.cash.yaml`，再逐byte複製baseline。installer MUST NOT刪除caller-owned`.spectra.yaml`。執行安裝的direct與batch mode在target的`openspec/config.yaml`不存在時，installer MUST以installer bundle內嵌的canonical baseline，在同一transaction內以`0644`建立該檔。該baseline MUST為LF結尾的UTF-8、首行為`schema: spec-driven`，其餘行 MUST只有blank line與full-line `#` comment，因此其parse結果的`context` MUST為空字串、`rules` MUST為空mapping；它 MUST先以同一`openspec/config.yaml` parser驗證通過才可寫入，且 MUST NOT在安裝時取自source repository的同名檔案，以免source專案自身的context或rules進入target。既有的`openspec/config.yaml` MUST逐byte保留並零寫入。缺檔時的建立 MUST優先於`current`分類的零寫入契約：其餘managed inventory一致但該檔缺失時，target MUST分類為`update`並建立該檔，MUST NOT分類為`current`。建立後該檔即為project-owned：後續安裝 MUST NOT覆寫或修復其內容，且它 MUST NOT進入receipt或managed inventory。installer MUST NOT建立`openspec/`下的其他目錄。成功transaction MUST最後才發佈receipt；failure MUST回滾新建config與先前receipt，或維持兩者absent；該回滾 MUST涵蓋新建的`openspec/config.yaml`，為它建立的`openspec/`目錄則可保留。

Installer SHALL提供source-only `--self [--dry-run]`模式。它 MUST從installer所在目錄解析唯一Git top-level，驗證canonical source version、stable launcher/lock、replaceable runtime generation、24個skills、`.cash.yaml`與`openspec/config.yaml`的no-follow identity、bytes及contract modes，並在既有stable lock的exclusive FD下分類或發布canonical portable manifest及清除source receipt residue。Real run需要變更時 MUST在recoverable transaction中發布manifest並刪除receipt residue，回報`Result: bootstrap`；`--dry-run` MUST執行相同preflight與計畫並回報`Result: would-bootstrap`且零寫入；canonical manifest且receipt absent時 MUST回報`Result: current`且零寫入。`--self` MUST NOT與`--target`、`--vendor`、`--all`、`--register`、`--unregister`、`--list`或`--force`組合，MUST NOT發布或修改launcher、lock、runtime、skills、config、guidance或legacy內容。`--self` MUST NOT建立缺失的`openspec/config.yaml`；source repository缺少該檔 MUST以execution error失敗且零寫入。已辨識source layout的launcher在manifest存在時 MUST只走portable gate；manifest缺失且receipt缺失時 MUST回報`bootstrap_invalid`，receipt存在但內容驗證失敗時 MUST回報`receipt_invalid`，invalid manifest MUST回報`manifest_invalid`且不得fallback。所有失敗 MUST以exit 1結束；JSON與non-JSON actionable diagnostic在兩種信任資料皆缺失時 MUST包含`./install-cash-skills.fish --self`，installed target diagnostic MUST NOT建議source-only指令。一般direct、registry與batch target modes仍 MUST拒絕source repository。

#### Scenario: Fresh target 原子安裝

- **GIVEN**安全、是Git top-level、具有有效`openspec/config.yaml`且沒有Cash inventory/config的target
- **WHEN**執行installer
- **THEN**stable launcher/lock、runtime generation、24個skills、source canonical Cash config與receipt在同一transaction完成
- **AND**下一次相同版本安裝回報current且零寫入

#### Scenario: Source repository self bootstrap

- **GIVEN** canonical source repository的portable manifest缺失或未同步，且stable lock、launcher、runtime、24個skills及configs安全且完整
- **WHEN** 執行`install-cash-skills.fish --self`
- **THEN** installer在existing lock inode的exclusive FD下發布canonical manifest、清除source receipt residue並回報`Result: bootstrap`
- **AND** 後續source launcher以portable gate執行Cash commands，重複`--self`回報`Result: current`且零寫入

#### Scenario: Source self dry run 與模式互斥

- **WHEN** 執行`--self --dry-run`
- **THEN** installer執行相同preflight並回報`Result: would-bootstrap`或`Result: current`，但零寫入
- **WHEN** `--self`與target、vendor、batch、registry、list或force mode任一組合
- **THEN** installer以caller-input error失敗且零寫入

#### Scenario: Source launcher提供可行動診斷

- **GIVEN** 已辨識source layout且manifest與receipt皆缺失，或目前選定的manifest／receipt gate無效
- **WHEN** 以JSON或non-JSON模式啟動launcher
- **THEN** launcher依選定gate以`bootstrap_invalid`、`manifest_invalid`或`receipt_invalid`與exit 1失敗
- **AND** 兩種信任資料皆缺失時diagnostic指出從project root執行`./install-cash-skills.fish --self`，invalid manifest則不得fallback到receipt

#### Scenario: Target prerequisite 不足

- **WHEN**direct、registered或batch target不是Git worktree top-level，或其既有`openspec/config.yaml`為unsafe shape或schema-invalid
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

#### Scenario: 缺 openspec config 的全新 target 仍完成安裝

- **GIVEN**安全、是Git worktree top-level、沒有`openspec/`目錄也沒有Cash inventory/config的target
- **WHEN**執行installer
- **THEN**installer在同一transaction內以`0644`建立schema-valid的`openspec/config.yaml`
- **AND**stable launcher/lock、runtime generation、24個skills、Cash config與receipt同樣在該transaction完成
- **AND**下一次相同版本安裝回報`current`且該檔零寫入

#### Scenario: 既有 openspec config 逐 byte 保留

- **GIVEN**target已有安全、schema-valid且與installer baseline不同的`openspec/config.yaml`
- **WHEN**執行installer
- **THEN**installer逐byte保留該檔且不寫入它
- **AND**installer不因該檔與baseline不同而失敗

#### Scenario: 缺 openspec config 的 dry run 零寫入

- **GIVEN**缺`openspec/config.yaml`但其餘前置條件成立的target
- **WHEN**執行`--dry-run`
- **THEN**installer以既有dry-run分類回報（`--target`模式輸出`Result: update`，batch模式輸出`would-update`）
- **AND**installer不建立`openspec/config.yaml`，亦不建立`openspec/`目錄

#### Scenario: 缺 openspec config 的安裝失敗回滾該檔

- **GIVEN**缺`openspec/config.yaml`的target，且installer在建立該檔之後的某個publication失敗
- **WHEN**transaction回滾
- **THEN**該檔被移除且target不留下installer產生的`openspec/config.yaml`
- **AND**receipt維持absent，`openspec/`目錄可保留

#### Scenario: openspec config 的 unsafe shape 不被視為缺檔

- **WHEN**target的`openspec/config.yaml`是symlink、hard link、目錄或FIFO等非regular file
- **THEN**installer在首次target write前以execution error失敗，且不阻塞等待writer
- **AND**installer不建立或替換該檔，`--force`亦不繞過

#### Scenario: 缺 openspec config 的 target 可被登錄

- **GIVEN**是Git worktree top-level但缺`openspec/config.yaml`的target
- **WHEN**執行`--register`
- **THEN**installer完成登錄並以exit 0結束
- **AND**installer不建立`openspec/config.yaml`
- **WHEN**同一target的`openspec/config.yaml`為unsafe shape或schema-invalid
- **THEN**`--register`以execution error失敗且registry不變

#### Scenario: --self 不建立缺失的 openspec config

- **GIVEN**source repository缺少`openspec/config.yaml`
- **WHEN**執行`--self`或`--self --dry-run`
- **THEN**installer以execution error失敗且零寫入

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
- **AND**stable workspace-lock source bytes改變時一律失敗；stable launcher source bytes改變時只接受bundle version已調升且exact transition已登錄的受控migration

#### Scenario: Receipt-less 完整新 inventory 被認養

- **GIVEN**target沒有receipt且stable launcher/lock與全部replaceable runtime/24個skills逐byte及mode等於source
- **WHEN**installer執行
- **THEN**installer先鎖定existing lock inode、保留stable bootstrap與managed bytes並發佈含runtime generation的receipt
- **AND**回報`Result: update`

#### Scenario: Current、newer 與 conflict 分類

- **WHEN**版本、全部receipt records、modes、guidance、target版控排除設定與legacy state都一致，且`openspec/config.yaml`存在
- **THEN**installer回報`Result: current`且零寫入

- **WHEN**target receipt版本高於source
- **THEN**installer回報`Result: newer`且零寫入

- **WHEN**target managed path相對有效receipt drift且未授權`--force`
- **THEN**installer回報`Result: conflict`、exit 2且零寫入

#### Scenario: Upgrade 與 force 只收斂 managed inventory

- **GIVEN**target版本不高於source且所有preflight通過
- **WHEN**clean upgrade或授權`--force`執行
- **THEN**installer持有existing lock inode，只更新replaceable runtime generation、24個skills、Cash guidance、target版控排除設定、receipt與精確baseline legacy removals
- **AND**stable lock inode不變；stable launcher除approved exact transition migration外維持bytes與inode不變
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
source: add-repo-vendored-cash-bundle
updated: 2026-07-29
code:
  - .cash-skills/bin/cash
  - .cash-skills/lib/cash_cli/installer.py
  - .cash-skills/manifest.tsv
  - scripts/cash-skills/tests/skill-checks.fish
  - scripts/cash-skills/tests/test_bundle_version_history.py
  - scripts/cash-skills/tests/test_init_receipt.py
  - scripts/cash-skills/tests/test_installer_runtime.py
tests:
  - scripts/cash-skills/tests/test_init_receipt.py
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

Installer SHALL canonicalize既有target；一般direct、registry與batch模式 MUST拒絕空值、`/`、source repository、symlink target、root外destination及symlink/hard-link ownership不明的managed boundary。唯一source repository例外是明確`--self`模式，且該模式只能在已驗證source root內發布canonical portable manifest並清除source receipt residue；它不得簽發新的source receipt。Publisher MUST以held no-follow parent directory handle、exclusive relative temporary basename、snapshot revalidation、明確mode與transaction journal完成publication/cleanup。Registry與`uninstall-spectra-plus-repair.fish` MUST保留既有HOME absolute/non-root、symlink及service identity fail-closed contract。Mode參數的分派 MUST依「該參數是否被提供」判定，MUST NOT依參數值的truthiness判定；空字串的`--target`、`--register`或`--unregister` MUST被視為該mode的invalid value並以caller-input error失敗，MUST NOT被重新解讀為batch mode或任何其他mode。該空值拒絕 MUST早於registry的讀取，也 MUST早於與mode相依的`--dry-run`及`--force`相容性檢查：空字串mode參數 MUST NOT讀取registry、MUST NOT對任何已註冊project執行安裝；即使registry或HOME本身不合法，diagnostic MUST指出mode參數值無效而非registry或HOME錯誤；空字串mode參數與`--dry-run`或`--force`併用時，diagnostic MUST指出該值無效而非指出缺少mode參數。與mode相依的`--dry-run`及`--force`相容性檢查本身 MUST對帶值mode參數使用同一存在性判準，對`store_true`的boolean mode flag則 MUST維持既有判準，使既有的caller-input守衛不因此失效。

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
source: add-repo-vendored-cash-bundle
updated: 2026-07-29
code:
  - .cash-skills/bin/cash
  - .cash-skills/lib/cash_cli/installer.py
  - .cash-skills/manifest.tsv
  - scripts/cash-skills/tests/skill-checks.fish
  - scripts/cash-skills/tests/test_bundle_version_history.py
  - scripts/cash-skills/tests/test_init_receipt.py
  - scripts/cash-skills/tests/test_installer_runtime.py
tests:
  - scripts/cash-skills/tests/test_init_receipt.py
  - scripts/cash-skills/tests/test_installer_runtime.py
-->

### Requirement: Live namespace 與歷史邊界

live scan SHALL只包含`.agents/skills/cash-*/`、`.claude/skills/cash-*/`、`scripts/cash-skills/blocks/`、`scripts/cash-skills/generate.fish`、`scripts/cash-skills/variant-rules.yaml`、`scripts/cash-skills/SKILL-LINT.md`、`CASH-GLOSSARY.md`、`install-cash-skills.fish`、`scripts/cash-skills/tests/`、`.cash-skills/`、`scripts/cash-cli/`、`AGENTS.md`、`CLAUDE.md`、`CASH-SKILLS.md`、`.cash.yaml`與`openspec/specs/`。這些surface SHALL NOT包含可執行的Spectra CLI command、`Requires spectra CLI`或未治理的`.spectra/`runtime read。active migration change/reviews、`openspec/changes/archive/`與signal occurrence history SHALL保留provenance原文。Legacy migration code SHALL只在下列明列paths辨識`SPECTRA` markers、`.spectra.yaml`、`.spectra/touched`、`.spectra/snapshots`與`spectra-*`directories：`install-cash-skills.fish`、`uninstall-spectra-plus-repair.fish`、`scripts/cash-skills/legacy-spectra-digests.tsv`，以及`.cash-skills/lib/cash_cli/`中負責`touched ensure` legacy import的module；`.spectra.yaml`→`.cash.yaml` config migration亦限於`install-cash-skills.fish`。這些paths之外的live surface MUST NOT出現legacy literal，且以上任何path MUST NOT執行Spectra binary或讀取其他Spectra state。

#### Scenario: Live namespace residue scan

- **WHEN**contract test掃描所有non-archive live surfaces
- **THEN**任何可執行的`spectra`command、compatibility declaration或runtime config read使測試失敗
- **AND**明列的legacy detector literals不被誤判為runtime dependency

#### Scenario: 歷史 artifacts 不回寫

- **WHEN**namespace migration完成
- **THEN**`openspec/changes/archive/`內既有files維持逐byte不變
- **AND**signal occurrence中的歷史provenance不被重新命名

#### Scenario: 生成源頭檔納入 scan surface

- **WHEN** `scripts/cash-skills/variant-parity/` 自工作樹移除且生成管線檔案（`scripts/cash-skills/blocks/`、`scripts/cash-skills/generate.fish`、`scripts/cash-skills/variant-rules.yaml`）建立後
- **THEN** live scan 的枚舉不含 `scripts/cash-skills/variant-parity/`
- **AND** 生成管線檔案與 `scripts/cash-skills/SKILL-LINT.md`、`CASH-GLOSSARY.md` 皆在 scan surface 內

<!-- @trace
source: cash-skill-maintainability
updated: 2026-07-27
code:
  - .agents/skills
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-propose/SKILL.md
  - .cash-skills/receipt.tsv
  - .claude/skills/cash-apply/SKILL.md
  - .claude/skills/cash-propose/SKILL.md
  - scripts/cash-skills/SKILL-LINT.md
  - scripts/cash-skills/blocks/review-gate.md
  - scripts/cash-skills/generate.fish
  - scripts/cash-skills/tests/skill-checks.fish
  - scripts/cash-skills/tests/test_live_namespace.py
  - scripts/cash-skills/variant-parity
  - scripts/cash-skills/variant-rules.yaml
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

### Requirement: touched record 記錄 review loop 產出

CLI SHALL 提供 `touched record <name> --path <path> [--path <path> ...]`，把指定的 project-root-relative 路徑記入 `.cash-skills/state/touched/<name>.json` 中 `task_id` 為 `review-loop`、`task_desc` 為 `Review loop outputs` 的保留條目。

`touched record` MUST NOT 成為第一次 Cash touched access：`.cash-skills/state/touched/<name>.json` 不存在時 MUST 以 `touched_invalid` 失敗且零寫入，並 MUST NOT 執行 legacy import；呼叫端 MUST 先執行 `touched ensure <name>`。

每個 `--path` MUST 依序通過三段驗證：既有的 unsafe path 檢查（絕對路徑、含 `..`、以 `.git/` 或 `.cash-skills/state/` 開頭者 MUST 以 `touched_invalid` 失敗）；前綴拒絕（以 `openspec/changes/` 或 `.cash-skills/receipt.tsv` 開頭者 MUST 以 `touched_invalid` 失敗；此組前綴與 `git_fingerprints` 忽略的前綴對齊，MUST NOT 拒絕整個 `.cash-skills/` 前綴，`.cash-skills/lib/` 與 `.cash-skills/bin/` 之下的既存一般檔案 MUST 可被記錄）；以及存在性與型別檢查（路徑 MUST 為既存的一般檔案，`missing`、`directory` 與其他型別 MUST 以 `touched_invalid` 失敗，symlink MUST 以 `unsafe_path` 失敗）。任一 `--path` 失敗時整個 command MUST 零寫入。

該 command MUST NOT 依賴、讀取或寫入 `.cash-skills/state/snapshots/<name>.json`，MUST NOT 改動 `tasks.md`，MUST NOT 改動任何既有 per-task 條目的 `task_desc` 與 `files`，MUST NOT 提供 `--json`。既有 per-task 條目的 `task_id` MAY 因 task attribution 對齊而被改寫，`touched` 陣列 MAY 因該對齊而重新排序。條目內 `files` 與頂層 `files` MUST 維持以 UTF-8 bytes 排序去重的正規形式，頂層 `files` MUST 恰為各條目 `files` 的排序聯集，`legacy_import` 原值 MUST 保留。合併結果與載入值相同且 task attribution 對齊未改變任何內容時 MUST NOT 寫入；對齊改變了內容時 MUST 寫入，即使合併結果本身與載入值相同。`openspec/changes/<name>/` 不是目錄時 MUST 以 `change_not_found` 失敗且零寫入；未提供任何 `--path` 或 `--path` 缺值時 MUST 以 `invalid_arguments` 失敗且零寫入。`touched ensure` 除新增的 task attribution 對齊與其修復性寫入外，其餘行為 MUST 不變。

#### Scenario: 無 snapshot 時仍可記錄

- **GIVEN** change `demo-change` 存在且從未執行過 `in-progress add`
- **AND** 已執行過 `touched ensure demo-change`
- **AND** `.cash-skills/state/snapshots/demo-change.json` 不存在
- **WHEN** 執行 `touched record demo-change --path openspec/signals/demo.md`
- **THEN** command 成功並建立 `review-loop` 條目
- **AND** `.cash-skills/state/snapshots/demo-change.json` 仍不存在

#### Scenario: 未先 ensure 時失敗

- **GIVEN** `.cash-skills/state/touched/demo-change.json` 不存在
- **WHEN** 執行 `touched record demo-change --path openspec/signals/demo.md`
- **THEN** command 以 `touched_invalid` 失敗
- **AND** `.cash-skills/state/touched/demo-change.json` 不被建立
- **AND** command 不讀取也不匯入任何 legacy touched 檔

#### Scenario: 與既有 per-task 條目並存

- **GIVEN** `demo-change` 的 touched state 已含一個 per-task 條目
- **AND** 該條目的 `task_desc` 與目前 `tasks.md` 一致，且該 state 的 `touched` 已為 canonical 排序，因此 task attribution 對齊不改變任何內容
- **WHEN** 執行 `touched record demo-change --path openspec/signals/demo.md`
- **THEN** 既有 per-task 條目逐字不變
- **AND** touched state 同時含該 per-task 條目與 `review-loop` 條目
- **AND** 頂層 `files` 恰為兩個條目 `files` 的排序聯集

#### Scenario: 重複記錄相同路徑不寫入

- **GIVEN** `demo-change` 的 `review-loop` 條目已含 `openspec/signals/demo.md`
- **AND** 全部非保留條目的 `task_desc` 與目前 `tasks.md` 一致，且該 state 的 `touched` 已為 canonical 排序，因此 task attribution 對齊不改變任何內容
- **WHEN** 再次執行 `touched record demo-change --path openspec/signals/demo.md`
- **THEN** command 成功
- **AND** `.cash-skills/state/touched/demo-change.json` 的 bytes、`st_ino` 與 mtime 皆不變

#### Scenario: 缺少 path 參數時失敗

- **WHEN** 執行 `touched record demo-change` 或 `touched record demo-change --path`
- **THEN** command 以 `invalid_arguments` 失敗
- **AND** touched state 不被建立或改動

#### Scenario: 不安全路徑被拒絕

- **WHEN** 執行 `touched record demo-change --path` 並帶入絕對路徑、含 `..` 的路徑、以 `.git/` 開頭的路徑、或以 `.cash-skills/state/` 開頭的路徑
- **THEN** command 以 `touched_invalid` 失敗
- **AND** touched state 不被建立或改動

#### Scenario: 被拒前綴維持 touched 的來源檔不變量

- **WHEN** 執行 `touched record demo-change --path` 並帶入以 `openspec/changes/` 開頭的路徑或 `.cash-skills/receipt.tsv`
- **THEN** command 以 `touched_invalid` 失敗
- **AND** touched state 不被建立或改動
- **AND** 帶入 `.cash-skills/lib/` 之下的既存一般檔案時 command 成功並記錄該路徑

#### Scenario: 非既存一般檔案被拒絕

- **WHEN** 執行 `touched record demo-change --path` 並帶入不存在的路徑或目錄路徑
- **THEN** command 以 `touched_invalid` 失敗
- **AND** touched state 不被建立或改動

#### Scenario: 混合合法與非法路徑時零寫入

- **GIVEN** `demo-change` 的 touched state 已存在
- **WHEN** 單次執行 `touched record demo-change` 並帶入多個合法 `--path` 與一個非法 `--path`
- **THEN** command 以 `touched_invalid` 失敗
- **AND** `.cash-skills/state/touched/demo-change.json` 的 bytes 逐字不變，合法路徑亦未被記錄

#### Scenario: change 不存在時失敗

- **GIVEN** `openspec/changes/absent-change/` 不存在
- **WHEN** 執行 `touched record absent-change --path openspec/signals/demo.md`
- **THEN** command 以 `change_not_found` 失敗
- **AND** `.cash-skills/state/touched/absent-change.json` 不被建立

#### Scenario: 不改動 tasks 與 snapshot

- **GIVEN** `demo-change` 已有 `tasks.md` 與 snapshot
- **WHEN** 執行 `touched record demo-change --path openspec/signals/demo.md`
- **THEN** `openspec/changes/demo-change/tasks.md` 的 bytes 不變
- **AND** `.cash-skills/state/snapshots/demo-change.json` 的 bytes 不變

<!-- @trace
source: guard-task-state-integrity
updated: 2026-08-23
code:
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-commit/SKILL.md
  - .cash-skills/lib/cash_cli/commands/tasks.py
  - .cash-skills/lib/cash_cli/installer.py
  - .cash-skills/manifest.tsv
  - .claude/skills/cash-archive/SKILL.md
  - .claude/skills/cash-commit/SKILL.md
  - scripts/cash-cli/tests/test_creation_task_lifecycle.py
  - scripts/cash-cli/tests/test_sync_archive_transaction.py
tests:
-->

### Requirement: TDD discipline 以適用性判準表述

Cash-owned `DISCIPLINES["tdd"]` SHALL是 `instructions --skill tdd` 回傳內容的唯一完整語意來源，並 MUST以 task 性質與驗證邊界表述 Red-Green-Refactor 的適用條件，而非要求每個 task 無條件建立失敗測試。`skill_payload("tdd")` MUST逐字回傳該 canonical instruction；command 與 JSON shape 繼續由既有「Artifact graph 與 instructions 使用單一來源」requirement 擁有，本 requirement MUST NOT重新定義該 shape contract。

canonical instruction MUST依下列 precedence 將每個 task 分到恰好一種處置：bug fix 且有實際可行自動測試邊界時，先以能辨識該缺陷的失敗測試重現；其餘新增或改變可觀察可執行行為且有實際可行自動測試邊界時，執行 Red-Green-Refactor；不改變可觀察行為的純 refactor 以既有 regression tests 保護並只在 evidence 不足時補 characterization test；其餘 task 使用命名 verification target，有可用自動 checker 時 MAY使用，但不得為文件、metadata、checker-only 或沒有實際可行自動測試邊界的 task 強迫建立 red phase。分類 MUST由前至後判定，命中後不得再落入後續分支。

對需要 red phase 的 task，agent MUST在任何production edit前實際執行current workflow命名的primary verification target，且初始測試 MUST因目標行為尚未存在而失敗，並 MUST以diagnostic、state、artifact或等價assertion觀察到current workflow命名的failure marker，以區分目標路徑與不相關的較早guard、pre-existing suite failure、execution error或只有相同exit code的失敗。實作 SHALL以最小變更使同一primary target通過；agent MUST重跑並觀察current workflow命名的success marker，再執行current workflow命名的相關regression targets，且只在綠燈狀態進行refactor。discipline MUST保持tool與framework中立，且 MUST NOT假設evidence carrier一定是`tasks.md`。

回歸測試 MUST分別斷言observable executable behavior、目標失敗原因、unrelated failure排除、executed RED、same-target GREEN、related regression、minimal green、green refactor、bug reproduction、pure-refactor evidence與remaining-task verification十一個行為語意，不得只以`Red-Green-Refactor`單一marker代表完整contract。測試 MUST另以獨立assertions驗證四分支由前至後的precedence、沒有可行自動測試邊界的bug fix與具有checker的文件／metadata task都落入remaining-task分支，以及canonical instruction不要求任何特定程式語言或test framework。

#### Scenario: CLI 逐字回傳 canonical TDD instruction

- **WHEN** caller執行 `instructions --skill tdd --json`
- **THEN** payload 的 `instruction` 逐字等於 `DISCIPLINES["tdd"]`
- **AND** payload 繼續符合「Artifact graph 與 instructions 使用單一來源」requirement 的既有 skill discipline shape contract

#### Scenario: 行為 task 實際執行有效 Red-Green-Refactor

- **GIVEN** task 新增可觀察的可執行行為且存在實際可行的自動測試邊界
- **WHEN** agent遵循 canonical TDD instruction
- **THEN** agent在任何production edit前實際執行current workflow命名的primary verification target
- **AND** agent觀察到目標assertion到達且failure marker與current workflow命名的marker一致
- **AND** agent以最小實作使同一primary target出現current workflow命名的success marker，再執行相關regression targets
- **AND** agent僅在綠燈狀態整理程式碼

#### Scenario: 未執行或不相關失敗不構成 red phase

- **GIVEN** agent未實際執行target，或新測試在到達目標路徑前已因另一個guard、execution error或pre-existing failure結束
- **AND** 該失敗只與預期結果共享exit code或缺少artifact等一般表象
- **WHEN** agent判定red phase是否成立
- **THEN** canonical discipline要求實際執行target，並加入能辨識目標路徑的diagnostic、state、artifact或等價assertion，或改用適合的驗證邊界
- **AND** agent不得把推測結果或該不相關失敗視為有效red evidence

#### Scenario: 有自動測試邊界的 Bug fix 先建立可辨識的重現

- **GIVEN** task 修正一個既有缺陷
- **AND** 該缺陷存在實際可行的自動測試邊界
- **WHEN** agent套用 canonical TDD instruction
- **THEN** agent先實際執行能辨識該缺陷的失敗測試
- **AND** 修正後重跑同一target轉綠，且該測試保留為regression evidence

#### Scenario: 純 refactor 與其餘 task 使用各自 evidence

- **GIVEN** task 不改變可觀察行為
- **WHEN** agent套用 canonical TDD instruction
- **THEN** agent使用既有 regression tests，並只在 evidence 不足時補 characterization test
- **AND** 不要求刻意製造 red phase

- **GIVEN** task 未命中前三個分支
- **WHEN** agent套用 canonical TDD instruction
- **THEN** agent執行命名 verification target
- **AND** 有可用自動 checker 時 MAY使用，但不要求 red phase

#### Scenario: Resource tests 覆蓋完整語意

- **WHEN** 執行 `PYTHONPATH=.cash-skills/lib python3 scripts/cash-cli/tests/test_graph_instructions.py`
- **THEN** 測試分別斷言十一個必要行為語意、四分支precedence、兩個remaining-task boundary case與`skill_payload("tdd")`的逐字同源
- **AND** 任一必要分支、實際執行gate或same-target GREEN被移除或反轉時測試以非零結束
- **AND** 測試驗證 canonical instruction 不要求任何特定程式語言或 test framework

<!-- @trace
source: strengthen-cash-tdd-evidence
updated: 2026-08-24
code:
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .cash-skills/lib/cash_cli/installer.py
  - .cash-skills/lib/cash_cli/resources.py
  - .cash-skills/manifest.tsv
  - .claude/skills/cash-apply/SKILL.md
  - .claude/skills/cash-debug/SKILL.md
  - scripts/cash-cli/tests/test_discovery_contracts.py
  - scripts/cash-cli/tests/test_graph_instructions.py
  - scripts/cash-skills/tests/skill-checks.fish
tests:
-->

### Requirement: Target-local receipt 初始化

`cash_cli.installer` SHALL 提供 target-side 的 `--init-receipt` 模式，與 `--self`、`--target`、`--vendor`、`--register`、`--unregister`、`--list`、`--all`、`--force` 互斥，以在 target 專案根執行 `PYTHONPATH=.cash-skills/lib python3 -s -P -B -m cash_cli.installer --init-receipt` 的形式使用。此模式 MUST NOT 新增任何檔案到 bundle inventory、MUST NOT 改變 receipt 的 record 集合或 schema、MUST NOT 修改 `.cash-skills/bin/cash` 的任何 bytes。

`--init-receipt` MUST 依序：於 import 完成後檢查 Python 3.11+；驗證執行目錄為 canonical Git worktree top-level；以 launcher 的 source layout marker 集合（source-only 檔案、runtime core、24 個 canonical skill 的存在與 regular-file 形狀，加上可解析的 `cash-skills.version`）拒絕 canonical source repository 並在診斷中指向 `./install-cash-skills.fish --self`，該判定 MUST NOT 以 contract mode 相等為條件，因為這些 marker 都不在 mode 正規化涵蓋的 managed inventory 內，mode 相等的判定會使 umask 偏移的 source clone 被誤判為一般 target；source判定完成後以no-follow `lstat`檢查portable manifest path，非source target只要該path存在（包含unsafe shape）就 MUST以`init_vendored_bundle`fail closed且不得讀取或修改receipt；驗證 `openspec/config.yaml` 安全可讀且 schema-valid（缺檔、unsafe 或 invalid 皆 fail closed，MUST NOT 建立任何檔案）；確認 `.cash-workspace.lock` 為既存且為空的 regular file（缺失或非空皆 fail closed，MUST NOT 建立或修復 stable 檔案）並取得 exclusive flock 全程持有；取得exclusive flock後 MUST再次以no-follow `lstat`重驗portable manifest path仍缺失，若它由missing變為任何present shape，MUST在mode正規化、inventory open或receipt publication前以`init_vendored_bundle`fail closed；檢核 runtime inventory 完整性；再以 no-follow `lstat` 確認 managed inventory 逐檔為 regular file 後，將其 mode 正規化為 contract modes（launcher `0755`、其餘 `0644`），非 regular file 形狀 MUST fail closed 且不 chmod。runtime 完整性檢核 MUST 先於 mode 正規化，使 runtime 集合不符時零 `chmod`。任一檢核失敗 MUST 以具名 error code（`init_python_version`、`init_outside_worktree`、`init_source_repo`、`init_vendored_bundle`、`init_config_invalid`、`init_inventory_invalid`、`init_write_failed`）與統一 JSON 錯誤 shape 輸出到 stdout 並以 exit 1 結束，且零檔案內容寫入；mode 正規化的 `chmod` 是唯一允許的 metadata 修改。持有 exclusive flock 之後對 target 檔案的每一次開檔 MUST 先以 `lstat` 判定形狀，`.cash-skills/receipt.tsv` 本身為 FIFO 等非 regular file 時 MUST 以 `init_write_failed` fail closed 而非阻塞在開檔。

簽發時，`--init-receipt` MUST 從現地 bytes 計算 digests、以本機 no-follow `lstat` 產生 stable identity，組出與 installer 安裝路徑相同 schema 的 receipt：`version` 值取自 installer module 內嵌的 `BUNDLE_VERSION` 常數，record 集合與現行 inventory 完全相同。寫入 MUST 沿用 same-directory owned temporary 與 atomic rename，`.cash-skills` 非 regular directory 時 MUST fail closed。既有 receipt 的 bytes 與 contract mode `0644` 都與重算結果一致時 MUST 回報 `current` 且零寫入；bytes 一致但 mode 已漂移時 MUST 走一般簽發路徑重寫並回報 `initialized`，因為 launcher 對 receipt 有 `0644` 的 mode 閘門，回報 `current` 會留下「成功卻不可用」的狀態。成功簽發回報 `initialized`，兩者皆輸出單行到 stdout 並以 exit 0 結束。簽發的信任根是 git clone 的現地內容：`--init-receipt` 是使用者主動的明示動作，launcher MUST NOT 在 receipt 缺失或無效時自動觸發它。

inventory 完整性檢核 MUST 以獨立於現地觀察狀態的期望集合進行。stable 與 24 個 canonical skill 的期望路徑為常數推導；runtime 的期望路徑 MUST 取自 installer module 內嵌的 `BUNDLE_RUNTIME_PATHS` 常數，MUST NOT 以現地 `rglob` 枚舉結果作為自身的期望集合——那會使比對恆真、缺檔與多檔皆不被偵測，並簽發一份自洽但錯的 receipt。現地 runtime 集合與 `BUNDLE_RUNTIME_PATHS` 不相等時 MUST 以 `init_inventory_invalid` fail closed，診斷 MUST 同時列出 missing 與 extra 兩個差集。

`cash_cli.installer` 的 import-time 相依（`installer.py` 自身、它的 `from .config import`，以及 `cash_cli/__init__.py` → `main.py` → `errors.py` 的匯入鏈，共 4 個；`cash_cli/__init__.py` 本身因 PEP 420 namespace package fallback 不屬此類）缺席時，`-m` 載入在任何檢核之前就以未捕捉的 `ModuleNotFoundError` 失敗，因此 MUST NOT 期待具名 error code；此限制與舊直譯器的 `SyntaxError` 屬同一類（import 先於任何檢查），已於 proposal Non-Goals 載明。`CASH-INIT-RECEIPT.md` MUST 明載哪些模組屬此類，且 MUST NOT 把它們列為 `init_inventory_invalid` 對照表的適用對象。

`BUNDLE_VERSION` 常數 MUST 由 contract test 斷言恆等於 `cash-skills.version` 的檔案內容；`BUNDLE_RUNTIME_PATHS` 常數 MUST 由 contract test 斷言恆等於 source 端 `source_inventory` 推導出的 runtime 路徑集合。

source repository 的 `AGENTS.md` 與 `CLAUDE.md` Cash guidance 區塊 MUST 各含信任模式分流：manifest存在時直接使用portable mode且不得執行`--init-receipt`；只有manifest缺失的receipt-based target在receipt缺失出現`bootstrap_invalid`時才提供完整初始化指令。既有guidance部署 MUST把該分流帶到每個target的managed block；target端的發現管道由此承擔，MUST NOT依賴source-only檔案（如`CASH-SKILLS.md`）作為target端引導。

#### Scenario: Fresh clone 一次初始化後 CLI 可用

- **GIVEN** 一個由 git clone 取得、含完整版控 inventory、沒有portable manifest且沒有 `.cash-skills/receipt.tsv` 的receipt-based installed target
- **WHEN** 在專案根執行 `PYTHONPATH=.cash-skills/lib python3 -s -P -B -m cash_cli.installer --init-receipt`
- **THEN** 模式回報 `initialized` 並簽發逐項通過 launcher `validate_receipt` 的 receipt
- **AND** 後續 `.cash-skills/bin/cash list --json` 成功執行，不以 `bootstrap_invalid` 或 `receipt_invalid` 失敗

#### Scenario: 有效 receipt 時零寫入

- **GIVEN** target 的 receipt 與現地內容重算結果逐 byte 等價且其 mode 為 `0644`
- **WHEN** 再次執行 `--init-receipt`
- **THEN** 模式回報 `current`
- **AND** `.cash-skills/receipt.tsv` 的 bytes 不變且無 temporary 檔殘留

#### Scenario: Umask 差異被 mode 正規化吸收

- **GIVEN** 一個在 umask `002` 環境 clone 的 installed target，其 launcher checkout 為 `0775`、其餘檔案為 `0664`
- **WHEN** 執行 `--init-receipt`
- **THEN** managed inventory 的 mode 被正規化為 contract modes（launcher `0755`、其餘 `0644`）
- **AND** 簽發的 receipt 通過 launcher `validate_receipt`

#### Scenario: 失敗路徑零內容寫入

- **WHEN** `--init-receipt` 在非 worktree top-level執行、或非source target存在portable manifest、或 `openspec/config.yaml` 缺失或invalid、或 `.cash-workspace.lock` 或任一**非 import-time 相依**的inventory檔案缺失、或 `.cash-workspace.lock` 非空、或任一managed路徑非regular file、或 `.cash-skills/receipt.tsv` 本身非regular file
- **THEN** 模式以對應的具名 error code 與統一 JSON 錯誤 shape 失敗（exit 1）
- **AND** 沒有任何檔案內容被建立或修改
- **AND** 模式不阻塞在任何開檔上

#### Scenario: Canonical source repository 被拒絕

- **WHEN** 在 canonical source repository 執行 `--init-receipt`
- **AND** 該 repository 的檔案 mode 為 umask `022` 或 umask `002` clone 產生的任一組
- **THEN** 模式以 `init_source_repo` 失敗
- **AND** 診斷包含 `./install-cash-skills.fish --self`
- **AND** `.cash-skills/bin/cash` 的 bytes 不因本 requirement 的任何行為而改變

#### Scenario: Vendored target 拒絕初始化 receipt

- **GIVEN** 非source target的portable manifest path存在，不論manifest valid或unsafe
- **WHEN** 執行`--init-receipt`
- **THEN** 模式以`init_vendored_bundle`與exit 1失敗
- **AND** 不讀取、不建立、不修改也不刪除receipt或任何bundle檔案

#### Scenario: Runtime inventory 缺檔時 fail closed

- **GIVEN** 一個沒有 receipt 的 installed target，其 `.cash-skills/lib/cash_cli/` 少了一個 canonical runtime 模組
- **AND** 該模組不是 `cash_cli.installer` 的 import-time 相依
- **WHEN** 執行 `--init-receipt`
- **THEN** 模式以 `init_inventory_invalid` 失敗（exit 1）且診斷含該缺檔路徑
- **AND** 沒有 receipt 被建立
- **AND** 後續 `.cash-skills/bin/cash list --json` MUST NOT 因 receipt 通過驗證而以未捕捉的 `ModuleNotFoundError` 失敗

#### Scenario: Runtime inventory 多檔時 fail closed

- **GIVEN** 一個沒有 receipt 的 installed target，其 `.cash-skills/lib/cash_cli/` 多了一個不屬於 canonical 集合的 `.py`
- **WHEN** 執行 `--init-receipt`
- **THEN** 模式以 `init_inventory_invalid` 失敗（exit 1）且診斷含該多餘路徑
- **AND** 沒有 receipt 被建立，該 target 的後續 `install-cash-skills.fish --target` MUST NOT 因 record 數不符而永久失敗

#### Scenario: 版本常數受 contract test 守衛

- **WHEN** `BUNDLE_VERSION` 與 `cash-skills.version` 的內容不相等
- **THEN** contract test 以非零結束並指出兩個值
- **AND** 當 `BUNDLE_RUNTIME_PATHS` 與 source 端 `source_inventory` 推導出的 runtime 路徑集合不相等時，contract test 同樣以非零結束並指出差集

#### Scenario: 併發下以 stable lock 序列化

- **WHEN** `--init-receipt` 與 launcher 或 installer 同時對同一 target 執行
- **THEN** `--init-receipt` 在取得 `.cash-workspace.lock` 的 exclusive flock並重驗manifest仍缺失後，才進行 mode 正規化、檢核與簽發
- **AND** receipt 的發佈維持 atomic，任何併發讀取者只會看到舊或新完整內容

#### Scenario: Manifest 在 preflight 後出現時拒絕簽發 receipt

- **GIVEN** `--init-receipt`首次檢查時portable manifest path缺失
- **AND** 併發 `--vendor`在它取得exclusive flock前發布manifest
- **WHEN** `--init-receipt`取得同一stable lock的exclusive flock
- **THEN** 它重驗manifest path、以`init_vendored_bundle`與exit 1失敗
- **AND** 不執行mode正規化、不讀寫receipt，也不留下temporary檔

#### Scenario: Init 指引隨 guidance 部署到達 target

- **GIVEN** source repository 的 `AGENTS.md` 與 `CLAUDE.md` Cash guidance 區塊含portable／receipt分流與 `--init-receipt` 指引段
- **WHEN** installer 對任一 target 完成安裝或更新
- **THEN** 該 target 的 `AGENTS.md` 與 `CLAUDE.md` managed guidance block 含同一信任模式分流
- **AND** manifest-present target不被要求初始化，manifest缺失的receipt-based target在 `bootstrap_invalid` 情境下可由該指引得知初始化指令

#### Scenario: Inventory 未擴充使既有 targets 正常升級

- **GIVEN** 既有 registry targets 持有前一版本簽發的 receipt
- **WHEN** 新版本以 `--all` 部署
- **THEN** 每個 target 的既有 receipt 以相同 record 集合正常解析並走 update 路徑
- **AND** 沒有 target 因 record 集合不符而以 execution error 失敗

<!-- @trace
source: add-repo-vendored-cash-bundle
updated: 2026-07-29
code:
  - .cash-skills/bin/cash
  - .cash-skills/lib/cash_cli/installer.py
  - .cash-skills/manifest.tsv
  - scripts/cash-skills/tests/skill-checks.fish
  - scripts/cash-skills/tests/test_bundle_version_history.py
  - scripts/cash-skills/tests/test_init_receipt.py
  - scripts/cash-skills/tests/test_installer_runtime.py
tests:
  - scripts/cash-skills/tests/test_init_receipt.py
  - scripts/cash-skills/tests/test_installer_runtime.py
-->

### Requirement: Portable manifest 啟動信任模式

Cash launcher SHALL在 `.cash-skills/manifest.tsv` path存在時提供完全唯讀的portable manifest啟動信任模式，不論machine-local receipt是否同時存在。launcher MUST在任何open前以no-follow `lstat`判斷manifest path presence；path存在（包含broken symlink、FIFO、directory、hard link或其他unsafe shape）時 MUST只走portable gate，驗證失敗 MUST以 `manifest_invalid`與exit 1 fail closed且 MUST NOT fallback到receipt。只有manifest path缺失才可判斷receipt；receipt存在時走既有receipt gate，兩者皆缺失時維持 `bootstrap_invalid`與exit 1。valid manifest是committed trust-mode marker，因此pull後殘留的ignored舊receipt MUST NOT shadow portable mode。

`.cash-skills/manifest.tsv` MUST 是 LF-terminated UTF-8 canonical TSV，依序包含 `format<TAB>cash-portable-manifest-v1`、`bundle_version<TAB><strict-MAJOR.MINOR.PATCH>`、`runtime_generation<TAB><lowercase-sha256>`，再依 receipt canonical inventory順序包含 `<kind><TAB><project-relative-path><TAB><lowercase-sha256><TAB><git-mode>` records。`kind` MUST 僅為 `stable`、`runtime` 或 `skill`；`git-mode` MUST 僅為 `100644` 或 `100755`。records MUST恰含 stable launcher、stable workspace lock、依 UTF-8 path bytes排序的 canonical runtime paths及 canonical 24-skill paths，不得 duplicate、missing、extra、unknown、absolute、dot-segment或 root-escaping path。manifest MUST NOT記錄自身、receipt、`st_dev`或`st_ino`，且 portable manifest的存在 MUST NOT擴充 receipt schema或 record集合。

manifest path只有在no-follow shape判定為single-link regular file後才可open；manifest自身的observed POSIX mode MUST正規化為non-executable Git logical class `100644`，executable class `100755` MUST以 `manifest_invalid`失敗；unsafe-present、unreadable或open後pathname／FD identity不同都 MUST以 `manifest_invalid`失敗，FIFO等shape MUST NOT阻塞。launcher MUST先安全開啟 launcher與 `.cash-workspace.lock`，依 argv取得既有 shared／exclusive flock，再驗證對應信任模式且持有同一 lock FD至 process結束。portable gate MUST將 observed POSIX mode正規化成 Git logical executable class後與 `git-mode` 比較，使常見 umask `022`與`002` clone產生的 `0644`／`0755`或`0664`／`0775`皆可按相同 Git mode通過；它仍 MUST拒絕錯誤 executable class。manifest與每個 inventory path都 MUST為 root-contained、non-symlink、single-link regular file；hash時 MUST比較 opened FD與 pathname的 `st_dev/st_ino`，digest與runtime generation都 MUST相符，且runtime record的exact source bytes MUST保留供import。runtime expected paths MUST取自manifest records並符合受約束namespace與canonical排序，launcher MUST另列舉現地 `.cash-skills/lib/cash_cli/`下的 `.py` paths並拒絕相對expected set的missing或extra；expected set MUST NOT由該現地列舉結果反向產生。launcher MUST在任何managed runtime import前設定 `sys.dont_write_bytecode = True`並提供 `VerifiedSourceLoader`；它可繼承 `SourceFileLoader`以配合 `FileFinder`，但 `get_code` MUST只以portable gate保留的verified bytes呼叫 `source_to_code`，MUST NOT呼叫superclass cache path或寫入cache。launcher在 `sys.path_importer_cache`為project-local library root及每個含manifest runtime record的 `cash_cli` package directory安裝 `FileFinder`／`VerifiedSourceLoader`；此限制 MUST只套用project-local `cash_cli` namespace且 MUST NOT改變stdlib importer。timestamp／hash-valid或sourceless `.pyc` MUST NOT被 `cash_cli` import使用。portable gate與後續read command MUST NOT建立、修改、chmod或刪除任何檔案。

本 requirement 與 `Project-local Cash CLI runtime`、`Cash workflow command surface`、`Bundle 安裝與 runtime receipt`及 `Target-local receipt 初始化`的本文共同定義manifest-present啟動行為：launcher MUST在receipt與portable manifest中恰完成一個gate；manifest缺失時既有receipt-only規則不變。

#### Scenario: Fresh vendored clone 不需初始化

- **GIVEN** 一個 canonical Git clone含完整受管 inventory與 valid `.cash-skills/manifest.tsv`
- **AND** clone不含 `.cash-skills/receipt.tsv`
- **WHEN** 在 umask `022`或`002`產生的任一合法 Git logical mode組合下執行 `.cash-skills/bin/cash list --json`
- **THEN** launcher取得正確 shared lock、通過 portable gate並載入 project-local runtime
- **AND** command成功，且包含ignored files、directories與mtime的完整filesystem snapshot前後相同

#### Scenario: 舊或無效 receipt 不遮蔽 vendored mode

- **GIVEN** target同時有 valid portable manifest與存在但 bytes、mode、identity或 shape無效的 receipt path
- **WHEN** 啟動任一 Cash command
- **THEN** launcher只驗證portable manifest並成功執行
- **AND** launcher不讀取、不修改也不刪除non-authoritative receipt residue

#### Scenario: Manifest drift fail closed

- **WHEN** portable manifest的 schema、version、row order、path set、Git mode、digest或runtime generation無效，或任一受管 path的 bytes、logical executable class或 filesystem shape與 record不符
- **THEN** launcher以 `manifest_invalid`與 exit 1失敗
- **AND** 即使存在valid receipt，command仍不 import managed runtime且不修改 workspace

#### Scenario: Unsafe manifest shape 在 open 前失敗

- **WHEN** manifest path是broken symlink、FIFO、directory、hard link或其他non-regular shape
- **THEN** launcher以 `manifest_invalid`與exit 1失敗
- **AND** 不把path視為missing、不fallback到receipt，也不阻塞在open

#### Scenario: Executable manifest fail closed

- **GIVEN** manifest是root-contained、single-link regular file且bytes canonical，但observed mode正規化為Git logical class `100755`
- **WHEN** 啟動任一Cash command
- **THEN** launcher在managed runtime import前以 `manifest_invalid`與exit 1失敗
- **AND** 不fallback到receipt、不chmod manifest且workspace零寫入

#### Scenario: Portable help 完成 portable gate

- **GIVEN** target有valid portable manifest且receipt缺失或殘留
- **WHEN** 執行 `.cash-skills/bin/cash --help`或 `.cash-skills/bin/cash --help --json`
- **THEN** launcher取得shared lock、完成portable gate後輸出help
- **AND** invalid manifest仍在輸出help前以 `manifest_invalid`失敗

#### Scenario: Portable generation 受同一 stable lock 保護

- **GIVEN** launcher read command與 `--vendor` update對同一target併發
- **WHEN** read command取得shared lock並驗證portable manifest
- **THEN** 它只從manifest驗證過的 `.py` source載入同一generation的runtime，忽略既存且可被一般import接受的不同payload `.pyc`
- **AND** updater取得exclusive lock後才可發布下一個完整generation

#### Scenario: 兩種信任資料皆缺失

- **GIVEN** receipt與portable manifest都缺失
- **WHEN** 啟動任一 Cash command
- **THEN** launcher維持 `bootstrap_invalid`與 exit 1
- **AND** 不自動執行 `--init-receipt`或 installer

#### Scenario: Manifest expected set 不由現地狀態推導

- **WHEN** runtime或skill inventory相對 canonical expected set缺一筆、多一筆或重複一筆
- **THEN** portable gate以 `manifest_invalid`失敗並指出不一致
- **AND** 現地枚舉結果 MUST NOT取代 manifest runtime records、launcher stable／skill constants與受約束 runtime namespace共同定義的 expected set

#### Scenario: Canonical source fresh clone 使用 committed manifest

- **GIVEN** canonical source repository的fresh clone含 valid committed manifest但沒有 machine-local receipt
- **WHEN** 直接執行 project-local Cash launcher
- **THEN** launcher使用 portable mode成功執行
- **AND** 不要求先執行 source-only `--self`

<!-- @trace
source: add-repo-vendored-cash-bundle
updated: 2026-07-29
code:
  - .cash-skills/bin/cash
  - .cash-skills/lib/cash_cli/installer.py
  - .cash-skills/manifest.tsv
  - scripts/cash-skills/tests/skill-checks.fish
  - scripts/cash-skills/tests/test_bundle_version_history.py
  - scripts/cash-skills/tests/test_init_receipt.py
  - scripts/cash-skills/tests/test_installer_runtime.py
tests:
  - scripts/cash-skills/tests/test_init_receipt.py
  - scripts/cash-skills/tests/test_installer_runtime.py
-->

### Requirement: Repo-vendored Cash bundle 發佈

`cash_cli.installer` SHALL新增與 `--target`、`--self`、`--register`、`--unregister`、`--list`、`--all`及 `--init-receipt`互斥的 `--vendor <project>` mode，並允許 `--dry-run`與 `--force`。vendor target MUST是安全、既存、非 canonical source的 Git worktree top-level。preflight MUST對每個planned managed inventory、manifest、config與guidance path驗證其已由Git tracked，或不受repository `.gitignore`、`.git/info/exclude`與global exclude規則排除；任何blocked path MUST在首次target write前一次列出並fail closed，final publication前 MUST以相同path集合重驗。空值、root、symlink、non-Git、Git子目錄、unsafe config／guidance／inventory boundary或blocked planned path MUST fail closed，且 `--force` MUST NOT繞過。

`cash-skill-workflows` capability之 `手動的 cash 專案 registry` requirement已將 `--vendor`明列為非registry的repo-vendored publication；registry資料格式、registry操作模式與既有receipt-based batch語意不變。

`--vendor` MUST以 `source_inventory`作為 receipt與portable manifest共用的 version、runtime generation及受管 record單一來源，並 deterministic產生 canonical manifest。fresh publication MUST在同一 stable lock的 exclusive FD與 recoverable transaction中發佈 launcher、lock、runtime、canonical 24 skills、必要 config／guidance及manifest，MUST NOT建立 receipt；它 MUST沿用 receipt-based target的 `.gitignore` plan以排除 `.cash-skills/receipt.tsv`、`.cash-skills/state/`與 `__pycache__/`，但 MUST NOT排除portable manifest或其他planned publication path。manifest MUST是最後一筆trust-bearing managed bundle publication；唯一可排在它之後的operation是 `receipt_delete` cleanup。journal在manifest前失敗 MUST rollback舊gate，manifest成功後 MUST進入 `portable_cutover` phase並在後續失敗時保留新portable gate、roll forward完成cleanup。既有 vendored baseline的mode比較 MUST使用manifest的 Git logical mode，合法 umask造成的完整POSIX permission差異 MUST NOT構成managed drift。成功後相同 source重跑 MUST回報 `Result: current`且零寫入；有合法較舊bundle或 project-owned managed digest／logical-mode drift時依既有 update／conflict規則分類，`--force`只可收斂 replaceable managed bytes與mode class，不得接受 unsafe shape、version downgrade、invalid baseline manifest或 unapproved launcher drift。`--dry-run` MUST執行相同分類與 revalidation但 target零寫入。

receipt與manifest都缺失時，zero managed inventory MUST分類為fresh並在real run回報 `Result: update`；stable launcher／lock、runtime及canonical skills完整且逐檔符合source digest、Git logical mode與safe shape時 MUST分類為receiptless adoption，在exclusive lock下保留相符bytes並最後發布manifest。partial、unknown或different inventory未帶 `--force`時 MUST conflict；`--force`只可補齊或替換canonical expected path上的missing／different replaceable runtime與skills。unknown extra runtime及unknown stable drift即使帶 `--force`也 MUST fail closed。stable prefix只能是absent、safe empty lock、current launcher或allowlisted old launcher。

manifest absent的receipt-based target只有在既有 receipt完整通過receipt schema、identity、inventory及source版本判定時，才可由明示 `--vendor`轉換。轉換 MUST在同一transaction中發佈新inventory並以manifest publication完成trust-mode cutover，之後刪除receipt作為machine-local cleanup。若crash發生在manifest與cleanup之間，launcher因manifest-first precedence仍 MUST可用，recovery MUST完成cleanup。manifest已存在時，safe regular single-link receipt是non-authoritative residue，`--vendor` MAY不解析其內容而transactionally刪除；unsafe receipt shape仍 MUST fail closed。反向轉換 MUST NOT隱式發生：direct `--target`、`--register`及 `--all`遇到 manifest時 MUST拒絕並指出該 target由 `--vendor`管理。

canonical source的 `.cash-skills/manifest.tsv` MUST逐 byte等於同一 serializer對現行 source inventory的輸出。source-only `--self` SHALL在既有exclusive stable lock transaction中發布該manifest並刪除任何source receipt residue；除了manifest與receipt cleanup外仍 MUST零寫入。real run需要變更時 MUST回報 `Result: bootstrap`，dry-run對同一計畫 MUST回報 `Result: would-bootstrap`且零寫入，canonical manifest且receipt absent時 MUST回報 `Result: current`且零寫入。`Bundle 安裝與 runtime receipt`及 `Installer 與 legacy cleanup filesystem boundaries`的本文同步定義此source-only `--self`行為。`--init-receipt`在一般不含manifest的 receipt-based target維持現行行為；在 vendored target MUST以具名 `init_vendored_bundle`、統一 JSON error shape與 exit 1 fail closed且零內容寫入，canonical source仍優先使用既有 `init_source_repo`；`Target-local receipt 初始化`的具名error code清單已包含 `init_vendored_bundle`。

任何 launcher、runtime、skill、portable manifest schema／record或 Git logical mode改變 MUST在第一個受 guard的 production artifact改動前，將 `cash-skills.version`調升為嚴格較大版本。`.cash-skills/manifest.tsv` MUST受 first-parent bundle history與 canonical serializer contract tests守衛，但 MUST NOT加入 receipt records，使既有 receipt target可用原 record集合正常升級。

#### Scenario: 維護者一次發佈後提交

- **GIVEN** 一個符合 prerequisite且尚無 Cash inventory的團隊 Git repository
- **WHEN** 維護者執行 `--vendor <project>`
- **THEN** installer回報 `Result: update`並發佈完整 vendored inventory與portable manifest，但不建立 receipt
- **AND** 維護者可將受管檔案提交，其他成員clone後符合「Fresh vendored clone 不需初始化」scenario

#### Scenario: Planned path 被任一 Git exclude 阻擋

- **GIVEN** 任一planned publication path未tracked，且被repository、info或global exclude中的 `.cash-skills/`、`*.py`、`.agents/`、`.claude/`或其他pattern匹配
- **WHEN** 執行 `--vendor <project>`或 `--vendor <project> --force`
- **THEN** installer在首次write前列出全部blocked paths並失敗
- **AND** 不發布manifest或任何partial inventory

#### Scenario: Receiptless 完整 inventory 可認養

- **GIVEN** target沒有manifest與receipt，但stable prefix、runtime及canonical skills完整符合source digest、Git logical mode與safe shape
- **WHEN** 執行 `--vendor <project>`
- **THEN** installer保留相符bytes、收斂必要project files並最後發布manifest
- **AND** partial或different inventory未帶 `--force`時conflict，unknown stable drift即使帶 `--force`也fail closed

#### Scenario: Vendored update 與 current

- **GIVEN** target具有 valid較舊或同版本portable manifest及相符的受管 baseline
- **WHEN** 維護者以較新或相同 source執行 `--vendor <project>`
- **THEN** 較舊 target在 transaction內更新並回報 `Result: update`，相同 canonical target回報 `Result: current`且零寫入
- **AND** 較新 target拒絕 downgrade且零寫入

#### Scenario: Vendored managed drift 需要 force

- **GIVEN** valid manifest所記錄的 replaceable runtime或skill在 target已 drift但 filesystem shape仍安全
- **WHEN** 執行 `--vendor <project>`且未帶 `--force`
- **THEN** installer回報 `Result: conflict`且 target零寫入
- **WHEN** 再次明示 `--vendor <project> --force`
- **THEN** installer只收斂受管 replaceable內容並發佈新manifest，project-owned內容維持不變

#### Scenario: Receipt target 明示轉換

- **GIVEN** target沒有manifest且有完整有效 receipt
- **WHEN** 維護者執行 `--vendor <project>`
- **THEN** installer在同一 recoverable transaction完成受管更新，以manifest發佈完成cutover，再清除 receipt
- **AND** manifest發佈後即使cleanup前crash，下一次launcher仍只走portable mode且recovery可完成cleanup

#### Scenario: Invalid receipt 不能被 vendor force 合法化

- **GIVEN** receipt-based target的 receipt或 stable identity無效
- **WHEN** 執行 `--vendor <project>`或 `--vendor <project> --force`
- **THEN** installer在首次 write前以 execution error失敗
- **AND** 不建立manifest、不刪除receipt且不修改受管檔案

#### Scenario: Receipt installer 拒絕 vendored target

- **GIVEN** target有portable manifest，不論 receipt缺失或殘留
- **WHEN** 該 target被傳給 `--target`、`--register`或由 `--all`處理
- **THEN** receipt-based mode拒絕隱式轉換並提供 `--vendor`指引
- **AND** target與registry不因該 target被修改

#### Scenario: Self refresh 維持 canonical manifest

- **GIVEN** canonical source的 versioned inventory已合法調升但manifest或本機receipt尚未同步
- **WHEN** 執行 source-only `--self`
- **THEN** installer在同一exclusive lock transaction發布canonical manifest、清除source receipt residue並回報 `Result: bootstrap`
- **AND** 重複執行回報 `Result: current`且manifest零寫入、receipt維持absent

<!-- @trace
source: add-repo-vendored-cash-bundle
updated: 2026-07-29
code:
  - .cash-skills/bin/cash
  - .cash-skills/lib/cash_cli/installer.py
  - .cash-skills/manifest.tsv
  - scripts/cash-skills/tests/skill-checks.fish
  - scripts/cash-skills/tests/test_bundle_version_history.py
  - scripts/cash-skills/tests/test_init_receipt.py
  - scripts/cash-skills/tests/test_installer_runtime.py
tests:
  - scripts/cash-skills/tests/test_init_receipt.py
  - scripts/cash-skills/tests/test_installer_runtime.py
-->

### Requirement: 受控 launcher bootstrap migration

Cash installer SHALL允許 stable launcher replacement，但僅限 `APPROVED_LAUNCHER_TRANSITIONS`明列的 `(old_digest, new_digest, introduced_version)`組合。target launcher已等於source時為no-op；否則target old digest與source new digest MUST命中同一筆transition，且source version MUST大於等於 `introduced_version`。history gate MUST驗證new launcher bytes恰在 `introduced_version`首次出現；source launcher自該版後未改變時，較高source bundle version MAY跨過中間版本使用同一transition。未知launcher、僅部分digest、wildcard、source digest不同、source version低於introduced version或 `--force`繞過 MUST一律以execution error fail closed。

launcher replacement MUST使用 `InstallTransaction` journal schema v3的專用 `launcher` operation，在既有或monotonic建立的 `.cash-workspace.lock` exclusive FD下執行；journal MUST記錄old launcher bytes、mode與device/inode，新installer MUST仍能讀取及恢復既有schema v2 journal。receipt-based upgrade MUST使用專用dynamic `receipt` operation，在launcher實際cutover後才從pathname重新取得launcher／lock `st_dev/st_ino`並組出新receipt，MUST NOT在transaction planning時把舊launcher inode固化進desired receipt。`.cash-workspace.lock`仍 MUST永久保持同一inode且不得unlink／rename。

publication failure的rollback MAY以atomic write還原old launcher bytes而取得新inode，但完成前 MUST從journal保存的old receipt重建相同old version、runtime generation、record paths、digests與modes，只將stable launcher／lock identity重綁到rollback後現地inode，再原子發布rebound old receipt。該receipt通過完整receipt gate後才算rollback完成；rebind失敗 MUST保留journal供matching-or-newer installer重試。journal在operation實際write前先標示published所造成的crash，也 MUST走相同rebind流程。vendored rollback依manifest gate復原，不需保留launcher inode。fault coverage MUST包含journal advance前後、launcher replace前後、dynamic receipt前後、manifest publication前後及receipt cleanup前後；每個recovery結果都 MUST通過完整舊或新gate。

本 requirement 是 `Project-local Cash CLI runtime`與 `Bundle 安裝與 runtime receipt` 中 stable launcher bytes／inode不得在 upgrade替換規則的唯一例外。bundle history contract MUST繼續永久凍結 `.cash-workspace.lock`；launcher差異只有在 bundle version已嚴格調升且 exact transition已登錄時通過。任何普通 runtime／skill更新不得隱含 launcher migration。

#### Scenario: 既有 receipt target 升級到新 launcher

- **GIVEN** target持有 valid舊receipt且launcher digest是 allowlist中的 exact old值
- **AND** source launcher digest命中同一transition的new digest，source bundle version大於等於introduced version
- **WHEN** 執行 direct或batch installer upgrade
- **THEN** installer在既有 workspace lock inode下 transactionally替換launcher並最後發布新receipt
- **AND** upgrade後 launcher以新 identity通過 receipt gate

#### Scenario: 跨版本沿用已引入的 launcher transition

- **GIVEN** launcher transition在版本V引入，後續版本W未再改變source launcher bytes
- **AND** target仍使用該transition的old launcher，W嚴格高於V
- **WHEN** 以版本W installer升級target
- **THEN** installer依同一old／new digest transition完成migration
- **AND** history gate仍只把V視為new launcher bytes的introduced version

#### Scenario: 未核准 launcher drift fail closed

- **WHEN** target launcher digest不等於source且不命中exact transition，或source new digest不符、source version低於introduced version
- **THEN** installer在首次 target write前失敗
- **AND** `--force`不得改變結果

#### Scenario: Launcher publication failure 可復原

- **GIVEN** fault injection使transaction在journal advance、launcher replacement、dynamic receipt、manifest publication或receipt cleanup任一邊界失敗或 crash
- **WHEN** 同一次rollback完成或下一次 matching-or-newer installer執行recovery
- **THEN** receipt-based rollback以old bundle內容與rebound stable identity通過完整receipt gate，或target完成完整新gate
- **AND** workspace lock inode保持不變，schema v2／v3 journal均依契約恢復並在成功後清除

#### Scenario: History gate拒絕未治理變更

- **WHEN** launcher bytes改變但bundle version未嚴格調升、exact transition缺失或 `.cash-workspace.lock` bytes／Git mode改變
- **THEN** bundle history contract test以非零結束
- **AND** 不把該差異視為一般 replaceable artifact更新

<!-- @trace
source: add-repo-vendored-cash-bundle
updated: 2026-07-29
code:
  - .cash-skills/bin/cash
  - .cash-skills/lib/cash_cli/installer.py
  - .cash-skills/manifest.tsv
  - scripts/cash-skills/tests/skill-checks.fish
  - scripts/cash-skills/tests/test_bundle_version_history.py
  - scripts/cash-skills/tests/test_init_receipt.py
  - scripts/cash-skills/tests/test_installer_runtime.py
tests:
  - scripts/cash-skills/tests/test_init_receipt.py
  - scripts/cash-skills/tests/test_installer_runtime.py
-->

### Requirement: touched state 的 task attribution 對齊

`.cash-skills/state/touched/<name>.json` 的 per-task 條目以位置式 `task_id` 為鍵，而該 id 由 `tasks.md` 中 task 條目的順序推導；在 `tasks.md` 插入或刪除條目會使既有條目的 `task_id` 與其真正對應的 task 整體錯位。CLI SHALL 在讀取既有 touched state 時對齊該 attribution，使消費端取得的視圖指向正確的 task。

對齊 MUST 以 `task_desc` 為語意錨點、`task_id` 為衍生的位置索引，方向為以描述反推 id：依目前 `tasks.md` 建立「描述 → 位置式 id」映射，對每個 `task_id` 不等於保留值 `review-loop` 的條目，若其 `task_desc` 在映射中且對應 id 與現存 `task_id` 不同，MUST 改寫該條目的 `task_id`。

對齊 MUST NOT 改寫任何條目的 `task_desc`。相反方向（依位置改寫 `task_desc`）MUST NOT 採用：`task_desc` 是偵測漂移的唯一證據，改寫它會把原屬於某個 task 的檔案清單重新標記到另一個 task 名下。

某條目的 `task_desc` 在映射中完全找不到時，CLI MUST 以 `touched_invalid` fail closed，且錯誤訊息 MUST 包含該 `task_desc`。位置式 id 無法區分「條目被刪除」與「描述被改寫」，任何自動處置都可能把錯誤配對簽為合法。

`task_id` 為 `review-loop` 的保留條目 MUST 豁免於對齊與 fail closed 判定。

對齊 MUST NOT 改動任何條目的 `files`：它只重新指派 `task_id`，檔案歸屬本身不變。

touched state 的 `legacy_import` 非 `null` 時，其條目的 `task_desc` 並非由本專案的 `tasks.md` 產生，因此 MUST 豁免上述 fail closed：對齊 MUST 只做描述對得上的 `task_id` 改寫，描述查無此項時 MUST 保留該條目原樣並繼續。

對齊需要 `tasks.md` 作為輸入，取不到時 MUST 原樣回傳而非失敗：`openspec/changes/<name>/tasks.md` 不存在時 MUST 再查 `openspec/changes/.parked/<name>/tasks.md`，兩者皆不存在才原樣回傳；讀取或解析 `tasks.md` 的任何失敗——包含 task 標籤缺失或重複的 `task_id_invalid`、`tasks.md` 為 symlink 的 `unsafe_path`、內容非 UTF-8、以及 `tasks.md` 是目錄——MUST 被捕捉並原樣回傳，MUST NOT 從對齊路徑逸出。

對齊完成後 MUST 檢查 `task_id` 唯一性。`legacy_import` 為 `null` 時重複 MUST 以 `touched_invalid` 失敗；非 `null` 時重複代表某個依豁免保留原樣的條目其陳舊 `task_id` 與另一條目對齊後的新 id 相撞，此時 MUST 放棄本次對齊並原樣回傳，MUST NOT 失敗。通過檢查後 MUST 依 `task_id` 的 UTF-8 bytes 重新排序；僅順序改變而條目內容不變時，仍 MUST 視為對齊改變了內容。

對齊本身 MUST NOT 自行寫入檔案，但其結果 MUST 被持久化：`touched ensure` MUST 在對齊改變了內容時把對齊後的值寫回 `.cash-skills/state/touched/<name>.json`，即使該檔已存在；`touched record` MUST 把「對齊是否改變內容」併入其寫入條件。對齊未改變任何內容時 `touched ensure` MUST NOT 寫入，維持其既有的零寫入行為。只在記憶體中對齊不足以達成本 requirement 的目的，因為 `cash-commit` 直接讀取該檔而非透過 CLI。

#### Scenario: 插入 task 造成位移時依描述對齊

- **GIVEN** change `demo-change` 的 touched state 有一筆 `task_id` 為 `1`、`task_desc` 為 `1.1 改寫 A` 的條目
- **AND** `tasks.md` 在該 task 之前新增了一條 task，使 `1.1 改寫 A` 的位置式 id 變為 `2`
- **WHEN** CLI 讀取該 touched state
- **THEN** 該條目的 `task_id` 對齊為 `2`
- **AND** 該條目的 `task_desc` 維持 `1.1 改寫 A`
- **AND** 該條目的 `files` 不變

#### Scenario: 描述查無此項時 fail closed

- **GIVEN** change `demo-change` 的 touched state 有一筆 `task_desc` 為 `1.1 改寫 A` 的條目
- **AND** `tasks.md` 中已不存在描述為 `1.1 改寫 A` 的 task
- **WHEN** CLI 讀取該 touched state
- **THEN** CLI 以 `touched_invalid` 失敗
- **AND** 錯誤訊息包含 `1.1 改寫 A`

#### Scenario: 保留條目豁免

- **GIVEN** change `demo-change` 的 touched state 含 `task_id` 為 `review-loop`、`task_desc` 為 `Review loop outputs` 的條目
- **AND** `tasks.md` 中不存在描述為 `Review loop outputs` 的 task
- **WHEN** CLI 讀取該 touched state
- **THEN** CLI 不因該保留條目而失敗
- **AND** 該條目的 `task_id` 與 `task_desc` 皆不被改寫

#### Scenario: tasks.md 不存在時跳過對齊

- **GIVEN** change `demo-change` 沒有 `openspec/changes/demo-change/tasks.md`
- **WHEN** CLI 讀取該 change 的 touched state
- **THEN** CLI 原樣回傳該 state
- **AND** 不因缺少 `tasks.md` 而失敗

#### Scenario: 對齊後 id 重複時 fail closed

- **GIVEN** change `demo-change` 的 touched state 其 `legacy_import` 為 `null`
- **AND** 該 state 有兩筆非保留條目
- **AND** 兩者的 `task_desc` 依目前 `tasks.md` 對應到同一個位置式 id
- **WHEN** CLI 讀取該 touched state
- **THEN** CLI 以 `touched_invalid` 失敗

#### Scenario: legacy 來源的 state 在 id 重複時放棄對齊

- **GIVEN** change `demo-change` 的 touched state 其 `legacy_import` 非 `null`
- **AND** 其中一筆條目的 `task_desc` 在 `tasks.md` 中查無此項，依豁免保留其陳舊 `task_id`
- **AND** 另一筆條目對齊後的新 `task_id` 與該陳舊 id 相同
- **WHEN** CLI 讀取該 touched state
- **THEN** CLI 不以 `touched_invalid` 失敗
- **AND** 回傳的 state 與磁碟上的原值逐字相同，未帶任何已套用的 `task_id` 改寫
- **AND** `.cash-skills/state/touched/demo-change.json` 的內容不變

#### Scenario: 僅順序改變時仍視為對齊改變了內容

- **GIVEN** change `demo-change` 的 touched state 其全部條目的 `task_id` 都已與 `tasks.md` 一致
- **AND** 該 state 的 `touched` 陣列未依 `task_id` 的 UTF-8 bytes 排序
- **WHEN** 執行 `touched ensure demo-change`
- **THEN** `.cash-skills/state/touched/demo-change.json` 被更新為重新排序後的值

#### Scenario: 對齊不自行寫檔

- **GIVEN** change `demo-change` 的 touched state 存在需要對齊的條目
- **WHEN** 執行只讀取 touched state 而不寫入的操作
- **THEN** `.cash-skills/state/touched/demo-change.json` 的內容不變

#### Scenario: 對齊改變內容時 touched ensure 寫回磁碟

- **GIVEN** change `demo-change` 的 touched state 存在且有一筆 `task_id` 與其 `task_desc` 不再對應的條目
- **WHEN** 執行 `touched ensure demo-change`
- **THEN** `.cash-skills/state/touched/demo-change.json` 的內容被更新為對齊後的值
- **AND** 後續直接讀取該檔的消費端取得已對齊的 `task_id`

#### Scenario: 對齊改變內容時 touched record 也寫回磁碟

- **GIVEN** change `demo-change` 的 touched state 有一筆 `task_id` 與其 `task_desc` 不再對應的條目
- **AND** `review-loop` 條目已含 `openspec/signals/demo.md`
- **WHEN** 執行 `touched record demo-change --path openspec/signals/demo.md`
- **THEN** command 成功
- **AND** `.cash-skills/state/touched/demo-change.json` 被更新為對齊後的值
- **AND** 即使 `review-loop` 條目的合併結果與載入值相同，仍因對齊改變了內容而寫入

#### Scenario: 對齊未改變內容時 touched ensure 不寫入

- **GIVEN** change `demo-change` 的 touched state 全部條目的 `task_id` 都已與 `tasks.md` 一致
- **WHEN** 執行 `touched ensure demo-change`
- **THEN** `.cash-skills/state/touched/demo-change.json` 的內容不變

#### Scenario: legacy 來源的 state 豁免 fail closed

- **GIVEN** change `demo-change` 的 touched state 其 `legacy_import` 非 `null`
- **AND** 其中一筆條目的 `task_desc` 在 `tasks.md` 中查無此項
- **WHEN** CLI 讀取該 touched state
- **THEN** CLI 不因該條目而失敗
- **AND** 該條目原樣保留

#### Scenario: tasks.md 解析失敗時原樣回傳

- **GIVEN** change `demo-change` 的 `tasks.md` 存在但含缺少標籤的 task 行
- **WHEN** CLI 讀取該 change 的 touched state
- **THEN** CLI 原樣回傳該 state
- **AND** 不以 `task_id_invalid` 失敗

#### Scenario: parked change 仍能對齊

- **GIVEN** change `demo-change` 已被 park，其目錄位於 `openspec/changes/.parked/demo-change/`
- **AND** `openspec/changes/demo-change/tasks.md` 不存在
- **WHEN** CLI 讀取該 change 的 touched state
- **THEN** CLI 以 `openspec/changes/.parked/demo-change/tasks.md` 作為對齊輸入

<!-- @trace
source: guard-task-state-integrity
updated: 2026-08-23
code:
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-commit/SKILL.md
  - .cash-skills/lib/cash_cli/commands/tasks.py
  - .cash-skills/lib/cash_cli/installer.py
  - .cash-skills/manifest.tsv
  - .claude/skills/cash-archive/SKILL.md
  - .claude/skills/cash-commit/SKILL.md
  - scripts/cash-cli/tests/test_creation_task_lifecycle.py
  - scripts/cash-cli/tests/test_sync_archive_transaction.py
tests:
-->

### Requirement: Test quality discipline 使用單一來源

Cash-owned `DISCIPLINES["test-quality"]` SHALL是`instructions --skill test-quality`回傳內容的唯一完整語意來源。該discipline只治理已決定新增或修改的測試，MUST NOT要求沒有測試需求的task為形式而新增測試，且MUST保持tool與framework中立。

canonical instruction MUST要求：寫test body前命名一個realistic production defect；expected value以literal或手工驗證fixture獨立推導，不得重用受測程式、其helper或同一套邏輯；斷言consumer-visible output、state、side effect或failure mode，不得以source text、private structure或mock自身存在代替結果，除非call shape本身就是contract；mock只切slow或external boundary並保留測試依賴的真實side effects，mock response涵蓋該路徑消費的完整contract shape；完成前對與task contract相關的wrong branch／argument、missing side effect、empty／default return與必要validation執行有限mutation check。有限mutation check MAY是mental check或局部fixture，MUST NOT要求新增mutation framework。

本change在建立`DISCIPLINES["test-quality"]`前的第一個test edit MAY使用`design.md` C2逐項列出的五個gate作為唯一的narrow bootstrap carrier；該例外只適用於建立canonical resource本身，不是其他change或後續test edit可用的fallback。完成bundle version與managed resource edits後，agent MUST先執行`./install-cash-skills.fish --self`重建可信manifest／receipt，並將透過project-local Cash CLI取得`instructions --skill test-quality`及驗證逐字同源作為self-install後第一個步驟；通過後才可進行後續test edit。

#### Scenario: CLI 逐字回傳 canonical test-quality instruction

- **WHEN** caller執行`instructions --skill test-quality --json`
- **THEN** payload的`instruction`逐字等於`DISCIPLINES["test-quality"]`
- **AND** payload恰含`skill`、`locale`與`instruction`

#### Scenario: 首次建立 test-quality resource 使用有界 bootstrap

- **GIVEN** 本change尚未建立`DISCIPLINES["test-quality"]`
- **WHEN** agent為建立該resource進行第一個test edit
- **THEN** agent逐項遵循`design.md` C2的五個test-quality gate
- **AND** 完成managed resource edits後先執行`./install-cash-skills.fish --self`，再以project-local Cash CLI取得並驗證canonical instruction作為發布後第一個步驟
- **AND** CLI驗證通過前不得進行後續test edit
- **AND** 此bootstrap不得延伸為其他change或後續test edit的fallback

#### Scenario: Expected value 與 observable assertion 保持獨立

- **GIVEN** agent新增或修改一個測試
- **WHEN** agent遵循canonical test-quality instruction
- **THEN** agent先命名該測試要捕捉的realistic production defect
- **AND** expected value不由受測程式、其helper或同一套邏輯推導
- **AND** assertion檢查consumer-visible behavior，而非只檢查source text、private structure或mock自身存在

#### Scenario: Mock 保留必要 side effects

- **GIVEN** 測試需要隔離slow或external dependency
- **WHEN** agent加入mock
- **THEN** mock切在slow或external boundary並保留測試依賴的真實side effects
- **AND** mock response包含測試路徑實際消費的完整contract shape

#### Scenario: Mutation check 有界且能辨識 false green

- **WHEN** 測試準備完成
- **THEN** agent確認與task contract相關的wrong branch／argument、missing side effect、empty／default return或必要validation中至少適用的realistic mutation會使測試失敗
- **AND** discipline不要求新增mutation framework、外部dependency或無關coverage threshold

#### Scenario: Resource tests 拒絕 test-quality 語意退化

- **WHEN** 執行`PYTHONPATH=.cash-skills/lib python3 scripts/cash-cli/tests/test_graph_instructions.py`
- **THEN** 測試分別斷言named defect、independent expected、observable assertion、mock boundary與bounded mutation check
- **AND** 移除或反轉任一gate時測試以非零結束

<!-- @trace
source: strengthen-cash-tdd-evidence
updated: 2026-08-24
code:
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .cash-skills/lib/cash_cli/installer.py
  - .cash-skills/lib/cash_cli/resources.py
  - .cash-skills/manifest.tsv
  - .claude/skills/cash-apply/SKILL.md
  - .claude/skills/cash-debug/SKILL.md
  - scripts/cash-cli/tests/test_discovery_contracts.py
  - scripts/cash-cli/tests/test_graph_instructions.py
  - scripts/cash-skills/tests/skill-checks.fish
tests:
-->

### Requirement: Canonical discipline contract tests 精確辨識語意退化

canonical TDD、test-quality 與 tasks resource 的 deterministic contract tests SHALL分離 required-marker absence 與 additive contradiction 兩種失敗機制。required marker 被移除或替換時 MUST以`missing`類 rejection失敗；canonical required markers全部仍存在、但另加入會弱化同一義務的矛盾句時 MUST以`forbidden`類 rejection失敗。每個保留的 explicit contradiction MUST有一個只加入該句的獨立 mutation case直接行使，不得由較早的required-marker failure冒充。

validator MUST只拒絕 obligation-specific contradiction，不得以`可以不`、`不必`、`視情況`等裸 token作為跨 contract 的通用失敗條件。測試 MUST包含會命中這些裸 token但符合 canonical contract 的 acceptance cases，至少涵蓋remaining task不建立red phase、未修改測試時不取得test-quality，以及無自動測試邊界時使用manual assertion。checker MUST保持tool與framework中立，且 MUST NOT引入外部dependency或mutation framework。

TDD contradiction categories MUST恰為`carrier-fixed`、`unexecuted-red`與`red-after-edit`；test-quality categories MUST恰為`derived-expected`、`non-observable-result`、`unbounded-mock`、`framework-required`、`test-for-every-task`與`mutation-skippable`；tasks categories MUST恰為`multiple-primary`、`mixed-success`、`blank-red`與`placeholder-fields`。每個category的detector literal與固定mutation fixture MUST逐字相同，但兩份inventory MUST獨立定義，fixture不得從detector registry推導。測試 MUST先斷言category exact sets，再由fixture inventory執行mutations；只刪除detector guard而保留fixture時，suite MUST非零結束。

每個contradiction literal MUST滿足negation-containment不變式：把該literal改寫成強化同一義務的合法否定句時，該literal MUST NOT仍是該否定句的子字串。測試 MUST持有一份與detector registry及mutation fixture inventory都獨立定義、逐字固定的negation restatement inventory，先斷言其category exact set，再逐一驗證該不變式。測試 MUST另斷言`可以不`、`不必`與`視情況`三個retired裸token都 MUST NOT成為任一detector inventory的完整value，並 MUST以exact set斷言錨定這三個token本身，使該守衛的比對來源無法被靜默削減。negation restatement inventory本身也是守衛的輸入：測試 MUST斷言每句restatement包含「把該category的literal插入單一個`不`或`並非`後」所得的字串，使inventory退化成空字串、單字元、缺少否定詞或與該義務無關的字串時該不變式非零結束；MUST以exact set斷言錨定這兩個否定詞；MUST斷言每句append到對應canonical文本後仍被該validator接受；並 MUST以「該category的literal append到同一canonical後被同一validator具名拒絕」綁定validator與category的對應，使對照表被錯接時非零結束。negation-containment斷言 MUST排在上述斷言之前，使literal退化時它是首先失敗且具名的診斷。此結構規則 MUST NOT宣稱能判定否定詞的插入位置在語法上真的構成否定；該層由D5的逐字清單與人工審查保證。

#### Scenario: Required marker removal 與 additive contradiction 使用不同 rejection

- **GIVEN** canonical instruction或tasks resource包含全部required markers
- **WHEN** mutation只移除或替換一個required marker
- **THEN** validator以`missing`類rejection失敗
- **AND** mutation保留全部required markers、只加入一個具名矛盾句時，validator以`forbidden`類rejection失敗

#### Scenario: 每個 explicit contradiction 都被直接行使

- **WHEN** 執行`PYTHONPATH=.cash-skills/lib python3 scripts/cash-cli/tests/test_graph_instructions.py`
- **THEN** TDD、test-quality與tasks validator的每個保留explicit contradiction都有獨立additive mutation
- **AND** 刪除任一對應guard時，該mutation以未捕捉矛盾而使suite非零結束
- **AND** fixed mutation fixtures不由受測detector registry派生，刪除guard不會同步刪除對應case

#### Scenario: 合法近義措辭不被裸 token 誤判

- **GIVEN** canonical required markers保持不變
- **WHEN** instruction或resource另含符合contract且使用`可以不`、`不必`或`視情況`的合法說明
- **THEN** validator接受該內容
- **AND** acceptance cases分別覆蓋TDD remaining-task、test-quality no-test scope與tasks manual verification

#### Scenario: 強化義務的合法否定句不被 contradiction literal 命中

- **GIVEN** 某個category的contradiction literal
- **WHEN** 把該literal改寫成強化同一義務的合法否定句
- **THEN** 該literal不是該否定句的子字串
- **AND** negation restatement inventory獨立於detector registry與mutation fixture inventory定義，且其category exact set先被斷言

#### Scenario: 守衛的比對來源本身被錨定

- **GIVEN** retired裸token集合與negation restatement inventory
- **WHEN** 任一者被靜默弱化——retired token集合被削減，或restatement被改為空字串、單字元、去掉否定詞、與該義務無關的字串、或本身即為contradiction的字串
- **THEN** suite非零結束
- **AND** validator與category的對照表被錯接時同樣非零結束

#### Scenario: 裸 token 未被重新加入 detector inventory

- **GIVEN** TDD、test-quality與tasks三個detector inventory
- **WHEN** 檢查其全部value
- **THEN** `可以不`、`不必`與`視情況`都不是任一value的完整內容
- **AND** 把任一retired裸token加入某個inventory時，該斷言使suite非零結束

#### Scenario: 精煉不改變 canonical resources

- **WHEN** 完成本requirement的實作
- **THEN** `DISCIPLINES["tdd"]`、`DISCIPLINES["test-quality"]`與tasks artifact resource bytes保持不變
- **AND** 變更只落在contract test validator與fixtures

<!-- @trace
source: refine-cash-tdd-test-guards
updated: 2026-08-25
code:
  - scripts/cash-cli/tests/test_graph_instructions.py
  - scripts/cash-skills/tests/skill-checks.fish
tests:
-->
