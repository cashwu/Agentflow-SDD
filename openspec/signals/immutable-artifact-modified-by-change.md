---
id: immutable-artifact-modified-by-change
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-24
last_seen: 2026-07-24
links:
  - openspec/changes/guard-target-receipt-version-control/reviews/propose-r1.md
---

# Immutable artifact modified by change

A change plans to modify an artifact that an existing contract freezes, so satisfying the change would break every already-deployed consumer and fail the contract test that binds the artifact to its introduction commit.

## Occurrences

- 2026-07-24 — guard-target-receipt-version-control — cash-propose round 1 — task 計畫修改 stable launcher `.cash-skills/bin/cash`，但既有契約要求 stable bootstrap bytes 不隨一般 version bump 改變；`publish_launcher` 對 bytes 不符直接 raise，會使全部既有 installed target 無法安裝，正好封死該 change 想拯救的族群。
