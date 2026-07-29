## Summary

新增一個 machine-local 的全域 shim `~/.local/bin/cash`，讓使用者在任何目錄都能直接輸入 `cash` 操作 Cash CLI：一般指令路由到該專案自己的 `.cash-skills/bin/cash` launcher，新的 `cash init` 子命令則呼叫 source repo 的 `install-cash-skills.fish` 完成 bundle 安裝，必要時先在目標資料夾執行一次 git 初始化。shim 是純便利層，不攜帶 runtime、不具版本、不改變既有信任模型。

## Motivation

目前 Cash CLI 只有 project-local 入口：在已安裝的專案內要輸入 `.cash-skills/bin/cash`，替新專案安裝 bundle 則必須切換到 source repo 執行 installer。相較之下，舊 Spectra 的全域指令可以在任何專案資料夾直接 init 與查看 change／spec，日常操作明顯較順手。討論結論是：值得複製的是 Spectra 的打字體驗，而非其全域 runtime 分發架構——全域 runtime 會繞過 manifest／receipt 的 fail-closed 驗證、犧牲 vendored 專案「clone 即用」的性質，並重新引入已在 Spectra Plus 遷移中刻意移除的版本漂移與修復問題。因此以 thin dispatcher shim 提供全域 UX，信任鏈與更新模型維持不變。

## Proposed Solution

新增三個 source repo 檔案與一段文件：

1. **Shim 腳本源頭**（新檔，POSIX sh）：提交於 source repo，內容只做路由：
   - 非 `init` 指令：以 git 解析目前目錄所屬 worktree 的 top-level，`exec` 該 root 下的 absolute launcher 並原樣傳遞全部引數；不在 git worktree 內或 launcher 不存在／不可執行時 fail closed，stderr 提示執行 `cash init`，不建立任何狀態。
   - `init` 子命令：固定順序為旗標解析 → source repo 定位與驗證（`CASH_SOURCE_ROOT` 環境變數優先，未設定時使用預設路徑）→ 需要時的 git 初始化 → 印出 target → `exec` source repo 的 `install-cash-skills.fish`。目前目錄已在 git worktree 內時以該 top-level 為安裝目標且不執行 git 初始化；位於 git 目錄內部（含 bare repo）而不屬於任何 worktree 時 fail closed 不初始化；其餘情況在前述驗證全部通過後於目前目錄執行一次 git 初始化，以目前目錄為目標。預設帶 `--vendor <root>`；`cash init --target` 改帶 `--target <root>`，並透傳 `--dry-run`／`--force`。`--dry-run` 為純預覽、一律不觸發 git 初始化，於非 worktree 目錄 fail closed。
   - shim 不設定、不覆寫 launcher 或 installer 自行推導的環境（如 `CASH_PROJECT_ROOT`），不寫入任何檔案，無版本概念，無自我更新。
2. **Shim 安裝入口**（新檔 `install-cash-shim.fish`）：從 source repo 將 shim 複製到 `~/.local/bin/cash` 並設為可執行；重複執行為冪等（內容相同時零寫入）。入口以 source-only `scripts/cash-shim/install_shim.py` 執行 filesystem mutation，helper 持有 `HOME`、`.local` 與 `bin` 的 directory FD，以 `st_dev`／`st_ino` 驗證 identity，並用 `dir_fd` 相對操作完成 temp create、atomic replace 與 cleanup，使 parent pathname 被換成 symlink 時不會把寫入導向外部目錄。兩個檔案都不納入 bundle manifest，不影響 `cash-skills.version`。
3. **Contract tests**（新檔）：覆蓋路由、fail-closed、init 的 git 初始化分支、fresh git repo 通過 installer target 前置檢查、冪等重跑等情境。
4. **文件**：`CASH-SKILLS.md` 新增 shim 章節，說明安裝、`cash init` 流程與更新模型（照舊：source repo 更新後明確重跑 installer；shim 本身幾乎永不更新）。

## Non-Goals

- 不做全域 runtime：shim 不攜帶、不執行任何 `cash_cli` Python 模組；artifact 指令一律由專案內已驗證的 launcher 執行。
- 不改動 launcher 與 installer 的信任模型（manifest／receipt 驗證、fail-closed 語意、`APPROVED_LAUNCHER_TRANSITIONS`）。
- 不新增發佈通道：不上 Homebrew／npm，不做 shim 自我更新或背景同步。
- 不提供未安裝專案的全域 read-only fallback：`cash list` 等指令在未安裝專案一律 fail closed 並引導 init。
- 非 `init` 指令不建立 git repo、不寫入任何狀態。
- 不修改十二個 cash skill 的 SKILL.md 內容；skills 內既有的 bootstrap 片段（直接使用 `.cash-skills/bin/cash`）維持不變。

## Alternatives Considered

- **完全比照 Spectra 的全域 runtime**：需拆除或重寫整套 manifest／receipt 信任層、每台機器獨立升版導致 bundle 與各專案 SKILL.md 版本錯位，並重新引入 Spectra Plus 已移除的漂移修復需求。否決。
- **fish function（`~/.config/fish/functions/`）**：最輕量，但只在 fish 互動 shell 有效，Claude Code 等工具 spawn 的子 shell 吃不到。否決，改用 PATH 上的獨立腳本。
- **symlink 到某個專案的 launcher**：launcher 以自身路徑推導 project root，symlink 會把 root 解析到 `~/.local` 下，直接壞掉。否決。
- **在 installer.py 內加 `--install-shim` 模式**：把 machine-local 便利安裝混入 trust-bearing 的 bundle installer，擴大高風險檔案的變更面。否決，改用獨立的小安裝腳本。
- **只以 fish 重複檢查 parent pathname**：檢查與 `mktemp`／`mv` 之間仍存在 parent-swap 視窗，無法把 mutation 綁定同一個已驗證目錄 identity。否決，改由小型 source-only Python helper 使用 held directory FD 與 `dir_fd` 相對操作。

## Capabilities

### New Capabilities

- `cash-global-shim`：全域 shim 的路由契約、fail-closed 行為、`cash init` 生命週期（含 git 初始化 fallback 與 installer 委派）、source repo 定位與驗證、安裝入口的冪等性。

### Modified Capabilities

（無）

## Impact

- Affected specs: `cash-global-shim`（新增）
- Affected code:
  - New:
    - scripts/cash-shim/cash-shim.sh
    - scripts/cash-shim/install_shim.py
    - install-cash-shim.fish
    - scripts/cash-shim/tests/shim-checks.fish
  - Modified:
    - CASH-SKILLS.md
  - Removed:
    - (none)
