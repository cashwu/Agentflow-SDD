# Cash Propose Review — Round 4

## Reviewer Findings

本輪為第四輪 full checkpoint，spawn 兩個 fresh reviewer（Reviewer A — Adherence、Reviewer B — Quality）平行執行完整重掃，並各自對 cumulative blocking set 成員給出 resolved/unresolved 判定。

### Cumulative blocking set 判定

| member | Reviewer A | Reviewer B | 合併判定 |
| --- | --- | --- | --- |
| F1 | resolved | resolved | **resolved** |

兩位 checkpoint reviewer 皆確認免除範圍已同時涵蓋 ready 與 release 檔，且在 design D3／IC3／IC5、spec requirement、scenario、tasks 1.3／2.3 共七處一致；舊名 `不因自身 ready 檔而失敗` 與 `Hold path 不安全形狀` 在 4 份 artifact 中零殘留；對偶 scenario 的前提互斥子句已在位。Reviewer B 另覆核 per-hook 記帳對 `installer.py:1303` 與 `:1403` 兩個不同 hook 成立。F1 以 verified resolution 離開 cumulative set，該集合在本輪開始時清空。

### Critical

**G1**
- `severity`: Critical
- `confidence`: 100
- `layer`: design
- `location`: tasks.md 4.1 與 4.2；`scripts/cash-skills/tests/skill-checks.fish:38`；proposal.md `## Impact`
- `summary`: 4.1 要求 `cash-skills.version` 嚴格遞增，但 `skill-checks.fish:38` 以字面值釘住 `test (string trim <"$root_dir/cash-skills.version") = 2.1.0`，而 4.2 又要求該套件全數通過——兩個 task 互相矛盾，且唯一解法是改動 grader-protected 的 `scripts/cash-skills/tests/skill-checks.fish`，該路徑既未列於 `## Impact` 也未在 tasks.md 宣告為交付目標。
- `recommendation`: 在 proposal `## Impact` 的 Modified 清單加入該檔並在 tasks 4.1 明寫同步更新釘住的字面值，使該修改落在已宣告範圍內。
- `disposition`: `new`
- reviewer source: Reviewer A。主 agent 已核對 `skill-checks.fish:38`，字面值確為 `2.1.0`，確認成立。

**G2**
- `severity`: Critical
- `confidence`: 95
- `layer`: design
- `location`: design.md `### D2`／`### IC2`；specs/cash-cli/spec.md `#### Scenario: Crash 後首次執行即完成恢復`；tasks.md 1.2；`.cash-skills/lib/cash_cli/installer.py:1216-1290` vs `:1346`
- `summary`: D2 指定的恢復機制掛在 `recover_installer` 的現有呼叫點，但該點位於 conflict 分類之後；只要半發布 bytes 落在任何 receipt-managed path（正是新 scenario 的 GIVEN 與 tasks 1.2 fixture 明寫的狀態），`validate_installed_receipt` 會把那些 path 收進 conflicts，執行就以 `managed target drift`、exit 2 返回，recovery 永遠不會被呼叫，因此「單次執行內完成恢復並回報 `update`」不可能達成。
- `recommendation`: 把 journal 偵測與恢復拉成一個位於 conflict 判定之前的前置階段；IC2 增列「未完成 journal 存在時 SHALL NOT 先以 conflict 返回」；tasks 1.2 的斷言加上「不出現 `Result: conflict`」。
- `disposition`: `new`
- reviewer source: Reviewer B（附本機 fixture 實測）。主 agent 獨立重現確認：對已安裝 target 半發布 `.cash-skills/lib/cash_cli/resources.py` 並放入 `phase: publishing` journal 後，真實執行與 `--dry-run` 皆輸出 `Result: conflict`、rc 2，journal 原封不動留在原地。本變更原始 repro 之所以能走到 recovery，是因為當時半發布的是 `CLAUDE.md`（guidance，非 receipt-managed），屬 conflict 判定看不見的少數檔案。

### Warning

