# Cash receipt 初始化（`--init-receipt`）

本文件說明 `cash_cli.installer` 的 target-side 模式 `--init-receipt`：它讓一個已安裝 Cash 的專案在 `git clone` 之後，不需要取得 canonical source repository 的存取權，就能在本機簽發 `.cash-skills/receipt.tsv` 並開始使用 `.cash-skills/bin/cash`。

讀者是本 repository 的維護者，以及需要替隊友排除 `bootstrap_invalid` 的人。target 端的 agent 引導另由部署到每個 target 的 `AGENTS.md`／`CLAUDE.md` managed block 承擔。

## 什麼時候需要它

`.cash-skills/receipt.tsv` 記錄 target 上 launcher 與 workspace lock 的 `st_dev`／`st_ino`，是機器特定的資料，因此被 `.gitignore` 排除（見 [`CASH-SKILLS.md`](CASH-SKILLS.md) 的「Target 版控排除保護」）。結果是：

| 隨 git clone 取得 | 不隨 git clone 取得 |
| --- | --- |
| `.cash-skills/bin/cash`（launcher） | `.cash-skills/receipt.tsv` |
| `.cash-skills/lib/cash_cli/`（runtime） | |
| `.cash-workspace.lock` | |
| 24 個 canonical `SKILL.md` | |

launcher 的主流程無條件執行 `validate_receipt`，receipt 缺席時以 `bootstrap_invalid` fail closed：

```
error[bootstrap_invalid]: /path/to/project/.cash-skills/receipt.tsv: [Errno 2] No such file or directory
```

`--init-receipt` 就是用來補上這一步的。它適用於：

- 隊友 clone 了一個已安裝 Cash 的專案，第一次要使用 `cash`。
- CI 或 sandbox 每次都從乾淨 clone 開始。
- 同一份 checkout 被複製到別的機器或別的 inode（receipt 記錄的 identity 因此失效）。

它**不**適用於 canonical source repository（也就是本 repo）——那裡請用 `./install-cash-skills.fish --self`，`--init-receipt` 會主動拒絕。

## 指令與前提

在**專案根目錄**執行：

```fish
PYTHONPATH=.cash-skills/lib python3 -s -P -B -m cash_cli.installer --init-receipt
```

三個直譯器 flag 都是必要的，不是裝飾：

- `-P` — 不把 cwd 放進 `sys.path`。少了它，專案根目錄下任何與 stdlib 同名的 `.py`（`uuid.py`、`json.py`、`stat.py`⋯）會在 import 期就被執行，早於 Python 版本檢查與 source-repo 檢查，使用者只會看到 traceback，完全繞過 JSON 錯誤契約。
- `-s` — 不載入 user site-packages，與 `install-cash-skills.fish` 的隔離等級一致。
- `-B` — 不寫 bytecode 快取。少了它，連失敗路徑都會在 target 內留下 `.cash-skills/lib/cash_cli/__pycache__/*.pyc`。

前提：

- **Python 3.11+**。更舊的直譯器會在 `-m` 載入期就以 `SyntaxError` traceback 失敗，不會產生具名錯誤——這是已知且刻意接受的限制。可達 `__main__` 的情形由 `init_python_version` 涵蓋。
- **`cash_cli.installer` 的 import-time 相依必須存在**：`installer.py`（`-m` 的目標模組）、`config.py`（`installer.py` 直接匯入），以及 `main.py` 與 `errors.py`（套件 `__init__` 的匯入鏈）。這四個缺席時，`-m` 載入在任何檢核之前就以 `No module named` 失敗（stderr，無 stdout JSON），**不會**有具名 error code，也不會走到下面的 `init_inventory_invalid` 對照表——處置方式是修好 checkout 讓該檔存在。其餘 15 個 canonical runtime 模組的增減則由 `init_inventory` 以 `init_inventory_invalid` 具名回報。
- **必須在 Git worktree top-level 執行**。`PYTHONPATH=.cash-skills/lib` 是相對路徑，從子目錄執行會先撞到 `ModuleNotFoundError: No module named 'cash_cli'` 而不是具名錯誤。
- `--init-receipt` 與 `--self`、`--target`、`--register`、`--unregister`、`--list`、`--all`、`--force`、`--dry-run` 互斥，同時給會以 exit `2` 拒絕。

## 輸出與結果碼

成功時輸出**單行**到 stdout，exit `0`：

