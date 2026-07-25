# Cash Propose Review — Round 8

本輪為 micro 輪，是 re-run 的第二輪。由單一 Reviewer V — Verification 對 round 7 的 cumulative blocking set 做 delta 驗證，並重點審查 round 7 兩處新增設計：tasks 1.8 與其 `##### Example`、D3 新增的第二個 source 側後果。

## Reviewer Findings

### Cumulative blocking set 判定

| member | verdict | 依據摘要 |
| --- | --- | --- |
| A-1 | resolved | tasks 第 1 節前言現為「red-first 規則與其三個例外：……例外有三個：1.3、1.6 前者與 1.7」，引導語與列舉一致，同句矛盾消除；全 change grep `其兩個例外` 殘留為 0 |

### round 7 兩處新增設計的專項查核

**tasks 1.8 的 red-first 分類正確，不需列為第四個例外。** Reviewer V 實測：source `AGENTS.md` 含兩個獨立成行的 `<!-- CASH:START -->` 時，現行 `marker_span` 走重複判斷並拋 `duplicate or unbalanced CASH guidance marker`，訊息不含檔名也不含 source 限定詞。因此 1.8 的三條斷言中，「非零結束」與「無 target 檔案被建立或修改」在修復前已成立，「診斷同時含 source 限定詞與相對路徑」在修復前為紅——整個 case 在修復前為紅，符合 red-first。與 1.7 的差別在於 1.8 把診斷斷言寫在自己任務內，而 1.7 的存活斷言無法變紅、要靠 1.6 後者追加的診斷斷言才紅。

**D3 第二個 source 側後果的前提與後果成立，但機制歸屬敘述有誤（見 V-3）。** Reviewer V 確認：現行實作對含該散文的 source 回傳無 span 而放行、容忍後拋例外；`canonical_guidance` 在 `render_guidance` 內對每個 target 各呼叫一次，故一個 source 失敗確實使 7 個 registered target 全數失敗；本 repo `CASH-SKILLS.md` 第 68 行今天確實含該形式的字串且在新 pattern 下會匹配。「本次不加防範」與 requirement 正文相容——master 的 `Guidance marker malformed` 已涵蓋 source 或 target 非獨立行須 exit 1，此後果本就在既有 normative 範圍內。

**最終收斂檢查全部通過。** 9 個 scenario、3 個 Example、IC1–IC8、16 個 task 三向對應無孤兒無重複；計數三處一致；delta 標題與首段與 master 逐 byte 相同、三個保留 scenario 逐字未改；`cash validate --all` 與 `test_live_namespace.py` 通過。design 引用的實測數字經 Reviewer V 逐項獨立量測後**全部成立**，包含 round 7 新寫入的第四種形狀與 A-2 修正後的 digest 敘述。

### Critical

**V-1**（confidence 100，layer design，`disposition`：`new`）

- `location`：`design.md` IC7 與 `tasks.md` 2.5
- `summary`：IC7 與 2.5 寫死「`cash-skills.version` 由 `2.3.1` 調升為 `2.3.2`」，但工作樹當前值已是 `2.4.0`。該調升來自同一 workspace 的 sibling change `guard-post-archive-commit-allowlist`，其 10 個 task 已全部完成。
- 主 agent 獨立核對確認：`git show HEAD:cash-skills.version` 為 `2.3.1`，工作樹為 `2.4.0`，尚未提交；guard 的 tasks 完成度為 `[x]=10 [ ]=0`。實測 `2.3.2` 不大於 `2.4.0`，`check_history` 會拋 bundle version must strictly increase，IC8 的三道關卡必然失敗；反之若 sibling 尚未落地就寫 `2.3.2`，會靜默回退它已完成的調升。
- 特別值得記錄：guard 的 task 5.1 用的正是推導式寫法（讀取當下值與 HEAD 值再取嚴格大於者），且其 design 與 task 正文**逐字點名本 change**並警告不得寫死常數。sibling 做對了，本 change 犯了它警告的錯。
- 依規則 `new` 的 Critical 為非阻斷，但它是 apply 時必然踩到的可實作性阻斷，已於本輪修復。

### Warning

**V-2**（confidence 100，layer text，`disposition`：`fix-introduced`，`introduced_by`：round 7 `## Fix Actions` 的「修 B-1」與「修 A-3」）

- `location`：`tasks.md` 2.4
- `summary`：與 A-1 完全同型的數量詞漏改，且同一任務內出現兩處。2.4 開頭仍寫「兩處都要改」、句尾仍寫「這兩處 drift」，中間卻列舉「其一、其二、其三」。round 7 把 2.4 由兩處擴為三處時只改了列舉與說明段。對照證據：proposal 已寫「需改寫三處」、design D7 已寫「要求改寫三處而非一處」，唯獨 tasks 2.4 自身的兩個數量詞停留在「兩處」。

### Suggestion（非阻斷）

