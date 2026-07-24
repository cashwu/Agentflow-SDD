# Cash Apply Review — Round 4

## Cumulative Blocking Set Verification

1. `unresolved-prior` — hidden `--source` 已移除，但 invocation cwd 中的 `cash_cli.installer` 仍可優先於 canonical source module 載入。
2. `unresolved-prior` — installer 已重驗多數 source／target inputs，但 target `openspec/config.yaml` 與 Git prerequisite 尚未納入持鎖後重驗。
3. `resolved` — `--register` 在 registry write 前拒絕 source repository，且失敗時零 registry 寫入。
4. `resolved` — launcher source hint 已驗證 Git top-level、strict version、source-only files、runtime core 與完整 24-skill inventory。
5. `resolved` — launcher receipt parser 已要求 canonical `0[0-7]{3}` mode。
6. `resolved` — `bootstrap_source()` 取得鎖後會重驗 Git top-level、`openspec/config.yaml`、source inventory 與 `.cash.yaml`。

## Reviewer Findings

### Critical

1. `severity: Critical`; `confidence: 100`; `layer: design`; `location: install-cash-skills.fish`
   - `summary`: wrapper 使用 `python -m cash_cli.installer` 時，invocation cwd 仍優先於 `PYTHONPATH`，hostile cwd 可完全取代 canonical installer module。
   - `recommendation`: Python 3.11+ 使用 safe-path mode 啟動 canonical module，並加入 hostile-cwd regression。
   - `disposition`: `unresolved-prior`
   - reviewer source: Reviewer V
2. `severity: Critical`; `confidence: 100`; `layer: design`; `location: .cash-skills/lib/cash_cli/installer.py installation_inputs()、install_target()`
   - `summary`: target 等待 stable lock 期間若 `openspec/config.yaml` 或 Git prerequisite 漂移，installer 仍可能發布 managed content。
   - `recommendation`: 將 target config 納入 snapshot，並在持鎖後重跑 Git-root/config prerequisite validation；加入 invalid-target-config 零寫入 regression。
   - `disposition`: `unresolved-prior`
   - reviewer source: Reviewer V

### Warning

None.

### Suggestion

None.

## Rating

- Critical: 2
- Warning: 0
- Non-blocking triaged findings: 0
- `critical_gap`: `true`
- `round_type`: `micro`
- rationale: 累積阻塞集仍有兩個 Critical member 未由 reviewer 驗證解除，因此本輪必須 `next_round`。

## Fix Actions

- 修改 `install-cash-skills.fish`：以 Python `-P` safe-path mode 啟動 canonical installer module，阻止 invocation cwd module shadowing。
- 修改 `.cash-skills/lib/cash_cli/installer.py`：把 target `openspec/config.yaml` 納入完整 input snapshot，並於取得 target lock 後重跑 Git-root/config prerequisite validation。
- 修改 `scripts/cash-skills/tests/test_installer_runtime.py`：新增 hostile-cwd module 與 lock-wait invalid target config 零發布 regressions。
- Post-fix verification：兩個新增測試先紅後綠；installer runtime 38 tests 全部通過。

## Decision

next_round