| 輸出 | 意義 |
| --- | --- |
| `initialized` | 已簽發 receipt（原本缺席、內容不符，或 mode 已漂移） |
| `current` | 既有 receipt 的 bytes 與 mode `0644` 都已正確，**零寫入** |

失敗時輸出統一 JSON shape 到 **stdout**（不是 stderr），exit `1`：

```json
{"error":{"code":"init_inventory_invalid","message":"managed path is missing: .claude/skills/cash-ask/SKILL.md"}}
```

沒有 `--json` flag——init 模式的輸出形式是固定的。

## 錯誤診斷對照表

以下訊息皆為實測輸出。

### `init_python_version`

```
Cash receipt initialization requires Python 3.11+
```

直譯器版本過舊但仍能載入模組。改用 `python3.11` 以上的直譯器。

### `init_outside_worktree`

```
--init-receipt must run from the Git worktree top-level: /private/tmp/example
```

cwd 不是 Git worktree 的 top-level，訊息中的路徑是 git 回報的實際 top-level——`cd` 過去再執行即可。

```
--init-receipt must run from the Git worktree top-level
```

沒有路徑後綴代表 `git rev-parse --show-toplevel` 整個失敗：這裡不是 Git repository，或 `git` 不在 PATH 上。

> 若你從子目錄執行且用的是相對 `PYTHONPATH`，會先看到 `ModuleNotFoundError: No module named 'cash_cli'`——那不是本模式的錯誤契約，而是 Python 根本沒載入到 runtime。回到專案根目錄執行。

### `init_source_repo`

```
this is the canonical Cash source repository; run ./install-cash-skills.fish --self from the project root
```

偵測到 canonical source layout。改用 `./install-cash-skills.fish --self`。

判定條件是 source-only marker（`install-cash-skills.fish`、`cash-skills.version`、`.cash.yaml`、`openspec/config.yaml`、`CASH-SKILLS.md`、`scripts/cash-skills/legacy-spectra-digests.tsv`）、runtime core 四個檔案與 24 個 canonical skill 的**存在與 regular-file 形狀**，加上可解析的 `cash-skills.version`。它刻意**不**比對 contract mode——這些 marker 都不在 mode 正規化的涵蓋範圍內，若比對 mode，umask `002` clone 的 source repo 會被誤判成一般 target 而被簽發 receipt。

### `init_config_invalid`

```
invalid openspec/config.yaml: openspec/config.yaml: line 1: unsupported openspec config syntax
```

```
invalid openspec/config.yaml: cannot open regular file openspec/config.yaml: [Errno 2] No such file or directory: '...'
```

`openspec/config.yaml` 缺席、不是安全可讀的 regular file，或 schema 不合法。修好該檔再重跑。`--init-receipt` **不會**代為建立它——建立預設 config 是 `install-cash-skills.fish --target` 的職責。

### `init_inventory_invalid`

managed inventory 或 stable workspace lock 的形狀有問題。常見訊息：

| 訊息 | 原因與處置 |
| --- | --- |
| `managed path is missing: <path>` | 該檔在 clone 中缺席。用 `git status` 確認是否被誤刪，或請維護者重跑 `install-cash-skills.fish --target`。 |
| `stable workspace lock must be an empty regular file: .cash-workspace.lock` | lock 被寫入了內容。它契約上必須是空檔；init 刻意不代為修復 stable 檔案，請用版本控制還原。 |
| `symlink managed boundary: <path>` | managed 路徑上有 symlink。還原成真實檔案。 |
| `unsafe managed file identity: <path>` | 該路徑不是 regular file，或是 hard link（`st_nlink != 1`）。 |
| `runtime inventory does not match the canonical set: missing=[...] extra=[...]` | 現地的 `.cash-skills/lib/cash_cli/**.py` 集合與 canonical 集合不符。見下方說明。 |

**runtime inventory 不符**是最需要理解的一則。init 不會拿現地檔案跟自己比對——那樣比對恆真、缺檔與多檔都不會被發現。期望集合來自 installer module 內嵌的 `BUNDLE_RUNTIME_PATHS` 常數，診斷同時列出兩個差集：

```
{"error":{"code":"init_inventory_invalid","message":"runtime inventory does not match the canonical set: missing=['.cash-skills/lib/cash_cli/spec_merge.py'] extra=[]"}}
```

