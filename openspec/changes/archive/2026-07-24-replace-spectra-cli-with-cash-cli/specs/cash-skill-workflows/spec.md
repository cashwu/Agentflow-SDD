## MODIFIED Requirements

### Requirement: Cash namespace 負責 workflow 路由，Spectra 仍是 artifact 引擎

Cash skills SHALL 在每一次 skill 之間的轉換使用 cash namespace。Codex 指示 MUST 使用 `$cash-*`；Claude 指示 MUST 使用對應的 `/cash-*` 語法。Artifact 操作 MUST 繼續使用 Cash CLI 與設定的 `openspec/` 路徑。

#### Scenario: 內部 workflow 轉換

- **WHEN** `cash-discuss` 建議將某項決策正式化
- **THEN** 它引導使用者前往 `cash-propose`
- **AND** 它不引導使用者前往任何 `spectra-*` 或 `cash-*-plus` skill

#### Scenario: Artifact 指令由 Cash 擁有

- **WHEN** 某個 cash skill 列出、建立、驗證、分析或封存 artifacts
- **THEN** 它呼叫適用的 `.cash-skills/bin/cash` CLI 指令
- **AND** 它讀取或寫入設定的 `openspec/` artifact 路徑
- **AND** 它不引入 Spectra CLI 轉接層



### Requirement: Cash 提案品質關卡

`cash-propose` SHALL 依照 Cash artifact DAG 建立 proposal、design、delta specs 與 tasks，執行 `.cash-skills/bin/cash validate`，然後每個 change 執行一次共用的評分審查迴圈。它 MUST 以繁體中文撰寫非 spec artifacts 與審查文字、spec 檔依 Spec 檔案語言政策撰寫（繁體中文內文、英文結構關鍵字與規範動詞）、讓該 change 保持 active，且 MUST NOT 呼叫 apply 或 park。

#### Scenario: 驗證先於審查

- **WHEN** apply 所需的全部 artifacts 都已建立
- **THEN** `cash-propose` 執行 `.cash-skills/bin/cash validate "<change>"`
- **AND** 在開始審查 round 1 之前修正驗證失敗
- **AND** 每當 fix action 更動任一 artifact 時，在下一輪之前重新驗證

#### Scenario: 提案 workflow 結束時不進入 apply

- **WHEN** 提案審查迴圈以 `passed` 或 `aborted` 結束
- **THEN** `cash-propose` 記錄最終回合與摘要
- **AND** 將該 change 留在 `openspec/changes/` 之下
- **AND** 不呼叫 `cash-apply` 或 `.cash-skills/bin/cash park`

#### Scenario: 大型 impact 清單產生 advisory

- **WHEN** proposal 的 `## Impact` 在排除 `(none)` 佔位項並將每個目錄計為一個項目後，包含 16 個受影響程式碼項目
- **THEN** `cash-propose` 印出一則非阻斷的按能力拆分 advisory
- **WHEN** 相同計數為 15
- **THEN** `cash-propose` 不印出任何 impact-granularity advisory



### Requirement: cash-propose 品質關卡

系統 SHALL 提供一個 `cash-propose` skill，保留 proposal、design、specs 與 tasks 的完整 artifact 建立合約（proposal、design、specs、tasks），但以 sub-agent 審查／評分／修正迴圈取代行內自我審查與 analyze-fix 迴圈。該 skill MUST 在進入 sub-agent 迴圈之前執行 `.cash-skills/bin/cash validate`，使驗證修正發生在品質關卡審查最終 artifact 狀態之前。該 skill MUST 以 per-change 粒度執行迴圈（在所有必要 artifacts 寫入且驗證通過之後，而非逐 artifact）。該 skill MUST 將迴圈上限設為 6 輪。該 skill MUST NOT 使用 rater sub-agent 且 MUST NOT 產生 `quality_score`；主 agent SHALL 改為從過濾後的 findings 以機械方式推導該輪決策。當且僅當信心過濾後沒有任何存活 finding 具 `severity == Critical` 也沒有任何存活 finding 具 `severity == Warning` 時，該次執行的第一輪 MUST 被視為通過；在累積 blocking 集合已被 seed 的重跑中，第一輪改依 `分級收斂與 micro 驗證輪` requirement 使用累積 blocking 集合的通過條件。當且僅當信心過濾後累積 blocking 集合不含任何 `Critical` 也不含任何 `Warning` finding 時，該次執行第一輪之後的一輪 MUST 被視為通過，其中 blocking 與累積 blocking 集合由 `分級收斂與 micro 驗證輪` requirement 定義；非 blocking findings 依該 requirement 進入 triage。當某一輪的決策為 `next_round` 時，主 agent MUST 依 `分級收斂與 micro 驗證輪` requirement 推導下一輪的型別（full 或 micro）。本 requirement 中的修正義務受 `審查迴圈的 grader 不可變性` requirement 定義的 grader 保護例外，以及 `接受風險 ledger` 與 `審查輪的行動義務` requirements 定義的經同意接受風險路徑所約束。該 skill MUST NOT 在其 workflow 結尾執行 `.cash-skills/bin/cash park`。

#### Scenario: 迴圈在達到輪數上限前滿足通過條件

- **WHEN** 某一輪完成時，信心過濾後的累積 blocking 集合為空
- **THEN** 該 skill 寫入對應的 round 檔案並記錄 `decision: passed`
- **AND** 停止迴圈且不再開始另一輪
- **AND** 直接進入最終摘要，不執行關卡後的驗證修正
- **AND** 不執行 `.cash-skills/bin/cash park`

#### Scenario: 驗證先於品質關卡

- **WHEN** `cash-propose` 已建立 apply 所需的全部 artifacts
- **THEN** 它執行 `.cash-skills/bin/cash validate "<name>"`
- **AND** 在第一個審查迴圈輪之前修正驗證錯誤
- **AND** 審查迴圈僅在驗證通過後才開始

