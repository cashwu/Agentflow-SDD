---
id: filesystem-boundary-validation-missing
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-18
last_seen: 2026-07-18
links:
  - openspec/changes/fork-spectra-skills-to-cash/reviews/propose-r1.md
---

# Filesystem boundary validation missing

A mutating installer or cleanup accepts a caller-controlled root without first canonicalizing it, rejecting unsafe roots and symlink boundaries, and proving every managed path remains inside the intended root.

## Occurrences

- 2026-07-18 — fork-spectra-skills-to-cash — spectra-propose-plus round 1 — installer/cleanup 初稿未處理 `/`、unsafe HOME、symlink 與 containment escape；補上所有 mutation/launchctl 前的 fail-closed preflight 與零寫入 fixtures。
