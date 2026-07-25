# Cash Propose Review — Round 1

本輪為 full 輪，未 seeded，由 Reviewer A — Adherence 與 Reviewer B — Quality 兩個獨立 sub-agent 平行審查。兩位皆對本機真實語料與 patched installer 做了端對端實跑，findings 幾乎全部帶有可複現的實測證據。

依 round 1 未 seeded 的規則，全部通過 confidence filter 的 Critical 與 Warning 皆為 blocking。

## Reviewer Findings

### Critical

**C1**（confidence 100，layer design，來源：Reviewer A finding 1 與 Reviewer B finding 1 獨立提出後合併）

- `location`：`specs/cash-cli/spec.md` 新增段落末句 vs `design.md` D2／IC3 與 `tasks.md` 2.1
- `summary`：delta 新增 normative「marker形式不被辨識時產生的失敗診斷 MUST NOT把「形式不被辨識」誤述為marker失衡」，但 design D2、IC3 與 task 2.1 都逐字要求「三個 `raise` 的觸發條件與例外訊息文字不變」，該 MUST NOT 因此沒有任何實作路徑，也沒有任何 task 承接。
- 實測證據：兩位 reviewer 分別以 patched installer 確認，`<!-- SPECTRA:START v1.0>2 -->`（字尾含 `>`）與 `<!-- SPECTRA:STARTv1.0.2 -->`（種類後無空白）在修好之後仍回傳 `duplicate or unbalanced SPECTRA guidance marker`，正是該 MUST NOT 禁止的誤述。
- `recommendation`：刪除該句改為非 normative 敘述，或保留並新增可辨識的診斷分支與對應 task。

### Warning

**W1**（confidence 85，layer design，Reviewer A finding 2）`location`：`specs/cash-cli/spec.md` 的「MUST對`CASH`與`SPECTRA`兩個名稱、`START`與`END`兩種種類一致適用」vs `design.md` IC4 與 `tasks.md` 1.1–1.4。`summary`：這是 delta 中最強的新 MUST，也是 D1 否決「只特判 start」方案的唯一理由，但全部測試情境只使用「SPECTRA 的 start 帶字尾」，帶字尾的 `END` 與帶字尾的 `CASH` 完全無覆蓋，該 MUST 無機械驗證。

**W2**（confidence 90，layer design，Reviewer A finding 3）`location`：`tasks.md` 1.1。`summary`：fixture 描述自相矛盾——同時要求「首行為 `<!-- SPECTRA:START v1.0.2 -->`」與「在 legacy block 之前放一段 project-owned 文字」。若首行即 marker，其前不可能有內容，實作者必須任選其一，被犧牲的通常是「span 前側 bytes 逐 byte 保留」這條最有價值的斷言。

**W3**（confidence 85，layer design，Reviewer B finding 2）`location`：`design.md` `## Risks / Trade-offs` 第二段。`summary`：字尾容忍新增一整類 regression——目前被靜默忽略的「散文中提到 marker」文字，修好之後會讓整個 target 永久 fail closed 且 `--force` 無法繞過，訊息與本次要修的 bug 完全相同。端對端實測：target `AGENTS.md` 含合法 Cash block 加獨立一行的 `<!-- SPECTRA:START v1.0.2 -->` 而無對應 END，修復前 `Result: update` exit 0，修復後 exit 1。design 僅以「誤匹配機率極低」帶過，未說明後果是整個 target fail closed 且無 escape hatch。

**W4**（confidence 85，layer design，Reviewer B finding 4）`location`：`CASH-SKILLS.md:68` 與 `proposal.md` `## Impact`。`summary`：`CASH-SKILLS.md:68` 逐字寫著「Symlink、duplicate、orphan、reversed、nested、非獨立行或未知版本 marker都會在首次 target write前 fail closed」，本次改動使「未知版本 marker fail closed」變成假；該檔由 `openspec/specs/cash-skill-workflows/spec.md` 治理，卻未列入 `## Impact` 或 `tasks.md`，且沒有任何自動檢查會偵測這處 drift。主 agent 已獨立複核該行原文，確認屬實。

