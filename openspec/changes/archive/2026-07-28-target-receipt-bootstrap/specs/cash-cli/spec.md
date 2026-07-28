## ADDED Requirements

### Requirement: Target-local receipt 初始化

`cash_cli.installer` SHALL 提供 target-side 的 `--init-receipt` 模式，與 `--self`、`--target`、`--register`、`--unregister`、`--list`、`--all`、`--force` 互斥，以在 target 專案根執行 `PYTHONPATH=.cash-skills/lib python3 -s -P -B -m cash_cli.installer --init-receipt` 的形式使用。此模式 MUST NOT 新增任何檔案到 bundle inventory、MUST NOT 改變 receipt 的 record 集合或 schema、MUST NOT 修改 `.cash-skills/bin/cash` 的任何 bytes。

`--init-receipt` MUST 依序：於 import 完成後檢查 Python 3.11+；驗證執行目錄為 canonical Git worktree top-level；以 launcher 的 source layout marker 集合（source-only 檔案、runtime core、24 個 canonical skill 的存在與 regular-file 形狀，加上可解析的 `cash-skills.version`）拒絕 canonical source repository 並在診斷中指向 `./install-cash-skills.fish --self`，該判定 MUST NOT 以 contract mode 相等為條件，因為這些 marker 都不在 mode 正規化涵蓋的 managed inventory 內，mode 相等的判定會使 umask 偏移的 source clone 被誤判為一般 target；驗證 `openspec/config.yaml` 安全可讀且 schema-valid（缺檔、unsafe 或 invalid 皆 fail closed，MUST NOT 建立任何檔案）；確認 `.cash-workspace.lock` 為既存且為空的 regular file（缺失或非空皆 fail closed，MUST NOT 建立或修復 stable 檔案）並取得 exclusive flock 全程持有；檢核 runtime inventory 完整性；再以 no-follow `lstat` 確認 managed inventory 逐檔為 regular file 後，將其 mode 正規化為 contract modes（launcher `0755`、其餘 `0644`），非 regular file 形狀 MUST fail closed 且不 chmod。runtime 完整性檢核 MUST 先於 mode 正規化，使 runtime 集合不符時零 `chmod`。任一檢核失敗 MUST 以具名 error code（`init_python_version`、`init_outside_worktree`、`init_source_repo`、`init_config_invalid`、`init_inventory_invalid`、`init_write_failed`）與統一 JSON 錯誤 shape 輸出到 stdout 並以 exit 1 結束，且零檔案內容寫入；mode 正規化的 `chmod` 是唯一允許的 metadata 修改。持有 exclusive flock 之後對 target 檔案的每一次開檔 MUST 先以 `lstat` 判定形狀，`.cash-skills/receipt.tsv` 本身為 FIFO 等非 regular file 時 MUST 以 `init_write_failed` fail closed 而非阻塞在開檔。

簽發時，`--init-receipt` MUST 從現地 bytes 計算 digests、以本機 no-follow `lstat` 產生 stable identity，組出與 installer 安裝路徑相同 schema 的 receipt：`version` 值取自 installer module 內嵌的 `BUNDLE_VERSION` 常數，record 集合與現行 inventory 完全相同。寫入 MUST 沿用 same-directory owned temporary 與 atomic rename，`.cash-skills` 非 regular directory 時 MUST fail closed。既有 receipt 的 bytes 與 contract mode `0644` 都與重算結果一致時 MUST 回報 `current` 且零寫入；bytes 一致但 mode 已漂移時 MUST 走一般簽發路徑重寫並回報 `initialized`，因為 launcher 對 receipt 有 `0644` 的 mode 閘門，回報 `current` 會留下「成功卻不可用」的狀態。成功簽發回報 `initialized`，兩者皆輸出單行到 stdout 並以 exit 0 結束。簽發的信任根是 git clone 的現地內容：`--init-receipt` 是使用者主動的明示動作，launcher MUST NOT 在 receipt 缺失或無效時自動觸發它。

