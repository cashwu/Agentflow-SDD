## MODIFIED Requirements

### Requirement: Repo-vendored Cash bundle 發佈

`cash_cli.installer` SHALL新增與 `--target`、`--self`、`--register`、`--unregister`、`--list`、`--all`及 `--init-receipt`互斥的 `--vendor <project>` mode，並允許 `--dry-run`與 `--force`。vendor target MUST是安全、既存、非 canonical source的 Git worktree top-level。preflight MUST對每個planned managed inventory、manifest、config與guidance path驗證其已由Git tracked，或不受repository `.gitignore`、`.git/info/exclude`與global exclude規則排除；任何blocked path MUST在首次target write前一次列出並fail closed，final publication前 MUST以相同path集合重驗。空值、root、symlink、non-Git、Git子目錄、unsafe config／guidance／inventory boundary或blocked planned path MUST fail closed，且 `--force` MUST NOT繞過。

`cash-skill-workflows` capability之 `手動的 cash 專案 registry` requirement已將 `--vendor`明列為非registry的repo-vendored publication；registry資料格式不變，receipt-based record的batch語意不變。registry操作接受何種target、以及batch如何為每個record選擇publication路徑，由本requirement的batch publication-mode分派段落與 `手動的 cash 專案 registry`、`版本感知的 cash skill 批次安裝` 共同治理，並以較窄契約優先。

`--vendor` MUST以 `source_inventory`作為 receipt與portable manifest共用的 version、runtime generation及受管 record單一來源，並 deterministic產生 canonical manifest。fresh publication MUST在同一 stable lock的 exclusive FD與 recoverable transaction中發佈 launcher、lock、runtime、canonical 24 skills、必要 config／guidance及manifest，MUST NOT建立 receipt；它 MUST沿用 receipt-based target的 `.gitignore` plan以排除 `.cash-skills/receipt.tsv`、`.cash-skills/state/`與 `__pycache__/`，但 MUST NOT排除portable manifest或其他planned publication path。manifest MUST是最後一筆trust-bearing managed bundle publication；唯一可排在它之後的operation是 `receipt_delete` cleanup。journal在manifest前失敗 MUST rollback舊gate，manifest成功後 MUST進入 `portable_cutover` phase並在後續失敗時保留新portable gate、roll forward完成cleanup。既有 vendored baseline的mode比較 MUST使用manifest的 Git logical mode，合法 umask造成的完整POSIX permission差異 MUST NOT構成managed drift。成功後相同 source重跑 MUST回報 `Result: current`且零寫入；有合法較舊bundle或 project-owned managed digest／logical-mode drift時依既有 update／conflict規則分類，`--force`只可收斂 replaceable managed bytes與mode class，不得接受 unsafe shape、version downgrade、invalid baseline manifest或 unapproved launcher drift。`--dry-run` MUST執行相同分類與 revalidation但 target零寫入。

receipt與manifest都缺失時，zero managed inventory MUST分類為fresh並在real run回報 `Result: update`；stable launcher／lock、runtime及canonical skills完整且逐檔符合source digest、Git logical mode與safe shape時 MUST分類為receiptless adoption，在exclusive lock下保留相符bytes並最後發布manifest。partial、unknown或different inventory未帶 `--force`時 MUST conflict；`--force`只可補齊或替換canonical expected path上的missing／different replaceable runtime與skills。unknown extra runtime及unknown stable drift即使帶 `--force`也 MUST fail closed。stable prefix只能是absent、safe empty lock、current launcher或allowlisted old launcher。

manifest absent的receipt-based target只有在既有 receipt完整通過receipt schema、identity、inventory及source版本判定時，才可由明示 `--vendor`轉換。轉換 MUST在同一transaction中發佈新inventory並以manifest publication完成trust-mode cutover，之後刪除receipt作為machine-local cleanup。若crash發生在manifest與cleanup之間，launcher因manifest-first precedence仍 MUST可用，recovery MUST完成cleanup。manifest已存在時，safe regular single-link receipt是non-authoritative residue，`--vendor` MAY不解析其內容而transactionally刪除；unsafe receipt shape仍 MUST fail closed。反向轉換 MUST NOT隱式發生：direct `--target`遇到 manifest時 MUST拒絕並指出該 target由 `--vendor`管理。registry batch `--all`與 `--register`則不再以拒絕達成此保證，改由緊接其後的 batch publication-mode 分派契約治理。

