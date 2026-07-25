## Context

Cash installer 由兩層組成：進入點 `install-cash-skills.fish` 只負責解析自身路徑、挑選 interpreter 並交棒；實際邏輯全在 `.cash-skills/lib/cash_cli/installer.py`。後者對檔案系統操作採一致的 fail-closed 基準──`ensure_contained` 拒絕 symlink 與越界路徑、`read_regular` 以 no-follow 開啟並比對 device/inode/link count、`InstallTransaction` 以 journal 記錄每一步發布並在失敗時回滾。

本變更處理三處未達該基準的既有缺陷，以及進入點的四項機制落差。三者都不涉及 receipt schema、lock 的建立與 identity 重驗機制與 lock inode 的持久性，也不涉及 legacy 遷移判準，因此可觀察的安裝結果分類（`current`、`update`、`newer`、`conflict`、`bootstrap`）維持不變，只有錯誤路徑與恢復路徑的行為收斂。

`.cash-skills/bin/cash` 是 stable bootstrap 物件，其 bytes 綁定引入 commit 且安裝後不得替換，因此本變更不觸碰它。`installer.py` 屬 replaceable runtime record，任何 bytes 變動都必須調升 `cash-skills.version`。

## Goals / Non-Goals

**Goals**

- 空值 mode 參數以 caller-input error 失敗，且零寫入。
- crash 之後的第一次 installer 執行即完成 journal recovery 並得到正確分類，不再需要第二次執行。
- fault-injection hooks 只在單一顯式開關開啟時生效，且其檔案寫入受與 installer 其餘部分相同等級的 no-follow／identity 約束。
- 進入點以 `exec` 交棒、在泛用名稱不合格時能備援到合格的版本化 interpreter、並停用 user site 目錄。

**Non-Goals**

- 不調整 batch 迴圈的例外捕捉範圍、reclassification 遞迴上限，或 registry 內不存在專案的分類。
- 不加入 parent directory 的 fsync。
- 不變更 stable launcher 的不可替換性，也不新增其 migration 路徑。
- 不變更 receipt schema、lock 的建立與 identity 重驗機制（`O_CREAT|O_EXCL`、`flock`、`fstat` device/inode 比對）與 lock inode 的持久性、legacy 遷移判準或 guidance 區塊渲染。兩項明確的例外：recovery 觸發的釋放-重入沿用既有 post-lock 重新分類的同一路徑；以及恢復前置階段需要一條**不建立** lock 的取鎖路徑（既有 `O_CREAT|O_EXCL` 建立語意與 identity 重驗步驟本身不變，只是該路徑不使用建立分支）。兩者都不改變 lock 的建立語意或 identity 重驗步驟。

## Decisions

### D1：mode 分派改用「參數是否存在」

`run()` 目前以真值判斷分派 `--target`、`--register`、`--unregister`。改為判斷是否為 `None`。argparse 對未提供的 mode 參數填入 `None`，對 `--target ""` 填入空字串，兩者因此可區分。

分派條件本身不足以滿足契約，另有兩個順序與退出碼的約束：

**空值拒絕必須是解析後的第一道檢查。** 空字串的診斷有兩個會遮蔽它的前置關卡：

- `run()` 在三個 registry 分支之前無條件執行 `records = read_registry()`。若只改分派條件，`--register ""` 仍會先讀取 registry，違反「空字串 mode 參數 MUST NOT 讀取 registry」；更嚴重的是 `read_registry()` 內含 `safe_home()` 與逐行 canonical 檢查，registry 或 HOME 本身不合法時會先以 registry／HOME 診斷失敗。
- `--dry-run` 與 `--force` 的相容性檢查的運算元不含 `--register`／`--unregister`。`--register "" --dry-run` 會先命中「`--dry-run` 需要 `--target`、`--all` 或 `--self`」，診斷指向「缺少 mode 參數」──正是本變更要消除的誤導訊息。

因此 `run()` SHALL 在解析參數之後、`read_registry()` 與相容性檢查兩者之前，對三個帶值 mode 參數各自做一次空值拒絕。

**退出碼必須是 2。** master spec 的錯誤契約規定 exit 2 表示 caller input 失敗、exit 1 表示 internal execution error。但 `InstallerError` 的 `exit_code` 預設為 1，而 D1 原先設想沿用的兩個既有守衛──`install_target` 的 `target must be a safe existing directory` 與 `canonical_target` 的 `project path is invalid`──都走預設值，且同時服務 master spec 中被歸類為 execution error 的 boundary scenario，無法一碼兩用。因此新增的空值守衛 SHALL 以 `exit_code=2` 拋出，且 SHALL NOT 改動那兩個既有守衛的退出碼。

