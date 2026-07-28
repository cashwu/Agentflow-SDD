## Context

target 專案經 installer 安裝後，launcher（`.cash-skills/bin/cash`、stable、0755）、`.cash-workspace.lock`（stable、0644）、runtime（`.cash-skills/lib/cash_cli/`）與 24 個 skills 全部進入版控；唯 `.cash-skills/receipt.tsv` 因記錄機器特定 `st_dev`／`st_ino` 而被 gitignore。launcher 主流程無條件執行 `validate_receipt`：receipt 檔案缺失時由 `open_regular`（`.cash-skills/bin/cash:154` 經 `:68`）以 `bootstrap_invalid` 失敗，檔案存在但內容驗證失敗時以 `receipt_invalid` 失敗——fresh clone 的 cash CLI 因此不可用。

三重凍結約束（皆已實檔驗證）決定解法形狀：

1. **launcher runtime record 路徑檢核**（`.cash-skills/bin/cash:238-243`）：每筆 runtime record 的 path MUST 以 `.cash-skills/lib/cash_cli/` 開頭且以 `.py` 結尾，否則 `receipt_invalid`。lib 之外的新 record 不可能被接受。
2. **launcher bytes 凍結**：master spec「Stable bootstrap bytes不得隨一般bundle version改變」條款、`scripts/cash-skills/tests/test_bundle_version_history.py` 對 stable paths 的 introduction-commit byte 斷言（即使 bump 版本也失敗）、`installer.py` 的 `publish_launcher` 對 bytes 不同的既有 launcher 直接 raise「stable launcher drift requires an unsupported bootstrap migration」。
3. **installer 舊 receipt 嚴格解析**（`installer.py` 的 `parse_receipt` 要求 `len(rows) == len(expected_records) + 2` 且逐筆比對；`install_target` 在 `compare_versions` 之前呼叫它）：任何 bundle inventory 擴充都使既有 target 的升級以 execution error 失敗，`--force` 不可繞過。

因此初始化邏輯嵌入既有 runtime record `.cash-skills/lib/cash_cli/installer.py`（純 stdlib＋套件內 `from .config import` 相對匯入、具 `__main__` 進入點、由 fish 進入點以 `python3 -s -P -m cash_cli.installer` 執行）：零新檔、零 inventory 擴充、零 launcher 修改。

## Goals / Non-Goals

**Goals**

- 隊友 clone target 專案後，於專案根執行一次 `PYTHONPATH=.cash-skills/lib python3 -s -P -B -m cash_cli.installer --init-receipt` 即簽發本機 receipt，cash CLI 立即可用，無需 canonical repo。
- init 模式吸收 clone 環境的 umask 差異（mode 正規化），使「clone 即用」不依賴特定 umask。
- `CASH-SKILLS.md` 提供團隊 onboarding 指引。

**Non-Goals**

- 不動 launcher bytes；不擴充 bundle inventory 與 receipt schema；不做自動修復；不動 registry／批次安裝；不動 `Target 版控排除保護`；不處理 import 完成之前的失敗（舊直譯器的 `SyntaxError`，以及 `cash_cli.installer` import-time 相依缺席造成的 `ModuleNotFoundError`）——兩者都先於任何檢核發生，無法產生具名 error code。

## Decisions

**D1 — 進入形式**：`cash_cli.installer` 的 argparse 新增 `--init-receipt` 模式，與 `--self`、`--target`、`--register`、`--unregister`、`--list`、`--all`、`--force` 互斥（沿用既有互斥骨架）。文件化指令為在 target 專案根執行 `PYTHONPATH=.cash-skills/lib python3 -s -P -B -m cash_cli.installer --init-receipt`。不新增任何檔案。

**D2 — 版本來源**：installer module 新增模組常數 `BUNDLE_VERSION`（本 change 首次實作為 `"2.8.0"`；因 D6 的部署時序修復遞增為 `"2.9.0"`；因 D8 再次修改 `installer.py` 遞增為 `"2.10.0"`；因 round 4 fix actions 再次修改 `installer.py`，最終值為 `"2.11.0"`）。init 模式以它作為 receipt 首行 `version` 值——target 上沒有 source-only 的 `cash-skills.version`。source 端既有「從 `cash-skills.version` 讀版本」的路徑完全不變。`scripts/cash-skills/tests/test_installer_runtime.py` 新增 contract 斷言：`BUNDLE_VERSION` 恆等於 `cash-skills.version` 檔案內容，守衛雙真相來源。

