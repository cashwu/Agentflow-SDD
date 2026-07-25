## ADDED Requirements

### Requirement: touched record 記錄 review loop 產出

CLI SHALL 提供 `touched record <name> --path <path> [--path <path> ...]`，把指定的 project-root-relative 路徑記入 `.cash-skills/state/touched/<name>.json` 中 `task_id` 為 `review-loop`、`task_desc` 為 `Review loop outputs` 的保留條目。

`touched record` MUST NOT 成為第一次 Cash touched access：`.cash-skills/state/touched/<name>.json` 不存在時 MUST 以 `touched_invalid` 失敗且零寫入，並 MUST NOT 執行 legacy import；呼叫端 MUST 先執行 `touched ensure <name>`。

每個 `--path` MUST 依序通過三段驗證：既有的 unsafe path 檢查（絕對路徑、含 `..`、以 `.git/` 或 `.cash-skills/state/` 開頭者 MUST 以 `touched_invalid` 失敗）；前綴拒絕（以 `openspec/changes/` 或 `.cash-skills/receipt.tsv` 開頭者 MUST 以 `touched_invalid` 失敗；此組前綴與 `git_fingerprints` 忽略的前綴對齊，MUST NOT 拒絕整個 `.cash-skills/` 前綴，`.cash-skills/lib/` 與 `.cash-skills/bin/` 之下的既存一般檔案 MUST 可被記錄）；以及存在性與型別檢查（路徑 MUST 為既存的一般檔案，`missing`、`directory` 與其他型別 MUST 以 `touched_invalid` 失敗，symlink MUST 以 `unsafe_path` 失敗）。任一 `--path` 失敗時整個 command MUST 零寫入。

該 command MUST NOT 依賴、讀取或寫入 `.cash-skills/state/snapshots/<name>.json`，MUST NOT 改動 `tasks.md`，MUST NOT 改動任何既有 per-task 條目，MUST NOT 提供 `--json`。條目內 `files` 與頂層 `files` MUST 維持以 UTF-8 bytes 排序去重的正規形式，頂層 `files` MUST 恰為各條目 `files` 的排序聯集，`legacy_import` 原值 MUST 保留。合併結果與載入值相同時 MUST NOT 寫入。`openspec/changes/<name>/` 不是目錄時 MUST 以 `change_not_found` 失敗且零寫入；未提供任何 `--path` 或 `--path` 缺值時 MUST 以 `invalid_arguments` 失敗且零寫入。既有的 `touched ensure` 行為 MUST 不變。

#### Scenario: 無 snapshot 時仍可記錄

- **GIVEN** change `demo-change` 存在且從未執行過 `in-progress add`
- **AND** 已執行過 `touched ensure demo-change`
- **AND** `.cash-skills/state/snapshots/demo-change.json` 不存在
- **WHEN** 執行 `touched record demo-change --path openspec/signals/demo.md`
- **THEN** command 成功並建立 `review-loop` 條目
- **AND** `.cash-skills/state/snapshots/demo-change.json` 仍不存在

#### Scenario: 未先 ensure 時失敗

- **GIVEN** `.cash-skills/state/touched/demo-change.json` 不存在
- **WHEN** 執行 `touched record demo-change --path openspec/signals/demo.md`
- **THEN** command 以 `touched_invalid` 失敗
- **AND** `.cash-skills/state/touched/demo-change.json` 不被建立
- **AND** command 不讀取也不匯入任何 legacy touched 檔

#### Scenario: 與既有 per-task 條目並存

- **GIVEN** `demo-change` 的 touched state 已含一個 per-task 條目
- **WHEN** 執行 `touched record demo-change --path openspec/signals/demo.md`
- **THEN** 既有 per-task 條目逐字不變
- **AND** touched state 同時含該 per-task 條目與 `review-loop` 條目
- **AND** 頂層 `files` 恰為兩個條目 `files` 的排序聯集

#### Scenario: 重複記錄相同路徑不寫入

- **GIVEN** `demo-change` 的 `review-loop` 條目已含 `openspec/signals/demo.md`
- **WHEN** 再次執行 `touched record demo-change --path openspec/signals/demo.md`
- **THEN** command 成功
- **AND** `.cash-skills/state/touched/demo-change.json` 的 bytes、`st_ino` 與 mtime 皆不變

#### Scenario: 缺少 path 參數時失敗

- **WHEN** 執行 `touched record demo-change` 或 `touched record demo-change --path`
- **THEN** command 以 `invalid_arguments` 失敗
- **AND** touched state 不被建立或改動

#### Scenario: 不安全路徑被拒絕

- **WHEN** 執行 `touched record demo-change --path` 並帶入絕對路徑、含 `..` 的路徑、以 `.git/` 開頭的路徑、或以 `.cash-skills/state/` 開頭的路徑
- **THEN** command 以 `touched_invalid` 失敗
- **AND** touched state 不被建立或改動

#### Scenario: 被拒前綴維持 touched 的來源檔不變量

- **WHEN** 執行 `touched record demo-change --path` 並帶入以 `openspec/changes/` 開頭的路徑或 `.cash-skills/receipt.tsv`
- **THEN** command 以 `touched_invalid` 失敗
- **AND** touched state 不被建立或改動
- **AND** 帶入 `.cash-skills/lib/` 之下的既存一般檔案時 command 成功並記錄該路徑

#### Scenario: 非既存一般檔案被拒絕

- **WHEN** 執行 `touched record demo-change --path` 並帶入不存在的路徑或目錄路徑
- **THEN** command 以 `touched_invalid` 失敗
- **AND** touched state 不被建立或改動

#### Scenario: 混合合法與非法路徑時零寫入

