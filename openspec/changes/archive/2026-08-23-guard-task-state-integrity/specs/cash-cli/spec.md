## ADDED Requirements

### Requirement: touched state 的 task attribution 對齊

`.cash-skills/state/touched/<name>.json` 的 per-task 條目以位置式 `task_id` 為鍵，而該 id 由 `tasks.md` 中 task 條目的順序推導；在 `tasks.md` 插入或刪除條目會使既有條目的 `task_id` 與其真正對應的 task 整體錯位。CLI SHALL 在讀取既有 touched state 時對齊該 attribution，使消費端取得的視圖指向正確的 task。

對齊 MUST 以 `task_desc` 為語意錨點、`task_id` 為衍生的位置索引，方向為以描述反推 id：依目前 `tasks.md` 建立「描述 → 位置式 id」映射，對每個 `task_id` 不等於保留值 `review-loop` 的條目，若其 `task_desc` 在映射中且對應 id 與現存 `task_id` 不同，MUST 改寫該條目的 `task_id`。

對齊 MUST NOT 改寫任何條目的 `task_desc`。相反方向（依位置改寫 `task_desc`）MUST NOT 採用：`task_desc` 是偵測漂移的唯一證據，改寫它會把原屬於某個 task 的檔案清單重新標記到另一個 task 名下。

某條目的 `task_desc` 在映射中完全找不到時，CLI MUST 以 `touched_invalid` fail closed，且錯誤訊息 MUST 包含該 `task_desc`。位置式 id 無法區分「條目被刪除」與「描述被改寫」，任何自動處置都可能把錯誤配對簽為合法。

`task_id` 為 `review-loop` 的保留條目 MUST 豁免於對齊與 fail closed 判定。

對齊 MUST NOT 改動任何條目的 `files`：它只重新指派 `task_id`，檔案歸屬本身不變。

touched state 的 `legacy_import` 非 `null` 時，其條目的 `task_desc` 並非由本專案的 `tasks.md` 產生，因此 MUST 豁免上述 fail closed：對齊 MUST 只做描述對得上的 `task_id` 改寫，描述查無此項時 MUST 保留該條目原樣並繼續。

對齊需要 `tasks.md` 作為輸入，取不到時 MUST 原樣回傳而非失敗：`openspec/changes/<name>/tasks.md` 不存在時 MUST 再查 `openspec/changes/.parked/<name>/tasks.md`，兩者皆不存在才原樣回傳；讀取或解析 `tasks.md` 的任何失敗——包含 task 標籤缺失或重複的 `task_id_invalid`、`tasks.md` 為 symlink 的 `unsafe_path`、內容非 UTF-8、以及 `tasks.md` 是目錄——MUST 被捕捉並原樣回傳，MUST NOT 從對齊路徑逸出。

對齊完成後 MUST 檢查 `task_id` 唯一性。`legacy_import` 為 `null` 時重複 MUST 以 `touched_invalid` 失敗；非 `null` 時重複代表某個依豁免保留原樣的條目其陳舊 `task_id` 與另一條目對齊後的新 id 相撞，此時 MUST 放棄本次對齊並原樣回傳，MUST NOT 失敗。通過檢查後 MUST 依 `task_id` 的 UTF-8 bytes 重新排序；僅順序改變而條目內容不變時，仍 MUST 視為對齊改變了內容。

對齊本身 MUST NOT 自行寫入檔案，但其結果 MUST 被持久化：`touched ensure` MUST 在對齊改變了內容時把對齊後的值寫回 `.cash-skills/state/touched/<name>.json`，即使該檔已存在；`touched record` MUST 把「對齊是否改變內容」併入其寫入條件。對齊未改變任何內容時 `touched ensure` MUST NOT 寫入，維持其既有的零寫入行為。只在記憶體中對齊不足以達成本 requirement 的目的，因為 `cash-commit` 直接讀取該檔而非透過 CLI。

#### Scenario: 插入 task 造成位移時依描述對齊

- **GIVEN** change `demo-change` 的 touched state 有一筆 `task_id` 為 `1`、`task_desc` 為 `1.1 改寫 A` 的條目
- **AND** `tasks.md` 在該 task 之前新增了一條 task，使 `1.1 改寫 A` 的位置式 id 變為 `2`
- **WHEN** CLI 讀取該 touched state
- **THEN** 該條目的 `task_id` 對齊為 `2`
- **AND** 該條目的 `task_desc` 維持 `1.1 改寫 A`
- **AND** 該條目的 `files` 不變

#### Scenario: 描述查無此項時 fail closed

