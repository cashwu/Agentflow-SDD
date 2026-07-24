---
id: diagnostic-requires-validation-reorder
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-24
last_seen: 2026-07-24
links:
  - openspec/changes/guard-target-receipt-version-control/reviews/propose-r1.md
---

# Diagnostic requires validation reorder

Making a failure diagnostic actionable would require moving a detection step ahead of the integrity validation that currently gates it, inverting a security-critical ordering so that unvalidated state drives external probing.

## Occurrences

- 2026-07-24 — guard-target-receipt-version-control — cash-propose round 1 — 要讓 installed target 的 `bootstrap_invalid` 帶補救指示，必須把含 git subprocess 與大量 lstat 的 layout 偵測提前到 stable identity 驗證之前。
