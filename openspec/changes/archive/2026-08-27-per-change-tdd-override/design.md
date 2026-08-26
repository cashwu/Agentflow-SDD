## Context

TDD 目前是 `.cash.yaml` 的全域開關（`tdd: true|false`），由 `cash-apply` Step 5 讀取後決定是否取得並遵循 `instructions --skill tdd` 回傳的 canonical discipline。使用者的實際需求是 per-change 決定：小 change 跳過、大 change 啟用，不想來回編輯全域設定。同時借用「TDD in the agent loop」一文「量測產出而非規定流程」的結論，在 apply 品質關卡結束時回報 loop-ledger 摘要作為設計劣化警訊。

已驗證的程式碼事實（Reviewer A 可對照）：

- `.cash-skills/lib/cash_cli/commands/create.py` 的 `create_change` 寫入 `.openspec.yaml` 恰含 `schema:`、`created:`、`created_by:` 三行。
- `.cash-skills/lib/cash_cli/validation.py` 對 `.openspec.yaml` 只做 `schema: spec-driven` 子字串檢查（`validate_change` 的 required mapping）。
- `.cash-skills/lib/cash_cli/commands/discovery.py` 的 `_created` 逐行掃描 `created: ` 前綴，其他行一律忽略。
- `parse_openspec_config`（`.cash-skills/lib/cash_cli/config.py`）解析的是 `openspec/config.yaml`，不是 change 目錄的 `.openspec.yaml`。
- 因此在 `.openspec.yaml` 追加一行 `tdd: true|false` 不影響任何既有 CLI metadata 解析或可觀察行為；唯一 CLI runtime 檔案修改是 C6 的 installer `BUNDLE_VERSION` 發布 metadata 同步。
- `scripts/cash-skills/generate.fish` Stage 1 注入 review-gate block、Stage 2 由 `.claude` 生成 `.agents` 變體；`.claude/skills/cash-*/SKILL.md` 是 single source。
- `scripts/cash-skills/tests/skill-checks.fish` 的 `assert_tdd_discipline` 斷言兩個 apply 變體含 change-level 解析、global fallback、非法值警告與 effective value/source 輸出文字；`assert_tdd_variant_parity` 以 section 標題 `5. **Check project preferences**` 與 `6. **Show current progress**` 為 parity 區間錨點。
- `.cash-skills/manifest.tsv` 以 `skill` record 追蹤四個 cash-propose／cash-apply SKILL.md 的 digest；修改後需以 install-cash-skills.fish --self 重建。

## Goals / Non-Goals

**Goals**

- 每個 change 可獨立記錄 TDD 選擇，propose 問一次、apply 全程一致（含跨 session）。
- 全域 `.cash.yaml` 保持為未記錄時的預設，語意不變。
- apply 品質關卡結束時回報本次 loop run 的 ledger 摘要，高輪數時給設計劣化警訊。

**Non-Goals**

- 不修改 Cash CLI 的 parser、commands、`DISCIPLINES["tdd"]`、`.openspec.yaml` 初始寫入或可觀察行為；C6 的 installer `BUNDLE_VERSION` 發布 metadata 同步除外。
- `cash-debug` 的 toggle 仍只讀 `.cash.yaml`（無 change context）。
- 不做 mutation testing 或跨 change 歷史趨勢比較。
- `audit` 與 `parallel_tasks` 不獲得 change-level override；本 change 只處理 `tdd`。

## Decisions

