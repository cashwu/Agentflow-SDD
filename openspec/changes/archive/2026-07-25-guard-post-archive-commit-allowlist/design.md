## Context

`cash-commit` 的來源檔允許清單唯一權威是 `.cash-skills/state/touched/<name>.json`。該檔由 `cash task done`（`.cash-skills/lib/cash_cli/commands/tasks.py` 的 `mark_task_done`）逐 task 累積寫入，並由 `cash archive`（`.cash-skills/lib/cash_cli/commands/archive.py`）在封存交易中連同 snapshot 與 sync state 一併刪除。

`cash-commit` step 2 在解析前會先執行 `touched ensure`。`ensure_touched` 在檔案缺席時建立一份 `touched: []`、`files: []` 的空殼並回傳。因此「這個 change 從未追蹤任何來源檔」與「追蹤狀態已被封存刪除」在 step 2 的觀察面上完全同形，而 step 2 明文規定 `Cash state is the only allowlist authority after this point`，於是後者會使該 change 的所有來源檔在 step 4 被歸類為 Unrelated。

`archive-manifest.json` 目前只保留 `touched_digest`（對 touched 物件的 sha256），檔案清單本身在封存當下即遺失，事後沒有可稽核的復原來源。

`cash-commit` step 6a 的內建 archive-first 子流程沒有這個問題：它在呼叫 archive 之前就先保存了已確認的提交集合。缺口只存在於「archive 已在 `cash-commit` 之外先行完成」這條路徑。

封存會把整個 `openspec/changes/<name>/` 目錄移走（`archive.py` 的 `transaction.move`），因此該路徑上受影響的不只有 step 3 的 artifact 集合，還包括 step 4 的 Unrelated 判定、step 5 的「無 artifact 也無來源檔即 STOP」判定與呈現格式、step 6 的 archive-first 選項可用性，以及 step 7 讀取 proposal 與 tasks 產生 commit message 的來源路徑。

## Goals / Non-Goals

**Goals**

- 讓 `cash-commit` 能在觀察面上區分「無追蹤來源檔」與「追蹤狀態已被封存刪除」，並在後者提供可稽核的復原來源。
- 讓 `archive-manifest.json` 保留封存當下的 touched 檔案清單，使復原不必依賴宣告式的 proposal Impact。
- 讓 `cash-commit` 在偵測成立的路徑上，從 step 2 到 step 7 都指向封存後仍存在的來源，不留下讀取已移走路徑的斷點。
- 讓 `cash-apply` 的封存指引把使用者導向不會踏上該缺口的順序。
- `.claude` 與 `.agents` 兩個 skill 變體維持逐字對等。

**Non-Goals**

- 不改變 `cash archive` 刪除 touched、snapshot、sync state 的行為。
- 不改變 `ensure_touched` 的建立空殼行為，也不新增「change 已封存」的 CLI 錯誤碼。
- 不改變 `touched_digest` 的輸入或值。
- 不處理 `openspec/signals/` 之下的 signal 檔未被允許清單追蹤的問題；該缺口在未封存路徑同樣存在，屬既有缺口。
- 不改變 step 6a 內建 archive-first 子流程本身的文字語意（只規範偵測成立時該選項是否可用）。

## Decisions

**決策一：復原來源放在 archive manifest，而非 proposal Impact**

proposal 的 `## Impact` 是宣告，touched state 是實測結果，兩者可能漂移。把 manifest 的 `touched_files` 當作主要復原來源，可讓復原後的允許清單與封存當下的實測結果逐字一致。proposal Impact 只在 manifest 缺該欄位（早於本變更產生的封存）時作為需使用者確認的備援，不作為預設。

**決策二：偵測條件必須三者同時成立**

只用「`files` 為空」會把「本來就沒有追蹤來源檔」的正常 change 誤判成封存後空殼。三個條件同時成立才觸發：

