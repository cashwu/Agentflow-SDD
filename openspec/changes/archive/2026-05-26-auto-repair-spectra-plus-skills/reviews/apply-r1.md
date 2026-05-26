# Apply Plus Review — Round 1

## Reviewer Findings

### Critical

- severity: Critical
  confidence: 100
  location: install-spectra-plus.fish:340-347,413-415
  summary: repair-all 的 skipped 判斷只檢查 plus 檔案存在與 guard marker，會把 guard 內容不完整或 plus skill 內容不符合 single-target validation 的 target 誤判為 already current，違反「reuse single-target installer validation」契約。
  recommendation: 讓 `target_is_current` 重用與 single-target installer 相同的驗證條件，至少完整驗證 `spectra-commit` guard 必要內容與 generated plus skill 必要 marker；驗證失敗時不得 skipped，必須執行修復。
  reviewer: A+B

### Warning

- severity: Warning
  confidence: 100
  location: openspec/changes/auto-repair-spectra-plus-skills/tasks.md:21; scripts/spectra-plus/tests/repair-all-checks.fish:237-251,262-295
  summary: tasks 要求驗證 throttle window 不大於 LaunchAgent StartInterval，但測試只檢查 plist 含 StartInterval 與 throttle 行為，未比較兩者數值。
  recommendation: 在 `repair-all-checks.fish` 解析 plist StartInterval，並與實作 throttle window 期望值比對，確保 throttle window <= StartInterval。
  reviewer: B

- severity: Warning
  confidence: 88
  location: install-spectra-plus.fish:501-504
  summary: uninstall LaunchAgent 會忽略 launchctl bootout 失敗並刪除 plist，可能在 unload 失敗時回報成功且留下已載入 agent。
  recommendation: 捕捉 bootout 狀態與 stderr，只忽略明確的「未載入/不存在」情境；其他 launchctl 失敗應非零退出並保留可執行的手動修復訊息。
  reviewer: B

### Suggestion

None.

## Rating

quality_score: 6
critical_gap: true

仍有一個高信心 Critical finding，核心問題是 repair-all 的 current 判斷未重用 single-target installer validation，可能跳過實際需要修復的 target，直接違反本 change 的主要契約；另有兩個 Warning 涉及測試覆蓋不足與 uninstall 失敗處理不可靠，因此目前品質未達可接受門檻。

## Fix Actions

- 修改 `install-spectra-plus.fish`：新增 `guard_is_current` 與 `plus_outputs_are_current`，讓 `target_is_current` 驗證完整 `spectra-commit` guard 內容與 plus skill 必要內容，避免 stale target 被誤判為 skipped。
- 修改 `scripts/spectra-plus/tests/repair-all-checks.fish`：解析 LaunchAgent plist 的 `StartInterval`，並確認固定 throttle window 不大於該值。
- 修改 `install-spectra-plus.fish` 與 `scripts/spectra-plus/tests/repair-all-checks.fish`：uninstall LaunchAgent 在 `launchctl bootout` 非預期失敗時回傳非零、保留 plist，並輸出 `manual cleanup` 指引；測試以 stub `launchctl` 覆蓋失敗路徑。
- 重新執行 `fish scripts/spectra-plus/tests/repair-all-checks.fish`、`fish scripts/spectra-plus/tests/installer-commit-guard-checks.fish`、`fish scripts/spectra-plus/tests/generator-checks.fish`、`fish -n install-spectra-plus.fish scripts/spectra-plus/repair-all.fish scripts/spectra-plus/tests/repair-all-checks.fish`、`spectra validate auto-repair-spectra-plus-skills`，全部通過。

## Decision

next_round
