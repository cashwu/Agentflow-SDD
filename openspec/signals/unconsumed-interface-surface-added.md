---
id: unconsumed-interface-surface-added
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-25
last_seen: 2026-07-25
links:
  - openspec/changes/track-review-loop-outputs-in-allowlist/reviews/propose-r1.md
---

# Unconsumed interface surface added

A design adds an output or flag to a new command that nothing in the change consumes: no spec sentence defines it, no task verifies it, and every documented call site omits it. It still inherits every cross-cutting contract the project imposes on that surface, so it becomes an unverified obligation rather than a feature. The fix is to either back it with a spec clause plus a test, or delete it — an interface with no consumer is not simpler for being present.

## Occurrences

- 2026-07-25 — track-review-loop-outputs-in-allowlist — cash-propose round 1 — 新 verb 的 `--json` 輸出無 spec 背書、無任務驗證、無消費者（兩個呼叫點都不帶該旗標），卻受 master 的統一 JSON 與錯誤契約約束；修法是直接移除並在 design 與 spec 明寫 MUST NOT 提供。
