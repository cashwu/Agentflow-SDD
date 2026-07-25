---
id: acceptance-path-infeasible-in-test-harness
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-25
last_seen: 2026-07-25
links:
  - openspec/changes/align-cli-skill-contracts/reviews/propose-r1.md
---

# Acceptance path infeasible in test harness

An acceptance criterion prescribes exercising the real entry point rather than an internal function, without checking that the entry point can run under the test harness. Launchers that derive their project root from their own location reject a temporary workspace, so the test fails for a reason unrelated to the behavior under test.

## Occurrences

- 2026-07-25 — align-cli-skill-contracts — cash-propose round 4 — 驗收要求以 subprocess 呼叫 repo 自身的 launcher 驗證臨時 workspace 的 stdout，實跑得到 workspace_root_mismatch rc=1；改為先安裝到臨時 workspace 再呼叫其 launcher 並指定 cwd 後成立。
