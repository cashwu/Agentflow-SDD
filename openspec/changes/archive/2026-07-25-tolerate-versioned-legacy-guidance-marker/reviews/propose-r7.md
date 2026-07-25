# Cash Propose Review — Round 7

本輪為 re-run 的第一輪（`full` round，seeded）。前一次執行跑滿 6 輪後以 `aborted` 收尾，abort triage 的 bucket 1 只有一個成員 F1，本輪以它為 seeded cumulative blocking set。由 Reviewer A — Adherence 與 Reviewer B — Quality 兩個 fresh sub-agent 平行審查。

## Reviewer Findings

### Seeded cumulative blocking set 判定

| member | verdict | 依據摘要 |
| --- | --- | --- |
| F1 | resolved | **兩位 reviewer 各自獨立量測後判定**，且皆重驗了 Risks 第三段的全部三個案例而非只驗 F1 指出的那一個。Reviewer A：案例一在範例兩側皆不帶字尾時新舊皆為 `(47, 96)` 逐 byte 相同、帶 ` v1.0.2` 時舊 raise 而新為 `(47, 103)`，差值 7 等於該字尾長度、算術自洽；案例二三種形狀全部重現；案例三新定位起點落在第二個 marker、遷移後首行殘留斷頭 marker 且該 bytes 落在 span 外。Reviewer B 以自己的 fixture（filler 較長，絕對值為 `(47, 104)` 與 `(47, 111)`）獨立取得同一位移 7，載重關係一致 |

F1 的判定方式本身是本輪設計的重點。該 finding 的成因正是「採信未經自己量測的敘述」，因此兩位 reviewer 都被要求必須基於自己跑出的數字判定，不得引用 `## Fix Actions` 的自述。seeded set 因此清空。

Reviewer A 另完成全面 adherence 重掃並回報：**code-facing claims 全數核對無誤**，design 引用的實測數字（Tubify 的 `(1200, 5095)`、legacy span 長度 1198 與 1212、span 後兩個空行、16 檔語料的不一致數 0、`CASH-SKILLS.md` 的 14 條字面與五個 `fail closed` 出現行、`scripts/` 無 legacy start marker 字面）全部重現；delta 標題、首段與三個保留 scenario 與 master 逐 byte 相同；requirement 正文 7 段皆有承接；scope 未溢出，不宣告 `skill-checks.fish` 與 `cli-checks.fish` 的判斷成立；IC1–IC8 皆可機械驗證且各有 task；Non-Goals 無被違反。

Reviewer B 另以 patched bundle（含 IC4 標籤與 IC5 source 檢查）實跑端對端：`--all --dry-run` 得 `would-update=7 failed=0`，**無第二個隱藏失敗點**；本 repo 自身 guidance 通過 IC5 的新檢查，不會擋住全部 target；四檔 render 結果 idempotent、mode 保持 `0644`；1.5 五個 fixture 的 red-first 逐一實測皆成立；IC4 的標籤設計不與既有訊息形式衝突（`scripts/` 全域無斷言 marker 例外字串）。

### Warning

**B-1**（confidence 85，layer design，`disposition`：`new`）

- `location`：`design.md` D3 與 `## Risks / Trade-offs` 第二段；`tasks.md` 2.4
- `summary`：D3 把 source 側風險敘述為單一項（帶字尾的 Cash marker 被散播）並以 IC5 收束，Risks 則把「現行可安裝 → 容忍後 fail closed」整段寫成 target 側的事。實際上同一方向在 source 側也存在，後果嚴重一個數量級：source guidance 只要有一行提到帶字尾的 legacy marker，`canonical_guidance` 對該名稱的定位就會失衡而 fail closed，於是每一個 registered target 都安裝失敗。IC5 不攔這個——它只管 source 的 Cash marker 字尾。
- 主 agent 獨立實測確認：在本 repo 的 `AGENTS.md` 的 Cash block 內插入一行含 `<!-- SPECTRA:START v1.0.2 -->` 的說明文字，現行實作對該檔的 `SPECTRA` 定位回傳無 span 而放行，容忍之後則拋例外。Reviewer B 以 patched bundle 實跑 `--all` 得 `failed=7`。
- 本 repo 的 `CASH-SKILLS.md` 今天就含有一行這種寫法，可見它在本專案是自然會出現的形式。

**B-2**（confidence 90，layer design，`disposition`：`new`）

