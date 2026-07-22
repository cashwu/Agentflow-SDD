# Cash Apply Review — Round 4

## Reviewer Findings

### Critical

None.

### Warning

- severity: Warning
  confidence: 100
  layer: design
  location: `scripts/cash-skills/tests/skill-checks.fish:609-620`; `openspec/changes/migrate-cash-project-guidance/tasks.md:41`; `openspec/changes/migrate-cash-project-guidance/design.md:116`
  summary: 新增的source malformed fixture只證明installer非零結束，沒有斷言task與Implementation Contract明定的精確code 1；code 2、其他exit code或signal termination都可能通過。
  recommendation: 執行installer後立即保存`$status`並明確斷言等於`1`，再保留既有無`Result:`與target tree逐byte不變檢查。
  reviewer source: Reviewer A — Adherence；Reviewer B — Quality

- severity: Warning
  confidence: 95
  layer: design
  location: `scripts/cash-skills/tests/skill-checks.fish:645-650`
  summary: Dry-run cleanup fixture比較整個共享system temp namespace的before/after集合，未證明temporary paths屬於本次installer；同步執行的installer可能造成非決定性false failure，且pipeline狀態未被檢查。
  recommendation: 以test-local `mktemp` PATH shim代理真實`mktemp`並記錄本次process建立的guidance snapshot paths，process結束後逐一斷言不存在。
  reviewer source: Reviewer B — Quality

### Suggestion

None.

## Rating

- post-filter cumulative blocking set Critical: 0
- post-filter cumulative blocking set Warning: 2
- non-blocking triaged finding count: 0
- `critical_gap: false`
- `round_type: full`
- rationale: 本次run第一個full round的兩項Warning皆為blocking；必須補齊精確exit code與per-invocation temporary ownership證據後進入micro verification。

## Fix Actions

- 修改`scripts/cash-skills/tests/skill-checks.fish`：source malformed fixture保存installer `$status`並精確斷言code 1。
- 修改`scripts/cash-skills/tests/skill-checks.fish`：以test-local `mktemp` PATH shim記錄本次dry-run建立的四個guidance snapshot paths，逐一驗證process exit後不存在，移除共享system temp集合比較與pipeline依賴。
- 修改`openspec/changes/migrate-cash-project-guidance/tasks.md`：同步task 7.1的精確code 1與per-invocation snapshot ownership驗證描述。
- Post-fix verification：targeted marker/boundary matrices、`fish scripts/cash-skills/tests/skill-checks.fish`、`fish -n scripts/cash-skills/tests/skill-checks.fish`、`spectra analyze migrate-cash-project-guidance --json`及`spectra validate migrate-cash-project-guidance`全數通過；system temp無snapshot遺留。
- Post-fix mechanical self-check：delta comment counts平衡、numeric claims與22/22 tasks一致、identifier與artifact描述已同步；沒有open signal `check` command需執行。

## Decision

next_round
