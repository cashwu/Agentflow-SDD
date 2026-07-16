---
id: ungoverned-exit-path
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-16
last_seen: 2026-07-16
links:
  - openspec/changes/converge-plus-review-loop/reviews/propose-r1.md
---

# Ungoverned exit path

A change adds a fallback or escape route for a gated obligation, but the fallback routes around the governance (consent, seeding, tracing) that the primary path enforces — creating an unconsented exit precisely where the gate matters most. The fix is routing fallbacks to the bucket that preserves the obligation, never to the one that discharges it.

## Occurrences

- 2026-07-16 — converge-plus-review-loop — spectra-propose-plus round 4 — 「無法取得同意時退回 signals 桶」讓 blocking finding 經無同意路徑離開 change 義務且不進 re-run 種子，形成第三出口；修正為退回義務桶（bucket 1）。
