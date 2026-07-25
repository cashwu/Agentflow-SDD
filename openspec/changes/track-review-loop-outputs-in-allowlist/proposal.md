## Summary

讓 review loop 的產出進入 Cash 的來源檔允許清單。新增 CLI verb `touched record`，以明確路徑（而非 snapshot 差分）把 signals write step 與 fix actions 實際寫到的檔案記入 `.cash-skills/state/touched/<name>.json`；`cash-propose` 與 `cash-apply` 的 review loop 在對應時點呼叫它；`cash-commit` 則把 `review-loop` 條目的檔案獨立成一個區段，並在其中位於 `openspec/signals/` 者標示出被多個進行中 change 共同修改、無法乾淨拆分者。

## Motivation

`touched` state 只在 task loop 中由 `cash task done` 累積。review loop 跑在所有 task 都 `[x]` 之後，它的 signals write step 寫出的 `openspec/signals/*.md` 因此永遠不會進 touched；這些檔案又不在 `openspec/changes/<name>/` 之下，`cash-commit` 的 artifact filter 也接不到，於是落進 Unrelated 而靜默漏 commit。review round 檔（`reviews/*.md`、`loop-ledger.tsv`）沒有這個問題，因為它們住在 change 目錄內、被 artifact filter 撈到——差別只在住哪個目錄。

同族的隱蔽變體：cash-apply 的 review loop 在 fix 階段若改到一個之前沒有任何 task 碰過的檔案，該檔同樣不會進 touched。

實證來自本 workspace 的 change `guard-post-archive-commit-allowlist`（commit `2c700eb`）：

- 該 change 的 review loop 共寫出 6 個 signal 檔（propose 迴圈 5 個、apply 迴圈 1 個），沒有任何一個進得了 touched state。提交時必須逐一手動挑出，否則會全部落在 Unrelated 而漏掉。
- 其中 `openspec/signals/acceptance-criterion-unreachable-at-specified-point.md` 被兩個並行 change 同時修改：`occurrences` 由 `3` 變 `5`，`links` 與 `## Occurrences` 各多一條屬於不同 change 的條目。單一檔案無法依 change 拆分 staging，最後只能由使用者裁決整檔納入或整檔排除。

這與 `guard-post-archive-commit-allowlist` 是同一種失效形態——靜默漏檔——只是發生在另一個位置；當時已在該 change 的 Non-Goals 明列為刻意留在範圍外並建議另開變更。它也正是該 change 的 review loop 產生的 signal `exclusion-without-matching-inclusion` 所描述的形狀：新增的產出沒有被接進任何輸出集合。

一個限制必須先講清楚：**檔案粒度的 staging 無法拆分被多個 change 共同修改的單一檔案**。任何允許清單機制都解不了這件事。本變更能做的是讓它「可見且需裁決」，而不是讓它靜默通過。

## Proposed Solution

**一、新增 CLI verb `touched record`**

`touched record <name> --path <p> [--path <p> ...]` 把指定的 project-root-relative 路徑記入該 change 的 touched state，存放於保留條目 `task_id` 為 `review-loop` 之下，與既有 per-task 條目並存。重複呼叫以 union 合併，維持既有的排序去重正規形式，並同步更新頂層 `files`。`touched` 已在 launcher 的 mutating command family 集合與 CLI 的 command 表中，因此新 verb 只需擴充 `touched` family 內部的 argument 分派，不需新增 top-level command。

刻意採用明確路徑而非 snapshot 差分，理由有二：

- `cash-propose` 從不執行 `in-progress add`，因此 propose 迴圈根本沒有 snapshot 可差分；而本次 6 個 signal 檔有 5 個正是 propose 迴圈寫的。
- signals write step 本來就明確知道自己寫了哪些檔，明確路徑的歸屬比差分精確，也不會把同時間其他來源的改動誤記進來。

**二、review loop 在兩個時點呼叫它**

- signals write step 完成後，以該步驟實際建立或更新的 signal 檔路徑呼叫一次。兩個呼叫點在呼叫 `touched record` 之前都 MUST 先執行 `touched ensure`。
- 某一輪的 fix actions 完成後，若該輪 `## Fix Actions` 記錄了任何位於 `openspec/changes/<change>/` 之外的已修改檔案，以那些路徑再呼叫一次。此條件以「檔案是否在 change 目錄之外」判定，兩個 skill 一致，不以 skill 名稱判定。

