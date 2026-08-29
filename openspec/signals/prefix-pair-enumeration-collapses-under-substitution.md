---
id: prefix-pair-enumeration-collapses-under-substitution
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-08-29
last_seen: 2026-08-29
links:
  - openspec/changes/strengthen-archive-commit-guidance/reviews/apply-r1.md
---

# Prefix-pair enumeration collapses under substitution

規範句在單一來源變體中同時枚舉兩個 invocation 前綴（如「`/cash-` 與 `$cash-`」）時，變體生成的前綴置換會把其中一個改寫成另一個，使生成變體出現退化的自我配對（「`$cash-` 與 `$cash-`」），該句在生成變體中自相矛盾。既有的正規化對等比較（兩前綴映為同一 token）與再生比對都無法攔截這種劣化。修法是把前綴對改寫為不含可置換字面的描述（如「斜線與錢字號兩種形式」），或為該句建立置換例外。與 [[generated-literal-path-corruption]] 同屬生成置換損壞 literal 內容的家族，但根因不同：前者是置換誤及 path literals，本類是來源句刻意枚舉置換對本身。

## Occurrences

- 2026-08-29 — strengthen-archive-commit-guidance — cash-apply round 1 — `.claude/skills/cash-apply/SKILL.md` 模板規範句枚舉「（`/cash-` 與 `$cash-`）」，generate.fish 置換後 `.agents` 變體成為「（`$cash-` 與 `$cash-`）」；改寫為「（斜線與錢字號兩種形式）」後再生收斂。
