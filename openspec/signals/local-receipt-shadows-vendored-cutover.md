---
id: local-receipt-shadows-vendored-cutover
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-28
last_seen: 2026-07-28
links:
  - openspec/changes/add-repo-vendored-cash-bundle/reviews/propose-r1.md
---

# Local receipt shadows a vendored cutover

一個工具從 machine-local receipt trust mode 遷移到 repo-vendored manifest trust mode，但模式選擇仍優先讀取舊 receipt。已安裝過的團隊成員在 pull 到新 manifest 後便繼續走舊信任鏈，fresh clone 與既有工作樹產生不同結果，讓「提交一次、全隊生效」的 cutover 保證失效。

修法是以 committed mode marker 決定模式：manifest 存在時必須完整驗證 manifest，且不得因 manifest 無效或本機 receipt 尚存而 fallback；receipt 只在 manifest 缺席的既有模式生效。

## Occurrences

- 2026-07-28 — add-repo-vendored-cash-bundle — cash-propose round 1 — 初稿保留 receipt-first launcher 流程，使曾執行舊 installer 的成員會忽略新提交的 manifest；修正為 manifest path presence 優先且 invalid manifest fail closed，不回退 receipt。
