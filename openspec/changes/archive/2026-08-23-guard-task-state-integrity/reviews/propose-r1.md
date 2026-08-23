# Cash Propose Review — Round 1

## Reviewer Findings

### Critical

1.
- `severity`: Critical
- `confidence`: 95
- `layer`: design
- `location`: `tasks.md` 任務 2.2 ／ IC3 ／ `proposal.md` `## Impact`
- `summary`: 對齊會使 `scripts/cash-cli/tests/` 至少三個既有測試必然失敗，任務 2.2 因此不可能通過，而沒有任何任務授權修改這些測試。
- `recommendation`: 在 IC 明列必須同步更新的既有測試，並把測試檔加入 `## Impact` 與任務交付目標。
- reviewer source: Reviewer A — Adherence
- 主 agent 複核：三筆分別為 `test_creation_task_lifecycle.py` 的 `test_touched_record_preserves_existing_task_order`（fixture 寫 `Task 1`..`Task 10` 而 `tasks.md` 只有兩個 task）、同檔的 `test_legacy_import_is_validated_once_and_provenance_is_preserved`（`Change a` ≠ `1.1 Change a`）、`test_sync_archive_transaction.py` 的 `test_archive_manifest_records_touched_files`（`task_desc` 與 fixture `tasks.md` 不一致，且 `touched_digest` 斷言會因對齊而不符）。finding 成立。

2.
- `severity`: Critical
- `confidence`: 88
- `layer`: design
- `location`: `design.md` IC3 第 3 點與 `## Risks / Trade-offs` 第三項
- `summary`: 把 legacy import 排除在對齊之外不能達成其宣稱目的——匯入結果被 `ensure_touched()` 立刻落地，下一次讀取必然走既有 state 路徑並套用對齊而 fail closed，排除只把失敗延後一次呼叫。
- `recommendation`: 改為以 `legacy_import` 非 `null` 為持久判準豁免 D3 的 fail closed，只做能對上的 id 改寫。
- reviewer source: Reviewer A — Adherence 與 Reviewer B — Quality 獨立提出，依 `location + summary` 合併（A 報 `confidence: 85`、B 報 `88`，取較高值；`layer` 兩者皆 `design`）
- 主 agent 複核：`ensure_touched()` 在 `not workspace.exists(relative)` 時 `transaction.write()` 落地，確認成立。

3.
- `severity`: Critical
- `confidence`: 90
- `layer`: design
- `location`: `design.md` D1／D7；`.claude/skills/cash-commit/SKILL.md` 步驟 2；`.cash-skills/lib/cash_cli/commands/tasks.py`
- `summary`: 對齊結果在 `ensure_touched()` 與 `touched record` 兩條路徑上都不會寫回磁碟，而 `cash-commit` 直接 parse state 檔，因此 proposal `## Motivation` 指名的頭號症狀實際上沒有被修好。
- `recommendation`: 讓對齊結果在內容改變時強制落地，並更正 D1／D7 的敘述。
- reviewer source: Reviewer B — Quality（`Critical`／`85`）與 Reviewer A — Adherence（`Warning`／`90`，僅針對 D7 的敘述）依 `location + summary` 合併，取較嚴重的 `Critical` 與較高的 `confidence: 90`
- 主 agent 複核：`ensure_touched()` 在檔案存在時 `return value` 零寫入；`touched record` 的 `items = list(touched["touched"])` 為 shallow copy，就地改寫在 `updated` 與 `touched` 兩側同步可見使 `if updated != touched:` 對對齊恆為 False；`cash-commit` SKILL.md 步驟 2 明寫 `Then parse .cash-skills/state/touched/<change-name>.json`。三點全部成立。

