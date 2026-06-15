## Context

`spectra-propose-plus` 與 `spectra-apply-plus` 共用一段 review/rating/fix loop，其單一真實來源是 `scripts/spectra-plus/template/review-loop-block.md`，經 `scripts/spectra-plus/generate.fish`（讀 `rules.yaml` + template）產生四個 `SKILL.md`（`.claude/` 與 `.agents/` 各兩個，檔頭標記 `DO NOT EDIT MANUALLY`）。其行為契約寫在 master spec `openspec/specs/spectra-plus-skills/spec.md`。

現行每輪流程：兩個並行 reviewer（A=Adherence、B=Quality）產出帶 `severity` + `confidence` 的 findings → 主 agent 去重並套 confidence filter → 一個獨立 rater sub-agent 讀「過濾後 findings」吐 `quality_score`（0–10）、`critical_gap`、rationale → 主 agent 依 `quality_score > 9 AND critical_gap == false` 判定是否 pass。

關鍵觀察：rater 與主 agent 看到同一份過濾後清單、不重讀程式碼；`critical_gap` 在 filter 後已機械確定；`quality_score` 無 rubric。rater 因此是同資訊上的多餘序列 round-trip。

## Goals / Non-Goals

**Goals:**

- 移除 rater sub-agent，砍掉每輪一個序列 round-trip。
- 以可重現的機械規則取代 `quality_score`-based pass 判定，消除「無 rubric 的主觀分數」與「做事者自評放水」兩種風險。
- 在行為上盡量貼近原本 `> 9` 的高標（採嚴格政策：Warning 也擋）。
- 維持四個 `SKILL.md` 與 master spec 的一致性，且 generator 仍冪等。

**Non-Goals:**

- 不動兩個 reviewer 的數量、角色或並行方式（reviewer 是真正讀 artifacts/diff 的獨立視角，不在本次精簡範圍）。
- 不改 confidence scoring rubric、confidence filter、common false positives 清單。
- 不改 6 輪上限、failure handling、round file 路徑與 `## Reviewer Findings` / `## Fix Actions` / `## Decision` 三個 section、語言規則。
- 不引入「Warning 可放行」的寬鬆模式或任何可設定開關（YAGNI）。
- 不觸碰 `spectra-commit` guard、installer、repair-all、LaunchAgent 等其他 requirements。

## Decisions

### 決策 1：移除 rater，pass 判定改為主 agent 在 filter 後的機械規則

主 agent 在 confidence filter 完成後（findings 已分流為 Critical / Warning / Suggestion，且只有 confidence ≥ 80 能留在 Critical/Warning），依下列順序得出 `decision`：

1. 存活集合含 `severity == Critical` → `next_round`
2. 否則存活集合含 `severity == Warning` → `next_round`
3. 否則（僅 Suggestion 或空）→ `passed`

達 6 輪上限仍未 `passed` → `aborted`（不變）。

**為何不讓 reviewer 直接評分（使用者最初提案）**：有兩個 reviewer，會得到兩個分數需要 reconciliation；且 reviewer 在 filter「之前」評分，會把該被丟棄/降級的雜訊算進去，分數失真；找問題的人自評亦有 bias。機械規則完全避開這三點。

**為何不保留 rater 只改 rubric**：rater 不重讀程式碼，看到的就是主 agent 已有的清單，無新資訊；保留它只是多一個序列 agent。

### 決策 2：嚴格政策——存活 Warning 也擋 pass

原 `quality_score > 9` 等同「近乎無瑕才放行」。機械化後若放行 Warning，門檻會比現狀鬆。採「Critical 或 Warning 任一存活即 next_round」最貼近現行高標。Suggestion（含被 confidence filter 從 50–80 降級者）不擋 pass，僅供可視性。

### 決策 3：移除 round file 的 `quality_score` 欄位

`## Rating` 區塊不再有沒有 rubric 的分數。改為記錄機械判定的依據：存活 Critical 數、存活 Warning 數、`critical_gap`（機械衍生，保留）、一段 rationale 說明該輪為何 pass/next_round。round file 仍維持五個 heading（`#` 標題 + 四個 `##`），section 數量與名稱不變。

### 決策 4：改 template 來源 + 重新產生，不手改 `SKILL.md`

真正編輯 `scripts/spectra-plus/template/review-loop-block.md`（必要時 `rules.yaml` / `generate.fish`），再跑 generator 重新產生四個 `SKILL.md`。`generator-checks.fish` 內任何斷言 rater / `quality_score` 字串存在的檢查需同步更新。

## Implementation Contract

**Behavior（observable）**

- 執行任一 plus skill 的 review loop 時，每輪只 spawn 兩個 reviewer sub-agent（並行），不再 spawn rater sub-agent。
- 每輪 `decision` 由主 agent 依「存活 Critical → next_round；否則存活 Warning → next_round；否則 passed」得出；6 輪未過為 `aborted`。
- 產生的 round file `## Rating` 區塊不含 `quality_score`；含存活 Critical/Warning 計數、`critical_gap`、rationale。

**Interface / data shape**

