## MODIFIED Requirements

### Requirement: Deterministic lexical search

`search` SHALL 只讀取以 no-follow handle 開啟、經 `fstat` 確認且 identity 位於 root 內的 regular files，以 Unicode case-folded query tokens 比對 path、heading 與 body，並回傳 `path`、`title`、`excerpt` 與 normalized `score`。symlink file/directory、parent identity swap 與 root 外 target MUST 在讀取 body 前拒絕。相同 score MUST 依 project-relative path byte order 排序。合法 zero-result MUST 回傳空 `results` 且 exit 0。CLI MUST NOT 要求 vector model 或 index。

語料範圍 SHALL 由 `--scope` 控制，其值 MUST 為 `specs`、`active` 或 `all` 三者之一，未提供時 MUST 等同 `active`。`specs` MUST 只涵蓋 `openspec/specs/` 底下的文件；`active` MUST 涵蓋 `openspec/` 底下但排除位於 `openspec/changes/archive/` 之下、且其路徑中存在一個完整片段等於 `reviews` 的目錄之文件。此比對 MUST 以完整路徑片段進行，MUST NOT 以字串前綴或子字串比對，因此名稱僅包含 `reviews` 的目錄（例如 `code-reviews`）MUST NOT 被排除；`all` MUST 涵蓋 `openspec/` 底下全部文件而不作任何排除。`--scope` 提供了不在這三個列舉值內的值時 MUST 以 `invalid_scope` 與 exit 2 失敗。

排除 SHALL 在目錄走訪層剪枝，MUST NOT 以走訪後過濾實作。因此被排除的檔案 MUST NOT 被開啟或解碼，且封存 `reviews` 目錄下存在非 UTF-8 檔案時 `--scope active` 與 `--scope specs` MUST 仍 exit 0。`--scope specs` 在 `openspec/specs/` 不存在時 MUST 回傳空 `results` 且 exit 0，MUST NOT 以 execution error 失敗。

參數解析 SHALL 與旗標位置無關：解析器 MUST 辨識 `--limit` 與 `--scope` 為帶值旗標並同時略過旗標與其值，MUST 辨識 `--json` 為無值旗標，其餘不以 `--` 開頭的 token 才是位置參數。以單一連字號開頭的 token MUST 視為位置參數而非旗標，使自然語言 query 維持可用。帶值旗標後方的 token 若以 `-` 開頭，MUST 視為該旗標缺值，MUST NOT 吞掉該 token 當作值。位置參數 MUST 恰為一個；零個、多於一個、或出現未知的 `--` 開頭 token 時 MUST 以 `invalid_arguments` 與 exit 2 失敗。

`--limit` 未提供時 SHALL 採用預設值 `10`，MUST NOT 因其缺席而失敗。`--limit` 提供了但缺值、值非整數、或值不在 `1` 到 `100` 的閉區間內時 MUST 以 `invalid_limit` 與 exit 2 失敗，且缺值與值不合法兩種情形的 message MUST 不相同。空 query 與 unreadable/unsafe file MUST 失敗。

#### Scenario: Lexical ranking 穩定

- **GIVEN** 三個文件分別在 heading、body 與 path 命中相同 query token
- **WHEN** 執行 `search "archive safety" --limit 3 --json`
- **THEN** 結果依定義的 path/heading/body 權重排序
- **AND** 相同 score 依 path byte order 排序

#### Scenario: 無結果不是執行錯誤

- **WHEN** 合法 query 沒有命中任何文件
- **THEN** CLI 回傳 `{ "results": [] }`
- **AND** process exit code 為 0

#### Scenario: 旗標位置不改變 query 身分

- **GIVEN** 一個含多份文件的 workspace
- **WHEN** 分別執行 `search openspec --limit 5 --json` 與 `search --limit 5 openspec --json`
- **THEN** 兩次的 stdout 逐位元組相同

##### Example: 旗標前置與後置

| 指令 | 解析出的 query | 解析出的 limit |
| --- | --- | --- |
| `search openspec --limit 5` | `openspec` | `5` |
| `search --limit 5 openspec` | `openspec` | `5` |

#### Scenario: 位置參數數量不合法時失敗

- **WHEN** 執行不含任何位置參數的 `search --limit 5 --json`
- **THEN** CLI 以 `invalid_arguments` 與 exit 2 失敗
- **WHEN** 執行含兩個位置參數的 `search alpha beta --json`
- **THEN** CLI 以 `invalid_arguments` 與 exit 2 失敗
- **WHEN** 執行含未知旗標的 `search alpha --bogus --json`
- **THEN** CLI 以 `invalid_arguments` 與 exit 2 失敗

