---
id: modified-requirement-undeclared-rewrite
type: recurring-finding
status: open
occurrences: 2
first_seen: 2026-07-07
last_seen: 2026-07-16
links:
  - openspec/changes/add-micro-verification-round/reviews/propose-r1.md
  - openspec/changes/converge-plus-review-loop/reviews/propose-r1.md
---

# Modified requirement undeclared rewrite

While transcribing a MODIFIED requirement block from the master spec into a delta spec, wording outside the change's declared scope gets silently rewritten instead of copied verbatim. The MODIFIED workflow requires copying the entire block and editing only what the proposal declares; any other edit is an unauthorized behavior change that survives to archive time.

## Occurrences

- 2026-07-07 — add-micro-verification-round — spectra-propose-plus round 1 — The "Archive guidance waits for gate pass" scenario line "the final response may suggest archiving the change" was rewritten to different wording not declared in proposal/design/tasks.
- 2026-07-16 — converge-plus-review-loop — spectra-propose-plus round 1 — MODIFIED「spectra-apply-plus quality gate」轉錄時把 master 的「may suggest archiving」靜默改寫為「is permitted to suggest」（為避開禁用詞而未宣告的改寫）。
