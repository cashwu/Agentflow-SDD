# Cash Apply Review — Round 1

## Reviewer Findings

### Critical

（無）

### Warning

1. **FIFO `.gitignore` 阻塞而非 fail closed**
   - `severity`: Warning
   - `confidence`: 100
   - `layer`: design
   - `location`: `.cash-skills/lib/cash_cli/installer.py:175-188`（`optional_snapshot`）與 `:449`（`installation_inputs` 納入 `GITIGNORE_PATH`）
   - `summary`: `.gitignore` 為 FIFO（非 regular file）時 installer 於 `os.open` 無限阻塞，未依 spec `既有檔案為symlink、非regular file、hard link或無法安全讀取時 MUST在首次target write前以execution error失敗` fail closed。
   - `recommendation`: 在 `installation_inputs` 開頭以 `os.lstat` + `stat.S_ISREG` 對 `GITIGNORE_PATH` 前置判定並 fail closed，不必改動共用的 `read_regular`；並補 `fifo` 形狀（含 `--force`）與 timeout 斷言的 contract test。
   - reviewer source: Reviewer A（實測 fixture `mkfifo .gitignore`，installer 阻塞逾 8 秒未返回）

2. **`git ls-files` 會執行 target repo 設定的 `core.fsmonitor` 程式**
   - `severity`: Warning
   - `confidence`: 90
   - `layer`: design
   - `location`: `.cash-skills/lib/cash_cli/installer.py:699-723`（`report_version_controlled_receipt`）、呼叫點 `:1138`
   - `summary`: 新增的 index 查詢會執行 target repository `.git/config` 指定的 `core.fsmonitor` 程式，使「唯讀 index 查詢」實際引入以安裝者身分執行任意程式的新攻擊面。
   - `recommendation`: 只強化本次新增的 invocation：`["git", "-c", "core.fsmonitor=", "-C", str(target), "ls-files", "--", RECEIPT_PATH]`。
   - `introduced_by`: 本次 diff 新增 `report_version_controlled_receipt` 的 `subprocess.run(["git", "-C", str(target), "ls-files", ...])`，以及 `install_target` 中新增的呼叫點。
   - reviewer source: Reviewer B（主 agent 已於 isolated fixture 獨立複驗：`git config core.fsmonitor ./hook.sh` 後 `git ls-files` 執行 hook，`git -c core.fsmonitor= ls-files` 不執行，既有 `git rev-parse --show-toplevel` 亦不執行）

3. **版控診斷在重新分類重試時重複輸出**
   - `severity`: Warning
   - `confidence`: 95
   - `layer`: design
   - `location`: `.cash-skills/lib/cash_cli/installer.py:1138`（位於自遞迴的 `install_target` 內，遞迴點 `:1219`、`:1245`、`:1286`、`:1302`）
   - `summary`: 診斷置於 `install_target` 函式開頭，該函式在 post-lock 重新分類與 in-flight receipt 路徑會自我遞迴，使已追蹤 receipt 的 target 輸出 N+1 行，違反 design `### Command interfaces and data shapes` 的 `輸出至 stderr，每個 target 一行`；本 change 把 `.gitignore` 這個常被改動的 project-owned 檔案納入 `installation_inputs` 後，此路徑更容易觸發，`--all` 模式下重複次數無上限。
   - `recommendation`: 將診斷移出遞迴主體，或以參數抑制遞迴重入時的重複輸出。
   - `introduced_by`: 本次 diff 將 `report_version_controlled_receipt(target)` 置於遞迴函式體內。
   - reviewer source: Reviewer A + Reviewer B（同一 finding，依 `location + summary` 合併；layer 兩者皆 `design`，取較高 severity 與 confidence）

### Suggestion

