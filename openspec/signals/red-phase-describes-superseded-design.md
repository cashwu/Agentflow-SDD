---
id: red-phase-describes-superseded-design
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-09-05
last_seen: 2026-09-05
links:
  - openspec/changes/dispatch-vendored-targets-in-batch/reviews/propose-r3.md
---

# Red phase describes a superseded design instead of the pre-change baseline

一個 task 的 `red` 欄描述的失敗，是「若照某個**已被審查推翻的設計**實作會發生的失敗」，而不是「變更前的實際基線下該斷言為何不成立」。這通常在審查迴圈重寫設計之後發生：修正把 success 條件改對了，卻沿用上一版設計的失敗敘述。後果是該 task 實際上沒有 red phase——它的全部斷言在變更前就已成立，只是個 regression pin——而 TDD discipline 卻把它記為有 red 的行為變更。辨識方法是把 success 的每一條斷言拿到未修改的程式碼上逐條求值：若全部成立，red 必為 N/A 並依 pure-refactor 或 remaining-task 分類，不能寫成某種假想實作的失敗。

## Occurrences

- 2026-09-05 — dispatch-vendored-targets-in-batch — cash-propose round 3 — 兩個 task 同時犯。2.4 的 red 寫「FIFO 情境因被分派到 vendored 路徑、在 pre-lock snapshot 開檔時阻塞而觸發 subprocess timeout」，但那是 round 1 那版被推翻的設計；變更前 `--all` 一律走 `install_target`，三種 shape 都在 `path_is_present` 後即被既有拒絕擋下、零寫入且不阻塞。2.5 的 red 寫「probe 未捕捉 `InstallerError`、例外逸出 per-record try」，但變更前根本沒有 probe，該例外由 `install_target` 內同一個 `ensure_contained` 拋出並被迴圈捕捉計為 `failed`。修法是 2.5 改為 `N/A — pure-refactor` 的 regression pin，2.4 改用 hard-linked manifest 這個變更前後確有可觀察差異的載體取得真實 red。
