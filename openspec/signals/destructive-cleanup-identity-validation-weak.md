---
id: destructive-cleanup-identity-validation-weak
type: recurring-finding
status: open
occurrences: 3
first_seen: 2026-07-18
last_seen: 2026-07-23
links:
  - openspec/changes/add-versioned-cash-skill-batch-update/reviews/apply-r6.md
  - openspec/changes/replace-spectra-cli-with-cash-cli/reviews/propose-r1.md
  - openspec/changes/replace-spectra-cli-with-cash-cli/reviews/propose-r7.md
---

# Destructive cleanup identity validation weak

A cleanup path permanently removes legacy content after checking only a partial or ambiguous identity marker, so malformed or user-owned content can be mistaken for a managed artifact. Destructive cleanup must require a complete, unique identity and fail closed on unknown shape or metadata.

## Occurrences

- 2026-07-18 — add-versioned-cash-skill-batch-update — cash-apply round 6 — retired-plus cleanup initially matched only the first two `SKILL.md` lines; it now requires an exact one-file shape, closed frontmatter, and exactly one matching `name`, with malformed and conflicting fixtures preserved unchanged.
- 2026-07-23 — replace-spectra-cli-with-cash-cli — cash-propose round 1 — 標準`spectra-*`移除原先只靠directory名稱；修正為versioned full-body digest、one-file shape、mode/hard-link/symlink/extra-content全數fail closed。
- 2026-07-23 — replace-spectra-cli-with-cash-cli — cash-propose round 7 — legacy touched cleanup原先只記錄path與digest，無法辨識同路徑同內容但不同inode的替換檔；修正為import時保存`st_dev/st_ino`，cleanup以held parent FD、no-follow FD、identity、digest與unlink前pathname revalidation全數相符才可移除。
