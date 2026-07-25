# Cash Propose Review — Round 7

本輪是 re-run 的第一輪（前一次執行於第六輪達 6 輪上限而 `aborted`）。輪次自 7 續編，round type 依 re-run 內位置推導為第一輪，故為 `full`：spawn 兩個 fresh reviewer 平行執行完整重掃，並各自對 seeded cumulative blocking set 給出 resolved/unresolved 判定。

## Reviewer Findings

### Seeded cumulative blocking set 判定（bucket 1，兩位 reviewer 各自判定）

| member | Reviewer A | Reviewer B | 合併判定 |
| --- | --- | --- | --- |
| F1（注入路徑計數矛盾） | resolved | resolved | **resolved** |
| F2（recovery 寫入 vs conflict 零寫入契約） | resolved | resolved | **resolved** |

兩位 reviewer 皆逐一以 artifact 現況與源碼核對而非採信 round file 敘述。F1：design IC5 與 tasks 2.3 現皆為「六個測試／三條注入路徑」，(a)(b)(c) 各兩個測試共六個，與 `test_installer_runtime.py` 的 `:394`／`:868`（`install` helper 的 `TEST_` 轉譯）、`:1839`／`:1855`（`os.environ` + `install_from` 繼承）、`:1586`／`:1741`（自建 `environment` + `Popen`）完全一致，`run_installer` 確認無 hook 測試使用。F2：carve-out 已在 delta spec recovery 段、IC2 與 tasks 1.2 三處到位，且與被牴觸的 `#### Scenario: Current、newer 與 conflict 分類` 落在同一個 requirement 內因而有效。兩者皆以 verified resolution 離開 cumulative set，該集合在本輪開始時清空。

### Critical

**H1**
- `severity`: Critical
- `confidence`: 85
- `layer`: design
- `location`: specs/cash-cli/spec.md `Installer fault-injection hooks 治理` requirement 本文與 `#### Scenario: 兩個 hold hook 各自記帳`；design.md `### IC3`；tasks.md 1.3
- `summary`: 「兩者指向同一路徑時亦如此」（publication hook 仍正常等待）與同一 requirement 的 ready 檔 exclusive 建立、release 檔在等待點不得預先存在兩條 MUST 互斥，該 AND 子句與 tasks 1.3 的對應斷言無法同時滿足。
- `failure_scenario`: 兩個 hook 皆設為同一路徑 `P`。hook 1 在 `installer.py:1303` 以 exclusive 語意建立 `P.ready` 並等待，呼叫端建立 `P.release` 解除。記帳鍵為 hook，故 hook 2（`:1403`）不在免除範圍：進入等待點時 `P.release` 已存在（`wait_for_test_hold` 從不刪除它）→ 依「等待點進入時已存在 MUST 以 execution error 中止」必須中止；即使跳過該關，`P.ready` 已存在也會使 exclusive、no-follow 建立以 `EEXIST` fail closed。「仍正常等待」在同路徑情形下無任何實作可達成。
- `recommendation`: 要求兩個 hook 同時啟用時 hold 路徑互異，相同時於 preflight fail closed；scenario 的 AND 改為斷言該 fail-closed。
- `disposition`: `fix-introduced`
- `introduced_by`: `reviews/propose-r4.md` `## Fix Actions` 的「**修 G15** — design IC3 新增「at-most-once 的記帳鍵 SHALL 為 hook 本身而非 hold 路徑」並具名兩個 hook；spec requirement 同步；新增 `#### Scenario: 兩個 hold hook 各自記帳`；tasks 1.3 加入對應斷言。」
- reviewer source: Reviewer B。

### Warning

