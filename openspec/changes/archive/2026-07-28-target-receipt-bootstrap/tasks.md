## 1. 版本前置

- [x] 1.1 將 `cash-skills.version` 由 2.7.0 遞增為 2.8.0；此 task MUST 先於 `.cash-skills/lib/cash_cli/installer.py` 的任何修改完成（該檔屬 `scripts/cash-skills/tests/test_bundle_version_history.py` 的 replaceable 守衛集合）

## 2. --init-receipt 實作

- [x] 2.1 修改 `.cash-skills/lib/cash_cli/installer.py`：新增模組常數 `BUNDLE_VERSION = "2.8.0"`；argparse 新增與既有 modes 互斥的 `--init-receipt`；依 design D3 十步流程實作——Python 3.11+ 檢查、worktree top-level 驗證、source layout 拒絕（不以 mode 相等為條件，診斷含 `./install-cash-skills.fish --self`）、`openspec/config.yaml` 驗證、`.cash-workspace.lock` 存在與非空檢查加 exclusive flock、managed inventory 的 no-follow lstat 形狀檢核與 mode 正規化 chmod、inventory 完整性檢核、現地 digests 與本機 no-follow `lstat` 組 receipt（`version` 取 `BUNDLE_VERSION`、record 集合不變）、same-directory temporary 加 atomic rename 簽發、`current` 零寫入；具名 error codes（`init_python_version`、`init_outside_worktree`、`init_source_repo`、`init_config_invalid`、`init_inventory_invalid`、`init_write_failed`）以統一 JSON shape 輸出 stdout 並 exit 1，成功單行 `initialized`／`current` 輸出 stdout 並 exit 0
- [x] 2.2 確認 `.cash-skills/bin/cash` 在本 change 前後逐 byte 不變（git diff 為空），launcher 相關凍結測試不受影響

## 3. 測試

- [x] 3.1 新增 `scripts/cash-skills/tests/test_init_receipt.py`：覆蓋 fresh-clone 模擬（移除 receipt 的 target 副本）簽發後 receipt 逐項通過 launcher `validate_receipt` 且 `.cash-skills/bin/cash list --json` 可用、冪等零寫入（bytes 不變、無 temp 殘留）、umask `002` fixture 下 mode 正規化後成功簽發、四類 fail-closed 零內容寫入（非 top-level、source repo 拒絕且診斷含 `--self`、config 缺失或 invalid、inventory 缺失）、非 regular file 形狀 fail closed 不 chmod（被 skew 的 path 排在不安全 path 之前）、flock 被他人持有時的序列化行為、umask 002 的 source repo 仍被拒絕、非空 `.cash-workspace.lock` fail closed、receipt 為 FIFO 時不阻塞、失敗路徑不留 bytecode、文件化指令忽略 shadowing module
- [x] 3.2 更新 `scripts/cash-skills/tests/test_installer_runtime.py`：新增 `BUNDLE_VERSION` 恆等於 `cash-skills.version` 內容的 contract 斷言
- [x] 3.3 執行 `scripts/cash-skills/tests/` 與 `scripts/cash-cli/tests/` 兩處測試套件全數通過

## 4. 文件

- [x] 4.1 [P] 更新 `CASH-SKILLS.md`：新增團隊 onboarding 一節（source 維護者視角），載明 clone 後於專案根執行 `PYTHONPATH=.cash-skills/lib python3 -s -P -B -m cash_cli.installer --init-receipt` 即可使用 cash CLI，並載明 Python 3.11+ 前提與信任模型（git clone 內容為信任根、receipt 負責簽發後 drift 偵測）
- [x] 4.2 在 source repo 的 `AGENTS.md` 與 `CLAUDE.md` Cash guidance 標記區塊內新增 init 指引一段（receipt 缺失出現 `bootstrap_invalid` 時，於專案根執行 `PYTHONPATH=.cash-skills/lib python3 -s -P -B -m cash_cli.installer --init-receipt`），兩檔區塊內容一致；此段隨 installer guidance 部署到各 target 的 managed block
- [x] 4.3 新增 source-only 參考文件 `CASH-INIT-RECEIPT.md`：完整記載 `--init-receipt` 的使用情境、文件化指令與 `-s -P -B` 各自的必要性、`initialized`／`current` 結果碼、六個具名 error code 的實測診斷與處置、D3 執行流程與寫入面保證、信任模型、與 `install-cash-skills.fish` 各模式的對照，以及 FAQ；文件中的每則錯誤訊息與行為宣稱 MUST 以實測取得，不得由程式碼推斷

