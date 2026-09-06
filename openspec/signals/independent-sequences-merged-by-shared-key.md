---
id: independent-sequences-merged-by-shared-key
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-09-05
last_seen: 2026-09-05
links:
  - openspec/changes/add-host-derived-round-lint/reviews/propose-r1.md
---

# Independent sequences merged by a shared key

兩組各自從相同起點編號的獨立序列共用同一個命名空間或目錄，而規則以「最高編號者」這類跨序列的單一鍵取值，於是其中一組的進度會遮蔽另一組。錯誤的方向通常不對稱：被遮蔽的那一組往往正是需要該規則生效的那一組。凡序列有「每個 X 各自從 1 起算」的性質，全部排序、邊界推導與狀態判定都必須逐 X 分組進行。

## Occurrences

- 2026-09-05 — add-host-derived-round-lint — cash-propose round 1 — 迴圈活動狀態的判定取 `reviews/` 下「最高編號 round file」的 `## Decision`，但 `propose-r<N>.md` 與 `apply-r<N>.md` 是各自從 `r1` 起算的兩個獨立序列且同處一個目錄。`propose-r3`（`passed`）與 `apply-r1`（`next_round`）並存時，跨序列最高編號者是 propose-r3，於是迴圈被判為非 active，唯一具實質約束力的 `grader_immutability` gate 在整個 cash-apply loop 期間全程 `skip`——而 apply 階段正是最會改動受保護裁判面的階段。同一份 design 的另一個 decision 已正確地把 run 邊界推導限定在「某個 skill 的序列」，活動判定卻退回跨序列取值，屬自身不一致。
