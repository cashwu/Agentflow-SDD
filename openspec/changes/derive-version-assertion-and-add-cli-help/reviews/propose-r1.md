# Cash Propose Review — Round 1

## Reviewer Findings

聚合自兩個平行 reviewer（Reviewer A — Adherence、Reviewer B — Quality），以 `location + summary` 去重後套用 confidence filter。主 agent 對每一項 blocking finding 都以實測獨立求證。

### Critical

**C1**
- `severity`: Critical
- `confidence`: 100
- `layer`: design
- `location`: design.md `## Context` 與 `### D3`；proposal.md `## Impact`；`scripts/cash-cli/fixtures/negative-atomicity/error-contracts.json`；`scripts/cash-cli/tests/test_negative_atomicity.py:437`
- `summary`: design 兩處宣稱「實測確認沒有任何測試釘住這兩個錯誤訊息的字面值」為事實錯誤。`error-contracts.json` 以 golden fixture 逐字釘住 `"message":"Unknown command: nope"`，且 `test_error_fixture_documents_stable_exit_classes` 以 `assertEqual(json.loads(unknown.stdout), contracts["unknown_command"])` 做整個 object 的相等比對；IC3 要求的訊息擴充必然使該測試失敗，而該 fixture 既未列於 `## Impact` 也無任何 task 涵蓋，使 tasks 3.2 的驗收在已宣告範圍內不可達。
- `recommendation`: 修正 design 的事實宣稱；把 fixture 加入 `## Impact`；新增同批更新該 fixture 的 task。
- reviewer source: Reviewer A（100）與 Reviewer B（100）獨立提出。主 agent 已讀取 fixture 內容與 `:437` 的斷言確認。我原先的 grep 只搜 `scripts/cash-cli/tests/` 而漏了 `fixtures/`，是這個錯誤宣稱的來源。

### Warning

**W1**（A3）confidence 95 — `design.md ### D1` 用來論證「形狀是唯一未被覆蓋的面向」的理由不成立：`check_history:140` 的 `current = version(...)` 無條件執行且**早於** `current != head` 的 early return，`version()` 已擁有三分量格式規則。真正未被測試層覆蓋的只有「單一 LF」，因為 `version()` 以 `.strip()` 容忍。

**W2**（A2）confidence 95 — delta 把逐字相同的 `0|[1-9][0-9]*` 與 strict `MAJOR.MINOR.PATCH` 搬進 `Cash 合約測試套件`，而 master 的 `Bundle 安裝與 runtime receipt` 已定義同一規則。本 change 宣稱要消除 `cross-artifact-definition-drift`，卻在同一份 delta 製造第三份定義。

**W3**（B4）confidence 85 — 「單一 LF」的檢查沒有指定實作機制，而現場 fish 慣用法做不到。主 agent 實測 `test (string trim <file) = 2.3.0`：`no-LF`／`one-LF`／`CRLF` **三者全部 PASS**。照最自然的寫法會產出「宣稱檢查、實際不檢查」的斷言，且無既有測試能抓到該退化。

**W4**（B5）confidence 90 — tasks 3.1 的驗收「以 `test_bundle_version_history.py` 驗證版本嚴格遞增與 bundle 內容綁定成立」在該時點不可達：3.1 建立的正是「已升版但未 commit」狀態，`check_history` 在 `current != head` 時只檢查嚴格遞增即 `return`，內容綁定分支根本不執行，該半邊是 vacuous pass。

**W5**（B2）confidence 90 — launcher 在 `from cash_cli.main import main` 之前就完成 `validate_receipt`，因此 `cash --help` 無法繞過 receipt gate。`.cash-skills/receipt.tsv` 是 gitignore 檔，剛 clone 的 repo 必然沒有它，使用者最需要 help 的時刻拿到的是 `receipt_invalid`；而 spec 的 MUST 是無條件的，無任何 artifact 承認此前置條件。

**W6**（B3）confidence 90 — 新增的 MUST 未限定產生者，但 `unknown_command` 另有兩個產生點（`create.py:121` 的未知 new mode、`discovery.py:323` 的未知 discipline，後者還被 master 的 `Artifact graph 與 instructions 使用單一來源` 明訂）。照字面執行會把 15 個 top-level command 塞進語意錯誤的位置，並擴大改動面到兩個額外的 runtime record。

**W7**（A4）confidence 90 — IC2「第一個 argument 不是 help flag 時，CLI 行為 MUST 與未提供該表面時完全相同」與 IC3「`message` MUST 包含清單」互斥：`cash update` 的第一個 argument 不是 help flag，其 message 卻依 IC3 必須改變。

