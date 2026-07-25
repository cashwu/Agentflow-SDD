## Summary

移除 `scripts/cash-skills/tests/skill-checks.fish` 對 bundle version 的字面值斷言，改為與既有單一來源一致的衍生檢查；並為 CLI 補上 help 表面，使 15 個 command 可被發現。

## Motivation

兩項都在 `align-cli-skill-contracts` 的 Non-Goals 中被明列為另案處理，且都已由實測確認。

### A：版本字面值 pin 是重複定義，並對每次 bundle 變更課稅

`scripts/cash-skills/tests/skill-checks.fish` 的 `assert_inventory` 以字面值斷言當前 bundle 版本。實測確認全 repo 只有這一處字面值 pin。

問題不只是「每次升版要多改一行」。該檔是 grader-protected path，因此每一次 replaceable runtime 或 skill bytes 的變更——依 `Bundle 安裝與 runtime receipt` 的規定都 MUST 調升 `cash-skills.version`——都被迫把一個 grader-protected 檔案宣告進 proposal 的 `## Impact` 才能合法修改。最近兩份 change 各付了一次這個稅：`harden-installer-mode-and-recovery` 的 propose review 第四輪把它列為 Critical，理由是「調升版本」與「合約測試套件全數通過」兩個 task 互相矛盾，而唯一解法是動 grader-protected 檔案。

更關鍵的是這個斷言幾乎不提供額外覆蓋——它唯一多做的能力（攔到無正當理由的升版）在 design 的 Risks 中已明文評估並刻意捨棄。`scripts/cash-skills/tests/test_bundle_version_history.py` 的 `check_history` 已經強制三件事：版本字串為 strict `MAJOR.MINOR.PATCH`、相對於 `HEAD` 版本嚴格遞增、以及相同版本時綁定 first-parent history 中的引入 commit 內容。該檔由 `skill-checks.fish` 的 `assert_installer` 呼叫，因此只有 `all` 與 `installer-runtime` 兩個 case 會在同一次執行中同時涵蓋形狀與數值——字面值所在的 `assert_inventory` 則由另外兩個 case 觸發。字面值 pin 唯一多做的是「版本恰好等於某個特定值」，那不是契約，只是一個每次升版都要手動同步的絆線。格式規則本身另有數個既有擁有者：master spec 的 `Bundle 安裝與 runtime receipt` 定義它，`.cash-skills/lib/cash_cli/installer.py` 的 `VERSION_RE` 與 `source_inventory`（後者另強制單一 LF 終止）、`.cash-skills/bin/cash` 的 `is_source_layout`（逐字重述格式並含 LF 條款，每次 launcher 執行都跑；它是 stable path，一般升版改不動）與 `scripts/cash-skills/tests/test_bundle_version_history.py` 的 `version()` 各自編碼一次。同一個規則在兩處各自定義後其中一處退化為常數，正是 open signal `cross-artifact-definition-drift`（累計 10 次）的形狀。

### B：CLI 沒有任何 help 表面

`.cash-skills/lib/cash_cli/main.py` 的 `COMMANDS` 有 15 個 command：`list`、`status`、`instructions`、`new`、`task`、`in-progress`、`touched`、`park`、`unpark`、`validate`、`analyze`、`drift`、`archive`、`sync`、`search`。但沒有任何入口能列出它們。實測：

```
$ cash --help
error[unknown_command]: Unknown command: --help

$ cash
error[missing_command]: A command is required.
```

`missing_command` 告訴使用者「需要一個 command」卻不說有哪些，`--help` 則被當成未知 command。使用者只能去讀原始碼或 skill 文件。這對一個 repository-owned、沒有外部文件的 CLI 特別不合理。

## Proposed Solution

