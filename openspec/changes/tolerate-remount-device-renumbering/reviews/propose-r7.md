# Cash Propose Review — Round 7

本輪是前一個 run 以 `aborted` 結束後的 **seeded re-run 的第 1 輪**，依位置推導為 `full`，全域編號續接為第 7 輪。Reviewer A（Adherence）與 Reviewer B（Quality）平行獨立執行。

## Reviewer Findings

### Seeded cumulative blocking set 判定

- S1（`design.md` IC-15 第 9 列標為 red 但斷言在現行程式碼下都成立，Warning，由前一個 run 的 bucket 1 種子化）：**兩位 reviewer 皆判 `resolved`**，且各自給出實作前必紅與實作後可達的雙向追跡。共同證據：stable record 迴圈在 runtime 迴圈之前，該 fixture 今日以 `stable record drift: {relative}` 結束，`relative` 只會是兩筆 stable path 之一，訊息不含任何 runtime path，因此新增的「訊息指名該 runtime path」斷言今日必定失敗；實作後 hard link 檔 mode 仍 `0644` 故不短路，進 `sha256_file` → `open_regular` 在 `st_nlink != 1` 命中，訊息 `{path}: unsafe identity or mode` 指名該 runtime path。Reviewer A 另確認改 receipt 內 stable 列的 inode 文字不影響 `runtime_generation`（generation stream 只由 runtime 列組成），因此不會提早在 generation 檢查失敗；兩位都確認 `sha256_file` 在 launcher 內只有兩個呼叫點且都在 `validate_receipt` 內，IC-4 的 `error_code` 參數化不觸及 portable manifest 路徑。

S1 以 verified resolution 離開 cumulative blocking set。

### Warning

- `severity`: Warning / `confidence`: 82 / `layer`: design / `disposition`: `fix-introduced` / `introduced_by`: 前一個 run 結束後把 IC-8 由「內嵌 target 絕對路徑」改為「前綴慣例」的那次改動 / `location`: `design.md` D3 執行位置段與 IC-8；spec delta 的指引措辭段與 `#### Scenario: Installer 的指引指向目標專案而非來源專案`；`tasks.md` 2.2 / `summary`: 「以 target 絕對路徑作為訊息前綴」被寫成 installer 全部使用者可見訊息的既有慣例，而該宣稱正是選擇前綴方案而非 quoting 規則的正當化理由，但真實程式碼不支持：`validate_installed_receipt` 的 raise 與同檔其餘二十餘處 `InstallerError` 全部不帶前綴，`--target` 與 `--vendor` 經 `main()` 印為 `Error: <message>`，前綴只由 `--all` 批次迴圈的呼叫端對 registry record 加上。後果有二——實作必須把前綴併進 raise 的訊息本身而 IC-8 未說明由誰產生；一旦併進去，`--all` 會輸出重複前綴，而該副作用四份 artifact 都未處理，IC-15 對應列只測 direct 路徑因此測不到 / `recommendation`: 改正事實陳述，並改由訊息散文指名 target / 來源：Reviewer A（判 `new`／80）與 Reviewer B（判 `fix-introduced`／82）獨立提出，依 blocking disposition 優先規則取 `fix-introduced`、取較高 confidence
- `severity`: Warning / `confidence`: 80 / `layer`: design / `disposition`: `fix-introduced`（見下方 disposition 更正） / `introduced_by`: 第 2 輪 Fix Action 4（釘死第三支訊息形態）與第 4 輪 Fix Action 5（要求第三支訊息給出下一步） / `location`: `design.md` IC-5 與 IC-8；spec delta 前提段；IC-15 對應列 / `summary`: IC-5 同一句先把第三支訊息逐字釘死為 `stable record identity drift: {relative}; {other_kind} record drift: {other_path}`，緊接著又要求它 MUST 指出下一步——釘死的形式裡沒有任何位置容納那句下一步，而同一份文件中 IC-6／IC-8 以「MUST 為 `<字串>`」表達的正是逐字釘死，兩條 MUST 因此互相抵消。IC-8 的第三支訊息更完全沒有提到下一步，但 spec 對兩個 gate 都要求、IC-15 對應列也斷言「含還原或重新安裝的下一步」，而 task 2.2 只指向 IC-8——依 IC-8 實作出來的 installer 訊息會使該測試失敗 / `recommendation`: 把釘死改為「前段 + 釘死的下一步句」兩段式，並補進 IC-8 / 來源：Reviewer B

