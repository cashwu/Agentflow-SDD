## Summary

替 `spectra-propose-plus` 與 `spectra-apply-plus` 生成檔加入可判斷 freshness 的穩定 plus 版本資訊，讓已註冊 project target 可以被 installer 或 repair-all 判斷是否落後。

## Motivation

目前 plus skill 生成檔保留 base Spectra skill 的 `metadata.version: "1.0"`，但這個值不代表 plus layer 的 rules/template 版本。當 `scripts/spectra-plus/rules.yaml` 或 template 更新後，相關專案只能靠內容 sentinel 判斷是否 current，缺少一個清楚的人讀與機器檢查用版本訊號。

## Proposed Solution

- 在 plus skill 生成輸出中加入穩定的 plus layer 版本欄位與更新日期欄位，例如 `spectraPlusVersion` 與 `spectraPlusUpdated`。
- 版本資訊由 `scripts/spectra-plus/rules.yaml` 控制，透過既有 generator 寫入所有 `.claude/` 與 `.agents/` plus skill 輸出，避免手改 generated `SKILL.md`。
- 更新 installer/repair-all 的 current 判斷，使 target project 缺少 current plus 版本資訊時會被視為 stale 並重新產生。
- 更新 generator 與 repair-all 測試，鎖定四個 generated plus skill variants 都含有 current plus version metadata。

## Non-Goals

- 不修改 `install-agentflow-sdd.fish`；該 installer 已棄用，不納入本變更範圍。
- 不使用每次生成時的動態 timestamp；這會破壞 generator idempotency。
- 不把 `metadata.version` 重新定義為 plus layer 版本，避免混淆 base Spectra skill 版本與 plus generated layer 版本。

## Alternatives Considered

- 只看 generated file 的 git diff 或 sentinel：可用於測試，但無法讓人快速看出目標專案是否落後，也不適合 registry target 的 freshness 判斷。
- 只加入日期、不加入版本：日期對人可讀，但不適合機器做相容性或升級判斷。
- 每次 generate 寫入 `generatedAt`：會讓兩次無輸入變更的 generator output 不再 byte-identical，違反既有 idempotent regeneration 契約。

## Impact

- Affected specs: spectra-plus-skills
- Affected code:
  - Modified: scripts/spectra-plus/rules.yaml
  - Modified: scripts/spectra-plus/generate.fish
  - Modified: install-spectra-plus.fish
  - Modified: scripts/spectra-plus/tests/generator-checks.fish
  - Modified: scripts/spectra-plus/tests/repair-all-checks.fish
  - Modified: openspec/specs/spectra-plus-skills/spec.md
  - Modified: .claude/skills/spectra-propose-plus/SKILL.md
  - Modified: .claude/skills/spectra-apply-plus/SKILL.md
  - Modified: .agents/skills/spectra-propose-plus/SKILL.md
  - Modified: .agents/skills/spectra-apply-plus/SKILL.md
  - New: none
  - Removed: none
