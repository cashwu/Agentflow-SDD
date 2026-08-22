# Cash Apply Review — Round 3

## Reviewer Findings

### Critical

（無）

### Warning

1.
- `severity`: Warning
- `confidence`: 80
- `layer`: design
- `location`: `tasks.md` task 1.1 正向判準的 `**Template selection**` 那一條；對照 `design.md` IC1 第 8 點
- `summary`: IC1 第 8 點把「規則必須放在 bullet list 之外、於清單下方另起一段」明訂為規範（逐字寫著「位置是規範的一部分」），但 round 2 合併後的唯一判準是無錨點的子字串比對——把整段原樣改寫成 `- **Template selection**: …` 塞回欄位清單內，該判準仍然 exit 0，對這次修復真正要防的失敗模式零鑑別力；同時 round 2 移除的舊 bullet 形式 `- Include the skipped warning line …` 沒有對應的回歸守則。
- `recommendation`: 補一條錨定行首與內文縮排的判準（`^   \*\*Template selection\*\*: use the`），加註說明兩條必須一併成立；並在回歸守則區塊補一條 `- Include the skipped warning line` 的守則。
- `disposition`: `fix-introduced`
- `introduced_by`: round 2 `## Fix Actions`「非 blocking finding 的處置」finding 5 條目——該條同時改寫 `design.md` IC1 第 8 點使位置成為規範，又把「1.1 的兩條正向判準合併為一條釘住新的單行形式」，合併後的單條判準未涵蓋新引入的位置義務。
- reviewer source: Reviewer V — Verification
- 主 agent 獨立複核：`rg -q -- '^   \*\*Template selection\*\*: use the'` 在兩個 archive 變體上皆 rc `0`，證實錨定判準可行且現行實作已滿足位置義務；缺的是把該義務寫成判準。finding 成立。

### Suggestion

2.
- `severity`: Suggestion
- `confidence`: 70
- `layer`: design
- `location`: `tasks.md` task 1.1 的 `段落級判準`、`回歸守則` 與其後的 `註` 三段
- `summary`: round 2 把新的 `回歸守則` 區塊插在 `段落級判準` 與其解釋性 `註` 之間，使該 `註` 開頭的「此判準」在字面上指向緊鄰上方的回歸守則，而其內容（`AskUserQuestion` 段落檢查、「不發問」的鑑別力）明顯是為段落級判準而寫；1.2 的同類註就緊接其段落級判準，可見原意如此。
- `recommendation`: 把 `回歸守則` 區塊移到該 `註` 之後，讓 `註` 重新緊鄰它所解釋的段落級判準。
- `disposition`: `fix-introduced`
- `introduced_by`: round 2 `## Fix Actions`「blocking finding 的修復」finding 2 條目——「移出『負向判準』區塊，另立『回歸守則』」，新區塊被置於 `段落級判準` 與 `註` 之間。
- reviewer source: Reviewer V — Verification
- 過濾紀錄：Reviewer V 原標 `layer: text`。主 agent 依 confidence filter 逐條重檢 `text` finding，判定該 `註` 是對判準構成方式的規範性敘述（`不得改用 ask|prompt|confirm 的正則作為此判準`），指錯對象會導致後續維護者放寬錯誤的判準，屬可影響 design statement 的情形，故重新分類為 `layer: design`。`confidence: 70` ∈ `[50, 80)`，維持 `Suggestion`，非 blocking。

## Rating

- post-filter cumulative blocking set Critical count: `0`
- post-filter cumulative blocking set Warning count: `1`
- 非 blocking 的 triaged finding 數：`1`
- `critical_gap`: `false`
- `round_type`: `micro`

rationale：Reviewer V 對 round 2 cumulative blocking set 的四名成員 M1、M2、M3、M4 全部給出 `resolved` 判定並附驗證證據，四者依「verified resolution」離開 cumulative blocking set，該集合因此清空。但本輪新增一筆 `disposition: fix-introduced` 的 `Warning`（`confidence: 80` ≥ 80，通過 confidence filter），依規則 `fix-introduced` 為 blocking disposition，故進入 cumulative blocking set，本輪不能 pass。無 blocking `Critical`，`critical_gap` 為 `false`。第二筆為 `Suggestion`，非 blocking。本輪為本 run 第三輪，非第四輪，故 `round_type` 為 `micro`。

## Fix Actions

**cumulative blocking set 的 verified resolution 移除紀錄**

- M1（1.1 交付描述與 IC1 第 9 點矛盾）：移除。fix reference — round 2 `## Fix Actions` finding 1 條目；verifying reviewer — Reviewer V，證據為該句現與 IC1 第 9 點及 D5 逐字一致，原矛盾句已不存在。
- M2（負向判準在 baseline 即 exit 1）：移除。fix reference — round 2 `## Fix Actions` finding 2 條目；verifying reviewer — Reviewer V，證據為該判準已移入 `回歸守則` 區塊，並以 `git show HEAD:` 重建的 baseline 樹實測極性誠實，全樹 111 次判準執行中無第二處極性錯標。
- M3（touched 紀錄位置式 id 錯位）：移除。fix reference — round 2 `## Fix Actions` finding 3 條目；verifying reviewer — Reviewer V，證據為 `cash instructions apply --json` 的 `tasks[].id`／`description` 與 touched JSON 六筆 record 逐筆相同，`cash touched ensure` rc `0` 且未改寫檔案（代表 shape、per-task canonical 排序與 `files` 聯集三項驗證全過），聯集 13 條未縮減。
- M4（`implementation-notes.md` 未回填）：移除。fix reference — round 2 `## Fix Actions` finding 4 條目，加上本輪前追加的第五筆條目；verifying reviewer — Reviewer V，證據為第三筆已回填說明前兩筆被吸收為 IC6／task 1.0／`## Impact`，第四筆 `open-question` 之後緊接第五筆記錄使用者裁決並明寫關閉，依 Implementation Notes Protocol 為合法的解決紀錄，該 `open-question` 不再阻擋。

