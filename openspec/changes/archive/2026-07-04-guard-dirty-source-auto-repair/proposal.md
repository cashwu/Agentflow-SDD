## Why

目前 LaunchAgent 會每 60 秒從 `Agentflow-SDD` 的 working tree 執行 `install-spectra-plus.fish --repair-all`。如果 source checkout 的 plus generator、rules、template、或 guard source 正在修改但尚未 commit，background repair 可能把半成品自動套用到所有 registered target，包含 `Agentflow-SDD` 自己。

## What Changes

- 讓自動 `repair-all` 在 source git working tree 或 index 有 source-sensitive dirty changes 時停止處理 registered targets，並輸出清楚的 skip 訊息。
- 保留手動單一 target 安裝/修復的彈性，避免開發者在測試 WIP 時被完全擋住。
- 讓 dry-run 路徑也呈現相同的 source dirty guard 決策，不再因為 dry-run 提早 return 而隱藏風險。
- 明確讓 dirty-source guard 在 `--repair-all` 中優先於 local metadata validation，避免 invalid WIP `rules.yaml` 被背景 repair 解讀或擴散。
- 收窄既有 background `--repair-all` 的 source guard auto-restore 行為：`--repair-all` 不再從 `HEAD` self-heal stripped source guard，而是 dirty-source skip；manual `--target` 仍保留 auto-restore。
- 增加測試覆蓋 source dirty 時不會修改 registered target，也不會把 target 誤報為 current 或 repaired。

## Non-Goals

- 不移除或自動 unregister `Agentflow-SDD` 這個 target；是否註冊自己仍由使用者管理。
- 不要求 source checkout 必須完全 clean；`openspec/changes/**`、`openspec/signals/**`、unrelated docs 等 source-sensitive path set 以外的 dirty files 不阻擋 auto repair。所有 `.agents/skills/spectra-*/**` / `.claude/skills/spectra-*/**` WIP 則刻意視為 source-sensitive。
- 不改變 `install-agentflow-sdd.fish`；該 installer 已棄用。

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `spectra-plus-skills`: 補強 automatic repair 的 source checkout safety contract，避免 background repair 使用未完成的 local source changes。

## Impact

- Affected specs: spectra-plus-skills
- Affected code:
  - Modified: install-spectra-plus.fish
  - Modified: scripts/spectra-plus/repair-all.fish
  - Modified: scripts/spectra-plus/tests/repair-all-checks.fish
  - Modified: openspec/specs/spectra-plus-skills/spec.md
  - New: none
  - Removed: none
