---
id: spec-requirement-no-backing-task
type: recurring-finding
status: open
occurrences: 2
first_seen: 2026-07-04
last_seen: 2026-07-04
links:
  - openspec/changes/version-spectra-plus-skills/reviews/propose-r1.md
  - openspec/changes/version-spectra-plus-skills/reviews/propose-r2.md
  - openspec/changes/guard-dirty-source-auto-repair/reviews/propose-r1.md
  - openspec/changes/guard-dirty-source-auto-repair/reviews/propose-r3.md
---

# Spec requirement with no backing task

A Spectra change artifact introduced a requirement, failure mode, or implementation contract item without a matching task or test expectation that would force it to be implemented and verified.

## Occurrences

- 2026-07-04 — version-spectra-plus-skills — spectra-propose-plus rounds 1-2 — Review found spec/design requirements for generator and installer failure behavior that were not fully backed by tasks or tests.
- 2026-07-04 — guard-dirty-source-auto-repair — spectra-propose-plus rounds 1 and 3 — Review found dirty-source guard scenarios and porcelain status coverage that were not fully backed by task/test expectations.
