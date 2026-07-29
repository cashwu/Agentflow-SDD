## ADDED Requirements

### Requirement: 全域 shim 的指令路由

全域 shim（安裝於 `$HOME/.local/bin/cash` 的 POSIX sh 腳本）SHALL 以互斥且窮盡的兩分支路由指令：第一個引數逐字等於 `init` 時走 init 分支；其餘一切情況（含零引數）走 dispatch 分支。dispatch 分支 SHALL 以 git 解析目前目錄所屬 worktree 的 top-level，並以 `exec` 執行該 root 下的 `.cash-skills/bin/cash`，引數逐字透傳，不解讀、不改寫、不追加。shim MUST NOT 以 symlink 形式指向任何 launcher，MUST NOT export 任何 shim internal value 給被 exec 的程序，MUST NOT 改寫 caller 的一般環境變數，且非 init 分支 MUST NOT 寫入任何檔案或建立任何狀態。

#### Scenario: 已安裝專案內的指令透傳

- **GIVEN** 目前目錄位於一個含 `.cash-skills/bin/cash`（可執行）的 git worktree 內
- **WHEN** 使用者在任意子目錄執行 `cash list --json`
- **THEN** shim 以 `exec` 執行該 worktree top-level 下的 `.cash-skills/bin/cash`，引數 `list --json` 逐字傳遞
- **AND** 輸出與 exit code 完全由 launcher 決定，shim 不附加任何輸出

#### Scenario: 零引數透傳

- **WHEN** 使用者在已安裝專案內執行不帶任何引數的 `cash`
- **THEN** shim 走 dispatch 分支，以零引數 `exec` 專案 launcher

##### Example: 引數逐字透傳

- 在 `~/proj/src/` 內執行 `cash search "portable manifest" --limit 10 --json`
- shim 執行 `exec ~/proj/.cash-skills/bin/cash search "portable manifest" --limit 10 --json`
- 含空白的引數維持單一引數，不被重新切分

#### Scenario: hostile inherited environment 不洩漏 internal values

- **GIVEN** caller 預先 export 與 shim 一般變數名及 `_cash_shim_` reserved internal names 同名的環境變數
- **WHEN** shim dispatch 或 init 後 `exec` stub launcher／installer
- **THEN** caller 的一般環境變數值維持不變
- **AND** 被 exec 程序的環境 MUST NOT 含 shim 寫入的 reserved internal values

### Requirement: dispatch 分支的 fail-closed 行為

dispatch 分支在目前目錄不屬於任何 git worktree，或解析出的 top-level 下 `.cash-skills/bin/cash` 缺失或不可執行時，SHALL fail closed：以 `cash-shim:` 開頭的單行錯誤寫入 stderr、內文包含 `cash init` 提示、exit code 為 `1`，且零檔案寫入。shim MUST NOT 在 dispatch 分支建立 git repo、MUST NOT 提供任何未經專案 launcher 驗證的 read-only fallback。

#### Scenario: 非 git 目錄執行一般指令

- **WHEN** 使用者在不屬於任何 git worktree 的目錄執行 `cash list`
- **THEN** shim 以 exit `1` 結束，stderr 為 `cash-shim:` 開頭的單行錯誤且內文含 `cash init`
- **AND** 該目錄不產生任何新檔案或 git repo

#### Scenario: git worktree 內但未安裝 cash

- **WHEN** 使用者在一個沒有 `.cash-skills/bin/cash` 的 git worktree 內執行 `cash status`
- **THEN** shim 以 exit `1` 結束並在 stderr 提示執行 `cash init`
- **AND** 不讀取、不解析該專案的 `openspec/` 內容

### Requirement: cash init 的 target 解析與 git 初始化

init 分支 SHALL 依下列互斥規則解析安裝 target：目前目錄已屬於某 git worktree（含子目錄）時，target 為該 worktree top-level 且 MUST NOT 執行 git 初始化；目前目錄不屬於任何 git worktree 時，SHALL 先在目前目錄執行一次無額外選項的 git 初始化，target 為目前目錄。操作順序 SHALL 固定為：旗標解析 → source-layout 驗證 → git 初始化（僅在需要時）→ 印出 target → 呼叫 installer；旗標解析或 source-layout 驗證失敗時 MUST 在 git 初始化發生前 fail closed。目前目錄位於 git 目錄內部（`git rev-parse --is-inside-git-dir` 為 true，含 bare repo）而不屬於任何 worktree 時，MUST fail closed 且 MUST NOT 執行 git 初始化。`--dry-run` SHALL 為純預覽且一律不觸發 git 初始化：目錄已是 worktree 時照常透傳 installer；非 worktree 目錄時 MUST fail closed 且零寫入。git 初始化失敗時 SHALL 中止且不呼叫 installer。init 分支在呼叫 installer 前 SHALL 於 stdout 印出解析後的 target 絕對路徑。git 初始化 MUST 僅發生於 init 分支。

#### Scenario: 全新資料夾一鍵初始化

