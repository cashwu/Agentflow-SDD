---
id: single-bound-assertion-misses-deletion
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-26
last_seen: 2026-07-26
links:
  - openspec/changes/rightsize-cash-skills/reviews/propose-r4.md
---

# Single-bound assertion misses deletion

An assertion that guards only an upper bound (at most N occurrences) passes when the count is zero, so it cannot catch the rule being deleted outright. This is especially dangerous when the guarded content sits inside a block the same change is trimming — the deletion the assertion was written to prevent is exactly the one it lets through.

## Occurrences

- 2026-07-26 — rightsize-cash-skills — cash-propose round 4 — fallback 斷言原本只把關「至多一次」，而七個 skill 的唯一 fallback 陳述正是層次一要修剪的 `**Guardrails**` 區塊末條 bullet；整條被刪仍會全綠。修正為同時把關上下界：使用該工具者恰為一次，不使用者為零次。
