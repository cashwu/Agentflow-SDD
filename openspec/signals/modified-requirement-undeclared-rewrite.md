---
id: modified-requirement-undeclared-rewrite
type: recurring-finding
status: open
occurrences: 3
first_seen: 2026-07-07
last_seen: 2026-08-22
links:
  - openspec/changes/add-micro-verification-round/reviews/propose-r1.md
  - openspec/changes/converge-plus-review-loop/reviews/propose-r1.md
  - openspec/changes/guard-task-state-integrity/reviews/propose-r1.md
---

# Modified requirement undeclared rewrite

While transcribing a MODIFIED requirement block from the master spec into a delta spec, wording outside the change's declared scope gets silently rewritten instead of copied verbatim. The MODIFIED workflow requires copying the entire block and editing only what the proposal declares; any other edit is an unauthorized behavior change that survives to archive time.

## Occurrences

- 2026-07-07 — add-micro-verification-round — spectra-propose-plus round 1 — The "Archive guidance waits for gate pass" scenario line "the final response may suggest archiving the change" was rewritten to different wording not declared in proposal/design/tasks.
- 2026-07-16 — converge-plus-review-loop — spectra-propose-plus round 1 — MODIFIED「spectra-apply-plus quality gate」轉錄時把 master 的「may suggest archiving」靜默改寫為「is permitted to suggest」（為避開禁用詞而未宣告的改寫）。
- 2026-08-22 — guard-task-state-integrity — cash-propose round 1 — 既有 master requirement `touched record 記錄 review loop 產出` 逐字要求「MUST NOT 改動任何既有 per-task 條目」與「合併結果與載入值相同時 MUST NOT 寫入」，本變更讓該 command 改寫既有條目的 `task_id` 並新增寫入條件，但 delta 只有 `## ADDED Requirements`，等於靜默修訂既有 requirement。
