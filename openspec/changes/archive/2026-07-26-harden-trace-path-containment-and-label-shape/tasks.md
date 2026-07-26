## 1. 測試先行（Red）

第 1 節不受第 2 節前言所述的 receipt 失效影響：`scripts/cash-cli/tests/test_sync_archive_transaction.py` 不在 receipt 的受管集合內，且其驗證以 `PYTHONPATH=.cash-skills/lib python3 scripts/cash-cli/tests/test_sync_archive_transaction.py` 直接執行，不經 Cash CLI。

各 case 標註「Red」或「護欄」：Red 表示以現行程式碼實測必定失敗；護欄表示實作前即為綠燈，用途是防止實作把既有正確行為改壞，**不得因其一開始就綠燈而視為該 task 未完成**。本節全部 case MUST 透過既有的 `extract_code_paths` 與 `extract_test_paths` 兩個 helper 撰寫，MUST NOT 另建平行的 fixture 路徑。

- [x] 1.1 在 `scripts/cash-cli/tests/test_sync_archive_transaction.py` 新增 root containment 的 case：（a）`- Affected code:` 子清單含以 `../` 起首的路徑時該值不入 `code`【Red：現行 `_canonical_path` 兩個條件皆不成立而原樣回傳】；（b）子清單含路徑段為 `.` 的值（形如 `a/./b.py`）時不入 `code`【Red】；（c）子清單含內部連續斜線的值（形如 `a//b.py`）時不入 `code`【Red：結尾的 `//` 由既有反覆剝除處理，內部的不會】；（d）驗證子句寫成 `python3` 加以 `../` 起首的測試路徑時該路徑不入 `tests`【Red：現行該值通過字元集與 `/tests/` 判準】；（e）子清單含以 `~/` 起首的路徑、以及驗證子句含以 `~/` 起首的測試路徑時，兩者分別不入 `code` 與 `tests`【Red：`~` 在 `_PLAIN_PATH` 與 `_verification_path` 共用的字元集內，且其各段皆非空段、`.` 或 `..`，故只加路徑段條件並不足以攔截】；（f）第一段不以 `~` 起首、僅後續段含 `~` 的路徑（形如 `a/~b/c.py`）仍入 `code`【護欄：擋住把 `~` 判定寫成「值中任一處含 `~`」而誤殺合法檔名的實作】。（b）（c）兩個值 MUST 以純文字書寫於 `- Affected code:` 子清單內，使其同時經過 `_PLAIN_PATH` 與 `_canonical_path` 兩道。

  **（a）（b）（c）（e）的斷言 MUST 為集合相等**（例如 `code` 恰等於同一子清單中另一條合法路徑構成的單元素清單），MUST NOT 只斷言「該原字面值不在結果中」。理由：把 2.1 的條件誤讀為「濾掉不合格的路徑段」而非「整個值回傳 `None`」，是一個實作者真的會寫出來的形態——`[s for s in value.split("/") if s not in ("", ".", "..") and not s.startswith("~")]` 再重組。該實作對（a）（b）（c）（e）四個 case 全部產生落在 repo 內的合法值（實測依序為 `outside/x.py`、`a/b.py`、`a/b.py`、`outside/x.py`），因而通過僅斷言「不含原字面值」的 case，使 design D1「拒絕而非解析」完全未被固定；集合相等斷言則使這些被消毒出來的值必然被偵測到。（註：`os.path.normpath` **不**摺疊開頭的 `..`、也不展開 `~`，因此它只對（b）（c）造成同類問題，MUST NOT 被引為（a）（e）的理由。）驗證：以 `PYTHONPATH=.cash-skills/lib python3 scripts/cash-cli/tests/test_sync_archive_transaction.py` 執行時（a）（b）（c）（d）（e）皆失敗、（f）通過。
