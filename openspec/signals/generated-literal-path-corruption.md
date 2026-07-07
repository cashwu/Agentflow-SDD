---
id: generated-literal-path-corruption
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-07
last_seen: 2026-07-07
links:
  - openspec/changes/add-review-loop-discipline/reviews/apply-r1.md
---

# Generated literal path corruption

A generator or variant substitution rewrites literal project paths inside generated instructions, so the generated artifact no longer contains the exact path strings required by the spec or by later workflow logic.

## Occurrences

- 2026-07-07 — add-review-loop-discipline — spectra-apply-plus round 1 — Codex variant substitution rewrote protected path literals such as `scripts/spectra-plus/...` and `.agents/skills/spectra-...` into `$`-corrupted paths until substitution was narrowed to backtick command forms and literal-path assertions were added.