- **GIVEN** change `demo-change` 的 touched state 有一筆 `task_desc` 為 `1.1 改寫 A` 的條目
- **AND** `tasks.md` 中已不存在描述為 `1.1 改寫 A` 的 task
- **WHEN** CLI 讀取該 touched state
- **THEN** CLI 以 `touched_invalid` 失敗
- **AND** 錯誤訊息包含 `1.1 改寫 A`

#### Scenario: 保留條目豁免

- **GIVEN** change `demo-change` 的 touched state 含 `task_id` 為 `review-loop`、`task_desc` 為 `Review loop outputs` 的條目
- **AND** `tasks.md` 中不存在描述為 `Review loop outputs` 的 task
- **WHEN** CLI 讀取該 touched state
- **THEN** CLI 不因該保留條目而失敗
- **AND** 該條目的 `task_id` 與 `task_desc` 皆不被改寫

#### Scenario: tasks.md 不存在時跳過對齊

- **GIVEN** change `demo-change` 沒有 `openspec/changes/demo-change/tasks.md`
- **WHEN** CLI 讀取該 change 的 touched state
- **THEN** CLI 原樣回傳該 state
- **AND** 不因缺少 `tasks.md` 而失敗

#### Scenario: 對齊後 id 重複時 fail closed

- **GIVEN** change `demo-change` 的 touched state 其 `legacy_import` 為 `null`
- **AND** 該 state 有兩筆非保留條目
- **AND** 兩者的 `task_desc` 依目前 `tasks.md` 對應到同一個位置式 id
- **WHEN** CLI 讀取該 touched state
- **THEN** CLI 以 `touched_invalid` 失敗

#### Scenario: legacy 來源的 state 在 id 重複時放棄對齊

- **GIVEN** change `demo-change` 的 touched state 其 `legacy_import` 非 `null`
- **AND** 其中一筆條目的 `task_desc` 在 `tasks.md` 中查無此項，依豁免保留其陳舊 `task_id`
- **AND** 另一筆條目對齊後的新 `task_id` 與該陳舊 id 相同
- **WHEN** CLI 讀取該 touched state
- **THEN** CLI 不以 `touched_invalid` 失敗
- **AND** 回傳的 state 與磁碟上的原值逐字相同，未帶任何已套用的 `task_id` 改寫
- **AND** `.cash-skills/state/touched/demo-change.json` 的內容不變

#### Scenario: 僅順序改變時仍視為對齊改變了內容

- **GIVEN** change `demo-change` 的 touched state 其全部條目的 `task_id` 都已與 `tasks.md` 一致
- **AND** 該 state 的 `touched` 陣列未依 `task_id` 的 UTF-8 bytes 排序
- **WHEN** 執行 `touched ensure demo-change`
- **THEN** `.cash-skills/state/touched/demo-change.json` 被更新為重新排序後的值

#### Scenario: 對齊不自行寫檔

- **GIVEN** change `demo-change` 的 touched state 存在需要對齊的條目
- **WHEN** 執行只讀取 touched state 而不寫入的操作
- **THEN** `.cash-skills/state/touched/demo-change.json` 的內容不變

#### Scenario: 對齊改變內容時 touched ensure 寫回磁碟

- **GIVEN** change `demo-change` 的 touched state 存在且有一筆 `task_id` 與其 `task_desc` 不再對應的條目
- **WHEN** 執行 `touched ensure demo-change`
- **THEN** `.cash-skills/state/touched/demo-change.json` 的內容被更新為對齊後的值
- **AND** 後續直接讀取該檔的消費端取得已對齊的 `task_id`

#### Scenario: 對齊改變內容時 touched record 也寫回磁碟

- **GIVEN** change `demo-change` 的 touched state 有一筆 `task_id` 與其 `task_desc` 不再對應的條目
- **AND** `review-loop` 條目已含 `openspec/signals/demo.md`
- **WHEN** 執行 `touched record demo-change --path openspec/signals/demo.md`
- **THEN** command 成功
- **AND** `.cash-skills/state/touched/demo-change.json` 被更新為對齊後的值
- **AND** 即使 `review-loop` 條目的合併結果與載入值相同，仍因對齊改變了內容而寫入

#### Scenario: 對齊未改變內容時 touched ensure 不寫入

- **GIVEN** change `demo-change` 的 touched state 全部條目的 `task_id` 都已與 `tasks.md` 一致
- **WHEN** 執行 `touched ensure demo-change`
- **THEN** `.cash-skills/state/touched/demo-change.json` 的內容不變

#### Scenario: legacy 來源的 state 豁免 fail closed

