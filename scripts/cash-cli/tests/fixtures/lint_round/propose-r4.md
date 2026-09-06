# Cash Propose Review — Round 4

## Reviewer Findings

本輪為本次執行的第四輪，依位置推導 MUST 為 `full` checkpoint——本次執行第一輪之後唯一的完整重新掃描。由兩位全新獨立 reviewer（Reviewer A — Adherence、Reviewer B — Quality）於同一則訊息內並行 spawn，context 相同、彼此獨立且未互相傳遞輸出。

### 累積 blocking 集合逐成員裁定

**verified resolution（1 項）**

- V1 — 兩位 reviewer 皆裁定 `resolved`，裁定一致無分歧。證據：specs/cash-round-gate/spec.md 的 scenario 標題現為「重入時仍執行判定後放行」，其 GIVEN／THEN 與 design D6、R7 三處一致；五份 artifact 全文 grep `立即` 均為 0 命中。修正參照：Round 3 `## Fix Actions` V1。驗證 reviewer：Reviewer A 與 Reviewer B。

集合因此清空。以下為本輪 full 重掃的新發現，依 `location + summary` 聚合。

### Critical

**G1** — `severity`: Critical｜`confidence`: 90｜`layer`: design｜`disposition`: `fix-introduced`｜`introduced_by`: Round 1 `## Fix Actions` 的 **S2** 條目（「design D6 的 fail-open 條件加入『取鎖逾時』，並要求 `--hook` mode 自帶整體時間上限」）｜reviewer: B｜`location`: design.md D6；specs/cash-round-gate/spec.md Stop hook requirement 與取鎖逾時 scenario；tasks.md 1.6、1.7
`summary`: 「`--hook` mode 自帶取鎖時間上限」在本 change 的其他約束下不可實作，且其 scenario 的 fixture 會使 hook 無限阻塞——正是 D6 要避免的情形。
主 agent 覆核：成立。`.cash-skills/bin/cash:626-627` 的 `fcntl.flock` 發生在 `validate_portable_manifest` 與 `cash_cli` import **之前**，因此 `lint_round.py` 內任何逾時機制都在鎖取得後才開始，涵蓋不到阻塞本身；design.md:13 `## Goals` 明文「新增 command 不修改 `.cash-skills/bin/cash`」，`## Implementation Contract` 又規定 hook command 直接執行 launcher、settings.json 不含判定邏輯，排除了 wrapper。這是我在 Round 1 修 S2 時寫進去的 MUST，當時未查證取鎖位置。

**G2** — `severity`: Critical｜`confidence`: 90｜`layer`: design｜`disposition`: `new`｜reviewer: A（Warning 90）+ B（Critical 85），合併取較嚴重者｜`location`: tasks.md 1.1；design.md D7 與 R5
`summary`: 1.1 修改 `installer.py` 的 `BUNDLE_VERSION` 但 delivery 不含 `.cash-skills/manifest.tsv` 且無發佈動作；`installer.py` 是 portable manifest 的 runtime record 並綁定 digest，因此 1.1 一完成整支 CLI 即以 `manifest_invalid` 失效，直到 1.3 才發佈——期間 `cash task done` 不可用，1.1 自己無法被記為完成。D7 只把停機窗口歸因於新增 `.py` 的 extra-path 拒絕，掩蓋了這個更早觸發的 digest drift。
主 agent 覆核：成立。`.cash-skills/manifest.tsv:19` 確有 `runtime .cash-skills/lib/cash_cli/installer.py 0b065a04…`；launcher 逐筆比對 sha256 並以 `portable manifest digest drift` 走 `fail("manifest_invalid", …)`。連帶使 1.2／1.3 的 `red` 標記（`unknown_command`）不可達——實際會拿到 `manifest_invalid`。

### Warning

**G3** — `severity`: Warning｜`confidence`: 90｜`layer`: design｜`disposition`: `new`｜reviewer: A｜`location`: specs/cash-round-gate/spec.md grader immutability requirement；tasks.md 1.4；design.md R4
`summary`: requirement 宣告兩個宣告來源（proposal `## Impact` 與 `tasks.md` delivery target），但只有前者有 distinguishing scenario；`tasks.md` 那一半只出現在否定前提中，因此完全忽略 `tasks.md` 的實作能通過每一個 scenario。這直接違反 R4 的 MUST——R4 要求以 `## Impact` 條目**與該 task 的 delivery 行**同為必須判 `pass` 的 fixture。
主 agent 覆核：成立。`tasks.md 的 delivery target` 在 spec 中僅出現於三處否定前提，無任何正面 scenario。