- **GIVEN** `demo-change` 的 touched state 已存在
- **WHEN** 單次執行 `touched record demo-change` 並帶入多個合法 `--path` 與一個非法 `--path`
- **THEN** command 以 `touched_invalid` 失敗
- **AND** `.cash-skills/state/touched/demo-change.json` 的 bytes 逐字不變，合法路徑亦未被記錄

#### Scenario: change 不存在時失敗

- **GIVEN** `openspec/changes/absent-change/` 不存在
- **WHEN** 執行 `touched record absent-change --path openspec/signals/demo.md`
- **THEN** command 以 `change_not_found` 失敗
- **AND** `.cash-skills/state/touched/absent-change.json` 不被建立

#### Scenario: 不改動 tasks 與 snapshot

- **GIVEN** `demo-change` 已有 `tasks.md` 與 snapshot
- **WHEN** 執行 `touched record demo-change --path openspec/signals/demo.md`
- **THEN** `openspec/changes/demo-change/tasks.md` 的 bytes 不變
- **AND** `.cash-skills/state/snapshots/demo-change.json` 的 bytes 不變

## MODIFIED Requirements

### Requirement: Cash workflow command surface

CLI SHALL 提供且僅需支援Cash workflows消費的`list`、`status`、`instructions`（含artifact-level、`instructions apply`與`instructions --skill <tdd|audit>`三種mode）、`new change`、`new artifact`、`task done`、`in-progress add`、`touched ensure`、`touched record`、`park`、`unpark`、`validate`（含single-change與`validate --all`）、`analyze`、`drift`、`archive`、`sync`與`search`command families。每個呼叫artifact engine的canonical Cash skill MUST 呼叫`.cash-skills/bin/cash`，MUST NOT包含可執行的`spectra`command或`Requires spectra CLI`相容性宣告。

CLI SHALL 另提供不擴張上述command family集合的help表面。第一個argument為`--help`或`-h`時，CLI MUST在launcher完成既有的lock取得與receipt驗證之後、進入command dispatch之前輸出help並以exit 0結束；help MUST NOT繞過launcher的receipt gate，因此receipt缺失或無效時 MUST維持既有的`bootstrap_invalid`／`receipt_invalid`失敗而非輸出help。help flag不是command，`Project-local Cash CLI runtime`對unknown command的失敗規定僅適用於進入dispatch的token。第一個argument不是help flag時，CLI的dispatch目標、exit code、`error` code與JSON object結構 MUST與未提供該表面時相同。由top-level command dispatch產生的`missing_command`與`unknown_command` MUST維持既有的code、exit code與`error` object結構，但其`message` MUST指向help flag。該訊息 MUST NOT內嵌command清單——內嵌會使釘住該訊息的golden fixture成為第二份需手動同步的清單，與本requirement消除重複定義的目的相反；指向help的措辭是不隨dispatch table變動的穩定字串。由個別handler產生的其他`unknown_command`（例如未知的new mode或未知的discipline）MUST NOT受此規定影響。command清單 MUST只有help一個輸出處，且 MUST由dispatch table導出，MUST NOT另立靜態副本。`--json`時help MUST輸出單一JSON object，其`commands`欄位為排序後的dispatch table key陣列。

#### Scenario: 支援的 command 被 dispatch

- **WHEN** caller提供上述任一已支援command與有效arguments
- **THEN** CLI dispatch到Cash-owned handler
- **AND** handler不經過外部CLI adapter

##### Example: discovery command dispatch

- **GIVEN** caller位於有效workspace
- **WHEN** caller執行`.cash-skills/bin/cash list --json`
- **THEN** discovery handler回傳單一`changes` JSON object

#### Scenario: 未治理 command 被拒絕

- **WHEN** caller執行`.cash-skills/bin/cash update`
- **THEN** CLI回傳`unknown_command`錯誤
- **AND** CLI不建立Spectra相容pass-through
- **AND** 該dispatch層錯誤訊息指向help flag，且不內嵌command清單

#### Scenario: Help flag 列出全部 command

- **GIVEN** target的receipt有效且launcher可取得lock
- **WHEN** caller以`--help`或`-h`作為第一個argument執行CLI
- **THEN** CLI輸出dispatch table全部command並以exit 0結束
- **AND** CLI不進入command dispatch

##### Example: help 的兩種輸出形狀

- **GIVEN** caller位於receipt有效的workspace
- **WHEN** caller執行`.cash-skills/bin/cash --help --json`
- **THEN** CLI在stdout輸出單一JSON object，其`commands`為排序後的dispatch table key陣列
- **AND** 同一指令去除`--json`時輸出人類可讀文字

#### Scenario: Help 不繞過 receipt gate

- **GIVEN** target的`.cash-skills/receipt.tsv`缺失或內容無效
- **WHEN** caller以`--help`作為第一個argument執行CLI
- **THEN** CLI維持既有的`bootstrap_invalid`或`receipt_invalid`失敗
- **AND** CLI不輸出help

#### Scenario: 缺少 command 時指向 help

- **WHEN** caller不提供任何argument執行CLI
- **THEN** CLI以`missing_command`與既有exit code失敗
- **AND** 錯誤訊息指向help flag，且不內嵌command清單

#### Scenario: Handler 層的 unknown_command 不受影響

- **WHEN** caller執行`.cash-skills/bin/cash new bogus <artifact-id>`或`.cash-skills/bin/cash instructions --skill bogus`
- **THEN** CLI維持既有的`unknown_command` code、exit code與訊息語意
- **AND** 該訊息不包含top-level command清單，也不指向help flag

#### Scenario: Help flag 不改變其他位置的行為

- **WHEN** caller執行`.cash-skills/bin/cash list --help`
- **THEN** CLI將該argument交給`list` handler，dispatch目標與exit code與未提供help表面時相同
- **AND** CLI不輸出help
