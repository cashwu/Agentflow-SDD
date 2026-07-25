---
id: shape-removal-silently-degrades-consumer
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-25
last_seen: 2026-07-25
links:
  - openspec/changes/align-cli-skill-contracts/reviews/propose-r1.md
---

# Shape removal silently degrades consumer

A change removes a structural convention (a heading, a label row, a nested list shape) after checking only that no code errors on its absence. Consumers that parse by locating that shape do not fail — they return empty or skip, so the loss surfaces as a feature quietly never firing rather than as a broken build.

## Occurrences

- 2026-07-25 — align-cli-skill-contracts — cash-propose round 1 — 刪除 cash-propose 的三個型別模板會一併帶走 ## Impact 與 ## Capabilities 的子結構，而 spec 合併的 trace 產生與 impact 粒度提示都靠該形狀定位，兩者在形狀消失時皆為靜默降級。
