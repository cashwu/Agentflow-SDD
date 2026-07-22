## ADDED Requirements

### Requirement: Cash project guidance migration

`install-cash-skills.fish` SHALL 從 source repository 的 `AGENTS.md` 與 `CLAUDE.md` 各擷取恰好一個完整的 `<!-- CASH:START -->`／`<!-- CASH:END -->` canonical block，並在任何 target 寫入前驗證 source files 為非 symlink、可讀的 regular files，Cash markers 完整、唯一且順序正確。每份source與既有target guidance的identity、mode、完整bytes、digest、marker解析與render MUST 綁定到同一次`O_NOFOLLOW` file-handle snapshot，且parser MUST NOT 在記錄digest後透過pathname重讀內容。Source file中由外部工具加入但不與 Cash block巢狀的合法 Spectra managed block MUST NOT 阻斷 canonical Cash block擷取或其他 target更新。對每個非 `newer`、非 `conflict` target，安裝器 MUST 使 `AGENTS.md` 與 `CLAUDE.md` 各含一個與其 source variant 相同的 canonical Cash block，MUST 移除一個可安全辨識的完整 Spectra managed block，且 MUST 保留 managed block spans之外的既有 bytes與既有 POSIX mode bits；新建 guidance files MUST 使用 `0644`。每個changed guidance publication MUST 由單一publisher process持有已驗證的no-follow parent directory FD，以`chdir($directory_fh)`把working directory綁定到held directory object，並使temporary create、anchored snapshot read、mode設定、failure cleanup與atomic rename MUST 全部只對不含`/`的validated relative basenames執行；parent pathname replacement MUST NOT 將任何操作重新導向替代路徑。Cash guidance SHALL NOT 加入 `.cash-skills/receipt.tsv`，且標準 `spectra-*` skills MUST 保持不變。

#### Scenario: 缺少 guidance files 的 target 建立雙變體

- **GIVEN** 有效 target 不存在 `AGENTS.md` 與 `CLAUDE.md`
- **WHEN** 安裝器完成成功的非 `newer`、非 `conflict` 安裝
- **THEN** 它建立只含對應 canonical Cash block 的兩個 regular files
- **AND** `AGENTS.md` 使用 `$cash-*`
- **AND** `CLAUDE.md` 使用 `/cash-*`
- **AND** 它回報 `Result: update`

#### Scenario: Spectra-only guidance 原地遷移

- **GIVEN** target guidance file 含一個完整且唯一的 Spectra managed block及 block 外自訂 bytes
- **WHEN** 安裝器執行 guidance migration
- **THEN** 它以對應 canonical Cash block取代 Spectra block
- **AND** 它逐位元組保留 block span 外的自訂內容
- **AND** 它不移除任何標準 `spectra-*` skill

#### Scenario: Cash 與 Spectra blocks 同時存在時收斂為 Cash-only

- **GIVEN** target guidance file 含一個合法 Cash block與一個合法 Spectra block
- **WHEN** 安裝器執行 guidance migration
- **THEN** 它在 Cash block原位置更新 canonical Cash內容
- **AND** 它移除 Spectra block
- **AND** 它保留兩個 managed spans 之外的 bytes

#### Scenario: 無 managed block 的既有文件附加 Cash block

- **GIVEN** target guidance file 是不含 Cash 或 Spectra markers 的 regular file
- **WHEN** 安裝器執行 guidance migration
- **THEN** 它只以最少必要的邊界換行在檔尾附加 canonical Cash block
- **AND** 原有 bytes 維持不變

#### Scenario: Canonical target 重複安裝保持 current

- **GIVEN** skills、receipt 與 source version皆為 current
- **AND** target 不含 retired plus candidate或 Spectra managed block
- **AND** 兩個 target Cash blocks皆與 source canonical blocks相同
- **WHEN** 安裝器再次執行
- **THEN** 它不修改任何 target bytes
- **AND** 它回報 `Result: current`

#### Scenario: Spectra app 重新加入 guidance 後可再次收斂

- **GIVEN** canonical Cash target之後又被加入一個合法 Spectra managed block
- **WHEN** 同版本 Cash installer再次執行
- **THEN** 它移除 Spectra block並保留 canonical Cash block與其他 bytes
- **AND** 它回報 `Result: update`

#### Scenario: Guidance marker結構不合法時 fail closed

