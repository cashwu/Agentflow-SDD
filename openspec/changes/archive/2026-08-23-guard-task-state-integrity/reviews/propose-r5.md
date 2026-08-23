# Cash Propose Review — Round 5

## Reviewer Findings

### Critical

（無）

### Warning

1.
- `severity`: Warning
- `confidence`: 100
- `layer`: design
- `location`: `design.md` IC4 第 2 點第二個 bullet
- `summary`: round 4 把 D5 的捕捉範圍擴為「讀取或解析 `tasks.md` 的任何失敗」並在 delta spec 同步，但 IC4 第 2 點仍逐字停留在窄版「`_task_entries()` 拋出 `task_id_invalid` 時 MUST 捕捉」。IC4 是任務 1.3 指名要「依 IC4 六點施作」的實作契約，照它逐字實作會讓 `unsafe_path` 與 `invalid_encoding` 從對齊路徑逸出，直接違反 D5 與已定案的 delta spec；`tasks.md` 的判準對此完全不敏感。round 4 fix action 宣稱的「IC4 第 2 點同步」未實際發生。
- `recommendation`: 把該 bullet 改寫為與 D5、ADDED 散文逐字一致，並界定捕捉範圍只包住讀取與解析、不得包住對齊迴圈自身拋出的 `touched_invalid`。
- `disposition`: `fix-introduced`
- `introduced_by`: round 4 `## Fix Actions`「非 blocking finding 的處置」finding 11 條目。
- reviewer source: Reviewer V — Verification
- 主 agent 複核：實檔 grep 確認 IC4 第 2 點該 bullet 逐字仍為窄版。**finding 成立，且屬 `fix-action-recorded-without-being-applied`——round 4 的 Fix Actions 記錄了一項未實際執行的修改，該記錄不實。**

2.
- `severity`: Warning
- `confidence`: 100
- `layer`: design
- `location`: `proposal.md` `## Proposed Solution` 第 2、7 點 ／ `design.md` `## Goals` 第五項 ／ `design.md` IC9 第一個 bullet
- `summary`: M2 的修復在 D8、IC2、delta spec 與 `tasks.md` 都落地了，但三處敘述層仍描述修復前的世界：`## Proposed Solution` 完全未宣告 `cash-archive` 步驟 5 的 `touched_invalid` 指引；`## Goals` 仍寫「兩個會撞到它的 skill」；IC9 對第一條 requirement 的內容摘要漏掉已新增的 `touched_invalid` 義務。`## Proposed Solution` 是宣告範圍，現在弱於 delta spec 與 tasks 實際交付的內容。
- `recommendation`: 三處同步。
- `disposition`: `fix-introduced`
- `introduced_by`: round 4 `## Fix Actions`「blocking finding 的修復」finding 2 條目——該修復只列出四處，未 propagate 到這三處。
- reviewer source: Reviewer V — Verification

3.
- `severity`: Warning
- `confidence`: 90
- `layer`: design
- `location`: `design.md` D7 第二段 ／ IC4 第 2 點 ／ `specs/cash-cli/spec.md` ADDED 散文
- `summary`: legacy 重複 id 的「放棄整次對齊並回傳原樣值」與同一契約要求的「就地改寫 `task_id`」互斥——就地改寫之後那個「原樣值」已不存在，回傳的物件帶著已套用的部分改寫與重複 id；`mark_task_done()` 以 shallow copy 取值後無條件寫檔，重複 id 會就此落地，下一次讀取時 `_validate_touched()` 立即以 `touched_invalid` 拒絕，正是 D6／D7 該分支要避免的永久卡死。D7 的理由句「`_validate_touched()` 對原樣值的唯一性檢查本來就已通過」因此不成立。
- `recommendation`: 明訂對齊 MUST 在深層複本上運作，放棄分支回傳未被污染的原輸入；D7 的理由句改為以此為前提。
- `disposition`: `fix-introduced`
- `introduced_by`: round 4 `## Fix Actions`「非 blocking finding 的處置」finding 4 條目——新增放棄分支時未與 IC4 既有的「就地改寫」手段及 `mark_task_done()` 的無條件寫入對照。
- reviewer source: Reviewer V — Verification

