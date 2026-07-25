# Cash Propose Review — Round 2

本輪為 micro 輪，由單一 Reviewer V — Verification 對 round 1 的 cumulative blocking set 做 delta 驗證，並重點審查 round 1 的 fix 新增的三處設計：不被辨識形式的診斷分支、source 側字尾封死、`CASH-SKILLS.md` 同步。

## Reviewer Findings

### Cumulative blocking set 逐項判定

round 1 的 8 個 blocking 成員全數 `resolved`，5 個非阻斷項亦全數關閉：

| member | verdict | 依據摘要 |
| --- | --- | --- |
| C1 | resolved | IC3 已改為「四個既有判定的觸發條件不變」、不再要求訊息文字不變；tasks 2.1 同步移除該鎖；新增 IC4 與 tasks 1.6／2.2，互相封死已解除 |
| W1 | resolved | tasks 1.4 新增 `SPECTRA:END` 與 `CASH:START` 兩個 case；delta GIVEN 已放寬為任一名稱任一側並新增 Cash 自我修復 Example |
| W2 | resolved | tasks 1.1 已拆為 fixture A（首行即 marker）與 fixture B（marker 之前另有文字），形狀不再互斥 |
| W3 | resolved | design Risks 第二段已明列後果；D6 記錄端對端修復前後對照；proposal 新增對應段落 |
| W4 | resolved | `CASH-SKILLS.md` 已列入 proposal `## Impact`；tasks 2.4 承接；design D7 說明。Reviewer V 與主 agent 皆獨立複核 `CASH-SKILLS.md:68` 原文確含該句 |
| W5 | resolved | D3 已改寫為「target 側是修復、source 側必須反向封死」；新增 IC5、tasks 2.3／1.7、delta 條款與 scenario。Reviewer V 實測相容性：`skill-checks.fish:208-209` 以整行字面計數檢查 source marker，方向與 IC5 一致；本 repo 自身 guidance 可通過新檢查 |
| W6 | resolved | IC2 驗收已改綁 tasks 1.3 的可重跑 fixture；IC8 改為不綁定 registry 條目總數；Tubify 的 offsets 僅殘留於 design 作為歷史證據 |
| W7 | resolved | IC4 要求 `marker_span` 新增相對路徑引數並附於全部例外；delta 新增對應 scenario；tasks 1.6／2.2 承接 |

**傳播完整性**：Reviewer V 確認 IC 編號 IC1–IC8 連續無缺、tasks 引用皆為現行編號、全 change 無殘留舊 IC 引用；舊措辭（`嚴格改善`、`訊息文字不變`、`would-update`、`三個成功情境`）在 artifact 中皆為 0 次；delta 標題、首段與三個保留 scenario 與 master 逐 byte 相符。

### Critical

**F1**（confidence 90，layer design，`disposition`：`fix-introduced`，`introduced_by`：round 1 `## Fix Actions` 的「修 C1（保留 requirement 並補上實作路徑）」）

- `location`：`specs/cash-cli/spec.md` 的「形式不被辨識時的診斷不誤述為失衡」scenario vs `design.md` IC4／D6、`tasks.md` 1.6／2.2
- `summary`：delta 把「形式不被辨識 → exit 1 且診斷指出形式不被辨識」寫成無條件 MUST，IC4 與 2.2 卻把該分支 gate 在「計數不相等」上；不被辨識的 marker 若未造成計數失衡，installer 完全不失敗也不診斷，該 scenario 的 THEN 對自己 GIVEN 的一個子集為假。
- 主 agent 獨立實測確認：`<!-- SPECTRA:START v1.0>2 -->` 與 `<!-- SPECTRA:STARTv1.0.2 -->` 在無對側 marker 時，合法匹配數皆為 start 0 end 0，計數相等，`marker_span` 直接 `return None`，installer 照常成功。tasks 1.6 未要求 fixture 另含合法對側 marker，照字面寫出的測試不會 red。
- 這是 C1「delta normative 超出 design 與 task 所能交付」的同型復發，方向由「封死」變成「範圍不足」。

### Warning

**F2**（confidence 85，layer design，`disposition`：`fix-introduced`，`introduced_by`：round 1 的「修 N4」與「修 N3」）`location`：`design.md` D2 末段與 `specs/cash-cli/spec.md` 的等價保證限定段。`summary`：兩處都以「該輸入的 marker 所在行另有文字，本就違反非獨立行判定」作為排除構造反例的理由，但該理由為假——新舊實作都接受該輸入、都不 fail closed，只是 span 起點不同，等於用假前提掩蓋一處無測試覆蓋的靜默行為改變。主 agent 獨立實測：對 `<!-- CASH:START <!-- CASH:START -->` 起始的輸入，現行實作回傳 `(16, 54)`，只排除 `>` 的 pattern 回傳 `(0, 54)`，且尾側緊接換行、通過非獨立行判定。後果不只是 span 不同：`render_guidance` 會以 canonical block 取代 `(0, 54)`，把舊實作視為 span 外、受逐 byte 保留保護的前 16 bytes 一併刪除。

