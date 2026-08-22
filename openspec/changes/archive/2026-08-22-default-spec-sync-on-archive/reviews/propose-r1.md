# Cash Propose Review — Round 1

本輪為本次執行的第一輪，`round_type: full`，spawn 兩位全新的平行 reviewer sub-agents（Reviewer A — Adherence、Reviewer B — Quality），各自獨立收到相同情境。未 seeded，因此每個通過過濾器的 `Critical` 與 `Warning` 皆為 blocking，無需 `disposition` 欄位。

## Reviewer Findings

彙整以 `location + summary` 去重；兩位 reviewer 獨立提出同一 finding 者已合併，合併後取較高 severity 與較高 confidence。

### Critical

**C1 — 完成回報義務對 `cash-commit` 不可實作**

- `severity`: Critical
- `confidence`: 90
- `layer`: design
- `location`: `specs/cash-skill-workflows/spec.md` ADDED requirement 本文；`design.md` D5、IC2；`tasks.md` 1.2
- `summary`: ADDED requirement 要求「兩者的完成摘要 MUST 回報本次封存是同步或跳過」，但 `cash-commit` 沒有回報 spec sync 狀態的完成摘要，而 D5／IC2 又禁止改動任何模板，該 MUST 在實作完成時必然不成立且無 backing task。
- `recommendation`: 依兩個入口既有的輸出面分配回報義務；`cash-commit` 改由 archive-first 的 updated commit plan 承擔，並在 IC2 開放一行模板追加。
- reviewer source: Reviewer A（F1，Critical／90）∪ Reviewer B（F3，Warning／75）

**C2 — 6a-iii 新納入條件在無 delta specs 時恆真，構成新引入的迴歸**

- `severity`: Critical
- `confidence`: 100
- `layer`: design
- `location`: `specs/cash-skill-workflows/spec.md` MODIFIED requirement 本文與其 sync 納入 scenario；`design.md` D4、IC2；對應 `.claude/skills/cash-commit/SKILL.md:214`
- `summary`: 把納入條件從「使用者明確選擇 sync」改為「封存未帶 `--skip-specs`」，會讓沒有 delta specs 的封存也符合條件，把無關的 dirty `openspec/specs/` 路徑掃進 archive-first 提交集合；舊條件在該情形下為 false，故此為本變更新引入的迴歸。
- `recommendation`: 改為三值判定結果，只有 `synced` 才納入 `openspec/specs/` 路徑。
- reviewer source: Reviewer B（Critical／75）；主 agent 依 confidence rubric「直接證據證明違反」複驗後校正為 100，證據見 `## Fix Actions` 的 V2。

**C3 — Optional flags 措辭與不推論規則直接矛盾，且 IC1 明文保護該行不得改動**

- `severity`: Critical
- `confidence`: 100
- `layer`: design
- `location`: `.claude/skills/cash-archive/SKILL.md:87`；`design.md` IC1；`specs/cash-skill-workflows/spec.md` 不推論 scenario
- `summary`: 步驟 4 改為判定段落後，`--skip-specs — skip delta spec application (for tooling/doc-only changes)` 成為檔內唯一還在以 change 性質描述旗標使用時機的句子，與新 requirement 的「MUST NOT 從 change 性質推論」矛盾；IC1 原本把整份 Optional flags 清單列為 MUST NOT 改動，等於把矛盾寫進 Implementation Contract。
- `recommendation`: 縮小 IC1 的保護範圍到 `--mark-tasks-complete` 與 `--no-validate`，改寫 `--skip-specs` 說明指向步驟 4；一併處理步驟 5 的殘留措辭 `adding the selected flags`。
- reviewer source: Reviewer B（Critical／75）；主 agent 複驗後校正為 100，證據見 `## Fix Actions` 的 V3。

### Warning

**W1 — tasks 判準對契約覆蓋不足**

