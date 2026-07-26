---
id: design-claim-unverified-against-code
type: recurring-finding
status: open
occurrences: 7
first_seen: 2026-07-25
last_seen: 2026-07-26
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
  - openspec/changes/rightsize-cash-skills/reviews/propose-r3.md
  - openspec/changes/harden-spec-trace-path-extraction/reviews/propose-r6.md
  - openspec/changes/harden-spec-trace-path-extraction/reviews/propose-r7.md
  - openspec/changes/harden-spec-trace-path-extraction/reviews/propose-r9.md

---

# Design claim unverified against code

A design or proposal states a fact about the existing codebase as the premise of a decision, but the fact was recalled or inferred rather than read from the code. The decision may still be sound while its stated justification is false, which misleads later changes that build on the justification.

## Occurrences

- 2026-07-25 — align-cli-skill-contracts — cash-propose round 1 — design 宣稱同組三個 fork 型 skill 已完整處理 Claude-only frontmatter，實際上 cash-ask 只被剝除兩個 key，唯二完整處理的是 cash-audit 與 cash-drift。

- 2026-07-25 — derive-version-assertion-and-add-cli-help — cash-propose rounds 1–6 — 本 loop 最高頻的形狀，出現八次：我在 artifact 中寫下「已實測」或斷言程式碼行為，但證據不足或範圍錯誤。包括 grep 只搜 `tests/` 而漏 `fixtures/` 導致「沒有測試釘住錯誤訊息」為假、誤判 `version()` 的執行位置、未實測 fish 慣用法是否真能檢查 LF、未讀 `check_history` 的 early return 就寫下驗收、把 `assert_installer` 的呼叫誤植於 `assert_inventory`、格式規則擁有者數錯、未實測 `CASH_PROJECT_ROOT` 的語意就寫下 binding 手段、未分別實測 `.cash-workspace.lock` 的建置要求。

- 2026-07-25 — tolerate-versioned-legacy-guidance-marker — cash-propose round 1、4、5、6 — 未經量測的論斷寫進設計論證，四次。W5 宣稱字尾容忍對 source 側也是嚴格改善（實測相反：字尾會散播到全部 target）；Q1 把 target 側論斷為一律是修復（實測反方向會靜默刪除內容）；V1 與 F1 是同一段落的兩個案例前提缺漏，且 F1 發生在修 V1 的同一輪——`## Fix Actions` 宣稱「經本輪 reviewer 重新實測皆成立」，實際上只複測了其中一個，另一個是採信 reviewer 敘述。

- 2026-07-25 — tolerate-versioned-legacy-guidance-marker — cash-propose round 7 至 round 9（re-run）—— 同型第七至九次。A-2：round 4 reviewer 說「四段 legacy block digest 一致」，我未量測直接抄進 design，實測為兩個相異 digest 各兩份且長度不同故不可能一致。V-3：實測了「插入該行會使定位失敗」卻沒看它落入哪一條判定，就寫成「計數不相等」，實際是非獨立行。R9-1 是新變體「驗證了結論卻沒驗證機制」：量了 `2.3.2` 不大於 `2.4.0`，但沒讀 `check_history` 只比對工作樹與 HEAD，因而把一個無聲的版本回退誤述為會被 contract test 攔下的響亮失敗。round 10 首次零復發。
- 2026-07-26 — rightsize-cash-skills — cash-propose round 3 — design 以 `unavailable` 為關鍵字取首個匹配行，把 `cash-propose` 的 fallback 位置誤植為 accepted-risks ledger 的 `:302`（實為 `:518`），而該節已宣告「實作時 MUST 以這些位置為準」。

- 2026-07-26 — harden-spec-trace-path-extraction — cash-propose rounds 1／2／6 — 三次修正建立在對程式碼的錯誤事實之上，且每次都在下一輪被實測推翻：round 1 宣稱「ASCII 限定後零偽陽性」（實際殘留 `runtime/install`）與「23 個空 tests 代表合法無測試」（實際全來自同一 change 的 clause 定位缺陷）；round 2 為補救機制宣稱「merge 對相同輸入是冪等的」（實際只對 MODIFIED-only 冪等，ADDED 撞 `requirement_collision`）；round 6 發現 round 4 寫入的「`workspace.spec_files` 順序來自未排序的 `os.listdir`」是錯的（`list_directory` 最後一行即 `sorted(...)`），而 round 5 據該錯誤事實設計的驗證 case 因此空轉。
- 2026-07-26 — harden-spec-trace-path-extraction — cash-propose rounds 7–9（re-run）—— 同型於重跑中復發兩次，皆為修正動作寫入未經量測的語料宣稱：round 7 的修正把 round 3 已判定不可重現並移除的「73／72」總數重新寫回兩處（R7-W2）；round 7 對 R7-S7 的修正在 design Risks 寫入「實測⋯損失為 0」的未量測宣稱（R8-W1），round 8 修正其計數後同句又寫入錯誤的出處歸屬「皆來自同一份已封存 proposal」（實為兩份，R9-W1），至 round 9 修正、round 10 兩位檢查點 reviewer 獨立量測後才確認收斂。教訓：fix action 中的每一個「實測」字樣都必須附帶當下真的執行過的量測。
