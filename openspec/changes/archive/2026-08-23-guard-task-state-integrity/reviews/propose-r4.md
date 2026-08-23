# Cash Propose Review — Round 4

## Reviewer Findings

### Critical

（無）

### Warning

1.
- `severity`: Warning
- `confidence`: 100
- `layer`: design
- `location`: `tasks.md` 任務 0.1 判準區塊 ／ `design.md` `## Context` 相依段 ／ `design.md` `## Risks / Trade-offs` 第一項
- `summary`: 0.1 的乾淨工作樹閘門只檢查 5 個路徑，漏掉 `.claude/skills/cash-commit/SKILL.md` 與 `.agents/skills/cash-commit/SKILL.md`——這兩個檔同時落在 `default-spec-sync-on-archive` 的未提交工作樹修改與本變更的 `## Impact` 之中，閘門會在它們仍髒時通過，任務 1.2 隨即編輯同一份檔案，正是該閘門宣稱要防止的混合；同段「本變更修改同一組檔案中的四個」亦為錯誤計數（實際重疊為 7 個）。
- `recommendation`: 閘門補上兩條，並同步修正 `## Context` 與 `## Risks` 第一項的檔案清單與計數。
- `disposition`: `fix-introduced`
- `introduced_by`: round 1 `## Fix Actions`「finding 10」條目——該修復把兩個 `cash-commit` 路徑加入 `## Impact` 並新增任務，但未 propagate 到任務 0.1 的判準、`## Context` 的相依段與 `## Risks` 第一項。
- reviewer source: Reviewer A — Adherence 與 Reviewer B — Quality 獨立提出，依 `location + summary` 合併（兩者皆 `confidence: 100`、`layer: design`）
- 主 agent 複核：實測 `## Impact` 的 10 個路徑中 7 個現為 ` M`，其中含兩個 `cash-commit` 變體，而閘門只列 5 條。finding 成立。

2.
- `severity`: Warning
- `confidence`: 90
- `layer`: design
- `location`: `design.md` D8 與 `## Risks / Trade-offs` 第三項；IC2；`.claude/skills/cash-archive/SKILL.md` Guardrails 與步驟 5
- `summary`: D8 逐字宣告新失敗模式「在**兩個**會撞到它的 skill 都要有復原指引」並只列 `cash-commit` 與 `cash-apply`，但同一份 design 的 `## Risks` 第二項自己證明 `archive` 是第三個撞擊點，而 `cash-archive` 步驟 5 的失敗處置本輪已被任務 1.1 改寫、卻只加 `tasks_incomplete` 不加 `touched_invalid`；Guardrails 又逐字禁止直接刪除 touched state，使撞到該錯誤的使用者在該 skill 內既無指引、又被擋住唯一直覺的動作。`cash-apply` 的省略有理由（裁判面保護、不在 `## Impact`），`cash-archive` 兩者皆不成立。
- `recommendation`: IC2 增加 `touched_invalid` 的失敗處置，D8 的枚舉改為三個撞擊點，delta spec 補對應義務與 scenario。
- `disposition`: `fix-introduced`
- `introduced_by`: round 1 `## Fix Actions`「finding 10」條目——新建 D8 與 IC3 時把撞擊點枚舉定為兩個，未把同輪 `## Risks` 新增的 archive 撞擊點納入。
- reviewer source: Reviewer B — Quality
- 主 agent 複核：`.claude/skills/cash-archive/SKILL.md` Guardrails 逐字含 `Never delete touched or sync state directly`；D8 標題逐字為「兩個」。finding 成立。

### Suggestion

