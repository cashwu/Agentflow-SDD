---
id: test-hook-disabled-by-dry-run
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-08-20
last_seen: 2026-08-20
links:
  - openspec/changes/tolerate-remount-device-renumbering/reviews/propose-r10.md
---

# Test hook disabled by dry-run

A timing or synchronization acceptance test relies on a test hook that the real call site intentionally skips in dry-run mode. If the fixture does not require a non-dry-run invocation, the hook's observable marker remains absent even after the code crosses the guarded boundary, producing a false green.

## Occurrences

- 2026-08-20 — tolerate-remount-device-renumbering — cash-propose round 10 — IC-15 used `.ready` absence to prove failure before exclusive-lock acquisition, but `wait_for_test_hold` is guarded by `not dry_run`; the contract now requires a direct real run plus the exact test-hook enable switch.
