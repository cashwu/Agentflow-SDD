---
id: append-without-separator-corrupts-tail
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-24
last_seen: 2026-07-24
links:
  - openspec/changes/guard-target-receipt-version-control/reviews/propose-r1.md
---

# Append without separator corrupts tail

A workflow appends managed lines to a project-owned text file without guaranteeing a separator, so a file whose last line lacks a terminator has that line silently merged with the appended content — destroying the user's rule while also failing to create the intended one, yet still reporting success.

## Occurrences

- 2026-07-24 — guard-target-receipt-version-control — cash-propose round 1 — 對 target `.gitignore` 的附加未定義無尾端行終止符時的處置，會產生 `node_modules.cash-skills/receipt.tsv`，同時毀掉既有規則且未建立所需規則。
