# Cash Propose Review — Round 2

## Reviewer Findings

本輪為 micro 輪，由單一 Reviewer V — Verification 對 cumulative blocking set 做 delta 驗證並檢查 fix propagation。

### Cumulative blocking set 逐項判定（Reviewer V）

Reviewer V 對 round 1 的 8 個 blocking 成員全數給出 `resolved`：

| member | verdict | 驗證依據摘要 |
| --- | --- | --- |
| C1 | resolved | design D1 新增專段與 IC1 第 2 條要求空值拒絕早於 `read_registry()`；spec 加入診斷優先序條款與 `#### Scenario: 空字串 mode 參數的診斷優先於 registry 錯誤`；tasks 1.1 以不合法 registry 把「未讀取 registry」變成可觀察條件 |
| C2 | resolved | IC1 第 3 條明訂 `exit_code=2` 且禁止改動兩個既有守衛；核對 `installer.py:55` 預設值與 master spec `spec.md:687` 錯誤契約；tasks 1.1 已收緊為確切 exit 2；另核對 master spec `Target 與 HOME boundary fail closed` 未指定 exit code，新守衛不與其衝突 |
| W1 | resolved | 泛用優先順序在 design D4／IC4／Risks、spec requirement、兩個 interpreter scenario、tasks 3.1、proposal 共七處一致；新增 `#### Scenario: 泛用名稱合格時選擇結果不改變` 且有 backing task |
| W2 | resolved | 核對 `acquire_lock`（`installer.py:766-775`）以 `O_CREAT|O_EXCL` 建立 workspace lock 確為首次 target write；驗證前移至 preflight 後，scenario 的「首次 target write 前」THEN 可成立；tasks 1.3 加入 fresh target 斷言 |
| W3 | resolved | D3、IC3、spec requirement 與新 scenario 一致定義 at-most-once；另核對兩個既有 hold 測試（`test_installer_runtime.py:1576`、`:1732`）在 at-most-once 與 exclusive ready 建立之下皆維持通過 |
| W4 | resolved | IC1 第 5 條限定存在性判準只套用於帶值參數；以 `installer.py:1580-1587` 逐條驗算 `--list --dry-run` 仍 raise exit 2；新增 `#### Scenario: Boolean mode flag 的相容性守衛不受影響` |
| W5 | resolved | fixture 規格與 `_journal()`（`installer.py:897-935`）產出的欄位、`recover_installer`（`installer.py:1105-1113`）的 schema 驗證逐項相符，TDD 第一步可執行 |
| W6 | resolved | proposal `## Proposed Solution` 第 3 點已改為 identity 約束並明確排除 containment，`containment` 字樣移除，與 design D3、spec requirement 一致 |

依 cumulative set 規則，8 個成員皆以「verified resolution」離開集合（fix 已記錄於 `reviews/propose-r1.md` 的 `## Fix Actions`，由本輪 Reviewer V 確認且未再被 re-report）。

### Fix propagation 檢查結果（Reviewer V）

interpreter 候選順序七處一致；scenario 更名無殘留（舊名 `Hold path 不安全形狀 fail closed` 僅出現在 `reviews/propose-r1.md` 的歷史紀錄）；15 個新增 scenario 與 tasks.md 互為子集無缺漏；兩個 MODIFIED requirement 的 master 既有 scenario 全數保留、標題逐字相符。IC5 列舉有兩處未達「一一對應」的宣稱（見 N4）。

### Warning

**N1**
- `severity`: Warning
- `confidence`: 92
- `layer`: design
- `location`: proposal.md `## Proposed Solution` 第 1 點
- `summary`: proposal 第 1 點仍描述被 C1／C2／W4 推翻的舊機制（「使空字串進入既有的空值守衛」、「`--dry-run` 與 `--force` 的前置相容性檢查一併改為同一判準」），與 design D1／IC1 現行條款直接矛盾。
- `recommendation`: 改寫第 1 點為：新增專屬空值守衛以 exit 2 失敗、順序早於 registry 讀取與相容性檢查、既有守衛退出碼不動、存在性判準只套用於帶值參數。
- `disposition`: `fix-introduced`
- `introduced_by`: `reviews/propose-r1.md` `## Fix Actions` 的「**修 C1（registry 讀取順序）**」「**修 C2（退出碼）**」「**修 W4（布林 flag 判準）**」三項——其所列修改檔案皆為 `design.md`／`specs/cash-cli/spec.md`／`tasks.md`，未含 `proposal.md`（該輪只有「修 W1」與「修 W6」動到 proposal），修正前 proposal 與 design 對此機制一致，修正後才發散。

