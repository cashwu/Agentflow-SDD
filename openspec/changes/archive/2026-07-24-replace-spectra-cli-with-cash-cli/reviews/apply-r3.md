# Cash Apply Review — Round 3

## Reviewer Findings

### Critical

1. `severity: Critical`; `confidence: 100`; `layer: design`; `location: install-cash-skills.fish、.cash-skills/lib/cash_cli/installer.py`
   - `summary`: hidden `--source` 可覆寫 installer 所在 repository 的真實 source root。
   - `recommendation`: source root 必須由 runtime module 位置不可覆寫地推導，使用者提供 `--source` 必須以 caller-input error 拒絕且零寫入。
   - reviewer source: Reviewer A — Adherence、Reviewer B — Quality
2. `severity: Critical`; `confidence: 100`; `layer: design`; `location: .cash-skills/lib/cash_cli/installer.py install_target()`
   - `summary`: installer 在取得 stable target lock 前建立完整 plan，鎖後只比較 receipt，會以 stale source／target inputs 發布內容。
   - `recommendation`: 對 source inventory、target managed state、config、guidance、receipt 與 legacy candidates 建立完整 snapshot；取得鎖後若任一 input 改變，丟棄舊 plan 並重新分類，publication 前再次驗證。
   - `introduced_by`: 本 change 的 pre-lock planning 與 post-lock publication flow。
   - reviewer source: Reviewer B — Quality

### Warning

1. `severity: Warning`; `confidence: 100`; `layer: design`; `location: .cash-skills/lib/cash_cli/installer.py register branch`
   - `summary`: `--register` 仍可將 source repository 寫入 registry。
   - `recommendation`: registry write 前拒絕 canonical project path 等於 source root，並驗證 registry 零寫入。
   - reviewer source: Reviewer A — Adherence
2. `severity: Warning`; `confidence: 100`; `layer: design`; `location: .cash-skills/bin/cash source hint detection`
   - `summary`: launcher 只用四個 marker 推定 source，installed target 可能收到錯誤的 `--self` 建議。
   - `recommendation`: 驗證 Git top-level、strict version、source-only files、runtime core 與完整 24-skill inventory；installed target 即使有同名 marker 也不得顯示 source hint。
   - `introduced_by`: 本次 source bootstrap 修正新增的 marker heuristic。
   - reviewer source: Reviewer A — Adherence、Reviewer B — Quality
3. `severity: Warning`; `confidence: 100`; `layer: design`; `location: .cash-skills/bin/cash receipt mode parser`
   - `summary`: launcher 接受非 canonical 四位 mode 欄位，與 installer receipt parser 不一致。
   - `recommendation`: 所有 receipt records 在數值轉換前必須符合 `0[0-7]{3}`，並加入 malformed stable mode regression。
   - `introduced_by`: 本 change 新增的 launcher receipt parser。
   - reviewer source: Reviewer A — Adherence、Reviewer B — Quality
4. `severity: Warning`; `confidence: 95`; `layer: design`; `location: .cash-skills/lib/cash_cli/installer.py bootstrap_source()`
   - `summary`: `--self` 取得 exclusive lock 後未重新驗證 Git top-level 與 `openspec/config.yaml`。
   - `recommendation`: 鎖後再次執行 no-follow config validation與Git-root identity驗證，並覆蓋 lock-wait config mutation。
   - `introduced_by`: 本次新增的 `bootstrap_source()`。
   - reviewer source: Reviewer B — Quality

### Suggestion

None.

## Rating

- Critical: 2
- Warning: 4
- Non-blocking triaged findings: 0
- `critical_gap`: `true`
- `round_type`: `full`
- rationale: 本次 run 的首輪 surviving Critical 與 Warning 全部進入累積阻塞集；雖然 fix actions 與完整回歸已完成，仍須由後續 Reviewer V 明確驗證每個 member resolved，故本輪為 `next_round`。

## Fix Actions

- 修改 `install-cash-skills.fish`：移除可由 argv 覆寫的 hidden `--source` forwarding。
- 修改 `.cash-skills/lib/cash_cli/installer.py`：由 `__file__` 推導 source root；拒絕 source registry；以完整 source/target/legacy input snapshots 在 lock 後重分類並於 publication 前重驗；逐檔比對 staged source digest；`bootstrap_source()` 鎖後重驗 Git/config。
- 修改 `.cash-skills/bin/cash`：以 Git top-level、strict version、source-only files、runtime core與24個skills判斷canonical source layout；所有receipt mode先驗證四位octal格式。
- 修改 `scripts/cash-skills/tests/test_installer_runtime.py`：新增hidden source override、source registry、false source hint、malformed mode、self config lock-wait、guidance edit、managed drift與source runtime drift regressions。
- Post-fix verification：targeted 8 tests、installer 36 tests、CLI 75 tests、bundle history 4 tests、exact live namespace scan、`cash validate`與`git diff --check`全部通過。

## Decision

next_round
