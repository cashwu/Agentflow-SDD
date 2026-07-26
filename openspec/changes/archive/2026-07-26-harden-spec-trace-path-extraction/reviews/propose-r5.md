# Cash Propose Review — Round 5

micro round，單一 Reviewer V 做差異驗證。主 agent 已對其裁定與 findings 獨立重跑驗證。

## Reviewer Findings

### 累積 blocking 集合裁定（1 位成員）

**`R4-W1`：`resolved`**。Reviewer V 以 `rg` 確認被否定的因果句在三個 artifact 的殘留為 0，且 delta 與 design D6 的表述逐句一致、proposal 第 4 點已補上「本次 merge 實際套用過 `@trace`」限定。

### Warning

本輪五個 blocking finding 中有四個的 `disposition` 是 `unresolved-prior`，且成因相同且嚴重：**第 4 輪的 `## Fix Actions` 宣稱了未實際套用的修改**。

- **R5-W1** `95` / `design` / `unresolved-prior` / `location: tasks.md 2.3 對 Contract 6、D4、delta gap 判定條款` — R4-W2 的跨檔聚合修正只落到 design 與 delta，tasks 2.3 仍逐字寫著「`delta.modified`、`delta.added`、`delta.renamed` 三者皆空」，正是 R4-W2 指出的單數迴圈變數寫法。tasks 是 apply 迴圈實際遵循的文件，與 Contract 6 直接牴觸。主 agent 機械驗證：該字串在 tasks.md 命中 1 次。**成立。**
- **R5-W2** `90` / `design` / `unresolved-prior` / `location: tasks.md 1.5 與 Contract 10` — 第 4 輪 Fix Actions 宣稱新增 case（b2），但 tasks 1.5 現況只有五個 case 且結尾逐字寫「五個 case 皆紅燈」；Contract 10 的測試枚舉同樣未列該情形。結果是 Contract 6 唯一新增的 MUST 在整份 tasks 中沒有任何機械驗證落點——一個只讀迴圈結束後 `delta` 的實作可以讓 1.4、1.5 全部綠燈。主 agent 驗證：`b2` 命中 0 次。**成立。**
- **R5-W3** `85` / `design` / `unresolved-prior` / `location: tasks.md 1.6、1.5（c）(d)(e) 與 Contract 8` — 第 4 輪宣稱新增 stderr **缺席**斷言，但 tasks.md 全檔無任何一處斷言 stderr 不含診斷。R4-S3 的核心缺陷因而未消除：一個把 helper 直接接到 `plan.trace_gaps` 的實作（`--skip-specs` 下 `_merge` 仍已執行、plan 值非空）會讓 1.5、1.6 全部綠燈，卻違反 delta 的 MUST NOT。主 agent 驗證：`缺席` 命中 0 次。**成立。**
- **R5-W4** `80` / `design` / `fix-introduced` / `introduced_by: 第 4 輪 R4-S3／S6 對 delta 診斷條款與 Contract 8 的改寫` / `location: delta archive 診斷條款 對 tasks 1.6 末句` — delta 寫成絕對敘述「使未寫入任何 master spec 即中止的 archive MUST NOT 輸出」，但 tasks 1.6 末句要求相反的 case（注入 commit 失敗後 stderr 仍含診斷）；commit 失敗會 rollback、一 byte 未寫入，滿足 tasks 的實作即違反 delta。且 `archive.py` 在 validation 與 commit 之間仍有 `load_or_import_touched`、`ensure_directory` 等中止點，任何 helper 位置都存在「未寫入卻已輸出」的路徑，絕對敘述不可能成立。Contract 8 用的是較窄的列舉式表述，兩者不等價，而 delta 是會被併入 master spec 的那一份。**成立。**
- **R5-W5** `80` / `design` / `unresolved-prior` / `location: Contract 4 對 delta tests 判準與 tasks 2.2、3.4` — R4-S7 的字元集前置條件只落在 Contract 4：delta 的 `tests` 判準是封閉形式且無字元集要求（依該 normative 條款，`path::test_y` 是 MUST 接受的）；tasks 2.2 作為唯一 Green 步驟也沒有字元集，實作者依 tasks 不會實作它；唯一相關的 3.4 corpus 斷言因現況 12 個值全部乾淨而屬空轉。Contract 4 的新 MUST 既無 normative 靠山、也無實作指示、也無有效測試。**成立。**

### Suggestion（非 blocking，已 triage）

- **R5-S1** `70` / `design` / `new` / `location: tasks.md 3.4` — 「以 `git show HEAD:...spec_merge.py` 取出並寫入暫存檔後 import」依字面不可執行：該檔有 `from .errors import CashError` 等相對 import，單獨 import 必以 `ImportError: attempted relative import with no known parent package` 失敗。
- **R5-S2** `70` / `text` / `fix-introduced` / `introduced_by: 第 4 輪 R4-W1 對 proposal 第 4 點的改寫` — 「（見下方第 4 點以外的四種情形）」是懸空指涉，proposal 全檔未枚舉那四種情形。
- **R5-S3** `50` / `text` / `unresolved-prior` / `location: delta gap 段首句` — 首句「本次 merge 未套用任何 `@trace` 的執行」與同段枚舉的 `archive --skip-specs` 不相容（`--skip-specs` 下 `_merge` 仍完整跑完並套用 trace），該段靠後半的一般判準才成立。

