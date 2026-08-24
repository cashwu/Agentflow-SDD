## MODIFIED Requirements

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

## ADDED Requirements

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
