---
id: new-scope-contradicts-unamended-contract
type: recurring-finding
status: open
occurrences: 6
first_seen: 2026-07-24
last_seen: 2026-08-20
links:
  - openspec/changes/guard-target-receipt-version-control/reviews/propose-r1.md
  - openspec/changes/harden-installer-mode-and-recovery/reviews/propose-r6.md
  - openspec/changes/align-cli-skill-contracts/reviews/propose-r1.md
  - openspec/changes/guard-post-archive-commit-allowlist/reviews/propose-r1.md
  - openspec/changes/track-review-loop-outputs-in-allowlist/reviews/propose-r1.md

  - openspec/changes/tolerate-remount-device-renumbering/reviews/propose-r1.md
---

# New scope contradicts unamended contract

A delta introduces behavior that contradicts a closed enumeration or an exclusive-scope MUST in an existing requirement, but the delta is ADDED-only and never amends the requirement it invalidates, so the merged master spec becomes self-contradictory.

## Occurrences

- 2026-07-24 — guard-target-receipt-version-control — cash-propose round 1 — 新增的 `.gitignore` 寫入牴觸既有「其他 project-owned bytes 維持不變」「failure 只回滾…」「全部一致回報 current 且零寫入」三處封閉列舉，以及 `--self` 的「real run 只寫 receipt」；delta 全為 ADDED，未以 MODIFIED 承接。

- 2026-07-25 — harden-installer-mode-and-recovery — cash-propose round 6 — 新增的 recovery 會在分類前寫入 target，與 delta 中原文保留、未修訂的 `conflict` 零寫入 scenario 直接牴觸；補上 carve-out 說明零寫入契約自 recovery 完成後的重新分類起適用。
- 2026-07-25 — align-cli-skill-contracts — cash-propose round 1 — drift 的 primary_recommendation 改為不含 invocation 前綴，但 cash-drift 兩個變體的 SKILL.md 仍逐字宣稱該欄位是 a single copy-pasteable command line 並指示直接執行其值，未修訂即成為假敘述。

- 2026-07-25 — guard-post-archive-commit-allowlist — cash-propose round 1 — 新增的 step `2a` 以 archive manifest 的 `touched_files` 作為來源允許清單，與同一份 SKILL.md 內未修訂的絕對句 `Cash state is the only allowlist authority after this point.` 直接牴觸；修法是把該句改寫為帶 `2a` 例外的形式並將例外字面句納入機械斷言。

- 2026-07-25 — track-review-loop-outputs-in-allowlist — cash-propose round 1 — 新增的 `touched record` verb 在 `cash-propose` 情境下必然是第一次 touched access，與 master `Change 與 artifact lifecycle` 的「第一次Cash touched access MUST統一透過`touched ensure <name>`」牴觸，而 delta 只 MODIFIED 了 command surface 的封閉列舉、未修訂此條；同一批還把 legacy import 的 fail-closed 語意從 ensure 一個進入點擴散為兩個。修法不是補 MODIFIED，而是規定 record 在 state 不存在時 fail closed、呼叫端先執行 ensure，使不變量得以保留。

- 2026-08-20 — tolerate-remount-device-renumbering — cash-propose round 1 — 新的診斷分類把「bytes 相同但 mode 漂移」歸入 content drift 並禁止建議重新簽發，但未修改的 `Target-local receipt 初始化` requirement 明訂「bytes 一致但 mode 已漂移時 MUST 走一般簽發路徑重寫」，且既有 guidance 對 launcher 在該狀態產生的 `bootstrap_invalid` 的處置正是執行一次重新簽發。同一份 target 會從兩個 gate 拿到相反指引。修法是把分類軸從「digest 或 mode」收斂為只用 digest。
