# Cash Propose Review — Round 4

## Reviewer Findings

本輪為 full round 檢查點，Reviewer A（Adherence）與 Reviewer B（Quality）平行獨立執行，兩者都被要求對 cumulative blocking set 的成員給出明確判定。

### Cumulative blocking set 逐筆判定

兩位 reviewer 對兩個成員的判定一致，皆為 `resolved`，且各自附上修正後文字與真實程式碼的雙向證據：

- P1（`design.md` D3 契約總結句未依 gate 分寫，Warning）：`resolved`。該句已改為依 gate 分寫形式，小標題在 design、IC-4 與 spec delta 三處統一為「該 gate 本來就會對現地檔案驗證的其餘 records」；兩位 reviewer 都以 grep 掃過四份 artifact 確認無其他未分寫的殘留句，並各自以真實碼覆核 launcher 只對 stable 與 runtime records 做現地 digest、`validate_installed_receipt` 的迴圈確實走完 stable／runtime／skill 全部 records。
- P2（IC-14 第 8 列與第 11 列 red／guard 錯標，Warning）：`resolved`。第 11 列現要求 launcher 側斷言形狀專屬的 `receipt identity is invalid`，兩位 reviewer 都確認該字串目前只由 `except ValueError` 產生、`-1` 走不到，因此斷言今日必定失敗而 red 成立；installer 側標 guard 正確。第 8 列現要求斷言 identity 診斷含兩步指引，兩位都確認今日的 `stable receipt identity drift: {path}` 沒有任何兩步指引文字因此 red 成立，且都獨立指出「僅斷言兩者一併出現」在今日即成立、舊標記為假 red。Reviewer B 另抽查其餘各列未發現新錯標。

兩個成員皆以 verified resolution 離開 cumulative blocking set，移除依據為本輪兩位 reviewer 的一致判定與其引用的證據。兩位也都複查了前三輪對先前八個成員的 resolved 判定，未發現判定本身有誤。

### Critical

- `severity`: Critical / `confidence`: 80 / `layer`: design / `disposition`: `fix-introduced`（見下方 disposition 更正） / `introduced_by`: 第 1 輪 Fix Action 13（IC-5 hint 文字與 IC-11 guidance 條款）與第 3 輪 Fix Actions 3、5（版控限定只加在 installer 面、Risks 的緩解敘述） / `location`: `design.md` IC-5 hint 文字、IC-11、`## Risks / Trade-offs`；spec delta 版控段與 `Target 版控排除保護` 理由句 / `summary`: 版控限定只加在 installer 面，但 `Target 版控排除保護` 自己指名的執行面是 **launcher**。receipt 被 commit 後在別台 clone 的狀態完全落在 launcher 面的 identity drift——digest 由 git 保證相同、mode 由 exec bit 與 umask 得到、runtime records 一併 clone 因此前提成立——於是 launcher 會附上可直接執行的 `--init-receipt` 指令；更嚴重的是 IC-5 的 hint 前提子句與 IC-11 的 guidance 條款**逐字把 `fresh clone` 列為可以重簽的正當理由**，等於對該保護唯一要擋的情境發出明示許可，而該 guidance 會被部署到每個 target 供 agent 讀取。依 proposal 自己的判準，launcher 面現在正是一鍵繞法，且是本 change 新增的（今日 launcher 只輸出 `stable record drift`，沒有任何指令）。其成本理由（每次啟動一次 Git 呼叫）不成立為省略**文字**限定的理由——修文字不需要任何查詢 / `recommendation`: hint 與 guidance 移除 fresh clone 的無條件背書，改為內含版控前提；或 launcher 面一律採兩步形式 / 來源：Reviewer B

### Warning

