## Context

`build_sync_plan` 在 `.cash-skills/lib/cash_cli/spec_merge.py` 以兩個 helper 產生 `@trace`：`_paths_in_section(workspace, change / "proposal.md", "## Impact")` 取 `code`、`_task_paths(workspace, change / "tasks.md")` 取 `tests`，兩者結果交給 `_trace` 渲染，再由 `_with_trace` 套到 requirement block 上。`_with_trace` 以 `_TRACE.sub("\n", block)` 無條件移除既有 trace 後才接上新的，因此新 trace 的欄位為空時，既有 trace 的內容會一併消失。`_with_trace` 只在 `_merge` 的 MODIFIED、ADDED 與 RENAMED 三個分支被呼叫；REMOVED 分支只刪除 requirement，不套用 trace。

`_paths_in_section` 只在 `_CODE_SPAN` 的匹配結果中挑含斜線的值，且掃描範圍是整個 `## Impact` 區段，因此 `- Affected specs:` 的 spec 路徑也會進入 `code`。`_verification_path` 只檢查 code span 的第一個 whitespace token。這些限制都不在 Cash-owned 的 proposal 模板（`.cash-skills/lib/cash_cli/resources.py` 的 `ARTIFACT_GRAPH`）或任何 requirement 中。

`_verification_path` 目前的窄化是刻意的：signal `trace-verification-path-source-confusion` 記錄了它原本收集 tasks 內所有含斜線 code span、把 source 交付路徑記成測試證據的缺陷。本變更放寬 token 掃描時 MUST NOT 回歸該缺陷。

`build_sync_plan` 在 `.cash-skills/state/sync/<name>.json` 存在且其 `delta_digests` 相符時以 `already_synced` 提前返回；該 manifest 的輸入指紋只涵蓋 delta specs，`proposal.md` 與 `tasks.md` 不在其中，因此某個 change 的 `@trace` 實質上是第一次 sync 時 write-once。`validation.py:239` 也呼叫 `build_sync_plan`，但只讀 `.already_synced`。本變更只改 `spec_merge.py` 的兩個抽取 helper 與其共用的 canonical 化，不動 `SyncPlan`、manifest、transaction 或任何 command 的回傳形狀。

## Goals / Non-Goals

Goals：

- `- Affected code:` 子清單以 backtick 或純文字書寫的 repo-relative 路徑都能進入 `code`，且 `- Affected specs:` 的路徑不進入。
- 驗證子句以直譯器或指令前綴開頭時，其中的測試路徑仍能進入 `tests`，且 source 交付路徑不進入。
- 兩個欄位寫入的值皆為 canonical repo-relative 形式。

Non-Goals：

- 不回填既有 master spec 的 trace。
- 不改變 `@trace` 的欄位集合、順序或渲染。
- 不改變 sync manifest 的 no-op 判定：`sync` 完成後該 change 的 `@trace` 即為 write-once。
- 不修 `_VERIFICATION_CLAUSE` 對 `以` 後不接空白之驗證子句的定位缺陷。
- 不新增任何診斷、gap 回報或輸出面。抽取為空時的可見性由後續 change 處理，且該 change SHOULD 放在 `validate` 而非 `sync`／`archive`：`validate` 不寫入、可反覆重跑，因此不受 sync manifest no-op 影響，且在 change 仍為 active 時觸發而可被作者收斂。其判準亦 SHOULD 為「宣告了 affected code 卻抽不到任何路徑」，而非「欄位為空」——後者在本變更修好抽取後於現有 29 份 proposal 上是 0/29，永不觸發。
- 不把任何 trace 抽取結果變成 execution error 或 validation finding。
- 不改變 transaction、rollback 與 archive 的移動語意，也不動 `.cash-skills/lib/cash_cli/commands/archive.py`。

## Decisions

