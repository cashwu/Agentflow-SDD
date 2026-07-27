## ADDED Requirements

### Requirement: TDD discipline 以適用性判準表述

Cash-owned `DISCIPLINES["tdd"]` SHALL是 `instructions --skill tdd` 回傳內容的唯一完整語意來源，並 MUST以 task 性質與驗證邊界表述 Red-Green-Refactor 的適用條件，而非要求每個 task 無條件建立失敗測試。`skill_payload("tdd")` MUST逐字回傳該 canonical instruction；command 與 JSON shape 繼續由既有「Artifact graph 與 instructions 使用單一來源」requirement 擁有，本 requirement MUST NOT重新定義該 shape contract。

canonical instruction MUST依下列 precedence 將每個 task 分到恰好一種處置：bug fix 且有實際可行自動測試邊界時，先以能辨識該缺陷的失敗測試重現；其餘新增或改變可觀察可執行行為且有實際可行自動測試邊界時，執行 Red-Green-Refactor；不改變可觀察行為的純 refactor 以既有 regression tests 保護並只在 evidence 不足時補 characterization test；其餘 task 使用命名 verification target，有可用自動 checker 時 MAY使用，但不得為文件、metadata、checker-only 或沒有實際可行自動測試邊界的 task 強迫建立 red phase。分類 MUST由前至後判定，命中後不得再落入後續分支。

對需要 red phase 的 task，初始測試 MUST因目標行為尚未存在而失敗，且 MUST以 diagnostic、state、artifact 或等價 assertion 區分目標路徑與不相關的較早 guard、pre-existing suite failure 或只有相同 exit code 的失敗。實作 SHALL以最小變更使該測試通過，並只在綠燈狀態進行 refactor。discipline MUST保持 tool與framework中立。

回歸測試 MUST分別斷言 observable executable behavior、目標失敗原因、unrelated failure 排除、minimal green、green refactor、bug reproduction、pure-refactor evidence與remaining-task verification八個行為語意，不得只以 `Red-Green-Refactor` 單一 marker 代表完整 contract。測試 MUST另以獨立 assertions 驗證四分支由前至後的 precedence、沒有可行自動測試邊界的 bug fix 與具有 checker 的文件／metadata task 都落入 remaining-task 分支，以及 canonical instruction 不要求任何特定程式語言或 test framework。

#### Scenario: CLI 逐字回傳 canonical TDD instruction

- **WHEN** caller執行 `instructions --skill tdd --json`
- **THEN** payload 的 `instruction` 逐字等於 `DISCIPLINES["tdd"]`
- **AND** payload 繼續符合「Artifact graph 與 instructions 使用單一來源」requirement 的既有 skill discipline shape contract

#### Scenario: 行為 task 執行有效 Red-Green-Refactor

- **GIVEN** task 新增可觀察的可執行行為且存在實際可行的自動測試邊界
- **WHEN** agent遵循 canonical TDD instruction
- **THEN** agent先建立因目標行為尚未存在而失敗的測試
- **AND** agent以最小實作使測試通過後，僅在綠燈狀態整理程式碼

#### Scenario: 不相關的較早失敗不構成 red phase

- **GIVEN** 新測試在到達目標路徑前已因另一個 guard 失敗
- **AND** 該失敗只與預期結果共享 exit code或缺少 artifact 等一般表象
- **WHEN** agent判定 red phase 是否成立
- **THEN** canonical discipline要求加入能辨識目標路徑的 diagnostic、state、artifact 或等價 assertion，或改用適合的驗證邊界
- **AND** agent不得把該不相關失敗視為目標行為的有效 red evidence

#### Scenario: 有自動測試邊界的 Bug fix 先建立可辨識的重現

- **GIVEN** task 修正一個既有缺陷
- **AND** 該缺陷存在實際可行的自動測試邊界
- **WHEN** agent套用 canonical TDD instruction
- **THEN** agent先以能辨識該缺陷的失敗測試重現
- **AND** 修正後該測試成為 regression evidence

#### Scenario: 純 refactor 與其餘 task 使用各自 evidence

- **GIVEN** task 不改變可觀察行為
- **WHEN** agent套用 canonical TDD instruction
- **THEN** agent使用既有 regression tests，並只在 evidence 不足時補 characterization test
- **AND** 不要求刻意製造 red phase

- **GIVEN** task 未命中前三個分支
- **WHEN** agent套用 canonical TDD instruction
- **THEN** agent執行命名 verification target
- **AND** 有可用自動 checker 時 MAY使用，但不要求 red phase

#### Scenario: Resource tests 覆蓋完整語意

- **WHEN** 執行 `PYTHONPATH=.cash-skills/lib python3 scripts/cash-cli/tests/test_graph_instructions.py`
- **THEN** 測試分別斷言八個必要行為語意、四分支 precedence、兩個 remaining-task boundary case 與 `skill_payload("tdd")` 的逐字同源
- **AND** 任一必要分支被移除時測試以非零結束
- **AND** 測試驗證 canonical instruction 不要求任何特定程式語言或 test framework
