---
id: spec-precedence-exception-missing
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-04
last_seen: 2026-07-04
links:
  - openspec/changes/guard-dirty-source-auto-repair/reviews/propose-r1.md
  - openspec/changes/guard-dirty-source-auto-repair/reviews/propose-r2.md
  - openspec/changes/guard-dirty-source-auto-repair/reviews/propose-r3.md
  - openspec/changes/guard-dirty-source-auto-repair/reviews/propose-r4.md
---

# Spec precedence exception missing

A change introduces a new guard or early-return behavior that overrides existing requirements, but the delta spec does not explicitly modify the affected existing requirements to define precedence.

## Occurrences

- 2026-07-04 — guard-dirty-source-auto-repair — spectra-propose-plus rounds 1-4 — Review found dirty-source guard precedence conflicts with metadata validation, dry-run repair output, throttle behavior, and auto-restore requirements.
