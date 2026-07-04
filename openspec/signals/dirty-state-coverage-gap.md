---
id: dirty-state-coverage-gap
type: recurring-finding
status: open
occurrences: 2
first_seen: 2026-07-04
last_seen: 2026-07-04
links:
  - openspec/changes/guard-dirty-source-auto-repair/reviews/propose-r1.md
  - openspec/changes/guard-dirty-source-auto-repair/reviews/propose-r2.md
  - openspec/changes/guard-dirty-source-auto-repair/reviews/propose-r3.md
  - openspec/changes/guard-dirty-source-auto-repair/reviews/apply-r1.md
---

# Dirty state coverage gap

A change relies on git dirty-state detection but does not specify or test the full set of relevant index and working-tree status cases, such as staged-only, added, deleted, renamed, copied, typechange, unmerged, or untracked paths.

## Occurrences

- 2026-07-04 — guard-dirty-source-auto-repair — spectra-propose-plus rounds 1-3 — Review found staged-only and non-modified porcelain states were not fully covered by the dirty-source guard contract and tasks.
- 2026-07-04 — guard-dirty-source-auto-repair — spectra-apply-plus round 1 — Review found the implementation test matrix still missed copied source-sensitive porcelain entries after covering renamed, typechange, unmerged, deleted, staged, and untracked paths.
