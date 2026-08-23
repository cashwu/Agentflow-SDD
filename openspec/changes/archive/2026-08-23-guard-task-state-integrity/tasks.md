## 0. Prerequisite

- [x] 0.1 確認 `default-spec-sync-on-archive` 已提交

  本變更修改的七個路徑——`.claude/skills/cash-archive/SKILL.md`、`.claude/skills/cash-commit/SKILL.md`、`.agents/skills/cash-archive/SKILL.md`、`.agents/skills/cash-commit/SKILL.md`、`cash-skills.version`、`.cash-skills/lib/cash_cli/installer.py` 與 `.cash-skills/manifest.tsv`——在 `default-spec-sync-on-archive` 的工作樹修改中也全部存在且尚未提交。判準 MUST 逐一涵蓋這七個路徑：少列任何一個，該路徑就會在仍髒的情況下被本變更的 task 編輯。在該 change 提交之前開始本變更，會使兩者的編輯混在同一份未提交的工作樹中而無法分離。

  判準（MUST 全部成立）：

  ```
  test -z (git status --porcelain .claude/skills/cash-archive/SKILL.md | string trim)
  test -z (git status --porcelain .claude/skills/cash-commit/SKILL.md | string trim)
  test -z (git status --porcelain .agents/skills/cash-archive/SKILL.md | string trim)
  test -z (git status --porcelain .agents/skills/cash-commit/SKILL.md | string trim)
  test -z (git status --porcelain cash-skills.version | string trim)
  test -z (git status --porcelain .cash-skills/lib/cash_cli/installer.py | string trim)
  test -z (git status --porcelain .cash-skills/manifest.tsv | string trim)
  ```

  任一判準不成立時 MUST 停止並先完成 `default-spec-sync-on-archive` 的 `/cash-commit`，MUST NOT 以「稍後一起提交」略過。

## 1. Implementation

- [x] 1.0 依 IC8 調升 bundle version

  交付目標：`cash-skills.version`、`.cash-skills/lib/cash_cli/installer.py`、`.cash-skills/manifest.tsv`

  相依 0.1。MUST 排在 1.1 之前執行——bundle version history contract 要求任何 `SKILL.md` 或 `.cash-skills/lib/` 下的檔案位元改變時 `cash-skills.version` 嚴格領先 HEAD，因此在第一個受版本守衛檔案的修改之前先完成。

  以 `git show HEAD:cash-skills.version` 取得 HEAD 當下的值，採 minor bump 決定新版本號（例如 HEAD 為 `2.14.0` 時新值為 `2.15.0`），MUST NOT 寫死任何版本號。把 `cash-skills.version` 改為新值；把 `.cash-skills/lib/cash_cli/installer.py` 的 `BUNDLE_VERSION` 常數同步為同一字串；在專案根執行 `PYTHONPATH=.cash-skills/lib python3 -s -P -B -m cash_cli.installer --self` 重建 `.cash-skills/manifest.tsv`。

  判準（MUST 全部成立）。先以 `set NEW (…依上述規則決定的新版本號…)` 綁定變數，再逐條執行：

  ```
  test (cat cash-skills.version | string trim) = "$NEW"
  rg -Fq -- "BUNDLE_VERSION = \"$NEW\"" .cash-skills/lib/cash_cli/installer.py
  rg -q -- "^bundle_version\t$NEW\$" .cash-skills/manifest.tsv
  test (git show HEAD:cash-skills.version | string trim) != "$NEW"
  # 嚴格領先：以 test_bundle_version_history.py 的 version_greater() 語意比較，非僅相異
  python3 -c "import sys;a=tuple(map(int,sys.argv[1].split('.')));b=tuple(map(int,sys.argv[2].split('.')));sys.exit(0 if a>b else 1)" "$NEW" (git show HEAD:cash-skills.version | string trim)
  ```

  此後每次修改 `SKILL.md` 或 `.cash-skills/lib/` 下的檔案，都 MUST 重跑該 `--self` 指令使 manifest digest 與工作樹一致，否則 `.cash-skills/bin/cash` 會以 `manifest_invalid` fail closed。

  範圍界定：本任務只改版本值與由其衍生的 manifest 內容，MUST NOT 改動 `installer.py` 的其他部分。

