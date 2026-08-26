## MODIFIED Requirements

### Requirement: cash-apply 以條件式 canonical TDD discipline 驅動 task loop

`cash-apply`的兩個變體 SHALL將TDD視為條件式啟用的embedded discipline，其生效值依下列互斥順序解析：change目錄`.openspec.yaml`存在unindented的`tdd:`前綴行，且第一個該行的完整suffix恰為` true`或` false`時，生效值即對應change-level值；該檔不存在或無`tdd:`行時，生效值 fallback 為project root`.cash.yaml`的`tdd`值；第一個`tdd:`行的suffix不是` true`亦非` false`（包含冒號後無空格或使用tab）時，skill MUST印出一則含實際suffix的警告並 fallback 為`.cash.yaml`的`tdd`值。同檔存在多個unindented`tdd:`行時，skill MUST取第一個`tdd:`前綴行為準並忽略其後的行，即使第一行非法亦 MUST NOT改採後續合法行。skill MUST在進度輸出宣告生效值與其來源（change-level或global）。當且僅當生效值為`true`時，skill MUST以project-local Cash CLI呼叫`instructions --skill tdd`，並在task loop遵循回傳的canonical `instruction`；生效值為`false`時 MUST NOT強迫task執行TDD red phase。`audit`與`parallel_tasks`的讀取行為不受此解析影響，仍只讀`.cash.yaml`。兩個`SKILL.md` SHALL只擁有生效值解析、consumer invocation與共同task-completion contract，MUST NOT複述由Cash-owned resource擁有的Red-Green-Refactor sequence、bug-fix fail-first規則或task-type適用性矩陣；`Red-Green-Refactor`literal在每個變體中 MUST恰好出現零次。

當`cash-apply`將新增或修改任何測試時，兩個變體 MUST在首次test edit前以project-local Cash CLI呼叫`instructions --skill test-quality`並遵循回傳的canonical `instruction`，不論生效`tdd`值為何。未新增或修改測試時，skill MUST NOT為形式而取得該instruction或新增測試。兩個`SKILL.md` MUST只擁有test-quality consumer invocation，不得複述named defect、independent expected、observable assertion、mock boundary或bounded mutation check的完整語意。

不論生效值，每個task在呼叫`task done`前 MUST具有適合該task性質、可對照`tasks.md` evidence contract與相關Implementation Contract的verification evidence。每個pending task的checkbox description MUST同列非空的`delivery`、`verification`、`regression`、`success`與`red`欄位；`verification` MUST恰好是primary target，`regression` MUST命名相關targets，或以`N/A`說明primary已涵蓋完整相關範圍；`success`與`red`分別是該primary target的success與failure marker，`success`不得混入regression、publication或task completion結果，且`red`不適用時 MUST為`N/A`並指出pure-refactor或remaining-task分類理由。任一欄位缺失、含placeholder，或生效`tdd`值為`true`時`red`欄位與canonical TDD classification矛盾，skill MUST在任何production edit前走既有unclear-task branch，不得猜測、寫code或呼叫`task done`。skill MUST將規格`##### Example:`視為task scope內的高保真acceptance reference，但 MAY在有具體風險或邊界理由時增加其他test case；example table MUST NOT被解讀為唯一允許的輸入集合。

`cash-apply`的TDD consumer（含生效值解析）、test-quality consumer、verification-evidence gate與example-reference段落在`.claude`與`.agents`兩個變體中，經invocation prefix（`/cash-`與`$cash-`）正規化後 MUST逐行完全相同。回歸套件 MUST提供可獨立執行的`tdd-discipline`具名群組，並 MUST將該群組納入全量執行路徑；該群組 MUST驗證兩個變體的條件式TDD consumer——含change-level解析、global fallback與非法值警告文字——以及按需test-quality consumer、單一來源禁重複、task欄位、共同verification gate與舊絕對規則不存在。

#### Scenario: change-level 值優先於全域值