- **WHEN** 審查迴圈的 Fix Action 修改了 proposal、design、tasks 或 spec artifacts
- **THEN** 它再次執行 `.cash-skills/bin/cash validate "<name>"`
- **AND** 在開始下一個審查迴圈輪之前修正驗證錯誤

#### Scenario: 存活的 blocking Warning 迫使再進行一輪

- **WHEN** 某一輪完成時，信心過濾後的累積 blocking 集合中沒有 blocking `Critical` finding，但至少有一個 blocking `Warning` finding
- **THEN** 該 skill 寫入 round 檔案並記錄 `decision: next_round`
- **AND** 在開始下一輪之前修正這些 blocking Warning findings，但下列除外：依 `審查迴圈的 grader 不可變性` requirement 被保留不修的 finding（記錄為 unfixed-due-to-grader-protection 且維持存活），以及經 `接受風險 ledger` requirement 同意路徑接受的 finding（記錄為 downgrade trace 並自累積 blocking 集合移除）
- **AND** 依 `分級收斂與 micro 驗證輪` requirement 推導下一輪的型別

#### Scenario: 迴圈到達 6 輪上限仍未通過

- **WHEN** 迴圈完成 6 輪仍未滿足通過條件
- **THEN** 該 skill 寫入第六輪並記錄 `decision: aborted`
- **AND** 印出摘要說明未解決 findings 的警告
- **AND** 依 `Abort 後的 triage` requirement 執行 abort triage
- **AND** 結束 workflow 而不 park 該 change

#### Scenario: 永不呼叫 park

- **WHEN** `cash-propose` 在任何結果下結束其 workflow
- **THEN** 該 workflow 永不呼叫 `.cash-skills/bin/cash park`
- **AND** change 目錄仍保留在 `openspec/changes/` 之下（未被 park）

##### Example: workflow 結尾路徑比較

| Skill | 行內自我審查 | Analyze-fix 迴圈 | Sub-agent 迴圈（上限 6） | 結尾 park |
| ----- | ------------------ | ---------------- | ---------------------- | ----------- |
| Legacy baseline（已移除） | 是 | 是（上限 2）  | 否  | 是 |
| cash-propose  | 否  | 否           | 是 | 否  |





### Requirement: cash-apply 品質關卡

系統 SHALL 提供一個 `cash-apply` skill，保留完整的任務執行合約，並在所有 tasks 完成後附加一個 sub-agent 審查／評分／修正迴圈。該 skill MUST 以 per-change 粒度執行迴圈（僅一次，在 `tasks.md` 中每個 task 都標記完成之後）。該 skill MUST 將迴圈上限設為 6 輪。該 skill MUST NOT 在審查迴圈以 `decision: passed` 結束之前建議封存該 change。該 skill MUST NOT 使用 rater sub-agent 且 MUST NOT 產生 `quality_score`；主 agent SHALL 改為從過濾後的 findings 以機械方式推導該輪決策。當且僅當信心過濾後沒有任何存活 finding 具 `severity == Critical` 也沒有任何存活 finding 具 `severity == Warning` 時，該次執行的第一輪 MUST 被視為通過；在累積 blocking 集合已被 seed 的重跑中，第一輪改依 `分級收斂與 micro 驗證輪` requirement 使用累積 blocking 集合的通過條件。當且僅當信心過濾後累積 blocking 集合不含任何 `Critical` 也不含任何 `Warning` finding 時，該次執行第一輪之後的一輪 MUST 被視為通過，其中 blocking 與累積 blocking 集合由 `分級收斂與 micro 驗證輪` requirement 定義；非 blocking findings 依該 requirement 進入 triage。當某一輪的決策為 `next_round` 時，主 agent MUST 依 `分級收斂與 micro 驗證輪` requirement 推導下一輪的型別（full 或 micro）。本 requirement 中的修正義務受 `審查迴圈的 grader 不可變性` requirement 定義的 grader 保護例外，以及 `接受風險 ledger` 與 `審查輪的行動義務` requirements 定義的經同意接受風險路徑所約束。

#### Scenario: 審查迴圈在 tasks 完成後執行

- **WHEN** `tasks.md` 中的每個 checkbox 皆為 `[x]`
- **THEN** `cash-apply` 開始 sub-agent 審查／評分／修正迴圈
- **AND** 不會更早開始該迴圈

#### Scenario: 存活的 blocking Critical 迫使再進行一輪

- **WHEN** 某一輪完成時，信心過濾後的累積 blocking 集合中至少有一個 blocking `Critical` finding
- **THEN** 該 skill 寫入 round 檔案並記錄 `decision: next_round`
- **AND** 在開始下一輪之前修正這些 blocking Critical findings，但下列除外：依 `審查迴圈的 grader 不可變性` requirement 被保留不修的 finding（記錄為 unfixed-due-to-grader-protection 且維持存活），以及經 `接受風險 ledger` requirement 同意路徑接受的 finding（記錄為 downgrade trace 並自累積 blocking 集合移除）
- **AND** 依 `分級收斂與 micro 驗證輪` requirement 推導下一輪的型別

#### Scenario: 迴圈到達 6 輪上限

- **WHEN** 迴圈完成 6 輪仍未滿足通過條件
- **THEN** 該 skill 寫入第六輪並記錄 `decision: aborted`
- **AND** 印出摘要說明未解決 findings 的警告
- **AND** 依 `Abort 後的 triage` requirement 執行 abort triage
- **AND** 結束 workflow

#### Scenario: 封存指引等待關卡通過

- **WHEN** 所有 tasks 已完成但審查迴圈尚未通過
- **THEN** `cash-apply` 說明封存指引將延後至 cash 品質關卡通過之後
- **AND** 不指示使用者執行 `.cash-skills/bin/cash archive`、`/cash-archive` 或 `$cash-archive`

- **WHEN** 最終審查迴圈輪為 `decision: passed`
- **THEN** 最終回覆可以建議封存該 change





### Requirement: cash-commit 的 archive-first 允許清單

