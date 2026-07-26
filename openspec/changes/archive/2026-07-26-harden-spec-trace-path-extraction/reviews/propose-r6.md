# Cash Propose Review — Round 6

micro round，本次執行的第六輪，達到迴圈上限。單一 Reviewer V 做差異驗證。主 agent 已對其裁定與 findings 獨立重跑驗證。

## Reviewer Findings

### 累積 blocking 集合裁定（5 位成員）

**全部 5 位 resolved**：`R5-W1`、`R5-W2`、`R5-W3`、`R5-W4`、`R5-W5`。Reviewer V 依第 5 輪的教訓逐一直接讀檔確認，未採信 `## Fix Actions` 的敘述。

`R5-W3` 的裁定值得記錄：Reviewer V 不只確認三個缺席 case 存在，還評估了它們的鑑別力——（i）`archive --skip-specs` 有效，因為 `archive.py:115` 顯示 `--skip-specs` 只是不把 `plan.writes` 納入 transaction、`build_sync_plan` 仍完整跑完使 plan 值非空，直接讀 plan 的錯誤實作必使該 case 紅燈；（ii）（iii）在 Contract 6 下 plan 值本就是空 tuple，無鑑別力但不影響（i）單獨構成防線。

### Warning

- **R6-W1** `95` / `design` / `fix-introduced` / `introduced_by: 第 4 輪 R4-W2 引入的錯誤事實與第 5 輪 R5-W2 據此設計的驗證手段` / `location: Contract 6 與 tasks 2.3 的理由句、tasks 1.5（b2）、Contract 10`
  - `summary`: `Workspace.list_directory` 的最後一行是 `return sorted(entries, key=lambda item: item[0].encode("utf-8"))`，`spec_files` 逐 capability 目錄走該已排序結果，因此 `delta_paths` 完全由 capability 目錄名的 byte 排序決定、與建檔順序無關。兩處理由句因而是錯誤的事實陳述，且據此設計的 1.5（b2）驗證手段空轉：「以兩種不同的建檔順序各執行一次」兩次的迭代順序逐字相同，該 case 能否擋住錯誤實作只取決於未被指定的目錄命名。
  - 主 agent 驗證：`workspace.py:223` 確為該 sorted 呼叫，`spec_files:225-234` 逐 `list_directory` 結果附加。**成立。**
- **R6-W2** `90` / `design` / `fix-introduced` / `introduced_by: 第 5 輪 R5-W2 新增（b2）時的插入點與未同步的邊界` / `location: tasks 1.5（b2）分層標示、2.3 與 2.4 驗證句、追溯表最末列` — 1.5 明寫「分為 plan 層與 command 層兩組，不得混用」，但（b2）被放在 command 層之後，其內容卻是以 `build_sync_plan` 斷言 `plan.trace_gaps`，依該 task 自己的定義屬 plan 層；連帶 2.3、2.4 與追溯表三處邊界都漏掉它。實作者若把它當 command 層，會在 2.3 邊界放行錯誤實作。**成立。**
- **R6-W3** `85` / `design` / `fix-introduced` / `introduced_by: 第 5 輪 R5-W5 新增 1.3（d）時未同步計數與下游` / `location: tasks 1.3 驗證句、2.2 驗證句、追溯表第 2 列` — 1.3 新增（d）後有四個 case，驗證句仍逐字是「三個 case 皆失敗」；（d）由 2.2 轉綠，但 2.2 的驗證句與追溯表都只列（a）（b）。（d）因此在 2.4 的「全數綠燈」之前沒有專屬落點。**成立。**

### Suggestion（非 blocking，已 triage）

- **R6-S1** `80→保留 Warning 級但 disposition 為 new，故非 blocking` / `design` / `location: tasks 1.3（d）` — （d）標【Red】但紅綠取決於未指定的書寫位置：現行 `_verification_path` 只判 `value.split(maxsplit=1)[0]`，若寫成 `python3 -m pytest <token>` 單一 span，第一個 token 為 `python3` 而回傳 `None`，該 case 在實作前即綠燈。
- **R6-S2** `65→Suggestion` / `design` / `fix-introduced` / `location: delta gap 段首句` — 第 5 輪 R5-S3 把段首句改為**回顧式**絕對敘述，而同段中段是**前瞻式**判準；在 archive 的 commit 失敗 rollback 路徑上兩者結論相反。與 R5-W4 從第 13 行移除的絕對敘述同型，只是換到另一段，而第 13 行的免責句不及於此段。
- **R6-S3** `55` / `design` / `fix-introduced` / `location: tasks 1.6` — 「每一次呼叫 MUST 使用各自獨立的 workspace」與缺席 case（ii）「先 `sync` 後 manifest 相符的 `archive`」牴觸——後者必須是同一 workspace 的兩次呼叫；且（ii）的第一次 `sync` 必然輸出診斷，捕獲範圍若涵蓋兩次會使斷言必然失敗。
- **R6-S4** `50` / `design` / `new` / `location: delta 字元集敘述` — delta 兩處只寫「ASCII 路徑字元（集）」而未定出集合，其給定目的僅為排除非 ASCII 散文；併入 master spec 後讀者無從導出 `--rootdir=...` 與 `path::test_y` MUST 被排除，該限定只由 Contract 1／4 釘住。

