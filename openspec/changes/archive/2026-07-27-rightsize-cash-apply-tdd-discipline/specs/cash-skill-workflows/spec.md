## ADDED Requirements

### Requirement: cash-apply 以條件式 canonical TDD discipline 驅動 task loop

`cash-apply` 的兩個變體 SHALL 將 TDD 視為由 `.cash.yaml` 條件式啟用的 embedded discipline。當且僅當 `tdd: true` 時，skill MUST 以 project-local Cash CLI 呼叫 `instructions --skill tdd`，並在 task loop 遵循回傳的 canonical `instruction`；`tdd: false` 時 MUST NOT強迫 task 執行 TDD red phase。兩個 `SKILL.md` SHALL 只擁有 toggle、consumer invocation 與共同 task-completion contract，MUST NOT複述由 Cash-owned resource 擁有的 Red-Green-Refactor sequence、bug-fix fail-first 規則或 task-type 適用性矩陣；`Red-Green-Refactor` literal 在每個變體中 MUST 恰好出現零次。

不論 toggle 值，每個 task 在呼叫 `task done` 前 MUST具有適合該 task 性質、可對照 `tasks.md` verification target 與相關 Implementation Contract 的 verification evidence。skill MUST將規格 `##### Example:` 視為 task scope 內的高保真 acceptance reference，但 MAY在有具體風險或邊界理由時增加其他 test case；example table MUST NOT被解讀為唯一允許的輸入集合。

`cash-apply` 的 TDD consumer、verification-evidence gate 與 example-reference 段落在 `.claude` 與 `.agents` 兩個變體中，經 invocation prefix（`/cash-` 與 `$cash-`）正規化後 MUST逐行完全相同。回歸套件 MUST提供可獨立執行的 `tdd-discipline` 具名群組，並 MUST將該群組納入全量執行路徑；該群組 MUST驗證兩個變體的條件式 consumer、單一來源禁重複、共同 verification gate 與舊絕對規則不存在。

#### Scenario: 啟用 TDD 時按需取得 canonical discipline

- **GIVEN** project root 的 `.cash.yaml` 包含 `tdd: true`
- **WHEN** `cash-apply` 進入 task loop 前讀取 project preferences
- **THEN** skill 呼叫 `"$cash_cli" instructions --skill tdd` 並遵循回傳的 `instruction`
- **AND** skill 自身不含 `Red-Green-Refactor` literal，只遵循回傳的 canonical `instruction`

#### Scenario: 停用 TDD 時仍保留 verification gate

- **GIVEN** project root 的 `.cash.yaml` 包含 `tdd: false`
- **WHEN** `cash-apply` 執行一個 pending task
- **THEN** skill 不強迫該 task 先建立 TDD red phase
- **AND** skill 仍要求 task 指定的 test、CLI、analyzer 或 manual assertion 通過後才呼叫 `task done`

#### Scenario: 純 refactor 不被迫製造失敗測試

- **GIVEN** `tdd: true` 且某個 task 不改變可觀察行為
- **WHEN** canonical TDD discipline 將該 task 分類為純 refactor
- **THEN** task 以既有 regression tests 保護行為，並只在既有 evidence 不足時補 characterization test
- **AND** `cash-apply` 不因沒有刻意失敗的測試而阻擋該 task 完成

#### Scenario: 其餘 task 使用命名 verification target

- **GIVEN** `tdd: true` 且某個 task 未命中 canonical discipline 的前三個分支
- **WHEN** task loop 執行該 task
- **THEN** task 執行 `tasks.md` 指定的 verification target
- **AND** 有可用自動 checker 時 MAY使用，但 skill 不要求 red phase

#### Scenario: Example 是 reference 而非封閉輸入集合

- **GIVEN** task scope 的 spec 包含一個 `##### Example:` table
- **WHEN** `cash-apply` 建立 verification evidence
- **THEN** table 的每列輸入與預期結果都被納入驗證
- **AND** 有具體風險或邊界理由時 MAY加入 example 以外的 test case

#### Scenario: TDD contract 由具名群組治理

- **WHEN** 執行 `fish scripts/cash-skills/tests/skill-checks.fish tdd-discipline`
- **THEN** 套件驗證兩個 `cash-apply` 變體各有唯一的條件式 TDD consumer invocation與共同 verification-evidence gate
- **AND** 套件驗證兩檔皆不含舊的 per-task absolute fail-first 或「TDD 關閉仍必須更新測試」規則，且各檔的 `Red-Green-Refactor` literal count 恰為零
- **AND** 相同 assertions 由全量 `skill-checks.fish` 執行路徑觸發

#### Scenario: 兩個變體保持完整對等

- **WHEN** 比較 `.claude/skills/cash-apply/SKILL.md` 與 `.agents/skills/cash-apply/SKILL.md`
- **THEN** TDD consumer、verification-evidence gate 與 example-reference 段落在 invocation prefix 正規化後逐行完全相同
- **AND** parity 驗證不只比較選定 markers
