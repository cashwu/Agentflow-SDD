# Cash Propose Review — Round 1

## Reviewer Findings

本輪為 unseeded 第一輪 full round，Reviewer A（Adherence）與 Reviewer B（Quality）平行獨立執行。以下為 `location + summary` 聚合並套用 confidence filter 之後的結果。

### Critical

- `severity`: Critical / `confidence`: 92 / `layer`: design / `location`: `specs/cash-cli/spec.md` ADDED requirement 第 2 段與 `Scenario: Identity 欄位形狀不合仍 fail closed`；`design.md` IC-6 / `summary`: 移除 device 比對後，launcher 只有 `int(row[4])` 而沒有範圍檢核，negative device 的 receipt 會被接受，與本 change 自己的 scenario 直接矛盾 / `recommendation`: launcher 補上與 `installer.py` `parse_receipt` 相同的「device 非負、inode 為正」判準，並補負向測試 / 來源：Reviewer A
- `severity`: Critical / `confidence`: 80 / `layer`: design / `location`: `proposal.md` `## Proposed Solution`、`design.md` D4、`tasks.md` 3.1 / `summary`: `launcher_update` 以精確 (old, new) 配對授權替換且無鏈式推導，只登錄一筆 transition 會讓 launcher 仍為 `592345fff…`、尚未升到 2.12.0 的 target 在 2.13.0 永久 fail closed，而該族群與本 change 要救的族群高度重疊 / `recommendation`: 追加 `(592345fff…, <new digest>, 2.13.0)` 這筆 skip transition；history gate 為成員檢查，多登錄相容 / 來源：Reviewer A 與 Reviewer B 獨立提出（A 判 Warning／80，B 判 Critical／75，取較高 severity 與較高 confidence）

### Warning

- `severity`: Warning / `confidence`: 88 / `layer`: design / `location`: `design.md` IC-11；`tasks.md` 1.1、2.2 / `summary`: ADDED requirement 的兩個診斷 scenario 的 WHEN 明寫涵蓋 installer preflight，IC-5 也對 installer 規定了訊息契約，但 IC-11 的四個測試全部只針對 launcher，task 2.2 的驗收也只引用「preflight 不失敗」，installer 端訊息原樣不動也會全綠 / `recommendation`: 補 installer 端 content／identity 兩支訊息的測試，並改寫 task 2.2 驗收 / 來源：Reviewer A（Reviewer B 第 9 條同類）
- `severity`: Warning / `confidence`: 85 / `layer`: design / `location`: `tasks.md` 2.3 驗收 / `summary`: 驗收引用「launcher migration rollback 測試」，但 `scripts/cash-skills/tests/` 中不存在任何涵蓋 rollback 或 `rebind_receipt_stable_identity` 的測試，該驗收條件無法機械執行 / `recommendation`: 改為指名實際存在的測試，或改成可執行的 diff 判準 / 來源：Reviewer A
- `severity`: Warning / `confidence`: 82 / `layer`: design / `location`: `specs/cash-cli/spec.md` ADDED scenarios；`tasks.md` 1.1、2.3、5.3 / `summary`: 八個 scenario 中有四個沒有任何 task 或測試支撐，唯一兜底是 task 5.3 的人工敘述 / `recommendation`: 建立逐 scenario 對照表並把缺口補進測試清單 / 來源：Reviewer A（Reviewer B 第 9 條同類）
- `severity`: Warning / `confidence`: 80 / `layer`: design / `location`: `design.md` IC-2／IC-5 第 1 支；spec delta 分類第 1 條 / `summary`: 把 mode 漂移歸入 content drift 會與既有契約矛盾——`--init-receipt` 依 `Target-local receipt 初始化` requirement 正是 mode 正規化的授權入口，而 launcher 對 mode 漂移在進入 receipt gate 前就以 `bootstrap_invalid` 失敗、既有 guidance 對該碼的處置就是執行 `--init-receipt`，同一狀態會從兩個 gate 拿到相反指引 / `recommendation`: 分類軸改為只用 digest，mode 與 inode 一併歸 identity drift / 來源：Reviewer B

### Suggestion（經 confidence filter 由 Critical／Warning 降級，或原即為 Suggestion）