- [x] 1.1 [P] 依 IC1 與 IC2 改寫 `.claude/skills/cash-archive/SKILL.md`

  交付目標：`.claude/skills/cash-archive/SKILL.md`

  相依 1.0。依 IC1 把步驟 3 的 `**If incomplete tasks found:**` 分支整段替換為 IC1 第 1 點的逐字內容，並原樣沿用其 3 空格基準縮排；依 IC2 在步驟 5 的 bash 範例增加帶 `--mark-tasks-complete` 的一行，並在既有 `validation_failed` 那一條之後依序增加 `tasks_incomplete` 與 `touched_invalid` 兩條失敗處置。

  正向判準（實作前 exit 1，實作後 MUST exit 0）：

  ```
  rg -Fq -- 'Use the **AskUserQuestion tool** to ask: "These tasks are still incomplete. Mark all as complete before archiving?"' .claude/skills/cash-archive/SKILL.md
  rg -Fq -- '**Yes**: set a flag to pass `--mark-tasks-complete` to the archive command in step 5' .claude/skills/cash-archive/SKILL.md
  rg -Fq -- '**No**: stop without archiving; do not invoke archive with incomplete tasks' .claude/skills/cash-archive/SKILL.md
  rg -Fq -- '**If archive fails** with `tasks_incomplete`, report the exact error and re-run with `--mark-tasks-complete`; neither `--skip-specs` nor `--no-validate` bypasses this precondition.' .claude/skills/cash-archive/SKILL.md
  rg -Fq -- '**If archive fails** with `touched_invalid` naming a `task_desc` that no longer exists in `tasks.md`' .claude/skills/cash-archive/SKILL.md
  rg -Fq -- 'Repairing this drift by editing `task_desc` does not violate the guardrail against deleting touched state; never delete the file.' .claude/skills/cash-archive/SKILL.md
  rg -q -- '^   - Use the \*\*AskUserQuestion tool\*\* to ask:' .claude/skills/cash-archive/SKILL.md
  rg -Fq -- '"$cash_cli" archive <name> --mark-tasks-complete' .claude/skills/cash-archive/SKILL.md
  ```

  負向判準（實作前 exit 0，實作後 MUST exit 1）：

  ```
  rg -Uq -- '   - Prompt user for confirmation to continue\n   - Proceed if user confirms\n\n   \*\*If no tasks file exists:\*\*' .claude/skills/cash-archive/SKILL.md
  ```

  段落級判準（實作後 MUST 成立）：

  ```
  awk '/^3\. \*\*Check task completion status\*\*/,/^4\. \*\*Determine spec sync behavior\*\*/' .claude/skills/cash-archive/SKILL.md | rg -Fq -- 'AskUserQuestion'    → MUST exit 0
  awk '/^3\. \*\*Check task completion status\*\*/,/^4\. \*\*Determine spec sync behavior\*\*/' .claude/skills/cash-archive/SKILL.md | rg -Fq -- 'Proceed if user confirms'    → MUST exit 1
  awk '/^3\. \*\*Check task completion status\*\*/,/^4\. \*\*Determine spec sync behavior\*\*/' .claude/skills/cash-archive/SKILL.md | rg -Fq -- 'Prompt user for confirmation to continue'    → MUST exit 1
  awk '/^2\. \*\*Check artifact completion status\*\*/,/^3\. \*\*Check task completion status\*\*/' .claude/skills/cash-archive/SKILL.md | rg -Fq -- 'Prompt user for confirmation to continue'    → MUST exit 0
  awk '/^5\. \*\*Perform the archive\*\*/,/^6\. \*\*Display summary\*\*/' .claude/skills/cash-archive/SKILL.md | rg -Fq -- 'touched_invalid'    → MUST exit 0
  rg -Uq -- 'bypasses this precondition\.[^\n]*\n\n   \*\*If archive fails\*\* with `touched_invalid`' .claude/skills/cash-archive/SKILL.md    → MUST exit 0
  awk '/^5\. \*\*Perform the archive\*\*/,/^6\. \*\*Display summary\*\*/' .claude/skills/cash-archive/SKILL.md | rg -Fq -- 'tasks_incomplete'    → MUST exit 0
  rg -Uq -- 'once the findings are judged acceptable\.[^\n]*\n\n   \*\*If archive fails\*\* with `tasks_incomplete`' .claude/skills/cash-archive/SKILL.md    → MUST exit 0
  ```

  註：負向判準以「步驟 3 特有的三行相鄰序列」為比對單位，不能只比對 `- Prompt user for confirmation to continue` 這一行——步驟 2 的 artifact 分支有同樣一行且 IC1 第 3 點要求它 MUST NOT 改動，單行比對會在實作後仍然命中而使判準永遠失敗。該判準 MUST 使用 `rg -U` 的多行模式並以 `\n` 表示換行：`rg` 預設逐行比對，把換行直接寫進 `-F` 的 pattern 會使它永遠不命中，判準即淪為恆 exit 1 的空真。段落級判準的 awk 範圍在實作前後皆非空，具鑑別力。步驟 5 的四條依序為：第一條釘住 `touched_invalid` 出現在步驟 5 範圍內，第二條以 `rg -U` 釘住它緊接在 `tasks_incomplete` 那一段之後（IC2 第 4 點的置放義務），第三條釘住 `tasks_incomplete` 出現在步驟 5 範圍內，第四條以 `rg -U` 釘住它緊接在 `validation_failed` 那一段之後（IC2 第 3 點的相鄰義務）——四條合起來使兩個錯誤碼的存在性與彼此順序都成為可機械比對的關係；縮排判準 `'^   - Use the \*\*AskUserQuestion tool\*\* to ask:'` 以行首錨定 MUST 恰為 3 空格。此處不能用 `rg -F` 加前導空格的形式——`-F` 是子字串比對，只能排除少於 3 空格的縮排，以 6 空格插入仍會命中。

  保留守則（實作前後皆 MUST exit 0）：

  ```
  rg -Fq -- '- `--mark-tasks-complete` — mark all incomplete tasks as complete before archiving' .claude/skills/cash-archive/SKILL.md
  rg -Fq -- '**If no tasks file exists:** Proceed without task-related warning.' .claude/skills/cash-archive/SKILL.md
  rg -Fq -- '"$cash_cli" archive <name> --skip-specs' .claude/skills/cash-archive/SKILL.md
  ```

  範圍界定：步驟 2 的 `**If any artifacts are not `done`:**` 分支（含其 `- Prompt user for confirmation to continue` 與 `- Proceed if user confirms` 兩行）MUST NOT 改動。

