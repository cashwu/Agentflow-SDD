---
id: multi-operation-phase-order-undefined
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-23
last_seen: 2026-07-23
links:
  - openspec/changes/replace-spectra-cli-with-cash-cli/reviews/propose-r3.md
---

# Multi-operation phase order undefined

A transaction accepts several operations over the same logical identity but does not define their legal combinations, collision rules, and deterministic phase order, making results depend on iteration order or causing a valid combined change to fail midway.

## Occurrences

- 2026-07-23 — replace-spectra-cli-with-cash-cli — cash-propose round 3 — sync允許同一requirement的MODIFIED與RENAMED卻未定義順序；修正為MODIFIED/REMOVED、ADDED、RENAMED固定phases與完整collision matrix。
