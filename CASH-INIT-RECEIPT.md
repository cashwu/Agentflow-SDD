# Cash receipt 初始化（`--init-receipt`）

本文件說明 `cash_cli.installer` 的 target-side 模式 `--init-receipt`。它只適用於沒有 `.cash-skills/manifest.tsv` 的 receipt-only direct／legacy target：使用者不需要取得 canonical source repository 的存取權，即可在本機簽發 `.cash-skills/receipt.tsv`。

讀者是本 repository 的維護者，以及需要替隊友排除 `bootstrap_invalid` 的人。target 端的 agent 引導另由部署到每個 target 的 `AGENTS.md`／`CLAUDE.md` managed block 承擔。

## 先判斷信任模式

launcher 依 `.cash-skills/manifest.tsv` path 是否存在選擇互斥的信任 gate：

| target 狀態 | launcher 行為 | 操作 |
| --- | --- | --- |
| `.cash-skills/manifest.tsv` 存在 | 只走 portable manifest gate；ignored 的舊 receipt 不會遮蔽 manifest | clone／pull 後直接使用 `.cash-skills/bin/cash`，不要執行 `--init-receipt` |
| manifest 缺失、receipt 存在 | 走 receipt gate | receipt 有效時直接使用；出現 stable record identity drift 的 `receipt_invalid` 時執行 `--init-receipt`，其他無效狀態由 canonical source 的 direct／registry workflow 更新 |
| manifest 與 receipt 都缺失 | 以 `bootstrap_invalid` fail closed | 只有已確認為 receipt-based direct／legacy target 時才執行 `--init-receipt` |

manifest path 只要存在就選擇 portable gate；broken symlink、FIFO、directory 或其他 unsafe shape 也算存在，會以 `manifest_invalid` fail closed，絕不 fallback 到 receipt。

`.cash-skills/receipt.tsv` 記錄 target 上 launcher 與 workspace lock 的 `st_dev`／`st_ino`，是機器特定資料，因此被 `.gitignore` 排除。identity 比對只用 digest、mode 與 `st_ino` 三項；`st_dev` 是 mount 時配發的 volume 編號而非檔案屬性，不參與比對，只作為 machine-local provenance 保留並受形狀閘門（device 非負、inode 為正）約束。這只影響 receipt-based target；repo-vendored target 透過提交到 Git 的 portable manifest 攜帶信任資料。

`--init-receipt` 適用於下列情形，且**每一項都以同一個前提為條件**：`.cash-skills/receipt.tsv` 是 machine-local identity，被納入版控時必須先執行 `git rm --cached .cash-skills/receipt.tsv` 解除追蹤，再重新簽發。取得方式本身不構成可以重新簽發的理由。

- 隊友 clone 了一個 receipt-only direct／legacy target，且 checkout 沒有 receipt。
- receipt-based CI 或 sandbox 每次都從乾淨 clone 開始。
- receipt-based checkout 被複製到別的機器或別的 inode，舊 receipt identity 因此失效。
- launcher 以 `receipt_invalid` 回報 `stable record identity drift:`，或 installer 以 `Error: stable receipt identity drift:` 失敗（installer 不輸出 error code）：digest 相符而 mode 或 `st_ino` 不符，檔案內容可證明仍是 receipt 記錄的那份，重新簽發不引入新的信任。指引只在同一份 receipt 中該 gate 本來就會驗證的其餘 records 全數相符時才出現；否則診斷會同時指名該 stable path 與漂移的 record，下一步是把該筆 record 還原成 receipt 記錄的內容後重試，或從可信 source 重新安裝。

它不適用於：

- stable record content drift：digest 與記錄值不符代表內容本身已改變，重新簽發會以現地 bytes 覆寫 receipt，等同把漂移合法化。診斷不會建議 `--init-receipt`；處置是還原該筆 record 或從可信 source 重新安裝。
- repo-vendored target：改由 canonical source 執行 `./install-cash-skills.fish --vendor <project>` 安裝或更新；target 端的 `--init-receipt` 會以 `init_vendored_bundle` 拒絕。
- canonical source repository（也就是本 repo）：執行 `./install-cash-skills.fish --self` 同步 canonical portable manifest 並清除 source receipt residue；`--init-receipt` 會以 `init_source_repo` 拒絕。

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
- `--init-receipt` 與 `--self`、`--target`、`--vendor`、`--register`、`--unregister`、`--list`、`--all`、`--force`、`--dry-run` 互斥，同時給會以 exit `2` 拒絕。

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

### `init_vendored_bundle`