**G4** — `severity`: Warning｜`confidence`: 85｜`layer`: design｜`disposition`: `new`｜reviewer: A（75）+ B（85），取較高｜`location`: design.md D2；specs/cash-round-gate/spec.md run 邊界 requirement
`summary`: 連續性規則錨定在「該序列最小編號」而非 `r1`，只攔得住中間缺號。刪除序列前綴（刪 `r1` 至 `r3`、留 `r4` 起）後序列仍自其最小編號連續、無缺號，`r4` 反被判為新 run 的第一輪，正好完成刪檔者要的重新對齊——這正是該規則自述要防止的情形。
主 agent 覆核：成立。既有規則保證合法歷史中每個 skill 序列必含 `r1`（round file 不得覆寫、re-run 續號），因此 `r1` 錨點是 host-derived 且無額外成本，卻未被採用。

**G5** — `severity`: Warning｜`confidence`: 80｜`layer`: design｜`disposition`: `fix-introduced`｜`introduced_by`: Round 3 `## Fix Actions` 的 **V2** 條目（聯集語意）｜reviewer: B｜`location`: design.md D4 第二段；specs/cash-round-gate/spec.md grader immutability requirement 第二段
`summary`: 聯集把宣告來源從「當前 change」放寬為「全部被列舉 change」，而列舉集合是全部非 archive 目錄加上全部 parked change，不限 active。`openspec/changes/` 不在受保護集合內且受審者可寫，因此新建或編輯任一無關 change 的 `## Impact` 即可對所有 change 永久解除 `grader_immutability`，而被審查的 change 自身 artifacts 看起來乾淨。master requirement 逐字要求例外只在「當前 change 的結構化範圍宣告」成立，聯集因此比它要機械化的規則更寬。
主 agent 覆核：成立。這是我在 Round 3 修 V2 時引入的過寬語意。

**G6** — `severity`: Warning｜`confidence`: 80｜`layer`: design｜`disposition`: `new`｜reviewer: B｜`location`: design.md `## Implementation Contract` 的 `decision_value` 與 `round_type_position`；specs/cash-round-gate/spec.md 兩個對應 requirement；tasks.md 1.2
`summary`: 兩個 gate 都以「`## Decision` 的值恰為……」「`## Rating` 所記 `round_type`」表述，但沒有任何 artifact 定義如何從 section 內文擷取「值」。實際 round file 的形狀是 `## Decision` 之下一行 backtick 包裹的值再接一整段 rationale（`Round 檔案輸出合約` 本就要求記 rationale），`## Rating` 的形狀是 `` - `round_type`：`micro` ``（backtick 加全形冒號）。依「值恰為」字面實作會使本 change 現存的三個 round file 全部判 `fail`，而 hook 是阻擋型且每個 turn 執行，等於啟用當天就對每個無關 turn exit `2`。
主 agent 覆核：成立且已對本 change 的 `propose-r3.md` 實地確認形狀。此為解析規則缺口造成的偽陽性，與 R2 承認的「既有 change 留有**違規**的歷史 round file」不同——這些檔案並未違反任何散文規則。

### Suggestion

以下經信心過濾後為 Suggestion，均非 blocking；本輪一併修正。

