## Context

`repair_all` 目前先檢查 source checkout 是否有 source-sensitive dirty path；只要其中一條路徑被修改、刪除、加入 index 或由外部工具覆寫，整次 repair-all 就以成功狀態跳過全部 registered target。source checkout 同時也是 registered target，因此外部工具改寫它的 skills 時，會同時建立修復需求與阻斷修復的條件。

dirty guard 的原始目的，是避免把未提交的 generator、rules、templates 或 commit-guard source 寫進其他專案。正確的邊界不是治理工作區，而是讓 repair-all 產生內容所使用的共用輸入直接來自單一 commit。

現有 repair lock、throttle、registry 與直接 `--target` 安裝行為均已存在。本 change 只替換 repair-all 的輸入來源與 current-state 判定來源。

## Goals / Non-Goals

**Goals:**

- dirty source checkout 不再阻擋任何 registered target 的 repair。
- 一次 repair-all 內，metadata、current-state 判定與 target installation 使用同一個 pinned `HEAD` commit 的共用輸入。
- current-state 檢查明確區分 current、stale 與執行錯誤。
- snapshot 建立或讀取失敗時，在寫入任何 target 前以非零狀態失敗。
- 正常結束與可處理的失敗路徑不留下本次執行建立的 snapshot。
- 第二次 repair-all 對前一次成功修復的 target 回報 already current。

**Non-Goals:**

- 不修改 repair lock 的 stale 門檻、回收條件、ownership 或並行語意。
- 不新增 dirty-path advisory、路徑分類或未提交變更說明。
- 不為 rebase、bisect、merge、cherry-pick 或 revert 新增 gate。
- 不 pin target-local base skills；generator 仍從各 target root 讀取它們。
- 不讓 repair-all 還原、備份或清理 source checkout 工作區。
- 不讓系統從壞掉的工作區 driver 或 entrypoint 自我 bootstrap。
- 不改變直接 `--target` 的安裝、驗證或 guard auto-restore 行為。
- 不新增 stale snapshot reaper；SIGKILL 後可能殘留的暫存目錄留給獨立 change 處理。

## Decisions

### 從單一 commit 具現化最小共用輸入

repair-all 以 `git -C <source-top> rev-parse --verify HEAD^{commit}` 解析一次 commit SHA，再以 `git archive` 將下列共用輸入解開至唯一的 `mktemp -d` snapshot：

- `install-spectra-plus.fish`
- `scripts/spectra-plus/generate.fish`
- `scripts/spectra-plus/rules.yaml`
- `scripts/spectra-plus/template/`
- `.claude/skills/spectra-commit/`
- `.agents/skills/spectra-commit/`

每個 git 呼叫都以 `git -C <source-top>` 錨定，不能依賴 LaunchAgent 的 working directory。archive 先寫到 snapshot 內的 tar 檔，實作必須分別檢查 `git archive` 與解壓縮命令的狀態，不能用只反映最後一個命令狀態的 pipeline 判斷成功。

這份清單只包含產生任一 target 內容時共用的 source 輸入。排程 driver 仍從工作區執行；target-local base skills 仍從 target root 讀取。選擇 `git archive` 而不是逐檔 `git show`，是為了保留目錄結構與 executable bit，並以一個 commit 建立一致 snapshot。

### 由 snapshot 同時判定 current state 與執行安裝

父行程不得使用工作區版本的 `rules.yaml`、`plus_outputs_are_current` 或 `guard_is_current` 判定 target。snapshot 中的 installer 新增內部介面 `--check-current <target>`：

- exit 0：target current。
- exit 10：target stale。
- 其他 exit status：無法判定；父行程將該 target 回報為 failed，且不得委派安裝。

`--check-current` 必須唯讀，不得修改 target、registry、lock、cache 或 throttle。stale target 由同一份 snapshot 的 `install-spectra-plus.fish --target <target>` 執行安裝。如此 current verdict 與實際寫入內容不會分別來自工作區和 commit。

三態介面也處理部署期間的版本落差：工作區父行程可能已包含新邏輯，但 pinned `HEAD` 尚未包含 `--check-current`。舊 entrypoint 的一般錯誤狀態不得被誤判為 stale。

### 移除 dirty-source guard 且不加入替代 gate

刪除 `source_dirty_paths`、`source_sensitive_path_matches`、`porcelain_entry_paths` 與 repair-all 的 dirty skip 分支。repair-all 不執行 `git status` 來決定是否修復，也不加入 rebase 或 bisect gate。

未提交的共用輸入不會進入 snapshot，因此不需要 blocking guard。未提交的 driver 或父 entrypoint 仍會影響本次執行，這是已知 bootstrap 邊界，不在本 change 內以另一個 skip 條件掩蓋。

### 將 snapshot 清理限定為本次執行擁有的路徑

snapshot 由 `mktemp -d` 建立，路徑以未 export 的 process-global 變數保存。fish exit event handler 只能在該變數有值時刪除該唯一 snapshot；變數不得 export，避免 snapshot 子行程繼承後刪除父行程資源。

正常與 dry-run 路徑亦顯式清理 snapshot 並清空變數。handler 只負責 snapshot，不取得、釋放或回收 repair lock。SIGKILL 無法執行 handler，殘留 snapshot 是明確接受的限制；本 change 不加入 reaper。