```
target is managed by a portable manifest; --init-receipt is not allowed
```

非source target 的 portable manifest path 已存在。無論 manifest 是 valid 或 unsafe shape，`--init-receipt` 都不讀取、不建立、不修改也不刪除 receipt，並以 exit `1` fail closed。請直接使用 valid vendored bundle；若 manifest 或受管內容無效，請由 canonical source 明示執行 `./install-cash-skills.fish --vendor <project>` 處理，不得用 receipt fallback 掩蓋問題。

此檢查會做兩次：第一次在 target preflight，第二次在取得 `.cash-workspace.lock` 的 exclusive flock 後、任何 mode 正規化、inventory open 或 receipt publication 之前。若併發 publisher 在兩次檢查間建立 manifest，第二次檢查仍以 `init_vendored_bundle` 零內容寫入拒絕。

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
4. 以 no-follow `lstat` 拒絕任何 portable manifest present shape。
5. 驗證 `openspec/config.yaml` 安全可讀且 schema-valid。
6. 確認 `.cash-workspace.lock` 是既存、空的 regular file，取 **exclusive flock 並全程持有**。
7. 取鎖後再次以 no-follow `lstat` 確認 portable manifest 仍缺失。
8. 檢核 runtime inventory 完整性：期望集合取自內嵌的 `BUNDLE_RUNTIME_PATHS`，與現地集合不符即 fail closed，並在診斷列出 `missing` 與 `extra` 兩個差集。這一步排在 mode 正規化之前，所以 runtime 集合不符時連一次 `chmod` 都不會發生。stable 與 24 個 skill 的存在性與形狀檢核則與下一步同趟進行。
9. 把 managed inventory 的 mode 正規化為 contract modes。
10. 從現地 bytes 計算 digests、以本機 no-follow `lstat` 取 stable identity，組出 receipt。
11. 與既有 receipt 比對：bytes 與 mode 皆一致則回報 `current` 零寫入；否則以 same-directory temporary 加 atomic rename 簽發，回報 `initialized`。

**mode 正規化**讓 receipt-only clone 不依賴特定 umask。git checkout 產生的 mode 是 `0666/0777 & ~umask`，在 umask `002` 的群組協作環境會 checkout 出 launcher `0775`、其餘 `0664`，而 receipt gate 的 contract mode 要求精確值。步驟 9 用 no-follow 開檔加 `fchmod` 把它們收斂回契約值，只改 metadata、不動任何 bytes。portable gate 則比較 Git logical mode（`100755`／`100644`），不要求完整 POSIX mode 精確相等。

**寫入面保證**：所有失敗路徑零檔案內容寫入；成功路徑唯一的內容寫入是 receipt 本身。步驟 9 的 `chmod` 是唯一的 metadata 修改，且僅及 managed inventory。（若 `chmod` syscall 本身在中途失敗——唯讀掛載、他人擁有的檔案——可能留下部分正規化的 metadata；內容零寫入的保證不受影響。）

## 信任模型

這是 receipt-only `--init-receipt` 與 portable manifest 最重要的差別，值得明確理解。

installer 簽發的 receipt 證明「這份安裝來自 canonical installer」。`--init-receipt` 簽發的 receipt **不證明這件事**——它的信任根是 git clone 的現地內容。執行它等同於使用者主動宣告「我信任版控裡的這份內容」，provenance 由 git 歷史承擔。

推論有三：

1. init 執行時 import 的 `cash_cli` runtime 本身尚未經 receipt 驗證，這屬於同一個信任宣告的一部分。
2. 對一個已經 drift 的 target 重跑 init，會把該 drift 合法化。這是使用者主動的明示動作，與 `install-cash-skills.fish --force` 同級。替換無效的舊 receipt 時會在 **stderr** 印出 warning（stdout 仍只有 `initialized` 一行）：

   ```
   /path/to/project: replacing an invalid .cash-skills/receipt.tsv: receipt has an invalid record count
   ```

3. launcher **從不**在 receipt 缺失或無效時自動觸發 init。自動修復會使「receipt 缺失」從可疑狀態變成正常狀態，竄改者只要刪掉 receipt 就能觸發重簽，drift 偵測歸零。

簽發之後，receipt 維持它既有的職責：偵測簽發後的本機 drift 與竄改。

repo-vendored target 不使用 machine-local stable identity作為啟動 gate。portable manifest 記錄受管 inventory 的 digest 與 Git logical mode，provenance 由 repository commit／review history承擔；能同時改寫 manifest 與受管檔案的 working-tree writer 仍可建立新的自洽狀態，因此 portable manifest 不是簽章。

