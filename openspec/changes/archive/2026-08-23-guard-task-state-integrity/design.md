## Context

**`cash-archive` 的未完成 task 路徑。**

`.claude/skills/cash-archive/SKILL.md` 步驟 3 標題為 `3. **Check task completion status**`，其未完成分支只有三行：`Display warning showing count of incomplete tasks`、`Prompt user for confirmation to continue`、`Proceed if user confirms`，且這些行在檔案中縮排 3 空格（步驟 3 是 numbered list item，其內文屬於該 item）。步驟 5 的 Optional flags 清單雖列有 `- `--mark-tasks-complete` — mark all incomplete tasks as complete before archiving`，但全檔沒有任何一句把步驟 3 的確認接到該旗標，步驟 5 的 bash 範例也只有 `"$cash_cli" archive <name>` 與 `"$cash_cli" archive <name> --skip-specs` 兩行。

`.cash-skills/lib/cash_cli/commands/archive.py` 的 `archive_change()` 以 `if any(not task["done"] for task in tasks) and not mark_tasks_complete:` 拋出 `tasks_incomplete`，該檢查排在 `build_sync_plan()` 與 `validate_change()` 之後、transaction 之前。因此使用者確認繼續後必然撞上這個錯誤。

`.claude/skills/cash-commit/SKILL.md` 的 `**6a-i. Incomplete task handling**` 對同一情境是正確的（Yes 設旗標、No 取消子流程），且其 6a-iii 的 bash 範例為 `"$cash_cli" archive <name> [--mark-tasks-complete] [--skip-specs]`，旗標在執行層可見。本變更是讓 `cash-archive` 在提問層與執行層都向它看齊。

**touched state 的 attribution。**

`.cash-skills/lib/cash_cli/commands/tasks.py` 的 `_task_entries(content)` 以 `str(len(entries) + 1)` 產生 task id，並以 `_TASK_LABEL` 驗證每個 task 的標籤存在且唯一；標籤缺失或重複時拋 `CashError("task_id_invalid", ...)`。id 因此是位置式的，標籤才是語意識別。

`_validate_touched(value, name)` 的簽章只有已解析的 dict 與 change 名稱，**沒有 `Workspace`**，結構上讀不到 `tasks.md`。對齊因此不能加在它內部，必須加在拿得到 workspace 的呼叫層。

`_validate_touched()` 有兩個呼叫點：`load_or_import_touched()` 與 `touched record` 的 command handler。`load_or_import_touched()` 又被 `ensure_touched()`、`mark_task_done()`（經由 `ensure_touched()`）與 `.cash-skills/lib/cash_cli/commands/archive.py` 的 `archive_change()` 呼叫。

**現行寫入時機（本設計的關鍵約束）。**

- `ensure_touched()` 在 `workspace.exists(relative)` 為真時 `return value`，**零寫入**；只有 state 檔不存在時才建立並寫入。
- `touched record` 的 handler 以 `items = list(touched["touched"])` 取得 **shallow copy**，其條目與 `touched` 共用同一批 dict 物件，最後以 `if updated != touched:` 決定是否寫入。就地改寫條目內容的操作在 `updated` 與 `touched` 兩側同步可見，該比較恆為 False。
- `mark_task_done()` 必然寫入。

因此「在記憶體中對齊、依賴既有寫入路徑落地」是不成立的：`ensure_touched()` 與 `touched record` 都不會把對齊結果寫回磁碟。

**消費端直接讀檔。**

`.claude/skills/cash-commit/SKILL.md` 步驟 2 先執行 `"$cash_cli" touched ensure "<change-name>"`，`If ensure fails, report the error and STOP`，**然後直接 parse `.cash-skills/state/touched/<change-name>.json`**，不再經過 CLI。因此只有寫回磁碟的對齊才能修正 `cash-commit` 顯示的 per-task 歸屬；而因為 ensure 在 parse 之前執行，把落地時機放在 `ensure_touched()` 即可涵蓋該消費端。

**既有 master requirement 的約束。**

`openspec/specs/cash-cli/spec.md` 的 `touched record 記錄 review loop 產出` 逐字要求 `touched record`「MUST NOT 改動任何既有 per-task 條目」且「合併結果與載入值相同時 MUST NOT 寫入」。本變更讓該 command 改寫既有條目的 `task_id`，因此 MUST 以 MODIFIED 修訂該 requirement，不能只用 ADDED。

`Change 與 artifact lifecycle` 定義 touched schema 與 `touched ensure` 的建立行為，但沒有任何一句禁止 ensure 在 state 已存在時寫入。該 requirement 另有一句 `` `cash-commit` MUST在建立source allowlist前呼叫ensure，archive MUST在其transaction內執行相同ensure ``——本設計的解讀是「相同 ensure」指的是同一個 import／建立語意，而非兩處必然產生相同的寫入行為；`archive_change()` 隨即在同一 transaction 內刪除該 state，因此對齊在 archive 側是否落地沒有可觀察差異。此解讀記於此處，不另做 MODIFIED。本變更對 ensure 增加的是修復性寫入，不改 schema、不改 `legacy_import` 保留規則、不改「Cash state 一旦存在即為唯一權威」，因此不需要 MODIFIED。