系統 SHALL 使 `cash-commit` 在 `.cash-skills/bin/cash archive` 完成後，透過明確的允許清單收集 archive-first 提交檔案。archive-first 提交集合 MUST 包含封存前已確認提交集合中的 tracked 來源檔案、屬於所選 change 封存的檔案，以及使用者在封存子流程中明確選擇 spec sync 時來自 `openspec/specs/` 的 spec sync 檔案。archive-first 提交集合 MUST NOT 包含封存後 `git status --porcelain` 掃描發現的無關 dirty 檔案。

#### Scenario: archive-first 提交前已存在無關刪除

- **WHEN** `cash-commit` 在啟用 archive-first 下提交 change `demo-change`
- **AND** 在 `.cash-skills/bin/cash archive demo-change` 執行之前，`git status --porcelain` 已含有 `D .agents/skills/cash-apply/SKILL.md`
- **THEN** 預設提交集合排除 `.agents/skills/cash-apply/SKILL.md`
- **AND** 提交計畫將該刪除顯示在被納入的封存相關檔案之外

#### Scenario: 封存成功後納入封存檔案

- **WHEN** `.cash-skills/bin/cash archive demo-change` 將檔案從 `openspec/changes/demo-change/` 移至 `openspec/changes/archive/2026-05-19-demo-change/`
- **THEN** `cash-commit` 納入 `openspec/changes/demo-change/` 之下的刪除
- **AND** `cash-commit` 納入 `openspec/changes/archive/2026-05-19-demo-change/` 之下的新增或修改
- **AND** `cash-commit` 排除所選 change 封存、tracked 來源檔案與明確選擇的 spec sync 檔案以外的 dirty 檔案

#### Scenario: spec sync 檔案需要明確的 sync 選擇

- **WHEN** 使用者在 `demo-change` 的封存子流程中選擇 spec sync
- **THEN** `cash-commit` 納入 `openspec/specs/` 之下的相應變更
- **AND** 更新後的提交計畫將它們顯示為 Spec Sync Changes

#### Scenario: 封存路徑措辭為現行版本

- **WHEN** `cash-commit` 顯示更新後的 archive-first 提交計畫
- **THEN** 封存檔案區段標明 `openspec/changes/archive/<date>-<change>/`
- **AND** archive-first workflow 文字不提及 `openspec/archived/`





### Requirement: 審查迴圈的 grader 不可變性

canonical 的 Claude 與 Codex `cash-propose` 與 `cash-apply` skill 檔案 SHALL 各自包含一條以唯一的 sentinel 註解 `<!-- GRADER-IMMUTABILITY -->` 標記的 grader 不可變性規則。在 cash 審查迴圈期間，主 agent MUST NOT 修改——無論是作為修正動作或作為機械自我檢查的修正——受保護 grader 路徑集合中的任何檔案：`.claude/skills/cash-propose/SKILL.md`、`.claude/skills/cash-apply/SKILL.md`、`.agents/skills/cash-propose/SKILL.md`、`.agents/skills/cash-apply/SKILL.md`、`.cash.yaml`、`scripts/cash-skills/tests/skill-checks.fish`、`scripts/cash-cli/tests/cli-checks.fish`，以及 `openspec/specs/` 之下的 master spec 檔案——除非該檔案被當前 change 的結構化範圍宣告明確指名。結構化範圍宣告僅限於 proposal `## Impact` affected-code 條目中的專案根相對路徑，以及 `tasks.md` 中被明確標識為交付目標的專案根相對路徑。僅出現在驗證指令、規則描述、範例、審查 finding、reviewer 情境或其他附帶性文字中的路徑 MUST NOT 計為結構化範圍宣告。在結構化範圍宣告中指名一個目錄路徑即指名其下的所有檔案。已在進行中的迴圈依其開始時的 canonical 指令版本繼續；對 cash skill 的範圍內編輯自下一次迴圈執行起生效。此外，無論宣告範圍為何，主 agent MUST NOT 新增、修改或移除 `openspec/signals/` 之下任何 signal 的 `check` frontmatter 欄位——`check` 欄位是每輪前機械自我檢查的 grader 輸入。當解決一個存活 finding 需要修改該結構化範圍之外的受保護檔案，或觸及 signal 的 `check` 欄位時，修正動作 MUST NOT 執行該修改、MUST 在 `## Fix Actions` 記錄一則 unfixed-due-to-grader-protection 註記並指名該檔案與該 finding，且該 finding 就該輪決策而言維持存活。無論最終決策為何，cash workflow 的完成輸出 MUST 列出迴圈任何一輪所記錄的每則 unfixed-due-to-grader-protection 註記：對 `decision: passed` 的 `cash-propose`，這些註記 MUST 列在最終摘要中；對 `decision: passed` 的 `cash-apply`，這些註記 MUST 列在 gate-complete 最終回應中；對任何 `decision: aborted`，這些註記 MUST 列在未解決 findings 警告中。在結構化範圍例外之下被修改的受保護檔案，視同其他任何修正動作的修改，且不改變下一輪的型別——依 `分級收斂與 micro 驗證輪` requirement，型別僅從其在本次執行中的位置推導。此規則 MUST 適用於兩個變體中的兩個 cash workflows。

#### Scenario: 範圍外的 grader 修改被拒絕

- **WHEN** 某個審查迴圈 finding 的建議需要編輯 `.agents/skills/cash-propose/SKILL.md`，而當前 change 的結構化範圍宣告未指名該檔案
- **THEN** 修正動作不修改 `.agents/skills/cash-propose/SKILL.md`
- **AND** 該輪檔案的 `## Fix Actions` 記錄一則 unfixed-due-to-grader-protection 註記，指名該檔案與該 finding
- **AND** 該 finding 仍計入該輪決策

#### Scenario: 附帶性的受保護路徑文字不解鎖 grader 檔案

