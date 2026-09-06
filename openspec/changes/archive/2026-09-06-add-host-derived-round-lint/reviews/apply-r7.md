# Cash Apply Review — Round 7

## Reviewer Findings

None.

The user-reported Example-subtree bypass and task-description delivery parsing issues were fixed before review. Reviewer V confirmed that the Example subtree is excluded recursively, real task bullets accept delivery fields after descriptions, and the previous declaration, hook, delimiter, and launcher read-only cases remain covered.

## Rating

- Critical: 0
- Warning: 0
- Confidence: 100%
- Review layer: design
- `critical_gap`: false

## Fix Actions

- Added recursive `Example` subtree exclusion and a regression test proving a protected path inside that subtree cannot release grader protection.
- Parsed `delivery:` from actual task bullets after task descriptions and added the repository's fullwidth-semicolon task shape as a regression test.
- Re-published the managed runtime at bundle version `2.26.0`.

## Decision

- `passed`
