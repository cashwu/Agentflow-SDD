---
id: relocated-resource-consumers-partially-updated
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-25
last_seen: 2026-07-25
links:
  - openspec/changes/guard-post-archive-commit-allowlist/reviews/propose-r1.md
---

# Relocated resource consumers partially updated

A change adds a branch for the state in which a resource has been moved elsewhere, but only redirects the one consumer that motivated the change. Sibling steps in the same workflow keep reading the pre-move path, so the recovery branch runs far enough to look correct — often past the user's confirmation — and then breaks on a path that no longer exists. The fix is to enumerate every consumer of the relocated resource in the same pass, not just the one the finding named.

## Occurrences

- 2026-07-25 — guard-post-archive-commit-allowlist — cash-propose round 1 — `cash-commit` 新增的封存後偵測只把 step 3 的 artifact 集合改以封存目錄為準，但 step 5 的「無可提交即停止」判定輸入、step 6 的 archive-first 選項可用性、step 7 讀取 `openspec/changes/<name>/proposal.md` 與 `tasks.md` 產生 commit message 的路徑都未同步；archive 已把整個目錄 move 走，復原路徑會在使用者確認 commit plan 之後才撞上不存在的檔案。兩個 reviewer 獨立提出同一缺陷。
