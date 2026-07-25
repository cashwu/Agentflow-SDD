# Cash Propose Review — Round 1

## Reviewer Findings

信心過濾後保留的 findings。本輪為 unseeded run 的第一輪，因此每一個存活的 Critical 與 Warning 皆為 blocking，不需要 `disposition`。

### Critical

**CR-1**
- `severity`: Critical
- `confidence`: 100
- `layer`: design
- `location`: `specs/cash-skill-workflows/spec.md` 變體專屬 frontmatter 段落；design.md `C7`；tasks.md 2.3、4.3
- `summary`: 「`.agents` 底下 12 個 `SKILL.md` frontmatter 不含三個 key」的斷言在 `.agents/skills/cash-ask/SKILL.md` 與 `.agents/skills/cash-discuss/SKILL.md` 上必然失敗，而 C7 的範圍邊界明文排除修正 cash-ask。
- `recommendation`: 擴大範圍，四個 skill 一起收斂，並處理 cash-discuss 首次產生變體差異所需的 manifest 與 divergent 清單登記。
- 來源：Reviewer A、Reviewer B（獨立提出，已合併）

**CR-2**
- `severity`: Critical
- `confidence`: 95
- `layer`: design
- `location`: design.md `D6`；proposal.md `## Motivation` A6
- `summary`: 「同組其他三個 fork 型 skill 已把這些欄位視為 Claude-only 差異處理」不成立——cash-ask 只被剝除兩個 key，`disallowedTools` 仍在。
- `recommendation`: 把參照對象更正為實際完整處理的 cash-audit 與 cash-drift，並把受影響 skill 數由二更正為四。
- 來源：Reviewer A

**CR-3**
- `severity`: Critical
- `confidence`: 95
- `layer`: design
- `location`: `specs/cash-skill-workflows/spec.md` 空 code span 判準；tasks.md 4.3
- `summary`: 「兩個相鄰且中間無任何字元的反引號」會誤判 markdown 合法的雙反引號跳脫寫法與三反引號 code fence，24 個 canonical `SKILL.md` 全數偽陽性。
- `recommendation`: 判準改為「一對相鄰反引號且前後字元都不是反引號」，並在 Example 表格固定三種形狀的判定邊界。
- 來源：Reviewer A、Reviewer B（獨立提出，已合併）

**CR-4**
- `severity`: Critical
- `confidence`: 100
- `layer`: design
- `location`: tasks.md 2.1；design.md `C1` 驗收標準；`.claude/skills/cash-propose/SKILL.md:448`、`.agents/skills/cash-propose/SKILL.md:448`
- `summary`: `## What Changes` 除 step 5 模板外還出現在第 448 行的審查過濾規則，任務 2.1 宣告的改動範圍無法達成自身的驗收條件。
- `recommendation`: 把第 448 行列為第二個編輯點並改為只引用 `## Proposed Solution`；同時說明該行位於 grader sentinel 區塊之外。
- 來源：Reviewer A、Reviewer B（獨立提出，已合併）

**CR-5**
- `severity`: Critical
- `confidence`: 80
- `layer`: design
- `location`: design.md `D1`／`C1`；`.cash-skills/lib/cash_cli/resources.py`
- `summary`: 三個型別模板同時是全專案唯一教導 `## Capabilities` 與 `## Impact` 子結構的地方，刪除後 resources.py 的裸標題模板會讓 `drift._impact_paths`、`spec_merge._paths_in_section` 與 impact 粒度提示三處靜默降級。
- `recommendation`: 把兩組子結構骨架寫入 resources.py 的模板，並在 C1 的介面／資料形狀明文列出。
- 來源：Reviewer B

### Warning

**WA-1**
- `severity`: Warning
- `confidence`: 100
- `layer`: design
- `location`: design.md `D5`／`C5` 範圍邊界；`.claude/skills/cash-drift/SKILL.md:60,93`、`.agents/skills/cash-drift/SKILL.md:49,82`
- `summary`: cash-drift 兩個變體逐字宣稱 `primary_recommendation` 是 `a single copy-pasteable command line` 並指示輸出 `Run <primary_recommendation>.`，欄位改為裸 skill 名稱後這兩處成為假敘述並產生不可執行的輸出行。
- `recommendation`: 把 cash-drift 兩個變體與其 manifest 納入範圍，同步改寫欄位描述與輸出範本。
- 來源：Reviewer A

