---
id: version-bump-sequenced-after-guarded-edits
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-27
last_seen: 2026-07-27
links:
  - openspec/changes/cash-skill-maintainability/reviews/propose-r1.md
---

# Version bump sequenced after guarded edits

在 bundle-version history gate 之下，版本檔的 bump 任務被排在受版本守衛檔案的修改之後。`check_history` 在工作樹版本未嚴格領先時，逐檔比對每個 replaceable 檔案與其 introduction commit，因此中間任何時點執行回歸套件都必然失敗，「全套測試通過」類驗收在該序位下不可達。正確序位是 bump 作為第一個 task，先於第一個受守衛檔案的修改。與 [[replaceable-artifact-change-without-version-bump]] 不同：bump 任務存在且版本檔已列入 Impact，缺陷純粹在任務序位。

## Occurrences

- 2026-07-27 — cash-skill-maintainability — cash-propose round 1 — tasks 原把 `cash-skills.version` bump 排在 4.4（所有 SKILL.md 修改與測試切換之後），reviewer 實測對任一 SKILL.md 附加一行即重現 `changed without a strictly greater cash-skills.version`；修正為提前為 task 1.1 並在 design D6 記載序位約束。
