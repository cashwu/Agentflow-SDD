---
id: transaction-publication-ledger-crash-window
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-24
last_seen: 2026-07-24
links:
  - openspec/changes/replace-spectra-cli-with-cash-cli/reviews/apply-r1.md
---

# Transaction publication ledger crash window

A multi-file transaction records publication only after mutating the destination, so a process crash between those actions leaves recovery unable to identify and roll back the published operation.

## Occurrences

- 2026-07-24 — replace-spectra-cli-with-cash-cli — cash-apply round 1 — Workspace journal原先在publish後才更新count；改為atomic write-ahead ledger、staged publication inode及真實process crash/restart regressions。
