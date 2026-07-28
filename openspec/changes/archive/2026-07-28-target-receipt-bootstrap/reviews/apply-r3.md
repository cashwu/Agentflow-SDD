# Cash Apply Review — Round 3

本輪是新一次 loop run 的第一輪（前一次 run 的 apply-r1、apply-r2 已以 `passed` 結束）。round 編號續接既有最高號，run 內位置為第 1 輪，故 `round_type` 為 `full`，且未 seeded。

## Reviewer Findings

### Critical

無。

### Warning

1. **severity**: `Warning`｜**confidence**: `100`｜**layer**: `design`｜**disposition**: `new`｜**reviewer**: B — Quality
   - **location**: `.cash-skills/lib/cash_cli/installer.py`（`init_inventory`）；`scripts/cash-skills/tests/test_init_receipt.py`（`test_missing_inventory_fails_closed`）
   - **introduced_by**: 本次 diff 新增的 `init_inventory()`——runtime 條目來源為 `library.rglob("*.py")` 的就地枚舉，沒有任何期望集合比對（tasks 2.1／design D3 步驟 7）；配套測試的三個 case（lock、`SKILL_PATHS[0]`、`.cash-skills/bin/cash`）全部落在常數推導路徑上
   - **summary**: D3 步驟 7 與 spec「任一 inventory 檔案缺失 fail closed」對 runtime 部分是空談——runtime record 集合由 `rglob` 就地推導而非比對固定期望路徑，因此 clone 少了或多了任一 `.cash-skills/lib/cash_cli/**.py`，init 都會簽發一份「自洽但錯的」receipt 並回報 `initialized`（exit 0）
   - **recommendation**: 比照 D2 的 `BUNDLE_VERSION` 雙真相來源作法，在 installer module 內嵌一組 canonical runtime 相對路徑常數作為期望集合，實際 `rglob` 結果與其不相等（缺檔或多檔）即以 `init_inventory_invalid` fail closed 並在診斷列出差集；並在 `test_installer_runtime.py` 加上該常數恆等於 `source_inventory` 推導結果的 contract 斷言；`test_missing_inventory_fails_closed` 補上一個 runtime `.py` case
   - **evidence（主 agent 已獨立重現，非僅採信 reviewer）**: 於 `/tmp` 以 `install-cash-skills.fish --target` 建 fixture（baseline 20 筆 runtime record）。刪除 receipt 與 `.cash-skills/lib/cash_cli/spec_merge.py` 後執行文件化指令 → stdout `initialized`、exit `0`、receipt 僅 19 筆 runtime；隨後 `.cash-skills/bin/cash list --json` 通過 `validate_receipt`，卻在 `commands/archive.py:11` 以 `ModuleNotFoundError: No module named 'cash_cli.spec_merge'` traceback 失敗、exit `1`。反向：放入一個 `.cash-skills/lib/cash_cli/stray_helper.py`（`0644`）後 init → `initialized`、21 筆 runtime、launcher 通過；接著 `./install-cash-skills.fish --target <fixture>` → `Error: receipt has an invalid record count`，加 `--force` 仍為同一錯誤。launcher 的 `validate_receipt` 只驗證 receipt 內「已列出」的 runtime record，從不枚舉 runtime 目錄，因此無法補上此缺口
   - **failure_scenario**: target 專案自己的 `.gitignore` 含一行 `spec_merge.py`（同類常見樣式：`config.py`、`tasks.py`、`search.py`、`archive.py`⋯）→ 該 runtime 模組從未進版控 → 隊友 `git clone` 得到少一個 `.py` 的 checkout → 依部署的 `AGENTS.md` 指引執行 `--init-receipt` → 輸出 `initialized`、exit `0`（工具宣告成功）→ `.cash-skills/bin/cash list --json` 吐出 traceback 而非任何具名 error code。**直接違反 Implementation Contract 第 1 項**

2. **severity**: `Warning`｜**confidence**: `100`｜**layer**: `design`｜**disposition**: `new`｜**reviewer**: A — Adherence
   - **location**: `openspec/changes/target-receipt-bootstrap/design.md` — Context 凍結約束 2／3、Context 末段、D5
   - **summary**: `design.md` 全部 5 處 `installer.py:` 行號引用指向本 change 修改前的檔案，實檔對照後無一成立，而 Context 明稱「皆已實檔驗證」
   - **recommendation**: 改為只引函式名／常數名而不引行號，避免同一 change 自己修改該檔後行號必然失效
   - **evidence（主 agent 已獨立複核）**: 現行檔案 `GUIDANCE_PATHS` 在 43（design 寫 42）、`def parse_receipt` 在 507（寫 498-507）、`publish_launcher` 的 raise 在 994（寫 985）、`if __name__ == "__main__":` 在 2223（寫 1915）。偏差來源是本 change 自己插入的 `BUNDLE_VERSION`、`InitError` 與全部 `init_*` 函式。凍結約束的實質內容逐條實測皆成立，不成立的只有指標

