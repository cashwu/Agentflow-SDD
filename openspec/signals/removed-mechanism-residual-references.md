---
id: removed-mechanism-residual-references
type: recurring-finding
status: open
occurrences: 4
first_seen: 2026-07-16
last_seen: 2026-07-23
links:
  - openspec/changes/converge-plus-review-loop/reviews/propose-r1.md
  - openspec/changes/fork-spectra-skills-to-cash/reviews/propose-r1.md
  - openspec/changes/fork-spectra-skills-to-cash/reviews/propose-r2.md
  - openspec/changes/fork-spectra-skills-to-cash/reviews/apply-r1.md
  - openspec/changes/replace-spectra-cli-with-cash-cli/reviews/propose-r1.md
---

# Removed mechanism residual references

A change removes or replaces a mechanism (a rule, a derivation step, a note type), but normative references to it elsewhere in the master spec or shared templates are not inventoried and rewritten in the same change — the merged spec then mandates compliance with rules that no longer exist. The fix is grepping every artifact and template for the removed concept before finalizing the delta.

## Occurrences

- 2026-07-16 — converge-plus-review-loop — spectra-propose-plus rounds 1–2 — 刪除 re-derivation 機制時，master spec 的 grader immutability 例外句、ledger 時序句、Fresh sub-agent 決策推導句三處殘留引用未列入 MODIFIED，需三輪才清完。
- 2026-07-18 — fork-spectra-skills-to-cash — spectra-propose-plus rounds 1–2 — 退役 plus generator/template 時，live 文件與完整搬移的 cash delta spec 仍殘留已移除機制的操作與 normative target；補入文件 migration scope，並改由 canonical cash skill files 直接持有 governed sections。
- 2026-07-18 — fork-spectra-skills-to-cash — cash-apply round 1 — 兩份 Spectra-owned `spectra-commit` 在退役 plus patch 後仍殘留 project-custom archive allowlist；修正為與隔離 `spectra update --force` baseline byte-identical，客製行為只留在 `cash-commit`。
- 2026-07-23 — replace-spectra-cli-with-cash-cli — cash-propose rounds 1–5 — 替換Spectra runtime時未在第一版完整盤點仍具權威的master installer、registry、guidance與batch requirements；逐條MODIFIED/REMOVED後才消除合併衝突。