- **WHEN** `tasks.md` 僅在描述 grader 保護規則或驗證步驟時提及 `openspec/specs/`
- **THEN** 該提及不計為結構化範圍宣告
- **AND** 主 agent MUST NOT 經由 grader 不可變性例外修改 `openspec/specs/` 之下的檔案

#### Scenario: Signal 的 check 欄位從不被修正動作修改

- **WHEN** 某個每輪前自我檢查的 `check` 指令失敗，且修正動作可藉由弱化或移除該 signal 的 `check` 欄位使其通過
- **THEN** 修正動作不新增、修改也不移除任何 signal 的 `check` 欄位
- **AND** 底層缺陷改在該 change 自身的 artifacts 或檔案中修正

#### Scenario: 已宣告範圍內的 grader 檔案維持可修改

- **WHEN** 當前 change 的結構化範圍宣告明確指名 `.agents/skills/cash-propose/SKILL.md`，且某個修正動作修改該檔案
- **THEN** 該 canonical skill 修改是被允許的
- **AND** 該修改不改變下一輪的型別，型別僅從其在本次執行中的位置推導

#### Scenario: 完成輸出錨定 grader 保護紀錄

- **WHEN** 迴圈的任何一輪記錄了 unfixed-due-to-grader-protection 註記，且迴圈其後以 `cash-propose` 的 `decision: passed` 結束
- **THEN** 最終摘要列出迴圈每一輪的每則此類註記

- **WHEN** 迴圈的任何一輪記錄了 unfixed-due-to-grader-protection 註記，且迴圈其後以 `cash-apply` 的 `decision: passed` 結束
- **THEN** gate-complete 最終回應列出迴圈每一輪的每則此類註記

- **WHEN** 迴圈的任何一輪記錄了 unfixed-due-to-grader-protection 註記，且迴圈以 `decision: aborted` 結束
- **THEN** 未解決 findings 警告列出迴圈每一輪的每則此類註記

#### Scenario: Canonical skills 帶有 grader 不可變性 sentinel

- **WHEN** 檢視四個 canonical 的 cash proposal 與 apply skill 檔案
- **THEN** 每個檔案皆含有 `<!-- GRADER-IMMUTABILITY -->` sentinel 與受保護 grader 路徑集合
- **AND** `scripts/cash-skills/tests/skill-checks.fish` 斷言該 sentinel 的存在





### Requirement: Spec 檔案語言政策

所有 spec 檔（openspec/changes/<change>/specs/<capability>/spec.md 的 delta spec 與 openspec/specs/<capability>/spec.md 的 master spec）的內文 SHALL 以繁體中文撰寫，包含 Requirement 敘述、Scenario 步驟、Example 說明與 Purpose 段落。下列結構關鍵字 MUST 逐字保留英文：`## ADDED Requirements`、`## MODIFIED Requirements`、`## REMOVED Requirements`、`## RENAMED Requirements`、`### Requirement:`、`#### Scenario:`、`##### Example:`，以及 Scenario 步驟中的 **GIVEN** / **WHEN** / **THEN** / **AND** 標記。規範動詞 SHALL / MUST / SHOULD / MAY MUST 以英文嵌入中文句子使用。程式識別字、檔案路徑、CLI 指令、schema 欄位名，以及自其他文件引用的原文 MUST 逐字保留，不得翻譯。openspec/changes/archive/ 下的歷史 spec 檔為歷史紀錄，不受本政策約束，SHALL NOT 回溯翻譯。

#### Scenario: 新撰寫的 delta spec 使用中文內文與英文結構關鍵字

- **WHEN** cash-propose 為某 capability 產生 delta spec
- **THEN** Requirement 敘述與 Scenario 步驟以繁體中文撰寫
- **AND** 結構關鍵字（如 `### Requirement:`、`#### Scenario:`、**WHEN** / **THEN**）維持英文
- **AND** 規範動詞（SHALL / MUST）以英文嵌入中文句子

##### Example: 符合政策的 requirement 條文

- **GIVEN** 一條關於匯出功能的需求
- **WHEN** 依本政策撰寫其 spec 條文
- **THEN** 條文形如：「系統 SHALL 在使用者觸發匯出時，將結果寫入 `exports/` 目錄，且檔名 MUST 使用 `YYYY-MM-DD` 前綴。」

#### Scenario: 引用原文與識別字不翻譯

- **WHEN** spec 條文需要引用 SKILL.md 或其他英文文件中的字面內容（例如 `None; pass condition met.`）
- **THEN** 該引用逐字保留英文原文
- **AND** 檔案路徑與 CLI 指令（例如 `.cash-skills/bin/cash validate --strict`）逐字保留



### Requirement: Requirement 標題是合併身分鍵

delta spec 中 `## MODIFIED Requirements` 與 `## REMOVED Requirements` 區段下的每個 `### Requirement:` 標題、以及 `## RENAMED Requirements` 區段中的 FROM 標題，MUST 從對應 master spec 現行內容逐字（byte-for-byte）複製，不得重打、改寫或翻譯。cash-propose 與 cash-apply 的 pre-round mechanical self-check MUST 對上述每個標題執行存在性檢查（**Spec delta title-identity check**）：標題必須逐字存在於對應 master spec `openspec/specs/<capability>/spec.md` 的 `### Requirement:` 標題集合中；master spec 尚不存在的 capability SHALL 跳過此檢查。任何不吻合 MUST 視為 self-check 失敗，並且 MUST 在 spawn reviewers 之前以「從 master spec 逐字複製標題」的方式修復。

#### Scenario: 標題逐字存在時檢查通過

- **GIVEN** master spec 含標題 `### Requirement: 匯出檔案處理`
- **WHEN** delta spec 在 `## MODIFIED Requirements` 下使用逐字相同的標題
- **THEN** self-check 的標題身分鍵檢查通過

#### Scenario: 標題不吻合時必須在 review 前修復

