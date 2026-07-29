## Context

Cash CLI 的信任模型是 project-local：`.cash-skills/bin/cash` launcher 由 committed portable manifest（Git provenance）或 machine-local receipt（inode 綁定）fail-closed 驗證，bundle 更新只經由明確重跑 `install-cash-skills.fish` 傳播。本 change 在此模型之外加一層 machine-local 便利層：PATH 上的全域 shim，提供「任何目錄直接輸入 `cash`」與「一個指令完成新專案安裝」的體驗，同時保證刪除 shim 後一切照舊（deletion test：shim 非 trust-bearing）。

launcher 以 `os.path.abspath(__file__)` 推導 project root（`.cash-skills/bin/cash` 第 582-583 行），因此 shim 不能是 symlink，必須以 `exec` 呼叫 absolute launcher path。installer 的 `validate_target_prerequisites`（`.cash-skills/lib/cash_cli/installer.py` 第 751-777 行）要求 target 是 Git worktree top-level 且路徑 resolve 後相等，並驗證 target 的 `openspec/config.yaml`：檔案存在時必須是 regular file 且內容為合法 config；檔案缺失時，vendor／target 呼叫端以 `allow_missing_config=True` 呼叫而放行。因此零 commit 且無 `openspec/config.yaml` 的 fresh repo 可通過 preflight。

## Goals / Non-Goals

**Goals**

- 全域 `cash <指令>`：路由到目前專案的已驗證 launcher，引數逐字透傳。
- `cash init`：在專案資料夾一個指令完成 bundle 安裝；目錄尚非 git worktree 時先執行一次 git 初始化。
- 未安裝／非 git 情境 fail closed，並給出可執行的下一步提示。
- shim 安裝入口冪等，重複執行零副作用。

**Non-Goals**

- 不做全域 runtime、不上套件庫、不做自我更新或背景行為。
- 不改動 launcher／installer 的信任驗證與 `cash-skills.version` 語意。
- 不提供未安裝專案的 read-only fallback。
- 非 `init` 指令不寫入任何狀態。

## Decisions