- **GIVEN** project root的`.cash.yaml`包含`tdd: false`
- **AND** 該change的`.openspec.yaml`包含unindented的`tdd: true`行
- **WHEN** `cash-apply`進入task loop前解析生效值
- **THEN** 生效值為`true`，skill呼叫`"$cash_cli" instructions --skill tdd`並遵循回傳的`instruction`
- **AND** 進度輸出宣告生效值來源為change-level

#### Scenario: 缺少 change-level 欄位時 fallback 全域值

- **GIVEN** 該change的`.openspec.yaml`不含`tdd:`行
- **AND** project root的`.cash.yaml`包含`tdd: true`
- **WHEN** `cash-apply`進入task loop前解析生效值
- **THEN** 生效值取自`.cash.yaml`為`true`
- **AND** 進度輸出宣告生效值來源為global

#### Scenario: 非法 change-level 值印警告並 fallback

- **GIVEN** 該change的`.openspec.yaml`包含`tdd:`行但其值非`true`亦非`false`
- **WHEN** `cash-apply`進入task loop前解析生效值
- **THEN** skill印出一則含該實際值的警告
- **AND** 生效值 fallback 為`.cash.yaml`的`tdd`值

#### Scenario: 重複 tdd 行取第一行

- **GIVEN** 該change的`.openspec.yaml`同時包含`tdd: true`與其後的`tdd: false`兩個unindented行
- **WHEN** `cash-apply`進入task loop前解析生效值
- **THEN** 生效值為第一個`tdd:`前綴行的`true`
- **AND** 其後的`tdd:`行被忽略

#### Scenario: 啟用 TDD 時按需取得 canonical discipline

- **GIVEN** 生效`tdd`值為`true`
- **WHEN** `cash-apply`進入task loop前讀取preferences
- **THEN** skill呼叫`"$cash_cli" instructions --skill tdd`並遵循回傳的`instruction`
- **AND** skill自身不含`Red-Green-Refactor`literal，只遵循回傳的canonical `instruction`

#### Scenario: 停用 TDD 時仍保留 verification gate

- **GIVEN** 生效`tdd`值為`false`
- **WHEN** `cash-apply`執行一個pending task
- **THEN** skill不強迫該task先建立TDD red phase
- **AND** skill仍要求task指定的test、CLI、analyzer或manual assertion通過後才呼叫`task done`

#### Scenario: 新增或修改測試時按需取得 test-quality

- **GIVEN** pending task將新增或修改測試
- **WHEN** `cash-apply`準備進行首次test edit
- **THEN** skill呼叫`"$cash_cli" instructions --skill test-quality`並遵循回傳的`instruction`
- **AND** 此義務不受生效`tdd`值影響
- **AND** skill未修改測試時不為形式新增測試

#### Scenario: 缺少 task evidence 欄位時在 edit 前暫停

- **GIVEN** pending task缺少`delivery`、`verification`、`regression`、`success`或`red`任一欄位，欄位含placeholder，或生效`tdd`值為`true`時`red`與canonical classification矛盾
- **WHEN** `cash-apply`準備執行該task
- **THEN** skill在任何production edit前走既有unclear-task branch
- **AND** skill不猜測缺失內容、不呼叫`task done`

#### Scenario: 純 refactor 不被迫製造失敗測試

- **GIVEN** 生效`tdd`值為`true`且某個task不改變可觀察行為
- **WHEN** canonical TDD discipline將該task分類為pure refactor
- **THEN** task以既有regression tests保護行為，並只在既有evidence不足時補characterization test
- **AND** `cash-apply`不因沒有刻意失敗的測試而阻擋該task完成

#### Scenario: 其餘 task 使用命名 verification target

