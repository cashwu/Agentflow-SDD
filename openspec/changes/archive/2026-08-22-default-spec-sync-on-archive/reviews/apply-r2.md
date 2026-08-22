# Cash Apply Review — Round 2

## Reviewer Findings

### Critical

（無）

### Warning

1.
- `severity`: Warning
- `confidence`: 95
- `layer`: design
- `location`: `tasks.md` task 1.1 的交付描述散文
- `summary`: 1.1 的交付描述仍寫「warnings 模板的 `**Specs:**` 行與跳過警告行改為依判定結果填值的佔位形式」，但 round 1 已把 IC1 第 9 點與 D5 改成「跳過警告行維持純輸出文字，條件性由步驟 6 的規則承載」，兩者直接矛盾。
- `recommendation`: 把該句改寫為與 IC1 第 9 點一致的敘述。
- `disposition`: `fix-introduced`
- `introduced_by`: round 1 `## Fix Actions`「非 blocking finding 的處置」finding 5 條目——該條對 `tasks.md` 只列出「1.1 的正向判準改為兩條，並新增一條負向判準」，未涵蓋 1.1 的交付描述散文。
- reviewer source: Reviewer V — Verification

2.
- `severity`: Warning
- `confidence`: 90
- `layer`: design
- `location`: `tasks.md` task 1.1「負向判準（實作前 exit 0，實作後 MUST exit 1）」區塊
- `summary`: round 1 新增的 `rg -Fq -- '— include only when the outcome is `skipped`'` 在 HEAD baseline 就已 exit 1，不符合所屬區塊宣告的「實作前 exit 0」極性，對 baseline 零鑑別力。
- `recommendation`: 移出負向判準區塊，另立回歸守則並註明其守的是 review round 中間態措辭不得回歸。
- `disposition`: `fix-introduced`
- `introduced_by`: round 1 `## Fix Actions` finding 5 條目「新增一條負向判準釘住舊夾帶措辭必須消失」——該「舊措辭」是 round 1 自己在同一輪修復前的中間態產物，並非 baseline 內容。
- reviewer source: Reviewer V — Verification
- 主 agent 獨立複核：`git show HEAD:.claude/skills/cash-archive/SKILL.md | rg -c -F -- '— include only when the outcome is `skipped`'` 回傳 rc `1`（計數 `0`）。finding 成立。

3.
- `severity`: Warning
- `confidence`: 85
- `layer`: design
- `location`: `tasks.md` 新增的 `1.0` 對上 `.cash-skills/state/touched/default-spec-sync-on-archive.json`
- `summary`: Cash CLI 的 task id 是位置式，插入 `1.0` 使全部 id 位移一位；已持久化的 touched 紀錄仍是舊對應（`task_id: "1"` ↔ `task_desc: "1.1 …"`），位置 6（`2.2`）無紀錄，且 bump 三檔仍掛在 desc 為 `2.1 執行 skill 套件檢查` 的 record 下。
- `recommendation`: 重建該 change 的 touched 紀錄使位置式 id 與現行 6 條 task 對齊，並把 bump 三檔改記在 `1.0` 名下。
- `disposition`: `fix-introduced`
- `introduced_by`: round 1 `## Fix Actions`「blocking finding 的修復」finding 3 條目「新增排在 1.1 之前的 `1.0 依 IC6 調升 bundle version`」——該條只改 artifact，未同步 Cash 側狀態。
- reviewer source: Reviewer V — Verification
- 主 agent 獨立複核：`.cash-skills/lib/cash_cli/commands/tasks.py` 的 `_task_entries()` 以 `str(len(entries) + 1)` 產生 id，確為位置式；`cash instructions apply --json` 現回報 `'1' | '1.0 依 IC6 調升 bundle version'`，而 JSON 中 `task_id: "1"` 的 `task_desc` 仍為 `1.1 …`。finding 成立。影響範圍：`files` 聯集完整，故 archive-first 提交集合不受污染；受影響的是 per-task 歸屬顯示與後續 `cash task done` 的 record 比對。

4.
- `severity`: Warning
- `confidence`: 80
- `layer`: design
- `location`: `implementation-notes.md` 前兩筆 `deviation` 條目；對照 `tasks.md` task `1.0`
- `summary`: 兩筆 `deviation` 未回填：仍記「任務：2.1」，理由逐字寫著「`design.md` 的 IC1–IC3 與 `tasks.md` 只宣告修改四個 `SKILL.md`」，該前提已被 round 1 新增的 IC6、task 1.0 與 `## Impact` 三路徑推翻；同時 task 1.0 標為 `[x]` 且載明「MUST 排在 1.1 之前執行」，與紀錄中 bump 實際發生在 2.1 驗證失敗之後的事實相反。
- `recommendation`: 追加回填條目說明該 deviation 已被吸收為 IC6 與 task 1.0，並註明本次執行中 bump 的實際發生時點。
- `disposition`: `fix-introduced`
- `introduced_by`: round 1 `## Fix Actions` finding 2 與 finding 3 條目——兩者新增 IC6／`## Impact` 三路徑與 task `1.0`，但「本輪 Fix Actions 修改的檔案」清單與各條修復描述均未包含 `implementation-notes.md`。
- reviewer source: Reviewer V — Verification

