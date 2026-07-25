---
id: dry-run-bypasses-validation
type: recurring-finding
status: open
occurrences: 2
first_seen: 2026-07-04
last_seen: 2026-07-25
links:
  - openspec/changes/version-spectra-plus-skills/reviews/apply-r1.md
  - openspec/changes/version-spectra-plus-skills/reviews/apply-r2.md
  - openspec/changes/harden-installer-mode-and-recovery/reviews/propose-r4.md

---

# Dry-run path bypasses validation

A dry-run branch returned before shared validation ran, so invalid local source metadata could make a dry-run report success even though the real operation would fail.

## Occurrences

- 2026-07-04 — version-spectra-plus-skills — spectra-apply-plus rounds 1-2 — Review found `--repair-all --dry-run` and `--target --dry-run` paths bypassed local plus metadata validation.

- 2026-07-25 — harden-installer-mode-and-recovery — cash-propose round 4 — dry-run 遇未完成 journal 時的 diagnostic 發出點未定義，且該點位於 conflict 判定之後而永遠不可達；修正為把偵測點前移並要求 diagnostic 與最終分類無關而一律出現。
