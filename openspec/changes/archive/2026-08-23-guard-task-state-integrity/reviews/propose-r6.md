# Cash Propose Review — Round 6

## Reviewer Findings

### Critical

（無）

### Warning

（無）

### Suggestion

1.
- `severity`: Suggestion
- `confidence`: 90
- `layer`: text
- `location`: `tasks.md` 任務 1.1 段落級判準區塊之後的「註」
- `summary`: 該註仍寫「步驟 5 的**兩條**分別釘住…」，但該區塊現有四條步驟 5 判準；其後的序數對映亦與實際順序相反（第二條是 `touched_invalid` 的相鄰判準對應 IC2 第 4 點，第四條才是 `tasks_incomplete` 的相鄰判準對應 IC2 第 3 點）。判準本身正確且具鑑別力，只有註的計數與對映不實。
- `recommendation`: 把「兩條」改為「四條」並依實際順序敘述。
- `disposition`: `fix-introduced`
- `introduced_by`: round 5 `## Fix Actions`「非 blocking finding 的處置」finding 6 條目——該條宣稱「更新該區塊的註說明四條判準各自對應的義務」，實際只在句尾追加一個子句，未更新計數也未校正序數。
- reviewer source: Reviewer V — Verification
- 過濾紀錄：主 agent 依 confidence filter 重檢此 `text` finding——判準本身正確，修復只更正註的計數與序數敘述，不改變任何行為或 design statement，維持 `layer: text`。

2.
- `severity`: Suggestion
- `confidence`: 85
- `layer`: design
- `location`: `proposal.md` `## Proposed Solution` 第 4 點與 `## Alternatives Considered`
- `summary`: `proposal.md` 全檔不含 `legacy` 或「豁免」字樣，第 4 點把「描述查無此項時以 `touched_invalid` fail closed」寫成無條件規則，但 D6 與 delta spec 明訂 `legacy_import` 非 `null` 時 MUST 豁免、D7 又對 legacy 重複 id 要求放棄對齊；D5 的「取不到或解析失敗時原樣回傳」同樣未出現在宣告層。屬 M2 同一類別但程度較輕——沒有交付物未宣告，只是規則少了例外限定。
- `recommendation`: 第 4 點補上 legacy 豁免的限定，並補一句 D5 的原樣回傳規則。
- `disposition`: `fix-introduced`
- `introduced_by`: round 1 `## Fix Actions`「blocking finding 的修復」finding 2 條目與同輪「非 blocking finding 的處置」finding 13 條目——兩者新增 D6 與 D5 的規則時皆未 propagate 到 `proposal.md`。
- reviewer source: Reviewer V — Verification

3.
- `severity`: Suggestion
- `confidence`: 80
- `layer`: text
- `location`: `design.md` IC6 ／ `tasks.md` 任務 1.3 交付敘述與行為判準
- `summary`: 三處都把 MODIFIED 下的 11 條 scenario 描述為「逐字沿用」，但其中兩條已被本變更加上新 GIVEN。標題集合與條數仍相符、義務範圍不受影響，但「逐字沿用」這個描述已不成立。
- `recommendation`: 三處改為「沿用既有行為的 11 條（其中兩條僅補上對齊不改變內容的 GIVEN）」。
- `disposition`: `fix-introduced`
- `introduced_by`: round 2 `## Fix Actions` finding 5 條目與 round 4「非 blocking finding 的處置」finding 8 條目——兩次為 scenario 補 GIVEN 時都未回頭調整「逐字沿用」的措辭。
- reviewer source: Reviewer V — Verification
- 過濾紀錄：主 agent 重檢此 `text` finding——義務範圍不受影響，修復只更正描述用詞，維持 `layer: text`。

4.
- `severity`: Suggestion
- `confidence`: 70
- `layer`: design
- `location`: `specs/cash-cli/spec.md` `## ADDED Requirements` 第二段 ／ `proposal.md` `## Proposed Solution` 第 4 點
- `summary`: M3 的深層複本修復只落在 `design.md`，delta spec 與 proposal 仍逐字要求「MUST 就地改寫該 `task_id`」——與 IC4 第 2 點的「MUST NOT 就地改寫傳入的物件」共用同一個詞卻指涉不同物件，字面上可被讀成允許污染載入的物件。
- `recommendation`: 兩處刪除「就地」二字即可；無須把深層複本機制寫進 spec，同 requirement 的 legacy 放棄 scenario 已把可觀察結果釘住。
- `disposition`: `fix-introduced`
- `introduced_by`: round 5 `## Fix Actions`「blocking finding 的修復」finding 3 條目——該修復同步了 IC4 與 D7，未同步 delta spec 散文與 `proposal.md` 的同一措辭。
- reviewer source: Reviewer V — Verification

