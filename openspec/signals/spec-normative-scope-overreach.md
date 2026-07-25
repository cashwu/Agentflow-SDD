---
id: spec-normative-scope-overreach
type: recurring-finding
status: open
occurrences: 3
first_seen: 2026-07-07
last_seen: 2026-07-25
links:
  - openspec/changes/add-micro-verification-round/reviews/propose-r2.md
  - openspec/changes/migrate-cash-project-guidance/reviews/propose-r1.md
  - openspec/changes/tolerate-versioned-legacy-guidance-marker/reviews/propose-r1.md
---

# Spec normative scope overreach

A normative sentence (SHALL/MUST) names a broader subject set than the rule can or should govern, so a correct implementation strategy elsewhere in the change appears to violate the spec — or the extra subject becomes dead, unenforceable wording. The fix is narrowing the sentence's subject to its real scope, not weakening the implementation.

## Occurrences

- 2026-07-07 — add-micro-verification-round — spectra-propose-plus round 2 — New metadata requirement sentence put "test assertions" under "MUST NOT hard-code version/date literals", contradicting the deliberate (and correct) synchronized-pinned-literal strategy in the regression tests.
- 2026-07-22 — migrate-cash-project-guidance — cash-propose round 1 — 「持久target狀態僅由」的主詞錯誤涵蓋整個project，排除了合約要求保留的Spectra skills與project-owned state；修正為Cash installer新增或管理的狀態。

- 2026-07-25 — tolerate-versioned-legacy-guidance-marker — cash-propose round 1 至 round 5 — 同一形態出現四次：delta 寫下的 MUST／MUST NOT 超出 design 與 tasks 所能交付。C1 的診斷要求與 IC3「訊息文字不變」互相封死；F1 的無條件 GIVEN 對應一個 gate 在計數不相等上的實作；NF2 把逐檔的計數判定寫成逐 marker 的性質；V3 把不可觀察的實作禁令寫成永久 normative。最後一項的修法是把它降級為 design rationale，其餘為收斂 normative 範圍。