- [x] 1.2 [P] 依 IC3 為 `.claude/skills/cash-commit/SKILL.md` 增加 touched_invalid 復原指引

  交付目標：`.claude/skills/cash-commit/SKILL.md`

  相依 1.0。與 1.1、1.3 修改不同檔案且無資料相依，可並行。依 IC3 在步驟 2 的 `If ensure fails, report the error and STOP.` 之後增加 `touched_invalid` 的復原指引逐字內容。

  正向判準（實作前 exit 1，實作後 MUST exit 0）：

  ```
  rg -Fq -- 'If ensure fails with `touched_invalid` naming a `task_desc` that no longer exists in `tasks.md`' .claude/skills/cash-commit/SKILL.md
  rg -Fq -- 'Editing `task_desc` to repair this drift is the one permitted manual edit to touched state; never delete the file.' .claude/skills/cash-commit/SKILL.md
  rg -q -- '^   If ensure fails with `touched_invalid` naming' .claude/skills/cash-commit/SKILL.md
  ```

  段落級判準（實作後 MUST exit 0）：

  ```
  awk '/^2\. \*\*Read tracking file\*\*/,/^2a\. /' .claude/skills/cash-commit/SKILL.md | rg -Fq -- 'touched_invalid'
  ```

  註：awk 起點 `2. **Read tracking file**` 與終點 `2a. ` 已對實檔核對，實作前該範圍非空（步驟 2 內文完整落在其中），因此該判準在實作後具鑑別力而非空真。

  保留守則（實作前後皆 MUST exit 0）：

  ```
  rg -Fq -- 'If ensure fails, report the error and STOP.' .claude/skills/cash-commit/SKILL.md
  rg -Fq -- 'Cash state is the only allowlist authority after this point' .claude/skills/cash-commit/SKILL.md
  ```

  註：第三條正向判準以 `^   ` 行首錨定，把 IC3 第 1 點的縮排義務釘成可機械比對的判準。此處同樣不能用 `rg -F` 加前導空格——`-F` 是子字串比對，只能排除少於 3 空格的縮排，以 6 空格插入仍會命中。

  範圍界定：步驟 2 的 Expected format 區塊與步驟 2a MUST NOT 改動。

