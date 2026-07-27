---
id: removed-mechanism-residual-references
type: recurring-finding
status: open
occurrences: 7
first_seen: 2026-07-16
last_seen: 2026-07-27
links:
  - openspec/changes/converge-plus-review-loop/reviews/propose-r1.md
  - openspec/changes/fork-spectra-skills-to-cash/reviews/propose-r1.md
  - openspec/changes/fork-spectra-skills-to-cash/reviews/propose-r2.md
  - openspec/changes/fork-spectra-skills-to-cash/reviews/apply-r1.md
  - openspec/changes/replace-spectra-cli-with-cash-cli/reviews/propose-r1.md
  - openspec/changes/harden-spec-trace-path-extraction/reviews/propose-r7.md
  - openspec/changes/cash-skill-maintainability/reviews/propose-r1.md
  - openspec/changes/cash-skill-maintainability/reviews/apply-r1.md
---

# Removed mechanism residual references

A change removes or replaces a mechanism (a rule, a derivation step, a note type), but normative references to it elsewhere in the master spec or shared templates are not inventoried and rewritten in the same change — the merged spec then mandates compliance with rules that no longer exist. The fix is grepping every artifact and template for the removed concept before finalizing the delta.

## Occurrences

- 2026-07-16 — converge-plus-review-loop — spectra-propose-plus rounds 1–2 — 刪除 re-derivation 機制時，master spec 的 grader immutability 例外句、ledger 時序句、Fresh sub-agent 決策推導句三處殘留引用未列入 MODIFIED，需三輪才清完。
- 2026-07-18 — fork-spectra-skills-to-cash — spectra-propose-plus rounds 1–2 — 退役 plus generator/template 時，live 文件與完整搬移的 cash delta spec 仍殘留已移除機制的操作與 normative target；補入文件 migration scope，並改由 canonical cash skill files 直接持有 governed sections。
- 2026-07-18 — fork-spectra-skills-to-cash — cash-apply round 1 — 兩份 Spectra-owned `spectra-commit` 在退役 plus patch 後仍殘留 project-custom archive allowlist；修正為與隔離 `spectra update --force` baseline byte-identical，客製行為只留在 `cash-commit`。
- 2026-07-23 — replace-spectra-cli-with-cash-cli — cash-propose rounds 1–5 — 替換Spectra runtime時未在第一版完整盤點仍具權威的master installer、registry、guidance與batch requirements；逐條MODIFIED/REMOVED後才消除合併衝突。
- 2026-07-26 — harden-spec-trace-path-extraction — cash-propose round 7 — `cash-ingest` 把診斷／`trace_gaps` 機制移出範圍後，proposal 仍有兩處肯定句以該機制為論證支柱（與自身 Non-Goals 直接矛盾）、兩個懸空條號指向已不存在的「第 4 點」，design Risks 兩則引用已刪除的 `D5`——機制載體刪乾淨了，論證該機制的散文沒有。
- 2026-07-27 — cash-skill-maintainability — cash-propose round 1 — 移除 `scripts/cash-skills/variant-parity/` manifests 時，cash-cli master spec 的 scan surface SHALL 枚舉與 `CASH-SKILLS.md` 的所有權／live scan 敘述兩處殘留引用均未列入修訂範圍；修正為補 cash-cli delta 並擴充 CASH-SKILLS.md 修訂 task。
- 2026-07-27 — cash-skill-maintainability — cash-apply round 1 — 對等機制由 diff manifest 比對改為重新生成 freshness 檢查後，cash-cli master spec 仍以「24-skill variant parity」描述 `skill-checks.fish` 的治理範圍，而該句不在本 change 的 cash-cli delta 之內；經使用者裁決維持現狀（該措辭描述被治理的性質而非機制），但殘留引用的盤點仍應在 delta 定稿前完成而非留到 apply 才發現。
