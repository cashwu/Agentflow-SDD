# Cash Propose Review — Round 1

## Reviewer Findings

### Critical

1. `severity`: Critical
   `confidence`: 100
   `layer`: design
   `location`: `design.md` C2、`tasks.md` 1.1、`specs/cash-cli/spec.md`
   `summary`: 建立 `DISCIPLINES["test-quality"]` 的第一個測試修改要求先取得尚不存在的 canonical instruction，形成無法執行的自舉循環。
   `recommendation`: 為本 change 的 resource bootstrap 定義一次性且有界的五項 gate，並要求 resource 建立後立即切回 CLI 單一來源。
   reviewer source: Nash、Maxwell

2. `severity`: Critical
   `confidence`: 100
   `layer`: design
   `location`: `design.md` C1/C4、`specs/cash-cli/spec.md`、`specs/cash-skill-workflows/spec.md`
   `summary`: canonical TDD evidence 直接依賴 `tasks.md` 欄位，但 `cash-debug` 不一定在 Cash change 內執行，沒有可供 Phase 4 消費的 carrier。
   `recommendation`: 將 canonical discipline 改為 carrier-neutral，並由 `cash-debug` Phase 3 notes 提供 primary target、regression targets、success marker 與 failure marker 或 N/A 理由。
   reviewer source: Nash、Maxwell

### Warning

1. `severity`: Warning
   `confidence`: 100
   `layer`: design
   `location`: `design.md` C6、`tasks.md` 1.1
   `summary`: task 先要求遞增 `cash-skills.version` 與 `installer.py`，再要求觀察任何 production edit 前的 RED，實作順序互相衝突。
   `recommendation`: 先新增並執行 resource test 觀察具名 RED，再遞增版本，之後才修改 managed behavior。
   reviewer source: Nash

2. `severity`: Warning
   `confidence`: 100
   `layer`: design
   `location`: `design.md` C3、`tasks.md`、兩份 delta specs
   `summary`: 原本只有未分型的 `verification` 欄位，無法判定哪個 command 是 same-target RED/GREEN 的 primary target、哪些是後續 regression targets。
   `recommendation`: 將 task contract 擴充為 `delivery`、`verification`、`regression`、`success`、`red` 五欄，並明確定義 `verification` 恰為一個 primary target。
   reviewer source: Maxwell

### Suggestion

無。

## Rating

- Critical: 2
- Warning: 2
- Non-blocking triaged: 0
- `critical_gap`: true
- `round_type`: full

兩個 Critical 都使核心 workflow contract 無法被可靠執行，兩個 Warning 則造成 RED ordering 與 verification target 解讀不唯一；第一輪所有 surviving Critical／Warning 均屬 blocking，因此必須修正並進入下一輪。

## Fix Actions

- 修改 `proposal.md`：補入一次性 test-quality bootstrap 邊界、carrier-neutral TDD 語意、`cash-debug` Phase 3 carrier，以及 primary／regression 分型。
- 修改 `design.md`：新增有界 bootstrap 規則；把 canonical TDD 改為 current-workflow carrier；定義 `cash-apply` 與 `cash-debug` 的 evidence mapping；將 task 1 的順序改為先觀察 RED、再 bump version、最後修改 managed behavior。
- 修改 `tasks.md`：將兩個 implementation task 都改為五欄 verification contract；task 1.1 先執行 primary target 觀察具名 RED，再進行版本與 resource edits；task 2.1 明列 `cash-debug` Phase 3 carrier 驗證。
- 修改 `specs/cash-cli/spec.md`：同步 carrier-neutral executed RED／GREEN、五欄 task resource contract、primary／regression 定義及本 change 專用 bootstrap scenario。
- 修改 `specs/cash-skill-workflows/spec.md`：同步 `cash-apply` 五欄 mapping，並要求 `cash-debug` Phase 3 notes 在沒有 `tasks.md` 時提供完整 evidence carrier。
- 修正後執行 `.cash-skills/bin/cash validate strengthen-cash-tdd-evidence`，結果通過。
- 修正後完成 mechanical self-check：MODIFIED requirement 標題與 master specs 完全相同，五欄／十一項 TDD 語意／五項 test-quality gate 的數量一致，未發現 comment imbalance、stray separator 或殘留四欄敘述。

## Decision

next_round

第一輪四項 blocking findings 均已在 artifacts 中修正；依 cumulative blocking set 規則，仍須由全新的 Reviewer V 對每一項提供 resolved／unresolved verdict，才能移除 blocking members。
