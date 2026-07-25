---
id: detection-criterion-false-positive-on-legitimate-form
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-25
last_seen: 2026-07-25
links:
  - openspec/changes/align-cli-skill-contracts/reviews/propose-r1.md
---

# Detection criterion false positive on legitimate form

A new mechanical check is specified by describing the defect's shape, but the description also matches a legitimate construct that shares that shape, so the check fails on correct files. The criterion is written from the defect alone without enumerating the legitimate forms it must not match, and is adopted without running it against the real corpus.

## Occurrences

- 2026-07-25 — align-cli-skill-contracts — cash-propose round 1 與 round 2 — 空 code span 判準先後兩版都誤判 markdown 合法的雙反引號跳脫；第二版經對 24 個 canonical SKILL.md 實跑後才改為 run 計數形式並取得零偽陽性。
