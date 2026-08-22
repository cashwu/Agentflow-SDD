# Cash Apply Review — Round 5

## Reviewer Findings

### Critical

（無）

### Warning

（無）

### Suggestion

1.
- `severity`: Suggestion
- `confidence`: 90
- `layer`: design
- `location`: `tasks.md` task 1.1 的 `註`
- `summary`: 同一段 `註` 內對「`**Template selection**` 位置義務由幾條判準承擔」給出互相矛盾的兩個數字——開頭的操作性句子寫「兩條正向判準 MUST 一併成立」，其後卻寫「該位置義務由三條判準共同承擔」並逐條列出三條；正向判準區塊實際有 3 條涉及 `**Template selection**`。
- `recommendation`: 把開頭句的「兩條」改為「三條」，使該 MUST 句與其後的枚舉、與實際條數一致。
- `disposition`: `fix-introduced`
- `introduced_by`: 本輪 F5 修復——F5 新增第三條（`rg -U` 相鄰性）判準並改寫該 `註` 的枚舉部分為「三條」，但未同步開頭那句自 round 3 沿用下來的「兩條正向判準 MUST 一併成立」。round 3 `## Fix Actions` finding 1 條目建立該句時判準確為兩條，F5 使其失效。
- reviewer source: Reviewer V — Verification
- 過濾紀錄：`severity` 為 `Suggestion`，`confidence: 90`。confidence filter 只在 `confidence < 80` 時把 `Critical`／`Warning` 降級，對本來就是 `Suggestion` 的 finding 不改變分級；因非 `Critical`／`Warning`，即使 `disposition` 為 `fix-introduced` 亦不 blocking。

## Rating

- post-filter cumulative blocking set Critical count: `0`
- post-filter cumulative blocking set Warning count: `0`
- 非 blocking 的 triaged finding 數：`1`
- `critical_gap`: `false`
- `round_type`: `micro`

rationale：本輪為使用者明確要求把 round 4 五筆非 blocking finding 中的三筆（apply-r4 findings 1、4、5，本輪代號 F1、F4、F5）在本 change 內修復後，對該批修復所做的 delta verification。round 4 已以 verified resolution 清空 cumulative blocking set，本輪進入時該集合為空，故無成員需給判定。Reviewer V 確認 F1、F4、F5 三者皆 `landed`，並以 mutation test 證實 F5 新增的 `rg -U` 相鄰性判準是「把 `**Template selection**` 段移到清單之前」這個失敗模式的唯一且真實的鑑別器（全部 62 條判準中恰好只有該條失敗）。本輪唯一 finding 為 `Suggestion`，未有任何 `Critical` 或 `Warning` 存活，無新成員進入 cumulative blocking set，pass 條件成立。

## Fix Actions

None; pass condition met.

**mechanical self-check 記錄**

- 本輪 Reviewer V 提出的唯一 finding 屬 count-consistency 類別（一份 artifact 對其自身判準條數的數值宣稱與實際條數不符），該類別由 pre-round mechanical self-check 擁有，不是 reviewer findings 的一部分，因此不影響本輪決定。主 agent 依 self-check 的修正義務就地修正：把 `tasks.md` task 1.1 `註` 開頭的「`**Template selection**` 的兩條正向判準 MUST 一併成立」改為「三條」，並把緊接的「字面值判準只證明」調整為「單靠字面值判準只證明」以維持語意連貫。修正後以程式重新比對該 `註` 中所有「N 條正向判準」宣稱與正向判準區塊內實際涉及 `**Template selection**` 的判準條數，兩者皆為 `3`，一致。
- 本輪三筆修復（F1、F4、F5）之後的 self-check 其餘項目：delta spec 的 `<!--`／`-->` 皆為 `0`；`design.md` IC1 共 9 點、IC2 共 6 點，與 `tasks.md` 宣稱的「九點」「六點」相符；新引入的 `or a `skipped` outcome` 在兩個 archive 變體各 `1`、`design.md` `1`、`tasks.md` `2`，被移除的 `- Note about any warnings (incomplete artifacts/tasks)` 在四個 `SKILL.md` 皆為 `0`；`### Requirement: cash-commit 的 archive-first 允許清單` 與 master spec 仍逐位元相符；`openspec/signals/` 下無任何帶 `check` frontmatter 欄位的 signal，全部落入 best-effort 判斷分支，無 `範圍外 check 失敗` 與 fallback 紀錄。

**Reviewer V 驗證彙總**

- F1 `landed`：`proposal.md` `## Proposed Solution` 第 2 點與 `tasks.md` 1.1 交付描述現皆與 IC1 第 6 點逐字一致；「preflight 失敗時的兩條出路」措辭僅殘存於 `reviews/apply-r4.md` 的歷史紀錄，屬正確保留。
- F4 `landed`：兩份 `cash-archive/SKILL.md` 步驟 6 最後一項已改為新外延，`design.md` IC1 第 8 點以逐字形式訂為 MUST，新增的正向與負向判準極性誠實（現行樹 exit 0／exit 1，HEAD baseline exit 1／exit 0），舊字面值在四個 `SKILL.md` 為 0 次命中，`manifest.tsv` 四筆 skill digest 與工作樹 `shasum -a 256` 逐筆相符。
- F5 `landed`：IC1 第 8 點新增「MUST 緊接在該 bullet list 的最後一項之後（中間只隔一個空行）」，相鄰性判準現行樹 exit 0、HEAD baseline exit 1，mutation test 下 62 條判準中恰好只有它失敗。
- 未破壞既有結論：IC1 第 2 點與 IC2 第 2 點的逐字 fenced 區塊仍與檔案 byte-for-byte 相符；D5 保護的 `**Output On Success With Warnings**` 的 `**Warnings:**` 清單仍為 3 行、順序不變、結尾句未動，另外三個 Output 模板與 Guardrails 未被觸及；模板可達性窮舉六格中五格可達且各有唯一模板與正確 `**Specs:**` 值——F4 反而消除了 `skipped` + 無其他 warning 那一格原本的雙外延歧義。
- 執行面：`./scripts/cash-skills/tests/skill-checks.fish` exit `0`；`.cash-skills/bin/cash validate default-spec-sync-on-archive` 通過；`cash touched ensure` rc `0` 且 touched JSON 的 md5 前後相同（未改寫）；`cash analyze` 無 `Critical`；`.claude` 與 `.agents` 兩對檔案 raw `diff` 只差 `**Input**` 行的 invocation 前綴，其餘全檔零差異。
- 版本三元組：三處皆 `2.14.0`，HEAD 為 `2.13.0`。本輪 F4 改動了 `SKILL.md` 位元，但 bundle version history contract 只要求「嚴格領先 HEAD」而非「每次編輯各自 bump」，`2.14.0 > 2.13.0` 仍成立，且 manifest 已於 F4 後重建；`PASS: bundle version history` 即為該推理的機械證據，不需額外 bump。

**本輪 Fix Actions 修改的檔案（`openspec/changes/` 之外）**

- 無。本輪唯一的修正（count-consistency）僅限 `openspec/changes/default-spec-sync-on-archive/tasks.md`，濾除 `openspec/changes/` 下的路徑後候選集合為空，因此不呼叫 `"$cash_cli" touched ensure` 與 `"$cash_cli" touched record`，亦不產生警告。

無 `未修復：裁判面保護` 紀錄；本 run 五輪皆未修改任何裁判面保護路徑下的檔案。

## Decision

passed
