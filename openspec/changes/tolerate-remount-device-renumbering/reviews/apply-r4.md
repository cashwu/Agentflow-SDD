# Cash Apply Review — Round 4

本輪為本次 re-run 的第一輪 full round。兩位 fresh reviewers 獨立檢查 artifacts、actual call sites 與本輪 implementation diff；Reviewer A 最終回報 clean，Reviewer B 在審查期間提出三筆高信心 Warning。三筆皆已於本輪 Fix Actions 修正，Reviewer B 的同輪複核回報 clean；依 cumulative blocking set 規則，同輪複核不構成「later reviewer」的 verified resolution，因此三名 members 仍保留到下一個 micro round 驗證。

## Reviewer Findings

### Critical

（無）

### Warning

- `severity`: Warning / `confidence`: 95 / `layer`: design / `location`: `scripts/cash-skills/tests/test_installer_runtime.py:4594-4629` / `summary`: cleanup 原本以 process-group leader 的 `child.poll()` 作整段回收 gate；leader 已退出但 descendant 仍持有 stdout／stderr pipe 或 workspace lock 時，`communicate(timeout=...)` 可逾時而 `poll()` 已非 `None`，導致 finally 跳過 `killpg` 並留下 descendant / `recommendation`: 以 `communicate` 是否完成作 cleanup gate，即使 leader 已退出也對 session process group 執行有限 `SIGTERM` → `communicate` → `SIGKILL` → `communicate`，並把 `ProcessLookupError` 視為 group 已不存在 / `introduced_by`: 本輪最初 cleanup 修正以 `if child.poll() is None:` 包住 release／killpg／reap 流程 / 來源：Reviewer B
- `severity`: Warning / `confidence`: 95 / `layer`: design / `location`: `scripts/cash-skills/tests/skill-checks.fish:321-324` / `summary`: 分離的 `runtime record drift:`、`skill record drift:` 與 remedy assertions 只證明三段文字各自存在，沒有機械守住 composed diagnostic trigger 必須對應還原／可信重裝且 `MUST NOT 重新簽發` 的映射 / `recommendation`: 以單一連續完整 literal 綁住兩個 trigger 與完整 remedy / `introduced_by`: 本輪最初 guidance test 修正新增三條彼此獨立的 `assert_contains` / 來源：Reviewer B
- `severity`: Warning / `confidence`: 90 / `layer`: design / `location`: `scripts/cash-skills/tests/test_installer_runtime.py:4582-4586,4605-4610` / `summary`: crossed／release 路徑仍先後使用 60 秒與 20 秒的 `communicate` timeout，兩者都長於 test hook 自身的 10 秒 timeout；錯誤實作未正確觀察 `.release` 時，測試會先等待 hook 自身 timeout，違反 IC-15 / `recommendation`: crossed 路徑只給明確小於 10 秒的 grace，逾時後直接進 process-group `SIGTERM`／`SIGKILL` 有限回收 / `introduced_by`: 本 change 新增的 hold-boundary test 與本輪前兩次 cleanup 修正保留長 timeout / 來源：Reviewer B

### Suggestion

（無）

## Rating

- post-filter cumulative blocking set Critical count：0
- post-filter cumulative blocking set Warning count：3
- 非 blocking triaged finding count：0
- `critical_gap`：false
- `round_type`：full
- rationale：本輪三筆 Warning 的 confidence 均為 90 以上，且 `introduced_by` 可由本輪具體 diff 驗證，因此全部通過 confidence filter 並在第一輪進入 cumulative blocking set。雖然 Fix Actions 已完成且同輪 reviewer 複核 clean，規則要求由 later reviewer 明確判定 resolved 才能移出集合；本輪因此為 `next_round`。

## Fix Actions

1. 修改 `scripts/cash-skills/tests/test_installer_runtime.py`：以 `communicated` 取代 `child.poll()` 作回收 gate；leader 已退出但 descendant 仍持 pipe 時仍執行 process-group cleanup；`ProcessLookupError` 視為 group 已不存在；release 建立失敗不再跳過後續回收；crossed 路徑的 grace 改為 2 秒，逾時後直接進 `SIGTERM` → 有限等待 → `SIGKILL` → 有限等待。`crossed`／`unfinished` assertions 維持在 `cleanup_errors` 前，使主要失敗優先。
2. 修改 `scripts/cash-skills/tests/skill-checks.fish`：以單一連續完整 literal 綁住 `runtime record drift:`／`skill record drift:` trigger 與還原／可信重裝、`MUST NOT 重新簽發` remedy。
3. Pre-round mechanical self-check 修正 `openspec/changes/tolerate-remount-device-renumbering/proposal.md`：把 guidance 的「三件事／三條 literal」同步為「四件事／各至少一條 literal」，與 design、tasks 及現行 checker 一致。
4. Fix propagation 與 mechanical self-check：spec delta annotation 計數平衡；ADDED requirement 的 13 個 scenarios 與 IC-15 13 列一致；tasks 15/15；三個 MODIFIED requirement titles 逐 byte 存在於 master spec；`AGENTS.md`／`CLAUDE.md` managed blocks 相同；無 open signal 帶 `check` frontmatter；`cash validate tolerate-remount-device-renumbering` 與 `git diff --check` 通過。
5. 驗證：最新 `test_identity_drift_fails_before_acquiring_the_exclusive_lock` 通過；Reviewer B 與 Reviewer A 均以最新工作樹複核三筆修正為 clean。完整 suite 將在 micro round 前以最新 bytes 再跑一次。

裁判面保護：`scripts/cash-skills/tests/skill-checks.fish` 雖為 protected grader path，但 proposal `## Impact` 與 tasks 4.4 均把它列為 structured delivery target，符合明示例外。本輪無 `未修復：裁判面保護`。

## Decision

next_round