- [x] 1.3 [P] 依 IC4 為 `.cash-skills/lib/cash_cli/commands/tasks.py` 增加 attribution 對齊

  交付目標：`.cash-skills/lib/cash_cli/commands/tasks.py`、`scripts/cash-cli/tests/test_creation_task_lifecycle.py`、`scripts/cash-cli/tests/test_sync_archive_transaction.py`

  相依 1.0。與 1.1 無資料相依且修改不同檔案，可並行。依 IC4 六點施作：新增 `_RESERVED_TASK_ID` 常數並取代 `touched record` handler 中的字面值；新增 `_realign_touched_attribution()`；在 `load_or_import_touched()` 的既有 state 路徑與 `touched record` handler 兩處呼叫它；依 IC4 第 4、5 點讓 `ensure_touched()` 與 `touched record` 在對齊改變內容時把結果寫回磁碟；`_validate_touched()` 與 `mark_task_done()` 對既有條目的處理不得改動。並依 IC5 更新三個 fixture 與現行 `tasks.md` 不一致的既有測試，依 IC6 為 `cash-cli` delta spec `## ADDED Requirements` 之下的每條 scenario 新增一個 `test_realign_` 前綴的測試方法（`## MODIFIED Requirements` 下沿用既有行為的 11 條不在此義務範圍內）。

  正向判準（實作前 exit 1，實作後 MUST exit 0）：

  ```
  rg -Fq -- '_RESERVED_TASK_ID = "review-loop"' .cash-skills/lib/cash_cli/commands/tasks.py
  rg -Fq -- 'def _realign_touched_attribution(' .cash-skills/lib/cash_cli/commands/tasks.py
  test (rg -c -- '_realign_touched_attribution\(' .cash-skills/lib/cash_cli/commands/tasks.py; or echo 0) -ge 3
  awk '/^def load_or_import_touched/,/^def ensure_touched/' .cash-skills/lib/cash_cli/commands/tasks.py | rg -Fq -- '_realign_touched_attribution('
  rg -q -- 'def test_realign_' scripts/cash-cli/tests/test_creation_task_lifecycle.py
  test (rg -c -- '"review-loop"' .cash-skills/lib/cash_cli/commands/tasks.py; or echo 0) -eq 1
  ```

  保留守則（實作前後皆 MUST exit 0）：

  ```
  rg -Fq -- 'def _validate_touched(value: dict[str, object], name: str) -> dict[str, object]:' .cash-skills/lib/cash_cli/commands/tasks.py
  rg -Fq -- 'existing["files"] = sorted(' .cash-skills/lib/cash_cli/commands/tasks.py
  rg -Fq -- 'items.sort(key=lambda item: item["task_id"].encode("utf-8"))' .cash-skills/lib/cash_cli/commands/tasks.py
  ```

  負向守則（實作前後皆 MUST exit 1；對齊 MUST NOT 改寫 `task_desc`）：

  ```
  rg -q -- '\["task_desc"\]\s*=[^=]' .cash-skills/lib/cash_cli/commands/tasks.py
  ```

  註：`"review-loop"` 的計數判準屬**正向**判準——依 IC4 第 1 點，實作後全檔應恰剩常數定義行那一處，故實作前為 2（exit 1）、實作後為 1（exit 0）。把它放進負向判準區塊會使宣告方向與 IC4 第 1 點直接矛盾。

  註：兩條 count 判準的 `; or echo 0` 不可省略——`rg -c` 在零命中時不輸出且 exit 1，命令替換為空會使 `test` 以語法錯誤中止而非乾淨失敗，判準即無法區分「不成立」與「執行失敗」。

  註：此守則刻意不綁定任何變數名。綁定 `existing` 只涵蓋 `mark_task_done()` 的區域變數，攔不住 `_realign_touched_attribution()` 內以 `item`、`entry` 或索引式寫法改寫 `task_desc`——而那正是 D2 與 IC4 第 2 點明文禁止的「依位置改寫 `task_desc`」。現行程式碼中 `task_desc` 只以 dict 字面值 `"task_desc": ...` 出現，故該模式今天即 exit 1。

  行為判準（MUST 全部成立）：依 IC6，`cash-cli` delta spec `## ADDED Requirements` 之下的每一條 scenario，MUST 在 `scripts/cash-cli/tests/test_creation_task_lifecycle.py` 有一個 `test_realign_` 前綴的對應測試方法；`## MODIFIED Requirements` 下沿用既有行為的 11 條 scenario（其中兩條僅補上「對齊不改變任何內容」的 GIVEN）不在此義務範圍內。上方正向判準中的 `rg -q -- 'def test_realign_'` 只證明至少存在一個，因此本判準 MUST 以人工逐條核對覆蓋率：scenario 數與 `test_realign_` 方法數 MUST 相等，且每條 scenario 的 GIVEN/WHEN/THEN 皆有對應斷言。

  範圍界定：`tasks.py` 只改動 IC4 指名的位置，MUST NOT 重構其他部分。測試檔只改動 IC5 指名的三個既有測試與 IC6 要求的新增方法，MUST NOT 改動 `scripts/cash-cli/tests/cli-checks.fish`——它是裁判面保護路徑，且以 `test_*.py` glob 自動探索，新增案例不需改它。

