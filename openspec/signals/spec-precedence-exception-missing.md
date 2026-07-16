---
id: spec-precedence-exception-missing
type: recurring-finding
status: open
occurrences: 4
first_seen: 2026-07-04
last_seen: 2026-07-16
links:
  - openspec/changes/guard-dirty-source-auto-repair/reviews/propose-r1.md
  - openspec/changes/guard-dirty-source-auto-repair/reviews/propose-r2.md
  - openspec/changes/guard-dirty-source-auto-repair/reviews/propose-r3.md
  - openspec/changes/guard-dirty-source-auto-repair/reviews/propose-r4.md
  - openspec/changes/add-micro-verification-round/reviews/propose-r1.md
  - openspec/changes/add-review-loop-discipline/reviews/propose-r1.md
  - openspec/changes/converge-plus-review-loop/reviews/propose-r1.md
---

# Spec precedence exception missing

A change introduces a new guard or early-return behavior that overrides existing requirements, but the delta spec does not explicitly modify the affected existing requirements to define precedence.

## Occurrences

- 2026-07-04 — guard-dirty-source-auto-repair — spectra-propose-plus rounds 1-4 — Review found dirty-source guard precedence conflicts with metadata validation, dry-run repair output, throttle behavior, and auto-restore requirements.
- 2026-07-07 — add-micro-verification-round — spectra-propose-plus round 1 — Version bump to 1.3.0 affected master requirements whose scenarios pin version/date literals ("Generated plus skill version metadata", "Repair checks plus metadata freshness"), but the delta initially did not MODIFY them.
- 2026-07-07 — add-review-loop-discipline — spectra-propose-plus round 1 — The new grader-immutability rule mandated withholding some fixes, contradicting the master quality-gate scenarios' unconditional "fixes the ... findings before starting the next round"; the delta initially only ADDED the new requirement without MODIFYing the two governed gate requirements.
- 2026-07-16 — converge-plus-review-loop — spectra-propose-plus rounds 1、6 — 新增的 ≤25 強制降分未對「direct artifact violation 必為 100」不變式宣告優先權；needs-design note 同時是合法 next_round 動作與強制 aborted 觸發；prior-triage re-report 的不重複 note 規則與動作義務互斥（死鎖）。
