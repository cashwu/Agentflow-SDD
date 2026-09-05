# Cash Propose Review — Round 6

## Reviewer Findings

本輪為 micro round，也是本 run 的第 6 輪，即上限輪次。由單一 Reviewer V 執行最終驗證。

### Cumulative blocking set 逐筆判定

- R1（IC-15 第 9 列以 symlink 建構為假 red，Warning）：`resolved`。Reviewer V 逐行追跡 launcher 的 runtime 迴圈到 `sha256_file` 再到 `open_regular`，確認 hard link 建構會通過 mode 比對（hard link 與原檔共用 inode，mode 仍為 `0644`）、`or` 不短路、右運算元被求值、並在 `opened.st_nlink != 1` 失敗；套用 IC-4 的 `error_code="receipt_invalid"` 後該出口改以 `receipt_invalid` 結束，訊息為 `{path}: unsafe identity or mode`，不含 `--init-receipt`。另以本機實測佐證 symlink 的 `lstat` mode 為 `0755`／`st_nlink` 1、hard link 為 `0644`／`st_nlink` 2。R1 所述的「建構落不到目標出口」已消除，spec delta 對應 scenario 的 GIVEN 亦已同步。

R1 以 verified resolution 離開 cumulative blocking set。至此本 run 累計進入過集合的十一個成員全部經逐筆判定 resolved。

### Warning

- `severity`: Warning / `confidence`: 82 / `layer`: design / `disposition`: `fix-introduced` / `introduced_by`: 第 4 輪 Fix Action 10（建立該列與其斷言集合）與第 5 輪 Fix Action 1（改建構但未補上可鑑別的斷言） / `location`: `design.md` IC-15 第 9 列；`tasks.md` 1.1 驗收；spec delta `#### Scenario: 延後判定期間命中既有出口時以該出口回報` / `summary`: 該列標為 red，但其列出的兩條斷言（「以 `receipt_invalid` 而非 `bootstrap_invalid` 結束」「訊息不含 `--init-receipt`」）在現行程式碼下都成立，因此仍不構成 red——原因與 R1 不同：該列同時要求「receipt inode 改值」，而 launcher 的 stable record 迴圈在 runtime 迴圈之前執行，今日即以 `stable record drift` 結束，hard link 所在的 runtime 檔根本不會被開啟。R1 的修法只矯正了「實作後會落在哪個出口」，未改變「實作前不會失敗」 / `recommendation`: 補上可鑑別的斷言「訊息指名該 runtime path」，與該 scenario 第一條 THEN 對齊

### Suggestion（經 confidence filter 由 Warning 降級，或原即為 Suggestion）

- `confidence`: 62 / `disposition`: `fix-introduced` / `introduced_by`: 第 1 輪 Fix Action 9 / `location`: `tasks.md` 4.4 驗收 / `summary`: 「刻意刪掉三條新 literal 中任一條時該套件以非零結束」無鑑別力——同檔對受管區塊有 baseline SHA-256 斷言，刪掉區塊內任一 literal 必然使 digest 不符而失敗，與三條 `assert_contains` 是否存在無關，因此無法證明 IC-13 真正要防的事
- `confidence`: 58 / `disposition`: `fix-introduced` / `introduced_by`: 第 5 輪 Fix Action 6 / `location`: `design.md` IC-14；`tasks.md` 4.2、4.3 / `summary`: IC-14 補三項後仍未涵蓋 tasks 的全部要求——task 4.3 的「identity drift 是初始化入口」「content drift 不適用」對 `CASH-INIT-RECEIPT.md` 沒有對應條款，task 4.2 的「identity 比對條件為三項」亦無 IC-14 明文
- `confidence`: 45 / `layer`: text / `disposition`: `new` / `location`: `tasks.md` 4.1 驗收末句 / `summary`: 「區塊內不出現無條件背書取得方式的措辭」是語意判斷，無法機械驗證，與同一 task 前兩項的可驗證性不一致。此筆 confidence 低於 50，依 confidence filter 應被丟棄，僅記錄於此以保留 downgrade trace

### 最終整體檢查的通過項

Reviewer V 逐項確認以下皆成立：四份 artifact 之間無數量、編號、識別字或概念的不一致，IC-1 至 IC-15 全部有定義且被引用、無跳號無孤立；三個 MODIFIED requirement 的標題逐 byte 相同，body 相對 master spec 只有本 change 宣告的必要修改（逐行 diff 列出七處，其餘差異僅為 `@trace` 區塊移除）；13 個 scenario 與 IC-15 對照表逐字 1:1 且同順序，逐列（非抽樣）驗證建構可行性與 red／guard 標記，除第 9 列外全部正確；`design.md` 所有面向程式碼的宣稱全數與真實 call sites 相符，並確認 `592345fff…` 的 launcher bytes 可由 first-parent history 取得因而 task 5.2 的 fixture 可建構；除第 9 列與 4.4、4.1 兩處驗收外，每個 task 的驗收皆可機械驗證且在該 task 完成時點可達；proposal `## Impact` 的 10 個檔案與 IC／tasks 一一對應，無 over-declare 或 under-declare，並確認現有測試無任何一處斷言本變更會改動的訊息字串。