4. **CRLF `.gitignore` 的 idempotence 未端到端驗證**
   - `severity`: Suggestion（原 Warning，confidence 75 經 filter 降級）
   - `confidence`: 75
   - `layer`: design
   - `location`: `scripts/cash-skills/tests/test_installer_runtime.py:269-300`、`installer.py:689`
   - `summary`: CRLF 子案例由「不含任何規則」起始且只安裝一次，只證明附加路徑；spec `##### Example: 規則判定` 表中「`.cash-skills/state/` 後接 `\r` → 已滿足」這一列未被真正的 installer 驗證，回歸時會使每次安裝對 CRLF repo 重複附加三行。
   - `recommendation`: 以已含三項規則的 CRLF 種子安裝兩次，斷言 `Result: current` 且 bytes／inode／mtime 不變。
   - `introduced_by`: 本次 diff 新增的 `test_gitignore_append_preserves_line_terminators_and_encoding` 只有單次安裝的 CRLF 案例。
   - reviewer source: Reviewer B

5. **`existing.mode or 0o644` 會把 `0o000` 的既有 `.gitignore` 改寫為 `0644`**
   - `severity`: Suggestion
   - `confidence`: 55
   - `layer`: design
   - `location`: `.cash-skills/lib/cash_cli/installer.py:696`
   - `summary`: `0o000` 為 falsy，會走「檔案不存在」分支而以 `0644` 發布，違反 spec `既有檔案的mode MUST保留` 並放寬 project-owned 檔案的權限。
   - `recommendation`: 改為 `existing.mode if existing.mode is not None else 0o644`。
   - `introduced_by`: 本次 diff 的 `gitignore_plan` return 敘述。
   - reviewer source: Reviewer B

6. **測試在 parent process 設定 production 環境變數**
   - `severity`: Suggestion
   - `confidence`: 60
   - `layer`: design
   - `location`: `scripts/cash-skills/tests/test_installer_runtime.py:369-370`
   - `summary`: `os.environ["CASH_INSTALL_FAIL_AFTER_PATH"]` 汙染整個測試 process 的環境，繞過 `install()` helper 既有的 `TEST_CASH_INSTALL_*` 間接層，對應 open signal `inherited-export-breaks-process-isolation`。
   - `recommendation`: 沿用 `TEST_CASH_INSTALL_*` 前綴由 `install()` helper 轉換。
   - `introduced_by`: 本次 diff 的 `test_publication_failure_rolls_back_the_gitignore_operation`。
   - reviewer source: Reviewer B

7. **`CASH-SKILLS.md` 漏掉 `Result: current` 的前提**
   - `severity`: Suggestion
   - `confidence`: 65
   - `layer`: text
   - `location`: `CASH-SKILLS.md`（新增的 `## Target 版控排除保護` 段落）
   - `summary`: 文件寫「三項規則齊備時該檔案零寫入，target 回報 `Result: current`」，省略 spec 與 design 都帶有的「其餘 managed inventory 無變更」前提。
   - `recommendation`: 補上該前提。
   - reviewer source: Reviewer A + Reviewer B（依 `location + summary` 合併；兩者皆 `text`）

## Rating

- post-filter cumulative blocking set Critical count: 0
- post-filter cumulative blocking set Warning count: 3
- 非阻塞 triaged finding count: 0
- `critical_gap`: false
- `round_type`: full

Rationale：本輪為未 seed 之 run 的第一輪 full round，因此所有通過 confidence filter 的 Critical／Warning 皆為阻塞。confidence filter 套用結果：無 finding 低於 50 被丟棄；finding 4（75）、5（55）、6（60）、7（65）落在 `[50, 80)` 降級為 `Suggestion`；finding 1（100）、2（90）、3（95）維持 Warning。Reviewer B 的每一筆 Critical／Warning 都附有可驗證的 `introduced_by`（finding 2 另經主 agent 於 isolated fixture 獨立複驗），因此無 `introduced_by` 不可驗證的降級。累積阻塞集合含 3 個 Warning、0 個 Critical，故 `critical_gap` 為 false，決議為 `next_round`。

## Fix Actions