#### Scenario: 單一連字號開頭的 query 維持可用

- **WHEN** 執行以單一連字號開頭的 query
- **THEN** CLI 把該 token 視為位置參數而非旗標
- **AND** exit code 為 0

#### Scenario: limit 缺席採用預設值

- **WHEN** 執行未帶 `--limit` 的 `search openspec --json`
- **THEN** CLI exit 0
- **AND** `results` 的長度不超過 10

#### Scenario: limit 的缺值與不合法分別失敗

- **WHEN** 執行 `search openspec --limit --json`
- **THEN** CLI 以 `invalid_limit` 與 exit 2 失敗
- **AND** message 表明該旗標缺少值
- **WHEN** 執行 `search openspec --limit abc --json`
- **THEN** CLI 以 `invalid_limit` 與 exit 2 失敗
- **AND** message 表明該值不合法且與缺值情形的 message 不同
- **WHEN** 執行 `search openspec --limit 0 --json`
- **THEN** CLI 以 `invalid_limit` 與 exit 2 失敗

##### Example: limit 的四種輸入

| 指令片段 | 結果 | message 類別 |
| --- | --- | --- |
| 未帶 `--limit` | exit 0，最多 10 筆 | 不適用 |
| `--limit` 後方接 `--json` | `invalid_limit`，exit 2 | 缺值 |
| `--limit abc` | `invalid_limit`，exit 2 | 值不合法 |
| `--limit 0` | `invalid_limit`，exit 2 | 值不合法 |

#### Scenario: 預設語料排除封存的 review 檔案但保留封存決策脈絡

- **GIVEN** workspace 同時含 `openspec/specs/` 底下的 master spec、非封存 change 的 artifact、封存 change 的 `proposal.md` 與封存 change 的 `reviews/propose-r1.md`，且四者都命中同一個 query token
- **WHEN** 執行未帶 `--scope` 的 `search <token> --json`
- **THEN** `results` 不含任何位於封存 `reviews` 目錄底下的 `path`
- **AND** `results` 含該封存 change 的 `proposal.md`
- **WHEN** 對相同 workspace 執行 `search <token> --scope specs --json`
- **THEN** `results` 的每個 `path` 都位於 `openspec/specs/` 底下
- **WHEN** 對相同 workspace 以足以涵蓋全部命中文件的 `--limit` 執行 `search <token> --scope all --json`
- **THEN** `results` 為相同 `--limit` 下 `active` 結果的超集合
- **AND** `results` 至少含一個位於封存 `reviews` 目錄底下的 `path`
- **WHEN** 執行 `search <token> --scope bogus --json`
- **THEN** CLI 以 `invalid_scope` 與 exit 2 失敗

#### Scenario: 被排除的檔案不被開啟

- **GIVEN** 封存 change 的 `reviews` 目錄下存在一個非 UTF-8 檔案
- **WHEN** 執行未帶 `--scope` 的 `search <token> --json`
- **THEN** CLI exit 0 且不回報 `invalid_encoding`
- **WHEN** 對相同 workspace 執行 `search <token> --scope specs --json`
- **THEN** CLI exit 0 且不回報 `invalid_encoding`

#### Scenario: specs 範圍在目錄不存在時回空

- **GIVEN** 一個沒有 `openspec/specs/` 目錄的 workspace
- **WHEN** 執行 `search <token> --scope specs --json`
- **THEN** CLI 回傳 `{ "results": [] }` 且 exit 0

## ADDED Requirements

### Requirement: Drift 建議使用 variant 中立的 skill 名稱

本 requirement 細化 `Deterministic validation、analysis 與 drift` 對 `primary_recommendation` 的既有規定，只約束其字串形式，不重複定義該欄位的存在性或型別。

`drift` 的 `primary_recommendation` SHALL 只輸出 Cash skill 名稱與 change 名稱，MUST NOT 內嵌任一 agent variant 的 invocation 前綴字元。具體而言該欄位值 MUST NOT 含 `$` 字元，也 MUST NOT 含 `/` 字元。severity 到 skill 名稱的對應 MUST 維持既有語意：`light` 對應 `cash-apply`，`medium` 與 `heavy` 對應 `cash-ingest`。human output 的 primary recommendation 行 MUST 從相同欄位 render，MUST NOT 自行補上前綴。

