# Cash Apply Review — Round 3

本輪為 seeded re-run 的第一輪（full round）。cumulative blocking set 由前一個 run 的 Abort triage bucket 1 種子化，僅含一名 member：

> **M1** — 受管 guidance 的 `--init-receipt` 入口條件未區分「診斷僅指名該 stable record」與「訊息同時指名 `runtime`／`skill` record drift」，且使用者已裁定的收緊決定尚未落地於 `design.md` IC-12、spec delta 的 `Target-local receipt 初始化` requirement、`AGENTS.md`／`CLAUDE.md` 受管區塊、`scripts/cash-skills/tests/skill-checks.fish` 與 guidance baseline。

## Reviewer Findings

### M1 的 resolved／unresolved 判定

兩位 reviewer 皆回傳 `resolved`，且各自獨立重算而非採信 diff。共同證據：`design.md` IC-12 第四款與 IC-13 的「四件事」；spec delta guidance 段的新款與新增的 `#### Scenario: 前提不成立的診斷不被指引為重新簽發`（三條 THEN 與該款一一對應）；`AGENTS.md` 與 `CLAUDE.md` 的第四個 bullet 且兩份受管區塊逐 byte 相同、digest 為 `5f4b9f4b94bd39a7e262a1e12dea901bcd35c10fc2c32d925c39e00515b193bc` 並與 `skill-checks.fish` 釘死值相符；四條 literal 斷言與 cross-file premise parity 斷言皆存在且可滿足；`tasks.md` 4.1／4.4 的新驗收條款。兩位另各自以兩個 gate 的**實際**第三支訊息做封閉性測試：訊息逐字含 `runtime record drift:` 或 `skill record drift:`，受管區塊據此導向還原或重新安裝；不含這兩個子字串的裸 identity drift 訊息仍走初始化入口，兩個分支乾淨分離。Reviewer B 另確認不存在新的子字串風險——stable path 是固定 literal，裸訊息不可能意外含有 `runtime record drift:`。M1 依「verified resolution」離開 cumulative blocking set。

### Critical

（無）

### Warning

（無；下列 reviewer 原始 Warning 經 confidence filter 後全數降級為 Suggestion）

### Suggestion

