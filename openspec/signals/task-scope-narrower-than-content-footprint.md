---
id: task-scope-narrower-than-content-footprint
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-26
last_seen: 2026-07-26
links:
  - openspec/changes/rightsize-cash-skills/reviews/propose-r1.md
---

# Task scope narrower than content footprint

A task targets the file where a section is defined but misses the other files that quote or depend on it, because the section's real footprint was never measured. After the rename or rewrite lands, the unvisited copies point at a name that no longer exists.

## Occurrences

- 2026-07-26 — rightsize-cash-skills — cash-propose round 1 — `Common false positives` 中引用 `Simplicity First` 與 `Surgical Changes` 的兩條項目同時存在於 `cash-propose` 與 `cash-apply`（共四個檔案），但任務範圍只寫兩個檔案；重寫後 propose 側會留下懸空引用。
