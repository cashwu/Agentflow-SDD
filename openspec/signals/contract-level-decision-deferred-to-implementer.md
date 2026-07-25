---
id: contract-level-decision-deferred-to-implementer
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-25
last_seen: 2026-07-25
links:
  - openspec/changes/align-cli-skill-contracts/reviews/propose-r1.md
---

# Contract-level decision deferred to implementer

A design names a mechanism to change but leaves the semantics of the replacement undefined, so the implementer must make a contract-level decision mid-task. The acceptance criterion is written as the absence of the old defect rather than the presence of the newly defined behavior, which lets any replacement pass.

## Occurrences

- 2026-07-25 — align-cli-skill-contracts — cash-propose round 1 — design 要求改寫 Codex 變體被剝空的 plan 檔敘述，但未定義無 plan 目錄環境下引數的解析語意；驗收只斷言不存在空 code span，無法證明改寫後語意完整。