- **GIVEN** source 或 target guidance file含孤立、反序、重複、巢狀或非獨立行的 Cash/Spectra markers
- **WHEN** 安裝器執行 preflight
- **THEN** 它以 code 1 結束且不輸出 `Result:`
- **AND** `--force` 不繞過該失敗
- **AND** 它不修改任何 skill、guidance file、receipt或 retired plus candidate

#### Scenario: Post-preflight guidance變更不被覆蓋

- **GIVEN** target guidance在 preflight後、最後destination checkpoint完成前被修改，或其 parent/destination identity被替換
- **WHEN** installer準備建立 temporary file或執行最後destination checkpoint
- **THEN** 它重新驗證完整 snapshot bytes與 parent/destination identity
- **AND** 不一致時以 code 1結束且不輸出 `Result:`
- **AND** 它不覆蓋 post-preflight新內容或修改 target外 sentinel
- **AND** 較早已完成的 per-file publication保持不變且不發佈新 receipt

#### Scenario: Guidance snapshot metadata與render bytes來自同一次讀取

- **GIVEN** source或既有target guidance的同一inode可能在分離的pathname reads之間被短暫修改後還原
- **WHEN** installer擷取canonical block或render target guidance
- **THEN** identity、mode、digest、marker解析與rendered bytes全部來自同一次`O_NOFOLLOW` file-handle snapshot
- **AND** publisher的source與destination revalidation使用該snapshot bytes計算的digest

#### Scenario: Guidance publication 綁定已驗證 parent directory object

- **GIVEN** guidance publisher已以no-follow語意開啟parent directory並核對其device/inode與preflight identity
- **WHEN** parent pathname在temporary create前或atomic rename前被替換，或在最後一次pathname checkpoint後指向另一個directory
- **THEN** checkpoint已觀察到identity不符時publisher以code 1結束且不發佈目前guidance或新receipt
- **AND** checkpoint後發生的pathname replacement MUST NOT 將temporary create、cleanup或atomic rename重新導向替代parent
- **AND** 替代parent中的同名sentinel、later guidance與既有receipt bytes保持不變

#### Scenario: Atomic rename commit window不宣稱destination compare-and-swap

- **GIVEN** publisher已完成最後一次anchored destination identity與完整bytes checkpoint
- **WHEN** 未遵守同一協作同步機制的其他process在checkpoint後、atomic rename syscall前改寫同一destination basename
- **THEN** 該concurrent destination writer明確不在本change的保護範圍
- **AND** installer MUST NOT 以額外pathname `lstat`宣稱提供inode-conditional atomic replace

#### Scenario: Runtime publication失敗依重試時的可觀測狀態收斂

- **GIVEN** 所有 preflight validation已通過
- **AND** 一個較早的 per-file atomic publication已完成
- **WHEN** 較後的 guidance或 skill publication發生 runtime failure
- **THEN** installer以 code 1結束且不輸出 `Result:`
- **AND** 它不發佈新 receipt、保留既有有效 receipt且不回滾已完成的 per-file publication
- **AND** 下一次 invocation不依賴不可觀測的publication歷史，而依目前 skills、receipt與guidance重新分類
- **AND** 有有效 receipt且 skills相對 receipt漂移時，一般重試回報 `Result: conflict`且零寫入，只有帶 `--force`才收斂
- **AND** 若無 receipt且零個受管 skill目的地存在，一般重試沿用首次安裝
- **AND** 若無 receipt且24個 skills已全數與source相同，一般重試沿用 receipt-less adoption並補齊 guidance與receipt
- **AND** 若無 receipt且至少一個受管 skill目的地存在但未滿足完整全等 adoption，一般重試回報 `Result: conflict`且零寫入，只有帶 `--force`才收斂

##### Example: Marker狀態分類

| Cash pair | Spectra pair | 結果 |
| ----- | ----- | ----- |
| 0 | 0 | 附加 Cash block |
| 0 | 1 | 以 Cash block取代 Spectra block |
| 1 | 0 | 更新 Cash block |
| 1 | 1 | 更新 Cash block並移除 Spectra block |
| 2 | 0 | code 1、零寫入 |
| 1 | 2 | code 1、零寫入 |
| 孤立 start | 0 | code 1、零寫入 |

### Requirement: Cash 指引提供無向量模型替代流程

`AGENTS.md` 與 `CLAUDE.md` 的 canonical Cash blocks MUST 逐 byte包含下列完整 Markdown block，不得摘要、重排或省略。Installer MUST NOT 為此 fallback偵測模型狀態、執行語意搜尋或下載模型。

