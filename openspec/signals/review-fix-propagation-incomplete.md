---
id: review-fix-propagation-incomplete
type: recurring-finding
status: open
occurrences: 5
first_seen: 2026-07-07
last_seen: 2026-07-23
links:
  - openspec/changes/add-micro-verification-round/reviews/propose-r3.md
  - openspec/changes/converge-plus-review-loop/reviews/propose-r5.md
  - openspec/changes/chinese-spec-content/reviews/propose-r2.md
  - openspec/changes/migrate-cash-project-guidance/reviews/propose-r2.md
  - openspec/changes/migrate-cash-project-guidance/reviews/propose-r3.md
  - openspec/changes/migrate-cash-project-guidance/reviews/propose-r4.md
  - openspec/changes/migrate-cash-project-guidance/reviews/propose-r5.md
  - openspec/changes/replace-spectra-cli-with-cash-cli/reviews/propose-r6.md
---

# Review fix propagation incomplete

A review-round fix introduces or changes a rule, but claims about that rule elsewhere in the artifact set (risk statements, invariant claims, summaries) are not re-checked and updated in the same fix pass — the fix itself becomes the source of the next round's inconsistency finding.

## Occurrences

- 2026-07-07 — add-micro-verification-round — spectra-propose-plus round 3 — Round 2 added the post-fix re-derivation rule (a discretionary judgment), but design Risks still claimed round-type derivation was "purely mechanical with no discretion", and the new discretion point had no recorded mitigation.
- 2026-07-16 — converge-plus-review-loop — spectra-propose-plus rounds 4–6 — 前三輪 fix passes 引入的規則（同意 fallback、seeded re-run carve-out、per-class 動作選單、不回升例外）未在同一 fix pass 同步到 tasks（task 2.5/2.7 滯留舊版本）、scenario 與 proposal 短句，成為後續三輪 findings 的主要來源。
- 2026-07-19 — chinese-spec-content — cash-propose round 2 — round 1 修復把 cash-ingest parity diff 補進 proposal Impact 與 tasks 4.1，但 design 決策 6/C6 未同步，成為 round 2 的 fix-introduced finding（V-1）。
- 2026-07-22 — migrate-cash-project-guidance — cash-propose rounds 2–5 — Publication recovery修正連續漏掉receipt drift、receipt-less首次安裝、可觀測adoption與零檔clean install分支；最終以現行installer可觀測的0／24全等／partial-or-different三分法同步所有artifacts與fixtures。
- 2026-07-23 — replace-spectra-cli-with-cash-cli — cash-propose rounds 3–6 — consumer schema、config validation、stable bootstrap與legacy migration修正連續引入merge phase、parser ordering、old-receipt cutover、touched雙來源及lock rollback缺口；最後三項成為abort obligations。
