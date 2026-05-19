## Why

`$spectra-commit` 的 archive-first 流程會在 archive 後重新讀整個 `git status --porcelain`，但規則沒有要求只收集 archive 造成的路徑變化。當 workspace 內已存在 unrelated deletion，例如 `.agents/skills/spectra-apply-plus/SKILL.md` 或 `.claude/skills/spectra-propose-plus/SKILL.md`，Codex 可能把這些刪除誤納入同一個 commit，導致 plus skills 在提交時被刪掉。

## What Changes

- 調整既有 `spectra-commit` skill 規則，使 archive-first 流程只能把明確屬於該 change archive 的檔案加入 commit set。
- 在 `spectra-commit` 規則中加入 protected generated skills guard：`.agents/skills/spectra-*-plus/` 與 `.claude/skills/spectra-*-plus/` 的 deletion 預設不得被 stage，除非使用者在 Customize 明確指定。
- 調整 `install-spectra-plus.fish`，讓 plus installer 會檢查並套用/驗證目標專案的 `spectra-commit` guard，而不只產生 `spectra-propose-plus` 與 `spectra-apply-plus`。
- 不新增 `spectra-commit-plus` 作為主要解法；新增一個 commit-plus 只有在使用者每次都改叫它時才有效，無法修掉既有 `$spectra-commit` 的誤提交風險。

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `spectra-plus-skills`: 增加 plus installer 對 `spectra-commit` 安全規則的要求，避免 archive-first commit 誤納入 plus skill deletion。

## Impact

- Affected specs: `spectra-plus-skills`
- Affected code:
  - Modified: `install-spectra-plus.fish`
  - Modified: `.agents/skills/spectra-commit/SKILL.md`
  - Modified: `.claude/skills/spectra-commit/SKILL.md`
  - Modified: `.agents/skills/spectra-propose-plus/SKILL.md`
  - Modified: `.agents/skills/spectra-apply-plus/SKILL.md`
  - Modified: `.claude/skills/spectra-propose-plus/SKILL.md`
  - Modified: `.claude/skills/spectra-apply-plus/SKILL.md`
  - Modified: `scripts/spectra-plus/generate.fish`
  - Modified: `scripts/spectra-plus/tests/generator-checks.fish`
  - New: `openspec/changes/harden-spectra-commit-plus-skills/specs/spectra-plus-skills/spec.md`
  - New: `openspec/changes/harden-spectra-commit-plus-skills/design.md`
  - New: `openspec/changes/harden-spectra-commit-plus-skills/tasks.md`
  - New: `scripts/spectra-plus/tests/installer-commit-guard-checks.fish`
  - Removed: (none)