### Suggestion

5.
- `severity`: Suggestion
- `confidence`: 50
- `layer`: design
- `location`: `.claude/skills/cash-archive/SKILL.md` 步驟 6 `Show archive completion summary including:` 清單（`.agents` 同）
- `summary`: 該清單其餘項目都是「要顯示的欄位」，round 1 為承載條件性而在其中插入兩條撰寫指示，把 round 1 finding 5 想避免的「指示與輸出混雜」從模板 fence 內搬到了摘要欄位清單內。
- `recommendation`: 把兩條規則移到清單之外，改置於清單下方另起的 `**Template selection**` 段；`design.md` IC1 第 8 點同步調整。
- `disposition`: `fix-introduced`
- `introduced_by`: round 1 `## Fix Actions` finding 5 條目對 `design.md` IC1 第 8 點的改寫（「緊接其後 MUST 加入兩條」）。round 1 曾以 `confidence: 40` 丟棄同類 finding，此處為 fix 使問題由一條增為兩條的新證據。
- reviewer source: Reviewer V — Verification
- 過濾紀錄：`confidence: 50` ∈ `[50, 80)`，維持 `Suggestion`；因非 `Critical`／`Warning`，即使 `disposition` 為 `fix-introduced` 亦不 blocking。

## Rating

- post-filter cumulative blocking set Critical count: `0`
- post-filter cumulative blocking set Warning count: `4`
- 非 blocking 的 triaged finding 數：`1`
- `critical_gap`: `false`
- `round_type`: `micro`

rationale：Reviewer V 對 round 1 cumulative blocking set 的三名成員 M1、M2、M3 全部給出 `resolved` 判定並附修復位置的驗證證據，三者依「verified resolution」離開 cumulative blocking set。但本輪新增四筆 `disposition: fix-introduced` 的 `Warning`，全部通過 confidence filter（`95`／`90`／`85`／`80`，皆 ≥ 80），依規則 `fix-introduced` 為 blocking disposition，因此四者進入 cumulative blocking set，本輪不能 pass。無 blocking `Critical`，`critical_gap` 為 `false`。第五筆為 `Suggestion`，非 blocking，以 triage 處理。本輪為本 run 第二輪，非第四輪，故 `round_type` 為 `micro`。

## Fix Actions

**cumulative blocking set 的 verified resolution 移除紀錄**

- M1（IC1 第 6 點的無效出路）：移除。fix reference — round 1 `## Fix Actions` finding 1 條目；verifying reviewer — Reviewer V，證據為步驟 5 現為兩段獨立處置且各自明寫 `` `--skip-specs` does NOT bypass ``，與 `.cash-skills/lib/cash_cli/commands/archive.py` 的呼叫順序一致。
- M2（三個 bump 檔案未納入宣告範圍）：移除。fix reference — round 1 `## Fix Actions` finding 2 條目；verifying reviewer — Reviewer V，證據為 `## Impact` `Modified:` 已含三路徑、`## Proposed Solution` 第 7 點與 `**IC6 — bundle version bump**` 均存在且排在 IC5 之後。
- M3（bump 未排入 task 且序位錯誤）：移除。fix reference — round 1 `## Fix Actions` finding 3 條目；verifying reviewer — Reviewer V，證據為 `tasks.md` 已有排在 1.1 之前的 `- [x] 1.0`、三條判準實測 exit 0、1.3 相依已更新、D7 已補上前置條件敘述。

**confidence filter 降級與丟棄紀錄**

- 本輪五筆 finding 中，四筆 `Warning` 的 `confidence` 分別為 `95`／`90`／`85`／`80`，皆 ≥ 80，維持 `Critical`／`Warning` 分級。
- 第五筆原即為 `Suggestion`，`confidence: 50` ∈ `[50, 80)`，維持 `Suggestion`，未丟棄。
- 無 `confidence < 50` 的丟棄項。
- 五筆 finding 皆附可驗證的 `introduced_by`，無因缺乏 `introduced_by` 證據而降至 `confidence ≤ 25` 的 finding。
- 無 disposition 更正：五筆皆由 Reviewer V 標為 `fix-introduced`，主 agent 逐筆檢視 round 1 的 fix-touched 位置後確認標記正確，無 `new` 需更正為 `fix-introduced` 的情形。

**blocking finding 的修復**

