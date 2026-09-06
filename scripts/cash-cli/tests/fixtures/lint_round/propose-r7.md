# Cash Propose Review — Round 7

## Reviewer Findings

本輪為 Round 6 `aborted` 後的 seeded re-run 第一輪，依位置推導為 `full` 輪，由兩位全新的 Reviewer A（Adherence）與 Reviewer B（Quality）並行獨立審查。Reviewer A 依 run-first-round 規定先對 design.md 的 22 項 code-facing 宣稱逐項比對 launcher、installer、commands、tests 與 master spec，全部成立。

### Seeded 累積 blocking 集合逐成員裁定

- **W-A** — `resolved`。兩位 reviewer 各自引述現行 D5（「不產生任何由 command 自身控制的寫入——不建立目錄、不寫檔案——」）、spec 唯讀 requirement 與 design 驗收標準（receipt-based target 排除 `__pycache__/`、`*.pyc` 且同時適用「逐位元組不變」與「不建立目錄」）、新增 receipt-based scenario、tasks 1.2，並完成語意檢查 (a)：同段無條件子句已被明文一併限定。修正參照：Round 6 Abort triage 後修正（W-A）。驗證 reviewer：Reviewer A、Reviewer B，皆 `resolved`。
- **W-B** — `resolved`。兩位 reviewer 各自引述 proposal `## Proposed Solution` 現行文字「parked change 納入列舉以接受結構類 gate 判定，但 MUST NOT 計入 active 判定」，並以 parked／`.parked`／active 同義檢索確認 proposal 無其他反向陳述、與 D3／R11／spec／tasks 1.4 一致。修正參照：Round 6 Abort triage 後修正（W-B）。驗證 reviewer：Reviewer A、Reviewer B，皆 `resolved`。

集合因此清空。以下為本輪新發現，依 `location + summary` 聚合。

### Warning（blocking）

**N-1** — `severity`: Warning｜`confidence`: 85｜`layer`: design｜`disposition`: `fix-introduced`｜`introduced_by`: Round 1 `## Fix Actions` C4（每個 fail-open 分支 MUST 向 stderr 輸出 `gate_unavailable`）與 W5、Round 2 F3（重入放行時 MUST 將未解決失敗項輸出至 stderr 後 exit 0）｜reviewer: B｜`location`: design.md D6 第 3 段、`## Implementation Contract` Stop hook 驗收標準；specs/cash-round-gate/spec.md `Stop hook 自行判定對象並在失敗時阻擋` requirement 與 scenario「基礎設施錯誤 fail open 且留下診斷」「重入時仍執行判定後放行」；tasks.md 1.6、1.7；design.md R7、R8
`summary`: 全部 fail-open 分支與 `stop_hook_active` 重入放行都規定「exit 0 且將診斷輸出至 stderr」，但依 Claude Code hooks 的 host 行為，exit 0 時 stderr 只進 debug log、不顯示給使用者也不回饋給 Claude；exit 2 的 stderr 回饋給 Claude；其他非零 exit 的 stderr 顯示給使用者。D6「診斷使該旁路至少可稽核」與 R7「使放行留下紀錄」兩個緩解在 host 上實際不成立。
`recommendation`: fail-open 與有失敗項的重入放行改以 exit 1 結束並保留 stderr 輸出，仍屬非阻擋；把 host 的 exit 語意逐字寫入 D6，並同步 R7、R8、spec requirement 與 scenario、tasks 1.6／1.7。
主 agent 覆核：成立。`introduced_by` 經比對 Round 1 C4／W5 與 Round 2 F3 條目成立。

**N-2** — `severity`: Warning｜`confidence`: 90｜`layer`: design｜`disposition`: `fix-introduced`｜`introduced_by`: Round 1 `## Fix Actions` C4（新增 scenario「基礎設施錯誤 fail open 且留下診斷」並把 `gate_unavailable` 義務套到「每個」fail-open 分支）｜reviewer: B｜`location`: specs/cash-round-gate/spec.md Stop hook requirement「CLI 缺席或不可執行……MUST fail open 以 exit `0` 結束」與 scenario「基礎設施錯誤 fail open 且留下診斷」（GIVEN `.cash-skills/bin/cash` 不存在或不可執行）；design.md D6；tasks.md 1.6、1.7
`summary`: hook command 依 Implementation Contract 直接執行 `.cash-skills/bin/cash`，D6 又明文「不存在可插入 wrapper 的位置」。CLI 缺席時 shell 以 127 結束、無人能輸出 `gate_unavailable`；launcher 階段的 `manifest_invalid`／`bootstrap_invalid`／Python 版本檢查以 `fail()` exit 1 結束，早於 `lint_round.py` 執行。該 scenario 與 tasks 1.6 對應 case 在既定約束下不可交付。附帶後果：D7 兩個發佈窗口期間每次 Stop 都會以 `manifest_invalid` exit 1，未被任何 Risk 記錄。
`recommendation`: 把 `gate_unavailable` 義務限定為 `lint_round.py` 進入點之後可攔截的失敗；CLI 缺席、launcher 信任 gate 失敗、Python 版本不足併入 R9；改寫該 scenario 與 tasks 1.6。
主 agent 覆核：成立，與 N-1 同一根因（gate 外層的失敗語意由 host／shell 決定）。