4.
- `severity`: Critical
- `confidence`: 82
- `layer`: design
- `location`: `openspec/specs/cash-cli/spec.md` 的 `touched record 記錄 review loop 產出` vs 本變更的 `specs/cash-cli/spec.md`
- `summary`: 既有 master requirement 逐字要求 `touched record`「MUST NOT 改動任何既有 per-task 條目」且「合併結果與載入值相同時 MUST NOT 寫入」，本變更讓這兩點都不再成立，但 delta 只有 `## ADDED Requirements`，等於靜默修訂既有 requirement。
- `recommendation`: 補一個 `## MODIFIED Requirements` 條目重述該 requirement，限縮這兩句。
- reviewer source: Reviewer B — Quality
- 主 agent 複核：master spec 逐字含這兩句，確認成立。

### Warning

5.
- `severity`: Warning
- `confidence`: 85
- `layer`: design
- `location`: `proposal.md` `## Impact` ／ `tasks.md` 任務 1.2 交付目標
- `summary`: 任務要求在 `scripts/cash-cli/tests/` 建立測試案例，但該路徑既不在 `## Impact` 也不在交付目標。
- `recommendation`: 把實際會被修改的測試檔加入兩處。
- reviewer source: Reviewer A — Adherence（`90`）與 Reviewer B — Quality（`85`）合併，取 `confidence: 85`

6.
- `severity`: Warning
- `confidence`: 85
- `layer`: design
- `location`: `tasks.md` 任務 1.2 正向判準 ／ `design.md` IC3 第 3、4 點
- `summary`: 把對齊函式接到 `load_or_import_touched()` 與 `touched record` 的接線沒有任何機械判準；只定義函式而完全不呼叫的實作可通過全部判準。
- `recommendation`: 補綁定呼叫點的判準（計數與 awk 段落各一）。
- reviewer source: Reviewer A — Adherence

7.
- `severity`: Warning
- `confidence`: 85
- `layer`: design
- `location`: `tasks.md` 任務 1.2 負向守則
- `summary`: 本變更最核心的 MUST NOT（對齊不得改寫 `task_desc`）由 `existing\["task_desc"\] *=` 承擔，只綁定 `mark_task_done()` 的區域變數名，攔不住新函式內以 `item`／`entry`／索引式寫法的改寫。
- `recommendation`: 改為變數名無關的 `\["task_desc"\]\s*=[^=]`。
- reviewer source: Reviewer A — Adherence

8.
- `severity`: Warning
- `confidence`: 80
- `layer`: design
- `location`: `design.md` IC3 第 2 點 ／ `specs/cash-cli/spec.md`
- `summary`: 對齊把 `_task_entries()` 引入讀取路徑，使 `task_id_invalid` 成為 `touched ensure`／`touched record`／`archive` 的新失敗模式，而 design 與 delta spec 都未定義此情形；一份標籤重複的 `tasks.md` 會讓 `archive --no-validate` 從成功轉為失敗。
- `recommendation`: 明訂該錯誤是原樣傳播還是視同無法建立映射，並寫成 delta spec 的 scenario。
- reviewer source: Reviewer A — Adherence（`80`）與 Reviewer B — Quality（`78`）合併，取 `confidence: 80`

9.
- `severity`: Warning
- `confidence`: 80
- `layer`: design
- `location`: `design.md` IC1 第 1 點的逐字 fence
- `summary`: IC1 的逐字替換內容以 column 0 呈現，但步驟 3 的內文縮排為 3 空格；逐字插入會把該分支抽出 numbered list item 而破壞區塊結構，且全部 `rg -F` 判準對縮排不敏感、無法察覺。
- `recommendation`: fence 內容補上 3 空格基準縮排並明寫 MUST NOT 拉齊到 column 0；把一條正向判準改為含前導縮排的形式。
- reviewer source: Reviewer A — Adherence（`Warning`／`80`）與 Reviewer B — Quality（`Suggestion`／`65`）合併，取較嚴重的 `Warning` 與 `confidence: 80`

