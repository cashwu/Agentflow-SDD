# Cash Propose Review — Round 3

## Reviewer Findings

本輪為 micro 輪，由單一 Reviewer V — Verification 對 cumulative blocking set 做 delta 驗證並檢查 round 2 的 fix propagation。

### Cumulative blocking set 逐項判定（Reviewer V）

round 2 的 2 個 blocking 成員與 2 個非阻斷 triage 項全數 `resolved`：

| member | verdict | 驗證依據摘要 |
| --- | --- | --- |
| N1 | resolved | proposal `## Proposed Solution` 第 1 點五個要素齊備且與 design D1／IC1 逐條對應；舊機制描述（「使空字串進入既有的空值守衛」、「相容性檢查一併改為同一判準」）在 4 份 artifact 中零殘留 |
| N2 | resolved | 順序約束在 design D1、IC1、spec requirement、dry-run scenario、tasks 1.1／2.1 五處齊備且語義一致；程式面以 `installer.py:1579-1587` 逐條驗算確認前置空值守衛可消除該遮蔽，且 `--list --dry-run` 仍 raise exit 2 |
| N3 | resolved（僅就 ready 檔機制） | design D3／IC3、spec requirement、更名後的 scenario 與 tasks 1.3／2.3 五處一致；舊名 `重新進入不因自身 ready 檔而失敗` 在 artifact 中零殘留。release 檔的同型破口另見 F1 |
| N4 | resolved | 程式化雙向比對確認 IC5 四個 bullet 與 15 個新增 scenario 一一對應，round 2 補入的兩項確實在位 |

依 cumulative set 規則，N1、N2 以 verified resolution 離開集合。

### Fix propagation 檢查結果（Reviewer V）

順序約束五處一致、scenario 更名零殘留、batch 免除五處一致、IC5 一一對應、tasks 與 delta 的 scenario 雙向零缺漏——除 F1 與 F4 指出的兩點外全數通過。

### Warning

**F1**
- `severity`: Warning
- `confidence`: 85
- `layer`: design
- `location`: specs/cash-cli/spec.md `### Requirement: Installer fault-injection hooks 治理` 與其兩個 hold scenario；design.md `### D3` 第 3 點、`### IC3` 第 5 條；tasks.md 1.3
- `summary`: at-most-once 免除條件只涵蓋「等待」與「ready 檔存在性檢查」，未涵蓋同一 hook 的「release 檔在 hold 開始前不存在」preflight 檢查；release 檔由呼叫端建立且 `wait_for_test_hold` 從不刪除它，因此 batch 後續 target 與 recovery 重新進入會改在 release 檔這一關 fail closed——正是 N3 要消除的失敗模式，只是換了個運算元。
- `failure_scenario`: 開啟 hooks 開關並設定 `CASH_INSTALL_HOLD_FILE`，以 `--all` 安裝兩個已註冊 target。target A 的 preflight 通過，hook 建立 ready 檔並等待，harness 建立 release 檔解除等待（既有測試即如此，`test_installer_runtime.py:1771`）。target B 進入 `install_target` 後雖跳過等待與 ready 檔檢查，卻仍在「release 檔在 hold 開始前不存在」失敗，batch 整批中止。
- `recommendation`: 免除範圍由「等待與 ready 檔存在性檢查」擴為「完全跳過該 hook，包含 preflight 的全部 hold 檔存在性檢查（ready 與 release）」，並明示路徑形狀檢查仍逐次執行以免免除範圍過寬。
- `disposition`: `fix-introduced`
- `introduced_by`: `reviews/propose-r2.md` `## Fix Actions` 的「**修 N3（batch 迴圈的 ready 檔）** — design.md D3 第 3 點與 IC3 第 5 條的免除條件由「重新進入時」擴為「同一 process 內任何後續的 `install_target` 呼叫……SHALL 跳過該 hook 的等待與其 ready 檔存在性檢查」」——該擴充只列舉 ready 檔；與 `reviews/propose-r1.md` `## Fix Actions` 的「S4：D3 第 2 點與 IC3 加入 release 檔的 identity 規則」疊加後，release 檔成為未被免除的第二道 per-call preflight 關卡。

### Suggestion（confidence < 80 或 reviewer 分類為 Suggestion，皆非阻斷）

