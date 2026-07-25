# Cash Propose Review — Round 4

本輪為 full 輪（第四輪 checkpoint 全面重掃），由 Reviewer A — Adherence 與 Reviewer B — Quality 兩個 fresh sub-agent 平行審查。兩位皆對本機真實語料與 patched installer 做了端對端實跑。

## Reviewer Findings

### Cumulative blocking set 判定

| member | verdict | 依據摘要 |
| --- | --- | --- |
| NF1 | resolved | 兩位 reviewer 各自獨立確認：`## Risks / Trade-offs` 現為「IC6 的十二個情境中」，與 IC6 的六加六一致；「十三」在四個 artifact 中殘留為 0。Reviewer B 另逐一把十二個情境對回 tasks，雙向無孤兒、無重複計數 |

Reviewer A 另完成 checkpoint 全面重掃並回報：**無任何 design 對程式碼的論斷為假**。design 引用的全部實測數字皆重現——Tubify 的 `(1200, 5095)`、legacy span `(0, 1198)` 與 `CLAUDE.md` 的 `(0, 1212)`、構造反例的三個值、16 個語料檔 × 兩個名稱共 32 次定位的不一致數 0、`CASH-SKILLS.md` 的 14 條字面與 `fail closed` 的五個出現行。delta 標題、首段與三個保留 scenario 與 master 逐 byte 相符。不宣告 `skill-checks.fish` 與 `cli-checks.fish` 的判斷成立（後者全檔 58 行，`marker`／`guidance`／`installer` 命中數為 0）。`--self` 只寫 gitignore 的 receipt，非未宣告的交付。

Reviewer B 另確認四個方向無缺陷：端對端有效性（monkeypatch 後實跑 `--all --dry-run`，`failed=2` 變 `failed=0`，**無第二個隱藏失敗點**）；1.7 的 source fixture 可在既有 harness 的暫存 bundle 副本上構造，不需改動 repo 自身檔案；`CASH-SKILLS.md` 改寫可行；scope 不建議拆分——IC5、IC4、2.4 三項都是同一段程式碼改動的直接後果，拆出去會留下沒有 owner 的散播風險。

### Warning

**Q1**（confidence 85，layer design，`disposition`：`fix-introduced`，`introduced_by`：round 1 `## Fix Actions` 的「修 W5」——該 fix 把 D3 寫成「target 側是修復」的無條件論斷）

- `location`：`design.md` D3 與 `## Risks / Trade-offs` 第二段
- `summary`：D6 與 Risks 只記錄一個方向的行為改變（現行可安裝 → 容忍後 fail closed）。反方向同時存在且後果更嚴重：一份現行 fail closed 的 target guidance，容忍之後會成功安裝並靜默刪除或覆寫 project-owned 內容。
- 三個實測案例（Reviewer B 提出，主 agent 獨立複現其中兩個）：fenced 範例中的完整 legacy block 被辨識為真 marker 並替換為空 bytes，內容被刪除只剩空 fence；說明用的 Cash marker 對之間內容被整段換成 canonical block；`<!-- SPECTRA:START <!-- SPECTRA:START v1 -->` 起始的檔案在移除 legacy block 後首行永久殘留斷頭的 `<!-- SPECTRA:START `。三者現行實作皆 fail closed。
- 這正是 round 1 W5 在 source 側抓到的同一種無條件論斷，換到 target 側而無人複查。

**Q2**（confidence 90，layer design，`disposition`：`new`）`location`：`tasks.md` 第 1 節前言與 1.5。`summary`：1.5 的五個 case 未指明同一對 marker 的另一側是否也帶字尾。實測顯示現行實作對「只有單側帶字尾」的輸入必然造成計數失衡而已經 fail closed，只有兩側都帶字尾或完全沒有對側時計數才回到 0 對 0、installer 照常成功。因此反序、非獨立行、巢狀、重複四個 case 照字面寫出來在修復前就是綠的，等於四個 case 完全不驗證本次改動。主 agent 獨立實測確認：反序在單側帶字尾下現行即 raise，兩側帶字尾則現行回傳無 span。

