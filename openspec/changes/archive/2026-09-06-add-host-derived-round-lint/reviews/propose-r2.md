# Cash Propose Review — Round 2

## Reviewer Findings

本輪為本次執行的第二輪。依位置推導（第二輪、非第四輪）為 `micro` 輪，由一位全新的 Reviewer V 進行差異驗證。

### 累積 blocking 集合逐成員裁定

Reviewer V 對 Round 1 的 14 個成員各回傳明確裁定，主 agent 逐條覆核如下。

**verified resolution（12 項，經 Reviewer V 驗證解決後移出集合）**

- C2 — 逐 skill 活動判定。驗證位置：design.md D3、specs/cash-round-gate/spec.md requirement「迴圈活動狀態逐 skill 判定」與新增 scenario「另一個 skill 的迴圈仍進行中」、proposal.md。修正參照：Round 1 `## Fix Actions` C2。
- C3 — gate 適用性旁路已於 design.md R8 逐字記錄，並界定 `## Motivation` 宣稱的成立範圍。修正參照：Round 1 C3。
- C4 — `gate_unavailable` 診斷義務見 design.md D6 與 spec requirement，Non-Goals 明列不保護 gate 自身。修正參照：Round 1 C4。
- W1 — design.md R4 已重寫並指定雙向 fixture。修正參照：Round 1 W1。
- W2 — proposal、design D4、spec 三處已同步為涵蓋 staged 與 untracked，並新增對應 scenario。修正參照：Round 1 W2。
- W3 — 唯讀性 requirement 已由 tasks 1.2 與 1.3 承載。修正參照：Round 1 W3。
- W4 — round file 檔名樣式已逐字寫入 design D2 與 spec，並新增 scenario「非 round file 不納入判定」。修正參照：Round 1 W4。
- W5 — 短路代價已由 design.md R7 承認。修正參照：Round 1 W5。（其修正另引入 F3，見下。）
- W6 — spec 已改為只主張涵蓋路徑成分並明文 MUST NOT 主張涵蓋 signal `check` 欄位。修正參照：Round 1 W6。
- W7 — 舊 1.7 已拆為 1.7 與 1.8，`success` 不再混入其他 target。修正參照：Round 1 W7。
- W8 — 三處 iff 措辭已統一並與 master spec 一致。修正參照：Round 1 W8。
- W10 — `round_type` 缺席與值域外已明訂為 `fail`，並新增 scenario。修正參照：Round 1 W10。

驗證 reviewer：Reviewer V（本輪唯一 reviewer）。以上 12 項均以當前 artifact 原文為證據，非依賴 Round 1 `## Fix Actions` 的敘述。

**留在集合（2 項，裁定 `unresolved`）**

- C1 — `unresolved`。proposal 側已修正，但 design.md `## Non-Goals` 仍逐字保留「不調升 `cash-skills.version`」，與同檔 D7 及 tasks 1.1 互相否定。以 F1 形式回報。
- W9 — `unresolved`。D3、Stop hook 觀察行為、round-gate spec 與 proposal 均已修正，但 design.md `## Implementation Contract` 的 `--hook` 介面條目與 specs/cash-cli/spec.md 的 scenario 仍寫「非 `archive` 的目錄」。以 F2 形式回報。

### Critical

**F1** — `severity`: Critical｜`confidence`: 100｜`layer`: design｜`disposition`: `unresolved-prior`（對應 C1）｜`location`: design.md `## Goals / Non-Goals`
`summary`: design Non-Goals 仍宣告「不調升 `cash-skills.version`」，與同一份 design 的 D7、tasks 1.1 與 proposal `## Impact` 直接互相否定。
`recommendation`: 刪除該子句，保留同句其餘四項 Non-Goal。
主 agent 覆核：成立。Round 1 對 C1 的修正只清除了 proposal 的 Non-Goal，未清除 design 的平行條目——同一概念在兩個 artifact 各有一處，修正只套用了一處。

### Warning

