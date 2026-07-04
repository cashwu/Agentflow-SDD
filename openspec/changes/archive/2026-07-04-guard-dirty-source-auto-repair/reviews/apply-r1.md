# Apply Plus Review — Round 1

## Reviewer Findings

### Critical

None.

### Warning

- severity: Warning
  confidence: 100
  location: scripts/spectra-plus/tests/repair-all-checks.fish:396
  summary: 缺少必要的 copied source-sensitive porcelain 測試；matrix 已覆蓋 renamed、typechange、unmerged、deleted、staged、untracked，但沒有 copied entry。
  recommendation: 新增 dirty-source skip 測試，讓 fixture 的 `git status --porcelain` 產生 copied source-sensitive path，並驗證不修改 target、不建立 lock、不寫 throttle。
  reviewer: B

### Suggestion

None.

## Rating

- Critical: 0
- Warning: 1
- critical_gap: false

Round 1 未通過，因為 confidence 100 的 Warning 直接指出 `tasks.md` 1.2 的 copied/typechange matrix 覆蓋缺口；雖然實作本身攔截 copied-style paths 的機率高，但約定的驗證案例仍缺一個 copied entry。

## Fix Actions

- 已修改 `scripts/spectra-plus/tests/repair-all-checks.fish`：新增 `git status --porcelain` stub helper，覆蓋 copied source-sensitive entry 會 dirty-source skip，並覆蓋 copied unrelated entry 不會誤觸 dirty-source guard。
- 驗證目標：重跑 `fish scripts/spectra-plus/tests/repair-all-checks.fish`。

## Decision

next_round