`--dry-run` 與 `--force` 的相容性前置檢查也要對齊判準。要注意的是，空值守衛既已排在它們之前，抵達這兩個檢查時帶值參數只可能是 `None` 或非空字串，此時 `x is not None` 與 `bool(x)` 等價──因此帶值參數改用存在性判準**不改變任何可觀察行為**；`--target "" --dry-run` 的正確診斷來自順序約束而非這項修改。保留它的理由是消除分派判準與相容性判準之間的漂移，避免未來有人放寬空值守衛時這裡又悄悄回到真值語意。

真正有可觀察後果的是另一半：這兩個檢查的運算元混合了帶值參數與 `store_true` 的布林 flag（`--all`、`--self`），布林 flag 未提供時為 `False` 而非 `None`，整條改用存在性判準會使 `False is not None` 恆為真、守衛整組失效──`--list --dry-run` 會從 exit 2 變成印出 registry 並 exit 0，`--register <p> --force` 會從 exit 2 變成靜默接受。因此存在性判準 SHALL 只套用於帶值參數，布林 flag SHALL 維持真值判斷。

**替代方案（不採用）**：在 argparse 層加 `type=` 驗證器拒絕空字串。這會把錯誤訊息交給 argparse 生成，繞過既有的 `InstallerError` 診斷格式與 exit code 契約。

### D2：recovery 之後重新分類

`recover_installer` 會回滾前一次 crash 已發布的 bytes，因此它是一個會改變 target 狀態的操作。目前它在 target 快照定案之後才執行，導致 publication 前的最終比對必然不一致。

**恢復必須早於 conflict 判定。** 只把 recovery 移到快照之前還不夠：recovery 的現有呼叫點在 conflict 分類之後，而 crash 留下的半發布 bytes 只要落在任何 receipt-managed path，`validate_installed_receipt` 就會把它們收進 conflicts，執行在該處以 `managed target drift` 與 exit 2 直接返回，recovery 永遠不會被呼叫。實測確認：對已安裝 target 半發布一個 runtime path 並放入 `phase: publishing` 的 journal 後，真實執行與 `--dry-run` 皆輸出 `Result: conflict`、rc 2，journal 原封不動留在原地。換言之，若不動恢復點，本變更要修的那條路徑只有在半發布內容全部落在非 receipt-managed path（版控排除設定、guidance）時才碰得到——而那正是 conflict 判定看不見的少數幾個檔案。

因此恢復拆成**偵測**與**恢復**兩個分離的點，兩者位置不同：

1. **偵測（純讀取，早於 `newer` early return）**：`install_target` 在 read-only preflight 內偵測 journal 是否存在。這是純讀取，不持鎖、不解讀 target config，因此放在版本比較之前是安全的。通用 diagnostic 由此點發出，dry-run 與 real run 皆然，於是它對 `conflict`、`newer`、`current`、`update` 四種結論都成立；`newer` 專屬補充句另於 `newer` early return 之前輸出。
2. **恢復（緊接在 `newer` early return 之後）**：非 dry-run、target 未被分類為 `newer`、且偵測到 journal 時才執行恢復。錨定必須是「緊接在版本比較之後」而非籠統的「早於 conflict 判定」——`install_target` 在 `managed target drift` 之前還有兩個會提前返回的分類分支：legacy receipt migration 的 `legacy receipt drift`（exit 1），以及 receipt-less 分支的 `receipt-less Cash skill inventory is partial`（`conflict`、exit 2）。fresh install 在 skills 發布途中崩潰會留下「無 receipt、1–23 個 skill 已發布」的狀態而命中後者，legacy migration 崩潰則命中前者；若只把恢復排在 `managed target drift` 之前，這兩種 journal 仍永遠到不了 recovery。因此恢復 SHALL 早於這三個返回點的**全部**。`newer` 必須排除：master spec 要求合法 newer target 零寫入返回，而該 journal 是由較新 bundle 寫出的，可能使用本 bundle 不認識的 schema；對它執行 rollback 既違反零寫入，也可能把原本應回報 `newer` 的路徑變成硬失敗。newer target 的 journal 留待版本相符或更新的 installer 處理。

   要注意 `newer` 排除的判準是 **receipt 版本**，而 receipt 是 transaction 的最後一筆 operation：較新 bundle 在 publishing 階段崩潰時 receipt 尚未被替換，target 仍持有舊版本號，因此該次崩潰**不會**被 `newer` 排除。跨版本 journal 的風險因此不能只靠 `newer` 排除來擋。補充規則：journal 的 schema version 不被本 bundle 辨識時 SHALL 以 execution error fail closed，且 diagnostic SHALL 指出需要版本相符或更新的 installer——這是既有 `recover_installer` 的行為，本設計只是把它明確化並要求 diagnostic 可行動，而非讓 target 陷入無法安裝且無解釋的狀態。
