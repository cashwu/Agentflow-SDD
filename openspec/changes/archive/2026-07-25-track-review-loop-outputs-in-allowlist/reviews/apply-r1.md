# Cash Apply Review — Round 1

## Reviewer Findings

### Critical

無。

### Warning

1. 
   - severity: Warning
   - confidence: 100
   - layer: design
   - location: `.cash-skills/lib/cash_cli/commands/tasks.py` 的 `touched record` 合併邏輯
   - summary: 對完整 `touched` entries 依 UTF-8 task id 排序，會把既有 `1, 2, …, 10` 改成 `1, 10, 2, …`，違反 C1 不得改動既有 per-task 條目與 attribution 順序的要求。
   - recommendation: 保留所有既有 per-task entries 的原始順序；既有 `review-loop` entry 在原位置更新，不存在時才附加，並增加兩位數 task id regression test。
   - reviewer source: Reviewer A — Adherence

2. 
   - severity: Warning
   - confidence: 100
   - layer: design
   - location: `.cash-skills/lib/cash_cli/commands/tasks.py` 的 record path 驗證與持久化流程
   - summary: `Workspace.path_kind()` 會正規化路徑後確認檔案存在，但實作持久化原始字串，使 `./openspec/signals/demo.md` 或 `openspec//signals/demo.md` 成功寫入後仍無法匹配 git canonical path。
   - recommendation: 驗證、前綴判定與持久化皆使用 canonical project-root-relative path，並增加兩種 alias 的 regression test。
   - reviewer source: Reviewer B — Quality
   - introduced_by: `.cash-skills/lib/cash_cli/commands/tasks.py` 新增的 record path 驗證／持久化流程

### Suggestion

無。

## Rating

- post-filter cumulative blocking Critical: 0
- post-filter cumulative blocking Warning: 2
- non-blocking triaged findings: 0
- critical_gap: false
- round_type: full

兩項 confidence 100 的 Warning 都直接違反 C1，已進入 cumulative blocking set；本輪必須為 `next_round`，待 fresh Reviewer V 驗證修復有效後才能移除。

## Fix Actions

- 修正 `.cash-skills/lib/cash_cli/commands/tasks.py`：移除完整 entries 的重新排序；改為在原位置更新既有 `review-loop` entry，或在不存在時附加，保留所有 per-task entries 的原始順序。
- 修正 `.cash-skills/lib/cash_cli/commands/tasks.py`：以 `Path(path).as_posix()` 得到的 canonical project-root-relative path 執行前綴檢查、`path_kind()` 與持久化，避免成功記錄無法匹配 git status 的 alias。
- 修正 `scripts/cash-cli/tests/test_creation_task_lifecycle.py`：新增兩位數 task id 順序保持測試，以及 `./...`／重複 `/` alias 正規化測試；紅燈為 2 個 failure，修正後 20/20 通過。
- 因 runtime 檔變更，執行 `./install-cash-skills.fish --self` 重建 receipt；`.cash-skills/bin/cash validate --all` 通過。
- 執行 `scripts/cash-cli/tests/cli-checks.fish all`：116 tests 全數通過。
- Post-fix mechanical self-check 通過：annotation、title identity、count consistency、identifier cross-grep、open signal checks 與 `git diff --check` 均無問題。

## Decision

next_round