**H2**
- `severity`: Warning
- `confidence`: 90
- `layer`: design
- `location`: specs/cash-cli/spec.md `#### Scenario: Hold 協定不安全形狀 fail closed`；tasks.md 1.3
- `summary`: 該 scenario 把七種 WHEN 併到單一 THEN「在首次 target write 前以 execution error 失敗」，但其中「release 檔在該 hook 的等待點進入時才出現」與「release 檔不是非 symlink 的 regular file」只可能在等待點偵測，而等待點在 `acquire_lock` 之後；fresh target 此時 workspace lock 已建立，該 THEN 不可達。
- `failure_scenario`: fresh target、開關開啟、hold 路徑合法。preflight 通過（release 當下不存在）→ `installer.py:1301` 的 `acquire_lock` 以 `O_CREAT|O_EXCL` 建立 `.cash-workspace.lock`（首次 target write 已發生）→ `:1303` 進入等待點才看到外部出現的 release 檔。tasks 1.3 逐字要求這些形狀「在首次 target write 前以 execution error 失敗（含 fresh target 未建立 workspace lock）」，該斷言必然失敗；實作者唯一能讓它通過的做法是把等待點前移，而那直接違反同一份 spec 的「hold 的等待點 MUST 維持在既有位置」。
- `recommendation`: 拆成兩個 scenario——preflight 可判定的形狀維持「首次 target write 前 fail closed」，等待點才可判定的形狀改為「在等待點以 execution error 中止、不被當成解除訊號、不提交任何 transaction operation」，且不主張零 target write。
- `disposition`: `fix-introduced`
- `introduced_by`: `reviews/propose-r4.md` `## Fix Actions` 的「**修 G8** — …`Hold 協定不安全形狀 fail closed` 的 WHEN 拆為「release 檔在 preflight 已存在」與「release 檔在該 hook 的等待點進入時才出現」兩種情形；tasks 1.3、2.3 同步。」——該次擴充把等待點才可判定的形狀併進了原本只涵蓋 preflight 形狀的 THEN，等於把 r1 的 W2（同一 scenario、同一機制）重新引入。
- reviewer source: Reviewer A（confidence 90）與 Reviewer B（confidence 85）獨立提出同一問題。

**H3**
- `severity`: Warning
- `confidence`: 85
- `layer`: design
- `location`: design.md `### IC2`；specs/cash-cli/spec.md `#### Scenario: Crash 後首次執行即完成恢復`；proposal.md `## Proposed Solution` 第 2 點
- `summary`: F2 的 carve-out 規定「recovery 之後若仍存在與該 journal 無關的 drift，installer MUST 回報 `conflict`、exit 2」，但同一批 artifact 三處仍以「無併發 installer 介入時該分類 SHALL 為 `update`，且 SHALL NOT 為 `conflict`」無條件斷言，對同一輸入給出相反的必須結果。
- `failure_scenario`: target 版本不高於 incoming bundle、留有 publishing journal，且另有一個與該 journal 無關的 managed path 被改動（無併發 installer）。此輸入同時滿足 IC2 的「無併發 installer 介入 → SHALL NOT 為 conflict」與 carve-out 的「SHALL 回報 conflict」；scenario 的 GIVEN 同樣涵蓋此輸入而 THEN 禁止 `conflict`。實作者依 spec 寫驗收時兩條斷言必有一條失敗，且該 scenario 會隨 archive 永久進入 master spec。
- `recommendation`: 三處各加上「且 recovery 之後不存在與該 journal 無關的 drift」的限定。
- `disposition`: `fix-introduced`
- `introduced_by`: `reviews/propose-r6.md` `## Fix Actions` 的「**修 F2（recovery 寫入 vs conflict 零寫入契約）**」——該 fix 新增了例外，但未回頭修正三處與該例外互斥的既有斷言。
- reviewer source: Reviewer A。

**H4**
- `severity`: Warning
- `confidence`: 85
- `layer`: design
- `location`: design.md `### D2` 第 2 步、`### IC2`；specs/cash-cli/spec.md recovery 段；tasks.md 1.2、2.2；`.cash-skills/lib/cash_cli/installer.py:1238-1243, 1255-1263, 1277-1290`
- `summary`: 恢復點的錨定只列舉 `managed target drift` 這一個返回點，但在它之前還有兩處會提前返回的分類分支，照字面把恢復放在「conflict 判定之前」仍會讓 fresh install 崩潰與 legacy migration 崩潰兩種殘留 journal 永遠到不了 recovery，而所指定的測試全數通過。
- `failure_scenario`: fresh target 首次安裝在 skills 發布途中崩潰（receipt 是最後一筆 operation，故 target 無 receipt、留有 publishing journal、24 個 skill 中已發布 1–23 個）。下一次執行：`receipt_snapshot.exists` 為偽 → `target_version` 為 `None` → 不走 `newer` early return → 落入 receipt-less 分支 → `len(present_skills) not in {0, 24}` 於 `:1259` 直接以 `receipt-less Cash skill inventory is partial`（`conflict`、exit 2）返回，該處在 `:1277` 的 `managed target drift` 之前。legacy migration 崩潰同理命中 `:1243` 的 `legacy receipt drift`（exit 1）。tasks 1.2 的 fixture 明寫建立在已安裝 target 上，因此規定的測試不會捕捉這兩種情形。
- `recommendation`: 把錨定改寫為「緊接在 `newer` early return 之後、且早於全部三個提前返回分支」並具名列出；tasks 1.2 增列 receipt-less 與 legacy 兩種 journal 起點的 fixture。
- `disposition`: `new`
- reviewer source: Reviewer B。主 agent 已核對 `installer.py` 確認三個返回點的相對位置。

