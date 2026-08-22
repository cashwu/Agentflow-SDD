# Cash Apply Review — Round 4

## Reviewer Findings

### Critical

（無）

### Warning

（無）

### Suggestion

1.
- `severity`: Suggestion
- `confidence`: 65
- `layer`: design
- `location`: `proposal.md` `## Proposed Solution` 第 2 點末句；`tasks.md` task 1.1 交付描述散文
- `summary`: 兩處都寫著「步驟 5 的失敗處置補上 **preflight 失敗**時的**兩條**出路」，但 round 1 修正後的 IC1 第 6 點把出路拆為「preflight（delta parse／`requirement_identity_mismatch`）→ 只有一條出路」與「`validation_failed` → 兩條出路」，且 `validation_failed` 依 `openspec/specs/cash-cli/spec.md` 明確不屬於 preflight；該措辭是 round 1 判定無效的那條出路的敘述外殼。
- `recommendation`: 把兩處改為與 IC1 第 6 點一致的敘述。行為與判準不需改動。
- `disposition`: `fix-introduced`
- `introduced_by`: round 1 `## Fix Actions`「blocking finding 的修復」finding 1 條目——該條改寫了 IC1 第 6 點、兩個 archive 變體的步驟 5 與 `tasks.md` 的正向判準，未把同一概念在 `proposal.md` 第 2 點與 `tasks.md` 1.1 交付描述中的出現一併同步。
- reviewer source: Reviewer A — Adherence
- 過濾紀錄：`confidence: 65` ∈ `[50, 80)`，維持 `Suggestion`；非 `Critical`／`Warning`，故即使 `disposition` 為 `fix-introduced` 亦不 blocking。

2.
- `severity`: Suggestion
- `confidence`: 60
- `layer`: design
- `location`: `.claude/skills/cash-archive/SKILL.md` 步驟 5 的失敗處置（`.agents` 同）；對照同檔步驟 3 與 `.cash-skills/lib/cash_cli/commands/archive.py`
- `summary`: 新增的失敗處置只列舉 `archive_collision`、delta parse／`requirement_identity_mismatch`、`validation_failed` 三類，漏掉 `tasks_incomplete`——而步驟 3 在偵測到未完成 task 時只「Prompt user for confirmation to continue」，全檔沒有一句把該確認接到 `--mark-tasks-complete`，因此使用者確認繼續後步驟 5 必然以 `tasks_incomplete` 硬失敗且無出路指引，連帶使 warnings 模板的 `- Archived with 3 incomplete tasks` 在本 skill 路徑上不可到達。
- `recommendation`: 在步驟 5 補一條 `tasks_incomplete` 的處置指向 `--mark-tasks-complete` 重跑；或把步驟 3 的確認明訂為「確認繼續即設定 `--mark-tasks-complete`」。
- `disposition`: `fix-introduced`
- `introduced_by`: round 1 `## Fix Actions` finding 1 條目（「步驟 5 失敗處置拆為兩段」），落地為 `git diff .claude/skills/cash-archive/SKILL.md` 新增的兩段 `**If archive fails**`；該修復把步驟 5 變成錯誤碼的枚舉面，卻只覆蓋 `archive_change()` 五個 raise 點中的三個。
- reviewer source: Reviewer B — Quality
- 過濾紀錄：Reviewer B 原報 `Warning`／`confidence: 60`。`confidence: 60` ∈ `[50, 80)`，依 confidence filter 降為 `Suggestion`，因此非 blocking。主 agent 附註：`tasks_incomplete` 與步驟 3 不接旗標這個缺口在本變更之前即已存在（步驟 3 與 Optional flags 兩處皆為未修改行），本輪 finding 的新意在於步驟 5 被改寫成錯誤碼枚舉面之後該遺漏才變得顯眼。

3.
- `severity`: Suggestion
- `confidence`: 55
- `layer`: design
- `location`: `.cash-skills/state/touched/default-spec-sync-on-archive.json`；對照 `.cash-skills/lib/cash_cli/commands/tasks.py` 的 `_validate_touched()` 與 `mark_task_done()`
- `summary`: round 2 重建後的對應目前正確，但該正確性沒有任何機械守門：`_validate_touched()` 只檢 shape、canonical 排序與 `files` 聯集，從不比對 `task_id`／`task_desc` 與 `tasks.md`；`mark_task_done()` 對既有 entry 只 union `files`、永不更新 `task_desc`。若後續任何 fix action 再增刪 `tasks.md` 的 task 條目，同樣的錯位會靜默復發。
- `recommendation`: 把「任何改動 `tasks.md` task 條目數的 fix action 之後 MUST 以 `cash instructions apply --json` 重新核對 touched 的 `task_id`／`task_desc`」寫成流程義務。
- `disposition`: `fix-introduced`
- `introduced_by`: round 2 `## Fix Actions` finding 3 條目——該修復以人工手段恢復不變量，未同時建立維持它的機制。
- reviewer source: Reviewer B — Quality
- 過濾紀錄：`confidence: 55` ∈ `[50, 80)`，維持 `Suggestion`。

