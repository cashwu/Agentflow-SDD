## ADDED Requirements

### Requirement: Review loop 產出記入 touched 允許清單

`cash-propose` 與 `cash-apply` 的 review loop SHALL 把自身產出記入該 change 的 touched 允許清單，使這些檔案經由既有的 Cash state 權威進入 `cash-commit` 的提交集合，MUST NOT 另立第二個允許清單來源。兩個呼叫點在呼叫 `touched record` 之前都 MUST 先執行 `touched ensure`，以維持第一次 touched access 一律經由 ensure 的既有不變量。

signals write step 完成後，兩個 skill MUST 以該步驟實際建立或更新的每個 signal 檔路徑呼叫 `touched record`。某一輪的 fix actions 完成後，若該輪的 `## Fix Actions` 記錄了任何位於 `openspec/changes/<change>/` 之外的已修改檔案，兩個 skill MUST 以那些路徑再呼叫一次；該輪只改動 change 目錄內 artifacts 時不需呼叫。此條件以「檔案是否在 change 目錄之外」判定，MUST NOT 以 skill 名稱判定。

若該輪 fix actions 改到 `.cash-skills/` 之下的 runtime 檔，skill MUST 先於 project root 重建 receipt 再呼叫 `touched ensure` 與 `touched record`；未重建時 launcher 會使兩者皆以 `receipt_invalid` 失敗。傳給 `touched record` 的路徑 MUST 為 project-root-relative，且呼叫前 MUST 濾除位於 `openspec/changes/` 之下的路徑；濾除後若無任何路徑則 MUST NOT 呼叫，且 MUST NOT 產生警告。整批呼叫失敗時 MUST 以逐路徑重試取得最大合法子集，單一無法記錄的路徑 MUST NOT 連坐掉同批的其他合法路徑。

`touched ensure` 或 `touched record` 任一失敗時，skill MUST 印出警告並繼續，MUST NOT 使 workflow 失敗，MUST NOT 改變任何 round file 的 `decision`。該警告 MUST 列出未能記錄的路徑與 CLI 回傳的 `error.code`，且 MUST 同時出現在 skill 的最終完成輸出。此 requirement 適用於 `cash-propose` 與 `cash-apply` 的兩個變體（`.claude` 與 `.agents`）。

#### Scenario: signals write step 後記錄 signal 檔

- **GIVEN** review loop 已結束且 signals write step 建立或更新了一個以上的 signal 檔
- **WHEN** signals write step 完成
- **THEN** skill 先執行 `touched ensure`，再以該步驟實際建立或更新的每個 signal 檔路徑呼叫 `touched record`
- **AND** 這些路徑出現在 `.cash-skills/state/touched/<change>.json` 的 `review-loop` 條目

#### Scenario: cash-propose 在無 snapshot 時同樣記錄

- **GIVEN** `cash-propose` 從未執行 `in-progress add`，該 change 沒有 snapshot
- **WHEN** `cash-propose` 的 signals write step 完成
- **THEN** skill 仍成功記錄該步驟寫出的 signal 檔
- **AND** 不建立任何 snapshot

#### Scenario: fix actions 改到 change 目錄外時記錄

- **GIVEN** 某一輪的 `## Fix Actions` 記錄了位於 `openspec/changes/<change>/` 之外的已修改檔案
- **WHEN** 該輪的 fix actions 完成
- **THEN** skill 先執行 `touched ensure`，再以那些檔案路徑呼叫 `touched record`
- **AND** 此行為在 `cash-propose` 與 `cash-apply` 相同

#### Scenario: fix actions 只改 change 目錄內時不需記錄

- **GIVEN** 某一輪的 `## Fix Actions` 只記錄了 `openspec/changes/<change>/` 之下的已修改檔案
- **WHEN** 該輪的 fix actions 完成
- **THEN** skill 不因該輪而呼叫 `touched record`

#### Scenario: fix actions 改到 runtime 檔時先重建 receipt