registry batch `--all` SHALL 先以 read-only publication-mode probe 判定每個 registry record 的發佈模式，再分派到對應的既有 publication 路徑：判定為 vendored 的 record 走本 requirement 的 repo-vendored publication，其餘 record 走 receipt-based publication。probe MUST 只做讀取，MUST NOT 取鎖、寫入或解讀 target config，MUST NOT 自行產生新的 diagnostic，且 MUST NOT 在任何輸入上拋出例外——其求值過程中發生的任何例外 MUST 落入 catch-all 分支。probe 的判定 MUST 是有序且窮盡的分割，依序為：(1) resolved path 等於 canonical source → receipt；(2) 觀察到 `.cash-skills/manifest.tsv` 存在且為 regular file → vendor；(3) 其餘全部 remaining record，以及任何分支求值時發生的任何例外 → receipt。第 (3) 支是 catch-all：probe 落到 receipt 時，receipt-based publication 自身既有的 manifest 拒絕仍 MUST 生效，因此隱式反向轉換在任何 probe 結果下都不可能發生。非 regular shape 的 manifest MUST 落入第 (3) 支的 receipt 路徑，因為 repo-vendored publication 會在其 shape 驗證之前先開檔讀取 manifest，對 FIFO 會阻塞而永不 fail closed；receipt 路徑只以 `lstat` 判定，因此 MUST NOT 阻塞。present-but-malformed 或 unsafe shape 的 manifest MUST NOT 被當成 absent 而讓任一路徑繼續發佈：結果 MUST 是在首次 write 前以 execution error fail closed 且零寫入。由 batch 分派到 vendored 路徑的 record，MUST 在該路徑的任何分類進入點（含 journal recovery 後的重入）之前重新確認 manifest 仍存在；不存在時 MUST fail closed，MUST NOT 在 batch 上下文執行只可由明示 `--vendor` 進行的 receipt 轉換或 receiptless adoption。分派到 vendored 路徑且實際進入 publication transaction 的 record（即 real run 的 `update`），其殘留 `.cash-skills/receipt.tsv` MUST 依既有的 machine-local residue cleanup 在同一 transaction 內刪除；`--dry-run` 與 `conflict`、`newer` 的早期返回不建立 transaction，因而 MUST 維持零寫入且 MUST NOT 刪除該檔。此後果 MUST 被視為分派的一部分而非未宣告的副作用。batch 的 label 對映、summary 計數鍵集合、結束碼規則與 stderr 錯誤行格式 MUST 不變；publication-mode 判定本身 MUST NOT 成為中止批次的新來源；probe 落入 catch-all 之後，由被分派到的 publication 路徑重新產生的 `InstallerError` MUST 使該 record 計為 `failed`，而後續 record 仍被處理且 summary 仍輸出；分派到 vendored 路徑的 record MUST 在其輸出行的 record 之後附加 ` (vendored)` 後綴，該後綴 MUST 反映被分派到的模式而與最終 label 無關，因此 `failed`、`conflict` 與 `newer` 行同樣帶有它。`--all --force` 分派到 vendored 路徑時 MUST 逐字沿用 `--vendor --force` 的收斂邊界。`--register` MUST 接受 manifest-present target 並完成登錄，其 target prerequisite 驗證、正規化、去重與 atomic registry 寫入 MUST 不變；registry 本身 MUST NOT 記錄發佈模式，模式一律由 target 當下狀態在每次 batch 重新判定。

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

#### Scenario: Direct receipt mode 仍拒絕 vendored target

- **GIVEN** target有portable manifest，不論 receipt缺失或殘留
- **WHEN** 該 target被傳給 `--target`
- **THEN** receipt-based mode拒絕隱式轉換並提供 `--vendor`指引
- **AND** target不因該 target被修改

#### Scenario: Batch 依 target 模式分派

- **GIVEN** registry同時登錄一個具有regular portable manifest的target與一個manifest缺失的target，且source具有較新bundle
- **WHEN** 執行 `--all`
- **THEN** 具有regular manifest的target以repo-vendored publication更新、保留portable manifest模式並刪除任何殘留receipt，manifest缺失的target以receipt-based publication更新
- **AND** 兩者都計入 `updated`，summary的 `failed` 為零且結束碼為零
- **AND** 具有regular manifest的target其輸出行在record之後帶有 ` (vendored)` 後綴，manifest缺失的target其輸出行逐字維持既有格式