**F2** — `severity`: Warning｜`confidence`: 100｜`layer`: design｜`disposition`: `unresolved-prior`（對應 W9）｜`location`: design.md `## Implementation Contract` 的 `cash lint-round` 介面條目；specs/cash-cli/spec.md `#### Scenario: lint-round --hook 不接受 change 名稱` 的 THEN 子句
`summary`: W9 的修正未傳播到 Implementation Contract 與 cash-cli spec delta，兩處仍寫「非 `archive` 的目錄」；兩者皆為 normative，依其實作會把 `.parked` 當成 change 列舉並使 parked change 不受檢，`cash park` 逃逸口原封不動。
`recommendation`: 兩處改為與 D3 一致的措辭，cash-cli scenario 另加一條斷言 `.parked` 本身不被當成 change。
主 agent 覆核：成立。`.cash-skills/lib/cash_cli/commands/discovery.py:151` 確為 `ignored = {"archive", ".parked"}`。

**F3** — `severity`: Warning｜`confidence`: 85｜`layer`: design｜`disposition`: `fix-introduced`｜`introduced_by`: Round 1 `## Fix Actions` 的 **W5** 條目（「spec 要求重入放行時仍 MUST 將未解決失敗項輸出至 stderr；對應 scenario 同步」）｜`location`: design.md D6 與 R7；specs/cash-round-gate/spec.md Stop hook requirement 與重入 scenario；tasks.md 1.6
`summary`: W5 的修正引入互相否定的條款——D6 說 `stop_hook_active` 為真時「立即 exit 0」，spec 卻 MUST 輸出「上一次判定」的未解決失敗項；而 D1 與 D5 明訂 command 唯讀、不寫入任何檔案，因此沒有任何 host-derived 管道可保存前次判定結果，該 MUST 在既有約束下不可實作，tasks 1.6 據此寫下的 case 也無法建構 fixture。
`recommendation`: 收斂為「重入時仍執行判定、輸出當次未解決失敗項後 exit `0`」，或保留立即短路並把輸出義務降為非 normative。
主 agent 覆核：成立，且是本輪唯一由 Round 1 修正引入的 blocking 缺陷。

### Suggestion

**F4**（非 blocking）— `severity`: Suggestion｜`confidence`: 55｜`layer`: design｜`disposition`: `fix-introduced`｜`introduced_by`: Round 1 `## Fix Actions` 的 **C1** 條目（「tasks 新增排序最前的 1.1」）｜`location`: tasks.md 1.1 的 `red` 欄位
`summary`: 1.1 的 `red` 描述的是實作中途的半改狀態，而非 task 開始前 primary target 上可觀察的失敗；現況兩處版本值一致且 `test_bundle_version_history.py` 通過，不存在先行紅燈。

## Rating

- post-filter 累積 blocking 集合 `Critical` 數：1
- post-filter 累積 blocking 集合 `Warning` 數：2
- 非 blocking triaged finding 數：1
- `critical_gap`：`true`
- `round_type`：`micro`

理由：Round 1 的 14 個成員中，12 個經 Reviewer V 以當前 artifact 原文驗證解決並移出集合，C1 與 W9 兩個成員因修正未傳播到全部出現位置而維持 `unresolved` 並留在集合；另新增 F3 一個 `fix-introduced` 成員。集合內因此為 F1（Critical）、F2（Warning）、F3（Warning）三項。F4 為 `fix-introduced` 但嚴重度為 `Suggestion`，不進入 blocking 集合，以 triage 註記處理並一併修正。blocking 集合非空且含 `Critical`，本輪不通過。

本輪暴露的模式與 open signal `review-fix-propagation-incomplete` 完全吻合：C1 與 W9 的修正都只套用到 reviewer 指名的位置，未對該概念在全部 artifact 的每個出現處做同步。Round 1 `## Fix Actions` 已載明 fix propagation 義務，實際執行時仍遺漏兩處，屬執行落差而非規則缺失。

## Fix Actions

本輪修正涵蓋 3 筆 blocking finding 與 1 筆非 blocking Suggestion。修改檔案 4 個：`design.md`、`specs/cash-round-gate/spec.md`、`specs/cash-cli/spec.md`、`tasks.md`。`proposal.md` 本輪未修改。

**F1**：刪除 design.md `## Non-Goals` 中的「不調升 `cash-skills.version`」子句，保留同句其餘四項。修正後該概念在 proposal 與 design 兩處一致，且與 D7、tasks 1.1 不再矛盾。

