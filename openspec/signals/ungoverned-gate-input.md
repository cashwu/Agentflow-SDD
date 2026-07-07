---
id: ungoverned-gate-input
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-07
last_seen: 2026-07-07
links:
  - openspec/changes/add-review-loop-discipline/reviews/propose-r1.md
---

# Ungoverned gate input

A change introduces a new input that a quality gate or automated check consumes (a scoring rule, a detection command, a threshold, a protected-set definition), but does not govern who may create, modify, or delete that input — leaving the gate's own judgment surface writable by the very process it is supposed to judge. The gap is created by the change itself, not a pre-existing deviation: whenever a new gate input is added, its write-governance must be defined in the same change.

## Occurrences

- 2026-07-07 — add-review-loop-discipline — spectra-propose-plus round 1 — The new signal `check` field became deterministic grader input for the pre-round self-check, but nothing governed who may add/modify/remove it: a mid-loop fix action could weaken a failing check, and the automated signals write step could coin unreviewed shell commands for future runs to execute. Fixed by making `check` human-maintained (lifecycle MODIFIED) and unconditionally untouchable by fix actions (grader-immutability rule).
