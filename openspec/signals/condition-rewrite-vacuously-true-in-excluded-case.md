---
id: condition-rewrite-vacuously-true-in-excluded-case
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-08-22
last_seen: 2026-08-22
links:
  - openspec/changes/default-spec-sync-on-archive/reviews/propose-r1.md
---

# Condition rewrite vacuously true in a previously excluded case

A gating condition is restated in terms of a different observable that looks equivalent on the case the change cares about, but is vacuously true on an input the original condition excluded. The rewritten gate therefore admits content the old gate kept out, and because the regression only shows up on the input nobody was thinking about, it survives review as a wording change. The fix is to enumerate every input the original condition evaluated — especially the ones where it returned false for a reason unrelated to the change — and confirm the replacement returns the same verdict on each.

## Occurrences

- 2026-08-22 — default-spec-sync-on-archive — cash-propose round 1 — 移除「使用者明確選擇 spec sync」的提問後，`cash-commit` 6a-iii 的 `openspec/specs/` 納入條件被改寫為「封存未帶 `--skip-specs`」。但沒有 delta specs 時封存同樣不帶旗標，該條件恆真，會把無關的 dirty spec 路徑掃進 archive-first 提交集合；舊條件在該情形為 false（使用者從未被問、從未選擇）。修法是導入三值判定結果，只有 `synced` 才納入。
