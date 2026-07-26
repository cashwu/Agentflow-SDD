---
id: assertion-weaker-than-normative-statement
type: recurring-finding
status: open
occurrences: 2
first_seen: 2026-07-25
last_seen: 2026-07-26
links:
  - openspec/changes/derive-version-assertion-and-add-cli-help/reviews/propose-r2.md
  - openspec/changes/harden-trace-path-containment-and-label-shape/reviews/propose-r1.md
---

# 驗收斷言弱於其對應的 normative 陳述

spec 或 Implementation Contract 訂下一條較強的 MUST（例如排序、逐元素相等），但對應的驗收只斷言較弱的性質（例如集合相等），使違反該 MUST 的實作能通過全部斷言。這與「宣稱檢查、實際不檢查」同型，差別在於落差出現在規範與驗收之間而非規範與實作之間。

## Occurrences

- 2026-07-25 — derive-version-assertion-and-add-cli-help — cash-propose round 2 — spec 與 IC 要求 help 的 `commands` 欄位為排序後的 dispatch table key 陣列，但 IC4 與 tasks 只斷言集合相等；`COMMANDS` 的插入順序與排序後不同，因此 `list(COMMANDS)` 會違反 MUST 卻通過全部斷言。修法為改為逐元素等於排序後序列。
- 2026-07-26 — harden-trace-path-containment-and-label-shape — cash-propose round 1 — design 決策的核心是「MUST 為拒絕而非解析」，但 tasks 的對應 case 只斷言「該原字面值不在結果中」。一個把條件誤讀為「濾掉不合格的路徑段」再重組的實作會產生 `outside/x.py`、`a/b.py` 這類落在 repo 內的合法值，因而通過全部斷言，使該決策完全未被固定。修法是把拒絕類 case 的斷言改為集合相等。