3.
- `severity`: Suggestion
- `confidence`: 100
- `layer`: design
- `location`: `design.md` IC1 第 2 點 ／ `tasks.md` 任務 1.1 段落級判準
- `summary`: IC1 第 2 點要求 `- Prompt user for confirmation to continue` 與 `- Proceed if user confirms` **兩行**都從步驟 3 消失，但只有後者有步驟 3 範圍的 awk 判準；把前者留在步驟 3 的實作可通過任務 1.1 的全部判準，而該殘留行會使 delta spec 的「MUST 恰有兩條互斥且窮盡的出路」在檔面上不成立。
- `recommendation`: 補一條與現有 `Proceed if user confirms` 對稱的段落級判準，並補一條步驟 2 的保留守則使 IC1 第 3 點也可機械比對。
- `disposition`: `new`
- reviewer source: Reviewer A — Adherence
- 佐證：Reviewer A 以 mutation test 證實——建立只違反 IC1 第 2 點的變異檔（步驟 3 保留該行），任務 1.1 的 14 條判準**全數通過**。
- 過濾紀錄：`disposition` 為 `new`，依規則「Every surviving `new` finding is non-blocking」，即使 `severity` 為 `Warning`、`confidence` 為 `100` 亦不 blocking。主 agent 依規則檢查該 finding 是否位於本 loop 的 fix-touched 位置——IC1 第 2 點與該段落級判準皆為 artifact 建立時的原始內容，非任何一輪 fix 所產生，故 `new` 標記正確，不更正為 `fix-introduced`。

4.
- `severity`: Suggestion
- `confidence`: 75
- `layer`: design
- `location`: `design.md` D6 與 D7；IC4 第 2 點；`specs/cash-cli/spec.md` ADDED requirement
- `summary`: D6 讓 legacy state 中「描述查無此項」的條目保留原樣，也就是保留其陳舊 `task_id`；該陳舊 id 可能與另一筆已對齊條目的新 id 相撞，而 D7 的唯一性檢查沒有 legacy 例外，於是以 `touched_invalid` 永久 fail closed——正是 D6 明文要避免的情形。附帶：D7 的重複 id 失敗訊息不需指名任何 `task_desc`，而 IC3 的復原指引逐字條件是 `naming a task_desc that no longer exists`，對這條失敗不適用。
- `recommendation`: 明訂 legacy 豁免條目與對齊結果相撞時的處置。
- `disposition`: `new`
- reviewer source: Reviewer B — Quality
- 過濾紀錄：原報 `Warning`／`75`，`confidence ∈ [50, 80)`，降為 `Suggestion`。

5.
- `severity`: Suggestion
- `confidence`: 72
- `layer`: design
- `location`: `design.md` D4 第三個 bullet；`.cash-skills/lib/cash_cli/commands/tasks.py` 的 `mark_task_done()`
- `summary`: `mark_task_done()` 是 `ensure_touched()` 的呼叫端，因此對齊落地會在 `task done` 中段先行 commit 一次獨立 transaction，接著 `mark_task_done()` 自己的 transaction 再整份覆寫；D4 只說「使用對齊後的值即可」，未認知該路徑上的修復性寫入是多餘的，也未說明 `task done` 因此由單一 commit 變成兩次。
- `recommendation`: 明訂是否抑制該寫入，或明寫接受雙 commit 並說明其原子性代價。
- `disposition`: `new`
- reviewer source: Reviewer B — Quality
- 過濾紀錄：原報 `Warning`／`72`，降為 `Suggestion`。

6.
- `severity`: Suggestion
- `confidence`: 70
- `layer`: design
- `location`: `proposal.md` `## Proposed Solution` 第 3 點
- `summary`: 第 3 點只寫 `.agents/skills/cash-archive/SKILL.md` 由重新生成產生，未含 `.agents/skills/cash-commit/SKILL.md`，而 `## Impact`、IC7 與任務 1.4 都涵蓋兩個變體。
- `recommendation`: 補上第二個變體。
- `disposition`: `fix-introduced`
- `introduced_by`: round 1 `## Fix Actions`「finding 10」條目——與 finding 1 同一根因。
- reviewer source: Reviewer A — Adherence

7.
- `severity`: Suggestion
- `confidence`: 65
- `layer`: design
- `location`: `tasks.md` 任務 1.1 註與任務 1.2 註
- `summary`: 兩處註都宣稱含前導空格的 `rg -F` 判準把縮排義務釘住，但 `rg -F` 是子字串比對，只能排除**少於** 3 空格的縮排；以 6 空格插入的變異檔實測通過任務 1.1 全部 14 條判準。該宣稱強於判準實際交付的保證。
- `recommendation`: 改為行首錨定形式，或把註的措辭下修。
- `disposition`: `fix-introduced`
- `introduced_by`: round 1 `## Fix Actions`「finding 9」與 round 2「finding 7」條目——兩者都以「縮排義務可機械比對／不失守」表述，未區分上下界。
- reviewer source: Reviewer A — Adherence

