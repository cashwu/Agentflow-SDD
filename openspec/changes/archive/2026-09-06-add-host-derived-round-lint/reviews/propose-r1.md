# Cash Propose Review — Round 1

## Reviewer Findings

本輪為未 seed 執行的第一輪 full 輪，由 Reviewer A（Adherence）與 Reviewer B（Quality）獨立進行。findings 以 `location + summary` 聚合；未 seed 首輪不要求 `disposition`。

### Critical

**C1** — `severity`: Critical｜`confidence`: 100｜`layer`: design｜`location`: proposal.md `## Non-Goals` 與 `## Impact`；tasks.md｜reviewer: A + B（獨立提出同一 finding）
`summary`: Non-Goal 拒絕調升 `cash-skills.version`，但本 change 新增並修改 managed runtime bytes，master spec 明文 MUST 調升，且調升 MUST 排在第一個受 guard 的改動之前。
`recommendation`: 刪除該 Non-Goal；把 `cash-skills.version` 加入 `## Impact`；新增排序最前的版本調升 task，與 installer 的 `BUNDLE_VERSION` 同步。
主 agent 驗證：`openspec/specs/cash-cli/spec.md:2236` 逐字為「任何 launcher、runtime、skill、portable manifest schema／record或 Git logical mode改變 MUST在第一個受 guard的 production artifact改動前，將 `cash-skills.version`調升為嚴格較大版本」。`scripts/cash-skills/tests/test_bundle_version_history.py:72-75` 的 `replaceable_paths()` 以 `rglob("*.py")` 蒐集 `.cash-skills/lib/cash_cli` 下全部 `.py`，line 356 丟出 `replaceable inventory changed without a version bump`。原 Non-Goal 的理由「本 change 不改動任何 canonical SKILL.md」誤判觸發條件——觸發條件是 runtime bytes。成立。

**C2** — `severity`: Critical｜`confidence`: 90｜`layer`: design｜`location`: design.md D3；specs/cash-round-gate/spec.md 活動判定 requirement｜reviewer: A（Critical 90）+ B（Warning 85），合併取較嚴重者
`summary`: 活動判定取「最高編號 round file」，但 `propose-r<N>` 與 `apply-r<N>` 是各自從 1 起算的獨立序列，混存時最高編號者常非最新迴圈，使 `grader_immutability` 在 cash-apply loop 全程誤判為 `skip`。
`recommendation`: 改為逐 skill 各取最高編號，任一 skill 為 `next_round` 即 active；補一個 `propose-r3` = `passed` 與 `apply-r1` = `next_round` 並存的 scenario。
主 agent 驗證：`scripts/cash-skills/blocks/review-gate.md:142-144` 分別規定 `propose-r<N>.md` 與 `apply-r<N>.md`，line 144 明訂續號是「for that skill」。design D2 已正確限定在「某個 skill 的序列」，D3 卻退回跨檔案取最高編號，屬自身不一致。成立。

**C3** — `severity`: Critical｜`confidence`: 90｜`layer`: design｜`location`: design.md D3；specs/cash-round-gate/spec.md 活動判定｜reviewer: B
`summary`: `grader_immutability` 的適用與否完全由受審 main agent 自己撰寫的 round file `## Decision` 決定，受審者可單方面使該 gate `skip`，而此路徑未被任何 Risk 涵蓋。
`recommendation`: 至少新增一條 Risk 逐字記錄該旁路，不得讓 proposal 保留無限制的「改不動、也騙不了」宣稱。
主 agent 驗證：成立，且與本 change 已將 round file 不可變性移出 v1 同源——該 gate 正是本可攔下「把 `next_round` 改成 `passed`」的機制。

**C4** — `severity`: Critical｜`confidence`: 80｜`layer`: design｜`location`: design.md D6；specs/cash-round-gate/spec.md fail-open 條款｜reviewer: B
`summary`: 裁判自身（`lint_round.py`、`.claude/settings.json`）不在受保護路徑集合內，且 hook 對基礎設施錯誤靜默 fail open，受審者動裁判面即可無聲關掉整個 gate。
`recommendation`: fail-open 分支 MUST 輸出 `gate_unavailable` 診斷使旁路可稽核；把 gate 自身納入受保護集合，或說明為何不納入。
主 agent 驗證：成立。使用者已裁示採「範圍內誠實修」：實作診斷與 Risk，不擴大到 MODIFIED `cash-skill-workflows` 的受保護集合。