- **V-3**（100，`fix-introduced`，`introduced_by`：round 7 的「修 B-1」）round 7 新寫入的敘述把觸發的判定歸錯類。D3 寫「算出計數不相等而 fail closed」、tasks 2.4 其三寫「定位會失衡而 fail closed」，但同段自己給出的實測 fixture 是散文中的舉例，marker 後緊接的是反引號而非換行——實測該形狀走的是非獨立行判定並拋 `malformed`，不是 `duplicate or unbalanced`。只有當該 marker 恰好獨立成行且無對側時才會落入計數不相等。載重結論不受影響，但 2.4 其三若被逐字寫進 `CASH-SKILLS.md`，使用者看到的錯誤字樣會與文件描述的機制對不上。這是本 change「敘述未經自己量測」同型的延續。

## Rating

- post-filter cumulative blocking set Critical count：**0**
- post-filter cumulative blocking set Warning count：**1**（V-2）
- 非阻斷 triaged finding count：**2**（V-1、V-3）
- `critical_gap`：**false**
- `round_type`：**micro**

rationale：A-1 已 verified resolved 離開集合。round 7 新增的兩處設計經專項查核未引入結構性缺陷，1.8 的 red-first 分類正確且其斷言分佈恰好讓整個 case 在修復前為紅。

本輪最重要的是 V-1，它是一個外部條件變化造成的缺陷而非我自己寫錯推理：sibling change 在本 loop 進行期間完成並改變了 `cash-skills.version` 的工作樹值。值得記錄的是，我在本 session 稍早回答使用者「兩個 change 誰先做」時就明確指出過這個碰撞並提醒後做者必須調整，但我寫進自己 tasks 的仍是寫死常數——知道風險與把防範寫進 artifact 是兩回事。sibling 的 task 5.1 用推導式寫法並逐字點名本 change 提出警告，對照之下更清楚：正確的修法不是把 `2.3.2` 改成 `2.4.1`，而是把常數改成推導規則，否則下一個並行 change 會再踩一次。

V-3 則是本 change 第五次「敘述未經自己量測」（W5、V1、F1、A-2 之後）。這次的形態最細微——我實測了「插入這行會使定位失敗」，但沒有再看一眼它落入的是哪一條判定，就直接寫了「計數不相等」。

## Fix Actions

1 個 blocking 成員與 2 個非阻斷項全部修復。無 grader-protection 保留項，無 accepted-risks 條目。修改檔案共 2 個：`design.md`、`tasks.md`。

**修 V-1（改為推導規則，而非改寫常數）** — IC7 改為「`cash-skills.version` MUST 寫為嚴格大於當下工作樹值與 `git show HEAD:cash-skills.version` 兩者的下一個版本，MUST NOT 寫死常數」，並記錄理由與 sibling 的具體衝突值。tasks 2.5 同步改為推導式，示例值標明為撰寫當時的快照並明訂執行時 MUST 重新讀取。刻意不把常數從 `2.3.2` 改成 `2.4.1`：那只治本次碰撞，下一個並行 change 會再踩一次。

**修 V-2** — 2.4 的「兩處都要改」改為「三處都要改」，句尾的「這兩處 drift」改為「這三處 drift」。

**修 V-3** — D3 改為「落入既有的 fail-closed 判定而失敗」，並說明落入哪一條取決於該行形狀（散文舉例通常是非獨立行，獨立成行且無對側才是計數不相等），兩者後果相同但診斷字樣不同、故文件不應指名內部判定。tasks 2.4 其三的文件措辭同步改為不指名判定。

**修正後的機械自檢** — 重跑全部檢查，未捕捉到本輪 fix 引入的新缺陷。`2.3.2` 在 design 與 tasks 各殘留一處，經逐一核對皆為新寫的說明文字在解釋該陷阱本身、非指令，屬刻意保留；「兩處」與「失衡而在首次」殘留為 0；delta 註解計數 2 比 2 平衡；tasks 粗體項皆為 scenario 或 requirement 名。重跑 `cash validate` 通過。

**Signal-derived checks** — 全部 open signal 皆無 `check` frontmatter 欄位，採 best-effort。本輪最相關者：`design-claim-unverified-against-code`（V-3——第五次未量測就寫下機制歸屬）、`review-fix-propagation-incomplete`（V-2 的數量詞漏改，與 A-1 同型且同一輪引入）、`acceptance-criterion-not-mechanically-verifiable`（V-1——寫死的版本常數在 workspace 有並行 change 時是一個會過期的驗收前提）。

## Decision

next_round

post-filter cumulative blocking set 含 0 個 Critical 與 1 個 Warning（V-2），未滿足 pass 條件。A-1 已以 verified resolution 離開集合。1 個 blocking 成員與 2 個非阻斷項皆已完成 fix 並記錄於 `## Fix Actions`。下一輪為本次執行的第三輪，非第四輪，故為 `micro` 輪，由單一 Reviewer V 對 V-2 給出 resolved/unresolved 判定，並確認 V-1 的推導式修法在 sibling change 落地前後皆可執行。本次執行的 6 輪上限尚餘三輪。
