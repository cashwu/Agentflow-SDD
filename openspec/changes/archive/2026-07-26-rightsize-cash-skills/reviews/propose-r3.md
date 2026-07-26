# Cash Propose Review — Round 3

## Reviewer Findings

本輪為 micro round，由單一 Reviewer V 執行 delta 驗證。

### 累積 blocking 集合成員的判定

進入本輪時集合中僅有一個成員 **V1**（Critical，`fix-introduced`）。

- **V1**：`resolved`。Reviewer V 證據——delta spec 第 53 行已改為「本 requirement 的判準是出現次數至多為一，不是該規則的所在位置。該規則 SHOULD 置於…但位置 MUST NOT 作為規範條件」，`design.md` D3 同步，`tasks.md` 1.5／1.7／1.10 三處措辭一致且無殘留強制文字；`#### Scenario: 已為單一陳述的 skill 不被要求改動` 的 `**AND** 不因該陳述所在位置而失敗` 與豁免句相容。主 agent 覆核：全 artifacts grep 確認無任何把位置寫成 MUST／SHALL 的句子。V1 以 verified resolution 離開累積 blocking 集合。

### 本輪新 findings（過濾前 5 條）

**W1** — `severity: Warning`｜`confidence: 100`｜`layer: text`｜`disposition: fix-introduced`
- `introduced_by`: `propose-r2.md` `## Fix Actions` →「修正 blocking finding」→ **V1**
- `location`: `design.md` `### D3`
- `summary`: D3 把 `cash-propose` 的 fallback 位置寫為 `:302`，但實檔 `:302` 是 accepted-risks ledger 的 `If interaction is unavailable, do not write the entry and keep the finding surviving`；該 skill 真正的 fallback 陳述在 `:518`。
- `recommendation`: 改為 `:518`。`design.md` `## Context` 已宣告「實作時 MUST 以這些位置為準」，錯誤行號會把實作者導向 review-loop 的 ledger 規則。
- 主 agent 覆核：實檔確認 `:302` 為 ledger 規則、`:518` 為 `- If **AskUserQuestion tool** is not available, ask the same questions as plain text and wait for the user's response`。成立。此錯誤源於主 agent 在 Round 2 以 `unavailable` 為關鍵字取首個匹配行，取到了 ledger 行。

**W2** — `severity: Warning`｜`confidence: 75`｜`layer: design`｜`disposition: fix-introduced`
- `introduced_by`: `propose-r2.md` `## Fix Actions` →「修正非 blocking triage 項」→ **V2**
- `location`: delta spec `#### Scenario: 承載額外契約的 fallback 不被併入也不計入`
- `summary`: 該 scenario 的 WHEN 是「skill 回歸套件執行」，但第三條 AND「該例外在測試檔中以註解說明排除理由」是測試檔的靜態屬性，套件執行本身無從驗證，使該驗收標準成為宣稱要驗證卻無從驗證的條款。

**W3** — `severity: Warning`｜`confidence: 65`｜`layer: design`｜`disposition: new`
- `location`: delta spec fallback requirement 主句；`design.md` `### D3`
- `summary`: 位置條件降級後，主句仍寫「SHALL 在檔案層級陳述至多一次」，而被明列為已滿足的 `cash-verify:45` 實測是嵌在步驟句內的行內陳述，並非檔案層級陳述，構成與 V1 同型但較弱的殘留張力。

**W4** — `severity: Warning`｜`confidence: 60`｜`layer: design`｜`disposition: new`
- `location`: `design.md` `### D3`、`### C1`；`tasks.md` 3.2
- `summary`: D3 宣稱「本 repo 目前唯一這樣的位置是 `cash-ingest:261`」，但 `cash-apply:485` 與 `cash-propose:302` 也是互動不可用時規定不同控制流的規則；由於 3.2 要求斷言涵蓋泛稱措辭，以 unavailable 為主軸的樣式會把這兩行計入，使 `cash-propose` 計數為 2 而失敗——而 tasks 1.9 明訂 propose 的 fallback MUST NOT 改動，形成無解衝突。
- 主 agent 覆核：實檔確認 `cash-apply:485` 與 `cash-propose:302` 內容相同且皆為 accepted-risks ledger 規則。成立。

**W5** — `severity: Suggestion`｜`confidence: 50`｜`layer: design`｜`disposition: new`
- `location`: delta spec `#### Scenario: 重新引入風格禁令列舉使套件失敗`；`tasks.md` 3.1
- `summary`: scenario 以一般化措辭宣告「重新加入語法層級的風格禁令列舉」會使套件失敗，但 3.1 的機械支撐只是對具名字面值做 `assert_absent`，任何改寫措辭的新禁令都不會被攔截，scenario 涵蓋範圍大於斷言能力。

## Rating

- 過濾後累積 blocking 集合 Critical 數：**0**
- 過濾後累積 blocking 集合 Warning 數：**1**（W1）
- 非 blocking 已 triage 的 finding 數：**4**（W2、W3、W4、W5）
- `critical_gap`: `false`
- `round_type`: `micro`

