# Cash Apply Review — Round 1

## Reviewer Findings

### Critical

- severity: Critical
  confidence: 100
  layer: design
  location: `design.md` D3／D8、`specs/cash-skill-workflows/spec.md` 的 `touched_invalid` 復原 requirements、`.claude/skills/cash-archive/SKILL.md:102`、`.claude/skills/cash-commit/SKILL.md:52`
  summary: `touched_invalid` 同時涵蓋 renamed 與 removed task，但唯一復原指引只對 renamed task 可執行；removed task 沒有可同步的 current description。
  recommendation: 先在 design 與 delta spec 定義 removed task 的安全復原與檔案歸屬，再同步兩組 skill 變體與驗證案例。
  reviewer source: Reviewer A — Adherence

### Warning

None.

### Suggestion

None.

## Rating

- cumulative blocking Critical: 1
- cumulative blocking Warning: 0
- non-blocking triaged findings: 0
- critical_gap: true
- round_type: full

有效的 Critical 顯示 removed task 的復原 contract 尚未定義；在不誤配或遺失既有 `files` 的前提下補救，需要先定義新的 attribution identity／狀態表達，已觸發 cash-apply design circuit breaker，因此本輪不能進入實作修復或下一輪。

## Fix Actions

- confidence filter：Reviewer A 的 duplicate-`task_desc` Warning 已移除。`_task_entries()` 以 `_TASK_LABEL.match()` 從完整 `task_desc` 的開頭取得 label，完整描述包含該 label；不同 label 不可能產生相同完整描述，相同 label 則會先由既有唯一性檢查以 `task_id_invalid` 拒絕，因此 reviewer 所述 silent overwrite 路徑不可達。
- needs-design：Critical「removed task 沒有可執行的 `touched_invalid` 復原出口」需要一個可保留既有 `files` 且不誤配現行 task 的 removed-task attribution identity／tombstone 或等價狀態表達；這屬於 `a synchronization primitive, identity/generation type, or state machine not defined in design.md`，不得在 cash-apply fix action 中自行引入。請先以 `$cash-ingest guard-task-state-integrity` 更新 contract 與範圍。
- Abort triage bucket 1：上述 Critical 仍是本 change 的 obligation，將作為後續 re-run 的 cumulative blocking seed；前置條件是先定義 removed task 的復原與歸屬 contract，再更新實作與測試。

## Decision

aborted

本輪因 design circuit breaker 終止；有效 Critical 無法在現有 `design.md` contract 內安全修復，必須先透過 `$cash-ingest` 更新設計與範圍。
