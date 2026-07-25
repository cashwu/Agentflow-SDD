# Cash Propose Review — Round 6

## Reviewer Findings

本輪為 micro 輪，亦為 6 輪上限的最後一輪。由單一 Reviewer V — Verification 對 cumulative blocking set 做 delta 驗證，並經明確指示以 artifact 現況與源碼為準、不採信前一輪 `## Fix Actions` 的記述。

### Cumulative blocking set 逐項判定

| member | verdict | 依據摘要 |
| --- | --- | --- |
| V1（Critical） | **resolved** | 偵測與恢復確已分離：design D2 第 1／2 步、IC2 前三條、delta spec normative 段、新 scenario `Newer target 帶未完成 journal 仍零寫入`、proposal 第 2 點、tasks 1.2／2.2 全部到位。Reviewer V 另對源碼確認：把恢復點放在 `installer.py:1200` 的 `return "newer"` 之後、`:1202` 之前，是唯一同時滿足「晚於版本比較、早於 conflict 判定」的區間，且 `config_plan`、`render_guidance`、`legacy_candidates`、`installation_inputs` 全落在其後，符合「plan 取自 recovery 之後」——該點是良好定義的單一插入點 |
| G3／V4 | **resolved** | 逐行核對 `test_installer_runtime.py` 確認使用 hook 的測試恰為六個（:394、:868、:1586、:1741、:1839、:1855）；r4 的事實錯誤句已零殘留；:394 與 :868 確實經 `install` helper 的 `TEST_` 轉譯迴圈並已被明確列為 (a) 組並附靜默失效警語 |
| G6 | **resolved** | design IC3 末條與 tasks 2.3 皆已收斂為「實作、測試或使用者文件中作為可生效的 environment variable name」並豁免敘述性引用；殘留字串 `測試、規格或文件` 四份 artifact 皆 0 命中 |
| V5 | **resolved** | proposal `## Non-Goals` 與 design `## Goals / Non-Goals` 逐字相同；design `## Context` 已改寫且不再與其牴觸；`lock 協定` 四份 artifact 0 命中 |

四個成員全部以 verified resolution 離開 cumulative blocking set。round 5 的四個非阻斷項 V2、V3、V6、V7 亦皆判定 resolved，其中 V2 與 fresh-target 安裝路徑不衝突（規則以「該次取鎖」限定，恢復前置階段只在偵測到 journal 時進入，fresh target 無 journal），V3 的單一 descriptor 不變量與四個既有重新進入點相容（兩個 post-lock 在遞迴前即 `os.close` 並置 `None`，兩個 pre-lock 不持有 descriptor）。

### Warning

**F1**
- `severity`: Warning
- `confidence`: 92
- `layer`: text
- `location`: design.md `### IC5`；tasks.md 2.3
- `summary`: 修 G3／V4 後宣稱「六個既有測試…分屬四條注入路徑」，但緊接其後的枚舉只有 (a)(b)(c) 三組（各兩個測試，2+2+2＝6），源碼核對亦只存在三種機制，計數與枚舉自相矛盾。
- `failure_scenario`: 實作者依「分屬四條注入路徑，必須逐一處理，不得只涵蓋其中一部分」執行時只能找到三組；同段提到的第三個 helper `run_installer` 沒有任何 hook 測試使用（它服務 registry 測試）。實作者若相信「四條」，會停在「還有一條沒找到」的狀態，或反向懷疑枚舉不完整而放寬「逐一處理」的要求——正是 G3／V4 原始缺陷的同一形狀。
- `recommendation`: 改為「三條注入路徑」，並把 `run_installer` 改述為「目前無 hook 測試使用但同屬安裝入口、需一併改造的 helper」。
- `disposition`: `fix-introduced`
- `introduced_by`: `reviews/propose-r5.md` `## Fix Actions` 的「**修 G3／V4（測試枚舉事實錯誤）** — tasks 2.3 與 IC5 改為「六個既有測試、四條注入路徑」並逐一列出：(a)…(b)…(c)…」。

