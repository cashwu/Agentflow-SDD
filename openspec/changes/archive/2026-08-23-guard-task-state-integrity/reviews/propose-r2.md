# Cash Propose Review — Round 2

## Reviewer Findings

### Critical

（無）

### Warning

1.
- `severity`: Warning
- `confidence`: 100
- `layer`: design
- `location`: `tasks.md` 任務 1.3「負向判準（實作前 exit 0，實作後 MUST exit 1）」
- `summary`: `test (rg -c -- '"review-loop"' … ; or echo 0) -eq 1` 的極性與其所屬區塊相反——實測 `"review-loop"` 字面值目前有 2 處、該判準實作前即 exit 1，而依 IC4 第 1 點實作後恰剩 1 處會使它 exit 0；照宣告字面，實作後 MUST exit 1 等於要求「不得只剩一處」，與 IC4 第 1 點直接矛盾。
- `recommendation`: 移到「正向判準」區塊，或改寫為 `-gt 1` 的負向形式。
- `disposition`: `fix-introduced`
- `introduced_by`: round 1 `## Fix Actions`「finding 17」條目——round 1 只驗證了該判準「乾淨回傳 exit 1（非語法錯誤）」，未驗證該 exit 值是否符合所屬區塊的宣告。
- reviewer source: Reviewer V — Verification
- 主 agent 複核：實測 `rg -c -- '"review-loop"'` 目前為 2，判準 exit 1；IC4 第 1 點要求實作後恰剩 1。finding 成立。

2.
- `severity`: Warning
- `confidence`: 90
- `layer`: design
- `location`: `design.md` IC6 ／ `tasks.md` 任務 1.3「行為判準」
- `summary`: IC6 逐字要求「`cash-cli` delta spec 的每一條 scenario」都要有 `test_realign_` 方法，但 round 1 之後該 delta 多了 `## MODIFIED Requirements` 的 11 條逐字沿用 scenario；照字面這 11 條既有行為也要各配一個 `test_realign_` 方法，而 `tasks.md` 只寫「`## ADDED Requirements` 每一條」，兩份 artifact 對同一義務的範圍不一致。
- `recommendation`: 把 IC6 的範圍逐字限縮為 `## ADDED Requirements` 之下的 scenario。
- `disposition`: `fix-introduced`
- `introduced_by`: round 1 `## Fix Actions` 的 finding 4（新增 MODIFIED 並沿用 11 條 scenario）與 finding 12（新增 IC6）——兩筆修復未互相同步。
- reviewer source: Reviewer V — Verification

3.
- `severity`: Warning
- `confidence`: 88
- `layer`: design
- `location`: `design.md` IC4 第 4 點
- `summary`: 「實作手段不限（例如回傳 tuple、…），但 MUST NOT 改變 `archive.py` 既有 `load_or_import_touched(workspace, name)` 呼叫點的取值形狀」句內自相矛盾——`archive.py` 取值後直接當 dict 使用，改回傳 tuple 必然破壞該呼叫點，而 `archive.py` 既不在 `## Impact` 也無任務授權修改。
- `recommendation`: 刪除「回傳 tuple」這個例子，或改寫為「新增內部 helper，`load_or_import_touched()` 的公開簽章與回傳形狀 MUST 不變」。
- `disposition`: `fix-introduced`
- `introduced_by`: round 1 `## Fix Actions`「finding 3」條目——IC4 第 2 點改為回傳 tuple 時，第 4 點的例子未與同句的 MUST NOT 對齊。
- reviewer source: Reviewer V — Verification

4.
- `severity`: Warning
- `confidence`: 85
- `layer`: design
- `location`: `tasks.md` 任務 1.4 判準
- `summary`: 判準寫「1.1、1.2 與 1.3 的每條字面值判準在對應的 `.agents` 檔案上…同樣成立」，但重新編號後 1.3 交付的是 `.cash-skills/lib/` 與 `scripts/cash-cli/tests/` 下的檔案，根本沒有 `.agents` 對應檔（IC7 也只指名兩個 `SKILL.md`），該判準對 1.3 不可滿足且無從執行。
- `recommendation`: 改為「1.1 與 1.2 的每條字面值判準」並註明 1.3 無 `.agents` 對應檔。
- `disposition`: `fix-introduced`
- `introduced_by`: round 1「post-fix mechanical self-check」（a）的重新編號——該處聲稱「同時更新全部交叉引用」，此引用未被正確更新。
- reviewer source: Reviewer V — Verification

