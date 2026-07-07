# Propose Plus Review — Round 2

## Reviewer Findings

### Critical

（無 — confidence ≥ 80 的 Critical finding 不存在。）

### Warning

- severity: Warning | confidence: 85 | layer: design（原報 text，主 agent 依 filter 規則改判 — 修復涉及行為敘述）| reviewer: A
  - location: proposal.md `## What Changes` 第 1 項 vs delta「Review loop grader immutability」/ design Decision 1
  - summary: proposal 的「除非…明文列入範圍」例外子句附著在 signal `check` 禁改之後，讀起來像 `check` 禁令也有範圍例外，與 delta/design 的「regardless of declared scope」矛盾（cross-artifact-definition-drift）。
  - recommendation: 改寫 proposal 使範圍例外只涵蓋保護路徑集，`check` 禁令明文標注「一律禁止、不受範圍例外影響」。
- severity: Warning | confidence: 90 | layer: design | reviewer: A
  - location: tasks.md §2/§3 vs signals delta「Signal status lifecycle is human-maintained」新 scenario
  - summary: lifecycle MODIFIED 明文約束 signals write step 不得增改刪 `check`，但沒有任何 task 把這個義務落到操作載體 — SIGNALS-WRITE-STEP 區塊的 schema 行仍列恰好七欄、update 規則未要求保留 `check`（spec-requirement-no-backing-task）。
  - recommendation: 新增 task 修訂 SIGNALS-WRITE-STEP 區塊（schema 行提及 `check`、update-in-place 保留 `check` 逐字節不動、新建不得自動鑄造 `check`）。
- severity: Warning | confidence: 85 | layer: text | reviewer: A
  - location: proposal.md `## Capabilities` Modified 兩個 bullet vs 兩份 delta
  - summary: `spectra-plus-skills` bullet 漏列第三個 ADDED requirement（Deterministic signal-derived self-checks），而 self-check 消費行為誤掛在 `signals-shared-layer` bullet 下 — capability 對 delta 的映射漂移。
  - recommendation: 把確定性消費敘述移入 `spectra-plus-skills` bullet；`signals-shared-layer` bullet 限縮為 schema、README 與寫入者治理。
- severity: Warning | confidence: 80 | layer: design | reviewer: B
  - location: signals delta Example（`! grep -rq …`）+ README contract「written to exit only 0 or 1」
  - summary: 規範自己的示範命令把 grep 執行錯誤（exit 2）經 `!` 反轉映成 exit 0 =「anti-pattern 不存在」— 執行錯誤分支不可達、錯誤被靜默讀成通過；「只以 0 或 1 結束」的撰寫規則更等於指示作者把錯誤折疊掉，自我挫敗。
  - recommendation: Example 改為明確分辨 `$?` 的三態命令；撰寫規則改為「偵測結果只以 0/1 回報、可預見錯誤以其他 exit code 浮現、禁止盲目反轉」。

### Suggestion

- severity: Suggestion（原 Critical 70，confidence < 80 降級）| confidence: 70 | layer: design | reviewer: B
  - location: delta「Deterministic signal-derived self-checks」+ design Decision 3
  - summary: check 對「範圍外／既有」anti-pattern exit 1 時，規則只有「須修復才能 spawn reviewers」一條路 — 修復可能落在範圍外或裁判保護路徑，形成無合法動作的死鎖，且一個既有 anti-pattern 會鎖死所有後續 change 的 loop。
  - recommendation: 定義範圍外失敗的逃生路徑：記錄註記、納入 reviewers context、照常 spawn。
- severity: Suggestion（原 Warning 70 降級）| confidence: 70 | layer: design | reviewer: B
  - location: delta grader requirement「explicitly named」
  - summary: 「明文列入」對目錄、glob、散文式提及未定義，兩個合理 agent 會做出相反的 fix/withhold 判斷。
  - recommendation: 釘死判定規則：根相對路徑逐字出現；目錄視同其下所有檔案。