3. 恢復本身的順序是「先跑既有的 `launcher exists without stable workspace lock` 守衛 → 取得既存 stable lock → 呼叫 `recover_installer` → 釋放 → 重新進入」。取鎖 SHALL NOT 建立不存在的 lock：journal 存在而 lock 不存在是外部造成的 unknown partial state，master spec 要求 fail closed；若此處以 `O_CREAT|O_EXCL` 建立新 lock，會把該狀態靜默修復成新的 lock inode，同時違反「launcher-without-lock MUST fail closed」與「下一次 installer MUST 在同一 lock inode 上恢復」。
4. `recover_installer` 回傳它是否實際處理了 journal；持鎖後 journal 已不存在時回傳偽，因此 pre-lock 的偵測結果會在持鎖時被重新驗證，偵測與恢復之間的競爭不會造成錯誤恢復。**兩個回傳分支都必須關閉 lock descriptor**：回傳真時關閉後重新進入，回傳偽時關閉後沿原流程繼續。若回傳偽時不關閉而繼續走主流程，主流程稍後會對同一 lock 檔開第二個 fd 並取 exclusive lock——同一 process 的兩個 open file description 互為獨立持有者，第二次會無限期阻塞且沒有診斷。因此本設計維持一個不變量：同一 process 在任一時刻至多持有一個 stable lock descriptor。
5. 重新進入後該份 journal 已被刪除，同一份 journal 因此不會觸發第二次 recovery 重新進入；後續的 conflict 判定、快照、legacy candidate plan 與版控排除設定 plan 全部建立在 recovery 之後的狀態上。

上界的界定是 per-journal 而非絕對：釋放 lock 到重新取得之間，另一個 installer 可能崩潰並留下一份**新的** journal，使重新進入再發生一次。這是外部併發造成的，與既有兩處重新進入來源同性質，不構成新的無界迴圈。

此決定同時修正 version-control 排除設定的規劃：該規劃由 target 快照導出，重新進入後快照取自 recovery 之後的狀態。

**publishing 階段 journal 的 fixture 構造。** 現有 hooks 都無法留下 `phase: publishing` 的 journal──`CASH_INSTALL_FAIL_AFTER` 系列會進入 `except` 分支執行 `rollback` 與 `cleanup_journal`，崩潰型 hooks 則都在 `phase: committed` 寫入之後才離開 process。因此測試 fixture SHALL 直接構造該狀態：以 `0600` 手工寫入 schema v2 的 journal（`version` 為 `2`、`phase` 為 `publishing`、`published` 為已發布筆數、`operations` 內每筆 write 記錄其 `before` 的存在旗標、base64 內容與 mode），並同步把對應 managed paths 置為半發布 bytes。本變更不新增 mid-publication 崩潰 hook，避免與「零引用 hook 應移除」的收斂方向相互拉扯。

**替代方案（不採用）**：持鎖不放，就地重算 source/target 快照與全部 plan。這等同於把整段 preflight 再寫一次，且必須同步重算 receipt 分類、conflict 判定、config 與 guidance 規劃；重新進入以既有程式路徑達成同一結果，重複面積小得多。

**替代方案（不採用）**：在不持鎖的情況下執行 recovery。recovery 會寫入 target，必須在 exclusive lock 之下進行；把偵測提前是安全的（純讀取），把**恢復**提前到持鎖之前則會與並發 installer 競爭。因此前置階段的順序是「偵測（不持鎖）→ 取得 lock → 恢復 → 釋放 → 重新進入」。

`--dry-run` 維持不執行 recovery，因此維持零寫入。但修好 A2 之後，同一個殘留 journal 會使 dry-run 與真實執行的結論分歧：dry-run 看到的是半發布狀態，`validate_installed_receipt` 會把那些 path 收進 conflicts 而回報 `conflict`；真實執行則會恢復並回報 `update`。修正前兩者同向（都失敗），修正後不再同向，因此 dry-run 對這個情境不再具有預測性。此分歧刻意保留──讓 dry-run 執行 recovery 會破壞零寫入契約──但它必須是被規範且可稽核的，而非未定義：dry-run 遇到未完成的 journal 時 SHALL 維持零寫入、SHALL NOT 執行 recovery，並 SHALL 在 diagnostic 明確指出存在未完成的 journal，使操作者知道真實執行會先恢復。該 diagnostic 的發出點就是本節第 1 步的 journal 偵測，位於 conflict 判定之前，因此它在 dry-run 回報 `conflict`、`newer`、`current` 或 `update` 時一律出現，不因分類提早返回而消失。

### D3：fault-injection hooks 的治理與收斂

四項調整：

