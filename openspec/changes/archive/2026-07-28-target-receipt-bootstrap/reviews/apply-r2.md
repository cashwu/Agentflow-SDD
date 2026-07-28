# Cash Apply Review — Round 2

## Reviewer Findings

### Critical

無。

### Warning

無。

### Suggestion

1. **severity**: `Suggestion`｜**confidence**: `100`｜**layer**: `design`｜**disposition**: `fix-introduced`｜**reviewer**: V — Verification
   - **location**: `openspec/changes/target-receipt-bootstrap/proposal.md`（Proposed Solution 第 1 點）；`openspec/changes/target-receipt-bootstrap/tasks.md`（task 2.1）
   - **introduced_by**: Round 1 的 fix action A3（`fstat` claim）——只同步了 `design.md` D3-8 與 `specs/cash-cli/spec.md` 第 9 段兩處，未涵蓋 `proposal.md` 與 `tasks.md`
   - **summary**: Fix A3 只改了 design 與 spec 的 `fstat` 用語，`proposal.md` 與 `tasks.md` 仍寫「本機 `fstat` 組 receipt」，同一 change 的 artifact 之間自相矛盾
   - **recommendation**: 把兩處一併改為 no-follow `lstat`，與 design D3-8／spec 第 9 段一致；不要改動 `receipt_bytes`
   - **evidence**: reviewer 以 grep 確認 `fstat` 僅剩三筆命中：`design.md:39`（正確且已註明 `receipt_bytes` 內部以 `os.lstat` 取值）、`proposal.md:14`、`tasks.md:7`

2. **severity**: `Suggestion`｜**confidence**: `50`｜**layer**: `design`｜**disposition**: `fix-introduced`｜**reviewer**: V — Verification
   - **location**: `scripts/cash-skills/tests/test_init_receipt.py`（`test_initialization_waits_for_the_stable_lock`）
   - **introduced_by**: Round 1 的 fix action B3／B6（文件化指令隔離）——「測試 helper 改用同一組 flag 並移除 `PYTHONDONTWRITEBYTECODE`」只套用到 `init()` helper，未涵蓋這個自建 `Popen` 的測試
   - **summary**: 該測試仍以 `PYTHONDONTWRITEBYTECODE=1` 且不帶 `-s -P -B` 執行，與「文件化指令即受測指令」的修正意圖不同步
   - **recommendation**: 沿用 `INTERPRETER_FLAGS` 並移除 `PYTHONDONTWRITEBYTECODE`；flock 序列化的斷言邏輯不需改動
   - **evidence**: 對照 `init()` helper 的 `environment.pop("PYTHONDONTWRITEBYTECODE", None)` 與 `[sys.executable, *INTERPRETER_FLAGS, …]`；整檔 16 個 test 當時全綠，此項不影響現行判定

### Cumulative blocking set 逐一判定（Reviewer V）

| member | verdict | fix reference | 驗證要點 |
| --- | --- | --- | --- |
| M1 — source layout 判定式以 mode 相等比對 | `resolved` | Round 1 fix action A1 | reviewer 於 `/tmp` 重建 canonical source repository 副本並逐檔 chmod 為 umask `002` 的 `0664`／`0775`（91 檔），執行文件化指令 → `init_source_repo`、rc 1、receipt 未建立；umask `022` 由 `test_canonical_source_repository_is_rejected` 覆蓋 |
| M2 — `current` 等價判定納入 mode | `resolved` | Round 1 fix action A2 | spec 第 9 段、「有效 receipt 時零寫入」scenario、`design.md` D3-9 與 Implementation Contract 第 2 項皆已同步；行為面實測 `chmod 0664` 後重跑 init → `initialized`、mode 回到 `0644`、bytes digest 不變、CLI 可用 |
| M3 — FIFO receipt 在持鎖狀態阻塞 | `resolved` | Round 1 fix action B1 | reviewer 把 receipt 換成 FIFO 後以 25 秒 timeout 執行 → elapsed `0.07s`、rc 1、`init_write_failed`、FIFO 未被取代 |
| M4 — 測試 false-green | `resolved` | Round 1 fix action B4 | reviewer 以差分實驗證明鑑別力：把 `/tmp` 副本的 `init_normalize_modes` 改成單次交錯 loop 後，skew 檔被改為 `0644` 使斷言失敗；還原兩段式實作後維持 `0664`。實驗僅動 `/tmp` 副本 |

