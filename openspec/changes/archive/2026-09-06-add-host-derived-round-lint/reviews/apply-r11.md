# Cash Apply Review — Round 11

## Reviewer Findings

None.

Reviewer V confirmed that affected-code parsing now follows an allowlist: only explicit paths and `New`／`Modified`／`Removed` containers remain parseable, while all other parent nodes exclude their full indented subtrees regardless of language or punctuation.

## Rating

- Critical: 0
- Warning: 0
- Confidence: 100%
- Review layer: design
- `critical_gap`: false

## Fix Actions

- Replaced language-specific unknown-label filtering with a general ignored-subtree state for every non-allowlisted parent.
- Added reverse tests for Chinese parents with and without a colon, and re-published the managed runtime at bundle version `2.30.0`.

## Decision

- `passed`
