---
id: repeated-lifecycle-operation-idempotence-undefined
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-23
last_seen: 2026-07-23
links:
  - openspec/changes/replace-spectra-cli-with-cash-cli/reviews/propose-r1.md
---

# Repeated lifecycle operation idempotence undefined

A lifecycle design allows one command to perform an intermediate mutation and a later command to repeat that mutation, but does not define a durable identity manifest, no-op condition, or mismatch failure. The second command can duplicate effects or silently diverge.

## Occurrences

- 2026-07-23 — replace-spectra-cli-with-cash-cli — cash-propose round 1 — `sync`後再`archive`可能重複合併master specs；修正為input/result digest manifest、matching no-op、mismatch fail closed與explicit `--skip-specs`。