`Archive manifest 保留 touched 檔案清單` 要求 `touched_digest`「其計算輸入與計算方式 MUST 不變」。本設計的解讀是：計算輸入指「封存當下的 touched 物件」這個來源、計算方式指 sha256 演算法，兩者皆不變；對齊改變的是該物件本身的內容，與該 requirement 要約束的對象不同。`touched_files` 來自頂層 `files` 聯集，對齊不改動聯集，因此「不另行重新排序或去重」也不受影響。此解讀記於此處，不另做 MODIFIED。

**與 `default-spec-sync-on-archive` 的相依。**

該 change 已通過其 apply 品質關卡但尚未提交或封存，其工作樹修改包含 `.claude/skills/cash-archive/SKILL.md`、`.claude/skills/cash-commit/SKILL.md`、`.agents/skills/cash-archive/SKILL.md`、`.agents/skills/cash-commit/SKILL.md`、`cash-skills.version`（`2.13.0` → `2.14.0`）、`.cash-skills/lib/cash_cli/installer.py` 與 `.cash-skills/manifest.tsv` 共七個路徑。本變更的 `## Impact` 涵蓋這七個路徑的全部。

## Goals / Non-Goals

**Goals**

- `cash-archive` 的未完成 task 分支有可到達的出口，且在提問層與執行層都與 `cash-commit` 6a-i／6a-iii 對稱。
- `cash-archive` 對 `tasks_incomplete` 有明確且有效的出路指引。
- touched state 的 per-task attribution 在 `tasks.md` 增刪條目後指向正確的 task，且該修正**寫回磁碟**，使直接讀檔的消費端也取得正確視圖。
- 對齊不銷毀漂移證據。
- 描述在 `tasks.md` 中查無此項時 fail closed，且該失敗在三個撞擊點中落在本變更範圍內的兩個（`cash-commit` 步驟 2 與 `cash-archive` 步驟 5）都有復原指引。

**Non-Goals**

- 不改變 task id 的產生方式，不引入穩定 id。
- 不改變 `archive` 對 `tasks_incomplete` 的 CLI 行為、錯誤碼或拋出時機。
- 不改動 `cash-commit` 的 6a-i。
- 不改動 `cash-archive` 的 `**Output On Success With Warnings**` 模板的行組成——`default-spec-sync-on-archive` 的 design D5 明訂該區塊的行組成 MUST NOT 改動。`- Archived with 3 incomplete tasks` 那一行在本變更之後仍不可到達，處置留待後續 change。
- 不新增獨立的 migration 或修復 command。
- 不改變 `task_desc` 的產生方式或語意。

## Decisions

**D1：對齊掛在 `load_or_import_touched()` 之後，不動 `_validate_touched()` 的簽章。**
`_validate_touched()` 是純粹的 shape／canonical 驗證，沒有 `Workspace` 參數。為它加上 workspace 會讓純函式取得檔案系統存取並波及 `touched record` 的呼叫點。改為新增獨立 helper 並在 `load_or_import_touched()` 完成 `_validate_touched()` 之後呼叫；`touched record` handler 另行呼叫同一個 helper。

**D2：以 `task_desc` 反推 `task_id`，而非以位置反推 `task_desc`。**
`task_desc` 是 `tasks.md` 中該 task 描述的逐字複本，是語意錨點；`task_id` 是位置索引，是衍生值。插入或刪除條目只改變位置、不改變描述，因此「描述 → 目前位置」對位移有唯一正確解。
反方向（依位置改寫 `task_desc`）MUST NOT 採用：它銷毀唯一的漂移證據，並把原屬於某個 task 的檔案清單重新標記到另一個 task 名下。在 `default-spec-sync-on-archive` 的實例中，`task_id: "1"` 配 `task_desc: "1.1 …"`、files 含 `.claude/skills/cash-archive/SKILL.md`；依位置改寫會把該檔標記成 `1.0 依 IC6 調升 bundle version` 的產出。

**D3：描述查無此項時 fail closed，不猜測。**
描述在 `tasks.md` 中找不到，代表該 task 被刪除或其描述被改寫。位置式 id 無法區分這兩者，任何自動處置都可能把錯誤配對簽為合法。因此以既有的 `touched_invalid` 失敗類別回報，訊息 MUST 包含該 `task_desc`。與 D2 的自動對齊互斥且窮盡：描述找得到走對齊，找不到走 fail closed。

**D4：對齊結果 MUST 寫回磁碟。**
記憶體內對齊無法達成本變更的目的：`cash-commit` 直接 parse state 檔（見 `## Context`），而漂移的實際發生時點是「全部 task 已 `[x]` 之後的 review round」，此後不會再有 `task done` 觸發寫入。因此：

