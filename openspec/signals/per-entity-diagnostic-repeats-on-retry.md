---
id: per-entity-diagnostic-repeats-on-retry
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-24
last_seen: 2026-07-24
links:
  - openspec/changes/guard-target-receipt-version-control/reviews/apply-r1.md
---

# Per-entity diagnostic repeats on retry

A diagnostic specified as one line per entity is emitted from inside a function that re-enters itself to reclassify or retry, so the contracted per-entity cardinality silently becomes per-attempt. The duplication is invisible in the common path and unbounded in batch mode, and it grows more reachable whenever the change adds a frequently-edited input to the set whose drift triggers the retry.

## Occurrences

- 2026-07-24 — guard-target-receipt-version-control — cash-apply round 1 — 版控狀態 diagnostic 置於自遞迴的 `install_target` 開頭，post-lock 重新分類與 in-flight receipt 路徑各會再輸出一次；改為以 `announce_tracking` 參數在四個遞迴呼叫點抑制重入輸出，並以 lock-wait 重新分類情境斷言 stderr 恰為 1 行。