**W8**（A6／B6）confidence 85 — 「該檔由 `skill-checks.fish` 在同一次執行中呼叫」過度一般化。`test_bundle_version_history.py` 實際位於 `assert_installer`（第 220 行），只由 `installer-runtime` 與 `all` 觸發；字面值所在的 `assert_inventory` 由 `codex-command-matrix` 與 `canonical-inventory` 觸發。移除字面值後這兩個 group 對版本的治理將完全只剩形狀。

### Suggestion（經 confidence filter 降級，非阻斷）

- **S1**（A5，70）未修訂的 `Project-local Cash CLI runtime` 規定 unknown command 取得 shared lock 後失敗；`--help` 現在會以 exit 0 成功返回，與該條文字面衝突。
- **S2**（A7／B9，65）help 的 `--json` 只被規定為「單一 JSON object」，未定義 key，使 tasks 1.1 的防漂移斷言沒有可解析的欄位；repo 內其他 JSON 表面在 spec 中都有明列 key。
- **S3**（B7，75）scenario `版本治理不以字面值釘住` 的 GIVEN 寫成「任一合法值」過寬——低於 HEAD 的合法值會被嚴格遞增擋下，逐字驗證會得到反例，與其 Example 不一致。
- **S4**（B8，70）help 只導出 dispatch table 的 15 個 bare key，但同一 requirement 第一段列舉的是含子命令的 family（`new change`、`task done`、`instructions --skill`）。`## Non-Goals` 未承認這層粒度落差。

## Rating

- post-filter cumulative blocking set Critical count: **1**
- post-filter cumulative blocking set Warning count: **8**
- 非阻斷 triaged finding count: **4**
- `critical_gap`: **true**
- `round_type`: **full**

rationale：本輪為未 seeded 執行的第一輪，所有通過 confidence filter 的 Critical 與 Warning 均為 blocking。9 個 blocking finding 中有 5 個是我在撰寫 artifact 時做出的**事實錯誤**，而非設計取捨：C1（漏搜 `fixtures/` 導致宣稱無測試釘住訊息）、W1（誤判 `version()` 的執行位置）、W3（未驗證 fish 慣用法是否真能檢查 LF）、W4（未讀 `check_history` 的 early return 就寫下驗收）、W8（把 `assert_installer` 的呼叫誤植於 `assert_inventory`）。這五項的共同成因是我用了不夠嚴謹的證據就下結論——尤其 C1，我先前明明跑過 grep，卻限定在 `tests/` 目錄。W2 更諷刺：本 change 的宗旨是消除同一規則的多處定義，我卻在 delta 裡寫下第四份。這一輪的 reviewer 產出遠比前幾份 change 有價值，因為它們去讀了我宣稱「已實測」的東西。

## Fix Actions

9 個 blocking 成員與 4 個非阻斷項全部修復。無 grader-protection 保留項，無 accepted-risks 條目。修改檔案共 4 個：`proposal.md`、`design.md`、`tasks.md`、`specs/cash-cli/spec.md`（後二者為整份重寫，因改動面超過半數段落）。

**修 C1** — design `## Context` 改為如實記載：fixture 逐字釘住 `unknown_command` 訊息並以整個 object 相等比對驗證，`test_workspace_config_boundaries.py` 用子字串斷言不受影響，`missing_command` 無測試釘住。proposal `## Impact` 加入 `scripts/cash-cli/fixtures/negative-atomicity/error-contracts.json`。新增 task 2.2 要求同批更新該 fixture，並說明 fixture 是期望值的唯一承載處、不會產生第二份會漂移的清單。IC3 增列該 fixture 條款。tasks 3.2 的驗收明列 `negative-atomicity` group。

**修 W1 與 W2** — D1 整段改寫：如實承認 `version()` 已無條件擁有三分量格式，形狀驗證的實質新增價值收斂到「單一 LF」這唯一未被測試層覆蓋的面向。delta 的 `Cash 合約測試套件` 新增句改為**引用**而非複述——「MUST限於驗證版本檔符合`Bundle 安裝與 runtime receipt`所定義的形狀並以單一LF終止……且 MUST NOT在本套件重新定義該形狀規則的內容——形狀規則的權威來源維持在`Bundle 安裝與 runtime receipt`」。design `## Context` 新增一段列出形狀規則的三個既有擁有者（master spec、`installer.py` 的 `source_inventory`、`test_bundle_version_history.py` 的 `version()`）。

**修 W3** — D1 加入實測結論（`string trim` 對三種結尾形狀全部 PASS）並明訂必須以 byte-level 機制對檔案內容做完整比對；IC1 增列該條款與「SHALL 拒絕無 LF、CRLF、多個 LF、空檔與含前導零」；IC4 與 tasks 2.3 要求以五個負面案例驗證該機制確實會拒絕。tasks 2.3 另加一條一致性要求：接受集合必須與 `.cash-skills/lib/cash_cli/installer.py` 的 `source_inventory` 在安裝時強制的形狀一致。