- `ensure_touched()` MUST 在對齊改變了內容時把對齊後的值寫回，即使 state 檔已存在。這是本設計唯一新增的寫入時機。`cash-commit` 步驟 2 在 parse 之前先呼叫 ensure，因此該消費端自動取得已對齊的檔案內容。
- `touched record` handler MUST 以「對齊是否改變內容」與既有的 `updated != touched` 兩者的**或**決定是否寫入。單靠既有比較不足：依 IC4 第 3、5 點，handler 取得的 `touched` 已是對齊後的物件，而 `updated` 由它衍生——當 `--path` 的合併是 no-op 時 `updated == touched`，該比較恆為 False，即使對齊相對於磁碟內容已有差異。（`## Context` 記錄的 shallow-copy 同步可見是對齊前的既有程式碼性質；IC4 第 2 點的深層複本要求已使就地改寫不再是合法手段，故不能再以它作為本條的理由。）
- `mark_task_done()` 既有的寫入本來就必然發生，使用對齊後的值即可。它經由 `ensure_touched()` 取值，因此對齊改變內容時該路徑會先 commit 一次修復性寫入、再由 `mark_task_done()` 自己的 transaction 整份覆寫，`task done` 由單一 commit 變為兩次。MUST NOT 為此新增抑制分支：對齊是冪等的修復，兩次 commit 之間中斷所留下的「已對齊但 `tasks.md` 未標記完成」是一個合法且可重跑的狀態，為避免多餘寫入而在 `mark_task_done()` 繞過 `ensure_touched()` 反而會製造第二條需要各自維護的取值路徑。
- `archive_change()` 只讀取，取得對齊視圖但不因此產生額外寫入。

**D5：`tasks.md` 取不到或解析失敗時原樣回傳。**
對齊需要 `tasks.md` 作為輸入。取不到時 MUST 原樣回傳而非失敗：

- `openspec/changes/<name>/tasks.md` 不存在時，MUST 再查 `openspec/changes/.parked/<name>/tasks.md`——`park` 會把整個 change 目錄搬到該處而不動 touched state，且 `cash-commit` 步驟 2a 明確支援 parked change。兩者皆不存在才原樣回傳。
- 讀取或解析 `tasks.md` 的**任何**失敗 MUST 捕捉並原樣回傳，MUST NOT 讓該錯誤從對齊路徑逸出。這涵蓋 `_task_entries()` 的 `task_id_invalid`（標籤缺失或重複）、`tasks.md` 為 symlink 時 `workspace.exists()` 的 `unsafe_path`、內容非 UTF-8 時的 `invalid_encoding`、以及 `tasks.md` 是目錄時的讀取失敗。理由對全部情形一致：對齊是修復手段而非閘門，`tasks.md` 的格式良好性由 `validate_change()` 負責，而 `--no-validate` 是使用者對該閘門的明示 opt-out；讓對齊把原本完全不讀 `tasks.md` 的 `touched ensure`、`touched record` 或 `archive --no-validate` 從成功轉為失敗，是本變更不打算引入的回歸。

不得以「非保留條目只可能由 `mark_task_done()` 建立、而它必先讀 `tasks.md`」推論此情形不會發生——`park` 與 legacy import 都是反例。

**D6：legacy import 來源的 state 豁免 D3。**
`legacy_import` 非 `null` 代表該 state 由 `.spectra/touched/<name>.json` 匯入，其 `task_desc` 從未由本專案的 `tasks.md` 產生，D3「描述是 `tasks.md` 的逐字複本」這個前提不成立。對這類 state，對齊 MUST 只做描述對得上的 id 改寫，描述查無此項時 MUST 保留該條目原樣而 MUST NOT fail closed。
把 legacy 路徑排除在對齊之外（而非豁免 D3）無法達成目的：`ensure_touched()` 在 state 檔不存在時會立刻把匯入結果落地，此後任何一次讀取都命中既有 state 路徑並套用對齊，因此排除只把 fail closed 延後一次呼叫，實際效果是該 change 從第二個指令起永久卡死。豁免以 `legacy_import` 這個既有欄位為判準，是持久的而非一次性的。

**D7：對齊後 MUST 重新檢查 id 唯一性與排序。**
改寫 `task_id` 之後兩個條目有可能被指派到同一個位置。`_task_entries()` 的標籤唯一性使正常情形下不可能，但對齊的輸入是持久化狀態而非該函式的輸出，因此不能假設；`legacy_import` 為 `None` 時發生 MUST 以 `touched_invalid` fail closed。
`legacy_import` 非 `None` 時 MUST 改為放棄整次對齊並原樣回傳：D6 保留原樣的條目仍帶著陳舊 `task_id`，該 id 可能與另一條目對齊後的新 id 相撞，若照 fail closed 處理，該 change 會從第二個指令起永久卡死——正是 D6 存在的目的所要避免的。放棄對齊使該 state 維持其既有的可用狀態。此處的正確性依賴 IC4 第 2 點要求的「在深層複本上運作」：唯有回傳未被改寫污染的原輸入，`_validate_touched()` 對它的唯一性檢查才仍然成立，才不會有重複 id 經由 `mark_task_done()` 的無條件寫入落地。對齊後 MUST 依 `task_id` 的 UTF-8 bytes 重新排序，與 `mark_task_done()` 既有的排序一致。

