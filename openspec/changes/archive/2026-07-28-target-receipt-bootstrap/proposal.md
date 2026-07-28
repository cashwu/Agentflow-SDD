## Summary

在 installer module 內新增 target-side 的 receipt 初始化模式 `--init-receipt`，讓團隊成員 clone target 專案後執行一次 `PYTHONPATH=.cash-skills/lib python3 -s -P -B -m cash_cli.installer --init-receipt` 即可在本機簽發 `.cash-skills/receipt.tsv`，使 cash CLI 從「必須由 canonical repo 的 installer 安裝才能用」變成「clone 即用」。此模式不新增任何檔案、不擴充 bundle inventory、不修改 launcher——初始化邏輯嵌入既有 runtime record `.cash-skills/lib/cash_cli/installer.py`，隨既有安裝與升級路徑部署到所有 target。

## Motivation

- `.cash-skills/receipt.tsv` 記錄機器特定的 `st_dev`／`st_ino` 與 runtime digests，因此被 `Target 版控排除保護` requirement 排除於版控之外；launcher 在 receipt 缺失時以 `bootstrap_invalid`（`open_regular` 開檔失敗）、內容無效時以 `receipt_invalid` fail closed。結果是：target 專案裡 skills、runtime、launcher、`.cash-workspace.lock` 全部隨 git clone 取得，唯獨 receipt 缺失，新成員 clone 後 cash CLI 完全不可用。
- 目前唯一的 receipt 來源是 canonical repo（本 repository）的 `install-cash-skills.fish`，且 registry 是安裝者個人 HOME 之下的 cash-skills 設定檔（projects.txt）——分發是單人單機瓶頸，團隊成員必須取得 canonical repo 存取權才能開始使用。
- receipt 簽發邏輯（digest 計算、record 組裝、atomic 寫入與 containment）已存在於 target 版控內的 `.cash-skills/lib/cash_cli/installer.py`，且該 module 具 `__main__` 進入點、可以 python3 -m 形式執行；缺的只是一個不經過 launcher receipt 閘門的 target-side 模式。
- 三重凍結約束決定了解法形狀：launcher 的 runtime record 路徑檢核僅接受 `.cash-skills/lib/cash_cli/` 下的 `.py`；launcher bytes 受 stable freeze 條款、contract test 與 installer migration error 三重凍結不可修改；installer 對既有 receipt 以完整 expected inventory 嚴格解析，任何 inventory 擴充都會使既有 target 的升級在版本比較前失敗。把初始化邏輯嵌入既有 runtime record 是唯一同時避開三者的路徑。

## Proposed Solution

1. **`--init-receipt` 模式**：`cash_cli.installer` 的 argparse 新增與既有 modes 互斥的 `--init-receipt`。從 target 專案根執行：驗證 worktree top-level 與 `openspec/config.yaml`；以 source layout 判定式拒絕 canonical source repo（診斷導向 `./install-cash-skills.fish --self`）；對 `.cash-workspace.lock` 取 exclusive flock；將 managed inventory 的檔案 mode 正規化為 contract modes（吸收 clone 環境的 umask 差異）；檢核 inventory 完整性；以現地 bytes 與本機 no-follow `lstat` 組出與 installer 同 schema 的 receipt，沿用既有 atomic 寫入與 containment 語意簽發。
2. **內嵌的 target-side 真相來源**：target 上沒有 source-only 的 `cash-skills.version`，也沒有任何 canonical inventory 清單，因此 init 模式需要的兩項期望值都由 installer module 內嵌常數提供——bundle 版本（receipt `version` 值）與 canonical runtime 路徑集合（inventory 完整性檢核的期望集合）。兩者都以 contract test 守衛其與 source 端推導結果相等，消除雙真相來源風險。runtime 期望集合是必要的：若沿用「就地枚舉現地 `.py`」，完整性檢核會拿觀察狀態跟自己比對而恆真，缺檔或多檔都會簽發一份自洽但錯的 receipt。
3. **明確的信任模型**：init 簽發的 receipt 以 git clone 內容為信任根——執行它等於使用者主動宣告信任現地版控內容；provenance 由 git 歷史承擔，receipt 維持既有職責（簽發後偵測本機 drift 與竄改）。
4. **引導與部署**：launcher 完全不動；target 端的使用者引導由部署到各 target 的 cash guidance 區塊承擔（在 source repo 的 `AGENTS.md` 與 `CLAUDE.md` Cash 標記區塊新增 init 指引，隨 installer guidance 部署到達所有 target）；`CASH-SKILLS.md` 的 onboarding 一節服務 source 維護者視角（該檔為 source-only、不部署）。`cash-skills.version` 遞增且 bump 先於任何受版本守衛檔案的修改；收尾 `./install-cash-skills.fish --self` 重建本 repo receipt，再以 `--all` 推送——因 inventory 未擴充，既有 targets 走正常 update 路徑。部署後若任何受守衛檔案再被修改（如 review fix actions），MUST 再次遞增版本並重新部署，避免「同版本、不同 bytes」使後續 `--all` 以 equal-version source integrity drift 失敗——本 change 依此規則重新部署過三次：以 2.9.0 收斂 review fix actions 對 `installer.py` 的修改並同步更新 guidance pinned baseline digest，以 2.10.0 收斂 runtime 期望集合的建立，再以 2.11.0 收斂 `init_inventory` 的 `__pycache__` 過濾範圍修正；最終部署版本為 2.11.0。

