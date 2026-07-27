# Cash Propose Review — Round 1

## Reviewer Findings

### Critical

- severity: Critical｜confidence: 95｜layer: design｜location: design.md D1／Implementation Contract 4；tasks.md 1.1、5.2｜summary: 「四份 gate 現行文字為同一規格」claim 為假（apply 兩檔含 `## What Changes` or `## Proposed Solution`，propose 兩檔僅 `## Proposed Solution`），且 task 1.1 指定的統一方向（以 apply 版為準）會把 `## What Changes` 寫入 propose 檔，違反 master spec「cash-propose 的 proposal 結構取自 CLI 單一來源」的全檔禁令並使 `scripts/cash-skills/tests/skill-checks.fish` 既有斷言失敗｜recommendation: 修正 D1 記載已驗證漂移、反轉統一方向為 propose 版、Contract 4 與 task 5.2 將該統一列為第三類允許差異｜來源: Reviewer A
- severity: Critical｜confidence: 90｜layer: design｜location: tasks.md 3.4 與 4.4（修正前編號）｜summary: 版本 bump 排在 SKILL.md 修改之後，`scripts/cash-cli/tests/test_bundle_version_history.py` 的 `check_history` 會在版本未領先時以「changed without a strictly greater cash-skills.version」使套件失敗，「全套測試通過」不可達（reviewer 已在工作樹實測重現後還原）｜recommendation: 將 bump 提前為第一個 task，先於任何 SKILL.md 修改｜來源: Reviewer B

### Warning

- severity: Warning｜confidence: 85｜layer: design｜location: design.md D1／Contract 3；tasks.md 1.1、1.3（修正前編號）｜summary: gate 區段邊界未排除步驟標題行，而標題行清單編號在兩 skill 必然不同（propose 9.、apply 11.），「四份逐字相同」在含標題行的讀法下永不成立｜recommendation: 明定錨點位於標題行之後、標題行不屬 block 亦不參與比對｜來源: Reviewer A
- severity: Warning｜confidence: 85｜layer: design｜location: proposal.md Impact；openspec/specs/cash-cli/spec.md「Live namespace 與歷史邊界」；scripts/cash-cli/tests/test_live_namespace.py｜summary: cash-cli master spec 以 SHALL 枚舉 live scan surface，其中含即將移除的 `scripts/cash-skills/variant-parity/`，而新增的 live 檔案（blocks、generator、rules、SKILL-LINT、GLOSSARY）皆不在 surface 內；本 change 未附 cash-cli delta，留下殘引與治理缺口｜recommendation: 增列 cash-cli delta 更新枚舉，並把 test_live_namespace.py 列入 Impact 與 tasks｜來源: Reviewer B
- severity: Warning｜confidence: 85｜layer: design｜location: tasks.md 4.3；CASH-SKILLS.md（開頭所有權敘述與 live scan 敘述）｜summary: task 4.3 僅要求「新增一節＋兩連結」，未涵蓋 CASH-SKILLS.md 既有敘述的修訂——live scan 敘述明文引用即將刪除的 variant parity manifests，所有權敘述「直接維護的 source-controlled canonical files」與 `.agents` 改為生成輸出矛盾｜recommendation: 擴充 4.3 同步修訂兩處敘述｜來源: Reviewer A 與 Reviewer B 獨立提出（layer 依合併規則取 design）

### Suggestion

- severity: Suggestion｜confidence: 70｜layer: design｜location: design.md Context 1｜summary: 「靠 SKILL.md 內列舉的同步清單人工維持」描述不準確；實際機制是 skill-checks.fish 的 `grader_hash` 子區段 raw byte SHA-256 跨檔斷言，且該約束是 block 注入必須持續滿足的邊界條件而 design 未提及｜recommendation: 修正 Context 並在 Risks 記載 grader_hash byte-identity 約束｜來源: Reviewer A
- severity: Suggestion（Warning 65 經 confidence filter 降級）｜confidence: 65｜layer: design｜location: design.md D1；delta spec 通用轉換規則句｜summary: 前綴置換未定義 token 邊界，naive 全域置換會腐蝕路徑字面值；現行唯一機器編碼的邊界（`normalized_variant_diff` 的 lookbehind）將隨 D3 刪除｜recommendation: 在 design 與 delta spec 明文界定 `(?<![A-Za-z0-9_.-])` 邊界｜來源: Reviewer A 與 Reviewer B 獨立提出
- severity: Suggestion（Warning 65 經 confidence filter 降級）｜confidence: 65｜layer: design｜location: design.md D2；tasks.md 2.1｜summary: cash-audit 差異達 122 行近整檔替換，patch 錨定語意（行號或 marker）、fish 對 YAML 的解析手段、manifest 內 `@cash-` placeholder 還原皆未指明｜recommendation: 明定 marker／section 錨定、python3 輔助、placeholder 還原步驟｜來源: Reviewer B
- severity: Suggestion（Warning 60 經 confidence filter 降級）｜confidence: 60｜layer: design｜location: tasks.md（無 receipt 步驟）；.cash-skills/receipt.tsv｜summary: 本 repo 為 self-installed target，SKILL.md 修改與版本 bump 後 receipt 全面過期，tasks 無 `./install-cash-skills.fish --self` 重建步驟（對應 signal `integrity-receipt-not-regenerated-after-runtime-change`）｜recommendation: 收尾加入 receipt 重建 task｜來源: Reviewer B
- severity: Suggestion｜confidence: 55｜layer: design｜location: design.md D3；tasks.md 3.1｜summary: freshness 測試「暫存目錄重跑生成管線」未指明 generator 的 target-root 介面與需複製的完整輸入集，直接對工作樹執行會使測試改寫工作樹｜recommendation: 明定 target-root 參數與輸入集（12 個 .claude SKILL.md、block、rules）｜來源: Reviewer B
- severity: Suggestion｜confidence: 55｜layer: text｜location: tasks.md 4.3；delta spec「Cash skill lint 檢核清單」｜summary: delta 要求 CASH-SKILLS.md 說明 SKILL-LINT 用途為人工檢核維度，task 4.3 未含此動作｜recommendation: 4.3 補上用途說明｜來源: Reviewer A
- severity: Suggestion｜confidence: 50｜layer: text｜location: delta spec「變體檔案的內在良構獨立於對等比較」｜summary: delta 同檔內既宣告 `.agents` 為生成輸出，又保留「24 個 canonical `SKILL.md`」措辭，術語不一致｜recommendation: 改為「24 個雙變體 `SKILL.md`」並視為已宣告的 MODIFIED 編輯｜來源: Reviewer A