```markdown
## 向量模型未下載時的替代方式

Spectra 的語意搜尋依賴本機向量模型。若模型尚未下載，不需要中斷或要求先下載，直接改用路徑與檔案讀取：

- 使用者直接給 change 名稱 → 直接讀 `openspec/changes/<name>/` 底下的 artifacts（找不到時用 `spectra list --parked` 確認是否被 parked）
- 問程式碼或需求相關的問題 → 直接用 Grep／Read 搜尋 `openspec/specs/` 與程式碼來回答
```

#### Scenario: 已知 change名稱時不依賴向量搜尋

- **GIVEN** 本機向量模型尚未下載
- **WHEN** 使用者直接提供 change名稱
- **THEN** agent直接讀取 `openspec/changes/<name>/` 下的 artifacts
- **AND** 找不到 active change時使用 `spectra list --parked` 確認 parked狀態
- **AND** agent不要求先下載模型

#### Scenario: 程式碼或需求問題使用檔案搜尋

- **GIVEN** 本機向量模型尚未下載
- **WHEN** 使用者詢問程式碼或需求相關問題
- **THEN** agent使用 Grep／Read 搜尋 `openspec/specs/` 與程式碼
- **AND** agent不中斷工作或要求先下載模型

## MODIFIED Requirements

### Requirement: 無狀態的跨專案安裝器

本 repository SHALL 提供 `install-cash-skills.fish` 作為唯一的 cash 安裝與更新 CLI。它 MUST 恰好接受 `--target <project>`、`--register <project>`、`--unregister <project>`、`--list` 或 `--all` 其中之一；`--dry-run` 與 `--force` MUST 僅在搭配 `--target` 或 `--all` 時有效。在 target 模式下，安裝器 MUST 在首次寫入 target之前，驗證完整的 24 檔 skill來源清單、兩個 canonical Cash guidance source blocks、來源 bundle版本、存在時的 target receipt、target目錄、每個受管 skill目的地、`AGENTS.md`、`CLAUDE.md`、guidance markers、精確的已除役 plus skill候選項，以及所有 conflict與write conditions。它 SHALL 在成功的安裝、認養、升級、修復或同版本 guidance／retired-plus cleanup過程中，安裝或更新 canonical Cash blocks、移除可安全辨識的 Spectra managed blocks，並移除可辨識的 `.agents` 與 `.claude` 下的 `spectra-propose-plus` 與 `spectra-apply-plus` 目錄，同時保留其他所有 Spectra skill、managed guidance spans以外的專案內容與未知 legacy內容。它在自動專案探索與排程方面 SHALL 保持無狀態，同時管理 skill版本與漂移判斷所需的 target本地 receipt與明確的使用者 registry。對每個完成的 target領域判定，它 MUST 恰好輸出一行終端結果，值為 `update`、`current`、`newer` 或 `conflict`；conflict MUST 以 code 2 結束，其他每種領域結果 MUST 以 code 0 結束，而執行失敗 MUST 以 code 1 結束且不輸出領域結果。

#### Scenario: 安裝至乾淨的 target

- **WHEN** 安裝器收到一個沒有任何 cash目的地、guidance files或 receipt的有效 target
- **THEN** 它安裝全部 24 個 canonical skill檔案與兩個 canonical Cash guidance files
- **AND** 每個安裝的 skill檔案皆與其來源位元組相同
- **AND** 它發佈當前的 skill receipt
- **AND** 它回報 `Result: update`
- **AND** 它以 code 0 結束

#### Scenario: 完全相同的 legacy target 被認養

- **WHEN** 全部 24 個受管 target skill檔案皆與來源位元組相同且不存在 receipt
- **THEN** 安裝器保持所有 skill檔案不變
- **AND** 它遷移或安裝兩個 canonical Cash guidance blocks
- **AND** 它發佈當前的 skill receipt
- **AND** 它回報 `Result: update`
- **AND** 它以 code 0 結束

#### Scenario: 已有部分或不同 skills的 legacy target在寫入前即衝突

- **GIVEN** 不存在 receipt
- **AND** 至少一個受管 skill目的地存在
- **AND** 受管 skill目的地未達到24檔全數存在且與來源相同的 adoption條件
- **WHEN** 安裝器在未帶 `--force` 下執行
- **THEN** 它回報每個衝突的 skill目的地
- **AND** 它回報 `Result: conflict`
- **AND** 它以 code 2 結束
- **AND** 它不安裝、不取代也不發佈任何 skill、guidance或 receipt狀態