### Suggestion（非阻斷）

- **F3**（75，`fix-introduced`）design D7 對「三個候選自動檢查」的稽核與程式碼不符：把 `skill-checks.fish` 的 docs 檢查描述成 sha256 baseline，實際上這是兩個不同檢查，且 `assert_guidance_and_docs` 確實會讀 `CASH-SKILLS.md`、以 14 條字面斷言（含 `fail closed`）。D7 的結論仍成立（該字面在本檔五行皆出現，改寫其中一行不會變紅），但理由不是它宣稱驗證過的那件事，且遺漏了「改寫受 14 條 literal 約束」這個實作者必須知道的限制。
- **F4**（70，`fix-introduced`）前綴判準會對散文誤判：輸入「散文中提到 `<!-- SPECTRA:START` ＋ 一個真正孤立的合法 END」會被診斷為形式不被辨識，但真實成因是孤立，方向相反；且 design 未定義兩種成因並存時的優先序。
- **F5**（65，`fix-introduced`）D6 自述的動機案例不會走新增的診斷分支——該案例的 marker 形式是被辨識的，前綴數等於合法匹配數，分支不觸發，仍會拿到失衡措辭。「以可辨識的具名診斷緩解」對該案例只兌現了檔名一半。
- **F6**（60，`fix-introduced`）IC5 引入一個影響全部 target 的 source 側 fail-closed，但 tasks 2.4 只改寫「未知版本 marker」該句，`CASH-SKILLS.md` 仍未說明「source 的 Cash marker 帶字尾會擋掉所有 target 安裝」——這是本次影響面最大的新失敗模式。
- **F7**（55，`fix-introduced`）IC6 的失敗情境分項與 tasks 實際 case 不對應，總數 8 只是巧合相等：IC6 寫 5+3，tasks 實際是 5+2+1，且「診斷具名檔案」是橫向斷言而非獨立 case。
- **F8**（55，`new`）四個 name 與種類組合中 `CASH:END` 帶字尾仍無案例。若實作者只對 `START` 泛化而對 `CASH:END` 沿用字面比對，全部既有測試仍綠而該 MUST 已被違反。
- **F9**（50，`new`）tasks 3.3 要求比對修復前後的定位結果，但 2.1 執行後舊實作已不在工作樹，task 未說明如何取得對照組，最可能的結果是以修復後結果自我比對而得到必然的「不一致數 0」。

## Rating

- post-filter cumulative blocking set Critical count：**1**（F1）
- post-filter cumulative blocking set Warning count：**1**（F2）
- 非阻斷 triaged finding count：**7**（F3–F9）
- `critical_gap`：**true**
- `round_type`：**micro**

rationale：round 1 的 8 個成員全部以 verified resolution 離開集合，缺陷密度由 1C+7W 降至 1C+1W。本輪 7 個 `fix-introduced` 中有 4 個（F1、F4、F5、F7）指向同一個對象——round 1 為修 C1 而新增的「形式不被辨識」診斷分支。四個獨立缺陷集中在同一處新設計，本身就是該設計不成立的證據，因此本輪的處置不是逐條補丁而是撤除該分支。F2 則是第二次揭露我用一個未經驗證的理由去合理化一個已知的行為差異：round 1 我寫下「該行本就違反非獨立行判定」來排除構造反例，實測顯示它通過該判定，真正的問題是字尾會向前吞噬並刪除受保護的 bytes。

## Fix Actions

2 個 blocking 成員與 7 個非阻斷項全部修復。無 grader-protection 保留項，無 accepted-risks 條目。修改檔案共 4 個：`proposal.md`、`design.md`、`tasks.md`、`specs/cash-cli/spec.md`。

**修 F1、F4、F5、F7（撤除診斷分支，而非逐條補丁）** — 四個 finding 都是同一處新設計的缺陷。共同根因是：不做行首錨定就無法可靠區分「文件裡談到 marker」與「一個寫壞的 marker」，而行首錨定是本 change 的 Non-Goal，因此該分支的規格在本次範圍內不可能寫對。撤除該分支：delta 刪除「形式不被辨識時的診斷不誤述為失衡」scenario 與對應 requirement 條款，保留並強化「全部 marker 失敗診斷具名檔案」；IC4 收斂為只做具名路徑、明訂不新增其他診斷分支；D6 改寫為記錄該分支的三個實測缺陷與撤除理由；proposal 與 design 的 Non-Goals 各新增一條。tasks 1.6 改為承接新的「字尾不跨越註解界定符」與具名檔案兩項，2.2 明訂不得新增其他診斷分支。IC6 的情境重算為六個成功與六個失敗，並明訂「診斷具名檔案」是橫向斷言、不另計為情境（一併修 F7）。

