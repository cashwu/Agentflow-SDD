## Context

`cash_cli.installer.validate_target_prerequisites` 目前對 target 做兩件事：以 `git rev-parse --show-toplevel` 確認 target 是 Git worktree top-level，然後以 `read_regular(target, "openspec/config.yaml")` 讀取並以 `parse_openspec_config` 驗證。`read_regular` 對缺檔會丟出 `cannot open regular file openspec/config.yaml: [Errno 2] ...`，因此全新 repository 一律在 preflight 失敗。

`validate_target_prerequisites` 共有五個呼叫點：`install_target` 的 preflight 與取得 stable lock 之後各一次、`bootstrap_source`（`--self`）的兩次，以及 `run` 中 `--register` 分支在寫入 registry 前的一次（`main` 只是 `run` 的錯誤包裝）。同一個檔案路徑另外出現在 `installation_inputs` 的 `target_paths`，因此 preflight 與 lock 後各有一次 snapshot 比對。`.cash.yaml` 則已有 `config_plan` 產生「缺檔就用 canonical baseline 建立」的 plan，並由 `InstallTransaction` 發布與回滾。本次變更把 `openspec/config.yaml` 對齊到同一個模式。

## Goals / Non-Goals

Goals：

- target 缺 `openspec/config.yaml` 時，於既有 transaction 內以 `0644` 建立一份 schema-valid 預設檔，安裝其餘 inventory 不受影響。
- 既有檔案的 unsafe shape 與 invalid schema 維持在首次 target write 前 fail closed。
- 既有合法檔案零寫入、逐 byte 保留，重複安裝仍分類為 `current`。
- `--target` 與 `--all` 在 target 缺檔時建立該檔；`--register` 只放寬 preflight，接受缺檔的 target 但不建立該檔。

Non-Goals：

- 不建立 `openspec/specs/`、`openspec/changes/` 或其他 `openspec/` 子目錄。
- 不改變 `--self` 的 source-only 嚴格契約。
- 不把 `openspec/config.yaml` 納入 receipt 或 managed inventory。
- 不新增 installer flag。

## Decisions

**D1：以「缺檔 → bootstrap、既有 → 驗證」取代單一 fail-closed 路徑，並在任何 open 之前先判形狀。**
判序為 unsafe > missing > invalid。`ensure_contained` 對 symlink、`read_regular` 對 hard link 與非 regular file 都會丟 `InstallerError`，但**開啟 FIFO 進行讀取會阻塞到出現 writer 為止**，因此不能只靠 open 路徑判形狀。`ensure_regular_gitignore` 的 docstring 已逐字記錄同一危害並採「先 `lstat` 判形狀、再 open」的作法；本變更把該作法抽成共用 helper，並在 `validate_target_prerequisites` 讀取前先呼叫，使 FIFO 以 execution error 失敗而非阻塞。判序因此為：非 regular file（含 symlink、hard link、目錄、FIFO）先以 execution error 失敗；只有 `lstat` 回報 `FileNotFoundError` 的真正缺檔才進 bootstrap 分支；存在且安全的檔案才進 `parse_openspec_config` 的 schema 驗證。

**D2：baseline 內容以模組常數內嵌，不從 source repository 複製。**
`config_plan` 對 `.cash.yaml` 是從 source 讀取 canonical bytes，因為 `.cash.yaml` 本來就是 bundle 的一部分且已在 `installation_inputs` 的 `source_paths` 內。`openspec/config.yaml` 不是 bundle inventory，從 source 複製會把 source 專案自身的 `context` 與 `rules` 帶進 target，並讓輸出取決於 source 的可變狀態。內嵌常數使輸出對同一 bundle 版本恆定，且不需擴張 source snapshot 集合。

常數的定義是它自身的性質，**不綁定本 repository 的 `openspec/config.yaml`**：後者是 project-owned 且可變，若日後有人在其中加入本專案的 `context: |` 或 `rules:`，「維持逐 byte 相同」就會把本專案的 context 帶進每一個 target——正是本決策要避免的危害。因此常數 MUST 為 LF 結尾的 UTF-8、首行 `schema: spec-driven`、其餘行只有 blank line 與 full-line `#` 註解，其 parse 結果的 `context` 為空字串、`rules` 為空 mapping。plan 階段仍以 `parse_openspec_config` 驗證該常數，避免常數本身失效時把 invalid config 寫進 target。

