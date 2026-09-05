# Cash Propose Review — Round 2

## Reviewer Findings

本輪為 micro round，由單一 Reviewer V 執行 delta verification。

### Cumulative blocking set 逐筆判定

Reviewer V 對第 1 輪的六個成員各給出明確判定，全部為 `resolved`，且每筆都附上修正後 artifact 文字與真實程式碼的雙向證據：

- M1（launcher 缺範圍閘門，Critical）：`resolved`。IC-2 與 ADDED requirement 第 2 段皆已寫入判準，scenario 與 IC-14、task 1.1 同步；並對照 `.cash-skills/bin/cash` 只有 `int(row[4])`、`installer.py` 已有 `device < 0 or inode <= 0` 確認缺口與修法皆屬實。
- M2（transition 鏈斷點，Critical）：`resolved`。proposal 第五節、D5、IC-10、task 3.1 與 5.2 皆已同步；並對真實碼確認 `launcher_update` 是 `any(...)` 成員檢查、`check_launcher_history` 只對 history 推導出的那一筆做成員檢查、重複檢查以完整三元組為單位，因此第二筆 skip transition 合法。
- M3（installer 診斷無測試，Warning）：`resolved`。IC-14 對照表含 installer 驗證面，task 1.1 與 2.2 驗收同步。
- M4（scenario 無 task 支撐，Warning）：`resolved`。以 diff 驗證 spec delta 的 scenario 標題與 IC-14 對照表第一欄逐字且同順序完全相同，非僅數量相同。
- M5（引用不存在的測試，Warning）：`resolved`。四個被引用的測試函式全部 grep 命中；另確認 `test_managed_mode_drift_is_conflict_without_force` 操作的是 skill 檔案而非 stable path，不與新分類衝突。
- M6（mode 漂移分類，Warning）：`resolved`。分類軸已改為只用 digest；並對真實碼確認 launcher 的 `open_regular` 在 module level 先於 `validate_receipt` 執行精確 mode 檢查，因此新 scenario 選 installer 作為驗證面正確。

六個成員皆以 verified resolution 離開 cumulative blocking set，移除依據為本輪 Reviewer V 的逐筆判定與其引用的證據。

### Critical

- `severity`: Critical / `confidence`: 82 / `layer`: design / `disposition`: `fix-introduced` / `introduced_by`: 第 1 輪 Fix Action 7（新增 IC-4 與「其餘 records 同時漂移」scenario） / `location`: `design.md` IC-4 與 D3；`tasks.md` 2.1；spec delta ADDED requirement 的指引前提段 / `summary`: 前提被寫成「runtime generation 與每一筆 runtime／skill record 都相符」，但 launcher 的 `validate_receipt` 從不對 24 個 skill 檔做 digest 比對——`SKILL_PATHS` 只用於 receipt 內的順序檢查——因此該 MUST 在 launcher 端不是延後而是無法觀測：照字面實作會在每次啟動新增 24 次檔案雜湊（未被任何 IC、task 或 Risks 分析的行為與成本改變），不實作則 launcher 違反自己的 requirement / `recommendation`: 前提依 gate 分寫，launcher 面限縮為 runtime generation 與 runtime records，skill records 只加在 installer 面

### Warning

- `severity`: Warning / `confidence`: 85 / `layer`: design / `disposition`: `fix-introduced` / `introduced_by`: 第 1 輪 Fix Actions 3、4、6（IC-14 對照表與 task 1.1 擴充） / `location`: `tasks.md` 1.1 驗收句 / `summary`: 驗收要求「全部案例在未修改的狀態下失敗」，但擴充後的案例中至少四個在現況已是綠燈（mode 漂移的 installer 訊息現行就含 identity drift 字樣、negative device 的 installer 半已有範圍檢核、identity drift 後 receipt bytes 本來就不變、source layout 提示現行就會併入訊息），把它們算進紅燈驗收會產生假的 red evidence / `recommendation`: 明確區分 red 案例與 regression guard，紅燈驗收只涵蓋目標行為尚不存在的案例

### Suggestion（經 confidence filter 由 Warning 降級，或原即為 Suggestion）

