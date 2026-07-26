---
id: stated-criterion-diverges-from-applied-criterion
type: recurring-finding
status: open
occurrences: 2
first_seen: 2026-07-26
last_seen: 2026-07-26
links:
  - openspec/changes/rightsize-cash-skills/reviews/propose-r1.md
  - openspec/changes/rightsize-cash-skills/reviews/apply-r1.md
---

# Stated criterion diverges from applied criterion

A design states a principle for making a cut ('everything that must hold without X stays'), then applies a different, more convenient proxy ('everything marked with Y stays'). The two agree on most items, so the divergence is invisible until an item satisfies one and not the other — at which point the design's stated rationale no longer explains its own outcome.

## Occurrences

- 2026-07-26 — rightsize-cash-skills — cash-propose round 1 — 拆分點宣稱的判準是「未載入 reference 也必須生效者留在 SKILL.md」，實際套用的是「帶 sentinel 者留下」；fix actions 中的 receipt 重建指示（風險 R4 的唯一緩解手段）滿足前者卻不滿足後者，會被移入按需載入的檔案。
- 2026-07-26 — rightsize-cash-skills — cash-apply round 1 — spec 的 fallback axis (b) 接受提出相同問題或呈現相同選項，實作卻硬編碼必須含 `ask`；修正後同步辨識 `present`／`show`／`offer` 搭配 question/options。
