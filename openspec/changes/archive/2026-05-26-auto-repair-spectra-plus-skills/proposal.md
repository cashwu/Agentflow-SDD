## Why

開啟 `/Applications/Spectra.app` 後，Spectra 可能重新產生多個專案的 `.agents/skills/` 與 `.claude/skills/`，導致 `install-spectra-plus.fish` 安裝的 generated plus skills 與 `spectra-commit` guard 被 reset。現有 installer 只能修復單一 target，使用者需要一個可註冊多個專案並自動補回 derived artifacts 的機制。

## What Changes

- 新增多專案 target registry，讓使用者可以註冊、取消註冊需要維持 plus skills 的專案。
- 新增 repair-all 流程，依 registry 對所有 target 執行 idempotent 修復，補回 `spectra-propose-plus`、`spectra-apply-plus` 與 `spectra-commit` guard。
- 新增 macOS LaunchAgent 安裝/移除流程，讓 Spectra.app reset 多個專案後可以自動批次修復。
- 強化測試，覆蓋 registry 操作、repair-all 多 target、缺失 target 處理、LaunchAgent dry-run/idempotency。

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `spectra-plus-skills`: 增加多專案 registry、repair-all 與 LaunchAgent 自動修復需求。

## Impact

- Affected specs: `spectra-plus-skills`
- Affected code:
  - Modified: `install-spectra-plus.fish`
  - New: `scripts/spectra-plus/repair-all.fish`, `scripts/spectra-plus/tests/repair-all-checks.fish`
  - Removed: (none)