- `severity`: Suggestion（原始 Warning，confidence 75 落在 `[50, 80)` 而降級） / `confidence`: 75 / `layer`: design / `disposition`: `unresolved-prior` / `location`: `openspec/changes/tolerate-remount-device-renumbering/implementation-notes.md` / `summary`: 檔案仍有兩筆 `類別：open-question` 且沒有任何條目記錄它們已關閉。`19:22` 條目陳述的是前瞻性承諾而非既成事實，而該承諾已全數兌現；archive 後的讀者會看到一個最後狀態仍為「兩個未決問題」的 change，與已交付的 artifacts 矛盾 / `recommendation`: 以該檔既有的收尾模式追加一筆條目，指名六個可驗證的落地點，不改寫既有兩筆 / 來源：Reviewer A（Warning）
- `severity`: Suggestion（原始 Warning，confidence 70 落在 `[50, 80)` 而降級） / `confidence`: 70 / `layer`: design / `disposition`: `new` / `introduced_by`: 本次 diff 對 `report_version_controlled_receipt` 的字串修改，以及 spec delta 為 `#### Scenario: 已納入版控的 receipt 只回報不修改` 新增的 `- **AND** 該diagnostic以inode而非device描述fail-closed的成因`（master 無此條） / `location`: `scripts/cash-skills/tests/test_installer_runtime.py` 的 `test_version_controlled_receipt_is_reported_without_index_changes` / `summary`: 唯一觸及該 diagnostic 的測試沒有釘住 inode-only 措辭；把 `device` 加回該字串仍會全綠，卻直接違反 IC-9 與新增的 spec THEN。task 2.3 的驗收是人工目視，IC-15 的 13 列對照表不涵蓋該 scenario（它屬 MODIFIED 的 `Target 版控排除保護`） / `recommendation`: 補 `assertIn("target-specific inode identity", …)` 與 `assertNotIn("device", …)` / 來源：Reviewer B（第 1 筆）
- `severity`: Suggestion（原始 Warning，confidence 55 落在 `[50, 80)` 而降級） / `confidence`: 55 / `layer`: design / `disposition`: `new` / `introduced_by`: 本次 diff 把單一 identity drift raise 拆為三支訊息時，只給其中兩支 `in {target}` / `location`: `.cash-skills/lib/cash_cli/installer.py` 的 content drift raise / `summary`: D3 與 IC-8 主張 installer 診斷必須由散文指名 target（使用者 cwd 是 source repo，`--target`／`--vendor` 印為不帶前綴的 `Error: <message>`），兩支可行動訊息都遵守，content drift 訊息沒有；而 `.cash-workspace.lock` 在 source repo 也存在，新部署的 guidance 對該字串規定的處置是「還原該筆 record 或從可信 source 重新安裝」，讀者可能誤套到錯的專案 / `recommendation`: 改為 `stable receipt content drift: {path} in {target}` 並在 IC-8 記錄 / 來源：Reviewer B（第 2 筆）
- `severity`: Suggestion / `confidence`: 55 / `layer`: design / `disposition`: `fix-introduced` / `location`: `scripts/cash-skills/tests/skill-checks.fish` 的第四條 literal / `summary`: IC-12 第四款與新 scenario 各有兩個規範半段——(a) 入口只在診斷僅指名該 stable record 時適用、(b) 診斷同時指名其他 record drift 時 MUST 導向還原或重裝且 MUST NOT 重新簽發。新 literal 只釘住 (a)，bullet 的第二句完全未被釘死；依 task 4.4 建立的獨立性模型，刪掉第二句並重算 baseline 後套件仍會全綠 / `recommendation`: 延伸該 literal 或補第五條涵蓋 (b)；IC-13 的「四件事各補一條」是下限而非上限 / 來源：Reviewer A（Suggestion）
- `severity`: Suggestion / `confidence`: 50 / `layer`: design / `disposition`: `fix-introduced` / `location`: `AGENTS.md`／`CLAUDE.md` 受管區塊的 bullet 2 與 bullet 4 / `summary`: bullet 2 仍以無條件形式陳述入口，而前提不成立的第三支訊息字面上滿足 bullet 2 的條件；只有三個 bullet 之後的 bullet 4 收回它，bullet 2 沒有前向指涉。讀到第一個符合就停的讀者仍會走到 `--init-receipt`。IC-12 明文要求第四款是**獨立**一項，因此契約已滿足，此為措辭強化 / `recommendation`: 在 bullet 2 補一句指向下方限定，或把「僅」限定折進 bullet 2 的條件；兩者都需重算 guidance baseline / 來源：Reviewer B（第 3 筆）
- `severity`: Suggestion / `confidence`: 50 / `layer`: design / `disposition`: `unresolved-prior` / `location`: `CASH-INIT-RECEIPT.md` 的 `--init-receipt 適用於` 清單 / `summary`: 清單前三條把取得方式陳述為重新簽發的理由，收尾句才說取得方式不構成理由，兩者互相抵銷。Reviewer B 在 r2 以 confidence 45 提出而被捨棄，r2 的 `## Fix Actions` 記載「將隨 bucket 1 一併處理」，但本輪未觸及該檔，propagation 未完成 / `recommendation`: 把前提句移到清單之前，或把前三條改寫為症狀而非理由 / 來源：Reviewer B（第 4 筆）
- `severity`: Suggestion / `confidence`: 50 / `layer`: text / `disposition`: `new`（機制早於本次變更） / `location`: `CASH-INIT-RECEIPT.md` 的信任模式表格 / `summary`: 表頭三格但分隔列只有兩格，依 GFM 規則整個表格（含本次變更寫入 identity drift 入口的那一列）不會被算繪為表格 / `recommendation`: 補第三個 `| --- |` / 來源：Reviewer B（第 5 筆）
- `severity`: Suggestion / `confidence`: 50 / `layer`: design / `disposition`: `new`（機制早於本次變更） / `location`: `.cash-skills/lib/cash_cli/installer.py` 的 `receipt path mismatch` 檢查 / `summary`: reviewer 確認 r2 Fix Action 3 的 `drifted` 重構完整保留 `conflicts` 累積語意，但被它保護的那個出口其實不可達——`parse_receipt` 以相同的 `records` tuple 先行檢查 `row[1] != expected.path` 並丟出 `receipt record order or shape is invalid`。重構本身行為等價且無害，但其宣稱的效益是空的 / `recommendation`: 不改程式碼；在 round file 記錄該出口為 dead，避免未來以它為 exit-ordering 的先例 / 來源：Reviewer B（第 6 筆）
- `severity`: Suggestion / `confidence`: 50 / `layer`: design / `disposition`: `unresolved-prior` / `location`: `.cash-skills/bin/cash` 的 `sha256_file` 預設 `error_code` / `summary`: receipt gate 內 `bootstrap_invalid` 是繞過 IC-4 前提閘門的那個值卻被設為預設；已在 `apply-r1.md` 與 `apply-r2.md` bucket 2 兩度 triage，此處僅為保持可見度而重報 / `recommendation`: 留給後續 change，與 `apply-r1.md` 記錄的 stable 呼叫點併看 / 來源：Reviewer A（Suggestion）與 Reviewer B（verified-clean 段的重報聲明）

