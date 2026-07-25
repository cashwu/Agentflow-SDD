# Cash Propose Review — Round 3

本輪為 micro 輪，由單一 Reviewer V — Verification 對 round 2 的 cumulative blocking set 做 delta 驗證，並重點審查 round 2 的兩項改設計：撤除「形式不被辨識」診斷分支後 delta 與 design 是否自洽，以及字尾排除 `<` 是否引入新的邊界問題。

## Reviewer Findings

### Cumulative blocking set 逐項判定

round 2 的 2 個 blocking 成員全數 `resolved`：

| member | verdict | 依據摘要 |
| --- | --- | --- |
| F1 | resolved | 該分支已整體撤除而非補丁。Reviewer V 核對：delta 9 個 scenario 中已無「形式不被辨識時的診斷不誤述為失衡」，requirement 正文亦無對應 normative 條款；IC4 收斂為「不新增任何其他診斷分支」，tasks 2.2 逐字鏡射；Non-Goal 於 design 與 proposal 雙處新增；對四個 artifact grep「形式不被辨識」「前綴」「誤述」的全部命中皆為「明示不做」的說明。撤除未留孤兒：9 個 scenario 中 8 個有 task 承接，唯一未承接者已明記為刻意；tasks 無任何一項失去對應 requirement |
| F2 | resolved | 處置為改設計且經實測驗證。字尾字集「同時排除 `<` 與 `>`」在全部 8 個敘述點一致，無殘留「僅不含 `>`」的敘述；假理由已於 design D2 與 delta 兩處移除並改為據實陳述，方向詞統一為「向前」。Reviewer V 獨立以 `re` 實作 delta 描述的 pattern 對照現行 `marker_span`：構造反例下現行 `(16, 54)`、新字集 `(16, 54)`、舊字集 `(0, 54)`，與 design 宣稱的三個值逐一相符。全語料回歸：16 個 guidance 檔案 × 兩個名稱共 32 次定位，舊實作成功的案例中新舊 span 不一致數為 0，唯一 4 處差異正是本 change 要修的缺陷本身 |

**本輪指定的三項重點核實**：Reviewer V 確認 `skill-checks.fish` 對 `CASH-SKILLS.md` 綁定的字面確為 14 條且含 `fail closed`；2.4 要改寫的第 68 行只命中其中 `fail closed` 一條，而該字面在另外四行仍存在，其餘 13 條全部落在改寫範圍之外，因此兩處改寫確實能在保留全部字面的前提下完成。五種 fail-closed 判定在新 pattern 下皆仍可觸發，tasks 1.5 的五個 case 皆可寫成 red。IC1–IC8 連續無缺、無殘留舊編號。

### Warning

**NF1**（confidence 100，layer text，`disposition`：`fix-introduced`，`introduced_by`：round 2 `## Fix Actions` 的「修 F1、F4、F5、F7」末句「IC6 的情境重算為六個成功與六個失敗」）

- `location`：`design.md` `## Risks / Trade-offs` 第三段
- `summary`：該段逐字寫「IC6 的十三個情境中」，但同檔 IC6 已重算為六個成功與六個失敗共十二個，proposal 亦寫六類與六類，tasks 實際 case 數同為 6+6。「十三」是 round 1 的 5+8 舊值，round 2 重算時漏改，屬同檔內對自身 IC 的事實性矛盾。
- 主 agent 已獨立核對兩行原文確認屬實。

### Suggestion（非阻斷）

- **NF2**（60，`new`）等價保證寫成逐個 marker 的判準，但實際定位是逐檔的：檔案內只要另有一個帶字尾的同名 marker，計數就會改變，原本被正確定位的那對獨立成行無字尾 marker 反而 fail closed。主 agent 獨立實測 `<!-- CASH:START -->\nx\n<!-- CASH:END -->\n<!-- CASH:START v1 -->\n`：現行實作回傳 `(0, 40)`，新 pattern 的 start 匹配數為 2 而觸發重複判定。該輸入滿足 scenario 的 GIVEN 但 THEN 不成立。行為本身刻意（Risks 已載明容忍會讓一部分現行可安裝的 target 變 fail closed），缺陷在於 normative 未把該情形排除，是 F1 同型。
- **NF3**（55，`new`）delta 的「全部 marker 相關失敗診斷 MUST 具名路徑」涵蓋 IC5 新增的 source 側 fail-closed，tasks 1.6 也要求對 1.7 的失敗 case 斷言含路徑，但 IC4 只把義務綁在 `marker_span` 的例外上，IC5 對該新 raise 的訊息內容完全沒有約束。實作者照 IC 字面即可寫出不含路徑的 source 側訊息。
- **NF4**（45，`new`）「帶字尾的 marker 被辨識並收斂」的 GIVEN 未加字集限定，THEN 卻是無條件的不得 fail closed；字尾含 `<` 或 `>` 者實測會 raise，THEN 對 GIVEN 的一個子集為假。可辯護的讀法是同 requirement 前段已定義「字尾」的形式，屬術語繼承，但 round 2 把排除字集由一個字元擴為兩個使該子集變大。
- **NF5**（40，`new`）IC4 與 delta 皆寫「既有的重複、失衡與反序診斷」，但 `marker_span` 現行實有三個例外訊息，分別對應非獨立行、重複與失衡、反序，列舉遺漏了非獨立行對應的訊息，使該訊息語意不受任何條款保護。主 agent 已獨立核對三個 `raise` 的訊息字面確認屬實。

