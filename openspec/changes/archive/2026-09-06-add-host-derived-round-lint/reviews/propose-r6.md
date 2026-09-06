# Cash Propose Review — Round 6

## Reviewer Findings

本輪為本次執行的第六輪，即六輪上限的最後一輪。依位置推導為 `micro` 輪，由一位全新的 Reviewer V 進行差異驗證。

### 累積 blocking 集合逐成員裁定

**verified resolution（3 項，全部移出集合）**

- H1 — `resolved`。specs/cash-round-gate/spec.md 的唯讀 requirement、對應 scenario 的 GIVEN 與 tasks 1.2 的 case 三處均已加上 portable-manifest target 限定。修正參照：Round 5 `## Fix Actions` H1。驗證 reviewer：Reviewer V。
- H2 — `resolved`。design.md D7 末段已改寫為兩個發佈點，全檔 grep「之後才可再呼叫任何 Cash command」0 命中，且與 tasks 1.1／1.3／1.5／1.7 一致。修正參照：Round 5 H2。驗證 reviewer：Reviewer V。
- H3 — `resolved`。兩個 distinguishing scenario（「parked change 不使判定為 active」、「非 active change 的宣告不解除判定」）均已存在且與既有 scenario 不衝突，tasks 1.4 含對應 case。修正參照：Round 5 H3。驗證 reviewer：Reviewer V。

集合因此清空。以下為本輪新發現。

### Warning（blocking）

**W-A** — `severity`: Warning｜`confidence`: 90｜`layer`: design｜`disposition`: `fix-introduced`｜`introduced_by`: Round 5 `## Fix Actions` 的 **H1** 條目（bytecode 義務限於 portable-manifest target）｜`location`: design.md D5 末句；design.md `## Implementation Contract` 驗收標準；specs/cash-round-gate/spec.md 唯讀 requirement；tasks.md 1.2
`summary`: H1 的範圍限定被同一句中的無條件子句完全抵銷，且另有一處反向陳述未同步。其一，spec requirement 與 design 驗收標準在豁免 bytecode 義務的同時，仍無條件保留「排除 `.git/` 的 tracked 與 **untracked** 工作區內容……MUST 逐位元組不變」與「MUST NOT 建立目錄」；`__pycache__` 正是工作區內新建的 untracked 目錄，因此在 receipt-based target 上該豁免不生效，H1 要移除的不可達成 MUST 仍然成立，tasks 1.2 的無條件 case 亦必然失敗。其二，design.md D5 末句仍為無條件的「它不寫入任何檔案，包含不建立目錄與不寫 `.pyc`。」，與同檔驗收標準的限定直接矛盾。
主 agent 覆核：成立，且暴露 Round 5 窮舉稽核方法本身的缺陷——該稽核以**已知舊字串**比對（掃「MUST NOT 建立目錄或寫入 bytecode cache」），因此看不到 D5 改用「不寫 `.pyc`」這個同義措辭的位置，也無法察覺豁免被相鄰無條件子句抵銷這種語意層問題。字串掃描能抓殘留、抓不到同義表述與語意抵銷。

**W-B** — `severity`: Warning｜`confidence`: 80｜`layer`: design｜`disposition`: `fix-introduced`｜`introduced_by`: Round 4 `## Fix Actions` 的 **G7** 條目（parked change MUST NOT 計入 active 判定）；Round 5 的 H3 修正只觸及 spec 與 tasks｜`location`: proposal.md `## Proposed Solution`
`summary`: 「parked 不計入 active 判定」在 design D3、spec requirement、R11、tasks 1.4 都在，唯獨 proposal 未同步，且該段措辭正好反向成立——先寫「列舉對象……再加上 `openspec/changes/.parked/` 下的 parked change」，緊接下一句即「活動狀態依 round file 的 `## Decision` 判定」，無任何排除語。依 proposal 讀出的行為是 parked change 的 `next_round` 使 repo 判為 active，與 D3 的 MUST NOT 相斥。
主 agent 覆核：成立。這是同一失效模式在本迴圈的第六次出現。

### Suggestion（非 blocking）

