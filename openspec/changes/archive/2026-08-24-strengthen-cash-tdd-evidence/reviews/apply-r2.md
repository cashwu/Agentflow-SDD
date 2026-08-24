# Cash Apply Review — Round 2

## Reviewer Findings

### Critical

（無）

### Warning

（無）

### Suggestion

- `severity`: Suggestion｜`confidence`: 95｜`layer`: design｜`location`: `scripts/cash-cli/tests/test_graph_instructions.py:505`、`:516-524`、`:541-549`｜`summary`: 三個 validator 原本各自的顯式 `forbidden` literal tuple（共 12 個 literal）仍是 dead code——任何能觸及它們的 mutation 都會先移除某個必要 literal，因而被較早的 `missing …` 路徑拒絕；Reviewer V 以 scratchpad 副本清空三個 tuple 後仍為 22 tests OK｜`recommendation`: 刪除三個合成 `forbidden` tuple、只保留 `_reject_permissive` 作為單一 forbidden 守門，或為每個 tuple 補一個保留全部必要 literal、只附加該禁止句的 mutation｜`disposition`: fix-introduced｜`introduced_by`: Round 1 Fix Action W3 在既有 tuple 之外「新增」`PERMISSIVE_CONTRADICTIONS`／`_reject_permissive`，而非取代它們，使 round 1 建議中「把 forbidden 由測試自造合成字串擴為可辨識措辭集合」只執行了一半｜reviewer source: V

- `severity`: Suggestion｜`confidence`: 65｜`layer`: design｜`location`: `scripts/cash-cli/tests/test_graph_instructions.py:478-495`｜`summary`: `PERMISSIVE_CONTRADICTIONS` 含 `不必`、`可以不`、`視情況` 等裸露的寬鬆 token，與 canonical 文本既有的合法措辭（`不要求 red phase`、`不要求新增 mutation framework`）是近義詞；純粹改寫為 `不必建立 red phase` 這種等義表述會被誤判為 forbidden。Reviewer V 已確認目前所有 canonical 文本命中數為零，屬未來措辭風險而非現行 false positive｜`recommendation`: 把每個寬鬆 literal 錨定到它不得弱化的義務（例如 `可以先做 production edit`、`可以略過 mutation check`、`red 欄位可以留空`），而非比對裸露的寬鬆 token｜`disposition`: fix-introduced｜`introduced_by`: Round 1 Fix Action W3，`test_graph_instructions.py:478-484`｜reviewer source: V

- `severity`: Suggestion｜`confidence`: 60｜`layer`: design｜`location`: `scripts/cash-skills/tests/skill-checks.fish:235-240`，套用於 `:273-275` 與 `:314-316`｜`summary`: `test_quality_gate_literals` 是英文片語集合，但它要防止被複述的 canonical discipline 是繁體中文，因此只有逐字英文改寫才會被攔到；反向而言 `expected value` 泛用到可能誤傷 cash-apply 中描述 spec `##### Example:` 的合法散文｜`recommendation`: 改為斷言實際中文 canonical 片段不存在，或改以 `instructions --skill test-quality` consumer 數量加結構檢查取代，並移除泛用的 `expected value` literal｜`disposition`: fix-introduced｜`introduced_by`: Round 1 非阻塞修復「去重 assert 覆蓋不足」，`skill-checks.fish:235-240`｜reviewer source: V

## Rating

- post-filter cumulative blocking set Critical count: 0
- post-filter cumulative blocking set Warning count: 0
- 非阻塞 triaged finding count: 3
- `critical_gap`: false
- `round_type`: micro

rationale：Reviewer V 對 cumulative blocking set 的三個成員各給出明確 verdict，全部為 `resolved`，且逐一附上可重現的證據——W1 以 `.claude`／`.agents` cash-debug 的 toggle-scoped ordering 段落與兩條新 assert 佐證，W2 以 delta 與 master 區塊逐行 diff（唯一差異即列舉擴充）與 `validate` 通過佐證，W3 以「移除三行 `_reject_permissive` 呼叫即 3 個測試失敗」的 mutation 證明 fix 確實生效而非僅被記錄。三個成員因此以 verified resolution 離開 cumulative blocking set，集合清空。本輪新增的三筆 finding 全部是 `Suggestion`，依規則不具阻塞性，故本輪 `passed`。

## Fix Actions

None; pass condition met.

- 降級 trace：Reviewer V 的第四筆 finding（`.claude/skills/cash-debug/SKILL.md:100-104`、`.agents/skills/cash-debug/SKILL.md:100-104`，`severity`: Suggestion、`confidence`: 40、`layer`: text、`disposition`: new，指出 Phase 4 只列舉 `tdd: true` 與 `tdd: false` 兩個顯式分支，未明說 `.cash.yaml` 未設 `tdd` key 時的歸屬）confidence 低於 50，依 confidence filter 捨棄，不計入非阻塞 triaged 計數。Reviewer V 同時指出該措辭形態沿用自既有的 cash-apply preference block，且結尾的「Both `tdd` values require…」段落與 Guardrails 仍綁定 verification，因此非矛盾。
- 驗證解除 trace（三筆，皆由 Reviewer V 驗證）：
  - W1（cash-debug Phase 4 絕對 ordering 與 executed-RED gate 互斥）— fix 參照 Round 1 Fix Action W1 —（verified resolution）。
  - W2（master spec `Cash workflow command surface` 列舉未被 delta 涵蓋）— fix 參照 Round 1 Fix Action W2 —（verified resolution）。
  - W3（三個 validator 的 `forbidden` guard 為 dead code）— fix 參照 Round 1 Fix Action W3 —（verified resolution）。
- Triage note（三筆非阻塞 `Suggestion`，全部 `fix-introduced`，不阻塞本輪 pass）：合成 `forbidden` tuple 仍為 dead code、`PERMISSIVE_CONTRADICTIONS` 使用裸露寬鬆 token 有未來措辭誤判風險、`test_quality_gate_literals` 為英文片語集合而 canonical 文本為中文致辨別力偏弱。三者皆屬 deterministic 測試守門的精煉，不影響本 change 交付的可觀察行為；已納入 signals write step，並列於完成輸出。
- 無 `未修復：裁判面保護` 記錄。
- 本輪未修改任何檔案，因此不觸發 change 目錄外的 `touched` 記錄步驟。

## Decision

passed
