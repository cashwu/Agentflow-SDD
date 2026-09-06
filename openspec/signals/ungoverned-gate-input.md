---
id: ungoverned-gate-input
type: recurring-finding
status: open
occurrences: 2
first_seen: 2026-07-07
last_seen: 2026-09-05
links:
  - openspec/changes/add-review-loop-discipline/reviews/propose-r1.md
  - openspec/changes/add-host-derived-round-lint/reviews/propose-r1.md
  - openspec/changes/add-host-derived-round-lint/reviews/propose-r4.md
---

# Ungoverned gate input

A change introduces a new input that a quality gate or automated check consumes (a scoring rule, a detection command, a threshold, a protected-set definition), but does not govern who may create, modify, or delete that input — leaving the gate's own judgment surface writable by the very process it is supposed to judge. The gap is created by the change itself, not a pre-existing deviation: whenever a new gate input is added, its write-governance must be defined in the same change.

## Occurrences

- 2026-07-07 — add-review-loop-discipline — spectra-propose-plus round 1 — The new signal `check` field became deterministic grader input for the pre-round self-check, but nothing governed who may add/modify/remove it: a mid-loop fix action could weaken a failing check, and the automated signals write step could coin unreviewed shell commands for future runs to execute. Fixed by making `check` human-maintained (lifecycle MODIFIED) and unconditionally untouchable by fix actions (grader-immutability rule).

- 2026-09-05 — add-host-derived-round-lint — cash-propose rounds 1、4 — 本 change 新增一個以磁碟事實為判準的 gate，其判斷面連續兩輪被發現由受審者可寫。round 1：`grader_immutability` 是否適用取決於 round file 的 `## Decision`，而 round file 正是受審 main agent 撰寫的——把 `next_round` 改成 `passed` 即可使該 gate `skip`；同時 gate 自身的 `.claude/settings.json` 與 command 檔案都不在受保護路徑集合內，而 fail-open 分支又是靜默的。round 4：為修偽陽性引入的宣告聯集把來源放寬到全部被列舉 change，而 `openspec/changes/` 不在受保護集合內且受審者可寫，因此新建任一無關 change 的 `## Impact` 即可對所有 change 永久解除該 gate。緩解只能到「收窄來源 + 可稽核」為止：fail-open 一律輸出 `gate_unavailable`，並在 Risks 逐字界定「改不動、也騙不了」的成立範圍只到未主動攻擊 gate 自身的受審者。
