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

## Bundle 版本與單一 installer 入口

`cash-skills.version` 是 repository 內唯一的 bundle 版本。任何 24 個 canonical `SKILL.md` 內容異動，都由維護者在同一版變更中提升這個版本；版本只能往前，格式為三段無 leading zero 的數字，例如 `1.0.0`。

`install-cash-skills.fish` 是唯一操作入口。單一專案部署使用 `--target`：

```fish
./install-cash-skills.fish --target /path/to/project
./install-cash-skills.fish --target /path/to/project --dry-run
./install-cash-skills.fish --target /path/to/project --force
```

成功安裝後，target 會保存 `.cash-skills/receipt.tsv`，記錄 bundle 版本、24 個 canonical paths 與 SHA-256。installer 先用 receipt 判斷版本與 target drift，再決定結果：

- `Result: update`：完成首次安裝、接管或升級；exit `0`。
- `Result: current`：target 已是相同版本且內容一致，不寫入；exit `0`。
- `Result: newer`：target 比目前 source 新，不降版、不寫入；exit `0`。
- `Result: conflict`：target 有 drift 或無 receipt 的內容不完整／不同；exit `2`。
- argument、schema、I/O、hash 或 integrity error 不輸出 domain result；exit `1`。

## Cash project guidance migration

Repository root 的 `AGENTS.md` 與 `CLAUDE.md` 是兩個 canonical guidance sources：前者使用 `$cash-*`，後者使用 `/cash-*`。每份 source 都恰好包含一個 `<!-- CASH:START -->`／`<!-- CASH:END -->` managed block；installer 從這兩份 live files 擷取對應 block，不另外維護 template。

每次非 `newer`、非 `conflict` 的 target 安裝都會檢查同名 guidance files。Installer 會更新既有 Cash block、以 Cash block取代一個合法的 `<!-- SPECTRA:START ... -->`／`<!-- SPECTRA:END -->` block，或在沒有 managed block 時附加 Cash block。它只改動已辨識的 block spans與必要邊界換行，逐位元組保留 managed spans 以外的 project-owned內容與既有 mode。Symlink、duplicate、orphan、reversed、nested、非獨立行或未知版本 marker都會在首次 target write前 fail closed，`--force` 也不會繞過。

標準 `spectra-*` skills 會保留；skill availability 與 Cash-only workflow routing 是不同邊界。guidance 不會加入 `.cash-skills/receipt.tsv`，因此只遷移 guidance 不需要調升 `cash-skills.version`；同版本 target 可先因 guidance drift 回報 `Result: update`，下一次則穩定回報 `Result: current`。

若 Spectra app 日後在 target project重新加入合法 Spectra block，Cash block仍有效；再次明確執行 installer即可移除該 Spectra block並保留其他內容。若外部工具改動 source repository 的 committed guidance，先用版本控制還原 Cash-only `AGENTS.md`／`CLAUDE.md`；只要 canonical Cash block仍完整唯一，額外且不巢狀的合法 Spectra block不會阻斷其他 targets安裝。

每次成功的 target 安裝也會清除四個 retired plus skill 目錄：`.agents/skills/spectra-propose-plus`、`.agents/skills/spectra-apply-plus`、`.claude/skills/spectra-propose-plus`、`.claude/skills/spectra-apply-plus`。只有目錄只含一個 regular `SKILL.md`、frontmatter name 與目錄相符，且所有邊界可安全讀寫時才會移除；symlink、額外檔案、名稱不符或其他未知內容會在任何 target write 前以 exit `1` 拒絕。installer 逐一刪除已辨識的 `SKILL.md` 再移除空目錄，不使用 recursive deletion，也不會修改任何 non-plus Spectra skill。

如果 cash bundle 原本已是 `current` 但仍有可辨識的 retired plus skill，本次執行會列出 `remove:` plan、完成清除並回報 `Result: update`。`--dry-run` 只預覽、不移除；`newer` 與未使用 `--force` 的 `conflict` 分支保持零寫入，也不會先清除 plus skills。

`--dry-run` 執行相同的完整 preflight，但不建立 target temporary files或持久狀態，也不修改或移除 skill files、guidance、receipt或registry；只供驗證與render使用的system temporary validation/render snapshots會在 exit 時清除。預計更新仍輸出 `Result: update`。`--force` 只可在 source 版本不低於 target 且所有 validation 通過時修復 24 個 managed `SKILL.md` 與 receipt，並清除上述四個可辨識的 retired plus 目錄；不會碰其他 inventory 外檔案，也不能繞過同版本 source integrity failure。

舊 target 沒有 receipt 時，24 個 files 全不存在會首次安裝；24 個 files 全部與 source 相同時，adoption會保留既有 24 個 skill bytes、收斂 `AGENTS.md` 與 `CLAUDE.md` guidance，並建立 receipt；mixed、缺檔或內容不同則先回報 conflict，必須確認後才使用 `--force`。

## 手動專案清單與批次更新

專案清單固定在 `$HOME/.config/cash-skills/projects.txt`。它只是使用者明確維護的 canonical path 清單，不是 watcher、排程或自動 repair。registry 與 batch 仍使用同一支 installer：

```fish
./install-cash-skills.fish --register /path/to/project
./install-cash-skills.fish --unregister /path/to/project
./install-cash-skills.fish --list
./install-cash-skills.fish --all
```

`--register` 只接受既有 non-symlink directory 並去重；`--unregister` 也能移除清單中已不存在的 stale path；`--list` 完全唯讀。清單不存在時，`--list`、`--unregister` 與 `--all` 都視為空清單且不建立狀態。

批次更新必須由使用者明確執行，也支援完整預覽與修復 drift：

```fish
./install-cash-skills.fish --all --dry-run
./install-cash-skills.fish --all --force
```

每個 target 都會列為 `updated`、`would-update`、`current`、`newer`、`conflict` 或 `failed`，最後輸出各狀態計數。單一 conflict/failed 不會阻止後續 targets，但只要任一 target 是 conflict 或 failed，整體 exit code 就是非零。批次命令不會自動移除 missing/failed entries，也不會修改 registry。

Cash skills 沒有定期 repair、fingerprint freshness、LaunchAgent、daemon 或背景同步。source 更新後，必須再次明確執行 installer 才會傳到其他專案；registry 本身不會觸發任何工作。

## 移除舊 Spectra Plus 排程

如果過去曾啟用 Spectra Plus 自動修復，安全順序是：先對 legacy registry 中每個專案安裝 cash skills，視需要用 `install-cash-skills.fish --register` 加入新的手動清單，再移除舊排程。`install-cash-skills.fish` 只清除 target 內的 retired plus skill；`uninstall-spectra-plus-repair.fish` 則處理使用者層級的 LaunchAgent、legacy registry 與 cache。cleanup 會先列出 legacy registry 內的 targets，方便逐一完成安裝。

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
spectra validate --all
```
