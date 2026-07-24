# Cash Apply Review — Round 6

## Reviewer Findings

### Critical

1. `severity: Critical`; `confidence: 100`; `layer: design`; `location: .cash-skills/lib/cash_cli/installer.py read_registry()`
   - `summary`: dangling registry或parent symlink被`Path.exists()`誤判為缺失，使registry modes把unsafe boundary視為空清單。
   - `recommendation`: 使用no-follow snapshot區分真正缺失與既存unsafe directory entry，並驗證四種registry modes均fail closed且零寫入。
   - `introduced_by`: task 5.1新增的Python `read_registry()` absent check取代舊installer逐component symlink validation。
   - reviewer source: Reviewer A — Adherence、Reviewer B — Quality
2. `severity: Critical`; `confidence: 100`; `layer: design`; `location: .cash-skills/lib/cash_cli/installer.py read_registry()、--all loop`
   - `summary`: registry parser未完整拒絕`..`、root-only spelling與既存symlink/noncanonical target，unsafe later record可能在batch已修改前一個target後才失敗。
   - `recommendation`: 在回傳records前完成所有lexical canonical checks與既存target no-follow/realpath identity validation，並加入invalid later record使全部targets零寫入的regression。
   - `introduced_by`: task 5.1將舊`valid_absolute_record`與existing record realpath checks改寫為不完整的`Path.as_posix()`比較。
   - reviewer source: Reviewer A — Adherence、Reviewer B — Quality

### Warning

1. `severity: Warning`; `confidence: 100`; `layer: design`; `location: scripts/cash-skills/tests/test_installer_runtime.py test_registry_modes_ignore_exact_empty_lines`
   - `summary`: task 7.2要求前導／中間／尾隨空行fixture，但初版只有一筆non-empty record，未形成真正的中間空行。
   - `recommendation`: 使用兩筆以上有效records並在中間放置空行，驗證read-only mode維持順序與registry inode/mtime/bytes。
   - `introduced_by`: task 7.2初版`test_registry_modes_ignore_exact_empty_lines` fixture。
   - reviewer source: Reviewer A — Adherence、Reviewer B — Quality

### Suggestion

None.

## Rating

- Critical: 2
- Warning: 1
- Non-blocking triaged findings: 0
- `critical_gap`: `true`
- `round_type`: `full`
- rationale: 本次unseeded run的第一輪有兩個Critical與一個Warning通過confidence filter，全部進入累積blocking set；修正已完成，但仍需後續Reviewer V明確驗證解除。

## Fix Actions

- 修改`.cash-skills/lib/cash_cli/installer.py`：以`optional_snapshot()`驗證registry完整no-follow boundary；只有真正缺失才視為empty；逐record拒絕empty component、`.`／`..`、root-only／repeated／trailing slash、existing symlink、non-directory與realpath不一致。
- 修改`scripts/cash-skills/tests/test_installer_runtime.py`：補真正的leading/middle/trailing empty-line matrix、final/parent dangling symlink四模式matrix、noncanonical與existing symlink records，以及unsafe later record封鎖全部batch target writes。
- Post-fix verification：精準5 tests、installer 43 tests、CLI 75 tests、bundle history 4 tests、skill suite、namespace scan、`cash validate --all`、mechanical artifact self-check與`git diff --check`全部通過；實際7-project registry的`--list`維持exit 0且inode/mtime/bytes不變。

## Decision

next_round