1. **單一開關**：所有 `CASH_INSTALL_*` fault-injection hooks 只在環境變數 `CASH_INSTALL_TEST_HOOKS` 的值恰為 `1` 時被讀取。開關關閉時，installer 完全不查詢其餘 hook 變數，其存在與否不影響任何行為。

   這個開關**不是授權邊界**──能設定 `CASH_INSTALL_HOLD_FILE` 的呼叫端一律也能設定開關。它的作用是把 hooks 從「預設可達」變成「預設不可達」，縮小意外觸發的 blast radius。本次真正收斂邊界的是第 2、3 點的 identity 與解析約束。
2. **hold 協定的 identity 約束**：`wait_for_test_hold` 目前以會跟隨 symlink 且會截斷既有檔案的方式寫入就緒檔，且對解除等待的 release 檔只做 `exists()` 探測──該探測會跟隨 symlink、對 dangling symlink 回傳偽、也不驗證檔案型別或建立者。改為：hold 路徑要求為絕對路徑、其 parent 為既存且非 symlink 的目錄；兩個 hook 同時啟用時其 hold 路徑必須互異；ready 檔以 exclusive、no-follow 的建立語意產生；release 檔在 hold 開始前必須不存在，出現後必須是非 symlink 的 regular file。既有檔案或 symlink 皆 fail closed。

   release 檔的「尚不存在」判定必須做兩次。preflight 與真正的 hold 開始之間隔著整段分類與發布——publication hold 更是隔了 launcher 發布與 transaction 組裝——只在 preflight 檢查一次的話，這段窗內出現的 release 檔不會被任何檢查看到，`wait_for_test_hold` 會立刻視為已解除，hold 靜默退化成 no-op 而沒有任何診斷，正是本點要關掉的失敗模式。因此 preflight 驗證設定形狀與當下的不存在性，各 hook 在自己的等待點進入時（免除規則未生效的那一次）再驗證一次；此時已存在 release 檔 SHALL 以 execution error 中止，SHALL NOT 被當成解除訊號。

   此處刻意不要求路徑位於 target 之內：hold 檔屬於呼叫端的協調通道，其正當位置在呼叫端自有的暫存目錄，強制收進 target 會把協調狀態寫進被安裝的專案。既有測試正是把 hold 檔放在獨立暫存目錄，套用 target containment 會使它們全數 fail closed。
3. **hook 設定的驗證時機與重入語意**：兩個 hold hook 的等待點都在首次 target write 之後──`acquire_lock` 對 fresh target 會先以 `O_CREAT|O_EXCL` 建立 workspace lock，publication hold 更在 launcher 發布之後。因此 hook 設定（開關、hold 路徑形狀、失敗注入序號）SHALL 在 `acquire_lock` 之前的 preflight 一次驗證完畢，使不合法設定在任何 target write 前就 fail closed；等待點本身維持原位。

   另外，hold 的等待點位於 `install_target` 的可重入區段內，而 D2 又新增第五個重新進入來源。既有四個重新進入點中兩個為 pre-lock、兩個為 post-lock；D2 新增的恢復重新進入位於主流程取鎖之前，結構上屬 pre-lock，因此它本身不需要 at-most-once 免除（該次重新進入時 hold 尚未等待過、ready 檔也還沒建立）。需要免除的是兩個既有 post-lock 來源與 `--all` batch 迴圈；`--all` batch 迴圈也會對每個已註冊 target 各呼叫一次 `install_target`。若不定義重入語意，改成 exclusive 建立之後，第二次進入會因自己上一輪留下的 ready 檔而變成 execution error──把原本良性的重新分類與 batch 的第二個 target 都轉成失敗。因此每個 hold hook 在單一 process 內 SHALL 至多等待一次；已等待過之後，同一 process 內任何後續的 `install_target` 呼叫都 SHALL 完全跳過該 hook，包含其 preflight 的**全部** hold 檔存在性檢查。免除範圍必須同時涵蓋 ready 檔與 release 檔：release 檔由呼叫端建立且 `wait_for_test_hold` 從不刪除它，若只免除 ready 檔，batch 的第二個 target 會改在「release 檔在 hold 開始前不存在」這一關失敗，缺陷只是換了個運算元。路徑形狀檢查（絕對路徑、parent 非 symlink）不在免除範圍內，仍逐次執行。
4. **序號解析 fail-closed**：失敗注入序號的整數轉換以 `InstallerError` 包覆，非數字輸入成為明確的 execution error 而非未捕捉例外。

另刪除 commit 後崩潰用的 hook `CASH_INSTALL_CRASH_AFTER_COMMIT`：它在測試、規格與文件中皆為零引用。`recover_installer` 的 `phase == "committed"` 分支唯一的實質工作是 quarantine 清理，而該路徑由保留不動的 `CASH_INSTALL_CRASH_AFTER_QUARANTINE` 涵蓋；不含 legacy 移除的純 write transaction 在該分支只剩 journal 清除，沒有可回歸的行為。因此刪除不減少實質覆蓋。

