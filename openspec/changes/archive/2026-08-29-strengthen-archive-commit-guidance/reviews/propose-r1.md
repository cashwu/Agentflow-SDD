# Cash Propose Review — Round 1

## Reviewer Findings

### Critical

- severity: Critical｜confidence: 90｜layer: design｜location: tasks.md 任務序位（2.1／2.2／3.1 → 3.2）＋ design.md D5 與 Risks（manifest 再簽風險）｜summary: `./install-cash-skills.fish --self` 延後到 task 3.2 造成 fail-closed 窗口——task 2.1 修改受守衛 SKILL.md 後，task loop 自身每個 task 結尾的 `"$cash_cli" task done` 會被 launcher 以 manifest digest drift 擋下，實作迴圈走不到 3.2｜recommendation: 依既往先例讓每個修改 skill record 的 task 在自身結尾、任何下一次 Cash CLI 呼叫前執行 `--self`；3.2 改為最終冪等確認＋全套測試；同步改寫 D5 與 Risks｜reviewer: A

### Warning

- severity: Warning｜confidence: 90｜layer: text｜location: proposal.md Proposed Solution 2、design.md D2 交集非空分支、delta spec ADDED requirement 主文與「交集非空時發問且選項互斥」scenario｜summary: 交集定義明文含 untracked，但同句要求「列出這些未提交的 tracked source 檔案」，措辭自相矛盾｜recommendation: 三處改為「未提交的 source 檔案」｜reviewer: A+B（合併，location+summary 相同）
- severity: Warning｜confidence: 80｜layer: design｜location: design.md D2、delta spec ADDED requirement 主文（git 指令）｜summary: `git status --porcelain` 預設會把新目錄折疊成單一 `?? dir/` 條目，touched 中位於新目錄下的未提交新檔無法與 dirty 路徑相交，守門靜默漏放｜recommendation: 指令固定為含 `--untracked-files=all` 的完整形式並要求 skill 步驟逐字寫出｜reviewer: B
- severity: Warning｜confidence: 85｜layer: design（A 判 design、B 判 text，依規則取 design）｜location: design.md D4、tasks.md 2.3、design.md D1 主張句｜summary: 列舉的 assertion literal（含 `.cash-skills/state/touched/`，已存在於現行步驟 5）對新內容零鑑別力，且未 pin 住模板三段與守門規範元素；D1「直接消除」屬過度陳述｜recommendation: literal 全部改選新內容獨有字串並逐段覆蓋；D1 改述並在 Risks 記「守形不守行為」殘餘缺口｜reviewer: A+B（合併）

### Suggestion

- severity: Suggestion｜confidence: 70（原 Warning 70，依 confidence filter 降級）｜layer: design｜location: design.md D2、delta spec ADDED requirement（存在性檢查）｜summary: touched state 可能只存在於 legacy `.spectra/touched/<name>.json`，守門對其防護的同一 hazard 出現盲區｜reviewer: B
- severity: Suggestion｜confidence: 55（原 Warning 55，依 confidence filter 降級）｜layer: design｜location: design.md D2、delta spec ADDED requirement（git 指令）｜summary: `core.quotePath=true` 預設下非 ASCII 路徑被 C-quoted 轉義，與 touched 的 raw UTF-8 路徑交集必然漏判｜reviewer: B
- severity: Suggestion｜confidence: 85｜layer: design｜location: design.md D2、delta spec ADDED requirement（files 讀取）｜summary: touched JSON 的 top-level `files` 已是 CLI 驗證過的 canonical union，要求 agent 自行迭代條目取聯集是重複既有能力且多一個出錯面｜reviewer: B
- severity: Suggestion｜confidence: 65｜layer: design｜location: design.md D2、delta spec ADDED requirement｜summary: touched JSON malformed 時守門行為未定義，可能被誤判為缺檔靜默放行｜reviewer: B
- severity: Suggestion｜confidence: 60｜layer: design｜location: design.md D2 步驟序位｜summary: 4b 排在步驟 2／3 提問之後，使用者選停止時已回答的問題作廢；D2 只以避免重編號論證位置｜reviewer: B
- severity: Suggestion｜confidence: 55｜layer: text｜location: design.md D1 模板第 (3) 項、delta spec MODIFIED requirement 主文｜summary: 「較舊的封存甚至沒有該欄位」對當下要封存的 change 永不適用，鎖進逐字模板是規格化引入的噪音｜reviewer: B
- severity: Suggestion｜confidence: 75｜layer: text｜location: design.md Risks（manifest 再簽風險）｜summary: 本 repo 為 manifest 模式，實際失敗是 `manifest_invalid`（`portable manifest digest drift`），非 receipt 模式的「skill record drift」用語｜reviewer: A

## Rating

