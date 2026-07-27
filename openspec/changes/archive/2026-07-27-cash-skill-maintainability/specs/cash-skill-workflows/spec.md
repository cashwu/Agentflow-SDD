## MODIFIED Requirements

### Requirement: Cash skill 清單與所有權

本 repository SHALL 為 Codex 與 Claude 兩者提供恰好以下十二個 cash workflow skills：`cash-analyze`、`cash-apply`、`cash-archive`、`cash-ask`、`cash-audit`、`cash-commit`、`cash-debug`、`cash-discuss`、`cash-drift`、`cash-ingest`、`cash-propose` 與 `cash-verify`。每個 cash skill 檔案 MUST 是由本 repository 擁有、納入版本控制的檔案。`.claude/skills/` 底下的十二個 SKILL.md 與 `scripts/cash-skills/blocks/review-gate.md` 是人工維護的權威源頭；`.agents/skills/` 底下的十二個 SKILL.md 是由 `scripts/cash-skills/generate.fish` 依 `scripts/cash-skills/variant-rules.yaml` 生成的輸出，MUST 與重新生成的結果一致，且 MUST NOT 以直接人工編輯作為維護方式。

#### Scenario: 完整的雙變體清單

- **WHEN** 檢查 cash skill 清單時
- **THEN** 十二個 skills 全部存在於 `.agents/skills/` 之下
- **AND** 十二個 skills 全部存在於 `.claude/skills/` 之下
- **AND** 清單中沒有任何 skill 在任一變體中缺漏

#### Scenario: Cash 所有權中繼資料

- **WHEN** 檢視某個 cash skill 的 frontmatter 區塊時
- **THEN** 其 `name` 等於其 `cash-*` 目錄名稱
- **AND** 其中不包含 `generatedBy: "Spectra"`
- **AND** 其中不包含 `spectraPlusVersion`、`spectraPlusUpdated` 或 `spectraPlusFingerprint`

#### Scenario: 變體檔案為生成輸出

- **WHEN** 需要修改某個 skill 在 Codex 變體中呈現的內容
- **THEN** 修改發生在 `.claude/skills/` 源頭、`scripts/cash-skills/blocks/review-gate.md` 或 `scripts/cash-skills/variant-rules.yaml`
- **AND** `.agents/skills/` 的對應輸出以 `scripts/cash-skills/generate.fish` 重新生成
- **AND** 生成輸出仍為納入版本控制的檔案

### Requirement: 變體對等比較完整的受治理本文

回歸套件 SHALL 以重新生成驗證變體一致性：在暫存環境重跑完整生成管線（gate 注入與變體生成），其輸出與工作樹中 committed 的目標檔案 MUST byte-identical，任何差異 MUST 使套件以非零結束並指出該檔案。通用轉換規則（invocation 前綴 `/cash-*` 置換為 `$cash-*`——置換 MUST 套用 token 邊界條件（前綴前一字元不得屬於 `[A-Za-z0-9_.-]`），使路徑字面值不受置換——以及 tool-specific frontmatter 欄位移除、fork 區塊移除）之外的每個變體差異 MUST 在 `scripts/cash-skills/variant-rules.yaml` 以人可讀的具名 entry 宣告；規則檔 MAY 列舉工具特定的 frontmatter、fork 情境措辭、plan 目錄與 agent 選擇行為，以及工具能力特定的 `cash-audit` workflows（Codex standalone/discipline 相對於 Claude report-only）。套件 MUST NOT 以不透明的 digests 或大範圍忽略區域取代宣告式規則。

#### Scenario: 未經源頭的本文漂移使 freshness 檢查失敗

- **GIVEN** 有人直接編輯 `.agents/skills/` 底下某個生成輸出，而未修改 `.claude` 源頭、block 檔或轉換規則
- **WHEN** 生成 freshness 檢查執行
- **THEN** 套件以非零結束並指出該檔案

#### Scenario: 工具能力差異維持可審閱

- **GIVEN** 某對配對 skill 因工具能力不同而需要不同的 frontmatter、fork 行為、plan 整合、agent 選擇或 audit 執行
- **WHEN** 檢視 `scripts/cash-skills/variant-rules.yaml`
- **THEN** 該差異以人可讀的具名 entry 呈現
- **AND** 更改任一變體輸出而未同步更新規則並重新生成會使套件失敗

### Requirement: 變體檔案的內在良構獨立於對等比較

變體一致性檢查（重新生成 freshness 比對）只能偵測生成輸出與其源頭之間的不一致，因此 SHALL 另有一組獨立於該比對的斷言，檢查每個變體檔案自身的良構性。這組斷言 MUST 涵蓋兩類缺陷：生成輸入（`.claude/skills/` 的源頭檔與 `scripts/cash-skills/variant-rules.yaml` 的轉換規則）與生成輸出同時錯誤時 freshness 比對無法偵測的缺陷，以及已被 `scripts/cash-skills/variant-rules.yaml` 登記為 per-skill patch 因而被凍結的缺陷。

