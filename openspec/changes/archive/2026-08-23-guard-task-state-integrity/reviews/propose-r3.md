# Cash Propose Review — Round 3

## Reviewer Findings

### Critical

（無）

### Warning

1.
- `severity`: Warning
- `confidence`: 85
- `layer`: design
- `location`: `design.md` IC4 第 4 點
- `summary`: 第 4 點給出的第二個實作選項「由 `ensure_touched()` 自行再呼叫一次 `_realign_touched_attribution()` 取得 flag」必然得到 `False`——`ensure_touched()` 的值來自 `load_or_import_touched()`，而第 3 點已要求該路徑先行對齊，對已對齊的物件再跑一次不可能改變內容；依此選項實作會使 D4 要求的修復性寫入永遠不發生，卻仍通過 `tasks.md` 的全部字面值與計數判準。
- `recommendation`: 刪除該選項，只保留內部 helper 的手段；或明寫該路徑的對齊輸入為自行讀取的原始值。
- `disposition`: `fix-introduced`
- `introduced_by`: round 2 `## Fix Actions`「finding 3」條目——改寫 IC4 第 4 點時新增的兩個實作選項中，第二個未與第 3 點「`load_or_import_touched()` 回傳對齊後的物件」對照。
- reviewer source: Reviewer V — Verification

### Suggestion

2.
- `severity`: Suggestion
- `confidence`: 90
- `layer`: design
- `location`: `tasks.md` 任務 1.3「負向判準（實作前 exit 0，實作後 MUST exit 1）」
- `summary`: 唯一的負向判準被移到正向判準之後，該區塊只剩一個空的 code fence，成為宣告了極性卻沒有任何判準的空區塊。
- `recommendation`: 刪除該標題與空 fence，或改寫為真正屬於負向極性的形式。
- `disposition`: `fix-introduced`
- `introduced_by`: round 2 `## Fix Actions`「finding 1」條目（把該判準移出負向判準區塊後未移除空區塊）。
- reviewer source: Reviewer V — Verification

3.
- `severity`: Suggestion
- `confidence`: 80
- `layer`: design
- `location`: `tasks.md` 任務 1.3 的交付敘述段
- `summary`: 該段仍寫「依 IC6 為 `cash-cli` delta spec 的每條 scenario 新增一個 `test_realign_` 前綴的測試方法」，未帶 `## ADDED Requirements` 的限縮，與同一 task 下方已修好的行為判準以及限縮後的 IC6 不一致。
- `recommendation`: 補上 `## ADDED Requirements` 的限縮。
- `disposition`: `unresolved-prior`
- reviewer source: Reviewer V — Verification
- 備註：M2 指名的兩處（IC6、行為判準）都已修好故 M2 判 `resolved`；此為同一概念未 propagate 到的第三處。依規則，`unresolved-prior` 是 blocking disposition，但本 finding 經 confidence filter 後為 `Suggestion`，而 blocking 判定只適用於 `Critical` 與 `Warning`，故非 blocking。

4.
- `severity`: Suggestion
- `confidence`: 65
- `layer`: design
- `location`: `design.md` IC4 第 4 點 ／ `tasks.md` 任務 1.3 正向判準
- `summary`: `awk '/^def load_or_import_touched/,/^def ensure_touched/' … | rg -Fq -- '_realign_touched_attribution('` 要求該字面呼叫出現在兩個 `def` 之間；但 IC4 第 4 點允許的「抽出內部 helper」選項會使 `load_or_import_touched()` 只呼叫該 helper，判準是否成立取決於 helper 恰好被定義在這兩個 `def` 之間這個未被規定的排版。
- `recommendation`: 在 IC4 第 4 點規定 helper 的定義位置，或把判準改為取聯集的形式。
- `disposition`: `fix-introduced`
- `introduced_by`: round 2 `## Fix Actions`「finding 3」條目（新增「抽出內部 helper」選項）與 round 1「finding 6」條目（新增該 awk 判準）之間未互相對照。
- reviewer source: Reviewer V — Verification

