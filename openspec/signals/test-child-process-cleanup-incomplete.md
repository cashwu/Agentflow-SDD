---
id: test-child-process-cleanup-incomplete
type: recurring-finding
status: open
occurrences: 2
first_seen: 2026-08-20
last_seen: 2026-08-20
links:
  - openspec/changes/tolerate-remount-device-renumbering/reviews/propose-r10.md
  - openspec/changes/tolerate-remount-device-renumbering/reviews/apply-r4.md
---

# Test child process cleanup incomplete

A subprocess-based regression test defines its expected synchronization path but not cleanup for deadline expiry, assertion failure, or communication timeout. A failing implementation can then leak the child process and held locks, while secondary cleanup errors obscure the behavior the test was intended to diagnose.

## Occurrences

- 2026-08-20 — tolerate-remount-device-renumbering — cash-propose round 10 — The hold-boundary test now requires `try/finally`, finite waits, release on the crossed-boundary path, and `terminate`/`kill` fallback without masking the primary assertion.
- 2026-08-20 — tolerate-remount-device-renumbering — cash-apply round 4 — Cleanup initially gated process-group reclamation on the leader's `poll()` state and used grace periods longer than the hook timeout; the fix now gates on completed communication, handles exited leaders with live descendants, and escalates the crossed path before the hook's own timeout.
