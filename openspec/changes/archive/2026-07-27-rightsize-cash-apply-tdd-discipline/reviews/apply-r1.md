# Cash Apply Review — Round 1

## Reviewer Findings

### Critical

None.

### Warning

- severity: Warning
  confidence: 100
  layer: design
  location: `.cash-skills/lib/cash_cli/resources.py` 的 bug-fix branch；`scripts/cash-cli/tests/test_graph_instructions.py` 的 TDD behavior assertions
  summary: canonical bug-fix 分支只要求建立失敗重現，未要求修正後使該測試轉綠並保留為 regression evidence；全文 marker assertions 也無法證明該語意屬於 bug-fix branch。
  recommendation: 在第 1 分支綁定 failing reproduction、minimal fix、green 與 regression evidence，並以 branch-scoped assertion 驗證。
  reviewer: A+B
  introduced_by: `.cash-skills/lib/cash_cli/resources.py` 的 TDD matrix hunk與 `scripts/cash-cli/tests/test_graph_instructions.py` 新增的全文 behavior-marker assertions。

- severity: Warning
  confidence: 100
  layer: design
  location: `implementation-notes.md` 兩筆 `PYTHONPATH` deviations；`design.md` C5；`tasks.md` 1.1、3.1；`specs/cash-cli/spec.md`「Resource tests 覆蓋完整語意」
  summary: `PYTHONPATH=.cash-skills/lib` 是合理且保留 contract 的啟動機制替換，但 durable artifacts 仍列出會在 import 階段失敗的直接 Python command。
  recommendation: 將實際可執行的 command 回填至 design、delta spec 與 completed task descriptions，使 durable handoff 與驗證證據一致。
  reviewer: A

- severity: Warning
  confidence: 100
  layer: design
  location: `scripts/cash-cli/tests/test_graph_instructions.py` 的 precedence 與 remaining-task boundary tests
  summary: tests 只驗證 markers 在全文存在與出現順序，沒有證明兩個 boundary cases、verification target、checker allowance 與 no-red 結論實際位於第 4 catch-all branch。
  recommendation: 解析四個 numbered branches，並把兩個 boundary cases 與其處置 assertions 限定於第 4 branch。
  reviewer: B
  introduced_by: `scripts/cash-cli/tests/test_graph_instructions.py` 新增的 `test_tdd_discipline_classifies_tasks_by_precedence` 與 `test_tdd_discipline_routes_remaining_task_boundaries`。

### Suggestion

None.

## Rating

- Critical: 0
- Warning: 3
- Non-blocking triaged: 0
- critical_gap: false
- round_type: full
- rationale: 第一輪三個 100-confidence Warning 都是 artifacts 明定 contract 的直接缺口，且在 unseeded first round 全部進入累積 blocking set；必須完成 branch 語意、branch-scoped assertions 與 durable command propagation 後，再由 Reviewer V 驗證。

## Fix Actions

- 修正 bug-fix lifecycle：修改 `.cash-skills/lib/cash_cli/resources.py` 與 `scripts/cash-cli/tests/test_graph_instructions.py`，讓第 1 branch 明定重現、minimal fix、轉綠與保留 regression evidence，並新增同一 branch 內的獨立 assertions。
- 修正 boundary routing 證據：修改 `scripts/cash-cli/tests/test_graph_instructions.py`，解析恰好四個 numbered branches、驗證順序，並將兩個 boundary cases、命名 verification target、checker allowance 與 no-red assertions 綁定第 4 branch。
- 回填實際驗證機制：修改 `design.md`、`specs/cash-cli/spec.md` 與 `tasks.md`，把所有 resource contract test commands 同步為 `PYTHONPATH=.cash-skills/lib python3 scripts/cash-cli/tests/test_graph_instructions.py`；completed checkbox 維持 `[x]`。
- managed runtime bytes 修改後重新執行 `./install-cash-skills.fish --self`；Cash launcher、source receipt 與 bundle-history 驗證通過。
- 修正後重新執行 12 個 resource tests、`tdd-discipline`、variant parity、145 個 CLI tests、94 個 skill tests、bundle version history、Cash validation、comment／separator lint、identifier cross-grep 與 `git diff --check`，全部通過。
- 已以 Cash touched tracking 記錄 `.cash-skills/lib/cash_cli/resources.py` 與 `scripts/cash-cli/tests/test_graph_instructions.py`。

## Decision

next_round