- `severity`: Warning
- `confidence`: 90
- `layer`: design
- `location`: `tasks.md` 1.1 與 1.2 的全部判準
- `summary`: 判準只斷言舊機制的字面值被移除，對「預設不帶旗標」「僅在明確要求時帶旗標」「不得從間接訊號推論」等全部正向契約零覆蓋；且步驟 4 的散文提問 `If delta specs exist, ask whether to sync them.` 沒有任何 absence 斷言，一個只改標題、刪 bullet 卻保留散文提問的實作會通過全部判準。
- `recommendation`: 在 IC1／IC2 逐字釘住要寫入的判定句，tasks 對每一句加正向判準、對每一個被移除的舊字面值加負向判準。
- reviewer source: Reviewer A（F2，Warning／90）∪ Reviewer B（F4，Warning／75）

**W2 — design Risks 的緩解敘述不成立**

- `severity`: Warning
- `confidence`: 100
- `layer`: design
- `location`: `design.md` `## Risks / Trade-offs` 第一、二條；D3
- `summary`: 「步驟 2、步驟 3 的確認仍在」在常見路徑上不成立——那兩處只在 artifact 或 task 未完成時觸發；第二條「緩解方式是使用者明確要求跳過」是循環論證，且未點名 touched state 不可由 git 還原。
- `recommendation`: 改寫為事實敘述，明說常見路徑零確認、`.cash-skills/state/` 被 gitignore 因而不可還原、CLI preflight 只覆蓋 parse 與 identity。
- reviewer source: Reviewer B（Warning／75）；主 agent 複驗後校正為 100，證據見 `## Fix Actions` 的 V5。

**W3 — ADDED requirement 兩條 MUST 在交集情境衝突且無優先序**

- `severity`: Warning
- `confidence`: 100
- `layer`: design
- `location`: `specs/cash-skill-workflows/spec.md` ADDED requirement 本文；`design.md` IC1
- `summary`: 「無 delta specs 時 MUST NOT 帶 `--skip-specs`」與「明確要求跳過時 MUST 帶上 `--skip-specs`」在「無 delta specs ＋ 明確要求跳過」的交集同時指向同一決定，requirement 未定義優先序，也無 scenario 覆蓋。
- `recommendation`: 改寫為兩條有先後的互斥條件，明訂 explicit skip 優先，並補一條交集 scenario。
- reviewer source: Reviewer A（F3，Warning／60）∪ Reviewer B（F6，Warning／50）；主 agent 複驗自身 delta 文字後校正為 100，證據見 `## Fix Actions` 的 V6。

### Suggestion

- **S1**（`confidence` 50、`layer` design、`location` `proposal.md` × delta ADDED 本文）— proposal 的「跳過時 MUST 標明是使用者明確要求」轉錄到 delta 時弱化為只需回報同步或跳過，契約子集丟失。來源：Reviewer A F4。
- **S2**（`confidence` 50、`layer` design、`location` delta MODIFIED × `design.md` IC4）— MODIFIED 區塊新增了一條原 requirement 沒有的 scenario，超出 IC4「僅改動文字、其餘逐字沿用」所授權的操作。來源：Reviewer A F5。
- **S3**（`confidence` 50、`layer` design、`location` `design.md` IC2 × `.claude/skills/cash-commit/SKILL.md:171`、`:184`）— IC2 未規定 6a-ii 標題與 6a 開頭 `three checks` 的處置，改寫後留下不對稱的殘留措辭。來源：Reviewer A F6。
- **S4**（`confidence` 50、`layer` design、`location` `design.md` D2、IC1；`.claude/skills/cash-archive/SKILL.md` 步驟 5 失敗處置）— 跳過路徑沒有明示 invocation 語法，也沒有從 preflight 失敗指回該路徑的指引，實務上接近不可到達。來源：Reviewer B F7。
- **S5**（`confidence` 50、`layer` text、`location` `tasks.md` 1.1 段落級判準）— 該判準被歸類為「實作前已成立」，但成立理由是 awk 起點在實作前不存在造成的空真，與 1.2 同型判準的處理方式不一致。來源：Reviewer B F8。