**D3 — 執行流程**（依序）：
1. 於 `--init-receipt` 模式分支內、任何其他步驟之前檢查 Python 3.11+，不符以 `init_python_version` 失敗；其他既有 modes 的失敗形狀不變（更舊直譯器在 `-m` 載入期的 SyntaxError traceback 屬已接受限制，見 Risks）。
2. 解析並驗證 cwd 為 canonical Git worktree top-level（realpath 相等），否則 `init_outside_worktree`。
3. 以 launcher 的 source layout marker 集合偵測 canonical source repo；命中以 `init_source_repo` 失敗，診斷含 `./install-cash-skills.fish --self`。判定條件為 marker 的存在與 regular-file 形狀加上可解析的 `cash-skills.version`，**不含 contract mode 相等**：這些 marker（`install-cash-skills.fish`、`cash-skills.version`、`CASH-SKILLS.md`、legacy manifest 等）都不屬於步驟 7 正規化的 managed inventory，沿用 launcher 的 mode-equal 判定會使 umask `002` clone 的 source repo 被誤判為一般 target 並簽發 receipt，與步驟 7 明文支援 umask 偏移 clone 的立場自相矛盾。
4. 驗證 `openspec/config.yaml` 安全可讀且 schema-valid（重用 installer 既有驗證）；缺檔、unsafe 或 invalid 以 `init_config_invalid` 失敗，不建立任何檔案。
5. 檢查 `.cash-workspace.lock` 存在、為 regular file 且為空；缺失或非空以 `init_inventory_invalid` 失敗並在診斷指出原因（不自行建立或修復 stable 檔案）。非空的 lock 若被放行，簽發會成功但 launcher 隨即以 `workspace_lock_invalid` 失敗，形成「成功卻不可用」。通過則取 exclusive flock 並全程持有。
6. **runtime inventory 完整性檢核**：runtime 的期望路徑取自 D8 的 `BUNDLE_RUNTIME_PATHS`，與現地實際集合比對；不相等（缺檔或多檔）即以 `init_inventory_invalid` 失敗，診斷同時列出 missing 與 extra 兩個差集。此步驟排在 mode 正規化之前，因此 runtime 集合不符時連一次 `chmod` 都不會發生——嚴格優於步驟 10 所保證的寫入面。
7. **Mode 正規化**：對 managed inventory（launcher、lock、runtime `.py`、24 skills）以 no-follow `lstat` 檢核 regular-file 形狀後，將 mode `chmod` 為 contract modes（launcher 0755、其餘 0644）。僅 chmod、不改任何 bytes；非 regular file（symlink、FIFO、hard link）以 `init_inventory_invalid` fail closed 不 chmod。stable 與 24 個 skill 的存在性檢核與形狀檢核同趟進行，缺檔同樣以 `init_inventory_invalid` 失敗。此步驟吸收 git checkout 依 umask 產生的 mode 差異。
8. 以現地 bytes 計算 digests、本機 no-follow `lstat` 產生 stable identity，重用 `receipt_bytes` 組出與 installer 同 schema 的 receipt（record 集合與現行完全相同，無新 record）。`receipt_bytes` 內部即以 `os.lstat` 取 `st_dev`／`st_ino`；步驟 7 之後每個 managed path 都已由 `read_regular` 確認 `lstat` 與 `fstat` identity 一致，兩者取值等價。
9. 既有 receipt 的 bytes 與 contract mode `0644` 都與重算結果一致時回報 `current` 零寫入；缺失、bytes 不一致或 mode 已漂移時沿用 installer 的 same-directory owned temporary、directory-fd containment 與 atomic rename 寫入 `.cash-skills/receipt.tsv`，回報 `initialized`；替換無效舊 receipt 時印 warning。等價判定納入 mode 是因為 launcher 以 `open_regular(receipt_path, 0o644)` 對 receipt 設有 mode 閘門，只比 bytes 會在 mode 漂移時回報 `current` 卻留下 `bootstrap_invalid` 的 CLI。讀取既有 receipt 前先以 `lstat` 判定形狀（`ensure_regular_shape`）：此時已持有 exclusive flock，若 receipt 是 FIFO 則開檔會阻塞至有 writer 出現，整個 workspace 隨之卡死，因此非 regular file 一律 `init_write_failed`。`.cash-skills` 目錄非 regular directory 時亦 fail closed（`init_write_failed`）。
10. 檔案內容寫入面：所有失敗路徑零內容寫入；成功路徑唯一內容寫入為 receipt。步驟 7 的 chmod 是唯一的 metadata 修改，且僅及 managed inventory；形狀檢核與 chmod 分兩趟進行，因此形狀不安全時零 chmod（chmod syscall 本身失敗時仍可能留下部分正規化，此為 metadata 面，不影響內容零寫入保證）。文件化指令帶 `-s -P -B`，因此失敗路徑也不會在 target 內留下 bytecode 快取。

