---
id: derived-verdict-not-recomputed-after-mechanism-swap
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-27
last_seen: 2026-07-27
links:
  - openspec/changes/cash-skill-maintainability/reviews/apply-r1.md
---

# Derived verdict not recomputed after mechanism swap

A change replaces the mechanism a spec table, example, or matrix describes, and dutifully rewrites the mechanism's name in the header — but the verdict cells underneath are carried over unchanged. Renaming reads as updating, so the stale rows survive review: each one still asserts an outcome the old mechanism produced and the new one cannot. The rows are the acceptance references implementers and reviewers check against, so a wrong verdict silently licenses wrong behavior. This differs from residual references to a removed mechanism, where the reference itself was never inventoried; here the reference was updated and only its derived data was left behind. The fix is to re-derive every verdict cell against the new mechanism — ideally by executing each row — instead of editing only the labels.

## Occurrences

- 2026-07-27 — cash-skill-maintainability — cash-apply round 1 — 對等機制由 diff manifest 比對改為重新生成 freshness 檢查時，`##### Example: 兩類缺陷與其偵測來源` 的表頭已由「對等比較結果」改寫為「freshness 比對結果」，但前兩列的判定仍沿用 manifest 模型下的 `通過`；生成器對全部十二個 skill 無條件移除 `context`／`agent`／`disallowedTools`，該情境下 freshness 必定失敗。修正後改為生成模型下 freshness 確實偵測不到的缺陷類別，並逐列以暫存 root 實際重現四列判定。
