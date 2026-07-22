---
id: filesystem-boundary-validation-missing
type: recurring-finding
status: open
occurrences: 7
first_seen: 2026-07-18
last_seen: 2026-07-22
links:
  - openspec/changes/fork-spectra-skills-to-cash/reviews/propose-r1.md
  - openspec/changes/add-versioned-cash-skill-batch-update/reviews/apply-r1.md
  - openspec/changes/add-versioned-cash-skill-batch-update/reviews/apply-r4.md
  - openspec/changes/add-versioned-cash-skill-batch-update/reviews/apply-r6.md
  - openspec/changes/add-versioned-cash-skill-batch-update/reviews/apply-r7.md
  - openspec/changes/migrate-cash-project-guidance/reviews/propose-r1.md
  - openspec/changes/migrate-cash-project-guidance/reviews/apply-r1.md
  - openspec/changes/migrate-cash-project-guidance/reviews/apply-r2.md
---

# Filesystem boundary validation missing

A mutating installer or cleanup accepts a caller-controlled root without first canonicalizing it, rejecting unsafe roots and symlink boundaries, and proving every managed path remains inside the intended root.

## Occurrences

- 2026-07-18 — fork-spectra-skills-to-cash — spectra-propose-plus round 1 — installer/cleanup 初稿未處理 `/`、unsafe HOME、symlink 與 containment escape；補上所有 mutation/launchctl 前的 fail-closed preflight 與零寫入 fixtures。
- 2026-07-18 — add-versioned-cash-skill-batch-update — cash-apply round 1 — existing receipt update 未在 managed writes 前驗證 receipt directory 的 atomic-replace 權限；補上 directory write/execute preflight 與零 target-write fixture。
- 2026-07-18 — add-versioned-cash-skill-batch-update — cash-apply round 4 — receipt-clean destination 若為 hard link，in-place `cp` 會改寫專案外 inode；改為 target directory 內的受控 temporary file + atomic replace，並加入 external-inode regression fixture。
- 2026-07-18 — add-versioned-cash-skill-batch-update — cash-apply rounds 6–7 — retired-plus cleanup 與 managed replacement 起初未完整封閉 parent permissions、candidate/quarantine symlink swap 與 dangling symlink 邊界；補上 fail-closed preflight、`mv -h` no-follow quarantine/restore，以及 target 外 sentinel fault-injection fixtures。
- 2026-07-22 — migrate-cash-project-guidance — cash-propose round 1 — Guidance preflight未要求temporary creation與publish前重驗parent/destination identity，可能在swap後逃出target；補上兩階段no-follow revalidation與外部sentinel fixtures。
- 2026-07-22 — migrate-cash-project-guidance — cash-apply round 1 — Guidance publication在revalidation後仍透過mutable parent pathname執行temporary cleanup與atomic replace，parent swap可能觸及target外路徑；需先在design定義directory-FD primitive。
- 2026-07-22 — migrate-cash-project-guidance — cash-apply seeded round 1 — Directory-handle capability起初直到skill publication後才驗證；補上任何target mutation前的no-follow open、directory-handle `chdir`、identity與relative lookup零寫入preflight。
