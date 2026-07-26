---
id: cross-artifact-definition-drift
type: recurring-finding
status: open
occurrences: 14
first_seen: 2026-07-07
last_seen: 2026-07-26
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
  - openspec/changes/tolerate-versioned-legacy-guidance-marker/reviews/propose-r1.md
  - openspec/changes/rightsize-cash-skills/reviews/propose-r4.md
  - openspec/changes/harden-trace-path-containment-and-label-shape/reviews/propose-r2.md
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

- 2026-07-25 — tolerate-versioned-legacy-guidance-marker — cash-propose round 1 — W4：`CASH-SKILLS.md` 逐字宣稱「未知版本 marker都會在首次 target write前 fail closed」，本次改動使該句直接變假。該檔由 `openspec/specs/cash-skill-workflows/spec.md` 治理，但三個候選自動檢查（live namespace 掃描、source guidance 的 sha256 baseline、docs 的 14 條字面斷言）逐一核實都不會偵測到這處 drift，必須手動列入 Impact 並以獨立 task 同步。
- 2026-07-26 — rightsize-cash-skills — cash-propose round 4 — 修正 requirement 主句後標題仍為舊形狀措辭；identifier cross-grep 只掃了改動過的舊字串而未涵蓋同義字串，使「檔案層級／全域規則」在 delta spec 兩處與 proposal 三處殘留並與新主句互斥。
- 2026-07-26 — harden-trace-path-containment-and-label-shape — cash-propose round 2 — design 的 Risks 已具名接受「同層終止條件放寬會使子清單提前終止、其後路徑被靜默丟棄」這個取捨，但 tasks 的語料等價性驗證所列舉的「合乎設計的損失」條件集合沒有這一款，因此同一份 change 的兩處對「哪些差異是合乎設計的」給出互斥的定義——該形態一旦出現，驗證會把設計自己接受的結果判為實作缺陷，且同一 task 禁止所有脫困手段。
