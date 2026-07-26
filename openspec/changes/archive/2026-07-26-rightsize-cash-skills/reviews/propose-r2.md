# Cash Propose Review — Round 2

## Reviewer Findings

本輪為 micro round，由單一 Reviewer V 執行 delta 驗證。

### 累積 blocking 集合成員的判定

Reviewer V 對 Round 1 的 F1–F18 共 18 個成員逐一回傳 `resolved`／`unresolved` 判定，結果為**全部 resolved**。主 agent 抽樣覆核 Reviewer V 的判定依據：

- F1、F2、F3、F4、F5：撤回層次二後 `.cash-skills/bin/cash` 與 `.cash-skills/lib/cash_cli/installer.py` 皆未被任何 task 觸及，`## Impact` 亦不含這兩條路徑；skill 檔案總數維持 24，receipt 記錄數不變。覆核通過。
- F8：`tasks.md` 2.2 已列出四個檔案並附行號，主 agent 實檔核對 `cash-apply:531`／`:532` 與 `cash-propose:348`／`:349` 位置正確。覆核通過。
- F14：`tasks.md` 1.10 已逐行指名收斂來源與三處不得刪除的規則，`:411` 的逐位元組標題契約與 `requirement_identity_mismatch` 後果均已寫入。覆核通過。
- F15：主 agent 實檔核對 `cash-commit` 的五處 fallback（`:72`、`:102`、`:186`、`:198`、`:335`）位置與措辭正確，`:72` 確為未逐字提及工具名的形狀。覆核通過。
- F16：主 agent 實檔核對 `cash-verify:45` 為單一行內 fallback，`cash-discuss` 為零處。覆核通過。

全部 18 個成員以「verified resolution」離開累積 blocking 集合：修正已記錄於 `propose-r1.md` `## Fix Actions`，且本輪 Reviewer V 確認修正位置已解決而未再回報。

### 本輪新 findings（過濾前 6 條）

**V1** — `severity: Critical`｜`confidence: 90`｜`layer: design`｜`disposition: fix-introduced`
- `introduced_by`: `propose-r1.md` `## Fix Actions` →「逐條修正的 blocking findings」→ **F16**
- `location`: delta spec `### Requirement: Skill 互動 fallback 以單一全域規則表述`；`design.md` `### D3`
- `summary`: 同一條 requirement 內含互相否定的兩句規範——先以 MUST 要求 fallback 規則出現在第一個使用 AskUserQuestion 的步驟之前，隨即又豁免 analyze／archive／propose／verify「MUST NOT 僅因位置不同而被要求改動」，而這些 skill 實測正好違反該位置 MUST。
- `recommendation`: 位置條件降為 SHOULD 級建議，或限縮適用對象。
- 主 agent 覆核：實測 `cash-archive` 首次使用 `:34`／fallback `:172`、`cash-propose` `:45`／`:302`、`cash-verify` `:45`／`:45`，矛盾成立。

**V2** — `severity: Critical`｜`confidence: 85`｜`layer: design`｜`disposition: new`
- `location`: `tasks.md` 1.8；`design.md` `### C1`、`### D3`；delta spec fallback requirement
- `summary`: `cash-ingest:261` 的 fallback 與其餘各處語意不同——它要求顯示摘要、告知使用者稍後執行 `cash-apply`，然後 `Then STOP — do not continue`。把三處無差別收斂為「以純文字問相同的問題並等待」會刪掉唯一承載該停止契約的文字。
- `recommendation`: 把 `:261` 列為主詞不同、MUST NOT 併入的規則，收斂對象縮為 `:110` 與 `:275`，並在 requirement 中排除此類陳述的計數。
- 主 agent 覆核：實檔確認 `:257` 使用 AskUserQuestion 的目的即「This ensures the workflow stops even when auto-accept is enabled」，`:261` 為其工具不可用時的對應停止路徑，全檔無其他位置承載該契約。成立。
- 主 agent 對 `new` 標籤的檢查：本 finding 的缺陷機制在 Round 1 的原始 `tasks.md` 2.8 即已存在（「收斂三處 AskUserQuestion fallback」），非由 Round 1 修正動作引入，且未匹配任何先前 blocking finding。維持 `disposition: new`。

