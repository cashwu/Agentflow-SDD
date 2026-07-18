---
id: implementation-notes-protocol-drift
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-18
last_seen: 2026-07-18
links:
  - openspec/changes/add-versioned-cash-skill-batch-update/reviews/apply-r4.md
---

# Implementation notes protocol drift

An implementation-notes artifact contains free-form commentary that does not match the workflow's allowed deviation or open-question record format. This makes stale context look like a governed exception and weakens the review gate's ability to distinguish intentional deviations from obsolete notes.

## Occurrences

- 2026-07-18 — add-versioned-cash-skill-batch-update — cash-apply round 4 — implementation notes 保留不符合 deviation/open-question protocol 的自由文字 bullet，且仍引用已移除的 updater；移除該 bullet，只保留 initialized header。
