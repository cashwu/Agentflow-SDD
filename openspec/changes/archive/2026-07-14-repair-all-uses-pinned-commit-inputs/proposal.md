## Why

目前的 `--repair-all` 會在 source checkout 的 source-sensitive 路徑有任何未提交變更時跳過全部 registered target。source checkout 本身又是被修復的 target，外部工具覆寫其 skills 後會同時製造 dirty 狀態與修復需求，使排程持續輸出 `[skipped] dirty source checkout`，但永遠不修復缺失的 plus skills。

## What Changes

- `--repair-all` 不再以 source checkout 是否 dirty 決定是否執行，並移除既有 dirty-source blocking guard。
- 每次 repair-all 執行只解析一次 source checkout 的 `HEAD` commit，從該 commit 具現化產生 target 內容所需的共用輸入，並從該 pinned snapshot 執行 current-state 檢查與 per-target installation。
- repair-all 父行程不使用工作區版本的 metadata 或內容斷言判定 target 是否 current；snapshot entrypoint 以三態結果明確區分 current、stale 與無法判定。
- snapshot 解析、建立、讀取或 metadata 驗證失敗時，在處理 target 前大聲失敗；單一 target 的 current-state 檢查失敗時，回報該 target 失敗且不把執行錯誤視為 stale。
- 新增回歸測試，直接證明 dirty source 下仍能修復缺失輸出，且第二次執行會收斂為 already current。

## Non-Goals

- 不修改 repair lock 的 stale 判定、ownership、回收或並行控制。
- 不新增未提交變更的 advisory、路徑分組或說明訊息。
- 不新增 rebase、bisect、merge、cherry-pick 或 revert 的特殊 gate。
- 不修復 target 缺失或無效的 base skills。
- 不還原、備份或清理 source checkout 的工作區。
- 不改變直接執行 `--target` 的行為。

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `spectra-plus-skills`: repair-all 改用 pinned commit 的共用輸入執行修復，並移除會因 dirty source checkout 跳過全部 target 的既有行為。

## Impact

- Affected specs: `spectra-plus-skills`
- Affected code:
  - Modified: `install-spectra-plus.fish`
  - Modified: `scripts/spectra-plus/tests/repair-all-checks.fish`
  - Modified: `SPECTRA-PLUS.md`
  - New: none
  - Removed: none
