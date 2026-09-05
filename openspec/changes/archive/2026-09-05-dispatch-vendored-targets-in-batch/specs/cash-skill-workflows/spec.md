## MODIFIED Requirements

### Requirement: 手動的 cash 專案 registry

本 repository SHALL經由`install-cash-skills.fish`提供registry操作與明示的repo-vendored publication。每次registry操作恰好使用`--target <project>`、`--register <project>`、`--unregister <project>`、`--list`或`--all`其中之一；`--vendor <project>`與這些registry操作互斥，屬非registry的publication模式，MUST NOT讀取或修改registry，其target與publication契約由 `Repo-vendored Cash bundle 發佈` requirement治理。source-only `--self`與target-local `--init-receipt`另由 `Bundle 安裝與 runtime receipt`及 `Target-local receipt 初始化` requirements治理，不屬本requirement的封閉registry操作集合。registry SHALL是`$HOME/.config/cash-skills/projects.txt`，每個非空行一個正規化絕對專案路徑，路徑 MUST NOT包含ASCII控制字元。每個registry支援的模式 MUST在使用既有registry前完整驗證它；registry變動 MUST使用同目錄暫存檔與atomic rename，且installer MUST NOT排程或啟動未來呼叫。`--register`的target除了既存non-symlink directory外，還 MUST是canonical Git worktree top-level，並具有安全、可讀、schema-valid的regular `openspec/config.yaml`；它與direct/batch target使用同一prerequisite validator。`--register` MUST NOT 以target已有portable manifest為由拒絕登錄，因此registry可同時容納receipt-based與repo-vendored兩種target。`--all` SHALL 對每個registry record判定其發佈模式後分派到對應的publication路徑，其中repo-vendored record以 `Repo-vendored Cash bundle 發佈` requirement定義的publication契約發佈；該分派 MUST NOT 使 `--vendor` mode本身被啟用，讀取registry的一律是 `--all`，因此 `--vendor` 不讀取也不修改registry的既有契約不變。registry檔案 MUST NOT 記錄任何target的發佈模式；模式一律由target當下狀態在每次batch重新判定。

#### Scenario: Vendor mode 不使用 registry

- **WHEN** 維護者執行`--vendor <project>`
- **THEN** installer依repo-vendored publication契約處理明示target
- **AND** 它不讀取、不建立也不修改`$HOME/.config/cash-skills/projects.txt`

#### Scenario: Register 與 batch 涵蓋兩種發佈模式的 target

- **WHEN** `--register <project>` 收到符合全部target prerequisites且已具有regular portable manifest的target
- **THEN** installer完成登錄且不因該manifest拒絕
- **WHEN** 隨後執行 `--all`
- **THEN** 該record以repo-vendored publication發佈，registry中判定為receipt-based的record仍以receipt-based publication發佈
- **AND** `--vendor` mode未被啟用，registry不因該分派被讀取以外的方式使用

#### Scenario: 首次 register 建立安全狀態

- **GIVEN**cash-skills組態目錄與registry在安全HOME之下不存在
- **WHEN**`--register <project>`收到符合全部target prerequisites的target
- **THEN**installer僅建立所需組態目錄與atomic發佈的registry

#### Scenario: 缺失 registry 對讀取與移除模式視為空

- **GIVEN**cash-skills組態目錄與registry在安全HOME之下不存在
- **WHEN**`--unregister <project>`、`--list`或`--all`執行
- **THEN**installer對空清單成功執行且不建立狀態
- **AND**`--all`印出零計數摘要

#### Scenario: Register 正規化、去重並驗證 prerequisite

- **WHEN**`--register <project>`收到既存non-symlink directory
- **THEN**installer先canonicalize並要求該path恰為Git worktree top-level且具有安全有效的`openspec/config.yaml`
- **AND**成功時恰好儲存一次canonical absolute path並保持其他有效項目不變
- **AND**non-Git、Git子目錄、missing/unsafe/invalid config都以非零結束且registry零寫入

#### Scenario: Register 拒絕行導向 path injection

- **WHEN**register或unregister輸入包含tab、CR、LF或其他ASCII控制字元
- **THEN**installer以非零結束
- **AND**它不建立也不修改registry

#### Scenario: 既有 registry 紀錄拒絕殘留控制字元

- **WHEN**以LF分隔的既有registry紀錄包含tab、CR或其他殘留ASCII控制字元
- **THEN**每個registry支援的installer mode以非零結束
- **AND**它不建立也不修改registry或任何target

#### Scenario: Unregister 移除既存或過時 target

- **WHEN**`--unregister <project>`識別出canonical既存target，或不含dot segment且與儲存值完全一致的absolute stale target
- **THEN**installer以atomic方式移除該項目
- **AND**缺失項目是成功no-op

#### Scenario: List 是唯讀的

- **WHEN**`--list`收到有效registry
- **THEN**它印出去重後的canonical項目
- **AND**它不建立也不修改任何registry、target、receipt、skill、temporary file或background process

#### Scenario: 無效 registry fail closed

- **WHEN**registry不可讀，或包含relative path、root path、dot segment、malformed line或unsafe boundary
- **THEN**`--register`、`--unregister`、`--list`與`--all`在處理target或重寫registry前以非零結束
- **AND**沒有任何registry或target state被修改

### Requirement: 版本感知的 cash skill 批次安裝