**W5**（confidence 80，layer design，Reviewer B finding 5）`location`：`design.md` D3「兩者都是嚴格改善」。`summary`：D3 對 source 端的推論錯誤。字尾容忍套用到 `CASH` 之後，`canonical_guidance` 會把帶字尾的 marker 一併納入 canonical block 並散播到每一個 registered target，而現行實作對此輸入是 fail closed。主 agent 已獨立複核：source 為 `<!-- CASH:START v9.9.9 -->` 起始時，新定位回傳的 canonical block 逐字含該字尾。因此「嚴格改善」在 source 側不成立。

**W6**（confidence 85，layer design，Reviewer B finding 6）`location`：`design.md` IC2、IC6 與 `tasks.md` 3.2、3.3。`summary`：三項驗收基準都是本機一次性且會自我銷毀的。`(1200, 5095)` 只在第一次真實安裝之前成立——同一次修復會從 Tubify 的 `AGENTS.md` 刪去 offset 0 到 1198 共 1198 bytes，offsets 隨即永久失效；`would-update=7` 也綁定本機 registry 條目數，且真實安裝後會變成 `current=7`。主 agent 已獨立複核 legacy span 長度確為 1200。

**W7**（confidence 85，layer design，Reviewer B finding 3）`location`：`.cash-skills/lib/cash_cli/installer.py` 的三個 `raise`。`summary`：`marker_span` 的例外不帶 `relative`，使用者看不出是 `AGENTS.md` 還是 `CLAUDE.md`、也無 offset，而字尾容忍正好擴大了落到這些訊息上的輸入集合；同一路徑上 `render_guidance` 的巢狀例外則有帶檔名，落差明顯。此項與 C1、W3 指向同一個「新失敗形態無法自助定位」的根因，故一併處置。

### Suggestion（非阻斷）

- **N1**（75，Reviewer B finding 7）`design.md` Risks 第一段提出的「先以 `--dry-run` 確認」沒有實質效力：dry-run 只輸出分類結果、不提供 byte-level 預覽；且兩個受影響 target 的 `AGENTS.md`／`CLAUDE.md` 目前皆為 uncommitted modified，隱含的「用 git 還原」退路會連帶丟掉未提交修改。
- **N2**（70，Reviewer A finding 4 與 Reviewer B finding 8 合併）`tasks.md` 1.4 的「前後同行另有文字」措辭會讓實作者寫出不會 red 的測試——只在 marker 之前放文字時，修好後的 installer 會接受並成功安裝，且遷移後留下一個不獨立成行的 Cash marker。
- **N3**（65，Reviewer A finding 5）delta 的「既有target的guidance處理結果不因本容忍而改變」是無條件敘述，但 design Risks 自承容忍擴大了可接受輸入集合，兩者抵觸。
- **N4**（60，Reviewer B finding 9）IC2 的全稱敘述不成立：構造反例 `<!-- CASH:START <!-- CASH:START -->` 下，舊實作 span 起點為 16、新 pattern 為 0。照字面寫成測試會斷言一個假命題。
- **N5**（50，Reviewer A finding 6）IC1 的「字尾不被解析」無機械驗證——現有測試只用單一字尾 `v1.0.2`，無法區分「略過字尾」與「認得 v1.0.2」。

### confidence filter 降級紀錄

- Reviewer A finding 7（`tasks.md` 1.3 驗收粒度與 1.1／1.2 不一致，confidence 45）低於 50，依 filter 丟棄，不進入 blocking set。該項仍在 fix actions 中順手修正。
- Reviewer B finding 10（`Live namespace` path 白名單不含 `scripts/cash-skills/tests/`，confidence 35）低於 50，依 filter 丟棄。reviewer 已自行確認 `test_live_namespace.py` 不偵測 marker 字面、不會有測試變紅，屬 spec 文字與偵測器的既有落差而非本 change 造成。仍在 design D5 補一句說明以免後續 adherence review 誤判。

## Rating

- post-filter cumulative blocking set Critical count：**1**（C1）
- post-filter cumulative blocking set Warning count：**7**（W1–W7）
- 非阻斷 triaged finding count：**5**（N1–N5）
- `critical_gap`：**true**
- `round_type`：**full**