#### Scenario: 乾淨的較舊 target 無需 force 即可升級

- **GIVEN** 有效的 receipt記錄了低於來源的版本
- **AND** 每個受管 target skill檔案皆符合其記錄的 receipt digest
- **WHEN** 安裝器在未帶 `--force` 下執行
- **THEN** 它以來源 bundle取代 24 個受管 skill檔案
- **AND** 它收斂兩個 Cash guidance files
- **AND** 它發佈新的 receipt
- **AND** 它回報 `Result: update`
- **AND** 它以 code 0 結束

#### Scenario: 版本相同且 guidance canonical 的 target 為 current

- **GIVEN** 有效的 receipt記錄了來源版本
- **AND** 所有來源與 target skill檔案的 digests皆符合該 receipt
- **AND** 兩個 target Cash blocks皆為 canonical且不存在 Spectra block或 retired plus candidate
- **WHEN** 安裝器執行
- **THEN** 它回報 `Result: current`
- **AND** 它不對 target進行任何寫入
- **AND** 它以 code 0 結束

#### Scenario: 安裝過程移除可辨識的已除役 plus skills

- **GIVEN** 一個或多個精確的已除役 plus目錄僅包含一個一般的 `SKILL.md`，其封閉的 frontmatter區塊恰好含有一個符合 `spectra-propose-plus` 或 `spectra-apply-plus` 的 `name`欄位
- **WHEN** 安裝器完成安裝、認養、升級、修復或同版本 cleanup
- **THEN** 它移除每個可辨識的 plus `SKILL.md` 及其隨之清空的 skill目錄
- **AND** 它保留每個非 plus的 Spectra skill，以及四個精確已除役 plus目錄以外的每個 skill路徑
- **AND** 一個除此之外為 current的 target回報 `Result: update`

#### Scenario: 不安全的已除役 plus 候選項在寫入前即失敗

- **GIVEN** 某個精確的已除役 plus路徑是 symlink、不是目錄、包含 `SKILL.md` 以外的項目，或其 `SKILL.md` 缺失、為 symlink、不可讀、frontmatter格式錯誤、name重複、name衝突或 name不符
- **WHEN** 安裝器執行 preflight
- **THEN** 它以 code 1 結束且不輸出領域結果
- **AND** 它不修改 cash files、guidance files、receipt或任何已除役 plus候選項

#### Scenario: 同版本下的來源 skill 變異屬完整性失敗

- **GIVEN** 有效的 receipt記錄了來源版本
- **AND** 至少一個當前 skill來源 digest與 receipt digest不同
- **WHEN** 安裝器在帶或不帶 `--force` 下執行
- **THEN** 它以 code 1 結束且不輸出領域結果
- **AND** 它不對 target進行任何寫入

#### Scenario: 較新的 target 被保留

- **GIVEN** 有效的 target receipt記錄了高於來源的版本
- **WHEN** 安裝器在帶或不帶 `--force` 下執行
- **THEN** 它回報 `Result: newer`
- **AND** 它不對 skill、guidance、receipt或 retired plus候選項進行任何寫入
- **AND** 它以 code 0 結束

#### Scenario: 漂移在寫入前即衝突

- **GIVEN** 存在有效的較舊或同版本 receipt，且至少一個受管 target skill檔案與其可信比對內容不同
- **AND** 當版本相同時，每個當前 skill來源 digest皆符合該 receipt
- **WHEN** 安裝器在未帶 `--force` 下執行
- **THEN** 它指出每個衝突的 skill目的地
- **AND** 它回報 `Result: conflict`
- **AND** 它以 code 2 結束
- **AND** 它不安裝、不取代也不發佈任何 skill、guidance或 receipt狀態

#### Scenario: Force 僅取代受管 skill 與 guidance spans

- **GIVEN** target版本不高於來源
- **AND** 所有來源、receipt、guidance與檔案系統驗證皆已成功
- **WHEN** 安裝器帶 `--force` 執行
- **THEN** 它安裝或取代有差異的受管 cash skill目的地
- **AND** 它遷移或更新兩個 Cash guidance blocks並保留其 managed spans以外的 bytes
- **AND** 它為最終的 24 個 skill檔案發佈 receipt
- **AND** 它保留明確 24 檔清單、receipt、兩個 guidance managed spans與可辨識已除役 plus項目以外的每個檔案內容
- **AND** 它僅移除四個精確已除役 plus目錄中可辨識的項目與合法 Spectra guidance blocks
- **AND** 它回報 `Result: update`