10.
- `severity`: Warning
- `confidence`: 80
- `layer`: design
- `location`: `proposal.md` `## Non-Goals` ／ `design.md` `## Risks / Trade-offs` 最末段
- `summary`: D3 的 fail closed 會在 `cash-commit` 步驟 2 與 `cash-apply` 的 `task done` 上造成硬停止，但本變更沒有為新引入的 `touched_invalid` 在任何 skill 加出路指引，而 Risks 給的唯一出路又與 `cash-archive` Guardrails 的既有措辭相牴觸。
- `recommendation`: 在 `cash-commit` 步驟 2 加復原指引並明訂該手工編輯是被允許的例外，或誠實記為已知遺留。
- reviewer source: Reviewer B — Quality

11.
- `severity`: Warning
- `confidence`: 100
- `layer`: text
- `location`: `proposal.md` `## Capabilities` → Modified Capabilities ／ `specs/cash-cli/spec.md` requirement 標題
- `summary`: proposal 宣告的 requirement 名稱為 `touched state 的 task attribution 完整性`，delta spec 實際標題是 `touched state 的 task attribution 對齊`。
- `recommendation`: 兩處統一為 delta spec 的標題。
- reviewer source: Reviewer A — Adherence
- 過濾紀錄：主 agent 依 confidence filter 重檢此 `text` finding——其修復只是把 proposal 散文的名稱對齊 delta spec 標題，不改變任何行為或 design statement，維持 `layer: text`。`confidence: 100` ≥ 80，維持 `Warning`。

### Suggestion

12.
- `severity`: Suggestion
- `confidence`: 75
- `layer`: design
- `location`: `tasks.md` 任務 1.2「行為判準」與任務 2.2
- `summary`: 行為判準把驗收整體委派給「既有的測試組織方式」，沒有任何機械判準能區分「六條案例已建立」與「一條都沒建立」。
- `recommendation`: 指定測試落點與方法名前綴，並補一條實作前 exit 1 的判準。
- reviewer source: Reviewer A — Adherence
- 過濾紀錄：原報 `Warning`／`75`，`confidence ∈ [50, 80)`，依 confidence filter 降為 `Suggestion`。

13.
- `severity`: Suggestion
- `confidence`: 75
- `layer`: design
- `location`: `design.md` D5
- `summary`: D5 斷言「touched state 有非保留條目但 `tasks.md` 不存在」不可能發生，但 `park` 會把整個 change 目錄搬到 `openspec/changes/.parked/<name>/` 而不動 touched state，legacy import 也是反例。
- `recommendation`: 刪除該推理句，並讓對齊在 active 路徑不存在時再查 parked 路徑。
- reviewer source: Reviewer B — Quality
- 過濾紀錄：原報 `Warning`／`75`，降為 `Suggestion`。

14.
- `severity`: Suggestion
- `confidence`: 70
- `layer`: design
- `location`: `design.md` IC2 第 2 點 ／ `tasks.md` 任務 1.1 正向判準
- `summary`: IC2 要求新增的失敗處置與既有三條相鄰，但唯一對應的判準是全檔 substring 比對，位置完全未被驗證。
- `recommendation`: 補步驟 5 的 awk 段落判準與相鄰性判準。
- reviewer source: Reviewer A — Adherence
- 過濾紀錄：原報 `Warning`／`70`，降為 `Suggestion`。

15.
- `severity`: Suggestion
- `confidence`: 70
- `layer`: design
- `location`: `design.md` IC2 第 3 點；`.claude/skills/cash-archive/SKILL.md` 步驟 5 vs `.claude/skills/cash-commit/SKILL.md` 6a-iii
- `summary`: IC2 禁止改動步驟 5 的 bash 範例，因此步驟 3 新設的 `--mark-tasks-complete` 在步驟 5 完全不可見，與 `cash-commit` 的 `[--mark-tasks-complete]` 範例不對稱，執行者照抄會把旗標弄丟。
- `recommendation`: 放寬 IC2，允許在 bash 區塊增加帶該旗標的一行。
- reviewer source: Reviewer B — Quality
- 過濾紀錄：原報 `Warning`／`70`，降為 `Suggestion`。

