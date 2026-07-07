---
id: cross-artifact-definition-drift
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-07
last_seen: 2026-07-07
links:
  - openspec/changes/add-micro-verification-round/reviews/propose-r1.md
---

# Cross-artifact definition drift

The same concept (a role's scope, an enumerated list, a rule's condition set) is defined with diverging content across proposal, design, delta spec, or tasks — typically because one artifact was written or edited without re-checking the concept's other occurrences. Distinct from fix-propagation gaps: the drift exists from initial authoring, not from a later fix.

## Occurrences

- 2026-07-07 — add-micro-verification-round — spectra-propose-plus round 1 — Reviewer V's verification-scope third item read "mechanical self-check results" in proposal but "new defects introduced by fixes" in design and delta spec; the text-layer classification enumeration also differed between proposal and design/spec.