- `confidence`: 78 / `layer`: design / `location`: `design.md` D2／IC-2／IC-3；spec delta 第 2 類診斷 / `summary`: launcher 的 stable record 迴圈執行於 runtime digest 比對之前，installer 也在累積 runtime conflicts 前就丟例外，因此「stable inode 被換掉且 runtime 同時被竄改」的 target 會先拿到 `--init-receipt` 指引，而該模式不比對 runtime bytes，等於把竄改簽成合法 / 來源：Reviewer B（原判 Critical／78，未達 80 門檻）
- `confidence`: 78 / `layer`: design / `location`: spec delta MODIFIED `Bundle 安裝與 runtime receipt` 的 `#### Scenario: Invalid receipt fail closed` / `summary`: 正文已把 `device/inode` 消歧為「欄位形狀」，但保留的 scenario GIVEN 仍逐字寫 `device/inode`，與 ADDED requirement 字面衝突 / 來源：Reviewer A 與 Reviewer B 獨立提出（78／75）
- `confidence`: 75 / `layer`: design / `location`: `design.md` IC-8／IC-9；`tasks.md` 4.1、4.4 / `summary`: MODIFIED requirement 新增了 guidance 必須載明的條款，但驗證只有 baseline SHA-256 重算；digest 只能偵測漂移，任何寫錯內容的區塊只要重算就會全綠，與該檔既有以 `assert_contains` literal 守衛契約條款的作法不一致 / 來源：Reviewer A
- `confidence`: 72 / `layer`: design / `location`: `proposal.md` `## Non-Goals` 第 2 條；`design.md` `## Risks / Trade-offs` / `summary`: transaction journal 的排除理由「只在 crash 與下一次 installer 執行之間短暫存在」事實不成立——留下 journal 的事件與 volume 重新編號的事件是同一件事，且 rollback identity 比對失敗會保留 journal 並鎖死 target，不是 fail-safe / 來源：Reviewer B
- `confidence`: 70 / `layer`: design / `location`: spec delta「兩個gate的診斷 SHALL分成兩類」；`design.md` IC-2／IC-5 / `summary`: 全稱句宣告兩類，但實作至少還有 record 缺失、stable path 缺檔、形狀／mode 由 `open_regular` 產生 `bootstrap_invalid` 三個出口不落在任一類 / 來源：Reviewer B
- `confidence`: 70 / `layer`: design / `location`: `design.md` IC-5 / `summary`: installer 是從 source repository 對別的 target 執行，沿用 launcher 的「from the project root」措辭會引導使用者在 source repo 執行而必然得到 `init_source_repo` / 來源：Reviewer B
- `confidence`: 70 / `layer`: design / `location`: `design.md` D1「為何移除不損失偵測力」 / `summary`: `.cash-workspace.lock` 的 digest 是空內容的 SHA-256，對它沒有鑑別力，因此 D1 的論證對 lock 是空論證，移除 device 後 lock 的 identity 完全由 inode 承擔，而 identity drift 指引會把被替換的 lock inode 洗白 / 來源：Reviewer B
- `confidence`: 62 / `layer`: design / `location`: spec delta `#### Scenario: 未修復的 target 不因 identity drift 被自動改寫` / `summary`: GIVEN 的「installer 正持有 exclusive lock」在一般路徑不可達——`validate_installed_receipt` 的呼叫早於 `acquire_lock` / 來源：Reviewer A
- `confidence`: 62 / `layer`: design / `location`: `design.md` D2 末段／IC-3 / `summary`: launcher 的 `is_source_layout` 以 contract mode 精確相等為條件，而 `--init-receipt` 的 source 判定依既有 requirement 明確不得以 mode 相等為條件，兩者定義域不同時使用者會拿到一條會失敗的指令 / 來源：Reviewer B
- `confidence`: 62 / `layer`: design / `location`: `tasks.md` 2.1／3.2；`design.md` D4 / `summary`: 本 repo 自身是 manifest-present target，launcher bytes 一改，manifest 重新發佈之前本 repo 的 cash CLI 會以 `manifest_invalid` 不可用，而該窗口橫跨多個 task / 來源：Reviewer B
- `confidence`: 55 / `layer`: design / `location`: `openspec/specs/cash-cli/spec.md` `Target 版控排除保護`（原未列入 MODIFIED）；`installer.py` version-control diagnostic / `summary`: 該 requirement 的理由句與 installer 的使用者可見診斷仍把 device 描述為保護的一部分，在 device 不再參與比對後會誤導 / 來源：Reviewer B
- `confidence`: 50 / `layer`: design / `location`: `proposal.md` `## Non-Goals` 第 3 條 / `summary`: 本 change 落地後，archive 的 `legacy_cleanup: preserved_drift` 會是 device 重新編號唯一殘留的使用者可見症狀，而該狀態字串不區分內容漂移與 volume 重新編號 / 來源：Reviewer B

