---
id: test-fixture-required-case-missing
type: recurring-finding
status: open
occurrences: 3
first_seen: 2026-07-24
last_seen: 2026-07-25
links:
  - openspec/changes/replace-spectra-cli-with-cash-cli/reviews/apply-r6.md
  - openspec/changes/harden-installer-mode-and-recovery/reviews/propose-r1.md
  - openspec/changes/harden-installer-mode-and-recovery/reviews/apply-r1.md

---

# Test fixture required case missing

A regression test claims to cover a task-required input shape, but its fixture does not actually contain the distinguishing case needed to exercise that behavior.

## Occurrences

- 2026-07-24 — replace-spectra-cli-with-cash-cli — cash-apply round 6 — Registry empty-line test claimed leading/middle/trailing coverage but only contained one non-empty record, so no true middle empty line existed；改用兩筆有效records與中間空行，並驗證順序及registry inode/mtime/bytes不變。

- 2026-07-25 — harden-installer-mode-and-recovery — cash-propose round 1 — tasks 要求的 `phase: publishing` journal fixture 沒有任何既有機制可產生（失敗注入會走 rollback 並清除 journal，崩潰型 hook 都在 committed 之後），TDD 的第一步因而沒有可執行路徑；改為明訂手工構造 schema v2 journal 的方式。
- 2026-07-25 — harden-installer-mode-and-recovery — cash-apply round 1 — User-site fixture 假設固定 site path 且 qualified shim 未真正執行 interpreter probe，無法觀察 probe 載入 `usercustomize.py`；改由真實 interpreter 探測 site path 並實跑 probe。
