---
id: translation-negation-scope-drift
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-19
last_seen: 2026-07-19
links:
  - openspec/changes/chinese-spec-content/reviews/apply-r1.md
---

# Translation negation scope drift

When normative text is translated, a negation's scope silently narrows or shifts: the source negates an entire predicate ("not accepted through consent" = everything except consent-path acceptance), but the most natural reading of the translated word order negates only part of it ("accepted without consent" = an empty or different set). Mechanical invariants (token counts, code-span multisets) cannot catch this because the normative tokens are all still present. The fix is a review pass dedicated to negation-bearing sentences, comparing the decidable OUTCOME of each rule against the source, not the word-for-word rendering.

## Occurrences

- 2026-07-19 — chinese-spec-content — cash-apply round 1 — spec「Abort 後的 triage」bucket 1 定義句 "not accepted through consent" 譯為「未經同意被接受」，中文自然讀法變成「被接受但未經同意」（依 ledger 規則為空集合），bucket 1 作為 re-run seed 母集合的判定邊界被反轉；修正為「未經由同意路徑被接受」。