- severity: Suggestion（原 Warning 70 降級）| confidence: 70 | layer: design | reviewer: B
  - location: 兩份 delta 的 `sh -c '<check>'` 措辭
  - summary: 字面內插進單引號字串會在值含引號時產生假性執行錯誤（規範自己的 Example 即含引號），兩個合理 agent 執行方式不同。
  - recommendation: 明定「值作為 `sh -c` 的單一命令字串參數傳入，不得內插」。
- severity: Suggestion（原 Warning 65 降級）| confidence: 65 | layer: design | reviewer: B
  - location: design Decision 1 違規處理（fail loud 主張）
  - summary: 輪次無記憶 — 被裁判保護而未修復的 finding 若後續輪 fresh reviewers 沒再發現，loop 會靜默通過，fail loud 保證不成立。
  - recommendation: 完成摘要必須列出全部輪次的裁判保護記錄（含 passed 結局）。
- severity: Suggestion（原 Warning 60 降級）| confidence: 60 | layer: design | reviewer: B
  - location: delta ledger 追加時點 vs 母 spec「Validation precedes the quality gate」
  - summary: 追加時點枚舉未含 validation 重跑的修復記錄，row 寫入後補記 `## Fix Actions` 會讓 `fixed_files` 低估。
  - recommendation: 把 validation 修復記錄納入枚舉並以「spawn 前」為最終錨點。
- severity: Suggestion | confidence: 70 | layer: text | reviewer: A
  - location: proposal.md `## Impact` New 行 vs design Non-Goals
  - summary: 「非版本庫內容」與「隨 change 目錄歸檔」矛盾 — 歸檔即入庫。
  - recommendation: 改寫為「由後續 loop 產生於 change 目錄、隨 change 歸檔」。
- severity: Suggestion | confidence: 65 | layer: text | reviewer: A
  - location: design Migration Plan / Risks「三個新區塊」
  - summary: 與 Decision 3 的實際形狀（兩個新 sentinel 區塊＋既有區塊內改寫）不一致，實作者可能誤加第三個 sentinel。
  - recommendation: 改寫為「兩個新 sentinel 區塊＋既有區塊內改寫」。
- severity: Suggestion | confidence: 60 | layer: text | reviewer: A
  - location: delta MODIFIED gates 的 SHALL 段新句 vs design 行為 1 宣告
  - summary: delta 在兩個 gate requirement 本文各插入一句優先序句，超出 design 宣告的「場景層修改」範圍（良性但未宣告）。
  - recommendation: design 行為 1 補宣告該句。
- severity: Suggestion | confidence: 55 | layer: design | reviewer: A+B
  - location: delta ledger 追加時點兩個錨點的括號關係
  - summary: 「寫完之後」與「spawn 之前」可能被讀成不同括號範圍。
  - recommendation: 明定「spawn 前」為最終錨點。
- severity: Suggestion | confidence: 55 | layer: design | reviewer: B
  - location: design Decision 1 自指涉重生成
  - summary: 範圍內修模板並重生成時，進行中 loop 依哪個指令版本執行未定義。
  - recommendation: 明定進行中 loop 依啟動時版本、重生成自下次 loop 生效。
- severity: Suggestion | confidence: 55 | layer: text | reviewer: B
  - location: delta ledger「header row」
  - summary: 表頭內容（欄名、大小寫、分隔）未釘死，跨 change 機器讀取可能遇到分歧表頭。
  - recommendation: 表頭逐字釘死為七個欄位名依序 tab 分隔。
- severity: Suggestion | confidence: 50 | layer: design | reviewer: B
  - location: design Decision 1 保護路徑集
  - summary: 保護集漏列可識別的裁判輸入 — openspec/specs/ 下的 master specs（loop 中改它可消解 adherence finding）。
  - recommendation: master specs 入保護集；install/repair 腳本記錄排除理由。
