## MODIFIED Requirements

### Requirement: cash-apply 以條件式 canonical TDD discipline 驅動 task loop

`cash-apply`的兩個變體 SHALL將TDD視為由`.cash.yaml`條件式啟用的embedded discipline。當且僅當`tdd: true`時，skill MUST以project-local Cash CLI呼叫`instructions --skill tdd`，並在task loop遵循回傳的canonical `instruction`；`tdd: false`時 MUST NOT強迫task執行TDD red phase。兩個`SKILL.md` SHALL只擁有toggle、consumer invocation與共同task-completion contract，MUST NOT複述由Cash-owned resource擁有的Red-Green-Refactor sequence、bug-fix fail-first規則或task-type適用性矩陣；`Red-Green-Refactor`literal在每個變體中 MUST恰好出現零次。

當`cash-apply`將新增或修改任何測試時，兩個變體 MUST在首次test edit前以project-local Cash CLI呼叫`instructions --skill test-quality`並遵循回傳的canonical `instruction`，不論`tdd`值為何。未新增或修改測試時，skill MUST NOT為形式而取得該instruction或新增測試。兩個`SKILL.md` MUST只擁有test-quality consumer invocation，不得複述named defect、independent expected、observable assertion、mock boundary或bounded mutation check的完整語意。

不論toggle值，每個task在呼叫`task done`前 MUST具有適合該task性質、可對照`tasks.md` evidence contract與相關Implementation Contract的verification evidence。每個pending task的checkbox description MUST同列非空的`delivery`、`verification`、`regression`、`success`與`red`欄位；`verification` MUST恰好是primary target，`regression` MUST命名相關targets，或以`N/A`說明primary已涵蓋完整相關範圍；`success`與`red`分別是該primary target的success與failure marker，`success`不得混入regression、publication或task completion結果，且`red`不適用時 MUST為`N/A`並指出pure-refactor或remaining-task分類理由。任一欄位缺失、含placeholder，或`tdd: true`時`red`欄位與canonical TDD classification矛盾，skill MUST在任何production edit前走既有unclear-task branch，不得猜測、寫code或呼叫`task done`。skill MUST將規格`##### Example:`視為task scope內的高保真acceptance reference，但 MAY在有具體風險或邊界理由時增加其他test case；example table MUST NOT被解讀為唯一允許的輸入集合。

`cash-apply`的TDD consumer、test-quality consumer、verification-evidence gate與example-reference段落在`.claude`與`.agents`兩個變體中，經invocation prefix（`/cash-`與`$cash-`）正規化後 MUST逐行完全相同。回歸套件 MUST提供可獨立執行的`tdd-discipline`具名群組，並 MUST將該群組納入全量執行路徑；該群組 MUST驗證兩個變體的條件式TDD consumer、按需test-quality consumer、單一來源禁重複、task欄位、共同verification gate與舊絕對規則不存在。

#### Scenario: 啟用 TDD 時按需取得 canonical discipline

- **GIVEN** project root的`.cash.yaml`包含`tdd: true`
- **WHEN** `cash-apply`進入task loop前讀取project preferences
- **THEN** skill呼叫`"$cash_cli" instructions --skill tdd`並遵循回傳的`instruction`
- **AND** skill自身不含`Red-Green-Refactor`literal，只遵循回傳的canonical `instruction`

#### Scenario: 停用 TDD 時仍保留 verification gate

- **GIVEN** project root的`.cash.yaml`包含`tdd: false`
- **WHEN** `cash-apply`執行一個pending task
- **THEN** skill不強迫該task先建立TDD red phase
- **AND** skill仍要求task指定的test、CLI、analyzer或manual assertion通過後才呼叫`task done`

#### Scenario: 新增或修改測試時按需取得 test-quality

- **GIVEN** pending task將新增或修改測試
- **WHEN** `cash-apply`準備進行首次test edit
- **THEN** skill呼叫`"$cash_cli" instructions --skill test-quality`並遵循回傳的`instruction`
- **AND** 此義務不受`tdd`toggle影響
- **AND** skill未修改測試時不為形式新增測試

#### Scenario: 缺少 task evidence 欄位時在 edit 前暫停

- **GIVEN** pending task缺少`delivery`、`verification`、`regression`、`success`或`red`任一欄位，欄位含placeholder，或`tdd: true`時`red`與canonical classification矛盾
- **WHEN** `cash-apply`準備執行該task
- **THEN** skill在任何production edit前走既有unclear-task branch
- **AND** skill不猜測缺失內容、不呼叫`task done`

#### Scenario: 純 refactor 不被迫製造失敗測試

- **GIVEN** `tdd: true`且某個task不改變可觀察行為
- **WHEN** canonical TDD discipline將該task分類為pure refactor
- **THEN** task以既有regression tests保護行為，並只在既有evidence不足時補characterization test
- **AND** `cash-apply`不因沒有刻意失敗的測試而阻擋該task完成

#### Scenario: 其餘 task 使用命名 verification target

- **GIVEN** `tdd: true`且某個task未命中canonical discipline的前三個分支
- **WHEN** task loop執行該task
- **THEN** task執行`tasks.md`的`verification`欄位指定的primary target
- **AND** task再執行`regression`欄位指定的相關targets；若為`N/A`則其理由必須證明primary涵蓋完整相關範圍
- **AND** 有可用自動checker時 MAY使用，但skill不要求red phase

