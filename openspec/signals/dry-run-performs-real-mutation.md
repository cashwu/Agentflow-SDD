---
id: dry-run-performs-real-mutation
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-29
last_seen: 2026-07-29
links:
  - openspec/changes/add-global-cash-shim/reviews/propose-r1.md
---

# Dry-run path performs a real mutation

一條 dry-run 路徑在預覽之前先執行了真實的狀態變更（例如為了讓後續預覽可行而先初始化 repo、建立目錄或寫入 lock），使「dry-run 零寫入」的使用者預期被靜默違反；與 dry-run-bypasses-validation 不同，這裡不是漏跑驗證，而是 dry-run 分支本身帶有副作用。設計時應把 dry-run 明定為純預覽，無法在不變更狀態下預覽的情況應 fail closed 並說明前置條件。

## Occurrences

- 2026-07-29 — add-global-cash-shim — cash-propose round 1 — `cash init --dry-run` 於非 worktree 目錄仍會先執行真實 `git init` 寫入 `.git/`，與 tasks 驗收「零寫入」矛盾；修正為 dry-run 一律不觸發 git 初始化，非 worktree 目錄 fail closed。