**D3：plan 從既有的 `installation_inputs` target snapshot 導出，不另外讀檔。**
`target_paths` 已含 `openspec/config.yaml`，preflight 與取得 stable lock 後各解析一次並比對；不一致時既有邏輯會關閉 lock 並重新進入 `install_target`。因此「preflight 時缺檔、lock 前被別的 process 建立」會重新分類為既有檔案，不會覆寫。publication 前的 `final_target_inputs` 比對同樣涵蓋這個路徑。這與 `gitignore_plan` 從 `dict(target_inputs)[GITIGNORE_PATH]` 導出 plan 的既有作法一致。

**D4：publication 位置緊接在 `.cash.yaml` 之後、guidance 之前。**
`.gitignore` 必須維持在 receipt 之前的最後一個位置（既有註解言明此位置固定以保持先前 publication 的 operation index 穩定），因此新 operation 不放在尾端。config 類寫入集中在一起也讓 journal 內容易於閱讀。

**D5：`--self` 維持嚴格，`--register` 只放寬 preflight 而不建立檔案。**
`bootstrap_source` 的兩個 `validate_target_prerequisites` 呼叫沿用預設參數（不允許缺檔），因此 source repository 缺 `openspec/config.yaml` 仍是 execution error。`--self` 不發布 config，此性質不變。`--register` 分支只寫 registry、不開 transaction，因此它必須接受缺檔的 target 以免全新專案無法登錄，但它 MUST NOT 建立該檔；實際建立發生在後續 `--all` batch 安裝。

**D6：只建立檔案，不建立目錄骨架。**
`atomic_write` 會先呼叫 `ensure_directories` 建立 `openspec/`（`0755`）。其餘子目錄由 Cash CLI 於需要時建立：`Workspace.ensure_directory` 建立 `openspec/changes`，而 `Workspace.list_directory` 對不存在的目錄回傳空 list，因此新安裝的 workspace 可直接執行 `list`、`status` 等唯讀指令。

## Implementation Contract

1. `.cash-skills/lib/cash_cli/installer.py` 新增模組常數 `OPENSPEC_CONFIG_PATH = "openspec/config.yaml"`，並以它取代該檔內既有的三處字面值（`installation_inputs` 的 `target_paths`、`validate_target_prerequisites` 內的兩處）。
2. 同檔新增模組常數 `OPENSPEC_CONFIG_BASELINE: bytes`：LF 結尾的 UTF-8，首行 `schema: spec-driven`，其餘行只有 blank line 與說明 `context`、`rules` 用法的 full-line `#` 註解，因此 `parse_openspec_config(OPENSPEC_CONFIG_BASELINE.decode("utf-8"), path=OPENSPEC_CONFIG_PATH)` 的 `context` 為 `""`、`rules` 為 `{}`。該常數 MUST NOT 定義為「與本 repository 的 `openspec/config.yaml` 逐 byte 相同」。
3. 同檔新增 `def ensure_regular_shape(root: Path, relative: str) -> None`：以 `ensure_contained` 解析後 `os.lstat`，`FileNotFoundError` 直接返回，非 `stat.S_ISREG` 以 `InstallerError(f"unsafe regular file identity: {relative}")` fail closed。既有 `ensure_regular_gitignore(target)` 改為委派給 `ensure_regular_shape(target, GITIGNORE_PATH)`，其呼叫點與行為不變。
4. `validate_target_prerequisites` 簽章改為 `def validate_target_prerequisites(target: Path, *, allow_missing_config: bool = False) -> None`。Git top-level 檢查不變；其後先呼叫 `ensure_regular_shape(target, OPENSPEC_CONFIG_PATH)`，再判斷缺檔：`allow_missing_config` 為真且該路徑 `os.lstat` 為 `FileNotFoundError` 時直接 `return`；其餘情況維持既有的 `read_regular` 讀取與 `parse_openspec_config` 驗證，失敗訊息維持 `invalid target openspec/config.yaml: {error}`。不引入回傳值，因為所有呼叫點的 plan 一律由 `installation_inputs` 的 snapshot 導出。
5. 同檔新增 `def openspec_config_plan(snapshot: Snapshot) -> bytes | None`：`snapshot.exists` 為真時回傳 `None`；否則先以 `parse_openspec_config` 驗證 `OPENSPEC_CONFIG_BASELINE`，驗證失敗以 `InstallerError` fail closed，通過則回傳該常數。
6. 三個 target-facing 呼叫點改為允許缺檔：`install_target` 的 preflight 與取得 stable lock 之後的兩個 `validate_target_prerequisites(target)`，以及 `run` 中 `--register` 分支的 `validate_target_prerequisites(Path(project))`，全部改為傳入 `allow_missing_config=True`。`--register` 分支 MUST NOT 因此建立該檔。
7. `install_target` 的 transaction 建構階段，在 `.cash.yaml` 的 `transaction.add` 之後、guidance 迴圈之前，以 `openspec_config_plan(dict(target_inputs)[OPENSPEC_CONFIG_PATH])` 取得 plan；非 `None` 時執行 `transaction.add(OPENSPEC_CONFIG_PATH, planned, 0o644)`。`.gitignore` 維持在 receipt 之前的最後一個 operation。`install_target` 開頭的 `ensure_contained` 清單不需加入該路徑：line 1328 的 `validate_target_prerequisites` 已先經過同一檢查。
8. `bootstrap_source` 的兩個 `validate_target_prerequisites(source)` 呼叫不加參數，維持缺檔即 execution error。
9. `cash-skills.version` MUST 以相對方式提升：實作時讀取工作區的 `cash-skills.version` 與 `git show HEAD:cash-skills.version`，寫入嚴格大於兩者的下一個版本，維持單行 LF 結尾。MUST NOT 寫死常數——同一 workspace 的 sibling change `rightsize-cash-skills` 與 `support-multi-file-skill-payload` 也宣告要提升該檔，寫死值會在 sibling 先落地時使 `test_bundle_version_history.py` 的 `check_history` 失敗。撰寫本文件時兩者皆為 `2.5.0`，故當下的正確值為 `2.6.0`，但執行時 MUST 重新讀取而非沿用此示例。之後在 project root 執行 `./install-cash-skills.fish --self` 重建 receipt。
10. `scripts/cash-skills/tests/test_installer_runtime.py` 新增涵蓋以下情形的 case：無 `openspec/` 的全新 Git target 安裝成功且產生逐 byte 等於 `OPENSPEC_CONFIG_BASELINE` 的 `0644` config、安裝後 `openspec/` 的 entries 恰為 `{config.yaml}` 且 receipt 不含該路徑、重複安裝回報 `current` 且該檔零寫入、既有合法 config 逐 byte 保留、`openspec/config.yaml` 為 symlink／hard link／FIFO 時 fail closed 且不阻塞、既有 invalid config fail closed 且 `--force` 不繞過、缺檔時 `--dry-run` 零寫入且不建立該檔、缺檔的 target 可被 `--register` 登錄且該檔仍不存在、缺檔 target 在 config 之後的 publication 失敗時該檔被回滾、source 缺該檔時 `--self` 仍 fail closed。
11. `CASH-SKILLS.md` 的「Bundle 版本與單一 installer 入口」段落補一段說明：target 缺 `openspec/config.yaml` 時 installer 會在同一 transaction 內建立預設檔，既有檔案則保留，unsafe 或 invalid 仍 fail closed。