16.
- `severity`: Suggestion
- `confidence`: 62
- `layer`: design
- `location`: `openspec/specs/cash-cli/spec.md` 的 `Archive manifest 保留 touched 檔案清單`
- `summary`: `touched_digest` 對整個 touched 物件計算，對齊改變該物件因而改變 digest，而既有 requirement 要求「計算輸入與計算方式 MUST 不變」。
- `recommendation`: 在 design 明寫該句的解讀並說明為何不需 MODIFIED，或補一筆 MODIFIED。
- reviewer source: Reviewer B — Quality
- 過濾紀錄：原報 `Warning`／`62`，降為 `Suggestion`。

17.
- `severity`: Suggestion
- `confidence`: 60
- `layer`: design
- `location`: `design.md` IC3 第 1 點 ／ `tasks.md` 任務 1.2 負向判準
- `summary`: `touched record` handler 有兩處 `"review-loop"` 字面值，IC 以單數表述、負向判準只綁定其中一處，另一處可原樣留存而通過驗收。
- `recommendation`: 改為「全部字面值」並以計數判準表達。
- reviewer source: Reviewer A — Adherence

18.
- `severity`: Suggestion
- `confidence`: 55
- `layer`: design
- `location`: `tasks.md` 任務 1.0 判準
- `summary`: 第四條判準以 `!=` 表達版本前進，弱於 bundle version history contract 的「嚴格領先」；且 `$NEW` 未被定義為可執行的變數。
- `recommendation`: 補變數綁定說明並改為嚴格比較。
- reviewer source: Reviewer A — Adherence

## Rating

- post-filter cumulative blocking set Critical count: `4`
- post-filter cumulative blocking set Warning count: `7`
- 非 blocking 的 triaged finding 數：`7`
- `critical_gap`: `true`
- `round_type`: `full`

rationale：本輪是未 seeded run 的第一輪 full round，spawn 了 Reviewer A 與 Reviewer B 兩個 fresh sub-agent 並行審查，兩者收到相同 context 且獨立回報。依規則，第一輪全部通過 confidence filter 的 `Critical` 與 `Warning` 皆為 blocking。四筆 `Critical` 中有三筆是設計層級的實質缺陷——既有測試必然失敗、legacy 豁免在結構上不成立、對齊結果從不落地因而沒有修好宣稱要修的症狀——第四筆是靜默修訂既有 master requirement。主 agent 對這四筆全部以實檔與程式碼獨立複核後確認成立。七筆 `Warning` 涵蓋宣告範圍缺漏與四處判準鑑別力不足。`critical_gap` 為 `true`。七筆非 blocking finding 依規則以 triage 處理，不影響本輪決定。

## Fix Actions

**confidence filter 降級與丟棄紀錄**

- Reviewer A 的「行為判準無機械落點」（`Warning`／`75`）、Reviewer B 的「D5 park 反例」（`Warning`／`75`）、Reviewer A 的「IC2 相鄰性無判準」（`Warning`／`70`）、Reviewer B 的「步驟 5 bash 範例不對稱」（`Warning`／`70`）、Reviewer B 的「`touched_digest` 與既有 requirement」（`Warning`／`62`）五筆的 `confidence` 皆 ∈ `[50, 80)`，依 confidence filter 降為 `Suggestion`。
- Reviewer A 的「兩處 `review-loop` 字面值」（`60`）與「任務 1.0 判準弱於嚴格領先」（`55`）原即為 `Suggestion`，維持。
- 無 `confidence < 50` 的丟棄項。
- `layer` 重檢：finding 11 由 Reviewer A 標為 `text`，主 agent 確認其修復不影響行為或 design statement，維持 `text`。其餘 finding 皆為 `design`，主 agent MUST NOT 把 `design` 降為 `text`，未做任何此類重分類。
- 合併紀錄：finding 2、3、5、9 由兩位 reviewer 獨立提出，依 `location + summary` 合併；finding 3 與 9 兩位給出不同 `severity`，取較嚴重者；四筆的 `layer` 兩位皆為 `design`，無分歧。
- 本輪為 cash-propose，`introduced_by` 的 cash-apply 專屬規則不適用；第一輪亦不要求 `disposition`。

