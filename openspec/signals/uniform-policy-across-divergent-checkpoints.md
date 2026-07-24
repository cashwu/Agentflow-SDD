---
id: uniform-policy-across-divergent-checkpoints
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-24
last_seen: 2026-07-24
links:
  - openspec/changes/guard-target-receipt-version-control/reviews/propose-r1.md
---

# Uniform policy across divergent checkpoints

A fix states one uniform policy for a validation that runs at multiple checkpoints, but those checkpoints have divergent established contracts — one reclassifies and retries, another fails closed — so the uniform wording contradicts the implementation at one of them.

## Occurrences

- 2026-07-24 — guard-target-receipt-version-control — cash-propose round 2 — 修正把「不一致時重新分類」同時套用到 post-lock 與 publication 前兩個檢查點，但後者既有行為與 guidance 契約皆為 fail closed。
