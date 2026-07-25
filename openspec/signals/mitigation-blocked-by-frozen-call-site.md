---
id: mitigation-blocked-by-frozen-call-site
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-25
last_seen: 2026-07-25
links:
  - openspec/changes/align-cli-skill-contracts/reviews/propose-r1.md
---

# Mitigation blocked by frozen call site

A breaking default is accepted on the grounds that callers can opt back into the old behavior with a flag, without checking whether the callers can be edited at all. When the call sites are pinned by byte-exact assertions, content digests, or verbatim spec quotations, the escape hatch exists in the CLI but is unreachable from every real consumer.

## Occurrences

- 2026-07-25 — align-cli-skill-contracts — cash-propose round 1 — search 預設排除 archive 的緩解宣稱既有呼叫點可加 --scope all，但那些呼叫點被 skill-checks.fish 的 byte-exact 斷言、guidance 的 sha256 baseline 與 master spec 的逐 byte 引用三重凍結；最終改為收窄排除範圍而非依賴該緩解。