- `missing` 非空：clone 少了 runtime 模組。常見原因是該專案的 `.gitignore` 意外涵蓋了某個檔名（`spec_merge.py`、`tasks.py`、`search.py`、`archive.py`、`validation.py` 這類通用名稱特別容易中）。用 `git status --ignored` 確認，修好 `.gitignore` 後重新 checkout。
- `extra` 非空：`.cash-skills/lib/cash_cli/` 下多了不屬於 bundle 的 `.py`。移除它——若放著不管而 receipt 被簽發，該 target 的 `install-cash-skills.fish --target`／`--all` 會自此永久以 `receipt has an invalid record count` 失敗，且 `--force` 不可繞過。

這個檢核存在的理由：少檔時 receipt 本身仍然自洽，launcher 的 `validate_receipt` 會通過（它只驗證 receipt 已列出的 record，從不枚舉 runtime 目錄），於是 CLI 會在真正執行時以未捕捉的 `ModuleNotFoundError` traceback 死掉，使用者拿不到任何具名錯誤。

失敗時**不會**有任何檔案內容被建立或修改。形狀檢核與 mode 正規化分兩趟進行，因此形狀不安全時連一次 `chmod` 都不會發生。

### `init_write_failed`

```
unsafe regular file identity: .cash-skills/receipt.tsv
```

`.cash-skills/receipt.tsv` 存在但不是 regular file（例如是 FIFO 或目錄）。刪掉它再重跑。

形狀在任何開檔之前就以 `lstat` 判定——此時 exclusive flock 已被持有，若對 FIFO 開檔會無限阻塞，整個 workspace 的後續 `cash` 指令都會一併卡在 launcher 的 `flock`，因此這裡必須 fail closed 而非阻塞。

其他情形：`.cash-skills` 不是真實目錄，或 atomic rename 寫入失敗（磁碟滿、唯讀掛載、權限不足）。

## 它實際做了什麼

依序，任一步失敗即以對應的具名 code fail closed：

1. 檢查 Python 3.11+。
2. 驗證 cwd 是 Git worktree top-level。
3. 拒絕 canonical source repository。
4. 驗證 `openspec/config.yaml` 安全可讀且 schema-valid。
5. 確認 `.cash-workspace.lock` 是既存、空的 regular file，取 **exclusive flock 並全程持有**。
6. 檢核 runtime inventory 完整性：期望集合取自內嵌的 `BUNDLE_RUNTIME_PATHS`，與現地集合不符即 fail closed，並在診斷列出 `missing` 與 `extra` 兩個差集。這一步排在 mode 正規化之前，所以 runtime 集合不符時連一次 `chmod` 都不會發生。stable 與 24 個 skill 的存在性與形狀檢核則與下一步同趟進行。
7. 把 managed inventory 的 mode 正規化為 contract modes。
8. 從現地 bytes 計算 digests、以本機 no-follow `lstat` 取 stable identity，組出 receipt。
9. 與既有 receipt 比對：bytes 與 mode 皆一致則回報 `current` 零寫入；否則以 same-directory temporary 加 atomic rename 簽發，回報 `initialized`。

**mode 正規化**是「clone 即用」不依賴特定 umask 的關鍵。git checkout 產生的 mode 是 `0666/0777 & ~umask`，在 umask `002` 的群組協作環境會 checkout 出 launcher `0775`、其餘 `0664`，而 launcher 的自檢與 receipt 的 contract mode 都要求精確值。步驟 7 用 no-follow 開檔加 `fchmod` 把它們收斂回契約值，只改 metadata、不動任何 bytes。

**寫入面保證**：所有失敗路徑零檔案內容寫入；成功路徑唯一的內容寫入是 receipt 本身。步驟 7 的 `chmod` 是唯一的 metadata 修改，且僅及 managed inventory。（若 `chmod` syscall 本身在中途失敗——唯讀掛載、他人擁有的檔案——可能留下部分正規化的 metadata；內容零寫入的保證不受影響。）

## 信任模型

這是 `--init-receipt` 與 installer 安裝路徑最重要的差別，值得明確理解。

installer 簽發的 receipt 證明「這份安裝來自 canonical installer」。`--init-receipt` 簽發的 receipt **不證明這件事**——它的信任根是 git clone 的現地內容。執行它等同於使用者主動宣告「我信任版控裡的這份內容」，provenance 由 git 歷史承擔。

推論有三：