- [x] 1.2 於同檔新增標籤列形狀的 case：（a）`- Affected code:` 帶尾隨空白時子清單仍被定位【Red】；（b）該標籤列被縮排時仍被定位【Red】；（c）該標籤列 colon 之後同行帶路徑時，該行的路徑進入 `code`【Red：現行整行相等比對不命中】；（d）`## Impact` 標題列帶尾隨空白時仍被定位【Red】。驗證：同上指令中四個 case 皆失敗。
- [x] 1.3 於同檔新增容忍面邊界與對稱終止的 case：（a）標籤列寫成 `- **Affected code:**` 時不被視為子清單起點【護欄：此 case 固定「不容忍 markdown 強調標記」這個刻意決策，防止日後被誤認為疏漏而放寬】；（a2）標籤列寫成以全形冒號結尾的 `- Affected code：` 時同樣不被視為子清單起點【護欄：delta spec 對粗體與全形冒號並列了同一條 MUST NOT，兩者 MUST 各有一個 case，否則其中一條規範句沒有落點】。（a）與（a2）的 fixture MUST 在同一份 proposal 中另含一個以精確形狀書寫的 `- Affected code:` 子清單，並斷言 `code` 恰等於該精確子清單的路徑——以 `code` 為空作為斷言無法區分「不容忍該形式」與「整段抽取失效」。**該精確形狀子清單 MUST 置於粗體與全形冒號兩個標籤列之後**：`- **Affected code:**` 經 strip 後既不以 `- Affected code:` 起首（不成為子清單起點）**也不以 `- Affected ` 起首（不成為同層終止條件）**，因此若精確子清單排在粗體標籤之前，粗體標籤與其下的路徑會被當成該子清單的一般內容行而收進 `code`，斷言將對一個完全符合 2.2 的實作失敗。那是既有範圍定義的結果（design `## Non-Goals` 明示不改變），不是實作缺陷——順序約束因此是 fixture 的必要條件而非風格選擇。全形冒號形式在兩種順序下都不會使其下的路徑進入 `code`——排在已開啟的子清單之後時它終止該子清單，排在子清單開啟之前時它本身即不被掃描——但為與（a）一致，（a2）沿用同一順序。（b）`- Affected code:` 與其後的 `- Affected specs:` 都以縮排書寫時，`code` 只含前者的路徑、只出現在後者的 spec 路徑不入 `code`【Red：現行縮排標籤不被定位而使 `code` 為空，且此 case 專門擋住「只放寬起點、未同步放寬同層終止條件」的實作——該實作會使後者的 spec 路徑重新進入 `code`】。驗證：同上指令中（a）（a2）通過、（b）失敗。
- [x] 1.4 確認既有 `test_trace_path_extraction_never_crosses_lines` 與 `test_sync_applies_fixed_phases_and_is_idempotent` 未被修改且仍在測試集合中，作為「抽取不得跨行」與「sync 端到端冪等」兩個回歸護欄。驗證：`rg -F "test_trace_path_extraction_never_crosses_lines" scripts/cash-cli/tests/test_sync_archive_transaction.py` 與 `rg -F "test_sync_applies_fixed_phases_and_is_idempotent" scripts/cash-cli/tests/test_sync_archive_transaction.py` 各有命中，且兩者在上述各次執行中維持綠燈。

## 2. 實作（Green）

**順序要求與 `task done` 補標程序。** `.cash-skills/lib/cash_cli/spec_merge.py` 是 receipt 的 runtime 記錄，launcher 在載入前逐檔比對其 digest。因此自 2.1 第一次寫入起，**每一個 Cash 指令都會以 `receipt_invalid` 失敗**，訊息為 `runtime record drift: .cash-skills/lib/cash_cli/spec_merge.py. Run ./install-cash-skills.fish --self from the project root`，直到 3.2 重建 receipt 為止。

受影響的是 **2.1、2.2 與 3.1** 三個 task。據此：

- 2.1 至 3.1 **不得平行**，且期間 MUST NOT 執行任何 Cash 指令——包含 `task done` 與 `touched record`。實作者 MUST NOT 在 receipt 失效期間嘗試呼叫 CLI 並把失敗誤判為實作缺陷。
- 這些 task 的 `task done` MUST 延後到 3.2 完成之後一次補標，補標順序依 task 編號。
- 各 task 的驗證目標在此期間仍可執行，因為它們用的是 `python3`、`rg` 與 `git` 而非 Cash CLI。

