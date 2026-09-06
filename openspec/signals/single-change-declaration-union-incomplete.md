---
id: single-change-declaration-union-incomplete
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-09-06
last_seen: 2026-09-06
links:
  - openspec/changes/add-host-derived-round-lint/reviews/apply-r1.md
---

# Single-change declaration union is incomplete

A single-change verification mode narrows structured-scope declarations to the selected change even though the host-wide gate requires the same declaration union as hook mode. This makes equivalent workspace state produce different grader decisions depending on the entry point.

## Occurrences

- 2026-09-06 — add-host-derived-round-lint — cash-apply round 1 — single-change mode initially collected declarations only from its selected change; fixed by collecting all non-parked enumerated changes.
