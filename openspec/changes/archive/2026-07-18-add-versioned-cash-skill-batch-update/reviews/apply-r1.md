# Cash Apply Review — Round 1

## Reviewer Findings

### Critical

無。

### Warning

1. `severity`: Warning；`confidence`: 100；`layer`: design；`location`: `install-cash-skills.fish:38-63,235-435`；`summary`: installer 的版本比較、receipt parsing、target hash 與 drift loops 使用未檢查 exit status 的 `command seq`，execution error 可被空迴圈吞掉並偽裝成 `Result: current`；`recommendation`: 移除外部 `seq` 依賴，使用固定 Fish inventory indexes 與受控 index loop，並加入 hostile `seq` fixture；`introduced_by`: 本次 installer rewrite 在上述 change-diff locations 新增未檢查狀態的 `command seq`；reviewer source: Reviewer A — Adherence、Reviewer B — Quality。
2. `severity`: Warning；`confidence`: 100；`layer`: design；`location`: `scripts/cash-skills/tests/skill-checks.fish:582-649`；`summary`: repository-wide version literal scan 只驗證至少一筆命中，沒有比對完整 occurrence inventory，無法讓遺留或新增的 prior-version assertion fail loud；`recommendation`: 建立明確的 path/count inventory 與 isolated mutation fixture；reviewer source: Reviewer A — Adherence。
3. `severity`: Warning；`confidence`: 100；`layer`: design；`location`: `install-cash-skills.fish:365-423`；`summary`: 既有 receipt 更新只檢查 receipt file 可寫，沒有在第一次 skill write 前檢查 atomic replace 所需的 receipt directory write/execute 權限，可能留下新 skill bytes 搭配舊 receipt；`recommendation`: 所有 update/adoption branches 都在寫入前驗證 receipt directory，並加入 prior receipt + unwritable directory 的零寫入 fixture；`introduced_by`: 本次 installer rewrite 將 receipt parent 權限檢查限定在 receipt absent 分支，並在建立 receipt temporary file 前先寫 skills；reviewer source: Reviewer B — Quality。

### Suggestion

1. `severity`: Suggestion；`confidence`: 96；`layer`: text；`location`: `scripts/cash-skills/tests/skill-checks.fish:690-710`；`summary`: runtime installer ordering matrix 有 minor 與 arbitrary-length major，但沒有直接執行 patch upgrade；`recommendation`: 加入 `1.10.0` 到 `1.10.1` 的 installer upgrade fixture；reviewer source: Reviewer B — Quality。

## Rating

- post-filter cumulative blocking Critical: 0
- post-filter cumulative blocking Warning: 3
- non-blocking triaged findings: 1
- `critical_gap`: false
- `round_type`: full
- rationale: 第一輪三個 confidence 100 的 Warning 都直接對應 execution failure、atomic receipt preflight 或 task 3.2 的 fail-loud inventory 契約，因此全部進入 cumulative blocking set；patch runtime fixture 為非阻塞 Suggestion，但仍在進下一輪前一併處理。

## Fix Actions

- 修改 `install-cash-skills.fish`：以固定 24-entry `inventory_indexes` 與 Fish `while` 取代所有 `command seq`，避免 sequence execution error 被折疊成 domain success。
- 修改 `install-cash-skills.fish`：在任何 managed skill write 前，同時驗證既有 receipt file 與 canonical receipt directory 的必要 write/execute 權限。
- 修改 `scripts/cash-skills/tests/skill-checks.fish`：加入 hostile `seq` stub、runtime patch ordering、unwritable receipt directory 零寫入 fixtures。
- 修改 `scripts/cash-skills/tests/skill-checks.fish`：加入 repository path/count version-literal occurrence inventory 與 isolated extra-occurrence mutation fixture，讓未盤點的 prior-version assertion fail loud。
- Fix propagation 與 post-fix mechanical self-check：cross-grep 已確認 `install-cash-skills.fish` 不再含 `command seq`；delta comments 0/0、8 requirements、44 scenarios、8/8 tasks 維持一致。
- Post-fix validation：`fish --no-config scripts/cash-skills/tests/skill-checks.fish`、Fish syntax、`spectra validate add-versioned-cash-skill-batch-update`、`git diff --check` 全部通過。

## Decision

next_round