- **GIVEN** delta spec 的 MODIFIED 標題在對應 master spec 中不存在（例如被重打或翻譯過）
- **WHEN** pre-round mechanical self-check 執行
- **THEN** 該標題被判定為 self-check 失敗
- **AND** 失敗 MUST 在 spawn reviewers 之前修復，因為 `.cash-skills/bin/cash validate` 與 `.cash-skills/bin/cash sync` MUST 拒絕不吻合的標題

#### Scenario: 尚無 master spec 的新 capability 跳過檢查

- **WHEN** delta spec 的 capability 在 openspec/specs/ 下尚無 master spec
- **THEN** 標題身分鍵檢查對該 capability 跳過
- **AND** 該 delta 的 `## ADDED Requirements` 不受標題比對約束

### Requirement: Cash 指引提供無向量模型替代流程

`AGENTS.md` 與 `CLAUDE.md` 的 canonical Cash blocks MUST逐byte包含下列完整Markdown block，不得摘要、重排或省略。此block最上方 MUST為全域繁體中文回覆規則，使未進入任何cash skill的一般對話也預設以繁體中文回覆；該規則獨立於各skill的`Response language`段落。Installer MUST NOT偵測vector model狀態、執行semantic search或下載model；所有lifecycle fallback MUST使用project-local Cash CLI。

#### Scenario: Canonical guidance block 完整輸出

- **WHEN**installer擷取或render canonical Cash guidance
- **THEN**下列Markdown block逐byte出現在對應variant
- **AND**全域繁體中文回覆規則、code fence、阻塞分類與Cash-owned fallback皆完整

#### Scenario: 全域回覆語言規則位於 block 最上方

- **WHEN**檢視任一variant的canonical Cash block
- **THEN**block最上方逐byte包含`本專案所有面向使用者的回覆一律以繁體中文撰寫，除非使用者明確要求其他語言。`起始的回覆語言規則
- **AND**該規則出現在阻塞分類requirement與Cash-owned fallback之前

```markdown

本專案所有面向使用者的回覆一律以繁體中文撰寫，除非使用者明確要求其他語言。shell 指令、檔案路徑、程式識別字、schema 欄位名與引用原文逐字保留。

---
### Requirement: cash-apply 任務迴圈的阻塞分類

`cash-apply` 在 task loop 遇到實作阻塞時，SHALL 依「觀察到的 contract 是否改變」把阻塞分類為兩類並採取對應處置：機制替換（contract 不變）記一筆 Implementation Notes Protocol 的 `deviation` 條目後繼續，contract／範圍／行為變更則暫停並引導使用者前往 `cash-ingest`。此分類的暫停判準 MUST 逐字內嵌 Fix-loop design circuit breaker 觸發條件的英文片語 `a synchronization primitive, identity/generation type, or state machine not defined in design.md`，使 task-loop 與 review-loop 對「何謂真正的 design 變更」使用同一個可稽核的邊界字串。兩分支 MUST 互斥：當機制替換分支的條件全部成立時走機制替換分支，「在多個都保留 contract 的替代手段之間選一個」的內部選擇 SHALL 以記 `deviation` 解決，不觸發暫停分支。兩個分類分支 MUST 優先於通用 error／blocker fallback；該 fallback MUST 僅處理未被 blocker triage 涵蓋的其他錯誤或阻塞。此 requirement 適用於 `cash-apply` 的兩個變體（`.claude` 與 `.agents`）。

#### Scenario: 機制替換且 contract 不變則記 deviation 後繼續

- **WHEN** 某個 task 的阻塞是「原設計指定的達成手段在目標平台或現實不可行」
- **AND** 要交付的觀察行為、interface／資料形狀、失敗模式與驗收標準都不變
- **AND** 替代手段不需要 `a synchronization primitive, identity/generation type, or state machine not defined in design.md`
- **THEN** `cash-apply` 依 Implementation Notes Protocol 記一筆 `類別：deviation` 條目
- **AND** 繼續實作該 task，不暫停，也不要求 `cash-ingest`

#### Scenario: contract、範圍或行為變更則暫停並導向 ingest

- **WHEN** 某個 task 的阻塞改變了要交付的觀察行為、範圍或使用者可見的取捨
- **THEN** `cash-apply` 暫停並報告該 blocker
- **AND** 引導使用者前往 `cash-ingest`

#### Scenario: 解答可能改變 contract 的 open question 則暫停

- **WHEN** 某個 task 存在其解答可能改變 contract 或範圍、需要使用者決定的 open question
- **THEN** `cash-apply` 暫停並引導使用者前往 `cash-ingest`

#### Scenario: 替代手段需要未定義的設計機制則暫停

- **WHEN** 某個 task 的替代手段需要 `a synchronization primitive, identity/generation type, or state machine not defined in design.md`
- **THEN** `cash-apply` 走暫停分支而非繼續分支
- **AND** 引導使用者前往 `cash-ingest`

#### Scenario: 保留 contract 的內部手段選擇不觸發暫停

- **WHEN** 機制替換分支的全部條件成立
- **AND** 在多個都保留 contract 的替代手段之間存在需要選擇的內部問題
- **THEN** `cash-apply` 走機制替換分支，以記 `deviation` 解決該選擇
- **AND** 不因該內部選擇而暫停

#### Scenario: 兩個變體保持對等

- **WHEN** 比較 `.claude/skills/cash-apply/SKILL.md` 與 `.agents/skills/cash-apply/SKILL.md` 的阻塞分類段落
- **THEN** 兩者在 invocation 前綴（`/cash-` 與 `$cash-`）正規化後 MUST 完全相同

## Cash-owned artifact fallback

- 使用者直接給 change 名稱 → 直接讀 `openspec/changes/<name>/` 底下的 artifacts；找不到時，先以 `git rev-parse --show-toplevel` 解析root，再執行該root下 `.cash-skills/bin/cash list --parked --json`
- 問程式碼或需求相關的問題 → 先使用 `.cash-skills/bin/cash search "<query>" --limit 10 --json`，合法zero-result再以 Grep／Read 搜尋 `openspec/specs/` 與程式碼
```