8.
- `severity`: Suggestion
- `confidence`: 60
- `layer`: design
- `location`: `design.md` D7 ／ `specs/cash-cli/spec.md` `## MODIFIED Requirements` 的兩條沿用 scenario
- `summary`: 存在「全部 `task_desc` 都一致、但陣列未依 bytes 排序」的合法 state；D7 的重新排序是無條件的，這類 state 的對齊會改變內容並觸發修復性寫入，使兩條 scenario 於 round 2 補上的 GIVEN 不足以推出「因此對齊不改變任何內容」；同時 design 未定義「僅順序改變」是否算「對齊改變了內容」。
- `recommendation`: 明訂 `changed` flag 是否涵蓋僅重新排序，並把兩條 scenario 的 GIVEN 補為含 canonical 排序。
- `disposition`: `fix-introduced`
- `introduced_by`: round 2 `## Fix Actions`「finding 5」條目——補入的 GIVEN 只涵蓋 `task_desc` 一致。
- reviewer source: Reviewer B — Quality

9.
- `severity`: Suggestion
- `confidence`: 55
- `layer`: design
- `location`: `design.md` IC4 第 4 點末句 ／ `tasks.md` 任務 1.3 正向判準
- `summary`: IC4 把 helper 定義位置的義務理由寫為「使 awk 判準保有鑑別力」，但該判準比對 `_realign_touched_attribution(` 這個字面值，`def _realign_touched_attribution(` 這一行本身也會命中，而 IC4 從未規定該函式的定義位置；把它定義在兩個 `def` 之間即可在零呼叫下通過該判準。
- `recommendation`: 明訂 `_realign_touched_attribution()` MUST NOT 定義於該區間，或把判準改為只匹配呼叫形式。
- `disposition`: `fix-introduced`
- `introduced_by`: round 3 `## Fix Actions`「finding 4」條目——新增 helper 定義位置義務時，未檢查該 awk 判準會被 `def` 行自身滿足。
- reviewer source: Reviewer A — Adherence

10.
- `severity`: Suggestion
- `confidence`: 55
- `layer`: design
- `location`: `design.md` `## Context`「既有 master requirement 的約束」段
- `summary`: `Change 與 artifact lifecycle` 逐字含「`cash-commit` MUST在建立source allowlist前呼叫ensure，archive MUST在其transaction內執行相同ensure」。本變更讓 `touched ensure` 取得修復性寫入，而 D4 要求 `archive_change()` 不因對齊產生額外寫入，兩者之後不再是「相同 ensure」；design 對「為何不需要 MODIFIED」的理由未觸及這一句。
- `recommendation`: 補上對該句的解讀，或為該 requirement 補一筆 MODIFIED。
- `disposition`: `new`
- reviewer source: Reviewer B — Quality

11.
- `severity`: Suggestion
- `confidence`: 55
- `layer`: design
- `location`: `design.md` D5 與 IC4 第 2 點
- `summary`: D5 只處理「`tasks.md` 兩個路徑皆不存在」與「`_task_entries()` 拋 `task_id_invalid`」，但 symlink 的 `tasks.md` 會拋 `unsafe_path`、非 UTF-8 內容會拋 `invalid_encoding`、`tasks.md` 是目錄時讀取會失敗；這三種錯誤會從對齊路徑逸出，把原本完全不讀 `tasks.md` 的 `touched ensure` 與 `touched record` 轉為以新錯誤碼失敗。
- `recommendation`: 把捕捉範圍擴為「讀取或解析 `tasks.md` 的任何失敗」。
- `disposition`: `new`
- reviewer source: Reviewer B — Quality

12.
- `severity`: Suggestion
- `confidence`: 50
- `layer`: design
- `location`: `specs/cash-skill-workflows/spec.md` `#### Scenario: 旗標在執行層可見`
- `summary`: 該 scenario 斷言 cash-archive 的 command 範例「與 `cash-commit` archive-first 子流程的 command 範例對稱」，但兩者形狀本就不同（`cash-commit` 為單行括號可選式、IC2 指定的是新增一行具體形式），逐字驗證時會遇到「何謂對稱」的解釋爭議。
- `recommendation`: 改為可逐字驗證的陳述。
- `disposition`: `new`
- reviewer source: Reviewer A — Adherence