## Risks / Trade-offs

- **回滾殘留空目錄**：transaction failure 會 unlink 新建的 `openspec/config.yaml`，但 `atomic_write` 為它建立的 `openspec/` 目錄不會被移除。這與既有 managed 路徑（例如 `.cash-skills/`）的行為一致，且空目錄不影響後續分類與重試。
- **預設內容與其他工具的預期差異**：內嵌 baseline 只保證 `cash_cli.config.parse_openspec_config` 可解析。若使用者另有 openspec 工具鏈且其預設檔不同，使用者需自行調整；因為安裝後該檔即為 project-owned，installer 後續不再覆寫。
- **放寬 preflight 的邊界**：本變更只放寬「缺檔」一種情形。unsafe shape 與 invalid schema 的 fail-closed 行為、Git top-level 要求、`--force` 不繞過的性質皆不變，因此不擴大 installer 對 target 的寫入權限範圍，只多寫一個原本就必須存在的 project-owned 檔案。
- **刻意刪除的 config 會被還原**：已安裝的 target 若使用者刻意刪除 `openspec/config.yaml`（例如不再使用 openspec 工具鏈），下一次相同版本安裝會由 `update` 分支重新建立，而非回報 `current`。這是「缺檔即建立」的必然結果，也已寫入 delta spec 的優先序條款；不提供選擇退出，因為 Cash CLI 的 `Workspace.discover` 本來就要求該檔存在，缺檔的 workspace 無法執行任何 Cash 指令。
- **舊版 installer 遇到新版的半完成安裝**：帶本變更的 installer 在 bare target 發布到一半崩潰後，若使用者改以本變更之前的 installer 執行，recovery 會 unlink 新建的 config，接著重新分類時撞回舊版的嚴格 preflight，得到 `cannot open regular file openspec/config.yaml` 而沒有指引。target state 仍是一致的（journal 已清除、rollback 完成），屬 fail closed；解法是改用相同或更新的 installer，此性質與既有的 journal 跨版本規則一致，本變更不另外處理。