**修 W4** — tasks 3.1 的驗收收斂為此時點實際可驗的部分（嚴格遞增、stable-path 綁定），並明文說明相同版本的內容綁定在該時點不可驗及其原因（`check_history` 的 early return），不列為本任務驗收。

**修 W5** — D2 新增整段說明 help 不繞過 receipt gate 及其不可迴避的理由（繞過需改 stable path 的 bytes）；spec 的 help 段落加上「MUST在launcher完成既有的lock取得與receipt驗證之後」的前置條件與「MUST NOT繞過launcher的receipt gate」；新增 `#### Scenario: Help 不繞過 receipt gate`；`## Risks / Trade-offs` 記錄 fresh clone 的後果與 shared lock 的行為；tasks 1.1 加入對應斷言。

**修 W6** — spec 與 IC3 明文限定為「由top-level command dispatch產生的」，並加一句「由個別handler產生的其他`unknown_command`（例如未知的new mode或未知的discipline）MUST NOT受此規定影響」；新增 `#### Scenario: Handler 層的 unknown_command 不受影響`；tasks 2.1 明寫 `create.py` 與 `discovery.py` 不得改動，1.1 加入對應斷言。

**修 W7** — IC2 的不變性子句限縮為「dispatch 目標、exit code、`error` code 與 JSON object 結構」；spec 對應句同步限縮。

**修 W8** — proposal 與 design `## Context` 如實記載兩個 function 的觸發範圍差異。更重要的是改變設計本身：形狀驗證**移到 `assert_installer`**，與 `test_bundle_version_history.py` 的呼叫同址，使「形狀與數值同一次執行」成為結構事實。IC1 增列該位置要求；spec 增列「該形狀驗證 MUST與呼叫bundle version history contract test落在同一個test group」並新增 `#### Scenario: 形狀驗證與數值治理同組執行`；`## Risks` 記錄 `canonical-inventory` 與 `codex-command-matrix` 將不再含版本治理及其判斷理由。

**修 S1** — spec 的 help 段落加一句「help flag不是command，`Project-local Cash CLI runtime`對unknown command的失敗規定僅適用於進入dispatch的token」，避免兩個 requirement 對同一 argv 給出相反結論。

**修 S2** — IC2 與 spec 固定 `--json` 形狀為「其`commands`欄位為排序後的dispatch table key陣列」；Example 同步；tasks 1.1 的防漂移斷言改為直接對該欄位取值。

**修 S3** — scenario GIVEN 收斂為「任一不低於`HEAD`版本的合法值」，並把 WHEN 限定為完整套件，與其 Example 一致。

**修 S4** — proposal `## Non-Goals` 與 design `## Goals / Non-Goals` 明示 help 只揭露 top-level key、不揭露子命令粒度，子命令由各 handler 既有的 `invalid_arguments` 訊息承載。

**修正後的機械自檢與驗證** — 4 份 artifact comment/annotation 平衡皆 0/0；兩個 MODIFIED 標題與 master 逐 byte 相符；以句子級比對確認 `Cash 合約測試套件` 的段落為純增加（原 4 句全數保留，512 → 928 字元），`Cash workflow command surface` 為純追加（遺失 0 行）；新增 scenario 由 4 增至 7，全數有 backing task；proposal 含 `/` 的 6 個 code span 全部在 tasks.md 出現；無 lowercase `may`／`should`。自檢另捕捉到本輪 fix 自身引入的兩個問題並已修正：三處 ghost bold（`**不**`、`**不可驗**`——本 session 第四次同型錯誤）以及 `installer.py` 因新增於 Motivation 而產生的 Gaps=1（已在 tasks 2.3 加入真實引用：形狀機制的接受集合必須與 `source_inventory` 一致）。重跑 `cash validate` 通過，`cash analyze` 非 Suggestion finding 為 0，兩個契約套件維持全綠。

**Signal-derived checks** — `openspec/signals/` 下全部 open signal 無 `check` frontmatter，採 best-effort。本輪最相關者：`cross-artifact-definition-drift`（W2 —— 本 change 差點在修它的同時製造新一筆）、`enumerated-site-set-factually-wrong`（C1、W8）、`acceptance-criterion-unreachable-at-specified-point`（W4、W5）、`policy-surface-enumeration-incomplete`（W6）。

## Decision

next_round

post-filter cumulative blocking set 含 1 個 Critical 與 8 個 Warning，未滿足 pass 條件。全部 9 個 blocking 成員與 4 個非阻斷項皆已完成 fix 並記錄於 `## Fix Actions`。下一輪依位置推導為第二輪，故為 `micro` 輪，由單一 Reviewer V 對 9 個成員逐一給出 resolved/unresolved 判定，並重點檢查本輪對 D1／D2／D3 與 delta spec 的大幅改寫是否引入新缺陷。
