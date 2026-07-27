# Cash Propose Review — Round 1

## Reviewer Findings

### Critical

- severity: Critical
  confidence: 100
  layer: design
  location: `tasks.md` §2.1–2.2；`design.md` D5
  summary: task 2.1 修改 receipt-managed runtime／skill bytes 後，下一個 `task done` 會在 task 2.2 執行 version bump 與 receipt 重建之前先以 `receipt_invalid` 失敗。
  recommendation: 將 `cash-skills.version` bump 與首次 `./install-cash-skills.fish --self` 合併進 task 2.1，並要求在該 task 的 `task done` 前完成。
  reviewer: A+B

### Warning

- severity: Warning
  confidence: 100
  layer: design
  location: `design.md` D2；`specs/cash-cli/spec.md`「TDD discipline 以適用性判準表述」
  summary: 四分支宣稱涵蓋每個 task，但原第 4 分支只包含沒有自動測試邊界的 task，漏掉具有 checker、卻不是 bug fix、behavior change 或 pure refactor 的文件／metadata task。
  recommendation: 將第 4 分支改為真正的 remaining-task catch-all，允許使用自動 checker，但不要求 red phase，並同步所有 artifacts 與 tests。
  reviewer: B

### Suggestion

None.

## Rating

- Critical: 1
- Warning: 1
- Non-blocking triaged: 0
- critical_gap: true
- round_type: full
- rationale: 第一輪兩個存活 findings 均為 blocking；receipt 時序會直接使 apply task loop 無法跨過 task 2.1，四分支缺口則使 canonical discipline 的宣稱 partition 不成立，因此本輪必須修正後進入下一輪。

## Fix Actions

- 修正 receipt 時序：更新 `design.md` 與 `tasks.md`，將 version bump 與首次 `./install-cash-skills.fish --self` 納入修改 managed bytes 的 task 2.1，明定在該 task 的 `task done` 前完成；task 2.2 只保留 history／receipt 驗證。
- 修正四分支 partition：更新 `proposal.md`、`design.md`、`specs/cash-cli/spec.md`、`specs/cash-skill-workflows/spec.md` 與 `tasks.md`，把第 4 分支定義為所有 remaining tasks 的 catch-all，允許 checker 驗證但不強迫 red phase，並同步 semantic assertion 名稱。
- 修正後重新執行 Cash validation、delta comment／separator lint、identifier cross-grep 與 Cash analyze；validation 通過，Coverage、Consistency 與 Gaps 均為 clean。Cash analyze 對每個未含 `##### Example:` 的 scenario 仍產生泛化 Suggestion，但未指出具體不可判定語意，不列入 reviewer finding 或 blocking set。

## Decision

next_round
