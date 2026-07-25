## Context

兩項變更共用一個主題：把「同一規則在多處各自定義」與「使用者只能讀原始碼才知道有什麼」這兩種摩擦收掉，且都不擴張既有的契約邊界。

**bundle version 的形狀規則已經被重述多次。** master spec 的 `Bundle 安裝與 runtime receipt` 定義「`cash-skills.version` MUST恰含一個`MAJOR.MINOR.PATCH`值，三個分量各符合`0|[1-9][0-9]*`，不得含前導零、prerelease或build suffix」。實作面至少有四處各自編碼同一規則：`.cash-skills/lib/cash_cli/installer.py` 的 `VERSION_RE` 與 `source_inventory`（後者另強制單一 LF 終止）；`.cash-skills/bin/cash` 的 `is_source_layout` 逐字重述格式**並含單一 LF 條款**，且由 `validate_receipt` 在每次 launcher 執行時呼叫；同檔另有一份 receipt 版本分量規則；`scripts/cash-skills/tests/test_bundle_version_history.py` 的 `version()` 在測試時再驗一次，並額外擁有嚴格遞增與相同版本的內容綁定。

`.cash-skills/bin/cash` 是 stable bootstrap path，其 bytes 綁定引入 commit 且不隨一般 bundle 升版改變，因此那一份重述在一般變更中改不動——這是本 change 不去碰它、也不新增第五份重述的理由。

`scripts/cash-skills/tests/skill-checks.fish` 的 `assert_inventory` 另有一行字面值斷言。它不提供上述任一既有擁有者以外的任何覆蓋，卻因為所在檔案是 grader-protected path，使每一次 bundle 升版都必須把該檔宣告進 proposal 的 `## Impact`。

**兩個 function 的觸發範圍不同。** 呼叫 `test_bundle_version_history.py` 的是 `assert_installer`，不是 `assert_inventory`。前者只由 `installer-runtime` 與 `all` 兩個 case 觸發，後者由 `codex-command-matrix`、`canonical-inventory` 與 `all` 觸發。因此「形狀與數值在同一次執行中都成立」目前只在 `all` 與 `installer-runtime` 為真。

**CLI 的錯誤訊息有 golden fixture 釘住。** `scripts/cash-cli/fixtures/negative-atomicity/error-contracts.json` 逐字記錄 `"message":"Unknown command: nope"`，而 `scripts/cash-cli/tests/test_negative_atomicity.py` 以整個 object 的相等比對驗證它。任何在該訊息附加內容的實作都會使該測試失敗，因此 fixture 必須同批更新。`scripts/cash-cli/tests/test_workspace_config_boundaries.py` 對同一 code 使用子字串斷言，不受影響。`missing_command` 的訊息則無任何測試釘住。

**launcher 在 `main()` 之前就驗 receipt。** `.cash-skills/bin/cash` 依序取得 lock、呼叫 `validate_receipt`，之後才 import runtime 並呼叫 `main()`。因此 help 無法繞過 receipt gate。

`.cash-skills/lib/cash_cli/main.py` 屬 replaceable runtime record，任何 bytes 變動都必須調升 `cash-skills.version`——本次變更自身也會付一次這個稅，這正是要移除字面值的理由。

## Goals / Non-Goals

**Goals**

- bundle version 的形狀規則不再新增任何一份重述；`skill-checks.fish` 的治理改為委派驗證而非重新定義，且不再需要隨每次升版而修改。
- 形狀治理與數值治理落在同一個 test group，不再互不相交。
- 使用者能從 CLI 本身得知有哪些 top-level command。
- 兩項都不擴張 `Cash workflow command surface` 的 command family 集合，也不改動既有的 JSON／錯誤契約形狀。

**Non-Goals**

