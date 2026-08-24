# Cash Propose Review — Round 2

## Reviewer Findings

### Critical

1. `severity`: Critical
   `confidence`: 100
   `layer`: design
   `disposition`: fix-introduced
   `introduced_by`: Round 1 將 test-quality bootstrap 改為 resource 建立後立即透過 project-local CLI 驗證的 fix action
   `location`: `design.md` D2/D5/C2、`tasks.md` 1.1、`specs/cash-cli/spec.md`
   `summary`: managed resource 已修改但尚未 self-install 時，manifest／receipt 會 fail closed；原先要求在 self-install 前立即透過 project-local CLI 驗證，因此既定順序不可執行。
   `recommendation`: 排定為具名 RED、version bump、managed resource edits、self-install、project-local CLI 驗證，再允許後續 test edit與驗證。
   reviewer source: Reviewer V

### Warning

1. `severity`: Warning
   `confidence`: 100
   `layer`: design
   `disposition`: fix-introduced
   `introduced_by`: Round 1 將 task contract 擴為五欄並把 `success` 映射為 primary target success marker 的 fix action
   `location`: `design.md` D3/C3、`tasks.md` 1.1/2.1、兩份 delta specs
   `summary`: 兩個 task 的 `success` 混入 regression、publication 與全量 suite 結果，無法由各自唯一的 primary target 直接觀察，與 same-target GREEN contract 不一致。
   `recommendation`: 將 `success` 收斂為 primary target 可直接觀察的具名成功證據，其餘結果留在 `regression` 或 delivery contract。
   reviewer source: Reviewer V

### Suggestion

無。

## Rating

- Critical: 1
- Warning: 1
- Non-blocking triaged: 0
- `critical_gap`: true
- `round_type`: micro

Reviewer V 已明確確認 Round 1 的四個 cumulative members 全部 resolved，並由 Round 1 fixes 發現一個不可執行的 publication ordering 與一個 success-marker 分型缺陷；兩者皆為 `fix-introduced`，因此成為新的 blocking cumulative members。

## Fix Actions

- verified-resolution removal：Reviewer V 確認「test-quality resource bootstrap circularity」已由有界五項 gate解除，從 cumulative blocking set移除。
- verified-resolution removal：Reviewer V 確認「cash-debug 缺少 carrier-neutral evidence carrier」已由 Phase 3 notes contract解除，從 cumulative blocking set移除。
- verified-resolution removal：Reviewer V 確認「version bump 排在觀察 RED 前」已由 task 1.1 ordering修正，從 cumulative blocking set移除。
- verified-resolution removal：Reviewer V 確認「verification 未區分 primary 與 regression」已由五欄 contract解除，從 cumulative blocking set移除。
- 修改 `proposal.md`：將 bootstrap publication 順序明訂為 managed edits 後先 self-install，再以 project-local CLI 驗證，通過後才能繼續 test edit。
- 修改 `design.md`：同步 D2、D3、D5、C2、C3；定義 CLI check 是 self-install 後第一步，並禁止 `success` 混入 regression／publication／task-completion evidence。
- 修改 `tasks.md`：重排 task 1.1 為 self-install 後立刻執行 CLI 同源驗證；將兩個 task 的 `success` 收斂為各自 primary target 可直接觀察的 exit 0 與具名 assertions。
- 修改 `specs/cash-cli/spec.md`：新增可信 bundle publication ordering，並收緊 tasks resource 的 primary success marker contract與scenario。
- 修改 `specs/cash-skill-workflows/spec.md`：同步 `cash-apply` 對 `success` 欄位的分型限制。
- 修正後執行 `.cash-skills/bin/cash validate strengthen-cash-tdd-evidence`，結果通過。
- 修正後完成 mechanical self-check：self-install／CLI ordering 已跨 artifacts 同步，兩個 task 的 `success` 不再包含 manifest、receipt、全量 suite或其他 regression結果，未發現殘留四欄、`tasks.md`-only canonical carrier或 stray separator。

## Decision

next_round

本輪兩項 `fix-introduced` blocking findings 已修正；必須由下一位全新 Reviewer V 明確驗證 resolved，才能清空 cumulative blocking set。