## 5. 收尾驗證與部署

- [x] 5.1 逐條驗證 design.md Implementation Contract 第 1 至 10 項全部成立
- [x] 5.2 執行 `./install-cash-skills.fish --self` 重建本 repo `.cash-skills/receipt.tsv`，確認版本與 digests 反映 2.8.0
- [x] 5.3 執行 `./install-cash-skills.fish --all`，確認全部既有 registry targets 回報 `updated`（record 集合未擴充的回歸證據）、任一 target 的 managed guidance block 含 init 指引段，且任一 target 上以 `--init-receipt` 重簽後 launcher 驗證仍通過

## 6. 部署時序修復（cash-verify C1／C2）

第 5 節的 `--self`／`--all` 證據於 apply review fix actions 之前取得，其後 `installer.py` 與 guidance 區塊再被修改而版本未再遞增，證據已失效（詳 design D6 部署時序規則）；本節重新取得證據。

- [x] 6.1 將 `cash-skills.version` 由 2.8.0 遞增為 2.9.0，並同步更新 `.cash-skills/lib/cash_cli/installer.py` 的 `BUNDLE_VERSION` 為 `"2.9.0"`；版本檔 bump MUST 先於本節其他任何受守衛檔案的修改（現況：review fix 後的 `installer.py` bytes 與 targets 上 2.8.0 receipt 記錄的 digest 不同，`--all` 會以 equal-version source integrity drift 對每個 target 失敗且 `--force` 不可繞過）
- [x] 6.2 更新 `scripts/cash-skills/tests/skill-checks.fish` 的 canonical Cash guidance pinned baseline digest 為現行 `AGENTS.md`／`CLAUDE.md` Cash 區塊的實際 digest，使 `guidance-cutover` 具名群組轉綠；本 task 範圍內除該 digest 常數外不修改此檔的任何其他斷言（task 7.5 另行授權在 `assert_guidance_and_docs` 新增 `CASH-INIT-RECEIPT.md` 的 literal 釘選）
- [x] 6.3 重跑 `scripts/cash-skills/tests/skill-checks.fish` 全套（含 `guidance-cutover`）與 `scripts/cash-skills/tests/`、`scripts/cash-cli/tests/` 兩處 python 測試套件，全數通過
- [x] 6.4 執行 `./install-cash-skills.fish --self` 重建本 repo `.cash-skills/receipt.tsv`，確認 version 為 2.9.0 且 `installer.py` digest 與現地 bytes 一致
- [x] 6.5 執行 `./install-cash-skills.fish --all`，確認全部 8 個 registry targets 回報 `updated`、各 target receipt version 為 2.9.0 且 `installer.py` digest 與 source 一致（targets 自此執行含 source-repo 判定去 mode 化與 receipt FIFO 防阻塞的修正後行為）
- [x] 6.6 於任一 target 驗證：`--init-receipt` 重簽後 launcher 驗證通過、managed guidance block 含 init 指引段——此為 requirement「Target-local receipt 初始化」在 2.9.0 部署後的收尾驗證

## 7. Runtime inventory 期望集合（cash-apply round 3 finding 1／4）

round 3 以 Fix-loop design circuit breaker abort：`init_inventory` 的 runtime 期望集合由現地 `rglob` 就地推導，使 D3 的 inventory 完整性檢核恆真（詳 design D8）。本節依 D8 建立獨立的期望集合，並補上 round 3 finding 4 未處理的 gate 治理。