### Warning

**W1** — Warning｜`confidence`: 100｜`layer`: design｜`location`: design.md R4｜reviewer: A（100）+ B（100）
`summary`: R4 宣稱本 change 不修改任何受保護路徑，但 `scripts/cash-cli/tests/cli-checks.fish` 在受保護集合內且是本 change 的 delivery target，R4 前提為假。
主 agent 驗證：`scripts/cash-skills/blocks/review-gate.md:194` 逐字含該路徑。成立。

**W2** — Warning｜`confidence`: 100（reviewer 給 75，主 agent 上修）｜`layer`: design｜`location`: proposal.md `## Proposed Solution` vs design.md D4｜reviewer: B
`summary`: proposal 指名 `git diff --name-only`（僅 unstaged），design 與 spec 要求涵蓋 worktree 與 index；依 proposal 字面實作時 `git add` 即可讓受保護檔案逃離判定。
主 agent 驗證：proposal.md 原文確實為 `git diff --name-only`，與 design D4 直接矛盾且可逐字比對，屬 rubric 中「直接證據證明違反」，依「Direct artifact-requirement violations MUST score 100」上修為 100。成立。

**W3** — Warning｜`confidence`: 90｜`layer`: design｜`location`: specs/cash-round-gate/spec.md 唯讀性 requirement vs tasks.md 全部 task｜reviewer: A
`summary`: 唯讀性 requirement 的三條 MUST 與兩個 scenario 沒有任何 task 以其為 delivery 或 verification 涵蓋，而 D1 自稱那是本 change 的核心約束。

**W4** — Warning｜`confidence`: 80｜`layer`: design｜`location`: design.md Implementation Contract；specs/cash-round-gate/spec.md 結構判定｜reviewer: A
`summary`: 沒有任何 artifact 定義「什麼檔案算 round file」，而 `reviews/` 下必然有 `loop-ledger.tsv` 與可選的 `accepted-risks.md`，兩者都不具四個 section；實作者若取全部 `.md` 會使阻擋型 hook 每個 turn 都失敗。

**W5** — Warning｜`confidence`: 80｜`layer`: design｜`location`: design.md D6；specs/cash-round-gate/spec.md 重入 scenario｜reviewer: A（70）+ B（80），取較高
`summary`: `stop_hook_active` 為真即 exit 0，使阻擋成為一次性——agent 完全不修正也能在下一次 stop 結束 session，實效退化為「一次警告」，且此代價未在任何 Risk 承認。

**W6** — Warning｜`confidence`: 80｜`layer`: design｜`location`: specs/cash-round-gate/spec.md grader immutability requirement｜reviewer: A（80）+ B（65），取較高
`summary`: 「逐字對應所列路徑」未涵蓋既有 requirement 的兩個非路徑成分——`openspec/specs/` 的目錄型保護，以及無 declared-scope 例外的 signal `check` frontmatter 欄位級保護。
主 agent 驗證：`openspec/specs/cash-skill-workflows/spec.md:1835` 確含「`openspec/specs/` 之下的 master spec 檔案」與「無論宣告範圍為何，主 agent MUST NOT 新增、修改或移除 `openspec/signals/` 之下任何 signal 的 `check` frontmatter」。成立。

**W7** — Warning｜`confidence`: 80｜`layer`: design｜`location`: tasks.md 舊 1.7 `success` 欄位｜reviewer: A
`summary`: `success` 混入兩個不同 target 的結果——lint-round 實跑的 `ok` 與 `.claude/settings.json` 的 JSON 合法性——後者在 primary verification target 上不可觀察，違反欄位紀律。

**W8** — Warning｜`confidence`: 80｜`layer`: design｜`location`: proposal.md、design.md D2、specs/cash-round-gate/spec.md｜reviewer: A（65）+ B（80），取較高
`summary`: 「run 的第一輪 MUST 是 `full`；當且僅當某輪是其 run 的第四輪時 MUST 是 `full`」作為 normative 規則自相矛盾；master spec 的 iff 只作用於第一輪之後的輪。
主 agent 驗證：`openspec/specs/cash-skill-workflows/spec.md:1632` 原文為「一次迴圈執行的第一輪 MUST 是 full 輪。當某一輪的決策為 `next_round` 時……當且僅當下一輪是本次執行的第四輪時，它才是 full 輪」。三個 artifact 都省略了限定條件。成立。

