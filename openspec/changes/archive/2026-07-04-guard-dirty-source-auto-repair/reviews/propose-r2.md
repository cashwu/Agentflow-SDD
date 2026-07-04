# Propose Plus Review — Round 2

## Reviewer Findings

### Critical

- severity: Critical
  confidence: 100
  location: `specs/spectra-plus-skills/spec.md` `Repair-all protects registered targets from dirty source checkout`; `openspec/specs/spectra-plus-skills/spec.md` `Auto-restore stripped commit guard source from git HEAD`
  summary: dirty-source guard 把 `.agents/skills/spectra-*/` 與 `.claude/skills/spectra-*/` dirty state 列為 `--repair-all` skip 條件，但既有 auto-restore requirement 仍要求 `--repair-all` 可以 restore stripped source `spectra-commit/SKILL.md`。
  recommendation: 新增 `MODIFIED Requirements` 明確定義 dirty-source guard 是否優先於 auto-restore，並補 scenario/task。
  reviewer: A

### Warning

- severity: Warning
  confidence: 88
  location: `design.md` `### Guard repair-all with source-sensitive dirty detection`; `tasks.md` `1.1`
  summary: dirty 狀態枚舉漏掉 staged added/copied/typechange/unmerged；若實作只看 modified/deleted/renamed/untracked，staged new source file 可能繞過 guard。
  recommendation: 改成任何 matching `git status --porcelain` entry 都算 dirty，並補 staged added fixture。
  reviewer: B

- severity: Warning
  confidence: 82
  location: `scripts/spectra-plus/repair-all.fish`; `design.md` `## Implementation Contract`; `tasks.md`
  summary: LaunchAgent entrypoint 目前先檢查 `yq` 再呼叫 installer，可能讓 dirty source + missing `yq` 先 exit 1，而不是 dirty-source skip exit 0。
  recommendation: 明確要求 entrypoint 不得在 dirty guard 前做 `yq` preflight，或補 entrypoint 測試覆蓋 dirty source + missing `yq`。
  reviewer: B

### Suggestion

- severity: Suggestion
  confidence: 76
  location: `design.md` `## Implementation Contract`; `install-spectra-plus.fish` `repair_all`
  summary: dirty guard 相對於 lock/throttle 的順序未定義，可能先產生 lock/throttle state side effect。
  recommendation: 明確要求 dirty guard 在 lock/throttle 前執行，並補對應測試。
  reviewer: B

## Rating

Critical count: 1
Warning count: 2
critical_gap: true

Round 2 判定為 `next_round`，因為 auto-restore 與 dirty-source guard 的 precedence 是既有 requirement 與新 requirement 的直接衝突；另外 staged added 與 LaunchAgent missing `yq` 都是會影響背景 repair 安全性的可驗證缺口。lock/throttle ordering 雖為 Suggestion，也已一起修入 contract，避免 dirty skip 產生本機 side effect。

## Fix Actions

- 修改 `design.md`：定義 dirty-source guard 在 dependency preflight、lock/throttle、registry processing、metadata validation、auto-restore 前執行；dirty detection 改為任何 matching `git status --porcelain` entry；entrypoint 不得在 dirty guard 前因 missing `yq` fail。
- 修改 `specs/spectra-plus-skills/spec.md`：新增 auto-restore precedence、lock/throttle ordering、staged added、entrypoint missing `yq` scenarios；新增 `MODIFIED Requirements` 更新 `Auto-restore stripped commit guard source from git HEAD`。
- 修改 `tasks.md`：補 auto-restore precedence、staged added、LaunchAgent entrypoint ordering、lock/throttle no-state verification。
- 重新執行 `spectra validate guard-dirty-source-auto-repair`，結果通過。

## Decision

next_round
