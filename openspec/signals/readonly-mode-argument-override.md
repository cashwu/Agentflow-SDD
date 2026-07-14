---
id: readonly-mode-argument-override
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-14
last_seen: 2026-07-14
links:
  - openspec/changes/repair-all-uses-pinned-commit-inputs/reviews/apply-r1.md
---

# Read-only mode overridden by argument parsing

A read-only CLI mode shares permissive parsing with mutating modes, allowing extra or mixed arguments to replace the selected mode and perform writes instead of failing validation.

## Occurrences

- 2026-07-14 — repair-all-uses-pinned-commit-inputs — spectra-apply-plus round 1 — an extra positional argument after `--check-current` changed the mode back to install, violating the internal interface's read-only contract.