- post-filter cumulative blocking set Critical count: 1
- post-filter cumulative blocking set Warning count: 3
- non-blocking triaged finding count: 7
- critical_gap: true
- round_type: full
- rationale: 首輪（unseeded）全部 surviving Critical／Warning 進入 cumulative blocking set。Critical 的 --self 序位缺陷會使實作迴圈在 task 2.1 之後全面 fail closed，屬必然發生的流程死路；三個 Warning 分別是措辭自相矛盾、守門漏判與 assertion 鑑別力不足，皆有直接證據。全部 blocking findings 與非 blocking suggestions 已於本輪修復，交由下一輪 Reviewer V 驗證，故 decision 為 next_round。

## Fix Actions

1. 【Critical --self 序位】重排 tasks.md：2.1、2.2、3.1 各自在結尾、任何下一次 Cash CLI 呼叫前執行 ./install-cash-skills.fish --self（delivery 加入 .cash-skills/manifest.tsv）；移除 2.1／2.2／2.3 的 [P] 標記並在群組標題明訂循序執行；3.2 改為最終冪等確認（Result: current）＋全套測試。design.md D5 改寫（含 launcher 驗證機制與禁止平行的理由）、Implementation Contract 第 6 項、Risks「manifest 再簽風險」同步改寫。proposal.md Proposed Solution 3 同步。修改檔案：tasks.md、design.md、proposal.md。
2. 【Warning tracked 措辭】proposal.md Proposed Solution 2、design.md D2、delta spec ADDED 主文與「交集非空時發問且選項互斥」scenario 一律改為「未提交的 source 檔案」。修改檔案：proposal.md、design.md、specs/cash-skill-workflows/spec.md。
3. 【Warning untracked-files ＋ Suggestion quotePath，合併修復】四個 artifacts 的 git 指令統一固定為逐字完整形式 git -c core.quotePath=false status --porcelain --untracked-files=all，design D2 與 delta spec 要求 skill 步驟 4b 逐字寫出該指令並記載兩個旗標的理由。修改檔案：proposal.md、design.md、specs/cash-skill-workflows/spec.md、tasks.md。
4. 【Warning assertion 鑑別力】design D4 改寫：模板三段各取一個獨有中文 literal；守門區塊 literal 枚舉為步驟名、完整 git 指令、兩個選項標籤、靜默通過句、唯讀約束句；明訂既有內容已出現的字串（如 .cash-skills/state/touched/）MUST NOT 作為 literal。tasks 2.3 同步；design D1「直接消除」改述為「消除模板段落缺失類失效模式」，Risks 新增「assertion 守形不守行為」殘餘缺口條目。修改檔案：design.md、tasks.md。
5. 【Suggestion legacy 盲區】design D2 與 delta spec 把存在性檢查擴為兩路徑：僅 legacy .spectra/touched/<name>.json 存在時改讀 legacy 檔；唯讀約束涵蓋兩路徑；新增 scenario「僅 legacy touched state 存在時仍受守門」；「touched state 缺失時靜默通過」scenario 改為兩路徑皆缺。proposal.md、tasks 2.2 同步。修改檔案：proposal.md、design.md、specs/cash-skill-workflows/spec.md、tasks.md。
6. 【Suggestion top-level files】design D2 與 delta spec 改為讀取 top-level `files` 欄位（CLI 驗證過的 canonical union），scenario 同步。修改檔案：proposal.md、design.md、specs/cash-skill-workflows/spec.md、tasks.md。
7. 【Suggestion malformed fallback】design D2 新增 malformed 分支（不猜測、不修改、放行由 CLI 以 touched_invalid fail closed）；delta spec 主文同步並新增 scenario「touched state malformed 時放行由 CLI 守門」。修改檔案：proposal.md、design.md、specs/cash-skill-workflows/spec.md。
8. 【Suggestion 序位理由】design D2 新增「序位取捨」條目：4b 緊鄰不可逆 CLI 呼叫、選停止時已答問題作廢的成本與 cash-commit 6a-i 重問的等價性，成為記錄在案的決策。修改檔案：design.md。
9. 【Suggestion 模板歷史註腳】design D1 與 delta spec MODIFIED 主文把「較舊的封存沒有該欄位」移出逐字模板、保留於段落規範句。修改檔案：design.md、specs/cash-skill-workflows/spec.md。
10. 【Suggestion 錯誤碼用語】design Risks 的失敗敘述改為 manifest_invalid（portable manifest digest drift: <path>）。修改檔案：design.md。
11. 【post-fix 自我檢查】修復後重跑 pre-round mechanical self-check：annotation lint 0/0；完整 git 指令在四個 artifacts 出現次數 2/3/1/1 一致；「tracked source」字串已清零；發現並修正 tasks 2.3 success 的「兩組新 assertion 區塊」與 D4「擴充既有區塊＋新增一個區塊」的 count 不一致，及 tasks.md 群組標題 fail-loosed 錯字。`"$cash_cli" validate "strengthen-archive-commit-guidance"` 重跑通過。修改檔案：tasks.md。

修改檔案彙總（distinct）：proposal.md、design.md、specs/cash-skill-workflows/spec.md、tasks.md（皆位於 openspec/changes/strengthen-archive-commit-guidance/ 下，無 change 目錄外修改，不需 touched record）。

## Decision

next_round
