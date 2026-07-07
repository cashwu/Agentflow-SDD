# Apply Plus Review — Round 4

## Reviewer Findings

### Critical

無。

### Warning

1. `severity`: Warning
   `confidence`: 100
   `layer`: design
   `location`: `scripts/spectra-plus/tests/generator-checks.fish:181-189`; false-positive sources include generated header/base content such as `.claude/skills/spectra-propose-plus/SKILL.md:13,70,545` and `.claude/skills/spectra-apply-plus/SKILL.md:13,176,402`
   `summary`: Generator checks assert protected-path strings anywhere in each generated output, so unrelated generated content can satisfy `.spectra.yaml`, `openspec/specs/`, or `scripts/spectra-plus/generate.fish` even if the `<!-- GRADER-IMMUTABILITY -->` block regresses.
   `recommendation`: Assert the protected path strings inside the section between `<!-- GRADER-IMMUTABILITY -->` and `<!-- LOOP-LEDGER-STEP -->`.
   Reviewer: A

### Suggestion

無。

## Rating

- surviving `Critical` count: 0
- surviving `Warning` count: 1
- `critical_gap`: false
- `round_type`: full

Round 4 有一個 confidence 100 的 design-layer Warning 存活，因此依機械決策規則必須進入下一輪。

## Fix Actions

- Modified `scripts/spectra-plus/tests/generator-checks.fish`: added `assert_contains_between` to check a bounded section between two sentinel anchors.
- Modified `scripts/spectra-plus/tests/generator-checks.fish`: changed protected path assertions to require each path inside the `<!-- GRADER-IMMUTABILITY -->` to `<!-- LOOP-LEDGER-STEP -->` block, preventing unrelated generated content from satisfying the checks.
- Re-ran `fish scripts/spectra-plus/tests/generator-checks.fish`; exit 0.
- Re-ran `spectra validate "add-review-loop-discipline"`; exit 0.
- Re-ran `spectra analyze add-review-loop-discipline --json`; only the existing two Suggestion findings remained.
- Re-ran quick grep confirming `assert_contains_between` and all bounded protected path assertions are present.
- Re-derivation note: the fix modified an implementation test file and addressed a design-layer Warning, so the next round remains `full`.

## Decision

next_round
