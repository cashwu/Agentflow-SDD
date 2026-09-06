---
id: normative-quantifier-scope-dropped-in-restatement
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-09-05
last_seen: 2026-09-05
links:
  - openspec/changes/add-host-derived-round-lint/reviews/propose-r1.md
---

# Normative quantifier scope dropped in restatement

把上游 spec 的規則複述到新 artifact 時，原文中限定量詞作用範圍的子句被省略，使「當且僅當」之類的雙向條件從受限變成無條件，並與緊鄰的另一條規則直接矛盾。實作者逐字照抄時，該規則的期望值取決於兩句的先後解讀；若該規則驅動的是阻擋型檢查，誤判會擋住全部工作。複述帶量詞的規範時，限定條件與量詞必須一起搬。

## Occurrences

- 2026-09-05 — add-host-derived-round-lint — cash-propose round 1 — master spec 的原文是「一次迴圈執行的第一輪 MUST 是 full 輪。當某一輪的決策為 `next_round` 時……當且僅當下一輪是本次執行的第四輪時，它才是 full 輪」——該 iff 只作用於第一輪之後的輪。複述到 proposal、design 與 spec delta 三處時「當某一輪的決策為 `next_round` 時」這個限定被省略，變成無條件的「當且僅當某輪是其 run 的第四輪時 MUST 是 `full`」，與緊鄰的「第一輪 MUST 是 `full`」互相否定（第一輪不是第四輪，卻要是 full）。
