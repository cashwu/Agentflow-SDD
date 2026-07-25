---
id: exemption-premised-on-observed-behavior
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-25
last_seen: 2026-07-25
links:
  - openspec/changes/track-review-loop-outputs-in-allowlist/reviews/propose-r1.md
---

# Exemption premised on observed behavior

A rule grants one branch an exemption whose premise is an observation of how that branch happens to behave today, not a property any mechanism guarantees. Worse, the exemption is written as a prohibition (MUST NOT do X here), so the day the observation stops holding, doing the right thing becomes a spec violation. The fix is to restate the condition in terms of the property that actually matters — usually a structural test on the data — so the rule stays correct for both branches without naming either.

## Occurrences

- 2026-07-25 — track-review-loop-outputs-in-allowlist — cash-propose round 1 — 規則以「`cash-propose` 的 fix actions 只動 change 目錄內的 artifacts」為前提豁免該 skill，並寫成 `MUST NOT 因此新增呼叫`；但 grader-immutability 條款本身就明文允許主 agent 在 structured scope declaration 涵蓋下修改 change 目錄外的受保護檔案，且該條款為兩個 skill 共用。修法是改以「該輪是否修改了 change 目錄之外的檔案」判定，並明寫 MUST NOT 以 skill 名稱判定。