- [x] 7.1 將 `cash-skills.version` 由 2.9.0 遞增為 2.10.0，並同步更新 `.cash-skills/lib/cash_cli/installer.py` 的 `BUNDLE_VERSION` 為 `"2.10.0"`；版本檔 bump MUST 先於本節其他任何受守衛檔案的修改（依 design D6 部署時序規則：2.9.0 已由 `--all` 綁定散佈到 8 個 targets，其後再改 `installer.py` 而不 bump 會使 `--all` 對每個 target 以 equal-version source integrity drift 失敗）
- [x] 7.2 於 `.cash-skills/lib/cash_cli/installer.py` 新增模組常數 `BUNDLE_RUNTIME_PATHS`，內容為 19 條 canonical runtime 相對路徑的有序 tuple（依 path bytes 排序，與 `source_inventory` 的排序鍵一致）；修改 `init_inventory` 以它為期望集合與現地 `rglob` 結果比對，不相等即以 `init_inventory_invalid` fail closed，診斷 MUST 同時列出 missing 與 extra 兩個差集；`source_inventory` 的 source 端推導路徑不變
- [x] 7.3 更新 `scripts/cash-skills/tests/test_installer_runtime.py`：新增 `BUNDLE_RUNTIME_PATHS` 恆等於 `source_inventory` 推導出的 runtime 路徑集合的 contract 斷言，不相等時以非零結束並指出差集
- [x] 7.4 更新 `scripts/cash-skills/tests/test_init_receipt.py`：新增兩個 fail-closed 案例——刪除任一 canonical runtime `.py` 後 `--init-receipt` 以 `init_inventory_invalid` 失敗且診斷含該路徑、零 receipt 寫入；新增一個非 canonical 的 `.py` 後同樣失敗且診斷含該路徑。既有 `test_missing_inventory_fails_closed` 的 case 清單一併補入一條 runtime 路徑，使其名稱與涵蓋範圍相符
- [x] 7.5 於 `scripts/cash-skills/tests/skill-checks.fish` 的 `assert_guidance_and_docs` 新增 `CASH-INIT-RECEIPT.md` 的 literal 釘選（六個具名 error code、文件化指令字串 `python3 -s -P -B -m cash_cli.installer --init-receipt`、`init_source_repo` 的診斷字串 `./install-cash-skills.fish --self`），比照該函式既有的 `CASH-SKILLS.md` 釘選作法；不修改此檔的其他斷言
- [x] 7.6 更新 `CASH-INIT-RECEIPT.md` 的「錯誤診斷對照表」`init_inventory_invalid` 一節與「它實際做了什麼」的 inventory 完整性檢核一步，載明 runtime 期望集合比對與 missing／extra 差集診斷；訊息文字以實測取得
- [x] 7.7 重跑 `scripts/cash-skills/tests/skill-checks.fish` 全套與 `scripts/cash-skills/tests/`、`scripts/cash-cli/tests/` 兩處 python 測試套件，全數通過
- [x] 7.8 逐條驗證 design.md Implementation Contract 第 1 至 13 項全部成立
- [x] 7.9 執行 `./install-cash-skills.fish --self` 重建本 repo `.cash-skills/receipt.tsv`，確認 version 為 2.10.0 且 `installer.py` digest 與現地 bytes 一致
- [x] 7.10 執行 `./install-cash-skills.fish --all`，確認全部 8 個 registry targets 回報 `updated`、各 target receipt version 為 2.10.0 且 `installer.py` digest 與 source 一致；於任一 target 驗證 `--init-receipt` 重簽後 launcher 驗證仍通過，且刪除一個 runtime `.py` 後改以 `init_inventory_invalid` fail closed

註：本節的 2.10.0 不是最終部署版本。apply review round 4 的 fix actions 修正 `init_inventory` 的 `__pycache__` 過濾範圍後，依 design D6 部署時序規則再遞增為 **2.11.0** 並重新完成 `--self` 與 `--all` 部署；該次 bump 與部署證據見 `reviews/apply-r4.md` 的 `## Fix Actions`（Contract 第 7 項對此類 review-loop 內 bump 的證據出處有明文判準）。