**三、`cash-commit` 呈現與共用標示**

`cash-commit` 不需要新的允許清單來源——追蹤到的檔案會經由既有的 touched 讀取自然進入提交集合。它只需要：

- 把來自 `review-loop` 條目的檔案獨立顯示為一個區段，與 per-task 的 Source Files 區分。
- 對其中位於 `openspec/signals/` 且其 `links` 指向本 change 以外、且該 change 目錄目前仍存在（active 或 parked）的檔案，標示為共用並要求使用者明確裁決整檔納入或排除，不得靜默納入也不得靜默排除；指向已封存 change 的歷史 link 不觸發判定。

**四、bundle 關卡**

`.cash-skills/lib/cash_cli/` 之下的檔案與四個 review-loop SKILL 檔、兩個 cash-commit SKILL 檔都是 replaceable 檔案，因此必須提升 `cash-skills.version`，並在改動 runtime 檔後重建 `.cash-skills/receipt.tsv`。

## Non-Goals

- 不嘗試把單一檔案依 change 拆分 staging；檔案粒度的限制無法以允許清單解決，本變更只讓共用情形可見且需裁決。
- 不改變 `cash task done` 的既有行為、attribution 或 snapshot 更新語意。
- 不改變 `touched ensure` 的建立空殼行為。
- 不讓 `cash-propose` 執行 `in-progress add` 或以任何方式建立 snapshot。
- 不改變 signals write step 對 signal 檔內容的判定規則（target set、matching rubric、slug 規則、schema 一律不動）。
- 不追溯補記既有已封存 change 的 review loop 產出。
- 不改變 `cash-commit` 對 `openspec/changes/<name>/` artifact 集合的既有規則。Unrelated 判定僅新增一條例外：經使用者裁決排除的共用 signal 檔即使仍在 tracking file 內也列入 Unrelated Changes；其餘判定不變。

## Alternatives Considered

- **重跑 `cash task done` 於最後一個 task**：零 CLI 改動，且 `mark_task_done` 對已完成 task 會 union 合併而非報錯，技術上可行。但它把 review loop 的產出掛在一個不相關的 task 描述之下，commit plan 會顯示成「Task N: <最後一個任務的描述>」，attribution 是假的；且 cash-propose 沒有 snapshot，這條路在 propose 迴圈完全不可行。
- **以 snapshot 差分補記**：同樣受限於 cash-propose 無 snapshot；且差分會把同一時間其他來源的 dirty 改動一併誤記。
- **讓 `cash-commit` 反查 signal 的 `links` 自行發現本 change 的產出**：不需動 CLI，但等於在 touched 之外再開一個允許清單權威來源，與 `Cash state is the only allowlist authority after this point` 的既有契約衝突；且只解得了 signals，解不了 fix 階段新碰到的實作檔。
- **把 signal 檔改為 per-change 一檔以避免共用**：會摧毀 signals 作為跨 change 共享記憶層的核心設計（同一 issue class 累積 occurrences）。
- **自動整檔納入共用 signal 檔**：會把別的 change 未提交的 occurrence 條目與指向尚未提交路徑的 link 一併帶進 commit，製造懸空連結；靜默納入與靜默排除同樣糟。

## Capabilities

### New Capabilities

（無）

### Modified Capabilities

- `cash-cli`：新增 `touched record` command family 並修訂 command surface 的封閉列舉。
- `cash-skill-workflows`：review loop 在 signals write step 與 fix actions 之後補記 touched；`cash-commit` 呈現 review-loop 產出並標示共用 signal 檔。

## Impact

- Affected specs:
  - openspec/specs/cash-cli/spec.md
  - openspec/specs/cash-skill-workflows/spec.md
- Affected code:
  - New:
    - (none)
  - Modified:
    - .cash-skills/lib/cash_cli/commands/tasks.py
    - .claude/skills/cash-propose/SKILL.md
    - .agents/skills/cash-propose/SKILL.md
    - .claude/skills/cash-apply/SKILL.md
    - .agents/skills/cash-apply/SKILL.md
    - .claude/skills/cash-commit/SKILL.md
    - .agents/skills/cash-commit/SKILL.md
    - cash-skills.version
    - scripts/cash-cli/tests/test_creation_task_lifecycle.py
    - scripts/cash-skills/tests/skill-checks.fish
  - Removed:
    - (none)