**Q3**（confidence 85，layer design，`disposition`：`fix-introduced`，`introduced_by`：round 2 的「修 F2」）`location`：`tasks.md` 第 1 節前言與 1.6 前者。`summary`：1.6 前者的 fixture 在修復前後皆綠——現行實作與新實作對該輸入都回傳相同 span 並保留前綴。它的價值是防止實作者漏掉 `<` 排除，性質與 1.3 相同屬回歸鎖，但前言逐字寫「除 1.3 外的每一項都必須先確認因當前實作而失敗」且稱 1.3 為「明確例外」。實作者依前言會試圖讓它 red，做不到時最可能改寫 fixture 直到 red，而那會偏離它要鎖的性質。

**Q4**（confidence 80，layer design，`disposition`：`fix-introduced`，`introduced_by`：round 1 機械自檢的雙向對應修正——該修正加入「另兩個保留的 scenario 則分別由 3.2 與 1.5 承接驗證」一句）`location`：`tasks.md` 前言的 scenario 承接對應與 3.2。`summary`：3.2 被指派承接 **Missing、Spectra-only 與 mixed guidance 收斂**，但它只跑 `--dry-run`，而 dry-run 既不寫檔也不輸出 guidance diff，該 scenario 的三條斷言沒有任何一條被觀察到。3.2 只證明了「不再 fail closed」，那是 IC8 的內容。相關內部不一致：3.2 的前置步驟（先確認 guidance 已提交）是為保護真實安裝的刪除，但 3.2 只跑 dry-run，該前置對本 task 是空操作。

**Q5**（confidence 85，layer design，`disposition`：`fix-introduced`，`introduced_by`：round 1 的「修 W7」。與 Reviewer A 的 F-A3（Suggestion 60）合併，取 blocking disposition 與較高 confidence）`location`：`design.md` IC4 與 IC5、`tasks.md` 2.2／2.3／1.6、delta 的具名 scenario。`summary`：IC4 要求兩個呼叫端「各傳入其 `relative`」，但 `canonical_guidance` 與 `render_guidance` 的 `relative` 是同一組 `AGENTS.md` 與 `CLAUDE.md`，前者指 source repo 的檔案、後者指 target 的檔案，加上路徑後兩者訊息逐字相同。更嚴重的是批次路徑：`run()` 對每個 registry 條目以 target 路徑為前綴印出錯誤，因此一個 source 端的 marker 失敗會被印成 N 行、每行指控一個不同且無辜的 target。既有兩個 source 專用例外靠訊息中的 `source` 字樣自我消歧，IC4／IC5 對新訊息完全沒有這條要求。

**F-A1**（confidence 80，layer design，`disposition`：`fix-introduced`，`introduced_by`：round 2 的「修 F2」與 round 3 的「修 NF2」）`location`：`design.md` IC2 vs D2 末段與 delta 的等價保證段。`summary`：等價保證的範圍在三處互相矛盾。IC2 無條件寫「marker 所在行另有文字時亦不在保證範圍內」；D2 與 delta 卻寫該構造反例「屬本保證涵蓋範圍而非例外」。同一情形三處說法相反。主 agent 獨立核對三處原文確認。這是本 change 第四次出現「normative 範圍與實作前提不一致」。

### Suggestion（非阻斷）

- **F-A2**（75，`new`）delta 與 IC5 都要求 source 的 Cash **start 與 end** 皆不得帶字尾，2.3 也實作兩側，但 1.7 只構造 `CASH:START` 一個 case。實作者若只對 start 加檢查、end 沿用寬鬆定位，全部測試仍綠而該 MUST 已被違反——與 round 2 F8 對 `CASH:END` 的論證完全同型，定位側已為此建立標準，IC5 側未套用。
- **Q6／F-A4**（70／55，`new`，兩位 reviewer 獨立提出後合併）IC6 末句要求「成功情境必須一律斷言 span 外 bytes 與 mode 未變」，1.1／1.2／1.3 都逐字帶了，但 1.4 兩個 case 與 1.6 前者完全沒提。照 tasks 字面實作會產出三個不滿足該橫向要求的成功 case。
- **F-A5**（50，`fix-introduced`，`introduced_by`：round 3 的「修 NF3」與「修 NF5」）delta 在兩處 normative 列舉用「失衡」，而同一 requirement 其餘處與 master 既有正文一律用「孤立」。兩者在本設計中同義，但 MODIFIED 併回 master 後同一 requirement 內會出現兩個未定義關係的術語指涉同一判定。主 agent 獨立核對：master 該 requirement 用「孤立」2 次、「失衡」0 次。