- **GIVEN** 生效`tdd`值為`true`且某個task未命中canonical discipline的前三個分支
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
- **THEN** 套件驗證兩個`cash-apply`變體各有唯一的條件式TDD consumer——含change-level解析、global fallback與非法值警告文字——與按需test-quality consumer
- **AND** 套件驗證task五欄、primary／regression mapping、共同verification-evidence gate與test-quality單一來源
- **AND** 套件驗證兩檔皆不含舊的per-task absolute fail-first、無條件test-for-every-task或重複test-quality語意，且各檔的`Red-Green-Refactor`literal count恰為零
- **AND** 相同assertions由全量`skill-checks.fish`執行路徑觸發

#### Scenario: 兩個變體保持完整對等

- **WHEN** 比較`.claude/skills/cash-apply/SKILL.md`與`.agents/skills/cash-apply/SKILL.md`
- **THEN** TDD consumer（含生效值解析）、test-quality consumer、verification-evidence gate與example-reference段落在invocation prefix正規化後逐行完全相同
- **AND** parity驗證不只比較選定markers

## ADDED Requirements

### Requirement: cash-propose 記錄 change-level TDD 選擇

`cash-propose`的兩個變體 SHALL在`new change`成功之後、proposal撰寫之前——或在continue既有change時於繼續workflow的當下——先檢查該change的`.openspec.yaml`是否已存在unindented的`tdd:`行：已存在時 MUST跳過詢問且 MUST NOT重複 append，此前置檢查即「每個change恰好一次」的機械判準；該行缺失時，skill MUST以AskUserQuestion詢問本change是否套用TDD，提供「套用TDD」與「不套用TDD」兩選項並依需求描述附規模建議；AskUserQuestion不可用時 MUST依skill既有fallback以純文字詢問並等待回覆。skill MUST將答案以unindented、LF終止的`tdd: true`或`tdd: false`單行 append 至該change的`.openspec.yaml`；檔案非空且缺少尾端LF時 MUST先補恰好一個LF separator，再寫入新行，MUST NOT改動既有行內容，MUST NOT修改`.cash.yaml`；append寫入失敗時 MUST報告確切錯誤並停止workflow。

#### Scenario: 建立 change 後詢問並記錄選擇

- **GIVEN** `"$cash_cli" new change`已成功建立change目錄
- **AND** 該change的`.openspec.yaml`無`tdd:`行
- **WHEN** `cash-propose`繼續workflow
- **THEN** skill在撰寫proposal前詢問本change是否套用TDD並附建議
- **AND** 答案以unindented的`tdd: true`或`tdd: false`行 append 至該change的`.openspec.yaml`
- **AND** 該檔既有行保持不變且`.cash.yaml`不被修改

#### Scenario: 已有 tdd 行時跳過詢問

- **GIVEN** 該change的`.openspec.yaml`已存在unindented的`tdd:`行
- **WHEN** `cash-propose`到達TDD詢問時點（含continue既有change的路徑）
- **THEN** skill跳過詢問且不重複 append

#### Scenario: continue 路徑缺行時補問

- **GIVEN** `cash-propose`對已存在的change繼續workflow
- **AND** 該change的`.openspec.yaml`無`tdd:`行
- **WHEN** skill繼續workflow
- **THEN** skill補問本change是否套用TDD並將答案 append 至`.openspec.yaml`

#### Scenario: 寫入失敗時停止

- **WHEN** 對`.openspec.yaml`的 append 寫入失敗
- **THEN** skill報告確切錯誤並停止workflow

#### Scenario: 互動工具不可用時以純文字詢問

- **GIVEN** AskUserQuestion tool不可用
- **WHEN** `cash-propose`到達TDD詢問時點且需要詢問
- **THEN** skill以純文字提出相同選項並等待使用者回覆後才寫入

#### Scenario: propose 記錄由具名群組治理

- **WHEN** 執行`fish scripts/cash-skills/tests/skill-checks.fish tdd-discipline`
- **THEN** 套件驗證兩個`cash-propose`變體各含TDD詢問、`.openspec.yaml` append記錄與「已有`tdd:`行跳過詢問」的文字
- **AND** 相同assertions由全量`skill-checks.fish`執行路徑觸發

