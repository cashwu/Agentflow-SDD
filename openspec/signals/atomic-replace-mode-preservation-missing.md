---
id: atomic-replace-mode-preservation-missing
type: recurring-finding
status: open
occurrences: 2
first_seen: 2026-07-22
last_seen: 2026-07-23
links:
  - openspec/changes/migrate-cash-project-guidance/reviews/propose-r1.md
  - openspec/changes/replace-spectra-cli-with-cash-cli/reviews/propose-r1.md
---

# Atomic replace mode preservation missing

An atomic replacement design preserves file contents but leaves POSIX mode behavior undefined, allowing a temporary file's restrictive or permissive mode to become an unrelated metadata regression.

## Occurrences

- 2026-07-22 — migrate-cash-project-guidance — cash-propose round 1 — Guidance atomic replace未定義既有mode preservation；修正為保留既有POSIX mode bits、新檔固定0644，並加入mode fixtures。
- 2026-07-23 — replace-spectra-cli-with-cash-cli — cash-propose round 1 — Project-local launcher雖被安裝，初稿未治理executable mode；修正為launcher `0755`、lock/runtime/skills `0644`並由receipt與direct-execution fixtures驗證。
