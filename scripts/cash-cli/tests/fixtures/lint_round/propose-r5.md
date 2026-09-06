# Cash Propose Review — Round 5

## Reviewer Findings

本輪為本次執行的第五輪。依位置推導（第五輪、非第四輪）為 `micro` 輪，由一位全新的 Reviewer V 進行差異驗證。

### 累積 blocking 集合逐成員裁定

**verified resolution（2 項，全部移出集合）**

- G1 — `resolved`。Reviewer V 逐一核對該修正的四個面：design.md D6 的「MUST NOT 要求 `--hook` mode 自帶時間上限」與改由 host 承擔的規定、specs/cash-round-gate/spec.md 的同義條款、取代原取鎖逾時 scenario 的「hook 條目宣告 host 層 timeout」、以及 design.md R9 的代價記錄；tasks 1.6／1.7／1.8 亦已同步。全檔 grep「取鎖」「自帶」僅命中刻意的 MUST NOT 條款與 R9。修正參照：Round 4 `## Fix Actions` G1。驗證 reviewer：Reviewer V。
- G5 — `resolved`。收窄出現在全部三個規範位置（design.md D4、spec requirement、proposal.md），R10 逐字記錄未關閉的部分，tasks 1.5 括號亦含該項。修正參照：Round 4 G5。驗證 reviewer：Reviewer V。

集合因此清空。以下為本輪新發現。**五筆全部 `disposition` 為 `fix-introduced`，全部源自 Round 4 的修正動作**——本輪未發現任何 `new` 缺陷。

### Warning（blocking）

**H1** — `severity`: Warning｜`confidence`: 100｜`layer`: design｜`disposition`: `fix-introduced`｜`introduced_by`: Round 4 `## Fix Actions` 的 **G9** 條目（`__pycache__` 範圍限於 portable-manifest target）｜`location`: specs/cash-round-gate/spec.md 唯讀 requirement 與其 scenario；tasks.md 1.2
`summary`: G9 的範圍限定只套用到 design.md 的驗收標準，spec delta 與 tasks 完全未同步——spec 的 requirement 仍是無條件的「MUST NOT 建立目錄或寫入 bytecode cache」，scenario 仍無條件斷言「沒有產生 `__pycache__`」，tasks 1.2 的 case 亦為無條件。spec 是規範交付物，因此本 change 對 receipt-based target 立下了一條它自己的 design 逐字說明為不可達成的 MUST，且 1.2 依該 MUST 寫出的測試在 receipt target 上必然失敗。
主 agent 覆核：成立。我在 Round 4 修 G9 時只編輯了 design.md。

**H2** — `severity`: Warning｜`confidence`: 90｜`layer`: design｜`disposition`: `fix-introduced`｜`introduced_by`: Round 4 `## Fix Actions` 的 **G2** 條目（D7 一般化與 tasks 1.1 加入發佈）｜`location`: design.md D7 末段 vs tasks.md 1.1
`summary`: D7 前段已一般化為「每一次改動 manifest 覆蓋的 runtime bytes 之後、下一個 Cash command 之前都必須發佈」，但末段的順序句未同步，仍規定單一發佈點並以「最後執行 source-only 發佈；之後才可再呼叫任何 Cash command」收尾。tasks 1.1 現在在版本調升後當場發佈並明文倚賴該發佈使 `cash task done` 可用——既不是末段所述順序，也直接與該子句相斥。實作者若照末段執行，正是 G2 描述的停機窗口。
主 agent 覆核：成立。我加了一般化段落卻沒改緊接其後的順序句。

**H3** — `severity`: Warning｜`confidence`: 90｜`layer`: design｜`disposition`: `fix-introduced`｜`introduced_by`: Round 4 `## Fix Actions` 的 **G5** 與 **G7** 條目｜`location`: specs/cash-round-gate/spec.md 的 grader immutability 與活動判定兩個 requirement 的 scenario 集合；tasks.md 1.4
`summary`: Round 4 新增的兩條窄化規則都沒有 distinguishing scenario，完全忽略它們的實作能通過當時全部 32 個 scenario——這正是 Round 4 自己以 G3 認定為 Warning 的同一種缺口。其一「聯集來源 MUST 限於本身 active 的被列舉 change」：既有 scenario 的 GIVEN 是「兩者皆 active」的正面案例，或「沒有任何被列舉 change 宣告」（舊語意亦成立），沒有任何 scenario 能區分「非 active change 有宣告」時應判 `fail`。其二「parked change MUST NOT 計入 active 判定」：既有 scenario 只斷言 parked 被納入判定，未斷言 parked 不使 change 判為 active。
主 agent 覆核：成立，且是本輪最值得注意的一筆——我在 Round 4 把「規則缺 distinguishing scenario」判為 Warning 並修了 G3，卻在同一輪新增的兩條規則上重犯。