**F2**（confidence 80，`disposition`: `fix-introduced`）D1 為相容性檢查改用存在性判準所給的理由（使 `--target "" --dry-run` 回報值無效）在空值守衛前移後已不可能成立；帶值參數的存在性判準因而完全不可觀察，該 MUST 沒有任何 scenario 能驗收，且留下的因果句會讓實作者誤以為該項修改才是診斷正確的原因、進而低估順序約束。`introduced_by`：round 2 `## Fix Actions` 的「**修 N2（空值守衛的順序不足）** — ……IC1 第 2 條改為「在解析參數之後、且在 `read_registry()` 與 `--dry-run`／`--force` 相容性檢查兩者之前」」。

**F3**（confidence 68，`disposition`: `fix-introduced`）`Hold 協定不安全形狀 fail closed` 的 GIVEN 只有「hooks 開關已開啟」，其 WHEN 含「ready 檔已存在」即要求 fail closed；`後續 installation attempt 不因自身 ready 檔而失敗` 對同一可觀察狀態要求 MUST NOT 失敗。兩者前提可同時成立而 THEN 相反，差別只在未寫入前者 GIVEN 的隱含條件。`introduced_by`：round 2 `## Fix Actions` 的「**修 N3（batch 迴圈的 ready 檔）**……並把 batch 情形寫入 WHEN」，重疊面因此擴大。

**F4**（confidence 58，`layer`: text，`disposition`: `fix-introduced`）tasks.md 以 `**粗體**` 專指 scenario／requirement 名稱，1.1 新增的 `**各自**` 是純強調，使機械比對產生一個 delta 中不存在的幽靈項目；round 2 自檢宣稱該數為 0，實際為 1。`introduced_by`：round 2 `## Fix Actions` 的「**修 N2** — ……tasks.md 1.1 加入三個空字串各自配合 `--dry-run` 的斷言」。

### Reviewer V 明確排除（已檢查、不構成缺陷）

空值守衛前移不破壞既有行為：`--self --dry-run`、`--self --force`、`--list --dry-run`、`--register <p> --force` 逐條驗算結果不變；`--target ""` 兩條路徑同為 exit 2，僅診斷訊息改變，而 `test_installer_runtime.py` 中無測試釘住該訊息（grep `dry-run requires`／`force requires` 皆零命中），master spec 亦未規定其字面。widened batch exemption 不留下不安全 ready 檔破口：本 process 第一次 `install_target` 仍執行完整檢查，後續呼叫連等待一起跳過、不寫入也不開啟該路徑，路徑形狀檢查未被免除。dry-run 診斷走 stderr，與 master `Dry run 與 background-free registry` 的零寫入要求不衝突，且該 master scenario 在 delta 中原文保留。兩個 MODIFIED requirement 的 master 既有 scenario 全數保留（dropped=0），既有段落逐 byte 為 delta 前綴；delta 未攜帶 master 的 `<!-- @trace -->` 區塊不是缺陷，`spec_merge` 在 archive 時會剝除並重新生成。

## Rating

- post-filter cumulative blocking set Critical count: **0**
- post-filter cumulative blocking set Warning count: **1**（F1）
- 非阻斷 triaged finding count: **3**（F2、F3、F4）
- `critical_gap`: **false**
- `round_type`: **micro**

rationale：round 2 的 N1、N2 皆以 verified resolution 離開 cumulative set，N3、N4 亦確認關閉，無成員以 accepted risk 退出、無 grader-protection 保留。本輪新增 4 個缺陷全數 `disposition: fix-introduced`，且缺陷密度較上一輪下降（round 2 為 2 blocking + 2 非阻斷，本輪為 1 blocking + 3 非阻斷），顯示收斂中。F1 是 N3 修正的殘留半邊——round 2 只把 ready 檔納入免除，卻遺漏了同一 hook 的第二個 preflight 運算元 release 檔，而 release 檔恰恰是永不被刪除的那一個，因此 batch 的第二個 target 仍會失敗。這正是 review-fix-propagation-incomplete 的典型形狀：修正涵蓋了被舉例的那個運算元，而非該規則涉及的全部運算元。F1 經 confidence filter 後維持 Warning 且 disposition 為 blocking，因此本輪不能 pass。

## Fix Actions

唯一的 blocking 成員（F1）與三個非阻斷 triage 項（F2、F3、F4）皆已修復，無 grader-protection 保留項，無 accepted-risks 條目。修改檔案共 4 個：`proposal.md`、`design.md`、`tasks.md`、`specs/cash-cli/spec.md`。