## Rating

- post-filter cumulative blocking set Critical count: `0`
- post-filter cumulative blocking set Warning count: `2`
- 非 blocking 的 triaged finding 數：`10`
- `critical_gap`: `false`
- `round_type`: `full`

rationale：本輪為本 run 第四輪，依位置規則為 full-round checkpoint，spawn 了 Reviewer A 與 Reviewer B 兩個 fresh sub-agent 並行審查。兩位 checkpoint reviewer 對 cumulative blocking set 唯一成員 M1 都給出 `resolved` 判定，無分歧，M1 依「verified resolution」離開該集合。Reviewer A 的驗證特別具說服力：依 IC4 六點寫出參考實作放進 `.cash-skills/lib/cash_cli/commands/tasks.py`（事後已還原、`git status` 確認乾淨），實測 flag 在對齊改變內容時確為 `True`、修復寫入確實發生，且以該實作跑完 `scripts/cash-cli/tests` 全部 145 個測試，**恰好 2 個失敗且與 IC5 清單相符**（第三筆因 D6 豁免而通過，正如 IC5 的括號註記），證明 IC4 可依原文實作、不外溢 `## Impact`，且 IC5 的既有測試清單完整且無多餘。本輪十二筆 finding 經 confidence filter 後有兩筆維持 `Warning` 且 `disposition` 為 `fix-introduced`，屬 blocking disposition，故進入 cumulative blocking set，本輪不能 pass。無 blocking `Critical`，`critical_gap` 為 `false`。其餘十筆非 blocking——其中 finding 3 雖為 `Warning`／`confidence: 100` 且有 mutation test 佐證，但 `disposition` 為 `new`，依規則不 blocking。

## Fix Actions

**cumulative blocking set 的 verified resolution 移除紀錄**

- M1（IC4 第 4 點的 always-false 選項）：移除。fix reference — round 3 `## Fix Actions`「blocking finding 的修復」finding 1 條目；verifying reviewers — Reviewer A 與 Reviewer B，兩者判定一致無分歧。Reviewer A 的證據為參考實作實測（flag 為 `True`、修復寫入發生、任務 1.3 全部判準在該實作上翻轉為預期極性）；Reviewer B 的證據為 IC4 第 4 點現含逐字 MUST NOT 與理由，且兩條相關判準在該 helper 佈局下保有鑑別力。

**confidence filter 降級與丟棄紀錄**

- finding 4 原報 `Warning`／`75`、finding 5 原報 `Warning`／`72`，兩者 `confidence ∈ [50, 80)`，依 confidence filter 降為 `Suggestion`。
- finding 3 原報 `Warning`／`100`，`confidence` 未降級，但 `disposition` 為 `new`，依「Every surviving `new` finding is non-blocking」不進入 cumulative blocking set。主 agent 依規則檢查其是否位於本 loop 的 fix-touched 位置——IC1 第 2 點與該段落級判準皆為 artifact 建立時的原始內容，`new` 標記正確，不更正為 `fix-introduced`。
- finding 6、7、8、9、10、11、12 原即為 `Suggestion`，維持。
- finding 1、2 的 `confidence` 皆 ≥ 80 且 `disposition` 為 `fix-introduced`，維持 `Warning` 並進入 cumulative blocking set。
- 無 `confidence < 50` 的丟棄項；無 `layer` 重分類（本輪兩位 reviewer 皆未標任何 `text` finding）。
- 合併紀錄：finding 1 由兩位 reviewer 獨立提出，依 `location + summary` 合併，兩者 `severity`、`confidence`、`layer` 完全一致，無分歧需裁決。

**blocking finding 的修復**