本 requirement 的 receipt-based workflow 與 receipt publication 適用於依 `Repo-vendored Cash bundle 發佈` requirement 的 batch publication-mode 分派段落判定為 receipt-based 的 registry record；判定為 repo-vendored 的 record，其 publication 由該 requirement 的較窄契約優先治理。判準本身只由該段落定義，本 requirement 以引用界定自身範圍而 MUST NOT 自行陳述判準，使分派鍵在整份規格中只有一個權威定義。回落到本 requirement 的 record 由其既有拒絕或既有 workflow 處置。`install-cash-skills.fish --all [--dry-run] [--force]` SHALL 對每個去重後的 registry record，依 `Repo-vendored Cash bundle 發佈` requirement 的 batch publication-mode 分派段落判定其發佈模式後分派。判定為 receipt-based 的 record 重用與`--target`相同的完整installer target workflow。每個target MUST先驗證為Git worktree top-level且具有安全有效的`openspec/config.yaml`；走 receipt-based workflow 的 record 以stable launcher/lock bootstrap、replaceable runtime generation、24個skills、contract modes、Cash config validation/migration、guidance、receipt與精確baseline legacy removal構成同一managed decision，走 repo-vendored publication 的 record 則以該 requirement 定義的 manifest-last inventory 構成其 managed decision且 MUST NOT 建立 receipt。它 MUST將每個target回報為`updated`、`would-update`、`current`、`newer`、`conflict`或`failed`，然後印出每種狀態的計數；分派到repo-vendored publication的record MUST 在其輸出行的record之後附加 ` (vendored)` 後綴，該後綴與最終狀態無關。單一target的conflict或failed MUST NOT停止後續targets，發佈模式判定本身也 MUST NOT 成為中止批次的來源，且任何target為`conflict`或`failed`時，彙總指令 MUST以非零結束。

#### Scenario: 批次對兩種發佈模式的 record 都完成分派

- **GIVEN**registry同時包含一個具有regular portable manifest的record與一個manifest缺失的record，且source具有較新bundle
- **WHEN**installer以`--all`執行
- **THEN**具有regular manifest的record以repo-vendored publication回報`updated`且其輸出行帶 ` (vendored)` 後綴，並且不建立receipt
- **AND**manifest缺失的record以receipt-based workflow回報`updated`且其輸出行維持既有格式
- **AND**發佈模式判定不產生額外diagnostic，也不中止批次

#### Scenario: 較舊 bundle 或 managed drift 被更新

- **GIVEN**registry包含有效且乾淨的receipt-based targets（皆無portable manifest），其receipt版本分別舊於、等於與新於source
- **AND**等版本target的stable launcher/lock與replaceable runtime/skill bytes及modes皆符合receipt
- **AND**其中一個等版本target含可安全遷移的config、guidance或legacy baseline drift，其餘等版本target為canonical
- **WHEN**installer以`--all`執行
- **THEN**較舊target與可安全收斂的等版本target回報`updated`
- **AND**等版本且完整canonical的target回報`current`
- **AND**較新的target回報`newer`
- **AND**current或newer target的stable bootstrap、runtime generation、skills、config、guidance、receipt及legacy candidates皆零寫入

#### Scenario: 批次揭露等版本的 source 完整性失敗

- **GIVEN**某個manifest缺失的target具有等於source版本的有效receipt
- **AND**至少一個目前source replaceable runtime/skill digest或contract mode與該版本引入commit不符，或stable bootstrap source不符固定baseline
- **WHEN**installer以`--all`或`--all --force`執行
- **THEN**該target回報`failed`、零target write且彙總非零

#### Scenario: 除非明確 force 否則 managed drift 被保留

- **GIVEN**某個manifest缺失、較舊或等版本target的replaceable runtime/skill bytes或mode相對有效receipt drift
- **WHEN**installer未帶`--force`
- **THEN**target回報`conflict`且所有managed及project-owned state零寫入
- **WHEN**相同target再次帶`--force`
- **THEN**installer持有並保留stable lock/launcher inode，只收斂replaceable runtime/skills/modes、Cash managed guidance spans、receipt及精確baseline legacy candidates
- **AND**project-owned config與其他bytes維持不變，target回報`updated`

#### Scenario: Force 從不降級較新的 target

- **GIVEN**某個manifest缺失的target其有效receipt版本高於source
- **WHEN**installer以`--all --force`執行
- **THEN**target回報`newer`
- **AND**stable bootstrap、runtime generation、skills、modes、config、guidance、receipt與legacy candidates全部零寫入

#### Scenario: Target 失敗不停止批次

- **GIVEN**一個registered target因Git/config、receipt、guidance、legacy identity或filesystem validation失敗，且較後target可更新
- **WHEN**installer以`--all`執行
- **THEN**第一個target回報`failed`
- **AND**installer繼續更新較後target並以非零彙總

#### Scenario: 批次 dry run 使用完整驗證且不寫入

- **GIVEN**registry中manifest缺失的record
- **WHEN**installer以`--all --dry-run`執行
- **THEN**每個這樣的target接受與real run相同的Git/config、source inventory/mode、receipt/version、guidance、legacy identity、transaction及filesystem boundary驗證
- **AND**計畫中的任何runtime、skill、config、guidance、receipt或legacy removal更新回報`would-update`
- **AND**target、registry與persistent state零寫入；system temporary validation snapshots在該target invocation結束時清除
