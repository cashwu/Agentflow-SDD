# Cash Propose Review — Round 10

本輪為 full 輪（re-run 的第四輪 checkpoint 全面重掃），由 Reviewer A — Adherence 與 Reviewer B — Quality 兩個 fresh sub-agent 平行審查。

首次 spawn 的兩個 reviewer 因 session 額度用盡而同時中止。依規則「兩個 full-round 平行 reviewer 在同一輪失敗視為單一 role 失敗」，重試一次；重試的兩個 reviewer 皆正常完成。此失敗與重試記錄於此，未影響本輪的 finding 或決策。

## Reviewer Findings

### Cumulative blocking set 判定

| member | verdict | 依據摘要 |
| --- | --- | --- |
| R9-1 | resolved | **兩位 reviewer 各自獨立讀 `check_history` 原始碼後判定**。兩者皆確認該函式只比對 `current`（工作樹）與 `git show HEAD:cash-skills.version`，無第三個來源。Reviewer A 以當下實際值逐分支重算：sibling 已提交（HEAD `2.4.0`）時 `version_greater(2.3.2, 2.4.0)` 為 False 而拋錯；sibling 未提交（HEAD `2.3.1`）時為 True 而 early return、連 replaceable path 檢查都跳過，靜默覆寫。IC7 改寫後的兩分支敘述逐條成立且互斥，與 tasks 2.5 一致 |

R9-1 是集合唯一成員，離開後集合清空。

### checkpoint 全面重掃的結論

**Reviewer A**：design 中每一項可量測的 code-facing 論斷皆獨立重跑，**無一為假**——D1 的三個 span 值、D2 的 Tubify offset 與 16 檔不一致數 0、Risks 第一段的刪除量與兩組 digest、D4 的兩個空行、D7 的 14 條字面與五個 `fail closed` 出現行、`marker_span` 三個既有例外的對應、`canonical_guidance` 兩個 source 專用例外的消歧字樣、`scripts/` 無 legacy start marker 字面、`test_live_namespace.py` 的三個 detector 皆不匹配 marker 字面。另新驗兩項先前未查的前提：launcher 對所有指令都跑 `validate_receipt`，而 `install-cash-skills.fish` 直接 `exec python -m cash_cli.installer` 不經 launcher，故 2.5 的 `--self` 不會被壞掉的 receipt 擋住。四份 artifact 內部一致、delta 與 master 逐 byte 相容、三向對應完整、scope 未溢出、Non-Goals 無違反。

**Reviewer B**：以 patched bundle（regex 定位 + IC4 標籤 + IC5 source 檢查）實跑端對端——`--all --dry-run` 由 `would-update=5 failed=2` 變為 `would-update=7 failed=0`，且既有 `test_installer_runtime.py` 的 **76 個測試全綠**，沒有任何既有 fixture 的 source bundle 會被 IC5 擋下。另對 5×5×5×5×5 結構化變異做新舊 differential，divergence 共 5 類。IC1–IC8 逐項可達成且無互斥，IC4 與 IC5 的交互特別驗過。16 個 task 以實作者視角逐讀皆可在不回頭提問下完成，並已用 patched bundle 實際做完 2.1 至 2.3。

**與 sibling 的交互**：兩位皆確認無衝突。sibling 對 `skill-checks.fish` 的修改只新增 `assert_command_matrix` 內的字面斷言，未觸及 `assert_guidance_and_docs` 的 14 條字面與 `assert_installer`；`installer.py` 相對 HEAD 未被 sibling 修改，故 3.3 的對照組手法仍有效。

### Suggestion（全部非阻斷）