**D8：新失敗模式在本變更範圍內的每個撞擊點都要有復原指引。**
D3 的 fail closed 有三個撞擊點：`cash-commit` 步驟 2（`If ensure fails, report the error and STOP`）、`cash-archive` 步驟 5（`archive_change()` 經 `load_or_import_touched()` 取值，見 `## Risks / Trade-offs` 第二項）、以及 `cash-apply` 的每次 `task done`，而 `/cash-ingest` 改寫 `tasks.md` 的描述正是觸發它的常見途徑。本變更為 `tasks_incomplete` 補了指引卻不為自己新造的失敗模式補，是不對稱的。因此 `cash-commit` 步驟 2 與 `cash-archive` 步驟 5 都 MUST 增加 `touched_invalid` 的復原指引，且 MUST 先區分 renamed 與 removed task：renamed task 才把 touched state 中的 `task_desc` 同步為 `tasks.md` 的新描述；removed task MUST 停止目前流程並引導使用者執行無參數 `/cash-ingest`，把目前的 `touched_invalid` 與 change name 作為 conversation context，使 ingest 選取既有 change 並把 touched entry 保存的原 `task_desc` 恢復為 `tasks.md` 中已完成的 `[x]` task。前者是唯一允許的 touched state 手工編輯；後者不得編輯或刪除 touched entry，因為其 `files` 仍歸屬該歷史 task。`cash-apply` 是本變更範圍內唯一的例外：`.claude/skills/cash-apply/SKILL.md` 是裁判面保護路徑、未列入 `## Impact`，故不在此義務內，該不對稱記於 `## Risks / Trade-offs`。

**D9：`tasks_incomplete` 的出路只有一條。**
`archive.py` 的 `tasks_incomplete` 由 `not mark_tasks_complete` 單獨守門，`--skip-specs` 與 `--no-validate` 都不影響它。步驟 5 的失敗處置 MUST 只列 `--mark-tasks-complete` 這一條出路並明寫另兩個旗標不繞過，避免重蹈 `default-spec-sync-on-archive` 中「列出對該錯誤無效的出路」的覆轍。

**D10：既有測試 MUST 隨對齊一併更新。**
`scripts/cash-cli/tests/` 有三個既有測試的 fixture `task_desc` 與其 `tasks.md` 不一致，套用對齊後會走 D3 或使 digest 斷言不符。這些測試是本變更的交付範圍的一部分，MUST 列入 `## Impact` 與 task 的交付目標。

**D11：先提交或封存 `default-spec-sync-on-archive` 再實作本變更。**
詳見 `## Risks / Trade-offs`。

**D12：removed task 以恢復完成紀錄解決，不新增 touched identity。**
非 legacy 的 per-task touched entry 只會由 `mark_task_done()` 建立，因此其 `task_desc` 指向一個曾經完成、之後才從 `tasks.md` 消失的歷史 task。安全復原 MUST 把該 exact `task_desc` 恢復為 `tasks.md` 的 `[x]` task，再由既有 attribution 對齊重新推導位置式 `task_id`；touched entry 的 `task_desc` 與 `files` 全程不變。這同時恢復 ingest 應保留 completed task 的 artifact history，不需要 tombstone、stable id 或新 command。此處 MUST 使用無參數 `/cash-ingest`，並把目前的 `touched_invalid` 與 change name 作為 conversation context，讓 ingest 依既有流程選取 change；不得把 change name 當作 argument，因為 cash-ingest 的 argument contract 是 plan file。若 exact `task_desc` 的 task label 已被另一條 task 佔用，skill MUST 停止並要求先由同一個無參數 `/cash-ingest` context 解決 artifact label 衝突，MUST NOT 猜測新 label 或重新歸屬 `files`。

## Implementation Contract

**IC1 — `.claude/skills/cash-archive/SKILL.md` 步驟 3**

1. 步驟 3 的 `**If incomplete tasks found:**` 分支 MUST 替換為下列逐字內容。fence 內容已含步驟 3 內文的基準縮排（相對 fence 為 3 空格，巢狀選項行相對 fence 為 5 空格；對應 `design.md` 原始位元組中的 6 空格與 8 空格，插入 `.claude/skills/cash-archive/SKILL.md` 後為 3 空格與 5 空格），插入時 MUST 原樣沿用，MUST NOT 拉齊到 column 0——那會把該分支抽出 numbered list item 而破壞區塊結構：

   ```
      **If incomplete tasks found:**
      - Display warning showing count of incomplete tasks
      - Use the **AskUserQuestion tool** to ask: "These tasks are still incomplete. Mark all as complete before archiving?"
        - **Yes**: set a flag to pass `--mark-tasks-complete` to the archive command in step 5
        - **No**: stop without archiving; do not invoke archive with incomplete tasks
   ```

