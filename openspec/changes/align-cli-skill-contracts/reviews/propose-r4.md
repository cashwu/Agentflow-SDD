# Cash Propose Review — Round 4

## Reviewer Findings

本輪 `round_type` 為 `full`，是本次 run 第一輪之後唯一的完整重掃檢查點，由 Reviewer A（Adherence）與 Reviewer B（Quality）獨立審查後彙總。

### 累積 blocking 集合裁決

唯一成員 N1 由兩位檢查點 reviewer 各自裁決：

| 成員 | Reviewer A | Reviewer B | 合併裁決 |
| --- | --- | --- | --- |
| N1 | resolved | resolved | resolved |

兩者皆確認 `proposal.md` A1 已改為與 `design.md` D1 一致的兩層敘述，且全部 artifact 中對 `drift._impact_paths` 的唯一提及是 D1 的否定式註記。兩者並各自以程式碼交叉驗證兩層依賴為真。N1 移出累積 blocking 集合。

### Warning

**Q2**
- `severity`: Warning
- `confidence`: 85
- `layer`: design
- `location`: `tasks.md` 4.1；`design.md` C2／C3／C4 驗收標準；`proposal.md` `## Proposed Solution` 的驗證段
- `summary`: 驗收要求「以 subprocess 呼叫 `.cash-skills/bin/cash`」與「測試 workspace 以 `tempfile` 建立」互斥。launcher 由自身路徑推導 `CASH_PROJECT_ROOT` 並注入環境，`search.py` 把它當 `launcher_root` 傳給 `Workspace.discover`，`workspace.py:47` 在 git root 不等於 launcher root 時直接失敗。Reviewer B 實跑確認得到 `workspace_root_mismatch` 且 rc=1，失敗原因與被測行為無關。
- `recommendation`: 改為先以 `install-cash-skills.fish --target <tmpdir>` 把 launcher 與 runtime 安裝進臨時 workspace，再呼叫該 workspace 內的 launcher；repo 內既有先例為 `scripts/cash-cli/tests/test_negative_atomicity.py` 的 launcher 測試。
- `disposition`: fix-introduced
- `introduced_by`: propose-r1 `## Fix Actions` 對 SU-9 的吸收（「SU-9（驗收改以 subprocess 呼叫 launcher）」）

**disposition 更正紀錄**：Reviewer B 原標記為 `new`。主 agent 依規則檢查該 finding 是否位於本迴圈修正觸及的位置，確認第 1 輪之前 `tasks.md` 4.1 完全沒有 subprocess 相關要求，該要求係第 1 輪吸收 SU-9 時新增，因此更正為 `fix-introduced`。此更正使該 finding 由非 blocking 轉為 blocking，並使本輪決策由 `passed` 轉為 `next_round`。證據為 propose-r1.md 第 173 行的吸收清單。

### Suggestion

信心落在 50 至 79 而降級，或原即為 Suggestion，皆不進入 blocking 集合：

- **Q1**（Reviewer B，90，`disposition`: new）：本次改動四個 replaceable runtime 檔，但 tasks 沒有重建 receipt 這一步。launcher 每次執行都逐檔比對 `.cash-skills/receipt.tsv` 的 sha256，任一 byte 改動即以 `receipt_invalid` 失敗，導致任務 4.6 要求 exit 0 的 `validate --all` 與 cash-apply 自身用來標記 checkbox 的指令全部停擺。Reviewer B 以 digest 實測比對確認。
- **Q3**（Reviewer B，65，`disposition`: new）：排除判準在 spec 寫「路徑片段含 `reviews`」而 design 與 tasks 寫「路徑片段為 `reviews`」；spec 的措辭可被落地成 substring 或 prefix 比對，而任務 1.3 對排除參數的比對形狀完全未界定。
- **Q4**（Reviewer B，70，`layer`: text，`disposition`: new）：design Risks 寫「既有群組已涵蓋兩個測試檔」，本次實際改動的 CLI 測試檔是三個。
- **G1**（Reviewer A，60，`disposition`: fix-introduced，`introduced_by`: propose-r1 對 WA-1 的修正）：`cash-drift.diff` 被宣告為 Modified 並列入重新產生清單，但依任務 2.5 的編輯點它必然逐位元組不變；Reviewer A 以模擬改寫後重跑同一組正規化 diff 指令驗證。
- **G2**（Reviewer A，55，`disposition`: new）：`cash-propose.diff` 同樣可能是無操作項，只有當 step 2 結尾句改寫成不同行數時才會變動。
- **G3**（Reviewer A，60，`disposition`: fix-introduced，`introduced_by`: propose-r1 對 SU-3 的修正）：C9 的範圍邊界「不改動既有群組的斷言內容」與 C8／tasks 3.3 必須改寫 `assert_inventory` 版本字面值、tasks 3.1 必須改動 divergent 清單直接衝突。
- **G4**（Reviewer A，70，`layer`: text，`disposition`: new）：design `## Context` 與 proposal A2 寫「不以連字號開頭」，實際程式碼判準是 `startswith("--")`，為雙連字號。
- **G5**（Reviewer A，55，`disposition`: new）：D6／C7／tasks 2.3 寫「移除 fork 情境段落（含其標題與自述句）」，但該段落還含以 fork 為前提的行為規則與其後的 `---` 分隔線；逐字照做會留下指涉 fork 的孤兒敘述。