**F2**
- `severity`: Warning
- `confidence`: 82
- `layer`: design
- `location`: specs/cash-cli/spec.md `Bundle 安裝與 runtime receipt` 的 recovery normative 段 vs 同檔保留自 master 的 `#### Scenario: Current、newer 與 conflict 分類`；design.md `### IC2`
- `summary`: 恢復被規範為早於 conflict 判定且會寫入 target（rollback），但同一份 delta spec 原文保留的 conflict scenario 仍要求「回報 `Result: conflict`、exit 2 且零寫入」；當 recovery 之後仍存在與該 journal 無關的 drift 時，同一次 invocation 會既寫入又回報 `conflict`，兩條 normative 直接牴觸且無 carve-out。
- `failure_scenario`: target 版本不高於 incoming bundle、留有 `phase: publishing` journal，且另有一個與該 journal 無關的 managed path 被改動。新流程：偵測 → 非 `newer`、非 dry-run → 取既存 lock → recovery 回滾並刪除 journal（已寫入 target）→ 重新進入 → `validate_installed_receipt` 仍收到該 drift → 以 `managed target drift` 回報 `conflict`、exit 2。此時 delta spec 保留的「`conflict` 且零寫入」被違反；IC2 只在「無併發 installer 介入」的 fixture 下要求 `SHALL 為 update`，未涵蓋此情形。
- `recommendation`: 在 recovery 段落補上 carve-out，明確 recovery 造成的 rollback 寫入不受 `current`／`newer`／`conflict` 零寫入契約約束，該契約自 recovery 完成後的重新分類起適用。
- `disposition`: `fix-introduced`
- `introduced_by`: `reviews/propose-r4.md` `## Fix Actions` 的「**修 G2 與 G4（恢復點早於 conflict 判定）**」——該次移動使 recovery 的寫入落在 `conflict` 分類仍可能成立的區間，但四份 artifact 均未同步調整 conflict 的零寫入句。此項在 r1–r5 皆未被提出或 triage。

### Suggestion（confidence < 80，非阻斷）

- **F3**（62，`fix-introduced`）分離偵測與恢復後出現「偵測命中但恢復永不執行、操作者收不到訊號」的狀態：非 dry-run 對 `newer` target 執行時 journal 被偵測到、recovery 被正確跳過，但 diagnostic 被規範為僅 dry-run 發出，使 real run 的資訊少於 dry-run。
- **F4**（55，`fix-introduced`）D2 宣稱 diagnostic 對四種 dry-run 結論都成立，但 tasks 1.2 的驗收只覆蓋三種，`current` 無 backing 斷言。
- **F5**（58，`fix-introduced`）V7 的 `--force` 變體只傳播到 scenario、IC5 與 tasks，requirement 本文的 diagnostic 句仍只寫 `--dry-run`。

## Rating

- post-filter cumulative blocking set Critical count: **0**
- post-filter cumulative blocking set Warning count: **2**（F1、F2）
- 非阻斷 triaged finding count: **3**（F3、F4、F5）
- `critical_gap`: **false**
- `round_type`: **micro**

rationale：round 5 的四個 blocking 成員全部以 verified resolution 離開集合，包含 Critical V1；四個非阻斷項亦全數關閉；本輪未發現任何 Critical 級新缺陷，且 Reviewer V 對源碼確認 r5 針對的四個結構性問題（`newer` 零寫入排除、守衛順序與不建 lock、descriptor 雙分支關閉、單一 descriptor 不變量）均與 `installer.py` 現行控制流相容。缺陷密度續降：r4 為 2 Critical + 6 Warning，r5 為 1 Critical + 3 Warning，本輪為 0 Critical + 2 Warning。但 F1 與 F2 的 disposition 皆為 `fix-introduced`，依規則屬 blocking，post-filter blocking set 非空，因此本輪不能 pass。依 6 輪上限規則，`decision` 為 `aborted`。

值得記錄的是 F2 的性質：它不是本輪 fix 引入的，而是 round 4 移動恢復點時就已存在、卻連續兩輪未被任何 reviewer 提出的既存牴觸。它在最後一輪才浮現，說明「恢復點位置」這條變更線的下游影響面比前幾輪估計的更廣。

## Fix Actions

兩個 blocking 成員（F1、F2）與三個非阻斷項（F3、F4、F5）皆已在本輪完成 fix，無 grader-protection 保留項，無 accepted-risks 條目。修改檔案共 3 個：`design.md`、`tasks.md`、`specs/cash-cli/spec.md`。這些 fix 尚未經任何 reviewer 驗證——依規則它們構成 bucket 1，是 re-run 的前提而非本輪的 pass 依據。

