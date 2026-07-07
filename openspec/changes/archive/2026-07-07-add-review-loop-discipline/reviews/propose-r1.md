# Propose Plus Review — Round 1

## Reviewer Findings

### Critical

- severity: Critical | confidence: 100 | layer: design | reviewer: A
  - location: proposal.md `## What Changes` 第 1 項 vs design.md Decision 1 違規處理 vs delta spec「Review loop grader immutability」
  - summary: 裁判面違規處理在 proposal 與 design/delta 之間互相矛盾 — proposal 說「記錄為 Suggestion 並留待 loop 結束後由人另開 change 處理」（等於放行過關），design 與 delta 卻規定 fix 拒絕執行、記錄「未修復：裁判面保護」且 finding 保持存活（阻擋過關、到第 6 輪 fail loud aborted）。
  - recommendation: 統一為 design/delta 的「保持存活、fail loud」行為，改寫 proposal 該句並全 artifact 同步。
- severity: Critical | confidence: 80 | layer: design | reviewer: B
  - location: delta spec「Review loop grader immutability」與「Signals shared layer location and file schema」交界（design.md Decision 1 / Decision 3）
  - summary: `check` 欄位成為 self-check 的裁判輸入，但 `openspec/signals/` 不在保護路徑集內，且沒有任何規則治理誰能增改刪 `check` — loop 進行中 fix action 可以把失敗的 `check` 改寬鬆或刪除來讓 self-check 過關；signals write step 也可能自動鑄造未經人審的 shell 命令供後續 run 自動執行，抵銷本 change 自身引入的紀律。
  - recommendation: 雙邊補洞：(a) grader-immutability 規則明文禁止 fix action 增改刪任何 signal 的 `check` 欄位；(b) MODIFIED 母 spec「Signal status lifecycle is human-maintained」，把 `check` 納入人工維護欄位，自動化寫入者禁止增改刪。

### Warning

- severity: Warning | confidence: 85 | layer: design | reviewer: A
  - location: delta spec「Review loop grader immutability」（ADDED）vs 母 spec「spectra-propose-plus quality gate」場景（fixes the Warning findings before starting the next round）與「spectra-apply-plus quality gate」場景（fixes the Critical findings before starting the next round）
  - summary: spec-precedence-exception-missing — 新規則要求部分存活 finding 不得修復，直接與母 spec 兩個 quality gate 場景的無條件修復義務衝突；delta 只 ADDED 新 requirement 而未 MODIFIED 被覆蓋的既有 requirement 來定義優先序。
  - recommendation: 為兩個 quality gate requirement 加入 MODIFIED 區塊，在受影響場景明文加入 grader-protection 例外字句。
- severity: Warning | confidence: 100 | layer: text | reviewer: A
  - location: proposal.md `## What Changes` 第 1 項保護路徑清單 vs design.md Decision 1 / delta grader-immutability SHALL
  - summary: cross-artifact-definition-drift — proposal 的保護路徑集漏列 `scripts/spectra-plus/generate.fish`（design/delta 列 5 項、proposal 列 4 項），且「Spectra 驗證工具設定」未落到具體檔名 `.spectra.yaml`。
  - recommendation: proposal 補列 `scripts/spectra-plus/generate.fish` 與 `.spectra.yaml`，使三個 artifact 描述同一路徑集。
- severity: Warning | confidence: 100 | layer: text | reviewer: A
  - location: proposal.md `## What Changes` 第 2 項 ledger 欄位清單 vs design.md Decision 2 表格 / delta「Review loop ledger output」
  - summary: cross-artifact-definition-drift — proposal 的 ledger 欄位清單漏列 `skill` 欄（design/delta 定義七欄，proposal 只列六欄語意）。
  - recommendation: proposal 補上 `skill` 欄，使三個 artifact 描述同一 7 欄 schema。
- severity: Warning | confidence: 80 | layer: design | reviewer: B
  - location: delta spec「Review loop ledger output」+ design.md Implementation Contract 行為 2
  - summary: ledger 是 append-only 而 round file 重跑會覆寫 — aborted 後重跑或 propose 之後接 apply 迴圈時，「行數 = 表頭 1 行 + 已完成輪數」的契約與「1 header row plus N data rows」場景必然破裂，重跑語意完全未定義。
  - recommendation: 明文定義事件日誌語意：跨迴圈與重跑依時間累加、`(skill, round)` 非唯一鍵，並把行數場景改為 per-loop-run 敘述。