此 requirement 只約束 CLI 的輸出；消費該欄位的 skill 文件之義務由 `cash-skill-workflows` 的對應 requirement 規範。

此 requirement 的理由是 CLI runtime 為兩個 variant 共用，任何 variant 專屬的 invocation 字面值都會使其中一個 variant 收到錯誤的指令建議。

#### Scenario: JSON 與 human output 都不含 variant 前綴

- **GIVEN** 一個 total score 落在 `light` 區間的 change
- **WHEN** 執行 `drift <name> --json`
- **THEN** `primary_recommendation` 為 `cash-apply <name>`
- **AND** 該字串不含 `$` 也不含 `/`
- **WHEN** 對相同 change 執行不帶 `--json` 的 `drift <name>`
- **THEN** 報告的 primary recommendation 行呈現相同的不含前綴字串

#### Scenario: 三個 severity 分支各自對應正確的 skill

- **GIVEN** 一個 total score 落在 `light` 區間的 change
- **WHEN** 執行 `drift <name> --json`
- **THEN** `primary_recommendation` 為 `cash-apply <name>`
- **GIVEN** 一個 total score 落在 `medium` 區間的 change
- **WHEN** 執行 `drift <name> --json`
- **THEN** `primary_recommendation` 為 `cash-ingest <name>`
- **GIVEN** 一個 total score 落在 `heavy` 區間的 change
- **WHEN** 執行 `drift <name> --json`
- **THEN** `primary_recommendation` 為 `cash-ingest <name>`

##### Example: severity 對應

| severity | primary_recommendation |
| --- | --- |
| `light` | `cash-apply <name>` |
| `medium` | `cash-ingest <name>` |
| `heavy` | `cash-ingest <name>` |

### Requirement: Proposal 模板段落集合由 Cash-owned resources 定義

本 requirement 細化 `Artifact graph 與 instructions 使用單一來源` 對 proposal template 的既有規定，列舉該 template 必須承載的段落與子結構，不重複定義 template 的來源歸屬。

`instructions proposal --change <name> --json` 回傳的 `template` SHALL 是 proposal 段落結構的唯一定義來源，且 MUST 依序包含 `## Summary`、`## Motivation`、`## Proposed Solution`、`## Non-Goals`、`## Alternatives Considered`、`## Capabilities`、`## Impact` 七個段落標題。

該 `template` MUST 同時承載兩組子結構：`## Capabilities` 之下 MUST 含 `### New Capabilities` 與 `### Modified Capabilities`；`## Impact` 之下 MUST 含 `- Affected specs:` 與 `- Affected code:`，且後者之下 MUST 含 `New`、`Modified`、`Removed` 三個標籤列，每個標籤後接冒號。此要求存在的理由是 `## Impact` 標題是 spec 合併產生 trace 時界定區段的依據，而三個標籤列是 impact 粒度提示計數 affected-code 條目的依據；兩者在形狀消失時皆為靜默降級而非報錯。

該 `template` 所含的段落標題 MUST 是 `validate` 對 `proposal.md` 所要求標題的超集合，使依該 `template` 產出的 proposal 必然滿足必要標題檢查。必要標題集合本身 MUST 維持只在 validation 層定義一次，MUST NOT 在 resources 層重複定義。

#### Scenario: 模板涵蓋全部必要標題

- **WHEN** 讀取 `instructions proposal --change <name> --json` 的 `template`
- **THEN** 該字串含有 `## Summary`、`## Capabilities` 與 `## Impact`
- **AND** 依該 `template` 填寫且未刪除任何段落標題的 proposal 通過 `validate <name>`

#### Scenario: 模板承載下游依賴的子結構

- **WHEN** 讀取 `instructions proposal --change <name> --json` 的 `template`
- **THEN** 該字串含有 `### New Capabilities` 與 `### Modified Capabilities`
- **AND** 該字串含有 `- Affected specs:` 與 `- Affected code:`
- **AND** 該字串在 `- Affected code:` 之下含有 `New`、`Modified` 與 `Removed` 三個標籤列，每個標籤後接冒號

#### Scenario: 模板段落順序穩定

- **WHEN** 對同一個 change 兩次讀取 `instructions proposal --change <name> --json`
- **THEN** 兩次的 `template` 逐位元組相同
- **AND** 七個段落標題的出現順序與本 requirement 列舉的順序一致
