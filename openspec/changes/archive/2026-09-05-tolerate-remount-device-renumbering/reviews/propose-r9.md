# Cash Propose Review — Round 9

本輪是 seeded re-run 的第 3 輪，依位置推導為 `micro`，全域編號為第 9 輪。由單一 Reviewer V 執行。

本輪存在的原因不是 cumulative blocking set 有成員（第 8 輪 pass 後該集合已為空），而是第 8 輪之後累積了兩批未經 reviewer 驗證的 artifact 改動需要正式關閉：批次 A 是第 8 輪 pass 之後套用的五筆非 blocking 修正，批次 B 是回應外部 review 而修正的「remount happy path 未覆蓋 direct 與 vendor 兩條路徑、且第二條 THEN 完全無覆蓋」。

## Reviewer Findings

### 批次 A 與批次 B 的驗證結果

六筆**全部正確落地**，且三項事實宣稱經 Reviewer V 實測或逐行追蹤確認屬實：

- canonical fragment 實測為 112 字元（第 8 輪對第 7 輪 reviewer 所報 111 的更正正確），兩個目標檔案現行最長行皆為 106；`assert_contains` 確為 `rg -Fq` 逐行比對，因此單行約束有事實依據。
- 「先以現行 source 安裝再覆寫 launcher bytes 會先以 content drift raise」屬實：`validate_installed_receipt` 在 `acquire_lock` 之前，而 `launcher_update` 在鎖之內，因此走不到 transition 判定。Reviewer V 另確認 lagging fixture 可建構——全史 launcher 只有兩個真實 byte 狀態，且舊 digest 末個 commit 的 runtime 檔案集合與 HEAD 完全相同，故舊 source 簽出的 receipt 能被新 `parse_receipt` 以 `strict=True` 解析。
- 批次 B 的三項確實分別對應兩條 THEN，且 `--vendor` real run 在該 fixture 上的走向經逐行追蹤確認：無 manifest、有 receipt → `elif receipt is not None` 分支 → 移除 device 後通過驗證 → 等版本 integrity 檢查通過 → 取鎖 → `launcher_update` 回 `None` → transaction 加入 manifest 發佈與 receipt 刪除 → 回傳 `update`。遷移確實完成且既有 `assert_vendored` helper 已能斷言。三項在實作前皆為 red。

### 逐條 THEN／AND 覆蓋掃描（本輪重點）

Reviewer V 對 13 個 scenario 的全部 34 條 THEN／AND 逐條檢視（非抽樣），指出每一條由對照表哪一句斷言覆蓋：29 條有明確對應斷言，3 條由同列其他斷言邏輯蘊含，**2 處無任何對應斷言**，**1 處斷言強度低於 THEN 文字**。

### Warning

- `confidence`: 74 / `layer`: design / `disposition`: `fix-introduced` / `introduced_by`: 第 2 輪 Fix Action 7（把該 scenario 的 THEN 改為「在為本次安裝取得 exclusive lock 之前」，但對照表該列只同步了 GIVEN 的 journal 限定） / `location`: `design.md` IC-15 第 13 列；spec delta `#### Scenario: 未修復的 target 不因 identity drift 被自動改寫` / `summary`: 該 scenario 的 THEN 內含兩項獨立義務（失敗分類為 identity drift、失敗發生在取鎖之前），而對照表該列只斷言 AND 的「receipt bytes 逐 byte 不變」，THEN 的兩項義務零覆蓋。一份什麼都沒寫的 target 也能通過該斷言，因此該列無法區分「在取鎖前以 identity drift 擋下」與「在取鎖後某處失敗但恰好未寫入」。取鎖時點可機械驗證——`wait_for_test_hold` 在 `acquire_lock` 之後才執行
- `confidence`: 66 / `layer`: design / `disposition`: `new` / `location`: `design.md` IC-15 第 3、4 列；spec delta 兩個對應 scenario / `summary`: 兩個 scenario 的 THEN 都是複合句「gate 以 X drift 失敗並指名該 path」，而「MUST 指名該 record 的 project-relative path」在 spec 正文也是規範層的獨立 MUST；對照表這兩列只斷言分類字串與 `--init-receipt` 的有無，完全沒有斷言 path 被指名。對照之下第 8、9、10 列都明確要求斷言 path，因此 `stable record content drift:`（不接 path）這種實作可通過全表

### Suggestion

