# Cash Propose Review — Round 3

micro round，單一 Reviewer V 做差異驗證。主 agent 已對其裁定與 findings 獨立重跑驗證。

## Reviewer Findings

### 累積 blocking 集合裁定（5 位成員）

**全部 5 位 resolved**：`C2`、`W5`、`R2-W2`、`R2-W3`、`R2-W4`。第 1 輪與第 2 輪的成員至此全數離開集合，且皆為 exit-(a) verified resolution。

`C2` 的裁定值得記錄：Reviewer V 沒有只確認機制被移除，而是逐項驗證「以縮減範圍解決」是否自洽——診斷宣稱的價值（D5／proposal 第 4 點的迴歸護欄定位，重跑確認新規則下 `code` 為空為 0/29）、`## Non-Goals` 的理由與程式碼相符（`spec_merge.py:213-218`、`validation.py:235-239`）、Risks 的實務影響描述三者一致，且逐 byte 保留的 master 句「相同input/output的repeated sync MUST為no-op」與該 Non-Goal 相容。

### Warning

- **R3-W1** `100` / `design` / `disposition: new` / `location: proposal.md Proposed Solution 第 1 點 對 design.md D1` — proposal 把「`- Affected specs:` 路徑進入 `code`（29 份中 12 份）」歸因為「目前規則」的缺陷，但 12/29 是本變更放寬裸 token 之後才出現的數字。主 agent 重跑確認現行規則下只有 **3/29**，proposal 因此把本變更自身引入的成本記成現狀缺陷，且與 D1 的正確歸因互相矛盾。**成立。**
- **R3-W2** `100` / `design` / `disposition: new` / `location: proposal.md Proposed Solution 第 2 點 對 delta 第 11 行、Implementation Contract 4、design Risks` — proposal 宣稱「既有的『測試形狀』過濾條件原封不動保留，因此這是嚴格放寬而非放鬆判準」，但本變更同時移除了 `.fish`／`.sh` 後綴分支：delta 有 normative 的「僅以`.fish`或`.sh`副檔名為由 MUST NOT被視為測試路徑」，Contract 4 明寫該分支移除，design Risks 自稱「行為收窄」。唯一對外描述範圍的 artifact 與 delta 在一條 MUST 上直接相反。主 agent 機械驗證兩處原文皆存在。**成立。**
- **R3-W3** `80` / `design` / `disposition: new` / `location: tasks 2.3 的驗證目標 對 tasks 1.5（a）（d）` — 2.3 只實作 `SyncPlan.trace_gaps`（Contract 6 規定為 tuple），其驗證目標卻要求 1.5（a）綠燈，而 1.5（a）斷言的空 **list** 只能來自 Contract 7 由 2.4 接線的 result dict key；1.5（d）同時引用 `plan.writes` 與 `trace_gaps` 卻呼叫回傳 dict 的 `sync_change`。兩個斷言來源在該 task 邊界不可能同時成立。**成立。**
- **R3-W4** `90` / `design` / `disposition: fix-introduced` / `introduced_by: 第 2 輪 R2-C1 修正的 D7→D6 重編號與機制移除` / `location: design.md D6 內文` — 重編號後 D6 的理由句「依 D6 也無從重跑 sync」變成自我引用（原本指向已刪除的 manifest 決策），且該前提會反噬結論：「無從重跑 sync」在 commit 之前同樣成立，不能用來論證輸出點必須早於 commit。另 Risks 的「見 Non-Goals 的實測理由」指向 design 自己的 Non-Goals，實測理由實際寫在 proposal。**成立。**

### Suggestion（非 blocking，已 triage）

- **R3-S1** `90` / `text` / `disposition: unresolved-prior` — 第 2 輪 R2-S4 的計量基準統一只覆蓋 design.md；proposal 的「7 份多抓到 11 條」仍是各檔案增量加總基準，與 D3 的全域相異值同為 11 但意義不同。
- **R3-S2** `60` / `design` / `disposition: new` — D1 的「不限字元集得 73 個候選、限定 ASCII 後 72 個」不可重現：對照組未定義、抽取範圍未標明；Reviewer V 以 Contract 1 的字元集重跑得 73（`- Affected code:` 範圍）或 74（整個 `## Impact`）。其餘量測 Reviewer V 逐項複驗全部吻合。
- **R3-S3** `60` / `design` / `disposition: fix-introduced` / `introduced_by: 第 1 輪 W7 與第 2 輪 R2-W4 的 tasks 1.6` — `execute` 以 `Workspace.discover(os.getcwd(), launcher_root=os.environ.get("CASH_PROJECT_ROOT"))` 解析工作區，既有測試從不 chdir；照 1.6 字面實作會對真實 repo 執行 sync／archive。