**修 F1（release 檔未納入免除範圍）** — design.md D3 第 3 點的免除句改為「完全跳過該 hook，包含其 preflight 的**全部** hold 檔存在性檢查」，並補上一段說明為何必須同時涵蓋 ready 與 release（release 檔由呼叫端建立且 `wait_for_test_hold` 從不刪除它，只免除 ready 檔會使缺陷換個運算元重現），同時明訂路徑形狀檢查不在免除範圍內；IC3 第 5 條同步改寫；specs/cash-cli/spec.md 的 requirement 句改為「MUST完全跳過該hook，包含其等待與preflight的全部hold檔存在性檢查；ready檔與release檔皆在免除範圍內……路徑形狀檢查 MUST NOT被免除」；scenario 更名為 `後續 installation attempt 不因自身 hold 檔而失敗` 並把 release 檔寫入 AND 子句；IC5 的 IC3 bullet 同步；tasks.md 1.3、2.3 各自加入 ready 與 release 雙運算元的免除與「路徑形狀檢查仍逐次執行」的驗收。

**修 F2（不可觀察的 MUST 與誤導的因果句）** — design.md D1 末段拆為兩段：前段明寫空值守衛既已前移，帶值參數改用存在性判準在該點與真值判斷等價、不改變任何可觀察行為，並改述保留它的真正理由是消除判準漂移；後段保留唯一有可觀察後果的部分（布林 flag 維持真值判斷及其具體回歸）。

**修 F3（兩個 scenario 前提重疊而 THEN 相反）** — specs/cash-cli/spec.md 的 `#### Scenario: Hold 協定不安全形狀 fail closed` GIVEN 加上排除子句「且該hold hook在本次process尚未等待過」，使其與 `後續 installation attempt 不因自身 hold 檔而失敗` 的前提互斥。

**修 F4（tasks.md 粗體慣例）** — 移除 1.1 中 `**各自**` 的粗體，恢復「粗體只用於 scenario／requirement 名稱」的慣例。

**修正後的機械自檢與驗證** — 重跑 pre-round mechanical self-check：4 份 artifact 的 comment/annotation 平衡皆為 0/0；兩個 MODIFIED requirement 標題與 master spec 逐 byte 相符；15 個新增 scenario 與 tasks.md 雙向對應無缺漏；tasks.md 中「既非 scenario 也非 requirement」的粗體名稱數已由 1 降為 0；更名後的舊名 `不因自身 ready 檔而失敗` 與 `Hold path 不安全形狀` 在 4 份 artifact 中零殘留；無 lowercase `may`／`should`；無 stray `---` 分隔線。本輪自檢另捕捉到一項 reviewer 未提出的 identifier 漂移：user site 的處置在 proposal `### C`、design Goals 與 D4 第 4 點寫作「隔離」，而 IC4、spec requirement 與 scenario 寫作「停用」；已全部統一為「停用」，現「隔離 user site」的出現次數為 0。因 fix 行動修改了四份 artifact，重跑 `cash validate "harden-installer-mode-and-recovery"` 通過，`cash analyze` 四個維度皆為 0 finding。

**Signal-derived checks** — `openspec/signals/` 下全部 open signal 仍無 `check` frontmatter 欄位，採 best-effort 判斷。本輪最相關者為 `review-fix-propagation-incomplete`：F1 與本輪自檢捕捉的 user site 用語漂移都是同一形狀——修正只覆蓋被舉例的運算元／檔案，未覆蓋該規則涉及的全部運算元／全部出現位置。兩者皆已修並在 tasks 的驗收句中固定下來。

## Decision

next_round

post-filter cumulative blocking set 含 0 個 Critical 與 1 個 Warning（F1），未滿足 pass 條件。round 2 的兩個成員已以 verified resolution 離開集合。F1 與三個非阻斷 triage 項皆已完成 fix 並記錄於 `## Fix Actions`。下一輪為本次執行的第四輪，依規則為 `full` 輪：spawn 兩個 fresh reviewer（Reviewer A — Adherence、Reviewer B — Quality）平行執行完整重掃，並對 cumulative blocking set 成員 F1 各自給出 resolved/unresolved 判定，任一 `unresolved` 即保留該成員。
