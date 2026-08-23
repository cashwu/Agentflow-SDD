## Summary

補上兩個「狀態或錯誤處理的缺口沒有機械守門」的漏洞：`cash-archive` 在使用者確認要帶著未完成 task 繼續之後必然硬失敗且無出路指引；`.cash-skills/state/touched/<name>.json` 的 per-task attribution 以位置式 task id 為鍵，`tasks.md` 增刪條目就會整體錯位，而現行驗證從不比對該鍵與 `tasks.md`，漂移完全靜默。

## Motivation

兩個缺口都由 `default-spec-sync-on-archive` 的 apply review round 4 查出，記於該 change 的 `reviews/apply-r4.md` findings 2 與 3。

**其一：`cash-archive` 的未完成 task 路徑是死路。**

`cash-archive` 步驟 3 偵測到未完成 task 時只做 `Prompt user for confirmation to continue` 與 `Proceed if user confirms`，整份 SKILL.md 沒有任何一句把該確認接到 `--mark-tasks-complete`。使用者確認繼續之後，步驟 5 呼叫的 `archive` 會以 `tasks_incomplete` 失敗，而步驟 5 的失敗處置目前只涵蓋 `archive_collision`、delta parse／`requirement_identity_mismatch` 與 `validation_failed` 三類，沒有 `tasks_incomplete` 的出路指引。使用者因此在「被問要不要繼續 → 回答繼續 → 硬失敗 → 沒有下一步提示」之間空轉。

同一情境在 `cash-commit` 的 archive-first 子流程是被正確處理的：6a-i 的提問明確把 Yes 對應到「set a flag to pass `--mark-tasks-complete`」，No 對應到取消子流程。兩個封存入口對同一個 CLI 前置條件的處理不對稱。

連帶後果是 `cash-archive` 的 `**Output On Success With Warnings**` 模板中 `- Archived with 3 incomplete tasks` 這一行在本 skill 的路徑上不可到達——能走到成功輸出就代表 task 已完成或已被標記完成。

**其二：touched state 的 task attribution 沒有守門。**

`.cash-skills/lib/cash_cli/commands/tasks.py` 的 `_task_entries()` 以 `str(len(entries) + 1)` 產生 task id，因此 id 是位置式的。而 `_validate_touched()` 只檢查 shape、per-task canonical 排序與頂層 `files` 是否等於各條目的聯集，從不比對 `task_id`／`task_desc` 與 `tasks.md` 的現況；`mark_task_done()` 對既有條目只 union `files`，永不更新 `task_desc`。

結果是：在 `tasks.md` 插入或刪除任一 task 條目，就會使既有紀錄的 `task_id` 與 `task_desc` 整體錯位一位，而 `touched ensure` 仍然 rc 0、沒有任何工具會察覺。這不是假想情境——`default-spec-sync-on-archive` 的 review round 1 為修復宣告缺口而在 `tasks.md` 最前面插入 task `1.0`，實際造成 `task_id: "1"` 仍配 `task_desc: "1.1 …"`、位置 6 無紀錄、bump 三檔掛在 `2.1 執行 skill 套件檢查` 名下；該漂移是 reviewer 逐筆比對才發現的，已記為 signal `positional-id-state-desynced-by-list-insertion`。

檔案聯集不受影響，因此 archive-first 提交集合不會被污染；受影響的是 `cash-commit` 顯示的 per-task 歸屬，以及後續 `task done` 會依錯位的 id 覆寫錯誤的條目。

## Proposed Solution

