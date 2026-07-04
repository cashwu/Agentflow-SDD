---
id: dry-run-bypasses-validation
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-04
last_seen: 2026-07-04
links:
  - openspec/changes/version-spectra-plus-skills/reviews/apply-r1.md
  - openspec/changes/version-spectra-plus-skills/reviews/apply-r2.md
---

# Dry-run path bypasses validation

A dry-run branch returned before shared validation ran, so invalid local source metadata could make a dry-run report success even though the real operation would fail.

## Occurrences

- 2026-07-04 — version-spectra-plus-skills — spectra-apply-plus rounds 1-2 — Review found `--repair-all --dry-run` and `--target --dry-run` paths bypassed local plus metadata validation.