- **GIVEN** change `demo-change` 的 touched state 其 `legacy_import` 非 `null`
- **AND** 其中一筆條目的 `task_desc` 在 `tasks.md` 中查無此項
- **WHEN** CLI 讀取該 touched state
- **THEN** CLI 不因該條目而失敗
- **AND** 該條目原樣保留

#### Scenario: tasks.md 解析失敗時原樣回傳

- **GIVEN** change `demo-change` 的 `tasks.md` 存在但含缺少標籤的 task 行
- **WHEN** CLI 讀取該 change 的 touched state
- **THEN** CLI 原樣回傳該 state
- **AND** 不以 `task_id_invalid` 失敗

#### Scenario: parked change 仍能對齊

- **GIVEN** change `demo-change` 已被 park，其目錄位於 `openspec/changes/.parked/demo-change/`
- **AND** `openspec/changes/demo-change/tasks.md` 不存在
- **WHEN** CLI 讀取該 change 的 touched state
- **THEN** CLI 以 `openspec/changes/.parked/demo-change/tasks.md` 作為對齊輸入

## MODIFIED Requirements

### Requirement: touched record 記錄 review loop 產出

CLI SHALL 提供 `touched record <name> --path <path> [--path <path> ...]`，把指定的 project-root-relative 路徑記入 `.cash-skills/state/touched/<name>.json` 中 `task_id` 為 `review-loop`、`task_desc` 為 `Review loop outputs` 的保留條目。

`touched record` MUST NOT 成為第一次 Cash touched access：`.cash-skills/state/touched/<name>.json` 不存在時 MUST 以 `touched_invalid` 失敗且零寫入，並 MUST NOT 執行 legacy import；呼叫端 MUST 先執行 `touched ensure <name>`。

每個 `--path` MUST 依序通過三段驗證：既有的 unsafe path 檢查（絕對路徑、含 `..`、以 `.git/` 或 `.cash-skills/state/` 開頭者 MUST 以 `touched_invalid` 失敗）；前綴拒絕（以 `openspec/changes/` 或 `.cash-skills/receipt.tsv` 開頭者 MUST 以 `touched_invalid` 失敗；此組前綴與 `git_fingerprints` 忽略的前綴對齊，MUST NOT 拒絕整個 `.cash-skills/` 前綴，`.cash-skills/lib/` 與 `.cash-skills/bin/` 之下的既存一般檔案 MUST 可被記錄）；以及存在性與型別檢查（路徑 MUST 為既存的一般檔案，`missing`、`directory` 與其他型別 MUST 以 `touched_invalid` 失敗，symlink MUST 以 `unsafe_path` 失敗）。任一 `--path` 失敗時整個 command MUST 零寫入。

該 command MUST NOT 依賴、讀取或寫入 `.cash-skills/state/snapshots/<name>.json`，MUST NOT 改動 `tasks.md`，MUST NOT 改動任何既有 per-task 條目的 `task_desc` 與 `files`，MUST NOT 提供 `--json`。既有 per-task 條目的 `task_id` MAY 因 task attribution 對齊而被改寫，`touched` 陣列 MAY 因該對齊而重新排序。條目內 `files` 與頂層 `files` MUST 維持以 UTF-8 bytes 排序去重的正規形式，頂層 `files` MUST 恰為各條目 `files` 的排序聯集，`legacy_import` 原值 MUST 保留。合併結果與載入值相同且 task attribution 對齊未改變任何內容時 MUST NOT 寫入；對齊改變了內容時 MUST 寫入，即使合併結果本身與載入值相同。`openspec/changes/<name>/` 不是目錄時 MUST 以 `change_not_found` 失敗且零寫入；未提供任何 `--path` 或 `--path` 缺值時 MUST 以 `invalid_arguments` 失敗且零寫入。`touched ensure` 除新增的 task attribution 對齊與其修復性寫入外，其餘行為 MUST 不變。

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
- **AND** 該條目的 `task_desc` 與目前 `tasks.md` 一致，且該 state 的 `touched` 已為 canonical 排序，因此 task attribution 對齊不改變任何內容
- **WHEN** 執行 `touched record demo-change --path openspec/signals/demo.md`
- **THEN** 既有 per-task 條目逐字不變
- **AND** touched state 同時含該 per-task 條目與 `review-loop` 條目
- **AND** 頂層 `files` 恰為兩個條目 `files` 的排序聯集

#### Scenario: 重複記錄相同路徑不寫入

- **GIVEN** `demo-change` 的 `review-loop` 條目已含 `openspec/signals/demo.md`
- **AND** 全部非保留條目的 `task_desc` 與目前 `tasks.md` 一致，且該 state 的 `touched` 已為 canonical 排序，因此 task attribution 對齊不改變任何內容
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
