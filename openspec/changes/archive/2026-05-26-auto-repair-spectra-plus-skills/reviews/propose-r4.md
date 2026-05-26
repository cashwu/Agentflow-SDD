# Propose Plus Review — Round 4

## Reviewer Findings

### Critical

無。

### Warning

- `severity`: Warning
  `confidence`: 90
  `location`: `openspec/changes/auto-repair-spectra-plus-skills/specs/spectra-plus-skills/spec.md:105-111`, `openspec/changes/auto-repair-spectra-plus-skills/design.md:52`, `openspec/changes/auto-repair-spectra-plus-skills/tasks.md:19-22`
  `summary`: LaunchAgent install 契約只要求寫入/更新 plist，沒有要求非 dry-run install 實際 `launchctl bootstrap/load` 或明確告知需下次登入/手動載入。
  `recommendation`: 補上 install 後的啟用語意，要求非 dry-run install 載入/刷新 agent，並用 stub `launchctl` 測試；載入失敗時輸出 manual activation instruction。
  Reviewer: B

- `severity`: Warning
  `confidence`: 85
  `location`: `openspec/changes/auto-repair-spectra-plus-skills/design.md:39`, `openspec/changes/auto-repair-spectra-plus-skills/design.md:43`, `openspec/changes/auto-repair-spectra-plus-skills/design.md:62`, `openspec/changes/auto-repair-spectra-plus-skills/specs/spectra-plus-skills/spec.md:126-138`, `openspec/changes/auto-repair-spectra-plus-skills/tasks.md:21`
  `summary`: throttle 是 per-attempt 且未定義預設 window，可能讓實際修復延遲超過 `StartInterval` 的使用者預期。
  `recommendation`: 明確定義預設 throttle window 不大於 `StartInterval`，並補驗收條件。
  Reviewer: B

### Suggestion

無。

## Rating

`quality_score`: 8.0
`critical_gap`: false

Reviewer A 已無 findings，但 LaunchAgent 啟用語意與 throttle/interval 關係仍影響自動修復的可靠性與可測性，因此未達 pass bar。

## Fix Actions

- 修改 `openspec/changes/auto-repair-spectra-plus-skills/specs/spectra-plus-skills/spec.md`：`Install LaunchAgent` scenario 要求載入/刷新目前使用者 session，新增 `LaunchAgent activation failure` scenario，並要求 throttle window 不大於 `StartInterval` 除非使用者明確設定較大值。
- 修改 `openspec/changes/auto-repair-spectra-plus-skills/design.md`：明確非 dry-run `--install-launch-agent` 使用 `launchctl bootstrap gui/$UID <plist>` 或等價方式啟用 agent；載入失敗時非零 exit 並輸出 manual activation instruction；預設 throttle window 不大於 `StartInterval`。
- 修改 `openspec/changes/auto-repair-spectra-plus-skills/tasks.md`：補 stub `launchctl` activation 測試、activation failure 測試，以及預設 throttle window 不大於 plist `StartInterval` 的驗證。
- 重新執行 `spectra analyze auto-repair-spectra-plus-skills`：Coverage、Consistency、Gaps 皆 clean，僅剩 concrete example suggestions。
- 重新執行 `spectra validate auto-repair-spectra-plus-skills`：通過。

## Decision

next_round
