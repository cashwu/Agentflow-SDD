# Cash Apply Review — Round 1

## Reviewer Findings

### Warning

- severity: Warning / confidence: 100 / layer: design / location: `scripts/cash-skills/tests/test_installer_runtime.py:88-109`（`run_installer`）與新增的 `test_batch_unsafe_manifest_shape_fails_closed_without_blocking`；`tasks.md` 2.4 的 success 欄
  - summary: Implementation Contract 10 與 delta spec 的「非 regular 的 manifest shape 在 receipt 路徑 fail closed」scenario 都要求「不阻塞」被釘住，`tasks.md` 2.4 的 success marker 更逐字宣稱「該測試在其自身的 subprocess timeout 內完成」。但該測試唯一使用的 `run_installer` helper 的 `subprocess.run(...)` 不帶 `timeout`（同檔的 `install`／`vendor`／`run_target_cash` 三個 helper 都有）。因此「不阻塞」完全沒有 bounded 斷言：若 D3 的分派邊界退化、FIFO manifest 落到 vendored 路徑而在 `read_regular` 永久阻塞，該測試會無限 hang 而非失敗。宣稱存在的驗收機制實際不存在。
  - recommendation: 為 `run_installer` 加上 `timeout` 參數並轉傳給 `subprocess.run`，在該測試傳入有限上限，使阻塞回歸以 `TimeoutExpired` 失敗。
  - introduced_by: 本次 diff 新增的 `test_batch_unsafe_manifest_shape_fails_closed_without_blocking` 選用了不帶 timeout 的 `self.run_installer(["--all"], home=Path(home.name))`；該測試與該呼叫皆為本次 diff 新增。
  - reviewer source: Reviewer A finding 1、Reviewer B F1（兩位獨立提出，且 Reviewer B 另以 SIGALRM 實測確認 `snapshots` 對 FIFO manifest 會在 `os.open` 阻塞）

### Suggestion

- severity: Suggestion / confidence: 50 / layer: design / location: `test_installer_runtime.py` 的 dry-run 與 force／conflict 測試 —— delta spec 明文「`--dry-run` 與 `conflict`、`newer` 的早期返回……MUST NOT 刪除該檔」，但三個相關測試的 vendored target 由 `assert_vendored` 產生、本來就沒有 receipt，`workspace_snapshot` 相等對該子句是空載斷言。（Reviewer A finding 2）
- severity: Suggestion / confidence: 50 / layer: design / location: `test_batch_vendor_dispatch_requires_manifest_at_classification` —— spec scenario「分派後 manifest 消失則 fail closed」的 THEN 含「並計為 `failed`」，而該測試以 in-process 呼叫只斷言 `InstallerError` 與零寫入，計數子句只由迴圈的通用行為間接保證。（Reviewer A finding 3）
- severity: Suggestion / confidence: 50 / layer: text / location: `tasks.md` task 1.1 的理由段落 —— 仍留著依舊時序寫的「從本 task 完成到 4.1 的 `--self` 之間」，在增量發佈之下該敘述在 task 邊界上不再成立，屬第一筆 deviation 未清乾淨的殘留。（Reviewer A finding 4）
- severity: Suggestion / confidence: 50 / layer: design / location: `.cash-skills/lib/cash_cli/installer.py` 的 `registry_publication_mode` —— Implementation Contract 2 與 D1 逐字要求「其整個函式主體包在單一 try 內」，而 catch-all 的 `return "receipt"` 落在 `try/except` 之外。功能等價但與契約字面不符。（Reviewer A finding 5）
- severity: Suggestion / confidence: 50 / layer: design / location: 同上函式的 docstring —— 函式名與 docstring 宣稱回傳「target 的發佈模式」，但 canonical source 持有 regular manifest 卻回 `"receipt"`；實際語意是分派決策。docstring 完全沒提第 1 支。（Reviewer B F2）
- severity: Suggestion / confidence: 50 / layer: text / location: `CASH-SKILLS.md` batch 段落 —— 新增敘述把分派寫成單一條件，未反映 canonical source 一律走 receipt 路徑的第 1 支。（Reviewer B F3）

## Rating