- **GIVEN** 某一輪的 fix actions 改到 `.cash-skills/` 之下的 runtime 檔
- **WHEN** 該輪的 fix actions 完成
- **THEN** skill 先重建 receipt，再呼叫 `touched ensure` 與 `touched record`
- **AND** 兩個 CLI 呼叫不因 receipt drift 而失敗

#### Scenario: 濾除後無路徑時不呼叫

- **GIVEN** 某輪 fix actions 修改的 change 目錄外檔案全部位於其他 change 的 `openspec/changes/` 之下
- **WHEN** skill 依濾除規則處理該路徑集合
- **THEN** skill 不呼叫 `touched record`
- **AND** skill 不產生警告

#### Scenario: 單一無法記錄的路徑不連坐

- **GIVEN** 某次呼叫的路徑集合中混有一個 CLI 會拒絕的路徑
- **WHEN** skill 呼叫 `touched record`
- **THEN** skill 以逐路徑重試取得最大合法子集
- **AND** 警告只列出真正記不進去的路徑

#### Scenario: 記錄失敗可見且不中斷 workflow

- **WHEN** `touched ensure` 或 `touched record` 失敗
- **THEN** skill 印出警告並繼續
- **AND** 該警告列出未能記錄的路徑與 CLI 回傳的 `error.code`
- **AND** 該警告出現在 skill 的最終完成輸出
- **AND** workflow 不失敗且任何 round file 的 `decision` 不因此改變

#### Scenario: 兩個變體保持對等

- **WHEN** 比較 `.claude` 與 `.agents` 兩個變體中 `cash-propose` 與 `cash-apply` 的 review loop 記錄段落
- **THEN** 兩者在 invocation 前綴（`/cash-` 與 `$cash-`）正規化後 MUST 完全相同

### Requirement: cash-commit 呈現 review loop 產出並裁決共用 signal 檔

`cash-commit` SHALL 把 touched state 中 `task_id` 為 `review-loop` 的保留條目與 per-task 條目分開呈現，於 commit plan 新增獨立的 `### Review Loop Outputs` 區段列示該條目的檔案。該條目的檔案與 per-task 檔案同樣屬於提交集合。

對該條目中位於 `openspec/signals/` 的檔案，`cash-commit` MUST 讀取其 frontmatter `links`；只有當某條 link 形如 `openspec/changes/<other>/reviews/`、`<other>` 不等於本 change 名稱、且 `openspec/changes/<other>/` 或 `openspec/changes/.parked/<other>/` 其中之一目前仍存在時，該檔才 MUST 被標示為共用。指向已封存 change 的 link MUST NOT 觸發共用判定。共用檔 MUST 要求使用者明確選擇整檔納入或整檔排除；`cash-commit` MUST NOT 靜默納入共用檔，MUST NOT 靜默排除共用檔，且 MUST NOT 嘗試把單一檔案依 change 拆分。使用者選擇整檔排除時，該檔 MUST 改列於 commit plan 的 Unrelated Changes 區段並註明係使用者裁決排除，且最終輸出 MUST 提醒該檔仍為 dirty。此為對「不在 artifact set 且不在 tracking file 才算 Unrelated」既有判定的明確例外。

`cash-commit` 的封存後空允許清單復原路徑 MUST 對其來源允許清單中位於 `openspec/signals/` 的路徑套用同一組共用判定與裁決。`cash-commit` 在封存子流程後產出的更新版 commit plan MUST 同樣保留 `### Review Loop Outputs` 區段，內容沿用封存前已確認的集合。使用者確認步驟中「依所示提交」的選項說明 MUST 明示涵蓋 `### Review Loop Outputs` 區段。當使用者以「納入全部 dirty 檔案」或自訂調整把一個已被裁決排除的共用 signal 檔加回時，`cash-commit` MUST 先告知該操作會推翻先前的裁決並取得確認；當使用者以自訂調整移除一個已裁決納入的共用檔時，該檔 MUST 一併移入 Unrelated Changes 並沿用同一註記，不得從 commit plan 消失。此 requirement 適用於 `cash-commit` 的兩個變體（`.claude` 與 `.agents`）。

