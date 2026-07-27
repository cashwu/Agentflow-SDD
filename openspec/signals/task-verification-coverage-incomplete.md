---
id: task-verification-coverage-incomplete
type: recurring-finding
status: open
occurrences: 13
first_seen: 2026-07-14
last_seen: 2026-07-26
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
  - openspec/changes/refine-apply-blocker-triage/reviews/apply-r1.md
  - openspec/changes/harden-installer-mode-and-recovery/reviews/apply-r1.md
  - openspec/changes/bootstrap-openspec-config-on-install/reviews/propose-r1.md
  - openspec/changes/rightsize-cash-apply-tdd-discipline/reviews/apply-r1.md
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
- 2026-07-22 — refine-apply-blocker-triage — cash-apply round 1 — Governed-contract mutation fixture 初版只 mutation `<!-- BLOCKER-TRIAGE -->` marker，未鎖定 continue／pause 兩個處置分支；補上兩個 invocation-free behavior literals 的 direct assertions 與 mutation specs。
- 2026-07-25 — harden-installer-mode-and-recovery — cash-apply round 1 — Journal diagnostic matrix 未斷言最終 `Result:`、current/update fixture 相同且缺少 real-run 四分類；改為 dry-run／real-run 各自覆蓋四個可辨分類與 recovery 狀態。
- 2026-07-26 — bootstrap-openspec-config-on-install — cash-propose round 1 — delta spec 的 unsafe shape scenario 列舉 symlink、hard link、非 regular file 三種形狀，但 task 只斷言 symlink；hard link 是三者中唯一依賴 `read_regular` 的 `st_nlink != 1` 而非 `ensure_contained` 的形狀，實作若在新的缺檔分支改用較寬鬆的 `lstat`-only 判定就會靜默通過。「invalid + `--force` 不繞過」與「MUST NOT 進入 receipt」同樣有條文無斷言。
- 2026-07-26 — rightsize-cash-apply-tdd-discipline — cash-apply round 1 — precedence 與 catch-all boundary cases 只靠 instruction 全文中的靜態 marker 通過，未證明無可行測試邊界的 bug fix 與文件／metadata／checker-only task 實際落在第四分支；修正後解析四個編號分支並以 branch-scoped assertions 驗證 routing。
