# Cash Propose Review — Round 5

## Reviewer Findings

本輪為 micro round，由單一 Reviewer V 執行 delta 驗證。

### 累積 blocking 集合成員的判定

進入本輪時集合中有三個成員，全部 `fix-introduced`。Reviewer V 逐一回傳判定，皆為 `resolved`：

- **X1**（Critical）：`resolved`。delta spec 明訂「(a) 與 (b) MUST 以多行視窗比對，MUST NOT 要求同行出現」，`design.md` D3 記錄三項實測依據並逐一點名 `cash-apply:79`–`:81`、`:139`–`:141`、`cash-ingest:110`–`:112`，`tasks.md` 3.2 同步；新增 `#### Scenario: 條件與替代作法分行的陳述被正確計入` 與 Example 表對應列。關於 (b) 軸措辭變異未逐一列舉字面值，Reviewer V 判定該風險已被新增的下界斷言機制性涵蓋——過窄的 regex 會使某個 skill 計為 0 而立即失敗，而非靜默漏檢。
- **X3**（Warning）：`resolved`。requirement 標題已改為 `### Requirement: Skill 互動 fallback 的單一陳述`，與主句一致；`檔案層級`、`全域表述`、`單一全域` 於四份 artifacts 為零命中。殘留的兩處 `全域規則` 出現在「得為獨立的全域規則，亦得內嵌於步驟句中」的並列列舉中，是允許形狀而非強制形狀，與主句相容。
- **X4**（Warning）：`resolved`。`#### Scenario: 具名例外在測試檔中可審閱` 已完全移除；`具名例外` 僅剩兩處反向陳述（說明該機制已移除且無適用對象）；「比照既有的 `divergent_skills` 具名清單」該句已刪除。

三個成員皆以 verified resolution 離開累積 blocking 集合。

### Reviewer V 的獨立實測

Reviewer V 未僅閱讀 artifacts，而是自行實作兩軸多行視窗判別式並對全部 24 個 canonical `SKILL.md` 量測，視窗大小分別取 1、3、8 三組，結果一致：

- `.claude` 變體：apply 5、commit 5、ingest 2、drift 2、analyze／archive／propose／verify 各 1、ask／audit／debug／discuss 各 0。
- `.agents` 變體數量完全相同，行號略有偏移。
- 與 `design.md` `## Context` 宣告值**逐一相符，無任何一項不符**。
- `cash-ingest:261`、`cash-apply:485`、`cash-propose:302` 三處在三種視窗下皆正確排除；`cash-drift` 的五處報告格式 `plain-language` 皆因缺 (a) 而正確排除；`cash-ask:29` 的 `unavailable main conversation context` 亦不誤計。
- 下界規則的「是否使用該工具」可直接以檔內是否含 `AskUserQuestion` 字面值判定，實測與實檔完全吻合，不需要 per-skill 表。
- 工具可行性：`skill-checks.fish` 既有兩處內嵌 `python3` 腳本與一處 `perl -ne` 跨行掃描，多行視窗比對可用既有工具實作且與該檔慣例一致。

Reviewer V 明確回報 `ready_for_implementation: true`。

### 本輪新 findings（過濾前 3 條）

**Y1** — `Warning`｜`confidence: 70`｜`layer: design`｜`disposition: fix-introduced`
- `introduced_by`: `propose-r4.md` `## Fix Actions` →「修正非 blocking triage 項」→ **X5**、**X6**
- `location`: `design.md` D2 標題、D4 第一條斷言、C2 觀察行為
- `summary`: X5／X6 把 D2 的保留清單由兩條擴為五項，但 D2 標題仍為「保留兩條可稽核內容」，D4 與 C2 也仍寫「D2 的兩條保留內容」。實務影響有限（`tasks.md` 2.1 已逐項列出五條），但 `tasks.md` 5.3 以 C1–C5 為逐項核對清單，照 C2 字面核對只會檢查兩項。

**Y2** — `Suggestion`｜`confidence: 55`｜`layer: design`｜`disposition: new`
- `location`: delta spec、`design.md` D3、`tasks.md` 3.2
- `summary`: 「多行視窗」未界定邊界。Reviewer V 實測今日的安全區間是 W ≤ 13——`cash-ingest:261` 與 `:275` 相距 14 行，W ≥ 14 會誤計；而層次一修剪 Guardrails 後該邊際會縮小。視窗大小若寫成對現況調校的魔術數字，日後任何把 `:261` 移近 Guardrails 的編輯都會靜默誤判。

