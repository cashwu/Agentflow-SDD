# Cash Propose Review — Round 3

本輪為本次執行的第三輪，依位置推導 `round_type: micro`，spawn 一位全新的 `Reviewer V — Verification`。它收到 `reviews/propose-r1.md` 與 `reviews/propose-r2.md` 全文、四份 artifact 路徑、當前累積 blocking 集合成員清單（F1、F2），以及相關的 `open` signals。本 change 無 accepted-risks ledger。

## Reviewer Findings

### 累積 blocking 集合成員裁定

| 成員 | 裁定 | 驗證依據 | 對應修正 |
|---|---|---|---|
| F1 三值判定結果重疊、逐字文字無排序語意 | resolved | IC1 第 2 點與 IC2 第 2 點的 `Record the resolved outcome by evaluating in order: …` 逐字內容；三個 guard 各自帶旗標條件，旗標×delta 四格全覆蓋、既有序也互斥且窮盡；D4 與 delta ADDED 本文的中文句經程式化比對為同一字串；交集 scenario 的 THEN 已補齊；`sync skipped` 作為判定結果名稱已消滅 | round 2 Fix Actions 的 F1 條目 |
| F2 D5 的三模板對應宣稱不成立 | resolved | D5 第一個 bullet 已改為事實敘述並具名指出無模板可用的組合；IC1 第 9 點釘住 warnings 模板兩行的佔位改寫；tasks 三條舊字串已移入負向判準、三條佔位字串已入正向判準、`**Specs:** ✓ Synced to main specs` 已入保留守則 | round 2 Fix Actions 的 F2 條目 |

兩名成員皆經 Reviewer V 明確裁定為 resolved，以 verified resolution 離開集合。累積 blocking 集合於本輪清空。

### Suggestion（全部為非 blocking）

**V1 — IC2 第 2 點的逐字區塊缺 4 空格縮排，連帶使 1.2 段落級判準喪失鑑別力**

- `severity`: Suggestion（Reviewer V 給定 Warning／75，經信心過濾器降級）
- `confidence`: 75
- `layer`: design
- `location`: `design.md` IC2 第 2 點 fence；`tasks.md` 1.2 段落級判準；`.claude/skills/cash-commit/SKILL.md:184-194`
- `summary`: IC1 的 fence 剝掉 fence 縮排後為「標題 col 0／本文 3 空格」，恰好等於 `cash-archive` 步驟 4 的版面；IC2 的 fence 剝掉後為「全部 col 0」，但 `cash-commit` 的 6a 子段落一律縮排 4（6a 是 numbered list item，子段落屬其內文）。照字面施作會把 6a-ii 抽出 6a 內文而破壞區塊結構；連帶使 `tasks.md` 1.2 的段落級判準因 awk 起點 `^    \*\*6a-ii\.` 失配而範圍為空，exit 1 恰好等於它宣稱的實作後狀態，於是以零鑑別力通過，IC2 第 6 點失去唯一的機械把關。
- `recommendation`: fence 內容改為含 4 空格縮排並加明文要求；tasks 1.2 另加一條把縮排本身釘住的正向判準。
- `disposition`: new

**V2 — 「判定結果為 `skipped` 且無 warnings」在改寫後沒有可用模板，原本消歧的內容線索被 round 2 的修正拿掉**

