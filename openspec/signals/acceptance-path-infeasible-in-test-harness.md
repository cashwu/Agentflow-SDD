---
id: acceptance-path-infeasible-in-test-harness
type: recurring-finding
status: open
occurrences: 2
first_seen: 2026-07-25
last_seen: 2026-09-05
links:
  - openspec/changes/align-cli-skill-contracts/reviews/propose-r1.md
  - openspec/changes/dispatch-vendored-targets-in-batch/reviews/propose-r2.md
  - openspec/changes/dispatch-vendored-targets-in-batch/reviews/propose-r5.md
---

# Acceptance path infeasible in test harness

An acceptance criterion prescribes exercising the real entry point rather than an internal function, without checking that the entry point can run under the test harness. Launchers that derive their project root from their own location reject a temporary workspace, so the test fails for a reason unrelated to the behavior under test.

## Occurrences

- 2026-07-25 — align-cli-skill-contracts — cash-propose round 4 — 驗收要求以 subprocess 呼叫 repo 自身的 launcher 驗證臨時 workspace 的 stdout，實跑得到 workspace_root_mismatch rc=1；改為先安裝到臨時 workspace 再呼叫其 launcher 並指定 cwd 後成立。
- 2026-09-05 — dispatch-vendored-targets-in-batch — cash-propose rounds 2、5 — round 2：task 要求驗證「manifest 在 probe 之後、分類之前消失」，但測試全以 subprocess 執行 installer，唯一的 hold hook 位在分類之後，該狀態無法製造；改以 in-process import 直接對帶 batch-only 參數的入口斷言。round 5：改寫後的版本 bump 驗證用 `rg -o '(?<=^BUNDLE_VERSION = ")[0-9.]+'`，ripgrep 預設 Rust regex 引擎不支援 look-around，實跑 exit 2 使指令替換為空字串、比較恆為假。教訓是驗收指令本身也要實際跑過一次。
