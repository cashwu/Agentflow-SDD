# Apply Plus Review — Round 1

## Reviewer Findings

### Critical

（無。）

### Warning

- severity: Warning | confidence: 100 | layer: design | reviewer: A
  - location: `openspec/specs/signals-shared-layer/spec.md:73`；required by `openspec/changes/tighten-review-loop-edge-cases/specs/signals-shared-layer/spec.md:51`
  - summary: master `signals-shared-layer` spec 已更新 canonical `check` example，但其 `Signals directory README contract` master requirement 尚未同步新增 path-output 與 shell-trap clauses。
  - recommendation: 同步 master spec 的 README requirement 與 scenario，加入 project-root-relative path output requirement、POSIX `sh` / pipeline / native-exit-code remapping guidance。
- severity: Warning | confidence: 100 | layer: design | reviewer: A+B
  - location: `scripts/spectra-plus/tests/generator-checks.fish:290`；required by `openspec/changes/tighten-review-loop-edge-cases/tasks.md:15`
  - summary: task 3.1 要求四份 generated plus skill 的 byte-identical regeneration coverage，但 idempotence check 只 snapshot/diff 兩份 `.claude` outputs。
  - recommendation: 改為比較 `$all_outputs` 的 before/after fingerprint，或 copy/diff 四份 generated skill files。
- severity: Warning | confidence: 85 | layer: design | reviewer: B
  - location: `openspec/specs/signals-shared-layer/spec.md:49`、`openspec/changes/tighten-review-loop-edge-cases/proposal.md:39`、`openspec/changes/tighten-review-loop-edge-cases/tasks.md:11`
  - summary: implementation 修改 `openspec/specs/signals-shared-layer/spec.md` 這個 protected master spec path，但 structured delivery scope 未在 affected-code 或 task delivery target 中明確命名該 project-root-relative path，重現本 change 要防止的 declared-scope drift。
  - recommendation: 明確把 `openspec/specs/signals-shared-layer/spec.md` 加入 delivery target，或移除直接 master-spec 修改與測試耦合，等 archive sync。

### Suggestion

（無。）

## Rating

- surviving Critical count: 0
- surviving Warning count: 3
- critical_gap: false
- round_type: full
- rationale: Reviewer A 與 Reviewer B 均未提出 Critical。三筆 Warning 均通過 confidence filter，其中 idempotence coverage finding 由 A+B 獨立指出，另有 master spec README contract 同步缺口與 master spec scope declaration drift。依機械決策，任何 surviving Warning 都要求 `next_round`。

## Fix Actions

- Modified `openspec/specs/signals-shared-layer/spec.md`: 同步 `Signals directory README contract` master requirement 與 scenario，補入 path-output guidance、POSIX `sh` pipeline status 與 native exit code `1` remapping guidance。
- Modified `openspec/changes/tighten-review-loop-edge-cases/proposal.md`: 在 `## Impact` affected-code entries 明確列入 `openspec/specs/signals-shared-layer/spec.md`，消除 protected master spec scope drift。
- Modified `openspec/changes/tighten-review-loop-edge-cases/tasks.md`: 將 task 2.2 的 delivery target 明確寫成 `openspec/specs/signals-shared-layer/spec.md`。
- Modified `scripts/spectra-plus/tests/generator-checks.fish`: 將 idempotence check 改為比較 `output_fingerprint` before/after full `generate.fish`，涵蓋 `$all_outputs` 四份 generated plus skill files。
- Re-ran `spectra validate "tighten-review-loop-edge-cases"`; exit 0.
- Re-ran `spectra analyze tighten-review-loop-edge-cases --json`; all dimensions Clean.
- Re-ran `fish scripts/spectra-plus/tests/generator-checks.fish`; exit 0.

## Decision

next_round
