---
id: fenced-content-mistaken-for-requirement-identity
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-23
last_seen: 2026-07-23
links:
  - openspec/changes/replace-spectra-cli-with-cash-cli/reviews/propose-r1.md
---

# Fenced content mistaken for requirement identity

A delta treats a heading rendered inside a fenced guidance or template block as an authoritative master requirement title, so the intended outer requirement remains unchanged and archive silently ignores the false identity.

## Occurrences

- 2026-07-23 — replace-spectra-cli-with-cash-cli — cash-propose round 1 — 初稿修改guidance code fence內的`cash-apply`偽heading；修正為MODIFIED真正的outer guidance requirement並保留balanced fence全文。