**WA-2**
- `severity`: Warning
- `confidence`: 80
- `layer`: design
- `location`: proposal.md `## Impact`；design.md `## Risks / Trade-offs`；tasks.md 4.4
- `summary`: `scripts/cash-cli/tests/cli-checks.fish` 被宣告為 Modified，但其 `lexical-search` 與 `analyze-drift` 兩個 group 已分別對應到兩個測試檔且 `case all` 以萬用字元全收，實際上不會產生任何改動。
- `recommendation`: 從 affected-code 移除該檔，並把 Risks 中「同時修改兩個 grader 保護檔」更正為一個。
- 來源：Reviewer A

**WA-3**
- `severity`: Warning
- `confidence`: 80
- `layer`: design
- `location`: design.md `C6`；tasks.md 2.2；`.agents/skills/cash-ingest/SKILL.md:29-31,40`
- `summary`: design 從未決定 Codex 環境下 plan 檔引數的解析語意，實作者必須自行做一個 contract 級決定；且 C6 的唯一驗收無法證明「語意完整」。
- `recommendation`: 新增一條 decision 定義純路徑解析語意，並把 C6 的驗收補上內容字面值斷言。
- 來源：Reviewer A

**WA-4**
- `severity`: Warning
- `confidence`: 85
- `layer`: design
- `location`: design.md `C4` 驗收標準；`specs/cash-cli/spec.md` scope scenario
- `summary`: 「`--scope all` 的結果集合與本次變更前的預設結果集合相同」在變更完成後無法由任何測試驗證，且與 spec 對應 scenario 的表述不一致。
- `recommendation`: 改寫為可機械驗證的形式（`all` 為 `active` 的超集合且至少含一個被排除路徑），並與 spec scenario 對齊。
- 來源：Reviewer A、Reviewer B（獨立提出，已合併；採信心較高的 A 版本）

**WA-5**
- `severity`: Warning
- `confidence`: 85
- `layer`: design
- `location`: design.md `D4`／Risks；`.claude/skills/cash-ask/SKILL.md`；`scripts/cash-skills/tests/skill-checks.fish:75,179,186`
- `summary`: Risks 宣稱既有呼叫點可用 `--scope all` 還原舊行為，但三個既有呼叫點被 byte-exact 斷言、sha256 baseline 與 master spec 逐 byte 引用三重凍結，加不了旗標；排除整個 archive 會讓 cash-ask 的歷史查詢指示變成永遠不可達的死指示。
- `recommendation`: 把 `active` 的排除範圍收窄為封存 change 的 `reviews/` 目錄，使訊噪比問題解決而歷史脈絡仍可檢索；並誠實改寫 Risks。
- 來源：Reviewer B

**WA-6**
- `severity`: Warning
- `confidence`: 95
- `layer`: design
- `location`: tasks.md 4.2；`scripts/cash-cli/tests/test_analyze_drift.py:109`
- `summary`: 既有測試已有 `self.assertTrue(payload["primary_recommendation"].startswith("$cash-"))`，任務只寫「補上案例」而未要求替換這條相反斷言，照做必定紅燈。
- `recommendation`: 把任務改寫為明確的「替換而非新增」。
- 來源：Reviewer B

**WA-7**
- `severity`: Warning
- `confidence`: 80
- `layer`: design
- `location`: design.md `C4` 範圍邊界；`.cash-skills/lib/cash_cli/workspace.py:236-306`
- `summary`: `walk_text_files` 只接受單一 base 且無排除參數，事後過濾會讓被排除檔案仍被讀取與解碼、暴露面完全沒縮小；走訪層剪枝則需修改未宣告的 `workspace.py`。
- `recommendation`: 明訂採走訪層剪枝，把 `workspace.py` 納入 affected-code 與任務，並在 C4 補上被排除檔案不被開啟的可觀察行為。
- 來源：Reviewer B

### Suggestion

信心落在 50 至 79 而被降級為 Suggestion，或原即為 Suggestion 的 findings，皆不進入 blocking 集合：