5.
- `severity`: Suggestion
- `confidence`: 65
- `layer`: design
- `location`: `design.md` IC4 第 2 點第二個 bullet 末句
- `summary`: 該 bullet 把 symlink 情形寫為「`workspace.exists()`／`read_text()` 的 `unsafe_path`」，卻把捕捉範圍界定為「只包住讀取與 `_task_entries()` 解析這**兩個**動作」；而 `workspace.exists()` 經 `path_kind()` 對 symlink 直接拋 `unsafe_path`，發生在任何讀取之前。只包住兩個動作的實作會讓該錯誤逸出，違反 D5 與 ADDED 散文，而無任何判準或 scenario 能攔下。
- `recommendation`: 末句改為「只包住路徑探測（`workspace.exists()`）、讀取與 `_task_entries()` 解析這三個動作」。
- `disposition`: `fix-introduced`
- `introduced_by`: round 5 `## Fix Actions`「blocking finding 的修復」finding 1 條目——新增邊界句時以「兩個動作」收束，與同句列舉的 `workspace.exists()` 不相容。
- reviewer source: Reviewer V — Verification

6.
- `severity`: Suggestion
- `confidence`: 60
- `layer`: design
- `location`: `specs/cash-cli/spec.md` `## MODIFIED Requirements` 散文 ／ `design.md` IC6 ／ `tasks.md` 任務 1.3 行為判準
- `summary`: MODIFIED 散文的「對齊改變了內容時 MUST 寫入，即使合併結果本身與載入值相同」沒有任何 scenario：MODIFIED 下的 11 條只覆蓋反向規則，ADDED 下的寫回 scenario 全部針對 `touched ensure`。IC6 把測試義務掛在 ADDED 的 scenario 上，因此一個讓 `touched record` 呼叫對齊卻沒把 flag 併入寫入條件的實作仍能通過全部判準。
- `recommendation`: 在 ADDED 之下補一條 `touched record` 的寫入 scenario。
- `disposition`: `new`
- reviewer source: Reviewer V — Verification

## Rating

- post-filter cumulative blocking set Critical count: `0`
- post-filter cumulative blocking set Warning count: `0`
- 非 blocking 的 triaged finding 數：`6`
- `critical_gap`: `false`
- `round_type`: `micro`

rationale：Reviewer V 對 round 5 cumulative blocking set 的四名成員 M1–M4 全部給出 `resolved` 判定並附驗證證據——M1 逐字核對 IC4 第 2 點的廣義捕捉與四種情形列舉、M2 確認四處敘述層同步且全庫無「兩個會撞到它的 skill」殘留、M3 逐條追過 IC4 第 2 點的 bullet 序列並核對 `_validate_touched()` 的唯一性檢查確認放棄分支回傳的物件下次會被接受、M4 確認兩條 scenario 到位且 ADDED 由 11 增為 13。四者依「verified resolution」離開 cumulative blocking set，該集合因此清空。本輪六筆 finding 經 confidence filter 後**全部為 `Suggestion`**，無任何 `Critical` 或 `Warning` 存活，故無新成員進入 cumulative blocking set。post-filter cumulative blocking set 既無 blocking `Critical` 也無 blocking `Warning`，pass 條件成立。本輪為本 run 第六輪（上限），若未通過即須 `aborted`；實際通過，因此不進行 Abort triage。

本 run 的收斂軌跡：blocking 數 `11 → 4 → 1 → 2 → 4 → 0`。第五輪引入的機械化跨 artifact 傳播檢查是本輪收斂的直接原因——本 run 前五輪共 17 筆 `fix-introduced` finding，根因高度集中於「一筆修復觸及的概念未傳播到全部應提及它的 artifact」，而該檢查把傳播完整性從人工判斷改為機械掃描。本輪殘留的六筆 `Suggestion` 中有四筆仍屬同一根因（finding 1、2、3、4），顯示該檢查的概念清單仍未涵蓋全部應追蹤的概念。

## Fix Actions

None; pass condition met.

**cumulative blocking set 的 verified resolution 移除紀錄**

