---
id: post-preflight-snapshot-revalidation-missing
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-22
last_seen: 2026-07-22
links:
  - openspec/changes/migrate-cash-project-guidance/reviews/propose-r1.md
---

# Post-preflight snapshot revalidation missing

A mutating workflow builds replacement content from a preflight snapshot but does not revalidate the destination bytes before publication, allowing a concurrent edit to be overwritten even when the final replace itself is atomic.

## Occurrences

- 2026-07-22 — migrate-cash-project-guidance — cash-propose round 1 — Guidance migration可能以舊snapshot覆蓋preflight後的新project content；補上temporary creation與atomic publish前的完整bytes revalidation及lost-update fixtures。
