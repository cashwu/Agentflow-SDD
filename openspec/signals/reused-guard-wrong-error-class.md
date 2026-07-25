---
id: reused-guard-wrong-error-class
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-25
last_seen: 2026-07-25
links:
  - openspec/changes/harden-installer-mode-and-recovery/reviews/propose-r1.md
---

# 重用既有守衛而落入錯誤的 error class

一個新的輸入驗證沿用既有守衛來達成，但該守衛屬於另一個 error class（例如 internal execution error 而非 caller input），使新規範宣告的退出碼在實作上不可能成立；而該守衛同時服務既有情境，無法逕行改動其退出碼。

## Occurrences

- 2026-07-25 — harden-installer-mode-and-recovery — cash-propose round 1 — delta spec 要求空字串 mode 參數以 caller-input error 失敗（本 repo 契約為 exit 2），但 design 指定沿用的 `install_target` 與 `canonical_target` 既有守衛都走 `InstallerError` 預設 exit 1，且同時服務被歸類為 execution error 的 boundary scenario；修正為新增專屬守衛並明訂不得改動既有守衛的退出碼。