- [x] 1.4 依 IC7 重新生成 `.agents` 變體

  交付目標：`.agents/skills/cash-archive/SKILL.md`、`.agents/skills/cash-commit/SKILL.md`

  相依 1.0、1.1、1.2、1.3，不可與其並行。在專案根執行生成器，MUST NOT 手工編輯生成結果：

  ```
  ./scripts/cash-skills/generate.fish
  ```

  判準：1.1 與 1.2 的每條字面值判準在對應的 `.agents` 檔案上把 `/cash-` 正規化為 `$cash-` 後同樣成立（1.3 交付的是 `.cash-skills/lib/` 與 `scripts/cash-cli/tests/` 下的檔案，沒有 `.agents` 對應檔，IC7 也只指名兩個 `SKILL.md`）；且本任務造成的 `git status --porcelain` 新增變動只有 `.agents/skills/cash-archive/SKILL.md` 與 `.agents/skills/cash-commit/SKILL.md` 兩個路徑。生成後 MUST 重跑 `--self` 重建 manifest。

## 2. Verification

- [x] 2.1 執行 skill 套件檢查

  相依 1.4。該套件需要 `fish` 與 `rg`（ripgrep）。若環境缺少 `rg`，MUST 先安裝再執行，MUST NOT 以「環境不可執行」略過本任務。在專案根執行，MUST 通過（exit code 0）：

  ```
  ./scripts/cash-skills/tests/skill-checks.fish
  ```

- [x] 2.2 執行 CLI 套件檢查

  相依 1.3。在專案根執行，MUST 通過（exit code 0）：

  ```
  ./scripts/cash-cli/tests/cli-checks.fish
  ```

- [x] 2.3 執行 change 驗證

  相依 1.4。在專案根執行，MUST 通過（exit code 0）：

  ```
  ./.cash-skills/bin/cash validate guard-task-state-integrity
  ```

## 3. Apply review blocker resolution