- **G7**（reviewer B，Warning 70 → Suggestion）｜`disposition`: `new`｜停滯或 parked 的 change 其最高編號 round file 常永久停在 `next_round`，使 repository 進入「永久 active」，`grader_immutability` 因此對完全不在 review loop 的 session 每個 turn 生效；R2 的緩解逐字只涵蓋「無 round file 或迴圈已終結」，正好漏掉「迴圈永不終結」。
- **G8**（reviewer A，Suggestion 65）｜`disposition`: `new`｜`Round file 結構判定` 的「無法解析時 MUST 回報 `fail` 而 MUST NOT 以例外中止」無 distinguishing scenario，tasks 1.2 亦無對應 case。
- **G9**（reviewer A，Suggestion 55）｜`disposition`: `new`｜唯讀性的「不產生 `__pycache__`」為無條件表述，但 launcher 只在 portable 分支設 `sys.dont_write_bytecode = True`，receipt-based target 的 bytecode 寫入發生在 import system、早於 handler，command 無從阻止而 `## Goals` 又不改 launcher，該標準在 receipt target 上不可達成。
- **G10**（reviewer A，Suggestion 55，`layer`: text）｜`disposition`: `new`｜tasks 1.8 的 `red` 仍是 Round 3 V4 指出的假設形狀，V4 只修了 1.5 與 1.7。此為 V4 triage 註記在未觸及位置的再報，僅作交叉參照，不產生重複 triage 註記或 signal。
- **G11**（reviewer B，Suggestion 55）｜`disposition`: `fix-introduced`｜`introduced_by`: Round 3 `## Fix Actions` 的 **V2** 條目｜tasks 1.5 括號內逐項列舉 D4 子規則時未列入聯集語意，讀來像窮舉。
- **G12**（reviewer B，Suggestion 50）｜`disposition`: `new`｜`--hook` mode 會列舉到 artifacts 尚未寫齊的 change 目錄，宣告解析在 `proposal.md` 或 `tasks.md` 缺席時的行為未定義；若拋出例外會依 D6 使整批 fail open，一個半成品 change 目錄即可讓 gate 每個 turn 靜默不可用。

### 經信心過濾捨棄

- reviewer B 的 F9（`confidence` 45，低於 50 門檻）——掛載點在版控中的 `.claude/settings.json` 而 hook command 是 repo 內可執行檔，構成信任面擴張。依過濾規則捨棄，此處保留 downgrade trace。其實質內容與 R8 第二條同族，本輪仍在 R8 補一句敘明該信任面，屬順帶而非因該 finding 而修。

## Rating

- post-filter 累積 blocking 集合 `Critical` 數：1
- post-filter 累積 blocking 集合 `Warning` 數：1
- 非 blocking triaged finding 數：10
- `critical_gap`：`true`
- `round_type`：`full`

理由：V1 經兩位 reviewer 一致裁定 resolved 而移出集合，集合一度清空。本輪 full 重掃產生 12 筆存活 finding，經信心過濾後 2 筆 `Critical`、4 筆 `Warning`、6 筆 `Suggestion`，另捨棄 1 筆 `confidence` 45 者。依既有通過條件，`Critical` 與 `Warning` 只有在 `disposition` 為 `unresolved-prior` 或 `fix-introduced`、或符合 Safety exception 時才是 blocking：G1（`fix-introduced`，源自 Round 1 S2）與 G5（`fix-introduced`，源自 Round 3 V2）因此 blocking；G2、G3、G4、G6 的 `disposition` 均為 `new`。

Safety exception 逐筆評估：G2 與 G6 造成的是 CLI 停機與阻擋型 hook 的偽陽性，屬可用性後果，無資料遺失或安全邊界違反的具體證據；G4 是保護 gate 的旁路，但其後果是治理完整性失效而非可證的資料遺失或安全邊界違反，與 R8 已承認的兩條旁路同族；G3 是驗收覆蓋缺口。四者均不符 Safety exception 的證據門檻（受影響路徑與範圍宣告、可達的觸發輸入、以及證明破壞性結果或安全邊界違反的重現或明確因果鏈），故維持非 blocking。集合因此為 G1 與 G5 兩筆，含 `Critical`，本輪不通過。

本輪的意義在於它是本次執行唯一的完整重新掃描，而它找出的 12 筆全部是前三輪的 micro 輪未觸及的：兩筆是我自己在 Round 1 與 Round 3 的修正引入的（G1、G5），其餘是三輪差異驗證從未覆蓋到的面——擷取規則、發佈順序的第二個成因、驗收覆蓋缺口、以及序列前綴刪除旁路。這與 `分級收斂與 micro 驗證輪` 設置第四輪 checkpoint 的用意一致。

## Fix Actions

本輪修正 2 筆 blocking finding 與 10 筆非 blocking finding。修改檔案 4 個：`proposal.md`、`design.md`、`specs/cash-round-gate/spec.md`、`tasks.md`。`specs/cash-cli/spec.md` 本輪未修改。

