---
id: source-layout-detection-underconstrained
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-24
last_seen: 2026-07-24
links:
  - openspec/changes/replace-spectra-cli-with-cash-cli/reviews/apply-r3.md
---

# Source layout detection underconstrained

A recovery diagnostic classifies a repository as a canonical source bundle from weak marker files instead of validating the complete source layout and identities, so installed targets can receive unsafe or impossible repair instructions.

## Occurrences

- 2026-07-24 — replace-spectra-cli-with-cash-cli — cash-apply rounds 3–5 — Launcher source hint originally relied on four marker files；改為驗證 Git top-level、strict version、source-only files、runtime core與完整24-skill inventory。
