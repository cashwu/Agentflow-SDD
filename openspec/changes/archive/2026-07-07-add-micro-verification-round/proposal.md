## Why

現行 review loop 的收斂規則是「任何 surviving Warning（confidence ≥ 80）→ 下一整輪」，每一輪都要 spawn 兩個 fresh reviewer 從零全量重讀所有 artifacts。對交叉面大的 change，一條一句話就能修好的文字級 Warning（計數不同步、識別符拼寫、措辭一致性）也會觸發整輪重審，單輪成本可達十萬 token 以上；實際案例中曾因此多燒 2 輪。文字級修正的驗證面很小（修正處 + 傳播範圍），不需要兩個 reviewer 全量重讀。

## What Changes

- Reviewer 產出的每個 finding 新增 `layer` 欄位，值為 `design` 或 `text`：`design` 指涉及行為、架構、安全、正確性或 scope 的 finding；`text` 指僅涉及 artifact 之間一致性（計數、識別符拼寫、措辭、章節同步）、且修正不改變任何設計決策或行為敘述的 finding。
- 收斂規則分級：一輪（全量輪）結束後若無 surviving Critical、且所有 surviving Warning 的 `layer == text`、且本輪為全量輪，修正完成後下一輪改跑「微型驗證輪（micro-verification round）」；其餘情況（任何 surviving Critical、任何 `layer == design` 的 surviving Warning、或本輪已是微型輪）下一輪為全量輪（full round）。導出的輪型在下一輪 reviewer spawn 前為暫定：decision 記錄後的任何 artifact 修改（apply-plus 加上 implementation file 修改；包含但不限於 fix、機械自檢修正、validate 修正）若實際改動行為或設計敘述 —— 或主 agent 無法確定是否僅為文字同步 —— 下一輪必須改判回全量輪；改判僅允許 micro→full 單向，且須在 round file 的 `## Fix Actions` 末尾記一行改判註記。
- 微型驗證輪：spawn 恰好一個 fresh 驗證 reviewer（Reviewer V），只驗證「上一輪每個 fix 的落點 + 修正傳播完整性 + 修正引入的新缺陷」，不做全量重讀。Reviewer V 的 context 包含 artifact paths（apply-plus 加上 changed-file list）、上一輪 round file 的 surviving findings 與 `## Fix Actions` 內容，以及與全量輪 reviewer 相同的相關 `open` signals。Reviewer V 的 findings 經同一 confidence filter 後無 surviving Critical/Warning → `decision: passed`；有任何 surviving Critical/Warning → 修正後下一輪回到全量輪（微型輪不得連續出現，防止收斂規則被鑽漏洞）。
- apply-plus 的微型輪中，Reviewer V 承接 Implementation Notes Protocol 原本定義給 Reviewer A 的 per-round `implementation-notes.md` 讀取義務（含 file-absent 與 `open-question` 的 severity 規則）；`scripts/spectra-plus/template/apply-notes-block.md` 做對應的最小改寫。
- 微型驗證輪佔用 6 輪上限的 round 計數，照常產出 round file；round file 的 `## Rating` 段新增 `round_type` 欄位（`full` 或 `micro`）。
- 失敗處理沿用現行單一角色規則：Reviewer V 失敗 retry 一次，同輪連續兩次失敗即 abort。
- 落地位置：共用模板 `scripts/spectra-plus/template/review-loop-block.md`（`spectra-propose-plus` 與 `spectra-apply-plus` 同時受惠），連同 generator 版本 bump 與測試斷言更新。

## Capabilities

### New Capabilities

（無）

### Modified Capabilities

- `spectra-plus-skills`: 收斂規則由「任何 surviving Warning → 全量下一輪」改為依 finding `layer` 分級 —— 純文字級 Warning 允許以單一 reviewer 的微型驗證輪收斂（含 fix 後 micro→full 單向改判規則）；「每輪恰好兩個 reviewer」的要求改為僅適用於全量輪，微型驗證輪恰好一個 reviewer；round file 的 `## Rating` 段新增 `round_type` 欄位；finding 欄位新增 `layer`；「Generated plus skill version metadata」與「Repair checks plus metadata freshness」的 scenario 斷言改以 `rules.yaml` 宣告值為準（迴歸測試以同步釘死值實作）。

## Impact

- Affected specs: `spectra-plus-skills`（新增 1 個 requirement：Graded convergence and micro-verification round；修改 6 個 requirement：spectra-propose-plus quality gate、spectra-apply-plus quality gate、Round file output contract、Fresh sub-agent per round、Generated plus skill version metadata、Repair checks plus metadata freshness —— 後兩者將 scenario 中硬編碼的版本/日期字面值改為以 `scripts/spectra-plus/rules.yaml` 宣告值為準，消除版本 bump 造成的 spec 字面 drift）
- Affected code:
  - Modified: scripts/spectra-plus/template/review-loop-block.md, scripts/spectra-plus/template/apply-notes-block.md, scripts/spectra-plus/rules.yaml, scripts/spectra-plus/tests/generator-checks.fish, scripts/spectra-plus/tests/repair-all-checks.fish
  - Regenerated（衍生產物，由 generator 重生）: .claude/skills/spectra-propose-plus/SKILL.md, .claude/skills/spectra-apply-plus/SKILL.md, .agents/skills/spectra-propose-plus/SKILL.md, .agents/skills/spectra-apply-plus/SKILL.md
  - New: （無）
  - Removed: （無）