- `location`：`design.md` IC4 與 IC6 的失敗情境清單；`tasks.md` 1.5、1.6 後者、1.7
- `summary`：沒有任何情境會讓 `marker_span` 在 source guidance 上拋例外，IC4 最核心的那條 MUST 因此無可執行驗證。十三個情境的分布是：1.5 的五個失敗 case 全部在 target 側，1.7 的兩個在 source 側但打到的是 2.3 新增的 IC5 例外而非 `marker_span`。實作者只要在 2.3 的新訊息裡寫死 source 限定詞、而 `canonical_guidance` 呼叫 `marker_span` 時照舊傳相對路徑，全部斷言仍會綠而 IC4 已被違反，且 IC4 當初要解的問題（`--all` 下一個 source 端失敗被印成 N 行、每行指控無辜 target）對三個既有例外原封不動地留著。
- 主 agent 獨立核對 1.5 與 1.7 的情境分布確認屬實。Reviewer B 實測誤導輸出確實存在：source `AGENTS.md` 放兩個 Cash start 時，patched 版印出 7 行以不同 target 為前綴的相同訊息。
- 這與 round 4 的 F-A2（只測 `CASH:START` 會讓「只對 start 加檢查」的實作通過）是同一物種，該案當時判為 blocking。

**A-1**（confidence 100，layer text，`disposition`：`fix-introduced`，`introduced_by`：round 6 `## Fix Actions` 的「修 F2」）`location`：`tasks.md` 第 1 節前言。`summary`：同一句內自相矛盾——開頭寫「red-first 規則與其兩個例外」，緊接著寫「例外有三個：1.3、1.6 前者與 1.7」。round 6 把例外由兩個擴為三個時改了列舉與內文，漏改引導語的數量詞。主 agent 獨立核對該行原文確認。

**A-2**（confidence 95，layer design，`disposition`：`new`）`location`：`design.md` `## Risks / Trade-offs` 第一段。`summary`：「四段 block 的內容 digest 一致」如字面所寫為假，且與同括號內前半句自相矛盾——長度既已分別為 1198 與 1212 就不可能同 digest。主 agent 獨立量測四段 sha256：兩個 `AGENTS.md` 皆為 `34071a858c072c1d…`、兩個 `CLAUDE.md` 皆為 `7a48fb2a0fe0b9fa…`，是兩個相異 digest 各兩份。載重結論（是標準死指引而非使用者客製）仍成立，兩兩逐 byte 相同對它的支撐反而更強。

### Suggestion（非阻斷）

- **B-3**（70，`new`）1.4 case 二的斷言強度不足以在修復前變紅。現行實作對兩端皆帶字尾的 Cash block 是計數 0 對 0、回傳無 span、於檔尾附加 canonical block 而 exit 0，因此若實作者寫成「含 canonical block」加「exit 0」，兩條在修復前都成立。1.1 已用「恰含一個 Cash block」堵住同型陷阱，1.4 沒有沿用。
- **B-4**（60，`new`）第四種未被列舉的行為改變形狀：一個貨真價實的完整 legacy block，兩側皆帶字尾且 end marker 是檔案最後一行、其後無尾隨換行。現行因字面計數 0 對 0 而附加 canonical block 並 exit 0；容忍之後兩個匹配成立但 end 尾側不是換行，落入非獨立行判定而整個 target fail closed。它既非散文也非範例，因此 requirement 正文與 Risks 三案例的「形似 marker 的散文或範例」措辭沒有涵蓋它的形狀。前提要求兩側皆帶字尾，語料上不存在，實務風險低。
- **A-3**（65，`new`）tasks 2.4 要求 `CASH-SKILLS.md`「兩處都要改」，但 design D7 與 proposal 只記載其中一處，tasks 因而承載了一項在 design 與 proposal 中沒有對應決策記載的交付。

## Rating

- post-filter cumulative blocking set Critical count：**0**
- post-filter cumulative blocking set Warning count：**1**（A-1）
- 非阻斷 triaged finding count：**5**（B-1、B-2、B-3、B-4、A-3）
- `critical_gap`：**false**
- `round_type`：**full**

rationale：seeded 成員 F1 由兩位 reviewer 各自獨立量測後 resolved，離開集合。依 seeded re-run 第一輪的規則，本輪的 blocking 判定以 seeded set 為準，新發現的 `new` findings 不阻斷；唯一進入集合的是 A-1，因其 disposition 為 `fix-introduced`。

本輪最有價值的兩個發現都是 `new` 而非阻斷，但都很重要。B-1 揭露我把 source 側的風險清單當成只有一項：IC5 攔的是 source 的 Cash marker 帶字尾，但 source guidance 裡任何一行形似 legacy marker 的散文會讓**全部** target 一起 fail closed，而本 repo 的 `CASH-SKILLS.md` 今天就有這種寫法。B-2 則指出 IC4 的核心 MUST 完全沒有驗證點——這是 round 4 F-A2 的同型復發，我當時為定位側建立了「四個 name 與種類組合必須全部有案例」的標準，卻沒有把同一標準套用到「例外的觸發側」。

A-2 值得單獨記錄：那句「四段 digest 一致」來自 round 4 Reviewer B 的敘述，我直接抄進 design 而未量測。這是本 change 第三次同型錯誤（W5、V1 與 F1、再加這一筆），且 round 6 的收斂檢查逐字寫了「design 引用的實測數字無一為假」——這筆就是它的反例。前兩次都是 reviewer 抓出來的，這次也是。

