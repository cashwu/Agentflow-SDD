---
id: classification-partition-not-exhaustive
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-26
last_seen: 2026-07-26
links:
  - openspec/changes/rightsize-cash-apply-tdd-discipline/reviews/propose-r1.md
---

# Classification partition not exhaustive

A workflow claims that a set of branches classifies every input exactly once, but its fallback is narrower than the complement of the preceding branches. Legitimate inputs then match no branch, forcing the implementer to invent behavior outside the stated contract. The fix is to define ordered precedence and make the final branch an explicit remaining-input catch-all.

## Occurrences

- 2026-07-26 — rightsize-cash-apply-tdd-discipline — cash-propose round 1 — TDD discipline 的四分支原本宣稱涵蓋每個 task，但最後一支只涵蓋沒有自動測試邊界的工作，漏掉具有 checker、卻不是 bug fix、observable behavior change 或 pure refactor 的文件／metadata task；修正為依 precedence 判定，並將末支定義成所有 remaining tasks。
