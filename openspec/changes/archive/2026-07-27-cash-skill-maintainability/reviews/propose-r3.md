# Cash Propose Review — Round 3

## Reviewer Findings

### Cumulative blocking set 驗證（Reviewer V）

- 成員 6（Warning，fix-introduced，測試檔路徑錯誤）：resolved — 五處路徑（proposal Impact、design D6、design Contract 6、tasks 1.1、tasks 3.4）全部命中 `scripts/cash-skills/tests/` 正確路徑且實檔存在；全文對 `scripts/cash-cli/tests/test_bundle_version_history.py` 與 `scripts/cash-cli/tests/test_live_namespace.py` 零殘留；`check_history`（:139）與失敗訊息（:109）、`test_live_namespace.py:38` 的 variant-parity 枚舉均與 artifacts 引文吻合；兩套件範圍與 4.3 置換清單跨檔一致。修正參照：Round 2 Fix Actions 1、2、3。驗證者：Reviewer V。

cumulative blocking set 於本輪清空。

### Suggestion

- severity: Suggestion｜confidence: 55｜layer: text｜location: tasks.md 3.5；design.md Contract 6｜summary: 「live surface 無 `scripts/cash-skills/variant-parity/` 殘引」照字面對整個 live surface（含 `openspec/specs/`）驗證在 apply 時點不可達——master spec 枚舉要到 archive 才被 delta 置換，且三個 master spec 的 `@trace` provenance 區塊屬歷史紀錄仍會存留；Contract 6 括號註記暗示的窄讀法（功能性引用面）可達且顯為本意｜recommendation: 明文限定驗證範圍為功能性引用面並註明排除項｜disposition: new（先於 Round 2 修正即存在，非 fix-introduced）｜來源: Reviewer V

## Rating

- post-filter cumulative blocking set Critical count: 0
- post-filter cumulative blocking set Warning count: 0
- 非阻塞 triaged finding count: 1
- critical_gap: false
- round_type: micro
- rationale: 唯一 cumulative set 成員經 Reviewer V 逐項實檔驗證 resolved 並移除，set 清空；新 finding 為 confidence 55 的 text 層 Suggestion（非阻塞，disposition new），依規則不構成 next_round。post-filter cumulative blocking set 無 Critical 亦無 Warning，pass 條件成立。

## Fix Actions

None; pass condition met.

- 非阻塞 triage note：tasks 3.5／Contract 6 的「無殘引」驗證範圍字面過寬（見上方 Suggestion）。因修正成本極低且能消除 apply 時的判讀歧義，本輪已順帶完成澄清編輯：tasks.md 3.5 與 design.md Contract 6 改為明文限定「功能性引用面」（兩處測試套件、`scripts/cash-skills/tests/test_live_namespace.py` scan 枚舉、`CASH-SKILLS.md` 敘述），並註明 master spec 枚舉由 archive 置換、`@trace` provenance 排除在外。修改檔案：tasks.md、design.md。編輯後 `"$cash_cli" validate cash-skill-maintainability` 重跑通過。該 finding 為 Suggestion（confidence 55 < 80），依 signals write step 規則不產生 signal。
- 本輪修改檔案均位於 change 目錄內，無 change 目錄外路徑需記入 touched（signals write step 的簽署另行處理）。

## Decision

passed