**D1：`code` 的抽取範圍收斂到 `- Affected code:`，並同時接受 code span 與 ASCII 路徑形狀的裸 token。**
範圍收斂有兩個理由：本 requirement 既有條文寫的是「`code` 取 proposal affected-code paths」，掃整個 `## Impact` 與該定義不符；且放寬裸 token 之後，`- Affected specs:` 的路徑會大量進入 `code`（29 份 proposal 中 12 份，收斂後降為 7 份——後者是作者確實把 spec 檔列在 affected code 之下，屬合法）。

對每一行先以既有 `_CODE_SPAN` 取含斜線的值，再對以空白取代全部 code span 後的殘餘文字套用 plain-path pattern，兩組結果聯集。先以空白取代 code span 是為了讓同一路徑不被兩條規則各算一次、避免 code span 內的指令參數被誤認為裸路徑，也避免 span 兩側殘餘文字被拼接成假路徑。

pattern 限定 ASCII 的實測必須標明範圍，否則會被誤讀為當前偵測器：以**收斂前**的整個 `## Impact` 為對照範圍時，唯一被 ASCII 限定消除的是 `中硬編碼的版本/日期字面值改為以` 一例（不引用相異候選總數：該數字取決於對照組寬鬆字元集的定義，前幾輪三度出現不可重現的版本）；但該片語落在 `- Affected specs:` 行，因此在本規則實際生效的 `- Affected code:` 範圍上，現行 corpus 的消除數為 0。ASCII 限定的定位因此是防止未來作者在 affected-code 子清單寫入非 ASCII 散文的護欄，而非現況偵測器。**殘留 1 個 ASCII 散文偽陽性 `runtime/install`**，來自某份已封存 proposal 的 `- Generated（runtime/install 產生，不進版控）:`。本變更接受這個偽陽性：僅憑 token 形狀無法可靠區分 ASCII 散文與路徑，再加條件（要求副檔名、要求路徑存在）會分別排除合法的目錄項與已刪除檔案的歷史項。此決策回應 signal `detection-criterion-false-positive-on-legitimate-form` 的方式是「對真實 corpus 實跑並誠實記錄殘留偽陽性」，而非宣稱零偽陽性。

**D2：驗證子句掃描 code span 的全部 whitespace token。**
`_task_paths` 對每個 code span 改為逐 token 呼叫 `_verification_path`。過濾條件本身不放鬆，因此 `python3 <path>`、`fish <path> <arg>`、`PYTHONPATH=<dir> python3 -c '<code>'` 這類形式中的測試路徑會被抓到，而同一 span 內的非測試 token 仍被過濾。對本 change 以外的 28 份 tasks 實測，以**全域相異值**為基準：現行規則抽出 9 條，只放寬 token 掃描而沿用舊過濾條件抽出 13 條，損失 0 條。

**D3：以「測試形狀」取代 `.fish`／`.sh` 後綴規則，並為兩個欄位統一 canonical 化。**
`_verification_path` 目前接受任何以 `.fish` 或 `.sh` 結尾的含斜線 token。單獨看第一個 token 時傷害有限，但 D2 掃描全部 token 之後它會開始收進 source 腳本：實測顯示只靠後綴命中的 token 恰為 `./install-cash-skills.fish` 與 `scripts/spectra-plus/generate.fish`，兩者都是交付腳本。

判準改為：兩個 canonical check script 的裸檔名特例不變；其餘 token 先經 `_canonical_path` 正規化（反覆剝除 `./` 前綴與結尾 `/`；以 `/` 起首或剝除後不含斜線者丟棄），再要求正規化後的值滿足 `/tests/` 出現在路徑中或檔名以 `test_` 起首。實測（同樣以全域相異值為基準）此判準抽出 11 條：相對現行規則損失 0 條、新增 2 條（`scripts/spectra-plus/tests/generator-checks.fish` 與 `scripts/spectra-plus/tests/installer-commit-guard-checks.fish`），並相對「只放寬 token 掃描」少收上述兩個 source 腳本。本文所有 tasks 側數字皆以全域相異值計，避免與各檔案增量加總混淆。

