# Cash Apply Review — Round 1

## Reviewer Findings

### Critical

無。

### Warning

1. **severity**: `Warning`｜**confidence**: `100`｜**layer**: `design`｜**reviewer**: A — Adherence
   - **location**: `.cash-skills/lib/cash_cli/installer.py`（`init_source_layout`）+ `specs/cash-cli/spec.md` §「Canonical source repository 被拒絕」
   - **summary**: source-layout 判定式以精確 mode 相等比對，umask `002` clone 的 canonical source repository 不會被 `init_source_repo` 拒絕，`--init-receipt` 直接簽發 receipt
   - **recommendation**: `init_source_layout` 的檢核移除 contract mode 相等條件（保留 `S_ISREG` 與 `st_nlink != 1`），改以「存在且為 regular file」加上 `cash-skills.version` 可解析作為判定；並在 spec 與 design 明載此判定不以 mode 為條件
   - **evidence**: reviewer 實測把 source repo 副本全部檔案 mode 改為 umask `002` clone 會產生的 `0664`／`0775` 後執行 `--init-receipt` → `rc 0`、stdout `initialized`、receipt 被建立。這些 marker 都不在 mode 正規化涵蓋的 managed inventory 內，重跑仍持續誤判，與本 change 的 Scenario「Umask 差異被 mode 正規化吸收」自相矛盾

2. **severity**: `Warning`｜**confidence**: `100`｜**layer**: `design`｜**reviewer**: A — Adherence
   - **location**: `specs/cash-cli/spec.md` 第 9 段 + `design.md` D3-9 + `implementation-notes.md` 2026-07-27 23:26 條目
   - **summary**: `current` 的等價判定額外要求 `snapshot.mode == 0o644`，與 spec「逐 byte 等價時 MUST 回報 `current` 且零寫入」不符；此屬可觀察行為變更，僅記 `deviation` 不足
   - **recommendation**: 實作行為正確，需修 artifact：把 spec 的等價條件與 design D3-9、Implementation Contract 第 2 項同步為「bytes 與 contract mode `0644` 皆一致」，並在 `implementation-notes.md` 補一筆 resolution 條目
   - **evidence**: launcher `.cash-skills/bin/cash:154` 為 `open_regular(receipt_path, 0o644)`，mode 不符即 `bootstrap_invalid`；spec 原文僅以 bytes 為條件，實作多一個 mode 條件

3. **severity**: `Warning`｜**confidence**: `80`｜**layer**: `design`｜**reviewer**: B — Quality
   - **location**: `.cash-skills/lib/cash_cli/installer.py`（`init_publish_receipt`）
   - **introduced_by**: `init_publish_receipt` 中新增的 `snapshot = optional_snapshot(root, RECEIPT_PATH)`
   - **summary**: `.cash-skills/receipt.tsv` 為 FIFO 時 `optional_snapshot` 在 open 阻塞，且此時已持有 `.cash-workspace.lock` 的 exclusive flock，整個 workspace 死鎖而非 fail closed
   - **recommendation**: 在 `optional_snapshot` 之前呼叫既有的 `ensure_regular_shape(root, RECEIPT_PATH)`，非 regular 形狀以 `init_write_failed` 失敗
   - **evidence**: `ensure_regular_shape` 的 docstring 明寫 `opening a FIFO for reading blocks until a writer appears, so the shape is decided from the lstat metadata before any open`；新程式碼在 `init_validate_config` 用了這個 guard，卻在 `init_publish_receipt` 漏用。reviewer 實測行程阻塞逾 15 秒未結束

4. **severity**: `Warning`｜**confidence**: `80`｜**layer**: `design`｜**reviewer**: B — Quality
   - **location**: `scripts/cash-skills/tests/test_init_receipt.py`（`test_non_regular_managed_shape_fails_closed_without_chmod`）
   - **introduced_by**: 該測試新增的 fixture `skewed = target / SKILL_PATHS[1]`、`unsafe = target / SKILL_PATHS[0]`
   - **summary**: 測試 false-green：unsafe 檔在 inventory 順序上早於被 skew 的檔，「fail closed 不 chmod」的斷言就算實作改成單次交錯 loop 也會通過，兩段式不變式從未被驗到
   - **recommendation**: 反轉 fixture — skew 的檔取較早路徑、unsafe 形狀放較晚路徑，並斷言早的檔 mode 未被改動
   - **evidence**: `init_inventory` 順序為 stable → runtime → `managed_skill_paths()`，`SKILL_PATHS[0]`（`cash-analyze`）必早於 `SKILL_PATHS[1]`（`cash-apply`），第一段 loop 一遇 `SKILL_PATHS[0]` 即 raise，`SKILL_PATHS[1]` 根本沒被走到