- `severity`: Suggestion（Reviewer V 給定 Warning／75，經信心過濾器降級）
- `confidence`: 75
- `layer`: design
- `location`: `design.md` D5 第一個 bullet、IC1 第 8、9 點；`.claude/skills/cash-archive/SKILL.md:103-145`
- `summary`: round 2 把 warnings 模板的 `**Specs:**` 行從專屬跳過的硬寫值改為三值佔位，同時 IC1 第 9 點明訂另外兩個模板不得改動，於是三個成功模板變成混合鍵；而「模板由有沒有 warnings 決定」這條選擇規則只寫在 `design.md`，IC1 沒有要求把它寫進 SKILL.md。結果「使用者明確要求跳過、artifacts 全 done、tasks 全 `[x]`」的乾淨路徑沒有任何模板長得像它，`**Output On Success**` 成為自然吸引子，會印出硬寫的 `**Specs:** ✓ Synced to main specs`。IC1 第 8 點新增的步驟 6 規則能救 `**Specs:**` 的字串值，救不了模板選擇與跳過警告行的取捨。
- `recommendation`: 在步驟 6（本來就要改的段落）逐字加入模板選擇規則，並在 tasks 1.1 加對應正向判準；不必動到被第 9 點鎖住的另兩個模板。
- `disposition`: fix-introduced
- `introduced_by`: round 2 `## Fix Actions` 的 F2 條目（把 warnings 模板的 `**Specs:**` 行與跳過警告行改為佔位形式，同時維持另外三個 Output 模板不得改動）

**V3 — `proposal.md` 未接到 round 2 的兩項精修**

- `severity`: Suggestion
- `confidence`: 50
- `layer`: text
- `location`: `proposal.md` `## Proposed Solution` 第 1 點與第 3 點
- `summary`: 「依序判定」一句在 `design.md` 與 delta spec 各存在、在 `proposal.md` 出現 0 次；第 3 點仍寫「套用完全相同的判定規則」，而 F5 的修正已把明確要求的形式拆為 per-entry。round 2 的 F1 與 F5 修正動作都未把 proposal 納入傳播範圍。
- `recommendation`: proposal 補上依序判定一句，並把「完全相同的判定規則」限縮為「相同的兩條優先序判定，明確要求的形式依入口而異」。
- `disposition`: new

### Reviewer V 明確查驗無缺陷的項目

判定三分支經窮舉檢查為互斥且窮盡（旗標 set／unset × delta 有／無 四格全覆蓋）；IC1 第 8、9 點與其餘七點及 SKILL.md 未改動段落無衝突；改寫後兩份 SKILL.md 仍各自維持恰好一處互動 fallback 陳述，不觸犯 master spec 的 `Skill 互動 fallback 的單一陳述` requirement；MODIFIED 區塊標題與 master 逐字相同，改動全部落在 spec sync 納入條件，兩條未涉及的 scenario 逐字沿用，新增的負向 scenario 落在 IC4 明文允許的 MAY 範圍內；ADDED 的六條 scenario 兩兩以「是否明確要求跳過」「是否存在 delta specs」「哪個入口」區分，無重疊或矛盾且全部可機械驗證；per-entry 形式規定在 D2、delta ADDED 與 Risks 第三條之間一致；repo-wide 殘留掃描只命中 `proposal.md` `## Impact` 已列出的四個 SKILL.md；tasks 全部 47 條判準逐條實跑，與各分類宣稱的實作前狀態 100% 相符；23 條正向判準字面值對 `design.md` 逐字命中。

## Rating

- post-filter 累積 blocking 集合 Critical 數：0
- post-filter 累積 blocking 集合 Warning 數：0
- 非 blocking triaged finding 數：3（V1、V2、V3）
- `critical_gap`: false
- `round_type`: micro

rationale：累積 blocking 集合的兩名成員 F1、F2 皆經 Reviewer V 明確裁定為 resolved 並以 verified resolution 離開集合，集合於本輪清空。本輪三個新 finding 中，V1 與 V3 的 `disposition` 為 `new`——依規則存活的 `new` finding 一律非 blocking；V2 的 `disposition` 雖為 `fix-introduced`，但 Reviewer V 給定 `confidence` 75，經信心過濾器落在 `[50, 80)` 而降級為 `Suggestion`，不再是 blocking 的 `Critical` 或 `Warning`。主 agent 已複驗，未對這三項做向上校正：V2 的失效需要實作者在步驟 6 的明文規則與模板字面之間選擇後者才會發生，屬「已驗證且可能發生，但無直接證據證明必然違反」，75 是正確評分。因此 post-filter 累積 blocking 集合為空，依 pass 條件（若且唯若集合不含 blocking Critical 與 blocking Warning）本輪決策為 `passed`。