#### Scenario: 已知 change名稱時使用 Cash lifecycle

- **WHEN** 使用者直接提供 change名稱
- **THEN** agent直接讀取 `openspec/changes/<name>/` 下的 artifacts
- **AND** 找不到active change時使用project-local Cash CLI確認parked狀態
- **AND** agent不要求model或index

#### Scenario: 程式碼或需求問題使用 lexical fallback

- **WHEN** 使用者詢問程式碼或需求相關問題
- **THEN** agent先使用Cash lexical search
- **AND** 合法zero-result時再使用Grep／Read
- **AND** execution error MUST明確回報而不偽裝成zero-result

### Requirement: 現行文件反映 cash 所有權與清理

本 repository SHALL提供`CASH-SKILLS.md`作為當前的Cash workflow指南。該指南 MUST列出雙變體清單；說明project-local Cash CLI、直接安裝、strict bundle版本、mode-aware target receipt、registry指令、批次更新、dry-run、force、各狀態、結束行為、自無receipt安裝的遷移、Cash guidance migration、marker衝突、精確baseline標準Spectra skill removal、未知legacy內容的安全拒絕，以及bundle版本調升責任；保留一次性legacy修復自動化清理的順序；並述明Cash skills沒有週期性修復。`openspec/signals/README.md` MUST繼續將當前writer描述為Cash審查迴圈，同時保留歷史性的`## Occurrences` provenance文字。

#### Scenario: 當前的安裝與更新說明是完整的

- **WHEN**使用者閱讀`CASH-SKILLS.md`
- **THEN**文件提供單一installer進入點與所有直接、registry及batch commands
- **AND**它說明target何時因runtime、skill、guidance或receipt更新，何時因current或newer略過，何時被阻擋為conflict，何時歸類為failed
- **AND**它指明`cash-skills.version`、`.cash-skills/receipt.tsv`、`.cash-skills/bin/cash`與`$HOME/.config/cash-skills/projects.txt`
- **AND**它說明Cash guidance migration只管理marker spans、逐byte保留其餘內容，並在不合法marker時fail closed
- **AND**它說明成功migration只移除逐byte符合已知baseline的標準`spectra-*` directories，同名customization或未知legacy內容一律保留並fail closed

#### Scenario: 文件不再要求保留標準 Spectra skills

- **WHEN**contract suite掃描`CASH-SKILLS.md`與non-archive master requirements
- **THEN**不存在要求保留標準Spectra skills或只移除`spectra-*-plus`的現行規範
- **AND**合法legacy detector與歷史occurrence文字不被誤判

#### Scenario: 遷移文件沒有現行的修復指示

- **WHEN**使用者閱讀`CASH-SKILLS.md`與`openspec/signals/README.md`
- **THEN**現行指示使用Cash workflows、project-local Cash CLI、installer與一次性cleanup
- **AND**沒有任何現行指示要使用者產生或週期性修復plus或Cash skills
- **AND**歷史性的occurrence項目維持不變

### Requirement: 手動的 cash 專案 registry

本 repository SHALL經由`install-cash-skills.fish`提供registry操作，每次呼叫恰好使用`--target <project>`、`--register <project>`、`--unregister <project>`、`--list`或`--all`其中之一。registry SHALL是`$HOME/.config/cash-skills/projects.txt`，每個非空行一個正規化絕對專案路徑，路徑 MUST NOT包含ASCII控制字元。每個registry支援的模式 MUST在使用既有registry前完整驗證它；registry變動 MUST使用同目錄暫存檔與atomic rename，且installer MUST NOT排程或啟動未來呼叫。`--register`的target除了既存non-symlink directory外，還 MUST是canonical Git worktree top-level，並具有安全、可讀、schema-valid的regular `openspec/config.yaml`；它與direct/batch target使用同一prerequisite validator。

#### Scenario: 首次 register 建立安全狀態

- **GIVEN**cash-skills組態目錄與registry在安全HOME之下不存在
- **WHEN**`--register <project>`收到符合全部target prerequisites的target
- **THEN**installer僅建立所需組態目錄與atomic發佈的registry

#### Scenario: 缺失 registry 對讀取與移除模式視為空

- **GIVEN**cash-skills組態目錄與registry在安全HOME之下不存在
- **WHEN**`--unregister <project>`、`--list`或`--all`執行
- **THEN**installer對空清單成功執行且不建立狀態
- **AND**`--all`印出零計數摘要

#### Scenario: Register 正規化、去重並驗證 prerequisite

- **WHEN**`--register <project>`收到既存non-symlink directory
- **THEN**installer先canonicalize並要求該path恰為Git worktree top-level且具有安全有效的`openspec/config.yaml`
- **AND**成功時恰好儲存一次canonical absolute path並保持其他有效項目不變
- **AND**non-Git、Git子目錄、missing/unsafe/invalid config都以非零結束且registry零寫入

#### Scenario: Register 拒絕行導向 path injection

- **WHEN**register或unregister輸入包含tab、CR、LF或其他ASCII控制字元
- **THEN**installer以非零結束
- **AND**它不建立也不修改registry

#### Scenario: 既有 registry 紀錄拒絕殘留控制字元

- **WHEN**以LF分隔的既有registry紀錄包含tab、CR或其他殘留ASCII控制字元
- **THEN**每個registry支援的installer mode以非零結束
- **AND**它不建立也不修改registry或任何target

#### Scenario: Unregister 移除既存或過時 target

- **WHEN**`--unregister <project>`識別出canonical既存target，或不含dot segment且與儲存值完全一致的absolute stale target
- **THEN**installer以atomic方式移除該項目
- **AND**缺失項目是成功no-op

#### Scenario: List 是唯讀的

- **WHEN**`--list`收到有效registry
- **THEN**它印出去重後的canonical項目
- **AND**它不建立也不修改任何registry、target、receipt、skill、temporary file或background process

#### Scenario: 無效 registry fail closed

