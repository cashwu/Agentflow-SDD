---
id: non-goal-contradicted-by-own-design
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-25
last_seen: 2026-07-25
links:
  - openspec/changes/track-review-loop-outputs-in-allowlist/reviews/propose-r2.md
---

# Non-goal contradicted by own design

A proposal lists a Non-Goal disclaiming any change to some existing rule, while one of its own design decisions demonstrably changes exactly that rule. Implementers reading the Non-Goal derive the opposite obligation from implementers reading the decision, and the contract silently forks. The fix is to carve the exception out of the Non-Goal explicitly and restate it as a positive rule in the contract — never leave it as a bare "the remaining rules are unchanged".

## Occurrences

- 2026-07-25 — track-review-loop-outputs-in-allowlist — cash-propose round 2 — 決策要求把使用者裁決排除的共用檔改列 Unrelated，而該檔仍在 tracking file 內，因此確實改變了「不在 artifact set 且不在 tracking file 才算 Unrelated」的既有判定；proposal 的 Non-Goals 卻仍宣稱不改變該判定，contract 條目也只寫「其餘規則不變」。
