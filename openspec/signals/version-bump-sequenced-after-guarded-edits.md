---
id: version-bump-sequenced-after-guarded-edits
type: recurring-finding
status: open
occurrences: 3
first_seen: 2026-07-27
last_seen: 2026-09-05
links:
  - openspec/changes/cash-skill-maintainability/reviews/propose-r1.md
  - openspec/changes/default-spec-sync-on-archive/reviews/apply-r1.md
  - openspec/changes/add-host-derived-round-lint/reviews/propose-r1.md
  - openspec/changes/add-host-derived-round-lint/reviews/propose-r4.md
---

# Version bump sequenced after guarded edits

在 bundle-version history gate 之下，版本檔的 bump 任務被排在受版本守衛檔案的修改之後。`check_history` 在工作樹版本未嚴格領先時，逐檔比對每個 replaceable 檔案與其 introduction commit，因此中間任何時點執行回歸套件都必然失敗，「全套測試通過」類驗收在該序位下不可達。正確序位是 bump 作為第一個 task，先於第一個受守衛檔案的修改。與 [[replaceable-artifact-change-without-version-bump]] 不同：bump 任務存在且版本檔已列入 Impact，缺陷純粹在任務序位。

## Occurrences

- 2026-07-27 — cash-skill-maintainability — cash-propose round 1 — tasks 原把 `cash-skills.version` bump 排在 4.4（所有 SKILL.md 修改與測試切換之後），reviewer 實測對任一 SKILL.md 附加一行即重現 `changed without a strictly greater cash-skills.version`；修正為提前為 task 1.1 並在 design D6 記載序位約束。
- 2026-08-22 — default-spec-sync-on-archive — cash-apply round 1 — tasks 完全沒有 bump 任務，實作在 task 2.1 執行 `./scripts/cash-skills/tests/skill-checks.fish` 失敗（`changed without a strictly greater cash-skills.version`）後才補做；修正為新增排在 1.1 之前的 task 1.0 並在 D7 記載序位前置條件。與前次不同的是這次連 bump 任務本身都不存在。

- 2026-09-05 — add-host-derived-round-lint — cash-propose rounds 1、4 — 兩次都是誤判 bundle 版本與發佈的觸發條件。round 1：proposal 寫下 Non-Goal「不調升 `cash-skills.version`」，理由是「本 change 不改動任何 canonical SKILL.md」——但 master spec 的觸發條件是 replaceable runtime bytes，而該 change 新增並修改四個 `.cash-skills/lib/cash_cli/**.py`；`test_bundle_version_history.py` 的 `replaceable_paths()` 以 `rglob("*.py")` 蒐集，會以 `replaceable inventory changed without a version bump` 失敗，而該測試正是同一份 tasks 自己宣告的 regression target。round 4：停機窗口被歸因為單一成因（新增 `.py` 使 portable gate 拒絕 extra path），漏掉更早觸發的 digest drift——`installer.py` 本身是 manifest 的 runtime record，只調升其 `BUNDLE_VERSION` 常數就會使 launcher 以 `portable manifest digest drift` fail closed，期間連 `cash task done` 都不可用，該 task 因此無法被記為完成。規則應寫成：每一次改動 manifest 覆蓋的 runtime bytes 之後、下一個 CLI 呼叫之前都必須發佈。
