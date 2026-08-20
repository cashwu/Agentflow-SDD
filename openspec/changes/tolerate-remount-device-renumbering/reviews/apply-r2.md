# Cash Apply Review — Round 2

本輪為新一輪 run 的第一輪（full round，unseeded：前一輪 run 以 `passed` 結束，未執行 Abort triage，因此沒有 bucket-1 種子）。round file 依規則自既有最高編號續號。

## Reviewer Findings

### Critical

（無）

### Warning

- `severity`: Warning / `confidence`: 100 / `layer`: design / `location`: `openspec/changes/tolerate-remount-device-renumbering/implementation-notes.md` 第二筆條目（`2026-08-20 19:22`）、`design.md` IC-12、`specs/cash-cli/spec.md` 的 `Target-local receipt 初始化` requirement、`AGENTS.md`／`CLAUDE.md` 受管區塊、`scripts/cash-skills/tests/skill-checks.fish`、`tasks.md` 4.1 與 4.4 / `summary`: `implementation-notes.md` 記載使用者已於本次 session 明示裁定，不採「維持現狀」的假設，而是回到 `/cash-ingest` 收緊 requirement——guidance MUST 指出 `--init-receipt` 入口只在診斷「僅」指名該 stable record 時適用，訊息同時指名 `runtime` 或 `skill` record drift 時 MUST 改為還原該 record 或從可信 source 重新安裝。該裁定尚未落地：IC-12 仍只列三件事、spec delta 的對應 requirement 同樣只要求那三件事、受管區塊沒有第四條、`skill-checks.fish` 沒有對應 literal 斷言，而 `tasks.md` 4.1 與 4.4 已標記 `[x]`，使該裁定在 archive 後不再有任何強制點。技術後果可驗證且不變：以字串比對套用受管 guidance 的 agent，在讀到第三支訊息（launcher 形如 `stable record identity drift: <stable>; runtime record drift: <path>. …`）時會命中入口子字串，於是在 IC-4 前提閘門正要擋下的情境執行 `--init-receipt`，把已漂移的 runtime bytes 簽為合法 / `recommendation`: 執行 `/cash-ingest`：先在 `design.md` IC-12 與 spec delta 的 `Target-local receipt 初始化` requirement 追加該款並補一個對應 scenario，`tasks.md` 4.1／4.4 追加驗收（在此之前 4.1／4.4 不應維持 `[x]`）；artifacts 定案後才實作 `AGENTS.md`／`CLAUDE.md` 補句（兩份逐 byte 相同）、`skill-checks.fish` 新 `assert_contains` literal，最後重算 canonical Cash guidance baseline SHA-256（現值 `3c0e0a0094820f45ed759dd00797f873f5774f414532ec1b2ccde5fc6382993b`），並在 `implementation-notes.md` 補一筆解決條目關閉該 open-question / 來源：Reviewer A（Finding 1，confidence 100）與 Reviewer B（第 1 筆，confidence 75，`introduced_by`: 本次 diff 在受管區塊新增的 `或以 \`receipt_invalid\` 回報 stable record identity drift 時` 子句，配合本次 diff 在 `.cash-skills/bin/cash` 新增、逐字以 `stable record identity drift: ` 起頭的第三支訊息），依 `location + summary` 合併，兩者 `layer` 皆為 design，合併後取較高的 confidence 100。Reviewer B 明示宣告此 issue 的實體已在 `reviews/apply-r1.md` 被 triage 為不修復，本輪重報的是 r1 之後才出現的新事實——使用者已推翻該假設。

### Suggestion

