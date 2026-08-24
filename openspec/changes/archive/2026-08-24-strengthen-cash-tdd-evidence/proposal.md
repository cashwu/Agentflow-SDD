## Summary

強化 Cash 的測試驅動實作紀律：要求適用 TDD 的 task 實際執行並觀察可辨識的 RED 與 GREEN、以獨立的 canonical test-quality discipline 約束測試有效性、讓 tasks artifact 為每個 task 明列 verification target 與成功證據，並使 cash-debug 與 cash-apply 共用一致的 TDD toggle 語意。

## Motivation

Cash 現有 canonical TDD discipline 已能依 task 類型與自動測試邊界分類，並排除不相關 guard、pre-existing suite failure 與相同 exit code 造成的假 RED；但 instruction 尚未明訂 agent 必須在 production edit 前實際執行 target 並觀察預期 failure marker，也沒有獨立治理 expected value、observable behavior、mock boundary 與 mutation check 等測試品質。

同時，tasks template 只泛稱「執行驗證」，但 cash-apply 的完成 gate 依賴 tasks.md 的 named verification target，造成提案端可產出比執行端要求更弱的 task。cash-debug 又同時無條件要求 failing test、只在 tdd: true 時載入 canonical discipline，與 cash-apply 的 toggle 語意存在歧義。既有 open signals 已反覆記錄 vacuous RED、驗證覆蓋不完整、不可機械驗收與 expected set 自我推導等問題，顯示需要在 canonical instruction 與 artifact contract 層修補，而非繼續增加零散提示。

## Proposed Solution

- 擴充 DISCIPLINES["tdd"]：需要 red phase 時，必須在任何 production edit 前實際執行目前 workflow 命名的 primary verification target，觀察到能辨識目標缺失的 failure marker；實作後重跑同一 target 轉綠，再執行命名的 regression target。保留現有四分支 precedence，不把文件、metadata、純 refactor 或無可行自動測試邊界的 task 強迫成假 RED。
- 新增 DISCIPLINES["test-quality"] 作為測試品質的單一來源。任何 cash-apply 或 cash-debug 流程只要新增或修改測試，就按需取得並遵循它，不受 tdd toggle 控制。判準限制為：測試須對應一個可命名的 production defect、expected value 獨立於受測邏輯推導、斷言 observable behavior、mock 只切 slow 或 external boundary 且不得以 mock 自身存在作為結果、完成前以有限 mutation check 確認關鍵錯誤會被捕捉。
- 擴充 tasks artifact 的 canonical resource，使每個 task 都明列 delivery、primary verification、regression、成功證據與 red marker；需要 red phase 的 task另列可辨識的預期失敗。TDD ordering 仍只由 DISCIPLINES["tdd"] 擁有，tasks.md 不複述完整 sequence。
- 收斂 cash-debug：tdd: true 時遵循 canonical TDD discipline；tdd: false 時不強迫 fail-first ordering，但仍保留 root-cause fix、named verification target 與 regression verification。新增或修改測試時一律遵循 canonical test-quality discipline。
- 擴充 CLI resource tests、discovery contracts 與 skill checks，分別治理 RED/GREEN 實際觀察語意、test-quality 判準、task template contract、cash-apply／cash-debug consumers 與 Claude／Codex variant parity。

## Non-Goals

- 不採用「所有 production code 一律先有 failing test」或「每個 function／method 都必須有獨立測試」的絕對規則。
- 不改變 .cash.yaml schema、tdd 預設值、任何 test framework、coverage threshold 或 test file layout。
- 不要求修復與本 change 無關的 pre-existing suite failure；只要求辨識它並證明本次 target 與相關 regression target 的結果。
- 不建立新的 LLM／agent behavior eval harness。真實 agent pressure scenarios 可作後續 change；本次不引入外部模型依賴、API key 或非決定性 CI。
- 不新增持久化 TDD evidence ledger；RED/GREEN 證據維持為 task loop 的即時執行 gate。
- 新增 test-quality resource 的自舉 task 只在 resource 尚不存在時以本 change 的 Implementation Contract 五項 gate 作為一次性 bootstrap；完成 managed resource edits 後先以 `./install-cash-skills.fish --self` 發布可信 bundle，再以 project-local CLI 取得並驗證 canonical instruction，之後才可進行其他 test edit。此例外不延伸到其他 change。

## Alternatives Considered

- 將所有測試品質規則直接塞入 DISCIPLINES["tdd"]：檔案數較少，但 tdd: false 時新增的測試不受治理，且 ordering 與 test quality 是不同 concern。
- 在 cash-apply 與 cash-debug 各自複述 test-quality bullets：初期直接，但會形成多份語意來源與 variant drift。
- 立即建立真實 agent behavior eval：能驗證 skill 是否被模型遵守，但目前 repository 沒有既有 harness，會引入執行環境、成本與非決定性；先把 canonical contract 與 deterministic consumer gates 補齊較小且可交付。
- 保留 cash-debug 的無條件 fail-first 規則：對有可行測試邊界的 bug 很嚴謹，但會讓 tdd toggle 在不同 Cash workflow 代表不同意思，並重新引入 canonical discipline 已排除的假 RED 情境。

## Capabilities

### New Capabilities

- (none)

### Modified Capabilities

- cash-cli：擴充 canonical TDD instruction、加入 test-quality discipline，並強化 tasks artifact resource 的 verification contract。
- cash-skill-workflows：定義 cash-apply／cash-debug 的 discipline consumers、TDD toggle 一致性、task verification target 與雙變體治理。

## Impact

- Affected specs:
  - openspec/specs/cash-cli/spec.md
  - openspec/specs/cash-skill-workflows/spec.md
- Affected code:
  - New:
    - (none)
  - Modified:
    - .cash-skills/lib/cash_cli/resources.py
    - .cash-skills/lib/cash_cli/installer.py
    - .cash-skills/manifest.tsv
    - .claude/skills/cash-apply/SKILL.md
    - .claude/skills/cash-debug/SKILL.md
    - .agents/skills/cash-apply/SKILL.md
    - .agents/skills/cash-debug/SKILL.md
    - scripts/cash-cli/tests/test_graph_instructions.py
    - scripts/cash-cli/tests/test_discovery_contracts.py
    - scripts/cash-skills/tests/skill-checks.fish
    - cash-skills.version
  - Removed:
    - (none)
