# Apply Plus Review — Round 2

## Reviewer Findings

### Critical

None.

### Warning

- severity: Warning
  confidence: 95
  location: install-spectra-plus.fish:497-522
  summary: LaunchAgent plist 直接插入 path 字串，未做 XML escaping，repo/HOME/fish path 含 `&`、`<`、`>` 時會產生無效 plist 或被注入額外 XML。
  recommendation: 對所有寫入 `<string>` 的動態值先做 plist/XML escaping，或改用 `/usr/libexec/PlistBuddy`/`plutil` 這類結構化 plist 寫入方式。
  reviewer: B

- severity: Warning
  confidence: 90
  location: scripts/spectra-plus/tests/repair-all-checks.fish:173-182; openspec/changes/auto-repair-spectra-plus-skills/specs/spectra-plus-skills/spec.md:71-85
  summary: unregistered project 邊界測試只檢查一個 plus skill 檔案仍缺失，未驗證 unregistered target 的 commit guard 或其他 skill files 未被修改。
  recommendation: 在 repair-all 前後記錄 unregistered target 的 commit guard checksum，並確認所有 plus output/guard 狀態保持不變。
  reviewer: B

### Suggestion

None.

## Rating

quality_score: 8.0
critical_gap: false

兩個 finding 都是高信心且需要修正的 Warning：plist XML escaping 屬於實際可靠性與注入風險，測試邊界不足則降低變更保護力；但目前未指出核心功能失效、資料毀損或無法交付的 Critical/Blocker，因此不構成 critical gap。

## Fix Actions

- 修改 `install-spectra-plus.fish`：新增 `plist_escape`，對寫入 LaunchAgent plist `<string>` 的 `Label`、`fish` path、entrypoint path 與 log path 做 XML escaping。
- 修改 `scripts/spectra-plus/tests/repair-all-checks.fish`：LaunchAgent fixture 使用含 `&` 的 temporary HOME，驗證 plist 內路徑輸出為 escaped `&amp;`。
- 修改 `scripts/spectra-plus/tests/repair-all-checks.fish`：unregistered target 測試在 repair-all 前後比對 `.agents` / `.claude` 的 `spectra-commit` checksum，並確認四個 plus output 都仍不存在。
- 重新執行 `fish scripts/spectra-plus/tests/repair-all-checks.fish`、`fish scripts/spectra-plus/tests/installer-commit-guard-checks.fish`、`fish scripts/spectra-plus/tests/generator-checks.fish`、`fish -n install-spectra-plus.fish scripts/spectra-plus/repair-all.fish scripts/spectra-plus/tests/repair-all-checks.fish`、`spectra validate auto-repair-spectra-plus-skills`，全部通過。

## Decision

next_round