rationale：本輪是 run 的第一輪且未 seeded，因此全部通過 filter 的 Critical 與 Warning 皆為 blocking。兩位 reviewer 的產出品質很高：所有 code-facing claim 都被實際執行核對過，Reviewer A 明確回報「無任何 design 對程式碼的論斷為假」，而 findings 集中在 artifact 之間的自相矛盾與**修法本身引入的新後果**。其中 C1 最值得記錄——我在寫 delta 時順手加了一句要求更好診斷的 MUST NOT，卻同時在 IC3 與 task 2.1 要求訊息文字不變，等於寫下一條自己封死實作路徑的 requirement。W5 則揭露我把「容忍對 CASH 也生效」一律論斷為改善，但 source 側其實是把一個原本 fail closed 的錯誤輸入變成會散播到全部 target 的靜默污染，方向完全相反。

## Fix Actions

8 個 blocking 成員與 5 個非阻斷項全部修復，另修復兩個被 filter 丟棄的低分項。修改檔案共 4 個：`proposal.md`、`design.md`、`tasks.md`、`specs/cash-cli/spec.md`。無 grader-protection 保留項，無 accepted-risks 條目。

**修 C1（保留 requirement 並補上實作路徑，而非刪掉要求）** — 選擇 reviewer 給的 (b) 方案。理由是 W3 揭露的新失敗形態會讓使用者拿到與本次要修的 bug 一字不差的訊息，若同時刪掉診斷要求，等於用一個無法自助定位的永久失敗換掉另一個。delta 改寫為兩條可實作的 MUST：形式不被辨識時的診斷不得宣稱重複或失衡；全部 marker 失敗診斷必須具名 guidance 檔案。design 新增 D6 說明取捨與最小實作範圍、新增 IC4 定義契約，tasks 新增 2.2（實作）與 1.6（測試）。IC3 同步改為「四個既有判定的觸發條件不變」，不再宣稱訊息文字不變。

**修 W1** — tasks 新增 1.4，涵蓋帶字尾的 `SPECTRA:END` 與帶字尾的 `CASH:START` 兩個 case；delta 的「帶字尾的 marker 被辨識並收斂」scenario 的 GIVEN 由「legacy Spectra start marker」放寬為「`CASH` 或 `SPECTRA` 的 start 或 end marker」，並新增 `##### Example: 帶字尾的 Cash marker 自我修復`。IC6 的成功情境由三個改為五個。

**修 W2** — tasks 1.1 拆成 fixture A（首行即 marker，對應 Example 的形狀）與 fixture B（marker 之前另有 project-owned 文字，涵蓋 span 前側保留），兩個 fixture 都保留完整斷言集合，不再互斥。

**修 W3** — design `## Risks / Trade-offs` 新增一段明列後果：符合既有 requirement 但確為本次引入的行為改變、`--force` 不繞過、以可辨識的具名診斷緩解。D6 記錄端對端實測的修復前後對照。proposal `## Proposed Solution` 新增第四點同步這個取捨。

**修 W4** — `CASH-SKILLS.md` 加入 proposal `## Impact` 的 Modified；tasks 新增 2.4 改寫該段敘述；design 新增 D7 說明為何必須手動同步——三個候選自動檢查（`test_live_namespace.py`、`skill-checks.fish` 的 docs 檢查、sha256 baseline）逐一確認都不會偵測到這處 drift。

**修 W5** — D3 由「兩者都是嚴格改善」改寫為「target 側是修復、source 側必須反向封死」，並明文記錄這是本輪 review 修正的設計錯誤與實測證據。新增 IC5、tasks 2.3（實作）與 1.7（測試），delta 新增 `#### Scenario: Source canonical marker 不得帶字尾` 與對應的 requirement 條款。proposal `## Proposed Solution` 新增第三點。

**修 W6** — IC2 的驗收基準改綁到 tasks 1.3 的可重跑 fixture；Tubify 的 `(1200, 5095)` 與全語料一致性降級為 tasks 3.3 的一次性佐證並明記「不取代該 fixture」。IC8 的 `would-update=7 failed=0` 改為「`failed` 計數為 0 且那兩個 target 不再出現 marker 相關失敗」，明文不綁定 registry 條目總數。

**修 W7** — 併入 C1 的處置：IC4 要求 `marker_span` 新增 guidance 相對路徑引數、全部例外訊息附上該路徑，兩個呼叫端各傳入其 `relative`；delta 新增 `#### Scenario: 全部 marker 失敗診斷具名檔案`；tasks 1.6 對本節全部失敗 case 斷言診斷含該路徑。

