# Cash Propose Review — Round 7

**重跑（re-run）的第一輪，full round。** 前次執行六輪以 `aborted` 結束後，主 agent 以 `cash-ingest` 移除診斷／`trace_gaps` 機制，本輪為縮減後的首次審查。兩位 reviewer 平行執行、未互相傳遞輸出。累積 blocking 集合以前次 bucket 1 的三位 seed。

## Reviewer Findings

### 被 seed 的累積 blocking 集合裁定（3 位）

**兩位 reviewer 一致裁定全部 `resolved`**，無分歧。

- `R6-W1`（`trace_gaps` 跨 delta 檔聚合的 MUST 無守門）與 `R6-W2`（1.5（b2）分層錯置）：兩位皆確認機制**完整移除且非以隱藏方式規避**——`trace_gaps`、`SyncPlan`、`workspace.spec_files` 在四個 artifact 全部 0 命中；delta 只餘兩段純抽取條款、14 個 Scenario 中 6 個新增全為抽取行為，無任何 gap／diagnostic 的 normative 義務殘留。Reviewer A 另對照程式碼確認 Non-Goals「不動 `commands/archive.py`」的理由成立：三個抽取 helper 只在 `spec_merge.py:299-300` 被呼叫，該模組只消費 `SyncPlan`。
- `R6-W3`（1.3（d）計數與下游未同步）：兩位皆直接讀檔確認，未採信 `## Fix Actions`——1.3 四個 case、驗證句「四個 case 皆失敗」、2.2 含（d）、追溯表第 2 列含（d）與「token 字元集前置條件」。Reviewer A 另實測確認（d）確為 Red。

### Warning

- **R7-W1** `100` / `design` / `fix-introduced` / `introduced_by: cash-ingest 的腳本批次範圍縮減未同步引用敘述` / reviewer A+B（同一問題類別，已合併）/ `location: proposal.md 五處、design.md Risks 兩處`
  - `summary`: 診斷機制移出範圍後，兩份 artifact 仍以該機制為論證支柱。proposal 有兩處肯定句（「診斷會使這個原本無聲的缺陷變成可見」「本變更的診斷會使它變成可見」）與自身 Non-Goals「不新增任何診斷、gap 回報或輸出面」直接矛盾；另有兩個懸空條號指向已不存在的「第 4 點」與被誤指為診斷的「第 3 點」。design Risks 兩則引用已刪除的 `D5`。實質後果：proposal 是 apply 迴圈讀取的範圍文件，肯定句可被讀成診斷仍在交付範圍內；且殘留偽陽性 `runtime/install` 的接受論證以「診斷使 trace 在封存前可見」為兜底，該兜底已不存在。
  - 主 agent 驗證：`D5` 在 design.md 命中 2 次、「診斷」在 proposal 命中於 Motivation 與 Non-Goals 各處。**成立。**
- **R7-W2** `85` / `design` / `fix-introduced` / `introduced_by: 第 4 輪 R4-S1／S2 把第 3 輪已移除的 73／72 重新寫回` / reviewer B / `location: design.md D1 與 proposal.md 第 1 點`
  - `summary`: 「73 個相異裸 token 候選、限定 ASCII 後 72 個」仍不可重現，且與其自陳的範圍標註相反。Reviewer B 實測：以整個 `## Impact` 為範圍得 75→74，以收斂後的 `- Affected code:` 得 73→73（差集為空）；「73」恰好是文中明確否認的收斂**後**計數。質性結論（唯一被消除的是中文散文片語、收斂後消除數為 0）完全成立，錯的只有兩個絕對數字。此數字在第 3 輪 R3-S2 已被指為不可重現並自 design 移除，第 4 輪的修正又把它寫回兩處。
  - **成立。**

### Suggestion（非 blocking，已 triage）

- **R7-S1** `95` / `design` / `new` / B / `location: tasks 3.4` — 3.4 的語料枚舉明令涵蓋全部 `tasks.md` 與 `.parked`，因此必然包含本 change 自身；而本 change 的 1.3（d）刻意含 `--rootdir=...` 與 `x.py::test_y` 兩個帶字元集外字元的 token，舊規則接受、新規則必須丟棄，超集斷言在該檔上必然紅燈。危險不只誤報：讓它轉綠的最直接手段是放寬字元集，而那直接違反 delta 的 MUST。
- **R7-S2** `85` / `design` / `new` / A / `location: tasks 1.2 驗證句` — 1.2 有（a）（b）（c）三個 case，驗證句只寫「（a）失敗、（b）通過」，遺漏第 4 輪 R4-S9 專門新增的（c）護欄，使該護欄在 1.2 邊界不可判定。與 R6-W3 同型但發生在 1.2，未被其修正涵蓋。
- **R7-S3** `70→Suggestion` / `design` / `new` / A / `location: tasks 1.1（d）` — （d）標【Red】但紅綠取決於未指定的書寫形式：若比照同 task（a）寫成純文字，現行 `_paths_in_section` 本來就不收集，該 case 實作前即綠燈。與第 6 輪 R6-S1 對 1.3（d）指出的缺陷完全同型。
- **R7-S4** `70→Suggestion` / `design` / `fix-introduced` / B / `location: proposal Summary 與 Motivation 第三段` — 縮減後 Summary 的成果宣稱過度：「不再因抽取落空而靜默地以空 trace 覆蓋」，但本變更不動 `_with_trace` 的無條件抹除、不新增任何訊號，「靜默」未被觸及；Non-Goals 自己承認 root-level-only 的 change 仍會得到空 `code`。
- **R7-S5** `55` / `text` / `fix-introduced` / A / `location: tasks 第 2 節前言` — 「（本節現只有 2.1 與 2.2）」是縮減留下的編輯註記，且「2.1 至 3.1」跨兩節與「本節」並列時語意含混。
- **R7-S6** `50` / `text` / `new` / A / `location: proposal Motivation` — 「71 個 master spec trace」分母過期。主 agent 重測：寬鬆與嚴格計數皆為 **73**，分子（空 `code` 8、空 `tests` 23）不變。
- **R7-S7** `50` / `design` / `new` / B / `location: design Risks` — `_canonical_path` 剝除尾斜線使兩側的尾斜線目錄形態皆由接受變為丟棄（`code` 側單段目錄如 `openspec/`、`tests` 側如 `scripts/x/tests/`），Risks 只記載了 root-level 檔案這一類，低估了行為收窄面。實測現行 corpus 損失為 0。