**空 code span**：24 個雙變體 `SKILL.md` MUST NOT 含有空的 code span。空 code span 的判準是「同一行中，長度恰為 2 的反引號 run 出現的次數為奇數」。合法的雙反引號跳脫寫法在同一行必成對出現因而為偶數，三反引號的 code fence 其 run 長度為 3 而不計入，兩者皆 MUST NOT 被誤判。此形狀是變體字面值替換剝除來源字串後留下的殘骸，會使該行指示失去受詞。

**變體專屬 frontmatter**：`.agents/skills/` 底下的 12 個 `SKILL.md` 的 frontmatter MUST NOT 含有 `context`、`agent`、`disallowedTools` 三個 key，因為這三者是 Claude Code 專屬的執行設定，在 Codex 環境無語意。此斷言 MUST 只解析 frontmatter 區塊，MUST NOT 把本文中出現的相同字串誤判為 frontmatter key。對應的 fork 情境段落 MUST 只存在於 `.claude` 變體，且該差異由生成器的 fork 區塊移除規則產生。

**通用規則之外的差異必須登記**：首次需要通用轉換規則之外差異的 skill，MUST 在 `scripts/cash-skills/variant-rules.yaml` 新增具名 entry 並重新生成，否則 freshness 檢查以差異失敗。

**斷言必須被執行**：這組良構斷言 MUST 由一個具名測試群組承載，且該群組 MUST 同時出現在套件的全量執行路徑中。未被任何群組呼叫的斷言 MUST 視為未滿足本 requirement。

此 requirement 的理由是生成 freshness 比對具有雙向失效模式：生成輸入與輸出同樣錯誤時比對通過，而單一缺陷一旦寫入 per-skill patch 就被凍結為已審閱的允許差異。兩者都需要一組不依賴該比對的獨立斷言才能攔截。

#### Scenario: 空 code span 使套件失敗

- **GIVEN** 任一雙變體 `SKILL.md` 的某一行含有奇數個長度恰為 2 的反引號 run
- **WHEN** skill 回歸套件執行
- **THEN** 套件以非零結束並指出該檔案
- **AND** 即使該內容可由生成管線忠實重現也仍然失敗

#### Scenario: 合法的反引號寫法不被誤判

- **GIVEN** 某個雙變體 `SKILL.md` 含有以雙反引號包住含反引號內容的跳脫寫法
- **AND** 同一檔案含有三反引號的 code fence
- **WHEN** skill 回歸套件執行
- **THEN** 良構斷言對該檔案通過

##### Example: 三種相鄰反引號形狀

| 形狀 | 該行長度為 2 的 run 次數 | 判為空 code span |
| --- | --- | --- |
| 單獨一對相鄰反引號 | 1（奇數） | 是 |
| 雙反引號跳脫的開閉分隔符 | 2（偶數） | 否 |
| 三反引號 code fence | 0（run 長度為 3） | 否 |

#### Scenario: Codex 變體帶有 Claude 專屬 frontmatter 使套件失敗

- **GIVEN** `.agents/skills/` 底下任一 `SKILL.md` 的 frontmatter 含有 `context`、`agent` 或 `disallowedTools`
- **WHEN** skill 回歸套件執行
- **THEN** 套件以非零結束並指出該檔案與該 key
- **AND** 此斷言直接檢查 `.agents` 檔案自身，不論 freshness 比對回報通過或失敗都仍然失敗

##### Example: 兩類缺陷與其偵測來源

| 缺陷 | freshness 比對結果 | 良構斷言結果 |
| --- | --- | --- |
| 源頭含空 code span 且被忠實生成到輸出 | 通過 | 失敗 |
| 規則的 frontmatter 移除清單被縮減，使 `.agents` 輸出帶 `context: fork` 且已重新生成並提交 | 通過 | 失敗 |
| 僅 Codex 變體含空 code span 且已寫入 per-skill patch | 通過 | 失敗 |
| 僅 Claude 變體含 fork 段落且由移除規則產生差異 | 通過 | 通過 |

#### Scenario: 首次產生通用規則之外差異的 skill 必須登記規則

- **GIVEN** 某個先前僅有通用轉換差異的 skill，其 Codex 變體需要一段通用規則之外的替代流程
- **WHEN** skill 回歸套件執行且 `scripts/cash-skills/variant-rules.yaml` 未新增其具名 entry
- **THEN** freshness 檢查以差異非零結束
- **WHEN** 該 entry 已新增且輸出已重新生成
- **THEN** freshness 檢查通過

