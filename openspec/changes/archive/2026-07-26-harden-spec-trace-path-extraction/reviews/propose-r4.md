# Cash Propose Review — Round 4

full round 檢查點，兩位 reviewer 平行執行、未互相傳遞輸出。主 agent 已對其裁定與 findings 獨立重跑驗證。

## Reviewer Findings

### 累積 blocking 集合裁定（1 位成員）

**`R3-W4`：兩位 reviewer 皆裁定 `resolved`**，無分歧。前四輪的成員至此全數離開集合。

### Warning

- **R4-W1** `85` / `design` / `disposition: fix-introduced` / `introduced_by: 第 3 輪 R3-W4 的修正只落在 design.md` / reviewer A / `location: proposal.md 第 4 點與 specs/cash-cli/spec.md 診斷條款，對 design.md D6`
  - `summary`: 第 3 輪判定為「會反噬結論」的理由句只從 design.md 移除，未傳播到另外兩個 artifact；proposal 與 delta 仍逐字寫著「否則 change 目錄已被移入 archive，作者已無從修正」，而改寫後的 D6 明白否定它。其中 delta 是會被 sync 併入 master spec 的 normative 文字——一旦封存，master spec 將永久記載一個本變更自己已認定不成立的因果。附帶第二處脫節：proposal 第 4 點缺了 delta 與 D4 都設有的「本次 merge 實際套用過 `@trace`」限定，字面上涵蓋了規格明文要求 MUST NOT 輸出的四種情形。
  - 主 agent 驗證：`作者已無從修正` 在 proposal.md 與 delta 各命中 1 次。**成立。**
- **R4-W2** `85` / `design` / `disposition: new` / reviewer B（與 reviewer A 的同型 Suggestion 合併，取較高嚴重度）/ `location: design.md Implementation Contract 6 與 D4；spec_merge.py:305-333`
  - `summary`: gap 判定條款以單數 `delta` 表述，但 `build_sync_plan` 對每個 delta spec 檔各建一個 `Delta`，`delta` 是迴圈變數而 `SyncPlan` 在迴圈結束後才建構。照字面實作會取到最後一個 delta 檔的值而非跨檔聚合，對多 capability 的 change 產生靜默漏報；且 `workspace.spec_files` 依未排序的 `os.listdir`，同一 change 在不同檔案系統上會得到不同結果。
  - 主 agent 驗證：`for delta_path in delta_paths:` 內賦值、`SyncPlan(...)` 在迴圈後建構；repo 中有 **9 份** change 具兩個以上 delta spec 檔。**成立。**

### Suggestion（非 blocking，已 triage）

- **R4-S1** `75→Suggestion` / `design` / `new` / A — D1 的 ASCII 實測是在收斂**前**的範圍上做的：其唯一引用的非 ASCII 例落在 `- Affected specs:` 行，而在收斂後的 `- Affected code:` 範圍上，現行 corpus 的消除數為 0。
- **R4-S2** `80→Suggestion（severity 為 Suggestion）` / `text` / `unresolved-prior` / A — 第 3 輪 R3-S2 記載「D1 移除不可重現的 73／72」，但該修正只作用於 design.md，proposal 仍逐字保留兩個總數。又一次 `review-fix-propagation-incomplete`。
- **R4-S3** `75→Suggestion` / `design` / `new` / B — delta 的一般判準（「本次 merge 是否實際套用過 trace」）與其自身列舉的 `archive --skip-specs` 相反：`_merge` 在 `--skip-specs` 下仍已執行，只是不寫入。Contract 8 未指明輸出 helper 讀 plan 值還是 command 層值，最自然的實作會使 `--skip-specs` 輸出診斷而違反規格；且無任何 case 斷言 stderr 的**缺席**。
- **R4-S4** `65→Suggestion` / `design` / `new` / B — `drift.py:_impact_paths` 是同書寫形狀的第二個消費者（同樣只認 backtick，且掃整份 proposal 未限定 `## Impact`），未在任何 artifact 被提及；本變更後兩個抽取器的語意分歧會擴大。主 agent 驗證成立。
- **R4-S5** `60→Suggestion` / `design` / `new` / B — `_canonical_path` 使 repo root 層級的 affected-code 宣告結構性地永不入 `code`，因此「只宣告 root-level 檔案」的合法 change 會得到空 `code` 與一則無法收斂的診斷；D5 的 0/29 證據範圍不涵蓋此類 change。
- **R4-S6** `60` / `design` / `new` / A — Contract 8 只約束「早於 commit」，但 `build_sync_plan` 與 commit 之間還有 `validation_failed` 與 `tasks_incomplete` 兩個中止分支，helper 放在兩端會產生不同的可觀察 stderr，無 task 釘住該差異。
- **R4-S7** `55` / `design` / `new` / B — `tests` 側缺少與 `code` 對稱的字元集衛生：token 可帶任何字元並逐字寫入 trace（`--rootdir=...`、`path::test_x`）。現況 12 個相異值全部乾淨，屬前瞻性風險。
- **R4-S8** `55` / `design` / `new` / A — tasks 3.4 要求比較新舊兩版抽取，但該 task 位於 2.1-2.2 之後、工作區已無舊版；另語料含 `.parked` 隱藏目錄，`glob` 的 `**` 預設不進入。
- **R4-S9** `50` / `design` / `new` / A — delta 的「canonical check script 裸檔名維持既有映射」無專屬 case；一旦實作者把 canonical 化提到裸檔名分支之前，映射會靜默消失（`_canonical_path("cli-checks.fish")` 回傳 `None`）。

