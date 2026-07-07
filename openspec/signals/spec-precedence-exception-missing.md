---
id: spec-precedence-exception-missing
type: recurring-finding
status: open
occurrences: 3
first_seen: 2026-07-04
last_seen: 2026-07-07
links:
  - openspec/changes/guard-dirty-source-auto-repair/reviews/propose-r1.md
  - openspec/changes/guard-dirty-source-auto-repair/reviews/propose-r2.md
  - openspec/changes/guard-dirty-source-auto-repair/reviews/propose-r3.md
  - openspec/changes/guard-dirty-source-auto-repair/reviews/propose-r4.md
  - openspec/changes/add-micro-verification-round/reviews/propose-r1.md
  - openspec/changes/add-review-loop-discipline/reviews/propose-r1.md
---

# Spec precedence exception missing

A change introduces a new guard or early-return behavior that overrides existing requirements, but the delta spec does not explicitly modify the affected existing requirements to define precedence.

## Occurrences

- 2026-07-04 — guard-dirty-source-auto-repair — spectra-propose-plus rounds 1-4 — Review found dirty-source guard precedence conflicts with metadata validation, dry-run repair output, throttle behavior, and auto-restore requirements.
- 2026-07-07 — add-micro-verification-round — spectra-propose-plus round 1 — Version bump to 1.3.0 affected master requirements whose scenarios pin version/date literals ("Generated plus skill version metadata", "Repair checks plus metadata freshness"), but the delta initially did not MODIFY them.
- 2026-07-07 — add-review-loop-discipline — spectra-propose-plus round 1 — The new grader-immutability rule mandated withholding some fixes, contradicting the master quality-gate scenarios' unconditional "fixes the ... findings before starting the next round"; the delta initially only ADDED the new requirement without MODIFYing the two governed gate requirements.