**G3**
- `severity`: Warning
- `confidence`: 88
- `layer`: design
- `location`: tasks.md 2.3 末段；design.md `### IC5`；`scripts/cash-skills/tests/test_installer_runtime.py:32-50, 1586, 1741, 1839, 1855`
- `summary`: 2.3 與 IC5 規定既有 hook 測試「沿用既有的 `TEST_` 前綴間接層由 `install` helper 轉譯真名」，但四個既有使用 hooks 的測試沒有一個經過 `install` helper——兩個把真名寫進 `os.environ` 再經 `install_from` 繼承，兩個自行組 `environment` dict 交給 `subprocess.Popen`——因此該機制無法把開關送達那四個測試，且 `install` helper 也沒有可擴充的「剝除清單」。
- `recommendation`: 逐一列舉全部三個注入路徑，改以 per-call env 參數注入並先剝除全部 `CASH_INSTALL_*`（含新開關），並禁止把真名寫入 parent `os.environ`。
- `disposition`: `fix-introduced`
- `introduced_by`: `reviews/propose-r1.md` `## Fix Actions` 的「S6：tasks.md 2.3 明訂沿用 `TEST_` 前綴間接層並擴充 helper 的變數剝除清單」——該修正只指涉 `install` helper 一個注入點。
- reviewer source: Reviewer A（`fix-introduced`, 88）與 Reviewer B（`new`, 85）獨立提出同一問題；依 disposition 衝突規則，blocking disposition 勝出。

**G4**
- `severity`: Warning
- `confidence`: 88
- `layer`: design
- `location`: design.md `### D2` 末段、`### IC2`；specs/cash-cli/spec.md `#### Scenario: Dry run 遇未完成 journal 不恢復但明示`；tasks.md 1.2／2.2
- `summary`: IC2 要求 `--dry-run` 遇未完成 journal 時輸出 diagnostic，但 artifact 從未指定發出點；唯一被規範觸及 journal 的位置在 conflict 判定之後，dry-run 在半發布狀態下同樣先以 conflict 中止，根本到不了。
- `recommendation`: 與 G2 同源——把 journal 偵測前移到 conflict 判定之前並在 IC2 明訂 diagnostic 的發出點；tasks 1.2 斷言 conflict 與 update 兩種結局下 diagnostic 都出現。
- `disposition`: `new`
- reviewer source: Reviewer B（88）與 Reviewer A（70）。

**G5**
- `severity`: Warning
- `confidence`: 80
- `layer`: design
- `location`: proposal.md `## Proposed Solution` 第 2 點；design.md `### D2` 的「替代方案（不採用）」
- `summary`: proposal 第 2 點把解法寫成「把 journal recovery 提前到 target 快照定案之前，或在 recovery 實際變更檔案後重新分類」的並列選項，但第一個分支正是 D2 明確拒絕的替代方案；實作者只讀 proposal 而選該分支，會在無 lock 保護下對 target 執行 rollback 寫入，違反 master spec 的 lock 序列化契約。
- `recommendation`: proposal 第 2 點刪去該分支，改為單一機制陳述並與 D2／IC2 對齊。
- `disposition`: `unresolved-prior`（對應 `reviews/propose-r2.md` 的 N1：同一 artifact `proposal.md` `## Proposed Solution`、同一缺陷機制「proposal 仍陳述 design 已推翻的機制」；r2 的 fix 只改寫第 1 點，未掃第 2 點）
- reviewer source: Reviewer A。

**G6**
- `severity`: Warning
- `confidence`: 80
- `layer`: design
- `location`: specs/cash-cli/spec.md `### Requirement: Installer fault-injection hooks 治理` 末句；design.md `### IC3` 末條；tasks.md 2.3
- `summary`: 該 requirement 寫「`CASH_INSTALL_CRASH_AFTER_COMMIT` MUST NOT在測試、規格或文件留有引用」，但這句話本身就是規格文字且逐字含有該識別字；archive 後它成為 master spec 常駐條文，使該 MUST 永久自我違反，tasks 2.3 的驗收步驟因而是必定失敗的檢查。
- `recommendation`: 把約束範圍收斂為「MUST NOT 在實作、測試或使用者文件中作為可生效的 environment variable name 被讀取或設定；本 requirement 與 change artifacts 的敘述性引用不在此限」。
- `disposition`: `fix-introduced`
- `introduced_by`: `reviews/propose-r1.md` `## Fix Actions` 的「S5：spec 的開放式條款收斂為具名的 `CASH_INSTALL_CRASH_AFTER_COMMIT` 移除規定」——具名化把原本無界但無自指的條款轉成自我違反的條款。
- reviewer source: Reviewer A（80）與 Reviewer B（78），獨立提出同一問題。