**N2**
- `severity`: Warning
- `confidence`: 88
- `layer`: design
- `location`: specs/cash-cli/spec.md `### Requirement: Installer 與 legacy cleanup filesystem boundaries` 與 `#### Scenario: 空字串 mode 參數的 dry-run 診斷`；design.md `### IC1`；`.cash-skills/lib/cash_cli/installer.py:1580-1587`
- `summary`: W4 修正後 `--dry-run` 守衛的運算元恢復為只有 `--target`／`--all`／`--self`，因此 `--register "" --dry-run` 與 `--unregister "" --dry-run` 會先命中「`--dry-run` requires `--target`, `--all`, or `--self`」而回報「缺少 mode 參數」，直接違反該 scenario 的 `MUST NOT指出缺少mode參數`；IC1 只把空值守衛排在 `read_registry()` 之前，未排在相容性檢查之前。
- `recommendation`: IC1 補上順序約束——空值拒絕 SHALL 同時早於 `read_registry()` 與 `--dry-run`／`--force` 相容性檢查；spec requirement 的因果句相應改寫；scenario 明確涵蓋三個 mode 參數各自的情形。
- `disposition`: `fix-introduced`
- `introduced_by`: `reviews/propose-r1.md` `## Fix Actions` 的「**修 W4（布林 flag 判準）** — …IC1 明訂存在性判準只套用於帶值參數」。round 1 原本「整條改用同一存在性判準」會使該守衛恆不觸發，`--register "" --dry-run` 反而會落到空值守衛；改為布林 flag 維持真值判斷後，守衛重新生效並遮蔽了 register／unregister 的空值診斷。

### Suggestion（confidence ∈ [50, 80)，經 filter 降級後非阻斷）

**N3**（confidence 58，`disposition`: `fix-introduced`）at-most-once 的免除條件只寫「重新進入時」，但 `--all` batch 迴圈對每個 registered project 各呼叫一次 `install_target`，第二個 target 的 preflight 會看到第一個 target 留下的 ready 檔而落入「ready 檔已存在」分支，把 batch 下的 hooks 由現行可運作變成 fail closed。`introduced_by`：round 1 `## Fix Actions` 的「**修 W2（hook 驗證時機）**」與「**修 W3（hold 重入語意）**」之組合——ready-exists 檢查前移到每次 `install_target` 的 preflight，與 per-process at-most-once 併用才產生 batch 破口。

**N4**（confidence 62，`disposition`: `fix-introduced`）IC5 宣稱「與新增 scenario 一一對應」，但 IC1 bullet 未列入以不合法 registry 驗證診斷優先序的觀察手段，IC3 bullet 的 release 檔形狀漏掉「release 檔在 hold 開始前已存在」。`introduced_by`：round 1 `## Fix Actions` 的「S3：IC5 改寫為與 IC1–IC4 及全部新增 scenario 一一對應的完整列舉」，改寫後仍有兩處未達該宣稱。

### Reviewer V 明確排除（已檢查、不構成缺陷）

dry-run 的未完成 journal diagnostic 走 stderr，非 target 或 persistent write，與 master spec 零寫入契約及 `Dry run 與 background-free registry` 不衝突；新的 `exit_code=2` 守衛與 master spec 既有 scenario 無衝突；泛用優先的 interpreter 順序未削弱 proposal `### C` 陳述的動機；兩個既有 hold 測試在新語意下維持通過。

## Rating

- post-filter cumulative blocking set Critical count: **0**
- post-filter cumulative blocking set Warning count: **2**（N1、N2）
- 非阻斷 triaged finding count: **2**（N3、N4）
- `critical_gap`: **false**
- `round_type`: **micro**

rationale：round 1 的 8 個 blocking 成員全部由 Reviewer V 以 verified resolution 判定 `resolved` 並離開 cumulative set，無成員以 accepted risk 退出、無 grader-protection 保留。本輪新增的 4 個缺陷全數 `disposition: fix-introduced`——這正是 micro 輪的設計目的：round 1 一次修改 4 份 artifact、觸及 8 個 blocking 成員，修正本身成為新缺陷的來源。其中 N1、N2 經 confidence filter 後維持 Warning 且 disposition 為 blocking，因此進入 cumulative blocking set，本輪不能 pass。N2 特別值得記錄：它是 W4 修正的直接副作用，若無本輪的 delta 驗證，實作階段會產出一個滿足 IC1 卻違反自身 scenario 的 `run()`。N3、N4 confidence 落在 [50, 80) 而降級為 Suggestion，非阻斷，但本輪一併修正。

## Fix Actions

兩個 blocking 成員（N1、N2）與兩個非阻斷 triage 項（N3、N4）皆已修復，無 grader-protection 保留項，無 accepted-risks 條目。修改檔案共 4 個：`proposal.md`、`design.md`、`tasks.md`、`specs/cash-cli/spec.md`。