1. **Shim 為 POSIX sh 腳本**（`#!/bin/sh`，無 bash／fish 專屬語法），提交於 scripts/cash-shim/cash-shim.sh，安裝目的地固定為 `$HOME/.local/bin/cash`。理由：任何 shell 與工具 spawn 的子程序都吃得到；fish function 只在 fish 互動環境有效。
2. **路由分割互斥且窮盡**：第一個引數逐字等於 `init` 時走 init 分支；其他一切情況（含零引數）走 dispatch 分支。cash CLI 現有 command families（`new`、`list`、`status`、`sync` 等，見 `.cash-skills/bin/cash` 的 `MUTATING_FAMILIES` 與 `cash_cli/main.py`）不含 `init`，無遮蔽衝突；若未來 launcher 新增 `init` family，shim 攔截優先是已記錄的取捨。
3. **Dispatch 分支**：以 git 解析 worktree top-level；成功則 `exec "$root/.cash-skills/bin/cash" "$@"`（process replacement，引數與 exit code 語意完全由 launcher 接管）。解析失敗或 launcher 缺失／不可執行時 fail closed：stderr 輸出以 `cash-shim:` 開頭的單行錯誤並明確提及 `cash init`，exit `1`。shim 錯誤走 plain stderr，不模仿 launcher 的 `--json` 錯誤格式——shim 錯誤是 bootstrap 層的人類可讀錯誤。
4. **Init 分支的 target 解析與操作順序**：已在 git worktree 內（含子目錄）→ target 為該 top-level，不執行 git 初始化；否則在目前目錄執行一次無額外選項的 git 初始化，target 為目前目錄。操作順序固定為：旗標解析 → source-layout 驗證 → git 初始化（僅在需要時）→ 印出 target → exec installer；旗標或 source 驗證失敗時 MUST 在 git 初始化發生前 fail closed，避免在使用者目錄留下殘留 `.git/`。git 初始化前先以 `git rev-parse --is-inside-git-dir` 防護：目前目錄位於 git 目錄內部（含 bare repo）但不屬於任何 worktree 時 fail closed 說明原因，不執行 git 初始化。`--dry-run` 為純預覽：一律不執行 git 初始化——目錄已是 worktree 時照常透傳 installer `--dry-run`；非 worktree 目錄時 fail closed，說明 dry-run 預覽需要既有 git worktree（或改為不帶 `--dry-run` 執行）。git 初始化失敗即中止，不呼叫 installer。init 執行 installer 前在 stdout 印出解析後的 target 絕對路徑。
5. **Source repo 定位與驗證**：取 `CASH_SOURCE_ROOT` 環境變數，未設定時預設 `$HOME/Github/Agentflow-SDD`。驗證兩個 source-layout 標記：`install-cash-skills.fish` 存在且可執行、`cash-skills.version` 存在為 regular file。驗證失敗 fail closed 並提示設定 `CASH_SOURCE_ROOT`。shim 不重複 installer 的完整 source layout 驗證（`is_source_layout`），deeper 驗證與「target 不得為 source repo」由 installer 既有 fail-closed 邏輯把關。
6. **Init 旗標映射**：`cash init [--target] [--dry-run] [--force]`。預設執行 `install-cash-skills.fish --vendor <target>`；帶 `--target` 時改為 `--target <target>`；`--dry-run`／`--force` 逐字透傳。任何其他旗標或多餘位置引數 fail closed——不開放透傳任意 installer 旗標（如 `--register`、`--all`、`--self`），避免 shim 成為 installer 全表面的第二入口。
7. **Shim 安裝入口與 verified directory identity**：`install-cash-shim.fish` 置於 source repo root，維持唯一的人類呼叫入口；入口的 shebang 將 `XDG_CONFIG_HOME`、`XDG_DATA_HOME`、`XDG_CACHE_HOME` 設為 `/dev/null` 並以 `fish --no-config` 啟動，避免 fish 啟動期在 caller `HOME` 建立設定、資料或快取目錄。入口負責 realpath 自我定位、選擇 Python 3.11+，再以 safe-path mode `exec` source-only `scripts/cash-shim/install_shim.py`。helper 將 `HOME` resolve 為 absolute canonical directory 並拒絕 `/`、symlink 或 non-directory；開啟 held `HOME` FD 後 MUST 比較初始 no-follow `lstat` 與 `fstat` 的 `(st_dev, st_ino)`，identity 不一致時 fail closed，避免 `HOME` leaf 在 inspect／open 間被替換成外部 symlink。接著依序以 `O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC` 持有 `HOME`、`.local`、`bin` 的 directory FD；缺少的 `.local`／`bin` 只透過已持有 parent FD 的 `mkdir(..., dir_fd=...)` 建立。每個 held directory identity 定義為其 `fstat` 的 `(st_dev, st_ino)`；每次 mutation 前都由已持有 parent FD 以 `stat(..., follow_symlinks=False, dir_fd=...)` 重驗 child name 仍指向同一 identity。temp create、destination shape/read、`chmod 0755`、atomic `replace` 與 cleanup 全部相對同一個 held `bin` FD 執行，不重新沿 `$HOME/.local/bin` pathname 導航；cleanup 只在 `O_CREAT|O_EXCL` 成功取得 temp ownership 後 armed。parent pathname 被換成 symlink時，identity revalidation fail closed，而已持有 FD 保證 cleanup 不會跟隨替代 symlink。目的地已存在且為 regular file、內容逐 byte 相同且 mode `0755` 時回報 `current` 零寫入；否則回報 `installed`；目的地存在但非 regular file時 fail closed。兩個 informational 警告維持不影響 exit code：resolved install dir 不在 `PATH`；`command -v cash` 解析非 resolved destination。
8. **環境隔離**：shim 不設定、不覆寫 launcher／installer 使用的環境變數（`CASH_PROJECT_ROOT`、`CASH_LOCK_FD`、`PYTHONPATH` 均由被 exec 程序自行管理）；`CASH_SOURCE_ROOT` 只讀取、不 export。POSIX sh 對 inherited exported variable 重新賦值會保留 export attribute，因此所有 shim internal variables MUST 使用 `_cash_shim_` reserved prefix，並在第一次賦值前以 `unset` 清除同名 inherited export attribute；一般 caller variables（如 `root`、`target`、`launcher`）不得被 shim 改寫，reserved internal values 也不得出現在 exec 後環境。
9. **版本與 inventory**：shim 與其安裝入口不進 bundle manifest、不進 receipt、不觸發 `cash-skills.version` 調升；canonical SKILL.md 內容零變更。shim 更新途徑＝source repo git pull 後重跑 install-cash-shim.fish，明確執行、無背景機制。
10. **測試載體**：新增 scripts/cash-shim/tests/shim-checks.fish，沿用既有 fish 測試套件風格（暫存目錄 fixture、逐案例斷言、非零 exit 即失敗），不修改既有 protected 測試檔。

