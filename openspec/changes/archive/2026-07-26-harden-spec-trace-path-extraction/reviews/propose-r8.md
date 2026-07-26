# Cash Propose Review — Round 8

micro round，重跑的第二輪。單一 Reviewer V 做差異驗證。主 agent 已對其裁定與 findings 獨立重跑驗證。

## Reviewer Findings

### 累積 blocking 集合裁定（2 位）

**全部 `resolved`**。Reviewer V 依前次執行第 4 輪的教訓，逐一直接讀檔確認，未採信 `## Fix Actions`。

- `R7-W1`（診斷殘留敘述與懸空引用）：`診斷` 僅剩 proposal 與 design 各一處的 Non-Goals 排除敘述；`D4`–`D7`、`第 4 點`、`trace_gaps` 四檔 0 命中；design Risks 兩處改寫後的指涉對象皆存在。Reviewer V 另逐一實測殘留偽陽性 `runtime/install` 接受理由的四個支柱皆成立。
- `R7-W2`（不可重現的 73／72）：兩處總數皆已刪除，全檔 `7[0-9]` 只剩 master spec trace 分母。Reviewer V 以獨立腳本重跑證實保留的質性敘述——收斂前範圍的差集恰為 `中硬編碼的版本/日期字面值改為以` 一例、該片語確實落在 `- Affected specs:` 行、收斂後範圍差集為空。

### 第 7 輪 7 項非 blocking 修正的落地驗證

Reviewer V 逐項確認 **7/7 landed**，其中三項另做了獨立實測：3.4 的損失集合（舊 4 個、新 2 個、loss 恰為那兩個 token）、Summary 的 14→0、master spec trace 總數 73（cash-skill-workflows 49、cash-cli 21、signals-shared-layer 3）。

### Warning

- **R8-W1** `85` / `design` / `fix-introduced` / `introduced_by: 第 7 輪對 R7-S7 的修正` / `location: design.md Risks 尾斜線條目`
  - `summary`: 第 7 輪新增的尾斜線風險條目附帶「實測現行 corpus 此兩類的實際損失為 0」，但該宣稱未經量測。`code` 側實際有損失：`- Affected code:` 範圍內散文提及的 `.spectra/`（單段目錄，剝除尾斜線後不含斜線）今天會進入 `code`，新規則下會被丟棄。
  - 主 agent 重跑驗證：**成立，且比 reviewer 指出的多一個**——實際為 2 例（`.spectra/` 與 `/spectra-`），皆來自同一份已封存 proposal 的散文。

### Suggestion（非 blocking，已 triage）

- **R8-S1** `50` / `design` / `new` / `location: delta Scenario「以斜線分隔的非 ASCII 散文不進入 code trace」對 delta 抽取條款與 Contract 3` — 該 Scenario 的 GIVEN 未限定書寫形式而 THEN 是無條件 MUST NOT，但 ASCII 字元集只作用於裸路徑 token，code span 分支不做字元集過濾；若該片語寫在 code span 內，新規則仍會收進 `code`，Scenario 依字面不可滿足。tasks 1.1（c）把此 case 標為【護欄】實質上把書寫形式隱含釘在純文字，但未如第 7 輪為 1.1（d）所做的那樣明寫——同一個「書寫形式決定紅綠」的類別在（c）上仍未封閉。

## Rating

- 過濾後累積 blocking 集合 Critical：0
- 過濾後累積 blocking 集合 Warning：1
- Non-blocking triaged findings：1
- `critical_gap`: `false`
- `round_type`: `micro`

`R7-W1` 與 `R7-W2` 經驗證解決並移除，第 7 輪的 7 項非 blocking 修正全部落地。本輪唯一 blocking 成員 `R8-W1` 是主 agent 在第 7 輪寫入的一句未經量測的「實測」宣稱。

本輪的 finding 數（1 blocking + 1 suggestion）是本次 change 迄今最低，且兩者都不觸及任何 Contract、delta 條款或 task 語意——皆為敘述精確度問題。

## Fix Actions

修改的檔案：`proposal.md`、`design.md`、`tasks.md`、`specs/cash-cli/spec.md`（4 個相異檔案）。全部編輯使用帶斷言的替換。

**R8-W1** — design Risks 的尾斜線條目改為記載主 agent 實測的結果：`tests` 側損失為 0；`code` 側 2 例（`.spectra/` 與 `/spectra-`），皆來自同一份已封存 proposal 的 `- Affected code:` 範圍內散文，本非路徑宣告，丟棄屬預期而非回歸。

**R8-S1** — 採納 reviewer 建議的選項 (1)：delta 該 Scenario 的 GIVEN 收窄為「以純文字（非 code span）書寫」；tasks 1.1（c）比照（d）補上「該片語 MUST 以純文字書寫——ASCII 字元集只作用於裸路徑 token，code span 分支不做字元集過濾，若置於 code span 則新舊規則都會收集它，該 case 失去護欄性質」。未採選項 (2)（把字元集檢查套到 code span 分支），因其會改變既有行為並超出 delta 的宣告範圍。

**主 agent 自行追加的稽核與修正** — R8-W1 暴露的是「未經量測即寫入『實測』宣稱」這個模式，因此主 agent 對四個 artifact 的全部 14 處「實測」字樣逐一稽核是否附帶可重現的數據。此稽核抓到一項 reviewer 未指出、且**存活了八輪**的缺陷：proposal `## Alternatives Considered` 仍逐字保留「`tests` 的空在實測中有 23 個是合法結果」——該說法在第 1 輪 R1-W2 即被推翻（23 個空 `tests` 全來自同一個 change，成因是 `_VERIFICATION_CLAUSE` 對 `以` 後不接空白的定位缺陷），當時的修正落到 D5 與 Motivation 卻漏了本節；且該替代方案在診斷移出範圍後本身已不再相關。已整條替換為與現行範圍相符的替代方案（「在抽取器內對『宣告了 affected code 卻抽不到路徑』直接 fail closed」及其不採納理由）。

**修正後機械式自我檢查** — `D4`–`D7`、`第 4 點`、`trace_gaps`、`的診斷`、`23 個是合法結果`、`損失為 0，屬前瞻性` 全部 0 命中；既有 8 個 Scenario 逐 byte 保留、Scenario 總數 14、註解 lint 0/0；proposal 3 點、Contract 7 條、tasks 4-2-4。`validate` 重跑通過。

## Decision

next_round