- [x] [P] 3.1 依更新後 IC2 修正 requirement `cash-archive 未完成 task 的處置與失敗指引` 的 removed-task 復原分支

  交付目標：`.claude/skills/cash-archive/SKILL.md`

  將步驟 5 的 `touched_invalid` 指引改為 renamed／removed 互斥分支。Renamed task 保留更新 touched entry `task_desc` 的既有出口；removed task MUST 停止封存並導向無參數 `/cash-ingest`，把目前的 `touched_invalid` 與 change name 作為 conversation context，使 ingest 選取既有 change 並把 exact `task_desc` 恢復成 `tasks.md` 中的 `[x]` task。Removed 分支 MUST 明寫不得編輯、刪除或重新歸屬 touched entry，因為 `files` 仍屬於該歷史 task；label 衝突 MUST 由相同 ingest context 解決 artifacts，MUST NOT 猜測新 label。

  判準（MUST 全部成立）：

  ```
  rg -Fq -- 'determine whether that task was renamed or removed' .claude/skills/cash-archive/SKILL.md
  rg -Fq -- 'If renamed, update that entry' .claude/skills/cash-archive/SKILL.md
  rg -Fq -- 'If removed, stop and run `/cash-ingest` with the current `touched_invalid` error and change name as conversation context so it selects the existing change and restores the exact `task_desc` as a completed `[x]` task in `tasks.md`' .claude/skills/cash-archive/SKILL.md
  rg -Fq -- 'do not edit or delete the touched entry, because its `files` remain attributed to that historical task' .claude/skills/cash-archive/SKILL.md
  ```

  範圍界定：只改步驟 5 的既有 `touched_invalid` 指引；步驟 3、其他失敗分支、Optional flags 與輸出模板 MUST NOT 改動。

- [x] [P] 3.2 依更新後 IC3 修正 requirement `cash-commit 對 touched_invalid 的復原指引` 的 removed-task 復原分支

  交付目標：`.claude/skills/cash-commit/SKILL.md`

  將步驟 2 的 `touched_invalid` 指引改為 renamed／removed 互斥分支，語意與 3.1 相同；removed task 改以無參數 `/cash-ingest`，把目前的 `touched_invalid` 與 change name 作為 conversation context，使 ingest 選取既有 change 並恢復 exact completed task，MUST NOT 編輯或刪除 touched entry。

  判準（MUST 全部成立）：

  ```
  rg -Fq -- 'determine whether that task was renamed or removed' .claude/skills/cash-commit/SKILL.md
  rg -Fq -- 'If removed, stop and run `/cash-ingest` with the current `touched_invalid` error and change name as conversation context so it selects the existing change and restores the exact `task_desc` as a completed `[x]` task in `tasks.md`' .claude/skills/cash-commit/SKILL.md
  rg -Fq -- 'do not edit or delete the touched entry, because its `files` remain attributed to that historical task' .claude/skills/cash-commit/SKILL.md
  ```

  範圍界定：只改步驟 2 的既有 `touched_invalid` 指引；Expected format 與步驟 2a MUST NOT 改動。

- [x] 3.3 重新生成 `.agents` 變體並重建 manifest

  相依 3.1、3.2。在專案根依序執行：

  ```
  ./scripts/cash-skills/generate.fish
  PYTHONPATH=.cash-skills/lib python3 -s -P -B -m cash_cli.installer --self
  ```

  `.agents/skills/cash-archive/SKILL.md` 與 `.agents/skills/cash-commit/SKILL.md` MUST 由 generator 產生，MUST NOT 手工編輯；正規化 `/cash-` 與 `$cash-` invocation 前綴後，3.1 與 3.2 的更新段落 MUST 完全相同。Manifest 的 `bundle_version` MUST 維持目前已完成 task 1.0 設定的版本，只更新受修改檔案的 digest。

- [x] 3.4 執行 skill 套件檢查

  相依 3.3。在專案根執行且 MUST exit 0：

  ```
  ./scripts/cash-skills/tests/skill-checks.fish
  ```

- [x] 3.5 執行更新後 change 驗證

  相依 3.3。在專案根執行且 MUST exit 0：

  ```
  ./.cash-skills/bin/cash validate guard-task-state-integrity
  ```

  同時確認既有 `touched state 的 task attribution 對齊` 與 `touched record 記錄 review loop 產出` requirements 仍由已完成的 1.3／2.2 runtime tests 覆蓋；本 blocker resolution MUST NOT 修改 `.cash-skills/state/touched/<name>.json` 的 schema 或 `.claude/skills/cash-apply/SKILL.md`，也 MUST NOT 把歷史來源 `reviews/apply-r4.md` 或 design `## Risks / Trade-offs` 誤列為新增 delivery target。
