---
id: execution-error-masked-as-pass
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-07
last_seen: 2026-07-07
links:
  - openspec/changes/add-review-loop-discipline/reviews/propose-r2.md
---

# Execution error masked as pass

A detection command, validation step, or exit-code convention folds its own execution errors into a success or detection result — typically via blind negation (`! cmd`), a pipeline that discards an upstream failure, or a rule that collapses all exit codes into a binary outcome. The failure direction is unsafe: a broken check reads as "no problem found" and the guarded condition silently stops being checked. Detection results and execution errors must surface as distinguishable outcomes.

## Occurrences

- 2026-07-07 — add-review-loop-discipline — spectra-propose-plus round 2 — The canonical signal `check` example `! grep -rq PATTERN dir` mapped grep execution errors (exit 2, e.g. missing path) through `!` to exit 0 = "anti-pattern absent", and the authoring rule "written to exit only 0 or 1" instructed authors to collapse error codes, making the tri-state convention's error branch unreachable. Fixed by an explicit `$?` remapping example and a no-blind-negation authoring rule.
