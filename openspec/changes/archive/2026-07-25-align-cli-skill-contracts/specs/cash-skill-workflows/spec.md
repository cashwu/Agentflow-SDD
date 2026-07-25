## ADDED Requirements

### Requirement: cash-propose 的 proposal 結構取自 CLI 單一來源

`cash-propose` 撰寫 `proposal.md` 時 SHALL 使用 `instructions proposal --change <name> --json` 回傳的 `template` 作為段落結構，處理方式與該 skill 對 design、specs、tasks 三個 artifact 的既有處理一致。兩個變體的 `SKILL.md` MUST NOT 內嵌任何 proposal 段落模板本文。

具體而言，`.claude/skills/cash-propose/SKILL.md` 與 `.agents/skills/cash-propose/SKILL.md` MUST NOT 含有 `## Why`、`## What Changes`、`## Problem`、`## Root Cause`、`## Success Criteria` 這五個段落標題字面值。此禁令涵蓋全檔的每一次出現，不只 step 5 的模板區塊：審查 findings 過濾規則中對 `## What Changes` 的引用 MUST 一併改為只引用 `## Proposed Solution`。

變更型別分類步驟 MUST 保留，但其結尾敘述 MUST NOT 宣稱型別決定 proposal 的模板格式；該敘述 MUST 改為說明型別決定 `## Motivation` 與 `## Proposed Solution` 的敘述重心。

此 requirement 的理由是 proposal 的段落結構先前同時定義於 CLI resources 與兩個變體的 `SKILL.md`，三處各自演化後產生了「依 skill 指示產出的 proposal 無法通過 validate」的矛盾。收斂為單一來源後，新增或調整段落只需改動 CLI resources 一處。

#### Scenario: 依 skill 指示產出的 proposal 通過驗證

- **GIVEN** 一個新建立且僅有 `.openspec.yaml` 的 change
- **WHEN** `cash-propose` 依其 step 5 的指示取得 `template` 並據以寫入 `proposal.md`
- **THEN** `validate <name>` 對 `proposal.md` 不回報 `heading_missing`
- **AND** `list --json` 中該 change 的 `summary` 為非空字串

#### Scenario: 兩個變體全檔都不含被移除的段落標題

- **WHEN** 檢查 `.claude/skills/cash-propose/SKILL.md` 與 `.agents/skills/cash-propose/SKILL.md` 全檔
- **THEN** 兩者都不含 `## Why`、`## What Changes`、`## Problem`、`## Root Cause`、`## Success Criteria` 任一字面值
- **AND** 兩者的 step 5 明文指示使用 CLI 回傳的 `template`
- **AND** 兩者的審查 findings 過濾規則只引用 `## Proposed Solution`

#### Scenario: 型別分類步驟保留但不再指涉模板

- **WHEN** 檢查兩個變體的變更型別分類步驟
- **THEN** 該步驟仍存在且仍列出三種型別
- **AND** 其結尾敘述指向 `## Motivation` 與 `## Proposed Solution` 的敘述重心，而非 proposal 的模板格式

### Requirement: cash-drift 對建議欄位的描述與 CLI 輸出一致

`cash-drift` 兩個變體的 `SKILL.md` SHALL 把 `primary_recommendation` 描述為 Cash skill 名稱與 change 名稱，MUST NOT 描述為可直接執行的指令行，也 MUST NOT 指示使用者或 agent 直接執行其值。具體而言兩檔 MUST NOT 含 `copy-pasteable` 字面值，且輸出範本 MUST NOT 以執行動詞包裹該欄位的值。

此 requirement 的理由是該欄位的字串形式由 `cash-cli` 的對應 requirement 改為不含 invocation 前綴，未同步的 skill 描述會成為假敘述並產生不可執行的輸出行。

#### Scenario: 兩個變體不再宣稱該欄位可直接執行

- **WHEN** 檢查 `.claude/skills/cash-drift/SKILL.md` 與 `.agents/skills/cash-drift/SKILL.md`
- **THEN** 兩者都不含 `copy-pasteable` 字面值
- **AND** 兩者的欄位描述說明其為 skill 名稱與 change 名稱
- **AND** 兩者的輸出範本呈現建議的下一個 skill，而非一行待執行的指令

### Requirement: 變體檔案的內在良構獨立於對等比較

