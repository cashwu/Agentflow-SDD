---
id: rollback-restores-content-but-not-verifier-identity
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-28
last_seen: 2026-07-28
links:
  - openspec/changes/add-repo-vendored-cash-bundle/reviews/propose-r1.md
---

# Rollback restores content but not verifier identity

交易 rollback 把檔案 bytes 與 mode 還原，卻以 atomic replace 產生新的 inode；另一個驗證 artifact 若把 device／inode 當作可信 identity，rollback 後內容雖正確仍會被 verifier 判定失效。

修法是把 verifier identity 視為交易的一部分：rollback 若可能改變受驗證檔案的 identity，就必須在同一恢復流程重新簽發或重綁對應紀錄，並以 crash-recovery 測試驗證。

## Occurrences

- 2026-07-28 — add-repo-vendored-cash-bundle — cash-propose round 1 — launcher rollback 會以 replace 還原舊 bytes，但 source receipt 仍保留舊 inode identity；修正為 journal 保存動態 receipt 狀態，rollback 後依還原 launcher 的新 identity 重建 receipt。