**修 F2（改設計，不只改敘述）** — 字尾字集由「不含 `>`」改為「不含 `<` 與 `>`」，兩者各擋一個方向的吞噬。實測驗證：加上 `<` 排除後，構造反例回到 `(16, 54)`，與現行實作逐 byte 相同；真實帶字尾 marker 與無字尾 marker 的定位結果不受影響。因此該輸入不再是等價保證的例外而是被保證涵蓋。delta、design D1／D2／IC1、tasks 2.1、proposal 全部同步；delta 新增 `#### Scenario: 字尾不跨越註解界定符` 與 tasks 1.6 的對應測試，斷言該行稍前的 bytes 在遷移後仍逐 byte 存在。D2 與 delta 中那個假理由改寫為據實陳述。

**修 F3** — D7 改為分別敘述三個檢查的實際行為，明確指出 `assert_guidance_and_docs` 確實會讀 `CASH-SKILLS.md` 並以 14 條字面斷言、但該字面在本檔五行皆出現故不構成保護；tasks 2.4 新增「改寫時 MUST 保留全部 14 條字面」的約束。

**修 F6** — tasks 2.4 由改一處擴為改兩處，第二處補上 source 側規則的說明，並註明其影響面（一個 source 檔擋掉全部 registered target）。

**修 F8** — tasks 1.4 明訂四個 name 與種類組合必須全部有案例，case 二的同一 fixture 內 `CASH:START` 與 `CASH:END` 兩者皆帶字尾；IC6 的成功情境敘述同步。

**修 F9** — tasks 3.3 補上以 `git show HEAD:.cash-skills/lib/cash_cli/installer.py` 取得對照組的方式，並說明沒有對照組時該檢查會退化成必然通過的自我比對。

**修正後的機械自檢** — 重跑全部檢查，捕捉到三個本輪 fix 引入的缺陷並已修正：delta 的 `<!--` 與 `-->` 計數兩度不平衡（新 scenario 的 GIVEN 中含裸露的註解起始序列字面，兩次都改寫為敘述性文字）；tasks 出現 emphasis 粗體 `**兩者皆**`（本 session 第七次同型錯誤）；proposal 的 `### Modified Capabilities` 仍描述已撤除的診斷條款。另捕捉到兩處本輪改寫的漏網：delta 的等價保證限定段仍保留 F2 指出的假理由（design 已改而 delta 未改），以及 delta 的方向詞寫成「向後吞掉」而 design 寫「向前」。修正後：註解計數 2 比 2 平衡；tasks 全部 10 個粗體項皆為 scenario 或 requirement 名；9 個 scenario 與 2 個 Example 對 tasks 的雙向對應無缺漏；假理由與方向詞不一致殘留皆為 0；MODIFIED 標題與 master 逐 byte 相符。重跑 `cash validate` 通過。

**Signal-derived checks** — 全部 open signal 皆無 `check` frontmatter 欄位，採 best-effort。本輪最相關者：`detection-criterion-false-positive-on-legitimate-form`（F4——前綴判準對散文的誤判正是該 signal 描述的形態，且判準未對真實語料實跑就被寫進 IC；撤除該分支後，主 agent 對新字尾字集重跑全語料驗證，新舊 span 不一致數為 0）、`design-claim-unverified-against-code`（F2 的假理由）、`review-fix-propagation-incomplete`（F3、F6、以及自檢捕捉到的兩處 delta 漏網）、`acceptance-criterion-unreachable-at-specified-point`（F1、F9）、`test-fixture-required-case-missing`（F8）、`enumerated-site-set-factually-wrong`（F7）。

## Decision

next_round

post-filter cumulative blocking set 含 1 個 Critical（F1）與 1 個 Warning（F2），未滿足 pass 條件。round 1 的 8 個成員已全部以 verified resolution 離開集合。2 個 blocking 成員與 7 個非阻斷項皆已完成 fix 並記錄於 `## Fix Actions`。下一輪為本次執行的第三輪，非第四輪，故為 `micro` 輪，由單一 Reviewer V 對 F1 與 F2 給出 resolved/unresolved 判定，並重點檢查本輪兩項改設計——撤除診斷分支後 delta 與 design 是否仍自洽、以及字尾排除 `<` 是否引入新的邊界問題。