### Suggestion（經 confidence filter 降級或原為 Suggestion，皆非阻斷）

- **H5**（72，`fix-introduced`）通用 diagnostic 被要求在版本比較之前發出，卻同時被要求讓操作者得知「需版本相符或更新的 installer 才會恢復」——後者對絕大多數非 `newer` target 是錯誤資訊；且該 AND 子句在 tasks 與 IC5 皆無對應斷言。
- **H6**（70，`new`）「`.cash-skills/lib/cash_cli/` 底下的 `.py` 檔數維持不變」未指明是否遞迴，而決定 operation 序號的實際判準是 `library.rglob("*.py")`（19 個，含 `commands/` 下 10 個）；非遞迴讀法只會數到 9 個，在 `commands/` 新增模組仍會位移 `CASH_INSTALL_FAIL_AFTER = "47"` 而使該測試靜默失效。
- **H7**（60，`unresolved-prior`）F1 的 helper 改述只落在 tasks.md，design IC5 仍為「三個 helper（`install`、`install_from`、`run_installer`）」，緊接在 (a)(b)(c) 三條路徑之後容易被讀成一對一，而 (c) 實為測試自建 `environment`、與 `run_installer` 無關。
- **H8**（60，`new`）`newer` 排除以 receipt 版本為判準，但 receipt 是 transaction 的最後一筆 operation，較新 bundle 崩潰時 target 仍持有舊 receipt，因此「本 bundle 不認識的 journal schema」這個被具名的風險恰恰落在不會被排除的路徑上；該情形下 `recover_installer` 會以 `cannot recover installer journal` exit 1 且 `--force` 無從繞過。
- **H9**（55，`new`）Non-Goal 宣告「不變更 lock 的建立機制」，但 IC2 要求恢復前置階段的取鎖不得建立不存在的 lock，這需要一條與現行 `acquire_lock` 建立分支不同的取鎖路徑，而 tasks 4.2 的驗收又逐字要求「lock 的建立機制未改變」。
- **H10**（45，`new`，**經 confidence filter 丟棄**）journal 偵測未比照 hold 檔要求 no-follow／regular-file 判定，dangling symlink 會讓偵測靜默回報「無 journal」。confidence < 50 依規則丟棄，此處保留 downgrade trace。

## Rating

- post-filter cumulative blocking set Critical count: **1**（H1）
- post-filter cumulative blocking set Warning count: **2**（H2、H3）
- 非阻斷 triaged finding count: **6**（H4、H5、H6、H7、H8、H9；H10 因 confidence < 50 丟棄，僅留 trace）
- `critical_gap`: **true**
- `round_type`: **full**

rationale：seeded 的 F1、F2 由兩位 reviewer 一致以 verified resolution 判定 resolved，bucket 1 的義務已清空——re-run 的前提成立。本輪的價值在於 full 重掃再次抓到只靠 delta 驗證看不到的東西：H4 是其中最重要的一項，它顯示前一次執行第四輪起就寫定的「恢復必須早於 conflict 判定」這個錨定用詞太窄——`install_target` 在 `managed target drift` 之前還有 `legacy receipt drift` 與 `receipt-less Cash skill inventory is partial` 兩個提前返回分支，而 fresh install 崩潰恰恰命中後者。也就是說本變更的頭號賣點在「全新安裝途中崩潰」這個最典型的情境下仍然不成立，而前六輪指定的 fixture 全部建立在已安裝 target 上，測試不會捕捉。H1 與 H2 則是兩條互斥 MUST 的直接對撞，皆為前幾輪 fix 擴充枚舉時引入。H4 依 disposition 規則為 `new` 而非阻斷，但其嚴重性高於兩個 blocking Warning，已在本輪一併修復。

