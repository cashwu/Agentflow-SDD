---
id: modified-requirement-undeclared-rewrite
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-07
last_seen: 2026-07-07
links:
  - openspec/changes/add-micro-verification-round/reviews/propose-r1.md
---

# Modified requirement undeclared rewrite

While transcribing a MODIFIED requirement block from the master spec into a delta spec, wording outside the change's declared scope gets silently rewritten instead of copied verbatim. The MODIFIED workflow requires copying the entire block and editing only what the proposal declares; any other edit is an unauthorized behavior change that survives to archive time.

## Occurrences

- 2026-07-07 — add-micro-verification-round — spectra-propose-plus round 1 — The "Archive guidance waits for gate pass" scenario line "the final response may suggest archiving the change" was rewritten to different wording not declared in proposal/design/tasks.
