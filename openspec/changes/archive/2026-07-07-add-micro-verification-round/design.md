## Context

`spectra-propose-plus` 與 `spectra-apply-plus` 共用 `scripts/spectra-plus/template/review-loop-block.md` 作為 review loop 的模板來源，由 `scripts/spectra-plus/generate.fish` 依 `rules.yaml` 產生四個 SKILL.md（claude/codex 各兩個）。現行收斂規則：每輪由兩個 fresh reviewer（A — Adherence、B — Quality）全量重讀，confidence filter 後若有任何 surviving Critical 或 Warning 即 `next_round`，下一輪再度全量重讀，上限 6 輪。

實務痛點：文字級 Warning（artifact 之間計數不同步、識別符拼寫、措辭一致性）修正成本一句話，但驗證成本是一整輪雙 reviewer 全量重讀。模板近期已加入「Pre-round mechanical self-check」與「Fix propagation」協議（version 1.2.0），已能攔下大部分機器可查的缺陷；本設計在其上補收斂規則分級。

## Goals / Non-Goals

**Goals:**

- 純文字級 Warning 的收斂成本從「兩個 reviewer 全量重讀」降為「單一 reviewer 驗證修正處與傳播範圍」。
- 設計層 finding 的把關強度維持不變：任何 Critical 或設計層 Warning 仍觸發全量輪。
- 防鑽漏洞：微型輪不得連續出現；layer 分類存疑時一律從嚴。

**Non-Goals:**

- 不改變 6 輪上限、confidence rubric、confidence filter 門檻與機械決策規則本身。
- 不改變 round file 的四段結構（`## Reviewer Findings` / `## Rating` / `## Fix Actions` / `## Decision`）。
- 不動 signals write step 與 propose-plus scope-scan 的 signals read step；review-loop 內「Signals in reviewer context」僅做輪型中立的措辭調整（微型輪的 Reviewer V 同樣收到相關 open signals），不改其讀取語意。
- 不動機械自檢與修正傳播協議的既有內容。
- 不為微型輪引入新的 sub-agent 失敗處理規則（沿用現行單一角色 retry/abort 規則）。

## Decisions

### 決策一：finding 新增 layer 欄位，由 reviewer 標註、主 agent 保守覆核

每個 finding 新增必填欄位 `layer`，值為 `design` 或 `text`：

- `design`：涉及行為、架構、安全、正確性、scope 或任何設計決策的 finding。
- `text`：僅涉及 artifact 之間一致性（計數、識別符拼寫、措辭、章節同步），且修正後不改變任何設計決策或行為敘述實質的 finding。

由 reviewer 標註（reviewer 最了解 finding 語境），主 agent 在套用 confidence filter 時覆核所有標為 `text` 的 finding：只要修正可能觸及行為或設計敘述，就改標 `design`。Reviewer 與主 agent 都遵守同一條保守規則：**分不清楚時一律標 `design`**。兩個全量輪 reviewer 對同一 finding（依 `location + summary` 去重合併為 A+B）標出不同 `layer` 時，合併後一律取 `design`（與保守規則同向）。替代方案「由主 agent 事後統一分類」被否決 —— 主 agent 未讀過 reviewer 的驗證過程，分類品質較差，且違反現行「main agent 只做機械決策」的分工。

### 決策二：微型驗證輪的觸發與回退規則

在「Round limit and pass condition」加入輪型判斷。設本輪（第 N 輪）decision 為 `next_round`：

- 若 surviving Critical 數為 0，且所有 surviving Warning 的 `layer == text`，且第 N 輪是全量輪 → 第 N+1 輪為**微型驗證輪（micro round）**。
- 其餘情況（任何 surviving Critical、任何 `layer == design` 的 surviving Warning、或第 N 輪本身是微型輪）→ 第 N+1 輪為**全量輪（full round）**。
- **fix 後改判（單向）**：導出的輪型在下一輪 reviewer spawn 前為暫定。decision 記錄後的任何 artifact 修改（apply-plus 加上 implementation file 修改；包含但不限於 fix action、機械自檢修正、validate 錯誤修正；窗口內其他來源的修改如 ingest 或手動編輯，同樣觸發改判評估）若實際改動了行為或設計敘述（而非僅跨 artifacts 的文字同步），主 agent 必須把下一輪改判為全量輪；主 agent 無法確定某修改是否僅為文字同步時，必須視同改動行為並改判為全量輪（與 layer 的保守 tie-breaker 對稱）。改判僅允許 micro→full，永不反向；改判發生時必須在本輪 round file 的 `## Fix Actions` 末尾記一行改判註記（觸發的修改與理由），供事後稽核。此規則堵住「誠實標為 `text` 的 finding 在修正時才被證偽為設計層」的路徑 —— layer 分類是修正前的預測，最終判準是修改的實際內容。

