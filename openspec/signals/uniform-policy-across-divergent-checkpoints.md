---
id: uniform-policy-across-divergent-checkpoints
type: recurring-finding
status: open
occurrences: 2
first_seen: 2026-07-24
last_seen: 2026-07-25
links:
  - openspec/changes/guard-target-receipt-version-control/reviews/propose-r1.md
  - openspec/changes/harden-installer-mode-and-recovery/reviews/propose-r1.md

---

# Uniform policy across divergent checkpoints

A fix states one uniform policy for a validation that runs at multiple checkpoints, but those checkpoints have divergent established contracts — one reclassifies and retries, another fails closed — so the uniform wording contradicts the implementation at one of them.

## Occurrences

- 2026-07-24 — guard-target-receipt-version-control — cash-propose round 2 — 修正把「不一致時重新分類」同時套用到 post-lock 與 publication 前兩個檢查點，但後者既有行為與 guidance 契約皆為 fail closed。

- 2026-07-25 — harden-installer-mode-and-recovery — cash-propose round 1 — 把「改用存在性判準」統一套用到混合了帶值參數與 `store_true` 布林 flag 的相容性守衛，會使 `False is not None` 恆真而讓整組 caller-input 守衛失效；修正為判準只套用於帶值參數。
