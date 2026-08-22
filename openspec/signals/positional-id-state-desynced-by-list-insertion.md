---
id: positional-id-state-desynced-by-list-insertion
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-08-22
last_seen: 2026-08-22
links:
  - openspec/changes/default-spec-sync-on-archive/reviews/apply-r2.md
---

# Positional-id state desynced by list insertion

持久化狀態以「來源清單中的序位」作為記錄鍵，插入或刪除清單條目使該鍵之後的全部配對整體位移，既有紀錄因此靜默指向錯誤的條目。與 [[positional-failure-injection-index-invalidated]] 的機制同型但領域不同：那是測試以序位注入失敗，這是跨呼叫持久化的 attribution 狀態。加劇因素是驗證面只檢查該狀態的 shape、排序與集合聯集，從不把記錄鍵與來源清單重新比對，因此漂移不會被任何工具發現；修復後若沒有同時建立維持該不變量的機制，下一次增刪條目會以同樣方式復發。

## Occurrences

- 2026-08-22 — default-spec-sync-on-archive — cash-apply round 2 — review round 1 的 fix 為修復宣告缺口而在 `tasks.md` 最前面插入 task `1.0`，但 Cash CLI 的 task id 是位置式（`_task_entries()` 以 `str(len(entries) + 1)` 產生），使 `.cash-skills/state/touched/<change>.json` 的既有配對整體錯位一位（`task_id: "1"` 仍配 `task_desc: "1.1 …"`，位置 6 無紀錄，bump 三檔仍掛在 `2.1 執行 skill 套件檢查` 名下）。`_validate_touched()` 只驗 shape、canonical 排序與 `files` 聯集，全程不比對 `task_id`／`task_desc` 與 `tasks.md`，故 `touched ensure` 照樣 rc 0。修正為依 `cash instructions apply --json` 的現行 id 重建六筆 per-task 紀錄。