### Suggestion

5. **severity**: `Suggestion`｜**confidence**: `100`｜**layer**: `design`｜**reviewer**: A — Adherence
   - **location**: `design.md` D3-8 與 Implementation Contract 第 4 項；`specs/cash-cli/spec.md` 第 9 段
   - **summary**: design 與 spec 宣稱 stable identity 以「本機 `fstat`」產生，但實作重用的 `receipt_bytes` 是以 `os.lstat` 取 `st_dev`／`st_ino`
   - **recommendation**: 把 artifact 的 `fstat` 改為 no-follow `lstat`；不要為字面吻合而改動 `receipt_bytes`（會同時影響 installer 既有安裝路徑）
   - **evidence**: `receipt_bytes` 內為 `metadata = os.lstat(target / record.path)`；init 路徑上沒有任何 `fstat` 參與 receipt 的 stable identity 欄位。行為等價，僅 claim 不成立

6. **severity**: `Suggestion`（自 `Warning` 依 confidence filter 降級）｜**confidence**: `75`｜**layer**: `design`｜**reviewer**: B — Quality
   - **location**: `.cash-skills/lib/cash_cli/installer.py`（`init_acquire_lock`）
   - **introduced_by**: `init_acquire_lock` 的 `fstat` 檢核（僅檢 `S_ISREG`／`st_nlink`／dev-ino）
   - **summary**: 相對既有 `acquire_lock` 少了 `st_size != 0` 閘門，非空的 `.cash-workspace.lock` 會被簽進 receipt，init 回報 `initialized` exit 0 但 CLI 依然不可用
   - **recommendation**: 加入 `opened.st_size != 0` 條件，以 `init_inventory_invalid` 失敗並指出 stable lock 必須為空
   - **evidence**: reviewer 實測寫入非空 lock 後 init 回報 `initialized`、exit 0，隨後 `cash list --json` 回 `workspace_lock_invalid`

7. **severity**: `Suggestion`（自 `Warning` 依 confidence filter 降級）｜**confidence**: `75`｜**layer**: `design`｜**reviewer**: B — Quality
   - **location**: `AGENTS.md`、`CLAUDE.md`、`CASH-SKILLS.md`、`specs/cash-cli/spec.md`（文件化的 init 指令）
   - **introduced_by**: 本 diff 於三份文件新增的指令字串
   - **summary**: 文件化指令缺 `-s -P`，`-m` 會把 cwd 置於 `sys.path` 首位，target 根目錄的同名 `.py` 可在任何檢核之前劫持 import，並繞過 JSON 錯誤契約
   - **recommendation**: 指令一律改為帶 `-s -P`，與既有 fish 進入點 `python3 -s -P -m cash_cli.installer` 的隔離等級一致
   - **evidence**: reviewer 在 target 根放入 `uuid.py` 後執行文件化指令 → stderr 出現劫持訊息、stdout 空白、exit 1 且無任何 JSON；改用 `-s -P` 則正常

8. **severity**: `Suggestion`｜**confidence**: `70`｜**layer**: `design`｜**reviewer**: B — Quality
   - **location**: `CASH-SKILLS.md`、`AGENTS.md`／`CLAUDE.md` 的指令；`scripts/cash-skills/tests/test_init_receipt.py`
   - **introduced_by**: 三份文件新增的指令字串與測試 helper 的 `PYTHONDONTWRITEBYTECODE=1`
   - **summary**: 文件化指令未關閉 bytecode 快取，任何路徑（含全部失敗路徑）都會在 target 內寫出 `__pycache__/*.pyc`，與「失敗路徑零檔案內容寫入」的敘述不符，而測試以環境變數遮蔽了這個差異
   - **recommendation**: 文件化指令加上 `-B`，並讓測試 helper 改用同一組 flag 而非環境變數
   - **evidence**: reviewer 實測失敗路徑後 target 內產生 5 個 `.pyc`

