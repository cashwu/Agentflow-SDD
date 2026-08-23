# Cash Apply Review — Round 1

## Reviewer Findings

### Critical

None.

### Warning

- severity: Warning
  confidence: 99
  layer: design
  location: `scripts/cash-skills/tests/skill-checks.fish` 的 `validate_review()` 與 reviewer topology mutations
  summary: Reviewer topology checker 只確認 A／B／V literals，且只拒絕固定禁語；加入 `Reviewer C — Simplicity` 或 `Rater — Simplicity` 仍會通過，未證明 full round 恰好 A／B、micro round 恰好 V。
  recommendation: 解析 `Fresh sub-agent calls` 區段並精確斷言 full／micro role sets，加入 Reviewer C 與 Rater mutations。
  reviewer source: Reviewer A — Adherence + Reviewer B — Quality

- severity: Warning
  confidence: 99
  layer: text
  location: `scripts/cash-skills/tests/skill-checks.fish` 的 `validate_note_entry()`
  summary: known-ceiling fixture 只檢查欄位成對，會接受 `重訪條件：之後需要時`，未執行 task 1.2 明定的 vague-trigger entry fixture。
  recommendation: 驗證 trigger 非空且拒絕列舉的空泛值，加入「之後需要時」與「規模變大時」fixtures。
  reviewer source: Reviewer A — Adherence

- severity: Warning
  confidence: 98
  layer: text
  location: `scripts/cash-skills/tests/skill-checks.fish` 的 contract-invasive ceiling assertion
  summary: checker 未把 `/cash-ingest`／`$cash-ingest` destination 納入完整斷言，改導向其他 command 仍可能通過。
  recommendation: 依 apply variant 驗證正確 invocation prefix，並加入 wrong-destination mutation。
  reviewer source: Reviewer A — Adherence

### Suggestion

None.

## Rating

- cumulative blocking Critical: 0
- cumulative blocking Warning: 3
- non-blocking triaged findings: 0
- critical_gap: false
- round_type: full

本輪是 run first round，confidence filter 後的三項 Warning 全部進入 cumulative blocking set；decision 為 `next_round`。

## Fix Actions

- `fix-r1-topology`：更新 `validate_review()`，在 `Fresh sub-agent calls` 內解析角色定義，要求 full round roles 精確等於 Reviewer A／B、micro round role 精確等於 Reviewer V；新增 `Reviewer C — Simplicity` 與 `Rater — Simplicity` mutations。
- `fix-r1-trigger`：擴充 `validate_note_entry()`，要求 known-ceiling trigger 非空且不得為「之後需要時」或「規模變大時」；新增兩個真實 entry fixtures。
- `fix-r1-ingest`：依 `.claude`／`.agents` variant 逐字斷言 contract-invasive ceiling 導向 `/cash-ingest`／`$cash-ingest`，新增 wrong-destination mutation。
- 驗證：`fish scripts/cash-skills/tests/skill-checks.fish minimal-solution-discipline`、`fish scripts/cash-skills/tests/skill-checks.fish all`、`python3 scripts/cash-skills/tests/test_bundle_version_history.py` 與 `.cash-skills/bin/cash validate add-minimal-solution-discipline` 全部 exit 0。

## Decision

next_round