## Rating

- post-filter cumulative blocking set Critical count：2
- post-filter cumulative blocking set Warning count：4
- 非 blocking triaged finding count：12
- `critical_gap`: true
- `round_type`: full

rationale：本輪為 unseeded 第一輪，全部通過 confidence filter 的 Critical 與 Warning 皆為 blocking。兩個 Critical 都是可證實的契約缺口：一個會讓 `st_dev` 同時失去比對與範圍兩道閘門並直接違反本 change 自己的 scenario；另一個會讓本 change 想拯救的 target 族群在升級時永久 fail closed。四個 Warning 分別是分類軸錯誤與三項覆蓋／可執行性缺口。因此決定 `next_round`。

## Fix Actions

修改檔案：`openspec/changes/tolerate-remount-device-renumbering/proposal.md`、`design.md`、`specs/cash-cli/spec.md`、`tasks.md`（共 4 個檔案，全部位於 change 目錄內）。

blocking findings 的處置，每筆一個 fix：

1. **launcher device 形狀閘門**（Critical／92）：新增 IC-2 要求 launcher 補上與 `parse_receipt` 相同的「device 非負、inode 為正」判準；ADDED requirement 第 2 段改寫為「兩個 gate 採用相同形狀判準」並說明理由；scenario 改寫為 `Negative device 的 receipt 在兩個 gate 皆 fail closed`；IC-14 與 task 1.1 加入 `-1` 的負向測試；proposal `## Proposed Solution` 一 改寫該段陳述。
2. **launcher transition 鏈斷點**（Critical／80）：design D5 改為登錄兩筆並寫出理由與 history gate 的成員檢查性質；IC-10、task 3.1 同步；proposal 新增 `## Proposed Solution` 五 說明；task 5.2 增加「launcher 停在 `592345fff…` 的 fixture target 可升級」的端到端驗證。
3. **installer 診斷無測試**（Warning／88）：IC-14 建立逐 scenario 對照表，其中 content drift、identity drift、mode 漂移、指引位置四項各含 installer 案例；task 1.1 改為涵蓋十一個案例並明列 launcher／installer 兩側；task 2.2 驗收改為引用 installer 案例。
4. **scenario 無 task 支撐**（Warning／82）：IC-14 對照表逐條覆蓋十一個 scenario；task 5.3 由「人工逐條敘述」改為「核對對照表並指向具體測試函式名稱」。
5. **task 2.3 引用不存在的測試**（Warning／85）：拆為 task 2.4，驗收改為 `git diff` 判準加上三個實際存在的測試函式名稱（`test_invalid_receipt_is_execution_error_not_domain_result`、`test_managed_mode_drift_is_conflict_without_force`、`test_launcher_transition_and_journal_v3_contract_surface_is_explicit`），已逐一 grep 確認存在。
6. **mode 漂移分類錯誤**（Warning／80）：分類軸改為只用 digest；design D2 改寫並寫出「為何 mode 屬 identity drift」的契約理由；ADDED requirement 分類第 2 條加入 mode 並說明；新增 `#### Scenario: Mode 漂移歸入 identity drift`（以 installer 為驗證面，因為 launcher 的 `open_regular` 使該狀態在 launcher 端不可達）；IC-3、IC-14、task 1.1 同步。

非 blocking triaged findings 的處置。以下 11 筆雖不 blocking，但修法明確且成本低，已一併修正，各記一則 triage 註記：