**使用者裁決紀錄**

- 本輪 reviewer 派工前，主 agent 就 `tasks.md` 的 `- [x]` 語意徵詢使用者並取得明確裁決：`- [x]` 代表「該 task 的交付目標已達成且其判準通過」，不宣稱執行順序。依此在 `implementation-notes.md` 追加第五筆 `deviation` 條目關閉第四筆 `open-question`；task 1.0 內文的順序要求對後續執行仍然有效。此為對 gate 輸入的合法補記，未修改任何既有條目。

**confidence filter 降級與丟棄紀錄**

- finding 1：`confidence: 80` ≥ 80，維持 `Warning`。
- finding 2：Reviewer V 原標 `layer: text`；主 agent 依「Re-check every `text` finding；若其修復可影響行為或 design statement 則重新分類為 `design`」重檢後改為 `layer: design`（理由見該 finding 的過濾紀錄）。`confidence: 70` ∈ `[50, 80)`，維持 `Suggestion`。
- 無 `confidence < 50` 的丟棄項；兩筆皆附可驗證的 `introduced_by`，無因缺乏證據而降至 `confidence ≤ 25` 的 finding。
- 無 disposition 更正：兩筆皆由 Reviewer V 標為 `fix-introduced`，主 agent 檢視 round 2 的 fix-touched 位置後確認標記正確。

**blocking finding 的修復**

- finding 1：修改 `tasks.md`——在 1.1 正向判準補一條 `rg -q -- '^   \*\*Template selection\*\*: use the' .claude/skills/cash-archive/SKILL.md`，把 IC1 第 8 點的位置義務（行首無 `- `、3 空格內文縮排）本身釘成判準；在該任務加一條 `註` 說明兩條 `**Template selection**` 判準 MUST 一併成立，並寫明字面值判準單獨為何不足；在 `回歸守則` 區塊補一條 `rg -Fq -- '- Include the skipped warning line' .claude/skills/cash-archive/SKILL.md`，其標題敘述同步改為「兩個字串都不存在於 HEAD baseline」。

**非 blocking finding 的處置**

- finding 2：triage note——本輪一併修復，因修復僅為 `tasks.md` 內的區塊順序調整，成本極低且可消除規範性 `註` 指錯對象的風險。修改 `tasks.md`——把 `回歸守則` 區塊移到 `註` 之後、`保留守則` 之前，使 `註` 重新緊鄰其所解釋的段落級判準，與 1.2 的排列方式一致。

**post-fix mechanical self-check 結果**

- comment/annotation lint：delta spec 的 `<!--` 與 `-->` 皆為 `0`。
- count-consistency：`tasks.md` 宣稱的「IC1 的九點」「IC2 的六點」與 `design.md` 實際條目數（`9`／`6`）相符。
- identifier cross-grep：本輪未新增或改名任何跨 artifact 識別字；`**Template selection**` 的兩個變體出現次數與 `design.md` 逐字規定一致。
- spec delta title-identity：本輪未改動 delta spec；`### Requirement: cash-commit 的 archive-first 允許清單` 與 master spec 仍逐位元相符。
- signal-derived checks：`openspec/signals/` 下無任何帶 `check` frontmatter 欄位的 signal，全部落入 best-effort 判斷分支，無 `範圍外 check 失敗` 與 fallback 紀錄。
- self-check 未在本輪 fix actions 後抓到新的失敗。

**fix 後的重新驗證**

- 現行工作樹：`tasks.md` 抽出的全部 `56` 條 `rg` 判準以宣告極性逐條執行，`0` 失敗。
- HEAD baseline 重建樹：全部 `54` 條有宣告前置極性的判準逐條執行，`0` 筆極性不符——新增的兩條判準（錨定位置的正向判準、`- Include the skipped warning line` 回歸守則）極性宣告誠實。
- `.cash-skills/bin/cash validate default-spec-sync-on-archive` 通過。
- 本輪 fix actions 未改動任何 `SKILL.md`、`.cash-skills/manifest.tsv`、`cash-skills.version` 或 `.cash-skills/lib/cash_cli/installer.py`，故不需重新生成 `.agents` 變體、不需重建 manifest，`./scripts/cash-skills/tests/skill-checks.fish` 的既有 exit `0` 結果不受影響。

**本輪 Fix Actions 修改的檔案（`openspec/changes/` 之外）**

- 無。本輪修改僅限 `openspec/changes/default-spec-sync-on-archive/tasks.md` 與 `implementation-notes.md`，濾除 `openspec/changes/` 下的路徑後候選集合為空，因此不呼叫 `"$cash_cli" touched ensure` 與 `"$cash_cli" touched record`，亦不產生警告。

無 `未修復：裁判面保護` 紀錄；本輪未修改任何裁判面保護路徑下的檔案。

## Decision

next_round