- severity: Suggestion | confidence: 50 | layer: design | reviewer: B
  - location: delta grader requirement 約束主詞「a fix action」
  - summary: mechanical self-check 修復是另一個行為者，發生在 round file 之前、規則文字未涵蓋。
  - recommendation: 約束主詞擴為 loop 進行中主 agent 的所有修改。

## Rating

- surviving Critical count: 0
- surviving Warning count: 4
- critical_gap: false
- round_type: full
- rationale: Round 1 的兩個 Critical 已在前輪修復並未再現。本輪四個 Warning 均為可證實的一致性或設計缺口：proposal 例外子句歧義（85）、SIGNALS-WRITE-STEP 治理缺 backing task（90）、capabilities 映射漂移（85）、check 範例把執行錯誤映成通過（80）。另有多筆 confidence ∈ [50,80) 的降級 Suggestion，其中「範圍外 check 失敗死鎖」（原 Critical 70）屬實質設計缺陷，隨本輪一併修復。依機械決策規則：無 Critical 但有 Warning → next_round；存活 Warning 含 layer == design → 下一輪為 full。

## Fix Actions

- proposal.md：What Changes 第 1 項改寫 — 行為者擴為主 agent（含 self-check 修復）、保護集補 openspec/specs/ master specs、「明文列入」判定規則入文、`check` 禁令明文「一律禁止增改刪，不受範圍例外影響」、補完成摘要義務（W1 / S-master-specs / S-actor / S-named / S-fail-loud）；Capabilities 兩個 bullet 重新對位（W3）；Impact New 行改寫去除「非版本庫內容」矛盾（S-impact）。
- design.md：Decision 1 — 行為者主詞、保護集第 6 項（master specs）與 install/repair 排除理由、「明文列入」判定規則、自指涉重生成版本規則、違規處理補「輪次無記憶 → 完成摘要列出全部記錄」；Decision 2 — 追加時點枚舉補 validation 修復記錄並明定「spawn 前」為最終錨點、表頭逐字釘死；Decision 3 — `sh -c` 單一參數形式、exit 1 範圍內／範圍外分流（不死鎖）、SIGNALS-WRITE-STEP 同步修訂段、README 撰寫規則改為「錯誤以其他 exit code 浮現、禁止盲目反轉、YAML 陷阱」；Implementation Contract 三項行為同步（含宣告 MODIFIED gates 的 SHALL 段優先序句，S-undeclared）；Risks 與 Migration Plan 的「三個新區塊」改寫（S-blocks）。
- specs/spectra-plus-skills/spec.md：grader requirement — 主詞、master specs、named 判定、進行中 loop 版本規則、完成摘要義務＋新 scenario「Completion summary surfaces withheld findings even on pass」（共 5 scenario）；ledger requirement — 追加時點重述（spawn 前為最終錨點、含 validation 修復記錄）、表頭逐字釘死；deterministic requirement — `sh -c` 單一參數、exit 1 範圍內外分流＋新 scenario「Out-of-scope check failure does not deadlock the loop」（共 4 scenario）。
- specs/signals-shared-layer/spec.md：schema requirement — `check` 執行形式改為單一參數傳入；Example 改為明確三態分辨命令（W4）；README contract — 撰寫規則改寫（偵測結果 0/1、執行錯誤以其他 code 浮現、禁止盲目反轉、YAML 引號與 `#` 截斷陷阱），scenario AND 行同步。
- tasks.md：新增 task 2.4（SIGNALS-WRITE-STEP 區塊修訂，對應 W2）；task 2.1/2.2/2.3/3.1 同步新契約與 scenario 數（五／六／四個）。
- 修改 artifacts 後重新執行 `spectra validate "add-review-loop-discipline"` → valid；重跑 mechanical self-check（annotation lint、requirement 名稱與 design 標題交叉檢查、scenario 數對照、五個 MODIFIED 區塊 verbatim diff）→ 全數通過。

## Decision

next_round

（無存活 Critical、存在存活 Warning → next_round；存活 Warning 含 layer == design → 下一輪為 full。）