### Suggestion（經 confidence filter 由 Warning 降級，或原即為 Suggestion）

- `confidence`: 78 / `disposition`: `fix-introduced` / `introduced_by`: 前一個 run 結束後把 IC-15 對應列建構條件改為「路徑含空白的 fixture target」的那次改動 / `location`: `design.md` IC-15 對應列；`tasks.md` 1.1 / `summary`: 兩個 harness 障礙都未被涵蓋。其一，`make_target()` 硬寫 `tempfile.TemporaryDirectory()` 且無注入點，要含空白必須改 helper 或新增變體，而 `tasks.md` 1.1 逐項列出了本 task 唯一的新 helper 卻沒有列這一項——正是第 2 輪修過的「fixture 敘述與工作量不符」同一形態。其二，`install_target` 對 target input 做 `Path(...).resolve()`，macOS 上 `/var/folders/…` 會變成 `/private/var/folders/…`，以未 resolve 的 fixture 路徑比對會因與待測行為無關的理由失敗。另外空白本身對該列的斷言零鑑別力，因為它們都是子字串比對 / 來源：Reviewer A（62）與 Reviewer B（78）獨立提出，取較高 confidence
- `confidence`: 60 / `disposition`: `new` / `location`: spec delta（未涵蓋 `受控 launcher bootstrap migration`）；`design.md` Goals 末項與 D5；`tasks.md` 3.1、5.2 / `summary`: design 把「不把任何既有 target 留在無法升級的狀態」列為 Goal，其唯一實現是追加第二筆 skip transition，但 spec delta 沒有為它建立規範位置，master 的 `受控 launcher bootstrap migration` 也沒有任何條款要求登錄 catch-up entry。archive 之後 design 與 tasks 消失，該政策只剩程式碼裡兩行 tuple，下一次改 launcher 的 change 依現行 requirement 只登錄一筆仍完全合規 / 來源：Reviewer B
- `confidence`: 60 / `disposition`: `new` / `location`: `design.md` IC-6 與 IC-8 的兩段釘死文字 / `summary`: 兩段約 180 字元的字串僅執行位置子句不同，版控子句逐 byte 相同，卻是兩處各自獨立的事實。launcher 必須零 import、程式碼層面無法共用，因此釘死本身必要；但沒有任何條款要求共同子句保持一致，唯一的跨側約束是兩個子字串斷言，對子句其餘內容無鑑別力，未來只改一側時不會有機制發現 / 來源：Reviewer B
- `confidence`: 58 / `layer`: text / `disposition`: `new` / `location`: `design.md` IC-12；`tasks.md` 4.1 / `summary`: 受管區塊既有且 IC-12 要求保留的 literal 是「manifest 存在但為 invalid manifest 時……也不得執行 `--init-receipt`」，而 IC-12 新增的第一件事寫成無限定的「identity drift 的 `receipt_invalid` 同樣可由 `--init-receipt` 復原」，沒有帶上 spec delta 已寫進 `Target-local receipt 初始化` 的「manifest 缺失的 receipt-based target」限定。同一區塊因此同時出現無限定的「不得執行」與無限定的「可復原」 / 來源：Reviewer B
- `confidence`: 48 / `disposition`: `new` / `location`: `design.md` IC-5 與 IC-8；spec delta 分類段 / `summary`: 兩筆 stable records 同時出現 identity drift 時，訊息中的 path 取哪一筆未規定——IC-5 只對 `{other_kind}`／`{other_path}` 寫了迭代順序規則，沒有涵蓋 stable 端。這不是罕見組合：版控 clone 正好會使兩筆 inode 同時改變。此筆 confidence 低於 50，依 confidence filter 應被丟棄，僅記錄為 downgrade trace / 來源：Reviewer A
- `confidence`: 40 / `layer`: text / `disposition`: `fix-introduced` / `introduced_by`: 第 2 輪 Fix Action 2 / `location`: `tasks.md` 1.1 驗收末句 / `summary`: 「標記為 guard 的案例……並在實作後仍通過」的後半句在 task 1.1 的完成時點無法評估，彼時 launcher 與 installer 都還沒改。此筆 confidence 低於 50，依 confidence filter 應被丟棄，僅記錄為 downgrade trace / 來源：Reviewer A

