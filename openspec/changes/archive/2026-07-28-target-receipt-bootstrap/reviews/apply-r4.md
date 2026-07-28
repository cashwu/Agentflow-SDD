# Cash Apply Review — Round 4

本輪是 round 3 以 Fix-loop design circuit breaker `aborted` 之後的 **seeded re-run 的第一輪**。round 編號續接既有最高號，run 內位置為第 1 輪，故 `round_type` 為 `full`；cumulative blocking set 以 round 3 Abort triage 的 bucket 1 三項 seed（S1／S2／S3）。

## Reviewer Findings

### Critical

無。

### Warning

1. **severity**: `Warning`｜**confidence**: `100`｜**layer**: `design`｜**disposition**: `fix-introduced`｜**reviewer**: B — Quality
   - **location**: `.cash-skills/lib/cash_cli/installer.py`（`init_inventory` 相對於套件 import 鏈的執行時點）；`specs/cash-cli/spec.md` Scenario「Runtime inventory 缺檔時 fail closed」；`design.md` Implementation Contract 第 12 項；`CASH-INIT-RECEIPT.md` 的 `init_inventory_invalid` 說明段
   - **introduced_by**: 本次 seeded re-run 對 round 3 finding 1 的修復（tasks 7.2／7.4／7.6 新增的期望集合比對、spec 新增的兩個 runtime Scenario、Contract 第 12 項，以及 `CASH-INIT-RECEIPT.md` 新增的說明段——該段逐字把 `config.py` 列為常見受害檔名）
   - **summary**: 新的期望集合檢核並未涵蓋全部 19 個 canonical runtime 模組；import-time 相依缺席時 `-m` 載入即失敗，永遠走不到 `init_inventory`。spec Scenario 以全稱敘述涵蓋「任一 canonical runtime 模組」對這些成員為假，而文件恰恰把其中一個列為最可能被 `.gitignore` 誤吞的檔名，指向一條對它永不觸發的排錯路徑
   - **recommendation**: 以 artifact 對齊解決——收斂 spec Scenario 與 Contract 第 12 項的全稱敘述、於 proposal Non-Goals 明載此類 import-time 失敗、修正文件的受害檔名清單並新增前提說明；另把測試改為參數化涵蓋全部成員，使不對稱在套件內可見
   - **evidence（主 agent 已獨立重現）**: 於 `/tmp` fixture 逐一移走 7 個 runtime 模組後執行文件化指令：`resources`／`spec_merge`／`validation`／`workspace` → `init_inventory_invalid` 具名 error code；`config`／`errors`／`main` → `ModuleNotFoundError` traceback、stdout 無任何 JSON。**主 agent 在實作參數化測試時另發現 reviewer 漏算的第 4 個成員**：`installer.py` 自身亦為 import-time 相依（`-m cash_cli.installer` 需要它才能載入），移走後為 `No module named cash_cli.installer`。因此正確分類為 15 個具名 error code ／ 4 個 import-time
   - **failure_scenario**: target 專案的 `.gitignore` 含一行 `config.py`（用於隱藏本地設定，極常見）→ 隊友 clone 得到缺該檔的 checkout → 依部署到該 target 的 managed block 指引執行 `--init-receipt` → stdout 空、stderr traceback、exit 1，拿不到任何具名 error code，而文件的排錯路徑正以 `config.py` 為例卻永不觸發

### Suggestion

2. **severity**: `Suggestion`｜**confidence**: `100`｜**layer**: `design`｜**disposition**: `new`｜**reviewer**: A — Adherence
   - **location**: `.cash-skills/lib/cash_cli/installer.py`（`init_receipt` 的 `init_inventory` → `init_normalize_modes` 呼叫序）vs. `specs/cash-cli/spec.md` 第 7 段、`design.md` D3 步驟 6／7、`CASH-INIT-RECEIPT.md` 步驟表
   - **summary**: spec 以 `MUST 依序` 把 mode 正規化列在 inventory 完整性檢核之前，design 與文件亦編為步驟 6／7，但實作順序相反（`init_inventory` 先於 `init_normalize_modes`）
   - **recommendation**: 以程式碼為準修訂 artifact——實作順序較 artifact 所述更 fail-closed（runtime 集合不符時連一次 `chmod` 都不會發生），不應反向改碼
   - **evidence**: `init_receipt()` 內逐字為 `inventory = init_inventory(root)` → `init_normalize_modes(root, inventory)`；主 agent 已獨立複核。此 finding 由 reviewer 標為 `Warning`／`disposition: new`，經 confidence filter 後在 seeded re-run 首輪依 disposition 規則為非阻塞

3. **severity**: `Suggestion`｜**confidence**: `100`｜**layer**: `design`｜**disposition**: `new`｜**reviewer**: A — Adherence
   - **location**: `design.md` `## Implementation Contract` 第 7 項的括號舉例
   - **summary**: 舉例 `task 6.1 先於 6.2` 不是「受守衛檔案」規則的實例——task 6.2 修改的 `scripts/cash-skills/tests/skill-checks.fish` 不在 `test_bundle_version_history.py` 的 `replaceable_paths()` 守衛集合內
   - **recommendation**: 只列真正涉及受守衛檔案的配對，或改述 bump task 內部的寫入序
   - **evidence**: `replaceable_paths()` 僅涵蓋 `.cash-skills/lib/cash_cli/` 的 `rglob("*.py")` 與 24 個 `SKILL.md`，不含 `scripts/` 下任何檔案

