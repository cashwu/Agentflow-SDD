---
id: unsafe-shape-check-blocks-on-open
type: recurring-finding
status: open
occurrences: 2
first_seen: 2026-07-24
last_seen: 2026-07-26
links:
  - openspec/changes/guard-target-receipt-version-control/reviews/apply-r1.md
  - openspec/changes/bootstrap-openspec-config-on-install/reviews/propose-r1.md
---

# Unsafe shape check blocks on open

A contract requires a non-regular file to fail closed before the first write, but the implementation decides the shape by opening the file and inspecting the descriptor. A shape whose open blocks until a peer appears — a FIFO, a device — then hangs the workflow instead of raising an execution error, so the fail-closed guarantee silently becomes an unbounded stall that no timeout or exit code reports.

## Occurrences

- 2026-07-24 — guard-target-receipt-version-control — cash-apply round 1 — target `.gitignore` 的 symlink／directory／hard link 都能 fail closed，但 FIFO 使 `os.open(O_RDONLY|O_NOFOLLOW)` 無限阻塞；改為在任何 open 之前以 `os.lstat` + `stat.S_ISREG` 判定形狀，並以帶 timeout 的 contract test 使「不得阻塞」成為斷言的一部分。
- 2026-07-26 — bootstrap-openspec-config-on-install — cash-propose round 1 — installer 放寬 `openspec/config.yaml` 的缺檔前置條件時，delta spec 新宣告「symlink、非 regular file 或 hard link MUST 以 execution error 失敗」，但設計指定的 `optional_snapshot` → `read_regular` 路徑對 FIFO 會在 `os.open(O_RDONLY|O_NOFOLLOW)` 無限阻塞。同一份 `installer.py` 的 `ensure_regular_gitignore` docstring 早已逐字記錄同一危害與修法，卻沒有被新路徑沿用——既有的教訓寫在程式碼註解裡，不會自動傳染到下一個做同類判定的地方。修法是抽出共用的 `ensure_regular_shape`，在任何 open 之前以 `lstat` 判形狀，並讓 contract test 帶 `timeout=` 使「不得阻塞」成為斷言。
