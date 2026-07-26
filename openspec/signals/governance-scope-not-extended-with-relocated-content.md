---
id: governance-scope-not-extended-with-relocated-content
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-26
last_seen: 2026-07-26
links:
  - openspec/changes/rightsize-cash-skills/reviews/propose-r1.md
---

# Governance scope not extended with relocated content

Content moves out of a governed file into a new one, but the governance mechanisms that covered it — protected-path sets, anti-pattern assertions, parity comparison, well-formedness checks — keep pointing at the original file only. The relocated content silently leaves the governed surface, shrinking enforcement without anyone recording that it shrank.

## Occurrences

- 2026-07-26 — rightsize-cash-skills — cash-propose round 1 — 把 156 行 review loop 規則移出受保護的四個 `SKILL.md` 時，grader immutability 的受保護路徑集合、`assert_command_matrix` 的兩條反模式 `assert_absent`、對等比較與空 code span 檢查都仍只涵蓋 `SKILL.md`，搬移後的內容不受任何既有護欄約束。