**W9** — Warning｜`confidence`: 80｜`layer`: design｜`location`: design.md Implementation Contract 列舉條件；specs 兩檔｜reviewer: B
`summary`: 列舉條件「非 `archive` 的目錄」與既有 CLI 的忽略集合 `{"archive", ".parked"}` 不一致：`.parked` 被當成 change 列舉，且 parked change 的 round files 完全不受檢，`cash park` 成為逃逸口。
主 agent 驗證：`.cash-skills/lib/cash_cli/commands/discovery.py:151` 為 `ignored = {"archive", ".parked"}`。成立。

**W10** — Warning｜`confidence`: 80｜`layer`: design｜`location`: design.md Implementation Contract；specs/cash-round-gate/spec.md 結構判定｜reviewer: B
`summary`: `round_file_schema` 不要求 `## Rating` 內含 `round_type`，而 `round_type_position` 在該欄位缺席時行為未定義，刪掉欄位即成為位置推導 gate 的旁路。

### Suggestion

以下六筆經信心過濾後為 Suggestion（非 blocking）。本輪仍一併修正，理由記於 `## Fix Actions`。

- **S1**（reviewer A，Warning 75 → Suggestion）：舊 tasks 1.8 的 `red` 描述的是「套件仍全數通過」，是通過而非失敗，不構成可辨識的 failure marker。
- **S2**（reviewer B，Warning 60 → Suggestion）：launcher 以無 `LOCK_NB`、無 timeout 的 `fcntl.flock` 取鎖，hook 可能無限期阻塞，而被強制中止不在 D6 的 fail-open 條件內。
- **S3**（reviewer A，Suggestion 55）：舊 tasks 1.2 的 `red` 指向 D7 順序違反的 `manifest_invalid`，而非 primary target 上實作前的紅燈，且觀察面比 primary target 寬。
- **S4**（reviewer B，Suggestion 55）：「執行前後逐位元組不變」未排除 `.git/`，而 gate 必須呼叫 git 而刷新 `.git/index`，該驗收標準機械上不可驗證。
- **S5**（reviewer A，Suggestion 50）：「拒絕描述待驗事實的參數」scenario 的標題說「拒絕」但 THEN 只斷言「結果與未提供時相同」，報錯與靜默忽略兩種相反實作都能通過。
- **S6**（reviewer B，Suggestion 50）：round file 編號序列不連續時位置推導未定義，刪去一個 round file 可使其後各輪重新對齊而通過。

## Rating

- post-filter 累積 blocking 集合 `Critical` 數：4
- post-filter 累積 blocking 集合 `Warning` 數：10
- 非 blocking triaged finding 數：6
- `critical_gap`：`true`
- `round_type`：`full`

理由：本輪是未 seed 執行的第一輪，依既有通過條件，每個存活的 `Critical` 與 `Warning` 都是 blocking，因此 blocking 集合為 4 + 10 = 14 筆。其中 C1 與 W1、W2、W6、W8、W9 均由主 agent 對照 master spec 或現行程式碼逐條驗證屬實，非推測；C2 屬 design 自身 D2 與 D3 不一致；C3、C4 指出 gate 的兩條真實旁路。blocking 集合非空且含 `Critical`，本輪不通過，`decision` 為 `next_round`。

## Fix Actions

本輪修正涵蓋全部 14 筆 blocking finding，並一併修正 6 筆非 blocking Suggestion。修改檔案 4 個：`proposal.md`、`design.md`、`specs/cash-round-gate/spec.md`、`tasks.md`。`specs/cash-cli/spec.md` 本輪未修改。

**C1**：刪除 proposal `## Non-Goals` 的「不調升 `cash-skills.version`」；`## Impact` 的 Modified 加入 `cash-skills.version`；design D7 補入版本調升為第一個動作的順序規定與 `test_bundle_version_history.py` 的失敗訊息證據；tasks 新增排序最前的 1.1，同步 `cash-skills.version` 與 installer `BUNDLE_VERSION`，verification 為該契約測試。

**C2**：design D3 改為逐 skill 各取最高編號、任一 skill 為 `next_round` 即 active，並逐字說明跨 skill 取值在 apply loop 期間失效的後果；spec 對應 requirement 標題改為「迴圈活動狀態逐 skill 判定」並同步正文；新增 scenario「另一個 skill 的迴圈仍進行中」。proposal 對應段落同步。