#### Scenario: Dry run 不產生持久性影響

- **WHEN** 安裝器帶 `--dry-run` 執行
- **THEN** 它依一般 preflight規則回報領域結果與包含 guidance actions的完整行動計畫
- **AND** 它不建立或修改 target目錄、target暫存檔、guidance file、receipt、registry、cache、lock、LaunchAgent或背景行程
- **AND** 它不移除任何 Spectra guidance block或已除役 plus skill

#### Scenario: Preflight後的 publication失敗保留 receipt

- **GIVEN** skill、guidance、receipt與 boundary preflight全部成功
- **WHEN** 一個或多個 per-file publication完成後發生 runtime write failure
- **THEN** installer以 code 1結束且不輸出領域結果
- **AND** 它不發佈新 receipt、不回滾已完成的 per-file publication，並保留既有有效 receipt
- **AND** 下一次 invocation依當下可觀測 state套用既有 drift、receipt-less conflict或 adoption分類
- **AND** 有 receipt的 drift在一般重試回報 `Result: conflict`且零寫入，只有帶 `--force`才重新收斂
- **AND** 無 receipt且零個受管 skill目的地存在時，一般重試走首次安裝
- **AND** 無 receipt且24檔皆與source相同時，一般重試透過 adoption收斂並發佈新 receipt
- **AND** 無 receipt且至少一個目的地存在但未滿足完整全等 adoption時，一般重試回報 `Result: conflict`且零寫入，只有帶 `--force`才重新收斂

### Requirement: Cash 安裝不含修復自動化

Cash安裝器 MUST NOT 從 Git狀態計算新鮮度、排程修復、安裝 LaunchAgent、fork背景行程，或修改使用中或非 plus的 Spectra管理 skill。在明確的 target安裝期間，它 SHALL 管理 `AGENTS.md`／`CLAUDE.md` 中精確辨識的 Cash與Spectra guidance blocks，且 SHALL 僅移除四個精確已除役 `spectra-propose-plus` 與 `spectra-apply-plus` 目錄中可辨識的項目；它 SHALL NOT 移除任何其他 Spectra skill。Cash skill與 guidance的維護 SHALL 僅透過明確的 source變更與明確的安裝器呼叫進行。target receipts與使用者 registry SHALL 僅為支援那些明確呼叫而持久保存，且 MUST NOT 觸發未來的工作。

#### Scenario: 完成的 cash 安裝

- **WHEN** 一次 cash安裝成功
- **THEN** Cash installer新增或管理的持久 target狀態僅包含 cash skill檔案、Cash guidance managed blocks與 target receipt
- **AND** 既有標準 Spectra skills、managed guidance spans外內容與其他 project-owned state保持不變
- **AND** 沒有任何未來的行程被排程
- **AND** 之後的 source變更在安裝器被再次明確呼叫之前不會傳播

#### Scenario: 完成的 registry 操作

- **WHEN** 某個 target被註冊、取消註冊或列出
- **THEN** 不建立任何 LaunchAgent、daemon、排程任務、cache、lock或背景行程
- **AND** registry本身不會使之後的 source變更自行傳播

### Requirement: 安裝器與清理落實檔案系統邊界

