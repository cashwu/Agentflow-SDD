# Cash Propose Review — Round 4

## Reviewer Findings

本輪為第四輪檢查點，依規則使用 full round，由 Reviewer A（Adherence）與 Reviewer B（Quality）並行獨立執行。

### 累積 blocking 集合成員的判定

進入本輪時集合中僅有 **W1**（Warning，`fix-introduced`）。兩位 reviewer 皆回傳 `resolved`：`design.md` D3 的 `cash-propose`（`:45`／`:302`）已更正為（`:45`／`:518`），且 Reviewer A 另行逐條核對全 artifacts 的 54 個行號引用，確認無其他誤植。W1 以 verified resolution 離開集合。

### 本輪新 findings（彙總後 13 條）

彙總規則：Reviewer A 的「斷言只有上界」與 Reviewer B 的同一發現依 `location + summary` 合併為 X2。

#### Critical

**X1** — `Critical`｜`confidence: 90`｜`layer: design`｜`disposition: fix-introduced`｜來源：B
- `introduced_by`: `propose-r3.md` `## Fix Actions` →「修正非 blocking triage 項」→ **W4**
- `location`: `design.md` `### D3` 判定條件段、`### D4`；`tasks.md` 3.2；delta spec fallback requirement
- `summary`: Round 3 引入的「(a) 不可用條件與 (b) 純文字子句同時滿足」被寫成同行比對，但本 repo 的 fallback 陳述有一半是跨行的——`cash-apply:79`–`:81`、`:139`–`:141` 與 `cash-ingest:110`–`:112` 都把 (a) 放在條件行、(b) 放在後續行；依此實作的斷言在 `cash-apply` 只會數到 3 而非宣告的 5，且 tasks 3.2 的注入式驗證目標對這兩種既存形狀為假。另 (b) 軸實檔至少有六種措辭變體，artifacts 只在 (a) 軸列舉措辭。
- 主 agent 覆核：實檔確認 `cash-apply:79`–`:81` 與 `:139`–`:141` 為條件獨立成行的形狀。成立。

#### Warning

**X2** — `Warning`｜`confidence: 85`｜`layer: design`｜`disposition: new`｜來源：A、B（彙總）
- `location`: delta spec fallback requirement；`design.md` `### D4`；`tasks.md` 3.2
- `summary`: 斷言只有上界，0 次同樣通過，因此無法攔截「唯一一處 fallback 陳述被誤刪」——而該陳述在 analyze（`:99`）、archive（`:172`）、propose（`:518`）、drift（`:134`）、ingest（`:275`）、apply（`:709`）、commit（`:335`）七個 skill 中，正是層次一要修剪的 `**Guardrails**` 區塊最後一條 bullet。與 D4 自述目的（「只刪不補會讓同樣的漂移再次發生」）直接矛盾。

**X3** — `Warning`｜`confidence: 90`｜`layer: design`｜`disposition: fix-introduced`｜來源：A
- `introduced_by`: `propose-r3.md` `## Fix Actions` →「修正非 blocking triage 項」→ **W3**
- `location`: delta spec fallback requirement 標題與第 57／63 行；`proposal.md` `## Motivation`、`## Proposed Solution`、`## Capabilities`
- `summary`: W3 修正把主句改為「全檔至多陳述一次…得內嵌於步驟句中」，但 requirement 標題仍為「以單一全域規則表述」，且 delta spec 兩處與 proposal 三處仍寫「檔案層級的全域規則」，標題與本文對同一規範給出互斥的形狀要求。Round 3 的 identifier cross-grep 只 grep 了舊字串 `檔案層級陳述`，未涵蓋 `檔案層級`／`全域規則`，是此傳播缺口的直接成因。

**X4** — `Warning`｜`confidence: 80`｜`layer: design`｜`disposition: fix-introduced`｜來源：B
- `introduced_by`: `propose-r3.md` `## Fix Actions` →「修正非 blocking triage 項」→ **W4**
- `location`: `design.md` `### D3` 具名例外段；`tasks.md` 3.2；delta spec `#### Scenario: 具名例外在測試檔中可審閱`
- `summary`: `cash-ingest:261` 依 (a)+(b) 判定本來就不計入，因此 Round 2 引入的具名例外機制沒有任何適用對象，使該 scenario 無 witness；另「處理方式比照既有的 `divergent_skills` 具名清單」在結構上不可行——`divergent_skills` 是 skill 名稱清單，無法表達「排除某檔內的某一處而仍把該檔計為 1」。且行號會隨層次一的刪除位移，不可作為例外 key。