4.
- `severity`: Warning
- `confidence`: 85
- `layer`: design
- `location`: `specs/cash-cli/spec.md` `## ADDED Requirements` 的 scenario 集合 ／ `design.md` IC6 ／ `tasks.md` 任務 1.3「行為判準」
- `summary`: round 4 新增的 legacy 重複 id 放棄規則只寫進散文，沒有對應 scenario；而 IC6 與行為判準把測試義務逐條掛在「ADDED 之下的每一條 scenario」，因此該規則完全不在測試義務範圍內——一個把 legacy 重複 id 也照 fail closed 實作的版本能通過全部判準與逐條覆蓋核對。
- `recommendation`: 補一條對應 scenario，並在既有 fail-closed scenario 的 GIVEN 補 `legacy_import` 為 `null`。
- `disposition`: `fix-introduced`
- `introduced_by`: round 4 `## Fix Actions`「非 blocking finding 的處置」finding 4 條目——同步了三處散文，未同步 scenario 集合。
- reviewer source: Reviewer V — Verification

### Suggestion

5.
- `severity`: Suggestion
- `confidence`: 70
- `layer`: design
- `location`: `specs/cash-cli/spec.md` ADDED 散文末句 ／ 該 requirement 的 scenario 集合
- `summary`: round 4 新增的「僅順序改變仍 MUST 視為對齊改變了內容」同樣只存在於散文，無對應 scenario；同輪為兩條 MODIFIED scenario 補的 canonical 排序 GIVEN 使那兩條在任一實作下都成立，因此也不具鑑別力。該規則沒有任何機械落點。
- `recommendation`: 補一條純重排的 scenario。
- `disposition`: `fix-introduced`
- `introduced_by`: round 4 `## Fix Actions`「非 blocking finding 的處置」finding 8 條目。
- reviewer source: Reviewer V — Verification

6.
- `severity`: Suggestion
- `confidence`: 65
- `layer`: design
- `location`: `design.md` IC2 第 4 點末句 ／ `tasks.md` 任務 1.1 段落級判準
- `summary`: IC2 第 4 點要求 `touched_invalid` 那一條「MUST 置於 `tasks_incomplete` 那一條之後」，但 `tasks.md` 只為它加了存在性判準，沒有相鄰／順序判準；把它插到 `tasks_incomplete` 之前的實作可通過全部判準。
- `recommendation`: 比照 IC2 第 3 點補一條 `rg -U` 相鄰性判準。
- `disposition`: `fix-introduced`
- `introduced_by`: round 4 `## Fix Actions`「blocking finding 的修復」finding 2 條目——新增置放義務時未同步新增其機械判準。
- reviewer source: Reviewer V — Verification

## Rating

- post-filter cumulative blocking set Critical count: `0`
- post-filter cumulative blocking set Warning count: `4`
- 非 blocking 的 triaged finding 數：`2`
- `critical_gap`: `false`
- `round_type`: `micro`

rationale：Reviewer V 對 round 4 cumulative blocking set 的兩名成員 M1、M2 都給出 `resolved` 判定並附驗證證據——M1 以 `fish` 實測七條閘門全部回傳 exit 1、並確認與 `default-spec-sync-on-archive` 的重疊集合恰為這七個路徑；M2 以全庫 grep 確認無「IC2 第 4 點」殘留指向舊第 4 點。兩者依「verified resolution」離開 cumulative blocking set。Reviewer V 另以 mutation test 驗證 round 4 新增判準確實鑑別：correct-implementation 變異檔使 19 條判準全部翻轉，只違反 IC1 第 2 點的變異檔恰被步驟 3 的新判準攔下，以 6 空格插入的變異檔被行首錨定判準攔下（舊的 `rg -Fq` 形式會漏放）。但本輪新增六筆 finding，經 confidence filter 後四筆維持 `Warning` 且 `disposition` 皆為 `fix-introduced`，屬 blocking disposition，故四者進入 cumulative blocking set，本輪不能 pass。無 blocking `Critical`，`critical_gap` 為 `false`。本輪為本 run 第五輪，非第四輪，故 `round_type` 為 `micro`。

