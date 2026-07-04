---
id: metadata-validation-allows-invalid-values
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-04
last_seen: 2026-07-04
links:
  - openspec/changes/version-spectra-plus-skills/reviews/apply-r1.md
---

# Metadata validation allows invalid values

An implementation validated metadata field presence or consistency but did not reject invalid scalar values such as `null` or empty strings, allowing malformed metadata to pass into generated artifacts or installer freshness checks.

## Occurrences

- 2026-07-04 — version-spectra-plus-skills — spectra-apply-plus round 1 — Review found `spectraPlusVersion` accepted `null` or empty values instead of enforcing a non-empty string.