inventory 完整性檢核 MUST 以獨立於現地觀察狀態的期望集合進行。stable 與 24 個 canonical skill 的期望路徑為常數推導；runtime 的期望路徑 MUST 取自 installer module 內嵌的 `BUNDLE_RUNTIME_PATHS` 常數，MUST NOT 以現地 `rglob` 枚舉結果作為自身的期望集合——那會使比對恆真、缺檔與多檔皆不被偵測，並簽發一份自洽但錯的 receipt。現地 runtime 集合與 `BUNDLE_RUNTIME_PATHS` 不相等時 MUST 以 `init_inventory_invalid` fail closed，診斷 MUST 同時列出 missing 與 extra 兩個差集。

`cash_cli.installer` 的 import-time 相依（`installer.py` 自身、它的 `from .config import`，以及 `cash_cli/__init__.py` → `main.py` → `errors.py` 的匯入鏈，共 4 個；`cash_cli/__init__.py` 本身因 PEP 420 namespace package fallback 不屬此類）缺席時，`-m` 載入在任何檢核之前就以未捕捉的 `ModuleNotFoundError` 失敗，因此 MUST NOT 期待具名 error code；此限制與舊直譯器的 `SyntaxError` 屬同一類（import 先於任何檢查），已於 proposal Non-Goals 載明。`CASH-INIT-RECEIPT.md` MUST 明載哪些模組屬此類，且 MUST NOT 把它們列為 `init_inventory_invalid` 對照表的適用對象。

`BUNDLE_VERSION` 常數 MUST 由 contract test 斷言恆等於 `cash-skills.version` 的檔案內容；`BUNDLE_RUNTIME_PATHS` 常數 MUST 由 contract test 斷言恆等於 source 端 `source_inventory` 推導出的 runtime 路徑集合。

source repository 的 `AGENTS.md` 與 `CLAUDE.md` Cash guidance 區塊 MUST 各含一段 `--init-receipt` 指引（載明 receipt 缺失出現 `bootstrap_invalid` 時的初始化指令），使既有 guidance 部署把該指引帶到每個 target 的 managed block；target 端的發現管道由此承擔，MUST NOT 依賴 source-only 檔案（如 `CASH-SKILLS.md`）作為 target 端引導。

#### Scenario: Fresh clone 一次初始化後 CLI 可用

- **GIVEN** 一個由 git clone 取得、含完整版控 inventory 但沒有 `.cash-skills/receipt.tsv` 的 installed target
- **WHEN** 在專案根執行 `PYTHONPATH=.cash-skills/lib python3 -s -P -B -m cash_cli.installer --init-receipt`
- **THEN** 模式回報 `initialized` 並簽發逐項通過 launcher `validate_receipt` 的 receipt
- **AND** 後續 `.cash-skills/bin/cash list --json` 成功執行，不以 `bootstrap_invalid` 或 `receipt_invalid` 失敗

#### Scenario: 有效 receipt 時零寫入

- **GIVEN** target 的 receipt 與現地內容重算結果逐 byte 等價且其 mode 為 `0644`
- **WHEN** 再次執行 `--init-receipt`
- **THEN** 模式回報 `current`
- **AND** `.cash-skills/receipt.tsv` 的 bytes 不變且無 temporary 檔殘留

#### Scenario: Umask 差異被 mode 正規化吸收

- **GIVEN** 一個在 umask `002` 環境 clone 的 installed target，其 launcher checkout 為 `0775`、其餘檔案為 `0664`
- **WHEN** 執行 `--init-receipt`
- **THEN** managed inventory 的 mode 被正規化為 contract modes（launcher `0755`、其餘 `0644`）
- **AND** 簽發的 receipt 通過 launcher `validate_receipt`

#### Scenario: 失敗路徑零內容寫入

