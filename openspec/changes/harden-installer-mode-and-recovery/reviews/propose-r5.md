# Cash Propose Review — Round 5

## Reviewer Findings

本輪為 micro 輪，由單一 Reviewer V — Verification 對 cumulative blocking set 做 delta 驗證，並重點檢查 round 4 大幅改寫的 D2／IC2 恢復順序。

### Cumulative blocking set 逐項判定

| member | verdict | 依據 |
| --- | --- | --- |
| G3 | **unresolved** | round 4 的修正宣稱「四個既有測試…沒有一個經過 `install` helper 的 `TEST_` 轉譯層」，此為可證偽的事實錯誤。實際有六個使用 hook 的測試、四條注入路徑，其中 `test_installer_runtime.py:394` 與 `:868` 正是經 `install` helper 的 `TEST_` 轉譯層。缺陷機制（宣告的注入路徑集合與實際集合不符）與 G3 完全相同，只是漏掉的對象換了一組 |
| G5 | **resolved** | proposal `## Proposed Solution` 第 2 點已改寫為單一機制陳述並與 D2／IC2 逐條對齊；被 D2 否決的分支零殘留 |
| G6 | **unresolved** | spec 的收斂已到位，但 G6 的 `location` 同時列出 design `### IC3` 末條與 tasks 2.3，兩處皆未修改：IC3 仍為「SHALL NOT 在任何測試、規格或文件中留有引用」，tasks 2.3 的驗收仍為「確認實作、測試、規格與文件皆無其名稱殘留」，archive 後仍必定失敗 |

G5 以 verified resolution 離開集合；G3、G6 留在集合中。

round 4 的非阻斷項 G1、G7、G8、G9、G10、G11、G13、G15 皆判定 resolved；G2、G4 陳述層面 resolved 但引入新缺陷（V1）；G12 僅部分關閉（V7）；G14 未關閉（V5）；G16 的措辭統一已完成但新增的 pre／post-lock 說明本身有誤（V6）。

### D2／IC2 重寫的針對性驗證結果

Reviewer V 逐項回答並對源碼求證：read-only 探測可置放於 `validate_target_prerequisites` 之後到 conflict 判定之間；`recover_installer` 的 early return 確為 `if not journal.exists(): return`，改回傳 `False` 語意正確；dry-run diagnostic 走 stderr，不違反零寫入契約，且 `report_version_controlled_receipt` 已建立 preflight 期 stderr 診斷的先例；`phase: committed` 恢復路徑與其既有測試在新順序下三項斷言全數維持。但 `newer` early return 的相對順序未規範、取鎖會建立不存在的 lock、回傳偽時 descriptor 處置未定義三項均為新缺陷。

### Critical

**V1**
- `severity`: Critical
- `confidence`: 92
- `layer`: design
- `location`: design.md `### D2`、`### IC2`；specs/cash-cli/spec.md `Bundle 安裝與 runtime receipt`；`.cash-skills/lib/cash_cli/installer.py:1199-1200`
- `summary`: 新的偵測／恢復前置階段只被規範為「早於 conflict 判定」，未規範相對於 `newer` early return 的位置；而 IC2 同時要求 dry-run diagnostic「與最終分類無關而一律出現」（D2 明列 `newer`），兩條只有把該點放在 `newer` return 之前才同時成立——但偵測點與恢復點是同一點，放在該處會使「journal 存在的 newer target」在非 dry-run 下執行 rollback 寫入，違反 master spec 的「合法 newer target MUST 零寫入返回」。
- `failure_scenario`: target receipt 為 `3.0.0`，一個 v3.1.0 installer 在 publishing 階段崩潰（receipt 是最後一筆 operation，故 target 仍留 `3.0.0` receipt 加一份 journal）。以較舊 bundle 執行時本應在 `installer.py:1200` 以 `newer` 零寫入返回，新順序卻先取鎖並對一份由較新 bundle 寫出的 journal 執行 rollback；若該 journal 為未來 schema，`recover_installer` 會拋 `cannot recover installer journal` 而 exit 1，把應零寫入回報 `newer` 的路徑變成硬失敗。
- `recommendation`: 把偵測點與恢復點分離——diagnostic 的發出點置於 `newer` early return 之前（純讀取，不觸碰 target config），恢復的觸發條件加上「target 未被分類為 `newer`」的限定，並在 spec 補上 newer target 零寫入且不執行 recovery 的規定。
- `disposition`: `fix-introduced`
- `introduced_by`: `reviews/propose-r4.md` `## Fix Actions` 的「**修 G2 與 G4（恢復點早於 conflict 判定）**」中的「末段補上該偵測點同時是 dry-run diagnostic 的發出點，因此 diagnostic 對四種 dry-run 分類一律出現」。

