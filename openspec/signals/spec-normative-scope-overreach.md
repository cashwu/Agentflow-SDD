---
id: spec-normative-scope-overreach
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-07
last_seen: 2026-07-07
links:
  - openspec/changes/add-micro-verification-round/reviews/propose-r2.md
---

# Spec normative scope overreach

A normative sentence (SHALL/MUST) names a broader subject set than the rule can or should govern, so a correct implementation strategy elsewhere in the change appears to violate the spec — or the extra subject becomes dead, unenforceable wording. The fix is narrowing the sentence's subject to its real scope, not weakening the implementation.

## Occurrences

- 2026-07-07 — add-micro-verification-round — spectra-propose-plus round 2 — New metadata requirement sentence put "test assertions" under "MUST NOT hard-code version/date literals", contradicting the deliberate (and correct) synchronized-pinned-literal strategy in the regression tests.
