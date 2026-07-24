---
id: bundle-history-binding-missing
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-24
last_seen: 2026-07-24
links:
  - openspec/changes/replace-spectra-cli-with-cash-cli/reviews/apply-r1.md
---

# Bundle history binding missing

A versioned bundle test checks only the current version literal and does not bind same-version inventory, bytes, or modes to the version's first-parent introduction commit.

## Occurrences

- 2026-07-24 — replace-spectra-cli-with-cash-cli — cash-apply round 1 — Skill suite只硬編碼`2.0.0`；新增first-parent history checker，覆蓋same-version bytes/mode/inventory drift、stable bootstrap drift與合法SemVer bump。