### D4：進入點的四項機制調整

1. 以 `exec` 交棒給 interpreter，使 installer process 不再多一層 shell parent。
2. interpreter 候選清單由兩個泛用名稱擴充為「**泛用名稱在前，版本化名稱由新到舊在後**」。逐一以既有的版本探測驗證，第一個通過者勝出。系統預設 interpreter 版本過舊但已安裝合格版本化 interpreter 的環境因此可用。

   順序刻意是泛用優先而非版本化優先。版本化優先會改變**所有既有可用環境**的 interpreter 選擇：實測本 repo 主機上 `python3` 解析到 `mise` 管理的 3.13.0，而 `python3.14` 解析到 Homebrew 的 3.14.6──版本化優先會讓 installer 繞過開發者當前的 toolchain shim 改用 Homebrew。本次要解決的問題只是「泛用名稱不合格時沒有備援」，備援不應反過來奪走既有選擇。
3. 移除版本探測中從未被讀取的輸出變數，探測結果直接由條件式判定。
4. 交棒時停用 user site 目錄，使 installer 的 import 不受使用者層級自動載入程式碼影響。既有的 library 路徑注入與 cwd 隔離維持不變。

## Implementation Contract

### IC1 — mode 分派

- `run()` 中 `--target`、`--register`、`--unregister` 的分支條件 SHALL 為「不為 `None`」。空值守衛既已前移，抵達分派時這三個參數只可能是 `None` 或非空字串，因此此項與相容性判準同屬消除判準漂移的 defense-in-depth，無獨立可觀察後果；可觀察的驗收由空值守衛承擔。
- `run()` SHALL 在解析參數之後、且在 `read_registry()` 與 `--dry-run`／`--force` 相容性檢查兩者之前，對這三個帶值 mode 參數各自完成空值拒絕。
- 空值拒絕 SHALL 以 `InstallerError` 且 `exit_code=2` 失敗；`install_target` 的 `target must be a safe existing directory` 與 `canonical_target` 的 `project path is invalid` 兩個既有守衛的退出碼 SHALL NOT 被改動。
- 空字串 mode 參數 SHALL NOT 讀取 registry，SHALL NOT 對任何 registry 成員呼叫 `install_target`；即使 registry 或 HOME 本身不合法，diagnostic SHALL 指出 mode 參數值無效而非 registry／HOME 錯誤。
- `--dry-run` 與 `--force` 的相容性前置檢查 SHALL 只對帶值參數使用存在性判準，對 `--all`、`--self` 等 `store_true` 布林 flag SHALL 維持真值判斷；`--list --dry-run` 與 `--register <project> --force` SHALL 維持既有的 exit 2 失敗。

### IC2 — recovery 順序

