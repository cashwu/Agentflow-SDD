---
id: unsafe-shape-check-blocks-on-open
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-24
last_seen: 2026-07-24
links:
  - openspec/changes/guard-target-receipt-version-control/reviews/apply-r1.md
---

# Unsafe shape check blocks on open

A contract requires a non-regular file to fail closed before the first write, but the implementation decides the shape by opening the file and inspecting the descriptor. A shape whose open blocks until a peer appears — a FIFO, a device — then hangs the workflow instead of raising an execution error, so the fail-closed guarantee silently becomes an unbounded stall that no timeout or exit code reports.

## Occurrences

- 2026-07-24 — guard-target-receipt-version-control — cash-apply round 1 — target `.gitignore` 的 symlink／directory／hard link 都能 fail closed，但 FIFO 使 `os.open(O_RDONLY|O_NOFOLLOW)` 無限阻塞；改為在任何 open 之前以 `os.lstat` + `stat.S_ISREG` 判定形狀，並以帶 timeout 的 contract test 使「不得阻塞」成為斷言的一部分。
