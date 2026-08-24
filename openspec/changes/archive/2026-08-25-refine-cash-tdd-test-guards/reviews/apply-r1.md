# Cash Apply Review — Round 1

## Reviewer Findings

Round 1 為本次 run 的第一輪 full round，兩位 reviewer（A — Adherence、B — Quality）以相同 context 平行且獨立執行，未互相傳遞輸出。本輪為 unseeded 第一輪，因此不標註 `disposition`。

### Critical

無。

### Warning

無。（Reviewer B 的 finding 2 原始 `severity` 為 `Warning`、`confidence` 為 60，經 confidence filter 依 `[50, 80)` 區間降級為 `Suggestion`；降級 trace 記於 `## Fix Actions`。）

### Suggestion

1. `severity`: Suggestion｜`confidence`: 60｜`layer`: design｜`location`: `openspec/changes/refine-cash-tdd-test-guards/design.md` §D1，以及其逐字複本 `scripts/cash-cli/tests/test_graph_instructions.py` 的 `TDD_CONTRADICTIONS`／`TEST_QUALITY_CONTRADICTIONS`／`TASKS_CONTRADICTIONS`｜`summary`: 十三個 contradiction literal 中的 `red-after-edit`、`non-observable-result`、`framework-required`、`test-for-every-task` 四個，是其自身「加上否定詞的合法反述」的子字串，未來若 canonical 文本以 `不` 前綴改寫成強化義務的句子，會被誤判為 forbidden｜`recommendation`: 若接受此殘餘邊界，於 `design.md` §Risks / Trade-offs 補一句說明以 `可以`／`必須` 開頭的義務型 literal 可能與 `不` 前綴的合法否定碰撞；否則把該四個 literal 向左延伸使否定詞落入比對範圍，惟 C1 已把 inventory 逐字釘死於 D1，需經 `/cash-ingest` 才能變更｜reviewer source: A

2. `severity`: Suggestion｜`confidence`: 60｜`layer`: design｜`location`: `scripts/cash-skills/tests/skill-checks.fish` 的 `FORBIDDEN_GATE_CLAUSES` 與 `EXPECTED_GATE_FIXTURES`｜`summary`: 五個 `zh` clause 逐字等於 canonical `DISCIPLINES["test-quality"]` 的片段，但沒有任何斷言把兩者錨定；canonical 若改寫，該去重 guard 會靜默失效而 `tdd-discipline` 仍為綠｜`recommendation`: 在 `assert_test_quality_single_source` 內引入 `cash_cli.resources.DISCIPLINES`，當任一 `zh` clause 不是 canonical 子字串時 `record()` 一筆失敗；此為 anchor assertion 而非 derivation，與 D3／C3 的「十個 clause 逐字固定、fixture 不得從 registry 推導」相容｜`introduced_by`: `git diff scripts/cash-skills/tests/skill-checks.fish` 新增 hunk `@@ -321,6 +310,132 @@`（新的 `FORBIDDEN_GATE_CLAUSES` dict），取代 `@@ -232,12 +232,7 @@` 刪除的 `test_quality_gate_literals`｜reviewer source: B

3. `severity`: Suggestion｜`confidence`: 75｜`layer`: design｜`location`: `scripts/cash-cli/tests/test_graph_instructions.py` 的 `test_validators_accept_legitimate_phrasings_with_retired_tokens` 與 `RETIRED_PERMISSIVE_TOKENS`｜`summary`: `assertIn(token, RETIRED_PERMISSIVE_TOKENS)` 為套套邏輯——迴圈硬寫的三個 token 與同檔案中恰含該三者的 tuple 互相比對，同時刪掉兩者不會被 suite 察覺｜`recommendation`: 或者移除 `RETIRED_PERMISSIVE_TOKENS` 與該 `assertIn`（真正有鑑別力的是 `assertIn(token, phrasing)` 與三個 `assert_accepted`），或者改為斷言三個 retired token 都不是任一 detector inventory 的完整 value，使其成為「裸 token 未被重新加入」的實質守衛｜`introduced_by`: `git diff scripts/cash-cli/tests/test_graph_instructions.py` 新增 hunk `@@ -399,11 +389,122 @@` 與 `@@ -474,25 +579,70 @@`｜reviewer source: B

4. `severity`: Suggestion｜`confidence`: 60｜`layer`: design｜`location`: `scripts/cash-skills/tests/skill-checks.fish` 的 `clean = (root / SKILL_FILES[0]).read_text(...)` 與其後的 injection loop｜`summary`: mutation baseline `clean` 取自受測的 live artifact `.agents/skills/cash-apply/SKILL.md` 而非固定 fixture，符合 `expected-set-derived-from-observed-state` 的形狀；由於 `duplicated_gate_clauses` 回報的是 membership 而非出現次數，若該 live 檔案未來含有某個 clause X，X 的 injection self-test 會變成恆真而失去鑑別力｜`recommendation`: 在 injection loop 前明確守衛 baseline（例如 `if duplicated_gate_clauses(clean): record(...)`），或改用固定的合成 base string｜`introduced_by`: `git diff scripts/cash-skills/tests/skill-checks.fish` 新增 hunk `@@ -321,6 +310,132 @@` 的 `clean = ...` 行與其後的 injection loop｜reviewer source: B

### 兩位 reviewer 獨立完成的驗證（非 finding，記錄為本輪證據）