1. **欄位載體選 `.openspec.yaml`**：它已是 change-scoped metadata（`schema`／`created`／`created_by`），CLI 讀取皆為行級寬鬆比對，append 安全；捨棄 proposal.md／design.md（敘事文件非機器讀取位置）與 per-invocation flag（跨 session 不一致）。
2. **詢問時點在 change 建立後、proposal 前**：tasks 的 `red` evidence 欄位與 apply 的 red-phase 義務都下游依賴此值，越早定案越好；且此時需求描述已知，足以給規模建議。
3. **非法值 fail toward global with warning**：`tdd:` 行出現 `true`／`false` 以外的值時印一則警告並使用全域值，不靜默忽略（避免 silent failure）、也不硬停（metadata 髒值不該癱瘓 apply）。
4. **警訊閾值取本次 run 內第 4 輪**：與 review loop 的 fourth-round checkpoint 對齊——checkpoint 與 6 輪上限都以「本次 run 內的位置」計數（re-run 的 round file 編號雖接續全域編號，run 內位置重新起算），到達 run 內第 4 輪代表前三輪未收斂，本來就觸發唯一的 full re-scan；以同一 run 內邊界作為設計劣化警訊，不引入第二個獨立常數體系，也不受跨 re-run 的全域 round 編號影響。
5. **ledger 摘要放在 review-gate region 之外**：警訊是 apply-only 行為，放在 cash-apply SKILL.md 自身的完成輸出段，避免修改 shared 的 scripts/cash-skills/blocks/review-gate.md 而波及 cash-propose。
6. **摘要範圍限本次 loop run**：ledger 是 append-only、跨 re-run 累積，`(skill, round)` 非唯一鍵；主 agent 只對本次 run 的列負責，跨 run 比較留待未來。
7. **Bundle version 以相對規則同步**：四個受守衛 `SKILL.md` 的 bytes 改變會觸發既有 `test_bundle_version_history.py` contract。實作 MUST讀取工作樹與 `git show HEAD:cash-skills.version` 的合法版本，取較大者並嚴格提升為更大的版本（strictly greater），MUST NOT寫死版本常數；先寫入 `cash-skills.version`，再同步 `.cash-skills/lib/cash_cli/installer.py` 的 `BUNDLE_VERSION`，最後以 `./install-cash-skills.fish --self` 重建 manifest。Task 1.1 已在 ingest 前完成部分 skill edit 並由全量 regression 實際暴露缺口，因此新增的修復 task 必須在任何後續受守衛檔案編輯或 Cash CLI 呼叫前完成。

## Implementation Contract

**C1 — change-level TDD 欄位**

- 載體：`openspec/changes/<change>/.openspec.yaml`；格式為 unindented 的 `tdd: true` 或 `tdd: false` 單行，append 於既有內容之後。
- 合法整行恰為 `tdd: true` 或 `tdd: false`；第一個 unindented `tdd:` 前綴行若冒號後無空格、使用 tab 或帶其他 suffix，一律非法。
- 該欄位僅由 skills 讀寫，CLI metadata parser 不感知；本 change 不修改 CLI 可觀察行為，僅依 C6 同步 installer `BUNDLE_VERSION` 發布 metadata。

**C2 — cash-propose 詢問與記錄**

- 時點：`new change` 成功之後、proposal 撰寫之前；continue 既有 change（`new change` 因已存在而未執行）時，於繼續 workflow 的當下同一時點適用。
- 前置檢查（「每個 change 恰好一次」的機械判準）：詢問前先讀該 change 的 `.openspec.yaml`——已存在 unindented `tdd:` 行時跳過詢問且不重複 append；該行缺失時（含 continue 路徑與前次詢問後中斷的 change）才詢問並記錄。
- 行為：以 AskUserQuestion 提供「套用 TDD」／「不套用 TDD」兩選項，並依需求描述給建議（行為變更為主或範圍大 → 建議套用；文件、metadata、小範圍 refactor 為主 → 建議不套用）；AskUserQuestion 不可用時依 skill 既有 fallback 以純文字詢問並等待回覆。
- 寫入：將答案以 C1 格式及尾端 LF append 至 `.openspec.yaml`；檔案非空且缺少尾端 LF 時 MUST先補恰好一個 LF separator，再寫入新行，避免既有尾行與 `tdd:` 黏合；MUST NOT 改動既有行內容，MUST NOT 修改 `.cash.yaml`。
- 失敗模式：append 寫入失敗 → 報告確切錯誤並停止 workflow（與 Prerequisites 失敗處置一致）。
- 下游：tasks 的 `red` 欄位語意不變（toggle-independent 的 failure marker 描述），不因本 change 改變撰寫規則。