2. 原有的 `- Prompt user for confirmation to continue` 與 `- Proceed if user confirms` 兩行 MUST 從步驟 3 消失。
3. 步驟 2 的 `**If any artifacts are not `done`:**` 分支（含其同名的兩行）MUST NOT 改動——那是另一個提問，不在本變更範圍。

**IC2 — `.claude/skills/cash-archive/SKILL.md` 步驟 5**

1. 步驟 5 的 bash 範例 MUST 增加一行 `"$cash_cli" archive <name> --mark-tasks-complete`，使步驟 3 解析出的旗標在執行層可見。既有的兩行 MUST 原樣保留。沒有這一行，步驟 5 開頭的 `adding the resolved flags` 在本檔中沒有任何指向 `--mark-tasks-complete` 的落點，執行者照抄範例會把旗標弄丟，delta spec 的「與 `cash-commit` 對稱」也只在提問層成立。
2. 步驟 5 的失敗處置 MUST 增加一條，逐字為 `**If archive fails** with `tasks_incomplete`, report the exact error and re-run with `--mark-tasks-complete`; neither `--skip-specs` nor `--no-validate` bypasses this precondition.`
3. 該條 MUST 緊接在既有 `validation_failed` 那一條之後，使步驟 5 內的失敗處置彼此相鄰。
4. 步驟 5 的失敗處置 MUST 再增加一條 `touched_invalid` 的復原指引，逐字為 `**If archive fails** with `touched_invalid` naming a `task_desc` that no longer exists in `tasks.md`, determine whether that task was renamed or removed. If renamed, update that entry's `task_desc` in `.cash-skills/state/touched/<name>.json` to the task's current description, then re-run archive. Editing `task_desc` to repair a rename is the one permitted manual edit to touched state; never delete the file. If removed, stop and run `/cash-ingest` with the current `touched_invalid` error and change name as conversation context so it selects the existing change and restores the exact `task_desc` as a completed `[x]` task in `tasks.md`, then re-run archive; do not edit or delete the touched entry, because its `files` remain attributed to that historical task.` 該條 MUST 置於第 2 點的 `tasks_incomplete` 那一條之後。這兩個分支 MUST 互斥：只有存在 current description 時走 rename 分支；沒有 current description 時走 removed 分支。若恢復 exact `task_desc` 會造成 task label 衝突，MUST 由無參數 `/cash-ingest` 與相同 conversation context 先解決 artifacts，MUST NOT 猜測新 label 或重新歸屬 `files`。
5. 步驟 5 的 Optional flags 清單與既有三條失敗處置的文字 MUST NOT 改動。

**IC3 — `.claude/skills/cash-commit/SKILL.md` 步驟 2**

1. 步驟 2 中 `If ensure fails, report the error and STOP.` 之後 MUST 增加 `touched_invalid` 的復原指引。步驟 2 是 numbered list item，其內文縮排為 3 空格，插入時 MUST 沿用該縮排，MUST NOT 拉齊到 column 0——那會把該段抽出 list item 而破壞區塊結構。指引內容逐字為 `If ensure fails with `touched_invalid` naming a `task_desc` that no longer exists in `tasks.md`, determine whether that task was renamed or removed. If renamed, update that entry's `task_desc` in `.cash-skills/state/touched/<change-name>.json` to the task's current description, then re-run ensure. Editing `task_desc` to repair a rename is the one permitted manual edit to touched state; never delete the file. If removed, stop and run `/cash-ingest` with the current `touched_invalid` error and change name as conversation context so it selects the existing change and restores the exact `task_desc` as a completed `[x]` task in `tasks.md`, then re-run ensure; do not edit or delete the touched entry, because its `files` remain attributed to that historical task.` 這兩個分支 MUST 互斥，且 label 衝突時 MUST 由無參數 `/cash-ingest` 與相同 conversation context 解決 artifacts，MUST NOT 猜測新 label 或重新歸屬 `files`。
2. 步驟 2 的其餘內容、Expected format 區塊與步驟 2a MUST NOT 改動。

**IC4 — `.cash-skills/lib/cash_cli/commands/tasks.py`**

