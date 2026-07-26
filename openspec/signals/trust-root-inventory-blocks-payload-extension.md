---
id: trust-root-inventory-blocks-payload-extension
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-26
last_seen: 2026-07-26
links:
  - openspec/changes/rightsize-cash-skills/reviews/propose-r1.md
---

# Trust root inventory blocks payload extension

A change plans to add files to a managed payload, but the integrity trust root enumerates the payload as a fixed list and compares the receipt for exact equality, so every command fails closed once the payload grows. The trust root is itself frozen by a history test, and the receipt parser rejects differing record counts, leaving existing installations with no upgrade path. The single-file-per-unit shape turns out to be an architectural constraint written into the root of trust, not an installer implementation detail.

## Occurrences

- 2026-07-26 — rightsize-cash-skills — cash-propose round 1 — 把 review loop 本文抽成 skill 目錄下的 reference 檔，撞上 `.cash-skills/bin/cash` 硬編碼的 24 條 `SKILL.md` 路徑與 receipt 完全相等比對；該 launcher 又被 `test_bundle_version_history.py` 的 `STABLE_PATHS` 無條件凍結在引入 commit，且 `parse_receipt` 以記錄數硬比對使既有 target 無升級路徑。該層次已拆為獨立 change。
