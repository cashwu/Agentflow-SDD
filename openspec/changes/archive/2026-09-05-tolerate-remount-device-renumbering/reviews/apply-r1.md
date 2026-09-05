# Cash Apply Review — Round 1

## Reviewer Findings

### Critical

（無）

### Warning

（無；下列 reviewer 原始 Warning 經 confidence filter 後全數降級為 Suggestion 或捨棄，詳見 `## Fix Actions` 的降級追跡）

### Suggestion

- `severity`: Suggestion（reviewer 原始為 Warning，confidence 70 落在 `[50, 80)` 而降級） / `confidence`: 70 / `layer`: design / `location`: `AGENTS.md` 與 `CLAUDE.md` 的 `<!-- CASH:START -->` 受管區塊 `## Cash CLI 啟動信任模式` 第二條 / `summary`: 受管 guidance 以字面分類 `stable record identity drift` 作為 `--init-receipt` 的入口條件，而 IC-5／IC-8 前提不成立時的第三支訊息逐字含有同一個子字串，因此以字串比對套用該規則的 agent 會在 IC-4 前提閘門正要擋下的情境執行重新簽發 / `recommendation`: 把該入口限定為「診斷只指名該 stable record」的形態，並補上「訊息同時指名 `runtime record drift:` 或 `skill record drift:` 時改為還原該 record 或從可信 source 重新安裝」；同步補一條 `skill-checks.fish` literal 斷言並重算 guidance baseline SHA-256 / 來源：Reviewer A（Finding 1）與 Reviewer B（第 1 筆），兩位獨立提出，依 `location + summary` 合併，兩者 `layer` 皆為 design
- `severity`: Suggestion（reviewer 原始為 Warning，confidence 55 落在 `[50, 80)` 而降級） / `confidence`: 55 / `layer`: design / `introduced_by`: `.cash-skills/bin/cash` 本次 diff 重寫的 stable record digest 比較行 / `summary`: receipt gate 內 stable record 取 digest 的 `sha256_file` 仍沿用預設 `error_code="bootstrap_invalid"`，該錯誤碼的既有 guidance 是無條件執行一次 `--init-receipt` / `recommendation`: 在該呼叫點同樣傳入 `error_code="receipt_invalid"` / 來源：Reviewer B（第 2 筆）
- `severity`: Suggestion / `confidence`: 55 / `layer`: design / `location`: `.cash-skills/bin/cash` receipt 解析的新增範圍閘門 / `summary`: 範圍閘門對任何六欄 record 生效，使帶 identity 欄位的 `runtime`／`skill` row 改以 `receipt identity is invalid` 回報，而非既有的 `replaceable receipt record has identity fields`，分類優先序被靜默改變 / `recommendation`: 以 `kind == "stable"` 限定該閘門，與 installer `parse_receipt` 的 stable-only 判準一致 / 來源：Reviewer B（第 4 筆）
- `severity`: Suggestion / `confidence`: 65 / `layer`: design / `location`: `scripts/cash-skills/tests/test_installer_runtime.py` 的 `test_launcher_rejects_a_negative_stable_device_by_shape` / `summary`: `assertNotIn("stable record drift", message)` 在本次改名後成為死斷言——該 literal 已不存在於 launcher 任何一支訊息中 / `recommendation`: 改為可被 regression 觸發的守衛，使 `-1` 若在未來繞過範圍閘門落入 identity／content 分類時能被攔下 / 來源：Reviewer B（第 5 筆）

## Rating

- post-filter cumulative blocking set Critical count：0
- post-filter cumulative blocking set Warning count：0
- 非 blocking triaged finding 數：6
- `critical_gap`：false
- `round_type`：full
- rationale：本輪為 unseeded run 的第一輪，全部 surviving Critical 與 Warning 皆為 blocking。兩位 reviewer 共提出 8 筆原始 findings（Reviewer A 2 筆 Warning、Reviewer B 3 筆 Warning 與 3 筆 Suggestion），依 `location + summary` 合併後為 6 筆。套用 confidence filter：無任何 finding 的 confidence 達到 `≥ 80`，因此沒有 finding 保持 `Critical` 或 `Warning`；`[50, 80)` 者降級為 `Suggestion`，`< 50` 者捨棄。post-filter cumulative blocking set 為空，pass 條件成立。降級的實質理由是三者一致：合併後的第一筆所指的 guidance 文字逐字滿足 IC-12 與 spec delta `Init 指引隨 guidance 部署到達 target` scenario 的全部條款，兩份 artifact 都沒有要求 guidance 區分第三支訊息，因此它是 spec 層級的收緊建議而非 adherence 違反；Reviewer B 第 2 筆所指的 `bootstrap_invalid` 預設是本次 diff 未改動的既有行為，且 IC-4 明文把 error code 例外限定在 runtime records。

