# Cash Propose Review — Round 8

本輪是 seeded re-run 的第 2 輪，依位置推導為 `micro`，全域編號為第 8 輪。由單一 Reviewer V 執行 delta verification。

## Reviewer Findings

### Cumulative blocking set 逐筆判定

兩個成員皆判 `resolved`，各自附上修正後文字與真實程式碼的雙向證據：

- T1（前綴誤述為既有慣例、前綴產生位置未定義、`--all` 重複前綴，Warning）：`resolved`。Reviewer V 對 `前綴｜prefix｜散文` 全文 grep，確認四份 artifact 只剩四處相關敘述且全部與程式碼相符，並逐一核對三處帶前綴的直接 `print` 呼叫點與二十餘處不帶前綴的 `InstallerError`、`main()` 的 `Error: {error}`、`--all` 迴圈的 `f"{record}: {error}"`。另確認 `install_target` 與 `install_vendored_target` 都先做 `Path(target_input).resolve()` 再以該值呼叫 `validate_installed_receipt`，因此散文取得 resolved 絕對路徑**不需改動 IC-7 禁止改動的函式簽章**；三條路徑（`--target`／`--vendor`／`--all`）皆成立且不產生歧義。IC-15 對應列的四條斷言今日全部失敗，red 標記成立。
- T2（第三支訊息兩條 MUST 互相抵消，Warning）：`resolved`。兩段式可唯一導出完整字串（釘死前段 + 明文寫出的 `. ` 分隔 + 釘死的下一步句）；下一步句在 design 全文只出現一次（IC-5 定義），IC-8 以引用指向，維持單一真值來源；spec 前提段以規範層敘述、不重複釘死 literal，分層正確；IC-15 對應列與 task 2.2 皆一致。依 IC-8 實作的 installer 訊息可通過該列的斷言。

兩個成員皆以 verified resolution 離開 cumulative blocking set，該集合至此為空。

### 第 7 輪其餘六個 fix 的落地檢查

Reviewer V 逐項核對，六個 fix 全部落地且正確，其中兩項另有補充發現：

- IC-15 對應列的 fixture 障礙：`resolve()` 成因正確可實作；刪除「含空白路徑」的理由成立，因為 IC-8 的指令確實不內插任何路徑。
- skip transition 的 Risks 條：與 Goals 末項**不矛盾**。Reviewer V 以 `git log --first-parent -- .cash-skills/bin/cash` 確認歷史上 launcher 只有兩個 byte 狀態，兩筆 transition 即窮盡既有族群，故 Goal 成立；Risks 那條談的是未來的 launcher 變更沒有規範義務，兩者時間範圍不同、可並存。
- canonical fragment：四處措辭一致，`assert_contains` 對任意路徑可用因此 parity 斷言可行——但逐行比對帶出一個未言明的實作約束（見下方第 2 筆）。
- IC-12 的 manifest 限定：design 已落地並與 spec delta 逐項對齊，但同一 finding location 所列的 tasks 4.1 漏改（見下方第 1 筆）。
- stable 端迭代順序：與兩個 gate 的實際迭代順序相符（launcher 的 stable 迴圈第一筆是 `.cash-skills/bin/cash`；installer 的 `zip` 走 receipt canonical 順序，第一筆同值）。
- task 1.1 驗收末句：已移出該 task 的完成判準。

### 最終整體檢查

Reviewer V 逐項確認六個面向全部通過：四份 artifact 之間無數量、編號、識別字或概念的不一致；三個 MODIFIED requirement 的標題逐 byte 相同且 body 只有本 change 宣告的必要修改；13 個 scenario 與 IC-15 對照表逐字 1:1 且同順序，並**逐列（非抽樣）**核對建構可行性與 red／guard 標記全部正確；`design.md` 面向程式碼的十餘條宣稱（含第 7 輪新增的 `main()`、`--all` 迴圈、`InstallerError` 前綴三條）逐條相符、未發現任何事實錯誤；task 驗收可機械驗證且在完成時點可達；`## Impact` 的 10 個檔案與 IC／tasks 一一對應、無多無缺。

### Suggestion（全部低於 confidence filter 的 blocking 門檻，皆非 blocking）