## Implementation Contract

- C1 路由互斥：`argv[1] == "init"` 走 init 分支；其餘（含零引數）走 dispatch 分支；兩分支無重疊、無第三分支。
- C2 dispatch 透傳：成功路徑必為 `exec` absolute launcher，引數逐字傳遞，shim 不解讀、不改寫、不追加任何引數。
- C3 dispatch fail-closed：非 git worktree、launcher 缺失或不可執行 → stderr 單行 `cash-shim:` 錯誤（內文含 `cash init` 提示）、exit `1`、零檔案寫入。
- C4 init 的 git 初始化只在「目前目錄不屬於任何 git worktree」且旗標解析與 source-layout 驗證都已通過、且未帶 `--dry-run` 時發生，且只發生在目前目錄；已在 worktree 內時 target 為 top-level 且不執行 git 初始化；目前目錄位於 git 目錄內部（`git rev-parse --is-inside-git-dir` 為 true，含 bare repo）而不屬於任何 worktree 時 fail closed，不執行 git 初始化。
- C5 init 委派：source 驗證通過後 `exec` source repo 的 `install-cash-skills.fish`，模式映射固定為 `--vendor <target>`（預設）或 `--target <target>`；`--dry-run`／`--force` 透傳；未知旗標 fail closed，exit `1`，不呼叫 installer。`--dry-run` 一律不觸發 git 初始化：非 worktree 目錄帶 `--dry-run` 時 fail closed 且零寫入。
- C6 source 定位：`CASH_SOURCE_ROOT` 優先於預設路徑；兩個 source-layout 標記缺一即 fail closed，錯誤訊息含 `CASH_SOURCE_ROOT` 字樣。
- C7 init 冪等性委派：對已安裝專案重跑 `cash init` 的結果語意（`current`／`update`／`conflict`）完全由 installer 決定，shim 不攔截、不改寫。
- C8 shim 安裝冪等與邊界：install-cash-shim.fish 透過 shebang XDG suppression 避免 fish 啟動期寫入 `$HOME/.config`、`$HOME/.local/share` 或 `$HOME/.cache`；重複執行時，內容與 mode 已一致即回報 `current` 且零寫入；寫入路徑為 atomic rename；非 regular file 目的地 fail closed。
- C9 零環境污染：shim internal variables 使用 `_cash_shim_` reserved prefix，第一次賦值前清除同名 inherited export attribute；exec 後環境不得包含 shim 寫入的 internal values，且 caller 的一般同名變數不得被 shim 改寫。
- C10 contract tests 至少覆蓋：dispatch 成功透傳（引數含空白與 `--json`）、零引數透傳、非 git fail-closed、launcher 缺失 fail-closed、init 在 fresh 目錄的 git 初始化＋installer 呼叫參數、init 在 worktree 子目錄解析到 top-level、init 未知旗標拒絕（且斷言未產生 `.git/`）、source 驗證失敗（且斷言未產生 `.git/`）、init 於 git 目錄內部／bare repo fail-closed、`--dry-run` 於非 worktree 目錄 fail-closed 且零寫入、fresh `git init` fixture 直接呼叫真實 `cash_cli.installer.validate_target_prerequisites`（`PYTHONPATH=.cash-skills/lib`、`allow_missing_config=True`）斷言不 raise、shim 刪除後 fixture 專案 launcher 行為不變（deletion test）、install-cash-shim.fish 冪等三態（installed／current／fail-closed）。shim 路由測試以 stub installer／launcher fixture 驗證呼叫參數，不對真實 target 執行完整 vendor publication；install-cash-shim.fish 的測試案例 MUST 以覆寫 `HOME` 指向暫存 fixture 執行，並斷言真實 `$HOME/.local/bin/cash` 全程未被觸及。
- C11 filesystem identity：shim installer 的所有 filesystem mutation MUST 綁定 Design Decision 7 定義的 held directory FD 與 `(st_dev, st_ino)` identity；HOME leaf-swap fixture MUST 在初始 `lstat(HOME)` 後、held FD open 前把 supplied `HOME` 換成外部 symlink，並證明 pre-open／post-open identity mismatch fail closed且外部零寫入；parent-swap fixture MUST 在 temp create 後、publish 前把 `bin` pathname 換成外部 symlink，並證明 helper fail closed、外部 sentinel／destination 零變更、owned temp 經 held FD 清除。
- C12 Example 與 deletion verification：`shim-checks.fish` MUST 逐列執行 spec 的兩個 `##### Example:` blocks 並斷言完整 argv；deletion test 在真實 `$HOME/.local/bin/cash` 存在時可暫移並還原，不存在時 MUST 使用隔離 `HOME` fixture 安裝、暫移、direct-launcher 驗證與還原，兩條路徑驗證相同 deletion property 且不得改動真實 HOME。

