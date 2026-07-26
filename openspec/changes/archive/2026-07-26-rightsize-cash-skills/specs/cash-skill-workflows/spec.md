## ADDED Requirements

### Requirement: cash-apply 實作紀律以判準表述

`cash-apply` 兩個變體的 `SKILL.md` SHALL 以單一段落陳述 task loop 期間的實作紀律，且該段落 MUST 以判準表述而非逐項風格禁令。該段落 MUST 保留下列兩項可稽核內容：

- **diff 可追溯性驗收標準**：本次 diff 的每一行都能直接追溯到 `tasks.md` 中的某條任務，或 `design.md` 中的 Implementation Contract 項目。
- **Implementation Notes Protocol 銜接**：刻意偏離時，依 Implementation Notes Protocol 寫一筆 `deviation` 條目。

該段落 MUST NOT 逐項列舉語法層級的風格禁令（例如巢狀三元運算子、dense one-liner、method chain 長度、中介變數或命名常數的去留）。這類列舉是替模型的品味立法，且會與同段落的簡潔要求互相拉扯，MUST 以「clarity 優先於 brevity」這類判準取代。

審查迴圈 `Common false positives` 清單中引用該紀律段落名稱的項目，存在於 `cash-propose` 與 `cash-apply` 共用的 review-loop 本文，因此 MUST 在四個 canonical `SKILL.md` 中與該段落名稱保持一致。任何一處指向已不存在的段落名稱即為懸空引用。

回歸套件 MUST 以具名測試群組斷言上述內容，且該群組 MUST 出現在套件的全量執行路徑中。

#### Scenario: 保留的兩項可稽核內容存在

- **WHEN** 檢查 `.claude/skills/cash-apply/SKILL.md` 與 `.agents/skills/cash-apply/SKILL.md`
- **THEN** 兩檔皆含 diff 可追溯性驗收標準
- **AND** 兩檔皆含 Implementation Notes Protocol 的 `deviation` 銜接

#### Scenario: 移除可追溯性標準使套件失敗

- **GIVEN** 任一變體的 `cash-apply` 紀律段落被移除 diff 可追溯性驗收標準
- **WHEN** skill 回歸套件執行
- **THEN** 套件以非零結束並指出該檔案

#### Scenario: 重新引入風格禁令列舉使套件失敗

- **GIVEN** 任一變體的 `cash-apply` 紀律段落重新加入本 requirement 散文段所列舉的具名風格禁令字面值
- **WHEN** skill 回歸套件執行
- **THEN** 套件以非零結束並指出該檔案

#### Scenario: 段落名稱在四個檔案中一致

- **WHEN** 檢查 `.claude` 與 `.agents` 的 `cash-propose` 與 `cash-apply` 四個 `SKILL.md` 的 `Common false positives` 清單
- **THEN** 引用實作紀律段落名稱的項目所用的名稱，與 `cash-apply` 中該段落的實際名稱相同
- **AND** 四個檔案中不存在指向已不存在段落名稱的懸空引用

##### Example: 判準式與列舉式的分界

| 表述 | 屬於 | 允許 |
| --- | --- | --- |
| 本次 diff 的每一行都能追溯到某條任務或 Implementation Contract 項目 | 可稽核驗收標準 | 是 |
| clarity 永遠優先於 brevity | 判準 | 是 |
| 不要使用巢狀三元運算子 | 語法層級風格禁令 | 否 |
| 不要為了減少行數犧牲可讀性的 dense one-liner | 語法層級風格禁令 | 否 |

### Requirement: Skill 互動 fallback 的單一陳述

每個 canonical cash skill 的兩個變體的 `SKILL.md`，其互動 fallback SHALL 全檔恰好陳述一次；使用 AskUserQuestion 的 skill MUST 有恰好一次，不使用該工具的 skill MUST 為零次。MUST NOT 於多個決策點分別覆述。該單一陳述得為獨立的全域規則，亦得內嵌於使用該工具的步驟句中；兩種形式皆滿足本 requirement。判準是出現次數，不是該陳述的所在位置或形狀。

**判定條件。** 一段文字計為 fallback 陳述，當且僅當同時滿足：

- **(a) 不可用條件**——指出 AskUserQuestion 或其泛稱不可用；
- **(b) 純文字替代**——規定改以純文字向使用者提出相同的問題或選項並等待回應。

