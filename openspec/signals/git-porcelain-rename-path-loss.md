---
id: git-porcelain-rename-path-loss
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-09-06
last_seen: 2026-09-06
links:
  - openspec/changes/add-host-derived-round-lint/reviews/apply-r1.md
---

# Git porcelain rename record loses a path

A parser for NUL-delimited Git status output treats the second path in a rename or copy record as a normal status record and strips its first three bytes, allowing a protected source or destination path to disappear from the derived change set.

## Occurrences

- 2026-09-06 — add-host-derived-round-lint — cash-apply round 1 — `_git_changed` initially parsed every NUL token independently; fixed by consuming both paths for `R` and `C` records.
