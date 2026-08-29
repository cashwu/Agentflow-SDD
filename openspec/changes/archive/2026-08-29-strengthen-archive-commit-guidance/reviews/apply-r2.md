# Cash Apply Review — Round 2

## Reviewer Findings

### Suggestion

- severity: Suggestion
  confidence: 50
  layer: design
  location: `openspec/changes/strengthen-archive-commit-guidance/design.md` D2（NUL-delimited 解析 bullet）
  summary: round 1 的剝除前綴子句已鏡射至兩個 SKILL.md 變體、delta spec 與 skill-checks，但未鏡射至 design D2 的解析 bullet，design 描述的解析規則比 spec 少一條。
  recommendation: 把該子句補入 design D2 的解析 bullet，達成 artifact 對稱；不影響行為與 assertion。
  disposition: fix-introduced
  introduced_by: apply-r1.md「## Fix Actions」第二項（鏡射清單未含 design.md）。
  reviewer source: Reviewer V。

## Rating

- post-filter cumulative blocking set Critical count: 0
- post-filter cumulative blocking set Warning count: 0
- non-blocking triaged finding count: 1
- critical_gap: false
- round_type: micro
- rationale: Reviewer V 對唯一 cumulative blocking set 成員 M1（`.agents` 前綴對枚舉退化）回傳 resolved verdict，佐證為退化字串歸零、兩變體該句逐字相同、manifest digest 與四個 skill 檔一致且全套 skill-checks 綠（含再生比對與變體對等）。blocking set 清空，僅餘一個 fix-introduced Suggestion（confidence 50，非阻斷），符合 pass 條件。

## Fix Actions

- 驗證解除記錄：成員 M1（Warning，`.agents/skills/cash-apply/SKILL.md` 前綴對枚舉退化）— 修復引用 apply-r1.md「## Fix Actions」第一項，由 Reviewer V 於本輪確認 resolved，自 cumulative blocking set 移除。
- 修復 triaged Suggestion（design D2 對稱鏡射）：把「每筆條目以兩字元狀態欄加一個空白開頭，比對前先剝除該前綴取出路徑」補入 design D2 的 NUL-delimited 解析 bullet。修改檔案：`openspec/changes/strengthen-archive-commit-guidance/design.md`。此編輯位於 change 目錄內、不觸及任何 protected 檔案，不影響行為與 assertion。

## Decision

passed

cumulative blocking set 為空（M1 經 Reviewer V 驗證 resolved），無 blocking Critical 或 blocking Warning；非阻斷 Suggestion 已於本輪修復並記錄。