- M1（IC4 第 2 點未同步廣義捕捉）：移除。fix reference — round 5 `## Fix Actions` finding 1；verifying reviewer — Reviewer V。
- M2（三處敘述層仍描述修復前的世界）：移除。fix reference — round 5 finding 2；verifying reviewer — Reviewer V。
- M3（放棄分支與就地改寫互斥）：移除。fix reference — round 5 finding 3；verifying reviewer — Reviewer V，另核對 `.cash-skills/lib/cash_cli/commands/tasks.py` 的 `_validate_touched()` 確認放棄分支回傳的原輸入下次讀取會被接受。
- M4（legacy 重複 id 規則無 scenario）：移除。fix reference — round 5 finding 4；verifying reviewer — Reviewer V。

**confidence filter 降級與丟棄紀錄**

- 本輪六筆 finding 由 Reviewer V 全部歸類為 `Suggestion`，`confidence` 分別為 `90`／`85`／`80`／`70`／`65`／`60`，均未觸發降級（confidence filter 只在 `confidence < 80` 時把 `Critical`／`Warning` 降級，對本來就是 `Suggestion` 的 finding 不改變分級）。
- 無 `confidence < 50` 的丟棄項。
- `layer` 重檢：finding 1 與 finding 3 由 Reviewer V 標為 `text`，主 agent 逐條確認兩者的修復都只更正描述性文字（判準計數與序數、scenario 沿用程度的措辭），不改變任何行為或 design statement，維持 `text`。其餘四筆為 `design`，未做任何 `design` → `text` 的重分類。
- disposition 檢查：五筆標 `fix-introduced` 者皆附具體的 round 與條目引用，主 agent 逐筆對照確認正確；finding 6 標 `new`，主 agent 確認 MODIFIED 散文的該規則自 round 1 建立 MODIFIED 時即無 scenario、非任何一輪 fix 所產生，`new` 標記正確。

**非 blocking finding 的 triage note**

本輪決定為 `passed`，六筆 `Suggestion` 全部以 triage note 處理、本輪不修復——此時再改動 artifact 會使交付狀態與通過 gate 的狀態不一致，且該改動未經任何 reviewer 驗證。六筆逐一列於本節，並於完成輸出中明確列出：

- finding 1（任務 1.1 註的判準計數與序數不實）：純描述性文字，判準本身正確且經 mutation test 證實具鑑別力，不影響交付行為。
- finding 2（`proposal.md` 第 4 點未帶 legacy 豁免與 D5 原樣回傳的限定）：宣告層的規則少了例外限定；delta spec 與 design 兩處都完整，實作契約不受影響。
- finding 3（「逐字沿用」措辭已不成立）：純描述性文字，MODIFIED 的標題集合與條數仍相符，合併身分與義務範圍不受影響。
- finding 4（delta spec 與 proposal 殘留「就地改寫」）：措辭與 IC4 的深層複本要求共用同一個詞卻指涉不同物件；同 requirement 的 legacy 放棄 scenario 已把可觀察結果釘住，因此實作若照 scenario 驗收仍會被攔下，但措辭本身應在 apply 前釐清。
- finding 5（捕捉範圍「兩個動作」與 `workspace.exists()` 不相容）：**六筆中對實作影響最直接的一筆**。照 IC4 逐字實作會讓 symlink 的 `unsafe_path` 逸出，而無任何判準或 scenario 能攔下。建議在 apply 前先修。
- finding 6（`touched record` 的寫入條件無 scenario）：`disposition` 為 `new`，屬本變更自 round 1 起就存在的覆蓋缺口；一個未把 flag 併入 `touched record` 寫入條件的實作能通過全部判準。建議在 apply 前補一條 scenario。

**post-fix mechanical self-check 結果**

本輪無 fix actions，故不需要 post-fix self-check。Reviewer V 於本輪執行的機械驗證結果如下（皆通過）：`.cash-skills/bin/cash validate guard-task-state-integrity` exit `0`；`tasks.md` 全部可直接執行的判準極性 100% 符合宣告；8 條段落級判準的 `awk` 範圍皆非空且起訖點對實檔核對成立；任務 0.1 的七條閘門判準在 `fish` 下全部回傳非零（七個重疊路徑現皆為 ` M`），閘門會正確擋下；IC1–IC10 與 D1–D11 無空洞、無 dangling 引用；`tasks.md` 的「依 IC4 六點施作」與 IC4 實際條目數相符；MODIFIED requirement 標題與 master spec 逐位元相符；ADDED 13 條 scenario 逐條都能對應到 design 明訂的規則，反向缺口只有 finding 6 指出的一處。

**本輪 Fix Actions 修改的檔案（`openspec/changes/` 之外）**

- 無。本輪無任何修改。

無 `未修復：裁判面保護` 紀錄；本 run 六輪皆未修改任何裁判面保護路徑下的檔案。

## Decision

passed
