---
id: metadata-validation-allows-invalid-values
type: recurring-finding
status: open
occurrences: 3
first_seen: 2026-07-04
last_seen: 2026-07-24
links:
  - openspec/changes/version-spectra-plus-skills/reviews/apply-r1.md
  - openspec/changes/replace-spectra-cli-with-cash-cli/reviews/propose-r4.md
  - openspec/changes/replace-spectra-cli-with-cash-cli/reviews/apply-r3.md
---

# Metadata validation allows invalid values

An implementation validated metadata field presence or consistency but did not reject invalid scalar values such as `null` or empty strings, allowing malformed metadata to pass into generated artifacts or installer freshness checks.

## Occurrences

- 2026-07-04 — version-spectra-plus-skills — spectra-apply-plus round 1 — Review found `spectraPlusVersion` accepted `null` or empty values instead of enforcing a non-empty string.
- 2026-07-23 — replace-spectra-cli-with-cash-cli — cash-propose rounds 4–5 — Installer起初逐byte保留但不解析existing Cash config，後續受限YAML仍未拒絕unknown legacy scalar/map/list；修正為versioned parser、精確grammar與invalid matrix。
- 2026-07-24 — replace-spectra-cli-with-cash-cli — cash-apply rounds 3–5 — Launcher receipt parser 曾接受非 canonical mode scalar；補上 `0[0-7]{3}` 格式驗證與 malformed stable-mode regression。