- **Q-1**（100，`new`，Reviewer B）**本輪最重要的一筆。** 行為改變有第三個方向，delta 的雙向列舉與 Risks 的三案例都沒涵蓋它：target guidance 含一個合法 Cash block，另有一段以兩側皆帶字尾的 legacy marker 包住的說明文字。現行實作因計數 0 對 0 而回傳無 span，該段原樣保留、`Result: update` exit 0；容忍之後同一份檔案的該 span 被辨識為真 legacy block 並移除，同樣 `Result: update` exit 0。**前後兩次的 exit code 與分類結果完全相同，使用者沒有任何訊號**，而 `--dry-run` 不提供 byte-level 預覽。它是三個方向中唯一連失敗訊息都沒有的資料移除。更關鍵的是 design 其實看過這個輸入形狀卻下了相反結論——Risks case 2 的括號寫「兩側皆帶字尾時現行回傳無 span 而於檔尾附加 canonical block、亦非 fail closed」，該句對現行行為為真，但其修辭作用是把該形狀踢出風險清單，而從未陳述容忍之後會刪掉 span 內的 project-owned 內容。
- **Q-2**（70，`new`）delta 寫「字尾 MUST NOT 被解析、比較或用於任何決策」是絕對語氣且無範圍限定，但同一 requirement 又要求「source Cash marker 帶字尾時 MUST fail closed」——後者正是以字尾存在與否為輸入的決策，兩條 MUST 在同一 requirement 內抵觸。design IC1 寫得正確（限定於「字尾內容」且語境在 `marker_span`），delta 與 proposal 都掉了限定。
- **A-f1**（85，`new`，Reviewer A）`帶字尾的 marker 被辨識並收斂` 的 AND 是無條件的，唯一例外碑文只針對字尾含 `<` 或 `>`，但同檔另有帶字尾同名 marker 而落入重複判定的輸入同樣滿足 GIVEN 而 THEN 不成立，且與 `帶字尾 marker 違反判定仍 fail closed` 在同一輸入上結論相反。round 3 的 NF2 把逐檔限定加進了等價保證段，卻沒鏡射到本 scenario。
- **A-f2**（95，`new`，Reviewer A）IC4 與 delta 的末句寫「僅附加該路徑」，但同段前文剛確立「標籤不得只是相對路徑」「僅具名路徑不足以消歧」。照末句字面實作，source 側只需附加相對路徑即可——正是 IC4 要禁止的。tasks 2.2 寫的是「僅附加該標籤」，三處不一致。
- **Q-3**（100，`new`）sibling change 已於 commit `2c700eb` 提交並封存，工作樹與 HEAD 皆為 `2.4.0`，IC7 與 tasks 2.5 的快照值（「HEAD 為 `2.3.1`」「即本 change 撰寫當下的狀態」）已過期。推導規則本身不受影響，推出的值仍是 `2.4.1`。
- **Q-4**（55，`new`）tasks 1.2 的 fixture 未指明 END 是否也帶字尾，且斷言非排他形式。若取兩側皆帶字尾並用包含式斷言，現行實作對該輸入是計數 0 對 0、於檔尾附加 canonical block 而 exit 0，兩條斷言在修復前都成立、測試不 red。與 round 7 的 B-3（1.4 case 二）同物種。
- **Q-5**（50，`new`）IC5 末句要求訊息含「相對路徑」，而 2.3 要求「帶 source 限定詞的標籤」、1.6 後者斷言兩者兼具。單看 IC5 會允許只帶路徑的實作，那會讓 1.6 後者變紅。

## Rating

- post-filter cumulative blocking set Critical count：**0**
- post-filter cumulative blocking set Warning count：**0**
- 非阻斷 triaged finding count：**7**（Q-1 至 Q-5、A-f1、A-f2）
- `critical_gap`：**false**
- `round_type`：**full**

rationale：R9-1 由兩位 reviewer 各自獨立讀 `check_history` 原始碼後 resolved，集合清空。本輪 7 個 finding 全部 `disposition: new`，依規則皆非阻斷，pass 條件成立。

這一輪是整個 loop 十輪下來第一次沒有任何 `fix-introduced`。前九輪約六成的 finding 都是我修上一個問題時新寫的東西所引入，本輪為 0——這是收斂的實質訊號，而不只是缺陷數變少。Reviewer A 明確回報「design 中每一項可量測的 code-facing 論斷我都獨立重跑過，無一為假」，對照本 change 已記錄六次的「敘述未經自己量測」，這是該病灶第一次沒有復發。

Q-1 值得單獨記錄，即使它非阻斷。它揭露的不是「該不該防範」的爭議——本 change 一致地選擇不防範，且該決定有充分理由——而是我在 Risks case 2 的括號裡看過這個輸入形狀，卻用「亦非 fail closed」把它踢出了風險清單，從未陳述容忍之後對同一輸入會發生什麼。而它恰好是三個方向中唯一使用者完全沒有訊號的資料移除：exit code 不變、分類結果不變、dry-run 不預覽。把它寫進 requirement 的接受條款，是這輪最實質的改動。

## Fix Actions

無 blocking 成員需處理。7 個非阻斷項全部修復——雖然規則只要求為 `new` finding 記三桶分類的 triage note，但這 7 項皆已驗證為事實正確且修法成本低，其中 Q-1 更會影響併入 master 的永久接受條款，因此一併修掉而非留給 apply 階段。無 grader-protection 保留項，無 accepted-risks 條目。修改檔案共 4 個：`proposal.md`、`design.md`、`tasks.md`、`specs/cash-cli/spec.md`。

