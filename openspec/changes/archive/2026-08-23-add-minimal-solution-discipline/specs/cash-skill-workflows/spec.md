## MODIFIED Requirements

### Requirement: cash-apply 實作紀律以判準表述

`cash-apply` 兩個變體的 `SKILL.md` SHALL 以單一段落陳述 task loop 期間的實作紀律，且該段落 MUST 以判準表述而非逐項風格禁令。該段落 MUST 保留下列兩項可稽核內容：

- **diff 可追溯性驗收標準**：本次 diff 的每一行都能直接追溯到 `tasks.md` 中的某條任務，或 `design.md` 中的 Implementation Contract 項目。
- **Implementation Notes Protocol 銜接**：刻意偏離時，依 Implementation Notes Protocol 寫一筆 `deviation` 條目。

該段落 MUST NOT 逐項列舉語法層級的風格禁令（例如巢狀三元運算子、dense one-liner、method chain 長度、中介變數或命名常數的去留）。這類列舉是替模型的品味立法，且會與同段落的簡潔要求互相拉扯，MUST 以「clarity 優先於 brevity」這類判準取代。

在每個 task 寫入 code 前，`cash-apply` SHALL 先重新讀取 task、相關 spec、Implementation Contract 與實際 call flow，再執行 ordered minimal-solution ladder。任何候選方案都 MUST 先完整滿足 observable behavior、interface／data shape、failure modes、acceptance criteria、trust-boundary validation、data-loss prevention、security 與 accessibility；未通過者不屬於可選方案。通過後，skill MUST 依 `reuse`、`stdlib`、`native`、`installed-dependency`、`custom` 的順序停止在第一個成立的 rung。此 ladder MUST NOT 含「one line」或任何以行數取代 clarity 的 rung。

scope eligibility 只能辨識 task／contract 衝突或不清楚需求，MUST NOT 讓 agent 以 YAGNI 名義靜默略過 pending task。衝突或不清楚時，skill SHALL 沿用既有 unclear-task／blocker triage。多個候選皆保持 contract 時，skill MUST 先選較早 rung；同一 rung 成本相當時，先選 edge-case correctness 較強者，再選較符合既有 codebase pattern 者。此 tie-break MUST NOT 新增 pause branch，且 MUST NOT 取代 contract-preserving mechanism substitution 的 `deviation` 義務。

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

#### Scenario: ladder 在理解問題後依序停止

- **GIVEN** task、相關 spec、Implementation Contract 與實際 call flow 已被讀取
- **AND** `reuse` 與 `stdlib` 候選都完整通過 eligibility gate
- **WHEN** `cash-apply` 選擇實作機制
- **THEN** skill 選擇 `reuse`
- **AND** 不繼續選擇 `stdlib`、`native`、`installed-dependency` 或 `custom`

#### Scenario: 較早 rung 未滿足 contract 時繼續

- **GIVEN** codebase 的既有 helper 無法滿足 required failure mode
- **AND** standard library 方案完整滿足 observable behavior、interface／data shape、failure modes 與 acceptance criteria
- **WHEN** `cash-apply` 執行 ladder
- **THEN** `reuse` 候選被排除
- **AND** skill 選擇 `stdlib`

#### Scenario: pending task 不被 YAGNI 靜默略過

- **GIVEN** pending task 與 Implementation Contract 之間的必要行為不一致或不清楚
- **WHEN** `cash-apply` 執行 scope eligibility gate
- **THEN** skill 走既有 unclear-task／blocker triage
- **AND** skill MUST NOT 以 YAGNI 名義把 task 標記完成或靜默略過

#### Scenario: 同 rung 以 correctness 與既有 pattern 裁決

- **GIVEN** 兩個 `stdlib` 候選都保持 contract 且成本相當
- **WHEN** 其中一個候選對 edge cases 較正確
- **THEN** skill 選擇 edge-case correctness 較強者
- **AND** 只有 correctness 仍相當時才以既有 codebase pattern 作為下一個 tie-break
- **AND** 該內部選擇不觸發暫停分支

#### Scenario: ladder 不以 brevity 犧牲 safety

- **GIVEN** 一個較短候選會移除 trust-boundary validation 或 accessibility behavior
- **WHEN** `cash-apply` 評估該候選
- **THEN** 該候選不通過 eligibility gate
- **AND** skill 選擇完整保留 safety 與 acceptance criteria 的方案