- post-filter 累積 blocking set Critical 數：0
- post-filter 累積 blocking set Warning 數：1
- 非 blocking triaged finding 數：0
- critical_gap: false
- round_type: full
- rationale: 本輪是本次 run 的第一輪且未 seeded，因此全部通過信心過濾的 Critical 與 Warning 皆為 blocking。兩位 reviewer 獨立在同一機制上得到一致結論（`run_installer` 缺 `timeout` 使「不阻塞」驗收空載），主 agent 已讀 helper 定義複驗——同檔的 `install()` 具備 `timeout` 參數且在既有測試中正是用於釘住不阻塞，`run_installer` 獨缺。其餘六筆 confidence 均為 50，依 `[50, 80)` 規則降為 Suggestion，不計入 blocking set。存在 blocking Warning，本輪不能 pass。

## Fix Actions

- 修改 `scripts/cash-skills/tests/test_installer_runtime.py`：為 `run_installer` 加上 `timeout: float | None = None` 並轉傳給 `subprocess.run`，與同檔 `install()`／`vendor()` 的既有慣例一致；`test_batch_unsafe_manifest_shape_fails_closed_without_blocking` 的 batch 呼叫改為 `timeout=60` 並附註理由。以 mutation check 驗證守衛確實生效：暫時移除 probe 的 `ensure_regular_shape(target, PORTABLE_MANIFEST_PATH)` 後重跑，FIFO 子情境以 `subprocess.TimeoutExpired: ... timed out after 60 seconds` 失敗而非掛死，隨後還原並重新發佈 manifest。（解決 Warning 1）
- 修改 `scripts/cash-skills/tests/test_installer_runtime.py`：在 dry-run 測試與 force 測試的 conflict 階段各先寫入一份殘留 `.cash-skills/receipt.tsv`，並分別斷言早期返回後該檔仍存在；force 提交階段另補斷言該 residue 已被清除，使「早期返回保全 residue」與「real run 清除 residue」形成對稱的一對釘子。（解決 Suggestion 1）
- 修改 `.cash-skills/lib/cash_cli/installer.py`：把 `registry_publication_mode` 的 catch-all `return "receipt"` 移入 `try` 尾端，使整個函式主體確實落在單一 try 內；docstring 改寫為「這是 dispatch 決策而非模式判定」並明寫 canonical source 一律回 `"receipt"` 以保留既有 non-source 診斷。（解決 Suggestion 4、Suggestion 5）
- 修改 `CASH-SKILLS.md`：batch 段落補上 canonical source 例外，並說明該情形只可能來自手動編輯 registry，因為 `--register` 本來就拒絕 source。（解決 Suggestion 6）
- Suggestion 2 與 Suggestion 3 改以 `implementation-notes.md` 承載而非改寫 `tasks.md`：初次依建議改寫 task 1.1 與 task 2.2 的描述後，`cash touched ensure` 以 `error[touched_invalid]: Touched task description is absent from tasks.md` 失敗——touched state 逐字保存每個已完成 task 的 `task_desc`，改寫它會毀掉「哪些檔案屬於哪個 task」的稽核軌跡並使 `cash-commit` 失去來源允許清單。兩處改寫已還原為原文，更正內容改記為 `implementation-notes.md` 的第三筆 `deviation`（權威敘述分別在 design D12 與 2.5 的 batch 測試）。兩筆皆為 confidence 50 的非 blocking Suggestion，此處置不影響交付物、可觀察行為或驗收標準。
- Managed bundle publication：本輪 fix 修改了受管 runtime `installer.py`，已在任何後續 Cash command 之前執行 `./install-cash-skills.fish --self`（回報 `Result: bootstrap`）；mutation check 還原後再次執行並回報 `Result: current`。
- 修正後重跑驗證：7 個新增 batch 測試全數通過（50.8s），完整 `test_installer_runtime.py` 套件 142 tests `OK`（242.4s）。
- 修正後已重跑機械自我檢查：annotation lint（兩份 delta 的 `<!--`／`-->` 皆為 0）、requirement title 逐 byte identity、tasks 全 11 筆 `[x]`、過時措辭「到 4.1 的 `--self` 之間」零殘留。157 個 `open` signal 皆無 `check` 欄位，改用既有 best-effort 判斷，本輪對照 `assertion-weaker-than-normative-statement`（宣稱的 timeout 驗收實際不存在）與 `guard-fixture-content-unanchored`（空載的 residue 斷言）兩個 issue class。
- 本輪 Fix Actions 修改了 `openspec/changes/` 以外的三個檔案，已執行 `touched ensure` 與 `touched record` 記錄 `scripts/cash-skills/tests/test_installer_runtime.py`、`.cash-skills/lib/cash_cli/installer.py`、`.cash-skills/manifest.tsv` 與 `CASH-SKILLS.md`。

## Decision

next_round
