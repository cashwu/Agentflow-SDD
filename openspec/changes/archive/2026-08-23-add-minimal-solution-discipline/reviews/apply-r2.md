# Cash Apply Review — Round 2

## Reviewer Findings

### Critical

None.

### Warning

- severity: Warning
  confidence: 99
  layer: text
  location: `scripts/cash-skills/tests/skill-checks.fish` 的 topology `role_pattern`
  summary: topology parser 只辨識 `Reviewer`／`Rater` 開頭的角色，額外加入 `Auditor C — Simplicity` 仍會通過，尚未真正保證 exact role set。
  recommendation: 解析 full／micro slices 內所有粗體 role bullets，再 exact-compare A／B 與 V，並加入非 Reviewer/Rater 名稱 mutation。
  disposition: unresolved-prior
  reviewer source: Reviewer V — Verification

### Suggestion

None.

## Rating

- cumulative blocking Critical: 0
- cumulative blocking Warning: 1
- non-blocking triaged findings: 0
- critical_gap: false
- round_type: micro

Round 1 的 vague-trigger 與 cash-ingest destination members 已由 Reviewer V 明確判定 `resolved`；topology member 仍為 `unresolved-prior`，decision 為 `next_round`。

## Fix Actions

- verified resolution：移除 Round 1 的 vague-trigger member；Reviewer V 已確認 known-ceiling entry fixtures 拒絕「之後需要時」與「規模變大時」。
- verified resolution：移除 Round 1 的 cash-ingest destination member；Reviewer V 已確認兩 variant 的 exact prefix 與 wrong-destination mutation。
- `fix-r2-topology`：把 topology regex 改為解析 full／micro slices 內所有粗體 role bullets，再 exact-compare `[Reviewer A — Adherence, Reviewer B — Quality]` 與 `[Reviewer V — Verification]`；加入 `Auditor C — Simplicity` mutation。
- 驗證：具名 contract group、generated freshness、full skill suite 與 bundle history test 全部 exit 0。

## Decision

next_round