**blocking finding 的修復**

- finding 1、5：修改 `proposal.md`（`## Impact` 的 Modified 由 6 個路徑擴充為 10 個，加入 `.claude/skills/cash-commit/SKILL.md`、`.agents/skills/cash-commit/SKILL.md`、`scripts/cash-cli/tests/test_creation_task_lifecycle.py`、`scripts/cash-cli/tests/test_sync_archive_transaction.py`）、`design.md`（新增 `**IC5 — 既有測試同步**` 逐一列出三個必須更新的既有測試及其原因，並明訂 `cli-checks.fish` MUST NOT 改動；新增 `**IC6 — 新測試案例**` 要求每條 scenario 對應一個 `test_realign_` 前綴方法）、`tasks.md`（任務 1.3 的交付目標加入兩個測試檔）。
- finding 2：修改 `design.md`（新增 `**D6：legacy import 來源的 state 豁免 D3**`，以 `legacy_import` 非 `null` 為持久判準；IC4 第 2 點寫入該分支；`## Risks / Trade-offs` 新增一段說明豁免的代價）、`specs/cash-cli/spec.md`（ADDED requirement 補該規則與 `legacy 來源的 state 豁免 fail closed` scenario）。
- finding 3：修改 `design.md`（`## Context` 新增「現行寫入時機」與「消費端直接讀檔」兩段記錄 `ensure_touched()` 零寫入、`touched record` 的 shallow-copy 比較恆為 False、`cash-commit` 直接 parse state 檔三個事實；D7 整條改寫為 `**D4：對齊結果 MUST 寫回磁碟**`；IC4 第 2 點改為回傳 `tuple[dict, bool]`，第 4、5 點明訂 `ensure_touched()` 與 `touched record` 的新寫入條件）、`proposal.md`（`## Proposed Solution` 新增第 6 點）、`specs/cash-cli/spec.md`（ADDED requirement 補持久化規則與兩條落地／不落地 scenario）。
- finding 4：修改 `specs/cash-cli/spec.md`（新增 `## MODIFIED Requirements`，標題 `### Requirement: touched record 記錄 review loop 產出` 由 master spec 逐字複製，11 條既有 scenario 逐字沿用，只限縮「MUST NOT 改動任何既有 per-task 條目」與「合併結果與載入值相同時 MUST NOT 寫入」兩句並改寫「既有的 `touched ensure` 行為 MUST 不變」）、`proposal.md`（`## Capabilities` 的 `cash-cli` 說明補上該 MODIFIED）、`design.md`（IC9 明訂該 MODIFIED 的內容；`## Context` 新增一段說明為何 `Change 與 artifact lifecycle` 不需要 MODIFIED）。
- finding 6：修改 `tasks.md`（任務 1.3 正向判準新增 `test (rg -c -- '_realign_touched_attribution\(' … ; or echo 0) -ge 3` 與 `awk '/^def load_or_import_touched/,/^def ensure_touched/' … | rg -Fq -- '_realign_touched_attribution('` 兩條，把「函式被呼叫」而非僅「函式被定義」釘成判準）。
- finding 7：修改 `tasks.md`（負向守則由 `existing\["task_desc"\] *=` 放寬為變數名無關的 `\["task_desc"\]\s*=[^=]`，並加註說明為何不得綁定變數名）。
- finding 8：修改 `design.md`（D5 明訂 `_task_entries()` 拋出 `task_id_invalid` 時 MUST 捕捉並原樣回傳，理由是對齊為修復手段而非閘門、且 `--no-validate` 是使用者對該閘門的明示 opt-out；IC4 第 2 點寫入該分支；`## Risks` 明記該轉換已被排除）、`specs/cash-cli/spec.md`（ADDED requirement 補該規則與 `tasks.md 解析失敗時原樣回傳` scenario）。
- finding 9：修改 `design.md`（IC1 第 1 點的 fence 內容改為含 3 空格基準縮排、巢狀選項行 5 與 7 空格，並明寫 MUST NOT 拉齊到 column 0）、`tasks.md`（正向判準新增含 3 空格前導的 `'   - Use the **AskUserQuestion tool** to ask:'`，使縮排義務可機械比對）。
- finding 10：修改 `design.md`（新增 `**D8：新失敗模式在兩個會撞到它的 skill 都要有復原指引**`，並新增 `**IC3 — .claude/skills/cash-commit/SKILL.md 步驟 2**` 逐字指定復原指引；`## Risks` 記錄 `cash-apply` 側的不對稱及其原因）、`proposal.md`（`## Impact` 加入 `cash-commit` 兩個變體；`## Non-Goals` 明記不擴大到 `cash-apply` 及其理由）、`specs/cash-skill-workflows/spec.md`（requirement 補該義務與 `touched_invalid 有復原指引` scenario）、`tasks.md`（新增任務 1.2 交付 `cash-commit` 的編輯）。
- finding 11：修改 `proposal.md`（`## Capabilities` 的 requirement 名稱改為與 delta spec 標題逐字一致的 `touched state 的 task attribution 對齊`）。

