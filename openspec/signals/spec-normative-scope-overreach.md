---
id: spec-normative-scope-overreach
type: recurring-finding
status: open
occurrences: 2
first_seen: 2026-07-07
last_seen: 2026-07-22
links:
  - openspec/changes/add-micro-verification-round/reviews/propose-r2.md
  - openspec/changes/migrate-cash-project-guidance/reviews/propose-r1.md
---

# Spec normative scope overreach

A normative sentence (SHALL/MUST) names a broader subject set than the rule can or should govern, so a correct implementation strategy elsewhere in the change appears to violate the spec — or the extra subject becomes dead, unenforceable wording. The fix is narrowing the sentence's subject to its real scope, not weakening the implementation.

## Occurrences

- 2026-07-07 — add-micro-verification-round — spectra-propose-plus round 2 — New metadata requirement sentence put "test assertions" under "MUST NOT hard-code version/date literals", contradicting the deliberate (and correct) synchronized-pinned-literal strategy in the regression tests.
- 2026-07-22 — migrate-cash-project-guidance — cash-propose round 1 — 「持久target狀態僅由」的主詞錯誤涵蓋整個project，排除了合約要求保留的Spectra skills與project-owned state；修正為Cash installer新增或管理的狀態。
