---
id: unreadable-round-file-exception-path
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-09-06
last_seen: 2026-09-06
links:
  - openspec/changes/add-host-derived-round-lint/reviews/apply-r1.md
---

# Unreadable round file escapes the gate result

A round-file checker records an initial read failure but later re-reads the same file in another gate, allowing an unreadable or racing file to become an infrastructure exception instead of a normal per-gate failure with the remaining checks preserved.

## Occurrences

- 2026-09-06 — add-host-derived-round-lint — cash-apply round 1 — round type parsing initially re-read an unreadable file; fixed by reusing the first read result and returning `fail`.
