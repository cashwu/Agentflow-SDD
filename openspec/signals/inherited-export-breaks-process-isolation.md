---
id: inherited-export-breaks-process-isolation
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-14
last_seen: 2026-07-14
links:
  - openspec/changes/repair-all-uses-pinned-commit-inputs/reviews/apply-r2.md
---

# Inherited export breaks process isolation

A process-global ownership or coordination variable is assigned without explicitly clearing an inherited export attribute, so hostile or accidental environment state can leak parent-owned resource identifiers into child processes.

## Occurrences

- 2026-07-14 — repair-all-uses-pinned-commit-inputs — spectra-apply-plus round 2 — Fish `set -g` preserved an inherited exported snapshot ownership variable until assignments were changed to explicit `--unexport`.
