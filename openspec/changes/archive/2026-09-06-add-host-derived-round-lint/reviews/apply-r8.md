# Cash Apply Review — Round 8

## Reviewer Findings

- **Warning** — the same-line `Affected code:` form still used the permissive path extractor, so explanatory text such as `Notes: 保持 `.cash.yaml` 不變` could become an authorization.
  - **Source:** Reviewer V, `cash-apply` round 1.

## Rating

- Critical: 0
- Warning: 1
- Confidence: 100%
- Review layer: design
- `critical_gap`: false

## Fix Actions

- Routed same-line `Affected code:` declarations through the same explicit path／`New`／`Modified`／`Removed` whitelist as child entries.
- Added a regression test for same-line `Notes:` text and re-published the managed runtime at bundle version `2.28.0`.

## Decision

- `next_round`
- The warning was fixed; a micro re-review confirmed the cumulative finding is resolved.
