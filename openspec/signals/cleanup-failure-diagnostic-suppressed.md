---
id: cleanup-failure-diagnostic-suppressed
type: recurring-finding
status: open
occurrences: 2
first_seen: 2026-07-14
last_seen: 2026-07-22
links:
  - openspec/changes/repair-all-uses-pinned-commit-inputs/reviews/apply-r1.md
  - openspec/changes/repair-all-uses-pinned-commit-inputs/reviews/apply-r2.md
  - openspec/changes/migrate-cash-project-guidance/reviews/apply-r2.md
---

# Cleanup failure diagnostic suppressed

A resource cleanup path returns failure but suppresses or omits its diagnostic, so operators see a non-zero result without the owned resource path or cleanup cause needed to recover safely.

## Occurrences

- 2026-07-14 — repair-all-uses-pinned-commit-inputs — spectra-apply-plus rounds 1-2 — explicit snapshot cleanup initially returned non-zero silently, and the first fix did not propagate to fish-exit cleanup after shared handled failures.
- 2026-07-22 — migrate-cash-project-guidance — cash-apply seeded round 1 — Anchored publisher的`END` cleanup起初忽略relative `unlink`結果；現在保留原始nonzero failure並輸出temporary basename與系統原因。