四個成員皆經 Reviewer V 明確判定為 `resolved` 並移出 cumulative blocking set，移除紀錄如上表（成員、fix reference、驗證 reviewer 皆已載明）。

## Rating

- post-filter cumulative blocking set Critical count：`0`
- post-filter cumulative blocking set Warning count：`0`
- 非阻塞 triaged finding count：`2`
- `critical_gap`：`false`
- `round_type`：`micro`

**rationale**：本輪為本次 run 的第二輪，依位置推導為 `micro`，由單一 Reviewer V 執行 delta 驗證。Round 1 的四個 cumulative blocking set 成員全數經獨立實測判定為 `resolved` 並移出集合，post-filter cumulative blocking set 因此為空。Reviewer V 新增的兩筆 finding 經 confidence filter 後皆為 `Suggestion`（`confidence` 分別為 `100` 與 `50`，filter 不會把 `Suggestion` 上調為 `Critical`／`Warning`），依規則為非阻塞，不構成 `next_round`。集合中既無阻塞 `Critical` 也無阻塞 `Warning`，故本輪 pass。

## Fix Actions

- **V1（`fstat` 用語殘留）**：`openspec/changes/target-receipt-bootstrap/proposal.md` 的「以現地 bytes 與本機 `fstat` 組出」與 `tasks.md` 2.1 的「現地 digests 與本機 `fstat` 組 receipt」皆改為 no-follow `lstat`。修正後全 change artifacts 中 `fstat` 僅剩 `design.md` D3-8 一處，且該處是說明 `lstat` 與 `fstat` identity 等價的正確論述。未改動 `receipt_bytes`。
- **V2（測試隔離 flag 不同步）**：`scripts/cash-skills/tests/test_init_receipt.py` 的 `test_initialization_waits_for_the_stable_lock` 改用 `INTERPRETER_FLAGS` 並移除 `PYTHONDONTWRITEBYTECODE`。修正後該檔已無不帶 flag 的裸 `[sys.executable, "-m", …]` 呼叫。
- **未修復：裁判面保護（Round 1 起延續）** — `scripts/cash-skills/tests/skill-checks.fish` 的 `guidance-cutover` 群組以固定 SHA-256（`71cc139e2e69027e6e2d23edef83ad3fbb1e17154b932e8c2f923c0043b177b2`）釘住 `AGENTS.md`／`CLAUDE.md` 的 Cash block。本 change 的 spec requirement 與 task 4.2 要求在該 block 內新增 `--init-receipt` 指引，必然使該 baseline 失效；唯一修法是更新該檔的 pinned digest，但該檔屬 grader-immutability 保護路徑且未列於本 change 的 proposal `## Impact` 或 `tasks.md` 結構化 scope 宣告，故不予修改。此項使 Implementation Contract 第 10 項與 task 3.3 無法完全成立。
- **post-fix 驗證**：`scripts/cash-skills/tests/test_init_receipt.py` 16 tests 全綠；`scripts/cash-cli/tests/cli-checks.fish` 145 tests 全綠；`scripts/cash-skills/tests/skill-checks.fish` 的 `installer-runtime`、`generated-fresh`、`grader-immutability`、`namespace-scan`、`well-formedness`、`canonical-inventory`、`codex-command-matrix`、`tdd-discipline` 八個群組全數通過，僅 `guidance-cutover` 因上述裁判面保護而失敗。
- **post-fix mechanical self-check**：spec delta 註解開閉數皆為 `0`；artifacts 中 `本機 fstat` 殘留為 `0`；舊指令形式殘留為 `0`；`INTERPRETER_FLAGS` 在測試檔中四處一致使用，無裸呼叫殘留。
- **變更目錄外的檔案記錄**：本輪 Fix Actions 修改的 change 目錄外檔案僅 `scripts/cash-skills/tests/test_init_receipt.py`；未修改 `.cash-skills/` 下的 runtime 檔，故不需重建 receipt。已執行 `touched ensure` 與 `touched record`。

## Decision

passed
