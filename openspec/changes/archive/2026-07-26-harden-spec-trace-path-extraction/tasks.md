## 1. 測試先行（Red）

第 1 節不受第 2 節前言所述的 receipt 失效影響：`scripts/cash-cli/tests/test_sync_archive_transaction.py` 不在 receipt 的受管集合內，且其驗證以 `PYTHONPATH=.cash-skills/lib python3 scripts/cash-cli/tests/test_sync_archive_transaction.py` 直接執行，不經 Cash CLI。

各 case 標註「Red」或「護欄」：Red 表示以現行程式碼實測必定失敗；護欄表示實作前即為綠燈，用途是防止實作把既有正確行為改壞，**不得因其一開始就綠燈而視為該 task 未完成**。

- [x] 1.1 在 `scripts/cash-cli/tests/test_sync_archive_transaction.py` 新增 `code` 抽取範圍的 case：`- Affected code:` 子清單（a）只有純文字路徑【Red】、（b）同一路徑同時以 backtick 與純文字出現時結果恰一次【護欄：現行程式碼已只回傳一次】、（c）含以斜線分隔的非 ASCII 散文片語時該片語不入結果【護欄】。該片語 MUST 以純文字書寫——ASCII 字元集只作用於裸路徑 token，code span 分支不做字元集過濾，若置於 code span 則新舊規則都會收集它，該 case 失去護欄性質、（d）只出現在 `- Affected specs:` 的路徑不入結果【Red：現行掃整個 `## Impact`】。該路徑 MUST 以 backtick code span 書寫——現行 `_paths_in_section` 只收集 code span 命中的值，若比照（a）寫成純文字則現行程式碼本來就不會收集它，該 case 會在實作前即綠燈而失去 Red 性質。驗證：`PYTHONPATH=.cash-skills/lib python3 scripts/cash-cli/tests/test_sync_archive_transaction.py` 中（a）（d）失敗、（b）（c）通過。
- [x] 1.2 於同檔新增驗證子句 token 掃描的 case：（a）驗證子句寫成直譯器在前加路徑、以及指令在前加路徑再加參數兩種形式時抓到測試路徑【Red】；（b）同一 code span 內不滿足測試判準的其他 token 不出現在結果中【護欄】；（c）驗證子句以裸 `cli-checks.fish` 或 `skill-checks.fish` 書寫時仍映射為既有的兩條完整路徑【護欄：此 case 專門擋住把 canonical 化提到裸檔名分支之前而使映射靜默消失的實作】。驗證：同上指令中（a）失敗、（b）（c）通過。
- [x] 1.3 於同檔新增測試判準與 canonical 化的 case：（a）位於 tests 目錄之外、檔名不以 `test_` 起首、以 `.fish` 結尾的交付腳本路徑不入 `tests`【Red：現行因後綴規則被接受】；（b）以 `./` 起首的 tests 目錄下測試路徑回傳剝除後的形式【Red】；（c）`- Affected code:` 內以 `./` 起首或以 `/` 結尾的路徑在 `code` 中被 canonical 化，且含以 `././` 起首與以 `//` 結尾的重複形態各一，斷言輸出不以 `./` 起首、不以 `/` 結尾【Red】；（d）驗證子句含 `scripts/cash-cli/tests/x.py::test_y` 與 `--rootdir=scripts/cash-cli/tests/z` 這類帶字元集外字元的 token 時，兩者皆不入 `tests`【Red】。兩個 token MUST 各自獨立成一個 code span（或各自為其 code span 的第一個 whitespace token）——現行 `_verification_path` 只判 `value.split(maxsplit=1)[0]`，若寫成 `python3 -m pytest <token>` 這種單一 span，第一個 token 為 `python3` 而回傳 `None`，該 case 會在實作前即綠燈而失去 Red 性質。驗證：同上指令中四個 case 皆失敗，且（a）的失敗訊息顯示該交付腳本路徑出現在結果中。
- [x] 1.4 確認既有 `test_trace_path_extraction_never_crosses_lines` 未被修改且仍在測試集合中，作為「抽取不得跨行」的回歸護欄。驗證：`rg -F "test_trace_path_extraction_never_crosses_lines" scripts/cash-cli/tests/test_sync_archive_transaction.py` 有命中，且該 case 在上述各次執行中維持綠燈。

## 2. 實作（Green）