- `severity`: Warning / `confidence`: 80 / `layer`: design / `disposition`: `fix-introduced` / `introduced_by`: 第 2 輪 Fix Action 5 與第 3 輪 Fix Actions 3、4（版控限定的建立與強化） / `location`: `installer.py` 的 `install_vendored_target`；spec delta 版控段；`design.md` IC-7；`tasks.md` 2.2 / `summary`: `validate_installed_receipt` 有兩個呼叫點——`install_target` 與 `install_vendored_target`——而 `report_version_controlled_receipt` 只由前者呼叫，vendor 路徑整條不做 version-control 查詢。於是新規範的「MUST 與 tracked-receipt diagnostic 一併輸出」在 vendor 面沒有可搭配的對象，而同段的「查詢失敗或結果不可得時 MUST 以保守側處理」會使 vendor 面永遠不得輸出可執行指令——兩條 MUST 在同一路徑互相封死，而本 change 的主要目標在 proposal 自己指名的主要修復路徑（`--vendor` 是全域 shim 的 cash init 預設）上永遠達不到。四份 artifact、十四條 IC、十二列對照表與五組 tasks 沒有任何一處提到 `--vendor` / `recommendation`: 明確界定適用面，或把處置擴到 vendor 路徑並在 tasks 明列該函式 / 來源：Reviewer A 與 Reviewer B 獨立提出（A 判 Warning／80／`fix-introduced`，B 判 Warning／80／`new`；依 blocking disposition 優先規則取 `fix-introduced`）

### Suggestion（經 confidence filter 由 Warning 降級，或原即為 Suggestion）

