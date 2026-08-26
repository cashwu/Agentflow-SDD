---
id: run-boundary-underivable-from-append-log
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-08-26
last_seen: 2026-08-26
links:
  - openspec/changes/per-change-tdd-override/reviews/propose-r1.md
---

# Run boundary underivable from append-only log

契約要求消費者從 append-only 事件日誌回報「本次 run」的聚合值（輪數、總和），但該日誌的 schema 沒有 run 識別欄位、鍵值跨 re-run 重複且多種來源的列在同檔交錯累積——「本次 run 的列」無法從檔案內容單獨導出，naive 實作（數全部列、用全域編號）在 abort→re-run 情境必然高估或誤判。修法是把權威來源改為該資料的產生者（主 agent 本次 run 的自身紀錄），日誌讀取降為尾端核對；或在 schema 加入 run 識別欄。與 [[loop-edge-state-undefined]] 不同：那是 edge path 的紀錄契約未定義，這是聚合視窗在既有紀錄裡根本不可導出。

## Occurrences

- 2026-08-26 — per-change-tdd-override — cash-propose round 1 — ledger 摘要 requirement 要求從 `loop-ledger.tsv` 回報本次 run 的 apply 輪數 N 與 `fixed_files` 總和 M，但 ledger schema 無 run 識別欄、`(skill, round)` 非唯一鍵、re-run 列同檔累積；修正為 N／M 以主 agent 本次 run 寫入的紀錄為權威來源、ledger 讀取僅核對尾端列。