## Risks / Trade-offs

- **未來 `init` family 遮蔽**：若 launcher 日後新增 `init` 指令，shim 會攔截。取捨已記錄；屆時需同步修訂 shim 路由或改名子命令。
- **`CASH_SOURCE_ROOT` 可指向被遮蔽／竄改的 source checkout**（對應 signal `canonical-installer-source-shadowable`）：shim 只驗 layout 標記，不驗內容真偽。邊界與手動執行 installer 相同——控制環境變數與 source checkout 的人本來就控制安裝內容；不在 shim 層重建信任驗證。
- **在錯誤目錄執行 `cash init` 會建立非預期 git repo**：無確認提示是刻意的 UX 取捨（對齊 Spectra 體驗）；緩解為 init 前印出 target 絕對路徑，且 git 初始化本身可逆（移除 `.git/` 即還原）。
- **預設 source 路徑寫死 `$HOME/Github/Agentflow-SDD`**：換機器或搬移 checkout 需設 `CASH_SOURCE_ROOT`；已在文件與錯誤訊息中引導。
- **零 commit fresh repo 的 installer 相容性**：已查證 `validate_target_prerequisites`（751-777 行）要求 worktree top-level，`openspec/config.yaml` 缺失時由呼叫端 `allow_missing_config=True` 放行；contract test 以 fresh `git init` fixture 直接呼叫真實函式斷言不 raise——不以測試側重新實作等價邏輯，未來 installer 收緊時測試即變紅，不會靜默破壞 init 流程。
- **Submodule 視為獨立專案**：在 submodule 內 dispatch 解析到 submodule 自己的 top-level；未安裝時的 `cash init` 會把 bundle vendor 進 submodule。此為 git 語意的自然結果，於 CASH-SKILLS.md shim 章節明文記載，不在 shim 內特判。
- **平台範圍**：shim 為 POSIX sh、launcher 依賴 `fcntl`，維持現有 macOS／Linux 範圍，Windows 原生不支援（非新增限制）。