安裝器 SHALL 正規化既有的 target，且 MUST 拒絕空的 target、無法解析的 target、`/`、來源 repository本身或 symlink target。在任何 target寫入之前，它 MUST 拒絕身為 symlink的受管 skill目的地、guidance source/target、receipt、暫存同層檔案、可辨識的已除役 plus候選項或既有受管父目錄，且 MUST 證明每個解析後的目的地與移除候選項皆維持在正規化 target之下。對既有 guidance file，它 MUST 以單一`O_NOFOLLOW` file handle綁定identity、mode、完整bytes、digest、markers與render，驗證file與parent write conditions及同目錄 temporary file的 atomic-replace邊界；MUST 記錄preflight snapshot bytes與parent/destination identity；且 MUST 在 temporary file建立前與最後destination checkpoint重新驗證 snapshot及 identity未改變。每個guidance publisher MUST 以no-follow語意開啟parent directory並持有經`fstat`驗證的directory FD，以`chdir($directory_fh)`綁定publisher working directory後再次核對`stat(".")` identity；temporary create、destination snapshot read、mode設定、cleanup與atomic rename MUST 僅對不含`/`的validated relative basenames執行，且 MUST NOT 在identity mismatch或publication failure後透過原始parent pathname清除temporary file。Publisher MUST 在首次target mutation前驗證平台支援directory-handle `chdir`與綁定後的relative child lookup。Preflight boundary failure MUST 以零 target writes fail closed；preflight後的 runtime publication failure MUST 不發佈新 receipt、保留既有有效 receipt且不得回滾較早完成的 per-file publication。最後destination checkpoint至atomic rename syscall之間的非協作concurrent destination writer不在本change保護範圍，且installer MUST NOT 宣稱一般POSIX rename具備預期inode conditional replace。下一次 invocation MUST 依目前可觀測 state分類：有有效 receipt的 skill drift在一般重試 MUST 回報 `conflict`且零寫入並須帶 `--force`才可收斂；無 receipt時，零個受管 skill目的地存在 MUST 走首次安裝，24檔全數存在且與source相同 MUST 走 adoption，至少一個目的地存在但未滿足完整全等 adoption才 MUST 在一般重試回報 `conflict`且零寫入並須帶 `--force`；guidance差異在非 conflict分支 MUST 可由一般重試收斂。它 MUST 將每個既有的已除役 plus候選項驗證為精確的單檔 legacy形態。在破壞性清理之前，它 MUST 以目的地 symlink no-follow語意，將候選項 atomic-rename至同一 target父目錄之下唯一的同檔案系統隔離區，在不追隨原候選項路徑的情況下重新驗證被隔離的物件，且僅移除仍可辨識的 `SKILL.md` 及其清空的隔離目錄。若重新驗證失敗，它 MUST 保留未知內容且 MUST NOT 使用遞迴刪除。在 registry支援的模式中，安裝器 SHALL 驗證 `HOME`非空、為絕對路徑、存在且不是 `/`；SHALL 使 registry路徑與暫存同層檔案維持在正規化 `HOME`之下；且 MUST 在 registry讀寫之前拒絕 symlink的組態邊界。清理 SHALL 保留其既有的精確已知路徑 HOME邊界合約。

#### Scenario: 安裝器在寫入前拒絕 symlink 逃逸

- **GIVEN** 受管的 target父目錄、skill目的地、guidance file、receipt或其父目錄是 symlink
- **WHEN** `install-cash-skills.fish` 執行 preflight
- **THEN** 它在建立或取代任何 target file之前以非零結束
- **AND** 它指出不安全的專案相對目的地

#### Scenario: Guidance atomic replace 不改寫外部 hard link inode

- **GIVEN** 既有 target guidance regular file是某個 target外 inode的 hard link
- **WHEN** installer發佈更新後的 guidance file
- **THEN** 它使用 target file同目錄的 temporary file與 atomic replace
- **AND** target外 inode的 bytes維持不變

#### Scenario: Guidance publication重新驗證 identity與 mode

- **GIVEN** guidance preflight已記錄 destination bytes、parent/destination identity與既有 POSIX mode bits
- **WHEN** installer準備建立 temporary file與執行 atomic publish
- **THEN** 它在兩個時點重新驗證 bytes與 identity
- **AND** 不一致時不發佈目前 guidance file且不修改 target外 sentinel
- **AND** publication成功時既有 mode bits保持不變，新建 guidance file使用 `0644`

#### Scenario: Guidance cleanup 與 rename 不重新解析失效 parent pathname

- **GIVEN** publisher持有已驗證parent directory FD且已在其中建立exclusive temporary file
- **WHEN** parent pathname或destination在publication前被替換為另一個directory、inode或symlink
- **THEN** publisher透過held directory FD重新驗證原destination snapshot並在不符時以code 1結束
- **AND** failure cleanup只移除held directory object內由本次publisher建立的temporary basename
- **AND** publisher MUST NOT 透過失效parent pathname執行`rm`、`mv`或任何替代destination write

#### Scenario: 安裝器拒絕其來源 repository

- **WHEN** 安裝器的 target解析為包含該安裝器的 repository
- **THEN** 它在寫入 receipt、guidance或 skill file之前以非零結束

#### Scenario: 安裝器拒絕不安全的 HOME 或 registry 邊界