**D4 — 信任模型（明確取捨）**：init 簽發的 receipt 以 git clone 內容為信任根——執行 init 等於使用者主動宣告信任現地版控內容；provenance 由 git 歷史承擔，receipt 維持既有職責（簽發後偵測本機 drift 與竄改）。推論其一：init 執行時 import 的 `cash_cli` runtime 本身尚未經 receipt 驗證，屬同一信任宣告的一部分。推論其二：對已 drift 的 target 重跑 init 會把 drift 合法化——此為使用者主動的明示動作，與 installer `--force` 同級。

**D5 — 引導管道**：launcher 不動（Context 的凍結約束 2）。receipt 缺失時使用者看到的仍是既有 `bootstrap_invalid` 診斷。init 指令的發現管道有二：(1) 部署面——installer 的 guidance 部署（`installer.py` 的 `GUIDANCE_PATHS = ("AGENTS.md", "CLAUDE.md")`；內容取自 source repo 兩檔的 Cash 標記區塊，經 `canonical_guidance` 渲染進各 target 的 managed block）：在 source 的 Cash guidance 區塊新增一段 init 指引，隨 `--all` 到達所有 target，target 端的 agent 據以在 `bootstrap_invalid` 時引導使用者；(2) 維護面——`CASH-SKILLS.md` 的 onboarding 一節，以及 source-only 參考文件 `CASH-INIT-RECEIPT.md`（完整的指令、結果碼、六個 error code 的實測診斷、信任模型與模式對照）。注意 `CASH-SKILLS.md` 與 `CASH-INIT-RECEIPT.md` 都是 source-only 檔（installer 不部署它們，且前者是 launcher `is_source_layout` 的判定 marker 之一），只服務 canonical repo 的維護者與排錯者視角；target 端的可達管道是 (1)。

**D6 — 版本與部署**：`cash-skills.version` 2.7.0 → 2.8.0；`installer.py` 屬 `test_bundle_version_history.py` 的 replaceable 守衛集合（`lib/cash_cli` 的 `rglob("*.py")`），bump MUST 先於其修改。收尾 `./install-cash-skills.fish --self` 重建本 repo receipt，再 `--all` 部署——inventory 未擴充，既有 targets 的 receipt 與 expected records 集合一致，走正常 update 路徑。

**部署時序規則（cash-verify C1 修復）**：`--all` 一旦以某版本執行，該版本即與當時的 replaceable bytes 綁定散佈到 targets；其後對任何受守衛檔案的再修改 MUST 再次遞增版本後重新部署，否則 source 與 targets 形成「同版本、不同 bytes」——installer 的 equal-version source integrity drift 檢核會使後續 `--all` 對每個 target 以 execution error 失敗且 `--force` 不可繞過。本 change 的實際教訓：task 5.3 的 `--all` 在 apply review fix actions 之前執行，fix 修改了 `installer.py`（source-repo 判定去 mode 化、receipt FIFO 防阻塞）而未再 bump，8 個 targets 因此持有舊 bytes 的 2.8.0 receipt。修復：`cash-skills.version` 與 `BUNDLE_VERSION` 同步遞增為 2.9.0（bump 先於本節任何受守衛檔案修改），更新 `scripts/cash-skills/tests/skill-checks.fish` 的 canonical Cash guidance pinned baseline digest（該檔已納入 proposal `## Impact` 結構化範圍宣告；cash-verify C2——task 4.2 改 guidance 區塊後 `guidance-cutover` 群組因舊 digest 必然失敗），全套測試轉綠後依序 `--self`、`--all` 重新取得部署證據。

