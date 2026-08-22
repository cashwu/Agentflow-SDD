# Cash Propose Review — Round 2

本輪為本次執行的第二輪，依位置推導 `round_type: micro`，spawn 一位全新的 `Reviewer V — Verification`，範圍限於：對累積 blocking 集合的每名成員回傳明確裁定、檢查修正傳播是否完整、查驗修正是否引入新缺陷。Reviewer V 收到 `reviews/propose-r1.md` 全文、四份 artifact 路徑、round 1 的累積 blocking 集合成員清單，以及相關的 `open` signals。本 change 無 accepted-risks ledger。

## Reviewer Findings

### 累積 blocking 集合成員裁定

Reviewer V 對六名成員逐一回傳裁定，全部為 `resolved`，每項均附其實際讀到的檔案位置與引文。

| 成員 | 裁定 | 驗證依據 | 對應修正 |
|---|---|---|---|
| C1 完成回報義務對 `cash-commit` 不可實作 | resolved | `design.md` D5、IC2 第 4 點的 `**Spec sync:**` 追加、delta ADDED 本文與 `cash-commit 的封存子流程套用同一判定並記錄結果` scenario、`tasks.md` 對應正向判準實跑為紅 | round 1 Fix Actions 的 C1 條目 |
| C2 6a-iii 納入條件恆真造成迴歸 | resolved | `design.md` D4 逐字寫入禁止「封存未帶 `--skip-specs`」的理由、IC2 第 3 點釘住 `only when 6a-ii recorded the outcome `synced``、delta MODIFIED 本文與新增負向 scenario | round 1 Fix Actions 的 C2 條目 |
| C3 Optional flags 措辭與不推論規則矛盾 | resolved | IC1 第 7 點保護範圍已縮小、第 4 點要求 `(for tooling/doc-only changes)` 消失；`rg -ni 'tooling\|doc-only'` 對該檔只命中該行，確認為唯一衝突點 | round 1 Fix Actions 的 C3 條目 |
| W1 tasks 判準對契約覆蓋不足 | resolved | D8、IC1／IC2 第 2 點的逐字整段內容、tasks 四類判準；實跑 19 條正向全為紅、11 條負向與保留守則符合宣稱 | round 1 Fix Actions 的 W1 條目 |
| W2 design Risks 緩解敘述不成立 | resolved | `## Risks / Trade-offs` 全段改寫，三項事實（`.gitignore` 第 3 行、步驟 2／3 為條件式、`cash-apply` 既有警告）逐一查證屬實；D3 明文禁止舊緩解敘述 | round 1 Fix Actions 的 W2 條目 |
| W3 兩條 MUST 交集衝突無優先序 | resolved | delta ADDED 本文的「此條優先」、D2 的唯一解敘述、新增交集 scenario | round 1 Fix Actions 的 W3 條目 |

六名成員全部經 Reviewer V 明確裁定為 resolved，依累積 blocking 集合規則以「verified resolution」離開集合。

### Warning

**F1 — 三值判定結果在「無 delta specs ＋ 明確跳過」重疊，被釘進 SKILL.md 的逐字文字無排序語意**

- `severity`: Warning
- `confidence`: 100
- `layer`: design
- `location`: `design.md` IC1 第 2 點逐字內容、IC2 第 2 點逐字內容；`specs/cash-skill-workflows/spec.md` ADDED 本文
- `summary`: `skipped`（帶了旗標）與 `no delta specs`（沒有 delta specs）在「沒有 delta specs 且使用者明確要求跳過」同時成立；該情境由 delta 自身的 `明確要求跳過優先於沒有 delta specs 的預設` scenario 宣告為可達，但 `Record the resolved outcome as exactly one of …` 沒有排序語意，runtime agent 讀不到 scenario，若記為 `no delta specs` 就會走 `**Output On Success (No Delta Specs)**` 模板，違反 ADDED 本文「跳過時 MUST 標明該跳過出於使用者的明確要求」。
- `recommendation`: 兩處逐字內容改為有序判定；ADDED 本文的三值定義加同一句優先序；tasks 對應正向判準同步改字串；步驟 6 既有的 `Spec sync status (synced / sync skipped / no delta specs)` 納入 IC1，消除 `sync skipped` 與 `skipped` 兩套名稱。
- `disposition`: fix-introduced
- `introduced_by`: round 1 Fix Actions 的 C2 條目（導入三值判定結果 `synced`／`skipped`／`no delta specs`，寫入 D4、IC1 第 2 點、IC2 第 2 點）
- reviewer source: Reviewer V（Warning／75）；主 agent 複驗後校正為 100，證據見 `## Fix Actions` 的 V-F1。

