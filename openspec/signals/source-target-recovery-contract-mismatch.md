---
id: source-target-recovery-contract-mismatch
type: recurring-finding
status: open
occurrences: 2
first_seen: 2026-07-22
last_seen: 2026-07-23
links:
  - openspec/changes/migrate-cash-project-guidance/reviews/propose-r1.md
  - openspec/changes/replace-spectra-cli-with-cash-cli/reviews/propose-r5.md
---

# Source and target recovery contract mismatch

A recovery instruction is written as though the same repair path works for source and target state even though scope guards or ownership rules make one side ineligible for that operation.

## Occurrences

- 2026-07-22 — migrate-cash-project-guidance — cash-propose round 1 — Design要求重跑installer清理Spectra block，卻禁止source repository作為target；修正為target重跑installer、source透過版本控制還原，且合法source Spectra block不阻斷其他targets。
- 2026-07-23 — replace-spectra-cli-with-cash-cli — cash-propose rounds 5–6 — stable bootstrap規則套到舊24-skill receipt與receipt-less targets時缺少可達migration/recovery shape；old-schema已精確化，但receipt-less adoption與published-lock rollback仍未解。
