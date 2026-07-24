---
id: bootstrap-json-error-contract-bypassed
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-24
last_seen: 2026-07-24
links:
  - openspec/changes/replace-spectra-cli-with-cash-cli/reviews/apply-r1.md
---

# Bootstrap JSON error contract bypassed

A launcher failure that occurs before the managed runtime is imported bypasses the CLI's requested JSON error channel and emits only a human stderr diagnostic.

## Occurrences

- 2026-07-24 — replace-spectra-cli-with-cash-cli — cash-apply round 1 — Receipt、runtime generation與missing-lock bootstrap errors忽略`--json`；launcher改為stdout單一error object並補精確tests。