- **WHEN**registry不可讀，或包含relative path、root path、dot segment、malformed line或unsafe boundary
- **THEN**`--register`、`--unregister`、`--list`與`--all`在處理target或重寫registry前以非零結束
- **AND**沒有任何registry或target state被修改

### Requirement: 版本感知的 cash skill 批次安裝

`install-cash-skills.fish --all [--dry-run] [--force]` SHALL重用與`--target`相同的完整installer target workflow，處理每個去重後的registry target。每個target MUST先驗證為Git worktree top-level且具有安全有效的`openspec/config.yaml`，並以stable launcher/lock bootstrap、replaceable runtime generation、24個skills、contract modes、Cash config validation/migration、guidance、receipt與精確baseline legacy removal構成同一managed decision。它 MUST將每個target回報為`updated`、`would-update`、`current`、`newer`、`conflict`或`failed`，然後印出每種狀態的計數。單一target的conflict或failed MUST NOT停止後續targets，且任何target為`conflict`或`failed`時，彙總指令 MUST以非零結束。

#### Scenario: 較舊 bundle 或 managed drift 被更新

- **GIVEN**registry包含有效且乾淨的targets，其receipt版本分別舊於、等於與新於source
- **AND**等版本target的stable launcher/lock與replaceable runtime/skill bytes及modes皆符合receipt
- **AND**其中一個等版本target含可安全遷移的config、guidance或legacy baseline drift，其餘等版本target為canonical
- **WHEN**installer以`--all`執行
- **THEN**較舊target與可安全收斂的等版本target回報`updated`
- **AND**等版本且完整canonical的target回報`current`
- **AND**較新的target回報`newer`
- **AND**current或newer target的stable bootstrap、runtime generation、skills、config、guidance、receipt及legacy candidates皆零寫入

#### Scenario: 批次揭露等版本的 source 完整性失敗

- **GIVEN**某個target具有等於source版本的有效receipt
- **AND**至少一個目前source replaceable runtime/skill digest或contract mode與該版本引入commit不符，或stable bootstrap source不符固定baseline
- **WHEN**installer以`--all`或`--all --force`執行
- **THEN**該target回報`failed`、零target write且彙總非零

#### Scenario: 除非明確 force 否則 managed drift 被保留

- **GIVEN**較舊或等版本target的replaceable runtime/skill bytes或mode相對有效receipt drift
- **WHEN**installer未帶`--force`
- **THEN**target回報`conflict`且所有managed及project-owned state零寫入
- **WHEN**相同target再次帶`--force`
- **THEN**installer持有並保留stable lock/launcher inode，只收斂replaceable runtime/skills/modes、Cash managed guidance spans、receipt及精確baseline legacy candidates
- **AND**project-owned config與其他bytes維持不變，target回報`updated`

#### Scenario: Force 從不降級較新的 target

- **GIVEN**有效target receipt版本高於source
- **WHEN**installer以`--all --force`執行
- **THEN**target回報`newer`
- **AND**stable bootstrap、runtime generation、skills、modes、config、guidance、receipt與legacy candidates全部零寫入

#### Scenario: Target 失敗不停止批次

- **GIVEN**一個registered target因Git/config、receipt、guidance、legacy identity或filesystem validation失敗，且較後target可更新
- **WHEN**installer以`--all`執行
- **THEN**第一個target回報`failed`
- **AND**installer繼續更新較後target並以非零彙總

#### Scenario: 批次 dry run 使用完整驗證且不寫入

- **WHEN**installer以`--all --dry-run`執行
- **THEN**每個target接受與real run相同的Git/config、source inventory/mode、receipt/version、guidance、legacy identity、transaction及filesystem boundary驗證
- **AND**計畫中的任何runtime、skill、config、guidance、receipt或legacy removal更新回報`would-update`
- **AND**target、registry與persistent state零寫入；system temporary validation snapshots在該target invocation結束時清除

## ADDED Requirements

### Requirement: Cash CLI cutover 覆蓋全部 live workflow surfaces

兩個variant的十二個canonical Cash skills SHALL將所有artifact engine操作路由到`.cash-skills/bin/cash`，並 MUST移除`Requires spectra CLI`與任何Spectra binary fallback。installer、guidance、live docs與contract tests MUST使用同一project-local command namespace；標準`spectra-*` skills MUST從canonical inventory與安全辨識的installer targets移除。`openspec/changes/archive/`與signal occurrence history SHALL保持原文。

#### Scenario: Spectra binary 不存在時完整 workflow 可用

- **GIVEN**PATH中不存在Spectra binary且Cash bundle已完整安裝
- **WHEN**依序執行Cash propose、apply、verify與archive workflows所需的全部artifact operations
- **THEN**每個operation由project-local Cash CLI完成
- **AND**沒有workflow因缺少Spectra binary而停止

#### Scenario: Live residue scan 封鎖遺漏

- **WHEN**contract suite掃描canonical skills、guidance、live docs、installer與non-archive specs
- **THEN**任何可執行的Spectra command或`Requires spectra CLI`使測試失敗
- **AND**明列的legacy migration detector與歷史archive不被改寫

### Requirement: Cash-owned 設定與無向量模型 fallback

Cash workflows SHALL只讀取`.cash.yaml`runtime設定。`cash-ask` MUST使用Cash lexical search；合法zero-result SHALL回傳empty result且不中斷，execution error MUST明確失敗。guidance在已知change name時 SHALL直接讀取active artifacts並以`.cash-skills/bin/cash list --parked --json`確認parked狀態，且 MUST NOT要求vector model或index。

#### Scenario: 已知 change名稱時不依賴向量模型

- **GIVEN**使用者直接提供change名稱
- **WHEN**active path不存在
- **THEN**agent使用Cash CLI確認parked identity
- **AND**agent不要求下載model或建立index

#### Scenario: Lexical search execution error 不被當成無結果