canonical 化對兩個欄位統一適用：`code` 與 `tests` 的值都剝除 `./` 前綴、不以 `/` 起首、不以 `/` 結尾。只為 `tests` 做正規化會讓 `code` 留下 `scripts/spectra-plus/` 這類結尾斜線的目錄項，與 signal `noncanonical-path-persisted-in-allowlist` 的教訓不一致。

## Implementation Contract

1. `.cash-skills/lib/cash_cli/spec_merge.py` 新增模組層級 pattern `_PLAIN_PATH`，匹配至少含一個斜線、且全部字元屬於字元集 `[A-Za-z0-9_.@+~-]` 與 `/` 的 token，並以左側邊界條件避免匹配既有 token 的中段。該字元集 MUST NOT 含 `,`、`;`、`(`、`)` 等標點——corpus 中已有以 ASCII 逗號分隔的純文字路徑列，含 `,` 會使除最後一項外每個值都帶尾逗號寫入 `code`。
2. 同檔新增 `_canonical_path(value: str) -> str | None`：反覆剝除 `./` 前綴與結尾的 `/` 至不再變化，值以 `/` 起首或剝除後不含斜線時回傳 `None`，否則回傳剝除後的值。反覆剝除是 delta「寫入的值 MUST 為剝除 `./` 前綴後、不以 `/` 結尾」的必要條件——只剝單一層時 `././x/y` 與 `scripts/foo//` 會分別輸出仍帶 `./` 前綴與仍帶結尾 `/` 的非 canonical 值。`code` 與 `tests` 兩條抽取路徑都 MUST 經過它。
3. 同檔 `_paths_in_section` 改為接受子清單標籤參數，掃描範圍限定為 `## Impact` 之下 `- Affected code:` 標籤列之後、下一個同層 `- Affected ` 標籤列或下一個 `## ` 標題之前；範圍內對每行先以 `_CODE_SPAN` 取含斜線的值，再對 `_CODE_SPAN.sub(" ", line)` 的結果套用 `_PLAIN_PATH`（以空白取代而非刪除，避免 span 兩側殘餘文字被拼接成行內從未出現的假路徑），兩組值各自經 `_canonical_path` 後聯集，沿用既有的去重與 byte 排序。
4. 同檔 `_verification_path` 改為：`cli-checks.fish` 與 `skill-checks.fish` 兩個裸檔名的既有映射不變且 MUST 在任何 canonical 化之前判定（`_canonical_path` 對不含斜線的值回傳 `None`，先 canonical 化會使該映射靜默消失）；其餘輸入先要求全部字元屬於與 Contract 1 相同的字元集（不符即回傳 `None`，使 `--rootdir=...`、`path::test_x` 等帶額外字元的 token 不會逐字寫入 trace），再經 `_canonical_path`，最後要求結果滿足 `"/tests/" in f"/{value}"` 或 `Path(value).name.startswith("test_")`，成立時回傳該值，否則回傳 `None`。原本以 `.fish`／`.sh` 後綴接受的分支移除。
5. 同檔 `_task_paths` 對每個 code span 改為 `for token in value.split()` 逐 token 呼叫 `_verification_path`。`_VERIFICATION_CLAUSE` 定位、去重與排序不變。
6. `cash-skills.version` MUST 以相對方式提升：實作時讀取工作區的 `cash-skills.version` 與 `git show HEAD:cash-skills.version`，寫入嚴格大於兩者的下一個版本，維持單行 LF 結尾。MUST NOT 寫死常數——sibling change `rightsize-cash-skills` 與 `.parked/support-multi-file-skill-payload` 也宣告要提升該檔。之後在 project root 執行 `./install-cash-skills.fish --self` 重建 receipt。
7. `scripts/cash-cli/tests/test_sync_archive_transaction.py` 新增涵蓋以下情形的 case：`- Affected code:` 只用純文字路徑、backtick 與純文字混用、`- Affected specs:` 的路徑不進入 `code`、非 ASCII 散文不進入 `code`；驗證子句以 `python3 <path>` 與 `fish <path> <arg>` 書寫、同一 span 內非測試 token 被排除、tests 目錄外的 `.fish` 交付腳本被排除、`./` 前綴與結尾斜線被 canonical 化（兩個欄位各一）；帶字元集外字元的 token 不入 `tests`。既有 `test_trace_path_extraction_never_crosses_lines` MUST 維持綠燈。共用 fixture `make_workspace` 的 proposal 目前只有 `## Impact` 加一行 `- Modified:`，沒有 `- Affected code:` 標籤，抽取範圍收斂後其 `code` 必為空，會使既有的 `test_sync_applies_fixed_phases_and_is_idempotent` 轉紅；本變更 MUST 把該 fixture 的 proposal 改為模板形狀，此為預期的 fixture 更新而非實作缺陷。