**本輪必須誠實記錄的流程失誤**：finding 1 顯示 round 4 的 `## Fix Actions` 記錄了「IC4 第 2 點同步」，但該修改未實際執行。Fix Actions 是 gate 輸入，記錄不實會使後續輪次以錯誤前提判斷。本輪因此新增機械化的跨 artifact 傳播檢查（見 `## Fix Actions`），不再單靠人工判斷確認傳播完成。

## Fix Actions

**cumulative blocking set 的 verified resolution 移除紀錄**

- M1（0.1 閘門只涵蓋 5 個路徑）：移除。fix reference — round 4 `## Fix Actions` finding 1；verifying reviewer — Reviewer V，以 `fish` 實測七條閘門皆 exit 1、`git status --porcelain` 確認重疊集合恰為七個路徑、全庫 grep 已無五路徑敘述或「同一組檔案中的四個」。
- M2（D8 只列兩個撞擊點）：移除。fix reference — round 4 `## Fix Actions` finding 2；verifying reviewer — Reviewer V，確認 D8 標題與枚舉、IC2 新第 4 點、delta 義務散文與 scenario、`tasks.md` 三條判準皆到位，且無「IC2 第 4 點」殘留指向舊編號。

**confidence filter 降級與丟棄紀錄**

- finding 1、2、3、4 的 `confidence` 分別為 `100`／`100`／`90`／`85`，皆 ≥ 80，維持 `Warning`；`disposition` 皆為 `fix-introduced`，進入 cumulative blocking set。
- finding 5、6 原即為 `Suggestion`（`70`／`65`），維持。
- 無 `confidence < 50` 的丟棄項；本輪 reviewer 未標任何 `text` finding，無 `layer` 重分類。
- disposition 檢查：六筆皆標 `fix-introduced`，主 agent 逐筆對照 round 4 的 fix-action 條目確認標記正確，無需更正。

**blocking finding 的修復**

- finding 1：修改 `design.md`——IC4 第 2 點第二個 bullet 改寫為「讀取或解析 `tasks.md` 的**任何**失敗 MUST 捕捉並回傳 `(touched, False)`」並逐一列出四種情形（`task_id_invalid`、symlink 的 `unsafe_path`、非 UTF-8 的 `invalid_encoding`、目錄），另明訂該捕捉範圍 MUST 只包住讀取與 `_task_entries()` 解析，MUST NOT 包住對齊迴圈依 D3／D7 自行拋出的 `touched_invalid`。
- finding 2：修改 `proposal.md`（`## Proposed Solution` 第 2 點改為「增加兩條」並逐一說明 `tasks_incomplete` 與 `touched_invalid`，另補 command 範例增加帶旗標一行；第 7 點改為涵蓋 `cash-commit` 與 `cash-archive` 兩處並註明 `cash-apply` 是範圍外的第三撞擊點）、`design.md`（`## Goals` 第五項改為「三個撞擊點中落在本變更範圍內的兩個」並具名；IC9 第一個 bullet 補列 `touched_invalid` 的復原指引）。
- finding 3：修改 `design.md`——IC4 第 2 點新增第一個 bullet，明訂對齊 MUST 在輸入的深層複本上運作、MUST NOT 就地改寫傳入物件，並說明理由（放棄分支要回傳未被污染的原輸入，而 `mark_task_done()` 的 shallow copy 取值＋無條件寫檔會使被污染的重複 id 落地）；其後的改寫 bullet 改為作用於複本；legacy 放棄分支改為「丟棄該複本、回傳未被任何改寫污染的原輸入」；D7 的理由句改寫為以「在深層複本上運作」為前提。
- finding 4：修改 `specs/cash-cli/spec.md`——既有 `#### Scenario: 對齊後 id 重複時 fail closed` 的 GIVEN 補 `legacy_import` 為 `null`；新增 `#### Scenario: legacy 來源的 state 在 id 重複時放棄對齊`（THEN 含「回傳的 state 與磁碟上的原值逐字相同，未帶任何已套用的 `task_id` 改寫」，同時覆蓋 finding 3 的深層複本義務）。