**F2 — D5 的「三個 Output 模板恰好對應三個判定結果」在事實上不成立**

- `severity`: Warning
- `confidence`: 100
- `layer`: design
- `location`: `design.md` D5 第一個 bullet、IC1 第 8 點（修正前）；`.claude/skills/cash-archive/SKILL.md:103-145`
- `summary`: 模板選擇的變數是「有沒有 warnings」，不是判定結果；`**Output On Success With Warnings**` 的 `**Specs:**` 行硬寫為 `Sync skipped (user chose to skip)`。因此「判定結果為 `synced` 但有未完成 artifact 或 task」這個可達組合無模板可用——用無 warnings 模板會丟掉 warnings，用 warnings 模板會把 `synced` 誤報為跳過，違反 ADDED 本文「`cash-archive` 的完成摘要 MUST 回報該判定結果」。D5 以此不成立的一對一對應推導出「三個模板 MUST NOT 改動」，等於把 C1 在 `cash-commit` 端解掉的「MUST 無承載面」問題搬到 `cash-archive` 端。
- `recommendation`: D5 改為事實敘述；IC1 把 warnings 模板的 `**Specs:**` 行與跳過警告行改為依判定結果填值的佔位形式；tasks 的兩條相關保留守則改為負向判準，並補新佔位字串的正向判準。
- `disposition`: fix-introduced
- `introduced_by`: round 1 Fix Actions 的 C1 條目（design 新增 D5 說明 `cash-archive` 三個 Output 模板恰好對應三個判定結果因而不需改動）
- reviewer source: Reviewer V（Warning／75）；主 agent 複驗後校正為 100，證據見 `## Fix Actions` 的 V-F2。

### Suggestion

- **F3**（`confidence` 50、`layer` design、`disposition` fix-introduced、`introduced_by` round 1 Fix Actions 的 W1 條目）— IC1 第 3 點宣告「步驟 4 段落 MUST NOT 殘留任何 ask／prompt／confirm 語意的散文句」，但 IC1 第 2 點強制寫入的逐字內容本身含 `without asking the user`、`the user asked to skip`、`do NOT ask the user to choose` 三句，兩點字面互斥；`tasks.md` 已改用 `AskUserQuestion` 段落檢查，但 IC 這一層仍留著一條沒人套用且會誤導的判準字串。
- **F4**（`confidence` 50、`layer` text、`disposition` new）— `proposal.md` `### Modified Capabilities` 仍以更名前的「預設同步」描述該 requirement，是四份 artifact 中唯一還用舊框架描述它的位置。
- **F5**（`confidence` 50、`layer` design、`disposition` new）— ADDED 本文以「限於」兩種形式規範兩個入口，但只要求 `cash-archive` 的 `**Input**` 承認 `--skip-specs`，IC2 無對等條款，`cash-commit` 側兩種形式只剩一種可用；design 的第三條風險也只點名 IC1 第 1 點，對 `cash-commit` 的同型風險無敘述。

### 未計為 finding 的其他 Reviewer V 輸出

