# Cash Apply Review — Round 2

## Reviewer Findings

### Critical

無。

### Warning

1. `severity`: Warning；`confidence`: 100；`layer`: design；`location`: `scripts/cash-skills/tests/skill-checks.fish:592-600`；`summary`: version literal occurrence inventory 的 actual 與 expected 使用兩個未檢查狀態的 `sort` pipelines；若兩邊同時 execution failure 且無輸出，空集合比較會偽裝成成功；`recommendation`: 分別檢查兩個 pipeline 的完整 status，再進行 deterministic comparison，並加入 hostile `sort` fixture；`disposition`: fix-introduced；`introduced_by`: Round 1 W2 fix 新增 `check_version_literal_occurrence_inventory` 時加入兩個未檢查狀態的 paired `sort` pipelines；reviewer source: Reviewer V — Verification。

### Suggestion

無。

## Rating

- post-filter cumulative blocking Critical: 0
- post-filter cumulative blocking Warning: 1
- non-blocking triaged findings: 0
- `critical_gap`: false
- `round_type`: micro
- rationale: Reviewer V 明確確認 Round 1 的 W1、W2、W3 與 patch fixture 均 resolved，因此三者由 cumulative blocking set 移除；但 W2 fix 直接引入 confidence 100 的 execution-error masking，`disposition: fix-introduced`，故仍有一個 blocking Warning。

## Fix Actions

- Layer correction：Reviewer V 回傳 `layer: test`，不符合 gate schema 且修正會影響 regression gate 行為；主 agent 依規則更正為 `layer: design`。
- 修改 `scripts/cash-skills/tests/skill-checks.fish`：兩個 `command sort` pipeline 各自立即保存並驗證 `$pipestatus`，任何 producer 或 sort error 都回傳 failure，不再比較空輸出。
- 修改 `scripts/cash-skills/tests/skill-checks.fish`：加入恢復為 compliant occurrence 後再以 PATH stub 讓 `sort` exit 78 的 fixture，證明 execution error 不會被誤判為 inventory pass。
- Post-fix mechanical self-check 與 validation：delta comments 0/0、8 requirements、44 scenarios、8/8 tasks、Fish syntax、`git diff --check`、`spectra validate add-versioned-cash-skill-batch-update` 全部通過。
- Post-fix test：`fish --no-config scripts/cash-skills/tests/skill-checks.fish` 通過。

## Decision

next_round
