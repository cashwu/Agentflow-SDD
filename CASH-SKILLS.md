# Cash Skills

本 repository 直接維護 cash workflow skills。它們是 source-controlled canonical files，不由 Spectra 產生，也沒有 base／plus 兩層。

## Inventory

兩個 variant 都提供同一組十二個 workflow：

- `cash-analyze`
- `cash-apply`
- `cash-archive`
- `cash-ask`
- `cash-audit`
- `cash-commit`
- `cash-debug`
- `cash-discuss`
- `cash-drift`
- `cash-ingest`
- `cash-propose`
- `cash-verify`

Codex files 位於 `.agents/skills/`，Claude files 位於 `.claude/skills/`。Codex 以 `$cash-*` 呼叫，Claude 以 `/cash-*` 呼叫；兩者仍使用 `spectra` CLI 與 `openspec/` artifacts。

## 安裝到其他專案

installer 是明確、無狀態的單次部署：

```fish
./install-cash-skills.fish --target /path/to/project
./install-cash-skills.fish --target /path/to/project --dry-run
./install-cash-skills.fish --target /path/to/project --force
```

沒有 `--force` 時，任一 managed destination 與 source 不同都會列為 conflict，且完整 preflight 失敗前不會寫入任何 cash file。`--force` 只會替換 24 個 managed `SKILL.md`，不會碰其他檔案。

Cash skills 沒有定期 repair、target registry、fingerprint freshness、LaunchAgent 或背景同步。source 更新後，必須再次明確執行 installer 才會傳到其他專案。

## 移除舊 Spectra Plus 排程

如果過去曾啟用 Spectra Plus 自動修復，安全順序是：先對 registry 中每個專案安裝 cash skills，再移除舊排程。cleanup 會先列出舊 registry 內的 targets，方便逐一完成安裝。

先預覽，不呼叫 `launchctl`、不刪除狀態：

```fish
./uninstall-spectra-plus-repair.fish --dry-run
```

確認每個 target 都已安裝後再執行：

```fish
./uninstall-spectra-plus-repair.fish
```

cleanup 會卸載已知的兩個 legacy labels，移除其 plists、registry 與 cache，並保留 `$HOME/Library/Logs/spectra-plus-repair.log`。它可重複執行；狀態已不存在時會成功 no-op。

## Signals

`cash-propose` 與 `cash-apply` 的 review loop 會依 `openspec/signals/README.md` 讀寫共享 signals。`status` 與選填的 `check` 都由人維護；自動 writer 不會變更它們。

## 驗證

```fish
fish scripts/cash-skills/tests/skill-checks.fish
spectra validate fork-spectra-skills-to-cash
```