**G1**（blocking）：採 recommendation 的第三個方向並結合 host 承擔。design.md D6 移除「`--hook` mode MUST 自帶整體上限」與 fail-open 條件中的「取鎖逾時」，改為逐字說明為何不可實作——launcher 取得 `flock` 早於 manifest 驗證與 import，`## Goals` 不修改 launcher，hook command 直接執行 launcher 而無 wrapper 位置——並規定時間上限改由 `.claude/settings.json` 的 hook 條目宣告 host 層 `timeout`。specs/cash-round-gate/spec.md 的 Stop hook requirement 同步加入 MUST NOT 要求自帶上限的條款；原「取鎖逾時歸入 fail open」scenario 由「hook 條目宣告 host 層 timeout」取代。新增 design.md R9 記錄代價：該上限觸發時 hook 由 host 終止，既不走本 gate 的 exit code，也不輸出 `gate_unavailable`。tasks 1.6 移除取鎖逾時 case、1.7 移除自帶上限的實作項、1.8 的 delivery 斷言加入 `timeout` 宣告。

**G5**（blocking）：design.md D4 與 spec 對應段落把聯集來源收窄為「本身依 D3 判定為 active 的被列舉 change」，並明訂 MUST NOT 納入已終結或 parked 的 change。新增 design.md R10 逐字記錄未關閉的部分——`openspec/changes/` 不在受保護集合內且受審者可寫，收窄只提高偽造成本（需一併偽造 round file）而未關閉該路徑，納入受保護集合需 MODIFIED 另一個 capability 的 master requirement，超出本 change 範圍——並將該旁路併入 `## Motivation` 成立範圍的界定。proposal 同步。

**G2**：tasks 1.1 的 delivery 加入 `.cash-skills/manifest.tsv`，並把 source-only 發佈納入該 task，逐字說明只調升 `BUNDLE_VERSION` 而不發佈會使 CLI 立即 `manifest_invalid` 失效、連 `cash task done` 都無法執行。design.md D7 新增一段，明訂停機窗口有兩個成因——新增 `.py` 使 portable gate 拒絕 extra path，以及編輯既有 runtime record 造成 digest drift，後者更早觸發——並把規則一般化為「每一次改動 manifest 覆蓋的 runtime bytes 之後、下一個 Cash command 之前都必須發佈」。R5 的緩解同步擴及每一個改動 manifest 覆蓋 bytes 的 task。1.2／1.3 的 `red` 因 1.1 現已在同 task 發佈而重新可達，維持原措辭。

**G3**：specs/cash-round-gate/spec.md 新增 scenario「僅由 tasks.md delivery target 宣告亦成立」；tasks 1.4 的 case 列表補上該項。修正後 R4 指定的雙向 fixture 兩半都有對應 scenario 與 case。

**G4**：design.md D2 與 spec 的 run 邊界 requirement 均改為「序列的最小編號 MUST 為 `1`，且 MUST 自該編號起連續」，並逐字說明只錨定序列自身最小編號攔不住刪除前綴、以及既有規則保證合法歷史必含 `r1`。spec 新增 scenario「序列缺少起始編號」；tasks 1.2 的 case 列表補上該項。

**G6**：design.md `## Implementation Contract` 的兩個 gate 條目與 spec 的兩個對應 requirement 均加入明確擷取規則——`## Decision` 取 section 內第一個非空行、去 backtick 與空白後比對值域，其後 rationale 段落 MUST NOT 使 gate 失敗；`round_type` 取含該欄位的 bullet、取冒號（半形或全形）之後去 backtick 與空白的 token。spec 新增兩個 scenario：「Decision 值之後的 rationale 段落不使 gate 失敗」與「round_type 以 backtick 與全形冒號記錄仍可解析」。tasks 1.2 補上兩個 case，並把本 change 現存的 `propose-r1.md` 至 `propose-r4.md` 列為必須判 `pass` 的 fixture——以本迴圈自身產出的真實 round file 作為迴歸基準。

**G7**（非 blocking，triage 註記並一併修正）：triage 註記——停滯 change 使 gate 對無關 session 持續生效。design.md D3 與 spec 明訂 parked change MUST 納入列舉以接受結構類 gate 判定，但 MUST NOT 計入 active 判定；此舉同時保住 Round 1 W9 修正的目的（park 不再使 round files 逃檢）並移除 parked 造成的永久 active。非 parked 的停滯 change 無法以同法排除，新增 R11 逐字記錄，並在 R2 的緩解句補一行交叉參照指向 R11。

**G8**（非 blocking，triage 並修正）：spec 的 `Round file 結構判定` requirement 明訂無法解析時其餘 gate MUST 仍回報各自結果；新增 scenario「round file 無法解析」；tasks 1.2 補該 case。

