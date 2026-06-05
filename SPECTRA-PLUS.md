# Spectra Plus Skills

本文件說明如何產生、安裝與自動修復 `spectra-propose-plus` / `spectra-apply-plus`，以及如何維護 `spectra-commit` guard。

## 用途

`scripts/spectra-plus/generate.fish` 會從既有 `spectra-propose` / `spectra-apply` skill 與 `scripts/spectra-plus/rules.yaml` 產生 plus skills。`install-spectra-plus.fish` 則把這些 generated plus skills 安裝到目標專案，並補上 `spectra-commit` 的 archive-first allowlist 與 plus deletion protection。

Plus skills 是 derived artifacts。若 Spectra.app 重新產生 `.agents/skills/` 或 `.claude/skills/`，可以用 installer 或 repair-all 補回。

## 必要條件

- 本機可執行 `fish`。
- 本機可執行 `yq`。
- 目標專案已存在下列 base skills：
  - `.claude/skills/spectra-propose/SKILL.md`
  - `.claude/skills/spectra-apply/SKILL.md`
  - `.claude/skills/spectra-commit/SKILL.md`
  - `.agents/skills/spectra-propose/SKILL.md`
  - `.agents/skills/spectra-apply/SKILL.md`
  - `.agents/skills/spectra-commit/SKILL.md`

macOS 可用 Homebrew 安裝 `yq`：

```fish
brew install yq
```

## 單一專案安裝

指定一個 project target 安裝或修復 plus skills：

```fish
./install-spectra-plus.fish --target /path/to/project
```

也可以使用 positional target：

```fish
./install-spectra-plus.fish /path/to/project
```

Dry-run 只列出會做的動作，不修改檔案：

```fish
./install-spectra-plus.fish --target /path/to/project --dry-run
```

## Target Registry

Registry 保存需要自動維護 plus skills 的明確 project target 清單。預設路徑：

```text
$HOME/.config/spectra-plus/projects.txt
```

每行一個 normalized absolute path。空行與 `#` 開頭註解會被忽略。Registry 不會掃描 workspace，也不會推斷其他專案。

### Registry 檔案說明

`projects.txt` 是這個 plus skills 自動修復機制唯一持久化「要維護哪些專案」的檔案，行為如下：

- **格式**：純文字，一行一個 absolute path；空行與 `#` 開頭的整行註解會被忽略，可手動編輯。
- **建立時機**：首次 `--register-target` 成功時才建立（會一併 `mkdir -p` 上層目錄）；在此之前檔案不存在，`--list-targets` / `--repair-all` 視為「沒有任何 target」。
- **路徑正規化**：註冊時若 target 是存在的目錄，會以該目錄的真實絕對路徑寫入；尾端多餘的 `/` 會被移除。所以同一專案的不同寫法（相對路徑、尾斜線）正規化後算同一列。
- **去重**：以「整行完全相同」判斷，重複註冊同一 normalized path 不會新增列，只回報 `target already registered`。
- **誰會讀寫**：`--register-target` / `--unregister-target` 寫入；`--list-targets`、`--repair-all`（含 LaunchAgent 觸發）讀取。Registry 之外的專案一律不會被自動修復。
- **刪除專案後**：檔案路徑可能變 stale，用 `--unregister-target` 清掉該列即可（target 已從 filesystem 刪除也能成功）。

註冊 target：

```fish
./install-spectra-plus.fish --register-target /path/to/project
```

重複註冊同一路徑不會新增重複列。不存在或非目錄 target 會失敗，且不修改 registry。

取消註冊 target：

```fish
./install-spectra-plus.fish --unregister-target /path/to/project
```

取消註冊是 registry cleanup 操作，target 可以已經從 filesystem 刪除。未註冊路徑會成功 no-op。

列出目前有效 registry targets：

```fish
./install-spectra-plus.fish --list-targets
```

Registry dry-run：

```fish
./install-spectra-plus.fish --register-target /path/to/project --dry-run
./install-spectra-plus.fish --unregister-target /path/to/project --dry-run
```

## Repair All

修復 registry 內所有 target：

```fish
./install-spectra-plus.fish --repair-all
```

`--repair-all` 只處理 registry 內 target，不掃描或修復 registry 外的 project。每個 valid target 會重用單一 target installer 的驗證與修復邏輯；單一 target 失敗不會中止後續 target，但最後 exit code 會是非零。

輸出會包含 per-target summary：

- `[success]`：target 已修復。
- `[skipped]`：target 已是 current、被 lock 擋下，或在 throttle window 內。
- `[failed]`：target invalid 或修復失敗。

Dry-run 不修改 registry、project files、lock、cache 或 throttle state：

```fish
./install-spectra-plus.fish --repair-all --dry-run
```

手動強制執行可略過 throttle，但仍遵守 lock：

```fish
./install-spectra-plus.fish --repair-all --force
```

LaunchAgent 也會直接呼叫 thin entrypoint：

```fish
scripts/spectra-plus/repair-all.fish
```

## LaunchAgent 自動修復

