# Cash Propose Review — Round 3

## Reviewer Findings

### Critical

None.

### Warning

- severity: Warning
  confidence: 100
  layer: design
  disposition: unresolved-prior
  location: `proposal.md` Proposed Solution；`design.md` transaction與failure contracts；delta spec runtime publication scenarios
  summary: Skill partial publication的恢復規則只涵蓋相對先前 receipt的 drift，未涵蓋沒有先前 receipt的首次安裝；該 state一般重試也會是 conflict。
  recommendation: 同步定義有有效 receipt與 receipt-less首次安裝兩個分支；兩者一般重試都回報 `conflict`且零寫入，只有 `--force`可收斂。
  reviewer: Reviewer V

### Suggestion

None.

## Rating

- cumulative blocking Critical: 0
- cumulative blocking Warning: 1
- non-blocking triaged findings: 0
- critical_gap: false
- round_type: micro
- rationale: Round 2唯一的累積 Warning仍有 receipt-less首次安裝分支未覆蓋，Reviewer V判定為 unresolved-prior。本輪已補齊修正，但仍須後續 reviewer以證據確認；因下一輪為第4輪，依 review loop規則必須執行 full雙審，因此本輪為 `next_round`。

## Fix Actions

- 修改 `proposal.md`、`design.md`、delta spec與 `tasks.md`，明定任何 skill partial publication都進入 conflict recovery：有有效 receipt時是 drift，沒有 receipt時是混雜或不完整的 receipt-less state；兩者一般重試均 `Result: conflict`且零寫入，只有 `--force`可收斂並發佈新 receipt。
- 將 task 2.3的 runtime failure fixtures拆出有 receipt與 receipt-less首次安裝兩個明確分支。

## Decision

next_round