- `confidence`: 78 / `disposition`: `fix-introduced` / `introduced_by`: 第 1 輪 Fix Action 11 / `location`: spec delta ADDED requirement 第 3 段的判定順序句 / `summary`: 「缺record與缺檔優先於形狀」與 launcher 實際執行序相反——`open_regular` 在 module level 先於 receipt 解析執行，形狀與 mode 是最先判定的一項，等於寫下一條落地即違反的 MUST
- `confidence`: 74 / `disposition`: `fix-introduced` / `introduced_by`: 第 1 輪 Fix Action 7 / `location`: `design.md` IC-5／IC-7；IC-14 對照表 / `summary`: IC-5 與 IC-7 以窮舉語氣定義兩支訊息，但 IC-4 又要求第三種情形改為回報其餘 record 的漂移，該第三支訊息形態不在任何 IC 的契約內，對照表也只斷言「不含 `--init-receipt`」而不驗證回報內容
- `confidence`: 70 / `disposition`: `new` / `location`: spec delta MODIFIED `Target 版控排除保護` 新增句 vs ADDED requirement 的 identity drift 指引 / `summary`: 「receipt 被納入版控後在別台機器 clone」正好落在 digest 相符、只有 inode 不符的 identity drift，於是新增的指引會在 `receipt_invalid` 當場教使用者重綁 inode，使該保護從 fail closed 變成 fail closed 附一鍵繞法
- `confidence`: 64 / `disposition`: `fix-introduced` / `introduced_by`: 第 1 輪 Fix Action 11（與 Fix Action 1 交互） / `location`: spec delta ADDED requirement 第 3 段的出口列舉 / `summary`: 列舉未包含本 change 自己新增的 device／inode 欄位形狀出口，而該段以固定判定順序呈現，讀起來是窮舉
- `confidence`: 62 / `disposition`: `fix-introduced` / `introduced_by`: 第 1 輪 Fix Action 14 / `location`: spec delta `#### Scenario: 未修復的 target 不因 identity drift 被自動改寫` / `summary`: 改寫後的 THEN 在一般路徑成立，但 target 存在未完成 journal 時 installer 會先取得 exclusive lock 並執行 recovery，使該 THEN 與 AND 皆不成立
- `confidence`: 60 / `disposition`: `fix-introduced` / `introduced_by`: 第 1 輪 Fix Action 3 / `location`: `design.md` IC-14 第 9 列；`tasks.md` 1.1 / `summary`: `make_self_source` 會同時移除 receipt 與 manifest，而 source repository 無法以 `--init-receipt` 或 direct install 產生 receipt，因此該案例的建構工作量與敘述不符
- `confidence`: 58 / `disposition`: `fix-introduced` / `introduced_by`: 第 1 輪 Fix Action 1 / `location`: `design.md` D1 的形狀閘門段 vs IC-2 / `summary`: D1 指出 `int()` 也接受底線與空白並說今天擋住它們的唯一機制就是即將移除的比對，但 IC-2 只補範圍判準，該半沒有任何條款處理

## Rating

- post-filter cumulative blocking set Critical count：1
- post-filter cumulative blocking set Warning count：1
- 非 blocking triaged finding count：7
- `critical_gap`: true
- `round_type`: micro

rationale：第 1 輪的六個 blocking 成員全部由 Reviewer V 以逐筆證據判定 `resolved` 並離開 cumulative blocking set。本輪新增兩筆 blocking findings，兩筆的 `disposition` 都是 `fix-introduced`——這正是 micro round 要抓的東西：第 1 輪一次改了 4 個檔案、17 處，其中「把指引前提寫成涵蓋 skill records」超出了 launcher 實際會執行的驗證範圍，而「把案例數從四擴充到十一」讓紅燈驗收涵蓋了本來就是綠燈的案例。兩筆皆有可驗證的程式碼證據且 confidence ≥ 80，因此 `critical_gap` 為 true，決定 `next_round`。

## Fix Actions

修改檔案：`openspec/changes/tolerate-remount-device-renumbering/proposal.md`、`design.md`、`specs/cash-cli/spec.md`、`tasks.md`（共 4 個檔案，全部位於 change 目錄內）。

blocking findings 的處置：

1. **指引前提超出 launcher 實際驗證範圍**（Critical／82）：spec delta 的前提段改寫為「該 gate 本來就會驗證的其餘 records」，並明文分寫兩個 gate 的範圍——launcher 面為 runtime generation 與 runtime records 且 MUST NOT 納入 skill records 的逐檔 digest（附上「會使每次啟動新增 24 次檔案雜湊」的理由），installer 面涵蓋 runtime 與 skill records；design D3 新增「前提的範圍必須依 gate 分寫」段；IC-4 同步改寫；task 2.1 加上「MUST NOT 為此新增 skill 檔案的 digest 比對」，task 2.2 標明 installer 面涵蓋 skill records；proposal 第三節同步。
2. **紅燈驗收涵蓋本來就綠燈的案例**（Warning／85）：IC-14 對照表新增「類型」欄，逐列標記 red 或 guard，並在表頭前說明「把 guard 算進紅燈驗收會產生假的 red evidence」；mode 漂移那一列的驗證方式補強為同時斷言含 `--init-receipt`（現行實作雖已輸出 identity drift 字樣但不含指令），negative device 一列標為 launcher red、installer guard；task 1.1 驗收改為「red 案例全部失敗、guard 案例在同一狀態下通過並在實作後仍通過」；task 5.3 加上「沒有任何 guard 案例被當成 red evidence」。