## Rating

- post-filter cumulative blocking set Critical count：0
- post-filter cumulative blocking set Warning count：0
- 非 blocking triaged finding 數：9
- `critical_gap`：false
- `round_type`：full
- rationale：seeded re-run 的第一輪依規則以 seeded cumulative blocking set 作為 pass 判準。唯一的 member M1 由兩位 reviewer 各自回傳 `resolved` 且證據獨立重算，依「verified resolution」離開 blocking set。兩位共提出 11 筆原始 findings（Reviewer A 1 Warning + 2 Suggestion，Reviewer B 2 Warning + 6 Suggestion），依 `location + summary` 合併後為 9 筆。套用 confidence filter：無任何 finding 的 confidence 達到 `≥ 80`，因此三筆原始 Warning（75／70／55）全部降級為 `Suggestion`，`< 50` 的兩筆捨棄。post-filter cumulative blocking set 為空，pass 條件成立。所有 `unresolved-prior` 與 `fix-introduced` disposition 的 finding 都因降級為 `Suggestion` 而不再是 surviving Critical／Warning，依規則不構成 blocking。

## Fix Actions

本輪 pass，不存在必須修復的 blocking finding。以下五筆非 blocking Suggestion 屬「純文件或純測試、零 runtime 風險，且修正即可完全落回既有契約條款」的類型，已一併修復並重驗；其餘四筆的處置與全部降級追跡列於其後。本輪刻意不改動任何 runtime 程式碼，使通過本輪的實作與兩位 reviewer 實際審查的狀態逐 byte 相同。