##### Example: 判準式與列舉式的分界

| 表述 | 屬於 | 允許 |
| --- | --- | --- |
| 本次 diff 的每一行都能追溯到某條任務或 Implementation Contract 項目 | 可稽核驗收標準 | 是 |
| clarity 永遠優先於 brevity | 判準 | 是 |
| `reuse`、`stdlib`、`native`、`installed-dependency`、`custom` 的 ordered ladder | 可稽核機制選擇順序 | 是 |
| 不要使用巢狀三元運算子 | 語法層級風格禁令 | 否 |
| 不要為了減少行數犧牲可讀性的 dense one-liner | 語法層級風格禁令 | 否 |

## ADDED Requirements

### Requirement: Reviewer B 檢查變更引入的不必要複雜度

cash-propose 與 cash-apply 的 full-round `Reviewer B` SHALL 在既有品質掃描內加入 complexity lens，並 MUST NOT 新增第三位 reviewer、round type、finding schema、severity、confidence threshold 或 decision branch。對 cash-propose，該 lens SHALL 檢查 proposal、design 與 tasks 是否要求或默許 artifact 未證明為 contract 所需的複雜度；對 cash-apply，該 lens SHALL 只檢查 changed diff 引入的複雜度。

complexity lens MUST 明確涵蓋 `new dependency`、`single-implementation abstraction`、`pass-through wrapper`、`speculative configuration`、`duplicate existing capability`，以及可由 `stdlib`／`native` 取代的 custom code。Reviewer B MUST NOT 對 pre-existing code、unrelated refactor、由 contract 明確要求的機制、或已在 `design.md`／`implementation-notes.md`／proposal Non-Goals／`## Alternatives Considered` 說明的 intentional complexity 提出此類 finding。LOC、預估 token、cost 或 time MUST NOT 作為 finding、severity、confidence 或 gate decision 的輸入。

shared review-gate source、注入後的四個 canonical skills 與回歸套件 SHALL 保持上述 lens 一致。cash-apply Reviewer B 的 findings 仍受既有 `introduced_by` 證據與 confidence downgrade 規則約束。

#### Scenario: cash-propose 掃描 artifact 引入的複雜度

- **GIVEN** proposal 要求新增 dependency
- **AND** standard library 已完整滿足相同 contract
- **AND** artifacts 未說明 dependency 是 contract 所需
- **WHEN** cash-propose 的 Reviewer B 執行 full round
- **THEN** Reviewer B 回報該 unnecessary-complexity finding
- **AND** finding 使用既有 schema、severity 與 confidence 規則

#### Scenario: cash-apply 只掃描 changed diff

- **GIVEN** repository 既有一個 single-implementation abstraction
- **AND** 本 change diff 未新增或修改該 abstraction
- **WHEN** cash-apply 的 Reviewer B 執行 full round
- **THEN** Reviewer B 不以 complexity lens 回報該 pre-existing abstraction

#### Scenario: contract 要求的機制不是 unnecessary complexity

- **GIVEN** Implementation Contract 明確要求一個 state machine
- **WHEN** changed diff 依該 contract 實作 state machine
- **THEN** Reviewer B MUST NOT 僅因存在較短但不滿足 contract 的方案而回報 complexity finding

#### Scenario: pass-through wrapper 被辨識

- **GIVEN** changed diff 新增一個只有單一 caller、只轉呼叫既有 API 且不隱藏任何 behavior 的 wrapper
- **AND** task 與 contract 未要求新的 seam
- **WHEN** cash-apply 的 Reviewer B 執行 full round
- **THEN** Reviewer B 以既有 finding schema 回報該 pass-through wrapper

#### Scenario: reviewer 拓撲保持不變

- **WHEN** complexity lens 加入 full-round review
- **THEN** full round 仍恰好平行產生 Reviewer A 與 Reviewer B
- **AND** micro round 仍恰好產生 Reviewer V
- **AND** 不產生 complexity reviewer、rater 或第三位 reviewer

#### Scenario: LOC 不參與裁決

- **GIVEN** 兩個方案都滿足 contract
- **WHEN** Reviewer B 評估其中一個方案
- **THEN** Reviewer B 不以行數、`net: -N lines`、預估 token、cost 或 time 決定 finding 或 gate 結果