### Warning

**V4**（與 G3 同一 finding，合併計為一個 blocking 成員）
- `severity`: Warning
- `confidence`: 95
- `layer`: text
- `location`: tasks.md 2.3；design.md `### IC5`；`scripts/cash-skills/tests/test_installer_runtime.py:32-50, 393-395, 864-869`
- `summary`: 「四個既有測試…沒有一個經過 `install` helper 的 `TEST_` 轉譯層」是事實錯誤；實際六個測試、四條路徑，其中兩個正是經該轉譯層，被漏掉的兩個在開關導入後會靜默失效。
- `failure_scenario`: `test_publication_failure_rolls_back_replaceable_state_only`（:864）設 `TEST_CASH_INSTALL_FAIL_AFTER`，經 `install` helper 轉成真名送進子行程；開關導入後該變數不再被讀取 → 安裝成功 → `assertEqual(result.returncode, 1)` 失敗。`test_publication_failure_rolls_back_the_gitignore_operation`（:393）同理。且 tasks 2.3 要求 helper「先剝除全部 `CASH_INSTALL_*`（含新開關）」，這兩個測試既不在枚舉內也就沒有管道拿回開關。
- `recommendation`: 改為「六個既有測試、四條注入路徑」並逐一列出；`install` helper 的 `TEST_` 轉譯清單一併涵蓋新開關。
- `disposition`: `unresolved-prior`

**V5**
- `severity`: Warning
- `confidence`: 88
- `layer`: text
- `location`: proposal.md `## Non-Goals`；design.md `## Context`
- `summary`: round 4 的 G14 修正只落在 design 的 `## Goals / Non-Goals`，proposal `## Non-Goals` 與 design `## Context` 兩處仍寫「lock 協定」；同一份 design 內兩處對同一不變量給出不同措辭，且 proposal 宣告的不變量與 delta spec 新增的 lock 釋放-重取 normative 句直接牴觸。
- `recommendation`: 兩處改為與 design `## Goals / Non-Goals` 逐字相同的措辭，並在 proposal 補上「recovery 觸發的釋放-重入沿用既有 post-lock 重新分類的同一路徑」。
- `disposition`: `fix-introduced`
- `introduced_by`: `reviews/propose-r4.md` `## Fix Actions` 的「**修 G14** — proposal 與 design 的 Non-Goals 改為……」；該 fix action 宣告涵蓋 proposal，實際未套用。

### Suggestion（經 confidence filter 降級或原為 Suggestion，皆非阻斷）

- **V2**（78，`fix-introduced`）前置階段的取鎖被排在 `launcher exists without stable workspace lock` 守衛之前，而 `acquire_lock` 對不存在的 lock 走 `O_CREAT|O_EXCL`，會把 master spec 要求 fail closed 的 launcher-without-lock 狀態靜默修復成新的 lock inode，同時違反「下一次 installer MUST 在同一 lock inode 上恢復」。
- **V3**（75，`fix-introduced`）IC2 只規定 `recover_installer` 回傳真時關閉 lock descriptor；回傳偽時處置未定義，主流程稍後會對同一 lock 檔開第二個 fd 並 `flock(LOCK_EX)`——同一 process 的兩個 open file description 互為獨立持有者，第二次會無限期阻塞且無診斷、無 exit code。
- **V6**（78，`fix-introduced`）D3 把 D2 新增的恢復重新進入稱為「第三個 post-lock 重新進入來源」，但重寫後它發生在主流程取鎖之前，結構上屬 pre-lock；用來支撐 at-most-once 免除規則的論證對這個來源並不成立。
- **V7**（62，`fix-introduced`）G12 的修正只加進 tasks 1.1，未在 delta spec 新增或擴充對應 scenario、也未寫進 IC5，使 tasks 含一項既無 scenario 背書也不在 IC5 之列的驗收斷言。