4.
- `severity`: Suggestion
- `confidence`: 50
- `layer`: design
- `location`: `.claude/skills/cash-archive/SKILL.md` 步驟 6 的 `- Note about any warnings (incomplete artifacts/tasks)` 與其下的 `**Template selection**` 段（`.agents` 同）
- `summary`: 該 bullet 把 warning 的外延限定為未完成 artifact／task，緊接其下的 `**Template selection**` 段卻宣告 `an outcome of `skipped` is itself a warning`；同一步驟內對「什麼算 warning」給出兩個外延，只讀清單的 agent 在「`skipped` 但 artifacts 全 done、tasks 全 `[x]`」的乾淨路徑可能判定零 warning 而回到 `**Output On Success**`。
- `recommendation`: 把該 bullet 的括號改為 `(incomplete artifacts/tasks, or a `skipped` outcome)`，或刪去括號內的窮舉，讓 warning 的定義單一由 `**Template selection**` 段承載。
- `disposition`: `fix-introduced`
- `introduced_by`: round 1 `## Fix Actions` finding 5 條目（IC1 第 8 點改為新增步驟 6 規則）與 round 2 finding 5 條目（把該規則移出清單另起 `**Template selection**` 段）的交互——兩輪都只處理規則本身的位置與措辭，未同步清單內既有那一句對 warning 外延的窮舉。
- reviewer source: Reviewer B — Quality
- 過濾紀錄：`confidence: 50` ∈ `[50, 80)`，維持 `Suggestion`。主 agent 複核：該 bullet 在 `git diff` 中為 context 行（未修改），本 finding 的機制來自新舊內容相鄰後的交互。

5.
- `severity`: Suggestion
- `confidence`: 50
- `layer`: design
- `location`: `tasks.md` task 1.1 新增的錨定判準；對照 `design.md` IC1 第 8 點
- `summary`: IC1 第 8 點的位置義務是「放在該 bullet list **之外**、**於清單下方**另起一段」，新增的 `^   \*\*Template selection\*\*: use the` 只釘住「不是清單項目 + 3 空格內文縮排」，未釘住「下方」；把該段移到 `Show archive completion summary including:` 與 bullet list 之間時兩條判準仍全數 exit 0。
- `recommendation`: 補一條比較行號的順序判準，或把 IC1 第 8 點的「下方」降為說明性措辭，使規範面與判準面對齊。現行實作位置正確，不需改動任何 `SKILL.md`。
- `disposition`: `new`
- reviewer source: Reviewer A — Adherence
- 過濾紀錄：`confidence: 50` ∈ `[50, 80)`，維持 `Suggestion`。M1 指名的失敗模式（混進欄位清單）已完全涵蓋，殘餘的只是位置的前後向。

## Rating

- post-filter cumulative blocking set Critical count: `0`
- post-filter cumulative blocking set Warning count: `0`
- 非 blocking 的 triaged finding 數：`5`
- `critical_gap`: `false`
- `round_type`: `full`

rationale：本輪為本 run 第四輪，依位置規則為 full-round checkpoint，spawn 了 Reviewer A 與 Reviewer B 兩個 fresh sub-agent 並行審查，兩者收到相同 context 且獨立回報。兩位 checkpoint reviewer 對 cumulative blocking set 唯一成員 M1 都給出 `resolved` 判定，無分歧，M1 依「verified resolution」離開該集合，集合因此為空。本輪五筆 finding 經 confidence filter 後全部落在 `Suggestion`（`65`／`60`／`55`／`50`／`50`，其中 Reviewer B 原報的 `Warning`／`60` 因 `confidence ∈ [50, 80)` 降為 `Suggestion`），無任何 `Critical` 或 `Warning` 存活，故無新成員進入 cumulative blocking set。post-filter cumulative blocking set 既無 blocking `Critical` 也無 blocking `Warning`，pass 條件成立。

## Fix Actions

None; pass condition met.

**非 blocking finding 的 triage note**