1. `.claude/skills/cash-archive/SKILL.md` 步驟 3 的未完成 task 處置改為與 `cash-commit` 6a-i 對稱的兩分支：確認繼續即設定 `--mark-tasks-complete` 旗標，取消則不呼叫 archive。措辭以 `**AskUserQuestion tool**` 呈現兩個選項，與同檔步驟 1 的既有用法一致。
2. 同檔步驟 5 的失敗處置增加兩條：一條 `tasks_incomplete` 分支，指向以 `--mark-tasks-complete` 重跑並明寫 `--skip-specs` 與 `--no-validate` 都不繞過；一條 `touched_invalid` 分支，依 renamed／removed task 分流。Renamed task 才把 touched 條目的 `task_desc` 同步為現行描述；removed task 則停止封存並以無參數 `$cash-ingest`（把目前的 `touched_invalid` 與 change name 作為 conversation context）選取既有 change，把原 `task_desc` 對應的 task 恢復為 `[x]`，不得刪除或重新歸屬 touched entry。同檔步驟 5 的 command 範例增加帶 `--mark-tasks-complete` 的一行，使步驟 3 解析出的旗標在執行層可見。
3. `.agents/skills/cash-archive/SKILL.md` 與 `.agents/skills/cash-commit/SKILL.md` 由重新生成產生，MUST NOT 手工編輯。
4. 在 `.cash-skills/lib/cash_cli/commands/tasks.py` 增加一段 task attribution 對齊：以 `task_desc` 為語意錨點、`task_id` 為位置索引，對每個 `task_id` 不是保留值 `review-loop` 的條目，依目前 `tasks.md` 推導出的「描述 → 位置式 id」映射反推該條目應有的 `task_id`。描述找得到但 id 不符時（插入或刪除條目造成的整體位移）改寫該條目的 `task_id`；描述在 `tasks.md` 中完全找不到時（條目被刪除或改寫）以既有的 `touched_invalid` 失敗類別 fail closed，並在訊息中指出該 `task_desc`；但 `legacy_import` 非 `null` 的 state 豁免此 fail closed——其 `task_desc` 從未由本專案的 `tasks.md` 產生——該條目保留原樣。`tasks.md`（含 `.parked` 路徑）取不到或解析失敗時 MUST 原樣回傳，不使既有指令從成功轉為失敗。
5. 該對齊 MUST NOT 改寫任何既有條目的 `task_desc`。`task_desc` 是偵測漂移的唯一證據，改寫它會把原本屬於某個 task 的檔案清單重新標記到另一個 task 名下，等於把錯誤配對簽為合法。`mark_task_done()` 現行「只 union `files`、不動既有條目 `task_desc`」的行為因此 MUST 維持不變。
6. 對齊結果 MUST 寫回磁碟：`ensure_touched()` 在對齊改變內容時 MUST 寫回，`touched record` 的寫入條件 MUST 併入「對齊是否改變內容」。只在記憶體中對齊無法達成目的——`cash-commit` 直接 parse state 檔，而漂移的實際發生時點是全部 task 已 `[x]` 之後的 review round，此後不會再有 `task done` 觸發寫入。
7. `cash-commit` 步驟 2 與 `cash-archive` 步驟 5 都 MUST 增加 `touched_invalid` 的復原指引，明訂 renamed task 同步 `task_desc` 是唯一被允許的 touched state 手工修復；removed task MUST 改由無參數 `$cash-ingest`（把目前的 `touched_invalid` 與 change name 作為 conversation context）選取既有 change 並恢復原 task 為 `[x]`，以 `tasks.md` 的歷史紀錄承接 attribution，MUST NOT 編輯或刪除 touched entry。`cash-apply` 的 `task done` 是第三個撞擊點但不在本變更範圍內（裁判面保護路徑），該不對稱記於 design 的 `## Risks / Trade-offs`。
8. 既有測試中 fixture `task_desc` 與其 `tasks.md` 不一致的三個案例 MUST 隨本變更更新。
9. 修改 `SKILL.md` 或 `.cash-skills/lib/` 下的檔案會觸發既有的 bundle version history contract，因此 `cash-skills.version` MUST 調升、`.cash-skills/lib/cash_cli/installer.py` 的 `BUNDLE_VERSION` MUST 同步、`.cash-skills/manifest.tsv` MUST 重建。此 bump MUST 排在第一個受版本守衛檔案的修改之前。

## Non-Goals

