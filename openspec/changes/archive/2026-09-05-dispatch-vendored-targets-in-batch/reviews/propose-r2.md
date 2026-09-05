# Cash Propose Review — Round 2

## Reviewer Findings

### Critical

- severity: Critical / confidence: 100 / layer: design / disposition: unresolved-prior / location: `design.md` D3 第 2 支、`specs/cash-cli/spec.md` unsafe manifest scenario、`tasks.md` 2.4
  - summary: FIFO manifest 在 vendored 路徑不會被 `ensure_regular_shape` fail closed，而是在更早的 pre-lock `snapshots(target, target_watch_paths)` 內以 `read_regular` 開檔而永久阻塞，因此 Round 1 修正後的 D3 第 2 支仍不成立，且 task 2.4 的 FIFO 契約測試會讓整個測試套件卡死。
  - recommendation: 把 probe 第 3 支收窄為「存在且為 regular file」，非 regular shape 一律落入 catch-all 的 receipt 路徑。
  - reviewer source: Reviewer V F1（主 agent 已獨立複驗：`vendored_planned_paths` 明列 `PORTABLE_MANIFEST_PATH`，`snapshots` 在 `ensure_regular_shape` 之前，`read_regular` 以 `os.O_RDONLY | os.O_NOFOLLOW` 開檔而不帶 `O_NONBLOCK`，且 `ensure_regular_shape` 的 docstring 自身即記載 FIFO 開檔會阻塞）

- severity: Critical / confidence: 100 / layer: design / disposition: unresolved-prior / location: `design.md` D7、`specs/cash-cli/spec.md` probe fallback scenario、`tasks.md` 2.5
  - summary: 把 probe 放進 per-record `try` 不足以讓原生 `PermissionError` 計為 `failed`：迴圈的例外子句是 `except InstallerError`，而 probe 吞掉例外後 `install_target` 會沿同一路徑再次拋出同一個未包裝的原生例外並逸出，因此 D7 與對應 scenario、task 2.5 的宣稱為假。
  - recommendation: 把 D7 的保證收窄為「probe 自身不成為新的中止來源」，並把 task 2.5 的情境改為會產生 `InstallerError` 的子情境。
  - reviewer source: Reviewer V F2（主 agent 已獨立複驗 `ensure_contained` 的 `os.lstat` 只捕捉 `FileNotFoundError`，且 batch 迴圈與 `main()` 都只 catch `InstallerError`）

- severity: Critical（成員層級；本輪 finding 以 Warning 回報）/ confidence: 100 / layer: design / disposition: unresolved-prior / location: `specs/cash-skill-workflows/spec.md` `版本感知的 cash skill 批次安裝` 的 Scenario「批次 dry run 使用完整驗證且不寫入」
  - summary: 該 scenario 未隨其他四條一起收窄，仍主張 `--all --dry-run` 下「每個 target」接受 receipt/version 與 legacy identity 驗證且回報 receipt 或 legacy removal 的 `would-update`，對 vendored record 為假，與同 delta 新增的 dry-run scenario 形成未宣告優先權的重疊分類。
  - recommendation: 把該 scenario 的 GIVEN 收窄為 manifest 缺失的 record，與其他四條一致。
  - reviewer source: Reviewer V F5

### Warning

- severity: Warning / confidence: 100 / layer: design / disposition: fix-introduced / introduced_by: Round 1 Fix Action「修改 `design.md` … 新增 D5 要求 batch 分派的 vendored record 在分類前重新確認 manifest」 / location: `design.md` D5、Implementation Contract 4 與 9、Goals / Non-Goals
  - summary: D5 要求 vendored 路徑新增 fail-closed 行為，與 Contract 9「`install_vendored_target` 既有行為不變」及 Non-Goals「不改變兩個函式各自的內部契約」直接衝突；若改在 `run()` 迴圈重新確認以規避衝突，則 D5 宣稱的保證只是縮小 TOCTOU 窗口而非消除。
  - recommendation: 明確承認 `install_vendored_target` 取得一個 batch-only 參數，並相應修正 Contract 9 與 Non-Goals。
  - reviewer source: Reviewer V F3

- severity: Warning / confidence: 100 / layer: design / disposition: fix-introduced / introduced_by: Round 1 Fix Action「修改 `tasks.md`：新增 task 2.2（manifest 重新確認）」 / location: `tasks.md` 2.2
  - summary: task 2.2 需要「manifest 在 probe 之後、分類之前消失」的狀態，但測試全以 subprocess 執行 installer，唯一的 hold hook 位在 vendored 分類之後，無法製造該窗口；tasks 與 design 都未宣告新增 hook，`Installer fault-injection hooks 治理` 也不在本次 delta 中。
  - recommendation: 改以 in-process import 直接對帶 batch-only 參數的入口斷言，避免動到 fault-injection hook 治理。
  - reviewer source: Reviewer V F4