## 與 `install-cash-skills.fish` 各模式的關係

| 模式 | 執行位置 | 管理的信任模式 | `--dry-run` | `--force` | 用途 |
| --- | --- | --- | --- | --- | --- |
| `--self` | canonical source repo | portable source | 支援 | 不支援 | 在同一 stable lock transaction 同步 canonical manifest、清除 source receipt residue；不發布 launcher、runtime、skills、config 或 guidance |
| `--vendor <project>` | canonical source repo | portable target | 支援 | 支援 | 發布／更新 repo-vendored bundle，或明示把 valid receipt target 轉為 portable mode |
| `--target <project>` | canonical source repo | receipt target | 支援 | 支援 | direct 安裝／升級 receipt-based target；遇到 portable manifest 時拒絕並指向 `--vendor` |
| `--register <project>` / `--unregister <project>` / `--list` | canonical source repo | receipt registry | 不支援 | 不支援 | 維護 `$HOME/.config/cash-skills/projects.txt`；不得把 vendored target 納入 receipt workflow |
| `--all` | canonical source repo | receipt registry targets | 支援 | 支援 | 對 registry 中全部 receipt-based target 批次安裝／升級 |
| `--init-receipt` | receipt-only target 專案根 | receipt target | 不支援 | 不支援 | 從現地已安裝 inventory 簽發 machine-local receipt |

`--init-receipt` 是唯一不需要 source repo 且從 target 端執行的模式。它不會安裝、升級或修復任何 managed 檔案內容；receipt target 的內容更新由 `--target`／`--all` 負責，vendored target 則由 `--vendor` 負責。

receipt 首行的 `version` 取自 installer module 內嵌的 `BUNDLE_VERSION` 常數，因為 `cash-skills.version` 是 source-only 檔、target 上並不存在。`scripts/cash-skills/tests/test_installer_runtime.py` 以 contract test 斷言該常數恆等於 `cash-skills.version` 的內容，避免雙真相來源漂移。

## FAQ

**Q：init 簽發的 receipt 和 installer 寫的一樣嗎？**

在同版本、同一現地 identity 的 receipt target 上，兩條路徑使用相同 schema 與 record inventory。`--init-receipt` 由現地 bytes、contract mode 與 stable identity重算 receipt；之後 direct installer 會依完整 baseline 分類。

**Q：可以重複執行嗎？**

可以。receipt 已正確時回報 `current` 且零寫入，bytes、inode、mtime 都不變。

**Q：bytes 對但 mode 不對會怎樣？**

回報 `initialized` 並重寫。launcher 以 `open_regular(receipt_path, 0o644)` 對 receipt 設有 mode 閘門，只比 bytes 就回報 `current` 會留下「工具說成功、CLI 仍不可用」的狀態。

**Q：和別人同時跑會衝突嗎？**

不會。它在 mode 正規化、inventory 檢核與簽發之前取得 `.cash-workspace.lock` 的 exclusive flock 並全程持有（見上面步驟表的第 6 步），與 launcher 和 installer 使用同一個 inode 上的同一套協定。取鎖之前的五個步驟——Python 版本檢查、worktree top-level 驗證、source-repo 偵測、portable manifest preflight、`openspec/config.yaml` 驗證——都是唯讀的，且在無鎖狀態下執行。取鎖後會先重驗 manifest 仍缺失；receipt 的發佈是 atomic rename，併發讀取者只會看到舊的或新的完整內容。

**Q：需要新增檔案或改 launcher 嗎？**

`--init-receipt` 只會簽發 receipt，並在需要時正規化既有 managed inventory 的 mode；它不會改寫 launcher 或其他 managed 檔案內容。launcher 的版本更新屬於 canonical installer 的受控 migration，可能由 `--target` 或 `--vendor` 在 exact transition、exclusive lock 與 recoverable journal 契約下進行。portable manifest 不加入 receipt inventory，receipt 的 record 集合與 schema 維持不變。

**Q：`--dry-run` 呢？**

不支援，會以 exit `2` 拒絕。當 receipt 已正確時 `--init-receipt` 本身就是零寫入的，直接跑即可。

## 相關文件

- [`CASH-SKILLS.md`](CASH-SKILLS.md) — bundle 版本、installer 入口、Target 版控排除保護、團隊 onboarding
- `AGENTS.md`／`CLAUDE.md` 的 `<!-- CASH:START -->` block — 隨 installer 部署到每個 target 的 agent 引導
- `openspec/specs/cash-cli/spec.md` — `Target-local receipt 初始化` requirement 的規範性條文
