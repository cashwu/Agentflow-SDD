# Cash Propose Review — Round 9

本輪為 micro 輪，是 re-run 的第三輪。由單一 Reviewer V — Verification 對 round 8 的 cumulative blocking set 做 delta 驗證，確認 V-1 的推導式修法在 sibling change 落地前後皆可執行，並執行最終收斂檢查。

## Reviewer Findings

### Cumulative blocking set 判定

| member | verdict | 依據摘要 |
| --- | --- | --- |
| V-2 | resolved | tasks 2.4 開頭已為「三處都要改」、句尾已為「這三處 drift」，與中段的「其一／其二／其三」一致。全 change grep `兩處` 殘留為 0——design 唯一的「兩處」是「五種 fail-closed 判定分屬兩處」，指 `marker_span` 與 `render_guidance` 兩個函式，語意正確而非數量詞漏改。跨 artifact 一致：proposal 寫「需改寫三處」、design D7 寫「要求改寫三處而非一處」 |

### V-1 推導式修法的三狀態驗證

Reviewer V 在隔離 git repo 內實跑 `check_history`，確認推導規則在三種狀態下皆給出正確且可執行的結果：sibling 未提交（HEAD `2.3.1`、工作樹 `2.4.0`）推出 `2.4.1` PASS；sibling 已提交（兩者皆 `2.4.0`）推出 `2.4.1` PASS；sibling 放棄回退（兩者皆 `2.3.1`）推出 `2.3.2` PASS。工作樹值反而低於 HEAD 的退化情形亦收斂。「嚴格大於 HEAD」正是 `check_history` 強制的條件，「嚴格大於當下工作樹值」是額外約束，作用是避免靜默回退 sibling 未提交的調升。

### 最終收斂檢查

Reviewer V 逐項確認全部通過：計數三處一致且與 tasks 實際情境數相符（成功 6、失敗 8）；9 個 scenario、3 個 Example、IC1–IC8、16 個 task 三向對應無孤兒無重複；delta 標題與首段與 master 逐 byte 相同、三個保留 scenario 逐字未改；tasks 粗體項全為 scenario 或 requirement 名；delta 註解計數平衡；`cash validate --all` 與 `test_live_namespace.py` 通過。

**code-facing claim 抽驗**：Reviewer V 以現行 `marker_span` 對照依 D1／IC1 規格實作的 pattern prototype 逐項獨立重跑，**round 7 與 round 8 新寫入的敘述除 IC7 外全部成立**——D1 的三個 span 值、D2 的 Tubify offset 與 16 檔不一致數 0、D3 經 round 8 V-3 修正後的判定歸屬（散文行走非獨立行、獨立成行無對側才是計數不相等）、D4 的兩個空行、D7 的 14 條字面與五個 `fail closed` 出現行、Risks 第一段經 round 7 A-2 修正後的 digest 敘述、Risks 三案例與 round 7 B-4 新增的第四種形狀、delta 的 `<`／`>` 分流、tasks 1.4 case 二與 1.5 五個 fixture 與 1.8 的 red-first 分類。

**可實作性**：以實作者視角逐讀 16 個 task，全部可在不回頭提問下完成。另補充三項與 sibling 的交互確認：`installer.py` 相對 HEAD 未被 sibling 修改，故 3.3 的對照組手法有效；sibling 對 `skill-checks.fish` 的修改只動 `assert_command_matrix`，未觸及 `assert_guidance_and_docs`，故 2.4 的 14 條字面仍在；其餘 5 個 target 現為 `would-update`，唯二 `failed` 皆為 marker 理由，故 3.2 的 `failed=0` 可達成。

### Warning

**R9-1**（confidence 100，layer design，`disposition`：`fix-introduced`，`introduced_by`：round 8 `## Fix Actions` 的「修 V-1（改為推導規則，而非改寫常數）」）