### 未進入 blocking 集合的其他 reviewer 輸出

Reviewer B 回報 `scripts/cash-skills/tests/skill-checks.fish` 在本機無法執行（`fish: Unknown command: rg`，本機沒有真實 ripgrep binary）。主 agent 複驗屬實：`/opt/homebrew/bin/rg` 與 `/usr/local/bin/rg` 皆不存在，`rg` 只解析到 Claude Code 的 bash function shim。這是既有的環境缺口而非本變更引入的缺陷，依「不回報 pre-existing issues」規則不計為 finding；處置方式是在 IC5 與 task 2.1 明文要求先安裝 `rg`，MUST NOT 以「環境不可執行」略過驗證。

## Rating

- post-filter 累積 blocking 集合 Critical 數：3（C1、C2、C3）
- post-filter 累積 blocking 集合 Warning 數：3（W1、W2、W3）
- 非 blocking triaged finding 數：5（S1–S5）
- `critical_gap`: true
- `round_type`: full

rationale：本輪為未 seeded 的第一輪，全部通過過濾器的 Critical 與 Warning 皆為 blocking，累積 blocking 集合共 6 名成員。其中 C2 是本變更自身引入的行為迴歸、C3 是 Implementation Contract 內部矛盾、C1 是一條在實作完成時必然不成立的 MUST，三者都直接違反 artifact 明文契約。六名成員均已在本輪 Fix Actions 記錄具名修正並列出修改檔案，但成員只能經由後續 reviewer 的明確 resolved 裁定離開集合，因此本輪決策為 `next_round`。

## Fix Actions

### 主 agent 複驗與 confidence 校正

依 confidence rubric「`100` — 直接證據或引用的 `SHALL`／Implementation Contract 條目／task 行／proposal non-goal 證明該違反」，下列四項經主 agent 以直接證據複驗後由 reviewer 給定值上調至 100。每項的證據如下：

- **V2（C2）**：讀 `.claude/skills/cash-commit/SKILL.md` 確認 6a-ii 在無 delta specs 時直接 skip 到 6a-iii，使舊條件「使用者明確選擇」為 false；新條件「封存未帶 `--skip-specs`」在同一情形恆真。兩者行為不等價，且 6a-iii 的納入是無過濾的 `Changes under openspec/specs/`，不像步驟 2a 有 `master_digests` digest 比對保護。
- **V3（C3）**：讀 `.claude/skills/cash-archive/SKILL.md` 確認 `(for tooling/doc-only changes)` 存在於 Optional flags，且修正前 IC1 逐字寫「Optional flags 清單 MUST NOT 改動」，與同一份 delta 的不推論 scenario 直接互斥。
- **V5（W2）**：讀 `.claude/skills/cash-archive/SKILL.md` 步驟 2、3 確認兩處確認皆為條件式（`If any artifacts are not done`／`If incomplete tasks found`）；讀 `.gitignore` 第 3 行確認 `.cash-skills/state/` 被忽略；讀 `.claude/skills/cash-apply/SKILL.md` 的 Archive guidance timing 確認該陷阱已被文件化。
- **V6（W3）**：讀本 change 自身 delta 的 ADDED 本文，確認兩條 MUST 在交集情境同時適用且無優先序規則。

上述校正皆為向上調整，方向保守；無任何 finding 被下調或由 `design` 重分類為 `text`。

### 修正動作

- **C1** — 修改 `openspec/changes/default-spec-sync-on-archive/specs/cash-skill-workflows/spec.md`、`design.md`、`proposal.md`、`tasks.md`。ADDED requirement 的回報義務拆為兩句：`cash-archive` 的完成摘要 MUST 回報判定結果、跳過時 MUST 標明出於使用者明確要求；`cash-commit` MUST 在 archive-first 的 updated commit plan 中標明判定結果。design 新增 D5 說明 `cash-archive` 三個 Output 模板恰好對應三個判定結果因而不需改動，並在 IC2 第 4 點開放唯一一處模板追加（`**Spec sync:**` 一行）。ADDED 新增 `cash-commit 的封存子流程套用同一判定並記錄結果` scenario 覆蓋該義務；tasks 1.2 加入對應的正向字面值判準。