- **WHEN** `--init-receipt` 在非 worktree top-level 執行、或 `openspec/config.yaml` 缺失或 invalid、或 `.cash-workspace.lock` 或任一**非 import-time 相依**的 inventory 檔案缺失、或 `.cash-workspace.lock` 非空、或任一 managed 路徑非 regular file、或 `.cash-skills/receipt.tsv` 本身非 regular file
- **THEN** 模式以對應的具名 error code 與統一 JSON 錯誤 shape 失敗（exit 1）
- **AND** 沒有任何檔案內容被建立或修改
- **AND** 模式不阻塞在任何開檔上

#### Scenario: Canonical source repository 被拒絕

- **WHEN** 在 canonical source repository 執行 `--init-receipt`
- **AND** 該 repository 的檔案 mode 為 umask `022` 或 umask `002` clone 產生的任一組
- **THEN** 模式以 `init_source_repo` 失敗
- **AND** 診斷包含 `./install-cash-skills.fish --self`
- **AND** `.cash-skills/bin/cash` 的 bytes 不因本 requirement 的任何行為而改變

#### Scenario: Runtime inventory 缺檔時 fail closed

- **GIVEN** 一個沒有 receipt 的 installed target，其 `.cash-skills/lib/cash_cli/` 少了一個 canonical runtime 模組
- **AND** 該模組不是 `cash_cli.installer` 的 import-time 相依
- **WHEN** 執行 `--init-receipt`
- **THEN** 模式以 `init_inventory_invalid` 失敗（exit 1）且診斷含該缺檔路徑
- **AND** 沒有 receipt 被建立
- **AND** 後續 `.cash-skills/bin/cash list --json` MUST NOT 因 receipt 通過驗證而以未捕捉的 `ModuleNotFoundError` 失敗

#### Scenario: Runtime inventory 多檔時 fail closed

- **GIVEN** 一個沒有 receipt 的 installed target，其 `.cash-skills/lib/cash_cli/` 多了一個不屬於 canonical 集合的 `.py`
- **WHEN** 執行 `--init-receipt`
- **THEN** 模式以 `init_inventory_invalid` 失敗（exit 1）且診斷含該多餘路徑
- **AND** 沒有 receipt 被建立，該 target 的後續 `install-cash-skills.fish --target` MUST NOT 因 record 數不符而永久失敗

#### Scenario: 版本常數受 contract test 守衛

- **WHEN** `BUNDLE_VERSION` 與 `cash-skills.version` 的內容不相等
- **THEN** contract test 以非零結束並指出兩個值
- **AND** 當 `BUNDLE_RUNTIME_PATHS` 與 source 端 `source_inventory` 推導出的 runtime 路徑集合不相等時，contract test 同樣以非零結束並指出差集

#### Scenario: 併發下以 stable lock 序列化

- **WHEN** `--init-receipt` 與 launcher 或 installer 同時對同一 target 執行
- **THEN** `--init-receipt` 在取得 `.cash-workspace.lock` 的 exclusive flock 後才進行 mode 正規化、檢核與簽發
- **AND** receipt 的發佈維持 atomic，任何併發讀取者只會看到舊或新完整內容

#### Scenario: Init 指引隨 guidance 部署到達 target

- **GIVEN** source repository 的 `AGENTS.md` 與 `CLAUDE.md` Cash guidance 區塊含 `--init-receipt` 指引段
- **WHEN** installer 對任一 target 完成安裝或更新
- **THEN** 該 target 的 `AGENTS.md` 與 `CLAUDE.md` managed guidance block 含同段指引
- **AND** target 端使用者在 `bootstrap_invalid` 情境下可由該指引得知初始化指令

#### Scenario: Inventory 未擴充使既有 targets 正常升級

- **GIVEN** 既有 registry targets 持有前一版本簽發的 receipt
- **WHEN** 新版本以 `--all` 部署
- **THEN** 每個 target 的既有 receipt 以相同 record 集合正常解析並走 update 路徑
- **AND** 沒有 target 因 record 集合不符而以 execution error 失敗