## Rating

- post-filter cumulative blocking set Critical count: 2
- post-filter cumulative blocking set Warning count: 3
- 非阻塞 triaged finding count: 7
- critical_gap: true
- round_type: full
- rationale: 首輪（未 seeded）全部存活 Critical 與 Warning 均為 blocking。兩個 Critical 均經 reviewer 實測驗證（gate 漂移實測 diff、版本歷史測試實測重現），三個 Warning 各自指向可稽核的機制缺口（標題行編號、SHALL 枚舉殘引、文件矛盾）。blocking set 非空且含 Critical，故本輪不可 pass，進入下一輪由 Reviewer V 驗證修正。

## Fix Actions

本輪對全部 5 個 blocking findings 與 7 個非阻塞 findings 一併完成修正（非阻塞項因修正成本低且與 blocking 修正同檔，直接併入修正而非僅留 triage note）：

1. design.md：Context 1 改寫（漂移實況與 grader_hash 機制）；D1 記載漂移、統一方向反轉為 propose 版、錨點置於標題行之後、前綴置換邊界 `(?<![A-Za-z0-9_.-])`；D2 補 marker／section 錨定、python3 輔助、`@cash-` placeholder 還原；D3 補 target-root 介面與 freshness 測試輸入集；D6 補 bump 序位約束與 receipt 重建；D7 順序更新；Contract 3、4、6、8、9、10 對應更新（Contract 4 改為三類允許差異）；Risks 補 grader_hash byte-identity 約束。
2. tasks.md：整檔改寫——1.1 版本 bump 提前為首個 task；1.2 統一漂移（propose 版為準）＋機械驗證；1.4 錨點排除標題行；2.1 marker 錨定與 placeholder 還原；3.1 暫存 root 輸入集；3.4 新增 test_live_namespace.py scan surface 更新；3.5 兩套測試；4.3 擴充（所有權敘述、live scan 敘述、SKILL-LINT 用途說明）；5.3 新增 receipt 重建。
3. proposal.md：Proposed Solution 1 改為三類內容變更；4 補 live namespace surface 更新、bump 序位、receipt 重建；Non-Goals 措辭修正（runtime 程式不變、收尾執行既有 self 安裝）；Modified Capabilities 增列 `cash-cli`；Impact 增列 openspec/specs/cash-cli/spec.md、scripts/cash-cli/tests/test_live_namespace.py、.cash-skills/receipt.tsv。
4. specs/cash-skill-workflows/spec.md：「Review gate 單一源頭生成」補標題行排除；「變體對等比較完整的受治理本文」補前綴置換 token 邊界；「變體檔案的內在良構獨立於對等比較」內 canonical 措辭統一為「雙變體」（共 4 處）。
5. specs/cash-cli/spec.md：新增 delta——MODIFIED「Live namespace 與歷史邊界」（枚舉移除 variant-parity、加入五個新 live 路徑），新增 scenario「生成源頭檔納入 scan surface」。

修正後已重跑 pre-round mechanical self-check（註解成對 6/6 與 0/0、無 stray `---`、MODIFIED 標題含 cash-cli 共 5 個逐字命中、identifier 跨檔一致、無帶 `check` 之 open signal）並重跑 `"$cash_cli" validate cash-skill-maintainability` 通過。

附註：Impact affected-code 條目數修正後為 16（>15），已依 impact granularity advisory 印出資訊性拆分建議；使用者已明確選定四項合併於本 change，advisory 不阻斷。本輪修正檔案均位於 change 目錄內，無 change 目錄外路徑需記入 touched。

## Decision

next_round
