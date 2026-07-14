---
id: task-verification-coverage-incomplete
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-14
last_seen: 2026-07-14
links:
  - openspec/changes/repair-all-uses-pinned-commit-inputs/reviews/apply-r1.md
---

# Task verification coverage incomplete

A task is marked complete after testing the primary outcome but omits one or more verification branches explicitly named in the task or implementation contract, leaving the completion claim stronger than the regression evidence.

## Occurrences

- 2026-07-14 — repair-all-uses-pinned-commit-inputs — spectra-apply-plus round 1 — current-state error tests initially omitted fail-and-continue across targets and the required dry-run error/no-state branch even though both were explicit verification targets.