- **S-A**（Suggestion 70，`layer`: text）｜`disposition`: `fix-introduced`｜`introduced_by`: Round 4 的 **G2** 條目｜`location`: design.md D7 標題
  `summary`: D7 內文已一般化為涵蓋兩個成因，標題仍為「新增 runtime 檔案必須在同一個 transaction 發佈 manifest」，只涵蓋新增檔案。標題是 decision 索引面，掃標題的讀者會得出與內文相反的範圍。
- **S-B**（Suggestion 60）｜`disposition`: `fix-introduced`｜`introduced_by`: Round 4 的 **G2** 條目｜`location`: design.md R5 vs tasks.md 1.1
  `summary`: R5 逐字要求「在各該 task 的驗收中要求發佈後重跑一次任意 Cash command 確認 CLI 可用」並明文納入版本 task，但 tasks 1.1 的 verification、regression、success 全部不經 `.cash-skills/bin/cash`，該項落單。Reviewer V 指出實質風險有限——實作者在 1.1 結束時必然執行 `cash task done`，而 R5 自己指出該指令失效即是強制機制。
- **S-C**（Suggestion 55，`layer`: text）｜`disposition`: `unresolved-prior`｜`location`: tasks.md 1.2 末段
  `summary`: 1.2 以窮舉列舉把 fixture 釘死為 `propose-r1.md` 至 `propose-r4.md`，但 `reviews/` 現已含 `propose-r5.md` 與本檔，清單每輪過期，實作時會漏掉最新的合規 round file。應改為範圍式措辭。

### Reviewer V 的最終一致性判斷

Reviewer V 另逐項核對並回報：round-gate spec 的 6 個 requirement 皆有 backing task，`cash-cli` 的 MODIFIED requirement 由 1.3 與 1.9 支撐；D1 的 standard input 禁令與 `--hook` 讀取 host payload 因「其內容即為待驗命題」的限定詞而不衝突；host `timeout` 在 D6、R9、Implementation Contract 介面與驗收、spec requirement、spec scenario、tasks 1.8 六處齊備；D4 段末已無殘留的 parked 舊理由；34 個 scenario 與 6 個 requirement 的計數相符。其整體判斷為：artifact set 在結構上已可實作，gate 集合、`id`、失敗模式、列舉與活動判定、發佈順序都有單一且一致的定義；剩餘阻礙集中在 W-A 與 W-B 兩處同一失效模式的殘留，兩者都只需局部改字，不涉及任何 contract、範圍或行為變更。

## Rating

- post-filter 累積 blocking 集合 `Critical` 數：0
- post-filter 累積 blocking 集合 `Warning` 數：2
- 非 blocking triaged finding 數：3
- `critical_gap`：`false`
- `round_type`：`micro`

理由：H1、H2、H3 經 Reviewer V 以當前 artifact 原文驗證解決並移出集合。本輪五筆新發現中，W-A 與 W-B 為 `Warning` 且 `disposition` 為 `fix-introduced`，依既有通過條件為 blocking；S-A、S-B、S-C 的 severity 為 `Suggestion`，信心過濾只降級不升級，故非 blocking。集合含 2 筆 `Warning`，不含 `Critical`，不符通過條件。

本輪是本次執行的第六輪，即六輪上限的最後一輪。依 `分級收斂與 micro 驗證輪` 的規定，第六輪未通過時 MUST 記 `decision: aborted` 並進行 Abort triage，因此本輪不進行修正動作，改以 triage 交接未解決義務。

收斂軌跡為 14 → 3 → 1 → 2 → 3 → 2 筆 blocking，`Critical` 自第三輪起除第四輪 full 重掃外均為 0。實質設計缺陷已在前四輪清空——第五、六兩輪的全部 finding 皆為 `fix-introduced`，無一為 `new`。唯一未被根治的失效來源是「一次修多處時未把同一概念的全部出現處同步」，它在第二至第六輪連續出現，且本輪的 W-A 進一步顯示：以已知舊字串比對的窮舉掃描抓得到殘留，抓不到同義措辭與語意抵銷。

## Fix Actions