Reviewer V 額外查證了 `commands/archive.py` 的 `"specs_synced": not skip_specs` 與步驟 2a 的 `master_digests` digest 比對保護，確認與 proposal `## Non-Goals` 第 4 條一致；並確認 `scripts/cash-skills/tests/skill-checks.fish` 的外部相依中 `rg` 是本機唯一缺口，`fish` 與 `python3` 皆在，因此 IC5 與 task 2.1 的「先安裝 `rg`」處置對該套件足夠。兩者皆非缺陷。

## Rating

- post-filter 累積 blocking 集合 Critical 數：0
- post-filter 累積 blocking 集合 Warning 數：2（F1、F2）
- 非 blocking triaged finding 數：3（F3、F4、F5）
- `critical_gap`: false
- `round_type`: micro

rationale：round 1 的六名成員全部經 Reviewer V 明確裁定為 resolved 並以 verified resolution 離開集合，三個 Critical 因此清空，`critical_gap` 轉為 false。但本輪新發現兩個 `fix-introduced` 的 Warning：F1 與 F2 都是 round 1 修正動作自身引入的缺陷，且兩者各自可由本 change ADDED requirement 的一條 MUST 直接證明違反，依 confidence rubric 屬「直接證據證明違反」。依規則 `fix-introduced` 的存活 Warning 為 blocking，因此累積 blocking 集合非空，本輪決策為 `next_round`。

## Fix Actions

### 主 agent 複驗與 confidence 校正

- **V-F1（F1）**：讀本 change 自身的 IC1 第 2 點與 IC2 第 2 點逐字內容，確認 `Record the resolved outcome as exactly one of …` 無任何排序語意，而 `skipped` 與 `no delta specs` 的定義在交集情境同時成立；對照 delta ADDED 本文「跳過時 MUST 標明該跳過出於使用者的明確要求」，違反可由該 MUST 直接證明。校正為 100。
- **V-F2（F2）**：讀 `.claude/skills/cash-archive/SKILL.md` 三個 Output 模板，確認 `**Output On Success With Warnings**` 的 `**Specs:**` 行為硬寫的 `Sync skipped (user chose to skip)`、Warnings 清單同樣硬寫跳過；模板選擇條件為「有無 warnings」。對照 delta ADDED 本文「`cash-archive` 的完成摘要 MUST 回報該判定結果」，`synced` ＋ 有 warnings 的組合無正確輸出，違反可由該 MUST 直接證明。校正為 100。

兩項校正皆為向上調整，方向保守；無任何 finding 被下調或由 `design` 重分類為 `text`。

### 修正動作

- **F1** — 修改 `design.md`、`specs/cash-skill-workflows/spec.md`、`tasks.md`。D4 補上判定順序與其必要性理由；IC1 第 2 點與 IC2 第 2 點的逐字內容改為 `Record the resolved outcome by evaluating in order: `skipped` (the flag is set), then `synced` (delta specs exist and the flag is not set), then `no delta specs` (no delta specs and the flag is not set)`；ADDED 本文的三值定義同步改為依序判定；`明確要求跳過優先於沒有 delta specs 的預設` scenario 的 THEN 補為「依判定順序將結果記為 `skipped` 而非 `no delta specs`」並補完成摘要義務。IC1 新增第 8 點要求步驟 6 的 `- Spec sync status (synced / sync skipped / no delta specs)` 改用三個判定結果名稱並明訂各自對應的 `**Specs:**` 字串，消除 `sync skipped` 與 `skipped` 兩套名稱。tasks 1.1／1.2 的對應正向判準同步改為新字串。

