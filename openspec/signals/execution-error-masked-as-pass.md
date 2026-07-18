---
id: execution-error-masked-as-pass
type: recurring-finding
status: open
occurrences: 5
first_seen: 2026-07-07
last_seen: 2026-07-18
links:
  - openspec/changes/add-review-loop-discipline/reviews/propose-r2.md
  - openspec/changes/repair-all-uses-pinned-commit-inputs/reviews/apply-r1.md
  - openspec/changes/fork-spectra-skills-to-cash/reviews/apply-r1.md
  - openspec/changes/add-versioned-cash-skill-batch-update/reviews/apply-r1.md
  - openspec/changes/add-versioned-cash-skill-batch-update/reviews/apply-r2.md
  - openspec/changes/add-versioned-cash-skill-batch-update/reviews/apply-r4.md
---

# Execution error masked as pass

A detection command, validation step, or exit-code convention folds its own execution errors into a success or detection result — typically via blind negation (`! cmd`), a pipeline that discards an upstream failure, or a rule that collapses all exit codes into a binary outcome. The failure direction is unsafe: a broken check reads as "no problem found" and the guarded condition silently stops being checked. Detection results and execution errors must surface as distinguishable outcomes.

## Occurrences

- 2026-07-07 — add-review-loop-discipline — spectra-propose-plus round 2 — The canonical signal `check` example `! grep -rq PATTERN dir` mapped grep execution errors (exit 2, e.g. missing path) through `!` to exit 0 = "anti-pattern absent", and the authoring rule "written to exit only 0 or 1" instructed authors to collapse error codes, making the tri-state convention's error branch unreachable. Fixed by an explicit `$?` remapping example and a no-blind-negation authoring rule.
- 2026-07-14 — repair-all-uses-pinned-commit-inputs — spectra-apply-plus round 1 — current-state assertion 的 `rg`／`awk` execution error 被壓成 stale exit 10，錯誤觸發了不該發生的安裝委派。
- 2026-07-18 — fork-spectra-skills-to-cash — cash-apply round 1 — cleanup 未檢查 registry read error，且寬鬆 `not found` classifier 會把不相關 launchctl failure 當作 service absent；修正為 pre-launchctl read preflight 與 service-specific exact error classification。
- 2026-07-18 — add-versioned-cash-skill-batch-update — cash-apply rounds 1–2 — installer 的未檢查 `seq` 與 version literal inventory 的 paired `sort` pipelines 會把 execution error 折疊成 domain/test success；改為固定 Fish indexes 與逐 pipeline `$pipestatus` fail-closed checks。
- 2026-07-18 — add-versioned-cash-skill-batch-update — cash-apply round 4 — test-side bundle comparator 的未檢查 `seq` 與 inventory digest 的 final pipeline 會把 execution error 誤判為版本或 digest 成功；改用 Fish `while`、完整 `$pipestatus` checks 與 hostile command fixtures。