1. **`implementation-notes.md` 的收尾條目**（Reviewer A Warning）。修改檔案：`openspec/changes/tolerate-remount-device-renumbering/implementation-notes.md`（追加一筆 `類別：open-question` 收尾條目，指名六個落地點與兩個 gate 的封閉性驗證方式；既有兩筆條目未刪改）。
2. **第四款規範半段的釘死**（Reviewer A Suggestion）。修改檔案：`scripts/cash-skills/tests/skill-checks.fish`（追加第五條 literal `MUST 改為把該筆 record 還原成 receipt 記錄的內容或從可信 source 重新安裝，MUST NOT 重新簽發`，使 bullet 第二句無法在重算 baseline 後被靜默刪除）。
3. **version-control diagnostic 的機械守衛**（Reviewer B 第 1 筆）。修改檔案：`scripts/cash-skills/tests/test_installer_runtime.py`（`test_version_controlled_receipt_is_reported_without_index_changes` 補 `assertIn("target-specific inode identity", result.stderr)` 與 `assertNotIn("device", result.stderr)`），使 IC-9 與新增 spec THEN 由人工目視轉為機械可驗。
4. **`CASH-INIT-RECEIPT.md` 前提句的位置**（Reviewer B 第 4 筆，r2 記載應隨 bucket 1 一併處理但未執行）。修改檔案：`CASH-INIT-RECEIPT.md`（把版控前提由清單尾端的 bullet 移到清單之前作為前置條件句，使逐條閱讀者不會在讀到限定之前先取得無條件許可；前三條既有 bullet 逐字保留未改寫）。
5. **信任模式表格的分隔列**（Reviewer B 第 5 筆）。修改檔案：`CASH-INIT-RECEIPT.md`（補第三個 `| --- |`，使含本次新增 identity drift 入口的表格正確算繪）。

**Fix propagation**：本輪 fix 未觸及 `AGENTS.md`／`CLAUDE.md` 受管區塊，重算後 guidance baseline 仍為 `5f4b9f4b94bd39a7e262a1e12dea901bcd35c10fc2c32d925c39e00515b193bc`，`skill-checks.fish` 的釘死值不需變更。亦未觸及任何 bundle inventory 檔（stable、runtime 或 24 個 skills），因此 `.cash-skills/manifest.tsv` 不需重新發佈——以 `./install-cash-skills.fish --self --dry-run` 確認回報 `Result: current`。

**Fix 後的 pre-round mechanical self-check**：spec delta 的 `<!--`／`-->` 計數皆為 0 且無殘留 `---`；ADDED requirement 的 scenario 數 13 與 IC-15 對照表資料列數 13 相符；`design.md` 與 `tasks.md` 的「四件事」敘述一致；`tasks.md` 15 項全 `[x]`；canonical 版控前提 fragment 在兩個 gate 檔案各自完整落於單一原始碼行；launcher digest 與 transition 兩筆新 entry 及 manifest 三者相符，`installer.py` 實際 digest 等於 manifest 記載值；`cash-skills.version`、`BUNDLE_VERSION` 與 manifest `bundle_version` 皆為 `2.13.0`；spec delta 三個 MODIFIED requirement 標題逐 byte 存在於 master spec；`AGENTS.md` 與 `CLAUDE.md` 受管區塊逐 byte 相同。

**Fix 後重驗**：`fish scripts/cash-skills/tests/skill-checks.fish`（135 tests OK + bundle version history 10 tests OK + namespace scan PASS）、`fish scripts/cash-cli/tests/cli-checks.fish`（145 tests OK）、`.cash-skills/bin/cash validate --all`、`./install-cash-skills.fish --self --dry-run`（`current`）、`git diff --check` 皆通過。此處一併補上 Reviewer B 執行環境所缺的 green-run 確認：Reviewer B 因 sandbox 限制無法執行測試，並指名其第 1、6、8 筆需要 green-run 佐證；上述重跑涵蓋之。

**Signal-derived checks**：`openspec/signals/` 下沒有任何 signal 帶 `check` frontmatter 欄位，逐 signal 執行的分支不適用，改走既有 best-effort 判斷；相關 issue class 已納入兩位 reviewer 的 context。

**未修復的非 blocking triage note（Reviewer B 第 2 筆，content drift 訊息未指名 target）**：不修復。它需要改動 `.cash-skills/lib/cash_cli/installer.py` 的 runtime 程式碼並連帶重新發佈 manifest，而本輪的處置原則是不讓通過本輪的實作偏離 reviewer 實際審查的狀態。IC-8 只釘死該訊息的分類前綴與「MUST NOT 包含 `--init-receipt`」，未釘死其完整形式，因此這是契約留白而非 adherence 違反。列為後續 change 的候選。