- **F2** — 修改 `design.md`、`proposal.md`、`tasks.md`。D5 第一個 bullet 改為事實敘述：模板由 warnings 有無選擇，並具名指出 `synced` ＋ 有 warnings 的組合無模板可用。原 IC1 第 8 點拆為第 8 點（步驟 6 摘要詞彙）與第 9 點（模板處置）：第 9 點要求 warnings 模板的 `**Specs:** Sync skipped (user chose to skip)` 改為 `**Specs:** <✓ Synced to main specs | Sync skipped (explicitly requested by the user) | No delta specs>`，其 `- Delta spec sync was skipped (user chose to skip)` 改為 `- Delta spec sync was skipped (explicitly requested by the user) — include only when the outcome is `skipped``，另外三個 Output 模板與 Guardrails 維持不得改動。proposal `## Proposed Solution` 第 4 點同步改寫。tasks 1.1 把 `**Specs:** Sync skipped (user chose to skip)`、`- Delta spec sync was skipped (user chose to skip)`、`- Spec sync status (synced / sync skipped / no delta specs)` 三條由保留守則移入負向判準，新增三條佔位字串的正向判準，並把 `**Specs:** ✓ Synced to main specs` 加入保留守則。

- **F3** — 修改 `design.md`。IC1 第 3 點改為具名式，與 IC2 第 6 點的寫法對齊：步驟 4 段落 MUST NOT 含 `AskUserQuestion`，MUST NOT 殘留 `If delta specs exist, ask whether to sync them.` 與三個選項 bullet，並明文第 2 點逐字內容中的禁止式措辭不在此限。D1 對應句同步改寫。

- **F4** — 修改 `proposal.md`。`### Modified Capabilities` 改為指名 `封存前的 delta spec 同步判定` requirement。

- **F5** — 修改 `design.md`、`specs/cash-skill-workflows/spec.md`。ADDED 本文的形式規定拆為 per-entry：`cash-archive` 兩種形式、`cash-commit` 的 archive-first 子流程只有 session 內明說一種。D2 以同一措辭重述並說明理由（該子流程沒有自己的 invocation 可掛旗標）。`## Risks / Trade-offs` 第三條改寫為「跳過分支的可到達性在兩個入口不對稱」，明說 `cash-commit` 側可到達性較低、未提供緩解、需要明示旗標者改走 `cash-archive`。

### 修正後重跑的驗證

- 註解／annotation lint：四份 artifact 的 `<!--`／`-->` 計數皆為 0／0。
- 計數一致性：`design.md` IC1 現為 9 點、IC2 為 6 點，`tasks.md` 1.1 已同步改為「依 IC1 的九點」、1.2 維持「依 IC2 的六點」。
- 識別字交叉比對：`tasks.md` 的 45 條 `rg -Fq` 字面值（42 條相異）逐條比對 `design.md`，除 8 條指涉既有 SKILL.md 內容的負向與保留守則字面值外，全部逐字存在於 IC 中；該 8 條逐條確認在現行 `.claude` 檔案中存在。
- Spec delta title-identity：MODIFIED 標題逐字存在於 master spec；ADDED 標題在 master spec 中不存在。
- 判準鑑別力實測：以程式逐條執行 1.1 與 1.2 的全部正向、負向與保留守則判準，對現行 `.claude` 檔案的實際存在狀態與各分類宣稱的實作前狀態 100% 相符，無一例外。
- Signal-derived checks：`openspec/signals/` 下沒有任何 signal 具備 `check` frontmatter 欄位，本輪無 `check` 可執行。
- `.cash-skills/bin/cash validate default-spec-sync-on-archive` → `Validation passed.`

本輪 Fix Actions 修改的檔案全部位於 `openspec/changes/` 之下，依 touched 記錄規則濾除後候選集合為空，因此未呼叫 Cash CLI，也未產生警告。

## Decision

next_round

F1 與 F2 兩名 `fix-introduced` 的 blocking Warning 已記錄具名修正並列出修改檔案，三個非 blocking 的 Suggestion 也一併修畢；但成員只能經由後續 reviewer 的明確 resolved 裁定離開累積 blocking 集合。下一輪為本次執行的第三輪，依位置推導為 `micro`，由一位全新的 `Reviewer V — Verification` 對 F1、F2 逐一回傳裁定，並查驗本輪修正是否再引入新缺陷。
