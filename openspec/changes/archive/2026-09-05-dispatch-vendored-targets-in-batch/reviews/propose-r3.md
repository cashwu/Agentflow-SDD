# Cash Propose Review — Round 3

## Reviewer Findings

### Warning

- severity: Warning / confidence: 100 / layer: design / disposition: fix-introduced / introduced_by: Round 2 Fix Action「修改 `specs/cash-cli/spec.md`：probe 第 (3) 支加上『且為 regular file』……」 / location: `specs/cash-skill-workflows/spec.md` `版本感知的 cash skill 批次安裝` 首段與其後的 SHALL 分派句；次要：`proposal.md` `## Proposed Solution` 第 1 點
  - summary: Round 2 把分派鍵從「manifest 存在」收窄為「存在且為 regular file」，但只傳播到 design、`specs/cash-cli/spec.md`、`tasks.md` 與 proposal 的補述句，未傳播到本 requirement。本文仍以 presence 二分，而 FIFO／directory manifest 是 manifest-present 卻依 cash-cli delta 的 MUST 走 receipt 路徑，兩份 delta 對同一 record 給出相反的路徑歸屬且無例外句。
  - recommendation: 把首段與 SHALL 句的鍵改為「manifest 缺失或存在但非 regular shape → receipt-based；存在且為 regular file → repo-vendored」，並在首段明示非 regular shape 是回落例外；proposal 第 1 點同步加上 regular 條件。
  - reviewer source: Reviewer V F1

- severity: Warning / confidence: 100 / layer: design / disposition: fix-introduced / introduced_by: Round 2 Fix Action「修改 `tasks.md`：……2.4 改名為 `test_batch_unsafe_manifest_shape_fails_closed_without_blocking` 並改為三種 shape 都在 receipt 路徑 fail closed、red 改為 FIFO 觸發 subprocess timeout」 / location: `tasks.md` 2.4 的 `red` 欄
  - summary: 該 red 描述的是 Round 1 那版被推翻的設計，不是 pre-change 基線。實作前 `--all` 每個 record 一律走 `install_target`，三種 shape 都在 `path_is_present` 後即被既有拒絕擋下，零寫入且不阻塞，success 的四項斷言在實作前全部成立，因此該 task 沒有可失敗的 red。
  - recommendation: 改用一個在實作前後確有可觀察差異的載體，或明確改為 pure-refactor 分類的 regression pin。
  - reviewer source: Reviewer V F2

- severity: Warning / confidence: 100 / layer: design / disposition: fix-introduced / introduced_by: Round 2 Fix Action「……2.5 情境改為 `.cash-skills` 為 regular file 的 `managed parent is not a directory`，red 改為例外逸出 per-record try」 / location: `tasks.md` 2.5 的 `red` 欄
  - summary: 同上。實作前該 record 已由 `install_target` 內同一個 `ensure_contained` 拋出被迴圈 `except InstallerError` 捕捉的例外並計為 `failed`，summary 照常輸出；且 red 敘述的因果在實作後亦不成立，因為 probe 若拋 `InstallerError` 也會被同一子句捕捉而非逸出。
  - recommendation: 改為 `N/A` 並依 pure-refactor 分類敘明它釘住的是行為不變。
  - reviewer source: Reviewer V F3

### Suggestion