## Rating

- post-filter 累積 blocking 集合 Critical 數：0
- post-filter 累積 blocking 集合 Warning 數：1
- 非 blocking triaged finding 數：8
- `critical_gap`: false
- `round_type`: full

理由：唯一的累積 blocking 成員 N1 經兩位檢查點 reviewer 一致裁決為 resolved 並移出集合。本輪無 Critical。Reviewer B 的 Q2 經主 agent 依 disposition 檢查義務由 `new` 更正為 `fix-introduced` 後成為 blocking Warning，集合因此非空，本輪不通過。若未做此更正，本輪會以空集合通過，而 Q2 指出的驗收路徑在實作時必然失敗——這正是 disposition 更正規則存在的理由。

## Fix Actions

本輪修正涉及 4 個檔案：`openspec/changes/align-cli-skill-contracts/proposal.md`、`design.md`、`tasks.md`、`specs/cash-cli/spec.md`。

**流程紀錄**：本輪兩個 full-round reviewer 以背景模式派發，時間上並行執行、接收相同 context、未互餵輸出，獨立性與並行性均成立；但兩者是分兩次呼叫送出，未達成字面上的單一訊息派發。第 1 輪同一項偏差更嚴重（先後同步執行，無並行）。此偏差不影響 findings 的獨立性。

**blocking 修正**

- Q2：`tasks.md` 4.1、`design.md` C2 與 C3 的驗收標準、`proposal.md` 的驗證段三處同步改為「先以 `install-cash-skills.fish --target <tmpdir>` 安裝到臨時 workspace，再呼叫該 workspace 內的 launcher」，並明文記錄直接呼叫 repo 自身 launcher 會以 `workspace_root_mismatch` 失敗的原因與既有先例路徑。

**非 blocking triage 的處置**

以下八項雖非 blocking，但修正成本低且其中 Q1 若不處理會使實作階段的第一個任務即讓 CLI 停擺，因此一併修正而非僅記 triage note：

- Q1：新增任務 3.4，要求在全部 runtime 修改與版本提升完成後、任何回歸執行之前執行 `./install-cash-skills.fish --self` 重建 receipt，並說明順序理由與 receipt 為 gitignore 檔不列入 affected code；`design.md` 新增對應的 C10。
- Q3：`specs/cash-cli/spec.md` 的排除判準改為「其路徑中存在一個完整片段等於 `reviews` 的目錄」，並明文 MUST 以完整路徑片段比對、MUST NOT 以字串前綴或子字串比對、名稱僅包含 `reviews` 的目錄 MUST NOT 被排除；`design.md` C4 的介面／資料形狀同步補上相同界定。
- Q4：`design.md` Risks 改為三個測試檔並列出檔名與對應群組名。
- G1、G2：`tasks.md` 3.2 由「重新產生六份 manifest」改為「重跑正規化 diff，對變動者更新、對未變動者確認逐位元組不變」，並註明 cash-propose 與 cash-drift 預期不變但仍須以重跑確認而非假設。兩份 manifest 保留於 `## Impact` 的宣告：variant-parity manifest 不在 grader 保護清單內，過度宣告無連帶影響，而刪除三個模板區塊造成的行號位移是否影響 hunk 標頭需以實跑確認，保留宣告較移除安全。
- G3：`design.md` C9 的範圍邊界改為「本 contract 不改動既有群組的斷言內容；版本字面值斷言的同步由 C8 負責，divergent 清單的登記由 C7 負責」。
- G4：`design.md` `## Context` 與 `proposal.md` A2 的既有行為敘述更正為「不以 `--` 開頭」。
- G5：`design.md` D6 與 C7、`tasks.md` 2.3 三處改為「移除整個 fork 情境區塊，自其標題起至其後的 `---` 分隔線止，含標題、自述句與區塊內以 fork 為前提的行為規則」，並引用已完整處理的 cash-ask 與 cash-drift manifest 作為先例。

**結構調整**

新增的 C10 原插入於 C8 與 C9 之間，已移至 C9 之後以維持編號順序，內容未變。

**修正後的機械自我檢查**

全部通過：delta spec 的 `<!--` 與 `-->` 計數皆為 0 且無殘留 `---`；contract 編號 C1 至 C10 順序正確；21 個 task 全部具備可擷取的驗證目標；6 條 delta requirement 皆有 backing task；新增的 C10 由任務 3.4 承載；affected-code 維持 25 筆；「不以連字號開頭」「兩個測試檔」「路徑片段含」三個舊表述在全部 artifact 中已無殘留。`cash validate align-cli-skill-contracts` 通過；`preflight.status` 為 `clean`。

## Decision

next_round