**X5** — `Warning`｜`confidence: 85`｜`layer: design`｜`disposition: new`｜來源：B
- `location`: `design.md` `### D2`；`tasks.md` 2.1；delta spec 實作紀律 requirement
- `summary`: D2 的保留清單是封閉的兩條，但 `cash-apply:281`（不相關缺陷以 `open-question` 記錄而不得順手修）與 `:298` 前半（違反紀律視同 task 未完成，`task done` 前先修正）都是契約性內容而非風格禁令，且全檔無其他位置承載——`:336` 的 `open-question` 觸發條件不同，`:231` 與 `:335` 不承載 `task done` 前的 gating。3.1 的斷言只檢查那兩條與風格禁令字面值的缺席，刪掉這兩處仍全綠。

**X6** — `Warning`｜`confidence: 80`｜`layer: design`｜`disposition: new`｜來源：B
- `location`: `tasks.md` 2.1、2.2；`design.md` `### D2`
- `summary`: 「抽象層」在 cash-apply 有兩條極性相反的規則（`:271` 不為單一情境引入抽象層 vs `:294` 不為減少間接而拿掉合理抽象），2.1 未裁決指的是哪一條。而四個檔案的 `Common false positives` 條目其前提正是 `:271` 與 `:278`／`:281`；若被移除，即使 2.2 更新了段落名稱，該過濾規則仍會失去指涉對象，而審查迴圈每一輪都在用它過濾 reviewer 建議。

**X7** — `Warning`｜`confidence: 80`｜`layer: text`｜`disposition: new`｜來源：A
- `location`: `proposal.md` `## Summary`
- `summary`: Summary 宣稱「對 12 個 Cash skill 的兩個變體」，但 `## Proposed Solution` 明列十個、`## Impact` 只列 20 個 SKILL.md，discuss 與 verify 明文不在範圍內。

#### Suggestion（經信心過濾器降級或原級）

- **X8**（原 Warning，`confidence: 75`，B）：Guardrails 的「無法從前文推得」判準會刪掉後果最高的安全規則——`cash-commit:330` 的 `NEVER use git add . or git add -A` 在 `:291` 已有既有表述、`:331` 的 `NEVER commit files the user hasn't confirmed` 在步驟 6 已有既有表述，依判準都應刪；且 C1 的指認義務沒有落點可稽核。
- **X9**（原 Warning，`confidence: 75`，B）：六份受影響 parity manifest 中，analyze／ask／audit／drift／propose 五份的全部 hunk 都早於各該 skill 的 Guardrails 與 Rationalization Table 位置，內容不會改變，tasks 的「同步更新」是不存在的工作且動手就會使 `cmp -s` 失敗；真正會變的只有 `cash-ingest.diff`，其最後一個 hunk `@@ -267 +267 @@` 正是要修剪的 Guardrails bullet。全 repo 無 manifest 再生程序。
- **X10**（原 Suggestion，`confidence: 70`，B）：artifacts 未提及 `cash-apply:264` 的 `**Surgical & Simplicity Discipline**` 上位標題與 `:266` 導言（「以下兩項紀律」）；三段合併後該數量陳述會錯誤，且上位標題會與新段落名稱形成兩層命名，使 3.1 的 `assert_contains` 無從判別何者生效。
- **X11**（原 Suggestion，`confidence: 55`，A，`fix-introduced` ← `propose-r2.md` V3）：C3 的觀察行為與驗收仍只寫「兩條新 requirement 各有對應斷言」與「上述兩個注入案例」，第三條斷言沒有 contract 級注入驗收，而 tasks 5.3 以 C1–C5 為逐項核對清單。
- **X12**（原 Suggestion，`confidence: 50`，A）：1.10 未比照 1.5／1.8 逐行列出五處 fallback，其中 `:79`／`:139` 是多行形狀且覆述了指令序列，邊界判斷被留給實作者。

## Rating