### Suggestion（經 confidence filter 降級或原為 Suggestion，皆非阻斷）

- **G7**（75，`new`）IC2 的「任何情況下 SHALL NOT 以『installation inputs changed after lock acquisition』失敗」無條件過寬，連「重新進入取得 lock 之後真的有外部 process 修改 target」這種必須 fail closed 的情形也一併禁止，與既有測試釘住的行為牴觸。
- **G8**（72，`fix-introduced`）release 檔的存在性只在 preflight 驗證一次，但 publication hold 的等待點隔了整段分類與發布；該窗內出現的 release 檔不會被任何檢查看到，hold 靜默退化成 no-op。`introduced_by`：r1 的「修 W2（hook 驗證時機）」與「S4（release 檔 identity 規則）」疊加。
- **G9**（75，`new`）Risks 宣稱序號維持有效，但其有效性實際綁定於 runtime `.py` 檔數；若實作把新邏輯拆成新模組就會位移序號，使既有 rollback 測試仍通過卻不再落在原本階段。
- **G10**（70，`fix-introduced`）r3 對相容性判準的「不可觀察」論證同樣適用於分派判準，F2 的修正只覆蓋了一半。
- **G11**（66，`fix-introduced`）proposal 第 3 點漏掉「release 檔在 hold 開始前必須不存在」與 at-most-once 摘要，後者是本次唯一影響 `--all` 可觀察行為的規則。
- **G12**（62，`new`）requirement 要求空值拒絕早於 `--dry-run` 及 `--force` 兩個檢查，但 scenario 與 tasks 只涵蓋 `--dry-run` 組合。
- **G13**（60，`fix-introduced`）tasks 1.4 的 parent process 斷言沒有觀察手段；`exec` 之後 pid 不變，無法單靠 pid 比對驗證。
- **G14**（58，`new`）proposal 與 design 的 Non-Goals 寫「不變更 lock 協定」，但 delta spec 新增了 lock 釋放-重取的 normative 句，宣告的不變量與宣告的變更牴觸。
- **G15**（55，`new`）at-most-once 的記帳鍵未定義（以 hook 或以 hold 路徑為鍵）；`CASH_INSTALL_PUBLICATION_HOLD_FILE` 在 artifact 中從未出現，實作者無從得知兩個 hook 必須各自記帳。
- **G16**（55，`new`，`layer`: text）design 內兩種措辭並存：D3 寫「至多**執行**一次」而 IC3／spec 寫「至多**等待**一次」；同段「第三個重新進入來源」缺少 post-lock 限定詞。

## Rating

- post-filter cumulative blocking set Critical count: **0**
- post-filter cumulative blocking set Warning count: **4**（G3、G5、G6，以及第四個為 G4？見下）
- 非阻斷 triaged finding count: **12**
- `critical_gap`: **false**
- `round_type`: **full**

blocking 成員為 G3（`fix-introduced`）、G5（`unresolved-prior`）、G6（`fix-introduced`）三項；G1、G2、G4 雖為 Critical／Warning，但 disposition 皆為 `new`，依規則非阻斷。故 post-filter cumulative blocking set 為 **0 Critical、3 Warning**。

rationale：F1 由兩位 checkpoint reviewer 一致判定 resolved 並離開集合，cumulative set 在本輪開始時清空。本輪的價值全部來自 full 重掃：三輪 micro 的 delta 驗證都只看「上一輪改了什麼」，因此沒有任何一輪去質疑「recovery 的呼叫點在分類流程中的位置是否正確」這個從 round 1 就寫定、之後再沒被重新檢視的前提。G2 正是這個前提錯了——主 agent 獨立實測確認，半發布 bytes 落在 receipt-managed path 時，真實執行與 dry-run 都會先以 `Result: conflict` exit 2，recovery 永遠不會被呼叫。本變更的頭號賣點（crash 後首次執行即恢復）在最常見的情形下根本不成立，而三輪 review 都沒發現，因為原始 repro 用的是 guidance 檔而非 receipt-managed 檔。G1 同樣是 full 重掃才會碰到的跨檔矛盾：版本調升與 grader-protected 測試檔的字面值 pin 互鎖。這兩項雖依 disposition 規則非阻斷，但都已在本輪完整修復——把它們留到後續 change 會讓這個 proposal 交付一個無法達成其核心 scenario 的設計。critical_gap 為 false 是因為 blocking set 內無 Critical，而非因為沒有 Critical 被發現。