### Requirement: cash-apply 品質關卡結束回報 loop-ledger 摘要

`cash-apply`的兩個變體 SHALL在品質關卡以`passed`或`aborted`結束、最終ledger列與signals寫入步驟完成後，於最終回應回報本次loop run的apply輪數N與該run各輪`fixed_files`總和M。N與M MUST以主agent本次run寫入的round files與ledger列為權威來源——ledger schema無run識別欄位且`(skill, round)`非唯一鍵，「本次run的列」不可從檔案內容單獨導出；N MUST以run內位置計數，不受re-run接續的全域round編號影響。skill MUST讀取`openspec/changes/<change>/reviews/loop-ledger.tsv`核對其尾端apply列與本次run紀錄一致。本次run輪數達4以上時 MUST附一則設計劣化警訊，建議檢視design.md或以cash-ingest workflow更新設計——警訊文字 MUST使用不含invocation prefix的「cash-ingest workflow」表述，使兩變體逐字相同；本次run輪數3以下 MUST NOT附警訊。此步驟 MUST為read-only，MUST NOT修改任何round file的`decision`，MUST NOT使workflow失敗；ledger缺檔、無法讀取或尾端列與本次run紀錄不一致時 MUST印警告，摘要仍以本次run紀錄回報並繼續。此步驟 MUST位於shared review-gate region（`<!-- REVIEW-GATE:BEGIN -->`與`<!-- REVIEW-GATE:END -->`之間）之外，且 MUST NOT出現在`cash-propose`變體。

#### Scenario: 通過的迴圈回報摘要

- **GIVEN** 本次apply品質關卡的run進行了2輪後以`decision: passed`結束
- **WHEN** skill產生gate-complete最終回應
- **THEN** 回應包含本次run輪數2與該run各輪`fixed_files`總和
- **AND** 不附設計劣化警訊

#### Scenario: 高輪數時附設計劣化警訊

- **GIVEN** 本次apply品質關卡的run進行了4輪或以上
- **WHEN** skill產生最終回應
- **THEN** 回應包含ledger摘要與一則設計劣化警訊
- **AND** 警訊建議檢視design.md或以cash-ingest workflow更新設計

#### Scenario: re-run 的輪數以 run 內位置計數

- **GIVEN** 前一次apply迴圈以`decision: aborted`結束於第3輪，seeded re-run自第4個round file編號起算
- **AND** 該re-run進行了1輪後以`decision: passed`結束
- **WHEN** skill產生最終回應
- **THEN** 摘要回報本次run輪數1
- **AND** 不附設計劣化警訊

#### Scenario: aborted 迴圈同樣回報摘要

- **GIVEN** 本次apply品質關卡以`decision: aborted`結束
- **WHEN** skill產生含Abort triage的最終回應
- **THEN** 回應包含本次run的ledger摘要
- **AND** 摘要不改變該輪`decision`

#### Scenario: ledger 缺失或不一致時印警告仍回報摘要

- **GIVEN** `loop-ledger.tsv`不存在、無法讀取，或其尾端apply列與本次run紀錄不一致
- **WHEN** skill到達摘要步驟
- **THEN** skill印出警告
- **AND** 摘要仍以主agent本次run紀錄回報
- **AND** workflow繼續且不失敗

#### Scenario: ledger 摘要由具名群組治理

- **WHEN** 執行`fish scripts/cash-skills/tests/skill-checks.fish tdd-discipline`
- **THEN** 套件以摘要步驟特有文字驗證兩個`cash-apply`變體各含ledger摘要步驟與設計劣化警訊
- **AND** 套件以同一特有文字驗證該步驟不出現在兩個`cash-propose`變體，且該斷言不使用shared review-gate block既有字串
- **AND** 相同assertions由全量`skill-checks.fish`執行路徑觸發
