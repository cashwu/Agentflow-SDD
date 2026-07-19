## ADDED Requirements

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
- **AND** 檔案路徑與 CLI 指令（例如 `spectra validate --strict`）逐字保留

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
- **AND** 失敗 MUST 在 spawn reviewers 之前修復，因為 spectra archive 對不吻合的標題會靜默輸出 modified: 0 並丟棄修改內容

#### Scenario: 尚無 master spec 的新 capability 跳過檢查

- **WHEN** delta spec 的 capability 在 openspec/specs/ 下尚無 master spec
- **THEN** 標題身分鍵檢查對該 capability 跳過
- **AND** 該 delta 的 `## ADDED Requirements` 不受標題比對約束
