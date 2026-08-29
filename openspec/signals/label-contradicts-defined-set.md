---
id: label-contradicts-defined-set
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-08-29
last_seen: 2026-08-29
links:
  - openspec/changes/strengthen-archive-commit-guidance/reviews/propose-r1.md
---

# 指稱標籤與同句定義的集合矛盾

同一條規範句先以枚舉明確定義一個集合（例如 dirty 路徑「含 staged、unstaged 與 untracked」），隨後卻用一個語意較窄或互斥的標籤指稱該集合的成員（例如「列出這些未提交的 tracked source 檔案」——untracked 成員按字面不是 tracked）。按字面實作時部分成員會被排除，或實作者被迫在標籤與集合定義之間自行擇一，兩種讀法產生不同行為。修法是讓指稱標籤與集合定義一致（改用涵蓋全集合的中性稱呼），或直接以集合定義本身指稱，不引入第二個分類詞。

## Occurrences

- 2026-08-29 — strengthen-archive-commit-guidance — cash-propose round 1 — proposal、design D2 與 delta spec ADDED requirement 同句中，交集定義明文含 untracked，列出對象卻寫「未提交的 tracked source 檔案」；兩位 reviewer 獨立命中同一矛盾。修正為三處統一改為「未提交的 source 檔案」。