- severity: Warning / confidence: 100 / layer: design / disposition: unresolved-prior / location: `proposal.md` `## Impact`、`design.md` D13、`tasks.md` 4.1
  - summary: 文件同步涵蓋面不完整且計數自相矛盾：`CASH-INIT-RECEIPT.md` mode 對照表的 `--all` 與 `--register` 兩列同樣變成事實錯誤而未被涵蓋；task 4.1 的 verification 只針對 `CASH-SKILLS.md`，無法驗證另一份文件；D13 與 4.1 的 success 寫「四處敘述」而 4.1 自身已列出五處。
  - recommendation: 把兩列補進 D13 與 task 4.1、統一計數、並為 `CASH-INIT-RECEIPT.md` 補上斷言。
  - reviewer source: Reviewer V F6（主 agent 已逐行複驗 `CASH-INIT-RECEIPT.md:217`、`:218`、`:221` 三處）

- severity: Warning / confidence: 100 / layer: design / disposition: unresolved-prior / location: `design.md` Implementation Contract 6 與 10、`tasks.md` 2.4／2.6
  - summary: Contract 6 明列 `newer` 行同樣帶 ` (vendored)` 後綴，但測試清單與所有 task 的 success 只涵蓋 `failed` 與 `conflict`，`newer` 仍無斷言；且在 Critical 1 的修正之後，unsafe shape 不再是 `failed` 帶後綴的載體，需另尋載體。
  - recommendation: 在 2.6 追加 `newer` 與 Git-committable preflight 被阻擋的 `failed` 兩個載體。
  - reviewer source: Reviewer V F8（原為 Suggestion 50；因 Critical 1 的修正移除了原本的 `failed` 載體，主 agent 依「後綴與最終 label 無關」這條 MUST 的驗證缺口將其提升為 Warning 並記錄提升理由）

### Suggestion

- severity: Suggestion / confidence: 50 / layer: design / disposition: fix-introduced / introduced_by: Round 1 Fix Action「新增 D3 明訂 unsafe manifest shape 在兩支上都 fail closed 且零寫入的不變式」 / location: `design.md` D3 directory 情境 —— directory manifest 實際的 fail-closed 來源是 pre-lock snapshot 內的 `read_regular` 而非 `ensure_regular_shape`，兩者恰好產生同一句診斷，可觀察結果不受影響但機制歸因不正確。（Reviewer V F7；已隨 Critical 1 的重寫一併消除）

## Rating

- post-filter 累積 blocking set Critical 數：3
- post-filter 累積 blocking set Warning 數：4
- 非 blocking triaged finding 數：0
- critical_gap: true
- round_type: micro
- rationale: Round 1 的五個成員中，M3（缺漏 MODIFY）、M4（後綴驗證）、M5（文件 Impact）在主體上已由 Round 1 的修正解決，但 Reviewer V 分別以 F5、F8、F6 在同一 artifact、同一缺陷機制上再度回報殘留缺口，依「任一 unresolved 判定即保留成員」的規則三者留在集合內；M1、M2 明確 unresolved，且 Reviewer V 提供了 Round 1 未掌握的機制事實（pre-lock snapshot 早於 shape 驗證、原生 `PermissionError` 不被 `except InstallerError` 捕捉），主 agent 已回程式碼獨立複驗兩者皆為 CONFIRMED。另有兩個 `fix-introduced` Warning（F3、F4）由 Round 1 的 D5 與 task 2.2 引入。存在 blocking Critical，本輪不可能 pass。

## Fix Actions

