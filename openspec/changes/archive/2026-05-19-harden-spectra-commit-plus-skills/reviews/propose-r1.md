# Propose Plus Review — Round 1

## Reviewer Findings

### Critical

無。

### Warning

- `openspec/changes/harden-spectra-commit-plus-skills/specs/spectra-plus-skills/spec.md` 的 `Requirement: plus installer updates spectra-commit guard` 原本缺少「未加 guard 的 target 被更新」與「target skill shape 無法安全 patch 時失敗」scenario，installer 行為契約不完整。
- `openspec/changes/harden-spectra-commit-plus-skills/specs/spectra-plus-skills/spec.md` 原本只覆蓋 `.agents/skills/spectra-commit/SKILL.md` 缺失，未覆蓋 `.claude/skills/spectra-commit/SKILL.md` 缺失。
- `openspec/changes/harden-spectra-commit-plus-skills/tasks.md` 原本將重疊修改同一批 `spectra-commit` skill files 的 tasks 標為 `[P]`，不符合 parallel task 條件。
- `openspec/changes/harden-spectra-commit-plus-skills/proposal.md` 原本把 `openspec/specs/spectra-plus-skills/spec.md` 列為直接 modified，與 active change 只新增 delta spec、archive/sync 後才更新 master spec 的流程不一致。

### Suggestion

- `openspec/changes/harden-spectra-commit-plus-skills/specs/spectra-plus-skills/spec.md` 與 `openspec/changes/harden-spectra-commit-plus-skills/design.md` 需要釐清 tracked source files 來自 pre-archive confirmed commit set，archive-first 只額外加入 archive/spec-sync allowlist 變更。
- `.agents/skills/spectra-commit/SKILL.md` 與 `.claude/skills/spectra-commit/SKILL.md` 的後續實作應統一 archive path 文案為 `openspec/changes/archive/<date>-<change>/`，避免保留舊 `openspec/archived/`。
- `install-spectra-plus.fish` 的後續實作應驗證 idempotency，避免重跑 installer 重複插入 guard block。

## Rating

quality_score: 9.4

critical_gap: false

rationale: artifacts 已一致修正 reviewer 的 Warning：proposal scope 控制合理且不再把 master spec 列為直接 modified；design 明確說明 pre-archive confirmed commit set、current archive path、installer idempotency，並清楚回答不新增 `spectra-commit-plus` 的取捨；spec 補上 installer unguarded target、unsupported shape、missing Claude commit skill、archive path 等 scenario；tasks 也覆蓋 archive path、idempotency、unsupported shape、dry-run、missing skill 與內容檢查測試。整體可實作、測試面完整、scope 聚焦既有 `$spectra-commit` 與 installer guard，且 `spectra validate harden-spectra-commit-plus-skills` 通過；僅有 tasks 未使用 `[P]` 在 `parallel_tasks: true` 下略保守，但不構成 critical gap，已達 pass condition。

## Fix Actions

- 修改 `openspec/changes/harden-spectra-commit-plus-skills/proposal.md`，移除 `openspec/specs/spectra-plus-skills/spec.md` direct modified impact，避免 scope 與 Spectra sync/archive 流程不一致。
- 修改 `openspec/changes/harden-spectra-commit-plus-skills/design.md`，補充 tracked source files 來自 pre-archive confirmed commit set、archive path 必須使用 `openspec/changes/archive/<date>-<change>/`、installer 必須 idempotent。
- 修改 `openspec/changes/harden-spectra-commit-plus-skills/specs/spectra-plus-skills/spec.md`，新增 installer updates unguarded target、unsupported commit skill shape failure、missing Claude commit skill failure、archive path wording 等 scenarios，並釐清 source file collection 來源。
- 修改 `openspec/changes/harden-spectra-commit-plus-skills/tasks.md`，移除錯誤 `[P]` 標記，新增 archive path、unsupported shape failure、idempotency 驗證任務。
- 重新執行 `spectra validate harden-spectra-commit-plus-skills`，結果通過。

## Decision

passed