- [x] 2.1 在 `.cash-skills/lib/cash_cli/spec_merge.py` 的 `_canonical_path` 既有兩個回傳 `None` 條件之後、`return value` 之前，增加兩條：剝除後的值以 `/` 切分，（i）任一段屬於空字串、`.` 或 `..` 時回傳 `None`；（ii）第一段以 `~` 起首時回傳 `None`。（ii）MUST 只判定第一段，MUST NOT 寫成「值中任一處含 `~`」或「任一段以 `~` 起首」，否則 `a/~b/c.py` 這類在後續路徑段含 `~` 的合法路徑會被誤殺。既有的反覆剝除迴圈與兩個既有條件 MUST NOT 改動。此改動同時作用於 `code` 與 `tests`，因為兩者共用該 helper。驗證：`PYTHONPATH=.cash-skills/lib python3 scripts/cash-cli/tests/test_sync_archive_transaction.py` 中 1.1 的（a）至（f）全部 case 綠燈。
- [x] 2.2 於同檔改寫 `_paths_in_section` 的四處定位條件：`## Impact` 改以 `line.rstrip() == heading` 判定；`- Affected code:` 起點改以 `line.strip().startswith(list_label)` 判定；同層終止改以 `line.strip().startswith("- Affected ")` 判定；`## ` 的 section 終止條件維持 `line.startswith("## ")` 不變。標籤列命中時，MUST 對 `line.strip()` 去除 `list_label` 前綴後的殘餘字串套用與一般內容行相同的收集流程（先 `_CODE_SPAN.findall` 取含斜線的值，再對 `_CODE_SPAN.sub(" ", 殘餘)` 套用 `_PLAIN_PATH`，兩組各自經 `_canonical_path`）；為避免該流程在標籤列與內容行兩處重複，MUST 抽為單一個區域 helper 或等價的單一呼叫點。`_verification_path`、`_task_paths`、`_PLAIN_PATH` 字元集、`_VERIFICATION_CLAUSE`、去重與 byte 排序 MUST NOT 改動。驗證：同上指令中 1.2 與 1.3 的全部 case 綠燈，且 1.4 的兩個既有護欄維持綠燈。

## 3. 版本、receipt 與整體驗證