macOS LaunchAgent 可定期執行 repair-all，讓 Spectra.app reset skills 後自動補回 registered targets。

安裝或更新 LaunchAgent：

```fish
./install-spectra-plus.fish --install-launch-agent
```

移除 LaunchAgent：

```fish
./install-spectra-plus.fish --uninstall-launch-agent
```

Dry-run 不寫入或移除 plist，也不呼叫 `launchctl`：

```fish
./install-spectra-plus.fish --install-launch-agent --dry-run
./install-spectra-plus.fish --uninstall-launch-agent --dry-run
```

預設設定：

- Label：`com.agentflow.spectra-plus.repair`
- Plist：`$HOME/Library/LaunchAgents/com.agentflow.spectra-plus.repair.plist`
- Log：`$HOME/Library/Logs/spectra-plus-repair.log`
- `StartInterval`：`60` 秒
- Throttle window：不大於 `StartInterval`

LaunchAgent 不會修改 `/Applications/Spectra.app`。它只定期執行 repair-all，repair-all 只處理 registry 內 targets。

## Lock 與 Throttle

repair-all 使用 lock 防止 overlapping execution。預設 lock path：

```text
$TMPDIR/spectra-plus-repair.lock
```

最近 repair attempt time 存在：

```text
$HOME/.cache/spectra-plus/last-repair-attempt
```

Throttle 是以 repair attempt 為單位更新，不要求整體成功。即使 registry 中有 invalid target 導致非零 exit，下一次自動觸發仍會在 throttle window 內被跳過，避免 LaunchAgent 反覆觸碰 valid targets。

## 常見操作

註冊目前專案並立即修復：

```fish
./install-spectra-plus.fish --register-target (pwd)
./install-spectra-plus.fish --repair-all --force
```

設定自動修復：

```fish
./install-spectra-plus.fish --register-target /path/to/project-a
./install-spectra-plus.fish --register-target /path/to/project-b
./install-spectra-plus.fish --install-launch-agent
```

Spectra.app reset 後手動補回：

```fish
./install-spectra-plus.fish --repair-all --force
```

清掉已刪除 project 的 stale entry：

```fish
./install-spectra-plus.fish --unregister-target /path/to/deleted-project
```

## 驗證

完整驗證：

```fish
fish scripts/spectra-plus/tests/installer-commit-guard-checks.fish
fish scripts/spectra-plus/tests/repair-all-checks.fish
fish scripts/spectra-plus/tests/generator-checks.fish
spectra validate auto-repair-spectra-plus-skills
```

語法檢查：

```fish
fish -n install-spectra-plus.fish scripts/spectra-plus/repair-all.fish scripts/spectra-plus/tests/repair-all-checks.fish
```

`scripts/spectra-plus/tests/generator-checks.fish` 會暫時改寫 `scripts/spectra-plus/rules.yaml` 來測試 failure cases，執行結束會復原。不要把它和 `repair-all-checks.fish` 並行跑，避免測試互相踩到暫時狀態。

## 疑難排解

### `invalid target project directory`

`--register-target` 只接受存在且是目錄的 target。若 project 已刪除，請使用：

```fish
./install-spectra-plus.fish --unregister-target /path/to/deleted-project
```

### 找不到 `yq`

安裝 `yq` 後重跑：

```fish
brew install yq
yq --version
```

### LaunchAgent 無法啟用

Installer 會輸出 manual activation instruction。也可以查看 log：

```fish
cat "$HOME/Library/Logs/spectra-plus-repair.log"
```

### repair-all 顯示 `locked`

代表已有 repair-all 正在執行，或留下 lock。若 lock 已 stale，下一次 repair-all 會嘗試復原；必要時依輸出訊息手動清理：

```fish
rm -rf "$TMPDIR/spectra-plus-repair.lock"
```

### repair-all 顯示 `throttled`

代表上一個 repair attempt 還在 throttle window 內。手動維修可使用：

```fish
./install-spectra-plus.fish --repair-all --force
```

### 來源 commit skill 的 guard 被剝除

若 Spectra.app 把 source repo 自己的 `spectra-commit/SKILL.md`（`.claude` 與 `.agents`）reset 成不含 `SPECTRA-COMMIT-GUARD` 的版本，repair 會**自動從 git HEAD 還原該來源檔**再續行，輸出：

```text
restored .claude/skills/spectra-commit/SKILL.md from HEAD
```

自動還原只在「來源 guard 已失效、檔案位於 git 工作樹、且 HEAD 版本含合法 guard」時發生；只動該單一檔案的 working tree（不碰 index、不影響其他 dirty 檔），`--dry-run` 只印 `+ would restore … from HEAD` 不做變更。

若連 **git HEAD 版本也缺少合法 guard**（或來源不在 git 工作樹），無法自動還原，會回到既有 fail-loud：

```text
錯誤：spectra-commit guard (Claude) source 缺少必要內容：<!-- SPECTRA-COMMIT-GUARD: ... -->
```

此時請先把含 guard 的版本 commit 到 HEAD（或手動 `git restore` 一個含 guard 的版本），再重跑 repair。
