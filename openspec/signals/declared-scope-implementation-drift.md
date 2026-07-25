---
id: declared-scope-implementation-drift
type: recurring-finding
status: open
occurrences: 4
first_seen: 2026-07-07
last_seen: 2026-07-25
links:
  - openspec/changes/add-review-loop-discipline/reviews/apply-r2.md
  - openspec/changes/tighten-review-loop-edge-cases/reviews/apply-r1.md
  - openspec/changes/fork-spectra-skills-to-cash/reviews/propose-r1.md
  - openspec/changes/align-cli-skill-contracts/reviews/propose-r1.md
---

# Declared scope implementation drift

An implementation changes a file or behavior that is technically necessary, but the proposal, design, or tasks do not declare that file or behavior as in scope, leaving review and grader-protection rules with an inaccurate source of truth.

## Occurrences

- 2026-07-07 — add-review-loop-discipline — spectra-apply-plus round 2 — Round 1 modified `scripts/spectra-plus/rules.yaml` to narrow Codex slash-command substitution, but proposal Impact, design scope, and tasks did not declare that rules change until Round 2 backfilled the artifacts.
- 2026-07-07 — tighten-review-loop-edge-cases — spectra-apply-plus round 1 — Implementation modified `openspec/specs/signals-shared-layer/spec.md`, but proposal Impact and tasks did not initially name that protected master spec path until Round 1 fix actions backfilled the structured delivery scope.
- 2026-07-18 — fork-spectra-skills-to-cash — spectra-propose-plus round 1 — cash ownership migration 必須更新 signals current-writer contract 與 README，但初稿未宣告 `signals-shared-layer` capability 或 `openspec/signals/README.md`；Round 1 才補齊 delta、Impact 與 tasks。
- 2026-07-25 — align-cli-skill-contracts — cash-propose round 1 — 走訪層剪枝所需的 workspace.walk_text_files 排除參數未宣告於 proposal 的 Impact，事後過濾的替代做法則使排除完全不縮小暴露面。
