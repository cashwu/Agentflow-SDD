---
id: stable-lock-identity-lifecycle-undefined
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-23
last_seen: 2026-07-23
links:
  - openspec/changes/replace-spectra-cli-with-cash-cli/reviews/propose-r6.md
---

# Stable lock identity lifecycle undefined

A runtime and installer claim to synchronize through a stable lock but do not define one persistent inode identity across creation, upgrade, failure rollback, recovery, and concurrent openers. Unlinking or replacing a published lock can split participants across independent lock domains.

## Occurrences

- 2026-07-23 — replace-spectra-cli-with-cash-cli — cash-propose rounds 4–6 — bootstrap identity與generation oracle已補齊，但known-old migration rollback仍會unlink已公開lock，可能讓等待者與新installer分持不同inode；此項在round 6保持blocking。
