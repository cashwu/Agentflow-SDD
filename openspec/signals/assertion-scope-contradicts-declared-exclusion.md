---
id: assertion-scope-contradicts-declared-exclusion
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-25
last_seen: 2026-07-25
links:
  - openspec/changes/align-cli-skill-contracts/reviews/propose-r1.md
---

# Assertion scope contradicts declared exclusion

A change adds an assertion phrased over a whole population while its own scope boundary explicitly excludes part of that population, so the assertion is unsatisfiable the moment it lands. The defect appears when the assertion is drafted from the intended end state and the scope boundary from the intended edit set, without checking the two against the current inventory.

## Occurrences

- 2026-07-25 — align-cli-skill-contracts — cash-propose round 1 — 新增「12 個 .agents SKILL.md frontmatter 皆不含三個 key」的斷言，但 contract 範圍邊界明文排除修改 cash-ask，而 cash-ask 與 cash-discuss 當時都帶 disallowedTools。