- 修改 `design.md`：Context 補上 pre-lock `snapshots` 早於 `ensure_regular_shape`、`read_regular` 不帶 `O_NONBLOCK` 以及 FIFO 會阻塞的實測事實；D2 第 3 支改為「存在且 `ensure_regular_shape` 未拋出」；D3 整段重寫為「只有 regular shape 的 manifest 會被分派到 vendored 路徑，其餘一律 fail closed 於 receipt 路徑」，並列出 symlink 與 non-regular 兩種 shape 各自的既有診斷與「receipt 路徑只 `lstat` 不開檔因此不阻塞」的理由；D5 改為明確承認 `install_vendored_target` 取得預設關閉的 batch-only 參數；D7 的保證收窄為「probe 自身不成為新的中止來源」並明寫原生 `PermissionError` 逸出是既有行為、本變更不改變也不擴大；D13 涵蓋面由四處改為 `CASH-SKILLS.md` 四處與 `CASH-INIT-RECEIPT.md` 三處；Goals 的 unsafe shape 條目改為「都落入 receipt 路徑」；Non-Goals 補上 batch-only 參數例外與兩項不在範圍內的既有缺陷；Implementation Contract 2、4、9、10、11 同步改寫；Risks 補上 unsafe shape 診斷對 FIFO 具誤導性、以及明示 `--vendor` 對 FIFO 會阻塞的既有缺陷屬獨立 change 兩條。（解決 Critical 1、Critical 2、Warning 1、Warning 3、Warning 4，以及 Suggestion 1）
- 修改 `specs/cash-cli/spec.md`：probe 第 (3) 支加上「且為 regular file」；unsafe shape 條文改寫為「非 regular shape MUST 落入第 (4) 支的 receipt 路徑，因為 repo-vendored publication 會在其 shape 驗證之前先開檔讀取 manifest，對 FIFO 會阻塞而永不 fail closed；receipt 路徑只以 `lstat` 判定，因此 MUST NOT 阻塞」；批次不中止條文改為只對 probe 產生的 `InstallerError` 作保證；scenario「Unsafe manifest shape 在兩支上都 fail closed」改寫為「一律在 receipt 路徑 fail closed」並補上「都不阻塞」；新增 scenario「分派後 manifest 消失則 fail closed」；force scenario 補上 `newer: <path> (vendored)`。（解決 Critical 1、Critical 2、Warning 1、Warning 4）
- 修改 `specs/cash-skill-workflows/spec.md`：「批次 dry run 使用完整驗證且不寫入」scenario 補上 `GIVEN registry中manifest缺失的record` 並把 THEN 改為「每個這樣的target」，與其餘四條收窄一致。（解決 Critical 3）
- 修改 `tasks.md`：2.1 補上第 3 支的 regular shape 條件；2.2 改為新增 batch-only 參數並以 in-process `from cash_cli.installer import install_vendored_target` 斷言，red 改為 `TypeError`，regression 改為兩個涵蓋不帶參數之明示 `--vendor` 的既有測試；2.4 改名為 `test_batch_unsafe_manifest_shape_fails_closed_without_blocking` 並改為三種 shape 都在 receipt 路徑 fail closed、red 改為 FIFO 觸發 subprocess timeout；2.5 情境改為 `.cash-skills` 為 regular file 的 `managed parent is not a directory`，red 改為例外逸出 per-record try；2.6 的 success 追加 `newer: <path> (vendored)` 與 Git-committable preflight 被阻擋的 `failed: <path> (vendored)` 兩個後綴載體；4.1 補上 `CASH-INIT-RECEIPT.md` 的 mode 對照表兩列、verification 補上針對該檔的零命中斷言、success 的計數改為「`CASH-SKILLS.md` 四處與 `CASH-INIT-RECEIPT.md` 三處」。（解決 Critical 1、Critical 2、Warning 1、Warning 2、Warning 3、Warning 4）
- 修改 `proposal.md`：Proposed Solution 的 unsafe shape 句改為「非 regular shape 一律落入 receipt 分支……也不會落入 vendored publication 開檔讀取 manifest 而對 FIFO 阻塞的路徑」，manifest 重新確認句改為以 batch-only 參數表述；Non-Goals 改為以 mode 為單位陳述並補上 batch-only 參數例外，另補一條明列兩項不在範圍內的既有缺陷。（解決 Critical 1、Warning 1、Warning 3）
- 提升追蹤：Reviewer V F8 原為 Suggestion（confidence 50）。Critical 1 的修正移除了 unsafe shape 這個原本的 `failed` 帶後綴載體，使「後綴與最終 label 無關」這條 MUST 的驗證缺口從一種 label 擴大為兩種，主 agent 據此將其提升為 Warning 並列入 blocking set；原 Suggestion 分類與提升理由如上記錄。
- 修正後已重跑機械自我檢查：annotation lint（兩份 delta 的 `<!--`／`-->` 皆為 0）、requirement title 逐 byte identity（3 個標題全部命中 master spec）、identifier cross-grep（`regular shape`、`batch-only`、`(vendored)`、三個既有診斷字串、兩份文件路徑、三個改名後的測試名稱一致，且無任何舊測試名稱殘留）、計數一致性（D1–D13 連號、Implementation Contract 1–12 連號、tasks 共 11 筆）。`openspec/signals/` 中沒有任何 `open` signal 帶有 `check` 欄位，改用既有 best-effort 判斷，本輪額外對照了 `malformed-metadata-misclassified-as-absent`（非 regular shape 不得被當成 absent）與 `overlapping-classification-without-precedence`（dry-run scenario 的重疊分類）兩個 issue class。
- 修正涉及 proposal、design、tasks 與 spec artifacts，已重新執行 `cash validate "dispatch-vendored-targets-in-batch"`，結果為 `Validation passed.`。
- 本輪 Fix Actions 修改的檔案全部位於 `openspec/changes/` 之下，依規則濾除後候選路徑為空，因此不呼叫 `touched ensure`／`touched record`，也不產生警告。

## Decision

next_round