### disposition 修正紀錄

Q1 與 Q4 由 reviewer 標為 `new`，主 agent 依規則檢查其是否位於本 loop 的 fix-touched 位置後修正為 `fix-introduced`：Q1 的「target 側是修復」措辭由 round 1 修 W5 寫入；Q4 的 scenario 承接句由 round 1 機械自檢的雙向對應修正加入。兩者皆由 non-blocking 轉為 blocking，證據記於各該 finding。

## Rating

- post-filter cumulative blocking set Critical count：**0**
- post-filter cumulative blocking set Warning count：**5**（Q1、Q3、Q4、Q5、F-A1）
- 非阻斷 triaged finding count：**4**（Q2、F-A2、Q6／F-A4、F-A5）
- `critical_gap`：**false**
- `round_type`：**full**

rationale：NF1 由兩位 reviewer 各自 verified resolved 離開集合。checkpoint 全面重掃的價值在本輪完全兌現——前三輪都是 delta 驗證，只看被改動的地方，因此 Q1 這種「從 round 1 起就寫錯、但沒有任何後續 fix 觸及它」的無條件論斷一直沒被看到。Q1 是本 change 目前為止最重要的發現：我在 round 1 修 W5 時把 source 側的方向修對了，卻同時把 target 側寫成無條件的「是修復」，而實測顯示 target 側同樣有反方向後果，且其中一個案例會產生結構損壞的輸出。這與 W5 是完全相同的錯誤模式，只是換了一側，而 round 2 與 round 3 的 delta 驗證都不會回頭看它。Q2 則揭露一個更難堪的事實：1.5 的五個 case 有四個照字面寫出來在修復前就是綠的，也就是本 change 宣稱最重要的「五種判定不放寬」驗證，實際上四分之四是空轉。

## Fix Actions

5 個 blocking 成員與 4 個非阻斷項全部修復。無 grader-protection 保留項，無 accepted-risks 條目。修改檔案共 4 個：`proposal.md`、`design.md`、`tasks.md`、`specs/cash-cli/spec.md`。

**修 Q1** — D3 的「target 側是修復」限定為「target 上的真 marker 是修復」，並明記推廣不成立。`## Risks / Trade-offs` 新增一整段對稱記載第二個方向，附三個實測案例與其後果（內容被刪除、內容被替換、斷頭 marker 永久殘留），並說明本次接受而不加防範的理由——可靠的區分需要行首錨定與 fenced 區塊解析，兩者都遠超本 change 範圍。delta 亦新增一段把雙向行為改變寫成 normative，明訂定位 MUST NOT 嘗試區分「文件中談到 marker」與「一個真的 marker」，且 span 外 bytes 逐 byte 保留契約在兩個方向皆維持。proposal 的第四點同步改寫。此修法刻意不放進 design 私有記錄而是寫入 requirement，因為它是使用者可觀察的行為契約。

**修 Q2** — 1.5 逐 case 寫死 fixture 形狀：反序、尾側非獨立行、巢狀三個 case 的 start 與 end 兩者皆帶字尾；重複 case 放兩個帶字尾的 start 且不放對側 end；孤立 case 放一個帶字尾的 start 且無對側。並把 red-first 的確認改為可稽核的斷言——修復前 exit 0、修復後非零——而不是只寫「必須先確認失敗」。

**修 Q3** — 第 1 節前言改為列出兩個 red-first 例外（1.3 與 1.6 前者），並註明 1.6 前者的對照組不是現行實作而是「一個只排除 `>` 而未排除 `<` 的假想錯誤實作」，可用 3.3 的對照組手法一次性反證。

**修 Q4** — scenario 承接改指向 1.1 與 1.2（只有它們逐條斷言了收斂結果）；3.2 改為 IC8 的端對端驗收並明記只跑 dry-run、不寫入、不需內容層級前置保護。原本掛在 3.2 的前置保護改寫為「交付說明」：真正的刪除會發生在使用者日後某次真實安裝，因此完成回報必須告知使用者刪除量與兩檔的 uncommitted 狀態。