**C3**：design 新增 R8，逐字記錄「`grader_immutability` 的適用取決於受審者撰寫的 round file `## Decision`」這條旁路，並指明它與被移出 v1 的 round file 不可變性同源；同段明確界定 proposal `## Motivation` 的「改不動、也騙不了」成立範圍為未主動攻擊 gate 自身的受審者。

**C4**：design D6 要求每個 fail-open 分支 MUST 向 stderr 輸出 `gate_unavailable` 診斷並指出原因；R8 記錄 gate 自身不受保護；proposal 與 design 的 Non-Goals 明列「不保護 gate 自身」及其理由（納入需 MODIFIED 另一 capability 的 master requirement，超出本 change 範圍）；spec 的 Stop hook requirement 與驗收標準同步，並新增 scenario「基礎設施錯誤 fail open 且留下診斷」。此處採使用者於本輪裁示的範圍內修法。

**W1**：design R4 重寫，承認 `scripts/cash-cli/tests/cli-checks.fish` 是受保護路徑、本 change 確實依賴 structured scope declaration 例外，並將本 change 自身指定為 R3 解析器的雙向 fixture（`## Impact` 條目必須判 `pass`、`design.md` 散文中的受保護路徑必須判定為非宣告）。tasks 1.5 納入該 fixture 要求。

**W2**：proposal `## Proposed Solution` 的機制描述改為「Git 導出的變更集合，涵蓋工作區相對 `HEAD` 的改動（含已 staged 者）與 untracked 檔案」；design D4 與 spec 同步加上 staged 涵蓋與「只取 unstaged 會使 `git add` 成為旁路」的理由；spec 新增 scenario「已 staged 的受保護路徑仍在變更集合內」；tasks 1.4 補該 fail case。**信心更正紀錄**：reviewer B 給 `confidence` 75，主 agent 依 rubric「直接 artifact 違反 MUST 評 100」上修為 100，證據為 proposal 與 design 兩處原文可逐字比對的矛盾。該更正使此 finding 由非 blocking 轉為 blocking。

**W3**：tasks 1.2 的測試涵蓋範圍加入「執行前後排除 `.git/` 的工作區逐位元組不變且不產生 `__pycache__`」與「額外位置參數以 `unknown_command` 或 `invalid_arguments` 失敗而非靜默忽略」，1.3 的實作範圍同步納入唯讀性保證，使該 requirement 取得 backing task。

**W4**：design D2 改名為「round file 的辨識與 run 邊界推導」並逐字寫入檔名樣式 `<skill>-r<N>.md`（`<skill>` 恰為 `propose` 或 `apply`、`<N>` 為無前導零十進位正整數），明訂不符樣式者不納入任何 gate；spec 對應 requirement 標題改為「Round file 辨識與 run 邊界導出」並新增 scenario「非 round file 不納入判定」，逐字列出 `loop-ledger.tsv` 與 `accepted-risks.md`。

**W5**：design 新增 R7，記錄 `stop_hook_active` 短路使阻擋實效上限為「阻擋一次並列出失敗項」，並與 `## Alternatives Considered` 的阻擋型描述對齊；spec 要求重入放行時仍 MUST 將未解決失敗項輸出至 stderr；對應 scenario 同步；收窄短路條件明確留待後續 change。

**W6**：spec 的 grader immutability requirement 改為只主張涵蓋既有 requirement 的**路徑**成分、`openspec/specs/` 明列為目錄型宣告，並明文 MUST NOT 主張涵蓋 signal `check` 欄位保護；design D4 同步；proposal 與 design 的 Non-Goals 明列「不涵蓋 signal `check` 欄位保護」及其形狀理由。

**W7**：舊 tasks 1.7 拆為兩項——實跑既有 changes 的確認移入新 1.7 的 `regression` 欄位（該處是它的正確位置，屬 R2 緩解），`.claude/settings.json` 的掛載獨立為 1.8，其 `verification` 改為對該檔的 JSON 解析與 `Stop` hook 條目斷言，`success` 只保留該斷言結果，不再混入其他 target。

**W8**：proposal、design D2、spec 三處統一改寫為「run 的第一輪 MUST 是 `full`；run 第一輪之後的每一輪，當且僅當它是該 run 的第四輪時 MUST 是 `full`，否則 MUST 是 `micro`」，並在 spec 加註該 iff MUST 只作用於第一輪之後的輪。

