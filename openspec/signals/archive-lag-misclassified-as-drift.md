---
id: archive-lag-misclassified-as-drift
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-08
last_seen: 2026-07-08
links:
  - openspec/changes/tighten-review-loop-edge-cases/reviews/apply-r1.md
---

# Archive lag misclassified as drift

Review loop findings treat expected master-spec lag before archive as cross-artifact drift, pressuring apply loops to synchronize protected master specs before the archive step. Delta specs are allowed to differ from master specs until archive applies the change.

## Occurrences

- 2026-07-08 — tighten-review-loop-edge-cases — post-apply review — A round 1 warning treated the master `Signals directory README contract` lagging the change delta as a defect after a related master canonical check example had already been updated. The implementation safely backfilled scope and synchronized master text, but the underlying process issue is that expected archive-time sync can be mistaken for drift.