1. finding 1（阻塞）— 修正檔案：`.cash-skills/lib/cash_cli/installer.py`、`scripts/cash-skills/tests/test_installer_runtime.py`。新增 `ensure_regular_gitignore()`，於 `installation_inputs` 開頭以 `os.lstat` + `stat.S_ISREG` 對 `.gitignore` 前置判定；涵蓋三個 `installation_inputs` 呼叫點（pre-lock、post-lock、publication 前）。測試在 `test_gitignore_unsafe_shapes_fail_closed_before_any_write` 加入 `fifo` 形狀（plain 與 `--force`），並為 `install()` helper 加上 `timeout` 參數使「不得阻塞」成為斷言的一部分。
2. finding 2（阻塞）— 修正檔案：`.cash-skills/lib/cash_cli/installer.py`、`scripts/cash-skills/tests/test_installer_runtime.py`。`report_version_controlled_receipt` 的 git invocation 改為帶 `-c core.fsmonitor=`；新增 `test_receipt_diagnostic_does_not_run_repository_configured_programs` 驗證 target repo 設定的 hook 不被執行。
3. finding 3（阻塞）— 修正檔案：`.cash-skills/lib/cash_cli/installer.py`、`scripts/cash-skills/tests/test_installer_runtime.py`。`install_target` 增加 keyword `announce_tracking: bool = True`，四個遞迴呼叫點全部傳入 `announce_tracking=False`；新增 `test_receipt_diagnostic_is_one_line_per_target_across_reclassification`，於已追蹤 receipt 的 target 上以 lock-wait 期間改寫 `.gitignore` 觸發重新分類，斷言 stderr 中診斷恰為 1 次。已反向驗證此測試非空洞：暫時停用抑制後該測試回報 `2 != 1`，恢復後通過。
4. finding 4 — 修正檔案：`scripts/cash-skills/tests/test_installer_runtime.py`。`test_complete_gitignore_rules_are_zero_write_and_current` 改為 subTest，新增 `seeded-crlf` 種子（已含三項 CRLF 規則），第一次安裝後斷言 bytes 與種子完全相同，第二次安裝斷言 `Result: current` 且 bytes／inode／mtime 不變。
5. finding 5 — 修正檔案：`.cash-skills/lib/cash_cli/installer.py`。`gitignore_plan` 改為 `mode = 0o644 if existing.mode is None else existing.mode`。
6. finding 6 — 修正檔案：`scripts/cash-skills/tests/test_installer_runtime.py`。改用 `TEST_CASH_INSTALL_FAIL_AFTER_PATH`，並把 `install()` helper 的 `TEST_` 前綴轉換改為涵蓋 `CASH_INSTALL_FAIL_AFTER` 與 `CASH_INSTALL_FAIL_AFTER_PATH` 兩者。
7. finding 7 — 修正檔案：`CASH-SKILLS.md`。補上「其餘 managed inventory 亦無變更時 target 才回報 `Result: current`」。
8. Fix propagation — 對每個修復觸及的概念做全 artifact 與變更檔案 grep：`ensure_regular_gitignore`（定義 1 處、呼叫 1 處）、`announce_tracking`（定義 1 處、判斷 1 處、遞迴 4 處全數同步）、`core.fsmonitor`（實作 1 處、docstring 1 處、測試 1 處）、`TEST_CASH_INSTALL_FAIL_AFTER_PATH`（helper 轉換與測試設定一致），確認無殘留的舊寫法。
9. Implementation Notes — `implementation-notes.md` 的 FIFO `open-question` 條目依 protocol 保留原文，另附加一則 resolution 條目說明「超出範圍」判斷不成立、已於本輪修復，並記載此為實作既有 contract 而非 contract 變更，故不觸發 fix-loop design circuit breaker。
10. 修復後重跑 pre-round mechanical self-check：spec delta comment 開閉平衡（1/1）、delta `### Requirement:` title 與 master `openspec/specs/cash-cli/spec.md` 逐 byte 相符、identifier cross-grep 一致、`openspec/signals/` 無帶 `check` frontmatter 的 open signal（65 個 open signal 全數無 `check`），無新失敗。
11. 修復後重跑驗證：`test_installer_runtime.py` 59 tests OK、`test_bundle_version_history.py` 4 tests OK、`fish scripts/cash-skills/tests/skill-checks.fish` 全綠、`fish scripts/cash-cli/tests/cli-checks.fish` 83 tests OK、`.cash-skills/bin/cash validate --all` 通過。

無 `未修復：裁判面保護` 記錄；本輪修復觸及的檔案皆非 grader 保護路徑，`scripts/cash-skills/tests/skill-checks.fish` 雖列於保護集合但已在 proposal `## Impact` 的 affected-code 中具名，且本輪未再改動。

## Decision

next_round
