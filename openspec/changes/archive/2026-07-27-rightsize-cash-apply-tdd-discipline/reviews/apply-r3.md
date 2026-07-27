# Cash Apply Review — Round 3

## Reviewer Findings

### Critical

None.

### Warning

- severity: Warning
  confidence: 100
  layer: design
  location: `scripts/cash-skills/tests/skill-checks.fish:234` 的 `example-table every-row contract` assertion
  summary: skill 文字已明確要求每個 in-scope example 的 GIVEN/WHEN/THEN input 與 expected output（包含 example table 的每一列）納入 verification evidence，但回歸測試只搜尋 `including every row of an example table` 子句；若後續移除 input 與 expected output 義務，`tdd-discipline` 仍會通過。
  recommendation: 對兩個變體逐字斷言完整 every-row clause，使測試與 normative statement 同等嚴格。
  reviewer: A

### Suggestion

None.

## Rating

- Critical: 0
- Warning: 1
- Non-blocking triaged: 0
- critical_gap: false
- round_type: full
- rationale: Reviewer A 以 delta scenario 的明確 MUST 證明 assertion 弱於 normative statement，confidence 100 且本輪為新 run 的第一輪，因此進入 blocking set；Reviewer B 未發現其他品質問題。必須補強完整 clause assertion，再由 micro reviewer 驗證。

## Fix Actions

- 修改 `scripts/cash-skills/tests/skill-checks.fish`，將 `example-table every-row contract` assertion 由只搜尋 `every row` 子句，提升為逐字斷言完整的 GIVEN／WHEN／THEN input、expected output 與 every-row clause。
- 修正後重跑 `tdd-discipline`、`variant-parity`、Cash validation、完整 clause cross-grep 與 `git diff --check`，全部通過。
- 已以 Cash touched tracking 記錄 `scripts/cash-skills/tests/skill-checks.fish`。

## Decision

next_round