4. **severity**: `Suggestion`｜**confidence**: `100`｜**layer**: `design`｜**disposition**: `new`｜**reviewer**: B — Quality
   - **location**: `.cash-skills/lib/cash_cli/installer.py` — `init_inventory()` 的 `__pycache__` 過濾條件
   - **introduced_by**: 本輪新增的 `init_inventory()` 中 `present` 推導
   - **summary**: 過濾檢查的是 `rglob` 產出的**絕對路徑**全部 parts，因此專案位於任何祖先目錄名為 `__pycache__` 的路徑下時，19 條 runtime 全被濾掉，init 宣告「全部缺失」而檔案其實一個不缺
   - **recommendation**: 改為只看相對於 root 的路徑
   - **evidence**: reviewer 在 `<path>/__pycache__/proj` 安裝正常 target 後執行 init，得到列出全部 19 條的 `missing`；主 agent 已於修復後差分驗證同一情境回報 `initialized`

### Cumulative blocking set 逐一判定（兩位 reviewer 一致）

| member | Reviewer A | Reviewer B | 結果 |
| --- | --- | --- | --- |
| S1 — runtime 完整性檢核恆真 | `resolved` | `resolved` | 移出。兩位皆獨立重現缺檔／多檔兩方向 fail closed、還原後 `initialized`、再跑 `current`；缺檔時 CLI 改以具名 `bootstrap_invalid` 失敗而非 traceback |
| S2 — design 行號失效 | `resolved` | `resolved` | 移出。`installer.py:` 行號零殘留；保留的兩處 launcher 行號逐行核對相符且 launcher 逐 byte 凍結 |
| S3 — Contract 第 7 項 commit 序位判準 | `resolved` | `resolved` | 移出。改為工作樹＋task 序位，各合取項實測成立；`check_history` 不檢查 commit 序位一節亦經查證 |

三個 seeded member 皆經兩位 reviewer 明確判定 `resolved` 並移出 cumulative blocking set，移除紀錄如上表（成員、fix reference、驗證 reviewer 皆已載明）。

## Rating

- post-filter cumulative blocking set Critical count：`0`
- post-filter cumulative blocking set Warning count：`1`
- 非阻塞 triaged finding count：`3`
- `critical_gap`：`false`
- `round_type`：`full`

**rationale**：seeded re-run 的第一輪以 seeded cumulative blocking set 而非「所有 surviving 皆阻塞」判定。S1／S2／S3 經兩位 reviewer 一致 `resolved` 而移出集合。新增的四筆 finding 依 disposition 規則判定：finding 1 為 `fix-introduced`，屬阻塞並進入集合；finding 2／3／4 為 `new`，非阻塞。confidence filter 未觸發任何 drop 或降級（四筆皆 `confidence: 100`），Reviewer B 的兩筆皆附可查證 `introduced_by`。集合中因此僅餘一筆阻塞 `Warning`，該筆已於本輪完整修復但尚未經 reviewer 驗證，故本輪為 `next_round` 而非 `passed`。

## Fix Actions

- **finding 1（import-time 相依未被期望集合涵蓋）已修復**，全部以 artifact 對齊處理，未改變 runtime 行為：
  - `specs/cash-cli/spec.md`：Scenario「Runtime inventory 缺檔時 fail closed」新增 `AND 該模組不是 cash_cli.installer 的 import-time 相依`；requirement 本文新增一段明載 4 個 import-time 成員 MUST NOT 期待具名 error code，且 `CASH-INIT-RECEIPT.md` MUST NOT 把它們列為 `init_inventory_invalid` 對照表的適用對象。
  - `design.md` Implementation Contract 第 12 項收斂為「19 個成員中的 15 個」，並載明 4 個 import-time 成員與參數化測試要求。
  - `proposal.md` Non-Goals 由「不處理語法層級的舊 python 直譯器失敗」擴為「不處理 import 完成之前的失敗」，涵蓋 `SyntaxError` 與 `No module named` 兩類。
  - `CASH-INIT-RECEIPT.md`：受害檔名清單移除 `config.py`（改列 `validation.py`），前提一節新增 import-time 相依說明並指出其失敗形狀。
  - `scripts/cash-skills/tests/test_init_receipt.py` 新增 `test_every_runtime_member_is_classified`，以參數化 subTest 涵蓋全部 19 個成員，逐一斷言落在具名 error code 或 import-time 失敗何者。
  - **主 agent 修正 reviewer 的分類**：reviewer 報 3 個 import-time 成員，參數化測試立即抓到第 4 個（`installer.py` 自身）。全部 artifact 與文件的計數同步為 15／4。