## Fix Actions

三個 blocking 成員（H1、H2、H3）與六個非阻斷項（H4–H9）全部修復，另主動修復經 confidence filter 丟棄的 H10。無 grader-protection 保留項，無 accepted-risks 條目。修改檔案共 4 個：`proposal.md`、`design.md`、`tasks.md`、`specs/cash-cli/spec.md`。

**修 H1（兩個 hook 同路徑不可達）** — design D3 第 2 點與 IC3 新增「兩個 hook 同時啟用時其 hold 路徑 SHALL 互異；相同時 SHALL 在 preflight 以 execution error fail closed」，並說明記帳獨立不足以讓兩者共用一條路徑（第二個 hook 必然同時撞上 ready 已存在與 release 已存在兩條規則）；spec requirement 同步；`#### Scenario: 兩個 hold hook 各自記帳` 的 AND 由「兩者指向同一路徑時亦如此」改為「MUST 在 preflight 以 execution error fail closed，而非讓第二個 hook 在等待點才失敗」；tasks 1.3 的斷言同步改為「publication hook 設在另一條路徑仍正常等待」加上「兩者同路徑時 preflight fail closed」。

**修 H2（preflight 與等待點兩類形狀混用同一 THEN）** — spec 的 `#### Scenario: Hold 協定不安全形狀 fail closed` 拆為兩個 scenario：`#### Scenario: Preflight 可判定的 hold 設定錯誤 fail closed`（五種形狀加上「兩個 hook 的 hold path 相同」，維持「首次 target write 前 fail closed」）與 `#### Scenario: 等待點才可判定的 hold 形狀在等待點中止`（release 於等待點才出現、到等待點才被換成 symlink，改為「在該 hook 的等待點以 execution error 中止、不被當成解除訊號、不提交任何 transaction operation」）。requirement 本文加入同一區分並說明後者不得主張零 target write；design IC3 同步；tasks 1.3 的斷言分為兩組。

**修 H3（carve-out 與無條件 update 斷言互斥）** — design IC2、spec 的 `#### Scenario: Crash 後首次執行即完成恢復` 與 proposal `## Proposed Solution` 第 2 點三處，皆加上「且 recovery 之後不存在與該 journal 無關的 drift」的限定，並在 IC2 補一句說明有殘留 drift 時 `conflict` 是正確結果；tasks 1.2 註明兩個案例互斥、差別只在 recovery 之後是否仍有無關 drift。

**修 H4（恢復錨定只擋一個返回點）** — design D2 第 2 步改為「緊接在 `newer` early return 之後」並具名列出三個必須被繞前的返回點（`legacy receipt drift`、`receipt-less Cash skill inventory is partial`、`managed target drift`），說明 fresh install 崩潰命中 receipt-less 分支、legacy migration 崩潰命中 legacy 分支；IC2 與 spec requirement 同步；新增 `#### Scenario: Receipt-less 與 legacy 崩潰同樣先恢復`；tasks 1.2 增列兩個 fixture（「無 receipt、24 個 skill 中已發布 1–23 個」與「legacy receipt 尚未被替換」），2.2 與 proposal 第 2 點同步。

**修 H5（diagnostic 語意混用）** — 拆為兩段輸出：偵測點輸出與分類無關的通用句（僅陳述存在未完成 journal），`newer` early return 之前另外輸出 newer 專屬補充句；design IC2、spec requirement 與 `#### Scenario: Newer target 帶未完成 journal 仍零寫入` 的 AND 同步；tasks 1.2 加入對兩段輸出的斷言。

**修 H6（`.py` 檔數判準未指明遞迴）** — design IC5、`## Risks / Trade-offs` 與 tasks 4.1 三處改為「含子目錄，即 `library.rglob("*.py")` 排除 `__pycache__` 後的結果，現為 19 個」，並註明非遞迴清點只會數到 9 個而漏掉 `commands/` 下的 10 個。