- 不改變 task id 的產生方式。位置式 id 維持不變；本變更只補上偵測與自動修正，不引入穩定 id 或標籤式 id。改動 id 語意會影響 `touched record`、`archive-manifest.json` 與既有 state 的相容性，屬另一個決策。
- 不改變 `archive` 對 `tasks_incomplete` 的 CLI 行為。`--mark-tasks-complete` 的語意、拋出時機與錯誤碼全部維持不變；本變更只改 skill 側如何抵達與如何指引。
- 不改動 `cash-commit` 的 6a-i。它已經是正確的形態，本變更是讓 `cash-archive` 向它看齊。
- 不改動 `**Output On Success With Warnings**` 模板的行組成。`- Archived with 3 incomplete tasks` 那一行在本變更之後仍不可到達，但移除它會動到 `default-spec-sync-on-archive` 明訂 MUST NOT 改動的區塊；該行的處置留待後續。
- 不新增獨立的 migration 或修復 command。對齊在既有讀取路徑上就地發生，不提供一次性轉換工具。
- 不為 `cash-apply` 的 `task done` 路徑增加 `touched_invalid` 復原指引。`.claude/skills/cash-apply/SKILL.md` 是裁判面保護路徑，未列入本變更的 `## Impact`；該不對稱記於 design 的 `## Risks / Trade-offs`。
- 不改變 `task_desc` 的產生方式，也不為它引入穩定識別碼。它維持為 `tasks.md` 中該 task 的描述逐字複本。

## Alternatives Considered

- **改用標籤式 task id（以 `1.1`、`2.1` 本身為鍵）**：能從根本消除位置漂移，但會改變 `touched record` 的保留條目語意、`archive-manifest.json` 的既有內容比對，以及所有既存 state 檔的相容性，成本遠超過本次要解決的問題。
- **只在 `task done` 時修正，不在 `_validate_touched()` 偵測**：漂移可以由 `tasks.md` 的手工編輯造成，未必經過 `task done`；只修正寫入路徑會漏掉這一類。
- **偵測到漂移時依位置重建配對（而非依描述）**：等於直接把每個條目的 `task_desc` 改寫成其目前位置對應的描述。這會銷毀唯一的漂移證據，並把原屬於某個 task 的檔案清單重新標記到另一個 task 名下——在 `default-spec-sync-on-archive` 的實例中就會把 `.claude/skills/cash-archive/SKILL.md` 標記成 bump 任務的產出。本變更採取的是相反方向：以描述反推 id。
- **偵測到漂移就一律 fail closed、不自動對齊**：安全但把每次 review round 增刪 task 都變成人工修復事件，而插入造成的位移有唯一正確解（描述不變、只有位置變），沒有理由不自動處理。fail closed 保留給描述查無此項的情形。
- **為 removed task 新增 touched tombstone identity**：可把已刪 task 永久留在 state，但需要定義新的 `task_id` namespace、生成與碰撞規則，並擴張所有 touched consumers。非 legacy touched entry 只會由已完成 task 產生，恢復該 `[x]` task 即可保留同一份歷史與 `files` attribution，因此不引入第二套身分機制。
- **在 `cash-archive` 步驟 3 直接無條件帶上 `--mark-tasks-complete`**：那等於未經確認就改寫 `tasks.md`，比現行的死路更糟。

## Capabilities

### New Capabilities

（無）

### Modified Capabilities

- `cash-skill-workflows`：新增 `cash-archive 未完成 task 的處置與失敗指引` 與 `cash-commit 對 touched_invalid 的復原指引` 兩條 requirement。
- `cash-cli`：新增 `touched state 的 task attribution 對齊` requirement，並修改 `touched record 記錄 review loop 產出` 的既有條目與寫入條件約束。

## Impact

- Affected specs:
  - cash-skill-workflows
  - cash-cli
- Affected code:
  - New:
    - (none)
  - Modified:
    - .claude/skills/cash-archive/SKILL.md
    - .claude/skills/cash-commit/SKILL.md
    - .agents/skills/cash-archive/SKILL.md
    - .agents/skills/cash-commit/SKILL.md
    - .cash-skills/lib/cash_cli/commands/tasks.py
    - scripts/cash-cli/tests/test_creation_task_lifecycle.py
    - scripts/cash-cli/tests/test_sync_archive_transaction.py
    - cash-skills.version
    - .cash-skills/lib/cash_cli/installer.py
    - .cash-skills/manifest.tsv
  - Removed:
    - (none)