**順序要求與 `task done` 補標程序。** `.cash-skills/lib/cash_cli/spec_merge.py` 是 receipt 的 runtime 記錄，launcher 在載入前逐檔比對其 digest。因此自 2.1 第一次寫入起，**每一個 Cash 指令都會以 `receipt_invalid` 失敗**，訊息為 `runtime record drift: .cash-skills/lib/cash_cli/spec_merge.py. Run ./install-cash-skills.fish --self from the project root`，直到 3.2 重建 receipt 為止。

受影響的是 **2.1、2.2 與 3.1** 三個 task。據此：

- 2.1 至 3.1 **不得平行**，且期間 MUST NOT 執行任何 Cash 指令——包含 `task done` 與 `touched record`。實作者 MUST NOT 在 receipt 失效期間嘗試呼叫 CLI 並把失敗誤判為實作缺陷。
- 這些 task 的 `task done` MUST 延後到 3.2 完成之後一次補標，補標順序依 task 編號。
- 各 task 的驗證目標在此期間仍可執行，因為它們用的是 `python3`、`rg` 與 `git` 而非 Cash CLI。

- [x] 2.1 在 `.cash-skills/lib/cash_cli/spec_merge.py` 新增 `_PLAIN_PATH` pattern 與 `_canonical_path(value)` helper（反覆剝除 `./` 前綴與結尾 `/` 至不再變化，以 `/` 起首或剝除後不含斜線時回傳 `None`）；改寫 `_paths_in_section` 使其接受子清單標籤參數、掃描範圍限定為 `- Affected code:` 標籤列之後至下一個同層 `- Affected ` 標籤列或下一個 `## ` 標題之前，範圍內對每行先取 code span、再對 `_CODE_SPAN.sub(" ", line)` 套用 `_PLAIN_PATH`（以空白取代而非刪除，避免 span 兩側殘餘文字拼接成假路徑），兩組值各自經 `_canonical_path` 後聯集並沿用既有去重與 byte 排序；`build_sync_plan` 的呼叫點同步改為傳入 `- Affected code:`。同時把測試檔共用 fixture `make_workspace` 的 proposal 由 `## Impact` 加一行 `- Modified:` 改為模板形狀（`- Affected specs:`／`- Affected code:`／`- Modified:`），否則抽取範圍收斂後其 `code` 必為空，會使既有的 `test_sync_applies_fixed_phases_and_is_idempotent` 轉紅——**這是預期的 fixture 更新，不是實作缺陷**。驗證：`PYTHONPATH=.cash-skills/lib python3 scripts/cash-cli/tests/test_sync_archive_transaction.py` 中 1.1 與 1.3（c）的全部 case 綠燈，且 `test_sync_applies_fixed_phases_and_is_idempotent` 維持綠燈。
- [x] 2.2 於同檔改寫 `_verification_path`：兩個 canonical check script 裸檔名的既有映射不變；裸檔名映射 MUST 在任何 canonical 化之前判定（`_canonical_path` 對不含斜線的值回傳 `None`，先 canonical 化會使映射靜默消失）；其餘輸入先要求全部字元屬於與 `_PLAIN_PATH` 相同的字元集，不符即回傳 `None`，再經 `_canonical_path`，最後要求 `/tests/` 出現在其路徑中或其檔名以 `test_` 起首，成立時回傳該值，否則回傳 `None`；移除以 `.fish` 或 `.sh` 後綴接受的分支。並改寫 `_task_paths` 對每個 code span 逐 whitespace token 呼叫 `_verification_path`，`_VERIFICATION_CLAUSE` 定位、去重與排序不變。驗證：同上指令中 1.2、1.3（a）（b）（d）與 1.4 的 case 綠燈。

## 3. 版本、receipt 與整體驗證