信心過濾器：R6-S2 由 `confidence: 65` 降級為 `Suggestion`。R6-S1 的 `disposition` 為 `new`，依通過條件非 blocking。

## Rating

- 過濾後累積 blocking 集合 Critical：0
- 過濾後累積 blocking 集合 Warning：3
- Non-blocking triaged findings：4
- `critical_gap`: `false`
- `round_type`: `micro`

第 5 輪的 5 位成員全數經驗證解決並移除，但三個新的 `fix-introduced` Warning 進入集合。本輪為本次執行的第六輪，已達迴圈上限而集合非空，因此 `decision: aborted`。

本次執行的軌跡：Critical 由 2 降至 0 並連續四輪維持 0，blocking Warning 由 11 降至 3。六輪未收斂的主因是修正本身持續引入新缺陷——第 4 輪起的每一輪都有 `fix-introduced` 成員，且第 4 輪與第 5 輪各有一次修正建立在對程式碼的錯誤事實之上（`os.listdir` 未排序、`_merge` 對重複輸入冪等），兩次都在下一輪被實測推翻。

## Fix Actions

修改的檔案：`design.md`、`tasks.md`、`specs/cash-cli/spec.md`（3 個相異檔案）。全部編輯使用帶斷言的替換（目標 MUST 存在且恰好命中一次），完成後另跑 14 項特徵字串的獨立機械驗證，全部 OK。

**R6-W1** — Contract 6 與 tasks 2.3 的理由句更正為事實：「`workspace.spec_files` 經 `Workspace.list_directory` 依 capability 目錄名的 UTF-8 byte 排序回傳，迴圈結束後的 `delta` 恆為排序最後的那一份——多 capability 的 change 會依目錄命名靜默漏報，而非隨機失敗」。1.5（b2）的變體條件由「兩種建檔順序」改為「兩種 capability 目錄命名，使只含 REMOVED 的那份分別排在最後與非最後（例如在 `a-cap` 與 `z-cap` 之間對調）」，並明寫只讀迴圈結束後 `delta` 的實作會在前者綠燈、後者紅燈，兩次皆驗才擋得住。Contract 10 同步改寫。

**R6-W2** — （b2）標為「（b2，plan 層）」；2.3 的驗證句改為「plan 層 case（a）（b）（b2）綠燈」；追溯表最末列改為「plan 層（a）（b）（b2）→ 2.3；command 層（c）（d）（e）→ 2.4」，並在該列的條款描述補上「多 delta 檔」。

**R6-W3** — 1.3 的驗證句改為「四個 case 皆失敗」；2.2 的驗證句改為「1.2、1.3（a）（b）（d）與 1.7」；追溯表第 2 列補上（d）並在條款描述補上「token 字元集前置條件」。

**Suggestion 處置（全部採納）** — R6-S1：1.3（d）明寫「兩個 token MUST 各自獨立成一個 code span（或各自為其 code span 的第一個 whitespace token）」並說明現行程式碼只判第一個 token、寫成單一 span 會使該 case 失去 Red 性質。R6-S2：delta 段首句改為前瞻式並補上「此條款與下述判準同為前瞻式，MUST NOT 涵蓋 diagnostic 輸出點之後的中止或 rollback 路徑」。R6-S3：「每一次呼叫 MUST 使用各自獨立的 workspace」限定為「上述四種存在組合的每一次呼叫」，並在（ii）明寫 MUST 使用同一個 workspace 且 stderr 捕獲範圍 MUST 只涵蓋 `archive` 那一次。R6-S4：delta 的字元集敘述補上實質限定「MUST NOT 含 `,`、`;`、`(`、`)`、`:`、`=` 等非路徑標點，使帶指令參數或 test-id 後綴的 token MUST NOT 被逐字寫入」。

**Abort triage** — 依 bucket 分類如下。

- **bucket 1（本 change 的遺留義務，seed 之後的重跑）**：`R6-W1`、`R6-W2`、`R6-W3`。三者的修正已於本輪套用並通過機械驗證，但**未經任何 reviewer 驗證**，因此仍為本 change 的義務；重跑的第一輪 MUST 以這三位 seed 累積 blocking 集合並回傳明確的 resolved/unresolved 裁定。
- **bucket 2（新發現且從未 blocking，寫入 signals）**：`R6-S1`、`R6-S2`、`R6-S3`、`R6-S4`。四者的修正亦已於本輪套用。無 Critical，因此不需建議另立後續 change。
- **bucket 3（接受的取捨）**：無。本輪未取得任何 accepted-risks 同意，`openspec/changes/harden-spec-trace-path-extraction/reviews/accepted-risks.md` 不存在。

**重跑的具體前置條件**：bucket 1 的三項修正已落地，因此前置條件已滿足，可直接重跑；重跑 MUST 自 round 7 起編號、納入 r1–r6 全部 round 檔案、並以 bucket 1 的三位 seed 第一輪的通過條件。**MUST NOT 在未變更的狀態下重跑**——本輪若未套用上述修正即重跑，第一輪必然重現同樣三個 finding。

## Decision

aborted