## Risks / Trade-offs

- **移除 `.fish`／`.sh` 後綴規則是行為收窄**：未來若有位於 tests 目錄之外、檔名也不以 `test_` 起首的檢查腳本被寫進驗證子句，它不會再進入 `tests`。這是刻意取捨——不在 tests 目錄且無命名標記的腳本無法從路徑本身證明它是測試證據。真有此需求時應為該腳本加入 canonical 特例，而非放寬通則。
- **接受 1 個殘留 ASCII 偽陽性**：`runtime/install` 會進入該份 proposal 的 `code`。相對於「14/29 份 proposal 的 `code` 完全落空」，這是明確較小的代價；該值只影響一份已封存 proposal，且 tasks 3.4 已把它列為已知並接受的殘留而非失敗。
- **尾斜線書寫的目錄形態在兩側皆由接受變為丟棄**：`_canonical_path` 剝除結尾 `/` 之後，`code` 側的單段目錄宣告（如 `openspec/`）因不含斜線而回傳 `None`，`tests` 側以尾斜線書寫的測試目錄 token（如 `scripts/x/tests/`）則不再滿足 `/tests/` 判準。實測現行 corpus：`tests` 側損失為 0；`code` 側有 2 例，分別來自兩份已封存 proposal 的 `- Affected code:` 範圍內散文——`.spectra/`（單段目錄，剝除尾斜線後不含斜線）與 `/spectra-`（以 `/` 起首的片語殘片）。兩者本非路徑宣告，丟棄屬預期而非回歸。
- **repo root 層級的 affected-code 宣告永遠不入 `code`**：`_canonical_path` 對剝除後不含斜線的值回傳 `None`。實測 29 份 proposal 的 `- Affected code:` 子清單中被丟棄的值包含 `cash-skills.version`、`install-cash-skills.fish`、`CASH-SKILLS.md`、`AGENTS.md`、`CLAUDE.md`、`.gitignore`、`.cash.yaml`。因此 Non-Goals 引用的「新規則下 `code` 為空 0/29」不涵蓋「只宣告 root-level 檔案」這一類 change——該類 change 會得到空 `code`。corpus 中已有臨界案例只靠單一條含斜線路徑才未落空。此限制記於 proposal `## Non-Goals`。
- **既有空 trace 不回填**：本變更之前產生的空 trace 會維持原狀，且如 Non-Goals 所述無法由原 change 自行收斂。master spec 在一段期間內會同時存在新舊兩種品質的 trace。
- **receipt 失效區間**：`spec_merge.py` 在 `.cash-skills/lib/` 之下，屬 receipt 受管的 runtime 記錄。自第一次寫入起，每個 Cash 指令都會以 `receipt_invalid` 失敗，直到執行 `./install-cash-skills.fish --self` 重建為止；tasks 必須據此安排順序與 `task done` 的補標時機。