1. 新增模組層級常數，逐字為 `_RESERVED_TASK_ID = "review-loop"`，並把 `touched record` handler 中**全部**既有的 `"review-loop"` 字面值改用該常數（現有兩處：比較用的與建立保留條目用的）。改動後全檔 `"review-loop"` 字面值 MUST 恰好只剩常數定義行那一處。
2. 新增函式 `_realign_touched_attribution(workspace: Workspace, name: str, touched: dict[str, object]) -> tuple[dict[str, object], bool]`，回傳（對齊後的物件，是否改變了內容）。行為如下：
   - 依序嘗試 `openspec/changes/<name>/tasks.md` 與 `openspec/changes/.parked/<name>/tasks.md`；兩者皆不存在時 MUST 回傳 `(touched, False)`（D5）。
   - 以既有的 `_task_entries()` 解析取得的內容，建立「描述 → 位置式 id」映射。讀取或解析 `tasks.md` 的**任何**失敗 MUST 捕捉並回傳 `(touched, False)`，MUST NOT 逸出——涵蓋 `_task_entries()` 的 `task_id_invalid`、`tasks.md` 為 symlink 時 `workspace.exists()`／`read_text()` 的 `unsafe_path`、內容非 UTF-8 的 `invalid_encoding`、以及 `tasks.md` 是目錄時的讀取失敗（D5）。該捕捉範圍 MUST 只包住路徑探測（`workspace.exists()`）、讀取（`read_text()`）與 `_task_entries()` 解析這三個動作，MUST NOT 包住下方對齊迴圈依 D3／D7 自行拋出的 `touched_invalid`。路徑探測 MUST 納入：`workspace.exists()` 經 `path_kind()` 對 symlink 直接拋 `unsafe_path`，發生在任何讀取之前，只包住後兩個動作會使該錯誤逸出而違反本 bullet 自身的規定。
   - 對齊 MUST 在輸入的深層複本上運作（例如 `copy.deepcopy(touched)`，或重新建構 `touched` list 與其條目 dict），MUST NOT 就地改寫傳入的物件。放棄分支要回傳「未被任何改寫污染的原輸入」，而就地改寫會使該原輸入不復存在——`mark_task_done()` 以 `items = list(touched["touched"])` 取 shallow copy 後無條件寫檔，被污染的重複 id 會就此落地，下一次讀取時 `_validate_touched()` 即以 `touched_invalid` 拒絕，正是 D6／D7 要避免的永久卡死。
   - 對複本中每個 `task_id != _RESERVED_TASK_ID` 的條目：其 `task_desc` 在映射中且對應 id 與現存 `task_id` 不同時 MUST 改寫該複本條目的 `task_id`（D2）；不在映射中時，若 `touched["legacy_import"]` 為 `None` MUST 以 `CashError("touched_invalid", ...)` 失敗且訊息 MUST 包含該 `task_desc`（D3），若非 `None` MUST 保留該條目原樣並繼續（D6）。
   - MUST NOT 改寫任何條目的 `task_desc`（D2）。
   - `changed` flag MUST 涵蓋重新排序：僅 `touched` 陣列順序改變而每個條目內容不變時，`changed` 仍 MUST 為 `True`，因為持久化的 bytes 會不同。
   - 全部條目處理完畢後 MUST 檢查 `task_id` 唯一性。`touched["legacy_import"]` 為 `None` 時，重複 MUST 以 `CashError("touched_invalid", ...)` 失敗（D7）。非 `None` 時，重複代表某個依 D6 保留原樣的 legacy 條目其陳舊 `task_id` 與另一條目對齊後的新 id 相撞，此時 MUST 丟棄該複本、回傳 `(touched, False)`——即未被任何改寫污染的原輸入——MUST NOT 失敗（D6）。通過唯一性檢查後 MUST 依 `task_id` 的 UTF-8 bytes 重新排序（D7）。
   - MUST NOT 自行寫入任何檔案；落地由呼叫端負責（D4）。
3. `load_or_import_touched()` 的既有 state 路徑 MUST 改為先 `_validate_touched()` 再 `_realign_touched_attribution()`，回傳對齊後的物件。legacy import 與新建空 state 兩條路徑不呼叫對齊——前者的條目在落地後會於下一次讀取時經由既有 state 路徑取得 D6 的豁免對齊，後者沒有條目。
4. `ensure_touched()` MUST 改為：state 檔已存在時，若 `load_or_import_touched()` 這一趟的對齊改變了內容，MUST 把對齊後的值寫回該檔並回傳；未改變時維持現行的零寫入直接回傳（D4）。為取得「是否改變」，`ensure_touched()` MUST 能得知本趟對齊是否改變內容。`load_or_import_touched()` 的公開簽章與回傳形狀 MUST NOT 改變——`.cash-skills/lib/cash_cli/commands/archive.py` 以 `touched = load_or_import_touched(workspace, name)` 取值後直接當 dict 使用（`touched["files"]`、傳入 `_legacy_cleanup()`、序列化計算 digest），而 `archive.py` 不在本變更的 `## Impact` 內、亦無任務授權修改它。實作手段因此限於不改變該公開形狀者：MUST 抽出一個回傳 `tuple[dict[str, object], bool]` 的內部 helper，由 `load_or_import_touched()` 與 `ensure_touched()` 各自取用——前者只取第一元素以維持公開形狀，後者取 flag 決定是否寫回。該 helper MUST 定義於 `load_or_import_touched()` 與 `ensure_touched()` 兩個 `def` 之間，而 `_realign_touched_attribution()` 本身 MUST 定義於 `load_or_import_touched()` **之前**。位置是規範的一部分：tasks 中以該區間為範圍的 awk 判準比對的是 `_realign_touched_attribution(` 這個字面值，若把該函式的 `def` 行也放進區間內，判準會被定義行自身滿足而對「對齊確實被接上讀取路徑」失去鑑別力。

   MUST NOT 改為「由 `ensure_touched()` 自行再呼叫一次 `_realign_touched_attribution()` 取得 flag」：`ensure_touched()` 的值來自 `load_or_import_touched()`，而第 3 點已要求該路徑先行對齊，對已對齊的物件再跑一次對齊必然回報未改變，修復性寫入將永遠不發生——而該實作仍能通過 tasks 的全部字面值與計數判準。