**F2**：design.md `## Implementation Contract` 的 `--hook` 介面條目改為「依 D3 的列舉規則自行決定檢查對象——`openspec/changes/` 下排除 `archive` 與 `.parked` 兩個保留目錄名後的 change，加上 `openspec/changes/.parked/` 下的 parked change」。specs/cash-cli/spec.md 的 scenario THEN 同步改寫，並新增一條 `- **AND** `.parked`本身不被當成一個change列舉`。修正後 `.parked` 相關措辭在五個 artifact 的出現次數為 proposal 1、design 3、cash-round-gate spec 3、cash-cli spec 2、tasks 1，經 grep 確認語意一致。

**F3**：採 recommendation 的第一個選項收斂。design.md D6 移除「立即」，改為「hook 仍執行判定，將**當次**未解決的失敗項輸出至 stderr 後以 exit 0 結束」，並逐字寫明該義務 MUST 以當次判定為準的理由——command 依 D1 與 D5 為唯讀且不寫入任何檔案，沒有可保存前次判定結果的 host-derived 管道。design.md R7 的緩解敘述同步改為「重入時仍執行判定並把當次未解決的失敗項輸出到 stderr」。specs/cash-round-gate/spec.md 的 Stop hook requirement 同步，並明訂 MUST NOT 要求輸出上一次判定的失敗項；重入 scenario 的 GIVEN 與 THEN 由「上一次判定」改為「當次判定」。tasks.md 1.6 的 case 與 1.7 的實作描述同步改為「仍執行判定並輸出當次未解決失敗項」。此選項優於保留立即短路：它可實作、保持唯讀，且使重入放行仍留下當次的完整失敗清單。

**F4**（非 blocking，triage 後一併修正）：tasks.md 1.1 的 `red` 改為 `N/A`，並附 remaining-task 分類理由——版本調升為發佈前置動作、不交付可觀察行為，且現況兩處版本值一致、primary target 通過，不存在先行失敗狀態。

**修正後重跑的檢查**：`validate` 通過；pre-round mechanical self-check 全數重跑通過——annotation lint 兩個 delta 檔的 `<!--`／`-->` 皆為 0 且無 stray `---`；spec delta title-identity 確認 `### Requirement: Cash workflow command surface` 逐位元組存在於 master spec；`.parked` 措辭跨五個 artifact 一致；tasks 全部 `delivery` 路徑與 proposal `## Impact` 宣告路徑雙向對應，9 對 9，無遺漏也無多宣告；signal-derived checks 中仍無任何 signal 定義 `check` 欄位，第一步為空集合。

**針對本輪暴露模式的額外傳播檢查**：對本輪三筆修正各自的核心概念——`cash-skills.version` 調升立場、`.parked` 列舉規則、重入時的判定與輸出義務——分別跨 proposal、design、兩份 spec delta 與 tasks 全文 grep，確認無殘留的舊措辭。唯二仍出現「上一次判定」字樣的位置是 design.md D6 與 spec Stop hook requirement 中刻意寫入的 MUST NOT 排除條款，屬預期內容而非漏改。

**範圍外或未修復事項**：無。本輪無 `未修復：裁判面保護` 紀錄，無 accepted-risks 降級。disposition 覆核：F1 與 F2 的 `unresolved-prior` 經比對 Round 1 的 C1 與 W9 成立；F3 與 F4 的 `fix-introduced` 經比對 Round 1 `## Fix Actions` 的 W5 與 C1 條目成立，`introduced_by` 參照有效。無需更正任何 disposition 標記。

## Decision

`next_round`

本輪 post-filter 累積 blocking 集合含 1 筆 `Critical`（F1）與 2 筆 `Warning`（F2、F3），不符通過條件。三筆 blocking finding 與 1 筆非 blocking Suggestion 均已在本輪 `## Fix Actions` 記錄對應修正並實際套用，修正後 `validate` 與 pre-round mechanical self-check 皆重跑通過。依位置推導，下一輪是本次執行的第三輪、非第四輪，故為 `micro` 輪，由一位全新的 Reviewer V 進行差異驗證。
