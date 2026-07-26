---
id: detection-criterion-infeasible-in-harness
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-26
last_seen: 2026-07-26
links:
  - openspec/changes/rightsize-cash-skills/reviews/propose-r4.md
---

# Detection criterion infeasible in harness

A spec or design defines a detection rule that the existing test harness cannot express — most often by requiring two conditions to co-occur on a single line when the real occurrences span multiple lines, or by assuming a matcher mode the suite's tools do not provide. The assertion built from it silently under-counts instead of failing, so the requirement reads as enforced while covering nothing.

## Occurrences

- 2026-07-26 — rightsize-cash-skills — cash-propose round 4 — fallback 判定條件被寫成 (a) 不可用條件與 (b) 純文字子句同行出現，但 `cash-apply:79`–`:81`、`:139`–`:141`、`cash-ingest:110`–`:112` 的條件獨立成行、替代作法在後續行，同行比對會計為零。修正為多行視窗比對並把視窗界定為同一段落而非固定行數。
