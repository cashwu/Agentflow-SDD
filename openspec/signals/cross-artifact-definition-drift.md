---
id: cross-artifact-definition-drift
type: recurring-finding
status: open
occurrences: 3
first_seen: 2026-07-07
last_seen: 2026-07-14
links:
  - openspec/changes/add-micro-verification-round/reviews/propose-r1.md
  - openspec/changes/add-review-loop-discipline/reviews/propose-r1.md
  - openspec/changes/add-review-loop-discipline/reviews/propose-r2.md
  - openspec/changes/repair-all-uses-pinned-commit-inputs/reviews/apply-r2.md
---

# Cross-artifact definition drift

The same concept (a role's scope, an enumerated list, a rule's condition set) is defined with diverging content across proposal, design, delta spec, or tasks — typically because one artifact was written or edited without re-checking the concept's other occurrences. Distinct from fix-propagation gaps: the drift exists from initial authoring, not from a later fix.

## Occurrences

- 2026-07-07 — add-micro-verification-round — spectra-propose-plus round 1 — Reviewer V's verification-scope third item read "mechanical self-check results" in proposal but "new defects introduced by fixes" in design and delta spec; the text-layer classification enumeration also differed between proposal and design/spec.
- 2026-07-07 — add-review-loop-discipline — spectra-propose-plus rounds 1-2 — Proposal's protected grader path set omitted generate.fish, its ledger column list omitted the skill column, its grader-violation handling contradicted design/delta (Suggestion-and-pass vs remain-surviving-fail-loud), its scope-exception clause read as also covering the signal check prohibition, and the capabilities bullets misplaced the deterministic self-check behavior under signals-shared-layer.
- 2026-07-14 — repair-all-uses-pinned-commit-inputs — spectra-apply-plus round 2 — 文件把 pinned shared-input 保證擴張成整個 working tree 不影響內容，與 design 保留 target-local base skill 輸入的邊界不一致。