變體對等比較只能偵測兩個變體之間的差異，因此 SHALL 另有一組獨立於對等比較的斷言，檢查每個變體檔案自身的良構性。這組斷言 MUST 涵蓋兩類缺陷：對等比較在兩個變體同時錯誤時無法偵測的缺陷，以及已被 parity manifest 記錄為允許差異因而被凍結的缺陷。

**空 code span**：24 個 canonical `SKILL.md` MUST NOT 含有空的 code span。空 code span 的判準是「同一行中，長度恰為 2 的反引號 run 出現的次數為奇數」。合法的雙反引號跳脫寫法在同一行必成對出現因而為偶數，三反引號的 code fence 其 run 長度為 3 而不計入，兩者皆 MUST NOT 被誤判。此形狀是變體字面值替換剝除來源字串後留下的殘骸，會使該行指示失去受詞。

**變體專屬 frontmatter**：`.agents/skills/` 底下的 12 個 `SKILL.md` 的 frontmatter MUST NOT 含有 `context`、`agent`、`disallowedTools` 三個 key，因為這三者是 Claude Code 專屬的執行設定，在 Codex 環境無語意。此斷言 MUST 只解析 frontmatter 區塊，MUST NOT 把本文中出現的相同字串誤判為 frontmatter key。對應的 fork 情境段落 MUST 只存在於 `.claude` 變體，並在該 skill 的 parity manifest 中呈現為新增區塊。

**新產生的合法差異必須登記**：移除 Claude-only frontmatter 後首次產生變體差異的 skill，MUST 同時新增其 `scripts/cash-skills/variant-parity/` manifest 並加入回歸套件的 divergent 清單，否則對等比較會以「未列入的本文漂移」失敗。

**斷言必須被執行**：這組良構斷言 MUST 由一個具名測試群組承載，且該群組 MUST 同時出現在套件的全量執行路徑中。未被任何群組呼叫的斷言 MUST 視為未滿足本 requirement。

此 requirement 的理由是 parity manifest 具有雙向失效模式：兩個變體同樣錯誤時比較通過，而單一變體的錯誤一旦寫入 manifest 就被記錄為已審閱的允許差異。兩者都需要一組不依賴變體間比較的獨立斷言才能攔截。

#### Scenario: 空 code span 使套件失敗

- **GIVEN** 任一 canonical `SKILL.md` 的某一行含有奇數個長度恰為 2 的反引號 run
- **WHEN** skill 回歸套件執行
- **THEN** 套件以非零結束並指出該檔案
- **AND** 即使該差異已列於某個 parity manifest 也仍然失敗

#### Scenario: 合法的反引號寫法不被誤判

- **GIVEN** 某個 canonical `SKILL.md` 含有以雙反引號包住含反引號內容的跳脫寫法
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
- **AND** 即使兩個變體的 frontmatter 完全相同因而對等比較通過，此斷言仍然失敗

##### Example: 兩類缺陷與其偵測來源

| 缺陷 | 對等比較結果 | 良構斷言結果 |
| --- | --- | --- |
| 兩個變體都帶 `context: fork` | 通過 | 失敗 |
| 兩個變體都帶 `disallowedTools` | 通過 | 失敗 |
| 僅 Codex 變體含空 code span 且已列於 manifest | 通過 | 失敗 |
| 僅 Claude 變體含 fork 段落且已列於 manifest | 通過 | 通過 |

#### Scenario: 首次產生差異的 skill 必須登記 manifest

- **GIVEN** 某個先前兩變體逐字相同的 skill，其 Codex 變體移除了 Claude-only frontmatter
- **WHEN** skill 回歸套件執行且該 skill 未加入 divergent 清單也未新增 manifest
- **THEN** 對等比較以「未列入的本文漂移」非零結束
- **WHEN** 該 skill 已加入 divergent 清單且其 manifest 逐行反映實際差異
- **THEN** 對等比較通過

#### Scenario: 良構斷言確實被全量執行涵蓋

- **GIVEN** 承載良構斷言的具名測試群組
- **WHEN** 在任一 canonical `SKILL.md` 注入一個空 code span，並在任一 `.agents` `SKILL.md` 注入一個 `disallowedTools` key
- **THEN** 該具名群組以非零結束
- **AND** 套件的全量執行路徑亦以非零結束

#### Scenario: 合法的變體差異不被良構斷言誤判

- **GIVEN** `.claude` 變體含有 fork 情境段落與 `context`、`agent`、`disallowedTools` frontmatter，且該差異已列於該 skill 的 parity manifest
- **WHEN** skill 回歸套件執行
- **THEN** 良構斷言通過
- **AND** 對等比較亦通過
