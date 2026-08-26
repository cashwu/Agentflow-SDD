---
id: reentry-path-bypasses-creation-anchored-step
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-08-26
last_seen: 2026-08-26
links:
  - openspec/changes/per-change-tdd-override/reviews/propose-r1.md
---

# Reentry path bypasses creation-anchored step

一個「每個實體恰好一次」的義務把觸發點錨定在實體的建立事件（例如「`new change` 成功之後」），但工作流存在合法的再入路徑（continue 既有實體、前次中斷後續作）不會再經過建立事件——該路徑下義務永不觸發，實體永遠缺少該步驟的產出；同時「恰好一次」若無可機械判定的狀態檢查，重複路徑又可能重複執行。修法是把觸發條件從「建立事件發生」改為「產出狀態缺失」（先檢查產出是否已存在：已有則跳過、缺失則補做），使建立與再入路徑共用同一個冪等判準。與 [[option-cannot-observe-its-own-trigger]] 相近但 root cause 不同：那是實作選項在契約排序下觀察不到觸發條件，這是義務錨定的事件在合法路徑上根本不發生。

## Occurrences

- 2026-08-26 — per-change-tdd-override — cash-propose round 1 — propose 的 TDD 詢問義務錨定在「`new change` 成功之後」，但對已存在的 change 走 continue 路徑、不重跑 `new change`，該 change 將永遠沒有 `tdd:` 行；「恰好一次」亦無跨 session 判準。修正為詢問前先檢查 `.openspec.yaml` 是否已有 `tdd:` 行——已有跳過、缺行補問。