- finding 1（`proposal.md` 與 `tasks.md` 1.1 殘留「preflight 失敗時的兩條出路」）：triage note，本輪不修復。決定為 `passed`，此時再改動 artifact 會使交付狀態與通過 gate 的狀態不一致且該改動未經任何 reviewer 驗證。純為 artifact 散文與 IC1 第 6 點的敘述不同步，不影響任何交付行為、判準或 spec；列為後續 change 候選，並於完成輸出中明確列出。
- finding 2（步驟 5 未涵蓋 `tasks_incomplete`，步驟 3 的確認未接 `--mark-tasks-complete`）：triage note，本輪不修復。該缺口在本變更之前即已存在（步驟 3 與 Optional flags 皆為未修改行），補上會擴大到「改變 `cash-archive` 對未完成 task 的處理方式」，超出本變更宣告範圍；列為後續 change 候選，並於完成輸出中明確列出。
- finding 3（touched 的 `task_id`／`task_desc` 不變量無機械守門）：triage note，本輪不修復。建議的處置是新增流程義務或 CLI 驗證，兩者都超出本變更範圍；`proposal.md` `## Non-Goals` 明列不改動 Cash CLI。該 issue class 已於本輪 signals write step 建立新 signal `positional-id-state-desynced-by-list-insertion` 留存；列為後續 change 候選。
- finding 4（步驟 6 的 warning 外延與 `**Template selection**` 段不一致）：triage note，本輪不修復。理由同 finding 1——決定為 `passed` 後不再改動交付內容；且該 bullet 為本變更未修改的既有行。列為後續 change 候選，並於完成輸出中明確列出。
- finding 5（錨定判準未釘住「下方」）：triage note，本輪不修復。`disposition` 為 `new`，且現行實作位置本身正確、IC1 第 8 點指名的失敗模式已被 M1 的修復完全涵蓋，殘餘僅為位置前後向的理論缺口。列為後續 change 候選。

**checkpoint 驗證彙總（兩位 reviewer 各自獨立完成）**

- IC1 第 2 點與 IC2 第 2 點的 fenced 逐字區塊與實際檔案內容 `diff` 零差異（含 IC2 的 4 空格縮排）；IC1 第 1／4／5／6／8／9 點與 IC2 第 1／3／4 點的釘住字串逐字相符；IC1 第 7 點、第 9 點與 IC2 第 5 點的「MUST NOT 改動」範圍在 `git diff` 中確實未被觸及。
- `tasks.md` 全部判準對現行工作樹依宣告極性逐條執行，`0` 失敗；以 `git show HEAD:` 重建 baseline 樹重跑全部有宣告前置極性的判準，`0` 筆極性不符。兩條 `awk` 段落級判準的範圍皆非空（1.1 現行 12 行、1.2 現行 11 行），具鑑別力。
- Reviewer A 與 Reviewer B 各自以 mutation test 驗證 M1：把 `**Template selection**` 段改寫成 `   - **Template selection**: …` 塞回步驟 6 欄位清單後，舊的字面值判準仍 exit 0 而新增的錨定判準 exit 1，證明修復具鑑別力。
- delta spec 的 7 條 ADDED scenario 與 5 條 MODIFIED scenario 逐條走查，皆能由改寫後的 SKILL.md 文字產生；`### Requirement: cash-commit 的 archive-first 允許清單` 與 master spec 逐 byte 相同。
- `**Specs:**` 模板窮舉：{`synced`／`skipped`／`no delta specs`} × {有／無 warnings} 六種組合中五種可達，每種恰好對應一個模板且值正確，無無主組合、無雙重對應。
- 變體對等：`.agents` 兩檔正規化 invocation 前綴後與 `.claude` 對應檔全檔零差異。
- 版本 bump 一致性：三處皆 `2.14.0`；`.cash-skills/bin/cash` 位元未變，`APPROVED_LAUNCHER_TRANSITIONS` 不需新登錄，vendored／receipt-based target 與 `--init-receipt` 皆不受影響。
- touched state：`cash instructions apply --json` 的六個位置式 id／description 與 touched JSON 逐筆對齊；`cash touched ensure` rc `0` 且未改寫檔案。
- `./scripts/cash-skills/tests/skill-checks.fish` exit `0`；`.cash-skills/bin/cash validate default-spec-sync-on-archive` 通過；`cash analyze` 無 `Critical`。
- round 1 已 triage 的三筆（Warnings 模板其餘行、invocation-vs-session 偵測範圍、6a-iii `master_digests`）本輪未取得新證據，兩位 reviewer 皆未再提出。

**本輪 Fix Actions 修改的檔案（`openspec/changes/` 之外）**

- 無。本輪未做任何修復。

無 `未修復：裁判面保護` 紀錄；本 run 四輪皆未修改任何裁判面保護路徑下的檔案。

## Decision

passed