**修 F1（注入路徑計數矛盾）** — design IC5 與 tasks 2.3 的「四條注入路徑」改為「三條注入路徑」；tasks 2.3 的 helper 清單改述為「`install`、`install_from` 兩個實際承載 hook 注入的 helper，以及目前無 hook 測試使用但同屬安裝入口的 `run_installer`」，消除「第四條路徑」的暗示。

**修 F2（recovery 寫入 vs conflict 零寫入契約）** — delta spec 的 recovery normative 段補上 carve-out：「Journal recovery造成的rollback寫入 MUST NOT被視為違反`current`、`newer`或`conflict`分類的零寫入契約：該零寫入契約自recovery完成後的重新分類起適用，因此recovery之後若仍存在與該journal無關的drift，installer MUST回報`Result: conflict`、exit 2，且自重新分類起零寫入」；IC2 增列對應條款；tasks 1.2 加入該情形的斷言。

**修 F3（real run 缺 diagnostic）** — spec 與 IC2 的 diagnostic 條款由「`--dry-run` 遇到未完成 journal 時」擴為「偵測到未完成 journal 時，dry-run 與 real run 皆輸出」，並說明 `newer` target 的 recovery 被排除、操作者必須由該 diagnostic 得知需要版本相符或更新的 installer 才會恢復；`#### Scenario: Newer target 帶未完成 journal 仍零寫入` 補上對應 AND 子句。

**修 F4（`current` 結局無斷言）** — tasks 1.2 的結局清單由 `conflict`、`update`、`newer` 三種擴為四種，補上 `current`，並要求 dry-run 與 real run 皆斷言。

**修 F5（requirement 本文未涵蓋 `--force`）** — delta spec 的 `Installer 與 legacy cleanup filesystem boundaries` requirement 本文由「空字串mode參數與`--dry-run`併用時」改為「與`--dry-run`或`--force`併用時」，與同段既有的順序句對齊。

**修正後的機械自檢與驗證** — 重跑 pre-round mechanical self-check：4 份 artifact 的 comment/annotation 平衡皆為 0/0；兩個 MODIFIED requirement 標題與 master spec 逐 byte 相符；18 個新增 scenario 與 tasks.md 雙向對應無缺漏；ghost bold name 為 0；殘留措辭掃描（`四條`、`測試、規格或文件`、`lock 協定`、`至多執行一次`、`第三個 post-lock`）全數為 0；無 lowercase `may`／`should`。重跑 `cash validate` 通過，`cash analyze` 四個維度皆為 0 finding。

## Decision

aborted

第六輪為 6 輪上限的最後一輪，post-filter cumulative blocking set 仍含 2 個 Warning（F1、F2），未滿足 pass 條件，依規則記錄 `aborted` 並執行 Abort triage。

### Abort triage

**bucket 1 — 仍屬本 change 的義務（seeds a later re-run）**

- **F1**（Warning，`fix-introduced`，`layer`: text）注入路徑計數與枚舉矛盾。已於本輪修復（design IC5、tasks 2.3），但未經 reviewer 驗證。
- **F2**（Warning，`fix-introduced`，`layer`: design）recovery 的 rollback 寫入與保留自 master 的 `conflict` 零寫入 scenario 牴觸。已於本輪修復（delta spec recovery 段 carve-out、IC2、tasks 1.2），但未經 reviewer 驗證。

兩者皆未取得 accepted-risk 同意，因此留在 bucket 1。

**bucket 2 — 新發現且從未 blocking 的問題**

- **F3**、**F4**、**F5** 三項 Suggestion。皆已於本輪修復，且皆不涉及 Critical，因此不需另提 follow-up change proposal。它們會依 signals write step 併入 issue class 記錄。

**bucket 3 — 已接受的取捨**

無。本輪未向使用者徵詢任何 accepted-risk，因此沒有任何 finding 被記入 `accepted-risks.md`。

### Re-run 的具體前提

不建議原封不動重跑。bucket 1 的兩項已在本輪修復，因此 re-run 的前提是**驗證這兩項修復**，而非再次修復：re-run 的第一輪為 full 輪，須以 F1、F2 為 seeded cumulative blocking set，由該輪的兩位 reviewer 各自給出 resolved／unresolved 判定；任一 `unresolved` 即保留該成員。re-run 的輪次編號自 7 起續編，且須帶入本次全部六份 round file（或依規則使用 extract fallback）。
