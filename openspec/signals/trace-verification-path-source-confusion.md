---
id: trace-verification-path-source-confusion
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-24
last_seen: 2026-07-24
links:
  - openspec/changes/replace-spectra-cli-with-cash-cli/reviews/apply-r1.md
---

# Trace verification path and source path confusion

A provenance generator treats every path-like token in a task as a verification target, causing source delivery paths to be recorded as test evidence.

## Occurrences

- 2026-07-24 — replace-spectra-cli-with-cash-cli — cash-apply round 1 — `@trace.tests`原先收集tasks內所有含斜線code spans；改為只解析verification clause中的test targets並驗證code/tests不污染。
