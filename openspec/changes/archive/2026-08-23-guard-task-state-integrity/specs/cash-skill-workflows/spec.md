## ADDED Requirements

### Requirement: cash-archive 未完成 task 的處置與失敗指引

`cash-archive` 在偵測到未完成 task 時 SHALL 提供可到達的出口，MUST NOT 讓使用者在確認繼續之後撞上無指引的失敗。其未完成 task 分支 MUST 恰有兩條互斥且窮盡的出路：選擇標記完成時 MUST 設定 `--mark-tasks-complete` 旗標並繼續封存；選擇不標記時 MUST 停止且 MUST NOT 以未完成 task 呼叫 `archive`。此處置 MUST 與 `cash-commit` archive-first 子流程的未完成 task 提問對稱。

`cash-archive` 執行封存的步驟 MUST 對 `tasks_incomplete` 提供失敗指引，且該指引 MUST 只列出實際有效的出路：以 `--mark-tasks-complete` 重跑。該指引 MUST 明確指出 `--skip-specs` 與 `--no-validate` 都不繞過此前置條件，因為 `.cash-skills/lib/cash_cli/commands/archive.py` 中該錯誤只由 `--mark-tasks-complete` 單獨守門。

`cash-archive` 執行封存的步驟 MUST 讓 `--mark-tasks-complete` 在執行層可見：其 command 範例 MUST 含一行帶該旗標的形式，使解析出的旗標有可照抄的落點，與 `cash-commit` archive-first 子流程的 command 範例對稱。

`cash-archive` 執行封存的步驟 MUST 同樣為 `touched_invalid` 提供復原指引，並 MUST 把 renamed 與 removed task 分成互斥分支。Renamed task 存在現行描述時，指引 MUST 說明把 touched entry 的 `task_desc` 同步為該現行描述後重跑封存，且 MUST 明訂這是唯一允許的 touched state 手工編輯。Removed task 沒有現行描述時，指引 MUST 停止封存並導向無參數 `/cash-ingest`，把目前的 `touched_invalid` 與 change name 作為 conversation context，使 ingest 選取既有 change、把 exact `task_desc` 恢復為 `tasks.md` 中已完成的 `[x]` task 後重跑；此分支 MUST NOT 編輯、刪除或重新歸屬 touched entry，因為其 `files` 仍歸屬該歷史 task。若 exact `task_desc` 的 label 已被佔用，MUST 先由同一個無參數 `/cash-ingest` context 解決 artifact label 衝突，MUST NOT 猜測新 label。

此 requirement 適用於 `.claude` 與 `.agents` 兩個變體，正規化 invocation 前綴後兩者的相關段落 MUST 完全相同。

#### Scenario: 選擇標記完成則帶旗標繼續

- **GIVEN** change `demo-change` 的 `tasks.md` 存在未完成的 `- [ ]` 條目
- **WHEN** `cash-archive` 抵達 task 完成度檢查步驟
- **AND** 使用者選擇標記全部為完成
- **THEN** `cash-archive` 設定 `--mark-tasks-complete` 旗標
- **AND** 以帶該旗標的方式執行封存

#### Scenario: 選擇不標記則停止且不呼叫 archive

- **GIVEN** change `demo-change` 的 `tasks.md` 存在未完成的 `- [ ]` 條目
- **WHEN** `cash-archive` 抵達 task 完成度檢查步驟
- **AND** 使用者選擇不標記為完成
- **THEN** `cash-archive` 停止
- **AND** MUST NOT 呼叫 `.cash-skills/bin/cash archive demo-change`

#### Scenario: tasks_incomplete 的失敗指引只列有效出路

- **WHEN** `.cash-skills/bin/cash archive demo-change` 以 `tasks_incomplete` 失敗
- **THEN** `cash-archive` 報告確切錯誤
- **AND** 指引使用者以 `--mark-tasks-complete` 重跑
- **AND** 指引明確指出 `--skip-specs` 與 `--no-validate` 都不繞過此前置條件

#### Scenario: cash-archive 對 renamed task 有復原指引

- **GIVEN** change `demo-change` 的 touched state 有一筆 `task_desc` 已不存在於 `tasks.md` 的條目
- **AND** 該 task 在 `tasks.md` 有可確認的現行描述
- **WHEN** `.cash-skills/bin/cash archive demo-change` 以 `touched_invalid` 失敗並指名該 `task_desc`
- **THEN** `cash-archive` 的指引說明把該條目的 `task_desc` 同步為該 task 的現行描述後重跑封存
- **AND** 指引明訂該編輯是唯一允許的 touched state 手工編輯
- **AND** 指引 MUST NOT 建議刪除該 state 檔

#### Scenario: cash-archive 對 removed task 恢復完成紀錄

- **GIVEN** change `demo-change` 的 touched state 有一筆 `task_desc` 已不存在於 `tasks.md` 的條目
- **AND** 該 task 已從 `tasks.md` 移除，沒有可同步的現行描述
- **WHEN** `.cash-skills/bin/cash archive demo-change` 以 `touched_invalid` 失敗並指名該 `task_desc`
- **THEN** `cash-archive` 停止封存並引導使用者執行無參數 `/cash-ingest`
- **AND** 指引把目前的 `touched_invalid` 與 change name `demo-change` 作為 conversation context，使 ingest 選取既有 change
- **AND** ingest 把 exact `task_desc` 恢復為 `tasks.md` 中的 `[x]` task
- **AND** touched entry 的 `task_desc` 與 `files` MUST 保持不變
- **AND** 恢復後重跑封存時，既有對齊機制依恢復 task 的目前位置更新 `task_id`