5.
- `severity`: Suggestion
- `confidence`: 60
- `layer`: design
- `location`: `design.md` IC1 第 1 點散文的括號
- `summary`: 「對應原始檔中的 6 空格與 8 空格」語意含混——6／8 是 `design.md` 原始位元組中的絕對縮排，但字面可被讀成目標檔 `.claude/skills/cash-archive/SKILL.md`，而該檔步驟 3 內文實測為 3 空格；照後一種讀法插入會以 6 空格落地，而 `rg -F` 的 3 空格前綴判準因子字串比對仍會命中，無法攔截。
- `recommendation`: 明確區分兩個檔案各自的縮排數字。
- `disposition`: `fix-introduced`
- `introduced_by`: round 2 `## Fix Actions`「finding 8」條目（改寫 IC1 第 1 點散文的縮排數字時新增此括號子句）。
- reviewer source: Reviewer V — Verification
- 過濾紀錄：Reviewer V 原標 `layer: text`。主 agent 依 confidence filter 逐條重檢 `text` finding——該歧義可導致實作者以 6 空格落地而判準攔不住，屬可影響交付行為的情形，故重新分類為 `layer: design`。`severity` 維持 `Suggestion`。

## Rating

- post-filter cumulative blocking set Critical count: `0`
- post-filter cumulative blocking set Warning count: `1`
- 非 blocking 的 triaged finding 數：`4`
- `critical_gap`: `false`
- `round_type`: `micro`

rationale：Reviewer V 對 round 2 cumulative blocking set 的四名成員 M1–M4 全部給出 `resolved` 判定並附驗證證據（含以 `fish` 實測搬移後的計數判準極性、實檔核對 `archive.py` 三處 dict 用法、逐位元確認 MODIFIED 標題與 11 條 scenario 標題集合），四者依「verified resolution」離開 cumulative blocking set。本輪新增五筆 finding，經 confidence filter 後僅一筆維持 `Warning`（`confidence: 85` ≥ 80）且 `disposition` 為 `fix-introduced`，屬 blocking disposition，故進入 cumulative blocking set，本輪不能 pass。其餘四筆為 `Suggestion`——其中 finding 3 的 `disposition` 雖為 `unresolved-prior`，但 blocking 判定只適用於 `Critical` 與 `Warning`，故非 blocking。無 blocking `Critical`，`critical_gap` 為 `false`。本輪為本 run 第三輪，非第四輪，故 `round_type` 為 `micro`。

## Fix Actions

**cumulative blocking set 的 verified resolution 移除紀錄**

- M1（計數判準極性）：移除。fix reference — round 2 `## Fix Actions` finding 1；verifying reviewer — Reviewer V，以 `fish` 實測該判準現位於正向區塊且對現行工作樹回傳 exit 1。
- M2（IC6 範圍）：移除。fix reference — round 2 finding 2；verifying reviewer — Reviewer V，確認 IC6 已限縮且 ADDED 11 條／MODIFIED 11 條與陳述相符。
- M3（IC4 第 4 點自相矛盾）：移除。fix reference — round 2 finding 3；verifying reviewer — Reviewer V，實檔核對 `archive.py` 的三處 dict 用法屬實，且 IC4 第 2 點的 tuple 簽章與第 3 點不衝突。
- M4（1.4 判準引用 1.3）：移除。fix reference — round 2 finding 4；verifying reviewer — Reviewer V，確認已改為「1.1 與 1.2」且與 IC7 一致。

**confidence filter 降級與丟棄紀錄**

- finding 1 `confidence: 85` ≥ 80，維持 `Warning`。
- finding 2、3、4、5 原即為 `Suggestion`（`90`／`80`／`65`／`60`），維持。
- 無 `confidence < 50` 的丟棄項。
- `layer` 重檢：finding 5 由 Reviewer V 標為 `text`，主 agent 判定該歧義可導致實作以錯誤縮排落地且判準攔不住，重新分類為 `design`。未做任何 `design` → `text` 的重分類。
- disposition 檢查：finding 3 由 Reviewer V 標為 `unresolved-prior`，主 agent 確認該措辭確為 M2 同一概念未 propagate 到的第三處，標記正確；其餘四筆的 `fix-introduced` 標記經對照 round 1／round 2 的 fix-touched 位置後確認正確。

