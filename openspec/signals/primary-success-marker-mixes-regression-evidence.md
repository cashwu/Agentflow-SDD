---
id: primary-success-marker-mixes-regression-evidence
type: recurring-finding
status: open
occurrences: 2
first_seen: 2026-08-24
last_seen: 2026-09-05
links:
  - openspec/changes/strengthen-cash-tdd-evidence/reviews/propose-r2.md
  - openspec/changes/add-host-derived-round-lint/reviews/propose-r1.md
---

# Primary success marker mixes regression evidence

A task names one primary verification target but defines its success marker using outcomes that only separate regression suites, publication checks, or completion steps can observe. The same-target GREEN claim is then impossible to evaluate from the primary command alone. Keep `success` limited to direct output or assertions of the named primary target, and place all other completion evidence under explicitly named regression targets or delivery checks.

## Occurrences

- 2026-08-24 — strengthen-cash-tdd-evidence — cash-propose round 2 — both tasks mixed full-suite, manifest／receipt, discovery, or publication results into the primary `success` field；修正為各自primary group可直接觀察的exit 0與具名assertions，其餘證據留在`regression`。

- 2026-09-05 — add-host-derived-round-lint — cash-propose round 1 — 一個 task 的 `success` 同時斷言 CLI 實跑的 `ok` 欄位與 `.claude/settings.json` 的 JSON 合法性，而 `verification` 只指名前者；後者在該 primary target 的執行結果中根本不可觀察。成因是該 task 同時承擔兩個不同性質的交付（前置實跑確認與 hook 掛載），兩者的驗收無法用同一個 target 判定。修法是拆成兩個 task，各自的 success 只保留其 primary target 可直接觀察的 marker。