1. 解析後的 `files` 為空陣列。
2. `openspec/changes/<change-name>/` 與 `openspec/changes/.parked/<change-name>/` 皆不存在。
3. 存在符合 `openspec/changes/archive/<date>-<change-name>/` 的目錄。

條件 2 同時排除 active 與 parked 兩個位置：兩者都代表「有一個以該名稱進行中的工作」，此時封存目錄只是同名的歷史紀錄，把它的 `touched_files` 當成權威會產出一份看起來可信的錯誤清單，比現況更糟。任一條件為 false 即維持現行行為不變。

**決策三：復原邏輯放在 skill 層，不改 CLI 的 ensure 行為**

讓 `touched ensure` 對已封存的 change 失敗會觸發 step 2 既有的「ensure 失敗即 STOP」規則，使使用者完全無法提交已封存的 change。因此 CLI 端只補資料（manifest 欄位），判定與復原留在 `cash-commit`。

**決策四：封存目錄先自動消歧，無法消歧才要求確認**

`archive_change` 只在同日同名時以 `archive_collision` 失敗，不同日期的同名封存是合法狀態，因此「比對到多於一個目錄」是可預期的正常情形，不該直接打斷流程。消歧分兩層：

1. 在候選中只保留其 `archive-manifest.json` 的 `change` 等於 `<change-name>` 且 `destination` 等於該目錄相對路徑者，再取日期前綴最新的一個。
2. 第一層之後仍不唯一、沒有任何候選通過驗證、或該 manifest 缺席或無法解析時，才要求使用者確認。

**決策五：manifest 缺 `touched_files` 時 fail loud，並定義合法的終止狀態**

早於本變更產生的封存不會有 `touched_files`。此時 MUST 顯示警告並要求使用者從一組明確的選項中選擇，選項集合為：以封存目錄下 proposal `## Impact` 的 affected-code 路徑作為備援清單、手動逐檔選取、或不提交並停止。「不提交並停止」是合法終止狀態。被禁止的只有「未經使用者確認即以『全部歸 Unrelated』繼續提交」這一條路徑，因此該 MUST NOT 不會與「必須有可選出口」互相矛盾。

**決策六：封存後的 artifact 與 commit message 來源一律改以封存目錄為準**

封存後 `openspec/changes/<change-name>/` 只剩刪除紀錄，內容位於封存目錄。因此偵測成立時：

- artifact 集合改為「`openspec/changes/<change-name>/` 之下的刪除」加上「消歧後封存目錄之下的新增或修改」。
- step 4 的 Unrelated 判定以 `2a` 產出的 artifact 集合、來源允許清單與 spec sync 集合三者的聯集為排除依據。
- step 5 的「無 artifact 也無來源檔即 STOP」只在三個集合的 dirty 內容全部為空時成立，判定輸入為 artifact 集合、來源允許清單的 dirty 子集與 spec sync 集合三者。
- step 6 的 `Archive first, then commit together` 選項不再提供（該 change 已封存，再次執行 archive 會以 `change_not_found` 失敗）。
- step 7 讀取 proposal 與 tasks 的路徑改為消歧後封存目錄下的同名檔案。

**決策七：spec sync 檔案以 manifest digest 判定歸屬，並以獨立區段呈現**

`master_digests` 來自 `plan.master_after`，即使 `already_synced` 也是滿的，因此不能只憑「`specs_synced` 為 true」就把其中所有 `openspec/specs/` 路徑掃進提交——多個 change 並行時，別人對同一份 master spec 的 dirty 編輯會被靜默納入。判定改為：只納入「同時是 dirty，且其目前 digest 等於 manifest 中該路徑記錄值」的路徑；digest 不符者留在 Unrelated 並提示可能有第三方編輯。manifest 已存有該 digest，不需引入新資料。「目前 digest」的計算方式為該檔案內容的 sha256 hexdigest，與 `spec_merge.py` 的 `digest()` 一致，因此 `2a` MUST 指明比對手段（例如 `shasum -a 256`），否則該判定對執行者不可執行。

