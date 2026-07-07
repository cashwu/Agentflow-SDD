---
id: review-fix-propagation-incomplete
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-07
last_seen: 2026-07-07
links:
  - openspec/changes/add-micro-verification-round/reviews/propose-r3.md
---

# Review fix propagation incomplete

A review-round fix introduces or changes a rule, but claims about that rule elsewhere in the artifact set (risk statements, invariant claims, summaries) are not re-checked and updated in the same fix pass — the fix itself becomes the source of the next round's inconsistency finding.

## Occurrences

- 2026-07-07 — add-micro-verification-round — spectra-propose-plus round 3 — Round 2 added the post-fix re-derivation rule (a discretionary judgment), but design Risks still claimed round-type derivation was "purely mechanical with no discretion", and the new discretion point had no recorded mitigation.
