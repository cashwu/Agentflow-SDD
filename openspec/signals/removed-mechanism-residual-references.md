---
id: removed-mechanism-residual-references
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-16
last_seen: 2026-07-16
links:
  - openspec/changes/converge-plus-review-loop/reviews/propose-r1.md
---

# Removed mechanism residual references

A change removes or replaces a mechanism (a rule, a derivation step, a note type), but normative references to it elsewhere in the master spec or shared templates are not inventoried and rewritten in the same change — the merged spec then mandates compliance with rules that no longer exist. The fix is grepping every artifact and template for the removed concept before finalizing the delta.

## Occurrences

- 2026-07-16 — converge-plus-review-loop — spectra-propose-plus rounds 1–2 — 刪除 re-derivation 機制時，master spec 的 grader immutability 例外句、ledger 時序句、Fresh sub-agent 決策推導句三處殘留引用未列入 MODIFIED，需三輪才清完。