**修 N1（proposal 與 design 機制矛盾）** — proposal.md `## Proposed Solution` 第 1 點整段改寫：mode 分派改用存在性判準；在解析參數之後、任何其他檢查之前新增專屬空值守衛並以 caller-input error（exit 2）失敗；明寫該守衛必須早於 registry 讀取與相容性檢查及其理由；明寫既有的 `target must be a safe existing directory` 與 `project path is invalid` 守衛退出碼不動；明寫相容性檢查只對帶值參數改用存在性判準、`store_true` 布林 flag 維持真值判斷。

**修 N2（空值守衛的順序不足）** — design.md D1 的「空值拒絕必須早於 `read_registry()`」段落改寫為「空值拒絕必須是解析後的第一道檢查」，以兩個 bullet 分別列出 registry 讀取與相容性檢查兩個遮蔽關卡，並具名 `--register "" --dry-run` 會命中的訊息；IC1 第 2 條改為「在解析參數之後、且在 `read_registry()` 與 `--dry-run`／`--force` 相容性檢查兩者之前」；specs/cash-cli/spec.md 的 requirement 段落改為「該空值拒絕 MUST早於registry的讀取，也 MUST早於與mode相依的`--dry-run`及`--force`相容性檢查」並把 dry-run 診斷規定併入該句；`#### Scenario: 空字串 mode 參數的 dry-run 診斷` 改為明確涵蓋三個 mode 參數各自的情形，並加上「即使該mode參數不在相容性檢查的運算元之列」的 AND 子句；tasks.md 1.1 加入三個空字串各自配合 `--dry-run` 的斷言並註明該案例即為順序的觀察點，2.1 加入同一順序指示與理由。

**修 N3（batch 迴圈的 ready 檔）** — design.md D3 第 3 點與 IC3 第 5 條的免除條件由「重新進入時」擴為「同一 process 內任何後續的 `install_target` 呼叫——包含重新分類造成的重新進入，以及 `--all` batch 迴圈的後續 target——SHALL 跳過該 hook 的等待與其 ready 檔存在性檢查」；spec requirement 同步改寫；`#### Scenario: 重新進入不因自身 ready 檔而失敗` 更名為 `#### Scenario: 後續 installation attempt 不因自身 ready 檔而失敗` 並把 batch 情形寫入 WHEN；tasks.md 1.3、2.3 同步涵蓋 batch 後續 target。

**修 N4（IC5 列舉未達一一對應）** — design.md IC5 的 IC1 bullet 補入「以刻意不合法的 registry 驗證空字串的 diagnostic 優先於 registry／HOME 錯誤」與「三個空字串各自配合 `--dry-run`」；IC3 bullet 的 release 檔形狀補入「release 檔在 hold 開始前已存在」，與 scenario 及 tasks 1.3 對齊。

**修正後的機械自檢與驗證** — 重跑 pre-round mechanical self-check：4 份 artifact 的 comment/annotation 平衡皆為 0/0；兩個 MODIFIED requirement 標題與 master spec 逐 byte 相符；15 個新增 scenario 與 tasks.md 雙向對應無缺漏（scenario 未被 tasks 提及者為 0，tasks 引用而 delta 不存在者為 0）；更名後的 scenario 舊名 `Hold path 不安全形狀` 與 `重新進入不因自身 ready 檔而失敗` 在 4 份 artifact 中皆無殘留；interpreter 候選順序在 design、tasks、spec 三處以程式比對確認皆為泛用優先、無版本化優先殘留；無 lowercase `may`／`should`；無 stray `---` 分隔線。因 fix 行動修改了 proposal、design、tasks 與 spec artifacts，重跑 `cash validate "harden-installer-mode-and-recovery"` 通過，`cash analyze` 四個維度皆為 0 finding。

**Signal-derived checks** — `openspec/signals/` 下全部 open signal 仍無 `check` frontmatter 欄位，採 best-effort 判斷。本輪特別相關者：`specific-rule-shadowed-by-catch-all` 正是 N2 的類型（具體的空值錯誤被較泛用的「缺少 mode 參數」守衛遮蔽），已修；`review-fix-propagation-incomplete` 對應 N1、N4（round 1 的 fix 未傳播到 proposal 與 IC5），已修；`loop-edge-state-undefined` 對應 N3（batch 迴圈的 hook 邊界狀態未定義），已修。

## Decision

next_round

post-filter cumulative blocking set 含 0 個 Critical 與 2 個 Warning（N1、N2），未滿足 pass 條件。round 1 的 8 個成員已全部以 verified resolution 離開集合。本輪 2 個 blocking 成員與 2 個非阻斷 triage 項皆已完成 fix 並記錄於 `## Fix Actions`。下一輪依位置推導為本次執行的第三輪，非第四輪，故仍為 `micro` 輪，由單一 Reviewer V 對 N1、N2 逐一給出 resolved/unresolved 判定，並檢查本輪 fix 是否再引入新缺陷。