**未修復的非 blocking triage note（Reviewer B 第 3 筆，bullet 2 缺前向指涉）**：不修復。IC-12 明文要求第四款為**獨立**一項，現行寫法已滿足契約；改寫 bullet 2 需要重算 guidance baseline，屬措辭強化而非契約落差。列為後續 change 的候選。

**未修復的非 blocking triage note（Reviewer B 第 6 筆，`receipt path mismatch` 為 dead exit）**：不改程式碼，依 reviewer 建議在本檔記錄。`parse_receipt` 以相同的 `records` tuple 先行檢查 `row[1] != expected.path`，因此 `validate_installed_receipt` 內的同名檢查不可達；r2 Fix Action 3 的重構行為等價且無害，但**不得**被未來的 round 引為 exit-ordering 的先例。

**未修復的非 blocking triage note（Reviewer A Suggestion 與 Reviewer B 重報聲明，`sha256_file` 預設 error code）**：不修復，理由同 `apply-r1.md` 與 `apply-r2.md`：IC-4 明文把 error code 例外限定在 receipt gate 內對 runtime records 取 digest 的呼叫點，且改動會再次變更 launcher bytes 與其 digest。維持在 bucket 2，列為後續 change 的候選。

**Confidence 降級追跡**：
- Reviewer A Warning（`implementation-notes.md` 未記錄關閉）：confidence 75，落在 `[50, 80)`，降級為 `Suggestion`。其 `disposition` 為 `unresolved-prior`，但降級後已非 surviving Critical／Warning，依規則不構成 blocking。
- Reviewer B 第 1 筆（version-control diagnostic 缺機械守衛）：confidence 70，落在 `[50, 80)`，降級為 `Suggestion`。`introduced_by` 指向本次 diff 的字串修改與新增的 spec THEN，證據可驗證，不適用 introduced-by 降級。
- Reviewer B 第 2 筆（content drift 訊息未指名 target）：confidence 55，落在 `[50, 80)`，降級為 `Suggestion`。`introduced_by` 指向本次 diff 拆分三支訊息時的不對稱，證據可驗證。
- Reviewer A Suggestion、Reviewer B 第 3、4、5、6 筆：reviewer 原始即為 `Suggestion`，confidence 皆 50–55，維持 `Suggestion`。
- Reviewer B 第 7 筆（`test_installer_identity_guidance_states_the_version_control_premise` 的 tuple 提前求值使兩個 subTest 與 fixture 順序耦合）：confidence 40，低於 `50`，依 confidence filter 捨棄。reviewer 自述今日不 vacuous，回歸仍會失敗，只是失敗訊息會指向錯的 gate。
- Reviewer B 第 8 筆（poll 迴圈先判 `child.poll()` 後判 `ready.exists()`；deadline 路徑先 `communicate` 才進 `finally` 回收）：confidence 40，低於 `50`，依 confidence filter 捨棄。reviewer 自述兩者皆有界、皆非 false green，IC-15 的 `MUST NOT 留下 child process` 仍滿足。

**裁判面保護**：本輪無 `未修復：裁判面保護` 記錄。本 change 修改的 `scripts/cash-skills/tests/skill-checks.fish` 是 protected grader path，但其 project-root-relative 路徑同時出現在 proposal `## Impact` 的 affected-code 條目與 `tasks.md` 4.4 的交付目標，屬 structured scope declaration 的明示例外。

**M1 的 verified-resolution 移除記錄**：member M1；fix reference 為 `/cash-ingest` 對 `design.md` IC-12／IC-13 與 spec delta 的修改，加上 apply 對 `AGENTS.md`／`CLAUDE.md`、`skill-checks.fish` 與 guidance baseline 的修改；verifying reviewer 為本輪的 Reviewer A 與 Reviewer B，兩者皆回傳 `resolved`。

## Decision

passed