- `scripts/spectra-plus/template/review-loop-block.md`：移除所有 rater 角色描述、`quality_score` 欄位定義、`Rater output requirements` 段、以及 `quality_score > 9 AND critical_gap == false` 的 pass 條件；以機械規則文字取代；更新「Fresh sub-agent calls」段為「每輪兩個 reviewer，無 rater」；更新 round file schema 的 `## Rating` 描述與語言規則中對 `quality_score` 的引用。**保留不改名**：loop 標題 `10. **Sub-Agent Review/Rating/Fix Loop**`、句中「review/rating/fix loop」字串、以及 `## Rating` section 名稱維持不變——`## Rating` section 仍存在（改記錄機械判定結果），且 `generator-checks.fish` 斷言 `review/rating/fix` 字串存在；本次只移除 rater *agent* 與 `quality_score` *欄位*，不是移除「rating」這個概念，故 loop 名稱不動。
- `scripts/spectra-plus/template/apply-notes-block.md`：此為 apply-plus 專屬的第二段來源 template，其內含一句 rater 引用（「The rater (Section 10) does not read this file directly...」）。改寫該句，改以「主 agent 在 filter 後依機械規則判定，不直接讀此檔；reviewer findings 已納入 notes 脈絡」表達，使 apply-plus 產出不再殘留 `rater`。
- master spec `openspec/specs/spectra-plus-skills/spec.md`：本次以 delta spec 修改 capability `spectra-plus-skills`（見 specs 階段），涵蓋六個 requirements 與其 scenarios/examples：`spectra-propose-plus quality gate`、`spectra-apply-plus quality gate`、`Round file output contract`、`Fresh sub-agent per round`、`Confidence-scored findings and filter`（將「before passing findings to the rater」改為「before deriving the round decision」、scenario「the rater does not see it」改為「it does not contribute to the round decision」）、`Sub-agent failure handling`（將 scenario「a reviewer or the rater sub-agent fails」改為僅 reviewer）。
- 重新產生：`.claude/skills/spectra-propose-plus/SKILL.md`、`.claude/skills/spectra-apply-plus/SKILL.md` 及對應 `.agents/` 兩檔。

**Failure modes**

- reviewer 失敗處理維持原樣（retry 一次、兩次連續失敗 abort）；rater 相關的失敗分支整段移除。
- 機械規則無 sub-agent 參與，不會有「rater 回傳 malformed」的失敗態。

**Acceptance criteria**

- `scripts/spectra-plus/generate.fish` 執行成功（exit 0）且二次執行 byte-identical（冪等）。
- 產生後的四個 `SKILL.md` 與兩個來源 template（`review-loop-block.md`、`apply-notes-block.md`）皆不再出現 `rater`、`quality_score` 字樣（本次選擇完全移除，不留歷史說明）。
- `scripts/spectra-plus/tests/generator-checks.fish` 全數通過，且其斷言對「全部四個產出檔」同時檢查「不含 rater/quality_score」與「含機械規則文字」，以攔截僅改單一 template 而漏掉 `apply-notes-block.md` 的情況。
- `spectra validate "simplify-plus-review-drop-rater"` 通過。
- master spec 經 archive 同步後，六個相關 requirement 不再描述 rater 或 `quality_score > 9`。

**Scope boundaries**

- In scope：review loop 的 rater 移除、pass 判定機械化、`quality_score` 欄位移除、四個 `SKILL.md` 重新產生、相關 master spec requirement 更新、generator 測試更新。
- Out of scope：reviewer 數量/角色、confidence filter/rubric、6 輪上限、failure handling 其餘部分、`spectra-commit`/installer/repair-all/LaunchAgent 相關 requirements、其他非 plus skills。

## Risks / Trade-offs

- [失去整體「綜觀」判斷：個別 finding 都不嚴重、但合起來代表方向錯誤的情況，rater 理論上可給低分擋下] → 此判斷 rater 本來也只能從 finding 摘要做（與主 agent 同資訊），且 Reviewer A 的 scope/adherence 與 Reviewer B 的 quality 已涵蓋「方向錯誤」類問題並可標 Critical；嚴格政策確保任一 Warning 即 next_round，安全邊際偏保守。
- [嚴格政策可能增加輪數：Warning 也擋，可能比模糊的 `> 9` 多跑一兩輪] → 仍受 6 輪上限保護；且每輪少一個 rater，淨延遲多半下降。此為刻意取捨，偏向品質。
- [generator 冪等性與測試斷言遺漏：忘了更新 `generator-checks.fish` 內檢查 rater/quality_score 的斷言會導致測試紅燈或假綠燈] → Acceptance criteria 明列測試需通過，dev 階段先讀測試再改。
- [四個 `SKILL.md` 與 `.agents`/`.claude` 不同步：手改而非重新產生會被下次 generator 覆蓋] → 一律改 template 來源後 regenerate，符合「Plus skills are not hand-edited」requirement。
- [行為變更：Suggestion-only 的一輪現在會立即 `passed`] → 移除 rater 後，若某輪所有 finding 都被 confidence filter 丟棄（< 50）或降級為 Suggestion（50–80），機械規則會判 `passed`；舊規則下 rater 理論上仍能從 Suggestion 級摘要給出低 `quality_score` 而擋下。此為刻意取捨：confidence rubric 已要求「verified to be real and will hit in practice」者標 ≥ 80（落入 Warning/Critical），故真正會踩到的問題不會只停在 Suggestion；殘餘風險可接受，於此明列以免被視為未預期行為。
- [遺漏第二來源 template：apply-plus 由 `review-loop-block.md` 與 `apply-notes-block.md` 兩段組成，只改前者會讓 apply-plus 產出殘留 rater 並使 acceptance 的 grep 失敗] → Implementation Contract 已將 `apply-notes-block.md` 納入；generator 測試對全部四個產出檔斷言，dev 階段以此攔截。
