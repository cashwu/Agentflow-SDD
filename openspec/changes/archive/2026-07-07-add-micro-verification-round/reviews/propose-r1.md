# Propose Plus Review — Round 1

## Reviewer Findings

### Critical

（無）

### Warning

1. severity: Warning｜confidence: 100｜reviewer: A+B
   - location: `specs/spectra-plus-skills/spec.md` — MODIFIED「spectra-apply-plus quality gate」→ Scenario: Archive guidance waits for gate pass
   - summary: delta 意外改寫 master 既有場景句（「the final response may suggest archiving the change」被改為「archive guidance is no longer deferred in the final response」），改動不在本 change 宣告範圍內。
   - recommendation: 還原為 master 原文；若要改措辭須在 proposal 明文宣告。
2. severity: Warning｜confidence: 100｜reviewer: A+B
   - location: proposal.md「What Changes」第三點 vs design.md 決策二 vs delta spec ADDED requirement 第三段
   - summary: Reviewer V 驗證項目第三項三份 artifacts 不一致 —— proposal 寫「機械自檢結果」（且與模板既有規則「自檢結果 never feed the round decision」矛盾），design/delta spec 寫「修正引入的新缺陷」。
   - recommendation: 統一為「fix 落點 + 修正傳播完整性 + 修正引入的新缺陷」，修正 proposal。
3. severity: Warning｜confidence: 100｜reviewer: B
   - location: design.md「Scope 邊界」＋ scripts/spectra-plus/template/apply-notes-block.md「Sub-agent reviewer requirement」＋ delta spec ADDED requirement
   - summary: apply-notes-block.md 規定 Reviewer A 每輪必讀 `implementation-notes.md`（含 file-absent 即 Critical 等規則），但微型輪沒有 Reviewer A，且 scope 邊界明文排除 apply-notes-block.md —— apply-plus 微型輪的 implementation-notes 檢查義務出現真空。
   - recommendation: Reviewer V 承接該義務，apply-notes-block.md 納入 scope 做最小改寫。
4. severity: Warning｜confidence: 80｜reviewer: A
   - location: proposal.md Impact / delta spec 缺 MODIFIED ↔ master spec「Generated plus skill version metadata」「Repair checks plus metadata freshness」
   - summary: 本 change bump 版本至 1.3.0，但 master spec 兩個 requirement 的 scenario 以字面值釘死 `spectraPlusVersion: 1.1.0` / `spectraPlusUpdated: 2026-07-04`，delta 未 MODIFIED，重生後輸出將違反這些 scenario 斷言（與 open signal spec-precedence-exception-missing 同類；master 1.1.0 對實際 1.2.0 的 drift 為既有問題，但本 change 再度改值卻未同步屬重複同類缺陷）。
   - recommendation: delta 增列兩個 MODIFIED requirement，scenario 斷言改以 rules.yaml 宣告值為準。
5. severity: Warning｜confidence: 80｜reviewer: A+B
   - location: 模板「Signals in reviewer context」（review-loop-block.md）vs proposal/design/tasks/delta spec
   - summary: 該句規定 open signals 塞進「BOTH reviewers」context，微型輪只有一個 Reviewer V，各 artifacts 均未定義微型輪的 signals context 行為，"BOTH reviewers" 措辭在單 reviewer 輪不成立。
   - recommendation: 明文規定 Reviewer V 同樣收到相關 open signals；模板措辭改輪型中立。
6. severity: Warning｜confidence: 80｜reviewer: B
   - location: design.md 決策二（Reviewer V context 定義）＋ delta spec ADDED requirement 第三段
   - summary: Reviewer V 的驗證義務包含跨 artifacts／changed files 的傳播檢查，但其 context 定義未含 artifact paths 與 changed-file list，義務與輸入不匹配；delta spec 亦未定義 V 的 input context。
   - recommendation: 將 artifact paths（及 apply-plus changed-file list）明文加入 V 的 context 定義（design 與 delta spec）。

### Suggestion

1. severity: Suggestion｜confidence: 75｜reviewer: B（原 Warning，confidence ∈ [50, 80) 降級）
   - location: tasks.md 3.1 vs design.md 驗收標準 (3)
   - summary: 防退化斷言只覆蓋「微型輪不得連續」，觸發條件與 layer 保守規則若被刪除測試抓不到（spec-requirement-no-backing-task 同類）。
   - recommendation: task 3.1 增列觸發條件與保守規則關鍵句斷言。
2. severity: Suggestion｜confidence: 70｜reviewer: A
   - location: proposal.md「What Changes」第一點 vs design/delta spec
   - summary: `text` 分類枚舉 proposal 漏列「章節同步」。
   - recommendation: proposal 補列，使三份 artifacts 枚舉一致。
