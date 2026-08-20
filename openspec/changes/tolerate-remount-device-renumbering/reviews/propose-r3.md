# Cash Propose Review — Round 3

## Reviewer Findings

本輪為 micro round，由單一 Reviewer V 執行 delta verification。

### Cumulative blocking set 逐筆判定

- N1（指引前提超出 launcher 實際驗證範圍，Critical）：`unresolved`。normative 面（spec delta、IC-4、tasks、proposal）皆已分寫兩個 gate，但 `design.md` D3 的契約總結句仍是原始的未分寫形式「因此契約規定：identity drift 的指引只在 runtime generation 與每一筆 runtime／skill record 都相符時附上」，與相隔兩段的分寫段及 IC-4 直接矛盾。Reviewer V 另以真實碼確認事實面：launcher 的 `validate_receipt` 只對 stable 與 runtime records 做現地 digest 比對，`SKILL_PATHS` 僅用於 receipt 內順序與 contract-mode 表；`validate_installed_receipt` 的迴圈確實涵蓋 skill records。
- N2（紅燈驗收涵蓋本來就綠燈的案例，Warning）：`unresolved`。Reviewer V 對 IC-14 的十二列逐列（非抽樣）比對現行程式碼下的實際結果，找出兩個錯標：第 11 列的 launcher 半被標 red，但 device `-1` 今天就會命中 `record[3] != opened.st_dev` 而 fail closed，「斷言兩個 gate 皆 `receipt_invalid`」在實作前兩側都通過；第 8 列被標 red，但 `report_version_controlled_receipt` 的呼叫早於 `validate_installed_receipt` 且既有字串已含 `git rm --cached`，「兩者一併出現」在實作前即成立。其餘十列標記正確。

### Warning

- `severity`: Warning / `confidence`: 82 / `layer`: design / `disposition`: `unresolved-prior`（N1） / `location`: `design.md` D3 契約總結句 / `summary`: 第 2 輪的分寫修法漏掉同節的契約總結句，照該句實作 launcher 就會回到每次啟動 24 次檔案雜湊 / `recommendation`: 該句改為依 gate 分寫的形式
- `severity`: Warning / `confidence`: 90 / `layer`: design / `disposition`: `unresolved-prior`（N2） / `location`: `design.md` IC-14 第 8 列與第 11 列；`tasks.md` 1.1 / `summary`: 兩列的 red／guard 標記與其驗證方式與現行程式碼下的實際結果不符，會再度產生假的 red evidence / `recommendation`: 第 11 列的 launcher 半改為斷言形狀專屬訊息才具 red 性質；第 8 列改為斷言 identity 診斷本身不得輸出可直接執行的指令

### Suggestion（經 confidence filter 由 Warning 降級）