- 不改動 `Bundle 安裝與 runtime receipt` 對版本格式的定義，也不改動 `test_bundle_version_history.py` 已擁有的數值規則。
- 不新增 `help` command family，不改動 dispatch table 的 15 個成員。
- 不提供 per-command 的用法或參數說明，也不揭露 `new change`／`task done`／`instructions --skill` 這一層子命令粒度。help 只揭露 dispatch table 的 top-level key；子命令由各 handler 既有的 `invalid_arguments` 訊息承載。
- 不讓 help 繞過 launcher 的 receipt gate。
- 不改動 handler 層（未知 new mode、未知 discipline）產生的 `unknown_command`。
- 不改動 grader 保護清單的成員。

## Decisions

### D1：以引用取代複述，並與數值治理同組

字面值斷言移除。取而代之的形狀驗證**不重新定義格式規則內容**，而是驗證版本檔符合 `Bundle 安裝與 runtime receipt` 已定義的格式。單一 LF 終止則是本 change 在測試套件 requirement 內新增的條款——master 的格式定義未涵蓋它，實際強制它的是 `installer.py` 的 `source_inventory`（安裝時）。delta 因此明文說明該條款由測試套件 requirement 擁有並與 installer 一致，而非假稱其權威在別處。delta spec 因此寫成引用而非複述——本次變更的動機就是消除重複定義，若在此處寫下第四份 `0|[1-9][0-9]*` 就是一邊修 `cross-artifact-definition-drift` 一邊製造新的一筆。

**位置改在 `assert_installer`，與 `test_bundle_version_history.py` 的呼叫同址。** 這解決兩個問題：一是 `assert_inventory` 所屬的 `canonical-inventory`／`codex-command-matrix` 兩個 group 從來就不執行數值治理，若把形狀檢查留在那裡，這兩個 group 對版本的治理會只剩形狀；二是同址使「形狀與數值同一次執行」成為結構事實而非敘述上的巧合。

**單一 LF 是唯一真正未被測試層覆蓋的面向。** `test_bundle_version_history.py` 的 `version()` 以 `.strip()` 解析，容忍無 LF、CRLF 與多個結尾 LF；`installer.py` 雖強制單一 LF，但那是安裝時的檢查，不是對 repo 當前狀態的測試斷言。因此形狀驗證的實質新增價值就在這一點。

**必須以 byte-level 機制實作，且格式判定必須委派而非重寫。** 現行的 fish 慣用法做不到：實測 `test (string trim <file) = 2.3.0` 對 `2.3.0`（無 LF）、`2.3.0\n`、`2.3.0\r\n` 三者**全部 PASS**，完全分辨不出結尾形狀。因此必須對檔案內容做 byte-level 的完整比對。

   但直接在 `skill-checks.fish` 寫一條含 `0|[1-9][0-9]*` 的 regex 會與「不得重新定義格式規則」互斥——那正是第五份重述。解法是把格式判定**委派給 runtime 既有的 `version_parts`**：驗證讀取檔案 bytes，自行判斷「恰一個 LF 終止」（這是本 change 唯一自有的條款），再把去掉 LF 的內容交給 `version_parts` 判定格式。如此 `skill-checks.fish` 不含任何格式常數，且「內容接受集合與 `source_inventory` 一致」成為結構事實而非人工同步——兩者呼叫同一個判定函式。已實測該委派對 `2.3.0\n` 接受，對無 LF、CRLF、雙 LF、空檔、前導零五種全部拒絕。

**替代方案（不採用）**：把字面值改為從版本檔讀取後自我比對。那是恆真斷言，覆蓋為零。

**替代方案（不採用）**：`skill-checks.fish` 完全不檢查 bundle version。`Cash 合約測試套件` 明訂它 MUST 治理 bundle version，直接刪除會使該 requirement 失去載體。

### D2：help 以全域 flag 實作，且不繞過 receipt gate

`Cash workflow command surface` 明訂 CLI「僅需支援」skills 消費的那些 command families。新增 `help` command 會擴張該集合；以 flag 實作可達成同樣的可發現性而不觸動該邊界。

