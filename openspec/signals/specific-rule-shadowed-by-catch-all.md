---
id: specific-rule-shadowed-by-catch-all
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-22
last_seen: 2026-07-22
links:
  - openspec/changes/refine-apply-blocker-triage/reviews/apply-r1.md
---

# Specific rule shadowed by catch-all

A workflow adds a specific branch with a deterministic outcome but leaves a broader fallback that still matches the same condition, so a literal follower receives mutually exclusive instructions. The fix is defining explicit precedence or narrowing the fallback to cases not handled by the specific branches.

## Occurrences

- 2026-07-22 — refine-apply-blocker-triage — cash-apply round 1 — 新增的 mechanism-substitution continue 分支仍被通用 `Error or blocker encountered` fallback 涵蓋；修正為 fallback 只處理 blocker triage 未涵蓋的其他錯誤或阻塞。