- `confidence`: 72 / `disposition`: `fix-introduced` / `introduced_by`: 第 2 輪 Fix Action 5 / `location`: spec delta 版控段；`design.md` D3／IC-7 / `summary`: 新規範只要求「一併輸出」，而該 diagnostic 今天就無條件輸出且已含 `git rm --cached`，因此該 MUST 自動成立；沒有任何條款要求 identity 診斷本身在 tracked 情境收回或限定 `--init-receipt`，proposal 宣稱要防的一鍵繞法實際上沒有被防住
- `confidence`: 70 / `disposition`: `fix-introduced` / `introduced_by`: 第 2 輪 Fix Action 1 / `location`: spec delta 前提段；`design.md` D3／IC-4 / `summary`: launcher 面前提限縮為 runtime records 之後，「stable inode 被換掉、同時 skill 檔被竄改」的 target 會從 launcher 拿到指引而 installer 不會，兩個 gate 對同一狀態給出相反指引——正是 D2 用來否決「mode 歸 content drift」的判準；該殘留風險未出現在 Risks
- `confidence`: 68 / `disposition`: `fix-introduced` / `introduced_by`: 第 2 輪 Fix Action 5 / `location`: spec delta 版控段 / `summary`: 兩個相容性缺口未被涵蓋：version-control 查詢失敗時既有契約要求靜默略過，新規範沒說 identity 指引該如何處置；`install_target` 的 reclassification 再入以 `announce_tracking=False` 抑制該 diagnostic，journal recovery 後的再入會走到 identity drift 而使「一併輸出」不成立
- `confidence`: 65 / `disposition`: `fix-introduced` / `introduced_by`: 第 2 輪 Fix Action 1（與 Fix Action 4 交互） / `location`: `design.md` IC-4／IC-5；spec delta 前提段 / `summary`: 前提兩側都寫入「runtime generation」，但兩邊語意都對不上——launcher 的 generation 重算是以 receipt 自身 runtime 列進行的內部一致性檢查，installer 則完全沒有對 target 重算 generation（`receipt.generation != generation` 比的是 target 記載值與 source 的值且只在等版本時執行），把它列為前提違反 IC-4 自己的「MUST NOT 要求任一 gate 新增它現行未執行的驗證」；第三支訊息形態也無法表達 generation 不符
- `confidence`: 58 / `disposition`: `fix-introduced` / `introduced_by`: 第 2 輪 Fix Action 4 / `location`: `design.md` IC-5 / `summary`: 「第三支訊息 MUST NOT 附 hint」與同一 IC 的「source-repository 提示 MUST 保持優先」字面互斥，因為 `fail()` 在 `FAILURE_HINT` 非空時一律附加
- `confidence`: 55 / `disposition`: `fix-introduced` / `introduced_by`: 第 2 輪 Fix Action 4 / `location`: `design.md` IC-5／IC-7 的 `{other_kind}` / `summary`: `{other_kind}` 可取值未界定、多筆漂移時取哪一筆未定義，且該形態把既有 `runtime record drift: {path}` 完整包成子字串，斷言無法單以子字串區分兩支訊息

## Rating

- post-filter cumulative blocking set Critical count：0
- post-filter cumulative blocking set Warning count：2
- 非 blocking triaged finding count：6
- `critical_gap`: false
- `round_type`: micro

rationale：N1 與 N2 皆判為 `unresolved`，兩者都是第 2 輪修法不完整而非全新問題——N1 少改一句契約總結，N2 的 red／guard 標記在十二列中錯了兩列。兩筆的 confidence 皆 ≥ 80 因此維持 blocking，但兩筆的 severity 都是 Warning，故 `critical_gap` 為 false。另有六筆由第 2 輪 fix 引入的非 blocking findings，其中「版控限定其實沒有防住一鍵繞法」與「前提誤把 runtime generation 列入」兩筆都有可驗證的程式碼證據，雖未達 blocking 門檻仍一併修正。決定 `next_round`。

## Fix Actions

修改檔案：`openspec/changes/tolerate-remount-device-renumbering/proposal.md`、`design.md`、`specs/cash-cli/spec.md`（共 3 個檔案，全部位於 change 目錄內；`tasks.md` 亦有修改，合計 4 個檔案）。

blocking findings 的處置：

1. **N1 的殘留句**（Warning／82）：`design.md` D3 的契約總結句改為「identity drift 的指引只在該 gate 前提範圍內的 records 都相符時附上（launcher 面為每一筆 runtime record，installer 面另含 skill records）」，並把同段開頭的小標題由「該 gate 本來就會驗證的其餘 records」統一為「該 gate 本來就會對現地檔案驗證的其餘 records」，與 IC-4 用語一致。已以 grep 確認全域無其他未分寫的前提句。
2. **N2 的兩個錯標**（Warning／90）：IC-14 第 11 列的驗證方式改為「launcher 側 MUST 斷言失敗訊息為形狀專屬的 `receipt identity is invalid` 而非 `stable record drift`」，並寫明「僅斷言 `receipt_invalid` 不構成 red，因為今天 `-1` 是被即將移除的等值比對擋下的」；IC-2 同步加上該訊息要求並說明它是該行為唯一可觀測的 red 判準。第 8 列的驗證方式改為斷言 identity 診斷不含可直接執行的指令、含兩步指引，並寫明「僅斷言兩者一併出現不足以構成 red」。task 2.1 加上 IC-2 的訊息要求。

非 blocking triaged findings 的處置，六筆全部修正：