### Suggestion（非 blocking）

- **A1／S-1**（Reviewer A Warning 75 → 過濾後 Suggestion；Reviewer B Suggestion 50；`layer`: text）｜`disposition`: `unresolved-prior`（W-A 同機制殘留）｜`location`: design.md D6 第 4 段、spec Stop hook requirement 第 2 段「command……不寫入任何檔案」
  `summary`: W-A 修正後 D5 已把唯讀定義為「不產生任何由 command 自身控制的寫入」，此二處仍為無條件措辭。兩位 reviewer 對 W-A 本體皆裁定 resolved；本殘留因引用 D5 且 `.pyc` 不構成狀態管道而不改行為，過濾後為非 blocking。
- **A2／N-3**（Reviewer A Warning 70、Reviewer B Warning 75 → 過濾後 Suggestion；`layer`: design）｜`disposition`: `fix-introduced`｜`introduced_by`: Round 4 G6、Round 6 Abort triage 後修正（S-C）｜`location`: tasks.md 1.2 末段
  `summary`: fixture 來源釘在 `openspec/changes/add-host-derived-round-lint/reviews/` live 路徑，`cash archive` 會移走該目錄；封存後測試要麼永久紅燈、要麼 glob 為空時 vacuously pass（`expected-set-derived-from-observed-state`）。
- **N-4**（Reviewer B Warning 70 → 過濾後 Suggestion；`layer`: design）｜`disposition`: `fix-introduced`｜`introduced_by`: Round 1 W9、Round 2 F2｜`location`: design.md D3、spec 活動判定 requirement、cash-cli spec scenario「lint-round --hook 不接受 change 名稱」、Implementation Contract `--hook` 介面
  `summary`: 宣稱對齊 `discovery.py:151` 但只搬忽略集合，丟掉「目錄型」與名稱樣式 `[a-z][a-z0-9-]*` 兩個限定；`.DS_Store` 會被列舉為 change 而使整批進入 fail-open。
- **N-5／A4**（Reviewer B Warning 65、Reviewer A Suggestion 50 → Suggestion；`layer`: design）｜`disposition`: `new`｜`location`: spec `Grader immutability 以三方比對判定` 第 1 段 vs 第 2 段、design D4、tasks 1.7 regression
  `summary`: single-change mode 只取「該 change」宣告，`--hook` 取全部 active change 聯集；兩個 active change 並存時 hook 判 pass 而 single-change 判 fail，1.7 regression 會出現偽陽性。
- **N-6／A3**（Suggestion 55／50；`layer`: text）｜`disposition`: `new`｜`location`: spec scenario「無 round file 時靜默通過」GIVEN
  `summary`: 「全部 active change 都沒有 round file」依 D3 為空前提；應改為「全部被列舉的 change」。
- **N-7**（Suggestion 50；`layer`: design）｜`disposition`: `new`｜`location`: spec `Round file 辨識與 run 邊界導出`、design D2 與 `round_type_position` 擷取規則
  `summary`: (a) 「含 `round_type` 的 bullet」不唯一時未定義；(b) 第 N-1 輪 `## Decision` 不可解析時第 N 輪是否為新 run 未定義。
- **S-2**（Suggestion 50；`layer`: design）｜`disposition`: `new`｜`location`: design Implementation Contract `--hook` 介面「其欄位（`stop_hook_active`、`cwd`）」、Stop hook 介面
  `summary`: `cwd` 被列為讀取欄位但無任何規則使用；hook command 相對路徑依賴 host cwd，host 提供 `$CLAUDE_PROJECT_DIR` 未被採用。

### Reviewer 的整體判斷

