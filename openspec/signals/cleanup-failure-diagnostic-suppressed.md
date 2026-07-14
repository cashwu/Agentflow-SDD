---
id: cleanup-failure-diagnostic-suppressed
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-14
last_seen: 2026-07-14
links:
  - openspec/changes/repair-all-uses-pinned-commit-inputs/reviews/apply-r1.md
  - openspec/changes/repair-all-uses-pinned-commit-inputs/reviews/apply-r2.md
---

# Cleanup failure diagnostic suppressed

A resource cleanup path returns failure but suppresses or omits its diagnostic, so operators see a non-zero result without the owned resource path or cleanup cause needed to recover safely.

## Occurrences

- 2026-07-14 — repair-all-uses-pinned-commit-inputs — spectra-apply-plus rounds 1-2 — explicit snapshot cleanup initially returned non-zero silently, and the first fix did not propagate to fish-exit cleanup after shared handled failures.
