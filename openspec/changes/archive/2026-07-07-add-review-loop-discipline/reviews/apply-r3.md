# Apply Plus Review — Round 3

## Reviewer Findings

### Critical

無。

### Warning

1. `severity`: Warning
   `confidence`: 100
   `layer`: design
   `location`: `scripts/spectra-plus/tests/generator-checks.fish:181-187`; requirement at `openspec/changes/add-review-loop-discipline/specs/spectra-plus-skills/spec.md:5,31-35`; task at `openspec/changes/add-review-loop-discipline/tasks.md:18`
   `summary`: Generator checks do not assert the full literal protected path set because `.spectra.yaml` and `openspec/specs/` are omitted.
   `recommendation`: Add assertions for `.spectra.yaml` and `openspec/specs/` inside the all-output generator check loop.
   Reviewer: B

### Suggestion

1. `severity`: Suggestion
   `confidence`: 75
   `layer`: design
   `location`: `scripts/spectra-plus/tests/generator-checks.fish:151-200`; `scripts/spectra-plus/rules.yaml:36-37,78-79`
   `summary`: The narrowed Codex substitution is not positively locked by tests.
   `recommendation`: Add Codex-output assertions that representative slash commands convert to `$spectra-*` and that backticked `/spectra-` commands are absent.
   Reviewer: B

## Rating

- surviving `Critical` count: 0
- surviving `Warning` count: 1
- `critical_gap`: false
- `round_type`: full

Round 3 有一個 confidence 100 的 design-layer Warning 存活，因此依機械決策規則必須進入下一輪；Suggestion 不影響決策，但已在同一測試區塊一併修復。

## Fix Actions

- Modified `scripts/spectra-plus/tests/generator-checks.fish`: added all-output assertions for `.spectra.yaml` and `openspec/specs/`, completing the literal protected path set coverage.
- Modified `scripts/spectra-plus/tests/generator-checks.fish`: added Codex-output positive assertions for `$spectra-propose`, `$spectra-apply`, and `$spectra-ingest`, plus negative assertions for backticked `/spectra-` commands.
- Re-ran `fish scripts/spectra-plus/tests/generator-checks.fish`; exit 0.
- Re-ran `spectra validate "add-review-loop-discipline"`; exit 0.
- Re-ran `spectra analyze add-review-loop-discipline --json`; only the existing two Suggestion findings remained.
- Re-ran quick grep confirming the new `.spectra.yaml`, `openspec/specs/`, `$spectra-*`, and `` `/spectra-`` assertions are present.
- Re-derivation note: the fix modified an implementation test file and addressed a design-layer Warning, so the next round remains `full`.

## Decision

next_round