同一規則於 D8 再次適用：2.9.0 已由 `--all` 綁定散佈到 8 個 targets，D8 對 `installer.py` 的修改因此 MUST 先把 `cash-skills.version` 與 `BUNDLE_VERSION` 同步遞增為 2.10.0（tasks 7.1 先於 7.2），再於全套測試轉綠後依序 `--self`、`--all` 取得該版本的部署證據。同一規則於 round 4 fix actions 第三次適用：2.10.0 已部署，`init_inventory` 的 `__pycache__` 過濾範圍修正因此先遞增為 2.11.0 再重新部署。

**D7 — 錯誤與輸出契約**：init 模式成功時印單行 `initialized` 或 `current` 到 stdout、exit 0。失敗時印統一 JSON 錯誤 shape（`error.code`、`error.message`）到 stdout、exit 1；具名 codes：`init_python_version`、`init_outside_worktree`、`init_source_repo`、`init_config_invalid`、`init_inventory_invalid`、`init_write_failed`。不提供 `--json` flag——init 模式輸出固定。

**D8 — runtime payload 期望集合（cash-apply round 3 finding 1 修復）**：`init_inventory` 原本以 `library.rglob("*.py")` 就地枚舉推導 runtime record 集合，使 D3 步驟 6 對 runtime 部分成為空談——期望集合來自觀察狀態，比對恆真。實測後果有二：target 少一個 runtime 模組時 init 回報 `initialized`、exit `0`，launcher `validate_receipt` 通過（它只驗證 receipt 已列出的 record，從不枚舉目錄），CLI 隨即以未捕捉的 `ModuleNotFoundError` traceback 失敗，直接違反 Implementation Contract 第 1 項；多一個 `.py` 時 init 同樣成功，但該 target 的 `--target`／`--all` 自此永久以 `receipt has an invalid record count` 失敗且 `--force` 不可繞過。

修法沿用 D2 已確立的機制而不引入新抽象層：installer module 新增模組常數 `BUNDLE_RUNTIME_PATHS`，內容為 canonical runtime 相對路徑的有序 tuple（依 path bytes 排序，與 `source_inventory` 的排序鍵一致）。`init_inventory` 以它為期望集合，與現地 `rglob` 結果比對；不相等即 `init_inventory_invalid`，診斷同時列出 missing 與 extra 兩個差集，使診斷本身足以定位問題。`scripts/cash-skills/tests/test_installer_runtime.py` 新增 contract 斷言：`BUNDLE_RUNTIME_PATHS` 恆等於 `source_inventory` 從 source 推導出的 runtime 路徑集合，守衛雙真相來源。

**In scope**：`init_inventory` 的 runtime 期望集合比對與其診斷、常數本身、contract 斷言、對應的 fail-closed 測試案例。
**Out of scope**：不改變 receipt 的 record 集合與 schema；不改變 launcher；不改變 installer 既有的 source 端安裝路徑（`source_inventory` 仍以 `rglob` 推導，因為 source repo 上 `cash-skills.version` 與完整 source tree 就是真相來源）。

**明示取捨**：此常數使日後每次增刪 runtime 檔都必須同步兩處，正是 open signal `trust-root-inventory-blocks-payload-extension` 描述的架構約束。接受它的理由是 contract 斷言會在 source 端攔住任何漏改（漏改使 `scripts/cash-skills/tests/` 直接轉紅，不會流到 target），而缺少期望集合的代價是使用者拿到「工具宣告成功、CLI 隨即 traceback」且沒有任何具名 error code——後者不可接受。

## Implementation Contract

