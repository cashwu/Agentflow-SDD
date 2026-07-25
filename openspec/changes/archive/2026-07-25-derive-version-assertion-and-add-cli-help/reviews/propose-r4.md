# Cash Propose Review — Round 4

本輪為第四輪 full checkpoint，spawn 兩個 fresh reviewer 平行執行完整重掃，並各自對 cumulative blocking set 成員 F1 給出判定。

## Reviewer Findings

### Cumulative blocking set 判定

| member | Reviewer A | Reviewer B | 合併 |
| --- | --- | --- | --- |
| F1 | resolved | resolved | **resolved** |

兩位皆確認 design Risks 已改為「訊息會指向 help flag」，與 IC3 及 spec 一致，舊措辭全 artifact 零殘留。Reviewer A 另以 `main.py:124-127` 求證行為面：`cash --json --help` 的 `argv[0]` 為 `--json`，必然落入 `unknown_command`，`json_mode` 使其以 JSON `error` object 輸出、exit 2 不變。

### Warning

**G1**（A，confidence 95，`layer`: text，`fix-introduced`）task 1.1 的具名 scenario 清單仍列 **Help 不繞過 receipt gate**，與 task 1.2 及 IC4「receipt gate 的覆蓋 SHALL 置於 `test_negative_atomicity.py`」直接衝突，且該覆蓋在 1.1 指定的檔案內不可達。`introduced_by`：propose-r3 的「**修 F4** — 把 receipt gate 的覆蓋從 tasks 1.1 移出」——移出只施作於斷言本體，未及於同 task 的 scenario 具名清單。

**G2**（B，confidence 95，`layer`: design，`fix-introduced`）task 1.2 要求「驗證該測試在實作前失敗」，但其斷言描述的正是變更前的現況（launcher 先驗 receipt，`--help` 在 receipt 無效時必然 exit 1，且當時本就沒有 help 輸出），因此實作前後皆通過，red 階段不可達。拆成獨立 task 之前它與其他必失敗斷言同在 1.1、聚合起來確實會 red。`introduced_by`：propose-r3 的「**修 F4**」。

**G3**（B，confidence 90，`layer`: design，`fix-introduced`）design 的「形狀規則已經有三個擁有者」漏了 `.cash-skills/bin/cash` 的 `is_source_layout`——該處逐字重述完整格式規則**並含單一 LF 條款**，且由 `validate_receipt` 在每次 launcher 執行時呼叫；同檔另有第二份分量規則。實際重述點為五處而非三處。更關鍵的是該檔是 frozen stable path，其 bytes 不隨一般升版改變，因此那份重述在一般變更中改不動。`introduced_by`：propose-r1 的「**修 W1 與 W2** …… design `## Context` 新增一段列出形狀規則的三個既有擁有者」。

### Suggestion（經 confidence filter 降級或原為 Suggestion，皆非阻斷）

- **G4**（B，85）IC1 同時要求「byte-level 完整比對」與「SHALL NOT 重新定義格式規則」，兩者在實作層互斥——任何 byte-level regex 都必須把 `0|[1-9][0-9]*` 編碼進 `skill-checks.fish`，即第六份重述，Goal「不再被複述第四次」在實作後不成立。
- **G5**（B，70）五個負面案例沒有正向控制：任何使 fixture 不可達的執行錯誤都會被讀成「拒絕」，讓五個案例全部 vacuous pass——正是本 change 立論所針對的失效型態。
- **G6**（B，85）handler 層 `unknown_command` 的兩項斷言也不是純 unit 可達：`create.py` 與 `discovery.py` 都在判定之前先解析 workspace，實測以 repo root 為 cwd 得 `unknown_command`、以 `/tmp` 為 cwd 得 `workspace_not_found`。
- **G7**（A，70）proposal 以粗體斷言字面值 pin「不提供額外覆蓋」，與 design Risks 首項「字面值能攔到有人改了版本但沒意識到」矛盾。
- **G8**（A+B，55／60）spec 的「其對bundle version的治理 MUST限於……」與「MUST與呼叫 bundle version history contract test 落在同一個 test group」字面互斥——若治理「限於」形狀，則同時呼叫治理數值的 contract test 即逾越。
- **G9**（A，55，`unresolved-prior`）scenario `版本治理不以字面值釘住` 的 GIVEN 仍過寬：版本等於 `HEAD` 且 replaceable bytes 已漂移時，`check_history` 會以內容綁定失敗，THEN 的「通過」被自身 GIVEN 允許的狀態證偽。

## Rating

- post-filter cumulative blocking set Critical count: **0**
- post-filter cumulative blocking set Warning count: **3**（G1、G2、G3）
- 非阻斷 triaged finding count: **6**（G4–G9）
- `critical_gap`: **false**
- `round_type`: **full**