- **C2** — 修改 `specs/cash-skill-workflows/spec.md`、`design.md`、`proposal.md`、`tasks.md`。導入三值判定結果 `synced`／`skipped`／`no delta specs`（design D4、IC1 第 2 點、IC2 第 2 點）。MODIFIED requirement 本文改為「判定結果為 `synced` 時」納入，並明文規定 `skipped` 或 `no delta specs` 時 MUST NOT 包含任何 `openspec/specs/` 路徑；sync scenario 改寫為 `判定結果為 synced 時納入 spec 變更`，並新增負向 scenario `判定結果不是 synced 時不納入任何 spec 路徑`。IC2 第 3 點把 6a-iii 條件釘為逐字 `only when 6a-ii recorded the outcome `synced``，tasks 1.2 加對應正向判準與對舊條件字串的負向判準。

- **C3** — 修改 `design.md`、`proposal.md`、`tasks.md`。IC1 第 7 點把保護範圍縮小為 bash 範例、`--mark-tasks-complete` 與 `--no-validate`；IC1 第 4 點要求改寫 `--skip-specs` 說明為逐字 `skip delta spec application; use only on the explicit request described in step 4` 並要求 `(for tooling/doc-only changes)` 消失；IC1 第 5 點要求 `adding the selected flags` 改為 `adding the resolved flags`。tasks 1.1 對這三處各加正向或負向判準。

- **W1** — 修改 `design.md`、`tasks.md`。新增 D8 說明只斷言舊字面值消失無法區分「預設同步」與「一律跳過」。IC1 第 2 點與 IC2 第 2 點改為逐字指定要寫入的整段內容。tasks 1.1 與 1.2 改寫為四類判準：正向（實作前 exit 1、實作後 exit 0）、負向（實作前 exit 0、實作後 exit 1）、段落級、保留守則。

- **W2** — 修改 `design.md`、`proposal.md`。`## Risks / Trade-offs` 全段改寫：第一條明說常見路徑零確認、具名三類 mutation、指出 `.gitignore` 第 3 行使 touched state 不可由 git 還原、引用 `cash-apply` 既有警告，並註明「未提供緩解」；第二條改寫為誠實的殘餘風險敘述，說明 preflight 只覆蓋 parse 與 identity；新增第三條說明跳過分支可到達性依賴 IC1 第 1 點。D3 明文禁止再以「步驟 2、步驟 3 的確認仍在」作為緩解敘述。proposal `## Non-Goals` 加入不恢復 Cancel 出口的條目並指向 design 的殘餘風險段。

- **W3** — 修改 `specs/cash-skill-workflows/spec.md`、`design.md`、`proposal.md`。ADDED requirement 本文改寫為兩條有先後的互斥條件，明訂 explicit skip 優先於預設；design D2 以同一措辭重述；新增 scenario `明確要求跳過優先於沒有 delta specs 的預設` 覆蓋交集情境。requirement 標題同步由 `封存前的 delta spec 預設同步` 改為 `封存前的 delta spec 同步判定`，以反映它現在定義的是一組判定規則而非單一預設值。

- **S1** — 修改 `specs/cash-skill-workflows/spec.md`。ADDED 本文補回「跳過時 MUST 標明該跳過出於使用者的明確要求」，`使用者以 invocation 明確要求跳過` scenario 的 THEN 同步補足。

- **S2** — 修改 `design.md`。IC4 補一句授權 MODIFIED 區塊新增描述「判定結果不是 `synced` 時不納入任何 `openspec/specs/` 路徑」的負向 scenario，並說明理由：新條件的錯誤模式正是在該情形下才顯現。