- [x] 3.1 提升 `cash-skills.version`：讀取工作區當下值與 `git show HEAD:cash-skills.version`，寫入嚴格大於兩者的下一個版本並維持單行 LF 結尾。不得寫死常數，必須依執行當下兩者的最大值決定。兩者相等與兩者不等都是合法狀態——相等表示先前的 change 已提交，不等表示有 sibling change 已在工作區提升而尚未提交——MUST NOT 據其中任一狀態推斷環境異常。驗證：以 `python3 scripts/cash-skills/tests/test_bundle_version_history.py` 執行通過。
- [x] 3.2 於 project root 執行 `./install-cash-skills.fish --self` 重建 receipt。**這是第 2 節前言所述 receipt 失效區間的終點**：本 task 完成後 Cash CLI 恢復可用，MUST 立即依編號順序補標 2.1 至 3.1 全部 task 的 `task done`，再繼續 3.3。驗證：該指令回報 `Result: bootstrap` 或 `Result: current`；`.cash-skills/bin/cash validate --all` 通過。
- [x] 3.3 端到端驗證：以 `fish scripts/cash-cli/tests/cli-checks.fish sync-archive-transaction` 執行通過；並對本 change 自身的 artifacts 以 `PYTHONPATH=.cash-skills/lib python3 -c` 直接呼叫兩個抽取 helper，斷言 `code` 恰為 `.cash-skills/lib/cash_cli/spec_merge.py` 與 `scripts/cash-cli/tests/test_sync_archive_transaction.py` 兩條（`cash-skills.version` 位於 repo root、不含斜線，依 `_canonical_path` 不入 `code`，此為預期而非缺陷），`tests` 含 `scripts/cash-cli/tests/test_sync_archive_transaction.py` 與 `scripts/cash-skills/tests/test_bundle_version_history.py`。
- [x] 3.4 全語料等價性驗證。舊版抽取器的取得方式：`spec_merge.py` 內有 `from .errors import CashError` 等相對 import，單獨寫成暫存檔 import 必定以 `ImportError: attempted relative import with no known parent package` 失敗，因此 MUST 把整個 `.cash-skills/lib/cash_cli` 套件複製到暫存目錄、以 `git show HEAD:.cash-skills/lib/cash_cli/spec_merge.py` 覆寫其中的 `spec_merge.py`，再把該暫存目錄加入 `sys.path` 後 import。**複製後的套件目錄 MUST 改名（例如 `cash_cli_old`）**：同一個直譯器內不可能同時存在兩個 `cash_cli`，若沿用原名，`sys.path` 先命中者會同時充當新舊兩側，比較必得 0 差異——正是本 task 要擋的空洞通過。改用 `git worktree add` 取得完整 HEAD 樹時有同一個問題，除非改以兩個 subprocess 分別執行兩版。

  **退化守衛 MUST 為行為 sentinel**：執行任何比較前，先斷言 `old.__file__ != new.__file__`，再斷言 `old._canonical_path("../x/y") == "../x/y"` 且 `new._canonical_path("../x/y") is None`，任一不成立即以明確訊息失敗。只比對 `git show HEAD:` 內容與工作區內容是否不同 MUST NOT 作為唯一守衛——它檢查的是檔案 bytes，而不是實際被 import 的兩個模組物件，在上述同名情境下會通過。語料枚舉 MUST 以 `os.walk` 或 `find` 進行並涵蓋 `openspec/changes/.parked/` 之下的隱藏目錄（Python `glob` 的 `**` 預設不進入隱藏目錄）。對全部 `proposal.md` 與 `tasks.md` 執行新舊兩版抽取並斷言兩件事：（a）全語料逐檔 `code` 與 `tests` 結果新舊完全相等，差異數 MUST 為 0，且不排除任何檔案——含本 change 自身的 artifacts 在內，設計階段的原型實測差異即為 0，因此任何差異都是實作偏離設計的訊號而非預期；（b）若（a）出現任何差異，該差異 MUST 可歸入本變更兩個方向之一，且 MUST 分側斷言——本變更由方向相反的兩個改動組成：`_canonical_path` 是收緊（只會減少），標籤形狀是放寬（只會增加），因此 MUST NOT 斷言 `new` 為 `old` 的子集或 `new` 減 `old` 為空，那只編碼了收緊那一半，會把一份新加入語料、以 `- Affected code: <path>` 行內形式書寫的合法 proposal 判成實作缺陷。分側斷言為：`old` 減 `new` 的每個值 MUST 滿足以下任一（收緊側）——含空段、`.`、`..`，或其第一段以 `~` 起首；或該值位於同一份檔案中一個已命中的 `- Affected code:` 標籤列之後、且位於一個「strip 後才命中同層終止條件 `- Affected `」的 bullet 之後，因子清單提前終止而被丟棄；或該檔在真正的 `## Impact` 之前另有一行 rstrip 後才命中 `## Impact` 的標題列，使 section 在較早處開啟並提前終止（此兩形態皆為 Contract 2 放寬所必然帶來、且 design `## Risks / Trade-offs` 已具名接受的取捨，語料出現數各為 0，MUST NOT 被判為實作缺陷）；`new` 減 `old` 的每個值 MUST 出自該檔中一個 strip 後才命中的 `- Affected code:` 標籤列、該標籤列 colon 之後的行內內容、或一個帶尾隨空白的 `## Impact` 標題列（放寬側）。上述列舉是判定輔助而非封閉集合——它列的是設計已知會產生差異的形態，MUST NOT 被當成「不在列舉內即為實作缺陷」的自動判準，也 MUST NOT 反過來讓一個在位置上恰好符合某款、實際成因卻是別的實作錯誤的差異被自動歸為合乎設計。（a）出現任何差異時 MUST 停下、報告該檔與該差異集合、並逐項人工判定其成因，MUST NOT 逕行把該檔加入排除清單使斷言轉綠。**任何情況下 MUST NOT 為了讓斷言轉綠而放寬 `_canonical_path` 的路徑段判定。** 語料份數以執行當下枚舉為準，MUST NOT 把 design 記錄的份數寫成斷言條件。

## 4. Requirement 追溯

本節不含實作動作，用途是讓 spec requirement 有可稽核的落點。本變更的 delta 只修改一個 requirement：`Atomic park、sync 與 archive`，下表逐條款列出其落點。

| Spec requirement `Atomic park、sync 與 archive` 的條款 | 實作任務 |
| --- | --- |
| 路徑段 MUST NOT 為空、`.` 或 `..` | 1.1（a）（b）（c）（d）（Red）、2.1（Green）、3.4 |
| 第一段 MUST NOT 以 `~` 起首，且後續段含 `~` 者 MUST NOT 被拒絕 | 1.1（e）（Red）、1.1（f）（護欄）、2.1（Green）、3.4 |
| 該判定 MUST 為拒絕而非解析 | 1.1（a）（b）（c）（e）的集合相等斷言、2.1（Green） |
| 標籤列容忍前後空白與 colon 之後行內內容、`## Impact` 容忍尾隨空白 | 1.2（Red）、2.2（Green）、3.3 |
| 同層終止以相同正規化判定 | 1.3（b）（Red）、2.2（Green） |
| 粗體形式 MUST NOT 被視為起點 | 1.3（a）（護欄）、2.2（Green） |
| 全形冒號形式 MUST NOT 被視為起點 | 1.3（a2）（護欄）、2.2（Green） |
| 既有抽取行為不得回歸 | 1.4（護欄）、3.3、3.4 |