3. 版控限定沒有防住一鍵繞法（72）：spec delta 版控段改為「identity drift 的診斷 MUST NOT 包含可直接執行的 `--init-receipt` 指令，MUST 改為指示先解除版控追蹤、確認取得該 checkout 的方式之後再重新簽發」；對應 scenario 的 THEN／AND 同步；IC-7 與 proposal 第三節同步。
4. 查詢失敗與 reclassification 再入（68）：spec delta 補「該查詢失敗或結果不可得時 MUST 以保守側處理，比照已被追蹤處置」，以及「此義務同樣適用於 installer 在 journal recovery 之後的重新分類路徑，因此該路徑 MUST 沿用同一次查詢的結果，MUST NOT 因抑制重複輸出 tracked-receipt diagnostic 而讓 identity 診斷退回無限定形式」；IC-7 與 task 2.2 同步。
5. skill 竄改的 gate 不對稱（70）：`## Risks / Trade-offs` 新增專條明載該不對稱、其成因（IC-4 的「不新增現行未執行的驗證」）與兩層緩解（IC-5 的 hint 前提子句與 IC-11 的 guidance 條款）；proposal 第三節加一句指向該風險段。
6. 前提誤含 runtime generation（65）：spec delta、design D3、IC-4、proposal 第三節與 tasks 2.1／2.2 全部刪除前提中的 runtime generation，並寫出理由；spec delta 的出口列舉補上「receipt 自身的 runtime generation 不符」；identity drift scenario 的 AND 改為「該 receipt 在該 gate 前提範圍內的其餘 records 皆相符」。
7. 第三支訊息與 `FAILURE_HINT` 的字面互斥（58）：IC-5 改為「MUST NOT 附上 identity drift 的 `--init-receipt` hint（此規定不涉及 `FAILURE_HINT` 的既有內容）」。
8. `{other_kind}` 未界定（55）：IC-5 補上取值域（launcher 面只取 `runtime`，installer 面取 `runtime` 或 `skill`）、多筆漂移時取該 gate 既有迭代順序的第一筆，並明寫「因為該形態把既有的 `runtime record drift: {path}` 包成子字串，測試 MUST 以 `stable record identity drift:` 前綴而非該子字串區分兩支訊息」。

另一併調整：IC-5 的 hint 文字加入前提子句，改為 `Run PYTHONPATH=.cash-skills/lib python3 -s -P -B -m cash_cli.installer --init-receipt from the project root, but only if you can account for the current file identity (fresh clone, copy, or restore)`，使兩個 gate 的指引在無法偵測的情境（launcher 面的 skill 竄改、版控狀態）仍帶著前提而非成為無條件邀請。

fix 傳播：「前提」概念的兩次變動（移除 runtime generation、統一小標題用語）已在 proposal 第三節、design D3 三處與 IC-4、spec delta 前提段與 identity scenario、tasks 2.1／2.2 全部同步；版控限定的強化已在 spec delta 正文與 scenario、design D3／IC-7、proposal 第三節、tasks 2.2、IC-14 第 8 列同步；hint 文字只在 IC-5 定義一次，IC-14 第 9 列引用的 `from the project root` 仍是該文字的子字串故不需改。

post-fix mechanical self-check：spec delta 的 `<!--`／`-->` 計數皆為 0 且無殘留 `@trace`；scenario 數 12 與 IC-14 對照表列數 12 逐字 1:1 且同順序；三個 MODIFIED requirement 的 title 逐 byte 存在於 master spec；IC-1 至 IC-14 全部有定義且被引用、無跳號；以 grep 掃描四份 artifact 確認除「描述 launcher 執行序」的事實句外，無任何把 runtime generation 當作指引前提的殘留句。無 signal 具有 `check` frontmatter 欄位，故 signal-derived check 無可執行項。

fix 後已重新執行 `validate`，結果為 Validation passed。本輪 Fix Actions 修改的檔案全部位於 `openspec/changes/` 之下，依 touched 記錄規則濾除後為空，因此未呼叫 Cash CLI 的 touched 指令，亦無警告。

## Decision

next_round

兩筆 blocking Warning 已修正，但需由下一輪 reviewer 給出明確的 resolved 判定才能離開 cumulative blocking set。下一輪為本 run 的第 4 輪，依位置推導為 `full`，因此將平行spawn Reviewer A 與 Reviewer B 兩位，並要求兩者都對 cumulative blocking set 的成員給出明確判定。
