---
id: temporary-cleanup-ownership-unproven
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-22
last_seen: 2026-07-22
links:
  - openspec/changes/migrate-cash-project-guidance/reviews/apply-r2.md
---

# Temporary cleanup ownership unproven

A failure cleanup path is armed before exclusive creation proves ownership of its temporary entry, so a name collision can cause cleanup to delete caller-owned or unrelated content.

## Occurrences

- 2026-07-22 — migrate-cash-project-guidance — cash-apply seeded round 1 — Guidance publisher起初在`O_EXCL` create前armed cleanup；現在只在exclusive create成功後取得ownership，collision fixture證明既有同名entry完整保留。