3. **severity**: `Warning`｜**confidence**: `100`｜**layer**: `design`｜**disposition**: `fix-introduced`｜**reviewer**: A — Adherence
   - **location**: `openspec/changes/target-receipt-bootstrap/design.md` — `## Implementation Contract` 第 7 項
   - **introduced_by**: cash-verify 部署時序修復對 Contract 第 7 項的改寫，引入「每次 bump 的 commit 序位皆先於其後的 `installer.py` 修改」判準
   - **summary**: Contract 第 7 項以「commit 序位」為驗收判準，但本 change 完全未提交、2.8.0 從未且不會存在於任何 commit（cash change 以單一 commit 落地），該判準不可能成立也無從查證
   - **recommendation**: 改為工作樹與 task 序位的可查證形式，與實際 gate 一致
   - **evidence**: `git show HEAD:cash-skills.version` = 2.7.0、工作樹 = 2.9.0，中間態 2.8.0 在 first-parent 歷史中不存在。實際 gate（`test_bundle_version_history.py` 的 `check_history`）在 `current != head` 且 `version_greater` 時直接 `return`，不涉及 commit 序位。第 7 項另兩個合取項（最終 2.9.0 且與 `BUNDLE_VERSION` 一致、receipt 經 `--self` 重建反映 2.9.0）皆實測成立

### Suggestion

4. **severity**: `Suggestion`｜**confidence**: `100`｜**layer**: `design`｜**disposition**: `new`｜**reviewer**: A — Adherence
   - **location**: `CASH-INIT-RECEIPT.md` vs. `proposal.md` `## Impact`、`scripts/cash-skills/tests/skill-checks.fish` 的 `assert_guidance_and_docs`
   - **summary**: 新增的 repo root 文件大量複述本 change 的規範性行為，卻既未列入 `## Impact`，也未被任何 gate 治理，會靜默漂移
   - **recommendation**: 納入 `## Impact` 與 `tasks.md`，並比照 `CASH-SKILLS.md` 在 `assert_guidance_and_docs` 釘住其關鍵字
   - **evidence**: `assert_guidance_and_docs` 以 14 條 literal 釘住 `CASH-SKILLS.md`，該新檔不在其中，亦不在 `assert_grader_immutability` 的受保護集合

5. **severity**: `Suggestion`｜**confidence**: `100`｜**layer**: `design`｜**disposition**: `new`｜**reviewer**: B — Quality
   - **location**: `CASH-INIT-RECEIPT.md` — FAQ「和別人同時跑會衝突嗎？」
   - **summary**: FAQ 宣稱「在做任何檢核或簽發之前先取得 exclusive flock」，與實際行為及同文件自己的步驟表矛盾：Python 版本檢查、worktree 驗證、source-repo 偵測與 config 驗證都在取鎖之前完成
   - **recommendation**: 改為「在 mode 正規化、inventory 檢核與簽發之前取得 exclusive flock 並全程持有」
   - **evidence**: `init_receipt()` 內順序為版本檢查 → `git rev-parse` → `init_source_layout()` → `init_validate_config()` → `init_acquire_lock()`

## Rating

- post-filter cumulative blocking set Critical count：`0`
- post-filter cumulative blocking set Warning count：`3`
- 非阻塞 triaged finding count：`2`
- `critical_gap`：`false`
- `round_type`：`full`

**rationale**：本輪為本次 run 的第一輪且未 seeded，因此通過 confidence filter 後仍為 `Warning` 的三筆皆為阻塞。Reviewer B 的 `Critical`／`Warning` 皆附可查證的 `introduced_by`，無需依 cash-apply introduced-by 規則降級；無 `confidence < 50` 或落在 `[50, 80)` 的 finding，故無 drop 或降級。三筆阻塞 Warning 中的兩筆（design 行號、Contract 第 7 項）已於本輪修復但未經 reviewer 驗證；第三筆（runtime inventory 完整性檢核為空談）的修法需要 `design.md` 未定義的機制，觸發 Fix-loop design circuit breaker，因此本輪不 pass 亦不進入 `next_round`，而是 `aborted`。

## Fix Actions