**blocking finding 的修復**

- finding 1：修改 `design.md`——IC4 第 4 點刪除該選項，改為 MUST 抽出一個回傳 `tuple[dict[str, object], bool]` 的內部 helper 供兩個函式各自取用（前者只取第一元素維持公開形狀，後者取 flag 決定是否寫回），並新增一段明寫 MUST NOT 改為「由 `ensure_touched()` 自行再呼叫一次」及其理由——對已對齊的物件再跑一次必然回報未改變，修復性寫入將永遠不發生，而該實作仍能通過全部判準。

**非 blocking finding 的處置**

- finding 2：triage note——本輪一併修復。修改 `tasks.md`，刪除任務 1.3 中只剩空 fence 的「負向判準」標題與該 fence。
- finding 3：triage note——本輪一併修復。修改 `tasks.md`，任務 1.3 的交付敘述段補上 `## ADDED Requirements` 的限縮並註明 MODIFIED 下的 11 條不在義務範圍內。
- finding 4：triage note——本輪一併修復，與 finding 1 同一處。IC4 第 4 點新增「該 helper MUST 定義於 `load_or_import_touched()` 與 `ensure_touched()` 兩個 `def` 之間」，使 tasks 中以該區間為範圍的 awk 判準對「對齊確實被接上讀取路徑」保有鑑別力。
- finding 5：triage note——本輪一併修復。修改 `design.md` IC1 第 1 點散文，把括號改為「對應 `design.md` 原始位元組中的 6 空格與 8 空格，插入 `.claude/skills/cash-archive/SKILL.md` 後為 3 空格與 5 空格」，明確區分兩個檔案各自的縮排數字。

**post-fix mechanical self-check 結果**

- comment/annotation lint：兩份 delta 的 `<!--`／`-->` 與 stray `---` 皆為 `0`。
- count-consistency：`tasks.md` 的「依 IC4 六點施作」與 `design.md` IC4 實際條目數（`6`）相符；IC1–IC10 依序無空洞，`tasks.md` 引用的 IC1–IC8 全部存在。
- 空區塊掃描：以程式列舉全部具極性宣告的判準區塊，確認修復後無任何空 fence 區塊（本輪 finding 2 即此類，已修）。
- identifier cross-grep：本輪新引入的 helper 定義位置義務在 design 與 tasks 的敘述一致；無新增識別字。
- spec delta title-identity：本輪未改動 delta spec；`### Requirement: touched record 記錄 review loop 產出` 與 master spec 仍逐位元相符。
- signal-derived checks：`openspec/signals/` 下無任何帶 `check` frontmatter 欄位的 signal，全部落入 best-effort 判斷分支，無 `範圍外 check 失敗` 與 fallback 紀錄。
- self-check 未在本輪 fix actions 後抓到新的失敗。

**fix 後的重新驗證**

- `.cash-skills/bin/cash validate guard-task-state-integrity` 通過。
- `tasks.md` 中 22 條可直接執行的 `rg` 判準對現行（實作前）工作樹逐條執行，極性全部符合所屬區塊的宣告，`0` 筆不符。
- 空區塊掃描結果為 `none`。

**本輪 Fix Actions 修改的檔案（`openspec/changes/` 之外）**

- 無。本輪全部修改都落在 `openspec/changes/guard-task-state-integrity/` 之下，濾除該前綴後候選集合為空，因此不呼叫 `"$cash_cli" touched ensure` 與 `"$cash_cli" touched record`，亦不產生警告。

無 `未修復：裁判面保護` 紀錄；本輪未修改任何裁判面保護路徑下的檔案。

## Decision

next_round