**C3 — cash-apply Step 5 生效值解析**

- 解析順序（兩分支互斥、change-level 優先）：
  1. 讀 `openspec/changes/<change>/.openspec.yaml` 中第一個 unindented `tdd:` 前綴行：整個 suffix 恰為 ` true` 或 ` false` → 生效值即對應 lowercase 值，來源為 change-level。
  2. 檔案不存在、無 `tdd:` 行 → 生效值取 `.cash.yaml` 的 `tdd`，來源為 global。
  3. 第一個 `tdd:` 行的 suffix 不是 ` true` 或 ` false`（含無空格或 tab）→ 印一則含實際 suffix 的警告，然後同分支 2。
- 重複行處置：同檔存在多個 unindented `tdd:` 行時，取第一個 `tdd:` 前綴行為準並忽略其後全部 `tdd:` 行，即使第一行非法也不得改採後續合法行（與 CLI `_created` 的 first-match 逐行掃描前例一致）。
- 觀察點：Step 6 的進度輸出宣告生效值與來源（例如「TDD: on（change-level）」）。
- 後續行為不變：生效值 `true` → 呼叫 `instructions --skill tdd` 並遵循；生效值 `false` → 不強迫 red phase。test-quality 義務、task evidence 欄位 gate、`red` 與 canonical classification 的矛盾檢查改以生效值判定，其餘語意不變。
- `audit`、`parallel_tasks` 的讀取行為不變。

**C4 — loop-ledger 摘要與設計劣化警訊（cash-apply only）**

- 時點：review loop 以 `passed` 或 `aborted` 結束、最終 ledger 列與 signals 寫入步驟完成後，於最終回應（gate-complete 輸出或 abort 警告輸出）。
- 權威來源：本次 loop run 的輪數 N（run 內位置計數）與該 run 各輪 `fixed_files` 總和 M，以主 agent 本次 run 寫入的 round files 與 ledger 列為權威來源——主 agent 即該資料的產生者；ledger schema 無 run 識別欄位、`(skill, round)` 非唯一鍵，故「本次 run 的列」不可從檔案內容單獨導出。
- 內容：回報一行「apply 迴圈：本次 N 輪，修復檔案數合計 M」，並讀取 `openspec/changes/<change>/reviews/loop-ledger.tsv` 核對其尾端 apply 列與本次 run 紀錄一致。
- 警訊：N ≥ 4（run 內位置）→ 附一則設計劣化警訊，建議檢視 design.md 或以 cash-ingest workflow 更新設計；N ≤ 3 → 無警訊。警訊文字使用 prefix-中立的「cash-ingest workflow」表述，不含 `/cash-` 或 `$cash-` invocation prefix，兩變體因此逐字相同。
- 失敗模式：ledger 缺檔、無法讀取或尾端列與本次 run 紀錄不一致 → 印警告（含不一致細節），摘要仍以本次 run 紀錄回報，workflow 繼續。
- 邊界：此步驟 read-only，MUST NOT 修改任何 round file 的 `decision`，MUST NOT 使 workflow 失敗；位於 `<!-- REVIEW-GATE:BEGIN -->`／`<!-- REVIEW-GATE:END -->` region 之外；cash-propose 不包含此步驟；此段文字在兩變體經 invocation prefix 正規化後逐行相同（由全文 parity 治理涵蓋）。

**C5 — 變體對等、測試與 manifest**