- **GIVEN** `HOME`為空、相對、不存在、`/`，或某個既有的 registry邊界是 symlink
- **WHEN** `install-cash-skills.fish` 執行任何 registry支援的操作
- **THEN** 它以非零結束
- **AND** 它不透過不安全的邊界讀取 targets
- **AND** 它不建立也不修改任何 registry、暫存檔、guidance、receipt或 skill file

#### Scenario: 清理拒絕不安全的 HOME 或 symlink 邊界

- **GIVEN** `HOME`為空、相對、`/`，或某個精確清理路徑有 symlink的既有邊界
- **WHEN** `uninstall-spectra-plus-repair.fish` 執行 preflight
- **THEN** 它以非零結束
- **AND** 它不呼叫 `launchctl` 也不移除任何檔案

### Requirement: 專案擁有的 cash 指引在 Spectra 更新後存續

本 repository SHALL 使 committed `AGENTS.md` 與 `CLAUDE.md` 各含恰好一個 canonical Cash managed block，且不含 Spectra managed block。Cash block MUST 述明本專案只使用 Cash workflow invocations、Spectra CLI與 `openspec/` artifact schema仍具權威，且標準 Spectra skills是否存在不改變 Cash-only routing。若外部 Spectra update日後在 target project重新加入 Spectra managed block，Cash block MUST 保持有效；下一次明確的 Cash installer invocation MUST 移除重新加入的合法 Spectra block。若 source repository被外部工具加入 Spectra block，canonical Cash block MUST 仍可供其他 targets擷取，source repository本身 SHALL 由版本控制還原 committed Cash-only狀態。

#### Scenario: Repository guidance 為 Cash-only

- **WHEN** agent讀取 repository root的 `AGENTS.md` 或 `CLAUDE.md`
- **THEN** 文件只提供對應工具語法的 Cash workflow routing
- **AND** 文件不含 Spectra managed block或 `spectra-*` workflow invocation建議
- **AND** 文件仍指明 Spectra CLI與 `openspec/` artifacts的權威邊界

#### Scenario: Target外部更新後 Cash 指引仍有效且可再次清理

- **WHEN** 外部 Spectra update在 target guidance file重新加入一個合法 Spectra managed block
- **THEN** 既有 Cash block仍明確要求 Cash-only routing
- **AND** 下一次 Cash installer invocation移除 Spectra block並保留 Cash block與 managed spans外內容

#### Scenario: Source外部更新不阻斷其他 targets

- **GIVEN** source repository的 canonical Cash block仍完整且唯一
- **AND** 外部工具另加入一個不與 Cash block巢狀的合法 Spectra managed block
- **WHEN** installer為另一個 target擷取 canonical guidance
- **THEN** 它使用 Cash block完成 target installation
- **AND** source repository由 operator透過版本控制還原 Cash-only狀態

### Requirement: 版本感知的 cash skill 批次安裝

`install-cash-skills.fish --all [--dry-run] [--force]` SHALL 重用與 `--target` 相同的 installer target workflow，處理每個去重後的 registry target。它 MUST 將每個 target回報為 `updated`、`would-update`、`current`、`newer`、`conflict` 或 `failed`，然後印出每種狀態的計數。單一 target的 conflict或失敗 MUST NOT 停止後續 targets，且當任何 target為 `conflict` 或 `failed` 時，彙總指令 MUST 以非零結束。

#### Scenario: 較舊 bundle 或 guidance drift 被更新

- **GIVEN** registry包含有效且乾淨的 targets，其 receipt版本分別舊於、等於與新於來源版本
- **AND** 等版本 target的當前 source/target skill digests皆符合其 receipt
- **AND** 其中一個等版本 target含可安全遷移的 guidance drift，其餘等版本 target guidance為 canonical
- **WHEN** 安裝器以 `--all` 執行
- **THEN** 它將較舊 target與有 guidance drift的等版本 target回報為 `updated`
- **AND** 它將等版本且 guidance canonical的 target回報為 `current`
- **AND** 它將較新的 target回報為 `newer`
- **AND** 它不重寫等版本 current或較新的 target

##### Example: 數值版本與 guidance狀態

| Source | Target | Guidance | 預期狀態 |
| ----- | ----- | ----- | ----- |
| `1.10.0` | `1.9.9` | canonical | `updated` |
| `2.0.0` | `2.0.0` | canonical | `current` |
| `2.0.0` | `2.0.0` | Spectra-only | `updated` |
| `2.9.0` | `3.0.0` | Spectra-only | `newer` |