- 過濾後累積 blocking 集合 Critical 數：**1**（X1）
- 過濾後累積 blocking 集合 Warning 數：**2**（X3、X4）
- 非 blocking 已 triage 的 finding 數：**9**（X2、X5、X6、X7、X8、X9、X10、X11、X12）
- `critical_gap`: `true`
- `round_type`: `full`

理由：W1 取得 verified resolution 並離開集合。本輪兩位 reviewer 獨立回傳共 14 條 findings，彙總後 12 條加一條合併項共 12 條。經信心過濾器：X8（`75`）、X9（`75`）、X10（`70`）、X11（`55`）、X12（`50`）落在 `[50, 80)` 降級為 `Suggestion`；其餘維持原級。降級後仍為 `Critical` 或 `Warning` 者中，僅 X1、X3、X4 的 disposition 為 `fix-introduced` 因而 blocking；X2、X5、X6、X7 為 `new`，依規則非 blocking。過濾後累積 blocking 集合含一個 Critical，`critical_gap` 為 `true`，本輪 MUST NOT 通過。

本輪三條 blocking findings 全部指向同一根因：Round 2 與 Round 3 為 fallback 斷言逐步堆疊的機制（具名例外、(a)+(b) 同行判定）在實檔上既不可實作也無適用對象。修正方式不是再打一個補丁，而是以實測資料重新設計判定條件。

## Fix Actions

### 以實測重新設計 fallback 判定條件（解決 X1、X3、X4，並一併解決非 blocking 的 X2）

主 agent 先以實檔量測驗證候選判別式，再據以改寫：

- 單軸（僅比對純文字子句）：`cash-drift` 計為 7，實際為 2——五處 `plain-language`（`:64`、`:76`、`:80`、`:96`、`:100`）是報告本文的可讀性要求。故 (a) 軸必要。
- 單軸（僅比對不可用條件）：`cash-propose:302` 與 `cash-apply:485` 的 accepted-risks ledger 規則、`cash-ingest:261` 的終止規則都會被誤計。故 (b) 軸必要。
- 兩軸同行：`cash-apply:79`–`:81`、`:139`–`:141`、`cash-ingest:110`–`:112` 計為零。故 MUST 以多行視窗比對。
- 兩軸多行視窗：`cash-ingest:261`、`cash-apply:485`、`cash-propose:302` 皆自然排除，**具名例外機制沒有適用對象**。

據此改寫：delta spec 的 fallback requirement 整條重寫（標題改為 `Skill 互動 fallback 的單一陳述`，判定條件改為兩軸並明訂多行視窗，上下界同時把關，刪除具名例外機制與 `#### Scenario: 具名例外在測試檔中可審閱`，新增「刪除唯一 fallback 陳述使套件失敗」「條件與替代作法分行的陳述被正確計入」「只滿足純文字替代者不計入」三條 scenario，Example 表改為兩軸七列）；`design.md` D3 整段重寫並記錄上述四項實測依據，D4 第二條斷言同步；`tasks.md` 3.2 的比對要求與驗證目標同步。修改檔案：`specs/cash-skill-workflows/spec.md`、`design.md`、`tasks.md`。

X3 的形狀措辭傳播一併處理：`proposal.md` 三處與 delta spec 兩處的「檔案層級的全域規則／單一全域表述」改為形狀中立的「單一陳述」。修改檔案：`proposal.md`、`specs/cash-skill-workflows/spec.md`、`design.md`、`tasks.md`。

### 修正非 blocking triage 項

以下依規則為非 blocking，其必要動作為 triage 註記；主 agent 判斷全部為真實缺陷且修正成本可控，一併修正並記錄。