- severity: Suggestion / confidence: 50 / layer: design / disposition: new / location: `design.md` Goals 第 5 條與 D3 末段 —— hard-linked manifest 的 `S_ISREG` 為真，會通過第 3 支進入 vendored 路徑並由 `read_regular` 的 `allow_hardlink=False` fail closed，因此「任何 unsafe shape 都落入 receipt 路徑」與「unsafe shape 的輸出行不帶後綴」兩句與實際不符；task 2.4 也只涵蓋三種 shape，比既有測試的四種少一種。（Reviewer V F4）
- severity: Suggestion / confidence: 50 / layer: design / disposition: fix-introduced / introduced_by: Round 2 Fix Action「……批次不中止條文改為只對 probe 產生的 `InstallerError` 作保證」 / location: `specs/cash-cli/spec.md` batch 分派段落與 probe fallback scenario —— 同段已規定 probe 不得拋出任何例外，因此「probe 產生的 `InstallerError`」是空集合，該 MUST 恆為 vacuously true。（Reviewer V F5）
- severity: Suggestion / confidence: 50 / layer: design / disposition: fix-introduced / introduced_by: Round 2 Fix Action「……2.2 改為新增 batch-only 參數並以 in-process 斷言」 / location: `tasks.md` 2.2 的 `success` 欄 —— 未指定診斷字串，斷言可被 `validate_target_prerequisites` 或 `require_vendored_paths_committable` 的前置 preflight 失敗以錯誤理由滿足。（Reviewer V F6）
- severity: Suggestion / confidence: 50 / layer: text / disposition: fix-introduced / introduced_by: Round 2 Fix Action「修改 `design.md`：……D3 整段重寫……」 / location: `design.md` D3 末句 —— 交叉引用指向 D10，但實際列出三個後綴載體的是 Implementation Contract 10 與 task 2.6。（Reviewer V F7）
- severity: Suggestion / confidence: 50 / layer: design / disposition: fix-introduced / introduced_by: Round 2 Fix Action「……4.1 補上 `CASH-INIT-RECEIPT.md` 的 mode 對照表兩列、verification 補上針對該檔的零命中斷言、success 的計數改為……」 / location: `tasks.md` 4.1 的 `success` 欄 —— 「涵蓋七處」是 task-completion 陳述而非 verification 可判定的結果，且 `CASH-INIT-RECEIPT.md:221` 與 `CASH-SKILLS.md` 三處沒有任何斷言涵蓋。（Reviewer V F8）

## Rating

- post-filter 累積 blocking set Critical 數：1
- post-filter 累積 blocking set Warning 數：2
- 非 blocking triaged finding 數：0
- critical_gap: true
- round_type: micro
- rationale: Reviewer V 對七個成員逐一給出判定，其中 M1、M2、M4、M5、M6、M7 六個為 resolved 並附具體證據（含逐 shape 的分派表、`install_target` 從進入到 manifest 拒絕不開檔的完整路徑追蹤、`newer` 與 preflight 兩個後綴載體的可達性驗證、`test_installer_runtime.py` 既有 in-process import 機制的確認），依 verified-resolution 規則移出集合。M3 維持 unresolved：Round 2 指名的 dry-run scenario 殘留雖已修，但同一 requirement 的本文仍以 presence 為分派鍵，與 Round 2 在 cash-cli delta 的 regular-shape 收窄正面矛盾，屬同一缺陷機制的未竟部分。另有兩個 `fix-introduced` Warning（F2、F3）由 Round 2 的 task red 欄改寫引入。集合內仍有 blocking Critical，本輪不可能 pass。

## Fix Actions

