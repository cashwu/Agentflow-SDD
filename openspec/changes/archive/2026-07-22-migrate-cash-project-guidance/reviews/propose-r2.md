# Cash Propose Review — Round 2

## Reviewer Findings

### Critical

None.

### Warning

- severity: Warning
  confidence: 100
  layer: design
  disposition: fix-introduced
  introduced_by: Round 1 對 publication failure recovery 的修正
  location: `specs/cash-skill-workflows/spec.md` runtime publication scenarios；`design.md` transaction failure contract；`tasks.md` 2.3
  summary: Runtime failure若已發佈 skill但保留舊 receipt，一般重試會依既有 drift規則回報 `conflict`，無法直接收斂。
  recommendation: 區分 guidance-only 與 skill partial publication；前者允許一般重試，後者要求 `--force`重試。
  reviewer: Reviewer V

### Suggestion

None.

## Rating

- cumulative blocking Critical: 0
- cumulative blocking Warning: 1
- non-blocking triaged findings: 0
- critical_gap: false
- round_type: micro
- rationale: Reviewer V以證據確認 Round 1累積集合中的8項 findings全部 resolved並移除，但發現1項 confidence 100的 fix-introduced Warning。該 finding已修正，仍須由下一輪 Reviewer V確認後才能從累積 blocking集合移除，因此本輪為 `next_round`。

## Fix Actions

- 已確認並移除 Round 1累積集合中的8項 findings：publication failure零寫入矛盾、fallback未逐字、post-preflight lost update、持久狀態量詞過寬、平行同檔競爭、source recovery矛盾、mode preservation缺失、post-preflight identity escape。
- 修改 `proposal.md`、`design.md`、delta spec與 `tasks.md`，將 recovery contract統一為 guidance-only partial publication可由一般重試收斂；任何 skill partial publication造成 receipt drift時，一般重試維持 `conflict`，必須使用 `--force`重試。

## Decision

next_round