- finding 1：修改 `tasks.md`（任務 0.1 的判準由 5 條擴為 7 條，補入 `.claude/skills/cash-commit/SKILL.md` 與 `.agents/skills/cash-commit/SKILL.md`；交付敘述改為逐一列出七個路徑並明寫「少列任何一個，該路徑就會在仍髒的情況下被本變更的 task 編輯」）、`design.md`（`## Context` 相依段的檔案清單由 5 個改為 7 個、「同一組檔案中的四個」改為「本變更的 `## Impact` 涵蓋這七個路徑的全部」，並補一句要求閘門 MUST 涵蓋全部七個重疊路徑；`## Risks / Trade-offs` 第一項的檔案清單同步改為七個）。
- finding 2：修改 `design.md`（D8 標題由「兩個會撞到它的 skill」改為「本變更範圍內的每個撞擊點」，內文枚舉三個撞擊點並明訂 `cash-apply` 是範圍內唯一例外及其理由；IC2 新增第 4 點逐字指定 `cash-archive` 步驟 5 的 `touched_invalid` 復原指引，明寫該編輯不違反 Guardrails 的不得刪除規定，原第 4 點順延為第 5 點）、`specs/cash-skill-workflows/spec.md`（`cash-archive` requirement 補該義務散文與 `cash-archive 對 touched_invalid 也有復原指引` scenario）、`tasks.md`（任務 1.1 的交付敘述改為「依序增加 `tasks_incomplete` 與 `touched_invalid` 兩條失敗處置」，正向判準補兩條釘住新指引的字面值，段落級判準補一條步驟 5 範圍的 `touched_invalid` 檢查）。

**非 blocking finding 的處置**

- finding 3：triage note——本輪一併修復。雖 `disposition` 為 `new` 而不 blocking，但 Reviewer A 的 mutation test 直接證明違規實作可通過全部判準，屬本變更最關心的缺陷類別。修改 `tasks.md`，任務 1.1 段落級判準新增 `awk … | rg -Fq -- 'Prompt user for confirmation to continue'    → MUST exit 1`（步驟 3 範圍）與 `awk '/^2\. \*\*Check artifact completion status\*\*/,/^3\. \*\*Check task completion status\*\*/' … → MUST exit 0`（步驟 2 保留守則），使 IC1 第 2 點的兩行義務與第 3 點的「步驟 2 MUST NOT 改動」都可機械比對。
- finding 4：triage note——本輪一併修復。修改 `design.md`（D7 增訂 `legacy_import` 非 `None` 時重複 id MUST 放棄整次對齊並原樣回傳而非 fail closed，並說明理由；IC4 第 2 點寫入該分支）、`specs/cash-cli/spec.md`（ADDED 散文同步）。此處置同時解除了 IC3 復原指引對重複 id 失敗不適用的問題——該路徑不再產生失敗。
- finding 5：triage note——本輪一併修復。修改 `design.md` D4 第三個 bullet，明寫 `mark_task_done()` 路徑會由單一 commit 變為兩次、MUST NOT 為此新增抑制分支，並說明理由：對齊是冪等的修復，中斷所留下的「已對齊但 `tasks.md` 未標記完成」是合法且可重跑的狀態，而繞過 `ensure_touched()` 會製造第二條需各自維護的取值路徑。
- finding 6：triage note——本輪一併修復。修改 `proposal.md` `## Proposed Solution` 第 3 點，補上 `.agents/skills/cash-commit/SKILL.md`。
- finding 7：triage note——本輪一併修復。修改 `tasks.md`，把任務 1.1 與任務 1.2 的兩條縮排判準由 `rg -Fq` 加前導空格改為 `rg -q` 行首錨定（`'^   - Use the \*\*AskUserQuestion tool\*\* to ask:'` 與 `'^   If ensure fails with `touched_invalid` naming'`），並把兩處註改寫為說明「`-F` 是子字串比對，只能排除少於 3 空格的縮排，以 6 空格插入仍會命中」。
- finding 8：triage note——本輪一併修復。修改 `design.md`（IC4 第 2 點明訂 `changed` flag MUST 涵蓋僅重新排序的情形）、`specs/cash-cli/spec.md`（ADDED 散文同步；兩條沿用 scenario 的 GIVEN 補為「且該 state 的 `touched` 已為 canonical 排序」）。
- finding 9：triage note——本輪一併修復。修改 `design.md` IC4 第 4 點，增訂 `_realign_touched_attribution()` 本身 MUST 定義於 `load_or_import_touched()` 之前，並說明理由：若把該函式的 `def` 行放進 awk 區間，判準會被定義行自身滿足而失去鑑別力。
- finding 10：triage note——本輪一併修復。修改 `design.md` `## Context`，補上對「相同 ensure」該句的解讀——指的是同一個 import／建立語意而非兩處必然產生相同的寫入行為，且 `archive_change()` 隨即在同一 transaction 內刪除該 state，故對齊在 archive 側是否落地沒有可觀察差異。
- finding 11：triage note——本輪一併修復。修改 `design.md`（D5 的捕捉範圍由 `task_id_invalid` 擴為「讀取或解析 `tasks.md` 的任何失敗」並逐一列出四種情形；IC4 第 2 點同步）、`specs/cash-cli/spec.md`（ADDED 散文同步）。
- finding 12：triage note——本輪一併修復。修改 `specs/cash-skill-workflows/spec.md`，把該 scenario 的 `- **AND**` 改為可逐字驗證的陳述，並明記兩者呈現形式不同、對稱僅指旗標可見性。

