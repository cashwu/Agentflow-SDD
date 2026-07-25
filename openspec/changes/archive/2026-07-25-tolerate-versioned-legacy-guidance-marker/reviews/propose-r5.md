# Cash Propose Review — Round 5

本輪為 micro 輪，由單一 Reviewer V — Verification 對 round 4 的 cumulative blocking set 做 delta 驗證，並重點審查 round 4 的三處改設計：雙向行為改變寫入 requirement、診斷標籤的 source 與 target 消歧、1.5 的 fixture 形狀寫死。

## Reviewer Findings

### Cumulative blocking set 逐項判定

round 4 的 5 個 blocking 成員全數 `resolved`：

| member | verdict | 依據摘要 |
| --- | --- | --- |
| Q1 | resolved | D3 已限縮為「target 上的真 marker 是修復」並明記推廣不成立；Risks 新增對稱的第三段；proposal 第四點改寫；delta 新增對應段落。單向論斷已消除（第二個案例的敘述有誤，另見 V1，但不影響方向性論斷的解除） |
| Q3 | resolved | 前言逐字列出兩個 red-first 例外並註明 1.6 前者的對照組是「只排除 `>` 的假想錯誤實作」。Reviewer V 實測佐證分類正確：對該 fixture 現行 `(16, 59)`、含 `<` 排除的新 pattern `(16, 59)`、只排除 `>` 的錯誤 pattern `(0, 59)` |
| Q4 | resolved（tasks 側） | scenario 承接已改指 1.1 與 1.2；3.2 改為 IC8 驗收並明記只跑 dry-run、不需內容層級前置保護。9 個 scenario 雙向對應無孤兒。design 側未同步，另見 V2 |
| Q5 | resolved | IC4 已改為「能唯一識別該 guidance 的標籤引數」並明訂不得只是相對路徑；IC5、tasks 2.2／2.3／1.6、delta 兩處全部同步。Reviewer V 以程式碼核實可實作性：`canonical_guidance` 既有兩個例外確為 `source guidance has no Cash block: {relative}` 與 `source guidance contains a legacy Spectra block: {relative}`，皆含 `source` 字樣；`render_guidance` 的巢狀例外為 `nested guidance markers: {relative}` 不含該字樣，故 1.6 的兩側斷言可執行；`run()` 確為以 target 路徑為前綴、`main()` 為 `Error: {error}`，兩條輸出路徑都會攜帶標籤 |
| F-A1 | resolved | IC2、D2 末段、delta 三處已一致，皆為「普通文字（不含註解起始序列）不在範圍內；同行稍前為另一個註解起始序列的情形由 `<` 排除規則處理，屬涵蓋範圍」。無殘留矛盾 |

**round 4 三處改設計的專項查核**：Reviewer V 實際構造 1.5 的五個 fixture 驗證 red-first，全部成立——現行 `marker_span` 對反序、非獨立行、重複、孤立四者皆回傳無 span 而 exit 0，對四個 marker 皆帶字尾的巢狀 fixture 兩個名稱亦皆回傳無 span、由 `render_guidance` 附加 canonical block 而 exit 0；新 pattern 則分別 `reversed`、`malformed`、`duplicate or unbalanced`（兩例）、以及 `CASH=(0,74)` 與 `SPECTRA=(25,100)` 相交觸發 `nested guidance markers`。逐 case 的規定本身正確。

**fix 傳播完整性**：計數三處一致（proposal 六類加七類、IC6 六個成功加七個失敗、Risks 十三），與 tasks 實際 case 數相符。「失衡」在 design 與 delta 殘留為 0。IC2 範圍、IC4 語意、tasks 前言兩段橫向規則、3.2 改 IC8 均已就位。delta 註解計數平衡，tasks 粗體項皆為 scenario 或 requirement 名。

### Warning

**V1**（confidence 85，layer design，`disposition`：`fix-introduced`，`introduced_by`：round 4 `## Fix Actions` 的「修 Q1」）

