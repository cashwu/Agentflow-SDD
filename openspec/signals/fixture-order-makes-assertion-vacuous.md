---
id: fixture-order-makes-assertion-vacuous
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-28
last_seen: 2026-07-28
links:
  - openspec/changes/target-receipt-bootstrap/reviews/apply-r1.md
---

# Fixture order makes the assertion vacuous

一個測試以「先全面驗證、再統一施作」的兩段式不變式為目標，fixture 卻把觸發失敗的元素排在被觀測的元素之前。實作一遇到觸發元素就中止，被觀測的元素根本沒被走到，於是「它沒有被改動」這個斷言恆真——測試在正確實作與把兩段合併成單次交錯 loop 的錯誤實作下都會綠燈，不變式從未真正被驗證。

與 [[fixture-assertion-depends-on-unspecified-order]] 同屬「fixture 的相對順序是承重的但未被言明」，方向相反：那一個是順序使斷言對正確實作為假，這一個是順序使斷言對錯誤實作為真。後者更難察覺，因為沒有任何紅燈提示。

修法是把觸發元素排在被觀測元素之後，使被觀測元素必然先被走過，並在 design 或 tasks 逐字寫出這個順序要求與它的機制理由。驗證方式是差分實驗：暫時把實作改成要防的錯誤形狀，確認測試轉紅。

## Occurrences

- 2026-07-28 — target-receipt-bootstrap — cash-apply round 1 — `test_non_regular_managed_shape_fails_closed_without_chmod` 要驗證「`init_normalize_modes` 先驗證整份 managed inventory 的形狀、再統一 chmod，因此失敗時零 chmod」。fixture 把 unsafe 形狀放在 `SKILL_PATHS[0]`、被 skew mode 的對照檔放在 `SKILL_PATHS[1]`，而 receipt 順序中前者必早於後者，第一段 loop 一遇 unsafe 即 raise，對照檔的 `0664` 自然不變。反轉 fixture（skew `SKILL_PATHS[0]`、unsafe `SKILL_PATHS[-1]`）後，reviewer 以差分實驗確認：把實作改成單次交錯 loop 會使斷言失敗，還原兩段式則通過。hardlink 案例另需改由非 inventory 檔建立硬連結，否則會同時污染對照檔的 `st_nlink`。
