---
id: multi-operation-phase-order-undefined
type: recurring-finding
status: open
occurrences: 3
first_seen: 2026-07-23
last_seen: 2026-07-28
links:
  - openspec/changes/replace-spectra-cli-with-cash-cli/reviews/propose-r3.md
  - openspec/changes/harden-installer-mode-and-recovery/reviews/propose-r4.md
  - openspec/changes/harden-installer-mode-and-recovery/reviews/propose-r5.md
  - openspec/changes/add-repo-vendored-cash-bundle/reviews/propose-r2.md

---

# Multi-operation phase order undefined

A transaction accepts several operations over the same logical identity but does not define their legal combinations, collision rules, and deterministic phase order, making results depend on iteration order or causing a valid combined change to fail midway.

## Occurrences

- 2026-07-23 — replace-spectra-cli-with-cash-cli — cash-propose round 3 — sync允許同一requirement的MODIFIED與RENAMED卻未定義順序；修正為MODIFIED/REMOVED、ADDED、RENAMED固定phases與完整collision matrix。

- 2026-07-25 — harden-installer-mode-and-recovery — cash-propose rounds 4–5 — journal recovery 的呼叫點相對於 conflict 判定與 `newer` early return 的順序未定義：置於 conflict 之後則 receipt-managed 半發布狀態永遠先回報 conflict 而恢復不可達；置於 `newer` 之前則 newer target 會被寫入而違反零寫入契約。修正為把偵測與恢復拆成兩個位置。

- 2026-07-28 — add-repo-vendored-cash-bundle — cash-propose round 2 — source `--self` 同時要發布 portable manifest 並清除舊 receipt residue，但初稿一面宣稱 manifest 是最後寫入，一面把 receipt cleanup 放在其後；修正為把 receipt 刪除納入 journal，並明定 manifest commit point 前後的 rollback／roll-forward phase。
