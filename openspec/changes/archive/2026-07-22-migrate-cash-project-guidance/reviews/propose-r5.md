# Cash Propose Review — Round 5

## Reviewer Findings

### Critical

None.

### Warning

- severity: Warning
  confidence: 100
  layer: design
  disposition: fix-introduced
  introduced_by: Round 4將 receipt-less conflict統一描述為 skills混雜、不完整或與source不同
  location: `proposal.md` recovery summary；`design.md` transaction/failure/risk contracts；delta spec runtime recovery與clean-target scenarios；`tasks.md` 2.3
  summary: 「無 receipt且 skills不完整即 conflict」未排除零個受管 skill目的地存在的乾淨首次安裝，與 clean-target成功安裝合約衝突。
  recommendation: 把 receipt-less state明確分成零檔首次安裝、24檔完整全等 adoption，以及已有至少一檔但未滿足adoption的 conflict，並加入零檔fixture。
  reviewer: Reviewer V

### Suggestion

None.

## Rating

- cumulative blocking Critical: 0
- cumulative blocking Warning: 1
- non-blocking triaged findings: 0
- critical_gap: false
- round_type: micro
- rationale: Reviewer V確認Round 4的不可觀測歷史 finding已 resolved，但該修正引入一項 receipt-less零檔邊界 Warning。修正後仍須下一輪 Reviewer V確認才能移除，因此本輪為 `next_round`。

## Fix Actions

- 修改 `proposal.md`、`design.md`、delta spec與 `tasks.md`，把無 receipt狀態明定為互斥三分法：零個受管 skill目的地存在走首次安裝；24檔全數存在且與source相同走 adoption；至少一個目的地存在但未滿足完整全等 adoption才是 conflict並須 `--force`。
- 修改 runtime recovery scenarios與 task 2.3，加入零檔首次安裝不被攔截，以及24檔全等但receipt publication失敗後由adoption補齊的fixtures。

## Decision

next_round
