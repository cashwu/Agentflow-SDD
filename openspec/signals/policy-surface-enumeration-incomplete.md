---
id: policy-surface-enumeration-incomplete
type: recurring-finding
status: open
occurrences: 2
first_seen: 2026-07-19
last_seen: 2026-07-23
links:
  - openspec/changes/chinese-spec-content/reviews/propose-r1.md
  - openspec/changes/replace-spectra-cli-with-cash-cli/reviews/propose-r3.md
---

# Policy surface enumeration incomplete

A cross-cutting policy change (language rules, naming rules, format contracts) enumerates the components to update by starting from the most obvious implementers, missing other components that also read or write the governed artifact type. The omitted component keeps enforcing the old policy and silently reintroduces the defect the change was meant to eliminate. The fix is enumerating the affected surface mechanically (grep every skill/module that touches the artifact type) before writing the scope, not recalling implementers from memory.

## Occurrences

- 2026-07-19 — chinese-spec-content — cash-propose round 1 — spec 語言政策改寫只涵蓋 cash-propose/cash-apply，漏掉同樣會寫 delta spec 的 cash-ingest（兩變體），其 locale 例外句仍強制英文且無 self-check 攔截。
- 2026-07-23 — replace-spectra-cli-with-cash-cli — cash-propose round 3 — Spectra namespace退役的初稿使用模糊all-non-archive scan，沒有精確列出24個consumer variants、installer/runtime/tests/live docs與history/legacy例外；修正為固定include roots與窄化allowlist。