- `severity`: Suggestion（reviewer 原始為 Warning，confidence 70 落在 `[50, 80)` 而降級） / `confidence`: 70 / `layer`: design / `introduced_by`: 本次 diff 在 `CASH-INIT-RECEIPT.md` 新增的 identity drift bullet / `location`: `CASH-INIT-RECEIPT.md` 的 `--init-receipt 適用於` 清單 / `summary`: 該 bullet 把 launcher 專屬詞彙同時套用到 installer，兩處都不成立：installer 的訊息逐字是 `stable receipt identity drift`（非 `record`），且 `receipt_invalid` 在 `installer.py` 出現 0 次——installer 的同一個失敗經 `main()` 印為 `Error: …` 並 exit 1，不帶 error code / `recommendation`: 分寫兩個 gate 的實際可觀測形態 / 來源：Reviewer B（第 2 筆）
- `severity`: Suggestion / `confidence`: 60 / `layer`: design / `introduced_by`: 本次 diff 新增的 `finally` 區塊註解與其 `if child.poll() is None:` guard / `location`: `scripts/cash-skills/tests/test_installer_runtime.py` 的 `test_identity_drift_fails_before_acquiring_the_exclusive_lock` / `summary`: 註解陳述的 process 拓樸與本 repo 不符——`install-cash-skills.fish` 以 `exec` 取代自身，因此 `child.pid` 即 installer、今日不存在 grandchild；另 `finally` 內 `communicate` 的回傳被丟棄，使 deadline flake 的失敗訊息不帶任何 child 輸出 / `recommendation`: 改寫註解為實際拓樸，並把 `finally` 內 `communicate` 的回傳併入 `stdout`／`stderr` / 來源：Reviewer B（第 3 筆）
- `severity`: Suggestion / `confidence`: 55 / `layer`: design / `introduced_by`: 本次 diff 為 `sha256_file` 新增的 keyword-only 參數 `error_code: str = "bootstrap_invalid"` / `location`: `.cash-skills/bin/cash` 的 `sha256_file` 簽章 / `summary`: 在 receipt gate 內部，`bootstrap_invalid` 是繞過前提閘門的那個值（其部署 guidance 是無條件執行一次 `--init-receipt`）、`receipt_invalid` 是安全的那個；新參數把不安全的設為預設，安全的必須逐點 opt-in，任何未來在 receipt gate 內新增的呼叫都會靜默繼承繞過語意 / `recommendation`: 把 `error_code` 改為 required keyword-only，或改預設為 `receipt_invalid` 並讓 bootstrap 的兩個呼叫點明示傳入。Reviewer B 明示宣告此筆與 `reviews/apply-r1.md` 已 triage 的「stable 呼叫點」是不同的東西——本筆針對的是預設值方向 / 來源：Reviewer B（第 4 筆）
- `severity`: Suggestion / `confidence`: 55 / `layer`: design / `introduced_by`: 本次 diff 在 `elif` 分支內新增的第三支訊息 raise，位置在未被改動的 `receipt path mismatch` 檢查之前 / `location`: `.cash-skills/lib/cash_cli/installer.py` 的 `validate_installed_receipt` / `summary`: 新增的 raise 使既有的 `receipt path mismatch` 出口在「identity drift 延後判定中 + 該筆 record 同時漂移且 path 與 expected 不符」時不可達；IC-7 明文「`path != expected.path` 的 `receipt path mismatch` 檢查不變」，IC-4 亦要求延後期間命中既有 fail-closed 出口時 MUST 以該既有出口回報 / `recommendation`: 使既有出口在延後期間維持優先 / 來源：Reviewer B（第 5 筆）
- `severity`: Suggestion / `confidence`: 55 / `layer`: design / `introduced_by`: 本次 diff 新增的 `test_source_repository_hint_precedes_the_identity_drift_hint` / `location`: `scripts/cash-skills/tests/test_installer_runtime.py` / `summary`: reviewer 實跑該 fixture 確認它不 vacuous（identity drift 路徑確實走到、合成 receipt 通過全部形狀與 inventory 檢查），但它只釘住「source hint 出現」，沒有釘住「identity hint 不出現」；一個把兩段 hint 串接而非覆寫的實作同樣滿足現有斷言，而該實作會讓 source repository 的使用者拿到一個必然以 `init_source_repo` 失敗的指令 / `recommendation`: 補一條 `assertNotIn("--init-receipt", message)`，直接對應 spec scenario 的第二條 THEN / 來源：Reviewer B（第 6 筆）
- `severity`: Suggestion / `confidence`: 50 / `layer`: design / `location`: `scripts/cash-skills/tests/test_installer_runtime.py` 的 `test_identity_drift_fails_before_acquiring_the_exclusive_lock` cleanup / `summary`: 以 `start_new_session=True` + `os.killpg(SIGTERM→SIGKILL)` 取代 IC-15 字面指名的 `Popen.terminate()`／`kill()`，屬保留 contract 的機制替換（訊號種類與先後一致，且更完整滿足同條的 `MUST NOT 留下 child process 或持有中的 workspace lock`），但 `implementation-notes.md` 沒有對應的 `類別：deviation` 條目 / `recommendation`: 不改程式碼，補一筆 `deviation` 條目 / 來源：Reviewer A（Finding 2）

