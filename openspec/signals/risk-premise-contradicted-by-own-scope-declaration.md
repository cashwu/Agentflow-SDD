---
id: risk-premise-contradicted-by-own-scope-declaration
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-09-05
last_seen: 2026-09-05
links:
  - openspec/changes/add-host-derived-round-lint/reviews/propose-r1.md
---

# Risk premise contradicted by the change's own scope declaration

一條 Risk 或緩解敘述以「本 change 不觸及 X」為前提推導出安全結論，但同一份 change 的 `## Impact` 或 `tasks.md` delivery target 明確包含 X。前提為假使結論失去根據，而這類敘述通常正是讀者判斷「是否需要額外防護」的依據。撰寫任何以「本 change 不做 Y」為前提的 Risk 時，必須對照該 change 自己的結構化範圍宣告逐項核對。

## Occurrences

- 2026-09-05 — add-host-derived-round-lint — cash-propose round 1 — design 的一條 Risk 宣稱「本 change 不修改任何受保護路徑，因此不需要動用 declared-scope 例外，本 change 的 review loop 期間保護維持完整」，但 `scripts/cash-cli/tests/cli-checks.fish` 既在受保護路徑集合內，也同時出現在該 change 的 `## Impact` 與某個 task 的 delivery target。事實是該 change 確實修改受保護路徑並確實依賴 structured scope declaration 例外——它因此成為自己所實作 gate 的第一個 declared-scope 例外案例，該 Risk 改寫後反而變成指定實作時必須判 `pass` 的雙向 fixture 來源。