## Fix Actions

三個 blocking 成員（G3、G5、G6）與十三個非阻斷項（G1、G2、G4、G7–G16）全部修復，無 grader-protection 保留項，無 accepted-risks 條目。修改檔案共 4 個：`proposal.md`、`design.md`、`tasks.md`、`specs/cash-cli/spec.md`。

**修 G2 與 G4（恢復點早於 conflict 判定）** — design.md D2 新增「**恢復必須早於 conflict 判定。**」整段，含實測證據與三步驟的前置階段定義（read-only 偵測不持鎖 → 取得 lock → 恢復 → 釋放 → 重新進入），並說明 `recover_installer` 回傳偽即代表持鎖後 journal 已不存在，使 pre-lock 偵測在持鎖時被重新驗證；末段補上該偵測點同時是 dry-run diagnostic 的發出點，因此 diagnostic 對四種 dry-run 分類一律出現。IC2 改寫為六條，新增「偵測 SHALL 早於 conflict 判定」「未完成 journal 存在時 SHALL NOT 先以 conflict 返回」「半發布 bytes 落在 receipt-managed path 時亦如此，不得要求 `--force`」與 diagnostic 發出點條款。specs 的 `Bundle 安裝與 runtime receipt` 加入對應 normative 句；`#### Scenario: Crash 後首次執行即完成恢復` 的 AND 補上「回報 `update` 而非 `conflict`，且半發布 bytes 落在 receipt-managed path 時亦不需 `--force`」。tasks 1.2 的 fixture 改為必須同時含一筆版控排除設定與一筆 receipt-managed runtime path 的 write，並斷言不出現 `Result: conflict`、不需 `--force`，以及 dry-run diagnostic 在 conflict 與 update 兩種結局下皆出現；2.2 改寫實作位置。D2 的「替代方案（不採用）」同步修正為「在不持鎖的情況下執行 recovery」，因為新設計本身就把偵測提前了。

**修 G1（bundle version pin 互鎖）** — proposal `## Impact` 的 Modified 清單加入 `scripts/cash-skills/tests/skill-checks.fish`，並在 `## Proposed Solution` 第 5 點說明它是 grader-protected path、因版本 pin 而必然在範圍內，故明確宣告為交付目標；tasks 4.1 加入同步更新該字面值的指示與理由。

**修 G3（hook 測試注入點）** — tasks 2.3 與 IC5 改為逐一列舉四個既有測試的三個注入路徑（`os.environ` + `install_from` 繼承、自建 `environment` 交給 `Popen`），要求三個 helper 統一改由 per-call env 注入並先剝除全部 `CASH_INSTALL_*`，且禁止把真名寫入 parent `os.environ`。

**修 G5（proposal 第 2 點仍提供被否決的機制）** — proposal 第 2 點改寫為單一機制陳述，與 D2／IC2 一致，並加入「恢復點必須早於 conflict 判定」的理由與實測結論。

**修 G6（自我違反的 MUST NOT）** — spec 該句範圍收斂為「MUST NOT在實作、測試或使用者文件中作為可生效的 environment variable name 被讀取或設定；本requirement與change artifacts對該名稱的敘述性引用不在此限」。

**修 G7** — IC2 的無條件句改為因果限定（「SHALL NOT 因 recovery 自身造成的 target 變更而……」），並明寫外部併發修改仍 MUST fail closed；spec 對應句同步；tasks 2.2 的驗收句加入「特別確認 publication 前 revalidation 對外部併發修改仍 fail closed」。

**修 G8** — design D3 第 2 點新增一段說明 release 檔必須驗兩次及其理由；IC3 對應條款改寫為「preflight 與各 hook 自身的等待點進入時各驗證一次」；spec requirement 同步；`Hold 協定不安全形狀 fail closed` 的 WHEN 拆為「release 檔在 preflight 已存在」與「release 檔在該 hook 的等待點進入時才出現」兩種情形；tasks 1.3、2.3 同步。

**修 G9** — Risks 的序號項改寫，說明其有效性綁定於 runtime `.py` 檔數；IC5 與 tasks 2.3 加入「不得在 `.cash-skills/lib/cash_cli/` 新增模組檔案」，tasks 4.1 加入「`.py` 檔數與變更前相同」的驗收。