### confidence filter 降級紀錄

NF4（45）與 NF5（40）低於 50，依 filter 丟棄，不進入 blocking set。兩者的判定皆經主 agent 獨立核對為事實正確且修法成本極低，因此仍在 fix actions 中一併修正。

## Rating

- post-filter cumulative blocking set Critical count：**0**
- post-filter cumulative blocking set Warning count：**1**（NF1）
- 非阻斷 triaged finding count：**4**（NF2–NF5）
- `critical_gap`：**false**
- `round_type`：**micro**

rationale：round 2 的 2 個成員全部以 verified resolution 離開集合，缺陷密度由 1C+1W 降至 0C+1W，且 Critical 首次歸零。撤除診斷分支這個決定經 Reviewer V 逐項核對確認乾淨——沒有殘留條款、沒有孤兒 scenario、沒有失去對應的 task，證明「四個獨立缺陷集中在同一處新設計就該撤除該設計」的判斷是對的。本輪唯一的 blocking 是重算 IC6 時漏改另一處引用的數字，屬純粹的傳播疏漏。值得記錄的是 NF2：它與 F1 是同一形態——normative 寫成無條件而實作有前提——這已是本 change 第三次出現，共同根因是我把「逐個 marker 的性質」與「逐檔的計數判定」混為一談，而 `marker_span` 的三層防護本來就建立在整份資料的計數上。

## Fix Actions

1 個 blocking 成員與 4 個非阻斷項全部修復。無 grader-protection 保留項，無 accepted-risks 條目。修改檔案共 3 個：`design.md`、`tasks.md`、`specs/cash-cli/spec.md`。

**修 NF1** — `## Risks / Trade-offs` 第三段的「十三個情境」改為「十二個情境」，與 IC6 的六加六一致。

**修 NF2** — IC2 與 delta 的等價保證改寫為逐檔判準：「一份 guidance 中某個名稱的全部 marker 都獨立成行且都不帶字尾時」才適用，並明文說明理由——定位的判定建立在整份資料的匹配計數上，同檔另有帶字尾同名 marker 時計數會改變而落入重複判定，該情形屬 D6 記載的行為改變、不在保證範圍內。對應 scenario 的 GIVEN 與 tasks 1.3 的 fixture 描述同步改為逐檔措辭。

**修 NF3** — IC5 補上「該例外訊息必須包含 source guidance 的相對路徑，與 IC4 對其餘 marker 例外的要求一致」；delta 的具名條款明列涵蓋範圍為非獨立行、重複、失衡、反序、巢狀與 source 字尾六項判定；tasks 2.3 補上訊息具名要求，1.6 明列其斷言涵蓋 `marker_span` 三個既有例外、`render_guidance` 的巢狀例外與 2.3 新增的 source 例外。

**修 NF4** — scenario 的 GIVEN 改為「帶有一段符合本 requirement 所定義之可接受形式的字尾」，並新增一條 AND 明記字尾含 `<` 或 `>` 者不屬本 scenario、由「帶字尾 marker 違反判定仍 fail closed」涵蓋。

**修 NF5** — IC4 的列舉改為「`marker_span` 全部既有例外的語意維持不變……現行三個例外分別對應非獨立行、重複與失衡、反序，四種判定一個都不得改變措辭語意」；delta 對應處與 scenario 的 AND 同步補上非獨立行。

**修正後的機械自檢** — 重跑全部檢查，未捕捉到本輪 fix 引入的新缺陷。註解計數 2 比 2 平衡；tasks 全部 10 個粗體項皆為 scenario 或 requirement 名，無 emphasis 粗體；9 個 scenario 對 tasks 的雙向對應無缺漏；「十三個情境」與舊的三項列舉措辭殘留皆為 0；MODIFIED 標題與 master 逐 byte 相符。重跑 `cash validate` 通過。

**Signal-derived checks** — 全部 open signal 皆無 `check` frontmatter 欄位，採 best-effort。本輪最相關者：`enumerated-site-set-factually-wrong`（NF5 的三項列舉遺漏、NF1 的數字漏改）、`spec-normative-scope-overreach`（NF2、NF4——normative 寫成無條件而實作有前提，本 change 第三次出現）、`spec-requirement-no-backing-task`（NF3——delta 有 MUST 而 IC 無對應約束）、`review-fix-propagation-incomplete`（NF1）。

## Decision

next_round

post-filter cumulative blocking set 含 0 個 Critical 與 1 個 Warning（NF1），未滿足 pass 條件。round 2 的 2 個成員已全部以 verified resolution 離開集合。1 個 blocking 成員與 4 個非阻斷項皆已完成 fix 並記錄於 `## Fix Actions`。下一輪為本次執行的第四輪，依規則為 `full` 輪，由 Reviewer A — Adherence 與 Reviewer B — Quality 兩個 fresh sub-agent 平行做全面重掃，並各自對 NF1 給出 resolved/unresolved 判定。
