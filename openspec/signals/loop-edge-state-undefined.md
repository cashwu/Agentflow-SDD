---
id: loop-edge-state-undefined
type: recurring-finding
status: open
occurrences: 2
first_seen: 2026-07-16
last_seen: 2026-07-16
links:
  - openspec/changes/converge-plus-review-loop/reviews/propose-r1.md
  - openspec/changes/converge-plus-review-loop/reviews/apply-r2.md
---

# Loop edge state record contract undefined

A new loop or gate mechanism defines its happy path but leaves an edge path's record contract undefined — which file carries the outcome, what enum value applies, when the condition is evaluated (e.g. a zero-round abort, a mid-fix-phase state change) — so a literal follower hits mutually unsatisfiable MUSTs. The fix is enumerating every abort/edge path and assigning it a carrier, a value, and an evaluation point.

## Occurrences

- 2026-07-16 — converge-plus-review-loop — spectra-propose-plus rounds 5–6 — 全裁判面保護的 seeded re-run 短路在零輪次 run 的判定時點未定義；spawn 前短路 round file 的 round_type 無合法值可填（full 違反必 spawn 兩 reviewer、micro 違反首輪必 full）。
- 2026-07-16 — converge-plus-review-loop — spectra-apply-plus round 2 — fully protected seeded re-run 的短路已定義 round file 與 ledger，但 completion output 的恢復路徑未要求導向取得同意或透過 `/spectra-ingest` 擴充 structured scope。