**post-fix mechanical self-check 結果**

- comment/annotation lint：兩份 delta 的 `<!--`／`-->` 與 stray `---` 皆為 `0`。
- count-consistency：`tasks.md` 的「依 IC4 六點施作」與 `design.md` IC4 實際條目數（`6`）相符；`design.md` 三處「七個路徑」的敘述與 `tasks.md` 任務 0.1 的 7 條閘門判準、`## Impact` 中與 `default-spec-sync-on-archive` 重疊的 7 個路徑三者一致（以 `git status --porcelain` 實測確認該 7 個路徑現皆為 ` M`）。
- 空區塊掃描：全部具極性宣告的判準區塊皆非空。
- identifier cross-grep：本輪新引入的 `touched_invalid` 復原指引逐字內容在 design IC2、delta spec 與 tasks 判準三處一致；IC1–IC10、D1–D11 無空洞、無 dangling 引用。
- spec delta title-identity：`### Requirement: touched record 記錄 review loop 產出` 與 master spec 仍逐位元相符；無 `## REMOVED` 或 `## RENAMED` 條目。
- signal-derived checks：`openspec/signals/` 下無任何帶 `check` frontmatter 欄位的 signal，全部落入 best-effort 判斷分支，無 `範圍外 check 失敗` 與 fallback 紀錄。
- self-check 未在本輪 fix actions 後抓到新的失敗。

**fix 後的重新驗證**

- `.cash-skills/bin/cash validate guard-task-state-integrity` 通過。
- `tasks.md` 中 24 條可直接執行的 `rg` 判準對現行（實作前）工作樹逐條執行，極性全部符合所屬區塊的宣告，`0` 筆不符。
- 本輪新增的五條判準形式逐一實測實作前極性：步驟 3 `Prompt user for confirmation to continue` exit 0（實作後 MUST 1）、步驟 2 保留守則 exit 0（實作前後皆 0）、步驟 5 `touched_invalid` exit 1（實作後 MUST 0）、兩條行首錨定縮排判準 exit 1（實作後 MUST 0）——全部具鑑別力。
- 任務 0.1 的七條閘門判準以 `fish` 實測，`.claude/skills/cash-commit/SKILL.md` 該條正確回傳非零（該檔現為 ` M`），確認閘門會擋下。

**本輪 Fix Actions 修改的檔案（`openspec/changes/` 之外）**

- 無。本輪全部修改都落在 `openspec/changes/guard-task-state-integrity/` 之下，濾除該前綴後候選集合為空，因此不呼叫 `"$cash_cli" touched ensure` 與 `"$cash_cli" touched record`，亦不產生警告。

無 `未修復：裁判面保護` 紀錄；本輪未修改任何裁判面保護路徑下的檔案。Reviewer A 在驗證期間曾暫時寫入 `.cash-skills/lib/cash_cli/commands/tasks.py` 作為參考實作並已還原，`git status` 確認該檔乾淨；該檔在本變更的 `## Impact` 內，且該寫入是 reviewer 的驗證行為而非 fix action。

## Decision

next_round