**修 Q5** — IC4 由「相對路徑引數」改為「能唯一識別該 guidance 的標籤引數」，明訂標籤不得只是相對路徑並說明 `--all` 下的誤指控後果；`canonical_guidance` MUST 傳入帶 source 限定詞的標籤，沿用該函式既有兩個 source 專用例外的消歧慣例。IC5 同步。delta 的 requirement 條款與 scenario 各補一條「MUST 可區分 source 或 target」。tasks 2.2、2.3 同步，1.6 後半的斷言改為「source 側 case 含 source 限定詞、target 側不含」——只斷言路徑子字串會讓兩側同時通過而發現不了消歧缺失。

**修 F-A1** — IC2 末句改寫為與 D2、delta 一致：marker 之前同行若有普通文字（不含註解起始序列）不在保證範圍內，理由是行首錨定屬 Non-Goals；同行稍前為另一個註解起始序列的情形由 D1 的 `<` 排除規則處理，屬涵蓋範圍。delta 的對應句同步加上「不含註解起始序列」的限定。

**修 F-A2** — 1.7 由一個 case 擴為兩個（source `CASH:START` 帶字尾、source `CASH:END` 帶字尾），並說明兩者都必要的理由。IC6 的失敗情境由六個改為七個，總數由十二改為十三，`## Risks / Trade-offs` 與 proposal 的計數同步。

**修 Q6／F-A4** — 在第 1 節前言新增一段「全部成功情境的橫向斷言」，明訂每個成功情境都必須附帶 span 外 bytes 與 mode 兩項斷言，由前言單一承接、各 task 不逐項重述；IC6 末句同步改為指向該單一承接點。此作法與 IC4 具名檔案的橫向斷言處理方式一致。

**修 F-A5** — delta 三處「失衡」改為 master 既有詞彙「孤立」，design IC4 的「重複與失衡」同步改為「重複與孤立」。

**修正後的機械自檢** — 重跑全部檢查，捕捉到兩個本輪 fix 引入的缺陷並已修正：tasks 第 1 節前言的三個粗體小標題（`red-first 規則與其兩個例外。`、`全部成功情境的橫向斷言。`、`scenario 承接對應。`）會在雙向對應檢查中製造幽靈條目，已改為冒號引導的非粗體形式——這是本 session 第八次同型錯誤，前七次都是 emphasis 粗體，本次是結構性小標題，形態不同但後果相同；以及 design IC4 仍殘留一處「重複與失衡」未隨 F-A5 同步。修正後：註解計數 2 比 2 平衡；tasks 全部 10 個粗體項皆為 scenario 或 requirement 名；9 個 scenario 對 tasks 的雙向對應無缺漏；「失衡」在 delta 與 design 的殘留皆為 0；計數三處一致（IC6 六加七、Risks 十三、proposal 六類加七類），與 tasks 實際 case 數相符；MODIFIED 標題與 master 逐 byte 相符。重跑 `cash validate` 通過。

**Signal-derived checks** — 全部 open signal 皆無 `check` frontmatter 欄位，採 best-effort。本輪最相關者：`design-claim-unverified-against-code`（Q1——無條件論斷未經反方向驗證，與 round 1 W5 同型）、`test-fixture-required-case-missing`（Q2 的四個空轉 case、F-A2 的 `CASH:END`）、`acceptance-criterion-unreachable-at-specified-point`（Q4——被指派的 scenario 無法由該 task 的程序觀察到）、`spec-requirement-no-backing-task`（Q5——delta 有 MUST 而 IC 的實作方式無法達成）、`enumerated-site-set-factually-wrong`（F-A5 的術語分歧、Q6 的橫向要求未鏡射）、`cross-artifact-definition-drift`（F-A1 的三處矛盾）。

## Decision

next_round

post-filter cumulative blocking set 含 0 個 Critical 與 5 個 Warning（Q1、Q3、Q4、Q5、F-A1），未滿足 pass 條件。NF1 已以兩位 reviewer 的 verified resolution 離開集合。5 個 blocking 成員與 4 個非阻斷項皆已完成 fix 並記錄於 `## Fix Actions`。下一輪為本次執行的第五輪，非第四輪，故為 `micro` 輪，由單一 Reviewer V 對五個成員逐一給出 resolved/unresolved 判定，並重點檢查本輪三處改設計——雙向行為改變寫入 requirement、診斷標籤的 source 與 target 消歧、以及 1.5 的 fixture 形狀寫死——是否引入新缺陷。本次執行的 6 輪上限只剩兩輪，若第六輪仍未通過將依規則 abort 並做三桶分類。
