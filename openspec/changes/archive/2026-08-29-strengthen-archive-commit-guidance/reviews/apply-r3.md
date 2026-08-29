# Cash Apply Review — Round 3

（新 loop run 的第 1 輪；前一 run 於 apply-r2 以 passed 收斂後，經 ingest 併入外部 sol review 兩項並實作 task 4.1，故啟動本 run。編號延續既有 round files。）

## Reviewer Findings

### Suggestion

- severity: Suggestion
  confidence: 55
  layer: design
  location: `.claude/skills/cash-archive/SKILL.md`／`.agents/skills/cash-archive/SKILL.md` 步驟 4b「取得 dirty 路徑」bullet（同句鏡射於 delta spec 與 design D2）
  summary: 合併後解析規則自洽，但未明寫「如何辨識 rename／copy 條目（狀態欄 X 或 Y 為 `R`／`C`）」與「`-z` 輸出以 NUL 終結、split 尾端空 field 應忽略」兩個細節；兩者字面誤讀的失效方向皆為停止分支（安全、可見），非靜默漏判。
  recommendation: 補兩個子句並鏡射，或明文記入 design Risks 接受由停止分支吸收。
  reviewer source: Reviewer B。

## Rating

- post-filter cumulative blocking set Critical count: 0
- post-filter cumulative blocking set Warning count: 0
- non-blocking triaged finding count: 1
- critical_gap: false
- round_type: full
- rationale: 本 run 為 unseeded，首輪全部 surviving Critical／Warning 皆為 blocking，但兩位 reviewer 均未回報任何 Critical 或 Warning——Reviewer A 對 design 代碼面主張（porcelain `-z` rename 格式實測、BUNDLE_VERSION 相等斷言、touched task_desc 逐 byte 相符）全數驗證成立，Reviewer B 實測解析算術正確、17 個 literal 具鑑別力、touched JSON 經 `_validate_touched` 驗證通過。blocking set 為空，符合 pass 條件。

## Fix Actions

- 非阻斷 Suggestion triage：採 reviewer 提供的替代處置，把兩個 fail-safe 解析殘餘（rename／copy 辨識判準、NUL 終結尾端空 field）明文記入 design.md「Risks / Trade-offs」，接受由偵測失敗停止分支吸收，不再增寫 skill 解析細則。修改檔案：`openspec/changes/strengthen-archive-commit-guidance/design.md`。
- drop trace：Reviewer A finding「implementation-notes.md header initialized 時間晚於條目時間戳」severity Suggestion, confidence 40 < 50，依 confidence filter 丟棄；純 audit-trail 雜訊，不影響 deviation 實質正當性。
- 本輪 Fix Actions 於 change 目錄外無修改檔案，依規則不呼叫 touched record。

## Decision

passed

blocking set 為空（無任何 surviving Critical／Warning），非阻斷 Suggestion 已以 design Risks 明文化處置並記錄。