此判定 MUST 以 manifest 的 `specs_synced` 為 true 為前提。`--skip-specs` 的封存其 `specs_synced` 為 false，此時 `master_digests` 記錄的是封存當下、未經 sync 的 digest，同一條 digest 相等規則會把「封存前就已存在且封存後未再變動」的第三方 dirty 編輯納入提交，正好是本決策要防止的失效模式。因此 `specs_synced` 為 false 時，所有 `openspec/specs/` 路徑一律留在 Unrelated。

被納入的路徑必須真的進入提交集合而不只是通過判定：主流程 step 5 的 commit plan 現行只有 Change Artifacts、Source Files、Unrelated Changes 三個區段（Spec Sync Changes 只存在於 step 6a 的 updated plan），因此偵測成立時 step 5 MUST 增加一個獨立的 `### Spec Sync Changes` 區段容納它們，且 step 4 的 Unrelated 判定 MUST 把它們排除在外。

**決策八：`touched_files` 是時點快照，必須在 commit plan 上如實標示**

`task done` 只在 task 迴圈中執行，審查迴圈 fix 階段之後才變動的檔案不會進 touched state，因此 `touched_files` 可以是非空但不完整。以它復原時，commit plan MUST 標明該清單是封存當下的時點快照，且 dirty 但不在清單內的來源檔仍照既有規則列於 Unrelated 供使用者判斷，避免替一份不完整清單加上權威標籤。

**決策九：`touched_files` 的內容與順序直接取自 touched state 的 `files`**

`files` 已由 `mark_task_done` 與 `_import_legacy` 維持為「以 UTF-8 bytes 排序、去重」的正規形式，直接沿用可避免引入第二套排序規則。無追蹤來源檔時為空陣列，而非省略欄位，使消費端只需判斷「非空」而不必區分「缺席」與「空」。

**決策十：改動 replaceable runtime 檔必須同時處理 receipt 與 bundle version**

`.cash-skills/lib/cash_cli/commands/archive.py` 與四個 `SKILL.md` 都是 bundle 的 replaceable 檔案，受兩道既有關卡約束：

- `.cash-skills/bin/cash` 在任何 dispatch 之前逐檔比對 receipt 記錄的 runtime digest，`archive.py` 一經改動而未重建 `.cash-skills/receipt.tsv`，所有 `.cash-skills/bin/cash` 指令即以 `receipt_invalid: runtime record drift` 失敗，包含 cash-apply 自身用來標記進度的 `task done`。因為 `task done` 正是改動 `archive.py` 那個 task 收尾時執行的第一個 CLI 指令，重建 receipt MUST 併入該 task 本身的收尾步驟，不得排成後續獨立 task。
- `scripts/cash-skills/tests/test_bundle_version_history.py` 的 `check_history` 在 `cash-skills.version` 與 HEAD 相同時，逐檔比對所有 replaceable 檔案與其引入 commit 的 bytes。因此本變更必須提升 `cash-skills.version`，否則 `skill-checks.fish all` 必然失敗。版本值 MUST 由當下的 `cash-skills.version` 與 `git show HEAD:cash-skills.version` 推導為嚴格大於 HEAD 值者，而非寫死常數——同一 workspace 另一個進行中的 change 也宣告要提升該檔，寫死常數在並行落地時可能退化成 `current == head`。

版本提升不是 receipt 重建的前提；`validate_receipt` 不比對 `cash-skills.version`。`.cash-skills/receipt.tsv` 為 gitignore 檔，不列入 affected code。

## Implementation Contract

### C1 — `archive` 寫入 `touched_files`