- 驗證解決移除追蹤（六筆）：M1 由 Round 2「D2 第 3 支加上 regular shape 條件、D3 整段重寫」解決，Reviewer V 以逐 shape 分派表與 `install_target` 路徑追蹤確認；M2 由 Round 2「D7 保證收窄、Non-Goals 補既有缺陷」解決；M4 由 Round 2「2.6 追加 `newer` 與 preflight 兩個載體」解決，Reviewer V 確認兩個載體在 `install_vendored_target` 的實際控制流上可達；M5 由 Round 2「D13 與 4.1 補上 `CASH-INIT-RECEIPT.md` 三處、計數統一」解決；M6 由 Round 2「D5 明確承認 batch-only 參數、Contract 4／9 與兩份 Non-Goals 同步」解決；M7 由 Round 2「2.2 改用 in-process 呼叫」解決，Reviewer V 確認該檔已有四處相同的 `sys.path.insert` + `from cash_cli.installer import` 用法。六筆的驗證 reviewer 均為本輪的 Reviewer V。
- 修改 `specs/cash-skill-workflows/spec.md`：首段的適用範圍改為「manifest 缺失、或該檔存在但非 regular shape 的 registry record」並明寫非 regular shape 是回落到本 requirement 的例外；SHALL 分派句的鍵同步改為 regular-shape 二分；managed decision 句補上「含非 regular shape manifest 的 record，該類 record 由既有拒絕 fail closed 而不進入發佈」；新增的分派 scenario 其 GIVEN 與 THEN 由「manifest-present」改為「具有 regular portable manifest」。（解決 Critical 1）
- 修改 `proposal.md`：`## Proposed Solution` 第 1 點加上 regular file 條件，第 2 點明列三類會走 receipt 路徑的 record。（解決 Critical 1 的傳播部分）
- 修改 `tasks.md` 2.4：改為涵蓋四種 shape，symlink／FIFO／directory 在 receipt 路徑 fail closed 且不帶後綴，hard-linked regular manifest 通過第 3 支進入 vendored 路徑並由 `read_regular` 的 single-link 檢查以 `unsafe regular file identity` fail closed 且帶後綴；red 因此取得真實載體——實作前 hard link 情境仍由 receipt 路徑以 `use --vendor` 拒絕且輸出行不含 `(vendored)`；regression 改為既有的 `test_manifest_present_unsafe_shapes_fail_before_open_without_receipt_fallback`（已確認該測試存在且涵蓋同一組四種 shape）。（解決 Warning 1，同時解決 Suggestion 1）
- 修改 `tasks.md` 2.5：red 改為 `N/A — 依 pure-refactor 分類`，並敘明該 record 在實作前已由同一個 `ensure_contained` 拋出被迴圈捕捉的 `InstallerError` 而計為 `failed`，本設計刻意不為此情境引入新的可觀察差異。（解決 Warning 2）
- 修改 `design.md`：Goals 第 5 條與 D3 改為以「非 regular shape」表述，並新增一段說明 hard-linked manifest 是唯一仍進入 vendored 路徑的 unsafe shape、由 `allow_hardlink=False` fail closed 且因此是 `failed` 帶後綴的天然載體；D3 末句的交叉引用由 D10 改為 Implementation Contract 10；Contract 10 的 `failed` 載體由 Git-committable preflight 改為 hard-linked manifest。（解決 Suggestion 1、Suggestion 4）
- 修改 `specs/cash-cli/spec.md`：批次不中止條文改為「probe 落入 catch-all 之後，由被分派到的 publication 路徑重新產生的 `InstallerError` MUST 使該 record 計為 `failed`」，probe fallback scenario 的對應 AND 同步改寫，消除原條文的 vacuous MUST。（解決 Suggestion 2）
- 修改 `tasks.md` 2.2：success 補上「該 `InstallerError` 的訊息為新加的 manifest 重新確認診斷，因而與前置 preflight 失敗可區分」。（解決 Suggestion 3）
- 修改 `tasks.md` 2.6：移除 Git-committable preflight 的 `failed` 載體，該 label 的驗證改由 2.4 的 hard link 情境承擔，避免兩個 task 重複宣稱同一載體。
- 修改 `tasks.md` 4.1：verification 的零命中 pattern 擴為四個並同時涵蓋兩份文件；success 改為只陳述 verification 可判定的結果（`CASH-SKILLS.md` 出現 ` (vendored)` 且四個過時 pattern 零命中），原本的「涵蓋七處」計數移入 delivery 敘述。（解決 Suggestion 5）
- 修正後已重跑機械自我檢查：annotation lint（兩份 delta 皆為 0）、requirement title 逐 byte identity（3 個標題全部命中 master）、identifier cross-grep（`regular file`、`hard-link`、`unsafe regular file identity`、`(vendored)`、`batch-only` 的分佈一致，且四個被取代的舊措辭「Git-committable preflight 失敗的 `failed`」「D10 的 `conflict`」「manifest-present record 走 repo-vendored」「涵蓋 `CASH-SKILLS.md` 四處與」全部零殘留）、計數一致性（D1–D13 連號、Implementation Contract 1–12 連號、tasks 共 11 筆），並確認 `test_manifest_present_unsafe_shapes_fail_before_open_without_receipt_fallback` 在 `test_installer_runtime.py` 中存在。`openspec/signals/` 中沒有任何 `open` signal 帶有 `check` 欄位，改用既有 best-effort 判斷，本輪額外對照 `cross-artifact-definition-drift`（regular-shape 收窄未跨 delta 傳播）與 `acceptance-path-infeasible-in-test-harness`／`condition-rewrite-vacuously-true-in-excluded-case`（red 欄與 vacuous MUST）三個 issue class。
- 修正涉及 proposal、design、tasks 與 spec artifacts，已重新執行 `cash validate "dispatch-vendored-targets-in-batch"`，結果為 `Validation passed.`。
- 本輪 Fix Actions 修改的檔案全部位於 `openspec/changes/` 之下，依規則濾除後候選路徑為空，因此不呼叫 `touched ensure`／`touched record`，也不產生警告。

## Decision

next_round