#### Scenario: 良構斷言確實被全量執行涵蓋

- **GIVEN** 承載良構斷言的具名測試群組
- **WHEN** 在任一雙變體 `SKILL.md` 注入一個空 code span，並在任一 `.agents` `SKILL.md` 注入一個 `disallowedTools` key
- **THEN** 該具名群組以非零結束
- **AND** 套件的全量執行路徑亦以非零結束

#### Scenario: 合法的變體差異不被良構斷言誤判

- **GIVEN** `.claude` 變體含有 fork 情境段落與 `context`、`agent`、`disallowedTools` frontmatter，且生成器的通用移除規則涵蓋該差異
- **WHEN** skill 回歸套件執行
- **THEN** 良構斷言通過
- **AND** 生成 freshness 檢查亦通過

### Requirement: 審查迴圈的 grader 不可變性

canonical 的 Claude 與 Codex `cash-propose` 與 `cash-apply` skill 檔案 SHALL 各自包含一條以唯一的 sentinel 註解 `<!-- GRADER-IMMUTABILITY -->` 標記的 grader 不可變性規則。在 cash 審查迴圈期間，主 agent MUST NOT 修改——無論是作為修正動作或作為機械自我檢查的修正——受保護 grader 路徑集合中的任何檔案：`.claude/skills/cash-propose/SKILL.md`、`.claude/skills/cash-apply/SKILL.md`、`.agents/skills/cash-propose/SKILL.md`、`.agents/skills/cash-apply/SKILL.md`、`.cash.yaml`、`scripts/cash-skills/blocks/review-gate.md`、`scripts/cash-skills/generate.fish`、`scripts/cash-skills/variant-rules.yaml`、`scripts/cash-skills/tests/skill-checks.fish`、`scripts/cash-cli/tests/cli-checks.fish`，以及 `openspec/specs/` 之下的 master spec 檔案——除非該檔案被當前 change 的結構化範圍宣告明確指名。結構化範圍宣告僅限於 proposal `## Impact` affected-code 條目中的專案根相對路徑，以及 `tasks.md` 中被明確標識為交付目標的專案根相對路徑。僅出現在驗證指令、規則描述、範例、審查 finding、reviewer 情境或其他附帶性文字中的路徑 MUST NOT 計為結構化範圍宣告。在結構化範圍宣告中指名一個目錄路徑即指名其下的所有檔案。已在進行中的迴圈依其開始時的 canonical 指令版本繼續；對 cash skill 的範圍內編輯自下一次迴圈執行起生效。此外，無論宣告範圍為何，主 agent MUST NOT 新增、修改或移除 `openspec/signals/` 之下任何 signal 的 `check` frontmatter 欄位——`check` 欄位是每輪前機械自我檢查的 grader 輸入。當解決一個存活 finding 需要修改該結構化範圍之外的受保護檔案，或觸及 signal 的 `check` 欄位時，修正動作 MUST NOT 執行該修改、MUST 在 `## Fix Actions` 記錄一則 unfixed-due-to-grader-protection 註記並指名該檔案與該 finding，且該 finding 就該輪決策而言維持存活。無論最終決策為何，cash workflow 的完成輸出 MUST 列出迴圈任何一輪所記錄的每則 unfixed-due-to-grader-protection 註記：對 `decision: passed` 的 `cash-propose`，這些註記 MUST 列在最終摘要中；對 `decision: passed` 的 `cash-apply`，這些註記 MUST 列在 gate-complete 最終回應中；對任何 `decision: aborted`，這些註記 MUST 列在未解決 findings 警告中。在結構化範圍例外之下被修改的受保護檔案，視同其他任何修正動作的修改，且不改變下一輪的型別——依 `分級收斂與 micro 驗證輪` requirement，型別僅從其在本次執行中的位置推導。此規則 MUST 適用於兩個變體中的兩個 cash workflows。

#### Scenario: 範圍外的 grader 修改被拒絕

- **WHEN** 某個審查迴圈 finding 的建議需要編輯 `.agents/skills/cash-propose/SKILL.md`，而當前 change 的結構化範圍宣告未指名該檔案
- **THEN** 修正動作不修改 `.agents/skills/cash-propose/SKILL.md`
- **AND** 該輪檔案的 `## Fix Actions` 記錄一則 unfixed-due-to-grader-protection 註記，指名該檔案與該 finding
- **AND** 該 finding 仍計入該輪決策

#### Scenario: Gate 源頭檔未宣告時同受保護

