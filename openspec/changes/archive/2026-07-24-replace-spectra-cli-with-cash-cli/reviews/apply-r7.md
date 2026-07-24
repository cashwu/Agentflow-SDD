# Cash Apply Review — Round 7

## Reviewer Findings

### Critical

1. `severity: Critical`; `confidence: 100`; `layer: design`; `location: .cash-skills/lib/cash_cli/installer.py read_registry()`
   - `summary`: 前輪第二個累積阻塞 member 尚未完全解除；若 registry record 的最終 target 不存在，但既存 parent component 是 symlink，parser 會在最終 `lstat()` 回傳 `ENOENT` 後停止，未檢查 symlink ancestor。
   - `recommendation`: 對 record 的每個既存 path component 逐一執行 no-follow `lstat()`，任一 symlink 或 non-directory 都 fail closed；只有尚不存在 component 之後的尾段可視為 stale missing target。
   - `introduced_by`: Round 6 canonical record fix 只驗證完整存在 target，缺少 missing final target 的 ancestor boundary case。
   - reviewer source: Reviewer V

### Warning

None.

### Suggestion

None.

## Rating

- Critical: 1
- Warning: 0
- Non-blocking triaged findings: 0
- `critical_gap`: `true`
- `round_type`: `micro`
- rationale: Reviewer V 已確認前輪 member 1 與 member 3 resolved，但 member 2 在 missing child under symlink parent case 仍 unresolved；修正已完成，仍需下一位 fresh Reviewer V 明確驗證解除。

## Fix Actions

- 修改`.cash-skills/lib/cash_cli/installer.py`：逐 component 執行 `os.lstat()`；任一既存 symlink 或 non-directory 立即拒絕，只有碰到真正不存在的 component 才允許 stale missing target。
- 修改`scripts/cash-skills/tests/test_installer_runtime.py`：新增四種 registry modes 的 missing child under symlink parent regression，並驗證 registry 不變、先前有效 target 零寫入。
- Post-fix verification：精準6 tests、installer 44 tests、CLI 75 tests、bundle history 4 tests、skill suite、namespace scan、`cash validate --all`、mechanical artifact self-check與`git diff --check`全部通過；實際7-project registry的`--list`維持exit 0且inode/mtime/bytes不變。
- 累積阻塞狀態：member 1 resolved；member 2 修正前 unresolved、修正後待驗；member 3 resolved。

## Decision

next_round
