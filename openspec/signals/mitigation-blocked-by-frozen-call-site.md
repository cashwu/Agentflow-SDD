---
id: mitigation-blocked-by-frozen-call-site
type: recurring-finding
status: open
occurrences: 2
first_seen: 2026-07-25
last_seen: 2026-07-27
links:
  - openspec/changes/align-cli-skill-contracts/reviews/propose-r1.md
  - openspec/changes/target-receipt-bootstrap/reviews/propose-r1.md
---

# Mitigation blocked by frozen call site

A breaking default is accepted on the grounds that callers can opt back into the old behavior with a flag, without checking whether the callers can be edited at all. When the call sites are pinned by byte-exact assertions, content digests, or verbatim spec quotations, the escape hatch exists in the CLI but is unreachable from every real consumer.

## Occurrences

- 2026-07-25 — align-cli-skill-contracts — cash-propose round 1 — search 預設排除 archive 的緩解宣稱既有呼叫點可加 --scope all，但那些呼叫點被 skill-checks.fish 的 byte-exact 斷言、guidance 的 sha256 baseline 與 master spec 的逐 byte 引用三重凍結；最終改為收窄排除範圍而非依賴該緩解。
- 2026-07-27 — target-receipt-bootstrap — cash-propose round 1 — 原設計以「launcher 診斷附加 init 指引」作為使用者引導緩解，但 launcher bytes 被 master spec stable freeze 條款、`test_bundle_version_history.py` 的 introduction-commit byte 斷言與 `publish_launcher` 的 migration error 三重凍結，緩解在每個真實 target 都不可達；改由部署到 target 的 guidance 區塊承擔引導。