## Rating

- 過濾後累積 blocking 集合 Critical：0
- 過濾後累積 blocking 集合 Warning：1
- Non-blocking triaged findings：6
- `critical_gap`: `false`
- `round_type`: `micro`

前兩輪的 5 位成員全數經驗證解決並移除。本輪唯一 blocking 成員是 `R3-W4`（`disposition: fix-introduced`）：依通過條件，`new` 的 R3-W1 至 R3-W3 與三個 Suggestion 皆為非 blocking。集合非空，故不通過。

值得記錄的是本輪的三個 `new` Warning 都指向同一個位置——`proposal.md` 的 `## Proposed Solution`。前兩輪的修正集中在 delta、design 與 tasks，proposal 只被局部 patch，導致它與其餘 artifacts 的敘述逐漸脫節到互相矛盾的程度。

## Fix Actions

修改的檔案：`proposal.md`、`design.md`、`tasks.md`（3 個相異檔案）。

**R3-W4（blocking）** — D6 的理由句改寫為不自我引用且不反噬結論：明寫 pre-commit 輸出「並不使本次得以修好——依本變更的 Non-Goal，manifest 的 no-op 判定不變，重跑 sync 在 commit 前後同樣是零寫入」，其價值是讓作者在 change 目錄尚未被搬走、上下文仍在手上時看見缺口。Risks 的內部指引改為「見 proposal `## Non-Goals` 的實測理由」。

**R3-W1** — proposal 第 1 點改為與 D1 一致的歸因：現行規則 3/29，放寬裸 token 後升到 12/29，範圍收斂降回 7/29（該 7 份屬合法）；並明寫範圍收斂是本點自身成本的必要對沖。

**R3-W2** — 把原本合併的第 2 點拆成兩點：第 2 點只描述 token 掃描的放寬，新增第 3 點專門描述判準由「副檔名」改為「測試形狀」的**收窄**，含實測（損失 0、新增 2 條、排除兩個交付腳本）與代價（tests 目錄外且無 `test_` 標記的檢查腳本不再被視為測試證據）。`## Proposed Solution` 的引言由「分三個部分」改為「分四個部分」，原第 3 點順延為第 4 點；並移除原先描述污染面的段落，改為一句路徑正規化說明。已機械驗證引言宣稱的點數與實際列出的點數一致（皆為 4）。

**R3-W3** — tasks 1.5 明確拆為 plan 層（a）（b）與 command 層（c）（d）（e）兩組並註明「不得混用」：plan 層以 `build_sync_plan` 斷言 Contract 6 的 tuple、留在 2.3 的驗證目標；command 層斷言 Contract 7 的 result dict key、移到 2.4 的驗證目標。2.3 的驗證目標改為明寫 command 層 case 此時仍為紅燈、由 2.4 轉綠；追溯表對應列改為分層標示。

**Suggestion 處置** — R3-S1 已修：proposal 第 2 點標明「以檔案增量加總計，7 份各自多抓到合計 11 個條目；以全域相異值計為 9 條增為 13 條」。R3-S2 已修：D1 移除不可重現的 73／72 兩個總數，改述為「限定 ASCII 消除的正是中文以斜線當分隔的散文片語（實測唯一一例為 `中硬編碼的版本/日期字面值改為以`）」，殘留偽陽性 `runtime/install` 的記載不變。R3-S3 已修：tasks 1.6 補上「每個 case MUST 先 `chdir` 進該 workspace 的 root（結束後還原）並清除 `CASH_PROJECT_ROOT`，否則會對真實 repo 執行 sync／archive」。

**修正後機械式自我檢查** — 註解 lint（`<!--`／`-->` 皆 0）、C1 的 8 個既有 Scenario 逐 byte 保留、proposal 宣稱點數與實際點數一致（4／4）、Contract 10 條與 tasks 7／4／4 條無孤兒、舊編號（`D8`、`1.8`、`2.5`、`Contract 11`）與 `trace_inputs` 殘留皆為 0、`installer MUST` 殘留 0，皆通過。`validate` 於全部修正後重跑通過。

## Decision

next_round
