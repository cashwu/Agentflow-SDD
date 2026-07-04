# Propose Plus Review — Round 4

## Reviewer Findings

### Critical

- severity: Critical
  confidence: 100
  location: `specs/spectra-plus-skills/spec.md` `Auto-restore stripped commit guard source from git HEAD`; `tasks.md` `1.4`
  summary: `Auto-restore stripped commit guard source from git HEAD` 仍要求 automatic `--repair-all` 在 `source-sensitive paths are clean` 時可 restore stripped source from `HEAD`，但 stripped working-tree source 本身就是 source-sensitive dirty state，會被 dirty-source guard 優先 skip。
  recommendation: 將 auto-restore 成功路徑限制為 manual `--target` / `--target --dry-run`；automatic `--repair-all` 對 stripped source 應 dirty-source skip，不保留 clean-source restore 分支。
  reviewer: A+B

### Warning

- severity: Warning
  confidence: 84
  location: `design.md` `### Guard repair-all with source-sensitive dirty detection`; `specs/spectra-plus-skills/spec.md` `Repair-all protects registered targets from dirty source checkout`; `tasks.md`
  summary: artifacts 未定義 `git status --porcelain` 無法判定 source state 時的行為，例如 source 不在 git work tree、無 `HEAD`、或 `git` 執行失敗。
  recommendation: 定義 automatic `--repair-all` 在無法確認 source-sensitive paths clean 時 fail-closed skip exit 0，並補對應 task。
  reviewer: B

- severity: Warning
  confidence: 78
  location: `tasks.md` `1.2`; `specs/spectra-plus-skills/spec.md` source-sensitive path set
  summary: task matrix 只明確要求 `.agents/.claude/skills/spectra-commit/SKILL.md`，但 source-sensitive contract 涵蓋所有 `.agents/skills/spectra-*/**` 與 `.claude/skills/spectra-*/**`。
  recommendation: 在 task matrix 增加至少一個非 commit skill fixture，例如 `.agents/skills/spectra-propose/SKILL.md` 與 `.claude/skills/spectra-apply/SKILL.md`。
  reviewer: B

### Suggestion

None.

## Rating

Critical count: 1
Warning count: 1
critical_gap: true

Round 4 判定為 `next_round`，因為 auto-restore 的 automatic `--repair-all` 成功分支仍然和 dirty-source guard 的 source-sensitive path definition 矛盾。source clean state unavailable 與非 commit skill path matrix 也是實作安全性與測試完整性的缺口，已修入 contract/tasks。

## Fix Actions

- 修改 `design.md`：新增 source clean state unavailable fail-closed skip 行為。
- 修改 `specs/spectra-plus-skills/spec.md`：新增 source clean state unavailable scenario；將 `Auto-restore stripped commit guard source from git HEAD` 限定為 manual `--target` / `--target --dry-run`，並明確 `--repair-all` 對 stripped source dirty-source skip。
- 修改 `tasks.md`：新增非 commit skill path fixtures、manual target dry-run restore report、source clean state unavailable fixture。
- 重新執行 `spectra validate guard-dirty-source-auto-repair`，結果通過。

## Decision

next_round
