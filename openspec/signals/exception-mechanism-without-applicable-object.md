---
id: exception-mechanism-without-applicable-object
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-26
last_seen: 2026-07-26
links:
  - openspec/changes/rightsize-cash-skills/reviews/propose-r4.md
---

# Exception mechanism without applicable object

A change introduces a named-exception mechanism to carve out cases from a rule, then later tightens the rule itself so that those cases no longer match. The exception list ends up with no applicable object, its accompanying scenario has no witness, and implementers must either write a dead entry or let the scenario pass vacuously. Tightening a rule requires re-checking whether earlier carve-outs are still needed.

## Occurrences

- 2026-07-26 — rightsize-cash-skills — cash-propose round 4 — 為排除 `cash-ingest:261` 引入具名例外機制，隨後把判定條件改為兩軸後該處本來就不滿足 (b) 而自然排除，例外機制失去適用對象；另「比照 `divergent_skills` 具名清單」在結構上不可行，因該清單以 skill 為單位而非檔內位置。機制已整體移除。
