---
id: false-positive-fix-widens-exemption-into-bypass
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-09-05
last_seen: 2026-09-05
links:
  - openspec/changes/add-host-derived-round-lint/reviews/propose-r4.md
---

# False-positive fix widens an exemption into a bypass

一個 gate 被發現對合法工作產生偽陽性，修法是放寬其例外條件的來源範圍；但放寬後的來源集合包含了受審者可寫的位置，於是同一個修正把偽陽性換成了旁路——受審者只要在該來源寫下想解除的對象即可。偽陽性與旁路是同一個維度的兩端，收緊會誤擋、放寬會漏擋，因此放寬例外來源時必須同時檢查該來源的寫入治理；若來源本身不受保護，放寬只能縮小到「提高偽造成本」而非「消除偽陽性」，且未關閉的部分必須逐字記為 Risk。

## Occurrences

- 2026-09-05 — add-host-derived-round-lint — cash-propose round 4 — 前一輪為修正「變更集合是 repository 全域而宣告是 per-change，兩個 active change 並存時 A 合法宣告的改動會在 B 的比對中判為未宣告」這個偽陽性，把涵蓋判定改為取**全部被列舉 change** 宣告的聯集。但列舉集合是全部非 archive 目錄加上全部 parked change，而 `openspec/changes/` 不在受保護路徑集合內——受審者只要新建或編輯任一無關 change 的 `## Impact` 寫上受保護路徑，即可對所有 change 永久解除該 gate，且被審查的 change 自身 artifacts 看起來乾淨。收窄為「僅本身 active 的被列舉 change」只提高偽造成本（需一併偽造 round file），未關閉該路徑。