### Suggestion（非 blocking）

- **H4**（reviewer 給 Suggestion 80）｜`disposition`: `fix-introduced`｜`introduced_by`: Round 4 的 **G7** 與 **G5** 條目｜`location`: design.md D4 第二段末
  `summary`: 同一段落先立下「MUST NOT 納入已終結或 parked 的 change」，段末卻留著以 parked 為前提的舊理由（「被列舉進來的 parked change 其最後一輪 `## Decision` 常正是 `next_round`，使該情形更容易成立」）。新規則下該句前提已不成立，且會讓讀者反推出 parked change 仍參與聯集。spec 的對應段落無此句，屬 design 單點殘留。
- **H5**（reviewer 給 Suggestion 75）｜`disposition`: `fix-introduced`｜`introduced_by`: Round 4 的 **G1** 條目｜`location`: design.md `## Implementation Contract` 的 Stop hook 介面與驗收標準
  `summary`: G1 把時間上限的承擔者移到 `.claude/settings.json` 的 hook 條目，但 design 中唯一描述該條目形狀的位置未同步：介面未提 `timeout`，驗收標準亦未含該項。D6、spec 兩處與 tasks 1.8 都帶了該 MUST，僅此處落單。Reviewer V 另確認宣告 `timeout` 不與「settings.json 內不含判定邏輯」衝突——它是 host 層執行上限而非判定邏輯。

## Rating

- post-filter 累積 blocking 集合 `Critical` 數：0
- post-filter 累積 blocking 集合 `Warning` 數：3
- 非 blocking triaged finding 數：2
- `critical_gap`：`false`
- `round_type`：`micro`

理由：G1 與 G5 經 Reviewer V 以當前 artifact 原文驗證解決並移出集合，集合清空。本輪五筆新發現的 `disposition` 全部為 `fix-introduced`，其中 H1、H2、H3 為 `Warning` 且經信心過濾後維持（100／90／90），依既有通過條件全部 blocking；H4 與 H5 的 severity 為 `Suggestion`，信心過濾只降級不升級，故維持非 blocking。集合含 3 筆 `Warning`、不含 `Critical`，`critical_gap` 為 `false`，但集合非空，本輪不通過。

本輪的診斷意義大於其 finding 數量：**五筆全部由 Round 4 的修正引入，無一為 `new`**。這代表當前 artifacts 的實質設計面已趨穩定，剩餘缺陷集中在「一次修多處時未把同一概念的全部出現處同步」這一個機制上。該模式在 Round 2、3、4、5 連續出現，是本迴圈唯一未被根治的失效來源；H3 更是在 Round 4 剛把同型缺口判為 Warning 並修正之後，於同一輪新增的規則上重犯。

## Fix Actions

本輪修正 3 筆 blocking finding 與 2 筆非 blocking finding。修改檔案 3 個：`design.md`、`specs/cash-round-gate/spec.md`、`tasks.md`。`proposal.md` 與 `specs/cash-cli/spec.md` 本輪未修改。

**H1**（blocking）：specs/cash-round-gate/spec.md 的唯讀 requirement 改為「MUST NOT 建立目錄」為無條件、而「不寫入 bytecode cache」的義務 MUST 只適用於 portable-manifest target，並逐字寫入理由（launcher 僅在 portable 分支設 `sys.dont_write_bytecode = True`、receipt-based target 的寫入早於 handler、本 requirement 不修改 launcher）；對應 scenario 的 GIVEN 補上「該 target 為 portable-manifest target」；tasks 1.2 的 case 改為「在 portable-manifest target 上不產生 `__pycache__`（receipt-based target 不適用該義務）」。

