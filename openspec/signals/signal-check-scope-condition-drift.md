---
id: signal-check-scope-condition-drift
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-07
last_seen: 2026-07-07
links:
  - openspec/changes/add-review-loop-discipline/reviews/apply-r1.md
---

# Signal check scope condition drift

When documenting deterministic signal checks, the implementation can drift from the spec by testing the detected instance location where the contract requires testing the location or scope of the fix, changing whether out-of-scope or protected-path failures are handled correctly.

## Occurrences

- 2026-07-07 — add-review-loop-discipline — spectra-apply-plus round 1 — The template initially said to avoid fixing when the detected instance was outside scope or protected, but the spec required avoiding fixes when the instance was pre-existing or the fix would land outside scope or in a grader-protected path.
