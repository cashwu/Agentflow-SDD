---
id: retained-contract-subset-loss
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-18
last_seen: 2026-07-18
links:
  - openspec/changes/fork-spectra-skills-to-cash/reviews/propose-r1.md
---

# Retained contract subset loss

A migration replaces an owned workflow or capability but carries forward only a summary or subset of behavior that the change claims to preserve, silently dropping normative branches from the replacement contract.

## Occurrences

- 2026-07-18 — fork-spectra-skills-to-cash — spectra-propose-plus round 1 — 初稿移除 36 條 plus requirements，卻只摘要保留 quality gate 與 cash-commit allowlist；修正後完整搬移 19 條 retained gate requirements，以及 tracked sources、customizations、archive output 與 explicit spec-sync branches。