## Rating

- post-filter cumulative blocking set Critical count：0
- post-filter cumulative blocking set Warning count：1
- 非 blocking triaged finding 數：6
- `critical_gap`：false
- `round_type`：full
- rationale：本輪為 unseeded run 的第一輪，全部 surviving Critical 與 Warning 皆為 blocking。兩位 reviewer 共提出 10 筆原始 findings（Reviewer A 1 Warning + 1 Suggestion，Reviewer B 2 Warning + 6 Suggestion），依 `location + summary` 合併後為 7 筆。套用 confidence filter：合併後的第一筆 confidence 100，`≥ 80` 因此保持 `Warning` 並進入 cumulative blocking set；其餘 `[50, 80)` 者降級為 `Suggestion`；`< 50` 的兩筆捨棄。blocking set 含一筆 Warning，pass 條件不成立。該 blocking finding 的解除需要在 `design.md` IC-12 與 spec delta 的 requirement 追加新條款——那是 contract 條款的擴充而非實作缺陷的修復，cash-apply 的 fix actions 無法在不擴張 change 範圍的前提下完成；使用者已於本次 session 明示選擇以 `/cash-ingest` 處理，並明確不採 accepted-risks 路線。因此本輪不存在合法的 blocking action（fix／裁判面保護註記／已取得同意的 accepted-risks 條目三者皆不可得），依 Review round action obligation 不得進入 `next_round`，改以 `aborted` 結束並執行 Abort triage。

## Fix Actions

blocking finding 無法在本輪修復，理由見 `## Rating`；其處置為 Abort triage 的 bucket 1。以下為本輪對非 blocking Suggestion 所做的修復與全部降級追跡。

1. **`CASH-INIT-RECEIPT.md` 的 gate 用語**（Reviewer B 第 2 筆）。經實測確認：`grep -c receipt_invalid .cash-skills/lib/cash_cli/installer.py` 為 `0`，installer 的訊息逐字為 `stable receipt identity drift`。修改檔案：`CASH-INIT-RECEIPT.md`（該 bullet 改為分寫兩個 gate 的實際可觀測形態，並註明 installer 不輸出 error code）。
2. **測試註解的 process 拓樸與 deadline flake 的可診斷性**（Reviewer B 第 3 筆）。經實測確認 `install-cash-skills.fish` 第 27 行為 `exec "$python_command" …`。修改檔案：`scripts/cash-skills/tests/test_installer_runtime.py`（註解改為陳述實際拓樸並說明 group 訊號是為了 wrapper 拓樸改變時仍成立；`finally` 內三處 `communicate` 的回傳併入 `stdout`／`stderr`）。
3. **`receipt path mismatch` 的出口優先序**（Reviewer B 第 5 筆）。修改檔案：`.cash-skills/lib/cash_cli/installer.py`（非 stable 的漂移改以區域旗標記錄，`path != expected.path` 檢查移至第三支訊息 raise 之前，使該既有 fail-closed 出口在延後判定期間維持優先，同時保留 stable content drift 先於它的既有優先序）。
4. **source hint 優先性的反向斷言**（Reviewer B 第 6 筆）。修改檔案：`scripts/cash-skills/tests/test_installer_runtime.py`（補 `assertNotIn("--init-receipt", message)`）。
5. **機制替換的 deviation 記錄**（Reviewer A Finding 2）。修改檔案：`openspec/changes/tolerate-remount-device-renumbering/implementation-notes.md`（新增一筆 `類別：deviation`，說明以 session group 訊號實作 IC-15 指名的 terminate→有限等待→kill 序列的原因與不變的觀察行為）。