非 blocking triaged findings 的處置。以下 7 筆均不 blocking，但修法明確且成本低，已一併修正：

3. 判定順序與 launcher 執行序相反（78）：刪除該順序 MUST，改為「本段 MUST NOT 被讀為窮舉，也 MUST NOT 規定這些出口彼此之間的判定順序」，並說明兩個 gate 的既有執行序不同、launcher 端形狀判定必然早於缺 record。
4. 第三支訊息形態未定義（74）：IC-5 補上確切形態 `stable record identity drift: {relative}; {other_kind} record drift: {other_path}`，IC-7 要求 installer 採相同形態；spec delta 新增「診斷 MUST 仍指名 stable path 並 MUST 同時指名該筆漂移的 runtime 或 skill path」；對應 scenario 補一條 AND；IC-14 該列的驗證方式同步。
5. 版控中的 receipt 與 identity 指引的互動（70／`new`）：spec delta 新增一段規定 installer 在其唯讀 version-control index 查詢判定 receipt 已被追蹤時，identity 診斷 MUST 與既有 tracked-receipt diagnostic 一併輸出並指示先解除追蹤；新增 `#### Scenario: 版控中的 receipt 出現 identity drift 時不提供無限定的重新簽發指令`；design D3 新增「receipt 已被版控時的限定」段、IC-7 同步、Risks 新增專條說明 launcher 面不做 version-control 查詢是刻意取捨；proposal 第三節同步。
6. 出口列舉未含形狀閘門（64）：列舉補上「stable record 的 device／inode 欄位形狀不合法」。
7. journal recovery 使 no-auto-rewrite scenario 前提不成立（62）：GIVEN 補一條 `AND target 沒有未完成的installer journal`，THEN 改為「在為本次安裝取得 exclusive lock 之前」。
8. `make_self_source` fixture 敘述與工作量不符（60）：IC-14 該列與 task 1.1 明寫該案例需要本 task 新增一個 receipt 合成 helper，並說明 `make_self_source` 會同時移除 receipt 與 manifest。
9. D1 的字面形式論述超出 IC-2 的處置範圍（58）：D1 改為只論範圍問題，並新增 Risks 一條說明兩個 gate 都只以 `int()` 解析、不另立更嚴的字面判準以免判準再度分歧，其影響限於 provenance 欄位可能非 canonical。

fix 傳播：scenario 數由 11 變 12，已同步 IC-14 對照表（12 列）與 tasks 1.1／5.3 的「十二」敘述，並以逐字比對確認 12 個 scenario 標題與對照表第一欄 1:1 且同順序相同。「前提」這個概念已在 proposal 第三節、design D3／IC-4／IC-5／IC-7、spec delta 前提段與兩個相關 scenario、tasks 2.1／2.2 全部同步為分 gate 版本。

post-fix mechanical self-check：spec delta 的 `<!--`／`-->` 計數皆為 0 且無殘留 `@trace` 或 `---`；scenario 數 12 與對照表列數 12 一致且逐字 1:1；全域已無「十一」或「八個」殘留；三個 MODIFIED requirement 的 title 逐 byte 存在於 master spec；IC-1 至 IC-14 全部有定義且被引用、無跳號、無孤立引用。無 signal 具有 `check` frontmatter 欄位，故 signal-derived check 無可執行項。

fix 後已重新執行 `validate`，結果為 Validation passed。本輪 Fix Actions 修改的檔案全部位於 `openspec/changes/` 之下，依 touched 記錄規則濾除後為空，因此未呼叫 Cash CLI 的 touched 指令，亦無警告。

## Decision

next_round

本輪的兩筆 blocking findings 皆已修正，但依 cumulative blocking set 的規則，它們必須由下一輪 reviewer 給出明確的 resolved 判定才能離開集合。下一輪為本 run 的第 3 輪，依位置推導為 `micro`。