- `.agents` 兩變體由 generate.fish 重新生成；新段落經 invocation prefix 正規化後與 `.claude` 逐行相同。
- `scripts/cash-skills/tests/skill-checks.fish` 的 `tdd-discipline` 群組：同步既有 Step 5 文字斷言至新解析文字，並新增斷言涵蓋（a）兩個 cash-apply 變體的 change-level 解析與 global fallback 文字、（b）非法值警告文字、（c）兩個 cash-propose 變體的詢問、append 記錄與「已有 `tdd:` 行跳過詢問」文字、（d）兩個 cash-apply 變體的 ledger 摘要步驟且該文字不出現在 cash-propose 變體。
- 斷言字串約束：（d）的正向與負向斷言 MUST 鎖定摘要步驟特有文字（例如「apply 迴圈：本次」摘要行格式或設計劣化警訊句），MUST NOT 使用 shared review-gate block 既有字串（`loop-ledger.tsv`、`fixed_files` 等在 cash-propose 變體本來就出現）；所有新斷言字串 MUST 避開 `/cash-`／`$cash-` 這類 prefix-variant token，或按變體分別斷言。
- parity 錨點 `5. **Check project preferences**` 與 `6. **Show current progress**` 標題保留不變。
- manifest 同步窗口：每次修改任一 SKILL.md 並以 generate.fish 重新生成後，MUST 在下一次任何 Cash CLI 呼叫（含 `task done`）之前執行 install-cash-skills.fish --self 重建 `.cash-skills/manifest.tsv`，否則 manifest digest drift 會使 CLI fail closed；全量 `fish scripts/cash-skills/tests/skill-checks.fish` 通過。

**C6 — Bundle version history**

- `cash-skills.version` MUST為嚴格大於實作當下工作樹值與 `git show HEAD:cash-skills.version` 值兩者較大值的版本（strictly greater），且維持單行 LF 結尾；MUST NOT寫死 artifacts 建立時的版本值。
- `.cash-skills/lib/cash_cli/installer.py` 的 `BUNDLE_VERSION` MUST同步為相同版本；寫入順序 MUST先更新 `cash-skills.version`，再修改 `BUNDLE_VERSION`。
- 全部受守衛 skill bytes 完成後 MUST執行 `./install-cash-skills.fish --self`，使 `.cash-skills/manifest.tsv` 的 `bundle_version`、skill digests 與實際檔案一致。
- `python3 scripts/cash-skills/tests/test_bundle_version_history.py` 與 installer runtime regression MUST通過；本 contract 只履行既有 bundle 發布約束，不修改 CLI 行為或 inventory schema。

## Risks / Trade-offs

- **既有斷言破壞**：Step 5 文字改寫會使 `assert_tdd_discipline` 既有字串斷言失效——任務把斷言更新與 SKILL.md 修改排在同一批，並以全量 skill-checks 驗證。
- **未來 CLI 嚴格化**：若日後 CLI 對 `.openspec.yaml` 引入嚴格 parser，`tdd:` 行需納入 allowed keys；本 change 把欄位契約寫進 cash-skill-workflows spec，archive 後成為 master 契約，未來 CLI change 可見。
- **閾值啟發性**：4 輪警訊是啟發式邊界，可能對長尾 change 誤報；警訊為 advisory、不阻擋任何流程，誤報成本低。
- **propose 每次多一問**：所有 change 建立時都會被問一次 TDD 選擇；這正是使用者要的 per-change 決定點，且單選題成本低。已有 `tdd:` 行時跳過詢問，continue 路徑不會重複問。
- **manifest fail-closed 窗口**：SKILL.md 修改與 manifest 重簽之間，任何 Cash CLI 呼叫都會以 manifest digest drift fail closed——C5 的同步窗口規則與 tasks 內嵌的 install-cash-skills.fish --self 步驟消除此窗口。
- **平行 change 的版本碰撞**：同工作樹可能已有其他 change 提升 `cash-skills.version`；C6 以工作樹與 HEAD 的較大值動態推導嚴格更大的版本，避免回退或覆寫 sibling change 的版本。
- **propose 後翻轉 TDD 選擇**：本 change 不修改 `cash-ingest`（見 proposal Non-Goals）。使用者手動或在 ingest 中把 `tdd: false` 改為 `true` 時，既有 tasks 以 `red: N/A` 撰寫的欄位可能與 canonical TDD classification 矛盾，apply 會依既有規則走 unclear-task branch 而暫停——這是預期的保護行為：翻轉選擇時應連動檢視 tasks 的 `red` 欄位。