- **WHEN**Cash lexical search遇到unreadable artifact或invalid query
- **THEN**`cash-ask`回報execution error
- **AND**不輸出zero-result訊息

## REMOVED Requirements

### Requirement: Spectra 更新不改動 cash skills

**Reason**: Canonical Spectra runtime與update command不再屬於live system，保留update隔離contract會要求已移除的binary與fixtures。

**Migration**: Cash bundle的source/target byte identity與upgrade isolation改由installer receipt及Cash contract tests治理。

#### Scenario: Cash receipt 取代 update 隔離

- **WHEN** Cash bundle安裝或升級canonical skills
- **THEN** source/target identity由Cash receipt與contract tests驗證
- **AND** workflow不執行Spectra update

### Requirement: 專案擁有的 cash 指引在 Spectra 更新後存續

**Reason**: Project guidance完成Cash-only migration後不再由Spectra update寫入，原本的managed-update競爭邊界已不存在。

**Migration**: `install-cash-skills.fish`成為唯一guidance與canonical skill deployment入口，legacy Spectra markers只作為安全migration detector。

#### Scenario: Installer 擁有 guidance migration

- **WHEN** target需要安裝或更新Cash guidance
- **THEN** `install-cash-skills.fish`是唯一deployment入口
- **AND** legacy Spectra marker只用於辨識與移除既有managed block

### Requirement: 無狀態的跨專案安裝器

**Reason**: Installer inventory由僅含24個skills擴張為同時治理Cash runtime、mode-aware receipt、24個skills、guidance與精確digest legacy removal；原requirement的non-plus preservation與partial-publication-no-rollback規則已不成立。

**Migration**: 完整outcome matrix、receipt-less完全相同24-skill adoption、registry/batch無背景工作及transaction rollback移至`cash-cli` capability的`Bundle 安裝與 runtime receipt`。

#### Scenario: Installer ownership 移轉

- **WHEN**新Cash bundle安裝或升級target
- **THEN**runtime與skills由同一Cash transaction治理
- **AND**僅含24檔skills的舊inventory只作為明確legacy adoption輸入，不再作為安裝後的managed schema

### Requirement: Cash 安裝不含修復自動化

**Reason**: 無背景自動化原則保留，但「不得修改non-plus Spectra skills」與新legacy removal正面衝突。

**Migration**: 無daemon/LaunchAgent/自動傳播規則移至Cash CLI installer contract，標準Spectra skills只在精確baseline digest證明ownership時移除。

#### Scenario: 無背景工作原則保留

- **WHEN**Cash installer或registry操作完成
- **THEN**不建立daemon、LaunchAgent或scheduled repair
- **AND**後續source變更仍需明確installer invocation

### Requirement: Legacy plus 實作已除役

**Reason**: Legacy removal範圍由四個plus directories擴張到兩個variant的標準Spectra skills，舊requirement要求保留non-plus skills。

**Migration**: 完整legacy baseline digest與unknown-content fail-closed contract移至`cash-cli` capability。

#### Scenario: Canonical Spectra skills 完成退役

- **WHEN**migration實作完成
- **THEN**proposal列出的canonical standard Spectra skill directories皆不存在
- **AND**canonical inventory只保留24個Cash skills

### Requirement: Cash 合約回歸測試套件

**Reason**: 原suite強制執行Spectra update isolation，且沒有Cash runtime、consumer JSON、mode、transaction recovery與namespace residue contracts。

**Migration**: `scripts/cash-cli/tests/cli-checks.fish`治理CLI lifecycle/atomicity；更新後`skill-checks.fish`治理bundle、installer、guidance、parity與live namespace。

#### Scenario: Cash-only contract suites

- **WHEN**repository執行完整Cash contract validation
- **THEN**CLI與skill suites皆在PATH排除Spectra binary時通過
- **AND**suite不執行Spectra update

### Requirement: 安裝器與清理落實檔案系統邊界

**Reason**: 原requirement明確允許partial publication不rollback，且legacy allowlist只涵蓋plus skills，無法治理runtime executable mode與完整standard-skill removal。

**Migration**: Installer的snapshot、mode、transaction、rollback與legacy identity移至`cash-cli` capability；`uninstall-spectra-plus-repair.fish`既有HOME、symlink與service identity contracts維持由其他未移除requirements治理。

#### Scenario: 新 transaction boundary 生效

- **WHEN**installer publication在第N個managed path失敗
- **THEN**Cash transaction依journal回滾或保留可恢復journal並fail closed
- **AND**不再以partial publication作為成功後重試契約

### Requirement: Cash skill bundle 版本與 target receipt

**Reason**: Bundle與receipt由固定24檔digest擴張為runtime加24個skills的path/digest/mode inventory，舊schema無法偵測launcher不可執行或runtime drift。

**Migration**: Version ordering與bump governance保留於Cash CLI installer tests；新receipt schema與outcome matrix由`Bundle 安裝與 runtime receipt`定義。

#### Scenario: Mode-aware runtime receipt

- **WHEN**Cash bundle成功安裝
- **THEN**receipt記錄全部runtime與skills的path、digest及mode
- **AND**launcher mode drift不會被誤判為current

### Requirement: Cash project guidance migration

**Reason**: 原requirement要求標準`spectra-*` skills保持不變，且partial publication不rollback；兩者皆與完整Cash cutover衝突。

**Migration**: Cash block render、marker fail-closed、mode/bytes preservation與post-preflight revalidation移至`cash-cli` capability的guidance deployment requirement。

#### Scenario: Guidance migration 與 skill removal 同步提交

- **WHEN**target同時需要guidance migration、runtime upgrade與legacy skill removal
- **THEN**三者共用同一preflight與transaction decision
- **AND**任何identity或publication failure不留下未治理的mixed runtime

## RENAMED Requirements

- FROM: `### Requirement: Cash namespace 負責 workflow 路由，Spectra 仍是 artifact 引擎`
- TO: `### Requirement: Cash namespace 負責 workflow 路由與 artifact 引擎`
