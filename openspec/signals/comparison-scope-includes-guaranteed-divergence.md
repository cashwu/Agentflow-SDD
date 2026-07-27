---
id: comparison-scope-includes-guaranteed-divergence
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-27
last_seen: 2026-07-27
links:
  - openspec/changes/cash-skill-maintainability/reviews/propose-r1.md
---

# Comparison scope includes guaranteed divergence

一條「逐字相同／byte-identical」的一致性要求，其比較範圍把必然相異的內容含入邊界——例如因所在檔案而異的清單編號、檔案專屬的識別字或前綴——使該要求照字面讀法永不可能成立，實作者只能靠猜測縮小範圍。正確做法是在 requirement 與驗收條款中明定邊界（排除必異內容），或規定先行正規化步驟，讓比較範圍本身可機械判定。

## Occurrences

- 2026-07-27 — cash-skill-maintainability — cash-propose round 1 — 「四份 gate 區段正規化後逐字相同」的比對範圍若含「Sub-Agent Review/Rating/Fix Loop」步驟標題行，propose 的清單編號 9. 與 apply 的 11. 必然不同，Contract 與 tasks 的驗收永不可達；修正為錨點置於標題行之後、標題行不屬於生成區段亦不參與比對。
