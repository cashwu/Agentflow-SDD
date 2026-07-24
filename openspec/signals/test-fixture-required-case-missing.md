---
id: test-fixture-required-case-missing
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-24
last_seen: 2026-07-24
links:
  - openspec/changes/replace-spectra-cli-with-cash-cli/reviews/apply-r6.md
---

# Test fixture required case missing

A regression test claims to cover a task-required input shape, but its fixture does not actually contain the distinguishing case needed to exercise that behavior.

## Occurrences

- 2026-07-24 — replace-spectra-cli-with-cash-cli — cash-apply round 6 — Registry empty-line test claimed leading/middle/trailing coverage but only contained one non-empty record, so no true middle empty line existed；改用兩筆有效records與中間空行，並驗證順序及registry inode/mtime/bytes不變。