觸發規則收斂為**第一個引數是 `--help` 或 `-h`**，處理點在 `main()` 內、呼叫 `dispatch()` 之前。`cash list --help` 行為不變（per-command 說明是 Non-Goal），空引數維持 `missing_command`。

**help 不繞過 launcher 的 receipt gate，這是刻意的。** launcher 在 import runtime 之前就完成 lock 取得與 `validate_receipt`，因此 `cash --help` 在 receipt 缺失或無效時仍會得到 `bootstrap_invalid`／`receipt_invalid`。代價是：剛 clone 的 repo（`.cash-skills/receipt.tsv` 為 gitignore 檔，必然不存在）第一個打的 `cash --help` 拿不到 help，得先跑 `./install-cash-skills.fish --self`。要讓 help 在無 receipt 時可用，必須在 launcher 的 `validate_receipt` 之前分流——那會改動 stable path `.cash-skills/bin/cash` 的 bytes，該檔綁定引入 commit 且安裝後不得替換。此路不通，故接受此限制並明文寫入規範。

**與 `Project-local Cash CLI runtime` 的關係。** 該未修訂的 requirement 規定 unknown command 取得 shared lock 後失敗。help flag 不是 command，因此在本 requirement 明文限定「該規定僅適用於進入 dispatch 的 token」，避免兩個 requirement 對同一 argv 給出相反結論。

### D3：清單由 dispatch table 導出，且只作用於 dispatch 層

command 清單 SHALL 只有 help 一個輸出處，且 SHALL 由 dispatch table 的 key 導出並排序，不得另立靜態副本。

**必須限定在 top-level dispatch 層。** `unknown_command` 另有兩個產生點：未知的 new mode 與未知的 discipline。把指向 help 的措辭塞進那些訊息語意錯誤（help 列的是 top-level command，對未知 discipline 沒有幫助），且會擴大改動面到兩個額外的 replaceable runtime record。因此規範明文限定產生者。

**`--json` 的形狀必須固定。** 只寫「單一 JSON object」會讓防漂移測試沒有可解析的欄位，且 `Cash 合約測試套件` 明訂 `cli-checks.fish` MUST 治理所有 consumer JSON shapes。因此固定為 `commands` 欄位承載排序後的 key 陣列。

**錯誤訊息指向 help，而不是內嵌清單。** 最初的設計是把 15 個 command 附進 `missing_command` 與 `unknown_command` 的訊息，但 `error-contracts.json` 以整個 object 相等比對釘住 `unknown_command` 的完整訊息——內嵌清單等於在 golden fixture 裡再放一份 122 字元的 command 名稱副本，任何人增刪 dispatch table 的 key 都得手動同步它。那正是本 change 要從 `skill-checks.fish` 移除的那種絆線，一邊移除一邊新增沒有道理。

因此兩個 dispatch 層錯誤的訊息改為**指向 help flag**：這是不隨 dispatch table 變動的穩定字串，fixture 只需一次性更新後就不再需要同步，而可發現性的目標由 help 本身承擔。command 清單因此只有 help 一個輸出處。

## Implementation Contract

### IC1 — 版本形狀驗證

- `scripts/cash-skills/tests/skill-checks.fish` SHALL NOT 包含任何 bundle 版本的字面值。
- 形狀驗證 SHALL 置於呼叫 `scripts/cash-skills/tests/test_bundle_version_history.py` 的同一個 function，使其與數值治理落在同一個 test group。
- 形狀驗證 SHALL 以 byte-level 機制對檔案內容做完整比對，SHALL NOT 使用會剝除結尾換行或空白的慣用法。它 SHALL 只接受「恰一個符合 `Bundle 安裝與 runtime receipt` 所定義格式的值加單一 LF」，SHALL 拒絕無 LF、CRLF、多個 LF、空檔與含前導零的值。
- 格式判定 SHALL 委派給 `.cash-skills/lib/cash_cli/installer.py` 既有的 `version_parts`，`scripts/cash-skills/tests/skill-checks.fish` SHALL NOT 內含任何格式常數；該檔自有的條款 SHALL 只有「恰一個 LF 終止」。此委派使內容接受集合與 `source_inventory` 的一致成為結構事實。
- 該驗證 SHALL NOT 重新定義格式規則的內容；delta spec 對此 SHALL 以引用表述。
- 該驗證的**內容**接受集合 SHALL 與 `source_inventory` 對版本檔內容的判定一致。`source_inventory` 另經 `read_regular` 強制 mode `0644`、regular file、single hard link 與 no-follow，這些 identity 條件屬安裝時前置條件，SHALL NOT 納入本驗證的接受集合。
- 嚴格遞增與相同版本內容綁定 SHALL NOT 在 `skill-checks.fish` 定義。
- 調升 `cash-skills.version` SHALL NOT 再需要修改 `scripts/cash-skills/tests/skill-checks.fish`。

