---
id: design-claim-unverified-against-code
type: recurring-finding
status: open
occurrences: 2
first_seen: 2026-07-25
last_seen: 2026-07-25
links:
  - openspec/changes/align-cli-skill-contracts/reviews/propose-r1.md
  - openspec/changes/derive-version-assertion-and-add-cli-help/reviews/propose-r1.md
  - openspec/changes/derive-version-assertion-and-add-cli-help/reviews/propose-r2.md
  - openspec/changes/derive-version-assertion-and-add-cli-help/reviews/propose-r3.md
  - openspec/changes/derive-version-assertion-and-add-cli-help/reviews/propose-r4.md
  - openspec/changes/derive-version-assertion-and-add-cli-help/reviews/propose-r5.md
  - openspec/changes/derive-version-assertion-and-add-cli-help/reviews/propose-r6.md

---

# Design claim unverified against code

A design or proposal states a fact about the existing codebase as the premise of a decision, but the fact was recalled or inferred rather than read from the code. The decision may still be sound while its stated justification is false, which misleads later changes that build on the justification.

## Occurrences

- 2026-07-25 — align-cli-skill-contracts — cash-propose round 1 — design 宣稱同組三個 fork 型 skill 已完整處理 Claude-only frontmatter，實際上 cash-ask 只被剝除兩個 key，唯二完整處理的是 cash-audit 與 cash-drift。

- 2026-07-25 — derive-version-assertion-and-add-cli-help — cash-propose rounds 1–6 — 本 loop 最高頻的形狀，出現八次：我在 artifact 中寫下「已實測」或斷言程式碼行為，但證據不足或範圍錯誤。包括 grep 只搜 `tests/` 而漏 `fixtures/` 導致「沒有測試釘住錯誤訊息」為假、誤判 `version()` 的執行位置、未實測 fish 慣用法是否真能檢查 LF、未讀 `check_history` 的 early return 就寫下驗收、把 `assert_installer` 的呼叫誤植於 `assert_inventory`、格式規則擁有者數錯、未實測 `CASH_PROJECT_ROOT` 的語意就寫下 binding 手段、未分別實測 `.cash-workspace.lock` 的建置要求。
