---
id: declared-scope-implementation-drift
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-07
last_seen: 2026-07-07
links:
  - openspec/changes/add-review-loop-discipline/reviews/apply-r2.md
---

# Declared scope implementation drift

An implementation changes a file or behavior that is technically necessary, but the proposal, design, or tasks do not declare that file or behavior as in scope, leaving review and grader-protection rules with an inaccurate source of truth.

## Occurrences

- 2026-07-07 — add-review-loop-discipline — spectra-apply-plus round 2 — Round 1 modified `scripts/spectra-plus/rules.yaml` to narrow Codex slash-command substitution, but proposal Impact, design scope, and tasks did not declare that rules change until Round 2 backfilled the artifacts.