#### Scenario: review loop 產出獨立成區段

- **GIVEN** touched state 同時含 per-task 條目與 `review-loop` 條目
- **WHEN** `cash-commit` 顯示 commit plan
- **THEN** commit plan 含獨立的 `### Review Loop Outputs` 區段列示 `review-loop` 條目的檔案
- **AND** 該區段的檔案不混入 per-task 的 Source Files 區段
- **AND** 該區段的檔案屬於提交集合

#### Scenario: 指向 active change 的 link 觸發裁決

- **GIVEN** `review-loop` 條目含一個位於 `openspec/signals/` 的檔案
- **AND** 該檔 frontmatter 的 `links` 含一條指向其他 change 之 reviews 目錄的路徑
- **AND** 該其他 change 的 `openspec/changes/<other>/` 或 `openspec/changes/.parked/<other>/` 其中之一目前仍存在
- **WHEN** `cash-commit` 顯示 commit plan
- **THEN** `cash-commit` 把該檔標示為共用
- **AND** `cash-commit` 要求使用者選擇整檔納入或整檔排除
- **AND** `cash-commit` 說明單一檔案無法依 change 拆分

#### Scenario: 指向已封存 change 的 link 不觸發裁決

- **GIVEN** `review-loop` 條目含一個位於 `openspec/signals/` 的檔案
- **AND** 該檔的 `links` 只指向本 change 以及已封存 change 的 reviews 目錄
- **AND** 那些已封存 change 的 `openspec/changes/<other>/` 與 `openspec/changes/.parked/<other>/` 皆不存在
- **WHEN** `cash-commit` 顯示 commit plan
- **THEN** 該檔列於 `### Review Loop Outputs` 區段且不被標示為共用
- **AND** `cash-commit` 不為該檔要求額外裁決

#### Scenario: 依所示提交涵蓋 review loop 產出

- **GIVEN** commit plan 含 `### Review Loop Outputs` 區段
- **WHEN** 使用者選擇依所示提交
- **THEN** 該區段的檔案被納入 staging

#### Scenario: 加回已裁決排除的共用檔需再次確認

- **GIVEN** 某個共用 signal 檔已被使用者裁決排除並列於 Unrelated Changes
- **WHEN** 使用者以「納入全部 dirty 檔案」或自訂調整把該檔加回
- **THEN** `cash-commit` 告知該操作會推翻先前的裁決並取得確認
- **AND** `cash-commit` 不靜默納入該檔

#### Scenario: 裁決為排除時仍出現在 commit plan

- **GIVEN** 某個共用 signal 檔已被標示為共用
- **WHEN** 使用者選擇整檔排除
- **THEN** 該檔改列於 commit plan 的 Unrelated Changes 區段
- **AND** 該項註明係使用者裁決排除
- **AND** 最終輸出提醒該檔仍為 dirty

#### Scenario: 封存後路徑同樣套用共用裁決

- **GIVEN** `cash-commit` 走封存後空允許清單復原路徑
- **AND** 其來源允許清單含位於 `openspec/signals/` 的路徑
- **WHEN** `cash-commit` 顯示 commit plan
- **THEN** `cash-commit` 對那些路徑套用同一組共用判定與裁決
- **AND** 共用檔不被靜默納入

#### Scenario: 封存子流程後的更新版 plan 保留區段

- **GIVEN** 使用者在 `cash-commit` 中選擇先封存再一起提交
- **WHEN** `cash-commit` 顯示封存後的更新版 commit plan
- **THEN** 該 plan 保留 `### Review Loop Outputs` 區段
- **AND** 該區段的內容沿用封存前已確認的集合

#### Scenario: 兩個變體保持對等

- **WHEN** 比較 `.claude/skills/cash-commit/SKILL.md` 與 `.agents/skills/cash-commit/SKILL.md` 的 review loop 產出段落
- **THEN** 兩者在 invocation 前綴（`/cash-` 與 `$cash-`）正規化後 MUST 完全相同