### Disposition 更正紀錄

- 第三支訊息互相抵消一筆由 Reviewer B 標為 `new`，經主 agent 檢視後更正為 `fix-introduced`。證據：該缺陷的兩個構成要素分別由第 2 輪 Fix Action 4（釘死第三支訊息形態）與第 4 輪 Fix Action 5（要求第三支訊息給出下一步）引入，兩者都是本 loop 的 fix-touched 位置，缺陷正是這兩次 fix 的交互結果。原標記 `new`、更正後 `fix-introduced`，屬非 blocking 轉 blocking 的更正。
- 前綴一筆由 Reviewer A 標為 `new`、Reviewer B 標為 `fix-introduced`，依 blocking disposition 優先規則取 `fix-introduced`。

## Rating

- post-filter cumulative blocking set Critical count：0
- post-filter cumulative blocking set Warning count：2
- 非 blocking triaged finding count：6
- `critical_gap`: false
- `round_type`: full

rationale：S1 由兩位 reviewer 一致判定 resolved 並離開集合，前一個 run 的 bucket 1 至此關閉。本輪兩筆 blocking 都落在前一個 run 結束後為回應外部 review 而做的 IC-8 改動，以及該改動與先前輪次 fix 的交互：一筆是把「前綴」誤述為既有慣例並因此未定義前綴的產生位置與 `--all` 的重複前綴；一筆是第三支訊息同時被要求「逐字釘死」與「必須額外含下一步」而兩條 MUST 互相抵消。兩筆皆已修正。決定 `next_round`。

## Fix Actions

修改檔案：`openspec/changes/tolerate-remount-device-renumbering/proposal.md`、`design.md`、`specs/cash-cli/spec.md`、`tasks.md`（共 4 個檔案，全部位於 change 目錄內）。

blocking findings 的處置：

1. **前綴的事實錯誤與未定義的產生位置**（Warning／82）：主 agent 先自行查證確認 reviewer 的事實判斷——`main()` 對 `InstallerError` 印 `Error: {error}` 不帶前綴，`--all` 迴圈印 `f"{record}: {error}"` 由呼叫端加前綴。據此改為**由訊息散文指名 target** 而非依賴前綴：IC-8 要求 identity 訊息在指令以外的散文部分指名該 target 的 resolved 絕對路徑，形式為 `stable receipt identity drift: <record path> in <resolved target path>`，並明文 MUST NOT 自加 `<target>: ` 前綴（理由：`--all` 會重複、direct 與 vendor 本來就不帶）。design D3 的執行位置段改寫為事實正確的版本，明確區分「`print` 出來的 target-scoped diagnostic 有前綴」與「`InstallerError` 沒有」。spec delta 的指引措辭段與對應 scenario、tasks 2.2、proposal 第三節同步。此修法同時保留原本要解決的 quoting 性質：指令仍是不內插任何路徑的釘死字串。
2. **第三支訊息的兩條 MUST 互相抵消**（Warning／80）：IC-5 改為兩段式——MUST 以釘死的前段 `stable record identity drift: {relative}; {other_kind} record drift: {other_path}` 起頭，其後 MUST 接 `. ` 與逐字為 `Restore that record to the content the receipt records, or reinstall from a trusted source, then retry` 的下一步句，兩段都是釘死的。IC-8 明文要求 installer 的第三支比照 IC-5 組成且下一步句逐字相同。spec delta 前提段同步要求該下一步句「MUST 是訊息的一部分而非另一則輸出」。

非 blocking triaged findings 的處置，四筆修正、兩筆低於 filter 門檻但仍一併修正：