## Non-Goals

- 不修改 launcher `.cash-skills/bin/cash` 的任何 bytes：其 `validate_receipt` 邏輯、error codes、診斷文字全部不動（stable freeze 三重約束下不可行，亦非必要）。
- 不新增任何檔案到 bundle inventory、不改變 receipt 的 record 集合與 schema。內嵌的 runtime 期望集合常數不是 inventory 擴充——它列舉的正是現行 inventory，用途是讓 init 能在 target 上偵測差異，receipt 的 record 集合與 schema 完全不變。
- 不做 receipt 缺失時的自動自我修復：launcher 失敗行為維持現狀；自動修復會使竄改偵測失去意義。
- 不改變 registry 與批次安裝機制；不處理 plugin 化；不動 `Target 版控排除保護`。
- 不處理 import 完成之前的失敗：舊 python 直譯器的 `SyntaxError`，以及 `cash_cli.installer` import-time 相依（`installer.py` 自身、它直接匯入的 `config.py`，以及套件 `__init__` 匯入鏈上的 `main.py` 與 `errors.py`，共 4 個）缺席造成的 `No module named` 失敗。兩者都在 `-m` 載入期發生、先於任何檢核，無法產生具名 error code；可達 `__main__` 時以具名 error code 檢查 Python 3.11+，其餘 15 個 canonical runtime 模組的增減由 `init_inventory` 以 `init_inventory_invalid` 涵蓋。

## Alternatives Considered

- **新增獨立入口檔（.cash-skills/bin/ 或 lib/ 下新檔）**：任一新檔都是 bundle inventory 擴充——launcher 的 runtime record 路徑檢核拒絕 lib 外的 record；installer 的 `parse_receipt` 以完整 expected inventory 嚴格比對既有 receipt，inventory 擴充使全部既有 targets 的 `--all` 升級在版本比較前以 execution error 失敗（正是 open signal `trust-root-inventory-blocks-payload-extension` 的形狀）。解除需 MODIFIED 多條凍結條款與 launcher bytes，改動面與風險過大。棄。
- **launcher 診斷引導 init 指令**：launcher bytes 受「Stable bootstrap bytes 不得隨一般 bundle version 改變」條款、`test_bundle_version_history.py` 的 stable 斷言與 `publish_launcher` 的 migration error 三重凍結；修改需要引入 bootstrap migration 機制，遠超本 change 目的。改由文件引導。棄。
- **launcher 內建 auto-init（receipt 缺失時自動簽發）**：使「receipt 缺失」從可疑狀態變成正常狀態，竄改者可刪 receipt 觸發重簽，drift 偵測歸零；且同樣撞 launcher 凍結。棄。
- **teammate clone canonical repo 自行安裝（現行做法）**：可行的過渡，但要求全員取得 canonical repo，不解決根因。

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `cash-cli`：新增 target-side receipt 初始化模式（`--init-receipt`）契約——進入形式、prerequisite 驗證、mode 正規化、信任模型、版本常數守衛、冪等與錯誤契約；不改變既有 launcher、bundle inventory 與 receipt schema。

## Impact

- Affected specs:
  - openspec/specs/cash-cli/spec.md
- Affected code:
  - New:
    - scripts/cash-skills/tests/test_init_receipt.py
    - CASH-INIT-RECEIPT.md
  - Modified:
    - .cash-skills/lib/cash_cli/installer.py
    - cash-skills.version
    - AGENTS.md
    - CLAUDE.md
    - CASH-SKILLS.md
    - scripts/cash-skills/tests/test_installer_runtime.py
    - scripts/cash-skills/tests/skill-checks.fish
    - .cash-skills/receipt.tsv
  - Removed:
    - (none)
- Deployment surface: 8 個 registry targets 的 managed inventory 與 guidance block 已由 --all 實際改寫，且部署時序修復需再次部署（2.9.0，詳 design D6 與 tasks 第 6 節），runtime 期望集合建立後再以 2.10.0 部署（詳 design D8 與 tasks 第 7 節），`__pycache__` 過濾範圍修正後再以 2.11.0 部署（apply review round 4 fix actions，證據見該輪 round file）；**最終部署版本為 2.11.0**。
