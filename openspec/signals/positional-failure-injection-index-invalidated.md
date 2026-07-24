---
id: positional-failure-injection-index-invalidated
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-24
last_seen: 2026-07-24
links:
  - openspec/changes/guard-target-receipt-version-control/reviews/propose-r1.md
---

# Positional failure injection index invalidated

A test injects failure by ordinal position in an operation sequence; adding an operation shifts every later index, so the test silently exercises a different stage than intended while still passing.

## Occurrences

- 2026-07-24 — guard-target-receipt-version-control — cash-propose round 1 — 新增 transaction operation 會位移 `CASH_INSTALL_FAIL_AFTER` 的硬編索引，使既有 rollback 測試不再落在 legacy quarantine 之後而仍通過。