理由：V1 取得 verified resolution 並離開累積 blocking 集合，集合一度清空。本輪新增 5 條 findings，經信心過濾器處理後：W1（`100`）維持 `Warning`；W2（`75`）、W3（`65`）、W4（`60`）落在 `[50, 80)` 區間降級為 `Suggestion`；W5（`50`）維持 `Suggestion`。降級後僅 W1 仍為 `Warning`，且其 disposition 為 `fix-introduced`，因而是唯一的 blocking 成員。過濾後累積 blocking 集合不含 `Critical`，`critical_gap` 為 `false`，但仍含一個 blocking `Warning`，故本輪 MUST NOT 通過。

## Fix Actions

### 修正 blocking finding

- **W1**（Warning，`fix-introduced`）：`design.md` D3 的 `cash-propose`（`:45`／`:302`）更正為（`:45`／`:518`）。修改檔案：`openspec/changes/rightsize-cash-skills/design.md`。

### 修正非 blocking triage 項

以下四條依規則為非 blocking，其必要動作為 triage 註記；主 agent 判斷四條皆為真實缺陷且修正成本低，一併修正並記錄。

- **W2**（Suggestion，`fix-introduced`）：把「該例外在測試檔中以註解說明排除理由」從 `#### Scenario: 承載額外契約的 fallback 不被併入也不計入` 的 AND 中移除，改以獨立的 `#### Scenario: 具名例外在測試檔中可審閱` 表述，其 WHEN 為「檢查 `scripts/cash-skills/tests/skill-checks.fish` 中的 fallback 計數例外清單」，與待驗證的對象一致。修改檔案：`specs/cash-skill-workflows/spec.md`。
- **W3**（Suggestion，`new`）：delta spec 主句由「SHALL 在檔案層級陳述至多一次」改為「SHALL 全檔至多陳述一次…MUST NOT 於多個決策點分別覆述」，並明文「該單一陳述得為獨立的全域規則，亦得內嵌於唯一使用該工具的步驟句中；兩種形式皆滿足本 requirement」，使 `cash-verify:45` 的行內形狀無爭議地滿足。`design.md` D3 主句與標題同步（標題由「收斂為檔案層級的單一全域規則」改為「收斂為全檔單一陳述」）。修改檔案：`specs/cash-skill-workflows/spec.md`、`design.md`。
- **W4**（Suggestion，`new`）：在 `design.md` D3 新增「`fallback 陳述` 的判定條件」段——一段文字須同時滿足 (a) 條件為該工具不可用、(b) 替代作法是以純文字提出相同問題並等待，才計為 fallback 陳述；只滿足 (a) 者不計入，並具名 `cash-apply:485` 與 `cash-propose:302` 為此類。C1 範圍邊界新增這兩處為 MUST NOT 併入或刪除。delta spec 新增對應的判定條件段、一條 `#### Scenario: 只滿足不可用條件而無純文字詢問子句者不計入` 與一列 Example。`tasks.md` 3.2 的比對要求與驗證目標同步，新增「`cash-propose` 保留 `:302` 時通過」。同時把 D3 的「本 repo 目前唯一這樣的位置」改為「目前已確認需具名排除的位置」，並加註該清單為已確認者而非窮舉、實作時發現同型位置 MUST 一併具名排除並記 `deviation`，以消除與 `propose-r2.md` 自身 triage 註記的互相否定。修改檔案：`design.md`、`specs/cash-skill-workflows/spec.md`、`tasks.md`。
- **W5**（Suggestion，`new`）：`#### Scenario: 重新引入風格禁令列舉使套件失敗` 的 GIVEN 收斂為「重新加入本 requirement 散文段所列舉的具名風格禁令字面值」，使其外延與 `tasks.md` 3.1 的 `assert_absent` 清單一一對應。修改檔案：`specs/cash-skill-workflows/spec.md`。

### 修正後的每輪前機械自我檢查

- 註記／annotation lint：delta spec 的 `<!--` 與 `-->` 各 0 次，平衡。
- Spec delta 標題身分檢查：delta spec 僅含 `## ADDED Requirements`，本項無適用對象。
- 數量一致性掃描 — **已修正**：`design.md` D4 原寫「新增兩條 requirement，並為兩者各建立斷言」與「兩條斷言 MUST 由既有的具名測試群組承載」，但該節在 Round 2 已增為三個斷言項目（實作紀律內容、fallback 單一表述、段落名稱一致）。更正為「建立三條斷言承載它們」與「三條斷言 MUST 由既有的具名測試群組承載」。修改檔案：`design.md`。
- Identifier cross-grep：全 artifacts 已無 `檔案層級陳述` 與 `兩條斷言` 字樣；`:302` 僅出現於 `design.md` 的 accepted-risks ledger 具名排除說明與 `tasks.md` 3.2 的對應說明，語意一致；`:518` 為 `cash-propose` 的 fallback 位置，僅出現於 D3 的降級論證。
- Signal-derived checks：`openspec/signals/` 之下仍無 `status: open` 且含 `check` frontmatter 欄位的 signal，本項無指令可執行。
- 驗證重跑：`"$cash_cli" validate rightsize-cash-skills` 通過。

## Decision

next_round