- **SU-1**（Reviewer A，70）：兩條 ADDED requirement 為 master 既有 requirement 已規範的同一對象建立第二個規範來源，形狀符合 cross-artifact-definition-drift。
- **SU-2**（Reviewer A，75）：`##### Example:` 表格的涵蓋範圍超出其所屬 scenario 的斷言。
- **SU-3**（Reviewer A，65）：任務未指定良構斷言要接到哪個測試群組與 `case all`，漏接會讓斷言從未執行卻回報通過。
- **SU-4**（Reviewer A，60）：master 的 `Cash 合約測試套件` requirement 逐項列舉 skill-checks.fish 治理的 surface，新增 surface 未一併 MODIFY 該 requirement。
- **SU-5**（Reviewer A，100，`layer`: text）：proposal 的「24 個 canonical SKILL.md 有內容異動」會被讀成 24 個全改，與 design 的「5 個」不一致。
- **SU-6**（Reviewer A，100，`layer`: text）：封存 change 數量應為 19 而非 20。
- **SU-7**（Reviewer A，70）：`.agents/skills/cash-ingest/SKILL.md:45` 是同一次剝除留下的同類殘骸，不會被空 code span 斷言攔到也無任務覆蓋。
- **SU-8**（Reviewer B，70）：`--scope specs` 未定義 `openspec/specs/` 不存在時的行為，現行實作會以 execution error exit 1，與同一 requirement 的 zero-result 規定矛盾。
- **SU-9**（Reviewer B，70）：既有 lexical-search 測試全部直接呼叫 `search_payload`，沒有任何案例走 `execute()`，而驗收以 stdout 逐位元組相同與 exit code 表述。
- **SU-10**（Reviewer B，70）：並行未封存的 `harden-installer-mode-and-recovery` 同樣要提升版本並改 `skill-checks.fish` 同一行字面值，硬編版本號會使後落地者必然衝突。
- **SU-11**（Reviewer B，60）：bundle 版本歷史契約要求版本升級與全部 runtime 及 SKILL.md 異動落在同一個 first-parent commit，tasks 未宣告提交原子性。

## Rating

- post-filter 累積 blocking 集合 Critical 數：5
- post-filter 累積 blocking 集合 Warning 數：7
- 非 blocking triaged finding 數：0
- `critical_gap`: true
- `round_type`: full

理由：本輪為 unseeded run 的第一輪，全部 12 個存活的 Critical 與 Warning 皆為 blocking。其中三項（CR-1、CR-3、CR-4）是驗收標準在實作完成後仍必然失敗的自我矛盾，CR-5 與 WA-7 是會造成靜默降級而非報錯的設計缺口，WA-5 揭露緩解措施在既有凍結下不可用。累積 blocking 集合非空且含 Critical，因此不通過。

## Fix Actions

本輪修正涉及 5 個檔案：`openspec/changes/align-cli-skill-contracts/proposal.md`、`design.md`、`tasks.md`、`specs/cash-cli/spec.md`、`specs/cash-skill-workflows/spec.md`。

**流程偏差記錄**：本輪兩個 full-round reviewer 應在同一則訊息中並行派發，實際為先後派發。兩者接收相同的 artifact 與 signals context，且未把任一方的輸出餵給另一方，獨立性要求完整維持；僅並行性未達成。

**使用者決定**（fix 前以互動取得，共四項）：
1. CR-1／CR-2 採「擴大範圍，四個 skill 都清乾淨」。
2. WA-5 採「`active` 只排除封存 change 的 `reviews/`」。
3. CR-5 採「把子結構寫進 resources.py 模板」。
4. SU-10 採「不硬編版本號，改寫成相對規則」。

**逐項修正**

