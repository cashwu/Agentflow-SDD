# Cash Propose Review — Round 4

## Reviewer Findings

### Critical

None.

### Warning

- severity: Warning
  confidence: 100
  layer: design
  disposition: unresolved-prior
  location: `design.md` transaction與failure contracts；delta spec runtime publication、receipt-less adoption scenarios；`tasks.md` 2.3
  summary: Receipt-less recovery仍以「曾發佈任何 skill」這個不可觀測歷史狀態決定 conflict；若24檔已全數與source相同但receipt publication失敗，retry無法區分它與合法 receipt-less adoption。
  recommendation: 改依retry當下可觀測state分類：無receipt且skills混雜、不完整或與source不同時一般retry為 conflict並須 `--force`；24檔全數等於source時沿用一般 adoption。加入只剩receipt publication失敗的fixture。
  reviewer: Reviewer B

### Suggestion

None.

## Rating

- cumulative blocking Critical: 0
- cumulative blocking Warning: 1
- non-blocking triaged findings: 0
- critical_gap: false
- round_type: full
- rationale: Reviewer A判定Round 3修正 resolved且未發現新 finding；Reviewer B以現行 installer adoption分支為證據，確認同一累積 member仍含不可觀測歷史條件，因此維持 unresolved-prior。修正後仍需 Reviewer V確認才能移除，本輪為 `next_round`。

## Fix Actions

- 修改 `proposal.md`、`design.md`、delta spec與 `tasks.md`，移除對不可觀測 publication歷史的依賴，統一以重試時的 skills、receipt與guidance state分類。
- 明定有有效 receipt的 drift，以及無 receipt時混雜、不完整或與source不同的 skills，一般重試都 `conflict`且零寫入並須 `--force`；無 receipt且24檔全數等於source則沿用一般 adoption。
- 在 task 2.3加入「24檔已全數發佈、只剩receipt publication失敗」fixture，驗證一般重試補齊 guidance與receipt。

## Decision

next_round
