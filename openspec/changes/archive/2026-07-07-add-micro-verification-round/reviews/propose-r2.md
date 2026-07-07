# Propose Plus Review — Round 2

## Reviewer Findings

### Critical

（無）

### Warning

1. severity: Warning｜confidence: 85｜reviewer: A+B
   - location: delta spec MODIFIED「Generated plus skill version metadata」與「Repair checks plus metadata freshness」新增句 vs tasks.md 3.1/3.2、design.md 決策四
   - summary: 新增規範句把「test assertions」納入「不得硬編碼字面值、以 rules.yaml 為唯一真值來源」的 MUST 主詞，但 tasks/design 刻意（且正確地）保留測試檔的同步釘死值 —— 測試若動態讀 rules.yaml，錯誤 bump 會恆真通過。spec 措辭與規劃的測試策略矛盾（spec-requirement-no-backing-task 同類：規範句無對應 task，task 反而做相反的事）。
   - recommendation: 該句 scope 收窄為本 specification 的 scenario/example，並明文要求迴歸測試以同步釘死值實作、每次 bump 時更新。

### Suggestion

1. severity: Suggestion｜confidence: 75｜reviewer: B（原 Warning，confidence ∈ [50, 80) 降級）
   - location: design.md 決策一/決策二 vs delta spec ADDED requirement 第一、二段
   - summary: layer 分類與覆核都發生在 fix 之前、輪型於 decision 時導出，若誠實標為 `text` 的 finding 在實際修正時被證偽為設計層（fix 必須改動行為或設計敘述），無規則允許把已導出的 micro 輪升級回 full 輪。
   - recommendation: 補「fix 後單向改判」規則：任何 fix 實際改動行為或設計敘述 → 下一輪必為 full；改判僅允許 micro→full。
2. severity: Suggestion｜confidence: 70｜reviewer: A+B（原 Warning，confidence ∈ [50, 80) 降級）
   - location: tasks.md 3.1 vs delta ADDED requirement「MUST NOT reclassify a `design` finding to `text`」
   - summary: 主 agent 單向覆核（anti-gaming 三道防線之一）無對應防退化斷言。
   - recommendation: task 3.1 增列該關鍵句的 assert_contains。
3. severity: Suggestion｜confidence: 50｜reviewer: A
   - location: proposal.md「Modified Capabilities」vs「Impact」
   - summary: Modified Capabilities 敘述未涵蓋兩個 metadata requirement 的 scenario 宣告值化改寫，與 Impact 涵蓋面不同步。
   - recommendation: 補一短句。
4. severity: Suggestion｜confidence: 50｜reviewer: A
   - location: tasks.md 2.1 驗證條件 vs scripts/spectra-plus/generate.fish 實際輸出
   - summary: 「輸出四行 wrote/validated」與實況不符（每檔 2 行、共 8 行）。
   - recommendation: 改為「四組 wrote/validated 行（共 8 行）」。
5. severity: Suggestion｜confidence: 50｜reviewer: B
   - location: apply-notes-block.md「Sub-agent reviewer requirement」段末句 vs tasks.md 1.5
   - summary: 段末收尾句「Reviewer A findings already incorporate the notes context」在微型輪不成立，task 1.5 的最小改寫範圍未點名此句，有漏改風險。
   - recommendation: task 1.5 明文涵蓋該收尾句改為輪型中立措辭。

## Rating

- surviving Critical: 0
- surviving Warning: 1
- critical_gap: false
- round_type: full
- rationale: 兩個 fresh reviewer 全量重讀確認 Round 1 的 11 條修正傳播完整、6 個 MODIFIED 與 master 逐句 diff 僅含宣告內修改、design 程式碼主張全數屬實。去重後僅 1 條 Warning 存活 confidence filter（spec 新增句把 test assertions 誤納入禁止硬編碼的主詞，與正確的測試釘死策略矛盾）；另 5 條 Suggestion（含 2 條由 [50, 80) 降級，其中「fix 後 micro→full 改判」雖降級但屬有價值的規則補強，一併採納修正）。依機械規則任何 surviving Warning 即 `next_round`。

## Fix Actions

全部 1 條 Warning 與 5 條 Suggestion 均已修正：

1. （W1）delta spec 兩個 metadata requirement 的規範句改寫：「Scenarios and examples in this specification MUST reference the values declared in `scripts/spectra-plus/rules.yaml` instead of hard-coding version or date literals. Regression tests MUST pin the currently declared values as synchronized literals, updated on each bump」；`design.md` 決策四同步補「迴歸測試不在此限」的理由句；`proposal.md` Modified Capabilities 同步。
2. （S1）delta spec ADDED requirement 第二段補「fix 後單向改判」規則並新增 Scenario「Fix that touches behavior escalates the next round to full」；`proposal.md` What Changes、`design.md` 決策二、`tasks.md` 1.2 同步傳播。
3. （S2）`tasks.md` 3.1 增列主 agent 單向覆核關鍵句與 fix 後改判關鍵句的 assert_contains；`design.md` 決策四斷言清單同步。
4. （S3）`proposal.md` Modified Capabilities 補 metadata scenario 宣告值化改寫的涵蓋敘述（與 W1 修正合併完成）。
5. （S4）`tasks.md` 2.1 驗證條件改為「四組 wrote/validated 行（共 8 行）」。
6. （S5）`tasks.md` 1.5 明文涵蓋 apply-notes-block.md 段末收尾句改為輪型中立措辭。

修正後已重跑：`spectra validate` ✓、機械自檢（註解配對、計數 1 ADDED + 6 MODIFIED、改判規則與同步釘死值措辭在四份 artifacts 的傳播檢查）✓。

## Decision

next_round