rationale：F1 由兩位 checkpoint reviewer 一致以 verified resolution 判定並離開集合。本輪的價值在於 full 重掃找到三輪 micro 都看不到的東西：G3 顯示我從 round 1 起就把「形狀規則有幾個擁有者」數錯了，而正確答案（五處，其中一處在 frozen stable path）直接影響 G4 指出的設計矛盾——IC1 要求 byte-level 完整比對，但任何這樣的比對都必須把格式編碼進 `skill-checks.fish`，那就是我這份 change 宣稱要消除的東西再多一份。G2 則是 round 3 拆 task 的副作用：一個斷言在聚合時能 red，獨立出來就變成描述現況的 characterization test。G4 雖依 confidence 降為 Suggestion，但它是本輪最有價值的一項，因此一併以改設計處理而非僅改措辭。

## Fix Actions

3 個 blocking 成員與 6 個非阻斷項全部修復。無 grader-protection 保留項，無 accepted-risks 條目。修改檔案共 4 個。

**修 G4（改設計，非改措辭）** — 格式判定改為**委派給 runtime 既有的 `version_parts`**：驗證讀取檔案 bytes、自行判斷「恰一個 LF 終止」，再把去掉 LF 的內容交給該函式。`skill-checks.fish` 因此不含任何格式常數，自有條款只剩 LF 一項，且「內容接受集合與 `source_inventory` 一致」成為結構事實而非人工同步——兩者呼叫同一判定函式。已實測該委派對 `2.3.0\n` 接受，對無 LF、CRLF、雙 LF、空檔、前導零五種全部拒絕。design D1、IC1、tasks 2.3、spec 的治理句全部同步。

**修 G3** — design `## Context` 改為如實記載：格式規則在實作面至少有四處各自編碼（`installer.py` 的 `VERSION_RE` 與 `source_inventory`、`bin/cash` 的 `is_source_layout` 含 LF 條款、同檔的 receipt 版本分量、`test_bundle_version_history.py` 的 `version()`），並說明 `bin/cash` 是 stable bootstrap path、其重述在一般升版中改不動——這正是不去碰它也不新增第五份重述的理由。

**修 G1** — task 1.1 的具名 scenario 清單移除 **Help 不繞過 receipt gate**，使 1.1／1.2／IC4 三處對該 scenario 的檔案歸屬一致。

**修 G2** — task 1.2 改寫為 characterization test 並明寫理由：該斷言描述變更前的現況，實作前後皆通過；它的作用是回歸鎖，確保實作 help 時沒有人為了讓 fresh clone 也能用 help 而把分流點移到 `validate_receipt` 之前。驗收改為「驗證該測試在實作前後皆通過」。

**修 G6** — tasks 1.1 與 IC4 明訂 handler 層的兩項斷言必須自行建立暫存 workspace 並以 `CASH_PROJECT_ROOT` 綁定，不得依賴呼叫者 cwd，也不得對真實 repository workspace 執行 recover，並附上 repo root vs `/tmp` 的實測差異作為理由。

**修 G5** — IC4 與 tasks 2.3 在五個負面案例之前加入必要的正向控制：以同一 harness、同一暫存位置、同一建立方式對由當前值派生的合法 fixture 斷言「接受」，否則任何使 fixture 不可達的執行錯誤都會讓負面案例 vacuous pass。

**修 G8** — spec 的「其對bundle version的治理 MUST限於」改為「其在本套件內**直接定義**的bundle version規則 MUST限於單一LF終止；格式判定 MUST委派給runtime既有的版本解析函式」，使「限於」約束的是定義而非呼叫，與同段的委派要求及同組要求一致。

**修 G9** — scenario GIVEN 收斂為「repository的replaceable inventory未漂移，且`cash-skills.version`為任一不低於`HEAD`版本的合法值」。

**修 G7** — proposal 的粗體絕對斷言改為「幾乎不提供額外覆蓋——它唯一多做的能力（攔到無正當理由的升版）在 design 的 Risks 中已明文評估並刻意捨棄」，與 design 一致。

**修正後的機械自檢與驗證** — 4 份 artifact comment/annotation 平衡皆 0/0；兩個 MODIFIED 標題與 master 逐 byte 相符；7 個新增 scenario 全數有 backing task；Impact 的 7 個含 `/` 路徑全部被 tasks 引用；ghost bold 為 0；無 lowercase `may`／`should`。重跑 `cash validate` 通過，`cash analyze` 非 Suggestion finding 為 0。

**Signal-derived checks** — 全部 open signal 無 `check` frontmatter，採 best-effort。本輪最相關者：`cross-artifact-definition-drift`（G3、G4 —— 我一直低估了這個 repo 裡格式規則的重述次數，而我的設計差點再加一份）、`acceptance-criterion-unreachable-at-specified-point`（G2、G6）、`execution-error-masked-as-pass`（G5）、`review-fix-propagation-incomplete`（G1）。

## Decision

next_round

post-filter cumulative blocking set 含 0 個 Critical 與 3 個 Warning（G1、G2、G3），未滿足 pass 條件。F1 已由兩位 checkpoint reviewer 一致以 verified resolution 離開集合。3 個 blocking 成員與 6 個非阻斷項皆已完成 fix 並記錄於 `## Fix Actions`。下一輪為本次執行的第五輪，非第四輪，故為 `micro` 輪，由單一 Reviewer V 對 G1–G3 逐一給出 resolved/unresolved 判定，並重點檢查本輪「格式判定改為委派」這項改設計是否引入新缺陷。