- 檔案：`.cash-skills/lib/cash_cli/commands/archive.py`，`archive_change` 內組裝 `archive_manifest` 的位置。
- 新增鍵 `touched_files`，值為 `list(touched["files"])`，插入位置在 `touched_digest` 之後、`legacy_cleanup` 之前。
- `touched_digest` 的計算輸入（`touched` 物件本身）與計算方式 MUST 不變；`version`、`change`、`destination`、`specs_synced`、`delta_digests`、`master_digests`、`legacy_cleanup` 的值 MUST 不變。
- 失敗模式：無新增失敗模式；`touched` 已由 `load_or_import_touched` 保證含 `files` 鍵。
- 驗收：`scripts/cash-cli/tests/test_sync_archive_transaction.py` 新增三個測試——
  - (a) 預先寫入一份合法 touched state（含一筆 `touched` 條目，其 `files` 為兩個以 UTF-8 bytes 排序的來源檔路徑，且頂層 `files` 恰為各條目 `files` 的排序聯集，`version` 為 `1`、`change` 為該 change 名稱、`legacy_import` 為 `null`，以滿足 `_validate_touched` 的聯集檢查），封存後 manifest 的 `touched_files` 逐字等於該 `files` 陣列，且 `touched_digest` 等於以封存前 touched 物件依既有公式計算的結果。
  - (b) 沒有任何 touched state 時，manifest 的 `touched_files` 為 `[]`。
  - (c) 斷言 `version`、`change`、`destination`、`specs_synced`、`delta_digests`、`master_digests`、`legacy_cleanup` 的值與新增 `touched_files` 之前相同，以固定期望值斷言。
- (a) 的紅燈失敗原因 MUST 是 manifest 缺少 `touched_files`，不得是 `touched_invalid`。

### C2 — `cash-commit` 新增封存後空允許清單偵測

- 檔案：`.claude/skills/cash-commit/SKILL.md` 與 `.agents/skills/cash-commit/SKILL.md`。
- 在 step 2 之後、step 3 之前新增子步驟 `2a`，標題為 `**Detect a post-archive empty allowlist**`。
- step 2 既有句 `Cash state is the only allowlist authority after this point.` MUST 改寫為帶 2a 例外的形式，且 MUST 逐字包含 `except when step 2a establishes a post-archive recovery source`，避免同一份文件內出現互相矛盾的絕對指令。
- `2a` 的內容 MUST 包含下列各項，且 MUST 逐字包含其中標為字面句者：
  - 決策二的三條偵測條件；條件 1 MUST 逐字包含 `parsed files array is empty`，條件 2 MUST 逐字包含 `openspec/changes/.parked/<change-name>/`，條件 3 MUST 逐字包含 `openspec/changes/archive/<date>-<change-name>/`。
  - 任一條件不成立即回到既有行為，MUST 逐字包含 `keep the existing behavior and continue to step 3`。
  - 決策四的兩層封存目錄消歧規則。
  - `touched_files` 非空時作為來源允許清單，並在 commit plan 標明來源為 archive manifest。
  - 決策八的時點快照標示，MUST 逐字包含 `point-in-time snapshot taken at archive time`；dirty 但不在清單內的來源檔仍列於 Unrelated。
  - 決策五的選項集合與合法終止狀態，MUST 逐字包含 `stop without committing`。
  - 禁止句，MUST 逐字包含 `NEVER fall through to classifying every dirty source file as Unrelated`。
  - 決策六的 artifact 集合、step 4 Unrelated 判定、step 5 判定輸入、step 6 選項不可用、step 7 讀取路徑五項改寫。
  - 決策七的 spec sync 判定與獨立區段，MUST 逐字包含 `master_digests` 與 `` every `openspec/specs/` path stays in Unrelated Changes ``，MUST 指明該判定僅在 manifest 的 `specs_synced` 為 true 時適用，並 MUST 指明「目前 digest」的比對手段為該檔案內容的 sha256 hexdigest。
  - `2a` 重建的三個集合（artifact 集合、來源允許清單、spec sync 集合）MUST 明確宣告為提交集合的一部分而非僅供顯示，否則執行者有理由把 `### Spec Sync Changes` 當成純展示而不 stage。step 6 的 `Commit as shown` 選項 MUST 同步指明「as shown」涵蓋該區段。
