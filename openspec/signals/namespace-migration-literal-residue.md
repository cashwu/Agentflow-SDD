---
id: namespace-migration-literal-residue
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-18
last_seen: 2026-07-18
links:
  - openspec/changes/fork-spectra-skills-to-cash/reviews/propose-r2.md
---

# Namespace migration literal residue

A workflow namespace migration updates the primary names but leaves examples or tool-specific invocation literals from the old namespace or one variant, making the shared contract contradict its new provenance or portability rules.

## Occurrences

- 2026-07-18 — fork-spectra-skills-to-cash — spectra-propose-plus round 2 — 完整 contract 搬移留下 `Propose Plus Review` 範例與固定 `/cash-ingest`；修正為 cash heading 與 variant-appropriate invocation，並以 bounded grep 驗證。
