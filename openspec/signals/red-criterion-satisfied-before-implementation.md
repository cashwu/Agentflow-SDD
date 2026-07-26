---
id: red-criterion-satisfied-before-implementation
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-26
last_seen: 2026-07-26
links:
  - openspec/changes/bootstrap-openspec-config-on-install/reviews/propose-r2.md
---

# Red criterion already satisfied before implementation

A TDD task declares a test case must be red before implementation, but every assertion it lists already holds in the pre-implementation state — typically because an earlier guard fails the run for an unrelated reason and produces the same observable outcome (same exit code, same absent files). The red phase becomes vacuous, and worse, the case cannot distinguish the behavior it is supposed to prove from the earlier failure it accidentally matches. The fix is to assert something only the target code path can produce — a message, a state, an artifact unique to that path — so the case is red for the stated reason and green only when the intended mechanism actually runs.

## Occurrences

- 2026-07-26 — bootstrap-openspec-config-on-install — cash-propose round 2 — task 1.6 要求以 fault injection 驗證「新建的 `openspec/config.yaml` 在 publication failure 時被回滾」，並宣告該 case 在實作前應為紅燈。但它列出的四項斷言（exit 1、config 不存在、receipt 不存在、目錄殘留不計）在實作前全部成立——bare target 會更早在 preflight 以 `cannot open regular file openspec/config.yaml` 失敗，觀察到的結果完全相同。修法是加上只有注入點被走到才會出現的 stderr 斷言 `injected publication failure after .gitignore`，使該 case 在實作前必紅、實作後同時證明 rollback 與注入點都成立。