**修 H7（IC5 helper 措辭未隨 F1 更新）** — design IC5 改為與 tasks 2.3 相同的措辭，並補一句「helper 數與注入路徑數不對應：(c) 是測試自建 `environment` 交給 `subprocess.Popen`，與 `run_installer` 無關」。

**修 H8（跨版本 journal schema）** — design D2 補一段說明 `newer` 排除的判準是 receipt 版本，而 receipt 是最後一筆 operation，因此較新 bundle 在 publishing 階段的崩潰不會被排除；新增規則「journal 的 schema version 不被本 bundle 辨識時 SHALL 以 execution error fail closed，且 diagnostic SHALL 指出需要版本相符或更新的 installer」；spec 與 tasks 1.2、2.2 同步。

**修 H9（Non-Goal 與不建立 lock 的取鎖路徑）** — proposal `## Non-Goals`、design `## Goals / Non-Goals` 與 tasks 4.2 三處的 caveat 由一項擴為兩項，明列「恢復前置階段使用一條不走建立分支的取鎖路徑」為第二項例外，並說明既有建立語意與 identity 重驗步驟本身不變。

**主動修復經丟棄的 H10** — 該 finding confidence 45 低於 filter 門檻而被丟棄，但其指出的不一致為真且修法只需一個子句：design IC2 與 spec 的偵測條款補上「偵測 SHALL 以 no-follow 的 `lstat` 判定形狀，`JOURNAL_PATH` 非 regular file（含 symlink）時 SHALL 以 execution error fail closed，SHALL NOT 靜默視為無 journal」；tasks 1.2 加入對應斷言。此處記錄為 downgrade trace 加主動修復，該 finding 不計入任何 rating 計數。

**修正後的機械自檢與驗證** — 重跑 pre-round mechanical self-check：4 份 artifact 的 comment/annotation 平衡皆為 0/0；兩個 MODIFIED requirement 標題與 master spec 逐 byte 相符；新增 scenario 由 18 增至 20（新增 `Receipt-less 與 legacy 崩潰同樣先恢復` 與拆分後的 `等待點才可判定的 hold 形狀在等待點中止`），全數在 tasks.md 有 backing task 且無單向缺漏；ghost bold name 為 0；殘留措辭掃描（`四條`、舊 scenario 名 `Hold 協定不安全形狀`、`兩者指向同一路徑時亦如此`、`三個 helper（`）全數為 0；proposal `## Impact` 中含 `/` 的三個 code span 皆在 tasks.md 出現；無 lowercase `may`／`should`。重跑 `cash validate` 通過，`cash analyze` 四個維度皆為 0 finding。

**Signal-derived checks** — `openspec/signals/` 下全部 open signal 仍無 `check` frontmatter 欄位，採 best-effort 判斷。本輪最相關者：`acceptance-criterion-unreachable-at-specified-point` 對應 H2（等待點形狀被塞進「首次 write 前」的 THEN）；`multi-operation-phase-order-undefined` 對應 H4（恢復點與三個提前返回分支的相對順序）；`new-scope-contradicts-unamended-contract` 對應 H3（新 carve-out 與既有無條件斷言互斥）；`review-fix-propagation-incomplete` 對應 H3、H7（fix 未回頭掃既有互斥斷言與另一份 artifact）；`enumerated-site-set-factually-wrong` 對應 H4、H6（枚舉的返回點與檔案集合與實際不符）。

## Decision

next_round

post-filter cumulative blocking set 含 1 個 Critical（H1）與 2 個 Warning（H2、H3），未滿足 pass 條件。seeded 的 F1、F2 已以 verified resolution 離開集合。三個 blocking 成員與六個非阻斷項皆已完成 fix 並記錄於 `## Fix Actions`，另主動修復一個被丟棄的 finding。下一輪為本次 re-run 的第二輪，非第四輪，故為 `micro` 輪，由單一 Reviewer V 對 H1、H2、H3 逐一給出 resolved/unresolved 判定，並重點檢查本輪對恢復錨定與 hold scenario 拆分的大幅改寫是否引入新缺陷。