### Suggestion

5.
- `severity`: Suggestion
- `confidence`: 70
- `layer`: design
- `location`: `specs/cash-cli/spec.md` `## MODIFIED Requirements` 的 `#### Scenario: 與既有 per-task 條目並存` 與 `#### Scenario: 重複記錄相同路徑不寫入`
- `summary`: 限縮後的散文明訂 `task_id` MAY 因對齊被改寫、對齊改變內容時 MUST 寫入，但這兩條逐字沿用的 scenario 分別斷言「既有 per-task 條目逐字不變」與「bytes 不變」且無「該 state 已與 `tasks.md` 對齊」的前提，字面上與新散文互斥。
- `recommendation`: 各補一條說明對齊不改變內容的 GIVEN。
- `disposition`: `fix-introduced`
- `introduced_by`: round 1 `## Fix Actions`「finding 4」條目（11 條既有 scenario 逐字沿用）。
- reviewer source: Reviewer V — Verification
- 過濾紀錄：原報 `Warning`／`70`，`confidence ∈ [50, 80)`，降為 `Suggestion`。

6.
- `severity`: Suggestion
- `confidence`: 70
- `layer`: design
- `location`: `specs/cash-cli/spec.md` `## ADDED Requirements` 散文 vs 其兩條 scenario
- `summary`: 散文只正面規定「對齊改變內容時 MUST 寫回」與「MUST 就地改寫 `task_id`」，未陳述 scenario 實際斷言的「未改變時 MUST NOT 寫入」與「該條目的 `files` 不變」；scenario 強於散文。
- `recommendation`: 在散文補這兩條規則。
- `disposition`: `fix-introduced`
- `introduced_by`: round 1 `## Fix Actions`「finding 3」條目（ADDED requirement 補持久化規則與兩條 scenario）。
- reviewer source: Reviewer V — Verification
- 過濾紀錄：原報 `Suggestion`／`70`，維持。

7.
- `severity`: Suggestion
- `confidence`: 65
- `layer`: design
- `location`: `design.md` IC3 第 1 點 ／ `tasks.md` 任務 1.2 判準
- `summary`: IC1 因 round 1 的修復已明訂縮排義務，但同輪新增的 IC3 沒有對等處置——`cash-commit` 步驟 2 內文縮排為 3 空格，而 IC3 的逐字段落以 column 0 呈現，任務 1.2 的判準都對縮排不敏感。
- `recommendation`: IC3 補縮排義務，並把一條正向判準改為含 3 空格前導的形式。
- `disposition`: `fix-introduced`
- `introduced_by`: round 1 `## Fix Actions`「finding 10」條目（新增 IC3）——finding 9 的縮排修復未 propagate 到同輪新建的 IC3。
- reviewer source: Reviewer V — Verification

8.
- `severity`: Suggestion
- `confidence`: 65
- `layer`: text
- `location`: `design.md` IC1 第 1 點散文
- `summary`: 散文寫「巢狀選項行為 5 空格與 7 空格」，但 fence 內兩行巢狀選項實際都是相對 5 空格，沒有任何一行是 7 空格；fence 為逐字權威，散文的數字與它不符。
- `recommendation`: 改為與 fence 實際縮排一致的描述。
- `disposition`: `fix-introduced`
- `introduced_by`: round 1 `## Fix Actions`「finding 9」條目。
- reviewer source: Reviewer V — Verification
- 過濾紀錄：主 agent 依 confidence filter 重檢此 `text` finding——fence 是逐字權威且未改動，修正散文的數字描述不改變任何行為或 design statement，維持 `layer: text`。

9.
- `severity`: Suggestion
- `confidence`: 60
- `layer`: design
- `location`: `specs/cash-skill-workflows/spec.md` 的 `### Requirement: cash-archive 未完成 task 的處置與失敗指引`
- `summary`: `cash-commit` 步驟 2 的 `touched_invalid` 復原指引被塞進標題為 `cash-archive …` 的 requirement 內；Requirement 標題是合併身分鍵，把另一個 skill 的義務掛在此標題下會使該義務日後難以定位與修訂。
- `recommendation`: 拆為獨立 requirement，連同其 scenario 一併移入。
- `disposition`: `fix-introduced`
- `introduced_by`: round 1 `## Fix Actions`「finding 10」條目。
- reviewer source: Reviewer V — Verification

## Rating