**G9**（非 blocking，triage 並修正）：design.md 的唯讀驗收標準把 `__pycache__` 一項的範圍限於 portable-manifest target，並說明 receipt-based target 的 bytecode 寫入發生在 import system、早於 handler，command 無從阻止而 `## Goals` 不改 launcher。

**G10**（非 blocking，triage 並修正）：tasks 1.8 的 `red` 改為「該 `Stop` hook 條目新增之前，`.claude/settings.json` 不含該條目，斷言失敗」，與 1.3／1.5／1.7 的形狀一致。此為 Round 3 V4 triage 註記在未觸及位置的再報，依既有規定僅記一行交叉參照指向 Round 3 的 V4，不建立重複 triage 註記或 signal。

**G11**（非 blocking，triage 並修正）：tasks 1.5 括號內補上「涵蓋判定取全部 active 被列舉 change 宣告的聯集、parked change 納入列舉但不計入 active」。

**G12**（非 blocking，triage 並修正）：design.md 的失敗模式與 spec 的 grader immutability requirement 明訂缺少 `proposal.md` 或 `tasks.md` 的被列舉 change MUST 貢獻空宣告集合並繼續判定、MUST NOT 拋出例外；spec 新增 scenario「半成品 change 目錄不使判定中止」；tasks 1.4 補該 case。

**捨棄 finding 的 downgrade trace**：reviewer B 的 F9（信任面擴張，`confidence` 45）低於 50 門檻，依信心過濾捨棄，不進入任何集合、不產生 signal。

**修正後重跑的檢查**：`validate` 通過；pre-round mechanical self-check 全數重跑通過——annotation lint 兩份 delta 的 `<!--`／`-->` 皆為 0 且無 stray `---`；spec delta title-identity 確認 `### Requirement: Cash workflow command surface` 逐位元組存在於 master spec；tasks 九項五欄位無缺漏、無 `TBD`／`TODO`；delivery 路徑與 proposal `## Impact` 雙向對應 9 對 9；signal-derived checks 中仍無任何 signal 定義 `check` 欄位。round-gate spec 現有 6 個 requirement 與 32 個 scenario（本輪自 26 增加 6 個）。design 的 Risks 現為 R1 至 R11 且編號順序正確。

**傳播檢查**：對本輪每個修正概念全 artifact 全文 grep 確認無殘留舊措辭——「取鎖逾時」與「自帶時間上限」除 D6／spec 中刻意的 MUST NOT 條款外為 0 命中；聯集語意在 proposal、design、spec 三處均已帶 active 限定；`r1` 錨點在 design D2 與 spec 兩處一致；擷取規則在 design 兩個 gate 條目與 spec 兩個 requirement 四處一致。scenario 標題亦納入檢查面。

**範圍外或未修復事項**：無。本輪無 `未修復：裁判面保護` 紀錄，無 accepted-risks 降級。disposition 覆核：G1 與 G5 的 `fix-introduced` 經比對 Round 1 的 S2 與 Round 3 的 V2 條目成立，`introduced_by` 參照有效；G11 同源於 Round 3 V2，標記成立。G2、G3、G4、G6、G7、G8、G9、G10、G12 標為 `new`，主 agent 逐筆檢查其位置是否曾被本迴圈修正動作觸及：G6 的擷取規則缺口自 spec 初版即存在、G4 的錨點問題自 Round 1 S6 加入缺號規則時即已存在於該規則本身、G2 的 digest drift 自 D7 初版即未涵蓋、G3 的 scenario 缺口自 Round 1 W6 改寫該 requirement 時即存在——四者雖位於曾被修改的區段，但缺陷並非源自那些修正動作所改動的內容，故維持 `new`，不更正為 `fix-introduced`。無 blocking 轉非 blocking 的更正。

**程序紀錄**：本輪兩位 full-round reviewer 已於同一則訊息內並行 spawn，修正 Round 1 記錄的程序偏差。

## Decision

`next_round`

本輪 post-filter 累積 blocking 集合含 1 筆 `Critical`（G1）與 1 筆 `Warning`（G5），不符通過條件。兩筆 blocking finding 與 10 筆非 blocking finding 均已在本輪 `## Fix Actions` 記錄對應修正並實際套用，修正後 `validate` 與 pre-round mechanical self-check 皆重跑通過。依位置推導，下一輪是本次執行的第五輪、非第四輪，故為 `micro` 輪，由一位全新的 Reviewer V 進行差異驗證。本次執行的六輪上限尚餘兩輪。
