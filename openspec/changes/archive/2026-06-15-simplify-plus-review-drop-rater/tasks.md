## 1. 更新 generator 測試（TDD：先紅）

- [x] 1.1 在 `scripts/spectra-plus/tests/generator-checks.fish` 更新斷言：對**全部四個產生後的 `SKILL.md`**（`.claude/` 與 `.agents/` 各兩個，迴圈套用，比照既有 reviewer 斷言的寫法）斷言內容**不含** `rater` 與 `quality_score`，且 apply-plus 兩檔與 propose-plus 兩檔皆**含**機械 decision 規則文字（如「surviving Critical」/「surviving Warning」）與「每輪兩個 reviewer、無 rater」描述。涵蓋全部四檔是為了攔截「只改 `review-loop-block.md` 卻漏改 `apply-notes-block.md`」導致 apply-plus 產出殘留 rater 的情況。驗證：在尚未改 template 前執行 `scripts/spectra-plus/tests/generator-checks.fish` 應為紅（新斷言失敗）。

## 2. 改 review loop 來源 template（TDD：轉綠）

- [x] 2.1 編輯 `scripts/spectra-plus/template/review-loop-block.md`：移除 rater 角色（「Fresh sub-agent calls」段改為每輪僅兩個並行 reviewer、主 agent filter 後自行判定）、移除 `Rater output requirements` 段、移除 `quality_score` 欄位與 `quality_score > 9 AND critical_gap == false` pass 條件，改寫為機械規則（存活 Critical → next_round；否則存活 Warning → next_round；否則 passed）。`critical_gap` 保留為機械衍生值。**不要改 loop 名稱**：保留標題 `10. **Sub-Agent Review/Rating/Fix Loop**` 與句中「review/rating/fix loop」字串（`generator-checks.fish` 對此有斷言）。驗證：template 內 `grep -i 'rater\|quality_score'` 無結果；`grep -c 'review/rating/fix'` ≥ 1；內容含機械規則三分支。
- [x] 2.2 更新 `template/review-loop-block.md` 的 round file schema 與語言規則：`## Rating` 描述改為「surviving Critical 數 + surviving Warning 數 + `critical_gap` + rationale」，移除語言規則中對 `quality_score` 的逐字保留條目；維持五個 heading（`#` + 四個 `##`）不變。驗證：schema 段不再提及 `quality_score`，仍列出 `## Reviewer Findings` / `## Rating` / `## Fix Actions` / `## Decision`。
- [x] 2.3 編輯 `scripts/spectra-plus/template/apply-notes-block.md`：改寫其中對 rater 的引用句（「The rater (Section 10) does not read this file directly...」），改以「主 agent 在 confidence filter 後依機械規則判定，不直接讀此檔；reviewer findings 已納入 notes 脈絡」表達，使 apply-plus 產出不再殘留 `rater`。驗證：`grep -i 'rater\|quality_score' scripts/spectra-plus/template/apply-notes-block.md` 無結果。
- [x] 2.4 檢查 `scripts/spectra-plus/rules.yaml` 與 `scripts/spectra-plus/generate.fish` 是否有 rater / `quality_score` 的 per-skill 文字或斷言；若有則一併移除/更新，若無則確認不需改動並記錄。驗證：`grep -ni 'rater\|quality_score' scripts/spectra-plus/rules.yaml scripts/spectra-plus/generate.fish` 結果為空或僅剩無關項。

## 3. 重新產生 plus skills 並驗證

- [x] 3.1 執行 `scripts/spectra-plus/generate.fish` 重新產生四個 `SKILL.md`（`.claude/` 與 `.agents/` 各兩個），且不手改產出檔。驗證：generator exit code 0；四個 `SKILL.md` 皆含 `DO NOT EDIT MANUALLY` 標頭。
- [x] 3.2 驗證冪等性：連續執行 `scripts/spectra-plus/generate.fish` 兩次，兩次產出 byte-identical。驗證：第二次執行後 `git diff --stat` 對四個 `SKILL.md` 無變化。
- [x] 3.3 執行 `scripts/spectra-plus/tests/generator-checks.fish`，全數通過（步驟 1 的新斷言轉綠）。驗證：測試 exit code 0。

## 4. 整體驗證

- [x] 4.1 確認四個產生後的 `SKILL.md` 與兩個來源 template 皆不含 `rater` 與 `quality_score`，且四個 `SKILL.md` 含機械規則與「兩個 reviewer、無 rater」描述。驗證：`grep -rli 'rater\|quality_score' .claude/skills/spectra-*-plus .agents/skills/spectra-*-plus scripts/spectra-plus/template/review-loop-block.md scripts/spectra-plus/template/apply-notes-block.md` 結果為空。
- [x] 4.2 執行 `spectra validate "simplify-plus-review-drop-rater"` 通過。驗證：validate exit code 0、無 error。
