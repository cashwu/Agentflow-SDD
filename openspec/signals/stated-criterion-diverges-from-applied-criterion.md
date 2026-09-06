---
id: stated-criterion-diverges-from-applied-criterion
type: recurring-finding
status: open
occurrences: 4
first_seen: 2026-07-26
last_seen: 2026-09-05
links:
  - openspec/changes/rightsize-cash-skills/reviews/propose-r1.md
  - openspec/changes/rightsize-cash-skills/reviews/apply-r1.md
  - openspec/changes/harden-trace-path-containment-and-label-shape/reviews/propose-r1.md
  - openspec/changes/add-host-derived-round-lint/reviews/propose-r1.md
---

# Stated criterion diverges from applied criterion

A design states a principle for making a cut ('everything that must hold without X stays'), then applies a different, more convenient proxy ('everything marked with Y stays'). The two agree on most items, so the divergence is invisible until an item satisfies one and not the other — at which point the design's stated rationale no longer explains its own outcome.

## Occurrences

- 2026-07-26 — rightsize-cash-skills — cash-propose round 1 — 拆分點宣稱的判準是「未載入 reference 也必須生效者留在 SKILL.md」，實際套用的是「帶 sentinel 者留下」；fix actions 中的 receipt 重建指示（風險 R4 的唯一緩解手段）滿足前者卻不滿足後者，會被移入按需載入的檔案。
- 2026-07-26 — rightsize-cash-skills — cash-apply round 1 — spec 的 fallback axis (b) 接受提出相同問題或呈現相同選項，實作卻硬編碼必須含 `ask`；修正後同步辨識 `present`／`show`／`offer` 搭配 question/options。
- 2026-07-26 — harden-trace-path-containment-and-label-shape — cash-propose round 1 — delta 的規範句宣稱「指向 repo 之外或含非 canonical 路徑段的值 MUST NOT 進入任一欄位」（原則），實際機制只列舉了「任一路徑段為空、`.` 或 `..`」（代理判準）。兩者在絕大多數輸入上一致，直到 `~/outside/x.py` 出現——它滿足原則卻不觸發代理判準，且 `~` 正在裸路徑與驗證子句共用的字元集之內，因此會原樣寫入 `code` 與 `tests`。修法是把 `~` 納入拒絕條件並讓條文逐一列舉其涵蓋的逃逸形式，而非只寫概括的原則。

- 2026-09-05 — add-host-derived-round-lint — cash-propose round 1 — design 規定變更集合涵蓋工作區與 index，proposal 卻指名 `git diff --name-only` 這個只涵蓋 unstaged 改動的機制。兩者在多數情況下結果相同，差異只在受保護檔案已 `git add` 時顯現——而那正是規避者會做的動作。宣告意圖與指名機制分處兩份 artifact 時，機制那一側才是實作者會照做的。