信心過濾器：R4-S1、R4-S3、R4-S4、R4-S5 由 `[50, 80)` 降級為 `Suggestion`。Reviewer A 的多 delta 檔 finding（`confidence: 55`）與 Reviewer B 的同型 finding（`confidence: 85`）依 `location + summary` 合併為 R4-W2，取較高值。

## Rating

- 過濾後累積 blocking 集合 Critical：0
- 過濾後累積 blocking 集合 Warning：1
- Non-blocking triaged findings：10
- `critical_gap`: `false`
- `round_type`: `full`

`R3-W4` 經兩位 reviewer 一致裁定解決並移除。本輪唯一 blocking 成員是 `R4-W1`（`disposition: fix-introduced`）；`R4-W2` 雖為實質缺陷但 `disposition: new`，依通過條件為非 blocking。集合非空，故不通過。

本輪的 claim verification 值得記錄：Reviewer A 對 16 項 code-facing claim 與量測全部裁定 `holds`，包含 delta 逐 byte 保留（19/19 segment）、三組 corpus 數字、兩起可稽核事故、以及 tasks 1.1–1.7 的 Red／護欄 標註逐 case 推演。第 1 輪至第 3 輪反覆出現的「design 引用的量測不支持其結論」在本輪只剩 R4-S1 一處，且該處是範圍標註問題而非數字錯誤。

## Fix Actions

修改的檔案：`proposal.md`、`design.md`、`tasks.md`、`specs/cash-cli/spec.md`（4 個相異檔案）。

**R4-W1（blocking）** — proposal 第 4 點與 delta 診斷條款的理由句同步改為與 D6 一致：明寫 pre-commit 輸出「MUST NOT 被理解為使本次執行得以修正該缺口」，價值是讓作者在 change 目錄仍位於 active 路徑時看見缺口。proposal 第 4 點另補上「在本次 merge 實際套用過 `@trace` 的執行中」限定。機械驗證 `作者已無從修正` 在三個 artifact 的殘留為 0。

**R4-W2** — delta 的一般判準改為「任一 delta 檔的 MODIFIED、ADDED 或 RENAMED 非空即為套用過，MUST NOT 只依其中一份判定」；Contract 6 明寫實作 MUST 在迴圈內累積布林值、MUST NOT 讀取迴圈結束後的 `delta`，並記錄 `workspace.spec_files` 迭代順序不保證穩定；D4 同步改為跨檔聚合並引用「repo 中已有 9 份 change 具兩個以上 delta spec 檔」。tasks 1.5 新增 case（b2）：兩份 delta 檔（一份 MODIFIED-only、一份 REMOVED-only）時斷言 `trace_gaps` 非空，且該斷言 MUST NOT 依賴目錄迭代順序。

**Suggestion 處置（全部採納並修正）** — R4-S1 與 R4-S2 合併處理：design D1 與 proposal 第 1 點同步改寫，明寫 73→72 的對照範圍是收斂前的整個 `## Impact`、收斂後範圍的消除數為 0，並把 ASCII 限定的定位改為「未來的護欄而非現況偵測器」，與 D5 對診斷的誠實定位處理方式一致。R4-S3 與 R4-S6 合併處理：delta 的一般判準改為「本次執行是否會把套用過 trace 的 merge 結果寫入 master spec」，使 `--skip-specs` 由判準本身導出；Contract 8 明寫 helper 的輸入 MUST 是 command 層 gap 值、MUST NOT 直接讀 `plan.trace_gaps`，呼叫點 MUST 在全部 preflight 與 validation 之後、commit 之前；delta 對應加上「未寫入任何 master spec 即中止的 archive MUST NOT 輸出」；tasks 1.6 新增 stderr **缺席**斷言（三種情形）。R4-S4 與 R4-S5 寫入 proposal `## Non-Goals`：前者記錄 `drift._impact_paths` 是同形狀的第二個消費者、分歧的具體形式與收斂方向；後者記錄 root-level 宣告結構性不入 `code` 及其對 0/29 證據範圍的限制，design Risks 同步新增一則並列出實測被丟棄的值。R4-S7 已修：Contract 4 為 `tests` token 加上與 Contract 1 對稱的字元集前置條件，tasks 3.4 的乾淨度斷言同步套用到 `tests`。R4-S8 已修：3.4 補上以 `git show HEAD:` 取得舊版抽取器的手段，並明寫語料枚舉 MUST 以 `os.walk` 或 `find` 涵蓋 `.parked` 隱藏目錄。R4-S9 已修：Contract 4 明寫裸檔名映射 MUST 在任何 canonical 化之前判定並說明理由，tasks 1.2 新增【護欄】case（c）。

**修正後機械式自我檢查** — 註解 lint（皆 0）、既有 8 Scenario 逐 byte 保留、被否定推理殘留 0、proposal 點數 4／Contract 10 條／tasks 7-4-4 條無孤兒、舊編號與已移除機制殘留 0，皆通過。`validate` 重跑通過。

## Decision

next_round
