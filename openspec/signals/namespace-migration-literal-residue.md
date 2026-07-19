---
id: namespace-migration-literal-residue
type: recurring-finding
status: open
occurrences: 2
first_seen: 2026-07-18
last_seen: 2026-07-19
links:
  - openspec/changes/fork-spectra-skills-to-cash/reviews/propose-r2.md
  - openspec/changes/chinese-spec-content/reviews/apply-r1.md
---

# Namespace migration literal residue

A workflow namespace migration updates the primary names but leaves examples or tool-specific invocation literals from the old namespace or one variant, making the shared contract contradict its new provenance or portability rules.

## Occurrences

- 2026-07-18 — fork-spectra-skills-to-cash — spectra-propose-plus round 2 — 完整 contract 搬移留下 `Propose Plus Review` 範例與固定 `/cash-ingest`；修正為 cash heading 與 variant-appropriate invocation，並以 bounded grep 驗證。
- 2026-07-19 — chinese-spec-content — cash-apply round 1–2 — 42 個 requirement 標題中文化後，spec 內文與 SKILL.md 共 47 處 backtick 舊英文標題引用斷鏈（含 1 處 HEAD 既存縮短前綴形式漏於首輪枚舉）；C3 code-span 不變量原樣凍結了殘留，修復時宣告例外並以正反向逐一對應驗證收斂。
