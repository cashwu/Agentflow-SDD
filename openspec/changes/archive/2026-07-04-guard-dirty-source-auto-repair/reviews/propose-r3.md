# Propose Plus Review — Round 3

## Reviewer Findings

### Critical

- severity: Critical
  confidence: 95
  location: `specs/spectra-plus-skills/spec.md` `Repair-all skips before local metadata validation`; `openspec/specs/spectra-plus-skills/spec.md` `Repair checks plus metadata freshness`
  summary: dirty invalid `scripts/spectra-plus/rules.yaml` scenario 要求 `--repair-all` skip exit 0，但既有 metadata freshness requirement 仍無條件要求 local rules metadata parse failure non-zero abort。
  recommendation: 新增 `MODIFIED Requirements` 更新 `Repair checks plus metadata freshness`，明確限定 metadata parse failure abort 只在 source-sensitive paths clean 時適用。
  reviewer: A

- severity: Critical
  confidence: 90
  location: `specs/spectra-plus-skills/spec.md` `Repair-all dry-run skips when source-sensitive files are dirty`; `openspec/specs/spectra-plus-skills/spec.md` `Repair all registered plus skill targets`
  summary: dirty dry-run scenario 要求只輸出 dirty-source skip，但既有 dry-run repair-all scenario 仍無條件要求列出 per-target repair actions。
  recommendation: 新增 `MODIFIED Requirements` 更新 `Repair all registered plus skill targets`，將 dry-run per-target action listing 限定為 source-sensitive paths clean。
  reviewer: A

### Warning

- severity: Warning
  confidence: 90
  location: `tasks.md`; `scripts/spectra-plus/tests/repair-all-checks.fish`
  summary: 測試計畫未要求隔離 source checkout；實作此 change 時目前工作樹會 dirty，既有 normal repair-all tests 可能被 dirty guard 提早 skip，導致 clean path 沒被驗證。
  recommendation: 要求 `repair-all-checks.fish` normal cases 使用 clean temporary source fixture，dirty-source cases 在 fixture 中刻意製造 dirty state。
  reviewer: B

- severity: Warning
  confidence: 85
  location: `specs/spectra-plus-skills/spec.md` `Repair-all skips before lock and throttle state`; `openspec/specs/spectra-plus-skills/spec.md` `LaunchAgent-based automatic plus skill repair`
  summary: dirty-source skip 要早於 lock/throttle state，但 acceptance 只驗證不 create/write，未明確排除既有 throttle state 造成 throttle decision。
  recommendation: 新增 scenario 與 modified LaunchAgent requirement，明確 dirty-source skip 優先於既有 throttle decision，且不改寫 throttle state。
  reviewer: A

- severity: Warning
  confidence: 85
  location: `design.md` dirty detection contract; `tasks.md` `1.1`
  summary: dirty detection contract 涵蓋任何 `git status --porcelain` entry，但 task 只明確覆蓋 staged modified/staged added，對 delete/rename/copy/typechange/unmerged 的驗證不足。
  recommendation: 補 task/test 覆蓋 deleted、renamed、copied/typechange、unmerged parser fixture，並確認 unrelated rename 不阻擋。
  reviewer: A+B

### Suggestion

- severity: Suggestion
  confidence: 65
  location: `design.md` dirty detection contract; `specs/spectra-plus-skills/spec.md`
  summary: artifacts 未定義 `git status --porcelain` 無法執行時的行為。
  recommendation: 明確定義自動 `--repair-all` 在無法判定 source dirty state 時的行為，或將其標為 Non-Goal。
  reviewer: B

## Rating

Critical count: 2
Warning count: 3
critical_gap: true

Round 3 判定為 `next_round`，因為新 dirty-source guard 對既有 metadata fail-loud、dry-run repair-all、throttle behavior 都形成 precedence exception，但 spec 尚未用 `MODIFIED Requirements` 明確調整既有 requirement。測試隔離與 porcelain 狀態矩陣也是實作可驗性缺口，必須在 tasks 補齊。

## Fix Actions

- 修改 `specs/spectra-plus-skills/spec.md`：新增 `MODIFIED Requirements` for `Repair all registered plus skill targets`、`LaunchAgent-based automatic plus skill repair`、`Repair checks plus metadata freshness`，把 source-sensitive clean 與 dirty-source skip precedence 套進既有 scenarios。
- 修改 `design.md`：要求測試使用 clean temporary source fixture；補 lock/throttle precedence 與更完整 porcelain entry 測試範圍。
- 修改 `tasks.md`：新增 clean source fixture harness task；補 dirty-source path matrix 的 deleted/renamed/copied/typechange/unmerged parser fixture；補既有 throttle state 不產生 throttle decision 的驗證。
- 重新執行 `spectra validate guard-dirty-source-auto-repair`，結果通過。

## Decision

next_round
