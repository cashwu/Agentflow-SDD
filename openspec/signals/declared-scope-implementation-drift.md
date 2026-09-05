---
id: declared-scope-implementation-drift
type: recurring-finding
status: open
occurrences: 8
first_seen: 2026-07-07
last_seen: 2026-09-05
links:
  - openspec/changes/add-review-loop-discipline/reviews/apply-r2.md
  - openspec/changes/tighten-review-loop-edge-cases/reviews/apply-r1.md
  - openspec/changes/fork-spectra-skills-to-cash/reviews/propose-r1.md
  - openspec/changes/align-cli-skill-contracts/reviews/propose-r1.md
  - openspec/changes/add-repo-vendored-cash-bundle/reviews/propose-r1.md
  - openspec/changes/default-spec-sync-on-archive/reviews/apply-r1.md
  - openspec/changes/guard-task-state-integrity/reviews/propose-r1.md
  - openspec/changes/dispatch-vendored-targets-in-batch/reviews/propose-r1.md
  - openspec/changes/dispatch-vendored-targets-in-batch/reviews/propose-r2.md
  - openspec/changes/dispatch-vendored-targets-in-batch/reviews/propose-r4.md
---

# Declared scope implementation drift

An implementation changes a file or behavior that is technically necessary, but the proposal, design, or tasks do not declare that file or behavior as in scope, leaving review and grader-protection rules with an inaccurate source of truth.

## Occurrences

- 2026-07-07 — add-review-loop-discipline — spectra-apply-plus round 2 — Round 1 modified `scripts/spectra-plus/rules.yaml` to narrow Codex slash-command substitution, but proposal Impact, design scope, and tasks did not declare that rules change until Round 2 backfilled the artifacts.
- 2026-07-07 — tighten-review-loop-edge-cases — spectra-apply-plus round 1 — Implementation modified `openspec/specs/signals-shared-layer/spec.md`, but proposal Impact and tasks did not initially name that protected master spec path until Round 1 fix actions backfilled the structured delivery scope.
- 2026-07-18 — fork-spectra-skills-to-cash — spectra-propose-plus round 1 — cash ownership migration 必須更新 signals current-writer contract 與 README，但初稿未宣告 `signals-shared-layer` capability 或 `openspec/signals/README.md`；Round 1 才補齊 delta、Impact 與 tasks。
- 2026-07-25 — align-cli-skill-contracts — cash-propose round 1 — 走訪層剪枝所需的 workspace.walk_text_files 排除參數未宣告於 proposal 的 Impact，事後過濾的替代做法則使排除完全不縮小暴露面。
- 2026-07-28 — add-repo-vendored-cash-bundle — cash-propose round 1 — clone 後免初始化會直接改變既有 `CASH-INIT-RECEIPT.md` 的適用邊界，但初稿的 Impact 與 tasks 未宣告該文件；修正為把「receipt-only 模式才需要初始化」納入文件與驗收範圍。
- 2026-08-22 — default-spec-sync-on-archive — cash-apply round 1 — 實作為滿足既有 bundle version history contract 而修改 `cash-skills.version`、`.cash-skills/lib/cash_cli/installer.py` 與 `.cash-skills/manifest.tsv`，但 `## Impact` 只列四個 `SKILL.md`，design 亦無對應 IC；deviation 已記於 implementation notes 卻未回填為宣告範圍。
- 2026-08-22 — guard-task-state-integrity — cash-propose round 1 — `## Impact` 只列六個路徑，但 IC 與 tasks 實際要求修改 `scripts/cash-cli/tests/` 下兩個既有測試檔與 `cash-commit` 的兩個變體；reviewer 依 IC 寫出參考實作跑完 145 個 CLI 測試，確認恰好兩個既有測試會因對齊而失敗，而沒有任何 task 授權修改它們，使驗證 task 不可能通過。
- 2026-09-05 — dispatch-vendored-targets-in-batch — cash-propose rounds 1–2、4 — 兩類未宣告範圍：(a) `CASH-SKILLS.md` 與 `CASH-INIT-RECEIPT.md` 共七處敘述會因本變更變成事實錯誤，卻未進 proposal Impact，且 `skill-checks.fish` 的文件斷言以正向 `assert_contains` 為主、不會對過時敘述失敗；(b) `--all` 分派到 vendored 路徑會依既有 residue cleanup 刪除 target 的 `.cash-skills/receipt.tsv`，而 proposal 與 design 都以未定義的「receipt-based target」為主詞宣稱逐字不變，整份 artifact 未提及 `--all` 會刪除 receipt。
