---
id: reserved-entry-sort-reorders-existing-tasks
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-25
last_seen: 2026-07-25
links:
  - openspec/changes/track-review-loop-outputs-in-allowlist/reviews/apply-r1.md
---

# 保留條目排序改動既有 task 順序

為新增保留條目而對完整 entries 集合重新排序，會改變既有 task attribution 的穩定順序；當 identifier 的語意順序不是字典序時，這種全域正規化尤其容易造成 `1, 10, 2` 類型的重排。

## Occurrences

- 2026-07-25 — track-review-loop-outputs-in-allowlist — cash-apply round 1 — `touched record` 原先為插入 `review-loop` 而依 UTF-8 task id 重排所有 entries，違反既有 per-task 條目不變的 contract；修正為原位更新保留條目或在不存在時尾端附加，並加入兩位數 task id regression test。