**非 blocking finding 的處置**

- finding 5：triage note——本輪一併修復。修改 `specs/cash-cli/spec.md`，新增 `#### Scenario: 僅順序改變時仍視為對齊改變了內容`，使該規則落入 IC6 的 `test_realign_` 覆蓋義務。
- finding 6：triage note——本輪一併修復。修改 `tasks.md`，任務 1.1 段落級判準新增 `rg -Uq -- 'bypasses this precondition\.[^\n]*\n\n   \*\*If archive fails\*\* with `touched_invalid`'`，把 IC2 第 4 點的置放義務釘成相鄰關係；並更新該區塊的註說明四條判準各自對應的義務。

**流程改善：機械化跨 artifact 傳播檢查**

本 run 前五輪共 13 筆 `fix-introduced` finding，其中多數的根因相同——一筆修復觸及的概念沒有傳播到全部應提及它的 artifact，而傳播與否一直依賴人工判斷。finding 1 更顯示曾有一筆 Fix Actions 記錄了未實際執行的修改。因此本輪建立一支傳播檢查腳本，對十個關鍵概念各宣告「MUST 提及它的 artifact 集合」，機械掃描 `proposal.md`、`design.md`、兩份 delta spec 與 `tasks.md` 五份檔案並回報缺口。本輪修復後該檢查全數通過（exit 0）；其中兩筆初報的 GAP 經查為 probe 字串寫法造成的誤報（design 使用 `**任何**` 粗體標記與不同措辭），已修正 probe 後複驗。此檢查自本輪起納入每次 fix actions 後的自檢程序。

**post-fix mechanical self-check 結果**

- 跨 artifact 傳播檢查：十個關鍵概念全部 `OK`，無缺口。
- comment/annotation lint：兩份 delta 的 `<!--`／`-->` 與 stray `---` 皆為 `0`。
- count-consistency：`tasks.md` 的「依 IC4 六點施作」與 `design.md` IC4 實際條目數相符；`design.md` 三處「七個路徑」與 `tasks.md` 七條閘門判準一致；IC 條目 `10`、D 條目 `11`，無空洞。
- 空區塊掃描：全部具極性宣告的判準區塊皆非空。
- spec delta title-identity：`### Requirement: touched record 記錄 review loop 產出` 與 master spec 仍逐位元相符。
- signal-derived checks：`openspec/signals/` 下無任何帶 `check` frontmatter 欄位的 signal，全部落入 best-effort 判斷分支，無 `範圍外 check 失敗` 與 fallback 紀錄。

**fix 後的重新驗證**

- `.cash-skills/bin/cash validate guard-task-state-integrity` 通過。
- `tasks.md` 中 24 條可直接執行的 `rg` 判準對現行（實作前）工作樹逐條執行，極性全部符合宣告，`0` 筆不符。
- 本輪新增的 `rg -U` 相鄰性判準實測實作前 exit 1，具鑑別力。
- `cash-cli` delta 的 `## ADDED Requirements` scenario 由 11 條增為 13 條，兩條新增皆對應本輪修復的規則。

**本輪 Fix Actions 修改的檔案（`openspec/changes/` 之外）**

- 無。本輪全部修改都落在 `openspec/changes/guard-task-state-integrity/` 之下，濾除該前綴後候選集合為空，因此不呼叫 `"$cash_cli" touched ensure` 與 `"$cash_cli" touched record`，亦不產生警告。

無 `未修復：裁判面保護` 紀錄；本輪未修改任何裁判面保護路徑下的檔案。

## Decision

next_round
