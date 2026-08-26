---
id: malformed-metadata-misclassified-as-absent
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-08-27
last_seen: 2026-08-27
links:
  - openspec/changes/per-change-tdd-override/reviews/apply-r1.md
---

# Malformed metadata misclassified as absent

Metadata lookup narrows the field prefix to one canonical spacing shape before classifying the value. A present-but-malformed field is therefore treated as absent and silently enters the missing-field fallback, bypassing the warning or fail-closed behavior defined for invalid input; a later duplicate may also be selected even though first-match semantics require the malformed first field to remain authoritative.

## Occurrences

- 2026-08-27 — per-change-tdd-override — cash-apply round 1 — Step 5 只搜尋 `tdd: `，使 `tdd:true` 或 tab suffix 被當成缺行而靜默 fallback，並可能改採後續合法行；修正為先定位第一個 unindented `tdd:` prefix，再嚴格分類完整 suffix。
