# Propose Plus Review — Round 5

## Reviewer Findings

### Critical

None.

### Warning

- severity: Warning
  confidence: 85
  location: `design.md` `### Guard repair-all with source-sensitive dirty detection`; `tasks.md` `2.5`; `scripts/spectra-plus/repair-all.fish`
  summary: `scripts/spectra-plus/**` 是 source-sensitive path，但 LaunchAgent 實際先執行 `scripts/spectra-plus/repair-all.fish`；若 entrypoint 本身是 parseable WIP，installer 內的 dirty guard 只能在 entrypoint 成功 hand off 後保護流程。
  recommendation: 明確要求 `repair-all.fish` 在呼叫 `install-spectra-plus.fish --repair-all` 前不得做非必要 preflight 或 target/lock/throttle/registry side effect；補 parseable dirty `repair-all.fish` fixture。若 broken-syntax entrypoint 不保證，明列為 Non-Goal。
  reviewer: B

### Suggestion

None.

## Rating

Critical count: 0
Warning count: 1
critical_gap: false

Round 5 判定為 `next_round`，因為 parseable dirty entrypoint 是 LaunchAgent 實際入口的可靠性缺口；若 entrypoint 在 handoff 前執行任何 side effect，就可能繞過或削弱 installer dirty guard。此 finding 已用 thin-wrapper contract、scenario、task 修正。

## Fix Actions

- 修改 `design.md`：新增 `repair-all.fish` thin handoff wrapper contract，要求 handoff 前不得 registry read、lock/throttle、target current-state check、或非必要 dependency preflight；明列 broken-syntax entrypoint 為 Non-Goal。
- 修改 `specs/spectra-plus-skills/spec.md`：新增 parseable dirty `repair-all.fish` entrypoint scenario，要求仍 hand off 到 dirty-source skip，且不讀 registry、不建立 lock、不寫 throttle、不修改 target。
- 修改 `tasks.md`：補 parseable dirty entrypoint fixture，並更新 LaunchAgent entrypoint ordering task。
- 重新執行 `spectra validate guard-dirty-source-auto-repair`，結果通過。

## Decision

next_round