- `install_target` SHALL 在 read-only preflight 內偵測 journal 是否存在，且該偵測 SHALL 早於版本比較的 `newer` early return；該偵測為純讀取，SHALL NOT 持鎖，也 SHALL NOT 解讀 target config。偵測 SHALL 以 no-follow 的 `lstat` 判定形狀：`JOURNAL_PATH` 非 regular file（含 symlink）時 SHALL 以 execution error fail closed，SHALL NOT 靜默視為「無 journal」——否則一個 dangling symlink 會讓偵測回報偽，未知 partial state 因而未 fail closed。
- 恢復 SHALL 緊接在 `newer` early return 之後，且 SHALL 早於全部三個提前返回的分類分支：`legacy receipt drift`、`receipt-less Cash skill inventory is partial` 與 `managed target drift`。未完成 journal 存在時 installer SHALL NOT 先以其中任何一個返回而略過恢復。
- 被分類為 `newer` 的 target SHALL 維持零寫入返回，SHALL NOT 執行 recovery；其 journal 由版本相符或更新的 installer 處理。
- `recover_installer` SHALL 回傳一個布林值，表示是否實際處理並清除了 journal；無 journal 時回傳偽，使 pre-lock 偵測結果在持鎖後被重新驗證。
- 非 dry-run、target 未分類為 `newer` 且偵測到 journal 時，`install_target` SHALL 依序：先執行既有的 `launcher exists without stable workspace lock` 檢查，再取得既存 stable lock，再呼叫 `recover_installer`。該次取鎖 SHALL NOT 建立不存在的 lock；lock 不存在時 SHALL fail closed，SHALL NOT 以 `O_CREAT|O_EXCL` 建立新 lock inode。
- `recover_installer` 的兩個回傳分支 SHALL 都關閉 lock descriptor：回傳真時關閉後重新進入 `install_target`（且 SHALL NOT 在該次重新進入重複輸出版本控制診斷），回傳偽時關閉後沿原流程繼續。同一 process 在任一時刻 SHALL 至多持有一個 stable lock descriptor。
- 同一份 journal SHALL NOT 觸發第二次由 recovery 引起的重新進入；重新進入前該 journal 已被清除，此性質由「journal 不存在時 `recover_installer` 回傳偽」保證，不需額外的 journal identity 追蹤。外部併發在該時間窗內產生的**新** journal 可再觸發一次重新進入，屬既有併發語意。
- crash 於 publishing 階段之後的第一次非 dry-run 執行 SHALL 在單次 invocation 內完成恢復，並得到與 recovery 後 target state 一致的分類；無併發 installer 介入、且 recovery 之後不存在與該 journal 無關的 drift 時，該分類 SHALL 為 `update` 且 SHALL NOT 為 `conflict`。半發布 bytes 落在 receipt-managed path 時亦 SHALL 如此，不得要求 `--force`。recovery 之後仍存在與該 journal 無關的 drift 時，`conflict` 是正確結果（見零寫入 carve-out 條款）。
- 該次執行 SHALL NOT 因 recovery 自身造成的 target 變更而以「installation inputs changed after lock acquisition」失敗；外部併發在取得 lock 之後修改 target 時，publication 前 revalidation 的既有 fail-closed 契約 SHALL 維持不變。
- version-control 排除設定的寫入計畫 SHALL 由 recovery 之後的 target 快照導出。
- 偵測到未完成 journal 時，installer SHALL 在早於 `newer` early return 的偵測點輸出一句與分類無關的通用 diagnostic（僅陳述 target 存在未完成的 journal）；該句 SHALL 在 dry-run 與 real run 皆出現，且 SHALL 與最終分類無關而一律出現，包含 `current` 與 `newer`。若只在 dry-run 輸出，操作者在 real run 會完全看不到 journal 的存在——那會使 real run 的資訊少於 dry-run。
- 分類為 `newer` 時，installer SHALL 於 `newer` early return 之前**另外**輸出一句 newer 專屬補充：該 journal 需要版本相符或更新的 installer 才會恢復。此句 SHALL NOT 併入通用句——通用句在偵測點發出，當時尚未做版本比較，把 newer 專屬語意寫進去會對絕大多數會被本次執行恢復的 target 給出錯誤指引。
- `--dry-run` SHALL NOT 執行 recovery 並 SHALL 維持零寫入。
- Journal recovery 造成的 rollback 寫入 SHALL NOT 被視為違反 `current`、`newer` 或 `conflict` 分類的零寫入契約；該零寫入契約自 recovery 完成後的重新分類起適用。recovery 之後若仍存在與該 journal 無關的 drift，installer SHALL 回報 `conflict`、exit 2，且自重新分類起零寫入。

### IC3 — hooks 治理

- 環境變數 `CASH_INSTALL_TEST_HOOKS` 的值不為 `1` 時，installer SHALL NOT 讀取任何其他 `CASH_INSTALL_*` 變數，且行為 SHALL 與這些變數不存在時完全相同。
- 全部已啟用 hook 的設定驗證（hold 路徑形狀、兩個 hold 路徑互異、release 檔當下不存在、失敗注入序號可解析性）SHALL 在**任何** `acquire_lock` 呼叫之前的 read-only preflight 完成——包含 D2 新增的恢復前置階段所使用的那次取鎖——使這些設定錯誤在任何 target write 之前 fail closed；hold 的等待點 SHALL 維持在既有位置。
- 有一類形狀在 preflight 無法判定：release 檔在 preflight 之後、等待點進入之前才出現，或到等待點才被換成 symlink。這類 SHALL 在該 hook 的等待點以 execution error 中止，SHALL NOT 被當成解除訊號，且 SHALL NOT 提交任何 transaction operation；因為等待點在 `acquire_lock` 之後，這類 SHALL NOT 主張「首次 target write 之前」失敗——兩類的驗收條件必須分開陳述，否則後者的 THEN 在 fresh target 上不可能成立。
- `wait_for_test_hold` SHALL 拒絕非絕對路徑、parent 不存在或 parent 為 symlink 的 hold 路徑，SHALL 以 exclusive 且 no-follow 的語意建立 ready 檔，並 SHALL NOT 覆寫既有檔案或跟隨 symlink。
- at-most-once 的記帳鍵 SHALL 為 hook 本身而非 hold 路徑。`CASH_INSTALL_HOLD_FILE` 與 `CASH_INSTALL_PUBLICATION_HOLD_FILE` 是兩個獨立的 hook，各自記帳互不影響。
- 兩個 hook 同時啟用時，其 hold 路徑 SHALL 互異；相同時 SHALL 在 preflight 以 execution error fail closed。記帳互相獨立並不能讓兩個 hook 共用一條路徑：第一個 hook 已 exclusive 建立 `<path>.ready` 且呼叫端已建立 `<path>.release`，第二個 hook 進入等待點時必然同時撞上「ready 檔已存在」與「release 檔在等待點已存在」兩條 fail-closed 規則。與其讓它在等待點才炸，不如在 preflight 就把這個 caller 設定錯誤擋掉。
- release 檔的不存在性 SHALL 在 preflight 與各 hook 自己的等待點進入時各驗證一次；等待點進入時已存在 SHALL 以 execution error 中止，SHALL NOT 被當成解除訊號。release 檔 SHALL 只在其為非 symlink 的 regular file 時被視為解除訊號。
- 每個 hold hook 在單一 process 內 SHALL 至多等待一次。該 hook 已等待過之後，同一 process 內任何後續的 `install_target` 呼叫──包含重新分類造成的重新進入，以及 `--all` batch 迴圈的後續 target──SHALL 完全跳過該 hook，包含其等待與 preflight 的全部 hold 檔存在性檢查（ready 檔與 release 檔皆在免除範圍內），SHALL NOT 因本 process 前一輪建立或解除的 hold 檔而失敗。路徑形狀檢查 SHALL NOT 被免除。
- 失敗注入序號無法解析為整數時 SHALL 以 `InstallerError` 失敗。
- `CASH_INSTALL_CRASH_AFTER_COMMIT` SHALL 自實作中移除，且 SHALL NOT 在實作、測試或使用者文件中作為可生效的 environment variable name 被讀取或設定；本 Implementation Contract、delta spec 與 change artifacts 對該名稱的敘述性引用不在此限。`CASH_INSTALL_CRASH_AFTER_QUARANTINE` SHALL 保留並僅受開關約束。

