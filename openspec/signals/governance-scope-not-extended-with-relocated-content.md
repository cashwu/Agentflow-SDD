---
id: governance-scope-not-extended-with-relocated-content
type: recurring-finding
status: open
occurrences: 3
first_seen: 2026-07-26
last_seen: 2026-07-27
links:
  - openspec/changes/rightsize-cash-skills/reviews/propose-r1.md
  - openspec/changes/cash-skill-maintainability/reviews/propose-r1.md
  - openspec/changes/target-receipt-bootstrap/reviews/propose-r1.md
---

# Governance scope not extended with relocated content

Content moves out of a governed file into a new one, but the governance mechanisms that covered it — protected-path sets, anti-pattern assertions, parity comparison, well-formedness checks — keep pointing at the original file only. The relocated content silently leaves the governed surface, shrinking enforcement without anyone recording that it shrank.

## Occurrences

- 2026-07-26 — rightsize-cash-skills — cash-propose round 1 — 把 156 行 review loop 規則移出受保護的四個 `SKILL.md` 時，grader immutability 的受保護路徑集合、`assert_command_matrix` 的兩條反模式 `assert_absent`、對等比較與空 code span 檢查都仍只涵蓋 `SKILL.md`，搬移後的內容不受任何既有護欄約束。
- 2026-07-27 — cash-skill-maintainability — cash-propose round 1 — gate 規格改以 `scripts/cash-skills/blocks/review-gate.md` 為源頭並新增 generator 與 rules 檔時，proposal 雖已將三者納入受保護 grader 集合，但 cash-cli 的 live namespace scan surface 枚舉未同步延伸，新 live 檔全數落在 legacy-literal 治理之外；修正為新增 cash-cli delta 更新枚舉並將 `scripts/cash-skills/tests/test_live_namespace.py` 列入交付範圍。
- 2026-07-27 — target-receipt-bootstrap — cash-propose round 1 — 新增內容（而非搬移）的同型變體：原設計的 `.cash-skills/bin/cash-init` 完全落在 `test_bundle_version_history.py` 的 replaceable 守衛集合（`lib/cash_cli` 的 `rglob("*.py")` 加 24 skills）之外，其新增不觸發版本 bump 要求、其後漂移也不使 contract test 失敗——受治理集合的封閉枚舉未隨新內容延伸。最終設計改為把邏輯嵌入守衛集合內的既有檔案。
