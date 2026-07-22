---
id: shared-temp-namespace-test-interference
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-22
last_seen: 2026-07-22
links:
  - openspec/changes/migrate-cash-project-guidance/reviews/apply-r4.md
---

# Shared temporary namespace test interference

A cleanup test compares a process-shared temporary namespace instead of tracking resources owned by the invocation under test, allowing unrelated concurrent processes to cause false failures or hide ownership mistakes.

## Occurrences

- 2026-07-22 — migrate-cash-project-guidance — cash-apply round 4 — Dry-run cleanup fixture原先比較整個system temp namespace；改用test-local `mktemp` PATH shim記錄本次invocation建立的四個guidance snapshots並逐一驗證exit後不存在。