9. **severity**: `Suggestion`｜**confidence**: `60`｜**layer**: `design`｜**reviewer**: B — Quality
   - **location**: `.cash-skills/lib/cash_cli/installer.py`（`init_normalize_modes` docstring）
   - **introduced_by**: `init_normalize_modes` 的 docstring 與第二段 chmod loop
   - **summary**: docstring 宣稱 `a failed initialization changes nothing`，但第二段 chmod loop 中途失敗會留下部分已正規化的 managed inventory
   - **recommendation**: 把 docstring 的保證改為與實作一致；不要在註解中做超出契約的保證
   - **evidence**: 第一段 loop 只收集 `pending`，第二段逐檔 `os.fchmod`，任一失敗即 raise，此前成功的 fchmod 不回捲

## Rating

- post-filter cumulative blocking set Critical count：`0`
- post-filter cumulative blocking set Warning count：`4`
- 非阻塞 triaged finding count：`5`
- `critical_gap`：`false`
- `round_type`：`full`

**rationale**：本輪為本次 run 的第一輪且未 seeded，因此所有通過 confidence filter 後仍為 `Critical` 或 `Warning` 的 finding 皆為阻塞。Reviewer B 的四筆 `Critical`／`Warning` 都附有可查證的 `introduced_by`，無一需依 cash-apply introduced-by 規則降級；`confidence ∈ [50, 80)` 的兩筆（非空 lock 閘門、文件化指令缺 `-s -P`）依 filter 降為 `Suggestion`，`confidence < 50` 者為零。四筆阻塞 Warning 皆已在本輪 Fix Actions 修復，但驗證需由後續 reviewer 確認，故本輪不 pass。

## Fix Actions