- `confidence`: 78 / `disposition`: `fix-introduced` / `introduced_by`: 第 3 輪 Fix Action 4 / `location`: spec delta 版控段；`design.md` IC-7 / `summary`: 同段三條 MUST 互相抵銷——「一併輸出」對上 `Target 版控排除保護` 保留不變的「查詢失敗時 MUST 靜默略過該 diagnostic」字面不可同時滿足；journal recovery 再入以 `announce_tracking=False` 抑制該 diagnostic，該段自己承認該路徑上「一併輸出」被違反卻沒有豁免它 / 來源：Reviewer B
- `confidence`: 75 / `disposition`: `fix-introduced` / `introduced_by`: 第 2 輪 Fix Action 5 與第 3 輪 Fix Action 3 / `location`: `design.md` IC-6 vs IC-7；`tasks.md` 2.2 / `summary`: IC-6 與 task 2.2 都要求 `validate_installed_receipt` 函式簽章不變，但 IC-7 要求該函式產生的訊息取決於 version-control 查詢結果且須沿用 `install_target` 那一次查詢——在不改簽章的前提下唯一實作手段是 module-global 或在呼叫端依訊息字串攔截改寫，後者與 IC-5 強調的訊息子字串脆弱性衝突 / 來源：Reviewer B
- `confidence`: 75 / `disposition`: `fix-introduced` / `introduced_by`: 第 1 輪 Fix Action 7 / `location`: `design.md` IC-4／IC-5／IC-7；spec delta 前提段 / `summary`: 「前提不成立」這個新狀態沒有任何被記載的復原路徑——第三支訊息不給下一步、`--init-receipt` 被明文收回、`--force` 依既有契約不繞過、重新安裝也會在同一 preflight 被擋下；本 change 把一個原本有解的狀態換成無解且無指引的狀態 / 來源：Reviewer B
- `confidence`: 75 / `disposition`: `fix-introduced` / `introduced_by`: 第 1 輪 Fix Action 15 / `location`: `tasks.md` 3.2；`design.md` `## Risks / Trade-offs` / `summary`: 兩處都寫「manifest 重新發佈必須緊接在 launcher 編輯之後」，但 manifest 同時記錄 bundle version、runtime generation 與每筆 record digest，而 `installer.py` 本身是 runtime record 且 2.2、2.3、3.1 都要改它——照字面在 2.1 之後立刻發佈，後續編輯會讓本 repo 第二次落入 `manifest_invalid`。真正的約束是「全部 bundle bytes 變更之後的最後一步」 / 來源：Reviewer A（65）與 Reviewer B（75）獨立提出，取較高 confidence
- `confidence`: 70 / `disposition`: `fix-introduced` / `introduced_by`: 第 3 輪 Fix Action 4 / `location`: spec delta；`design.md` IC-14 對照表；`tasks.md` 5.3 / `summary`: 第 3 輪新增了兩條可觀測的 normative 分支（查詢失敗的保守側處理、journal recovery 再入沿用查詢結果），但 scenario 與對照表都沒有對應項；task 5.3 的覆蓋量測基準是 scenario 而非 MUST，因此這兩條義務在結構上不可能被驗收抓到 / 來源：Reviewer B
- `confidence`: 68 / `disposition`: `fix-introduced` / `introduced_by`: 第 1 輪 Fix Action 3 與第 2 輪的對照表擴充 / `location`: `tasks.md` 2.1／2.2 驗收；`design.md` IC-14 第 3、4、6、7 列 / `summary`: IC-14 把每列定義為一個案例，但這四列的驗證方式同時斷言兩個 gate；task 2.1 的「屬於 launcher 的案例全部轉綠」在 2.1 的完成時點不可達，也沒有任何定義說明如何把一個案例切成 launcher 半 / 來源：Reviewer A
- `confidence`: 62 / `disposition`: `fix-introduced` / `introduced_by`: 第 2 輪 Fix Action 4 與第 3 輪 Fix Action 8 / `location`: `design.md` IC-7 / `summary`: IC-7 說 installer「MUST 與 IC-5 採相同形態」，但 installer 的 stable 前綴是 `stable receipt identity drift:` 而非 `stable record`，且 `{other_kind} record drift:` 在 installer 端沒有既有對應訊息（非 stable 漂移現行是累進 conflicts 不產生字串），實作者無法唯一導出 installer 的第三支訊息 / 來源：Reviewer A
- `confidence`: 62 / `disposition`: `new` / `location`: `design.md` IC-4；`.cash-skills/bin/cash` 的 `sha256_file` → `open_regular` 預設 `error_code="bootstrap_invalid"` / `summary`: 延後判定之後，runtime 檔為 symlink／hard link 等情形會在「stable identity drift 尚未回報」的狀態下以 `bootstrap_invalid` 結束，而既有 guidance 對該碼的處置是無條件執行一次 `--init-receipt`——恰好是前提閘門要防的無限定邀請 / 來源：Reviewer B
- `confidence`: 58 / `disposition`: `fix-introduced` / `introduced_by`: 第 3 輪 Fix Action 5 / `location`: `design.md` `## Risks / Trade-offs` 的 skill bytes 不對稱條 / `summary`: 該條列的兩層緩解都不對應它宣稱要緩解的風險——hint 前提子句與 guidance 條款問的是 identity provenance，而風險是 skill bytes 完整性；且該條漏了實際後果（重簽後同版本 installer 會以 `equal-version source integrity drift` 硬性攔下、不同版本會直接覆寫修復），真正的殘留風險是使用者誤以為 launcher 通過即代表 skills 完好 / 來源：Reviewer B
- `confidence`: 58 / `layer`: text / `disposition`: `new` / `location`: `CASH-SKILLS.md`；`tasks.md` 4.2 / `summary`: 該文件既有全稱句「對已 drift 的 receipt-only target 重跑 init 會把該 drift 合法化」在本變更後只對 content drift 成立，對 identity drift 則相反，而 task 4.2 未涵蓋該句，會留下與新契約牴觸的殘骸 / 來源：Reviewer A
- `confidence`: 50 / `disposition`: `new` / `location`: `design.md` IC-4；spec delta 前提段 / `summary`: 沒有任何條款說明「已進入分類的 identity drift 遇到延後路徑上的其他既有出口時該如何回報」，該判斷被留給實作者 / 來源：Reviewer A
- `confidence`: 50 / `layer`: text / `disposition`: `unresolved-prior`（P1 文字殘留） / `location`: `proposal.md` 第三節 / `summary`: 小標題統一時 proposal 那一句仍是舊的「該 gate 本來就會驗證的」，缺「對現地檔案」四字 / 來源：Reviewer B（該 reviewer 同時判定 P1 為 resolved，並明言此殘留不影響判定）

### Disposition 更正紀錄

- 上方 Critical 一筆由 Reviewer B 標為 `new`，經主 agent 檢視後更正為 `fix-introduced`。證據：該缺陷的三個構成要素——identity hint 的存在、hint 文字中的 fresh clone 前提子句、版控限定只加在 installer 面——分別由第 1 輪 Fix Action 13 與第 3 輪 Fix Actions 3、5 引入，全部是本 loop 的 fix-touched 位置；本 change 之前 launcher 對 identity drift 只輸出 `stable record drift`，不含任何指令。原標記 `new`、更正後 `fix-introduced`。此更正不改變該筆的 blocking 性質（`new` 為非 blocking、`fix-introduced` 為 blocking），因此是非 blocking 轉 blocking 的更正，已依規定記錄。
- vendor 路徑一筆由 Reviewer A 標為 `fix-introduced`、Reviewer B 標為 `new`，依 blocking disposition 優先規則取 `fix-introduced`。