- CR-1、CR-2：proposal 的 `## Motivation` A6 改為列出四個受影響 skill 並更正參照對象為 cash-audit 與 cash-drift；design 的 Context 與 D6 同步更正；C7 移除「不改動 cash-ask」邊界並加入 cash-discuss 的 divergent 登記義務；`specs/cash-skill-workflows/spec.md` 新增「新產生的合法差異必須登記」段落與對應 scenario；tasks 新增 2.4 與 3.1；proposal Impact 新增 4 個路徑。
- CR-3：`specs/cash-skill-workflows/spec.md` 的空 code span 判準改為「一對相鄰反引號且前後字元都不是反引號」，新增「合法的反引號寫法不被誤判」scenario 與三種形狀的 Example；design 新增 D9；tasks 4.4 明訂判準。
- CR-4：tasks 2.1 加入第 448 行編輯點；design D1 記錄兩個連帶編輯點並說明該行位於 grader sentinel 區塊之外；`specs/cash-skill-workflows/spec.md` 明文「此禁令涵蓋全檔的每一次出現」並新增對應 scenario；proposal Non-Goals 記錄 cash-apply 同源行刻意分歧。
- CR-5：design D1 與 C1 加入子結構要求；`specs/cash-cli/spec.md` 的模板 requirement 新增子結構條款與「模板承載下游依賴的子結構」scenario；tasks 1.6 同步。
- WA-1：proposal Impact 新增 cash-drift 兩個變體與其 manifest；design D5 與 C5 加入 skill 端同步義務；`specs/cash-skill-workflows/spec.md` 新增「cash-drift 對建議欄位的描述與 CLI 輸出一致」requirement；tasks 新增 2.5。
- WA-2：proposal Impact 移除 `scripts/cash-cli/tests/cli-checks.fish`；design Risks 更正為只有一個 grader 保護檔被修改；tasks 原 4.4 的條件式交付目標移除，改由 4.6 純執行。
- WA-3：design 新增 D8 定義純路徑解析語意；C6 驗收補上內容字面值斷言；tasks 2.2 涵蓋第 40、45、53、267 四行（同時吸收 SU-7）。
- WA-4：C4 驗收改為「`all` 為 `active` 的超集合且至少含一個被排除路徑」；`specs/cash-cli/spec.md` 對應 scenario 同步（同時吸收 SU-1 之外的 Example 對齊需求）。
- WA-5：D4 改為只排除封存 `reviews/`，並記錄三重凍結導致既有呼叫點無法加旗標的事實；Risks 誠實改寫；`specs/cash-cli/spec.md` 的 scope 定義與 scenario 同步；tasks 1.4 同步。
- WA-6：tasks 4.2 改寫為明確的「替換第 109 行既有斷言而非新增」。
- WA-7：proposal Impact 新增 `.cash-skills/lib/cash_cli/workspace.py`；D4 明訂走訪層剪枝；C4 補上被排除檔案不被開啟的可觀察行為與非 UTF-8 情境；tasks 新增 1.3。

**非 blocking 的 Suggestion 處置**

以下在本輪一併吸收，因其修正成本低且與 blocking 修正共用同一段落：SU-2（Example 與 scenario 對齊）、SU-3（新增 `well-formedness` 具名群組並接入 `case all`，見 design C9 與 tasks 4.4、4.5）、SU-5 與 SU-6（計數更正為 5 與 19）、SU-7（併入 WA-3）、SU-8（`--scope specs` 目錄不存在時回空且 exit 0）、SU-9（驗收改以 subprocess 呼叫 launcher）、SU-10（D7 相對版本規則）、SU-11（tasks 4.6 提交原子性）。

以下記為 triage note，本輪不修正：

- SU-1 triage note：兩條 ADDED requirement 已各自加入一句話，明文聲明其為對應 master requirement 的細化而非第二個定義來源，並把 skill 端義務移出 `cash-cli` delta 以避免 spec-normative-scope-overreach。改為 MODIFIED 需逐位元組重寫兩條大型 master requirement，風險高於收益，留待後續 change 評估。
- SU-4 triage note：master 的 `Cash 合約測試套件` requirement 未隨新增的 skill-checks.fish surface 更新。信心 60，非 blocking。建議以後續 change 收斂該列舉，避免本次再擴大已達 25 筆的範圍。

**信心過濾的降級追溯**

- Reviewer B 的解析銳角 finding（帶值旗標吞下一個旗標、單一連字號 query）信心 45，低於 50 而被丟棄。其指出的兩個未定義行為確實存在，已在 D2 一併定義（帶值旗標後方以 `-` 開頭者視為缺值；未知旗標判準為以 `--` 開頭），此為超出過濾結果的主動改善，不計入 blocking 集合。

**修正後的機械自我檢查**

重新執行四項檢查與 signal 衍生檢查，全部通過：delta spec 的 `<!--` 與 `-->` 計數皆為 0 且無殘留 `---`；affected-code 實際 25 筆與 design 兩處宣稱一致；MODIFIED requirement 標題與 master spec 逐位元組相符；tasks 的交付目標全部涵蓋於 Impact；每條 delta requirement 皆有 backing task；每個 task 皆有可擷取的驗證目標。`cash validate align-cli-skill-contracts` 通過。

## Decision

next_round
