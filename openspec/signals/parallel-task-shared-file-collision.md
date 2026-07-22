---
id: parallel-task-shared-file-collision
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-22
last_seen: 2026-07-22
links:
  - openspec/changes/migrate-cash-project-guidance/reviews/propose-r1.md
---

# Parallel task shared-file collision

Tasks marked safe for parallel execution modify the same file, creating avoidable merge conflicts or allowing one task's edits to overwrite another's work.

## Occurrences

- 2026-07-22 — migrate-cash-project-guidance — cash-propose round 1 — Tasks 1.1與1.2都標記`[P]`且都會修改同一個skill-checks.fish；移除平行標記並把共用回歸集中到單一task。
