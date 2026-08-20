---
id: precondition-demands-unperformed-verification
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-08-20
last_seen: 2026-08-20
links:
  - openspec/changes/tolerate-remount-device-renumbering/reviews/propose-r2.md
---

# Precondition demands verification the gate never performs

A new clause gates some output on "all the other records verify", written once and applied to every enforcement point. But the enforcement points do not all verify the same set: one of them only checks names, ordering, or metadata for a category whose contents the other hashes in full. The clause is then unobservable at the weaker point — implementing it literally adds a per-invocation cost nobody analyzed, and not implementing it leaves the requirement violated. The same trap appears when a clause names a derived value (a generation, a rollup digest) that one side recomputes from the stored record rather than from disk, and the other side never recomputes at all. Write the precondition per enforcement point, scoped to what that point already reads from disk, and state the asymmetry explicitly so it is not read as an oversight.

## Occurrences

- 2026-08-20 — tolerate-remount-device-renumbering — cash-propose round 2 — 指引前提被寫成「runtime generation 與每一筆 runtime／skill record 都相符」，但 launcher 從不對 24 個 skill 檔做 digest 比對（該路徑只用於 receipt 內的順序與 mode 檢查），照字面實作會在每次啟動新增 24 次檔案雜湊。第 3 輪又發現「runtime generation」在兩側都對不上：launcher 的 generation 重算是 receipt 內部一致性檢查，installer 根本沒有對 target 重算 generation。修法是依 gate 分寫前提範圍、兩側都移除 generation，並把 generation 不符歸回既有的 invalid-receipt 出口。