**W9**：design D3 與 spec 的列舉規則改為逐字對齊 `discovery.py:151` 的 `{"archive", ".parked"}`，並明訂另行涵蓋 `openspec/changes/.parked/` 下的 parked change；spec 新增 scenario「parked change 仍受檢」；proposal 同步；tasks 1.4 補該 case。

**W10**：design Implementation Contract 與 spec 明訂 `## Rating` 缺少 `round_type` 或其值不在 `full`／`micro` 值域內時 `round_type_position` MUST 回報 `fail`；spec 新增 scenario「Rating 缺少 round_type」；tasks 1.2 補兩個 fail case。

**S1**：新 tasks 1.9 的 `red` 改為 `N/A` 並附 remaining-task 分類理由（為已通過行為補契約層斷言，不存在先行失敗狀態）。
**S2**：design D6 的 fail-open 條件加入「取鎖逾時」，並要求 `--hook` mode 自帶整體時間上限；spec 同步並新增 scenario「取鎖逾時歸入 fail open」；tasks 1.6 補該 case。
**S3**：新 tasks 1.3 的 `red` 改為 primary target 上可辨識的實作前失敗（1.2 全部 case 以 `unknown_command` 失敗）；D7 順序違反的 `manifest_invalid` 標記留在 design R5。
**S4**：design 驗收標準與 spec 的比較範圍明確界定為排除 `.git/`，並註明 `.git/index` 的 stat-cache 刷新不構成違反；對應 scenario 補上「沒有產生 `__pycache__`」。
**S5**：spec 明確擇一——額外位置參數 MUST 以 `unknown_command` 或 `invalid_arguments` 失敗、MUST NOT 靜默忽略；scenario 的 THEN 同步改為斷言錯誤 code 與 JSON 錯誤 shape。
**S6**：design D2 與 spec 明訂編號序列 MUST 自最小編號起連續、缺號 MUST 判 `fail`，並說明其動機是防止刪除 round file 使其後各輪重新對齊；spec 新增 scenario「編號缺號」；tasks 1.2 補該 fixture。

**修正後重跑的檢查**：`"$cash_cli" validate "add-host-derived-round-lint"` 通過；pre-round mechanical self-check 全數重跑通過——annotation lint 兩個 delta 檔的 `<!--`／`-->` 皆為 0 且無 stray `---`；count-consistency 確認 design R1 的「四個 gate」與 Implementation Contract 的四個 gate id 相符、tasks 1.3 的「結構類三個 gate」與實際三項相符；identifier cross-grep 確認 `gate_unavailable`、`stop_hook_active`、`.parked`、`cash-skills.version`、`round_type`、`<skill>-r<N>.md` 在各 artifact 間拼寫與語意一致；spec delta title-identity 確認 `### Requirement: Cash workflow command surface` 逐位元組存在於 master spec；signal-derived checks 中沒有任何 signal 定義 `check` 欄位，第一步為空集合，第二步以既有 best-effort 判斷處理且無新增發現。另新增一項交叉檢查：tasks 全部 `delivery` 路徑與 proposal `## Impact` 宣告路徑雙向完全對應，9 對 9，無遺漏也無多宣告。

**程序偏差紀錄**：本輪兩位 full-round reviewer 應於同一則訊息內 spawn，實際以兩次連續呼叫送出。兩者仍為並行執行、context 相同、彼此獨立且未互相傳遞輸出，獨立性未受影響。

**範圍外或未修復事項**：無。本輪無 `未修復：裁判面保護` 紀錄，無 accepted-risks 降級，無 disposition 更正（未 seed 首輪不要求 disposition）。唯一的信心更正為 W2，已記於該條。

## Decision

`next_round`

本輪 post-filter 累積 blocking 集合含 4 筆 `Critical` 與 10 筆 `Warning`，不符通過條件。全部 14 筆 blocking finding 與 6 筆非 blocking Suggestion 均已在本輪 `## Fix Actions` 記錄對應的修正動作並實際套用，修正後 `validate` 與 pre-round mechanical self-check 皆重跑通過，因此進入下一輪。依位置推導，下一輪是本次執行的第二輪、非第四輪，故為 `micro` 輪，由一位全新的 Reviewer V 進行差異驗證。