## Rating

- post-filter cumulative blocking set Critical count：1
- post-filter cumulative blocking set Warning count：1
- 非 blocking triaged finding count：12
- `critical_gap`: true
- `round_type`: full

rationale：兩個先前成員皆由兩位 reviewer 一致判定 resolved 並離開集合。本輪新增兩筆 blocking，兩筆都指向同一個根因：第 1 至 3 輪為了回應「輸出可執行的 `--init-receipt` 引導」而逐步堆疊出來的 hint／版控查詢機制。Reviewer B 證明該機制在它最該生效的那一面（launcher，也正是 `Target 版控排除保護` 指名的執行面）反而是反效果，Reviewer A 與 Reviewer B 又各自證明它在 `--vendor` 路徑上兩條 MUST 互相封死。十二筆非 blocking 中有七筆同樣落在這套機制上。因此本輪的處置不是再打補丁，而是把條件式查詢機制整個移除、改以「限定寫進指引文字」的無查詢設計。決定 `next_round`。

## Fix Actions

修改檔案：`openspec/changes/tolerate-remount-device-renumbering/proposal.md`、`design.md`、`specs/cash-cli/spec.md`、`tasks.md`（共 4 個檔案，全部位於 change 目錄內）。

blocking findings 的處置：

1. **launcher 面的一鍵繞法**（Critical／80）：移除 hint 文字中的 fresh clone 背書。新增 IC-6 規定 identity hint 文字 MUST 同時包含可執行指令、指出 `.cash-skills/receipt.tsv` 是 machine-local identity 且被納入版控時須先解除追蹤、且 MUST NOT 把 fresh clone 或任何取得方式陳述為無條件可以重新簽發的理由；launcher 面的文字逐字定為 `Run PYTHONPATH=.cash-skills/lib python3 -s -P -B -m cash_cli.installer --init-receipt from the project root; if .cash-skills/receipt.tsv is tracked by version control, untrack it first because it is machine-local identity`。IC-12 的 guidance 條款同步改為三件事並加上同一禁止。spec delta 新增規範段與 `#### Scenario: 指引一律內含版控前提且不背書任何取得方式`。
2. **vendor 路徑的兩條 MUST 互相封死**（Warning／80）：整套「installer 以 version-control 查詢作為分支條件」的機制移除。spec delta 的版控段改寫為「指引 SHALL 在兩個 gate 採用同一組前提陳述，且 MUST NOT 依賴任一 gate 對 target 版控狀態的查詢」，並寫出三個理由（launcher 無法在不新增每次啟動查詢的前提下判定、`report_version_controlled_receipt` 只由 `install_target` 呼叫而 `--vendor` 不執行、查詢失敗須靜默略過與「比照已被追蹤並一併輸出」字面不可同時滿足）。IC-8 明文要求該契約同時適用於 `validate_installed_receipt` 的兩個呼叫點且不依賴版控查詢結果；IC-9 明文規定既有 diagnostic 的契約不變且不得成為 identity 指引的前置條件；task 2.2 同步；IC-15 的版控前提列加上以 `--vendor` 路徑重跑同一斷言。

非 blocking triaged findings 的處置，十二筆全部修正：

