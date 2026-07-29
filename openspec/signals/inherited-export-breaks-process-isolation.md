---
id: inherited-export-breaks-process-isolation
type: recurring-finding
status: open
occurrences: 2
first_seen: 2026-07-14
last_seen: 2026-07-29
links:
  - openspec/changes/repair-all-uses-pinned-commit-inputs/reviews/apply-r2.md
  - openspec/changes/add-global-cash-shim/reviews/apply-r1.md
---

# Inherited export breaks process isolation

A process-global ownership or coordination variable is assigned without explicitly clearing an inherited export attribute, so hostile or accidental environment state can leak parent-owned resource identifiers into child processes.

## Occurrences

- 2026-07-14 — repair-all-uses-pinned-commit-inputs — spectra-apply-plus round 2 — Fish `set -g` preserved an inherited exported snapshot ownership variable until assignments were changed to explicit `--unexport`.
- 2026-07-29 — add-global-cash-shim — cash-apply round 1 — POSIX sh 對 inherited exported variable 重新賦值時保留 export attribute；shim 使用 `root`、`launcher`、`target` 等一般名稱後再 `exec`，會把內部值洩漏給 project launcher 或 installer，違反 C9。