## Fix Actions

本輪 pass，因此不存在必須修復的 blocking finding。以下三筆非 blocking Suggestion 屬於「修正即可完全落回既有 contract 條款」的類型，已一併修復並重驗；其餘兩筆與全部降級追跡列於其後。

1. **範圍閘門限定為 stable record**（Reviewer B 第 4 筆）。IC-2 的文字是「stable record 的 device 為負數或 inode 非正數時 MUST 以 `receipt_invalid` fail closed」，本次實作以 `len(row) == 6` 為條件而未限定 `kind`，比 contract 寬。修改檔案：`.cash-skills/bin/cash`（範圍閘門加上 `kind == "stable"`）。修正後非 stable 的六欄 row 回復由既有的 `replaceable receipt record has identity fields` 回報，分類優先序與 installer `parse_receipt` 一致。
2. **`CASH-INIT-RECEIPT.md` 前提句的涵蓋範圍**（Reviewer A Finding 2、Reviewer B 第 3 筆，合併）。原句寫「上述兩項都有一個共同前提」，但其上有四條 bullet，字面上把取得方式類的 bullet 排除在版控前提之外，與 IC-6「MUST NOT 把 fresh clone 或任何取得方式陳述為無條件可以重新簽發的理由」相抵觸。修改檔案：`CASH-INIT-RECEIPT.md`（改為「以上每一項都有一個共同前提」，並移除「它不適用於」清單中新增條目後的多餘空行）。
3. **死斷言替換**（Reviewer B 第 5 筆）。修改檔案：`scripts/cash-skills/tests/test_installer_runtime.py`（`test_launcher_rejects_a_negative_stable_device_by_shape` 的 `assertNotIn` 改為可被 regression 觸發的守衛）。

**Fix propagation**：fix 1 改變了 `.cash-skills/bin/cash` 的 bytes，因此該概念的全部出現位置在同一個 fix pass 內同步——`installer.py` 的 `APPROVED_LAUNCHER_TRANSITIONS` 兩筆 new digest 由 `2684106b3e7b7d939ddcd26636cd3d9b9f4bdd092ee853832dbe56868e2d584f` 更新為 `e7457338cfd6721fcc21fbbf96fad287176ebec674be6a12fc4e9ff27542804e`，並以 `./install-cash-skills.fish --self` 重新發佈 `.cash-skills/manifest.tsv`。修改檔案：`.cash-skills/lib/cash_cli/installer.py`、`.cash-skills/manifest.tsv`。

**Fix 後的 pre-round mechanical self-check**：canonical 版控前提 fragment 仍各自完整落在兩個檔案的單一原始碼行；`AGENTS.md` 與 `CLAUDE.md` 受管區塊逐 byte 相同且 digest 仍為 `3c0e0a0094820f45ed759dd00797f873f5774f414532ec1b2ccde5fc6382993b`（本輪 fix 未觸及該區塊）；`cash-skills.version`、`BUNDLE_VERSION` 與 manifest `bundle_version` 三者皆為 `2.13.0`；manifest 的 launcher digest 與工作樹一致；spec delta 的三個 MODIFIED requirement 標題逐 byte 存在於 `openspec/specs/cash-cli/spec.md`；spec delta 無 unclosed annotation 或殘留 `---`；IC-15 對照表為 13 列，與新增 requirement 的 13 個 scenario 相符。

