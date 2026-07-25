## MODIFIED Requirements

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