**A — 以衍生檢查取代字面值。** 移除 `assert_inventory` 中的版本字面值斷言，並把形狀驗證改置於呼叫 `scripts/cash-skills/tests/test_bundle_version_history.py` 的 `assert_installer`，使形狀與數值治理落在同一個 test group。驗證只確認 `cash-skills.version` 恰含一個以單一 LF 終止的合法版本值，不比對特定數值；格式判定委派給 `.cash-skills/lib/cash_cli/installer.py` 既有的 `version_parts`，本套件因此不內含任何格式常數。數值層面的規則——嚴格遞增與相同版本的內容綁定——維持由 `test_bundle_version_history.py` 單一擁有，`skill-checks.fish` 繼續在同一次執行中呼叫它。這使 `Cash 合約測試套件` 要求的「skill-checks MUST 治理 bundle version」仍然成立，但治理方式不再需要隨每次升版而修改。

**B — 以 flag 而非 command family 提供 help。** 新增 `--help` 與 `-h` 全域 flag，在 dispatch 之前處理；同時讓 **top-level dispatch 產生的** `missing_command` 與 `unknown_command` 在訊息中指向 help flag（handler 層產生的未知 new mode 與未知 discipline 不受影響）。訊息刻意不內嵌 command 清單——那會讓釘住該訊息的 golden fixture 變成第二份需手動同步的清單，正是本 change 要移除的絆線型態。help 不繞過 launcher 的 receipt gate。刻意不新增 `help` command family：`Cash workflow command surface` 明訂 CLI「僅需支援」skills 消費的那些 families，以 flag 實作可避免擴張該集合。

清單必須由 `COMMANDS` 導出，不得另立一份會漂移的副本——否則就是在修一個 `cross-artifact-definition-drift` 的同時製造另一個。

輸出與既有契約相容：`--help` 為成功路徑，exit 0；帶 `--json` 時輸出單一 JSON object 而非人類可讀文字。`missing_command` 與 `unknown_command` 維持既有的 exit 2 與 `error` object 結構，只擴充 `message` 內容。

## Non-Goals

- 不改動 `test_bundle_version_history.py` 已擁有的版本規則本身（格式、嚴格遞增、相同版本內容綁定），本次只移除另一處的重複定義。
- 不新增 `help` command family，也不改動 `COMMANDS` 的 15 個成員。
- 不為每個 command 提供 per-command 的詳細用法或參數說明，也不揭露 `new change`、`task done`、`instructions --skill` 這一層子命令粒度。help 只揭露 dispatch table 的 top-level key；子命令由各 handler 既有的 `invalid_arguments` 訊息承載。
- 不讓 help 繞過 launcher 的 receipt gate。receipt 缺失時 `--help` 維持既有失敗，這是 stable launcher 不可改動的必然結果。
- 不改動 handler 層產生的 `unknown_command`（未知 new mode、未知 discipline）。
- 不改動 grader 保護清單本身的成員。字面值 pin 移除後，未來的 bundle 升版仍需修改 `cash-skills.version`，但不再需要連帶修改 grader-protected 檔案。
- 不回頭修正封存目錄中既有 proposal 的 Impact 宣告。

## Alternatives Considered

**讓 `skill-checks.fish` 完全不檢查 bundle version**：可以移除全部重複，但 `Cash 合約測試套件` 明訂 skill-checks MUST 治理 bundle version，直接刪除會使該 requirement 失去載體。保留形狀檢查是滿足該 requirement 的最小形式。

**把版本字面值改為從檔案讀取後自我比對**：等同於恆真斷言，不提供任何覆蓋，比移除更糟。

**新增 `help` command family**：較符合一般 CLI 慣例，但 `Cash workflow command surface` 的「僅需支援」是刻意收斂的設計，為此擴張 command 集合需要更強的理由；以 flag 實作可達成同樣的可發現性而不觸動該邊界。

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `cash-cli`: bundle version 的測試治理方式由字面值改為衍生檢查；新增 help 表面並擴充 dispatch 錯誤的訊息內容。

## Impact

- Affected specs: `cash-cli`
- Affected code:
  - New: (none)
  - Modified:
    - `.cash-skills/lib/cash_cli/main.py`
    - `scripts/cash-skills/tests/skill-checks.fish`
    - `scripts/cash-cli/tests/test_runtime_and_errors.py`
    - `scripts/cash-cli/fixtures/negative-atomicity/error-contracts.json`
    - `scripts/cash-cli/tests/test_negative_atomicity.py`
    - `cash-skills.version`
  - Removed: (none)
