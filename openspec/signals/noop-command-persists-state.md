---
id: noop-command-persists-state
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-24
last_seen: 2026-07-24
links:
  - openspec/changes/replace-spectra-cli-with-cash-cli/reviews/apply-r1.md
---

# No-op command persists state

A command whose requested state already holds still creates or rewrites persistent state, changing inode or timestamps despite its documented successful no-op behavior.

## Occurrences

- 2026-07-24 — replace-spectra-cli-with-cash-cli — cash-apply round 1 — Missing registry或missing record的`--unregister`仍重寫projects file；改為records實際改變時才write並補inode/mtime/bytes assertions。