### IC4 — 進入點

- 進入點 SHALL 以 `exec` 交棒給選定的 interpreter。
- interpreter 候選清單 SHALL 依序為 `python3`、`python`、`python3.14`、`python3.13`、`python3.12`、`python3.11`，並對每個候選套用既有的最低版本探測；泛用名稱 SHALL 排在版本化名稱之前，使既有可用環境的選擇結果不改變。
- 進入點 SHALL NOT 保留未被讀取的變數。
- 交棒 SHALL 停用 user site 目錄，並 SHALL 維持既有的 library 路徑注入與 cwd 隔離。

### IC5 — 測試與版本

- `scripts/cash-skills/tests/test_installer_runtime.py` SHALL 新增覆蓋，且與新增 scenario 一一對應：
  - IC1：`--target`、`--register`、`--unregister` 三個空字串各自以 exit 2 fail closed、未讀取 registry、未觸及任何 registry 成員；以刻意不合法的 registry 驗證空字串的 diagnostic 優先於 registry／HOME 錯誤；三個空字串各自配合 `--dry-run` 與配合 `--force` 時 diagnostic 皆指出值無效而非缺少 mode 參數；`--list --dry-run` 與 `--register <project> --force` 維持 exit 2。
  - IC2：半發布 bytes 落在 receipt-managed path 的 publishing 階段 journal，於單次執行內完成恢復並回報 `update` 而非 `conflict`，且不需 `--force`；帶 publishing journal 的 receipt-less（無 receipt、1–23 個 skill 已發布）與 legacy（legacy receipt 尚未替換）target 皆先完成 recovery 再重新分類，不以 `receipt-less Cash skill inventory is partial` 或 `legacy receipt drift` 提前返回；journal schema version 不被本 bundle 辨識、以及 `JOURNAL_PATH` 為 symlink 時各自 fail closed；版控排除設定計畫取自 recovery 之後；帶 journal 的 newer target 維持零寫入回報 `newer` 且不執行 recovery；journal 存在而 stable lock 不存在時 fail closed 且不建立新 lock inode；`--dry-run` 遇未完成 journal 時零寫入、不恢復，且 diagnostic 在 `newer` early return 之前發出因而與最終分類無關地出現。
  - IC3：開關關閉時全部 hook 變數無效且不產生 ready 檔；preflight 可判定的六種形狀（hold 路徑為 relative path、parent 不存在、parent 為 symlink、ready 檔已存在、release 檔在 preflight 已存在、兩個 hook 的 hold path 相同）各自在任何 target write 前 fail closed；等待點才可判定的三種形狀（ready 檔於等待點前才出現、release 檔於等待點前才出現、該後出現的 release 檔為 symlink）各自在等待點以 execution error 中止且不提交任何 transaction operation；兩個 hook 各自記帳，`CASH_INSTALL_HOLD_FILE` 已等待過不影響 `CASH_INSTALL_PUBLICATION_HOLD_FILE` 是否等待；重新進入與 batch 後續 target 皆完全跳過該 hook（含 ready 檔與 release 檔的存在性檢查）而不失敗，且路徑形狀檢查仍逐次執行；失敗注入序號非整數時 fail closed。
  - IC4：泛用名稱不合格而版本化名稱合格時仍完成 invocation；泛用名稱合格時選擇結果與變更前一致；候選全數不合格時 fail closed 且零寫入；交棒後無由進入點建立的 shell parent（以 hold hook 持住 installer 期間檢查該 pid 之下不存在子行程來觀察）；user site 目錄已停用而 library 路徑注入仍生效。
