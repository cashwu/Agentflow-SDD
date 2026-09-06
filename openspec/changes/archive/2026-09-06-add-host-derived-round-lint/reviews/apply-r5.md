# Cash Apply Review — Round 5

## Reviewer Findings

- **Warning** — proposal parsing still accepted `Affected code:` inside fenced examples and under a nested `Verification` item, allowing non-declaration text to release grader protection.
  - **Source:** Reviewer V, `cash-apply` round 1.
- **Warning** — launcher read-only coverage depended on the inherited `PYTHONDONTWRITEBYTECODE` environment and could fail to exercise the receipt target's permitted bytecode changes.
  - **Source:** Reviewer V, `cash-apply` round 1.

## Rating

- Critical: 0
- Warning: 2
- Confidence: 100%
- Review layer: design
- `critical_gap`: false

## Fix Actions

- Changed proposal scope parsing to track fenced blocks and `Verification` subtrees, and to accept only actual list-item `Affected code:` declarations.
- Made launcher subprocess tests explicitly remove `PYTHONDONTWRITEBYTECODE`, then compare complete file and directory state for portable and receipt targets according to their contracts.
- Re-published the managed runtime and advanced the bundle version to `2.25.0`.

## Decision

- `next_round`
- Both warnings were addressed; a fresh micro review is required.
