---
id: red-criterion-satisfied-before-implementation
type: recurring-finding
status: open
occurrences: 3
first_seen: 2026-07-26
last_seen: 2026-08-20
links:
  - openspec/changes/bootstrap-openspec-config-on-install/reviews/propose-r2.md
  - openspec/changes/tolerate-remount-device-renumbering/reviews/propose-r2.md
  - openspec/changes/tolerate-remount-device-renumbering/reviews/propose-r10.md
---

# Red criterion already satisfied before implementation

A TDD task declares a test case must be red before implementation, but every assertion it lists already holds in the pre-implementation state — typically because an earlier guard fails the run for an unrelated reason and produces the same observable outcome (same exit code, same absent files). The red phase becomes vacuous, and worse, the case cannot distinguish the behavior it is supposed to prove from the earlier failure it accidentally matches. The fix is to assert something only the target code path can produce — a message, a state, an artifact unique to that path — so the case is red for the stated reason and green only when the intended mechanism actually runs.

## Occurrences

- 2026-07-26 — bootstrap-openspec-config-on-install — cash-propose round 2 — task 1.6 要求以 fault injection 驗證「新建的 `openspec/config.yaml` 在 publication failure 時被回滾」，並宣告該 case 在實作前應為紅燈。但它列出的四項斷言（exit 1、config 不存在、receipt 不存在、目錄殘留不計）在實作前全部成立——bare target 會更早在 preflight 以 `cannot open regular file openspec/config.yaml` 失敗，觀察到的結果完全相同。修法是加上只有注入點被走到才會出現的 stderr 斷言 `injected publication failure after .gitignore`，使該 case 在實作前必紅、實作後同時證明 rollback 與注入點都成立。

- 2026-08-20 — tolerate-remount-device-renumbering — cash-propose round 2 — 同一個 issue class 在本 run 的第 2、3、5、6 輪各出現一次，均已合併為本筆。形態依序是：測試案例集合由四個擴充到十一個後，紅燈驗收仍寫「全部案例在未修改的狀態下失敗」，而其中至少四個在現況已是綠燈；對照表逐列標記 red／guard 後仍有兩列標錯；改用 symlink 建構的錯誤碼案例會在 mode 比對就短路，根本走不到目標出口；改成 hard link 之後，因為同一案例還要求 receipt inode 改值，而 stable record 迴圈在 runtime 迴圈之前執行，今日仍在 stable 迴圈就結束。共同教訓是：紅燈判準必須是只有目標程式碼路徑才能產生的可鑑別觀察，而且「這個 fixture 今天會走到哪一行」必須逐行追過而不是推測。

- 2026-08-20 — tolerate-remount-device-renumbering — cash-propose round 10 — IC-15 把現行已在取鎖前成立的 identity drift、receipt 不改寫與時序判準誤標為 red；修正為整列 guard，避免以既有行為充當新實作的 red evidence。