**修 N1** — design Risks 第一段改寫：明記 dry-run 不提供 byte-level 預覽、不是內容層級的保護，實際保護是先確認已提交或另存副本；補上實測的刪除量（1198 與 1212 bytes）與四段 block digest 一致的證據。tasks 3.2 把該確認列為前置步驟。

**修 N2** — tasks 1.5 的非獨立行 case 明確寫成尾側形式，並加一句「行首錨定不在本次範圍，marker 之前同行有文字時實作會接受，不得為此新增斷言」。design Context 補上「遷移後可能留下不獨立成行的 Cash marker」這個既有行為的說明。

**修 N3** — delta 該 AND 改為獨立段落並限定於「marker 獨立成行」的情形，明記 marker 所在行另有文字時本就違反非獨立行判定、不在等價保證範圍內。scenario 標題同步改為「字尾容忍不改變獨立成行無字尾 marker 的 span」。design Goals 作同樣限定。

**修 N4** — IC2 限縮為「marker 獨立成行且不含字尾時，新舊 span 逐 byte 相同」；D2 補上 reviewer 提供的構造反例 `<!-- CASH:START <!-- CASH:START -->` 與其新舊 span 起點差異，並說明為何該輸入不納入保證範圍。

**修 N5** — tasks 1.4 末段加入廉價斷言：同一 fixture 以 `v1.0.2` 與另一段任意不含 `>` 的字尾各跑一次，斷言輸出 bytes 完全相同。

**修被丟棄的兩個低分項** — Reviewer A finding 7：tasks 1.3 補上與 1.2 相同的「span 以外 bytes 與 mode 不變」措辭。Reviewer B finding 10：design D5 補一句說明測試 fixture 中的 legacy marker 字面是測試資料而非 legacy migration code。

**修正後的機械自檢** — 重跑全部檢查，捕捉到兩個本輪 fix 引入的缺陷並已修正：delta 的 `<!--` 與 `-->` 計數為 3 比 2 不平衡（來自「形式不被辨識」scenario 的 GIVEN 中一個未閉合的註解起始序列字面，已改寫為敘述性文字）；tasks 1.5 出現一個 emphasis 粗體 `**之後**`（本 session 第六次同型錯誤，tasks 的粗體只用於 scenario 與 requirement 名，emphasis 粗體會在雙向對應檢查中製造幽靈條目）。另捕捉到 `CASH-SKILLS.md` 在 design 中出現 0 次但已是 tasks 2.4 的交付目標，補上 D7。修正後：註解計數 2 比 2 平衡；tasks 全部 10 個粗體項皆為 scenario 或 requirement 名；9 個 scenario 與 2 個 Example 對 tasks 的雙向對應無缺漏；identifier cross-grep 一致；delta 無 lowercase `may`／`should`；MODIFIED 標題與 master 逐 byte 相符；IC6 宣稱的「五個成功情境與八個失敗情境」與 tasks 實際情境數相符。重跑 `cash validate` 通過。

**Signal-derived checks** — 全部 open signal 皆無 `check` frontmatter 欄位（已逐檔掃描確認為 0 個），採 best-effort。本輪最相關者：`detection-criterion-false-positive-on-legitimate-form`（該 signal 要求判準必須對真實語料實跑，主 agent 已於 round 1 前對全機器 16 個 guidance 檔案跑過提案 pattern，新舊 span 不一致數 0、非獨立行誤匹配數 0）、`test-fixture-required-case-missing`（W1、W2）、`cross-artifact-definition-drift`（C1、W4）、`design-claim-unverified-against-code`（W5）、`acceptance-criterion-not-mechanically-verifiable`（W6、N5）、`declared-scope-over-declares-unchanged-file`（本 change 刻意不宣告 `skill-checks.fish` 與 `cli-checks.fish`，已由 Reviewer A 獨立驗證該判斷成立）。

## Decision

next_round

post-filter cumulative blocking set 含 1 個 Critical 與 7 個 Warning（C1、W1–W7），未滿足 pass 條件。8 個 blocking 成員與 5 個非阻斷項皆已完成 fix 並記錄於 `## Fix Actions`。下一輪為本次執行的第二輪，非第四輪，故為 `micro` 輪，由單一 Reviewer V 對 C1 與 W1–W7 逐一給出 resolved/unresolved 判定，並重點檢查本輪引入的三處新設計——不被辨識形式的診斷分支、source 側字尾封死、以及 `CASH-SKILLS.md` 同步——是否引入新缺陷。
