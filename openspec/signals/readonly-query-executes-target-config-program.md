---
id: readonly-query-executes-target-config-program
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-24
last_seen: 2026-07-24
links:
  - openspec/changes/guard-target-receipt-version-control/reviews/apply-r1.md
---

# Read-only query executes target-config program

A workflow inspects an untrusted target by shelling out to a tool that honours that target's own configuration file, and the configuration can name a program the tool then executes. The invocation is documented and intended as a read-only query, but pointing the workflow at a target whose config an attacker controls runs an arbitrary binary as the invoking user. The fix is to clear the exec-capable configuration keys on the invocation itself, not to trust the target.

## Occurrences

- 2026-07-24 — guard-target-receipt-version-control — cash-apply round 1 — installer 新增以 `git ls-files` 偵測 receipt 是否已被納入版控，該查詢會執行 target repository `.git/config` 的 `core.fsmonitor` 程式（既有的 `git rev-parse --show-toplevel` 不會）；改為在該 invocation 加上 `-c core.fsmonitor=`，並加入驗證 hook 不被執行的 contract test。
