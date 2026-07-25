---
id: interpreter-probe-bypasses-runtime-isolation
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-25
last_seen: 2026-07-25
links:
  - openspec/changes/harden-installer-mode-and-recovery/reviews/apply-r1.md
---

# Interpreter probe bypasses runtime isolation

An entry point applies isolation flags only to the final runtime handoff while its earlier interpreter capability probe starts the same interpreter without those protections, allowing user-level startup code or output to run before the isolated execution begins.

## Occurrences

- 2026-07-25 — harden-installer-mode-and-recovery — cash-apply round 1 — Python version probe 未使用 final handoff 的 `-s -P` 且未抑制 stdout，可能先執行 `usercustomize.py` 並污染 installer output；probe 改用相同 isolation flags 並丟棄 stdout/stderr。