#### Scenario: Batch dry run 對 vendored target 零寫入

- **GIVEN** registry登錄一個具有較舊有效portable manifest的target
- **WHEN** 執行 `--all --dry-run`
- **THEN** installer對該target回報 `would-update` 並帶 ` (vendored)` 後綴
- **AND** 該target零寫入且manifest維持原內容

#### Scenario: Probe 無法判定時退回 receipt 路徑

- **GIVEN** registry record不是既存目錄，或resolved path等於canonical source，或probe求值時發生例外
- **WHEN** 執行 `--all`
- **THEN** 該record分派到receipt-based publication並沿用其既有診斷
- **AND** probe自身不產生額外diagnostic，改由被分派到的receipt路徑重新產生的 `InstallerError` 使該record以 `failed` 計數而不中止batch
- **AND** 其餘record仍被處理且summary仍輸出

#### Scenario: 非 regular 的 manifest shape 在 receipt 路徑 fail closed

- **GIVEN** target的 `.cash-skills/manifest.tsv` 或其parent boundary為symlink
- **WHEN** 執行 `--all`
- **THEN** 該record落入catch-all的receipt路徑，並以 `symlink managed boundary` 在首次write前fail closed
- **GIVEN** target的 `.cash-skills/manifest.tsv` 存在但為directory、FIFO或其他non-regular shape
- **WHEN** 執行 `--all`
- **THEN** 該record同樣落入catch-all的receipt路徑，並以既有的portable manifest拒絕在首次write前fail closed
- **AND** 兩種情形都零寫入、都不阻塞，且MUST NOT被當成manifest absent而讓任一路徑繼續發佈

#### Scenario: Hard-linked regular manifest 由 vendored 路徑 fail closed

- **GIVEN** target的 `.cash-skills/manifest.tsv` 是regular file但其link count大於一
- **WHEN** 執行 `--all`
- **THEN** 該record通過publication-mode判定而分派到repo-vendored publication，並由其single-link檢查在首次write前fail closed
- **AND** 該record以 `failed` 計數、其輸出行帶有 ` (vendored)` 後綴且target零寫入

#### Scenario: 分派後 manifest 消失則 fail closed

- **GIVEN** 某個record在publication-mode判定時具有regular portable manifest
- **AND** 該manifest在repo-vendored publication進入分類前消失
- **WHEN** 執行 `--all`
- **THEN** 該record以execution error fail closed並計為 `failed`
- **AND** installer MUST NOT在batch上下文執行只可由明示 `--vendor` 進行的receipt轉換或receiptless adoption

#### Scenario: Batch force 沿用 vendored 收斂邊界

- **GIVEN** registry登錄一個valid manifest所記錄的replaceable runtime或skill已drift但shape仍安全的target
- **WHEN** 執行 `--all`
- **THEN** 該target回報 `conflict` 並帶 ` (vendored)` 後綴且零寫入
- **WHEN** 再次執行 `--all --force`
- **THEN** installer只收斂受管replaceable內容與mode class並發佈新manifest，project-owned內容維持不變
- **AND** registry中manifest版本高於source的vendored record回報 `newer: <path> (vendored)` 且零寫入
- **AND** unsafe shape、version downgrade、invalid baseline manifest或未核准的launcher drift即使帶 `--force` 也fail closed

#### Scenario: Register 接受 vendored target

- **GIVEN** 符合全部target prerequisites且已具有regular portable manifest的target
- **WHEN** 執行 `--register <project>`
- **THEN** installer完成登錄且不安裝、不建立receipt、不修改該target
- **AND** 後續 `--all` 以repo-vendored publication處理該record

#### Scenario: Self refresh 維持 canonical manifest

- **GIVEN** canonical source的 versioned inventory已合法調升但manifest或本機receipt尚未同步
- **WHEN** 執行 source-only `--self`
- **THEN** installer在同一exclusive lock transaction發布canonical manifest、清除source receipt residue並回報 `Result: bootstrap`
- **AND** 重複執行回報 `Result: current`且manifest零寫入、receipt維持absent