- **WHEN** 某個審查迴圈 finding 的建議需要編輯 `scripts/cash-skills/blocks/review-gate.md`、`scripts/cash-skills/generate.fish` 或 `scripts/cash-skills/variant-rules.yaml`，而當前 change 的結構化範圍宣告未指名該檔案
- **THEN** 修正動作不修改該檔案
- **AND** 該輪檔案的 `## Fix Actions` 記錄一則 unfixed-due-to-grader-protection 註記，指名該檔案與該 finding

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

## ADDED Requirements

### Requirement: Review gate 單一源頭生成

sub-agent review gate 規格 SHALL 以 `scripts/cash-skills/blocks/review-gate.md` 為唯一人工維護處。`.claude/skills/cash-propose/SKILL.md`、`.claude/skills/cash-apply/SKILL.md`、`.agents/skills/cash-propose/SKILL.md` 與 `.agents/skills/cash-apply/SKILL.md` 中的 gate 區段 MUST 由 `scripts/cash-skills/generate.fish` 從該 block 生成，區段邊界以成對錨點註解 `<!-- REVIEW-GATE:BEGIN -->` 與 `<!-- REVIEW-GATE:END -->` 標定，每個檔案中恰出現一對，且位於該 skill gate 步驟標題行之後——標題行（含其清單編號）不屬於生成區段。四份 gate 區段在 `/cash-*` 相對於 `$cash-*` 的呼叫語法正規化後 MUST 逐字相同。生成器 MUST 冪等：對乾淨工作樹連續執行兩次，第二次 MUST NOT 產生任何檔案變更。

#### Scenario: 生成器冪等

- **GIVEN** 一個乾淨的工作樹
- **WHEN** 連續執行兩次 `scripts/cash-skills/generate.fish`
- **THEN** 第二次執行結束後沒有任何檔案變更

#### Scenario: 手改 gate 區段被 freshness 檢查攔截

- **GIVEN** 有人直接編輯任一 SKILL.md 的 gate 區段而未修改 `scripts/cash-skills/blocks/review-gate.md`
- **WHEN** 生成 freshness 檢查執行
- **THEN** 套件以非零結束並指出該檔案

#### Scenario: 錨點成對且唯一

- **WHEN** 檢視四個 gate 檔案
- **THEN** 每個檔案中 `<!-- REVIEW-GATE:BEGIN -->` 與 `<!-- REVIEW-GATE:END -->` 各出現恰一次且前者在前
- **AND** 四份 gate 區段於呼叫語法正規化後逐字相同

### Requirement: Cash 領域詞彙表

repository 根目錄 SHALL 存在 `CASH-GLOSSARY.md`，集中定義 cash skill 系統的核心詞彙。每個詞條 MUST 為一個二級標題，內含定義、關係（指向相關詞條）、avoid（不應使用的近義寫法）三部分。首批詞條 MUST 至少涵蓋：change、artifact、contract、deviation、blocker、touched state、parked、signal、round、cumulative blocking set、accepted risk、variant。`CASH-SKILLS.md` MUST 含有指向 `CASH-GLOSSARY.md` 的連結。

#### Scenario: 詞條 schema 完整

- **WHEN** 檢視 `CASH-GLOSSARY.md` 的任一詞條
- **THEN** 該詞條為一個二級標題
- **AND** 內含定義、關係、avoid 三部分

#### Scenario: 首批詞條齊備且被索引

- **WHEN** 檢查 `CASH-GLOSSARY.md` 與 `CASH-SKILLS.md`
- **THEN** 十二個首批詞條全部存在
- **AND** `CASH-SKILLS.md` 含有指向 `CASH-GLOSSARY.md` 的連結

### Requirement: Cash skill lint 檢核清單

`scripts/cash-skills/SKILL-LINT.md` SHALL 存在，收錄 skill 內容的六種失效模式：premature completion、duplication、sediment、sprawl、no-ops、negation。每種模式 MUST 含定義、症狀、檢查問句三部分。`CASH-SKILLS.md` MUST 含有指向 `scripts/cash-skills/SKILL-LINT.md` 的連結，並說明其用途是 skill 內容修訂時的人工檢核維度。本清單是維護參考文件，MUST NOT 被實作為阻斷性的自動化檢查。

#### Scenario: 六種失效模式齊備

- **WHEN** 檢視 `scripts/cash-skills/SKILL-LINT.md`
- **THEN** 六種失效模式全部存在
- **AND** 每種模式含定義、症狀、檢查問句三部分

#### Scenario: 檢核清單被索引且非阻斷

- **WHEN** 檢查 `CASH-SKILLS.md` 與 skill 回歸套件
- **THEN** `CASH-SKILLS.md` 含有指向 `scripts/cash-skills/SKILL-LINT.md` 的連結
- **AND** 回歸套件沒有以該清單為依據的阻斷性斷言