Reviewer A：proposal ↔ design ↔ spec ↔ tasks 對 gate 集合與 `id`、活動判定、列舉規則、三方比對、`--hook` 失敗語意、D7 發佈順序都有單一且一致的定義；六個 round-gate requirement 與 cash-cli MODIFIED requirement 都有 backing task；`## Impact` 與 tasks delivery 9↔9 雙向對應；MODIFIED 標題逐位元組相符；全部 code-facing 宣稱成立。Reviewer B：seeded 兩成員已在全部指定位置解決且通過兩項語意檢查，六輪累積的字串殘留類缺陷已清空；剩餘問題集中在尚未對照 host 與 launcher 實際行為查證的 fail-open 層，N-1 與 N-2 同一根因，可一次收斂；無 Critical，不需 `cash-ingest`。

## Rating

- post-filter 累積 blocking 集合 `Critical` 數：0
- post-filter 累積 blocking 集合 `Warning` 數：2
- 非 blocking triaged finding 數：7
- `critical_gap`：`false`
- `round_type`：`full`

理由：seeded 成員 W-A、W-B 經兩位 reviewer 以現行 artifact 原文各自驗證並回傳明確 `resolved`，移出集合。本輪聚合後九筆 finding 中，N-1（85）與 N-2（90）為 `Warning` 且 `disposition` 為 `fix-introduced`，依 seeded re-run 首輪規則進入累積 blocking 集合；A1／S-1、A2／N-3、N-4、N-5／A4 的 reviewer 信心均落在 `[50, 80)`，依信心過濾降級為 `Suggestion`，非 blocking；N-6／A3、N-7、S-2 為 `Suggestion`。集合含 2 筆 `Warning`，不符通過條件。本輪為新 run 第一輪，下一輪依位置推導為 `micro`。

## Fix Actions

全部九筆本輪均已修正（blocking 兩筆為義務，非 blocking 七筆因皆屬局部改字且與 blocking 修正共用同一批段落，一併同步以免下一輪再出現同機制殘留）。修改檔案 5 個：`proposal.md`、`design.md`、`tasks.md`、`specs/cash-round-gate/spec.md`、`specs/cash-cli/spec.md`。

1. **N-1 + N-2（同根因，一次收斂）**：
   - design.md D6 第 1 段改寫為兩段語意：`lint_round.py` 進入點之後可攔截的失敗（workspace 解析、輸入 JSON 解析、未預期例外）fail open 以 exit 1 結束；進入點之前的失敗（CLI 缺席 → shell 127、launcher 信任 gate 失敗 → `fail()` exit 1 + `error[<code>]`、Python 版本不足）不在 command 可控範圍，記於 R9。新增一段逐字寫入 host 的三種 exit 語意，並收斂為「只有 exit 2 阻擋，其餘非零 exit 一律非阻擋且 stderr 可見」。
   - design.md D6 第 3 段：fail-open 分支 MUST 以 exit 1 結束，MUST NOT exit 0。第 4 段：重入時有未解決失敗項以 exit 1 輸出，無失敗項 exit 0 靜默。
   - design.md Implementation Contract Stop hook 驗收標準：逐項列出 exit 0／1／2 的條件，並明文進入點之前的失敗不在驗收範圍。
   - design.md R7 改為以 exit 1 放行並說明 host 可見性；R8 同步；R9 從「取鎖阻塞」一般化為「進入點之前的失敗與終止」涵蓋四類情形，並記錄 D7 發佈窗口期間 Stop 會以 `manifest_invalid` exit 1 的附帶後果。
   - specs/cash-round-gate/spec.md Stop hook requirement：fail-open 分支限定為進入點之後、exit `1`、MUST NOT exit `0`；寫入 host exit 語意；明文進入點之前的失敗 MUST NOT 被課予 exit code 或 `gate_unavailable` 義務。重入段落改為有失敗項 exit `1`、無失敗項 exit `0` 且無輸出。
   - scenario「基礎設施錯誤 fail open 且留下診斷」改為「基礎設施錯誤 fail open 且留下可見診斷」，GIVEN 改為 standard input JSON 無法解析、THEN exit `1`、AND 不以 exit `0` 結束。scenario「重入時仍執行判定後放行」THEN 改為 exit `1` 而非 exit `2`；新增 scenario「重入時無失敗項則靜默放行」。
   - proposal.md `## Proposed Solution` 第二層段落：「以非零 exit 阻擋」改為「以 exit 2 阻擋」，fail open 改為 exit 1 + `gate_unavailable` 並附 host 語意一句。
   - tasks.md 1.6 重寫 case 清單（JSON 不可解析 exit 1、workspace 解析失敗 exit 1、任何 fail-open 分支不 exit 0、重入有失敗項 exit 1、重入無失敗項 exit 0 且無輸出；CLI 缺席等依 R9 不在測試範圍）；1.7 同步 exit 語意並禁止 exit 0 搭配 stderr 診斷。