- step 3、step 4、step 5、step 6、step 7 MUST 各加一句指向 `2a`：
  - step 3 改用 `2a` 產出的 artifact 集合。
  - step 4 的 `the tracking file` 在 `2a` 成立時改指 `2a` 產出的來源允許清單，且 Unrelated 判定同時排除 `2a` 產出的 artifact 集合與 spec sync 集合。
  - step 5 的 STOP 判定輸入為 artifact 集合、來源允許清單的 dirty 子集與 spec sync 集合三者，只在三者的 dirty 內容全部為空時 STOP；只要 `2a` 成立就新增獨立的 `### Spec Sync Changes` 區段列示 spec sync 集合、且 Source Files 區段以單一未分組清單呈現（`2a` 的三條允許清單來源都不含 task 粒度），兩者皆不以允許清單來源為條件；僅「標明來源與時點快照性質」保留給 archive manifest 來源。
  - step 6 在 `2a` 成立時不提供 archive-first 選項。
  - step 7 在 `2a` 成立時改讀封存目錄下的 proposal 與 tasks。
- 兩個變體在 invocation 前綴（`/cash-` 與 `$cash-`）正規化後 MUST 逐字相同。
- 失敗模式：偵測條件全成立但無法取得任何可信允許清單來源時，MUST 停下並要求使用者決定，MUST NOT 靜默提交。
- 驗收：見 C4。

### C3 — `cash-apply` 封存指引改為提交優先

- 檔案：`.claude/skills/cash-apply/SKILL.md` 與 `.agents/skills/cash-apply/SKILL.md`，step 10 的 `**Archive guidance timing**` 區塊中 `decision: passed` 那一條。
- 該條 MUST 在保留「可以建議封存」的同時，加上「先提交，或改用 cash-commit 的 `Archive first, then commit together` 子流程」的指引，並 MUST 逐字包含 `deletes the touched state that`，說明單獨先封存會刪除 `cash-commit` 用作允許清單的 touched state。
- `decision: aborted` 那一條的既有行為 MUST 不變。
- 修改位置在 `<!-- GRADER-IMMUTABILITY -->` 與 `<!-- LOOP-LEDGER-STEP -->` 之間的 grader 區塊之外，因此 `skill-checks.fish` 的 `grader_hash` 跨四個檔案的一致性 MUST 不受影響。
- 兩個變體在 invocation 前綴正規化後 MUST 逐字相同。
- 驗收：見 C4。

### C4 — 測試與關卡

- `scripts/cash-cli/tests/test_sync_archive_transaction.py`：新增 C1 驗收所述的三個測試，沿用既有的 `make_workspace` helper。
- `scripts/cash-skills/tests/skill-checks.fish`：在 `assert_command_matrix` 內、既有 per-path 字面句斷言區塊之後新增兩組 `assert_contains`，沿用既有三參數形式。
  - 對 `.agents/skills/cash-commit/SKILL.md` 與 `.claude/skills/cash-commit/SKILL.md` 斷言十一個字面句：`Detect a post-archive empty allowlist`、`parsed files array is empty`、`openspec/changes/.parked/<change-name>/`、`openspec/changes/archive/<date>-<change-name>/`、`keep the existing behavior and continue to step 3`、`except when step 2a establishes a post-archive recovery source`、`point-in-time snapshot taken at archive time`、`stop without committing`、`master_digests`、`` every `openspec/specs/` path stays in Unrelated Changes ``、`NEVER fall through to classifying every dirty source file as Unrelated`。
  - 對 `.agents/skills/cash-apply/SKILL.md` 與 `.claude/skills/cash-apply/SKILL.md` 斷言兩個字面句：`Archive first, then commit together`、`deletes the touched state that`。