**V3** — `severity: Warning`｜`confidence: 75`｜`layer: design`｜`disposition: unresolved-prior`
- `location`: delta spec `### Requirement: cash-apply 實作紀律以判準表述` 的 `#### Scenario: 段落名稱在四個檔案中一致`；`tasks.md` 3.1
- `summary`: requirement 以 MUST 要求回歸套件斷言「上述內容」，但 `tasks.md` 3.1 建立的斷言只涵蓋 `cash-apply` 兩變體的內容，四檔名稱一致這條 scenario 沒有機械支撐。

**V4** — `severity: Suggestion`｜`confidence: 55`｜`layer: text`｜`disposition: new`
- `location`: `tasks.md` 1.7、1.8、1.10（相對於 1.5）
- `summary`: 只有 1.5 把位置條件寫進任務描述，drift／ingest／apply 三條只寫「收斂為單一全域規則」，四條任務對同一規範各說各話。

**V5** — `severity: Suggestion`｜`confidence: 50`｜`layer: text`｜`disposition: new`
- `location`: `tasks.md` 1.5
- `summary`: `cash-commit` 屬四個非 divergent skill 之一，但 1.5 未如 1.2／1.6／1.10 註明「非 divergent，兩變體正規化後 MUST 零差異」並加上 `diff` 自我檢查。

**V6** — `severity: Suggestion`｜`confidence: 40`｜`layer: text`｜`disposition: new`
- `location`: `design.md` `## Context`、`### C1`；`tasks.md` 1.10
- `summary`: 受保護範圍寫作 `:625`–`:633`，但 `**Round file language**` 標題行實測在 `:624`，落在宣告的保護範圍之外。

## Rating

- 過濾後累積 blocking 集合 Critical 數：**1**（V1）
- 過濾後累積 blocking 集合 Warning 數：**0**
- 非 blocking 已 triage 的 finding 數：**4**（V2、V3、V4、V5）
- `critical_gap`: `true`
- `round_type`: `micro`

理由：Round 1 的 18 個累積 blocking 成員全部取得 verified resolution 並離開集合。本輪新增 6 條 findings，經信心過濾器處理後：V6（`confidence: 40 < 50`）被丟棄；V3（`75`）、V4（`55`）、V5（`50`）落在 `[50, 80)` 區間降級為 `Suggestion`，降級後不再是 `Critical` 或 `Warning`，故不進入 blocking 集合；V1（`90`）與 V2（`85`）維持原分級。其中僅 V1 的 disposition 為 `fix-introduced` 因而 blocking；V2 的 disposition 為 `new`，依規則為非 blocking。過濾後累積 blocking 集合含一個 Critical，`critical_gap` 為 `true`，本輪 MUST NOT 通過。

## Fix Actions

### 修正 blocking finding

- **V1**（Critical，`fix-introduced`）：把位置條件從規範條件降為 SHOULD 級建議。理由有二且都已寫入 artifacts——機械斷言只能計數而無法可靠判定「首次使用之前」，寫成 MUST 會產生無法驗證的驗收標準（對應 open signal `acceptance-criterion-not-mechanically-verifiable`）；且 `cash-archive`（`:34`／`:172`）與 `cash-propose`（`:45`／`:302`）實測不滿足該條件，寫成 MUST 會迫使本 change 改動已滿足「至多一處」的 skill，與 `## Impact` 的宣告範圍矛盾。修改檔案：`openspec/changes/rightsize-cash-skills/design.md`（D3）、`openspec/changes/rightsize-cash-skills/specs/cash-skill-workflows/spec.md`（fallback requirement 第二段）、`openspec/changes/rightsize-cash-skills/tasks.md`（1.5、1.7、1.10）。

### 修正非 blocking triage 項