**非 blocking finding 的處置**

- finding 12：triage note——本輪一併修復。修改 `design.md`（新增 IC6 指定方法名前綴）、`tasks.md`（正向判準新增 `rg -q -- 'def test_realign_' scripts/cash-cli/tests/test_creation_task_lifecycle.py`，並把行為判準改為「scenario 數與 `test_realign_` 方法數 MUST 相等」的可核對形式）。
- finding 13：triage note——本輪一併修復。修改 `design.md`（D5 刪除「不可能發生」的推理句，改為明列 `park` 與 legacy import 兩個反例，並要求對齊在 active 路徑不存在時再查 `openspec/changes/.parked/<name>/tasks.md`）、`specs/cash-cli/spec.md`（補 `parked change 仍能對齊` scenario）。
- finding 14：triage note——本輪一併修復。修改 `tasks.md`（段落級判準新增步驟 5 的 awk 範圍判準與 `rg -U` 相鄰性判準，使 IC2 第 3 點的相鄰義務可機械比對）。
- finding 15：triage note——本輪一併修復。修改 `design.md`（IC2 第 1 點改為 MUST 在 bash 範例增加帶 `--mark-tasks-complete` 的一行並說明理由）、`specs/cash-skill-workflows/spec.md`（補 `旗標在執行層可見` scenario）、`tasks.md`（正向判準補該行的字面值）。
- finding 16：triage note——本輪一併修復。修改 `design.md`（`## Context` 明寫對該句的解讀：計算輸入指「封存當下的 touched 物件」這個來源、計算方式指 sha256 演算法，兩者皆不變，故不需 MODIFIED；`## Risks` 補一段記錄 digest 會因對齊而改變）。
- finding 17：triage note——本輪一併修復。修改 `design.md`（IC4 第 1 點改為「全部既有字面值」並註明現有兩處）、`tasks.md`（負向判準改為計數形式 `test (rg -c -- '"review-loop"' … ; or echo 0) -eq 1`）。
- finding 18：triage note——本輪一併修復。修改 `tasks.md`（判準區塊開頭加入 `set NEW (…)` 的變數綁定說明，並新增一條以 `python3` 做嚴格 tuple 比較的判準，與 `version_greater()` 同強度）。

**post-fix mechanical self-check 結果**