2. **A1／S-1**：design.md D6 第 4 段與 spec Stop hook requirement 第 2 段的「不寫入任何檔案」改為「不產生任何由自身控制的寫入」；propagation 掃描另發現 proposal.md 第 19 行同義措辭，一併同步為「不產生任何由 command 自身控制的寫入」。
3. **A2／N-3**：tasks.md 1.2 改為 round files MUST 複製為 `scripts/cash-cli/tests/fixtures/lint_round/` 靜態 fixture、MUST NOT 讀取 live 路徑、fixture 集合為空時 MUST 失敗；delivery 新增該目錄；proposal.md `## Impact` New 新增 `scripts/cash-cli/tests/fixtures/lint_round/`；design.md R2 補述理由。
4. **N-4**：design.md D3、Implementation Contract `--hook` 介面、spec 活動判定 requirement、cash-cli spec scenario「lint-round --hook 不接受 change 名稱」四處補上「目錄型且名稱符合 `[a-z][a-z0-9-]*`」；spec 新增 scenario「非目錄項目不被列舉為 change」；tasks.md 1.4 新增對應 case、1.5 補述。
5. **N-5／A4**：design.md D4、Implementation Contract 介面、spec `Grader immutability 以三方比對判定` 第 1、2 段改為兩種 mode 都取全部 active 被列舉 change 宣告的聯集，single-change 位置參數只決定回報對象；tasks.md 1.4 新增 case、1.5 補述。
6. **N-6／A3**：spec scenario「無 round file 時靜默通過」GIVEN 改為「全部被列舉的 change 都沒有 round file」。
7. **N-7**：design.md D2 與 spec run 邊界段落新增「第 N-1 輪 `## Decision` 不可解析時其後各輪 `round_type_position` MUST 判 `fail`」；design.md 與 spec 的 `round_type` 擷取規則改為「去除 bullet 標記、backtick 與前後空白後以 `round_type` 開頭的 bullet，不恰為一筆時判 `fail`」；tasks.md 1.2 新增兩個 case。
8. **S-2**：design.md Implementation Contract `--hook` 介面刪去 `cwd`，明文只讀取 `stop_hook_active`；Stop hook 介面與 tasks.md 1.8 的 command 改為 `"$CLAUDE_PROJECT_DIR"/.cash-skills/bin/cash lint-round --hook` 並說明理由。

### 修正後機械自檢

- propagation 掃描（exit 0 + stderr／`不寫入任何檔案`／`該 change 的 structured`／`cwd`／`project root 下的 .cash-skills/bin/cash`／`含 round_type 的 bullet`／`不存在或不可執行`）：除有意保留的 host 語意陳述外無殘留；另抓到 R7「即 exit 0」與 proposal 第 19 行兩處同義殘留並已同步（已計入上列修改檔案）。
- spec delta 註解配對 0/0；MODIFIED 標題與 master 逐位元組相符；`## Impact` 與 tasks delivery 集合相同（10↔10）；cash-round-gate spec 現為 6 requirement／37 scenario，無任何 artifact 宣稱 scenario 計數。
- open signals 164 個皆無 `check` 欄位，無可執行檢查。
- `.cash-skills/bin/cash validate add-host-derived-round-lint --json` 回報 `valid: true`。

### 其他紀錄

本輪無 `未修復：裁判面保護` 紀錄，無 accepted-risks 降級（ledger 不存在），無 disposition 更正——N-1、N-2、A2／N-3、N-4 的 `introduced_by` 經比對各該 round 的 `## Fix Actions` 條目成立，A1／S-1 的 `unresolved-prior` 成立。無 finding 觸發 Safety exception。fix actions 未修改 change 目錄以外的檔案，不執行 `touched` 記錄。

## Decision

`next_round`

seeded 成員 W-A、W-B 經兩位 reviewer 驗證 resolved 並移出集合；本輪新增兩筆 `fix-introduced` `Warning`（N-1、N-2）進入累積 blocking 集合，不符通過條件。兩筆與七筆非 blocking 項目均已於本輪修正並通過 validate，下一輪為本 run 第二輪，依位置推導為 `micro`，由 Reviewer V 對 N-1、N-2 逐成員裁定。
