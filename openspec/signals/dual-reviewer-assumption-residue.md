---
id: dual-reviewer-assumption-residue
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-07
last_seen: 2026-07-07
links:
  - openspec/changes/add-micro-verification-round/reviews/propose-r1.md
---

# Dual reviewer assumption residue

When a change introduces a new reviewer role or round type, existing per-round obligations, context-provisioning rules, and wording that silently assume the two-reviewer full-round shape (e.g. "BOTH reviewers", per-round duties assigned to Reviewer A, context lists defined only for A/B) are not systematically inventoried and reassigned — leaving obligation vacuums or duty/input mismatches for the new role.

## Occurrences

- 2026-07-07 — add-micro-verification-round — spectra-propose-plus round 1 — Three findings from one root cause: micro-round signals-in-reviewer-context behavior undefined ("BOTH reviewers" wording), apply-notes per-round Reviewer A obligation unfulfillable in micro rounds, and Reviewer V's propagation-check duty lacking artifact paths / changed-file list in its context definition.
