## Why

目前 `spectra-*` skills 由 Spectra 管理，專案對它們的客製化只能透過 `*-plus` 衍生檔與定期 repair 機制維持；每次 Spectra 更新都可能改寫來源或刪除衍生輸出，造成長期維護成本與背景修復風險。將工作流程 fork 為專案自有的 `cash-*` skills，可讓 Spectra 繼續管理 CLI 與 `openspec/` artifacts，同時讓客製化 workflow 擁有穩定且清楚的 ownership。

## What Changes

- 新增 Claude 與 Codex 雙變體的十二個 `cash-*` skills：`cash-analyze`、`cash-apply`、`cash-archive`、`cash-ask`、`cash-audit`、`cash-commit`、`cash-debug`、`cash-discuss`、`cash-drift`、`cash-ingest`、`cash-propose`、`cash-verify`。
- 將目前 `spectra-propose-plus` 的 artifact 建立與 sub-agent quality gate 完整併入 `cash-propose`，並將 `spectra-apply-plus` 的 implementation、review、fix 與收斂規則完整併入 `cash-apply`；不建立任何 `cash-*-plus` skill。
- 將所有 skill-to-skill invocation 改為 `$cash-*`，但保留 `spectra list`、`spectra status`、`spectra validate`、`spectra archive` 等 Spectra CLI contract 與既有 `openspec/` 目錄配置。
- 建立明確的自有 ownership：`cash-*` 是 source-controlled canonical files，不帶 `generatedBy: "Spectra"` 或 `spectraPlus*` metadata，也不從會被 Spectra 更新的 `spectra-*` skill 動態生成。
- 新增 `install-cash-skills.fish`，將本 repo 的 canonical Claude/Codex `cash-*` skills 安裝到明確指定的其他專案；支援 `--target` 與 `--dry-run`，且不建立 registry、背景程序或定期 repair。
- **BREAKING**：專案預設 workflow invocation 從 `$spectra-*`／`$spectra-*-plus` 切換為 `$cash-*`；舊的 `spectra-*` skills 留給 Spectra 管理，但不再是本專案客製流程的入口。
- 新增 `uninstall-spectra-plus-repair.fish` 作為一次性 migration cleanup，安全 unload 並移除舊 LaunchAgent、repair target registry 與排程狀態；預設保留診斷 logs，重複執行仍須成功。
- 將過時的 `SPECTRA-PLUS.md` 改寫為 `CASH-SKILLS.md`，記錄 cash inventory、跨專案安裝、先遷移 target 再清除舊排程的順序，以及 cash skills 不含 automatic repair 的 ownership 規則。
- 將 signals 共享層的現行 writer/read-loop 說明與 provenance 切換到 `cash-propose`／`cash-apply`，但保留 signal schema、人工維護的 `status`／`check` 與歷史 occurrence 文字。
- 移除 `spectra-plus` generator、installer、fingerprint、`repair-all`、LaunchAgent auto-repair 與 `spectra-commit` plus deletion workaround；以唯讀 contract tests 驗證 skill inventory、雙變體語意、installer 邊界、cleanup idempotence、禁止殘留 plus invocation，以及 Spectra update 不會改動 `cash-*`。
- 更新專案 workflow 說明，讓 discuss → propose → apply ⇄ ingest → archive/commit 全程使用 `cash-*`。

## Capabilities

### New Capabilities

- `cash-skill-workflows`: 定義自有 `cash-*` skill inventory、ownership、雙變體一致性、propose/apply quality gate、Spectra CLI interoperability、update isolation 與 legacy plus migration contract。

### Modified Capabilities

- `spectra-plus-skills`: 退役 `spectra-propose-plus`、`spectra-apply-plus` 及其 generation、installation、freshness、automatic repair、commit guard 與 quality-gate contracts，並將仍需保留的 workflow 行為移交給 `cash-skill-workflows`。
- `signals-shared-layer`: 將現行 signals README 與 automated-writer provenance 從 plus review loop 更新為 cash review loop，不改變 signal file schema 或人工維護規則。

## Impact

- Affected specs: `cash-skill-workflows`, `spectra-plus-skills`, `signals-shared-layer`
- Affected code:
  - Modified:
    - AGENTS.md
    - .agents/skills/spectra-commit/SKILL.md
    - .claude/skills/spectra-commit/SKILL.md
    - openspec/signals/README.md
    - openspec/signals/background-wrapper-bypasses-guard.md
    - openspec/signals/declared-scope-implementation-drift.md
    - openspec/signals/execution-error-masked-as-pass.md
    - openspec/signals/removed-mechanism-residual-references.md
    - openspec/signals/task-verification-coverage-incomplete.md
  - New:
    - .agents/skills/cash-analyze/SKILL.md
    - .agents/skills/cash-apply/SKILL.md
    - .agents/skills/cash-archive/SKILL.md
    - .agents/skills/cash-ask/SKILL.md
    - .agents/skills/cash-audit/SKILL.md
    - .agents/skills/cash-commit/SKILL.md
    - .agents/skills/cash-debug/SKILL.md
    - .agents/skills/cash-discuss/SKILL.md
    - .agents/skills/cash-drift/SKILL.md
    - .agents/skills/cash-ingest/SKILL.md
    - .agents/skills/cash-propose/SKILL.md
    - .agents/skills/cash-verify/SKILL.md
    - .claude/skills/cash-analyze/SKILL.md
    - .claude/skills/cash-apply/SKILL.md
    - .claude/skills/cash-archive/SKILL.md
    - .claude/skills/cash-ask/SKILL.md
    - .claude/skills/cash-audit/SKILL.md
    - .claude/skills/cash-commit/SKILL.md
    - .claude/skills/cash-debug/SKILL.md
    - .claude/skills/cash-discuss/SKILL.md
    - .claude/skills/cash-drift/SKILL.md
    - .claude/skills/cash-ingest/SKILL.md
    - .claude/skills/cash-propose/SKILL.md
    - .claude/skills/cash-verify/SKILL.md
    - install-cash-skills.fish
    - uninstall-spectra-plus-repair.fish
    - scripts/cash-skills/tests/skill-checks.fish
    - scripts/cash-skills/variant-parity/cash-analyze.diff
    - scripts/cash-skills/variant-parity/cash-ask.diff
    - scripts/cash-skills/variant-parity/cash-audit.diff
    - scripts/cash-skills/variant-parity/cash-drift.diff
    - scripts/cash-skills/variant-parity/cash-ingest.diff
    - scripts/cash-skills/variant-parity/cash-propose.diff
    - scripts/cash-skills/variant-parity/cash-verify.diff
    - CASH-SKILLS.md
    - openspec/signals/filesystem-boundary-validation-missing.md
    - openspec/signals/managed-block-overwrites-project-guidance.md
    - openspec/signals/namespace-migration-literal-residue.md
    - openspec/signals/retained-contract-subset-loss.md
    - openspec/signals/service-discovery-coupled-to-plist.md
    - openspec/signals/variant-parity-checks-only-markers.md
  - Removed:
    - .agents/skills/spectra-apply-plus/SKILL.md
    - .agents/skills/spectra-propose-plus/SKILL.md
    - .claude/skills/spectra-apply-plus/SKILL.md
    - .claude/skills/spectra-propose-plus/SKILL.md
    - scripts/spectra-plus/
    - install-spectra-plus.fish
    - SPECTRA-PLUS.md
- Affected systems: 已安裝的 macOS LaunchAgent 與 repair target registry 需要一次性停用／清理；Spectra CLI、`spectra-*` generated skills 與 `openspec/` artifact schema 不變。
