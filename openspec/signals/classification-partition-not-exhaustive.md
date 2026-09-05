---
id: classification-partition-not-exhaustive
type: recurring-finding
status: open
occurrences: 2
first_seen: 2026-07-26
last_seen: 2026-09-05
links:
  - openspec/changes/rightsize-cash-apply-tdd-discipline/reviews/propose-r1.md
  - openspec/changes/dispatch-vendored-targets-in-batch/reviews/propose-r1.md
---

# Classification partition not exhaustive

A workflow claims that a set of branches classifies every input exactly once, but its fallback is narrower than the complement of the preceding branches. Legitimate inputs then match no branch, forcing the implementer to invent behavior outside the stated contract. The fix is to define ordered precedence and make the final branch an explicit remaining-input catch-all.

## Occurrences

- 2026-07-26 — rightsize-cash-apply-tdd-discipline — cash-propose round 1 — TDD discipline 的四分支原本宣稱涵蓋每個 task，但最後一支只涵蓋沒有自動測試邊界的工作，漏掉具有 checker、卻不是 bug fix、observable behavior change 或 pure refactor 的文件／metadata task；修正為依 precedence 判定，並將末支定義成所有 remaining tasks。
- 2026-09-05 — dispatch-vendored-targets-in-batch — cash-propose round 1 — publication-mode probe 的四支分割只為第 1 支指定例外處置，第 3 支求值同樣會拋出且含未包裝的原生 `OSError`，catch-all 因此比前面各支的補集更窄；修正為「整個函式主體單一 try、任何例外一律落入 catch-all」，並在 round 4 進一步刪去在任何輸入上都不改變結果的第 1 支，把分割縮為三支。