## Rating

- post-filter cumulative blocking set Critical count：0
- post-filter cumulative blocking set Warning count：1
- 非 blocking triaged finding count：3
- `critical_gap`: false
- `round_type`: micro

rationale：R1 已 resolved 並離開集合，最終整體檢查的六個面向除三處外全部通過。但本輪新增一筆 blocking Warning：IC-15 第 9 列在換成 hard link 建構之後仍不構成 red，原因與 R1 所述不同——該列同時要求 receipt inode 改值，而 stable record 迴圈在 runtime 迴圈之前執行，今日即在 stable 迴圈結束。該筆 confidence 82、disposition `fix-introduced`，因此仍為 blocking，post-filter cumulative blocking set 非空。本輪是第 6 輪即上限輪次，依規則記錄 `decision: aborted` 並執行 Abort triage。

## Fix Actions

修改檔案：`openspec/changes/tolerate-remount-device-renumbering/design.md`、`tasks.md`（共 2 個檔案，全部位於 change 目錄內）。

本輪雖以 `aborted` 結束，仍先套用可直接解決的修正，使後續 re-run 的第一輪能以最短路徑驗證：

1. **第 9 列仍非 red**（Warning／82，bucket 1）：IC-15 第 9 列補上可鑑別的斷言「訊息**指名該 runtime path**」，並在該列明寫這是本列唯一可鑑別的 red 判準、以及另外兩條斷言今日即成立因而不構成 red 的理由。該斷言與 spec delta 對應 scenario 的第一條 THEN「launcher 以 `receipt_invalid` 回報該 runtime record 的失敗」對齊——今日該 fixture 的訊息只指名 stable path，因此斷言必定失敗。此 finding 仍列為 bucket 1，因為修正需由 re-run 的第一輪 reviewer 給出 resolved 判定才能離開 cumulative blocking set。
2. **task 4.4 驗收無鑑別力**（62）：驗收改為「刪掉三條新 literal 中任一條**並同步重算 baseline digest** 後該套件仍以非零結束」，並寫出理由（不重算 digest 的話 baseline 斷言必然先失敗，無法證明 `assert_contains` 真的生效）。
3. **IC-14 未涵蓋 tasks 全部要求**（58）：IC-14 補上「兩份文件 MUST 皆說明 identity 比對條件為 digest、mode 與 `st_ino` 三項」，並對 `CASH-INIT-RECEIPT.md` 明文要求載明 identity drift 是初始化入口、content drift 不適用；`CASH-SKILLS.md` 的全稱句限定改寫也一併併入該條。
4. **task 4.1 驗收末句無法機械驗證**（45，經 confidence filter 丟棄，記錄為 downgrade trace）：仍一併改為可機械檢查的「區塊內不出現 `fresh clone` 字樣」。

post-fix mechanical self-check：13 個 scenario 與 IC-15 對照表仍逐字 1:1 且同順序；三個 MODIFIED requirement 的 title 逐 byte 存在於 master spec；IC-1 至 IC-15 無跳號無孤立引用；spec delta 的 `<!--`／`-->`／`@trace` 計數皆為 0。無 signal 具有 `check` frontmatter 欄位，故 signal-derived check 無可執行項。

fix 後已重新執行 `validate`，結果為 Validation passed。本輪 Fix Actions 修改的檔案全部位於 `openspec/changes/` 之下，依 touched 記錄規則濾除後為空，因此未呼叫 Cash CLI 的 touched 指令，亦無警告。

### Abort triage

- **bucket 1（仍屬本 change 的義務，種子給 re-run）**：IC-15 第 9 列的 red 標記與其斷言集合（Warning／82／`fix-introduced`）。本輪已套用修正——補上「訊息指名該 runtime path」這條可鑑別斷言——但依規則，cumulative blocking set 的成員只能經由後續 reviewer 的 verified resolution 離開，因此它仍是 re-run 的種子。
- **bucket 2（新發現但從未 blocking）**：task 4.4 驗收無鑑別力（62）、IC-14 未涵蓋 tasks 全部要求（58）、task 4.1 驗收末句無法機械驗證（45）。三筆均已修正。三筆的 confidence 皆低於 80，依 signals write step 的門檻不產生 signal。無 Critical，因此不需建議後續 change proposal。
- **bucket 3（已接受的取捨）**：無。本 run 全程未建立 `accepted-risks.md`，亦未向使用者徵求任何 accepted-risk 同意。

**re-run 的具體前提**：bucket 1 的修正已經套用，因此 re-run 不是「原封不動重跑」。re-run MUST 從第 7 輪開始編號、納入前六輪的全部 round files、以 bucket 1 的該筆 finding 種子化 cumulative blocking set，並在其第一輪（full round）由兩位 reviewer 對該成員給出明確的 resolved／unresolved 判定。判定的關鍵事實是：在未實作的程式碼下，該 fixture 的 launcher 失敗訊息是否只指名 stable path 而不含該 runtime path。

## Decision

aborted