- finding 1：修改 `tasks.md`——task 1.1 的交付描述改為「`**Specs:**` 行改為依判定結果填值的佔位形式，跳過警告行改為 `- Delta spec sync was skipped (explicitly requested by the user)` 並維持純輸出文字，其條件性由步驟 6 清單下方的 `**Template selection**` 段承載」。
- finding 2：修改 `tasks.md`——把 `rg -Fq -- '— include only when the outcome is `skipped`'` 移出「負向判準」區塊，另立「回歸守則（實作前後皆 MUST exit 1；此字串不存在於 HEAD baseline，故非負向判準，其作用是防止 review round 中曾短暫出現的夾帶措辭回歸）」。
- finding 3：修改 `.cash-skills/state/touched/default-spec-sync-on-archive.json`——依 `cash instructions apply --json` 回報的現行位置式 id 重建 6 條 per-task 紀錄：`1` ↔ `1.0`（`cash-skills.version`、`.cash-skills/lib/cash_cli/installer.py`、`.cash-skills/manifest.tsv`）、`2` ↔ `1.1`、`3` ↔ `1.2`、`4` ↔ `1.3`、`5` ↔ `2.1`（無檔案）、`6` ↔ `2.2`（無檔案）；`review-loop` 條目原樣保留，`files` 聯集重新計算且為原聯集的超集，確保 archive-first 提交集合不縮減。
- finding 4：修改 `implementation-notes.md`——追加一筆 `deviation` 條目說明前兩筆已被吸收為 IC6 與 task 1.0（依 Protocol 不改寫原條目），並追加一筆 `open-question` 條目據實記錄 task 1.0 的順序要求為事後補記、本次執行中 bump 實際發生於 1.1–1.3 之後，請使用者裁決 `[x]` 的語意。

**非 blocking finding 的處置**

- finding 5：triage note——雖為非 blocking，但同一問題類別已由三輪不同 reviewer 提出三次（round 1 以 `confidence: 40` 丟棄、round 1 finding 5 以 `60` 修復、本輪以 `50` 再現），且 round 1 的修復實際上是把問題搬家而非消除，故本輪一併修復。修改 `design.md`（IC1 第 8 點改為要求該規則放在 bullet list 之外並逐字指定 `**Template selection**` 段）、`.claude/skills/cash-archive/SKILL.md`（兩條規則移出欄位清單，合併為清單下方的 `**Template selection**` 段）、`.agents/skills/cash-archive/SKILL.md`（重新生成）、`tasks.md`（1.1 的兩條正向判準合併為一條釘住新的單行形式）。

**post-fix mechanical self-check 結果**

- comment/annotation lint：delta spec 的 `<!--` 與 `-->` 皆為 `0`。
- count-consistency：`tasks.md` 宣稱的「IC1 的九點」「IC2 的六點」與 `design.md` 實際條目數（`9`／`6`）相符；IC1–IC6 依序無空洞。
- identifier cross-grep：`Template selection`（archive 兩變體各 `1`、design `1`、tasks `2`）、`Delta spec sync was skipped (explicitly requested by the user)`（archive 兩變體各 `1`、design `1`、tasks `2`）一致；被移除的 `- Include the skipped warning line` 在四檔與 design、tasks 皆為 `0`；`— include only when the outcome is` 僅存在於 `tasks.md` 的回歸守則（`1`），四個 `SKILL.md` 皆為 `0`。
- spec delta title-identity：`### Requirement: cash-commit 的 archive-first 允許清單` 與 `openspec/specs/cash-skill-workflows/spec.md` 逐位元相符；無 `## RENAMED Requirements` 條目。
- signal-derived checks：`openspec/signals/` 下無任何帶 `check` frontmatter 欄位的 signal，全部落入 best-effort 判斷分支，無 `範圍外 check 失敗` 與 fallback 紀錄。
- self-check 未在本輪 fix actions 後抓到新的失敗。

**fix 後的重新驗證**

- 由 `tasks.md` 抽出的全部 `54` 條 `rg` 判準對現行工作樹逐條執行，`0` 失敗。
- 另以 HEAD baseline 重建的檔案樹重跑全部 `51` 條有宣告前置極性的判準，`0` 筆極性不符——確認 finding 2 的缺陷已消除，且無第二處同類問題。
- `.claude` 與 `.agents` 兩對檔案在 invocation 前綴正規化後全檔零差異。
- `./scripts/cash-skills/tests/skill-checks.fish` exit `0`（`PASS: bundle version history`、`PASS: exact live include-root namespace scan`、`PASS: all`）。
- `.cash-skills/bin/cash validate default-spec-sync-on-archive` 通過；`cash instructions apply` 回報 `state: all_done`、`6/6`。
- `.cash-skills/bin/cash analyze default-spec-sync-on-archive` 無 `Critical`。

**本輪 Fix Actions 修改的檔案（`openspec/changes/` 之外）**

- `.claude/skills/cash-archive/SKILL.md`
- `.agents/skills/cash-archive/SKILL.md`
- `.agents/skills/cash-commit/SKILL.md`
- `.cash-skills/manifest.tsv`

無 `未修復：裁判面保護` 紀錄；本輪未修改任何裁判面保護路徑下的檔案。

## Decision

next_round
