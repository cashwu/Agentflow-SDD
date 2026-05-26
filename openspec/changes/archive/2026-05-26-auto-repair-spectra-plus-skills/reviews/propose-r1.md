# Propose Plus Review — Round 1

## Reviewer Findings

### Critical

無。

### Warning

- `severity`: Warning
  `confidence`: 100
  `location`: `openspec/changes/auto-repair-spectra-plus-skills/design.md:54`, `openspec/changes/auto-repair-spectra-plus-skills/specs/spectra-plus-skills/spec.md:51`, `openspec/changes/auto-repair-spectra-plus-skills/tasks.md:3-18`
  `summary`: `--dry-run` contract 覆蓋不足；design 要求 register/unregister/repair-all/install-launch-agent/uninstall-launch-agent 都不得寫檔或呼叫 `launchctl`，但 spec/tasks 只完整驗證 repair-all dry-run。
  `recommendation`: 在 spec/tasks 補上 registry 與 LaunchAgent dry-run scenarios/tasks，包含 registry/plist/target files 不變，以及 `launchctl` 不被呼叫。
  Reviewer: A+B

- `severity`: Warning
  `confidence`: 100
  `location`: `openspec/changes/auto-repair-spectra-plus-skills/design.md:33`, `openspec/changes/auto-repair-spectra-plus-skills/design.md:50`, `openspec/changes/auto-repair-spectra-plus-skills/specs/spectra-plus-skills/spec.md:43`, `openspec/changes/auto-repair-spectra-plus-skills/tasks.md:10`
  `summary`: repair-all per-target summary 覆蓋不足；design 要求 success、skipped、failed target 都要有 summary，但 spec/tasks 未完整驗收。
  `recommendation`: 在 `Repair all registered plus skill targets` requirement 增加 per-target summary scenario，tasks 補驗證三種 target 狀態與 exit code。
  Reviewer: A

- `severity`: Warning
  `confidence`: 85
  `location`: `openspec/changes/auto-repair-spectra-plus-skills/design.md:33`, `openspec/changes/auto-repair-spectra-plus-skills/design.md:43`, `openspec/changes/auto-repair-spectra-plus-skills/design.md:62`, `openspec/changes/auto-repair-spectra-plus-skills/specs/spectra-plus-skills/spec.md:74-78`
  `summary`: throttle 語意對持續失敗情境不夠明確；若只在整體成功時更新 throttle，invalid target 會讓 LaunchAgent 反覆觸碰 valid targets。
  `recommendation`: 明確定義 throttle 以 repair-all attempt 為單位更新，並加入 invalid target + repeated repair-all 的 throttle 測試。
  Reviewer: B

### Suggestion

- `severity`: Suggestion
  `confidence`: 100
  `location`: `.spectra.yaml:14`, `openspec/changes/auto-repair-spectra-plus-skills/tasks.md:1-23`
  `summary`: `.spectra.yaml` 設定 `parallel_tasks: true`，但 tasks 沒有 `[P]` 標記。
  `recommendation`: 對不同檔案且無相互依賴的任務加上 `[P]`。
  Reviewer: B

## Rating

`quality_score`: 7.0
`critical_gap`: false

三個 Warning 都是 artifact 可驗收契約不足，會讓後續實作與測試產生明顯漂移風險；沒有 Critical finding，但尚未達到 propose-plus pass bar。

## Fix Actions

- 修改 `openspec/changes/auto-repair-spectra-plus-skills/specs/spectra-plus-skills/spec.md`：新增 dry-run registry update、dry-run LaunchAgent update、per-target repair summary、failed repair attempt throttle scenarios。
- 修改 `openspec/changes/auto-repair-spectra-plus-skills/design.md`：將 throttle 定義改為 per-attempt，明確 success/skipped/failed summary 與 dry-run 不呼叫 `launchctl` 的驗證要求。
- 修改 `openspec/changes/auto-repair-spectra-plus-skills/tasks.md`：補 registry/LaunchAgent dry-run、per-target summary、invalid target throttle 測試任務，並加入 `[P]` 標記與 design decision heading cross-reference。
- 重新執行 `spectra analyze auto-repair-spectra-plus-skills`：Coverage、Consistency、Gaps 皆 clean，僅剩 concrete example suggestions。
- 重新執行 `spectra validate auto-repair-spectra-plus-skills`：通過。

## Decision

next_round