## Rating

- post-filter cumulative blocking set Critical count: **1**（V1）
- post-filter cumulative blocking set Warning count: **3**（G3／V4、G6、V5）
- 非阻斷 triaged finding count: **4**（V2、V3、V6、V7）
- `critical_gap`: **true**
- `round_type`: **micro**

rationale：本輪唯一離開集合的是 G5；G3 與 G6 皆判定 unresolved，兩者的共同形狀是 round 4 的 fix action 宣告涵蓋的範圍大於實際套用的範圍——G3 的修正寫進了一個事實錯誤的枚舉（四個測試／三條路徑，實為六個／四條），G6 的修正只套用到 spec 而未及 design IC3 與 tasks 2.3，V5 亦同（宣告涵蓋 proposal 卻未套用）。這三項合起來說明 round 4 的 `## Fix Actions` 記述與實際編輯之間存在系統性落差，本輪已逐一以檔案內容核對而非以 fix action 記述為準。V1 是本輪最重要的發現：round 4 為了修 G2 把恢復點前移，卻沒有回答它與 `newer` early return 的相對順序，而 IC2 同時寫下的「diagnostic 對四種分類一律出現」把該點隱含推到 `newer` 之前——那個位置會讓 newer target 被寫入，直接違反 master spec 的零寫入契約。blocking set 含一個 Critical，故 `critical_gap` 為 true。

## Fix Actions

四個 blocking 成員（V1、G3／V4、G6、V5）與四個非阻斷項（V2、V3、V6、V7）全部修復，無 grader-protection 保留項，無 accepted-risks 條目。修改檔案共 4 個：`proposal.md`、`design.md`、`tasks.md`、`specs/cash-cli/spec.md`。

**修 V1（偵測點與恢復點分離）** — design.md D2 的三步驟改寫為五步驟並明確分離兩個點：偵測為純讀取、置於 `newer` early return 之前、dry-run diagnostic 由此發出；恢復置於版本比較之後、conflict 判定之前，且只在非 dry-run 且 target 未分類為 `newer` 時執行，並說明 newer target 的 journal 可能使用本 bundle 不認識的 schema、對它 rollback 既違反零寫入也可能把 `newer` 變成硬失敗。IC2 拆為對應條款並新增「被分類為 `newer` 的 target SHALL 維持零寫入返回，SHALL NOT 執行 recovery」。spec 的 `Bundle 安裝與 runtime receipt` 同步，新增 `#### Scenario: Newer target 帶未完成 journal 仍零寫入`。proposal 第 2 點與 tasks 1.2、2.2 同步。

**修 V2（取鎖不得建立 lock、守衛順序）** — D2 第 3 步明訂順序為「先跑既有的 launcher-without-lock 守衛 → 取得既存 stable lock → recovery → 釋放 → 重新進入」，並說明以 `O_CREAT|O_EXCL` 建立新 lock 會同時違反 launcher-without-lock fail-closed 與同一 lock inode 恢復兩條契約；IC2 與 spec 同步；新增 `#### Scenario: Journal 存在而 stable lock 不存在則 fail closed`；tasks 1.2 加入「未建立新 lock inode（比對 device/inode）」的斷言，2.2 加入該守衛順序。

**修 V3（descriptor 雙分支處置）** — D2 第 4 步與 IC2 明訂兩個回傳分支都必須關閉 lock descriptor，並說明不關閉會導致同一 process 對同一 lock 檔開第二個 fd 而無限期阻塞；新增不變量「同一 process 在任一時刻至多持有一個 stable lock descriptor」；spec 同步；tasks 2.2 加入該不變量與實作指示。

**修 G3／V4（測試枚舉事實錯誤）** — tasks 2.3 與 IC5 改為「六個既有測試、四條注入路徑」並逐一列出：(a) 兩個經 `install` helper 既有的 `TEST_` 前綴轉譯層；(b) 兩個經 `os.environ` 加 `install_from` 繼承；(c) 兩個自建 `environment` 交給 `Popen`。特別標註 (a) 這一組容易被漏掉及其靜默失效後果，並要求 `TEST_` 轉譯清單一併涵蓋新開關。

