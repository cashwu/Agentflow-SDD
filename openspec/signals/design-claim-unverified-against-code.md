---
id: design-claim-unverified-against-code
type: recurring-finding
status: open
occurrences: 4
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
  - openspec/changes/tolerate-versioned-legacy-guidance-marker/reviews/propose-r6.md
  - openspec/changes/tolerate-versioned-legacy-guidance-marker/reviews/propose-r9.md

---

# Design claim unverified against code

A design or proposal states a fact about the existing codebase as the premise of a decision, but the fact was recalled or inferred rather than read from the code. The decision may still be sound while its stated justification is false, which misleads later changes that build on the justification.

## Occurrences

- 2026-07-25 — align-cli-skill-contracts — cash-propose round 1 — design 宣稱同組三個 fork 型 skill 已完整處理 Claude-only frontmatter，實際上 cash-ask 只被剝除兩個 key，唯二完整處理的是 cash-audit 與 cash-drift。

- 2026-07-25 — derive-version-assertion-and-add-cli-help — cash-propose rounds 1–6 — 本 loop 最高頻的形狀，出現八次：我在 artifact 中寫下「已實測」或斷言程式碼行為，但證據不足或範圍錯誤。包括 grep 只搜 `tests/` 而漏 `fixtures/` 導致「沒有測試釘住錯誤訊息」為假、誤判 `version()` 的執行位置、未實測 fish 慣用法是否真能檢查 LF、未讀 `check_history` 的 early return 就寫下驗收、把 `assert_installer` 的呼叫誤植於 `assert_inventory`、格式規則擁有者數錯、未實測 `CASH_PROJECT_ROOT` 的語意就寫下 binding 手段、未分別實測 `.cash-workspace.lock` 的建置要求。

- 2026-07-25 — tolerate-versioned-legacy-guidance-marker — cash-propose round 1、4、5、6 — 未經量測的論斷寫進設計論證，四次。W5 宣稱字尾容忍對 source 側也是嚴格改善（實測相反：字尾會散播到全部 target）；Q1 把 target 側論斷為一律是修復（實測反方向會靜默刪除內容）；V1 與 F1 是同一段落的兩個案例前提缺漏，且 F1 發生在修 V1 的同一輪——`## Fix Actions` 宣稱「經本輪 reviewer 重新實測皆成立」，實際上只複測了其中一個，另一個是採信 reviewer 敘述。

- 2026-07-25 — tolerate-versioned-legacy-guidance-marker — cash-propose round 7 至 round 9（re-run）—— 同型第七至九次。A-2：round 4 reviewer 說「四段 legacy block digest 一致」，我未量測直接抄進 design，實測為兩個相異 digest 各兩份且長度不同故不可能一致。V-3：實測了「插入該行會使定位失敗」卻沒看它落入哪一條判定，就寫成「計數不相等」，實際是非獨立行。R9-1 是新變體「驗證了結論卻沒驗證機制」：量了 `2.3.2` 不大於 `2.4.0`，但沒讀 `check_history` 只比對工作樹與 HEAD，因而把一個無聲的版本回退誤述為會被 contract test 攔下的響亮失敗。round 10 首次零復發。
