---
id: existing-assertion-contradicts-new-behavior
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-25
last_seen: 2026-07-25
links:
  - openspec/changes/align-cli-skill-contracts/reviews/propose-r1.md
---

# Existing assertion contradicts new behavior

A task adds test cases for changed behavior without checking whether an existing assertion in the same file asserts the old behavior. The suite goes red on a line nobody planned to touch, and the task as written cannot reach its own acceptance state.

## Occurrences

- 2026-07-25 — align-cli-skill-contracts — cash-propose round 1 — 任務要求為 drift 建議欄位補案例，但同一測試檔既有的 startswith("$cash-") 斷言與新行為相反；任務改寫為「替換而非新增」後才自洽。