Reviewer V 另重跑驗證且成立、未列為 finding 的項目包含：ASCII 實測方向與結論（收斂前消除 1、收斂後消除 0）、`drift._impact_paths` 與 root-level 兩則 Non-Goal 的事實陳述、「9 份 change 具兩個以上 delta spec 檔」、tasks 3.3 的兩條斷言、`make_workspace` fixture 描述、Contract 4 兩個順序條件無歧義、Contract 8 呼叫點與實際控制流相容。

## Rating

- 過濾後累積 blocking 集合 Critical：0
- 過濾後累積 blocking 集合 Warning：5
- Non-blocking triaged findings：3
- `critical_gap`: `false`
- `round_type`: `micro`

`R4-W1` 經驗證解決並移除，但五個新的 blocking Warning 進入集合，其中四個是 `unresolved-prior`。本輪的根本教訓與前四輪不同：問題不在判斷，而在**修正機制本身**。主 agent 在第 4 輪的 tasks 側編輯使用了不帶斷言的字串替換，目標字串不完全相符時靜默無作用，而主 agent 只確認腳本執行成功即在 `## Fix Actions` 記為已修。這使第 4 輪的 `## Fix Actions` 有四項是不實記載，也使 `review-fix-propagation-incomplete` 這個本 loop 反覆抓到的 signal 在主 agent 自己的修正機制上重演。

## Fix Actions

修改的檔案：`proposal.md`、`design.md`、`tasks.md`、`specs/cash-cli/spec.md`（4 個相異檔案）。

**修正機制本身的更正（優先於個別 finding）** — 本輪全部編輯改用帶斷言的替換：每個目標字串 MUST 存在且 MUST 恰好命中一次，否則腳本立即中止。修正完成後另跑一份逐項機械驗證，對 12 個修正點各檢查一個特徵字串，全部回報 OK 才進入本節記載。第 4 輪的不實記載不追溯修改該輪檔案（完成輪為不可變的 gate input），改由本輪如實記錄。

**R5-W1** — tasks 2.3 改寫為「**全部** delta spec 檔的 `modified`、`added`、`renamed` 皆空時回傳空 tuple」，並明寫「實作 MUST 在 `for delta_path in delta_paths:` 迴圈內以 OR 累積布林值，MUST NOT 讀取迴圈結束後的 `delta`」及其理由（`workspace.spec_files` 順序來自未排序的 `os.listdir`），與 Contract 6 用語對齊。

**R5-W2** — tasks 1.5 新增 plan 層 case（b2）：兩份 delta spec 檔、一份只有 MODIFIED 一份只有 REMOVED、`code` 或 `tests` 至少一者為空時斷言 `plan.trace_gaps` 非空，且 MUST 以兩種不同建檔順序各執行一次；結尾「五個 case」改為「六個 case」。Contract 10 的測試枚舉同步補上該情形並註明 MUST 以兩種順序各驗一次。

**R5-W3** — tasks 1.6 新增三個 stderr **缺席** case：`archive --skip-specs`、manifest 相符的 `archive`、REMOVED-only delta 的 `sync`，皆斷言 stderr 不含診斷字串且回傳 0，並在 task 內說明缺席面是對「helper 直接讀 `plan.trace_gaps`」這種錯誤實作的唯一防線。Contract 10 同步補上。

**R5-W4** — 兩側同時收斂：delta 的絕對敘述改為「使在該輸出點之前中止的 archive——含以 `validation_failed` 與 `tasks_incomplete` 中止者——MUST NOT 輸出」，並明寫「此條款不宣稱涵蓋輸出點之後的任何中止路徑」；tasks 1.6 末句的 commit-failure 斷言改為**呼叫順序**斷言（以 mock 記錄 stderr 寫入與 `transaction.commit` 的相對順序），並明寫 MUST NOT 以「注入 commit 失敗後 stderr 仍含診斷」表達此條款及其理由。

**R5-W5** — delta 的 `tests` 判準補上「MUST 先要求全部字元屬於與 `code` 側相同的 ASCII 路徑字元集，不符者 MUST NOT 進入 `tests`」，並明寫裸檔名映射 MUST 在任何 canonical 化之前判定；tasks 2.2 同步補上字元集與順序要求；tasks 1.3 新增 Red case（d），以 `scripts/cash-cli/tests/x.py::test_y` 與 `--rootdir=scripts/cash-cli/tests/z` 斷言兩者不入 `tests`；Contract 10 的測試枚舉同步補上。

**Suggestion 處置（全部採納）** — R5-S1：tasks 3.4 改寫取得舊版的手段為「把整個 `.cash-skills/lib/cash_cli` 套件複製到暫存目錄、以 `git show HEAD:` 覆寫其中的 `spec_merge.py`、再加入 `sys.path` 後以獨立模組名 import（或改用 `git worktree add`）」，並保留原有的相對 import 失敗說明作為理由。R5-S2：proposal 第 4 點的懸空指涉改為直接列出四種情形並註明「判定見 design D4 與 delta 的 gap 判定條款」。R5-S3：delta 段首句改為「本次執行未把套用過 `@trace` 的 merge 結果寫入 master spec 時 MUST 回報空的 gap 集合」，與同段後半的一般判準一致。

**修正後機械式自我檢查** — 12 個修正點逐一驗證全部 OK；既有 8 Scenario 逐 byte 保留、註解 lint 0/0、tasks 7-4-4 條、Contract 10 條、proposal 4 點皆一致。`validate` 重跑通過。

## Decision

next_round