**Y3** — `Suggestion`｜`confidence: 50`｜`layer: text`｜`disposition: fix-introduced`
- `introduced_by`: `propose-r4.md` `## Fix Actions` →「修正非 blocking triage 項」→ **X7**
- `location`: `proposal.md` `## Summary` 首句
- `summary`: X7 修正把 Summary 改為「對其中 10 個 Cash skill」，但 Summary 是全文第一段，「其中」沒有前指對象——12 這個總數要到 `## Motivation` 才出現。

## Rating

- 過濾後累積 blocking 集合 Critical 數：**0**
- 過濾後累積 blocking 集合 Warning 數：**0**
- 非 blocking 已 triage 的 finding 數：**3**（Y1、Y2、Y3）
- `critical_gap`: `false`
- `round_type`: `micro`

理由：X1、X3、X4 三個成員全部取得 verified resolution 並離開累積 blocking 集合，集合清空。本輪新增 3 條 findings，經信心過濾器：Y1（`70`）、Y2（`55`）、Y3（`50`）全部落在 `[50, 80)` 區間，降級為 `Suggestion`，降級後不再是 `Critical` 或 `Warning`，故均不進入 blocking 集合。過濾後累積 blocking 集合不含任何 blocking `Critical` 或 blocking `Warning`，`critical_gap` 為 `false`，通過條件成立。

本輪的收斂具備獨立證據：Reviewer V 自行實作了 artifacts 所規定的判別式並對全部 24 個受管檔案量測，結果與 `design.md` `## Context` 的宣告值逐一相符，且明確回報提案已可進入實作。這使「判定條件可實作」從設計主張變成已驗證事實。

## Fix Actions

通過條件已成立，本輪無 blocking finding 需要修正。三條非 blocking triage 項的必要動作為 triage 註記；主 agent 判斷三條皆為真實且修正成本極低的缺陷，一併修正並記錄。修正不改變本輪 `passed` 的決策。

- **Y1**（triage 註記 + 已修正）：`design.md` D2 標題改為「### D2：層次二的重寫保留可稽核內容」（去除數量詞）；D4 第一條斷言改為「含 D2 保留清單中可字面比對的兩項（diff 可追溯性、`deviation` 銜接）」並明示「機械斷言的涵蓋範圍小於保留清單是刻意的——`:281`、`:298` 前半與範圍紀律語意屬語意性保留，由 tasks 2.1 的驗證目標與 review loop 承載」；C2 觀察行為改為「保留 D2 保留清單的全部項目（其中兩項由機械斷言把關，其餘由 tasks 2.1 的驗證目標承載）」。修改檔案：`openspec/changes/rightsize-cash-skills/design.md`。
- **Y2**（triage 註記 + 已修正）：採納 Reviewer V 的建議，把視窗界定為「同一段落」——自 (a) 命中行起算至下一個空行為止的連續非空行區塊——並明訂 MUST NOT 使用固定行數常數，理由（`cash-ingest:261` 與 `:275` 現距 14 行，層次一修剪後距離會縮短）一併寫入。Reviewer V 已實測此語意在現況下對 24 個檔案給出與 W=1／3／8 完全相同的結果。修改檔案：`design.md`（D3）、`specs/cash-skill-workflows/spec.md`（判定條件段）、`tasks.md`（3.2）。
- **Y3**（triage 註記 + 已修正）：`proposal.md` `## Summary` 首句改為「對 12 個 Cash skill 中的 10 個、就其兩個變體做一次 prompt rightsizing」，消除懸空指涉。修改檔案：`proposal.md`。

### 信心過濾器的降級追溯

Y1（`70`）由 `Warning` 降為 `Suggestion`；Y2（`55`）與 Y3（`50`）維持 `Suggestion`。無 finding 因 `confidence < 50` 被丟棄。

### 修正後的每輪前機械自我檢查

- 註記／annotation lint：delta spec 的 `<!--` 與 `-->` 各 0 次，平衡。
- Spec delta 標題身分檢查：delta spec 僅含 `## ADDED Requirements`，本項無適用對象。
- 數量一致性掃描：D2 保留清單五項與其標題、D4、C2 的數量詞已一致；`## Summary` 的 10 與 `## Proposed Solution` 的十個列舉、`## Impact` 的 20 個 SKILL.md 一致。
- Identifier cross-grep：`兩條保留內容` 與 `D2 的兩條` 於 artifacts 為零命中。
- Signal-derived checks：`openspec/signals/` 之下仍無 `status: open` 且含 `check` frontmatter 欄位的 signal。
- 驗證重跑：`"$cash_cli" validate rightsize-cash-skills` 通過。

## Decision

passed