## Fix Actions

1 個 blocking 成員與 5 個非阻斷項全部修復。無 grader-protection 保留項，無 accepted-risks 條目。修改檔案共 4 個：`proposal.md`、`design.md`、`tasks.md`、`specs/cash-cli/spec.md`。

**修 B-1** — D3 增列第二個 source 側後果並附實測（現行放行、容忍後拋例外、`--all` 由 `failed=0` 變全部 failed），明記它與 Risks 記載的 target 側是同一機制但後果由「該 target 失敗」升級為「全部 target 失敗」，且不被 IC5 攔下；同時記錄本 repo `CASH-SKILLS.md` 今天就有這種寫法。本次不加防範（理由同 D6），但 tasks 2.4 的文件改寫由兩處擴為三處，明文告知使用者。

**修 B-2** — 新增 tasks 1.8：source 的 `AGENTS.md` 含兩個 `CASH:START`（或任一違反非獨立行、反序的形狀），斷言 installer 非零結束、無任何 target 檔案被建立或修改、且診斷同時含 source 限定詞與相對路徑。delta 在 `全部 marker 失敗診斷具名檔案` 之下新增 `##### Example: source 側的 marker 失敗具名`。IC6 的失敗情境由七改為八、總數由十三改為十四，並明記最後一項不可省略的理由。1.6 後者的涵蓋敘述加入 1.8，2.5 的前置由「1.1 至 1.7」改為「1.1 至 1.8」。proposal 的計數同步為六類加八類。

**修 A-1** — 前言引導語的「兩個例外」改為「三個例外」。

**修 A-2** — Risks 第一段改為據實表述：兩個 `AGENTS.md` block 逐 byte 相同、兩個 `CLAUDE.md` block 逐 byte 相同，是兩個相異 digest 各兩份而非四段一致，並說明長度不同就不可能同 digest，以及兩兩相同對「標準死指引」這個結論的支撐反而更強。

**修 B-3** — 1.4 case 二的斷言改為與 1.1 對齊的排他形式：檔案恰含一個 Cash block、其內容等於 canonical block、且不含任何帶字尾的 `CASH:` marker，並寫出為何非排他形式在修復前不會 red。

**修 B-4** — Risks 第三段補上第四種形狀的完整敘述與實測，並明記列出它的目的是讓 requirement 正文的「散文或範例」不被讀成窮舉。不新增 task。

**修 A-3** — D7 補一段說明同步範圍不只那一句：IC5 與 D3 各引入一個「一個 source 檔擋掉全部 registered target」的新失敗模式，兩者都是使用者無從自行推導的行為，因此 tasks 2.4 要求改寫三處。proposal 的第六點同步。

**修正後的機械自檢** — 重跑全部檢查，捕捉到一個本輪 fix 引入的缺陷並已修正：tasks 1.4 出現 emphasis 粗體 `**恰含一個**`（本 session 第九次同型錯誤）。修正後：delta 註解計數 2 比 2 平衡；tasks 全部粗體項皆為 scenario 或 requirement 名；9 個 scenario 與 3 個 Example 對 tasks 的雙向對應無缺漏；計數三處一致（IC6 六加八、Risks 十四、proposal 六類加八類）且與 tasks 實際情境數相符；舊措辭（`其兩個例外`、`四段 block 的內容 digest 一致`、`七類失敗情境`、`1.1 至 1.7`）殘留皆為 0；MODIFIED 標題與 master 逐 byte 相符。重跑 `cash validate` 通過。

**Signal-derived checks** — 全部 open signal 皆無 `check` frontmatter 欄位，採 best-effort。本輪最相關者：`design-claim-unverified-against-code`（A-2——第三次採信 reviewer 未量測的敘述並寫進論證）、`test-fixture-required-case-missing`（B-2 的 IC4 無驗證點、B-3 的非排他斷言）、`policy-surface-enumeration-incomplete`（B-1 的 source 側風險清單只有一項、B-4 的形狀列舉被讀成窮舉）、`review-fix-propagation-incomplete`（A-1 的數量詞漏改）、`spec-requirement-no-backing-task`（A-3 的 tasks 交付無 design 決策記載）。

## Decision

next_round

post-filter cumulative blocking set 含 0 個 Critical 與 1 個 Warning（A-1），未滿足 pass 條件。seeded 成員 F1 已由兩位 reviewer 各自獨立量測後以 verified resolution 離開集合。1 個 blocking 成員與 5 個非阻斷項皆已完成 fix 並記錄於 `## Fix Actions`。下一輪為本次執行的第二輪，非第四輪，故為 `micro` 輪，由單一 Reviewer V 對 A-1 給出 resolved/unresolved 判定，並重點檢查本輪兩處新增設計——tasks 1.8 與其對應的 `##### Example`、以及 D3 新增的第二個 source 側後果——是否引入新缺陷。本次執行的 6 輪上限尚餘四輪。