兩個軸都是必要的。缺 (a) 而僅有 (b) 會把報告格式用語誤計——`cash-drift` 有五處 `plain-language` 描述的是報告本文的可讀性要求，與互動 fallback 無關。缺 (b) 而僅有 (a) 會把規定其他控制流的規則誤計——accepted-risks ledger 的「互動不可用時不寫入該筆記錄」，以及 `cash-ingest` 在工具不可用時「顯示摘要並終止 workflow」，都只滿足 (a)，MUST NOT 計入，且 MUST NOT 被併入單一陳述或被刪除。

**(a) 與 (b) MUST 以多行視窗比對，MUST NOT 要求同行出現。** 視窗 MUST 界定為同一段落，即自 (a) 命中行起算至下一個空行為止的連續非空行區塊；MUST NOT 使用固定行數常數，因為既有位置的行距會隨本 change 的刪除而改變。 本 repo 既有的 fallback 陳述有兩種版面：單行同時含兩軸，以及條件獨立成行、替代作法在其後續行。要求同行會使後者計數為零而靜默漏檢。

回歸套件 MUST 以具名測試群組承載本斷言，且該群組 MUST 出現在套件的全量執行路徑中。斷言 MUST 同時把關上界與下界：多於一次為違反，使用該工具卻為零次亦為違反。只把關上界 MUST NOT 視為滿足本 requirement——七個 skill 的唯一 fallback 陳述位於正被修剪的 `**Guardrails**` 區塊末條，僅有上界時整條被刪仍會通過。

#### Scenario: 覆述的 fallback 使套件失敗

- **GIVEN** 任一 canonical `SKILL.md` 在單一陳述之外，另於某個決策點覆述該 fallback
- **WHEN** skill 回歸套件執行
- **THEN** 套件以非零結束並指出該檔案

#### Scenario: 刪除唯一的 fallback 陳述使套件失敗

- **GIVEN** 某個使用 AskUserQuestion 的 canonical `SKILL.md` 其唯一一處 fallback 陳述被刪除
- **WHEN** skill 回歸套件執行
- **THEN** 套件以非零結束並指出該檔案

#### Scenario: 條件與替代作法分行的陳述被正確計入

- **GIVEN** 某處 fallback 陳述的不可用條件獨立成行，純文字替代作法位於其後續行
- **WHEN** skill 回歸套件執行
- **THEN** 該陳述計為一次
- **AND** 該 skill 不因版面為多行而被判為零次

#### Scenario: 只滿足不可用條件者不計入

- **GIVEN** 某段文字規定互動不可用時不寫入某筆記錄，或顯示摘要後終止 workflow，但未規定以純文字提出相同問題
- **WHEN** skill 回歸套件執行
- **THEN** 該段文字不計入該檔的 fallback 陳述次數
- **AND** 該 skill 不因保留該段文字而失敗

#### Scenario: 只滿足純文字替代者不計入

- **GIVEN** 某段文字以純文字或純語言描述報告本文的可讀性要求，未指出該工具不可用
- **WHEN** skill 回歸套件執行
- **THEN** 該段文字不計入該檔的 fallback 陳述次數

#### Scenario: 不使用該工具的 skill 要求為零次

- **GIVEN** 某個 canonical `SKILL.md` 完全不使用 AskUserQuestion
- **WHEN** skill 回歸套件執行
- **THEN** 該 skill 的 fallback 陳述次數 MUST 為零
- **AND** 該 skill 不被要求加入 fallback 規則

##### Example: 判定條件的兩軸

| 文字形狀 | 滿足 (a) | 滿足 (b) | 計為 fallback 陳述 |
| --- | --- | --- | --- |
| 逐字提及工具名不可用，並說明改以純文字詢問並等待 | 是 | 是 | 是 |
| 以泛稱指涉該工具不可用，並說明改以純文字詢問並等待 | 是 | 是 | 是 |
| 不可用條件獨立成行，純文字替代作法在後續行 | 是 | 是 | 是（多行視窗） |
| 規定互動不可用時不寫入某筆記錄 | 是 | 否 | 否 |
| 規定工具不可用時顯示摘要並終止 workflow | 是 | 否 | 否 |
| 以純語言描述報告本文的可讀性要求 | 否 | 是 | 否 |
| 僅指示使用該工具而未提及不可用時的替代作法 | 否 | 否 | 否 |
