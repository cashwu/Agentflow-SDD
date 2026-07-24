---
id: new-scope-contradicts-unamended-contract
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-24
last_seen: 2026-07-24
links:
  - openspec/changes/guard-target-receipt-version-control/reviews/propose-r1.md
---

# New scope contradicts unamended contract

A delta introduces behavior that contradicts a closed enumeration or an exclusive-scope MUST in an existing requirement, but the delta is ADDED-only and never amends the requirement it invalidates, so the merged master spec becomes self-contradictory.

## Occurrences

- 2026-07-24 — guard-target-receipt-version-control — cash-propose round 1 — 新增的 `.gitignore` 寫入牴觸既有「其他 project-owned bytes 維持不變」「failure 只回滾…」「全部一致回報 current 且零寫入」三處封閉列舉，以及 `--self` 的「real run 只寫 receipt」；delta 全為 ADDED，未以 MODIFIED 承接。
