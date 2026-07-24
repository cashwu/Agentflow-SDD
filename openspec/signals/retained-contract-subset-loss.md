---
id: retained-contract-subset-loss
type: recurring-finding
status: open
occurrences: 3
first_seen: 2026-07-18
last_seen: 2026-07-23
links:
  - openspec/changes/fork-spectra-skills-to-cash/reviews/propose-r1.md
  - openspec/changes/migrate-cash-project-guidance/reviews/propose-r1.md
  - openspec/changes/replace-spectra-cli-with-cash-cli/reviews/propose-r1.md
---

# Retained contract subset loss

A migration replaces an owned workflow or capability but carries forward only a summary or subset of behavior that the change claims to preserve, silently dropping normative branches from the replacement contract.

## Occurrences

- 2026-07-18 — fork-spectra-skills-to-cash — spectra-propose-plus round 1 — 初稿移除 36 條 plus requirements，卻只摘要保留 quality gate 與 cash-commit allowlist；修正後完整搬移 19 條 retained gate requirements，以及 tracked sources、customizations、archive output 與 explicit spec-sync branches。
- 2026-07-22 — migrate-cash-project-guidance — cash-propose round 1 — 初稿只保留向量模型fallback的標題與摘要語意，未鎖定使用者指定的完整Markdown；修正後兩個canonical blocks逐byte包含全文並有完整block comparison task。
- 2026-07-23 — replace-spectra-cli-with-cash-cli — cash-propose rounds 1–6 — 自建Cash CLI初稿遺漏consumer JSON欄位、touched來源追蹤、archive trace、fresh/legacy installer branches與receipt-less adoption；多數已補齊，但receipt-less 24-skill adoption與touched單一來源仍是abort obligation。
