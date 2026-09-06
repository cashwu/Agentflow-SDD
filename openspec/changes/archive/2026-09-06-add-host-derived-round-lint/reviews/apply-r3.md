# Cash Apply Review — Round 3

## Reviewer Findings

- **Warning** — `scripts/cash-cli/tests/fixtures/lint_round/` did not include the `apply-r1.md` and `apply-r2.md` fixtures, so the static fixture gate did not exercise the complete round corpus required by the change.
  - **Source:** Reviewer B (Popper), `cash-apply` round 1.
- **Warning** — the acceptance suite omitted explicit coverage for missing/non-contiguous rounds, invalid previous decisions, duplicate round types, invalid change names, declaration-source fallbacks, parked/archive exclusions, specs-directory declarations, and receipt-based `__pycache__` handling.
  - **Source:** Reviewer B (Popper), `cash-apply` round 1.

## Rating

- Critical: 0
- Warning: 2
- Confidence: 100%
- Review layer: design
- `critical_gap`: false

## Fix Actions

- Copied `apply-r1.md` and `apply-r2.md` into the static lint-round fixture corpus and made the fixture test execute the corpus through the real gate.
- Added focused acceptance tests for run boundaries, prior-decision parsing, duplicate round types, change-name filtering, proposal/tasks fallback behavior, parked/archive/spec declarations, bytecode caches, hook re-entry, read-only behavior, and the other promised matrix branches.
- Re-ran `scripts/cash-cli/tests/test_lint_round.py`: 28 passed.

## Decision

- `next_round`
- Both warnings were direct verification gaps and are addressed in the current working tree. A fresh micro review is required to confirm the cumulative findings are resolved.
