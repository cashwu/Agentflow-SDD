---
id: mitigation-recorded-only-in-implementation-contract
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-25
last_seen: 2026-07-25
links:
  - openspec/changes/track-review-loop-outputs-in-allowlist/reviews/propose-r4.md
---

# Mitigation recorded only in implementation contract

A design names a failure mode that will occur in the shipped artifact's own runtime, then records the mitigation only in its Implementation Contract. That section binds whoever implements this change; it does not travel with the change. Nothing in the shipped skill text, spec, or task list carries the rule, so the failure mode arrives intact for every future user — often in precisely the scenario the design called out as most likely. The fix is to write the mitigation into the artifact that ships, and to assert it there.

## Occurrences

- 2026-07-25 — track-review-loop-outputs-in-allowlist — cash-propose round 4 — 設計指出「review loop 的 fix action 改到 CLI runtime 檔會使 launcher 全面 `receipt_invalid`，因此 receipt 常規 MUST 涵蓋 fix actions」，但該常規只寫在 Implementation Contract；出貨的 skill 文字、spec 與任務清單皆無對應規則，實測所有 SKILL 檔對 receipt 重建零命中。結果是本變更的旗艦情境恰好是它必然失效的情境。修法是把規則寫進 skill 文字並加入逐檔字面句斷言。