**修 G6（design 與 tasks 未同步收斂）** — design IC3 末條改為「SHALL NOT 在實作、測試或使用者文件中作為可生效的 environment variable name 被讀取或設定；本 Implementation Contract、delta spec 與 change artifacts 對該名稱的敘述性引用不在此限」；tasks 2.3 的驗收句改為同一範圍並明寫「archive 後 master spec 亦會保有該敘述，因此驗收不得以全域字串搜尋為準」。

**修 V5（Non-Goals 措辭未傳播）** — proposal `## Non-Goals` 與 design `## Context` 兩處改為與 design `## Goals / Non-Goals` 一致的措辭，proposal 並補上 recovery 釋放-重入不屬 lock 機制變更的說明。

**修 V6（pre／post-lock 標示錯誤）** — D3 第 3 點改為「第五個重新進入來源……位於主流程取鎖之前，結構上屬 pre-lock，因此它本身不需要 at-most-once 免除」，並改述需要免除的是兩個既有 post-lock 來源與 batch 迴圈；`## Risks / Trade-offs` 的對應項同步改為「第五個重新進入來源，位於主流程取鎖之前」；IC3 的「`acquire_lock` 之前」改為「任何 `acquire_lock` 呼叫之前」以消除兩個取鎖點造成的歧義。

**修 V7（`--force` 變體缺 scenario 與 IC5）** — spec 的 `#### Scenario: 空字串 mode 參數的 dry-run 診斷` 更名為 `#### Scenario: 空字串 mode 參數與相容性 flag 併用的診斷`，WHEN 併列 `--dry-run` 與 `--force`；IC5 的 IC1 bullet 補上 `--force` 變體；tasks 1.1 同步更名並註明兩者為同一 scenario 的兩個 flag 變體。

**修正後的機械自檢與驗證** — 重跑 pre-round mechanical self-check：4 份 artifact 的 comment/annotation 平衡皆為 0/0；兩個 MODIFIED requirement 標題與 master spec 逐 byte 相符；新增 scenario 由 16 增至 18，全數在 tasks.md 有 backing task（雙向無缺漏）；proposal `## Impact` 中含 `/` 的三個 code span 皆在 tasks.md 出現；殘留措辭掃描（`測試、規格或文件`、`lock 協定`、`至多執行一次`、`沒有一個經過`、`四個測試`、`第三個 post-lock`、舊 scenario 名）全數為 0；無 lowercase `may`／`should`。本輪自檢再次捕捉到由本輪 fix 自己引入的兩個 ghost bold name（`**六個**`、`**四條**`）——這是同一形狀第三次出現（r3 的 F4、r4、本輪），已移除，現為 0；另捕捉到 `## Risks / Trade-offs` 中一處未隨 V6 一併更新的「第三個 post-lock 重新進入來源」，已同步。重跑 `cash validate` 通過，`cash analyze` 四個維度皆為 0 finding。

**Signal-derived checks** — `openspec/signals/` 下全部 open signal 仍無 `check` frontmatter 欄位，採 best-effort 判斷。本輪最相關者仍是 `review-fix-propagation-incomplete`：G3、G6、V5、V7 四項都是「fix action 宣告的涵蓋範圍大於實際套用範圍」。`multi-operation-phase-order-undefined` 對應 V1、V2（新前置階段與既有 `newer` early return、launcher-without-lock 守衛之間的順序未定義）。`loop-edge-state-undefined` 對應 V3（回傳偽的分支狀態未定義）。

## Decision

next_round

post-filter cumulative blocking set 含 1 個 Critical（V1）與 3 個 Warning（G3／V4、G6、V5），未滿足 pass 條件。G5 已以 verified resolution 離開集合。四個 blocking 成員與四個非阻斷項皆已完成 fix 並記錄於 `## Fix Actions`。下一輪為本次執行的第六輪，是 6 輪上限的最後一輪，依位置推導為 `micro` 輪，由單一 Reviewer V 對 V1、G3／V4、G6、V5 逐一給出 resolved/unresolved 判定，並檢查本輪 fix 是否再引入新缺陷。若第六輪未 pass，依規則記錄 `decision: aborted` 並執行 Abort triage。
