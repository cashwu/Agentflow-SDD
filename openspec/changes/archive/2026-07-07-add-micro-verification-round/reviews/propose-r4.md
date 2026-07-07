# Propose Plus Review — Round 4

## Reviewer Findings

### Critical

（無）

### Warning

（無 —— 本輪唯一原始 Warning 因 confidence 60 ∈ [50, 80) 依規則降級為 Suggestion，見下）

### Suggestion

1. severity: Suggestion｜confidence: 60｜reviewer: A+B（原 Warning，confidence ∈ [50, 80) 降級）
   - location: proposal.md「What Changes」第 3 點末句 vs design 決策二、delta spec ADDED requirement 第三段
   - summary: proposal 的微型輪回退句「發現任何未修復或新的 surviving finding → 回到全量輪」漏 Critical/Warning 限定詞，且把「所有修正完成」寫成 pass 的獨立必要條件，與 delta spec 的機械 pass 條件字面矛盾（design/delta 本身無歧義，實害低）。
   - recommendation: 改為與 delta 對齊的措辭（filter 後無 surviving Critical/Warning → passed）。
2. severity: Suggestion｜confidence: 60｜reviewer: B
   - location: tasks.md 3.1 / design 決策四斷言清單 vs design Risks 第三點的三道防線
   - summary: 三道 anti-gaming 防線只有兩道有防退化斷言，改判註記關鍵句無 assert_contains。
   - recommendation: 斷言清單增列改判註記關鍵句。
3. severity: Suggestion｜confidence: 55｜reviewer: A
   - location: delta spec ADDED requirement 第三段 vs 該 requirement 的 scenarios
   - summary: apply-plus 微型輪的 implementation-notes 讀取義務是唯一 apply-plus 特有條款，卻無 scenario 覆蓋。
   - recommendation: 增列對應 scenario（file-absent → Critical、open-question → Warning）。
4. severity: Suggestion｜confidence: 50｜reviewer: B
   - location: delta spec 改判觸發句（proposal/design/tasks 四處同構）
   - summary: 改判觸發來源為封閉枚舉（fix、自檢修正、validate 修正），窗口內的 out-of-band 修改（ingest、手動編輯）按字面不觸發改判。
   - recommendation: 枚舉改為例示性措辭（including …）。

## Rating

- surviving Critical: 0
- surviving Warning: 0
- critical_gap: false
- round_type: full
- rationale: 本輪兩個 reviewer 首次呼叫均因帳號 session 用量上限被中止（非 reviewer 輸出品質問題），依「兩個並行 reviewer 同輪失敗視為單一角色失敗」規則於配額重置後同輪 retry 一次，兩者均成功完成。Reviewer A 以腳本機械 diff 確認 6 個 MODIFIED 與 master 的差異全在宣告範圍、前三輪修正傳播完整、design 程式碼主張全數屬實；Reviewer B 確認改判窗口／tie-breaker／單向規則／合併規則之間無矛盾。去重後僅餘 4 條 Suggestion（1 條由 60 降級），confidence filter 後無任何 surviving Critical 或 Warning —— 達成 pass 條件。

## Fix Actions

Pass 條件已達成（Suggestion 不阻擋 pass）。因四條 Suggestion 均為一句話的文字級修正，本輪在記錄 decision 後一併採納修正，並重跑 validate 與機械自檢確認狀態一致：

1. （S1）proposal.md 微型輪回退句改為「Reviewer V 的 findings 經同一 confidence filter 後無 surviving Critical/Warning → `decision: passed`；有任何 surviving Critical/Warning → 修正後下一輪回到全量輪」。
2. （S2）tasks.md 3.1 與 design.md 決策四斷言清單增列改判註記關鍵句（re-derivation note 記於 `## Fix Actions` 末尾）的 assert_contains。
3. （S3）delta spec ADDED requirement 增列 Scenario「Apply-plus micro round reads implementation notes」（file-absent → Critical、unresolved open-question → Warning）。
4. （S4）改判觸發句四處（delta spec 正文與 escalate scenario、design 決策二、proposal、tasks 1.2）枚舉改為例示性措辭（including / 包含但不限於）；design 決策二並明示窗口內其他來源修改（ingest、手動編輯）同樣觸發改判評估。

修正後已重跑：`spectra validate` ✓、機械自檢（註解配對、ADDED 段 1 requirement + 10 scenarios、例示性措辭與改判註記斷言在各 artifacts 的傳播）✓。上述修正全屬文字同步層，未改動任何設計決策。

## Decision

passed