**修 G10** — IC1 第 1 條補上分派判準同屬 defense-in-depth、無獨立可觀察後果的說明，與 r3 對相容性判準的處理一致。

**修 G11** — proposal 第 3 點補上「release 檔在 hold 開始前必須不存在」、等待點二次驗證，以及 at-most-once 與兩個 hook 各自記帳的摘要。

**修 G12** — tasks 1.1 加入三個空字串各自配合 `--force` 的斷言，並註明 `--force` 守衛的運算元同樣不含 `--register`／`--unregister`，是同一順序約束的第二個觀察點。

**修 G13** — tasks 1.4 指定觀察手段：以 hold hook 持住 installer 期間檢查 `Popen` pid 之下不存在子行程，並註明 `exec` 之後 pid 不變、無法單靠 pid 比對驗證；IC5 的 IC4 bullet 同步。

**修 G14** — proposal 與 design 的 Non-Goals 改為「不變更 lock 的建立與 identity 重驗機制（`O_CREAT|O_EXCL`、`flock`、`fstat` device/inode 比對）與 lock inode 的持久性」，並明寫 recovery 觸發的釋放-重入沿用既有 post-lock 重新分類路徑、不屬 lock 機制變更；tasks 4.2 的驗收句同步。

**修 G15** — design IC3 新增「at-most-once 的記帳鍵 SHALL 為 hook 本身而非 hold 路徑」並具名兩個 hook；spec requirement 同步；新增 `#### Scenario: 兩個 hold hook 各自記帳`；tasks 1.3 加入對應斷言。

**修 G16** — D3 的「至多執行一次」統一為「至多等待一次」；「第三個重新進入來源」改為「第三個 post-lock 重新進入來源」並補上四個重新進入點的 pre／post-lock 分佈說明。

**修正後的機械自檢與驗證** — 重跑 pre-round mechanical self-check：4 份 artifact 的 comment/annotation 平衡皆為 0/0；兩個 MODIFIED requirement 標題與 master spec 逐 byte 相符；新增 scenario 由 15 增至 16，全數在 tasks.md 有 backing task（無單向缺漏）；proposal `## Impact` 中含 `/` 的三個 code span 皆在 tasks.md 出現；identifier cross-grep（`CASH_INSTALL_HOLD_FILE`、`CASH_INSTALL_PUBLICATION_HOLD_FILE`、`skill-checks.fish`、`managed target drift`、`conflict 判定`）跨 artifact 一致；無 lowercase `may`／`should`；無 stray `---` 分隔線。本輪自檢另捕捉到兩個由本輪 fix 自己引入的 ghost bold name（`**早於 conflict 判定**` 與 `**外部**`）——與 r3 的 F4 同型，tasks.md 的粗體慣例只用於 scenario／requirement 名稱——已移除，現 ghost bold name 數為 0。重跑 `cash validate` 通過，`cash analyze` 四個維度皆為 0 finding。

**Signal-derived checks** — `openspec/signals/` 下全部 open signal 仍無 `check` frontmatter 欄位，採 best-effort 判斷。本輪最相關者：`execution-error-masked-as-pass` 與 `specific-rule-shadowed-by-catch-all` 對應 G2（較泛用的 conflict 判定遮蔽了更具體的 journal 恢復路徑）；`version-bump-test-inventory-incomplete` 對應 G1；`positional-failure-injection-index-invalidated` 對應 G9；`review-fix-propagation-incomplete` 對應 G3、G5、G10、G11、G13 五項——這一輪它是最高頻的形狀，反映三輪 micro 的 delta 驗證會系統性漏掉「修正未傳播到未被該輪觸及的 artifact」。

## Decision

next_round

post-filter cumulative blocking set 含 0 個 Critical 與 3 個 Warning（G3、G5、G6），未滿足 pass 條件。F1 已由兩位 checkpoint reviewer 一致以 verified resolution 判定離開集合。三個 blocking 成員與十三個非阻斷項（含兩個 Critical）皆已完成 fix 並記錄於 `## Fix Actions`。下一輪為本次執行的第五輪，非第四輪，故為 `micro` 輪，由單一 Reviewer V 對 G3、G5、G6 逐一給出 resolved/unresolved 判定，並重點檢查本輪大幅改寫的 D2／IC2 恢復順序是否引入新缺陷。