3. severity: Suggestion｜confidence: 60｜reviewer: B（原 Warning，confidence ∈ [50, 80) 降級）
   - location: design.md「Risks / Trade-offs」與 confidence filter 降級規則的交互
   - summary: 被 filter 降級的 design 層 finding（confidence ∈ [50, 80)）不阻擋微型輪，micro `passed` 收束會關閉「下一輪 fresh full reviewer 重新發現」路徑，此取捨未在 Risks 明文記載。
   - recommendation: Risks 明文記載此取捨。
4. severity: Suggestion｜confidence: 55｜reviewer: B
   - location: tasks.md 1.4 vs 模板「Decision record requirements」段
   - summary: `round_type` 未同步加入「Decision record requirements」清單，模板內部兩處欄位清單可能不同步。
   - recommendation: task 1.4 的修改範圍納入該段。
5. severity: Suggestion｜confidence: 50｜reviewer: B
   - location: delta spec Scenario: Micro round findings escalate to a full round
   - summary: 該 scenario 無條件斷言 next_round，未帶第 6 輪 abort 例外的限定。
   - recommendation: requirement 正文或 scenario 加 6-round-cap 限定。

## Rating

- surviving Critical: 0
- surviving Warning: 6
- critical_gap: false
- round_type: full
- rationale: 兩個 reviewer 獨立回報、去重後（A2=B2、A4=B3、A1=B7 合併）共 6 條 confidence ≥ 80 的 Warning 存活 confidence filter，其中三條 100 分屬 artifact 間直接不一致或未宣告的 scope 外改動，三條 80 分屬義務/context 定義真空與 master spec 字面值未同步。無 Critical，但依機械規則任何 surviving Warning 即 `next_round`。另有 5 條 Suggestion（含 2 條由 [50, 80) 降級）一併記錄。

## Fix Actions

全部 6 條 Warning 與 5 條 Suggestion 均已修正：

1. （W1）`specs/spectra-plus-skills/spec.md`：還原「Archive guidance waits for gate pass」場景句為 master 原文「the final response may suggest archiving the change」；`spectra validate` 重跑通過。
2. （W2）`proposal.md`：Reviewer V 驗證項第三項由「機械自檢結果」改為「修正引入的新缺陷」，並補「修正傳播完整性」措辭，與 design/delta spec 對齊。
3. （W3）`proposal.md`（What Changes 新增一點、Impact 檔案清單）、`design.md`（決策二、決策四、Scope 邊界）、`tasks.md`（新增 task 1.5）、delta spec（ADDED requirement 第三段）：apply-plus 微型輪由 Reviewer V 承接 implementation-notes 讀取義務（含 severity 規則），`apply-notes-block.md` 納入 scope 做最小改寫並保留 generator-checks 釘死句前綴。
4. （W4）delta spec 增列 MODIFIED「Generated plus skill version metadata」「Repair checks plus metadata freshness」（scenario 斷言改以 `scripts/spectra-plus/rules.yaml` 宣告值為準）；`proposal.md` Impact 計數 4→6；`design.md` 決策四補此項；`tasks.md` 2.1 補此契約。
5. （W5）`proposal.md`、`design.md`（Non-Goals、決策二、決策四）、`tasks.md` 1.3、delta spec ADDED requirement：明文規定 Reviewer V 收到與全量輪相同的相關 open signals；模板 "BOTH reviewers" 措辭改為輪型中立列入實作範圍。
6. （W6）`proposal.md`、`design.md` 決策二與 Implementation Contract、delta spec ADDED requirement：Reviewer V context 明文加入 artifact paths 與 apply-plus changed-file list。
7. （S1）`tasks.md` 3.1：增列微型輪觸發條件、layer 保守規則、implementation-notes 義務句的 assert_contains。
8. （S2）`proposal.md`：`text` 分類枚舉補「章節同步」。
9. （S3）`design.md` Risks：明文記載「降級 design 層 finding 因 micro 收斂失去制度性複查」的取捨。
10. （S4）`tasks.md` 1.4：修改範圍納入「Decision record requirements」段同步 `round_type`。
11. （S5）delta spec：ADDED requirement 正文加 6-round-cap 限定句，escalate scenario 的 WHEN 改為「a micro round that is not round 6」。

修正後已重跑：`spectra validate` ✓、機械自檢（註解配對、計數一致性 1 ADDED + 6 MODIFIED vs proposal、MODIFIED 名稱與 master 完全一致、requirement ↔ task 覆蓋、識別符傳播）✓。

## Decision

next_round