1. init 執行時 import 的 `cash_cli` runtime 本身尚未經 receipt 驗證，這屬於同一個信任宣告的一部分。
2. 對一個已經 drift 的 target 重跑 init，會把該 drift 合法化。這是使用者主動的明示動作，與 `install-cash-skills.fish --force` 同級。替換無效的舊 receipt 時會在 **stderr** 印出 warning（stdout 仍只有 `initialized` 一行）：

   ```
   /path/to/project: replacing an invalid .cash-skills/receipt.tsv: receipt has an invalid record count
   ```

3. launcher **從不**在 receipt 缺失或無效時自動觸發 init。自動修復會使「receipt 缺失」從可疑狀態變成正常狀態，竄改者只要刪掉 receipt 就能觸發重簽，drift 偵測歸零。

簽發之後，receipt 維持它既有的職責：偵測簽發後的本機 drift 與竄改。

## 與 `install-cash-skills.fish` 各模式的關係

| 模式 | 在哪裡執行 | 需要 source repo | 用途 |
| --- | --- | --- | --- |
| `--self` | canonical source repo | — | 重建 source repo 自己的 receipt |
| `--target <project>` | source repo | 是 | 安裝或升級一個 target |
| `--register` / `--unregister` / `--list` | source repo | 是 | 維護 `$HOME/.config/cash-skills/projects.txt` |
| `--all` | source repo | 是 | 對 registry 中全部 target 批次安裝／升級 |
| `--init-receipt` | **target 專案根** | **否** | 在本機簽發 target 的 receipt |

`--init-receipt` 是唯一不需要 source repo 的模式，也是唯一從 target 端執行的模式。它**不會**安裝、升級或修復任何 managed 檔案內容——那始終是 `--target` 的職責。

receipt 首行的 `version` 取自 installer module 內嵌的 `BUNDLE_VERSION` 常數，因為 `cash-skills.version` 是 source-only 檔、target 上並不存在。`scripts/cash-skills/tests/test_installer_runtime.py` 以 contract test 斷言該常數恆等於 `cash-skills.version` 的內容，避免雙真相來源漂移。

## FAQ

**Q：init 簽發的 receipt 和 installer 寫的一樣嗎？**

一模一樣。在同版本的 target 上，`--init-receipt` 產生的 `.cash-skills/receipt.tsv` 與 `install-cash-skills.fish --target` 寫出的檔案逐 byte 相同，之後再跑 installer 會回報 `Result: current`。

**Q：可以重複執行嗎？**

可以。receipt 已正確時回報 `current` 且零寫入，bytes、inode、mtime 都不變。

**Q：bytes 對但 mode 不對會怎樣？**

回報 `initialized` 並重寫。launcher 以 `open_regular(receipt_path, 0o644)` 對 receipt 設有 mode 閘門，只比 bytes 就回報 `current` 會留下「工具說成功、CLI 仍不可用」的狀態。

**Q：和別人同時跑會衝突嗎？**

不會。它在 mode 正規化、inventory 檢核與簽發之前取得 `.cash-workspace.lock` 的 exclusive flock 並全程持有（見上面步驟表的第 5 步），與 launcher 和 installer 使用同一個 inode 上的同一套協定。取鎖之前的四個步驟——Python 版本檢查、worktree top-level 驗證、source-repo 偵測、`openspec/config.yaml` 驗證——都是唯讀的，且在無鎖狀態下執行。receipt 的發佈是 atomic rename，併發讀取者只會看到舊的或新的完整內容。

**Q：需要新增檔案或改 launcher 嗎？**

都不需要。init 邏輯嵌在既有的 runtime record `.cash-skills/lib/cash_cli/installer.py` 裡，隨既有的安裝與升級路徑部署到所有 target。bundle inventory 沒有擴充，receipt 的 record 集合與 schema 沒有改變，`.cash-skills/bin/cash` 逐 byte 不變。

**Q：`--dry-run` 呢？**

不支援，會以 exit `2` 拒絕。當 receipt 已正確時 `--init-receipt` 本身就是零寫入的，直接跑即可。

## 相關文件

- [`CASH-SKILLS.md`](CASH-SKILLS.md) — bundle 版本、installer 入口、Target 版控排除保護、團隊 onboarding
- `AGENTS.md`／`CLAUDE.md` 的 `<!-- CASH:START -->` block — 隨 installer 部署到每個 target 的 agent 引導
- `openspec/specs/cash-cli/spec.md` — `Target-local receipt 初始化` requirement 的規範性條文