- `location`：`design.md` `## Risks / Trade-offs` 第三段的第二個案例
- `summary`：反方向行為改變的三個實測案例中，第二個如字面所寫在現行實作下並不會 fail closed。原文未指明該對說明用 Cash marker 帶字尾。
- 主 agent 獨立實測三種形狀：兩側皆不帶字尾時現行與新定位皆為 `(6, 49)`，根本不是行為改變；兩側皆帶字尾時現行回傳無 span 而於檔尾附加 canonical block，亦非 fail closed；只有恰有單側帶字尾才符合敘述——現行 raise、新定位 `(6, 51)`。
- 這一段是「本次接受這三個後果而不加防範」這個決定的證據基礎，三分之一的證據為假會使成本評估偏低。round 4 自述「主 agent 獨立複現其中兩個」，未複現的正是這一個。

**V2**（confidence 100，layer text，`disposition`：`fix-introduced`，`introduced_by`：round 4 `## Fix Actions` 的「修 Q4」）

- `location`：`design.md` Risks 兩處，對照 `tasks.md` 3.2
- `summary`：round 4 修 Q4 把 3.2 的內容層級前置保護移除並降級為交付說明，但 design 的 Risks 兩處仍逐字宣稱該保護是 3.2 的前置步驟，方向與 tasks 現況相反。同一件事在 design 與 tasks 兩處互相否定。
- 主 agent 獨立核對兩處原文確認屬實。這是本 loop 第一次由 fix 反向製造 design 對 tasks 的矛盾。

### Suggestion（非阻斷）

- **V3**（70，`fix-introduced`，`introduced_by`：round 4 的「修 Q1」）round 4 把雙向行為改變寫成 requirement 正文的 normative，但該段的規範性語句沒有任何 IC 定義、沒有 task 承接、也沒有 scenario 對應——它是本 requirement 中唯一一段沒有配套 scenario 的正文條款。其中「定位 MUST NOT 嘗試區分文件中談到 marker 與一個真的 marker」是對實作手法的禁止而非對可觀察行為的約束，無法機械驗證；而其真正可觀察的推論沒有任何 fixture 驗證。後果是：實作者若加入看似無害的防護（例如跳過 fenced 區塊內的 marker），既違反這條 MUST NOT 又不會有任何測試變紅；反之日後真要修這個資料損壞，必須先 MODIFY 一條剛寫進 master 的 MUST NOT。
- **V4**（90，`fix-introduced`，`introduced_by`：round 4 的「修 Q2」，與同輪「修 F-A5」的術語統一相衝突）tasks 1.5 的理由句有兩個缺陷同在一句。其一事實不成立：「只有兩側都帶字尾時計數才回到 0 對 0」，但同一 task 隨即規定的重複 case 與孤立 case 都不是兩側帶字尾，實測現行實作對兩者皆回傳無 span——正確表述應為「兩側都帶字尾或完全沒有對側時」，round 4 的 Q2 原文即如此，fix 時漏了後半。其二術語回退：同句的「計數失衡」使 round 4 修 F-A5 剛統一為「孤立」的術語在 tasks 重新出現。

## Rating

- post-filter cumulative blocking set Critical count：**0**
- post-filter cumulative blocking set Warning count：**2**（V1、V2）
- 非阻斷 triaged finding count：**2**（V3、V4）
- `critical_gap`：**false**
- `round_type`：**micro**

rationale：round 4 的 5 個成員全部以 verified resolution 離開集合，缺陷密度由 0C+5W 降至 0C+2W。本輪 4 個 finding 全部是 `fix-introduced`，且全部集中在 round 4 的修法本身——這是本 change 一再出現的模式：修一個問題時順手寫下的敘述或 normative，成為下一輪的缺陷來源。V1 最值得記錄：我在 round 4 為了論證「行為改變是雙向的」而列了三個實測案例，其中兩個我親自複現過，第三個是直接採信 reviewer 的敘述而未驗證——結果那一個的前提缺了「恰有單側帶字尾」這個關鍵條件，如字面所寫根本不成立。這與本 session 稍早我未經核對就宣稱 analyze 乾淨是同一種錯誤：把「別人說的」與「我驗證過的」混在同一份論證裡而不加區別。V3 則指出我把一條不可觀察的實作禁令寫成了永久 requirement，理由自述是「它是使用者可觀察的行為契約」，但被寫成 MUST NOT 的恰好是不可觀察的那一半。