- Reviewer A 與 Reviewer B 各自在 scratch 副本上逐一刪除 `TDD_CONTRADICTIONS`／`TEST_QUALITY_CONTRADICTIONS`／`TASKS_CONTRADICTIONS` 的全部 13 個 detector entry，兩者都確認**目標** additive-mutation test 本身失敗，而非僅由較早的 inventory 等式失敗取代——滿足 D2 的 `不得以⋯⋯另一個較早失敗取代目標 guard`。
- Reviewer B 另逐一破壞 `FORBIDDEN_GATE_CLAUSES` 的 10 個 clause value（保持 gate 與 language key set 合法，使只有 injection self-test 能捕捉），10 個全部被 `injected <gate>/<lang> must be the single detected duplication` 捕捉。
- Reviewer B 將 `independent-expected/en` 換回泛用的 `expected value`，`LEGITIMATE_PROSE` acceptance check 如期觸發，證明 false-positive 守衛為實質而非裝飾。
- Reviewer A 的 run-first-round claim verification：`design.md` Context 宣稱「HEAD 的顯式 `forbidden` tuples 未被行使」成立——在 HEAD 版本移除全部三組 tuple 後仍 22/22 通過。C1 要求保留的 carrier-neutral、framework-neutral、no-formal-test 三項邊界均仍為 required marker。
- 兩位 reviewer 都確認 repo 無 `PERMISSIVE_CONTRADICTIONS`／`_reject_permissive`／`test_quality_gate_literals` 的殘留引用，且 canonical `DISCIPLINES` bytes、tasks artifact resource 與四份 `SKILL.md` 均未被觸碰。
- `implementation-notes.md` 存在且僅含初始化註解、無任何 entry，依 protocol 視為 confirmed empty，不因空白本身產生 finding。
- 兩份 spec 皆無 `##### Example:` 區塊，故無 example 覆蓋義務。

## Rating

- post-filter cumulative blocking set Critical count：0
- post-filter cumulative blocking set Warning count：0
- 非阻塞 triaged finding count：0
- `critical_gap`: false
- `round_type`: full

rationale：本輪為 unseeded run 的第一輪，所有存活的 `Critical` 與 `Warning` 皆為阻塞。兩位 reviewer 合計提出 4 筆 finding，其中唯一一筆 `Warning`（`confidence` 60）與其餘三筆 `Suggestion`（`confidence` 60／75／60）在 confidence filter 後全部落於 `[50, 80)` 或原本即為 `Suggestion`，無任何 finding 達到 `confidence ≥ 80`，因此 post-filter 後無存活的 `Critical` 或 `Warning`，cumulative blocking set 為空。實作經兩位 reviewer 各自獨立的 guard-deletion 與 clause-neutering mutation 實驗，確認全部 13 個 contradiction guard 與 10 個雙語 clause 都具備個別鑑別力，且 primary 與 regression targets 全綠，符合 pass 條件。

## Fix Actions

None; pass condition met.

- Confidence filter 降級 trace（不計入 ledger `fixed_files`）：
  - Reviewer B finding 2（`scripts/cash-skills/tests/skill-checks.fish` 的 `zh` clause 未錨定 canonical `DISCIPLINES["test-quality"]`）原始 `severity` 為 `Warning`、`confidence` 為 60，落於 `[50, 80)` 區間，依 confidence filter 降級為 `Suggestion`。其 `introduced_by` 證據可驗證（指向具體 change-diff hunk），故不適用 cash-apply introduced-by 的 `≤ 25` 降級。
  - 其餘三筆 finding 原始即為 `Suggestion`，`confidence` 分別為 60、75、60，無降級或丟棄。
  - 無 `confidence < 50` 的 finding 被丟棄。
- 無 `未修復：裁判面保護` 紀錄：本輪未有任何 finding 的修復需要動到受保護的 grader 路徑。
- 無 accepted-risks 降級：`openspec/changes/refine-cash-tdd-test-guards/reviews/accepted-risks.md` 不存在。
- 無 disposition 修正：unseeded run 的第一輪不標註 `disposition`。
- Pre-round mechanical self-check（spawn reviewer 前，main agent inline 執行）結果：spec delta 的 `<!--`／`-->` 計數皆為 0 且無殘留 `---` 分隔線；proposal／design／tasks 對 scenario、gate、clause 與 contradiction 類別的數量宣稱（五個 gate、十個 clause、TDD 三類、test-quality 六類、tasks 四類）與實作及 spec 實際計數一致；`design.md` 定義的識別字（`PERMISSIVE_CONTRADICTIONS`、`test_quality_gate_literals`、`EXPECTED_*_CONTRADICTION_FIXTURES` 與兩個 delivery path）跨全部 artifact 與 changed files 拼寫與語意一致；兩份 delta spec 只有 `## ADDED Requirements`，無 MODIFIED／REMOVED／RENAMED，故 title-identity check 不適用；`openspec/signals/` 的 149 個 signal 全為 `status: open` 且**無任何** `check` frontmatter 欄位，故 signal-derived check 執行步驟為 no-op，改以既有 best-effort 判斷處理相關 signal issue class（已於 reviewer context 中列出）。以機械比對確認 D1 的 13 個 category literal 與 D3 的 10 個 clause 在 `design.md` 中逐字存在，且在各自 delivery file 中恰好各出現兩次（detector 一份、fixture 一份）。自 check 未發現任何需修正的缺陷。

## Decision

passed

本輪 post-filter cumulative blocking set 不含任何阻塞 `Critical` 或阻塞 `Warning`，符合 pass 條件，review loop 於本輪結束。四筆 `Suggestion` 皆為非阻塞，且其建議的修改分別需要變更 D1 逐字釘死的 inventory（需 `/cash-ingest`）或加入 contract 未要求的額外機制，依 Focused Implementation Discipline 不於本次 change 內實作，改列於完成輸出交由使用者決定。
