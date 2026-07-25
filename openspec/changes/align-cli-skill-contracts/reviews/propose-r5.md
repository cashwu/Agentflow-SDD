# Cash Propose Review — Round 5

## Reviewer Findings

本輪 `round_type` 為 `micro`，由單一 Reviewer V 對第 4 輪留下的累積 blocking 成員與已記錄的修正做 delta 驗證。

### 累積 blocking 集合裁決

| 成員 | 裁決 | 依據 |
| --- | --- | --- |
| Q2 | resolved | Reviewer V 在臨時目錄實跑完整路徑：`git init` 臨時 workspace 後執行 `install-cash-skills.fish --target <tmpdir>` rc=0，再以 `cwd` 指向該 workspace 呼叫其 `.cash-skills/bin/cash search` rc=0 並回傳正常結果；反向對照（cwd 停在 repo root）重現 `workspace_root_mismatch` rc=1，確認第 4 輪對成因的敘述正確。tasks 4.1、design C2、C3、proposal 驗證段四處表述一致 |

Q2 移出累積 blocking 集合。

### Warning

**V1**
- `severity`: Warning
- `confidence`: 90
- `layer`: design
- `location`: `tasks.md` 3.4；`design.md` C10 驗收標準
- `summary`: receipt 重建被排在任務 3.3 之後，但 launcher 從任務 1.1 改動 `search.py` 的那一刻起就全面失效，因此任務 1.1 至 3.3 這 10 個 task 期間 `cash-apply` 無法用 `task done` 標記完成，也無法執行任何 `status` 或 `instructions`。第 4 輪引入 3.4 的目的正是消除這個停擺，但該放置位置只消除了 3.3 之後的部分。
- 佐證：Reviewer V 在 repo 的完整 source-layout 副本上模擬任務 1.1 的編輯後執行 `task done`，得到 `error[receipt_invalid]: runtime record drift: .cash-skills/lib/cash_cli/commands/search.py` 與 rc=1。並實測 `install-cash-skills.fish --self` 在版本未提升的情況下仍 rc=0 成功重建，證明 3.4 給的順序理由（receipt 首列記錄 bundle 版本）不足以作為禁止提早重建的依據——`validate_receipt` 只檢查版本字串格式，不比對 `cash-skills.version`。
- `recommendation`: 把 3.4 改為可重複執行、每次 runtime 改動後即重建，並保留「最後一次重建 MUST 在版本提升之後」的約束。
- `disposition`: fix-introduced
- `introduced_by`: propose-r4 `## Fix Actions` 對 Q1 的處置（新增任務 3.4 與 design C10）

### Suggestion

- **V2**（80，`layer`: text，`disposition`: fix-introduced，`introduced_by`: propose-r4 對 Q2 的修正）：四處都只要求「呼叫該臨時 workspace 內的 launcher」，未要求 subprocess 的 `cwd` 指向該 workspace；cwd 未設時即使呼叫臨時 launcher 也會得到同一個 `workspace_root_mismatch`，而 tasks 4.1 把該錯誤碼歸因於「呼叫了 repo 自身的 launcher」，會把除錯導向錯誤方向。
- **V3**（80，`disposition`: fix-introduced，`introduced_by`: propose-r4 對 Q2 的修正）：`install-cash-skills.fish --target` 會在 target 建立 `openspec/specs/`，因此「缺少該目錄時 `--scope specs` 回空」的案例前提在安裝式 workspace 下預設不成立；不先移除該目錄則測到的是空目錄而非缺目錄，斷言會在未覆蓋目標條件的情況下綠燈。
- **V4**（75，`layer`: text，`disposition`: fix-introduced，`introduced_by`: propose-r4 對 Q1 的處置）：3.4 的驗收指名 `scripts/cash-cli/tests/cli-checks.fish` 為驗證載具，但該檔只以 `unittest discover` 跑 `test_*.py`，完全不呼叫 launcher 也不碰 receipt。

## Rating

- post-filter 累積 blocking 集合 Critical 數：0
- post-filter 累積 blocking 集合 Warning 數：1
- 非 blocking triaged finding 數：3
- `critical_gap`: false
- `round_type`: micro

理由：Q2 經 Reviewer V 端到端實跑驗證後確認解決並移出累積集合。本輪無 Critical。V1 為第 4 輪修正的放置位置不完整所引入，且以實測證明會在任務 1.1 就讓 cash-apply 的標記指令停擺，集合因此非空，本輪不通過。

## Fix Actions

本輪修正涉及 2 個檔案：`openspec/changes/align-cli-skill-contracts/tasks.md`、`design.md`。

**blocking 修正**

- V1：`tasks.md` 3.4 改寫為「每一次改動任一 replaceable runtime 檔之後、下一次執行任何 `.cash-skills/bin/cash` 指令之前即重建，此步驟可重複執行，最後一次重建 MUST 在版本提升之後、任何回歸執行之前」，並補上 Reviewer V 實測確認的事實（版本未提升時 `--self` 亦可成功；`validate_receipt` 只檢查版本字串格式）。同時在任務 1.1 加註本任務改動 runtime 檔、完成後須立即依 3.4 重建 receipt。`design.md` C10 的可觀察行為與驗收標準同步改為可重複執行的語意。

**非 blocking triage 的處置**

三項皆一併修正而非僅記 triage note，因其修正成本為單句且 V3 若不處理會產生一個看似通過卻未覆蓋目標條件的假陽性斷言：

- V2：`tasks.md` 4.1 與 `design.md` C2 驗收標準補上「subprocess MUST 以 `cwd` 指向該臨時 workspace 呼叫」，並說明兩者任一不符都會得到同一個錯誤碼，避免把除錯導向錯誤方向。
- V3：`tasks.md` 4.1 該案例補上「MUST 在安裝完成後先移除 target 的 `openspec/specs/` 目錄再執行」與其理由。
- V4：3.4 的驗證載具由 `cli-checks.fish` 改為該任務自身指令的 exit code，並註明由任務 4.6 的第三步再次確認。

**已知且刻意的自我檢查例外**

任務 3.4 因 V4 的修正而不再指名任何測試檔，是 21 個任務中唯一沒有可被 trace 擷取之驗證目標的任務。這是刻意的：該任務的驗證條件就是 `.cash-skills/bin/cash validate --all` 的 exit code，而 repo 內沒有任何測試檔會驗證 receipt 重建。此例外不影響 `@trace` 區塊的正確性，只是該任務不對其貢獻路徑。

**修正後的機械自我檢查**

全部通過：delta spec 的註解計數與分隔線檢查、contract 編號順序、6 條 delta requirement 的 backing task、affected-code 25 筆與 design 宣稱一致。`cash validate align-cli-skill-contracts` 通過；`preflight.status` 為 `clean`。驗證目標擷取檢查回報僅 3.4 一項無目標，與上述刻意例外相符。

## Decision

next_round
