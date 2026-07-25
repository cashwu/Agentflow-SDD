---
id: cross-artifact-definition-drift
type: recurring-finding
status: open
occurrences: 11
first_seen: 2026-07-07
last_seen: 2026-07-25
links:
  - openspec/changes/add-micro-verification-round/reviews/propose-r1.md
  - openspec/changes/add-review-loop-discipline/reviews/propose-r1.md
  - openspec/changes/add-review-loop-discipline/reviews/propose-r2.md
  - openspec/changes/repair-all-uses-pinned-commit-inputs/reviews/apply-r2.md
  - openspec/changes/converge-plus-review-loop/reviews/propose-r1.md
  - openspec/changes/converge-plus-review-loop/reviews/apply-r3.md
  - openspec/changes/add-versioned-cash-skill-batch-update/reviews/propose-r4.md
  - openspec/changes/migrate-cash-project-guidance/reviews/propose-r1.md
  - openspec/changes/refine-apply-blocker-triage/reviews/apply-r2.md
  - openspec/changes/replace-spectra-cli-with-cash-cli/reviews/propose-r3.md
  - openspec/changes/replace-spectra-cli-with-cash-cli/reviews/apply-r1.md
  - openspec/changes/derive-version-assertion-and-add-cli-help/reviews/propose-r1.md
  - openspec/changes/derive-version-assertion-and-add-cli-help/reviews/propose-r2.md

---

# Cross-artifact definition drift

The same concept (a role's scope, an enumerated list, a rule's condition set) is defined with diverging content across proposal, design, delta spec, or tasks — typically because one artifact was written or edited without re-checking the concept's other occurrences. Distinct from fix-propagation gaps: the drift exists from initial authoring, not from a later fix.

## Occurrences

- 2026-07-07 — add-micro-verification-round — spectra-propose-plus round 1 — Reviewer V's verification-scope third item read "mechanical self-check results" in proposal but "new defects introduced by fixes" in design and delta spec; the text-layer classification enumeration also differed between proposal and design/spec.
- 2026-07-07 — add-review-loop-discipline — spectra-propose-plus rounds 1-2 — Proposal's protected grader path set omitted generate.fish, its ledger column list omitted the skill column, its grader-violation handling contradicted design/delta (Suggestion-and-pass vs remain-surviving-fail-loud), its scope-exception clause read as also covering the signal check prohibition, and the capabilities bullets misplaced the deterministic self-check behavior under signals-shared-layer.
- 2026-07-14 — repair-all-uses-pinned-commit-inputs — spectra-apply-plus round 2 — 文件把 pinned shared-input 保證擴張成整個 working tree 不影響內容，與 design 保留 target-local base skill 輸入的邊界不一致。
- 2026-07-16 — converge-plus-review-loop — spectra-propose-plus round 1 — blocking finding 定義、動作清單、introduced_by 證據通道在 proposal/design/delta spec 初稿間表述分歧（clause (b) 依賴僅 apply-plus 才有義務提供的欄位）。
- 2026-07-16 — converge-plus-review-loop — spectra-apply-plus round 3 — delta spec 的 round file outline 要求所有 `fix-introduced` finding 都含 `introduced_by`，模板卻只對 apply-plus Reviewer B 明定該欄位。
- 2026-07-18 — add-versioned-cash-skill-batch-update — cash-propose round 4 — design 將 `Result:` 限定於 completed domain decisions，但 delta spec opening 無條件要求每次 invocation emit result，與 execution-failure scenario 的 no-domain-result 契約矛盾。
- 2026-07-22 — migrate-cash-project-guidance — cash-propose round 1 — Preflight/runtime publication的零寫入與部分完成語意，以及source/target的Spectra contamination recovery，在proposal、design與delta spec間定義不一致；修正後明確拆分failure phase與recovery scope。
- 2026-07-22 — refine-apply-blocker-triage — cash-apply round 2 — Proposal 將所有「多個可辯護答案」的 open question 都描述為暫停條件，範圍比 design/spec/task 僅涵蓋可能改變 contract／scope 的問題更廣。
- 2026-07-23 — replace-spectra-cli-with-cash-cli — cash-propose rounds 3–5 — archive flags、fixed `openspec/`與legacy `spec_dir`、existing/newer config parser及register prerequisites曾在design、delta與tasks間不同步，需逐輪收斂為單一contract。
- 2026-07-24 — replace-spectra-cli-with-cash-cli — cash-apply round 1 — Cash workflow文案仍聲稱title mismatch會silently drop，與runtime/spec的`requirement_identity_mismatch` fail-closed contract矛盾；六個variants已同步修正。

- 2026-07-25 — derive-version-assertion-and-add-cli-help — cash-propose rounds 1–2 — 一份宗旨為消除重複定義的 change，兩次差點自己製造新的一份：delta spec 一度複述 master 已定義的版本格式規則；錯誤訊息一度要內嵌 15 個 command 名稱，而該訊息被 golden fixture 以整個 object 相等比對釘住，等於新增一份需手動同步的清單。最終以「引用而非複述」與「指向 help 而非內嵌清單」兩項改設計解決。
