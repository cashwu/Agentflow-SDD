---
id: fix-action-recorded-without-being-applied
type: recurring-finding
status: open
occurrences: 2
first_seen: 2026-07-26
last_seen: 2026-08-22
links:
  - openspec/changes/harden-spec-trace-path-extraction/reviews/propose-r5.md
  - openspec/changes/guard-task-state-integrity/reviews/propose-r1.md
---

# Fix action recorded without being applied

A review round's `## Fix Actions` records a change as made, but the edit silently failed to land. The agent confirmed only that its edit tooling exited successfully — not that the target text actually changed — so an unmatched search string became a no-op that was then written up as completed work. The next round re-reports the original finding as `unresolved-prior`, and the round file that claimed the fix is already immutable.

This is distinct from an incomplete fix: nothing was fixed at all, yet the record asserts otherwise. It makes the round file — a gate input later rounds and re-runs depend on — factually false, and it consumes a full round to discover.

## Occurrences

- 2026-07-26 — harden-spec-trace-path-extraction — cash-propose round 5 — 第 4 輪的四項 tasks 側修正全部未落地：主 agent 使用不帶斷言的字串替換，目標字串不完全相符時 `.replace()` 靜默無作用，而主 agent 只確認腳本執行成功即記入 `## Fix Actions`。第 5 輪 reviewer 逐一讀檔後發現 `tasks 2.3` 仍為單數迴圈變數寫法、`1.5` 無新增 case 且仍寫「五個 case」、全檔無任何 stderr 缺席斷言、delta 的 `tests` 判準無字元集要求——四項在第 4 輪皆被記為已修。修法是每處編輯 MUST 斷言目標存在且恰好命中一次，並在修正後另跑一份獨立的特徵字串機械驗證，全部通過才記入 `## Fix Actions`。
- 2026-08-22 — guard-task-state-integrity — cash-propose round 5 — round 4 的 `## Fix Actions` 逐字記錄「IC4 第 2 點同步」，但該修改從未實際執行——round 5 的 reviewer 以實檔 grep 確認 IC4 第 2 點仍逐字停在窄版。Fix Actions 是 gate 輸入，記錄不實會使後續每一輪都以錯誤前提判斷收斂狀態。