### Suggestion

- severity: Suggestion（原 Warning 75，confidence ∈ [50,80) 降級）| confidence: 75 | layer: design | reviewer: B
  - location: delta「Review loop ledger output」追加時點 vs 既有模板 Fix actions 流程
  - summary: 「round file 寫完之後」在 next_round 輪不確定 — fix 記錄與 re-derivation 註記在 `## Decision` 之後才補寫，decision 時點追加會系統性低估 `fixed_files`。
  - recommendation: 把追加時點釘為「spawn 下一輪 reviewers 之前；最終輪在 loop 結束、signals write step 之前」。
- severity: Suggestion（原 Warning 75 降級）| confidence: 75 | layer: design | reviewer: B
  - location: delta「Deterministic signal-derived self-checks」+ design.md Decision 3
  - summary: exit code 慣例把「偵測到 anti-pattern」與「check 本身壞掉」混為一談（grep exit 2、pipeline 127 都是非 0），會把執行錯誤當成待修復失敗而卡住 loop。
  - recommendation: 明定 0/1/其他三分法：exit 1 才是偵測到，其他非 0 為執行錯誤走 fallback。
- severity: Suggestion（原 Warning 75 降級）| confidence: 75 | layer: design | reviewer: B
  - location: signals delta Example `check: "! grep …"` + delta「executes that command from the project root」
  - summary: 未指明解譯器 — `!` 否定是 POSIX sh 語法，在 fish（本專案 shell）無效，跨 runtime 不可重現。
  - recommendation: 明定以 `sh -c '<check>'` 執行並讓 Example 在該解譯器下合法。
- severity: Suggestion（原 Warning 60 降級）| confidence: 60 | layer: design | reviewer: B
  - location: delta fallback note 規則 vs 既有模板「None; pass condition met.」規則
  - summary: fallback 註記寫入「下一輪 `## Fix Actions`」與 passed 輪固定文字的共存關係未定義。
  - recommendation: 明定註記與 pass 文字共存、不計入 `fixed_files`。
- severity: Suggestion（原 Warning 50 降級）| confidence: 50 | layer: design | reviewer: B
  - location: signals delta「Optional check field」/ README 義務
  - summary: `check` 命令無 timeout / 有界執行要求，懸掛或依賴網路會阻塞每輪 self-check。
  - recommendation: README 撰寫規則加入快速、離線、非互動。
- severity: Suggestion | confidence: 50 | layer: design | reviewer: A+B
  - location: delta「Review loop ledger output」vs 母 spec「Sub-agent failure handling」
  - summary: sub-agent 失敗導致 aborted 的輪沒有過濾後 finding，ledger 的 `criticals`/`warnings` 值未定義。
  - recommendation: 明定無過濾後 finding 時記 0。
- severity: Suggestion | confidence: 50 | layer: text | reviewer: A
  - location: delta「Deterministic signal-derived self-checks」末句 vs signals delta schema requirement
  - summary: 唯讀規則措辭範圍不一致 —「MUST NOT modify any signal file」vs「MUST NOT modify any file」。
  - recommendation: 統一為「MUST NOT modify any file」。
- severity: Suggestion | confidence: 50 | layer: design | reviewer: B
  - location: delta「Deterministic signal-derived self-checks」（For each relevant `open` signal…）
  - summary: 確定性被上游 best-effort relevance 篩選限制 — 帶 `check` 的 signal 是否執行仍取決於 agent 判斷。
  - recommendation: 帶 `check` 的 open signal 一律執行、跳過 relevance 篩選。
- severity: Suggestion | confidence: 50 | layer: design | reviewer: B
  - location: delta「Review loop grader immutability」範圍例外 + design.md Decision 1
  - summary: 衍生物耦合未處理 — 未來 change 若只列模板檔未列四個生成檔，範圍內修模板後的必要重生成會被規則擋住。
  - recommendation: 明文規定範圍列入模板檔時其重生成產物視同列入。
- severity: Suggestion | confidence: 50 | layer: text | reviewer: A
  - location: tasks.md task 1.1 驗證句
  - summary: 「其餘既有斷言不受影響」在紅燈 run 上不可觀測（generator-checks.fish 遇第一個失敗斷言即停）。
  - recommendation: 改為只主張新斷言紅燈，既有斷言以 HEAD 基準 run 驗證。