- **GIVEN** 一個不屬於任何 git worktree 的空資料夾
- **WHEN** 使用者在該資料夾執行 `cash init`
- **THEN** shim 先在該資料夾完成 git 初始化，再以該資料夾為 target 呼叫 installer
- **AND** stdout 含該資料夾的絕對路徑

#### Scenario: 在既有 repo 子目錄執行 init

- **GIVEN** 目前目錄是某 git worktree 的子目錄
- **WHEN** 使用者執行 `cash init`
- **THEN** target 為該 worktree 的 top-level，而非目前子目錄
- **AND** 不執行任何 git 初始化

#### Scenario: git 目錄內部或 bare repo 內執行 init

- **GIVEN** 目前目錄位於 bare repo 或一般 repo 的 `.git/` 內部（`git rev-parse --is-inside-git-dir` 為 true 且不屬於任何 worktree）
- **WHEN** 使用者執行 `cash init`
- **THEN** shim 以 exit `1` 結束並在 stderr 說明目前位置為 git 目錄內部
- **AND** 不執行任何 git 初始化，不呼叫 installer

#### Scenario: dry-run 於非 worktree 目錄不建立 repo

- **GIVEN** 一個不屬於任何 git worktree 的資料夾
- **WHEN** 使用者執行 `cash init --dry-run`
- **THEN** shim 以 exit `1` 結束並在 stderr 說明 dry-run 預覽需要既有 git worktree
- **AND** 該資料夾零寫入，不產生 `.git/`

### Requirement: cash init 的 installer 委派與旗標映射

init 分支完成 source 驗證後 SHALL 以 `exec` 執行 source repo 的 `install-cash-skills.fish`，模式映射固定為：預設 `--vendor <target>`；帶 `--target` 旗標時改為 `--target <target>`；`--dry-run` 與 `--force` 逐字透傳。`cash init` 接受的旗標集合 SHALL 僅限 `--target`、`--dry-run`、`--force`；出現其他旗標或多餘位置引數時 MUST fail closed（exit `1`、不呼叫 installer）。對已安裝專案重跑 `cash init` 的結果語意 SHALL 完全由 installer 決定（`current`、`update`、`conflict`），shim MUST NOT 攔截或改寫。

#### Scenario: 預設 vendor 模式

- **WHEN** 使用者執行 `cash init`
- **THEN** shim 執行 source repo 的 `install-cash-skills.fish --vendor <target>`

#### Scenario: 未知旗標 fail closed

- **WHEN** 使用者在不屬於任何 git worktree 的資料夾執行 `cash init --register`
- **THEN** shim 以 exit `1` 結束且不呼叫 installer
- **AND** 不執行任何 git 初始化

#### Scenario: 已安裝專案重跑 init

- **GIVEN** target 專案已含相同版本的 valid manifest 與一致內容
- **WHEN** 使用者重跑 `cash init`
- **THEN** installer 回報 `Result: current`，shim 不改寫該結果

##### Example: 旗標映射

- `cash init` → `install-cash-skills.fish --vendor /abs/target`
- `cash init --target` → `install-cash-skills.fish --target /abs/target`
- `cash init --dry-run` → `install-cash-skills.fish --vendor /abs/target --dry-run`
- `cash init --target --force` → `install-cash-skills.fish --target /abs/target --force`

### Requirement: source repo 定位與驗證

init 分支 SHALL 以 `CASH_SOURCE_ROOT` 環境變數定位 source repo，未設定時使用預設路徑 `$HOME/Github/Agentflow-SDD`。呼叫 installer 前 SHALL 驗證兩個 source-layout 標記：`install-cash-skills.fish` 存在且可執行、`cash-skills.version` 存在且為 regular file；任一標記缺失時 MUST fail closed，且錯誤訊息 SHALL 包含 `CASH_SOURCE_ROOT` 字樣以引導修正。shim MUST NOT 在自身重建 installer 的完整 source layout 與信任驗證；更深層驗證由 installer 既有 fail-closed 邏輯把關。`CASH_SOURCE_ROOT` SHALL 只被讀取，MUST NOT 被 shim export。

#### Scenario: 環境變數優先於預設路徑

- **GIVEN** `CASH_SOURCE_ROOT` 指向一個含兩個 source-layout 標記的目錄
- **WHEN** 使用者執行 `cash init`
- **THEN** shim 使用該目錄的 `install-cash-skills.fish`，忽略預設路徑

#### Scenario: source 驗證失敗

- **WHEN** `CASH_SOURCE_ROOT` 指向缺少 `cash-skills.version` 的目錄且使用者於不屬於任何 git worktree 的資料夾執行 `cash init`
- **THEN** shim 以 exit `1` 結束、不呼叫 installer，stderr 錯誤訊息含 `CASH_SOURCE_ROOT`
- **AND** 不執行任何 git 初始化

### Requirement: shim 安裝入口的冪等安裝

