---
id: fix-introduces-mutually-negating-clauses
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-26
last_seen: 2026-07-26
links:
  - openspec/changes/rightsize-cash-skills/reviews/propose-r2.md
---

# Fix introduces mutually negating clauses

A fix adds an exemption or qualifier to a requirement without revisiting the neighbouring normative sentence, leaving two clauses in the same requirement that negate each other — one mandates a condition, the other exempts the very cases that violate it. The requirement becomes unsatisfiable as written, and any assertion derived from it must silently pick a side.

## Occurrences

- 2026-07-26 — rightsize-cash-skills — cash-propose round 2 — 為修正事實敘述而加入「已為單一陳述的 skill MUST NOT 僅因位置不同而被要求改動」的豁免句，卻未回頭處理同段既有的「規則 MUST 出現在首次使用之前」；`cash-archive`（`:34`／`:172`）與 `cash-propose`（`:45`／`:518`）實測正好違反該位置 MUST。修正為把位置降為 SHOULD 級建議。