### 保留既有 lock、throttle 與 per-target failure 語意

一般 repair-all 在 snapshot 建立與 metadata 驗證成功後，沿用既有 lock acquisition、stale lock recovery、throttle 判定與 throttle state 寫入順序。除了把 current check 與 installer entrypoint 換成 snapshot 版本，不修改 lock 或 throttle helper。

單一 target 無效、current-state 無法判定或安裝失敗時，repair-all 回報該 target 失敗並繼續處理其餘 target，最後以非零狀態結束。snapshot 本身無法建立或驗證時，因所有 target 共用該輸入，整次執行在 target processing 前失敗。

## Implementation Contract

### Behavior

一般 repair-all 的可觀察順序為：

1. 從 source checkout 解析一個 `HEAD` commit。
2. 建立並具現化 pinned snapshot。
3. 從 snapshot 驗證 plus metadata。
4. 取得既有 repair lock，套用既有 throttle 決策並寫入既有 throttle state。
5. 對每個 registered target 執行 snapshot 的 `--check-current`。
6. current target 回報 `[skipped] ... already current`；stale target 由 snapshot installer 修復；無法判定或安裝失敗的 target 回報 `[failed]`。
7. 處理完所有 target 後清理 snapshot 與 lock，並依是否有 target 失敗回傳狀態。

`--repair-all --dry-run` 執行步驟 1 至 3，使用 snapshot 的 `--check-current` 列出 already current、would repair 或 failed，然後清理 snapshot。任何 current-state 檢查失敗時，dry-run 最後以非零狀態結束。dry-run 不委派安裝、不建立 lock，也不寫入 cache、throttle 或 registry。

### Interface / data shape

- 新增內部 CLI：`install-spectra-plus.fish --check-current <absolute-target-path>`。
- exit status 契約固定為 0=current、10=stale、其他=error。
- repair-all 繼續輸出既有的 `[success]`、`[skipped]`、`[failed]` per-target summary。
- 不新增 registry、cache、lock 或設定檔格式。

### Failure modes

- source checkout 不是 git work tree、`HEAD` 無法解析、snapshot 無法建立、archive 失敗、解壓縮失敗或 pinned metadata 無效：整次 repair-all 非零結束，不取得 lock、不寫 throttle、不處理 target，並清理已建立的 snapshot。
- `--check-current` 回傳 0 或 10 以外的狀態：該 target 回報 failed，不執行其 installation，繼續下一個 target，最後非零結束。
- snapshot installer 安裝失敗：沿用既有 per-target failure 語意並繼續下一個 target。
- snapshot 顯式清理失敗：回報清理失敗並以非零狀態結束；不得刪除非本次執行建立的路徑。
- SIGKILL 後的 snapshot 殘留不影響 lock 或後續 repair；本 change 不回收它。

### Acceptance criteria

- source checkout 的 installer、rules、template、guard source 或 spectra skill 有未提交變更時，缺失 plus output 的 registered target 仍被修復，輸出不包含 dirty-source skip。
- 工作區 `rules.yaml` 含無效 metadata、但 pinned commit 的 rules 有效時，repair-all 使用 pinned metadata成功修復 target。
- 工作區 current-state 斷言與 pinned commit 不同時，repair-all 的 verdict 仍由 snapshot 回答。
- target 修復成功後立即再執行一次 repair-all，第二次回報 already current，不再次安裝。
- pinned entrypoint 不支援 `--check-current` 或 current check 執行失敗時，target 回報 failed，且不被當成 stale 安裝。
- snapshot 建立、archive、解壓縮或 metadata 驗證失敗時，沒有 registered target 被修改，沒有 lock、throttle 或 snapshot 殘留。
- 直接 `--target` 的既有 installer 與 guard auto-restore 測試保持通過。
- `fish scripts/spectra-plus/tests/repair-all-checks.fish` 與 `fish scripts/spectra-plus/tests/installer-commit-guard-checks.fish` 全數通過。

### Scope boundaries

In scope：repair-all 的 pinned 共用輸入、三態 current-state 查詢、dirty guard 移除、snapshot lifecycle，以及相關測試與文件。

Out of scope：lock reclamation、ownership token、stale reaper、advisory、Git operation gates、base-skill recovery、source workspace mutation，以及直接 `--target` 行為變更。

## Risks / Trade-offs

- [工作區 driver 或 entrypoint 仍可能壞掉並停止 repair] → 明確保留 bootstrap 邊界；本 change 只保證產生 target 內容的共用輸入來自 commit。
- [`HEAD` 在 rebase 或 bisect 期間可能指向中間 commit] → 接受使用任何可解析 commit；下一輪會使用新的 `HEAD`，且本 change 不以新 gate 重建無界 skip。
- [SIGKILL 可能留下 snapshot] → snapshot 使用唯一名稱且不持有 lock；不影響後續 repair，回收機制另案處理。
- [工作區父行程與 pinned child 版本不同] → 三態 `--check-current` 將不支援或執行錯誤明確分類為 failure。
- [target-local base skill 無效使該 target 安裝失敗] → 沿用 per-target fail-and-continue；其他 registered target 仍可修復。