- `location`：`design.md` IC7 的理由段
- `summary`：IC7 宣稱 `check_history` 會把寫入值與工作樹的 `2.4.0` 比較而拋 `bundle version must strictly increase`，但 `check_history` 比對的是工作樹值與 `git show HEAD:cash-skills.version`。在 IC7 自己指名的現況（HEAD `2.3.1`、工作樹 `2.4.0`）下，寫死 `2.3.2` **PASS 而不拋例外**，並靜默把 sibling 的 `2.4.0` 覆寫掉；會拋的是 sibling 已提交（HEAD `2.4.0`）的狀態。同段的「反之若 sibling 尚未落地就寫 `2.3.2`，則會靜默回退」與前半句描述的其實是同一個狀態，兩個分支不可區分且內部矛盾。
- 主 agent 獨立核對 `check_history` 原始碼確認：它只讀 `current`（工作樹）與 `head`（`git show HEAD:`）兩個值，不知道工作樹被覆寫前是什麼。`2.3.2 > 2.3.1` 為真，故現況下放行。
- 副作用是 IC7 把一個在現況下**靜默**的破壞描述成會被 contract test 攔下，低估了風險——而這正是該 IC 存在的理由。`tasks.md` 2.5 的措辭「因 `2.3.2` 不大於 HEAD 而拋」正確，兩處因此不一致。

## Rating

- post-filter cumulative blocking set Critical count：**0**
- post-filter cumulative blocking set Warning count：**1**（R9-1）
- 非阻斷 triaged finding count：**0**
- `critical_gap`：**false**
- `round_type`：**micro**

rationale：V-2 已 verified resolved 離開集合。round 8 對 V-1 的推導式修法本身經三狀態實測確認正確，最終收斂檢查全面通過，code-facing claim 抽驗涵蓋 round 7 與 round 8 全部新寫入的敘述且僅 IC7 一處為假。

R9-1 是本 change 第六次「敘述未經自己量測」，但它的形態值得單獨記錄：前五次都是把某個未驗證的斷言寫進論證，這一次是我**驗證了結論卻沒驗證機制**——我確實量了「`2.3.2` 不大於 `2.4.0`」，也確實知道 sibling 把工作樹升到了 `2.4.0`，於是直接推論 `check_history` 會攔下來；但我沒有去讀 `check_history` 到底比對哪兩個值。實際上它只比 HEAD，所以現況下這個錯誤是無聲的。把「無聲的回退」誤述為「響亮的失敗」，恰好抹掉了該 IC 存在的主要理由。

## Fix Actions

1 個 blocking 成員修復，無非阻斷項。無 grader-protection 保留項，無 accepted-risks 條目。修改檔案共 1 個：`design.md`。

**修 R9-1** — 只改 IC7 的理由段，normative 規則（MUST 寫為嚴格大於當下工作樹值與 HEAD 值兩者的下一個版本、MUST NOT 寫死常數）與示例值 `2.4.1` 不動，因為推導規則本身經三狀態實測皆正確。理由段改為據實的兩分支表述：sibling 已提交時寫死常數會因不大於 HEAD 而拋錯、失敗是響亮的；sibling 尚未提交時 `check_history` 只比對工作樹值與 HEAD 這兩個值、不知道工作樹被覆寫前是什麼，因此寫死 `2.3.2` 會靜默通過並覆寫掉 sibling 的調升，沒有任何檢查會攔。並明記第二種正是必須推導而非寫死的主要理由——響亮的失敗會被關卡擋住，無聲的回退不會。

**修正後的機械自檢** — 重跑全部檢查，未捕捉到本輪 fix 引入的新缺陷。IC7 與 tasks 2.5 現在對「`check_history` 只比對 HEAD」的敘述一致；delta 註解計數 2 比 2 平衡；tasks 粗體項皆為 scenario 或 requirement 名；計數三處一致（IC6 六加八、Risks 十四、proposal 六類加八類）與 16 個 task。重跑 `cash validate` 通過。

**Signal-derived checks** — 全部 open signal 皆無 `check` frontmatter 欄位，採 best-effort。本輪最相關者：`design-claim-unverified-against-code`（R9-1——第六次，且是「驗證了結論卻沒驗證機制」這個新變體）。

## Decision

next_round

post-filter cumulative blocking set 含 0 個 Critical 與 1 個 Warning（R9-1），未滿足 pass 條件。V-2 已以 verified resolution 離開集合，本輪無非阻斷 finding。1 個 blocking 成員已完成 fix 並記錄於 `## Fix Actions`。下一輪為本次執行的第四輪，依規則為 `full` 輪，由 Reviewer A — Adherence 與 Reviewer B — Quality 兩個 fresh sub-agent 平行做全面重掃，並各自對 R9-1 給出 resolved/unresolved 判定。本次執行的 6 輪上限尚餘兩輪。