微型驗證輪 spawn 恰好一個 fresh 驗證 reviewer（**Reviewer V — Verification**）。Reviewer V 的 context 明文定義為：artifact paths（apply-plus 加上 changed-file list）、上一輪 round file 的 surviving findings 與 `## Fix Actions` 內容，以及與全量輪 reviewer 相同的相關 `open` signals（「Signals in reviewer context」對微型輪同樣適用，模板措辭改為輪型中立，如 "all of that round's reviewers"）。驗證項目限定為：每個 fix 的落點是否正確修復、修正傳播是否完整（同概念在所有 artifacts／changed files 的出現處已同步）、有無因修正引入的新缺陷。Reviewer V 的 finding 欄位要求與 A/B 完全相同（含 `layer` 與 `confidence`），同樣經過 confidence filter。

apply-plus 的微型輪中，Reviewer V 承接 Implementation Notes Protocol 原本定義給 Reviewer A 的 per-round `implementation-notes.md` 讀取義務（含 file-absent 即 Critical、未解決 `open-question` 即 Warning 的 severity 規則）；`apply-notes-block.md` 做最小改寫以涵蓋微型輪，且保留 `generator-checks.fish` 既有釘死句「Reviewer A — Adherence in the Sub-Agent Review/Rating/Fix Loop MUST」的前綴不變。

- Reviewer V 無 surviving Critical/Warning → `decision: passed`。
- Reviewer V 有任何 surviving Critical/Warning → `decision: next_round`，修正後下一輪回到全量輪（微型輪不得連續，防止以 `text` 分類無限降級把關強度）；第 6 輪未達 pass 條件時依現行規則寫 `decision: aborted`。

### 決策三：微型輪計入回合上限並沿用 round file 結構

微型驗證輪佔用 6 輪上限的 round 計數，照常寫 `<skill>-r<N>.md`，維持四段結構；`## Rating` 段新增 `round_type` 欄位（`full` 或 `micro`）。第 1 輪永遠是全量輪。若第 6 輪為微型輪且未達 pass 條件，依現行規則寫 `decision: aborted`。替代方案「微型輪不計入上限」被否決 —— 會讓 abort 上限語意複雜化，且最壞情況下（full→micro 交替）總輪數翻倍。

### 決策四：落地於共用模板、generator 版本與測試斷言

- `scripts/spectra-plus/template/review-loop-block.md`：finding 欄位表加入 `layer`（含分類 rubric、保守規則、A+B 合併取 `design` 規則）；「Round limit and pass condition」加入輪型判斷（含 fix 後單向改判、保守 tie-breaker、改判註記）；「Fresh sub-agent calls」改寫為「全量輪兩個 reviewer、微型輪恰好一個 Reviewer V」並將「Signals in reviewer context」的 "BOTH reviewers" 與「Reviewer output requirements」段首句 "Both reviewers" 等雙 reviewer 假設措辭改為輪型中立；「Decision record requirements」段同步記錄 `round_type`；round file schema 的 `## Rating` 說明加入 `round_type`；round file language 的 verbatim 清單加入 `layer`、`round_type` 與其值。
- `scripts/spectra-plus/template/apply-notes-block.md`：「Sub-agent reviewer requirement」段最小改寫 —— 微型輪由 Reviewer V 履行 per-round `implementation-notes.md` 讀取義務，保留既有釘死句前綴。
- `scripts/spectra-plus/rules.yaml`：兩個 skill 的 `spectraPlusVersion` bump 至 `1.3.0`、`spectraPlusUpdated` 更新為實作當日。
- `scripts/spectra-plus/tests/generator-checks.fish`：版本釘死值同步；新增防退化斷言（`Reviewer V — Verification`、`round_type`、`layer`、微型輪不得連續關鍵句、微型輪觸發條件關鍵句、layer 保守規則關鍵句、主 agent 單向覆核關鍵句、fix 後 micro→full 單向改判關鍵句、改判保守 tie-breaker 關鍵句、改判註記關鍵句、A+B layer 合併取 `design` 關鍵句、apply-plus 微型輪 implementation-notes 義務句）。
- `scripts/spectra-plus/tests/repair-all-checks.fish`：`plus_version` / `plus_updated` 變數同步（該檔其餘版本引用已改為變數，無硬編碼殘留）。
- delta spec 同步修改「Generated plus skill version metadata」與「Repair checks plus metadata freshness」兩個 requirement：本 spec 的 scenario/example 斷言改以 `rules.yaml` 宣告值為準，不再硬編碼版本/日期字面值，一勞永逸消除版本 bump 造成的 spec 字面 drift（master 現值 1.1.0 對實際 1.2.0 的既有 drift 也一併被此改寫吸收）。迴歸測試不在此限 —— spec 明文要求測試以「同步釘死值」實作（每次 bump 時更新），因為測試若動態讀 rules.yaml，錯誤的 bump 會恆真通過，失去防退化意義。
- 跑 `scripts/spectra-plus/generate.fish` 重生四個 SKILL.md，並跑全部四個測試套件。