信心過濾器：R7-S3 與 R7-S4 由 `[50, 80)` 降級為 `Suggestion`。Reviewer A 的 proposal 診斷殘留 finding 與 Reviewer B 的同型 finding 依 `location + summary` 合併為 R7-W1。

## Rating

- 過濾後累積 blocking 集合 Critical：0
- 過濾後累積 blocking 集合 Warning：2
- Non-blocking triaged findings：7
- `critical_gap`: `false`
- `round_type`: `full`

被 seed 的三位成員全部經兩位 reviewer 一致驗證解決並移除，證實範圍縮減是實質解決而非規避。本輪兩個 blocking 成員皆為 `fix-introduced`，且皆源自 `cash-ingest` 的腳本批次縮減未同步引用敘述——與前次執行第 4、5 輪的失敗模式同型：**批次刪除機制時，機制的載體被刪乾淨了，論證該機制的散文沒有**。

Reviewer A 對 16 項 code-facing claim 全部裁定 `holds`，包含 delta 逐 byte 保留的程式化比對（3 個舊段落與 8 個舊 Scenario 逐 byte 相同）、tasks 側 9→13→11 的量測、`code` 側 3／12／7 與 14→0 的量測。縮減後的核心價值因此經獨立驗證成立。

## Fix Actions

修改的檔案：`proposal.md`、`design.md`、`tasks.md`（3 個相異檔案）。全部編輯使用帶斷言的替換（目標 MUST 存在且恰好命中一次）。

**R7-W1** — proposal 五處與 design 兩處全部改寫：Motivation 第三段改為「該缺陷的可見性同屬後續 change 的範圍；此處記錄它，是為了說明空 `tests` 與空 `code` 的成因不同」；第 1 點刪除「與第 4 點的診斷相同」與「第 3 點的診斷使 trace 內容在封存前可見」，殘留偽陽性的接受理由改以本變更範圍內成立的論據重寫（token 形狀無法區分、加條件會排除合法項、只影響一份已封存 proposal、代價小於 14/29 落空）；root-level Non-Goal 刪除「與一則無法收斂的診斷」並把「第 4 點」改為「本文件其他處」；clause 定位 Non-Goal 刪除診斷句。design Risks 兩則的 `D5` 引用分別改為不依賴診斷的理由與「Non-Goals 引用的」。機械掃描確認 `D4`–`D7`、`第 4 點`、`trace_gaps`、`的診斷` 在四個 artifact 皆為 0 命中。

**R7-W2** — 依第 3 輪 R3-S2 的原始處置辦理：D1 與 proposal 第 1 點都刪除 73／72 兩個總數，只保留可重現的質性敘述（唯一被消除的是該中文散文片語、收斂後消除數為 0），並在 D1 註明不引用總數的理由是「該數字取決於對照組寬鬆字元集的定義，前幾輪三度出現不可重現的版本」。

**Suggestion 處置（全部採納）** — R7-S1：3.4 明寫超集斷言 MUST 排除本 change 自身的 `tasks.md`、說明該檔損失集合恰為那兩個 token，並加上「MUST NOT 為了讓斷言轉綠而放寬字元集」的禁令與理由。R7-S2：1.2 驗證句改為「（a）失敗、（b）（c）通過」。R7-S3：1.1（d）補上「該路徑 MUST 以 backtick code span 書寫」與失去 Red 性質的理由。R7-S4：Summary 改為「大幅降低抽取落空的發生率——實測 29 份 proposal 中 `code` 為空由 14 份降為 0 份」，並明寫本變更不動 `_with_trace` 的無條件抹除、不新增訊號，「靜默」本身不在範圍內。R7-S5：第 2 節前言改為「受影響的是 2.1、2.2 與 3.1 三個 task」。R7-S6：71 改為 73。R7-S7：design Risks 新增一則記載尾斜線目錄形態的兩側收窄與現行損失為 0。

**修正後機械式自我檢查** — `D4`／`D5`／`D6`／`D7`／`第 4 點`／`trace_gaps`／`的診斷` 全部 0 命中；proposal 點數 3；`71 個 master` 已不存在。`validate` 重跑通過。

## Decision

next_round