**Fix propagation**：fix 3 改動了 `.cash-skills/lib/cash_cli/installer.py`——它是 runtime record——因此以 `./install-cash-skills.fish --self` 重新發佈 `.cash-skills/manifest.tsv`。launcher bytes 未被本輪改動，其 SHA-256 仍為 `e7457338cfd6721fcc21fbbf96fad287176ebec674be6a12fc4e9ff27542804e`，`APPROVED_LAUNCHER_TRANSITIONS` 兩筆新 entry 與 manifest 的 stable launcher digest 三者維持一致，故 transition 集合不需變更。修改檔案：`.cash-skills/manifest.tsv`。

**Fix 後的 pre-round mechanical self-check**：spec delta 的 `<!--`／`-->` 計數皆為 0 且無殘留 `---`；新增 requirement 的 scenario 數 13 與 IC-15 對照表資料列數 13 相符，`design.md` 與 `tasks.md` 的「十三個」敘述一致；`tasks.md` 15 項全 `[x]`；canonical 版控前提 fragment 在 `.cash-skills/bin/cash` 與 `.cash-skills/lib/cash_cli/installer.py` 各自完整落於單一原始碼行；launcher digest 與 transition 兩筆新 entry 及 manifest 三者相符，installer.py 的實際 digest 等於 manifest 記載值；`cash-skills.version`、`BUNDLE_VERSION` 與 manifest `bundle_version` 皆為 `2.13.0`；spec delta 三個 MODIFIED requirement 標題逐 byte 存在於 `openspec/specs/cash-cli/spec.md`。

**Fix 後重驗**：`fish scripts/cash-skills/tests/skill-checks.fish`（135 tests OK + bundle version history 10 tests OK + namespace scan PASS）、`fish scripts/cash-cli/tests/cli-checks.fish`（145 tests OK）、`.cash-skills/bin/cash validate --all`、`git diff --check` 皆通過；本輪 fix 直接觸及的四個測試函式單獨重跑亦全綠。

**Signal-derived checks**：`openspec/signals/` 下沒有任何 signal 帶 `check` frontmatter 欄位，逐 signal 執行的分支不適用，改走既有 best-effort 判斷；相關 issue class 已納入兩位 reviewer 的 context。

**未修復的非 blocking triage note（Reviewer B 第 4 筆，`sha256_file` 的預設 error code 方向）**：不修復。IC-4 明文把 error code 例外限定在 receipt gate 內對 runtime records 取 digest 的呼叫點，改動預設值方向會連帶改變 module 層 bootstrap 兩個呼叫點的語意，屬 contract 未要求的行為調整；且該改動會再次變更 launcher bytes 與其 digest，而 Reviewer B 第 8 筆已指出 review fix pass 反覆變更 launcher bytes 本身帶有 stranding 風險。列為後續 change 的候選。