#### Scenario: removed task 的 label 衝突不猜測

- **GIVEN** removed task 的 exact `task_desc` 所含 label 已被另一條 task 使用
- **WHEN** 使用者依 `cash-archive` 指引處理 `touched_invalid`
- **THEN** 指引 MUST 要求先以 `/cash-ingest` 解決 artifact label 衝突
- **AND** MUST NOT 猜測新 label、改寫 touched entry 或把 `files` 重新歸屬其他 task

#### Scenario: 全部 task 完成時不發問

- **GIVEN** change `demo-change` 的 `tasks.md` 全部條目為 `- [x]`
- **WHEN** `cash-archive` 抵達 task 完成度檢查步驟
- **THEN** `cash-archive` 不就未完成 task 向使用者發問
- **AND** 不設定 `--mark-tasks-complete` 旗標

#### Scenario: 旗標在執行層可見

- **WHEN** 檢視 `cash-archive` 執行封存步驟的 command 範例
- **THEN** 範例含一行帶 `--mark-tasks-complete` 的形式
- **AND** `cash-commit` archive-first 子流程的 command 範例同樣把該旗標寫進 command 範例，兩者皆使該旗標在執行層可見（兩者的呈現形式不同：`cash-archive` 為獨立一行的具體形式，`cash-commit` 為單行括號可選式）

#### Scenario: 兩個變體保持對等

- **WHEN** 比較 `.claude/skills/cash-archive/SKILL.md` 與 `.agents/skills/cash-archive/SKILL.md` 的 task 完成度檢查步驟與封存失敗處置
- **THEN** 兩者在 invocation 前綴（`/cash-` 與 `$cash-`）正規化後 MUST 完全相同

### Requirement: cash-commit 對 touched_invalid 的復原指引

`cash-commit` 的來源允許清單建立步驟 SHALL 為 `touched ensure` 的 `touched_invalid` 失敗提供復原指引，並 MUST 把 renamed 與 removed task 分成互斥分支。Renamed task 存在現行描述時，指引 MUST 說明更新 touched entry 的 `task_desc` 後重跑 ensure，且 MUST 明訂這是唯一允許的 touched state 手工編輯。Removed task 沒有現行描述時，指引 MUST 停止 commit 並導向無參數 `/cash-ingest`，把目前的 `touched_invalid` 與 change name 作為 conversation context，使 ingest 選取既有 change 並恢復 exact `task_desc` 對應的 `[x]` task；MUST NOT 編輯、刪除或重新歸屬 touched entry。Label 衝突 MUST 由相同的 ingest context 修正 artifacts，MUST NOT 猜測新 label。

此 requirement 適用於 `.claude` 與 `.agents` 兩個變體，正規化 invocation 前綴後兩者的相關段落 MUST 完全相同。

#### Scenario: cash-commit 對 renamed task 有復原指引

- **GIVEN** change `demo-change` 的 touched state 有一筆 `task_desc` 已不存在於 `tasks.md` 的條目
- **AND** 該 task 在 `tasks.md` 有可確認的現行描述
- **WHEN** `cash-commit` 在建立來源允許清單前執行 `touched ensure demo-change` 並得到 `touched_invalid`
- **THEN** `cash-commit` 的指引說明把該條目的 `task_desc` 同步為該 task 的現行描述後重跑 ensure
- **AND** 指引明訂該編輯是唯一被允許的手工編輯
- **AND** 指引 MUST NOT 建議刪除該 state 檔

#### Scenario: cash-commit 對 removed task 恢復完成紀錄

- **GIVEN** change `demo-change` 的 touched state 有一筆 `task_desc` 已不存在於 `tasks.md` 的條目
- **AND** 該 task 已從 `tasks.md` 移除，沒有可同步的現行描述
- **WHEN** `cash-commit` 在建立來源允許清單前執行 `touched ensure demo-change` 並得到 `touched_invalid`
- **THEN** `cash-commit` 停止並引導使用者執行無參數 `/cash-ingest`
- **AND** 指引把目前的 `touched_invalid` 與 change name `demo-change` 作為 conversation context，使 ingest 選取既有 change
- **AND** ingest 把 exact `task_desc` 恢復為 `tasks.md` 中的 `[x]` task
- **AND** touched entry 的 `task_desc` 與 `files` MUST 保持不變
- **AND** 恢復後重跑 ensure MUST 成功並把 `task_id` 對齊至恢復 task 的目前位置

#### Scenario: 兩個變體保持對等

- **WHEN** 比較 `.claude/skills/cash-commit/SKILL.md` 與 `.agents/skills/cash-commit/SKILL.md` 的來源允許清單建立步驟
- **THEN** 兩者在 invocation 前綴（`/cash-` 與 `$cash-`）正規化後 MUST 完全相同