- **X5**、**X6**：`design.md` D2 的保留清單由封閉兩條擴為五項，新增 `:281` 的不相關缺陷 `open-question` 紀律、`:298` 前半的 `task done` 前 gating，以及 `Common false positives` 所依賴的 `:271` 與 `:278`／`:281` 範圍紀律語意；並明文區分「MUST 移除的是 `Maintain Balance` 的六項語法層級風格禁令」與「範圍紀律不是風格禁令，MUST 保留其語意」，消除「抽象層」的極性歧義。`tasks.md` 2.1 同步，2.2 的驗證目標新增「四檔的 false-positive 條目所引用的範圍紀律在新段落中仍有對應文字」。修改檔案：`design.md`、`tasks.md`、`proposal.md`（`## Proposed Solution` 的層次二敘述同步）。
- **X7**：`proposal.md` `## Summary` 改為「對其中 10 個 Cash skill 的兩個變體」。同時更正 `## Motivation` 的 `cash-ingest` fallback 計數為兩次（兩軸判定下 `:261` 不計入）。修改檔案：`proposal.md`。
- **X8**：`design.md` C1 範圍邊界新增下限——帶 `**NEVER**` 或 `MUST NOT` 且規範不可逆副作用（git 暫存與提交、刪檔、寫入外部狀態）的 Guardrails 條目 MUST 保留，即使前文已有等效表述，並具名 `cash-commit:330`／`:331`；C1 的指認義務改為 MUST 寫入 `implementation-notes.md`（保留位置的檔案與行號）使其可稽核。`tasks.md` 第 1 節新增對應前言。修改檔案：`design.md`、`tasks.md`。
- **X9**：`tasks.md` 第 1 節新增 parity manifest 前言，明列五份 manifest MUST 維持逐位元組不變、MUST NOT 人工編輯，並從 1.1／1.3／1.4／1.7／1.9 移除「同步更新 manifest」指示；1.8 改為明示 `cash-ingest.diff` 是唯一需重新產生者，點名 `@@ -267 +267 @@` hunk 對應的 Guardrails bullet，並給出再生程序（比照 `normalized_variant_diff` 的 perl 正規化與 `diff -U0 --label` 呼叫），禁止手工拼湊 hunk 標頭。修改檔案：`tasks.md`。
- **X10**：`design.md` D2 明訂合併範圍為 `:264`–`:298`（含上位標題與導言）、合併後只保留單一標題、`:266` 導言若保留則其「兩項紀律」數量陳述 MUST 更正；`tasks.md` 2.1 同步。修改檔案：`design.md`、`tasks.md`。
- **X11**：`design.md` C3 的觀察行為與驗收由兩個注入案例擴為四個，涵蓋第三條斷言（舊段落名稱殘留）與新增的下界案例。修改檔案：`design.md`。
- **X12**：`tasks.md` 1.10 逐行列出五處 fallback（`:79`–`:81`、`:139`–`:141`、`:154`、`:172`、`:709`），並註明前兩者為多行形狀、其覆述的指令序列在同段的 AskUserQuestion 分支已完整承載故可安全收斂。修改檔案：`tasks.md`。

### 信心過濾器的降級追溯

X8（`75`）、X9（`75`）、X10（`70`）、X11（`55`）、X12（`50`）由原級降為 `Suggestion`。無 finding 因 `confidence < 50` 被丟棄。

### 修正後的每輪前機械自我檢查

- 註記／annotation lint：delta spec 的 `<!--` 與 `-->` 各 0 次，平衡。
- Spec delta 標題身分檢查：delta spec 僅含 `## ADDED Requirements`，本項無適用對象。ADDED requirement 的標題更名不受逐位元組身分鍵約束（尚未進入 master spec）。
- 數量一致性掃描：本輪所有新計數主張已對照實檔驗證——`cash-drift` 兩軸下為 2（另五處為報告格式用語）、`cash-ingest` 為 2（`:261` 不計入）、`cash-apply` 為 5、`cash-commit` 為 5、七處唯一 fallback 位於 Guardrails 末條、六份 manifest 中五份 hunk 位置早於改動區。
- Identifier cross-grep — **本輪擴大比對範圍**：Round 3 只 grep 舊字串 `檔案層級陳述` 而漏掉 `檔案層級`／`全域規則`，是 X3 的成因。本輪改以 `檔案層級`、`全域規則`、`具名例外`、`至多一處`、`至多為一`、`兩條斷言` 六個字串全 artifacts 掃描，殘留者僅為 design D3 說明「不需要具名例外機制」與形狀選項的語境引用，以及已完結的 r2／r3 round file（依規則不可變更）。
- Signal-derived checks：`openspec/signals/` 之下仍無 `status: open` 且含 `check` frontmatter 欄位的 signal。
- 驗證重跑：`"$cash_cli" validate rightsize-cash-skills` 通過。

## Decision

next_round