## Implementation Contract

- **行為**：review loop 一輪結束若 decision 為 `next_round`，主 agent 依決策二的規則決定下一輪型態；微型輪只 spawn 一個 Reviewer V（context 含 artifact paths、apply-plus changed-file list、上一輪 findings 與 Fix Actions、相關 open signals），全量輪維持兩個 reviewer 並行；apply-plus 微型輪由 Reviewer V 履行 implementation-notes 讀取義務。使用者可從 round file 的 `## Rating` 中 `round_type` 欄位辨識輪型。
- **資料形狀**：finding 欄位集合為 `severity`、`confidence`、`layer`、`location`、`summary`、`recommendation`（`layer` 為新增，其值僅 `design` 或 `text`）；round file `## Rating` 欄位集合為 surviving Critical 數、surviving Warning 數、`critical_gap`、`round_type`、rationale（`round_type` 為新增，其值僅 `full` 或 `micro`）。
- **失敗模式**：Reviewer V 無回應或輸出格式錯誤 → 同輪以 fresh invocation retry 一次；同輪同角色連續兩次失敗 → 整個 plus workflow abort 並寫 `decision: aborted`（沿用現行規則，不新增分支）。
- **驗收標準**：(1) `scripts/spectra-plus/generate.fish` 成功重生四個 SKILL.md 且四個輸出都含 `Reviewer V — Verification`、`round_type`、`layer` 關鍵內容；(2) `scripts/spectra-plus/tests/generator-checks.fish`、`repair-all-checks.fish`、`auto-restore-checks.fish`、`installer-commit-guard-checks.fish` 全數 PASS；(3) 手動檢視模板：微型輪觸發條件、微型輪不得連續、layer 保守規則三者皆以 MUST 語氣明文存在。
- **Scope 邊界**：只動決策四列出的五個來源檔（review-loop-block.md、apply-notes-block.md、rules.yaml、兩個測試檔）與四個衍生 SKILL.md；不動 `signals-read-block.md`、`surgical-simplicity-block.md` 等其他模板；不動 spectra CLI 與 installer。

## Risks / Trade-offs

- [Reviewer 濫標 `text` 使設計層問題以微型輪滑過] → 三重防線：分不清楚時一律 `design` 的明文規則、主 agent 覆核可單向升級（`text`→`design`）、微型輪不得連續（下一輪必回全量）。
- [Reviewer V 視野限縮於修正處，漏掉修正引入的遠端缺陷] → 修正傳播協議要求 fix 時已 grep 全部出現處；機械自檢在 spawn 前照跑；Reviewer V 的驗證項目明文包含「因修正引入的新缺陷」。
- [輪型判斷增加主 agent 的規則複雜度，且 fix 後改判判準（修改是否僅為文字同步）是整套規則中唯一的非機械裁量點，主 agent 有省成本動機把修改判為純文字同步] → 導出條件本身維持純機械（Critical 數、Warning layer 集合、上一輪型態）；唯一的裁量點以三道防線約束：無法確定時必須視同改動行為的保守 tie-breaker、改判僅允許 micro→full 單向、改判註記強制記錄於 `## Fix Actions` 供事後稽核。
- [layer 分類本身成為 reviewer 之間新的不一致來源] → layer 只影響「下一輪的驗證成本」，不影響 pass/fail 判定；最壞情況是保守分類多跑全量輪，回到現狀成本。
- [被 confidence filter 降級的 design 層 finding（confidence ∈ [50, 80)）不阻擋微型輪，若 loop 在微型輪 `passed` 收束，舊規則下「下一輪 fresh full-round reviewer 以更高 confidence 重新發現該問題」的路徑會關閉] → 明示接受此取捨：降級 finding 依既有規則本就不參與決策，其複查本質上靠 fresh eyes 的隨機性而非制度保證；換得的收斂成本下降是本 change 的核心目的。降級的 Suggestion 仍留在 round file 供人工查看。

## Migration Plan

模板與測試同 commit 落地，`generate.fish` 重生衍生檔後即生效；無資料遷移。回滾即 revert 該 commit 並重跑 generator。舊 change 既有的 round files 不受影響（新欄位只約束新產生的 round file）。

## Open Questions

（無）