**修 Q-1** — delta 的行為改變列舉由兩個方向擴為三個，第三個明訂為「由原本被忽略而內容原樣保留變成被當作真 marker 而內容被替換或移除」，並明記它 MUST 被明確涵蓋而非視為前兩者的特例、其前後兩次安裝的 exit code 與分類皆不變、使用者沒有任何訊號、`--dry-run` 不預覽，且該列舉 MUST NOT 被讀成窮舉。design 的 Risks 新增一整段記載第三個方向與其實測，並在 case 2 的括號補上「亦非 fail closed 不等於無風險」與該形狀在容忍後的實際後果，另附記 tasks 1.4 case 二測的正是同一個定位事件的良性面。

**修 Q-2** — delta 該句改為「字尾內容 MUST NOT 被解析、比較或用於 marker 定位的任何決策」，並明寫此限定僅及於定位、source 側以字尾之有無為判準的禁令不受本段拘束。proposal 的對應 Non-Goal 同步。

**修 A-f1** — 在該 scenario 補一條與 `<`／`>` referral 同形的 AND：同一份 guidance 中該名稱另有其他 marker 而使匹配計數落入重複或孤立判定者不屬本 scenario，由 `帶字尾 marker 違反判定仍 fail closed` 涵蓋，並註明此限定與等價保證段的逐檔判準一致。

**修 A-f2** — IC4 與 delta 的「僅附加該路徑」改為「僅附加該標籤」，與同段前文及 tasks 2.2 對齊。

**修 Q-3** — IC7 的敘述改為「sibling 曾於本 loop 進行期間把該檔由 `2.3.1` 升為 `2.4.0`，並已於 commit `2c700eb` 提交並封存，故當下工作樹與 HEAD 皆為 `2.4.0`」，並移除第二分支括號內已過期的「即本 change 撰寫當下的狀態」。tasks 2.5 的快照值更新為「工作樹與 HEAD 皆為 `2.4.0`，故應寫 `2.4.1`」，sibling 敘述改為已提交並封存。`MUST 重新讀取` 的指令不動。

**修 Q-4** — 1.2 明訂 fixture 取「START 帶字尾、END 不帶字尾」以貼合語料與對應 Example，斷言改為排他形式（exit 0、不含任何 `SPECTRA:` marker、恰含一個 Cash block 且內容等於 canonical），並寫出為何非排他形式在修復前不會 red。

**修 Q-5** — IC5 末句改為「必須包含帶 source 限定詞的標籤（其中含相對路徑）」，與 2.3 及 1.6 後者一致。

**修正後的機械自檢** — 重跑全部檢查。捕捉到一處 fix 未完全傳播：design IC4 仍殘留一句「僅附加該路徑」（A-f2 的第二個出現處），已一併修正。修正後：delta 註解計數 2 比 2 平衡；tasks 全部粗體項皆為 scenario 或 requirement 名，無 emphasis 粗體；9 個 scenario 與 3 個 Example 對 tasks 的雙向對應無缺漏；計數三處一致（IC6 六加八、Risks 十四、proposal 六類加八類）與 16 個 task；「僅附加該路徑」「用於任何決策」「HEAD 為 `2.3.1`」殘留皆為 0；MODIFIED 標題與 master 逐 byte 相符。重跑 `cash validate` 通過。

**Signal-derived checks** — 全部 open signal 皆無 `check` frontmatter 欄位，採 best-effort。本輪最相關者：`policy-surface-enumeration-incomplete`（Q-1 的方向列舉缺第三項、A-f1 的例外碑文不完整）、`spec-normative-scope-overreach`（Q-2 的絕對語氣禁令與同 requirement 的另一條 MUST 抵觸）、`cross-artifact-definition-drift`（A-f2 與 Q-5 的措辭三處不一致）、`test-fixture-required-case-missing`（Q-4 的非排他斷言）。

## Decision

passed

post-filter cumulative blocking set 為空：0 個 Critical、0 個 Warning。唯一成員 R9-1 已由兩位 reviewer 各自獨立讀原始碼後以 verified resolution 離開集合。本輪 7 個 finding 全部 `disposition: new`，依規則皆非阻斷，且已全部修復並記錄於 `## Fix Actions`。

本次 re-run 共四輪（round 7 至 10），依序解決 F1、A-1、V-2、R9-1，並於本輪首次出現零 `fix-introduced`。連同前一次執行的 6 輪，本 change 的 propose 品質關卡共歷 10 輪、修復 26 個 blocking 項，現正式通過。