- **needs-design（Fix-loop design circuit breaker）** — finding 1（runtime inventory 完整性檢核為空談）。**所需機制**：在 installer module 內嵌一組 canonical runtime 相對路徑常數，作為 `init_inventory` 比對的期望集合。**不予實作的理由**：target 上不存在其他真相來源，因此修法必然引入一個 `design.md` 未定義的 bundle runtime payload identity；它同時 (a) 新增一個規範性失敗模式——現行會成功簽發的 target（runtime 集合有增減者）自此以 `init_inventory_invalid` 被拒，屬使用者可見的取捨；(b) 使日後每次增刪 runtime 檔都必須同步該常數，正是 open signal `trust-root-inventory-blocks-payload-extension` 描述、且本 change proposal 刻意迴避的架構約束；(c) 需要新的 design decision、新的 spec 條文、新的 Implementation Contract 項與新的 contract test。以上皆屬設計層決定而非機械修正，依規則不在 fix actions 中實作，導向 `/cash-ingest`。
- **finding 2（design 行號失效）已修復**：`design.md` 的 5 處 `installer.py:` 行號引用全部改為函式名／常數名（`publish_launcher`、`parse_receipt`、`install_target` 在 `compare_versions` 之前呼叫、`__main__` 進入點、`GUIDANCE_PATHS`）。`.cash-skills/bin/cash` 的行號引用保留，因為 launcher 逐 byte 凍結、行號穩定。修改檔案：`design.md`。
- **finding 3（Contract 第 7 項判準）已修復**：改為「最終為 2.9.0、與 `BUNDLE_VERSION` 一致、嚴格大於 `git show HEAD:cash-skills.version`；每次 bump 在 **task 序位** 上先於其後受守衛檔案的修改（task 1.1 先於 2.1；task 6.1 先於 6.2）」，並註明改用 task 序位的理由與實際 gate 的行為。修改檔案：`design.md`。
- **finding 5（FAQ 取鎖時點）已修復**：`CASH-INIT-RECEIPT.md` 的該則 FAQ 改為「在 mode 正規化、inventory 檢核與簽發之前取得 exclusive flock」，並明列取鎖前四個唯讀步驟。修改檔案：`CASH-INIT-RECEIPT.md`。
- **finding 4（新文件治理）部分處理，其餘為 triage note**：本輪進行中，使用者明確指示把 `CASH-INIT-RECEIPT.md` 納入 change scope，已據此修改 `proposal.md` `## Impact`（`New:` 清單）、`tasks.md`（新增 task 4.3 並標記完成）與 `design.md`（D5 引導管道、Implementation Contract 第 8 項）。此編輯發生於 reviewer 執行期間，兩位 reviewer 取得的 context 仍為「該檔不在 Impact 宣告內」，因此 finding 4 前半段自提出時起即已被解決。**剩餘未處理部分**：finding 4 建議在 `assert_guidance_and_docs` 比照 `CASH-SKILLS.md` 釘住該檔關鍵字。此舉與 task 6.2 逐字要求的「除該 digest 常數外不修改此檔的任何其他斷言」直接衝突，故不在本輪實作，一併留給 `/cash-ingest` 決定是否擴充 task 6.2 的授權範圍。
- **post-fix 驗證**：`scripts/cash-skills/tests/skill-checks.fish` 全套（含 `guidance-cutover`、bundle version history、namespace scan）通過；`scripts/cash-cli/tests/cli-checks.fish` 145 tests 通過；`scripts/cash-skills/tests/test_init_receipt.py` 16 tests 通過。
- **post-fix mechanical self-check**：`design.md` 殘留 `installer.py:` 行號引用為 `0`；spec delta 註解開閉數皆為 `0`；contract 10 項、8 個 registry targets、24 個 skills 三處計數宣告與實際相符；版本三處（`cash-skills.version`／`BUNDLE_VERSION`／source receipt）一致為 2.9.0。`openspec/signals/` 下無任何帶 `check` frontmatter 的 signal，signal-derived check 分支為 no-op。
- **變更目錄外的檔案記錄**：本輪修改的 change 目錄外檔案為 `CASH-INIT-RECEIPT.md`。未修改 `.cash-skills/` 下的 runtime 檔，故不需重建 receipt。已執行 `touched ensure` 與 `touched record`。

## Abort triage

- **bucket 1 — 仍屬本 change 的義務（seeds 下次 re-run 的 cumulative blocking set）**
  1. finding 1（runtime inventory 完整性檢核為空談）：未修復，需先經 `/cash-ingest` 定義 runtime payload 期望集合的機制與其取捨。
  2. finding 2（design 行號失效）：已於本輪修復，但未經 reviewer 驗證，依規則仍留在 cumulative blocking set。
  3. finding 3（Contract 第 7 項判準）：已於本輪修復，但未經 reviewer 驗證，同上。
- **bucket 2 — 新發現且從未阻塞**
  - finding 4（新文件的 gate 治理缺口）與 finding 5（FAQ 取鎖時點，已修復）。兩者經 confidence filter 後皆為 `Suggestion`，依 signals write step 規則「`Suggestion` MUST NOT 產生 signal」，故不寫入 signals。
- **bucket 3 — 已接受的取捨**：無。本輪未取得任何 accepted-risks 的使用者明示同意，故不寫入 `accepted-risks.md`。
- **不建議原樣重跑。** 具體前置條件：先以 `/cash-ingest` 就 finding 1 決定 runtime payload 期望集合的機制（是否內嵌常數、如何與 `trust-root-inventory-blocks-payload-extension` 的架構約束取捨、失敗模式與診斷形式），並一併決定是否擴充 task 6.2 對 `skill-checks.fish` 的授權以涵蓋 finding 4 的 literal 釘選；artifacts 更新後再啟動 re-run，其第一輪為 `full` 並以上列 bucket 1 三項 seeds cumulative blocking set。

## Decision

aborted
