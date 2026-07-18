# Cash Apply Review — Round 7

## Reviewer Findings

### Critical

1. `severity`: Critical；`confidence`: 100；`layer`: implementation；`location`: `install-cash-skills.fish` retired-plus quarantine rename；`summary`: Round 6 為修正 original-path symlink swap 而加入的 `mktemp -d`、`rmdir`、`mv` 流程，在移除 temporary directory 後重新開啟 destination pathname；若該 pathname 被換成 target 外 directory symlink，macOS/BSD 一般 `mv source symlink-dir` 可能跟隨 destination symlink，把 candidate 移出 target 邊界；`recommendation`: quarantine 與 restore rename 使用 BSD/macOS `mv -h`，明確禁止跟隨 destination symlink，並加入 quarantine destination symlink swap fault injection；`disposition`: fix-introduced；`introduced_by`: Round 6 C2 的 quarantine fix；reviewer source: Reviewer V — Verification。

### Warning

1. `severity`: Warning；`confidence`: 100；`layer`: implementation；`location`: `install-cash-skills.fish` retired-plus candidate absence check；`summary`: `test -e` 對 dangling directory symlink 回傳 false，可能將其當成不存在而略過，留下 retired-plus pathname；`recommendation`: absence 判定同時檢查 `test -L`，並加入 dangling symlink fail-closed fixture；`disposition`: new（本輪非阻塞 triage）；reviewer source: Reviewer V — Verification。

### Suggestion

無。

## Rating

- post-filter cumulative blocking Critical: 1
- post-filter cumulative blocking Warning: 0
- non-blocking triaged findings: 1
- `critical_gap`: true
- `round_type`: micro
- rationale: Reviewer V 已確認 Round 6 C1 與 W1–W3 resolved，Round 6 C2 的 original-path external deletion path 也已消除；但該 C2 修正引入 quarantine destination symlink window，因此以 `fix-introduced` Critical 留在 cumulative blocking set。dangling symlink skip 是本 micro round 新發現，依規則列為非阻塞 triage；仍同步修正以維持 exact-path cleanup 的 fail-closed 行為。

## Fix Actions

- Verified resolution removal：Round 6 C1（retired-plus identity 過弱）經 Reviewer V 確認 resolved，從 cumulative blocking set 移除。
- Round 6 C2 的 original candidate path symlink-swap external deletion 已 resolved；但 quarantine destination pathname 被 symlink 取代的 fix-introduced C3 仍為 blocking Critical。
- Verified resolution removal：Round 6 W1（unsafe/normal cleanup verification matrix 不完整）經 Reviewer V 確認 resolved，從 cumulative blocking set 移除。
- Verified resolution removal：Round 6 W2（atomic replacement destination parent permission preflight 缺口）經 Reviewer V 確認 resolved，從 cumulative blocking set 移除。
- Verified resolution removal：Round 6 W3（newer+force 與 exact batch summary evidence 缺口）經 Reviewer V 確認 resolved，從 cumulative blocking set 移除。
- 修改 `design.md` 與 delta spec：quarantine/restore rename 必須使用 macOS/BSD destination-symlink no-follow semantics（`mv -h`）。
- 修改 `install-cash-skills.fish`：quarantine 與 restore 使用 `command mv -h`；candidate absence check 同時辨識 dangling symlink。
- 修改 `scripts/cash-skills/tests/skill-checks.fish`：新增 quarantine destination symlink swap fault injection 與 dangling directory symlink fixture，驗證 source candidate、target 外 sentinel 與 target boundary 都不被破壞。
- Post-fix validation：Fish syntax、完整 `fish scripts/cash-skills/tests/skill-checks.fish`、`spectra analyze add-versioned-cash-skill-batch-update --json`、`spectra validate add-versioned-cash-skill-batch-update` 與 `git diff --check` 全部通過；8 requirements、46 scenarios、14/14 tasks 一致。

## Decision

next_round