以下四條依規則為非 blocking，其必要動作為 triage 註記；主 agent 判斷其中三條為真實缺陷且修正成本低，一併修正並記錄。

- **V2**（Critical，`new` — triage 註記 + 已修正）：triage 註記——`cash-ingest:261` 承載的 `Then STOP — do not continue` 停止契約，在原任務描述下會被收斂動作刪除。此為非 blocking 的新發現，依規則列入本輪 signals write step，並在完成輸出中明列。修正內容：`design.md` D3 新增「承載額外契約的 fallback 不計入」段並具名 `cash-ingest:261`；C1 範圍邊界新增該位置並把收斂對象縮為 `:110` 與 `:275`；delta spec 的 fallback requirement 新增對應規範段、一條 scenario 與一列 Example；`tasks.md` 1.8 改寫收斂對象並加上 `:261` 的保留自我檢查；3.2 加上具名例外與註解說明的要求。修改檔案：`design.md`、`specs/cash-skill-workflows/spec.md`、`tasks.md`。此 finding 屬 Critical 但非 blocking，依規則**建議另開後續 change 提案**——本 repo 其他 skill 可能存在同類「fallback 承載額外契約」的位置，值得做一次全面盤點；本 change 只處理已確認的 `cash-ingest:261`。
- **V3**（Suggestion，`unresolved-prior`）：`tasks.md` 3.1 新增段落名稱一致斷言——對四個 `SKILL.md` 以新段落名稱 `assert_contains`、對舊名稱 `assert_absent`；`design.md` D4 新增對應的第三條斷言說明。修改檔案：`tasks.md`、`design.md`。
- **V4**（Suggestion，`new`）：`tasks.md` 1.7、1.10 補上與 1.5 一致的位置措辭，且三處同步採用 V1 修正後的 SHOULD 表述。修改檔案：`tasks.md`。
- **V5**（Suggestion，`new`）：`tasks.md` 1.5 補上非 divergent 註記與 `diff` 正規化後為空的自我檢查。修改檔案：`tasks.md`。

### 信心過濾器的降級追溯

- V3 由 `Warning` 降為 `Suggestion`：`confidence: 75`，落在 `[50, 80)`。
- V4 由 `Suggestion` 維持 `Suggestion`：`confidence: 55`。
- V5 由 `Suggestion` 維持 `Suggestion`：`confidence: 50`。
- V6 被丟棄：`confidence: 40 < 50`。主 agent 仍實檔覆核其事實主張並確認成立（`**Round file language**` 標題行在 `:624`），該修正成本為零且屬事實更正，一併執行：`design.md` `## Context` 與 `### C1`、`tasks.md` 1.10 的行號範圍由 `:625`–`:633` 改為 `:624`–`:633`（含標題行）。修改檔案：`design.md`、`tasks.md`。

### 修正後的每輪前機械自我檢查

- 註記／annotation lint：delta spec 的 `<!--` 與 `-->` 各 0 次，平衡。
- Spec delta 標題身分檢查：delta spec 僅含 `## ADDED Requirements`，無 MODIFIED／REMOVED／RENAMED 區段，本項無適用對象。
- 數量一致性掃描：本輪修正新增的計數主張——`cash-ingest` 收斂對象兩處（`:110`、`:275`）加保留一處（`:261`）、`cash-archive` `:34`／`:172`、`cash-propose` `:45`／`:302`、`cash-verify` `:45`／`:45`、`**Round file language**` 標題行 `:624`——全部已對照實檔驗證。
- Identifier cross-grep — **已修正**：`design.md` 的 Round file language 行號範圍已更新為 `:624`，但 `tasks.md` 1.10 仍為 `:625`，構成修正傳播缺口。已同步 `tasks.md` 1.10 為 `:624`–`:633`（含標題行）。修改檔案：`tasks.md`。
- Signal-derived checks：`openspec/signals/` 之下仍無 `status: open` 且含 `check` frontmatter 欄位的 signal，本項無指令可執行。
- 驗證重跑：`"$cash_cli" validate rightsize-cash-skills` 通過。

## Decision

next_round