- 既有使用 fault-injection hooks 的**六個**測試 SHALL 一併設定 hooks 開關。它們分屬三條注入路徑，SHALL 逐一處理，不得只涵蓋其中一部分：(a) 兩個經 `install` helper 既有的 `TEST_` 前綴轉譯層；(b) 兩個把真名寫進 `os.environ` 再經 `install_from` 繼承；(c) 兩個自行組 `environment` dict 交給 `subprocess.Popen`。(a) 的兩個測試若被漏掉，開關導入後其注入變數不再被讀取，安裝會成功而使 rollback 斷言靜默失效。`install`、`install_from` 兩個實際承載 hook 注入的 helper，以及目前無 hook 測試使用但同屬安裝入口的 `run_installer`，SHALL 統一改由 per-call 的 env 參數注入並先剝除全部 `CASH_INSTALL_*`（含新開關），`TEST_` 轉譯清單 SHALL 一併涵蓋新開關。helper 數與注入路徑數不對應：(c) 是測試自建 `environment` 交給 `subprocess.Popen`，與 `run_installer` 無關，SHALL 在該兩個測試各自處理；SHALL NOT 把 `CASH_INSTALL_*` 真名寫入 parent process 的 `os.environ`，否則同一測試期間所有子行程都會繼承而使「開關關閉」的測試失去意義。
- `cash-skills.version` SHALL 嚴格遞增；`scripts/cash-skills/tests/skill-checks.fish` 以字面值釘住當前 bundle version，SHALL 一併更新，否則版本調升與「合約測試套件全數通過」互相矛盾。
- `.cash-skills/lib/cash_cli/` 底下（**含子目錄**，即 `library.rglob("*.py")` 排除 `__pycache__` 後的結果，現為 19 個）的 `.py` 檔數 SHALL 維持不變，使既有以硬編序號注入失敗的測試仍落在原本階段。非遞迴清點只會數到 9 個而漏掉 `commands/` 下的 10 個，是無效的判準。

## Risks / Trade-offs

- **重新進入語意的擴散**：D2 新增第五個重新進入來源，位於主流程取鎖之前。既有四個來源由外部併發觸發而無深度上界，本次新增的來源對同一份 journal 上界為一層。整體遞迴無上限仍是既有性質，已列為 Non-Goal，本變更不使其惡化。
- **釋放 lock 造成的時間窗**：recovery 之後釋放 lock 再重新取得，期間另一個 installer 可能取得 lock 並先完成安裝，該情形下本次執行會在重新進入後把 target 分類為 `current` 或 `newer`；它也可能崩潰並留下一份新 journal，使重新進入再發生一次。兩者都屬既有重新分類語意涵蓋範圍，不產生不一致寫入。
- **dry-run 對殘留 journal 失去預測性**：修正後真實執行會恢復並成功，dry-run 則維持零寫入而回報 conflict，兩者結論不再同向。此取捨已在 D2 明確規範並要求 dry-run 輸出指出未完成的 journal，使操作者能據以判斷；讓 dry-run 執行 recovery 會破壞零寫入契約，因此不採用。
- **hooks 開關是行為變更**：任何外部依賴既有 `CASH_INSTALL_*` 變數的流程都會靜默失效。目前這些變數的唯一使用者是本專案的 installer runtime 測試，且該檔案在本變更範圍內一併更新。
- **序號式失敗注入的脆弱性**：既有測試以硬編序號注入失敗，其有效性綁定於 replaceable runtime `.py` 檔數（該數決定 transaction operation 的序列位置）。本變更不新增 transaction operation，也不得在 `.cash-skills/lib/cash_cli/` 新增模組檔案——新增一個 runtime record 就會新增一個 operation 並位移該序號，使既有的 rollback 測試仍然通過卻不再落在原本階段。tasks 已把「runtime `.py` 檔數不變」列為驗收條件。未來刻意新增 operation 時仍須同步重新校準該序號，屬既有已知風險。
- **interpreter 候選清單的維護成本**：版本化名稱清單需隨新版本擴充。清單以泛用名稱開頭，因此未列出的新版本只要是系統預設 interpreter 就仍會被選中，落差只影響「系統預設過舊且只安裝了未列出版本」的組合。