1. `cash_cli.installer` 支援 `--init-receipt` 且與其他 modes 互斥；在移除 receipt 的 installed target 執行一次後，`.cash-skills/bin/cash list --json` 成功執行，不再以 `bootstrap_invalid` 或 `receipt_invalid` 失敗。
2. 冪等：receipt 的 bytes 與 mode `0644` 都有效時再次執行回報 `current`，`.cash-skills/receipt.tsv` 的 bytes 與 mode 不變（零寫入）。
3. 寫入面：所有失敗路徑零檔案內容寫入；成功路徑唯一內容寫入為 receipt（same-directory temporary＋atomic rename，無 temp 殘留）；唯一 metadata 修改為 D3-7 對 managed inventory 的 mode 正規化 chmod。
4. 簽發的 receipt 逐項通過 launcher `validate_receipt`：`version` 等於 `BUNDLE_VERSION`、`runtime_generation` 依 canonical stream 定義、stable records 含本機 `st_dev`／`st_ino`、runtime record 集合與現行 inventory 完全相同（無新 record）。
5. 在 canonical source repo 執行 `--init-receipt` 以 `init_source_repo` 失敗且診斷含 `./install-cash-skills.fish --self`，umask `022` 與 umask `002` 兩種 clone mode 皆然；`.cash-skills/bin/cash` 的 bytes 在本 change 前後逐 byte 不變。
6. `BUNDLE_VERSION` 常數存在且 `scripts/cash-skills/tests/test_installer_runtime.py` 斷言其等於 `cash-skills.version` 內容。
7. `cash-skills.version` 最終內容為 2.11.0、與 `BUNDLE_VERSION` 一致，且嚴格大於 `git show HEAD:cash-skills.version`；**tasks 內的**每次 bump 在 task 序位上先於其後受守衛檔案的修改（task 1.1 先於 2.1、task 7.1 先於 7.2 這類受守衛檔案配對；6.1 與 7.1 這類 bump task 內部亦以版本檔先寫入為序）。發生在 review loop fix actions 內、不對應任何 task 的 bump（2.10.0 → 2.11.0）以該輪 round file 為證據出處，其序位由 `## Fix Actions` 記載，判準同為版本檔先寫入，`.cash-skills/receipt.tsv` 經 `./install-cash-skills.fish --self` 重建並反映 2.11.0。判準以 task 序位而非 commit 序位表述，因為 cash change 以單一 commit 落地，中間版本 2.8.0 不會存在於任何 commit；實際 gate（`test_bundle_version_history.py` 的 `check_history`）在工作樹版本嚴格遞增時即 early return，本就不檢查 commit 序位。
8. source repo 的 `AGENTS.md` 與 `CLAUDE.md` Cash guidance 區塊各含一段 init 指引（載明 receipt 缺失時執行 `PYTHONPATH=.cash-skills/lib python3 -s -P -B -m cash_cli.installer --init-receipt`），且 `--all` 後任一 target 的 managed guidance block 含同段指引；`CASH-SKILLS.md` 含團隊 onboarding 一節（source 維護者視角），載明同一指令、信任模型與 Python 3.11+ 前提；source-only 參考文件 `CASH-INIT-RECEIPT.md` 逐節涵蓋六個具名 error code 的診斷與處置、D3 執行流程與寫入面保證、信任模型，以及與 `install-cash-skills.fish` 各模式的對照，其錯誤訊息與行為宣稱皆為實測取得。
9. `scripts/cash-skills/tests/test_init_receipt.py` 覆蓋：fresh-clone（模擬無 receipt target）簽發後 launcher 驗證通過且 CLI 可用、冪等零寫入、umask 002 環境下 mode 正規化後仍成功、四類 fail-closed 零寫入（非 top-level、source repo、config 缺失或 invalid、inventory 缺失）、flock 被他人持有時序列化等待或明確失敗、無 temp 殘留；另覆蓋 umask 002 的 source repo 仍被 `init_source_repo` 拒絕、非空 `.cash-workspace.lock` fail closed、receipt 為 FIFO 時不阻塞而 fail closed、失敗路徑不留 bytecode、文件化指令忽略 target 根的同名 shadowing module。形狀不安全的 fail-closed 案例中，被 skew mode 的 managed path MUST 排在不安全 path 之前，否則該斷言無法辨識單次交錯 loop 的實作。
10. `scripts/cash-skills/tests/skill-checks.fish` 全套（含 `guidance-cutover` 具名群組，pinned baseline digest 更新後）與 `scripts/cash-skills/tests/`、`scripts/cash-cli/tests/` 兩處 python 測試套件全數通過；`--all` 對既有 registry targets 全數回報 `updated`（inventory 未擴充的回歸證據），且每個 target 的 receipt version 與 source 的 `cash-skills.version` 相同、`installer.py` digest 與 source 一致。
11. `BUNDLE_RUNTIME_PATHS` 常數存在且 `scripts/cash-skills/tests/test_installer_runtime.py` 斷言其恆等於 `source_inventory` 推導出的 runtime 路徑集合。
12. runtime inventory 差異 fail closed：在移除 receipt 的 installed target 上刪除任一**非 import-time 相依**的 canonical runtime `.py`（19 個成員中的 15 個）後執行 `--init-receipt`，以 `init_inventory_invalid` 失敗、exit `1`、零 receipt 寫入，診斷含該缺檔路徑；新增一個不屬於 canonical 集合的 `.py` 後執行，同樣以 `init_inventory_invalid` 失敗，診斷含該多餘路徑。4 個成員是 import-time 相依，缺席時 `-m` 載入即以 `No module named` 失敗而走不到本檢核：`installer.py`（`-m` 的目標模組本身）、`config.py`（`installer.py` 自身的 `from .config import`）、`main.py` 與 `errors.py`（`cash_cli/__init__.py` 的 `from .main import main` 再到 `main.py` 的 `from .errors import`）。注意 `cash_cli/__init__.py` 本身**不**屬此類：它缺席時 Python 以 PEP 420 namespace package 承接，`cash_cli.installer` 仍可載入，因此落在 15 個具名 error code 的一側，屬 proposal Non-Goals 明載的已接受限制。`scripts/cash-skills/tests/test_init_receipt.py` 以參數化案例覆蓋全部 19 個成員，逐一斷言其落在具名 error code 或 import-time traceback 何者，使此不對稱在套件內可見。
13. `scripts/cash-skills/tests/skill-checks.fish` 的 `assert_guidance_and_docs` 以 literal 釘住 `CASH-INIT-RECEIPT.md` 的關鍵內容（六個具名 error code、文件化指令字串、`init_source_repo` 的診斷字串），使該檔與 `CASH-SKILLS.md` 落在同一治理面。

