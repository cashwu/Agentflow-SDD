---
id: generated-output-idempotence-coverage-gap
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-07
last_seen: 2026-07-07
links:
  - openspec/changes/tighten-review-loop-edge-cases/reviews/apply-r1.md
---

# Generated output idempotence coverage gap

A generator idempotence test claims to protect all generated outputs but snapshots or diffs only a subset of those outputs, allowing one generated variant to drift while the test still passes.

## Occurrences

- 2026-07-07 — tighten-review-loop-edge-cases — spectra-apply-plus round 1 — `scripts/spectra-plus/tests/generator-checks.fish` task 3.1 required byte-identical regeneration for four plus skill outputs, but the test initially diffed only the two `.claude` outputs and missed the `.agents` variants.