- **finding 4（`__pycache__` 過濾範圍）已修復**：`init_inventory` 的過濾改判 `path.relative_to(root).parts`。差分驗證：修復前於 `<base>/__pycache__/proj` 執行 init 回報 19 條全部 missing，修復後回報 `initialized` 且 launcher exit 0。修改檔案：`.cash-skills/lib/cash_cli/installer.py`。
- **finding 2（步驟順序）已修復**：以程式碼為準修訂三份 artifact——`design.md` D3 步驟 6／7 對調（6 = runtime 完整性檢核，7 = mode 正規化），全部 `步驟 6`／`D3-6` 交叉引用同步；`specs/cash-cli/spec.md` 第 7 段的 `MUST 依序` 敘述改為完整性檢核先於 mode 正規化並加註「MUST 先於」的理由；`CASH-INIT-RECEIPT.md` 步驟表與其後兩處 `步驟 6` 引用同步。
- **finding 3（Contract 第 7 項舉例）已修復**：括號舉例改為只列受守衛檔案配對（`task 1.1 先於 2.1`、`task 7.1 先於 7.2`），並補述 bump task 內部以版本檔先寫入為序。
- **部署時序規則第三次適用**：finding 4 的修復觸及 `installer.py`，而 2.10.0 已由 `--all` 綁定散佈到 8 個 targets，因此先將 `cash-skills.version` 與 `BUNDLE_VERSION` 同步遞增為 2.11.0（版本檔先寫入），再修改該檔。`design.md` D2、Contract 第 7 項、部署時序規則段與 `proposal.md` 的部署敘述皆同步為 2.11.0。收尾 `--self` 後 `--all` 回報 8/8 `updated`，各 target receipt version 為 2.11.0 且 `installer.py` digest 與 source 一致。
- **spec 結構修正**：新增的 import-time 段落原本落在兩個 `#### Scenario:` 之間，已移至 requirement 本文區（`BUNDLE_VERSION` contract test 段之前），使 Scenario 區塊不夾雜散文。
- **analyzer 誤判處理**：`cash analyze` 把 Non-Goals 散文中的 `cash_cli/__init__.py` 誤判為未被 task 覆蓋的 Impact path（該路徑不在 `## Impact` 區段）。改以「套件 `__init__` 匯入鏈」表述後 non-Suggestion findings 歸零，語意不變。
- **round 3 計數更正（不改寫 round file）**：round 3 finding 1 的 evidence 與 signal `expected-set-derived-from-observed-state` 記「receipt 只有 19 筆 runtime（正常 20 筆）」，實際為 18／19——當時以 `grep -c '^runtime'` 一併數到了 `runtime_generation` 行。缺陷判定與重現不受影響。completed round file 屬 immutable gate input 故未改寫；更正已寫入本輪兩位 reviewer 的 context，並於本輪一併修正該 signal 的敘述。
- **reviewer 操作事故的獨立驗證**：Reviewer B 主動揭露它有一次 `cd` 到 `/tmp` fixture 失敗，導致數個唯讀邊界實驗誤在本 repo 工作樹執行，刪除過 gitignored 的 `.cash-skills/receipt.tsv` 並暫時 rename 過 `.cash-skills/lib` 與 `config.py`，並宣稱已還原。主 agent 未採信其自述，獨立驗證：`git status --short` 為預期的 22 筆且無非預期改動、launcher 逐 byte 未變、19 個 canonical runtime 檔案齊全且 mode 皆 `0644`、`--self` 回報 `current`、receipt 45 筆 record 的 digest 與現地檔案零 mismatch、`cash list --json` 正常。**沒有任何受版控檔案被改動。** 另記：驗證期間第一次全套 `skill-checks.fish` 出現一次 `installer runtime contract tests failed`，隨後單獨與全套各重跑皆通過（96 tests OK），研判為與 reviewer 行程並行造成的暫時性失敗，非本 change 引入。
- **post-fix 驗證**：`scripts/cash-skills/tests/test_init_receipt.py` 18 tests、`test_installer_runtime.py` 96 tests、`skill-checks.fish` 全套、`cli-checks.fish` 145 tests 全數通過；`"$cash_cli" validate` 通過；`cash analyze` non-Suggestion findings 為 `0`。
- **post-fix mechanical self-check**：spec delta 註解開閉數皆為 `0`；Implementation Contract 13 項與 task 7.8 的宣告一致；import-time 計數在四份文件中一致為 4（15／4）；版本三處一致為 2.11.0；`design.md` 無「最終為 2.10.0」殘留；spec 無散文夾在 Scenario 之間。
- **變更目錄外的檔案記錄**：本輪修改的 change 目錄外檔案為 `cash-skills.version`、`.cash-skills/lib/cash_cli/installer.py`、`scripts/cash-skills/tests/test_init_receipt.py`、`CASH-INIT-RECEIPT.md`。因修改了 `.cash-skills/` 下的 runtime 檔，已於 project root 執行 `./install-cash-skills.fish --self` 重建 receipt 後才續用 Cash CLI。已執行 `touched ensure` 與 `touched record`。

## Decision

next_round