### IC2 — help 表面

- 第一個引數為 `--help` 或 `-h` 時，CLI SHALL 在 launcher 完成 lock 取得與 receipt 驗證之後、進入 `dispatch()` 之前輸出 help 並以 exit 0 結束。
- help SHALL NOT 繞過 receipt gate；receipt 缺失或無效時 SHALL 維持既有的 `bootstrap_invalid`／`receipt_invalid` 失敗。
- help SHALL 列出 dispatch table 的全部 key，排序穩定。
- `--json` 時 help SHALL 輸出單一 JSON object，其 `commands` 欄位為排序後的 dispatch table key 陣列；非 `--json` 時 SHALL 輸出人類可讀文字至 stdout。
- 第一個引數不是 help flag 時，CLI 的 dispatch 目標、exit code、`error` code 與 JSON object 結構 SHALL 與變更前相同——包含 `cash list --help` 仍交給 `list` handler。

### IC3 — dispatch 層錯誤訊息

- 由 top-level command dispatch 產生的 `missing_command` 與 `unknown_command` SHALL 維持既有的 code、exit 2 與 `error` object 結構，其 `message` SHALL 指向 help flag，且 SHALL NOT 內嵌 command 清單。
- 由個別 handler 產生的其他 `unknown_command`（未知 new mode、未知 discipline）SHALL NOT 受此規定影響，其 code、exit code 與訊息語意 SHALL 不變。
- command 清單 SHALL 只有 help 一個輸出處，並 SHALL 由 dispatch table 導出。
- `scripts/cash-cli/fixtures/negative-atomicity/error-contracts.json` 的 `unknown_command` 訊息 SHALL 同批更新為新的指向 help 的訊息。因該訊息不含 command 清單，此為一次性更新，SHALL NOT 隨 dispatch table 變動而需要再次同步。

### IC4 — 測試與版本

