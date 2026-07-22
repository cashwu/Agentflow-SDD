---
id: task-verification-coverage-incomplete
type: recurring-finding
status: open
occurrences: 9
first_seen: 2026-07-14
last_seen: 2026-07-22
links:
  - openspec/changes/repair-all-uses-pinned-commit-inputs/reviews/apply-r1.md
  - openspec/changes/converge-plus-review-loop/reviews/apply-r2.md
  - openspec/changes/fork-spectra-skills-to-cash/reviews/apply-r1.md
  - openspec/changes/fork-spectra-skills-to-cash/reviews/apply-r2.md
  - openspec/changes/add-versioned-cash-skill-batch-update/reviews/apply-r4.md
  - openspec/changes/add-versioned-cash-skill-batch-update/reviews/apply-r6.md
  - openspec/changes/chinese-spec-content/reviews/propose-r1.md
  - openspec/changes/migrate-cash-project-guidance/reviews/apply-r1.md
  - openspec/changes/migrate-cash-project-guidance/reviews/apply-r2.md
  - openspec/changes/migrate-cash-project-guidance/reviews/apply-r4.md
---

# Task verification coverage incomplete

A task is marked complete after testing the primary outcome but omits one or more verification branches explicitly named in the task or implementation contract, leaving the completion claim stronger than the regression evidence.

## Occurrences

- 2026-07-14 — repair-all-uses-pinned-commit-inputs — spectra-apply-plus round 1 — current-state error tests initially omitted fail-and-continue across targets and the required dry-run error/no-state branch even though both were explicit verification targets.
- 2026-07-16 — converge-plus-review-loop — spectra-apply-plus round 2 — impact granularity advisory 的測試只鎖定標題與 `> 15` 主路徑，未鎖定 task/spec 明定的 `(none)` 排除及 15 靜默、16 警告邊界。
- 2026-07-18 — fork-spectra-skills-to-cash — cash-apply rounds 1–2 — review workflow tasks 宣告完整 branch fixtures，但初版只有靜態 marker 與單檔 mutation，且 Round 1 修正先被 variant parity 代擋；最終改為同步 mutation 所有 canonical copies並由 branch-specific assertions 獨立 fail loud。
- 2026-07-18 — add-versioned-cash-skill-batch-update — cash-apply round 4 — batch regression matrix 沒有真正的 dry-run `would-update` target，也未證明 `--all --force` 保留 newer target；補上獨立 older/newer fixtures、status assertions 與完整 tree 零變更證據。
- 2026-07-18 — add-versioned-cash-skill-batch-update — cash-apply round 6 — retired-plus cleanup tasks 已標記完成，但 unsafe candidate matrix、四個 normal plan branches、newer+force preservation 與 exact batch summaries 尚未全部 fail loud；補上獨立 fixtures 與完整輸出 assertions。
- 2026-07-19 — chinese-spec-content — cash-propose round 1 — C1 驗收 grep 以 cash-propose 措辭為模板推及四檔，cash-apply 實際措辭（'always English, regardless of any other language rule'）匹配不到，漏改不可偵測。
- 2026-07-22 — migrate-cash-project-guidance — cash-apply round 1 — Task 2.2已標記完成，但boundary matrix未覆蓋parent/destination swaps、permission failure、新檔0644與完整managed-span外byte snapshots。
- 2026-07-22 — migrate-cash-project-guidance — cash-apply seeded round 1 — 初次補強仍缺少final pathname checkpoint後的parent swap，且部分replacement sentinel只以trimmed text檢查；補上專用hook及完整byte、inode與symlink identity assertions。
- 2026-07-22 — migrate-cash-project-guidance — cash-apply round 4 — Source malformed fixture只區分成功與非成功，未證明task明列的精確code 1；改為保存`$status`並直接斷言等於1。
