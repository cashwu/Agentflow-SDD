---
id: hook-failure-detail-omitted
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-09-06
last_seen: 2026-09-06
links:
  - openspec/changes/add-host-derived-round-lint/reviews/apply-r1.md
---

# Hook failure omits the gate detail

A host hook reports only a compact failure identifier while dropping the gate's diagnostic detail, making the blocking result harder to act on and reducing observability of the actual violated condition.

## Occurrences

- 2026-09-06 — add-host-derived-round-lint — cash-apply round 1 — hook stderr initially emitted only `change:id`; fixed by including the gate detail and retaining JSON diagnostics.
