---
id: exclusion-without-matching-inclusion
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-25
last_seen: 2026-07-25
links:
  - openspec/changes/guard-post-archive-commit-allowlist/reviews/apply-r1.md
---

# Exclusion without matching inclusion

A change adds a new computed set and remembers to exclude it from the catch-all bucket, but never wires it into the bucket that actually gets acted on. The item then falls into the hole between the two: it is no longer reported as unrelated, and it is not committed, staged, or applied either. This is the inverse of a catch-all shadowing a specific rule — here the item escapes the catch-all and nothing downstream catches it. The fix is to require, for every new set, an explicit statement of which output it joins, not only which output it leaves.

## Occurrences

- 2026-07-25 — guard-post-archive-commit-allowlist — cash-apply round 1 與 round 2 — `cash-commit` 的 step `2a` 新增 spec sync 集合並讓 step 4 把它排除在 Unrelated 之外，但區段產生被多綁了「來源為 archive manifest」條件、且全文沒有一句宣告該集合屬於提交集合，通過 digest 比對的 `openspec/specs/` 路徑因此可能從 commit plan 消失或顯示但不 stage。兩個 reviewer 從不同角度獨立指出後合併。round 1 的修復補上「三個集合屬提交集合」的宣告後，round 2 又發現同一輪改寫的 STOP 判定輸入只列了三集合中的兩個，spec sync 集合非空時仍會在 `## Nothing to Commit` 被丟掉——同一個洞在修復中換位置復發。
