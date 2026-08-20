---
id: exact-transition-allowlist-strands-lagging-targets
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-08-20
last_seen: 2026-08-20
links:
  - openspec/changes/tolerate-remount-device-renumbering/reviews/propose-r1.md
---

# Exact-pair migration allowlist strands targets more than one hop behind

A bootstrap artifact may only be replaced when an exact `(old, new)` pair appears in an approved-transition allowlist, with no chain derivation and no force override. A change that modifies the artifact registers exactly one new pair — from the immediately previous version — and thereby permanently strands every target still holding an older version, because the shipped installer offers only its own `new` digest and the target's `old` digest matches no entry. The failure is loud but unrecoverable through any documented path. The stranding is worst when the defect being fixed is itself what froze those targets in place, so the stranded population overlaps precisely with the population the change is meant to rescue. Check whether the history gate validates allowlist membership only for the entry derived from history; if so, extra catch-up entries sharing the same `new` digest are legal and should be registered.

## Occurrences

- 2026-08-20 — tolerate-remount-device-renumbering — cash-propose round 1 — 兩位 reviewer 獨立指出，`launcher_update` 以精確 (old, new) 配對授權替換且 `--force` 不繞過，而變更只登錄 `(2.12.0 的 launcher, 新 launcher, 2.13.0)` 一筆，任何仍停在更舊 launcher 的 target 升級時會以 `stable launcher drift requires an approved exact bootstrap migration` 永久 fail closed。history gate 的檢查是「由 first-parent history 推導出的那一筆存在於集合中」的成員檢查、重複檢查以完整三元組為單位，因此追加一筆 skip transition 合法。修法是同時登錄兩筆，並在端到端驗證加入一個停在更舊 launcher 的 fixture target。
