---
id: trust-root-inventory-blocks-payload-extension
type: recurring-finding
status: open
occurrences: 2
first_seen: 2026-07-26
last_seen: 2026-07-27
links:
  - openspec/changes/rightsize-cash-skills/reviews/propose-r1.md
  - openspec/changes/target-receipt-bootstrap/reviews/propose-r1.md
---

# Trust root inventory blocks payload extension

A change plans to add files to a managed payload, but the integrity trust root enumerates the payload as a fixed list and compares the receipt for exact equality, so every command fails closed once the payload grows. The trust root is itself frozen by a history test, and the receipt parser rejects differing record counts, leaving existing installations with no upgrade path. The single-file-per-unit shape turns out to be an architectural constraint written into the root of trust, not an installer implementation detail.

## Occurrences

- 2026-07-26 — rightsize-cash-skills — cash-propose round 1 — 把 review loop 本文抽成 skill 目錄下的 reference 檔，撞上 `.cash-skills/bin/cash` 硬編碼的 24 條 `SKILL.md` 路徑與 receipt 完全相等比對；該 launcher 又被 `test_bundle_version_history.py` 的 `STABLE_PATHS` 無條件凍結在引入 commit，且 `parse_receipt` 以記錄數硬比對使既有 target 無升級路徑。該層次已拆為獨立 change。
- 2026-07-27 — target-receipt-bootstrap — cash-propose round 1 — 同一 issue class 的兩個面向同時命中：launcher 的 runtime record 路徑檢核（僅接受 `.cash-skills/lib/cash_cli/*.py`）使 `.cash-skills/bin/` 下的新 record 不可能被接受，而 `parse_receipt` 的記錄數硬比對使任何 inventory 擴充讓既有 targets 在版本比較前以 execution error 失敗且 `--force` 不可繞過。最終設計改為把 init 邏輯嵌入既有 runtime record（零新檔、零 inventory 擴充）以完全避開本約束。