**Confidence 降級追跡**：
- 合併後第一筆（使用者裁定未落地／guidance 子字串重疊）：Reviewer A confidence 100、Reviewer B confidence 75，合併後取 100，`≥ 80` 因此維持 `Warning` 並進入 cumulative blocking set。Reviewer B 的 `introduced_by` 指向本次 diff 新增的 guidance 子句與第三支訊息，證據可驗證，不適用 introduced-by 降級。
- Reviewer B 第 2 筆（`CASH-INIT-RECEIPT.md` gate 用語）：confidence 70，落在 `[50, 80)`，降級為 `Suggestion`。
- Reviewer B 第 3 筆（測試註解拓樸與 flake 可診斷性）：confidence 60，落在 `[50, 80)`，降級為 `Suggestion`。
- Reviewer B 第 4 筆（`sha256_file` 預設值方向）、第 5 筆（`receipt path mismatch` 優先序）、第 6 筆（source hint 反向斷言）：confidence 皆 55，reviewer 原始即為 `Suggestion`，維持 `Suggestion`。
- Reviewer A Finding 2（機制替換未記 deviation）：confidence 50，reviewer 原始即為 `Suggestion`，維持 `Suggestion`。
- Reviewer B 第 7 筆（`CASH-INIT-RECEIPT.md` 清單前三條與收尾句互相抵銷）：confidence 45，低於 `50`，依 confidence filter 捨棄。其實質與合併後第一筆的處置重疊——收尾句的措辭同屬 `/cash-ingest` 要收緊的 guidance 面，將隨 bucket 1 一併處理。
- Reviewer B 第 8 筆（中間態 launcher digest `2684106b3e…` 的 stranding 風險）：confidence 40，低於 `50`，依 confidence filter 捨棄。主 agent 另行查證其前提：apply-r1 之前那一輪 task 5.2 的全部 target 都建立在 session scratchpad 的 `e2e/` 目錄下並已 `rm -rf` 刪除，未對任何常駐 target 安裝過該 bytes，且該 digest 從未進入 commit，因此不存在持有該 launcher 的落後族群，不需追加 catch-up transition。Reviewer B 自己也因無法驗證而保守評分。

**裁判面保護**：本輪無 `未修復：裁判面保護` 記錄。本 change 修改的 `scripts/cash-skills/tests/skill-checks.fish` 是 protected grader path，但其 project-root-relative 路徑同時出現在 proposal `## Impact` 的 affected-code 條目與 `tasks.md` 4.4 的交付目標，屬 structured scope declaration 的明示例外；本輪 fix actions 未修改該檔。

**Abort triage**：
- **bucket 1（remains this change's obligation，種子化下一次 re-run）**：合併後第一筆——受管 guidance 的 `--init-receipt` 入口條件未區分「診斷僅指名該 stable record」與「訊息同時指名 `runtime`／`skill` record drift」，且使用者已裁定的收緊決定尚未落地於 `design.md` IC-12、spec delta 的 `Target-local receipt 初始化` requirement、`AGENTS.md`／`CLAUDE.md` 受管區塊、`scripts/cash-skills/tests/skill-checks.fish` 與 guidance baseline。
- **bucket 2（newly discovered，從未 blocking）**：Reviewer B 第 4 筆（`sha256_file` 預設 error code 方向）。依 signals write step 的規則，只有在任一輪 survived confidence filter 且分類為 `Critical` 或 `Warning`、且 confidence `≥ 80` 的 finding 才產生 signal；本筆為 `Suggestion`／55，因此不寫入 signal，僅在此記錄並列入完成輸出。其餘本輪 Suggestion 皆已於本輪修復，不入 bucket 2。
- **bucket 3（accepted trade-off）**：空。使用者於本次 session 被明示詢問後選擇 `/cash-ingest` 路線，明確不採 accepted-risks 記錄，因此無任何條目寫入 `accepted-risks.md`。
- **re-run 的具體前提**：不得原樣重跑。先以 `/cash-ingest` 更新 design 與 scope（bucket 1），實作對應 guidance 與斷言並重算 baseline，之後的 re-run 須自本檔之後續號、納入 `apply-r1.md` 與本檔、並以 bucket 1 種子化 cumulative blocking set，其第一輪的兩位 reviewer 須對每個 member 回傳明確的 resolved／unresolved 判定。

## Decision

aborted
