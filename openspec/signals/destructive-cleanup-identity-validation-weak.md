---
id: destructive-cleanup-identity-validation-weak
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-18
last_seen: 2026-07-18
links:
  - openspec/changes/add-versioned-cash-skill-batch-update/reviews/apply-r6.md
---

# Destructive cleanup identity validation weak

A cleanup path permanently removes legacy content after checking only a partial or ambiguous identity marker, so malformed or user-owned content can be mistaken for a managed artifact. Destructive cleanup must require a complete, unique identity and fail closed on unknown shape or metadata.

## Occurrences

- 2026-07-18 — add-versioned-cash-skill-batch-update — cash-apply round 6 — retired-plus cleanup initially matched only the first two `SKILL.md` lines; it now requires an exact one-file shape, closed frontmatter, and exactly one matching `name`, with malformed and conflicting fixtures preserved unchanged.