- 由於這兩組斷言同屬 `assert_command_matrix`，整組 `skill-checks.fish codex-command-matrix` 只有在四個 SKILL 檔全部改完之後才會通過。因此在四個 SKILL 檔全部改完之前，任何**以通過為驗收**的 task MUST 以針對單一檔案的 `rg -F` 作為驗證目標，避免驗收在指定時點不可達；以整組失敗為紅燈目標的 TDD 任務不受此限。
- receipt 常規（全域約束，不另立 task）：每一次改動 `.cash-skills/lib/cash_cli/commands/archive.py` 之後、下一次執行任何 `.cash-skills/bin/cash` 指令之前，MUST 於 project root 執行 `./install-cash-skills.fish --self`；此步驟可重複執行，版本提升不是其前提。
- `cash-skills.version` MUST 提升為嚴格大於 `git show HEAD:cash-skills.version` 的下一個 minor 版本（自現行 `2.3.1` 起為 `2.4.0`），否則 `test_bundle_version_history.py` 的 `check_history` 在 `current == head` 時逐檔比對 bytes 而必然失敗。
- `.cash-skills/receipt.tsv` MUST 在改動 `archive.py` 的那個 task 收尾時、標記該 task 完成之前，以 project root 的 `./install-cash-skills.fish --self` 重建；此後每次再改動 `archive.py` 亦同，且最後一次重建 MUST 在版本提升之後、任何回歸執行之前。
- 驗證指令：`scripts/cash-cli/tests/cli-checks.fish all`、`scripts/cash-skills/tests/skill-checks.fish all`、`.cash-skills/bin/cash validate --all`。

### 範圍邊界

- MUST NOT 改動 `tasks.py` 的 `ensure_touched`、`mark_task_done`、`load_or_import_touched`。
- MUST NOT 改動 `cash-archive` skill。
- MUST NOT 改動 `cash-commit` step 6a 子流程內部的既有文字語意。
- MUST NOT 改動 `scripts/cash-cli/tests/cli-checks.fish`（新測試併入既有檔案，`all` 群組以 `test_*.py` 探索）。

## Risks / Trade-offs

- **manifest 欄位新增改變既有 manifest 的位元組輸出**：已確認沒有任何程式或測試對 `archive-manifest.json` 全檔做雜湊或鍵集合相等比對（`test_positive_lifecycle.py` 只比對 `change` 與 `legacy_cleanup` 兩鍵），風險可接受。
- **早於本變更的封存無法自動復原**：這是不可回溯的資料缺口。緩解方式是 fail loud 加使用者確認，而非猜測。
- **`touched_files` 可能非空但不完整**：審查迴圈 fix 階段的改動不會進 touched state。以決策八的時點快照標示與 Unrelated 併陳緩解，不宣稱該清單完整。
- **偵測依賴目錄命名慣例 `<date>-<change-name>`**：若使用者手動改名封存目錄，偵測會退回「找不到比對」而維持現行行為。此時 `files` 為空且 active 與 parked 位置皆不存在，commit plan 會顯示沒有 artifacts 也沒有來源檔，使用者可觀察到異常；不引入額外的猜測邏輯。
- **skill 文字新增使 `cash-commit` 流程變長**：偵測只在三條件同時成立時才有動作，正常路徑的行為與輸出不變。
- **字面句斷言只保證文字存在、不保證行為**：這是 skill 層可機械驗證的上限。C4 的十一個 cash-commit 字面句涵蓋三條偵測條件各自的判別依據、fall-through 句、step 2 例外句、時點快照句、終止狀態句、`master_digests` 判定、`specs_synced` 為 false 時的保護句與禁止句，因此刪除任一條判定或任一條出口都會紅燈；未被字面句覆蓋的部分（例如兩層消歧的排序規則、step 6 選項不可用、三個集合屬於提交集合的宣告）仍只靠 spec 與 review 把關。