- **S3** — 修改 `design.md`、`tasks.md`。IC2 第 1 點要求 6a 開頭的 `three checks` 改為 `three steps`，第 2 點要求標題改為 `**6a-ii. Delta spec sync determination**`；tasks 1.2 對兩者各加正向與負向判準。

- **S4** — 修改 `design.md`、`proposal.md`、`tasks.md`。D2 定義明確要求的兩種形式並要求 `**Input**` 段承認 `--skip-specs`；IC1 第 1 點釘住 `**Input**` 的逐字新增內容，第 6 點要求步驟 5 的失敗處置補上 delta parse 失敗、`requirement_identity_mismatch`、`validation_failed` 三種情形的兩條出路；ADDED requirement 本文一併規定 `**Input**` MUST 承認該形式。tasks 1.1 對兩處各加正向判準。

- **S5** — 修改 `tasks.md`。該判準移入獨立的「段落級判準」分類，並註明它在實作前是空範圍空真、實作後才具鑑別力。

### 自我檢查在 fix actions 之後捕捉並修正的缺陷

- 修改 `tasks.md`。W1 的初版修正採用了 Reviewer A 建議的正則 `\b(ask|prompt|confirm)\w*\b` 作為步驟 4 的段落級判準，但 IC1 第 2 點的逐字內容本身就含 `without asking the user`、`the user asked to skip`、`do NOT ask the user to choose` 三處禁止式措辭，該正則在實作後必然命中而 exit 0，會使判準自我否定。改為 `AskUserQuestion` 的段落級 absence 檢查，並在 tasks 加註說明不得改用該正則。
- 修改 `proposal.md`。`## Motivation` 原句「真正需要 `--skip-specs` 的是 tooling／文件類 change」與本變更新增的「MUST NOT 從 change 性質推論」規則屬同型矛盾（與 C3 相同的機制），改寫為「而沒有 delta specs 的 change 根本走不到這個提問」。

### 修正後重跑的驗證

- 註解／annotation lint：四份 artifact 的 `<!--`／`-->` 計數皆為 0／0，無未閉合區塊。
- 計數一致性：`design.md` IC1 恰 8 點、IC2 恰 6 點，與 `tasks.md` 1.1「依 IC1 的八點」、1.2「依 IC2 的六點」相符。
- 識別字交叉比對：15 條被釘住的字面值在 `design.md` 與 `tasks.md` 之間逐字一致，無漂移。
- Spec delta title-identity：`### Requirement: cash-commit 的 archive-first 允許清單` 逐字存在於 `openspec/specs/cash-skill-workflows/spec.md`；ADDED 的新標題在 master spec 中不存在，無身分衝突。
- 判準鑑別力實測：1.1 與 1.2 合計 30 條字面值判準逐條在現行 `.claude` 檔案上執行，19 條正向判準全部為 absent（實作前正確為紅）、11 條負向與保留守則判準全部符合宣稱的實作前狀態。
- Signal-derived checks：`openspec/signals/` 下沒有任何 signal 具備 `check` frontmatter 欄位，故本輪無 `check` 可執行；改以既有的 best-effort 判斷處理相關 issue classes。
- `.cash-skills/bin/cash validate default-spec-sync-on-archive` → `Validation passed.`

本輪 Fix Actions 修改的檔案全部位於 `openspec/changes/` 之下，依 touched 記錄規則濾除後候選集合為空，因此未呼叫 Cash CLI，也未產生警告。

## Decision

next_round

六名 blocking 成員（C1、C2、C3、W1、W2、W3）都已記錄具名修正並列出修改檔案，五個非 blocking 的 Suggestion 也一併修畢，但依累積 blocking 集合規則，成員只能經由後續 reviewer 的明確 resolved 裁定離開集合。下一輪為本次執行的第二輪，依位置推導為 `micro`，由一位全新的 `Reviewer V — Verification` 對六名成員逐一回傳 resolved／unresolved 裁定、檢查修正傳播是否完整，並查驗修正是否引入新缺陷。