- **A1（source layout 判定式）**：修改 `.cash-skills/lib/cash_cli/installer.py` 的 `init_source_layout`，移除 contract mode 相等條件，改以 marker 的存在與 regular-file 形狀加上可解析的 `cash-skills.version` 判定，並更新 docstring 說明取捨。同步 `openspec/changes/target-receipt-bootstrap/specs/cash-cli/spec.md`（requirement 本文與「Canonical source repository 被拒絕」scenario 新增 umask `022`／`002` 兩組 mode 的 AND 條件）與 `design.md`（D3-3、Implementation Contract 第 5 項）。新增回歸測試 `test_umask_skewed_source_repository_is_rejected`。
- **A2（`current` 等價判定）**：實作不變，同步 artifact——`specs/cash-cli/spec.md` 的等價條件與「有效 receipt 時零寫入」scenario、`design.md` D3-9 與 Implementation Contract 第 2 項，皆改為「bytes 與 contract mode `0644` 皆一致才回報 `current`；bytes 一致但 mode 漂移時走一般簽發路徑」。於 `implementation-notes.md` 追加 resolution 條目，保留原條目為歷史紀錄。
- **A3（`fstat` claim）**：`design.md` D3-8 與 `specs/cash-cli/spec.md` 第 9 段的 `fstat` 改為 no-follow `lstat`，並註明 `receipt_bytes` 內部即以 `os.lstat` 取值、步驟 6 之後兩者等價。
- **B1（FIFO receipt 阻塞）**：`init_publish_receipt` 在 `optional_snapshot(root, RECEIPT_PATH)` 之前加入 `ensure_regular_shape(root, RECEIPT_PATH)`，非 regular file 以 `init_write_failed` fail closed；同步 `specs/cash-cli/spec.md` requirement 本文與「失敗路徑零內容寫入」scenario、`design.md` D3-9。新增回歸測試 `test_non_regular_receipt_fails_closed_without_blocking`（帶 30 秒 timeout 作為不阻塞的斷言）。
- **B4（測試 false-green）**：`test_non_regular_managed_shape_fails_closed_without_chmod` 的 fixture 反轉為 skew `SKILL_PATHS[0]`、unsafe `SKILL_PATHS[-1]`，hardlink 案例改由 target 內另一個非 inventory 檔案建立硬連結以免同時改動 skew 檔的 `st_nlink`；同步 `design.md` Implementation Contract 第 9 項與 `tasks.md` 3.1 記載此順序要求。
- **B2（非空 stable lock）**：`init_acquire_lock` 的識別檢核加入 `opened.st_size != 0`，以 `init_inventory_invalid` 失敗並指出 stable lock 必須為空；同步 `specs/cash-cli/spec.md`、`design.md` D3-5 與 `tasks.md` 2.1。新增回歸測試 `test_non_empty_stable_lock_fails_closed`。
- **B3／B6（文件化指令隔離）**：`AGENTS.md`、`CLAUDE.md`、`CASH-SKILLS.md`、`proposal.md`、`design.md`、`tasks.md`、`specs/cash-cli/spec.md` 共 11 處指令字串全數同步為 `PYTHONPATH=.cash-skills/lib python3 -s -P -B -m cash_cli.installer --init-receipt`；測試 helper 改用同一組 flag 並移除 `PYTHONDONTWRITEBYTECODE`。新增回歸測試 `test_documented_command_ignores_a_shadowing_module` 與 `test_failed_initialization_writes_no_bytecode`。
- **B5（docstring 過度宣稱）**：`init_normalize_modes` 的 docstring 改為與實作一致（形狀不安全時零 chmod；chmod syscall 本身失敗仍可能留下部分正規化），並在 `design.md` D3-10 明載內容零寫入與 metadata 的保證邊界不同。
- **未修復：裁判面保護** — `scripts/cash-skills/tests/skill-checks.fish` 的 `guidance-cutover` 群組以固定 SHA-256 釘住 `AGENTS.md`／`CLAUDE.md` 的 Cash block 內容（`71cc139e2e69027e6e2d23edef83ad3fbb1e17154b932e8c2f923c0043b177b2`）。本 change 的 spec requirement 與 task 4.2 要求在該 block 內新增 `--init-receipt` 指引，必然使該 baseline 失效；唯一的修法是更新該檔的 pinned digest，但 `scripts/cash-skills/tests/skill-checks.fish` 屬 grader-immutability 保護路徑，且未出現在本 change 的 proposal `## Impact` 或 `tasks.md` 的結構化 scope 宣告中，因此不予修改。現況：`scripts/cash-skills/tests/` 的 `guidance-cutover` 群組失敗，其餘 8 個群組（`codex-command-matrix`、`generated-fresh`、`tdd-discipline`、`grader-immutability`、`installer-runtime`、`canonical-inventory`、`namespace-scan`、`well-formedness`）與 `scripts/cash-cli/tests/` 全數通過。此項使 Implementation Contract 第 10 項與 task 3.3 無法完全成立。
- **post-fix mechanical self-check**：重跑後全數通過——spec delta 註解開閉數皆為 `0`、無 stray `---`；delta 僅有 `## ADDED Requirements` 故略過 title-identity 檢核；`design.md` D3 十步與 Implementation Contract 十項、spec 九個 scenario、`tasks.md` 十一個 task 的計數宣告一致；六個 error code 在程式碼與 spec 中拼寫一致；指令字串舊形式殘留為 `0`；`AGENTS.md` 與 `CLAUDE.md` 的 Cash block 逐 byte 相同。`openspec/signals/` 下無任何帶 `check` frontmatter 的 signal，故 signal-derived check 執行分支為 no-op；其餘 `open` signal 以既有 best-effort 判斷處理，未發現額外可機檢的 anti-pattern。
- **變更目錄外的檔案記錄**：本輪 Fix Actions 修改的 change 目錄外檔案為 `.cash-skills/lib/cash_cli/installer.py`、`scripts/cash-skills/tests/test_init_receipt.py`、`AGENTS.md`、`CLAUDE.md`、`CASH-SKILLS.md`。因修改了 `.cash-skills/` 下的 runtime 檔，已於 project root 執行 `./install-cash-skills.fish --self` 重建 receipt 後才續用 Cash CLI。

## Decision

next_round
