## MODIFIED Requirements

### Requirement: Cash workflow command surface

CLI SHALL 提供且僅需支援Cash workflows消費的`list`、`status`、`instructions`（含artifact-level、`instructions apply`與`instructions --skill <tdd|test-quality|audit>`三種mode）、`new change`、`new artifact`、`task done`、`in-progress add`、`touched ensure`、`touched record`、`park`、`unpark`、`validate`（含single-change與`validate --all`）、`analyze`、`drift`、`archive`、`sync`、`search`與`lint-round`（含single-change與`lint-round --hook`兩種mode）command families。每個呼叫artifact engine的canonical Cash skill MUST 呼叫`.cash-skills/bin/cash`，MUST NOT包含可執行的`spectra`command或`Requires spectra CLI`相容性宣告。

`lint-round` MUST 是shared-read command family：它 MUST NOT加入`.cash-skills/bin/cash`的`MUTATING_FAMILIES`集合，因此launcher依既有argv分類為它取得`LOCK_SH`，新增該command MUST NOT需要修改launcher，也 MUST NOT觸發受控launcher bootstrap migration。

CLI SHALL 另提供不擴張上述command family集合的help表面。第一個argument為`--help`或`-h`時，CLI MUST在launcher完成既有lock取得與manifest-presence所選信任gate驗證之後、進入command dispatch之前輸出help並以exit 0結束；help MUST NOT繞過launcher的信任gate：manifest存在時必須完成portable gate且invalid manifest以`manifest_invalid`失敗，manifest缺失時receipt缺失或無效仍 MUST維持既有的`bootstrap_invalid`／`receipt_invalid`失敗，而非輸出help。help flag不是command，`Project-local Cash CLI runtime`對unknown command的失敗規定僅適用於進入dispatch的token。第一個argument不是help flag時，CLI的dispatch目標、exit code、`error` code與JSON object結構 MUST與未提供該表面時相同。由top-level command dispatch產生的`missing_command`與`unknown_command` MUST維持既有的code、exit code與`error` object結構，但其`message` MUST指向help flag。該訊息 MUST NOT內嵌command清單——內嵌會使釘住該訊息的golden fixture成為第二份需手動同步的清單，與本requirement消除重複定義的目的相反；指向help的措辭是不隨dispatch table變動的穩定字串。由個別handler產生的其他`unknown_command`（例如未知的new mode或未知的discipline）MUST NOT受此規定影響。command清單 MUST只有help一個輸出處，且 MUST由dispatch table導出，MUST NOT另立靜態副本。`--json`時help MUST輸出單一JSON object，其`commands`欄位為排序後的dispatch table key陣列。

#### Scenario: 支援的 command 被 dispatch

- **WHEN** caller提供上述任一已支援command與有效arguments
- **THEN** CLI dispatch到Cash-owned handler
- **AND** handler不經過外部CLI adapter

##### Example: discovery command dispatch

- **GIVEN** caller位於有效workspace
- **WHEN** caller執行`.cash-skills/bin/cash list --json`
- **THEN** discovery handler回傳單一`changes` JSON object

#### Scenario: lint-round 以 shared lock dispatch

- **GIVEN** caller位於有效workspace
- **WHEN** caller執行`.cash-skills/bin/cash lint-round <change> --json`
- **THEN** launcher為該command取得`LOCK_SH`而非`LOCK_EX`
- **AND** CLI dispatch到Cash-owned handler並回傳單一JSON object

#### Scenario: lint-round --hook 不接受 change 名稱

- **GIVEN** caller位於有效workspace
- **WHEN** caller執行`.cash-skills/bin/cash lint-round --hook`
- **THEN** CLI自行列舉`openspec/changes/`下排除`archive`與`.parked`兩個保留目錄名後、為目錄型且名稱符合`[a-z][a-z0-9-]*`的change，加上`openspec/changes/.parked/`下同樣條件的parked change作為判定對象
- **AND** `.parked`本身不被當成一個change列舉
- **AND** CLI不要求也不接受change名稱位置參數

#### Scenario: lint-round 出現在 help 的 command 清單

- **GIVEN** target依manifest-presence優先序具有valid portable manifest或valid receipt
- **WHEN** caller執行`.cash-skills/bin/cash --help --json`
- **THEN** 輸出的`commands`陣列包含`lint-round`
- **AND** 該清單仍由dispatch table導出，不存在第二份靜態副本

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

#### Scenario: lint-round 的輸出遵守 round gate 契約

- **GIVEN** caller 提供合法 arguments 與 hook mode 所需的 host payload
- **WHEN** CLI dispatch `lint-round` 的 single-change、`--hook` 或 `--hook --json` 呼叫
- **THEN** stdout、stderr、JSON shape 與 exit code MUST 遵守 `cash-round-gate` 的 `lint-round 輸出與結束碼` requirement
- **AND** `--json` MUST NOT 改變重入放行或 gate failure 的 exit code

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
