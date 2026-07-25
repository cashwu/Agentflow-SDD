---
id: newline-byte-class-excludes-only-lf
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-25
last_seen: 2026-07-25
links:
  - openspec/changes/tolerate-versioned-legacy-guidance-marker/reviews/apply-r1.md
---

# Newline byte class excludes only LF

以 byte pattern 限制欄位不得跨越換行時，只排除 LF 而遺漏 CR，導致 CR-only 行界後的資料仍被匹配並納入 managed span。修正時應同時排除 `\r` 與 `\n`，並用 CR 邊界 fixture 驗證。

## Occurrences

- 2026-07-25 — tolerate-versioned-legacy-guidance-marker — cash-apply round 1 — `marker_matches` 的 suffix class 原為 `[^<>\n]+`，會把 CR-only 行界後的 project-owned bytes 視為 marker 字尾；改為 `[^<>\r\n]+` 並加入 fail-closed fixture。
