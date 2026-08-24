---
id: primary-success-marker-mixes-regression-evidence
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-08-24
last_seen: 2026-08-24
links:
  - openspec/changes/strengthen-cash-tdd-evidence/reviews/propose-r2.md
---

# Primary success marker mixes regression evidence

A task names one primary verification target but defines its success marker using outcomes that only separate regression suites, publication checks, or completion steps can observe. The same-target GREEN claim is then impossible to evaluate from the primary command alone. Keep `success` limited to direct output or assertions of the named primary target, and place all other completion evidence under explicitly named regression targets or delivery checks.

## Occurrences

- 2026-08-24 — strengthen-cash-tdd-evidence — cash-propose round 2 — both tasks mixed full-suite, manifest／receipt, discovery, or publication results into the primary `success` field；修正為各自primary group可直接觀察的exit 0與具名assertions，其餘證據留在`regression`。