## Fix Actions

2 個 blocking 成員與 2 個非阻斷項全部修復。無 grader-protection 保留項，無 accepted-risks 條目。修改檔案共 3 個：`design.md`、`tasks.md`、`specs/cash-cli/spec.md`。

**修 V1** — Risks 第三段的第二個案例補上「恰有一側帶字尾」這個前提，並把三種形狀的實測結果一併寫入，明記「恰有一側」不可省略的理由：兩側皆不帶字尾時新舊定位完全相同、根本不是行為改變，兩側皆帶字尾時現行回傳無 span 而於檔尾附加 canonical block、亦非 fail closed。案例一與案例三經本輪 reviewer 重新實測皆成立，不改動。

**修 V2** — Risks 兩處改為與 tasks 現況一致：3.2 本身只跑 dry-run、不寫入，因此該確認不是 3.2 的前置步驟，而是 3.2 明訂的完成回報交付說明，真正的刪除發生在使用者日後某次真實安裝。

**修 V3（採 reviewer 的 (a) 方案）** — 把不可觀察的實作禁令自 requirement 移除。delta 該段只保留可觀察的部分：容忍同時擴大與縮小可安裝 target 集合、兩個方向皆為本 requirement 接受的結果、span 外 bytes 逐 byte 保留契約在兩個方向皆 MUST 維持。「定位不去區分文件中談到 marker 與一個真的 marker」移入 design D6 作為 rationale，並在該處明文記錄為何不寫成 MUST NOT——不可觀察的實作禁令無法機械驗證，且會使日後真要修這個資料損壞時必須先 MODIFY 一條剛寫進 master 的條款。選 (a) 而非 (b) 的理由：(b) 要新增 scenario、IC6 情境與 task，使情境數由十三變十四並牽動三處計數，而新增的驗證對象是一個本 change 明確不打算防範的資料損壞行為，把它固定成回歸測試會讓日後修復更難。

**修 V4** — 1.5 的理由句改為「只有兩側都帶字尾、或完全沒有對側時，計數才回到 0 對 0」，並把「計數失衡」改為「計數不相等」以與 F-A5 統一後的術語一致。逐 case 的 fixture 規定本身正確（reviewer 已實測五個 fixture 的 red-first 全部成立），只改這句理由。

**修正後的機械自檢** — 重跑全部檢查，未捕捉到本輪 fix 引入的新缺陷。`列為前置步驟`、`MUST NOT嘗試區分`、`計數失衡`、`失衡` 在對應 artifact 的殘留皆為 0；delta 註解計數 2 比 2 平衡；tasks 全部 10 個粗體項皆為 scenario 或 requirement 名；9 個 scenario 對 tasks 的雙向對應無缺漏；MODIFIED 標題與 master 逐 byte 相符。重跑 `cash validate` 通過。

**Signal-derived checks** — 全部 open signal 皆無 `check` frontmatter 欄位，採 best-effort。本輪最相關者：`design-claim-unverified-against-code`（V1——採信未驗證的敘述並寫進論證）、`review-fix-propagation-incomplete`（V2——改 tasks 未同步 design）、`spec-normative-scope-overreach`（V3——把不可觀察的實作禁令寫成永久 normative）、`enumerated-site-set-factually-wrong`（V4 的事實與術語）。

## Decision

next_round

post-filter cumulative blocking set 含 0 個 Critical 與 2 個 Warning（V1、V2），未滿足 pass 條件。round 4 的 5 個成員已全部以 verified resolution 離開集合。2 個 blocking 成員與 2 個非阻斷項皆已完成 fix 並記錄於 `## Fix Actions`。下一輪為本次執行的第六輪，非第四輪，故為 `micro` 輪，由單一 Reviewer V 對 V1 與 V2 給出 resolved/unresolved 判定，並檢查本輪把 normative 降級為 rationale 是否留下缺口。第六輪為本次執行的最後一輪，若未通過將依規則記 `aborted` 並做三桶分類。