- post-filter cumulative blocking set Critical count: `0`
- post-filter cumulative blocking set Warning count: `4`
- 非 blocking 的 triaged finding 數：`5`
- `critical_gap`: `false`
- `round_type`: `micro`

rationale：Reviewer V 對 round 1 cumulative blocking set 的 11 名成員 M1–M11 全部給出 `resolved` 判定並附驗證證據（含以 Python 逐位元比對 MODIFIED 的標題與 11 條 scenario、實檔確認 `cash-commit` 步驟 2 先跑 `touched ensure` 才 parse state 檔），11 者依「verified resolution」離開 cumulative blocking set，該集合因此清空。但本輪新增九筆 `disposition: fix-introduced` 的 finding，其中四筆通過 confidence filter 後仍為 `Warning`（`100`／`90`／`88`／`85`，皆 ≥ 80），依規則 `fix-introduced` 為 blocking disposition，故四者進入 cumulative blocking set，本輪不能 pass。無 blocking `Critical`，`critical_gap` 為 `false`。其餘五筆降為或維持 `Suggestion`，非 blocking。本輪為本 run 第二輪，非第四輪，故 `round_type` 為 `micro`。

## Fix Actions

**cumulative blocking set 的 verified resolution 移除紀錄**

M1–M11 全部移除，fix reference 為 round 1 `## Fix Actions` 中對應的各條修復記錄，verifying reviewer 皆為 Reviewer V。關鍵證據：M3（對齊落地）——`## Context` 已記錄三個事實、`**D4**` 與 IC4 第 4、5 點指定新寫入條件，且 Reviewer V 實檔確認 `.claude/skills/cash-commit/SKILL.md` 步驟 2 確實先跑 `touched ensure` 才 parse state 檔，落地點涵蓋該消費端；M4（MODIFIED）——以 Python 逐位元切段比對，標題與 11 條 scenario 與 master spec 完全相同，`<!-- @trace -->` 已移除且無其他內容被連帶刪除；M7（`task_desc` 守則）——實測變數名無關形式目前 exit 1，且 `mapping[entry["task_desc"]] = …` 這類合法寫法不會誤命中。

**confidence filter 降級與丟棄紀錄**

- finding 5 原報 `Warning`／`70`，`confidence ∈ [50, 80)`，降為 `Suggestion`。
- finding 6、7、8、9 原即為 `Suggestion`（`70`／`65`／`65`／`60`），維持。
- finding 1、2、3、4 的 `confidence` 皆 ≥ 80，維持 `Warning`。
- 無 `confidence < 50` 的丟棄項。
- `layer` 重檢：finding 8 由 Reviewer V 標為 `text`，主 agent 確認 fence 為逐字權威且未改動、修正散文數字不影響行為或 design statement，維持 `text`。其餘皆為 `design`，未做 `design` → `text` 的重分類。
- 無 disposition 更正：九筆皆由 Reviewer V 標為 `fix-introduced`，主 agent 逐筆對照 round 1 的 fix-touched 位置後確認標記正確。

**blocking finding 的修復**

- finding 1：修改 `tasks.md`——把 `test (rg -c -- '"review-loop"' … ; or echo 0) -eq 1` 從任務 1.3 的「負向判準」移到「正向判準」區塊，並加註說明依 IC4 第 1 點實作前為 2（exit 1）、實作後為 1（exit 0），放在負向區塊會與 IC4 第 1 點直接矛盾。
- finding 2：修改 `design.md`（IC6 的範圍逐字限縮為「`cash-cli` delta spec **`## ADDED Requirements` 之下**的每一條 scenario」，並明寫 MODIFIED 下的 11 條沿用 scenario MUST NOT 要求新增 `test_realign_` 方法）、`tasks.md`（行為判準同步改為引用 IC6 並明列該排除）。
- finding 3：修改 `design.md`——IC4 第 4 點刪除「回傳 tuple」這個與同句 MUST NOT 衝突的例子，改為明寫 `load_or_import_touched()` 的公開簽章與回傳形狀 MUST NOT 改變（並記錄 `archive.py` 取值後直接當 dict 使用的三個位置作為理由），實作手段限於抽出內部 helper 或由 `ensure_touched()` 自行再呼叫一次 `_realign_touched_attribution()`。
- finding 4：修改 `tasks.md`——任務 1.4 的判準改為「1.1 與 1.2 的每條字面值判準」，並註明 1.3 交付的檔案沒有 `.agents` 對應檔、IC7 也只指名兩個 `SKILL.md`。