source repo SHALL 提供 `install-cash-shim.fish` 作為 shim 的唯一安裝入口：將 committed shim 腳本安裝到 `$HOME/.local/bin/cash` 並設 mode `0755`，`$HOME/.local/bin` 缺失時建立。入口的 shebang SHALL 將 `XDG_CONFIG_HOME`、`XDG_DATA_HOME`、`XDG_CACHE_HOME` 設為 `/dev/null` 並以 `fish --no-config` 啟動，MUST NOT 因 fish 啟動而在 caller `HOME` 建立設定、資料或快取目錄。入口 SHALL 選擇 Python 3.11+ 並委派 source-only helper；Python 3.11+ 不可用時 MUST 在首次 filesystem write 前 fail closed。helper MUST 將 `HOME` 驗證為 absolute canonical non-root directory，並以 no-follow held directory FD 與 `(st_dev, st_ino)` identity 綁定 `HOME`、`.local` 與 `bin`；初始 no-follow `lstat(HOME)` 與 opened HOME FD 的 identity MUST 相同，inspect／open 間 supplied `HOME` leaf 被換成外部 symlink 時 MUST fail closed且外部零寫入。建立 child directory、temp create、destination read／shape check、mode 設定、atomic replace 與 cleanup MUST 使用相對 held FD 的操作，不得在驗證後重新沿 caller-controlled parent pathname 導航。每次 mutation 前 MUST 由 held parent FD 重驗 child name 仍對應同一 identity；parent pathname 被換成 symlink 時 MUST fail closed，且外部 symlink target 零寫入。重複執行 SHALL 冪等：目的地已存在、為 regular file、內容逐 byte 相同且 mode 一致時回報 `current` 且零寫入；否則以位於同一 held `bin` directory identity 的 exclusively-created temp file 加 atomic rename 寫入後回報 `installed`，並在結束前以同一 held FD 清除 owned temp file。目的地存在但非 regular file（symlink、目錄、FIFO 等）時 MUST fail closed。安裝入口的寫入範圍 MUST 限定於驗證後持有的 `$HOME/.local/bin/` directory identity 之內（含透過 held parent FD 建立該目錄與其必要父目錄，如 `$HOME/.local`），MUST NOT 寫入其外任何路徑。兩個 informational 警告 SHALL 皆不改變 exit code：resolved `$HOME/.local/bin` 不在 `PATH` 時；安裝成功後 `command -v cash` 解析結果非 resolved `$HOME/.local/bin/cash`（被 PATH 上其他同名指令遮蔽）時。

#### Scenario: 首次安裝

- **WHEN** `$HOME/.local/bin/cash` 不存在且使用者於 source repo 執行 `./install-cash-shim.fish`
- **THEN** shim 以 mode `0755` 被安裝到 `$HOME/.local/bin/cash` 並回報 `installed`

#### Scenario: 重複執行零寫入

- **GIVEN** 已安裝且內容與 mode 與 source 一致
- **WHEN** 再次執行 `./install-cash-shim.fish`
- **THEN** 回報 `current` 且目的地檔案的內容、mode 與 mtime 皆不變

#### Scenario: 目的地為 symlink 時 fail closed

- **WHEN** `$HOME/.local/bin/cash` 是一個 symlink 且使用者執行 `./install-cash-shim.fish`
- **THEN** 安裝入口以非零 exit code 結束且不修改任何檔案

#### Scenario: parent swap 不逃出 verified directory identity

- **GIVEN** helper 已在 held `bin` directory FD 內 exclusively create owned temp file
- **WHEN** publication 前 `$HOME/.local/bin` pathname 被換成指向外部目錄的 symlink
- **THEN** identity revalidation 失敗，安裝入口以非零 exit code 結束
- **AND** 外部目錄的 sentinel 與 `cash` destination 零變更
- **AND** owned temp file 只透過原 held `bin` FD 清除

#### Scenario: HOME leaf swap 在首次寫入前 fail closed

- **GIVEN** helper 已取得 supplied `HOME` 的初始 no-follow `lstat` identity
- **WHEN** held HOME FD open 前該 leaf 被換成指向外部目錄的 symlink
- **THEN** opened FD 與初始 identity 不一致，安裝入口以非零 exit code 結束
- **AND** 外部目錄的 sentinel 與 `cash` destination 零變更
- **AND** 被移開的原 supplied `HOME` 零變更

### Requirement: shim 與 bundle inventory 的邊界

shim 腳本與其安裝入口 MUST NOT 進入 portable manifest 或 receipt 的 managed inventory，MUST NOT 觸發 `cash-skills.version` 調升，且本 capability MUST NOT 變更任何 canonical `SKILL.md` 內容。shim SHALL 無版本概念、無自我更新、無背景同步；其更新途徑為 source repo 更新後由使用者明確重跑 `install-cash-shim.fish`。

#### Scenario: manifest inventory 不含 shim

- **WHEN** 檢視 source repo 的 `.cash-skills/manifest.tsv`
- **THEN** 其 inventory 不含 scripts/cash-shim/ 下任何路徑，也不含 `install-cash-shim.fish`

#### Scenario: 刪除 shim 不影響既有專案

- **GIVEN** 任一已安裝 cash bundle 的專案
- **WHEN** 使用者刪除 `$HOME/.local/bin/cash`
- **THEN** 該專案的 `.cash-skills/bin/cash` 與全部 cash skills 行為不受任何影響
