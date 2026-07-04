---
id: source-sensitive-scope-mismatch
type: recurring-finding
status: open
occurrences: 2
first_seen: 2026-07-04
last_seen: 2026-07-04
links:
  - openspec/changes/guard-dirty-source-auto-repair/reviews/propose-r6.md
  - openspec/changes/guard-dirty-source-auto-repair/reviews/propose-post-abort-fix.md
---

# Source sensitive scope mismatch

A safety guard defines a protected source path set that is broader or narrower than the stated design intent, creating either unnecessary blocking or uncovered output-affecting changes.

## Occurrences

- 2026-07-04 — guard-dirty-source-auto-repair — spectra-propose-plus round 6 — Review found the source-sensitive path set covered all `spectra-*` skill WIP while the design intent said to focus on paths that affect plus repair output.
- 2026-07-04 — guard-dirty-source-auto-repair — post-abort fix verification — Follow-up review accepted the broad `spectra-*` path set after artifacts made it an explicit intentional trade-off and added non-output skill coverage.
