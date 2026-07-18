---
id: managed-block-overwrites-project-guidance
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-18
last_seen: 2026-07-18
links:
  - openspec/changes/fork-spectra-skills-to-cash/reviews/propose-r1.md
---

# Managed block overwrites project guidance

Project-owned workflow guidance is placed inside an externally managed document block, so an upstream update can silently replace the intended local precedence and routing.

## Occurrences

- 2026-07-18 — fork-spectra-skills-to-cash — spectra-propose-plus round 1 — cash workflow guidance 原本預計寫入 Spectra-managed AGENTS block；改為在 `<!-- SPECTRA:END -->` 後建立具 precedence 的 project-owned override，並新增 forced-update fixture。
