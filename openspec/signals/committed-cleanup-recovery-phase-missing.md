---
id: committed-cleanup-recovery-phase-missing
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-24
last_seen: 2026-07-24
links:
  - openspec/changes/replace-spectra-cli-with-cash-cli/reviews/apply-r1.md
---

# Committed cleanup recovery phase missing

A transaction permanently destroys rollback material while its journal still describes the state as rollback-capable, so recovery can mix committed cleanup with rolled-back managed writes.

## Occurrences

- 2026-07-24 — replace-spectra-cli-with-cash-cli — cash-apply rounds 1–2 — Installer刪除legacy quarantine後仍保留rollback journal；新增`publishing`／`committed` phases與partial-cleanup forward-recovery regression。