7. runtime 同時漂移時的指引前提（78）：新增 IC-4 與 `#### Scenario: 其餘 records 同時漂移時不提供重新簽發指引`，design 新增 D3 說明執行序與理由。
8. `Invalid receipt fail closed` scenario GIVEN（78）：GIVEN 改為 `device/inode 欄位形狀` 並補一條 AND 明確排除 device 值不符。
9. guidance 只靠 baseline digest（75）：IC-12 要求三條新 `assert_contains` literal 與 baseline 重算並行；task 4.4 驗收加入「刻意刪掉任一條新 literal 時套件以非零結束」。
10. journal Non-Goal 理由事實錯誤（72）：proposal Non-Goal 第 2 條與 design Risks 改寫，承認 crash 與 reboot 的相關性與硬鎖死後果，並把排除理由限定為範圍決定。
11. 分類未窮盡（70）：ADDED requirement 新增一段明列三個不屬於本分類的 fail-closed 出口與判定順序。
12. installer 指引位置（70）：IC-7 要求 installer 訊息內嵌 target 路徑；ADDED requirement 新增措辭段與 `#### Scenario: Installer 的指引指向目標專案而非來源專案`。
13. lock digest 無鑑別力（70）：design D1 新增該前提說明、Risks 新增專條，並在 IC-11 要求 guidance 明寫重新簽發的前提；proposal `## Alternatives Considered` 新增「把 lock 排除在指引之外」並說明捨棄理由。
14. no-auto-rebind scenario GIVEN 不可達（62）：GIVEN 與 THEN 改寫為「installer 在取得 exclusive lock 之前即以 identity drift 失敗」。
15. 本 repo CLI 中斷窗口（62）：task 3.2 加入排序註記，design Risks 併入該條。
16. 版控保護理由句與診斷字串（55）：`Target 版控排除保護` 加入 MODIFIED（第三個 MODIFIED requirement），理由句改為只引用 `st_ino` 並加上 diagnostic 的 MUST NOT；新增 task 2.3 修改 `installer.py` 的診斷字串；scenario 補一條 AND。
17. archive 殘留症狀（50）：proposal Non-Goal 第 3 條補上該說明。

未修正並記為 triage 註記者一筆：

18. `is_source_layout` 與 `--init-receipt` source 判定不同源（62／Reviewer B）：不修改。理由是該不一致的後果並非死路——`--init-receipt` 會以具名的 `init_source_repo` 失敗，而該診斷本身就指向 `./install-cash-skills.fish --self`，因此是一步繞路。統一兩個判定會把 launcher 的 source 偵測拉進本 change 範圍。已在 proposal `## Non-Goals` 明列並在 design `## Risks / Trade-offs` 記錄該取捨。

fix 傳播：分類軸由「digest 或 mode」改為「digest」這個概念，已在 proposal、design D2／IC-3、spec delta 分類段與四個相關 scenario 中同步；scenario 數量由 8 改為 11，已同步 design IC-14 對照表列數（11）與 tasks 1.1／5.3 的敘述。

post-fix mechanical self-check：spec delta 的 `<!--`／`-->` 計數皆為 0 且無殘留 `@trace` 或 `---`；ADDED scenario 數 11 與 IC-14 對照表列數 11 一致，tasks 的「十一」敘述一致；三個 MODIFIED requirement 的 title 逐 byte 存在於 master spec；design 與 tasks 引用的 `make_self_source`、`parse_receipt`、`open_regular`、`BUNDLE_RUNTIME_PATHS` 與四個測試函式名稱皆已 grep 確認存在於真實檔案。無 signal 具有 `check` frontmatter 欄位，故 signal-derived check 無可執行項。

fix 後已重新執行 `validate`，結果為 Validation passed。本輪 Fix Actions 修改的檔案全部位於 `openspec/changes/` 之下，依 touched 記錄規則濾除後為空，因此未呼叫 Cash CLI 的 touched 指令，亦無警告。

## Decision

next_round

兩個 blocking Critical 與四個 blocking Warning 皆已修正，但依 cumulative blocking set 的規則，它們必須由下一輪 reviewer 給出明確的 resolved 判定才能離開集合。下一輪為本 run 的第 2 輪，依位置推導為 `micro`，由 Reviewer V 對 cumulative blocking set 逐筆驗證並檢查 fix 是否引入新缺陷。