5. `touched record` handler MUST 在 `_validate_touched()` 之後呼叫 `_realign_touched_attribution()`，並把寫入條件由 `if updated != touched:` 改為「對齊改變了內容 **或** `updated != touched`」（D4）。
6. `mark_task_done()` 對既有條目「只 union `files`、不改動 `task_desc`」的行為 MUST NOT 改動；`_validate_touched()` 的簽章與函式體 MUST NOT 改動。

**IC5 — 既有測試同步**

以下既有測試的 fixture `task_desc` 與其 `tasks.md` 不一致，MUST 隨本變更更新為與 `tasks.md` 逐字一致的描述（或依 D6 改為 legacy 情境），使套用對齊後仍然通過：

- `scripts/cash-cli/tests/test_creation_task_lifecycle.py` 的 `test_touched_record_preserves_existing_task_order`（fixture 寫入 `Task 1`..`Task 10`，而其 `tasks.md` 只有兩個 task）。
- `scripts/cash-cli/tests/test_creation_task_lifecycle.py` 的 `test_legacy_import_is_validated_once_and_provenance_is_preserved`（`task_desc: "Change a"` 不等於 `1.1 Change a`；本例落在 D6 的豁免範圍，MUST 驗證豁免生效而非 fail closed）。
- `scripts/cash-cli/tests/test_sync_archive_transaction.py` 的 `test_archive_manifest_records_touched_files`（`task_desc` 與 fixture 的 `tasks.md` 不一致；其 `touched_digest` 斷言亦 MUST 依對齊後的物件重算）。

`scripts/cash-cli/tests/cli-checks.fish` MUST NOT 改動——它以 `test_*.py` glob 自動探索，新增案例不需改它，且它是裁判面保護路徑。

**IC6 — 新測試案例**

`cash-cli` delta spec **`## ADDED Requirements` 之下**的每一條 scenario MUST 在 `scripts/cash-cli/tests/test_creation_task_lifecycle.py` 有一個對應的測試方法。`## MODIFIED Requirements` 下沿用既有行為的 11 條 scenario（其中兩條僅補上「對齊不改變任何內容」的 GIVEN）描述的是既有行為、已有既有測試覆蓋，MUST NOT 要求為它們新增 `test_realign_` 方法，方法名 MUST 以 `test_realign_` 為前綴，使其存在性可機械比對。

**IC7 — 變體重新生成**

- `.agents/skills/cash-archive/SKILL.md` 與 `.agents/skills/cash-commit/SKILL.md` MUST 由在專案根執行 `scripts/cash-skills/generate.fish` 產生，MUST NOT 手工編輯。
- 生成後兩組變體在正規化 invocation 前綴後，被改寫的段落 MUST 完全相同。

**IC8 — bundle version bump**

- 修改 `SKILL.md` 或 `.cash-skills/lib/` 下的檔案會觸發 bundle version history contract，要求 `cash-skills.version` 嚴格領先 HEAD 的值。實作時 MUST 以 HEAD 當下的值為準決定新版本號並採 minor bump，MUST NOT 寫死版本號。
- `.cash-skills/lib/cash_cli/installer.py` 的 `BUNDLE_VERSION` MUST 與 `cash-skills.version` 一致。
- `.cash-skills/manifest.tsv` MUST 以 `PYTHONPATH=.cash-skills/lib python3 -s -P -B -m cash_cli.installer --self` 重建。
- 此 bump MUST 排在第一個受版本守衛檔案的修改之前，且每次修改 `SKILL.md` 或 `.cash-skills/lib/` 下的檔案之後 MUST 重跑該 `--self` 指令。

**IC9 — spec delta**

- capability `cash-skill-workflows` 的 delta 含兩個 `## ADDED Requirements` 條目。其一定義 `cash-archive` 未完成 task 的兩分支處置、旗標在執行層可見、`tasks_incomplete` 的失敗指引、`touched_invalid` 的復原指引，以及該 skill 兩個變體的對等。其二獨立定義 `cash-commit` 對 `touched_invalid` 的復原指引與該 skill 兩個變體的對等——Requirement 標題是合併身分鍵，把 `cash-commit` 的義務掛在 `cash-archive` 標題之下會使該義務日後難以定位與修訂。
- capability `cash-cli` 的 delta 含一個 `## ADDED Requirements` 條目與一個 `## MODIFIED Requirements` 條目。ADDED 定義對齊的方向、`task_desc` 不得改寫、保留條目豁免、描述查無此項時 fail closed、legacy 豁免、`tasks.md` 取不到或解析失敗時原樣回傳，以及對齊結果 MUST 寫回磁碟。MODIFIED 的 `### Requirement: touched record 記錄 review loop 產出` 標題 MUST 從 `openspec/specs/cash-cli/spec.md` 逐字複製，並把「MUST NOT 改動任何既有 per-task 條目」限縮為「MUST NOT 改動既有條目的 `task_desc` 與 `files`」、把「合併結果與載入值相同時 MUST NOT 寫入」限縮為「合併結果與載入值相同且對齊未改變內容時 MUST NOT 寫入」。