## Rating

- surviving Critical count: 2
- surviving Warning count: 4
- critical_gap: true
- round_type: full
- rationale: 兩個 Critical 均為可證實的設計層缺陷：proposal 與 design/delta 對裁判面違規處理的行為描述互相矛盾（confidence 100，直接引文對照），以及 `check` 欄位作為裁判輸入卻無任何治理、可在 loop 中被改寫的漏洞（confidence 80）。另有四個 Warning（母 spec 優先序未 MODIFIED、proposal 兩處定義漂移、ledger 重跑語意未定義）。依機械決策規則，存在存活 Critical → decision 為 next_round，且下一輪為 full。

## Fix Actions

- proposal.md：改寫 What Changes 第 1 項為「拒絕修改＋記錄＋finding 存活＋fail loud」行為（Critical 1）；補列 `scripts/spectra-plus/generate.fish`、`.spectra.yaml` 與 signal `check` 禁改（Warning 3 / Critical 2）；第 2 項補 `skill` 欄與事件日誌語意（Warning 4 / Warning 6 前半）；第 3 項改為人工撰寫、`sh -c`、自動化寫入者禁改（Critical 2）；Modified Capabilities 同步兩個 capability 的新範圍。
- design.md：Decision 1 加入 signal `check` 禁改段、衍生物耦合句、與母 spec 優先序段（Critical 2 / Warning 2 / Suggestion 衍生物耦合）；Decision 2 改題為「定稿後追加」，釘死追加時點、補 failure-abort 計數 0、fixed_files 相異檔案數與註記不計、重跑事件日誌語意（Warning 6 / Suggestion 時點 / Suggestion 計數）；Decision 3 改為 `sh -c` 執行、0/1/其他三分法、人工撰寫治理、一律執行不經 relevance 篩選、fallback 註記共存規則、README 撰寫規則（快速離線非互動）（Critical 2 / Suggestion exit code / Suggestion 解譯器 / Suggestion timeout / Suggestion relevance / Suggestion 共存）；Implementation Contract 三項行為與 Risks 同步更新。
- specs/spectra-plus-skills/spec.md：grader-immutability requirement 加入 signal `check` 禁改與衍生物耦合句、新增「Signal check field is never modified by a fix action」scenario；ledger requirement 全面改寫（確定性時點、0 計數、相異檔案數、append-only 事件日誌、re-run scenario、failure-abort scenario、per-loop-run 行數場景）；deterministic requirement 改寫（`sh -c`、一律執行、exit 三分法、註記共存、MUST NOT modify any file）；新增 `## MODIFIED Requirements` 區段，MODIFIED 母 spec「spectra-propose-plus quality gate」與「spectra-apply-plus quality gate」，於兩個 fixes 場景加入 grader-protection 例外字句並在 SHALL 段補優先序句（Warning 2）。
- specs/signals-shared-layer/spec.md：schema requirement 的 `check` 定義改為人工撰寫、`sh -c`、0/1/其他三分法，Example 改為 `sh -c` 下合法且說明 exit 語意；README contract 補 `sh -c`、exit 慣例、人工撰寫與唯讀/快速/離線/非互動/只出 0 或 1 的撰寫規則；新增 MODIFIED「Signal status lifecycle is human-maintained」，把 `check` 納入人工維護、自動化寫入者禁止增改刪，新增對應 scenario（Critical 2 / Suggestion timeout）。
- tasks.md：task 1.1 驗證句改寫（Suggestion 任務句）；task 2.1/2.2/2.3/3.1 同步新契約內容與 scenario 數，並補入「spectra-propose-plus quality gate」「spectra-apply-plus quality gate」「Signal status lifecycle is human-maintained」三個 requirement 名稱以滿足 analyzer 交叉檢查。
- 修改 artifacts 後重新執行 `spectra validate "add-review-loop-discipline"` → valid；重跑 mechanical self-check（annotation lint、requirement 名稱交叉檢查、design 標題交叉檢查、五個 MODIFIED 區塊 verbatim diff）→ 全數通過。

## Decision

next_round

（存在存活 Critical → next_round；存活 Critical 存在 → 下一輪為 full。）
