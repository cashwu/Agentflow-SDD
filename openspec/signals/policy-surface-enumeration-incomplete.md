---
id: policy-surface-enumeration-incomplete
type: recurring-finding
status: open
occurrences: 4
first_seen: 2026-07-19
last_seen: 2026-07-25
links:
  - openspec/changes/chinese-spec-content/reviews/propose-r1.md
  - openspec/changes/replace-spectra-cli-with-cash-cli/reviews/propose-r3.md
  - openspec/changes/align-cli-skill-contracts/reviews/propose-r1.md
  - openspec/changes/derive-version-assertion-and-add-cli-help/reviews/propose-r1.md

---

# Policy surface enumeration incomplete

A cross-cutting policy change (language rules, naming rules, format contracts) enumerates the components to update by starting from the most obvious implementers, missing other components that also read or write the governed artifact type. The omitted component keeps enforcing the old policy and silently reintroduces the defect the change was meant to eliminate. The fix is enumerating the affected surface mechanically (grep every skill/module that touches the artifact type) before writing the scope, not recalling implementers from memory.

## Occurrences

- 2026-07-19 — chinese-spec-content — cash-propose round 1 — spec 語言政策改寫只涵蓋 cash-propose/cash-apply，漏掉同樣會寫 delta spec 的 cash-ingest（兩變體），其 locale 例外句仍強制英文且無 self-check 攔截。
- 2026-07-23 — replace-spectra-cli-with-cash-cli — cash-propose round 3 — Spectra namespace退役的初稿使用模糊all-non-archive scan，沒有精確列出24個consumer variants、installer/runtime/tests/live docs與history/legacy例外；修正為固定include roots與窄化allowlist。
- 2026-07-25 — align-cli-skill-contracts — cash-propose round 1 — 待移除的段落標題字面值只枚舉了 step 5 模板區塊內的出現位置，遺漏審查過濾規則中同一字面值的引用，任務因此無法達成自身驗收。

- 2026-07-25 — derive-version-assertion-and-add-cli-help — cash-propose round 1 — 新增的 MUST 未限定產生者：要求 `unknown_command` 的 message 附上 command 清單，但該 code 另有兩個 handler 層產生點（未知 new mode、未知 discipline），照字面執行會把 top-level 清單塞進語意錯誤的位置並擴大改動面到兩個額外的 runtime record。修法為明文限定「由 top-level command dispatch 產生的」。