## Risks / Trade-offs

- **provenance 弱化**：receipt 不再證明「由 canonical installer 安裝」，只證明「簽發後未 drift」；git 歷史承擔 provenance（D4，明示取捨）。
- **重簽合法化 drift**：init 是使用者主動動作、launcher 從不自動觸發；替換無效舊 receipt 時印 warning。
- **mode 正規化的寫入面擴大**：chmod 僅及 managed inventory、僅在 no-follow lstat 確認 regular file 後執行；把「clone 即用」從 umask 相依變為確定性行為，收益大於metadata 修改的成本。
- **舊直譯器語法層級失敗**：`-m` 載入期的 SyntaxError 無法產生 JSON 錯誤（import 先於任何檢查）；已接受限制，`init_python_version` 涵蓋可達 `__main__` 的情形，onboarding 文件載明 Python 3.11+ 前提。
- **`BUNDLE_VERSION` 雙真相來源**：以 contract test 恆等斷言守衛（D2、Contract 6）；未來版本 bump 流程需同時改兩處，測試會攔住漏改。
- **`BUNDLE_RUNTIME_PATHS` 雙真相來源與 payload 擴充成本**：同樣以 contract test 恆等斷言守衛（D8、Contract 11）。日後新增或移除任一 runtime 模組都必須同步該常數，否則 `scripts/cash-skills/tests/` 在 source 端即轉紅——漏改不會流到 target。此成本是刻意換取的：沒有期望集合時，缺檔的 target 會得到「init 宣告成功、CLI 隨即以 traceback 死亡」且無任何具名 error code。此約束的一般形式見 open signal `trust-root-inventory-blocks-payload-extension`。
- **與 launcher／installer 併發**：以 `.cash-workspace.lock` exclusive flock 序列化，與既有協定同一 inode。
- **同版本不同 bytes 的部署防呆缺口**：本 change 以部署時序規則（D6）與人工序位約束防範，但缺乏機械防呆——release 流程可考慮比對 source receipt 的 runtime digests 與上次 `--all` 部署快照，版本未變而 digests 變即 fail closed；屬後續 change 候選，不在本 change 範圍。
