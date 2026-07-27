---
id: rule-driven-deletion-range-unbounded
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-27
last_seen: 2026-07-27
links:
  - openspec/changes/cash-skill-maintainability/reviews/apply-r1.md
---

# Rule-driven deletion range unbounded

A declarative transformation rule deletes from a start marker to an end marker, and the search for the end marker has no upper bound. On well-formed input the two markers are adjacent and the rule looks correct; on input where the end marker is missing, the search runs past the intended region and finds an unrelated later occurrence, deleting everything in between. Because a match was found, the transformation reports success and exits zero — the loss is silent and shows up only as missing content in the generated artifact. The risk is highest when the rule replaces an earlier mechanism that pinned exact line ranges, since the range constraint disappears with it. The fix is to bound the search at the next structural boundary and fail loudly when no end marker precedes it, so a malformed region is an error rather than an over-deletion.

## Occurrences

- 2026-07-27 — cash-skill-maintainability — cash-apply round 1 — `scripts/cash-skills/generate.fish` 的 `remove_section` 以 `lines.index(terminator, start + 1)` 搜尋 `## Claude fork context` 的 `---` 終止線；實測為 `cash-commit` 注入一段未終止的 fork 段落、後方隔著 `## KEEP ME A` 才出現 `---`，生成器 exit 0 且輸出檔案中該標題與其內容全數消失。此路徑取代了被刪除的 `scripts/cash-skills/variant-parity/*.diff`（原本以逐行範圍釘住被移除的內容）。修正為把搜尋上界收在下一個 `^## ` 標題，找不到終止線時 `die()`。