## Fix Actions

### 非 blocking finding 的處置

依規則 V1、V2、V3 皆為非 blocking，本可只記 triage note。主 agent 判定三者的修法都是機械性、低風險且不改變任何已驗證的契約決策，因此在記錄 triage 的同時一併修畢，避免把已知缺陷交給 apply 階段。**此三項修正發生在 pass 條件成立之後，未經任何 reviewer 驗證**，本事實一併記入完成輸出。

- **V1** — 修改 `design.md`、`tasks.md`。IC2 第 2 點的 fence 內容改為含 4 空格縮排（fence 本身縮排 3，內容行為 7），並在該點加入明文：6a 是 numbered list item、其子段落一律縮排 4，插入時 MUST 原樣沿用、MUST NOT 拉齊到 column 0，並具名說明拉齊會使 tasks 1.2 的段落級判準變成空真。`tasks.md` 1.2 新增正向判準 `rg -q -- '^    \*\*6a-ii\. Delta spec sync determination\*\*$'` 把縮排本身釘住，並在段落級判準下加註兩條 MUST 一併成立才算通過；1.2 的施作敘述補上「原樣沿用其 4 空格縮排」。

- **V2** — 修改 `design.md`、`tasks.md`。IC1 第 8 點補上第二條步驟 6 摘要行的逐字要求 `- Use the **Output On Success With Warnings** template whenever there is at least one warning; an outcome of `skipped` is itself a warning`，並記錄理由：第 9 點把 warnings 模板的 `**Specs:**` 行改為佔位形式後，原本靠內容線索消歧的方式已不復存在，模板選擇規則必須寫成明文。`tasks.md` 1.1 加入該字串的正向判準。未改動被第 9 點鎖住的另兩個模板。

- **V3** — 修改 `proposal.md`。`## Proposed Solution` 第 1 點補上「判定結果依序判定：先 `skipped`，再 `synced`，最後 `no delta specs`」並把明確要求的形式限定於 `cash-archive`；第 3 點改為「相同的兩條優先序判定規則（明確要求的形式依入口而異：`cash-commit` 的 archive-first 子流程沒有自己的 invocation 可掛旗標，只有在本次 session 中直接說明一種形式）」並補上依序判定。

### 修正後重跑的驗證

- 註解／annotation lint：四份 artifact 的 `<!--`／`-->` 計數皆為 0／0。
- 計數一致性：IC1 為 9 點、IC2 為 6 點，與 `tasks.md` 的「依 IC1 的九點」「依 IC2 的六點」相符。
- 縮排一致性：IC2 fence 內容行縮排實測為 7，扣除 fence 自身的 3 後為 4，與 `.claude/skills/cash-commit/SKILL.md` 的 6a-i／6a-ii／6a-iii 實測縮排 4 相符。
- 識別字交叉比對：27 條正向判準字面值對 `design.md` 逐字比對，除 2 條指涉既有 SKILL.md 內容的保留守則字面值外全部命中。
- Spec delta title-identity：MODIFIED 標題逐字存在於 master spec。
- 判準鑑別力實測：以程式逐條執行 1.1 與 1.2 的全部 47 條判準（含新增的 2 條），與各分類宣稱的實作前狀態 100% 相符，無一例外。
- Signal-derived checks：`openspec/signals/` 下沒有任何 signal 具備 `check` frontmatter 欄位，本輪無 `check` 可執行。
- `.cash-skills/bin/cash validate default-spec-sync-on-archive` → `Validation passed.`

本輪 Fix Actions 修改的檔案全部位於 `openspec/changes/` 之下，依 touched 記錄規則濾除後候選集合為空，因此未呼叫 Cash CLI，也未產生警告。整個迴圈三輪皆未觸及任何受 grader immutability 保護的路徑，無 `未修復：裁判面保護` 紀錄。

## Decision

passed