- `confidence`: 58 / `layer`: design / `disposition`: `fix-introduced` / `introduced_by`: 第 7 輪 Fix Action 5 / `location`: `design.md` IC-13、IC-6；`tasks.md` 4.4、2.1、2.2 / `summary`: parity 斷言依賴 `assert_contains` 的 `rg -Fq` 逐行比對，而 canonical fragment 長 112 字元、兩個檔案現行最長行皆為 106 字元，實作者依既有行寬習慣很可能以隱式串接拆行；拆點若落在 fragment 內部斷言就會失敗，且失敗訊息只會說 missing literal 而不指出真正成因。該實作約束在 IC-6／IC-13／tasks 2.1／2.2 都沒有記下
- `confidence`: 55 / `layer`: design / `disposition`: `fix-introduced` / `introduced_by`: 第 7 輪 Fix Action 1 與第 4 輪 Fix Action 5 的交互 / `location`: `design.md` IC-8 第三支訊息；spec delta 指引措辭段與對應 scenario / `summary`: 第 7 輪把「散文指名 target」只套用到帶指令的第二支訊息，釘死的第三支完全不含 target 標示；但第三支同樣帶有可執行指示且兩個 path 都是 project-relative，在 `--target`／`--vendor` 路徑上印為 `Error: <message>` 不帶前綴，正是 D3 要避免的「誤以為應在目前所在 repository 操作」。spec 的指引措辭段若讀為涵蓋全部 installer 面 identity 診斷，則與 IC-8 釘死的第三支形式衝突
- `confidence`: 55 / `layer`: design / `disposition`: `new` / `location`: `tasks.md` 5.2 後半段 / `summary`: 「建立一個 launcher 停在 `592345fff…` 的 fixture target」的建構路徑未言明，而最直覺的做法不可行——先以現行 source 安裝再覆寫 launcher bytes 會使 receipt 的 stable digest 與現地不符，preflight 先以 content drift raise，根本走不到 `launcher_update`；改以 `--init-receipt` 重簽則 receipt 版本變成 2.13.0，等版本路徑會以 integrity drift 擋下。唯一可行路徑是先以舊 bundle source 安裝出 lagging target
- `confidence`: 52 / `layer`: text / `disposition`: `new` / `location`: `tasks.md` 4.1 / `summary`: 第 7 輪 Fix Action 6 只把 manifest 限定補進 IC-12，未補進同一 finding location 所列的 tasks 4.1
- `confidence`: 45 / `layer`: text / `disposition`: `new` / `location`: `design.md` IC-15 對照表第 7、8 列 / `summary`: 這兩列的 spec scenario 同樣是「執行任一 Cash command 或 installer preflight」、同屬跨 gate，但驗證方式欄未標明拆分，task 5.3 核對「跨 gate 的案例對應到兩個函式」時會有解讀空間。此筆 confidence 低於 50，依 confidence filter 應被丟棄，僅記錄為 downgrade trace

## Rating

- post-filter cumulative blocking set Critical count：0
- post-filter cumulative blocking set Warning count：0
- 非 blocking triaged finding count：5
- `critical_gap`: false
- `round_type`: micro

rationale：T1 與 T2 皆由 Reviewer V 以逐項證據判定 `resolved` 並離開 cumulative blocking set，該集合至此為空。第 7 輪其餘六個 fix 全部落地正確，最終整體檢查的六個面向全部通過，且 13 列 red／guard 標記經逐列核對無誤。本輪五筆新 findings 的 confidence 落在 45–58，全部經 confidence filter 降為 Suggestion 因而皆非 blocking；依規則非 blocking findings 不造成 `next_round`。pass 條件成立，決定 `passed`。

## Fix Actions

本輪 pass 條件已成立，因此以下修正不是 blocking 義務；但其中三筆（parity 斷言的行寬約束、task 5.2 的 fixture 建構路徑、第三支訊息不指名 target）會在實作階段成為實際障礙，屬前幾輪反覆出現的「敘述與可行工作量不符」形態，因此一併修正而非只留 triage 註記。修改檔案：`design.md`、`tasks.md`（共 2 個，皆位於 change 目錄內）。

1. parity 斷言的逐行比對約束（58）：IC-13 補上說明——`assert_contains` 以 `rg -Fq` 逐行比對，因此 canonical fragment 在兩個檔案中 MUST 各自完整位於單一原始碼行，可在 `; ` 邊界拆行但不得在 fragment 內部拆；並寫出成因（fragment 長 112 字元、兩檔現行最長行皆 106 字元，已實測確認）與失敗時的誤導性（只會說 missing literal）。tasks 2.1 與 2.2 各補一句同樣的實作約束。
2. 第三支 installer 訊息未指名 target（55）：採 reviewer 建議的 (a) 案，IC-8 的第三支前段改為 `stable receipt identity drift: <record path> in <resolved target path>; {other_kind} record drift: {other_path}`，與第二支採同一形狀，因此 spec 的指引措辭段不需要為第三支寫例外；IC-15 對應列補上 installer 側的前段斷言。
3. task 5.2 的 fixture 建構路徑（55）：明寫 MUST 以「從 first-parent history 取出該 launcher digest 所屬 commit 的 bundle source，先安裝出 lagging target，再從新 source 對它執行」建構，並明寫 MUST NOT 以「先用現行 source 安裝再覆寫 launcher bytes」建構及其失敗原因（preflight 先以 stable content drift raise，走不到 transition 判定）。
4. tasks 4.1 的 manifest 限定（52）：補上「manifest 缺失的 receipt-based target」限定，與 IC-12 及 spec delta 對齊。
5. IC-15 第 7、8 列的拆分標記（45，低於 filter 門檻）：兩列的驗證方式比照第 3、4 列加上「拆成 launcher 與 installer 兩個函式」。

另修正一處主 agent 在撰寫上述第 1 項時引入的數值誤差：reviewer 報告的 fragment 長度為 111 字元，實測為 112，design 中已更正並以 `awk` 實測確認兩個檔案現行最長行皆為 106 字元。

post-fix mechanical self-check：13 個 scenario 與 IC-15 對照表仍逐字 1:1 且同順序；三個 MODIFIED requirement 的 title 逐 byte 存在於 master spec；IC-1 至 IC-15 全部有定義且被引用、無跳號無孤立引用；spec delta 的 `<!--`／`-->`／`@trace` 計數皆為 0；canonical fragment 在 design 出現 2 次（IC-6 定義、IC-8 組成）；對照表中標明拆分的列共 5 列。`cash analyze` 為 Coverage 4／Consistency 0／Ambiguity 69／Gaps 0。無 signal 具有 `check` frontmatter 欄位，故 signal-derived check 無可執行項。

fix 後已重新執行 `validate`，結果為 Validation passed。本輪修改的檔案全部位於 `openspec/changes/` 之下，依 touched 記錄規則濾除後為空，因此未呼叫 Cash CLI 的 touched 指令，亦無警告。

## Decision

passed
