---
id: fixture-assertion-depends-on-unspecified-order
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-26
last_seen: 2026-07-26
links:
  - openspec/changes/harden-trace-path-containment-and-label-shape/reviews/propose-r2.md
---

# Fixture assertion depends on an order the fixture never constrains

一個 scenario 或測試 fixture 要求多個元素同時存在（例如「一個不被接受的形式」加上「一個對照用的正常形式」），但沒有約束它們的相對順序，而斷言的成立與否恰恰取決於該順序。撰寫者以自己心中的排列驗證後即認定斷言成立，另一種同樣符合 GIVEN 的排列卻使斷言對一個完全正確的實作為假。

這個缺陷特別難察覺，因為它常由一個好的修法引入：把「不可觀察的內部狀態」改寫成「可觀察的輸出」時，需要在 fixture 中加入對照元素，而對照元素的位置就成了新的、未被言明的前提。後果是實作者照字面除錯時，唯一能讓斷言轉綠的修法往往被同一份文件的 Non-Goals 明文禁止。

修法是在 GIVEN 與 fixture 要求中逐字寫出順序約束，並附上「為什麼順序在此有語意」的機制說明，使後人不會把它當成可任意調整的風格選擇。

## Occurrences

- 2026-07-26 — harden-trace-path-containment-and-label-shape — cash-propose round 2 — 為了讓「粗體標籤不被視為子清單起點」可被觀察，scenario 改為要求同一份 proposal 另含一個精確形狀的子清單並斷言 `code` 恰等於後者。但 `- **Affected code:**` 經 strip 後既不成為子清單起點、**也不成為同層終止條件**，因此當精確子清單排在粗體標籤之前時，粗體標籤與其下路徑會被當成該子清單的一般內容行收進 `code`，斷言對一個完全符合 Implementation Contract 的實作為假（實測 `['bold/leak.py', 'exact/ok.py']`）。而實作者照字面除錯的唯一修法——把粗體納入起點或終止條件——分別被 proposal 與 design 的 Non-Goals 直接禁止。