**Fix 後重驗**：`fish scripts/cash-skills/tests/skill-checks.fish`（135 tests OK + bundle version history 10 tests OK + namespace scan PASS）、`fish scripts/cash-skills/tests/skill-checks.fish namespace-scan`、`fish scripts/cash-cli/tests/cli-checks.fish`（145 tests OK）、`.cash-skills/bin/cash validate --all` 四者全綠；task 5.2 的端到端四項在新 digest 下重跑仍全部成立（device 重新編號的 target launcher 可執行、direct dry-run 與 `--vendor` dry-run 皆不失敗、`--vendor` real run 完成遷移；launcher 停在 `592345fff…` 的 lagging target 升級到 2.13.0）。

**Signal-derived checks**：`openspec/signals/` 下沒有任何 signal 帶 `check` frontmatter 欄位，因此逐 signal 執行的分支不適用，改走既有 best-effort 判斷；相關 issue class 已納入兩位 reviewer 的 context。

**未修復的非 blocking triage note（Reviewer B 第 2 筆，`stable` digest 的 `error_code`）**：不修復。IC-4 明文「沿用既有出口的唯一例外是 error code：launcher 在 receipt gate 內對 **runtime records** 逐檔取 digest 時 MUST 以 `receipt_invalid` 回報失敗」，把例外擴及 stable records 是 contract 未要求的行為變更，且該 `bootstrap_invalid` 預設是本次 diff 未改動的既有行為（module 層級對 stable path 的 `open_regular` 本來就以 `bootstrap_invalid` 失敗）。列為後續 change 的候選。

**未修復的非 blocking triage note（合併後第一筆，guidance 字面分類的子字串重疊）**：不修復。受管 guidance 區塊的內容由 IC-12 與 spec delta `Target-local receipt 初始化` requirement 逐條指定，而兩者都只要求載明「identity drift 是入口、content drift 不是、版控前提」三件事，皆已滿足；補上第四條「前提不成立時的形態」是 contract 未涵蓋的新條款，且該區塊受 baseline digest 與 literal 斷言雙重釘死。屬 spec 層級的收緊，建議以 `/cash-ingest` 或後續 change 處理。

**Confidence 降級追跡**：
- 合併後第一筆（guidance 子字串重疊）：Reviewer A 與 Reviewer B 皆給 `Warning` / confidence 70，落在 `[50, 80)`，降級為 `Suggestion`。Reviewer B 的 `introduced_by` 指向本次 diff 在 `AGENTS.md`／`CLAUDE.md` 新增的子句，證據可驗證，因此不適用 introduced-by 降級。
- Reviewer B 第 2 筆（`stable` digest 的 `error_code`）：confidence 55，落在 `[50, 80)`，降級為 `Suggestion`。另記：其 `introduced_by` 指向本次 diff 重寫的比較行，但該行改動的是比較式而非 error code，缺陷機制本身未由本次 diff 引入，依 cash-apply introduced-by 規則本應另行降至 `≤ 25`；兩條規則都指向非 blocking，此處以較寬鬆的 `Suggestion` 保留，使其仍出現在完成輸出中。
- Reviewer A Finding 2 / Reviewer B 第 3 筆（`CASH-INIT-RECEIPT.md` 前提涵蓋範圍）：合併後取較高的 confidence 60，落在 `[50, 80)`，降級為 `Suggestion`。
- Reviewer B 第 4 筆與第 5 筆：reviewer 原始即為 `Suggestion`，confidence 55 與 65，維持 `Suggestion`。
- Reviewer B 第 6 筆（child process group 與 pipe drain）：confidence 45，低於 `50`，依 confidence filter 捨棄，不進入 findings 清單。理由：IC-15 要求的是「MUST NOT 留下 child process 或持有中的 workspace lock」，而 `wait_for_test_hold` 自身的 10 秒 timeout 為 grandchild 提供了有限上界，reviewer 自己也以此為由標為 Suggestion。

**裁判面保護**：本輪無 `未修復：裁判面保護` 記錄。本 change 修改的 `scripts/cash-skills/tests/skill-checks.fish` 是 protected grader path，但其 project-root-relative 路徑同時出現在 proposal `## Impact` 的 affected-code 條目與 `tasks.md` 4.4 的交付目標，屬 structured scope declaration 的明示例外；本輪 fix actions 未再修改該檔。

## Decision

passed