**H2**（blocking）：design.md D7 末段改寫為兩個發佈點的順序——先調升 `cash-skills.version` 與 `BUNDLE_VERSION` 並**當場**執行 source-only 發佈（逐字說明只調升不發佈會使 CLI 立即失效而連 `cash task done` 都不能執行），之後才擴充 installer runtime inventory、新增 runtime 檔案並**再次發佈**；並刪除與 tasks 1.1 相斥的「之後才可再呼叫任何 Cash command」單一發佈子句，改為「每個發佈點之後才可再呼叫 Cash command，其後每一次改動 manifest 覆蓋的 runtime bytes 都同樣適用此規則」。

**H3**（blocking）：specs/cash-round-gate/spec.md 新增兩個 distinguishing scenario——「非 active change 的宣告不解除判定」（GIVEN 受保護路徑只被一個最高編號 `## Decision` 為 `passed` 的被列舉 change 宣告，THEN active change 的 gate 判 `fail`、AND 已終結 change 的宣告不計入聯集）與「parked change 不使判定為 active」（GIVEN 唯一具 round file 的 change 位於 `.parked/` 且 `## Decision` 為 `next_round`，THEN MUST NOT 判定為 active、AND gate 狀態為 `skip`）。tasks 1.4 的 case 列表補上兩項對應 case。

**H4**（非 blocking，triage 並修正）：triage 註記——D4 段末殘留以 parked 為前提的舊理由。刪除該子句，保留「兩個 active change 並存」的偽陽性理由。

**H5**（非 blocking，triage 並修正）：triage 註記——Implementation Contract 的 hook 條目形狀未同步。介面 bullet 加上「該條目 MUST 宣告 host 層的 `timeout`（見 D6 與 R9）」並註明 `timeout` 是 host 層執行上限而非判定邏輯、不構成「settings.json 內不含判定邏輯」的例外；驗收標準補上該項。

**修正後重跑的檢查**：`validate` 通過；pre-round mechanical self-check 全數重跑通過。round-gate spec 現有 6 個 requirement 與 34 個 scenario（本輪自 32 增加 2 個）。

**針對連續四輪同一失效模式的窮舉稽核**：鑑於本輪五筆全部為 `fix-introduced`、且下一輪是六輪上限的最後一輪，本輪的傳播檢查改為程式化窮舉而非逐點確認。對 11 個規範概念——`__pycache__` 範圍限定、host `timeout`、兩個發佈點、active-only 聯集、parked 不計 active、`r1` 錨點、`## Decision` 擷取、`round_type` 擷取、不可解析處理、半成品 change 空宣告集合、`tasks.md`-only 宣告——逐一統計其在五份 artifact 的出現次數並人工核對語意一致。另對 8 個已被取代的舊措辭做矛盾字串掃描：「之後才可再呼叫任何 Cash command」「被列舉進來的 parked change」「MUST NOT 建立目錄或寫入 bytecode cache」「取全部被列舉 change 宣告的聯集」「自最小編號起連續」「非 `archive` 的目錄」「立即 exit」「不調升 `cash-skills.version`」——全部 0 命中。另核對六個 requirement 均有 backing task。

**範圍外或未修復事項**：無。本輪無 `未修復：裁判面保護` 紀錄，無 accepted-risks 降級。disposition 覆核：五筆 `fix-introduced` 的 `introduced_by` 均經比對 Round 4 `## Fix Actions` 的 G9、G2、G5、G7、G1 條目成立。本輪無 `new` finding，故無需檢查是否應更正為 `fix-introduced`。無 blocking 轉非 blocking 的更正。

## Decision

`next_round`

本輪 post-filter 累積 blocking 集合含 3 筆 `Warning`（H1、H2、H3），不含 `Critical`，不符通過條件。三筆與 2 筆非 blocking finding 均已在本輪 `## Fix Actions` 記錄對應修正並實際套用，修正後 `validate` 與窮舉稽核皆通過。依位置推導，下一輪是本次執行的第六輪、非第四輪，故為 `micro` 輪，由一位全新的 Reviewer V 進行差異驗證。

第六輪是本次執行六輪上限的最後一輪：若其累積 blocking 集合仍含 `Critical` 或 `Warning`，本次執行 MUST 記 `decision: aborted` 並進行 Abort triage，將未解決成員歸入 bucket 1 以 seed 後續重跑。