#### Scenario: 批次揭露等版本的來源完整性失敗

- **GIVEN** 某個已註冊 target有等於來源版本的有效 receipt
- **AND** 至少一個當前 skill source digest與該 receipt不同
- **WHEN** 安裝器以 `--all` 或 `--all --force` 執行
- **THEN** 它將該 target回報為 `failed`
- **AND** 它不進行任何 target寫入
- **AND** 彙總指令以非零結束

#### Scenario: 除非明確 force 否則 skill 漂移被保留

- **GIVEN** 某個較舊或等版本的 target有受管 skill file，其 digest與其有效 receipt不同
- **AND** 當版本相等時，每個當前 skill source digest皆符合該 receipt
- **WHEN** 安裝器在未帶 `--force` 下執行
- **THEN** 它將該 target回報為 `conflict`
- **AND** 它不修改任何受管 target狀態
- **WHEN** 安裝器再次帶 `--force` 執行
- **THEN** 它僅取代明確的受管 skill清單、guidance managed spans與 receipt
- **AND** 它將該 target回報為 `updated`

#### Scenario: Force 從不降級較新的 target

- **GIVEN** 有效的 target receipt版本高於來源版本
- **WHEN** 安裝器以 `--all --force` 執行
- **THEN** 它將該 target回報為 `newer`
- **AND** 它不修改 skill、guidance、receipt或 retired plus candidate

#### Scenario: Target 失敗不停止批次

- **GIVEN** 一個已註冊 target因 guidance或既有 validation執行失敗，且較後的已註冊 target可以更新
- **WHEN** 安裝器以 `--all` 執行
- **THEN** 它將第一個 target回報為 `failed`
- **AND** 它處理並更新較後的 target
- **AND** 彙總指令以非零結束

#### Scenario: 批次 dry run 使用完整驗證且不寫入

- **WHEN** 安裝器以 `--all --dry-run` 執行
- **THEN** 每個 target都接受與真實執行相同的 source guidance、receipt、版本、hash、registry、marker與檔案系統邊界驗證
- **AND** 計畫中的 skill或 guidance更新被回報為 `would-update`
- **AND** 沒有任何 target、guidance、receipt、registry、target內暫存檔或背景持久狀態被建立或修改
- **AND** system temporary directory中的validation/render snapshots可被建立，但 MUST 在該target invocation結束時清除

### Requirement: 現行文件反映 cash 所有權與清理

本 repository SHALL 提供 `CASH-SKILLS.md` 作為當前的 Cash workflow指南。該指南 MUST 列出雙變體清單；說明直接安裝、bundle版本、target receipt、registry指令、批次更新、dry-run、force、各狀態、結束行為、自無 receipt安裝的遷移、Cash guidance migration、marker衝突、可辨識已除役 plus skill的移除、對未知 legacy內容的安全拒絕，以及 bundle版本調升責任；保留一次性 legacy修復自動化清理的順序；並述明 Cash skills沒有週期性修復。`openspec/signals/README.md` MUST 繼續將當前 writer描述為 Cash審查迴圈，同時保留歷史性的 `## Occurrences` provenance文字。

#### Scenario: 當前的安裝與更新說明是完整的

- **WHEN** 使用者閱讀 `CASH-SKILLS.md`
- **THEN** 文件提供單一 installer進入點與所有直接、registry與 batch commands
- **AND** 它說明 target何時因 skill或 guidance被更新、何時因 current或 newer被略過、何時被阻擋為 conflict、何時被歸類為 failed
- **AND** 它指明 `cash-skills.version`、`.cash-skills/receipt.tsv` 與 `$HOME/.config/cash-skills/projects.txt`
- **AND** 它說明 Cash guidance migration只管理 marker spans、保留其餘 bytes與標準 Spectra skills，並在不合法 marker時 fail closed
- **AND** 它說明成功的 target安裝仍只移除可辨識的 `spectra-propose-plus` 與 `spectra-apply-plus` directories並拒絕未知內容

#### Scenario: 遷移文件沒有現行的修復指示

- **WHEN** 使用者閱讀 `CASH-SKILLS.md` 與 `openspec/signals/README.md`
- **THEN** 現行指示使用 `cash-propose`、`cash-apply`、installer與一次性 cleanup
- **AND** 沒有任何現行指示要使用者產生或週期性修復 plus或 Cash skills
- **AND** 歷史性的 occurrence項目維持不變