- [x] 3.1 提升 `cash-skills.version`：讀取工作區當下值與 `git show HEAD:cash-skills.version`，寫入嚴格大於兩者的下一個版本並維持單行 LF 結尾。不得寫死常數，必須依執行當下的實際值決定。驗證：`python3 scripts/cash-skills/tests/test_bundle_version_history.py` 通過。
- [x] 3.2 於 project root 執行 `./install-cash-skills.fish --self` 重建 receipt。**這是第 2 節前言所述 receipt 失效區間的終點**：本 task 完成後 Cash CLI 恢復可用，MUST 立即依編號順序補標 2.1 至 3.1 全部 task 的 `task done`，再繼續 3.3。驗證：該指令回報 `Result: bootstrap` 或 `Result: current`；`.cash-skills/bin/cash validate --all` 通過。
- [x] 3.3 端到端驗證：執行 `fish scripts/cash-cli/tests/cli-checks.fish sync-archive-transaction` 通過；並對本 change 自身的 artifacts 以 `PYTHONPATH=.cash-skills/lib python3 -c` 直接呼叫兩個抽取 helper，斷言 `code` 恰為 `.cash-skills/lib/cash_cli/spec_merge.py` 與 `scripts/cash-cli/tests/test_sync_archive_transaction.py` 兩條（`cash-skills.version` 位於 repo root、不含斜線，依 `_canonical_path` 不入 `code`，此為預期而非缺陷），`tests` 含 `scripts/cash-cli/tests/test_sync_archive_transaction.py` 與 `scripts/cash-skills/tests/test_bundle_version_history.py`。
- [x] 3.4 對既有 corpus 迴歸確認：舊版抽取器的取得方式：`spec_merge.py` 內有 `from .errors import CashError` 等相對 import，單獨寫成暫存檔 import 必定以 `ImportError: attempted relative import with no known parent package` 失敗，因此 MUST 把整個 `.cash-skills/lib/cash_cli` 套件複製到暫存目錄、以 `git show HEAD:.cash-skills/lib/cash_cli/spec_merge.py` 覆寫其中的 `spec_merge.py`，再把該暫存目錄加入 `sys.path` 後以獨立模組名 import（或改用 `git worktree add` 取得完整 HEAD 樹）；執行任何比較前 MUST 先斷言 `git show HEAD:.cash-skills/lib/cash_cli/spec_merge.py` 與工作區 `.cash-skills/lib/cash_cli/spec_merge.py` 的內容不同——若相同，代表 HEAD 已含本 change 的實作、新舊對照已退化為自我比較而使超集與損失集合斷言空洞地通過，MUST 以明確訊息失敗並改取本 change 實作前的 commit 作為舊版來源；語料枚舉 MUST 以 `os.walk` 或 `find` 進行並涵蓋 `openspec/changes/.parked/` 之下的隱藏目錄（Python `glob` 的 `**` 預設不進入隱藏目錄，會漏掉該語料）。對全部 `proposal.md` 與 `tasks.md` 執行新舊兩版抽取並比較。`tests` 的超集斷言 MUST 排除本 change 自身的 `openspec/changes/harden-spec-trace-path-extraction/tasks.md`：該檔的 1.3（d）刻意含 `--rootdir=scripts/cash-cli/tests/z` 與 `scripts/cash-cli/tests/x.py::test_y` 兩個帶字元集外字元的 token，舊規則會逐字接受、新規則依 Contract 4 必須丟棄，因此該檔的損失集合恰為這兩個值而非空集合。**MUST NOT 為了讓該斷言轉綠而放寬 token 字元集**——那會直接違反 delta 的「該字元集 MUST NOT含`,`、`;`、`(`、`)`、`:`、`=`等非路徑標點」。排除本檔後，斷言其餘語料的 `tests` 新結果是舊結果的超集（損失集合為空）、新結果不含位於 tests 目錄之外且檔名不以 `test_` 起首的 `.fish` 交付腳本路徑、`tests` 的新結果同樣不含字元集外字元與結尾標點、`code` 的新結果不含任何非 ASCII 字元、也不含任何以 `/` 起首、以 `/` 結尾或帶尾端標點（`,`、`;`、`)`）的值。已知並接受的殘留偽陽性 `runtime/install` 不視為失敗。

## 4. Requirement 追溯

本節不含實作動作，用途是讓 spec requirement 有可稽核的落點。本變更的 delta 只修改一個 requirement：`Atomic park、sync 與 archive`，下表逐條款列出其落點。

| Spec requirement `Atomic park、sync 與 archive` 的條款 | 實作任務 |
| --- | --- |
| `code` 抽取範圍限定 `- Affected code:`、接受兩種書寫形式、ASCII 字元集 | 1.1（Red 與護欄）、2.1（Green）、3.3、3.4 |
| `tests` 掃描全部 token、測試形狀判準、`.fish`/`.sh` 後綴不足以認定、token 字元集前置條件 | 1.2、1.3（a）（b）（d）、1.4（Red 與護欄）、2.2（Green）、3.4 |
| 兩個欄位的 canonical repo-relative 形式 | 1.3（b）（c）（Red）、2.1、2.2（Green）、3.4 |
