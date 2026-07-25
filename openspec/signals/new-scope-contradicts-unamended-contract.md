---
id: new-scope-contradicts-unamended-contract
type: recurring-finding
status: open
occurrences: 3
first_seen: 2026-07-24
last_seen: 2026-07-25
links:
  - openspec/changes/guard-target-receipt-version-control/reviews/propose-r1.md
  - openspec/changes/harden-installer-mode-and-recovery/reviews/propose-r6.md
  - openspec/changes/align-cli-skill-contracts/reviews/propose-r1.md

---

# New scope contradicts unamended contract

A delta introduces behavior that contradicts a closed enumeration or an exclusive-scope MUST in an existing requirement, but the delta is ADDED-only and never amends the requirement it invalidates, so the merged master spec becomes self-contradictory.

## Occurrences

- 2026-07-24 — guard-target-receipt-version-control — cash-propose round 1 — 新增的 `.gitignore` 寫入牴觸既有「其他 project-owned bytes 維持不變」「failure 只回滾…」「全部一致回報 current 且零寫入」三處封閉列舉，以及 `--self` 的「real run 只寫 receipt」；delta 全為 ADDED，未以 MODIFIED 承接。

- 2026-07-25 — harden-installer-mode-and-recovery — cash-propose round 6 — 新增的 recovery 會在分類前寫入 target，與 delta 中原文保留、未修訂的 `conflict` 零寫入 scenario 直接牴觸；補上 carve-out 說明零寫入契約自 recovery 完成後的重新分類起適用。
- 2026-07-25 — align-cli-skill-contracts — cash-propose round 1 — drift 的 primary_recommendation 改為不含 invocation 前綴，但 cash-drift 兩個變體的 SKILL.md 仍逐字宣稱該欄位是 a single copy-pasteable command line 並指示直接執行其值，未修訂即成為假敘述。