3. IC-15 對應列的 fixture 障礙（78）：刪除「含空白路徑是必要建構條件」的宣稱並說明理由（指令是不內插路徑的釘死字串，空白對四條斷言的可鑑別性零貢獻）；改為要求比對以 `Path(target).resolve()` 為準，並寫出 macOS 上 `/var/folders/…` → `/private/var/folders/…` 的成因。因為不再需要含空白的 fixture，tasks 1.1 也不需新增該 helper。
4. skip transition 沒有規範位置（60）：不擴張範圍去改 `受控 launcher bootstrap migration`，改在 `## Risks / Trade-offs` 新增一條誠實記錄——明載這是一次性補救而非通則、archive 後只剩程式碼裡一筆 tuple、下一次改 launcher 只登錄一筆仍合規、不寫成通則的理由是範圍，以及復發防護目前由 `openspec/signals/exact-transition-allowlist-strands-lagging-targets.md` 承擔、要成為契約需另開 change。
5. 兩段釘死文字缺單一真值來源（60）：IC-6 把版控前提句抽成具名的 canonical fragment 並逐字定義，規定每個 gate 的 hint MUST 恰為「執行位置子句 + `; ` + 該 fragment」；IC-8 依該形式組成；IC-13 新增一條斷言要求該 fragment 逐字同時出現於 `.cash-skills/bin/cash` 與 `.cash-skills/lib/cash_cli/installer.py`，使單邊漂移可機械偵測；tasks 4.4 同步。
6. IC-12 第一件事缺 manifest 限定（58）：補上「manifest 缺失的 receipt-based target」限定，與 spec delta 的措辭對齊。
7. stable 端多筆同時漂移的取捨未定義（48，低於 filter 門檻）：IC-5 的迭代順序規則明文擴及 stable 端。
8. task 1.1 驗收末句在該 task 完成時點無法評估（40，低於 filter 門檻）：把「並在實作後仍通過」移出 task 1.1 的完成判準，改為註明由 task 5.1 與 5.3 驗證。

fix 傳播：「前綴」這個概念已在 proposal 第三節、design D3 與 IC-8、spec delta 指引措辭段與對應 scenario、tasks 2.2、IC-15 對應列全部同步，並以 grep 確認四份 artifact 已無把前綴描述為既有慣例的殘留句；「第三支訊息」的兩段式已在 IC-5、IC-8、spec delta 前提段與 IC-15 對應列同步；canonical fragment 已在 IC-6 定義、IC-8 引用、IC-13 與 tasks 4.4 建立驗證。

post-fix mechanical self-check：13 個 scenario 與 IC-15 對照表逐字 1:1 且同順序；三個 MODIFIED requirement 的 title 逐 byte 存在於 master spec；IC-1 至 IC-15 全部有定義且被引用、無跳號無孤立引用；spec delta 的 `<!--`／`-->`／`@trace` 計數皆為 0；canonical fragment 在 design 出現 2 次（IC-6 的定義與 IC-8 組成的完整字串）、下一步句出現 1 次（IC-5 定義，IC-8 以引用方式指向它，維持單一真值來源）。`cash analyze` 為 Coverage 4／Consistency 0／Ambiguity 69／Gaps 0，其中 Coverage 與 Ambiguity 兩項已於本輪確認屬 analyzer 的機械式啟發（tasks 以 IC 編號而非 requirement 標題引用；69 筆中 56 筆來自逐字帶入的 MODIFIED requirement）。無 signal 具有 `check` frontmatter 欄位，故 signal-derived check 無可執行項。

fix 後已重新執行 `validate`，結果為 Validation passed。本輪 Fix Actions 修改的檔案全部位於 `openspec/changes/` 之下，依 touched 記錄規則濾除後為空，因此未呼叫 Cash CLI 的 touched 指令，亦無警告。

## Decision

next_round

兩筆 blocking 已修正，需由下一輪 reviewer 給出明確的 resolved 判定才能離開 cumulative blocking set。下一輪為本 run 的第 2 輪（全域第 8 輪），依位置推導為 `micro`。