#### Scenario: Example 是 reference 而非封閉輸入集合

- **GIVEN** task scope的spec包含一個`##### Example:` table
- **WHEN** `cash-apply`建立verification evidence
- **THEN** table的每列輸入與預期結果都被納入驗證
- **AND** 有具體風險或邊界理由時 MAY加入example以外的test case

#### Scenario: TDD contract 由具名群組治理

- **WHEN** 執行`fish scripts/cash-skills/tests/skill-checks.fish tdd-discipline`
- **THEN** 套件驗證兩個`cash-apply`變體各有唯一的條件式TDD consumer與按需test-quality consumer
- **AND** 套件驗證task五欄、primary／regression mapping、共同verification-evidence gate與test-quality單一來源
- **AND** 套件驗證兩檔皆不含舊的per-task absolute fail-first、無條件test-for-every-task或重複test-quality語意，且各檔的`Red-Green-Refactor`literal count恰為零
- **AND** 相同assertions由全量`skill-checks.fish`執行路徑觸發

#### Scenario: 兩個變體保持完整對等

- **WHEN** 比較`.claude/skills/cash-apply/SKILL.md`與`.agents/skills/cash-apply/SKILL.md`
- **THEN** TDD consumer、test-quality consumer、verification-evidence gate與example-reference段落在invocation prefix正規化後逐行完全相同
- **AND** parity驗證不只比較選定markers

## ADDED Requirements

### Requirement: cash-debug 共用 canonical testing disciplines

`cash-debug`的兩個變體 SHALL與`cash-apply`共用`.cash.yaml`的TDD ordering語意：Phase 3 MUST在debug notes記錄恰好一個primary verification target、相關regression targets、success marker，以及需要red phase時的failure marker或附分類理由的`N/A`，作為不依賴`tasks.md`的current-workflow evidence carrier；`tdd: true`時在Phase 4前以project-local Cash CLI呼叫`instructions --skill tdd`並以該carrier遵循回傳的canonical `instruction`；`tdd: false`時 MUST NOT強迫bug fix先建立red phase。兩個toggle值都 MUST要求先完成root-cause analysis，再做minimum root-cause fix，執行named primary target並執行相關regression targets；沒有實際可行自動測試邊界時可使用問題性質適合的CLI、analyzer或manual assertion。

當`cash-debug`新增或修改任何測試時，兩個變體 MUST在首次test edit前呼叫`instructions --skill test-quality`並遵循回傳的canonical `instruction`，不受`tdd`toggle影響。兩個`SKILL.md` MUST移除「Phase 4永遠先從failing test開始」與無條件failing-test步驟，MUST NOT複述canonical TDD或test-quality完整語意。

`cash-debug`的TDD toggle、test-quality consumer、Phase 3 evidence carrier、named primary verification與regression段落在`.claude`與`.agents`變體中，經invocation prefix正規化後 MUST逐行完全相同。`tdd-discipline`具名群組與全量skill checks MUST驗證兩個變體的consumer commands、carrier、retired absolute literals、command matrix與完整parity。

#### Scenario: cash-debug Phase 3 建立不依賴 tasks.md 的 evidence carrier

- **GIVEN** `cash-debug`不在Cash change的task loop內且沒有`tasks.md` contract
- **WHEN** skill在Phase 3形成可驗證的root-cause hypothesis
- **THEN** debug notes記錄primary verification target、相關regression targets、success marker與failure marker或附分類理由的`N/A`
- **AND** Phase 4以該carrier套用canonical TDD instruction，不假設存在`tasks.md`

#### Scenario: cash-debug 啟用 TDD 時遵循 canonical ordering

- **GIVEN** `.cash.yaml`包含`tdd: true`
- **WHEN** `cash-debug`完成root-cause analysis並進入Phase 4
- **THEN** skill呼叫`"$cash_cli" instructions --skill tdd`並遵循回傳的`instruction`
- **AND** skill不自行複述另一套Red-Green-Refactor sequence

#### Scenario: cash-debug 停用 TDD 時不強迫 fail-first

- **GIVEN** `.cash.yaml`包含`tdd: false`
- **WHEN** `cash-debug`執行fix
- **THEN** skill不強迫先建立failing test
- **AND** skill仍要求minimum root-cause fix、Phase 3命名的primary verification target與相關regression targets

#### Scenario: cash-debug 修改測試時遵循 test-quality

- **GIVEN** `cash-debug`將新增或修改測試
- **WHEN** skill準備進行首次test edit
- **THEN** skill呼叫`"$cash_cli" instructions --skill test-quality`並遵循回傳的`instruction`
- **AND** 此義務不受`tdd`toggle影響

#### Scenario: cash-debug 兩個變體與 command matrix 受治理

- **WHEN** 執行`fish scripts/cash-skills/tests/skill-checks.fish tdd-discipline`
- **THEN** 套件驗證`.claude`與`.agents`的`cash-debug`皆包含正確TDD toggle、test-quality consumer、Phase 3 evidence carrier與verification gates
- **AND** 套件拒絕無條件failing-test與Phase-4-always-failing-test舊規則
- **AND** command matrix包含`instructions --skill test-quality`，且完整variant parity通過