**IC10 — 驗證**

- 在專案根執行 `scripts/cash-skills/tests/skill-checks.fish`，MUST 全數通過。該套件需要 `rg`（ripgrep）與 `fish`。
- 在專案根執行 `scripts/cash-cli/tests/cli-checks.fish`，MUST 全數通過。
- 執行 `.cash-skills/bin/cash validate guard-task-state-integrity`，MUST 通過。

## Risks / Trade-offs

- **與 `default-spec-sync-on-archive` 的檔案衝突。** 該 change 已通過 apply 品質關卡但尚未提交或封存，其未提交的工作樹修改包含本變更要修改的七個路徑：`.claude/skills/cash-archive/SKILL.md`、`.claude/skills/cash-commit/SKILL.md`、`.agents/skills/cash-archive/SKILL.md`、`.agents/skills/cash-commit/SKILL.md`、`cash-skills.version`、`.cash-skills/lib/cash_cli/installer.py` 與 `.cash-skills/manifest.tsv`。在該 change 提交之前實作本變更，兩者的修改會混在同一份未提交的工作樹中，`cash-commit` 的 touched 允許清單無法把它們分開，且已通過 gate 的交付內容會被污染。緩解是排序而非機制：MUST 先完成 `default-spec-sync-on-archive` 的 `/cash-commit`，再開始本變更的 apply。task 0.1 的乾淨工作樹閘門 MUST 涵蓋全部七個重疊路徑——少列任何一個，該路徑就會在仍髒的情況下被本變更的 task 編輯，正是此閘門要防止的傷害。IC8 之所以不寫死版本號，正是因為 HEAD 會在該提交之後由 `2.13.0` 變為 `2.14.0`。
- **對齊會把 `archive` 路徑上既有的成功轉為失敗。** `archive_change()` 經由 `load_or_import_touched()` 取得 touched state，因此描述查無此項的漂移會使原本能成功的封存改為以 `touched_invalid` 失敗。這是刻意的 fail closed：帶著錯誤 attribution 完成封存會把錯誤的 `touched_files` 寫進 `archive-manifest.json`，而該欄位是 `cash-commit` 封存後復原路徑的唯一來源。D5 已把 `task_id_invalid` 這條非預期的轉換排除（捕捉後原樣回傳），因此本項只涵蓋 `touched_invalid` 一種。
- **fail closed 需要使用者判定 renamed 或 removed。** 本變更不提供修復 command（見 `## Non-Goals`），因為 CLI 無法從位置式 id 安全區分兩者。Renamed task 的出路是手工同步 `task_desc`；removed task 的出路是以 `/cash-ingest` 恢復 exact completed task，且不得修改 touched entry。判錯分支會使 attribution 被錯誤簽認，因此 skill MUST 以是否存在可確認的 current description 為邊界。`cash-apply` 的 `task done` 路徑沒有對等指引——那裡撞到 `touched_invalid` 時，使用者只能自行對照 `cash-commit` 的說明。這是已知不對稱；不擴大到 `cash-apply` 是因為那份 SKILL.md 是裁判面保護路徑，未列入本變更的 `## Impact`。
- **`touched_digest` 會因對齊而改變。** 同一份 state 在對齊前後產出不同的 `touched_digest`，因為該 digest 對整個 touched 物件計算。既有 requirement 要求的是計算輸入與方式不變，本設計在 `## Context` 記錄了該解讀。若後續判定該解讀不成立，`Archive manifest 保留 touched 檔案清單` 需要一筆 MODIFIED。
- **`task_desc` 作為錨點依賴描述文字不變。** 使用者若只改寫某個 task 的描述文字而不改其位置與意圖，D3 會判為查無此項並 fail closed，即使實際上沒有漂移。這是刻意取捨：位置式 id 之下無法區分「描述被改寫」與「條目被刪除並新增另一條」，後者若被誤判為前者會造成錯誤的檔案歸屬。`/cash-ingest` 改寫 `tasks.md` 正是會觸發此情形的常見途徑。
- **legacy 豁免使該類 state 永久不受 D3 保護。** D6 以 `legacy_import` 非 `null` 為判準，而該欄位一旦寫入就永久保留，因此由 legacy 匯入的 change 即使其後全部條目都經 `mark_task_done()` 重寫，仍然享有豁免。代價是這類 change 的 attribution 漂移不會被偵測；收益是 legacy 匯入不會從第二個指令起永久卡死。
