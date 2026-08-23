---
id: option-cannot-observe-its-own-trigger
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-08-22
last_seen: 2026-08-22
links:
  - openspec/changes/guard-task-state-integrity/reviews/propose-r3.md
---

# Implementation option cannot observe its own trigger

契約為某個義務列出數個「實作手段不限」的選項，其中一個在該契約自己規定的執行順序下永遠觀察不到觸發條件，因此依它實作會使該義務永不生效——而該實作仍能通過全部字面值與計數判準，因為判準檢查的是「函式存在、被呼叫」而非「條件曾為真」。與 [[fix-introduces-mutually-negating-clauses]] 不同：那是同一句內兩條規則互斥，這是單一選項與契約他處的執行順序不相容。與 [[condition-rewrite-vacuously-true-in-excluded-case]] 互為鏡像：那是條件恆真，這是條件恆假。

## Occurrences

- 2026-08-22 — guard-task-state-integrity — cash-propose round 3 — IC4 第 4 點列出兩個取得「對齊是否改變內容」flag 的手段，其一為「由 `ensure_touched()` 自行再呼叫一次 `_realign_touched_attribution()`」；但同 IC 第 3 點已要求 `load_or_import_touched()` 先行對齊，而 `ensure_touched()` 的值正來自它，對已對齊的物件再跑一次必然回報未改變，D4 要求的修復性寫入將永不發生。修正為刪除該選項並明寫 MUST NOT 與理由。