- comment/annotation lint：`cash-skill-workflows` delta 的 `<!--`／`-->` 皆為 `0`。`cash-cli` delta 初次自檢為 `1`／`1`——從 master spec 逐字複製 MODIFIED 的 scenario 時把生成的 `<!-- @trace … -->` 區塊一併帶入。trace 由 `spec_merge.py` 於合併時產生，delta MUST NOT 自帶，已移除；移除後兩份 delta 皆為 `0`／`0`，且無 stray `---`。
- count-consistency：`tasks.md` 宣稱的「依 IC4 六點施作」與 `design.md` IC4 實際條目數（`6`）相符；IC1–IC10 依序無空洞。初次自檢時 `tasks.md` 尚寫「依 IC3 六點」而當時 IC3 實際 5 點，已於 artifact 建立階段修正。
- identifier cross-grep：`_RESERVED_TASK_ID`、`_realign_touched_attribution`、`ensure_touched`、`legacy_import`、`task_id_invalid`、`touched_invalid`、`--mark-tasks-complete`、`test_realign_` 在 design、tasks、specs、proposal 四份 artifact 中的拼寫與語意一致；IC 編號的全部交叉引用（tasks 對 IC1／IC3／IC4／IC7／IC8，design 內部對 D2／D3／D5／D6／D7）皆指向正確條目。
- spec delta title-identity：`## MODIFIED Requirements` 下的 `### Requirement: touched record 記錄 review loop 產出` 與 `openspec/specs/cash-cli/spec.md` 逐位元相符；無 `## REMOVED` 或 `## RENAMED` 條目。
- signal-derived checks：`openspec/signals/` 下無任何帶 `check` frontmatter 欄位的 signal，全部落入 best-effort 判斷分支，無 `範圍外 check 失敗` 與 fallback 紀錄。
- self-check 額外抓到並修正的缺陷：（a）新增任務原以 `1.1b` 為標籤，而 `_TASK_LABEL` 只接受純數字標籤，`validate` 以 `task_syntax_invalid` 失敗，已重新編號為 `1.2` 並把後續任務順延為 `1.3`、`1.4`，同時更新全部交叉引用；（b）任務 1.2 的段落級判準 awk 起點原寫 `2. **Ensure Cash touched state**`，與實檔標題 `2. **Read tracking file**` 不符會使範圍為空而淪為空真，已依實檔修正並實測範圍為 32 行；（c）兩條 count 判準寫成 `test (rg -c …) -ge N`，在零命中時 `rg -c` 不輸出且 exit 1，命令替換為空會使 `test` 以語法錯誤中止而非乾淨失敗，已改為 `test (rg -c … ; or echo 0) -ge N` 並加註說明。

**fix 後的重新驗證**

- `.cash-skills/bin/cash validate guard-task-state-integrity` 通過。
- `tasks.md` 中 21 條可直接執行的 `rg` 判準對現行（實作前）工作樹逐條執行，極性全部符合其所屬區塊的宣告（正向 exit 1、負向 exit 0、保留守則 exit 0、負向守則 exit 1），`0` 筆不符。
- 五條段落級判準的實作前狀態逐條確認：步驟 3 `AskUserQuestion` exit 1、步驟 3 `Proceed if user confirms` exit 0、步驟 5 `tasks_incomplete` exit 1、步驟 5 相鄰性 exit 1、`cash-commit` 步驟 2 `touched_invalid` exit 1——全部與實作後的宣告方向相反，具鑑別力；`cash-commit` 步驟 2 的 awk 範圍實測 32 行、非空真。
- 兩條 count 判準以 fish 實測，修正後在實作前乾淨回傳 exit 1（非語法錯誤）。
- `.cash-skills/bin/cash analyze guard-task-state-integrity` 無 `Critical`。

**本輪 Fix Actions 修改的檔案（`openspec/changes/` 之外）**

- 無。本輪全部修改都落在 `openspec/changes/guard-task-state-integrity/` 之下，濾除該前綴後候選集合為空，因此不呼叫 `"$cash_cli" touched ensure` 與 `"$cash_cli" touched record`，亦不產生警告。

無 `未修復：裁判面保護` 紀錄；本輪未修改任何裁判面保護路徑下的檔案。

## Decision

next_round