### Requirement: cash-apply 記錄已知 ceiling 的 deviation

當 `cash-apply` 依既有 Implementation Notes Protocol 已須記錄一筆 `deviation`，且所採 contract-preserving 替代手段具有非平凡、真實且已知的 ceiling 時，skill SHALL 在既有 `原因` 欄位之後追加 `限制` 與 `重訪條件` 兩欄。兩欄 MUST 成對出現；`限制` MUST 指出不影響目前 contract、但會使替代機制不再適用的具體 scale、resource、contention、latency、platform 或 algorithmic bound，`重訪條件` MUST 是可觀察或可衡量的 trigger。

若替代手段沒有非平凡已知 ceiling，deviation SHALL 維持既有四欄 shape，不新增 `限制` 或 `重訪條件`，也不填 `none`。routine implementation、ordinary tradeoff 與未偏離 artifact 的內部判斷 MUST NOT 因本 requirement 建立新 note。`open-question` shape 保持不變。

ceiling 若已侵害目前 observable behavior、interface／data shape、failure modes、acceptance criteria 或 safety boundary，該替代手段 MUST NOT 被視為 contract-preserving，skill MUST 走既有暫停分支而非寫完 deviation 後繼續。Reviewer A 與 Reviewer V SHALL 把 known-ceiling deviation 缺少任一欄、不可觀察的 trigger 或侵害目前 contract 的 ceiling 納入既有 deviation justification 評估，不新增 decision branch。

#### Scenario: 已知 ceiling 時追加成對欄位

- **GIVEN** 原設計手段在目標平台不可行
- **AND** global lock 替代手段保持目前 contract
- **AND** 已知 ceiling 是每秒 100 次操作以上的 contention
- **WHEN** `cash-apply` 記錄既有 blocker triage 要求的 `deviation`
- **THEN** entry 在 `原因` 後含 `限制`，指出每秒 100 次操作的 contention ceiling
- **AND** entry 含 `重訪條件`，指出觀察到每秒 100 次操作時重新設計
- **AND** skill 繼續該 task

#### Scenario: known-ceiling 欄位不得缺一

- **GIVEN** 一筆 deviation 具有非平凡已知 ceiling
- **WHEN** entry 只有 `限制` 或只有 `重訪條件`
- **THEN** Reviewer A 或 Reviewer V 把不完整 shape 納入 deviation justification finding

#### Scenario: 空泛 trigger 不被接受

- **GIVEN** 一筆 known-ceiling deviation 的 `重訪條件` 只有「之後需要時」或「規模變大時」
- **WHEN** Reviewer A 或 Reviewer V 評估該 entry
- **THEN** reviewer 將 trigger 判定為不可觀察且不充分

#### Scenario: 無已知 ceiling 維持既有 shape

- **GIVEN** 一筆依既有 protocol 必須記錄的 deviation 沒有非平凡已知 ceiling
- **WHEN** `cash-apply` 寫入 entry
- **THEN** entry 維持 title、`類別`、`任務`、`內容`、`原因` 的既有 shape
- **AND** entry 不含 `限制` 或 `重訪條件`

#### Scenario: routine implementation 不建立 debt note

- **GIVEN** task 使用 `stdlib` 且完整符合 artifacts
- **AND** implementation 沒有偏離 spec、design 或 tasks
- **WHEN** `cash-apply` 完成該 task
- **THEN** skill 不因 minimal-solution ladder 建立 `deviation`

#### Scenario: ceiling 侵害 contract 時暫停

- **GIVEN** 替代手段的 ceiling 會使目前 acceptance criteria 在有效輸入下失敗
- **WHEN** `cash-apply` 分類該替代手段
- **THEN** skill MUST NOT 把它記為 contract-preserving deviation 後繼續
- **AND** skill 走既有 contract／範圍／行為變更暫停分支
- **AND** 引導使用者前往 `cash-ingest`

#### Scenario: 兩個變體保持對等

- **WHEN** 比較 `.claude/skills/cash-apply/SKILL.md` 與 `.agents/skills/cash-apply/SKILL.md` 的 ladder 與 Implementation Notes Protocol 段落
- **THEN** 兩者在 invocation 前綴（`/cash-` 與 `$cash-`）正規化後 MUST 完全相同