- `confidence`: 58 / `disposition`: `fix-introduced` / `introduced_by`: 第 7 輪 Fix Action 1 與第 8 輪 Fix Action 2 的累積（兩次為第二、三支加入 ` in <resolved target path>` 而未同步首句列舉） / `location`: `design.md` IC-8 首句 / `summary`: 首句以 `MUST 為` 把第二、三支釘死為不含 target 的版本，同段後文又以 `MUST 為`／`形式為` 把同兩支釘死為含 target 的版本，同一 IC 內對同一字串出現兩條互斥的 `MUST 為`，形態與第 7 輪判為 blocking 的第三支訊息互相抵消同類。可辯護的讀法是首句只是縮寫佔位，故 confidence 不高
- `confidence`: 56 / `disposition`: `new` / `location`: `design.md` IC-15 第 4 列 / `summary`: scenario 的 AND 寫的是「診斷包含執行 `--init-receipt` 的**完整指令**」，但該列只斷言含 `--init-receipt` 子字串，而 IC-6／IC-8 釘死的完整指令在整張對照表沒有任何一列逐字斷言，因此一個只吐出 `see --init-receipt` 的實作能通過全表

### 最終整體檢查

Reviewer V 逐項確認八個面向：四份 artifact 的數量／編號／識別字／概念一致；三個 MODIFIED requirement 標題逐 byte 相同且 body 只有宣告的必要修改（逐行 diff 列出七處）；13 個 scenario 與對照表逐字 1:1 且同順序；**每列 red／guard 標記逐列（非抽樣）與現行程式碼核對全部正確**；`design.md` 面向程式碼的十餘條宣稱全部相符、未發現事實錯誤；每個 task 的驗收可機械驗證且在完成時點可達（另確認 task 2.1／2.2 的驗收不受 manifest 中斷窗口影響，因為測試以 `install-cash-skills.fish` 從 source 執行而 `source_inventory()` 不讀 manifest）；`## Impact` 的 10 個檔案一一對應無多無缺。

## Rating

- post-filter cumulative blocking set Critical count：0
- post-filter cumulative blocking set Warning count：0
- 非 blocking triaged finding count：4
- `critical_gap`: false
- `round_type`: micro

rationale：cumulative blocking set 自第 8 輪起為空，本輪四筆 findings 的 confidence 落在 56–74，全部經 confidence filter 降為 Suggestion 因而皆非 blocking，依規則不造成 `next_round`。批次 A 與批次 B 的六筆改動全部驗證通過，未經驗證的 artifact 改動債至此清償。pass 條件成立，決定 `passed`。

## Fix Actions

本輪 pass 條件已成立，因此以下修正不是 blocking 義務。但本輪的逐條掃描正是為了找出這類缺口而設，找到後不修等於白掃；且四筆都是對照表的斷言粒度問題，會直接影響 task 1.1 的測試撰寫。修改檔案：`design.md`（1 個，位於 change 目錄內）。

1. 第 13 列的 THEN 零覆蓋（74）：該列類型改為「receipt bytes 為 guard、其餘兩條為 red」，並補兩條斷言——訊息含 identity drift 分類字串；設定 `CASH_INSTALL_HOLD_FILE` 後 `<hold>.ready` 未被建立。主 agent 另行查證確認該機制成立：`wait_for_test_hold` 在 `acquire_lock` 之後執行並以 `O_CREAT|O_EXCL` 建立 `<hold>.ready`，因此該檔不存在即證明失敗早於取鎖，且此斷言不會阻塞。該列同時寫出「只斷言 receipt bytes 不變不足以覆蓋 THEN」的理由。
2. 第 3、4 列缺 path 斷言（66）：兩列各補「含該 stable record 的 project-relative path」斷言（launcher 與 installer 兩側皆需），並註明該義務在 spec 正文也是獨立的 MUST。
3. 第 4 列的指令斷言強度不足（56）：改為斷言**逐字完整**的指令——launcher 側斷言 IC-6 釘死的字串、installer 側斷言 IC-8 釘死的字串——並寫出理由（只斷言子字串時，一個只吐出 `see --init-receipt` 的實作會通過）。
4. IC-8 首句與後文的兩條互斥 `MUST 為`（58）：首句改寫為「三支訊息的**分類前綴** MUST 分別為 …；三支的完整形式由本條後文各自釘死，本句只列舉分類前綴，MUST NOT 被讀為完整字串的釘死」。

post-fix mechanical self-check：13 個 scenario 與對照表仍逐字 1:1 且同順序；三個 MODIFIED requirement 的 title 逐 byte 存在於 master spec；IC-1 至 IC-15 全部有定義且被引用、無跳號無孤立引用；spec delta 的 `<!--`／`-->`／`@trace` 計數皆為 0。`cash analyze` 為 Coverage 4／Consistency 0／Ambiguity 69／Gaps 0。無 signal 具有 `check` frontmatter 欄位，故 signal-derived check 無可執行項。

fix 後已重新執行 `validate`，結果為 Validation passed。本輪修改的檔案位於 `openspec/changes/` 之下，依 touched 記錄規則濾除後為空，因此未呼叫 Cash CLI 的 touched 指令，亦無警告。

## Decision

passed
