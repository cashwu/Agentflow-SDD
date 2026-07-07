# Apply Plus Review — Round 1

## Reviewer Findings

### Critical

無。

### Warning

1. `severity`: Warning
   `confidence`: 100
   `layer`: design
   `location`: `scripts/spectra-plus/template/review-loop-block.md:129-139`; generated copies at `.agents/skills/spectra-apply-plus/SKILL.md:541-551`, `.agents/skills/spectra-propose-plus/SKILL.md:449-459`, `.claude/skills/spectra-apply-plus/SKILL.md:541-551`, `.claude/skills/spectra-propose-plus/SKILL.md:449-459`
   `summary`: Protected grader paths are split across adjacent code spans, so several project-root-relative paths are not present verbatim in the generated skills despite the spec requiring the protected path set and verbatim path matching.
   `recommendation`: Emit each protected path as a single literal path, fix the Codex substitution issue directly if needed, and add generator assertions for the literal protected paths in all four generated outputs.
   Reviewer: B

2. `severity`: Warning
   `confidence`: 100
   `layer`: design
   `location`: `scripts/spectra-plus/template/review-loop-block.md:19`, generated into `.agents/.claude` plus skill files
   `summary`: The out-of-scope `check` failure rule tests whether the detected instance is outside scope/protected, but the spec requires testing whether the fix lies outside scope or in a grader-protected path.
   `recommendation`: Update the Signal-derived checks text to say: if the detected instance is pre-existing, or its fix lies outside the change's declared scope or inside a grader-protected path, do not fix it; then regenerate all four plus skill files.
   Reviewer: A

### Suggestion

無。

## Rating

- surviving `Critical` count: 0
- surviving `Warning` count: 2
- `critical_gap`: false
- `round_type`: full

Round 1 有兩個 confidence 100 的 design-layer Warning 存活，因此依機械決策規則必須進入下一輪；沒有 Critical，所以 `critical_gap` 為 false，但 design-layer 修復會讓下一輪維持 full round。

## Fix Actions

- Modified `scripts/spectra-plus/template/review-loop-block.md`: restored the protected grader paths as single literal project-root-relative paths, and changed the Signal-derived checks out-of-scope branch to test whether the detected instance is pre-existing or its fix lies outside declared scope or inside a grader-protected path.
- Modified `scripts/spectra-plus/rules.yaml`: narrowed the Codex substitution from global `/spectra-` to backtick command form `` `/spectra-`` so generated Codex skills preserve literal protected path strings while still converting slash-command examples.
- Modified `scripts/spectra-plus/tests/generator-checks.fish`: added assertions that all four generated outputs contain the literal protected path set and do not contain corrupted `scripts$spectra-plus` or `skills$spectra-` paths.
- Modified `openspec/changes/add-review-loop-discipline/implementation-notes.md`: recorded the `rules.yaml` substitution-scope deviation and reason.
- Regenerated `.claude/skills/spectra-propose-plus/SKILL.md`, `.claude/skills/spectra-apply-plus/SKILL.md`, `.agents/skills/spectra-propose-plus/SKILL.md`, and `.agents/skills/spectra-apply-plus/SKILL.md`.
- Re-ran `fish scripts/spectra-plus/generate.fish`; exit 0.
- Re-ran `fish scripts/spectra-plus/tests/generator-checks.fish`; exit 0.
- Re-ran `spectra validate "add-review-loop-discipline"`; exit 0.
- Re-ran `spectra analyze add-review-loop-discipline --json`; only the existing two Suggestion findings remained.
- Re-ran mechanical self-check after fixes: delta spec comment counts are balanced, no signal frontmatter `check:` exists to execute, generated outputs contain the literal protected paths, no corrupted `$` protected paths remain, and two consecutive generator runs produced identical four-file `cksum` fingerprints.
- Re-derivation note: modifications to `scripts/spectra-plus/template/review-loop-block.md`, `scripts/spectra-plus/rules.yaml`, and generated plus skill files change behavior/design statements, so the next round remains `full`.

## Decision

next_round