本輪依 Abort triage 規定不進行修正動作，僅記錄 triage。修改檔案 0 個。

### Abort triage

**bucket 1 — 仍屬本 change 的義務，seed 後續重跑**

累積 blocking 集合中未經同意接受的全部成員：

1. **W-A** — bytecode 豁免被無條件子句抵銷，且 design.md D5 末句留有反向陳述。具體待辦：(a) 刪除或限定 D5 末句的「不寫 `.pyc`」子句；(b) 在 spec 唯讀 requirement、design 驗收標準與 tasks 1.2 的位元組不變條款中，明訂比較範圍在 receipt-based target 上另排除 bytecode cache 產物（`__pycache__/`、`*.pyc`），使豁免不與「MUST NOT 建立目錄」及「untracked 內容逐位元組不變」互相抵銷。
2. **W-B** — proposal `## Proposed Solution` 對 parked／active 的反向陳述。具體待辦：在「活動狀態依 round file 的 `## Decision` 判定」之後補一句，說明 parked change 納入列舉以接受結構類 gate、但不計入 active 判定（見 D3 與 R11）。

**bucket 2 — 新發現且從未 blocking，經 signals 寫入步驟記錄**

3. **S-A** — D7 標題只涵蓋新增檔案一個成因，與已一般化的內文相斥。
4. **S-B** — tasks 1.1 的驗收未含 R5 逐字要求的「發佈後重跑一次任意 Cash command」。
5. **S-C** — tasks 1.2 的 fixture 清單以窮舉編號釘死，每輪過期。

三筆均為 `Suggestion` 且從未進入 blocking 集合，符合 bucket 2 的定義；無任何先前 blocking finding 被置入本 bucket。

**bucket 3 — 經同意的取捨**

無。本次執行未取得任何 accepted-risks 同意，`openspec/changes/add-host-derived-round-lint/reviews/accepted-risks.md` 不存在。bucket 1 的兩筆均未提請接受為風險。

### 重跑的具體前提

不建議在未改動的情況下重跑。重跑前必須完成的具體前提是：修正 bucket 1 的 W-A 與 W-B 兩筆（兩者都只需局部改字，不涉及 contract、範圍或行為變更，因此不需要 `/cash-ingest`）。重跑時 MUST 自 `propose-r7.md` 續號、納入本次執行全部六份 round file 或其摘錄、以 bucket 1 的兩筆 seed 累積 blocking 集合，並在其第一個 full 輪套用累積集合通過條件；該輪 reviewers MUST 對每位 seed 成員回傳明確的 resolved／unresolved 裁定。六輪上限與輪型別依新執行內的位置重新起算，ledger 續寫不重置。

### 供後續重跑參考的方法建議

本輪 W-A 顯示 Round 5 採用的字串式窮舉稽核不足。後續重跑處理 bucket 1 時，除字串掃描外應另做兩項語意層檢查：(a) 對每個新增的範圍限定或豁免，檢查同一 requirement 或同一段落內是否存在涵蓋同一對象的無條件子句會將其抵銷；(b) 對每個被修改的概念，改以語意檢索該概念的同義措辭（如 bytecode cache 與 `.pyc` 與 `__pycache__`），而非僅比對已知舊字串。

### 其他紀錄

本輪無 `未修復：裁判面保護` 紀錄，無 accepted-risks 降級，無 disposition 更正——五筆的 `introduced_by` 均經比對 Round 4 G2／G7 與 Round 5 H1 條目成立，S-C 的 `unresolved-prior` 經比對亦成立。本次執行全程無任何 finding 觸發 Safety exception。fix actions 未修改 change 目錄以外的檔案，因此不執行 `touched` 記錄。

## Decision

`aborted`

本輪為六輪上限的最後一輪，post-filter 累積 blocking 集合含 2 筆 `Warning`（W-A、W-B），不符通過條件，依 `分級收斂與 micro 驗證輪` 的 round-cap 規定記 `aborted` 並完成上述 Abort triage。artifacts 保持完整且 `validate` 通過，未解決義務已歸入 bucket 1 交接後續重跑。