- `bootstrap_invalid`／`receipt_invalid` 只由 launcher 產生，需要真實安裝的 target；`scripts/cash-cli/tests/test_runtime_and_errors.py` 目前不含 launcher 或安裝路徑的 subprocess。handler 層 `unknown_command` 的兩項斷言同樣不是純 unit 可達：`create.py` 與 `discovery.py` 都在 mode／discipline 判定之前先解析 workspace，實測以 repo root 為 cwd 得到 `unknown_command`、以 `/tmp` 為 cwd 則得到 `workspace_not_found`。這兩項 SHALL 自行以 `tempfile` 建立 `git init` 過的暫存 workspace，含內容有效的 `.cash.yaml` 與 `openspec/config.yaml`，以及一個**空的 `0644`** `.cash-workspace.lock`（該檔的要求與前兩者相反：寫入內容或非 `0644` 會以 `workspace_lock_invalid` 失敗），並在測試內 `os.chdir` 進去、以 `addCleanup` 還原原 cwd。`CASH_PROJECT_ROOT` SHALL NOT 被當成 workspace 來源——它是一致性守衛，只設它而不 chdir 會得到 `workspace_root_mismatch`；若設定，其值 SHALL 等於該暫存 git root。這兩項 SHALL NOT 依賴呼叫者的 cwd，也 SHALL NOT 對真實 repository workspace 執行 recover。receipt gate 的覆蓋 SHALL 置於已具備 launcher 安裝設施的 `scripts/cash-cli/tests/test_negative_atomicity.py`，其餘覆蓋留在 `scripts/cash-cli/tests/test_runtime_and_errors.py`。
- `scripts/cash-cli/tests/test_runtime_and_errors.py` SHALL 新增覆蓋：`--help` 與 `-h` 各自 exit 0 且輸出涵蓋全部 dispatch table key；`--json` 輸出的 `commands` 欄位**逐元素等於**排序後的 dispatch table key 序列（期望值直接由 runtime 匯入該 table 後排序取得，不得在測試內另寫靜態清單；斷言集合相等不足以驗證 spec 要求的排序）；非 `--json` 輸出為人類可讀文字；`missing_command` 與 `unknown_command` 的訊息指向 help flag、不內嵌清單，且 code 與 exit code 不變；handler 層的未知 new mode（以帶第二個 argument 的形式觸發，否則會落在 `invalid_arguments`）與未知 discipline 的訊息既不含 top-level 清單也不指向 help；`cash list --help` 行為與變更前相同。
- `scripts/cash-skills/tests/skill-checks.fish` 的形狀驗證 SHALL 以無 LF、CRLF、多個 LF、空檔、含前導零各一個負面案例驗證。負面案例之前 SHALL 先以同一 harness、同一暫存位置、同一建立方式對一個由當前值派生的**合法** fixture 斷言「接受」作為正向控制——否則任何使 fixture 不可達的執行錯誤都會被讀成「拒絕」，五個負面案例全部 vacuous pass，正是本 change 立論所針對的失效型態。
- `scripts/cash-cli/tests/cli-checks.fish` SHALL NOT 需要修改：它以檔名執行相關測試檔，且 `case all` 以萬用字元納入全部測試檔。
- `cash-skills.version` SHALL 嚴格遞增。

## Risks / Trade-offs

- **形狀驗證比字面值弱**：字面值能攔到「有人改了版本但沒意識到」，形狀驗證不能。但那個能力是以「每次升版都要動 grader-protected 檔案」換來的，且 `test_bundle_version_history.py` 的嚴格遞增檢查已能攔到版本倒退或未升這個真正有害的方向。刻意接受。
- **`canonical-inventory` 與 `codex-command-matrix` 將不再含任何版本治理**：形狀驗證移到 `assert_installer` 之後，這兩個 group 對版本完全不檢查。今日它們至少還有字面值。判斷是：這兩個 group 的職責分別是 canonical inventory 與 command matrix，版本治理本就不屬於它們；`all` 與 `installer-runtime` 仍完整涵蓋。
- **fresh clone 的 `cash --help` 拿不到 help**：receipt 是 gitignore 檔，必然不存在，使用者第一個打的指令會得到 `receipt_invalid`。要繞過必須改 stable path 的 bytes，此路不通。已明文寫入規範並在此記錄。
- **help 仍會取 shared lock**：`--help` 不在 mutating families，取 `LOCK_SH`，因此在既有 exclusive lock 存在時會被阻塞。與其他 read command 一致，不另做處理。
- **help 只揭露 top-level key**：使用者看到 `new`、`task`、`in-progress`、`touched` 但看不到必填的子命令 token。子命令由各 handler 的 `invalid_arguments` 訊息承載，已列為 Non-Goal。
- **`cash --json --help` 不觸發 help**：觸發規則只認第一個引數，該組合會走 `unknown_command`（訊息會指向 help flag）。收斂觸發面的代價；日後若造成困擾，擴張規則是相容變更。
- **本次變更自身仍需付一次稅**：`main.py` 是 replaceable runtime record，本 change 仍必須調升版本，且因要改 `skill-checks.fish` 而必須宣告該 grader-protected 檔案。這是最後一次。
