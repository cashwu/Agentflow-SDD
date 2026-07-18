---
id: version-bump-test-inventory-incomplete
type: recurring-finding
status: open
occurrences: 2
first_seen: 2026-07-16
last_seen: 2026-07-18
links:
  - openspec/changes/converge-plus-review-loop/reviews/propose-r1.md
  - openspec/changes/add-versioned-cash-skill-batch-update/reviews/apply-r1.md
---

# Version bump test inventory incomplete

A change bumps a version string or rewrites generated content, but the inventory of test files asserting the old strings (hardcoded versions, verbatim template sentences, fixture replacements) is incomplete — acceptance criteria like "all tests green" become unsatisfiable as written. The fix is grepping every test file for the changed literals before writing the task inventory.

## Occurrences

- 2026-07-16 — converge-plus-review-loop — spectra-propose-plus rounds 1–3 — 移除斷言清單從三條修到六條（generator-checks.fish 附屬斷言兩度漏列），且 repair-all-checks.fish 硬編碼 1.4.0 的斷言與 fixture 完全不在 Impact/任務內。
- 2026-07-18 — add-versioned-cash-skill-batch-update — cash-apply round 1 — repository-wide version scan 只檢查至少一筆命中，未盤點完整 path/count occurrences；改為明確 inventory 與 extra-occurrence mutation fixture。