**非 blocking finding 的處置**

- finding 5：triage note——本輪一併修復。修改 `specs/cash-cli/spec.md`，在兩條沿用 scenario 各補一條 `- **AND** …因此 task attribution 對齊不改變任何內容` 的前提行，使其與限縮後的散文不再互斥；標題與其餘行維持逐字沿用以保住合併身分。
- finding 6：triage note——本輪一併修復。修改 `specs/cash-cli/spec.md` 的 ADDED 散文，補「對齊 MUST NOT 改動任何條目的 `files`」與「對齊未改變任何內容時 `touched ensure` MUST NOT 寫入」兩條規則，使散文不弱於其 scenario。
- finding 7：triage note——本輪一併修復。修改 `design.md`（IC3 第 1 點補「步驟 2 內文縮排為 3 空格，插入時 MUST 沿用，MUST NOT 拉齊到 column 0」）、`tasks.md`（任務 1.2 正向判準新增含 3 空格前導的 `'   If ensure fails with `touched_invalid` naming'`，並加註說明少了它把該段拉齊到 column 0 仍可通過全部字面值判準）。
- finding 8：triage note——本輪一併修復。修改 `design.md` IC1 第 1 點散文，改為「相對 fence 為 3 空格，巢狀選項行相對 fence 為 5 空格；對應原始檔中的 6 空格與 8 空格」，與 fence 實際內容一致。
- finding 9：triage note——本輪一併修復。修改 `specs/cash-skill-workflows/spec.md`（把 `cash-commit` 的義務與其 scenario 拆為獨立的 `### Requirement: cash-commit 對 touched_invalid 的復原指引`，並各自帶自己的變體對等 scenario；原 `cash-archive` requirement 的對等 scenario 收回只比較 `cash-archive` 兩變體）、`design.md`（IC9 改為「含兩個 `## ADDED Requirements` 條目」並說明拆分理由）、`proposal.md`（`## Capabilities` 的 `cash-skill-workflows` 說明改為兩條 requirement）。

**post-fix mechanical self-check 結果**

- comment/annotation lint：兩份 delta 的 `<!--`／`-->` 皆為 `0`，無 stray `---`。
- count-consistency：`tasks.md` 的「依 IC4 六點施作」與 `design.md` IC4 實際條目數（`6`）相符；`proposal.md` 宣稱 `cash-skill-workflows` 兩條 requirement 與該 delta 實際條目數（`2`）相符；`design.md` 宣稱 MODIFIED 沿用 11 條 scenario 與該區塊實際數（`11`）相符。
- identifier cross-grep：本輪新引入的 `cash-commit 對 touched_invalid 的復原指引` 在 delta、design、proposal 三處拼寫一致；IC1–IC10 與 D1–D11 無空洞、無 dangling 引用。
- spec delta title-identity：`## MODIFIED Requirements` 下的 `### Requirement: touched record 記錄 review loop 產出` 與 master spec 逐位元相符；無 `## REMOVED` 或 `## RENAMED` 條目。
- signal-derived checks：`openspec/signals/` 下無任何帶 `check` frontmatter 欄位的 signal，全部落入 best-effort 判斷分支，無 `範圍外 check 失敗` 與 fallback 紀錄。
- self-check 未在本輪 fix actions 後抓到新的失敗。

**fix 後的重新驗證**

- `.cash-skills/bin/cash validate guard-task-state-integrity` 通過。
- `tasks.md` 中 22 條可直接執行的 `rg` 判準對現行（實作前）工作樹逐條執行，極性全部符合所屬區塊的宣告，`0` 筆不符。
- 兩條 fish count 判準（現皆屬正向判準）以 fish 實測，實作前皆乾淨回傳 exit 1。
- 新增的含 3 空格前導判準 `'   If ensure fails with `touched_invalid` naming'` 實測實作前 exit 1，具鑑別力。

**本輪 Fix Actions 修改的檔案（`openspec/changes/` 之外）**

- 無。本輪全部修改都落在 `openspec/changes/guard-task-state-integrity/` 之下，濾除該前綴後候選集合為空，因此不呼叫 `"$cash_cli" touched ensure` 與 `"$cash_cli" touched record`，亦不產生警告。

無 `未修復：裁判面保護` 紀錄；本輪未修改任何裁判面保護路徑下的檔案。

## Decision

next_round