3. 三條 MUST 互相抵銷（78）：隨機制移除一併消失，spec delta 不再有「一併輸出」「查詢失敗比照已被追蹤」「recovery 再入沿用查詢結果」三條。
4. 簽章不變 vs 需要 tracked 旗標（75）：隨機制移除而消失。IC-7 同時改寫 conflicts 語意的說明——stable 分支今日即在累積 conflicts 之前丟出例外，因此「stable identity drift 與 runtime／skill 漂移並存」今日已是 raise，本變更只改變該次 raise 攜帶的訊息，不改變 conflicts 累積行為。
5. 前提不成立時無復原路徑（75）：spec delta 與 IC-5 要求第三支訊息 MUST 指出下一步是把該筆 record 還原成 receipt 記錄的內容後重試、或從可信 source 重新安裝；對應 scenario 改名為「其餘 records 同時漂移時改報該漂移並給出下一步」並補一條 AND；IC-15 該列的斷言同步；task 4.3 的 `CASH-INIT-RECEIPT.md` 條款加上「前提不成立時的下一步」。
6. manifest 重新發佈的排序（75）：task 3.2 改為「在 task 2.1、2.2、2.3 與 3.1 全部完成之後」並寫出理由與中斷窗口；design D5 的排序段與 Risks 對應條同步改寫。
7. 兩條新分支無 scenario（70）：隨機制移除而消失，不再有這兩條分支。
8. 跨 gate 案例與 task 驗收時點（68）：IC-15 表頭前明文要求「跨兩個 gate 的案例 MUST 拆成 launcher 與 installer 兩個測試函式」，content drift 與 identity drift 兩列的驗證方式各自寫明拆分；task 2.1／2.2 的驗收改為「屬於該 gate 的測試函式全部轉綠」；task 5.3 加上「跨 gate 的案例對應到兩個函式」。
9. installer 第三支訊息無法唯一導出（62）：IC-8 逐字寫出 installer 的三支訊息形態，並說明 `{other_kind} record drift:` 在 installer 是本變更新增的字串而非沿用 launcher 的既有訊息。
10. 延後判定擴大 `bootstrap_invalid` 出口（62）：IC-4 與 spec delta 明文要求 launcher 在 receipt gate 內對 runtime records 取 digest 時傳入 `error_code="receipt_invalid"`，並新增 `#### Scenario: 延後判定期間命中既有出口時以該出口回報`。
11. Risks 的 skill 不對稱條不誠實（58）：整條改寫，明載版控前提是 identity provenance 的限定因此對 skill bytes 完整性無緩解作用，並補上實際後果（重簽後同版本 installer 以 `equal-version source integrity drift` 攔下、不同版本直接覆寫修復），把殘留風險正確描述為「使用者可能誤以為 launcher 通過即代表 skills 完好」。
12. `CASH-SKILLS.md` 的全稱句（58）：IC-14 與 task 4.2 增列該句必須限定為 content drift 並指出 identity drift 是允許重新簽發的入口。
13. 延後期間命中其他既有出口的回報未定義（50）：IC-4 與 spec delta 補上「MUST 以該既有出口回報，identity drift 不另行輸出」。
14. proposal 第三節的措辭殘留（50）：該節整段重寫，措辭已與 design、IC-4、spec delta 一致。

fix 傳播：條件式版控機制的移除觸及 spec delta 版控段與其 scenario、design D3 與 IC-6 至 IC-9、proposal 第三節、tasks 2.2 與 IC-15 的版控列，已逐處同步；scenario 數由 12 變 13（移除舊的版控 scenario、新增「指引一律內含版控前提」與「延後判定期間命中既有出口」兩個），IC 由 14 條重整為 15 條並全部重新編號，已同步 tasks 的全部 IC 引用與 IC-15 對照表（13 列）。

post-fix mechanical self-check：spec delta 的 `<!--`／`-->` 計數皆為 0 且無殘留 `@trace`；scenario 數 13 與 IC-15 對照表列數 13 逐字 1:1 且同順序；三個 MODIFIED requirement 的 title 逐 byte 存在於 master spec；IC-1 至 IC-15 全部有定義且被引用、無跳號、無孤立引用；全域已無「十一」「十二」的過時計數；`fresh clone` 在四份 artifact 的全部出現處都在禁止或說明脈絡中，無背書用法。無 signal 具有 `check` frontmatter 欄位，故 signal-derived check 無可執行項。

fix 後已重新執行 `validate`，結果為 Validation passed。本輪 Fix Actions 修改的檔案全部位於 `openspec/changes/` 之下，依 touched 記錄規則濾除後為空，因此未呼叫 Cash CLI 的 touched 指令，亦無警告。

## Decision

next_round

兩筆 blocking 已修正，但需由下一輪 reviewer 給出明確的 resolved 判定才能離開 cumulative blocking set。本輪的處置是移除一整套機制而非局部補丁，因此下一輪 reviewer 應特別檢查移除是否留下懸空引用或新的缺口。下一輪為本 run 的第 5 輪，依位置推導為 `micro`。
