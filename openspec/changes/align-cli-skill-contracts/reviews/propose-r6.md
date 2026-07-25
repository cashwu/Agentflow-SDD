# Cash Propose Review — Round 6

## Reviewer Findings

本輪 `round_type` 為 `micro`，由單一 Reviewer V 對第 5 輪留下的累積 blocking 成員與已記錄的修正做 delta 驗證。本輪為本次 run 的最後一輪。

### 累積 blocking 集合裁決

| 成員 | 裁決 | 依據 |
| --- | --- | --- |
| V1 | resolved | Reviewer V 在 repo 的完整副本上端到端實跑六個時點並逐一取得 exit code 佐證 |

Reviewer V 的實測序列：模擬任務 1.1 改動 `search.py` 而不重建 → `receipt_invalid: runtime record drift` rc=1；版本未提升下執行 `--self` → `Result: bootstrap` rc=0；重跑 `validate --all` → rc=0；再改 `workspace.py` 後重複同一循環 → rc=0（可重複性成立）；只提升版本而不重建 → validate rc=0（版本提升本身不使 launcher 失效）；版本提升後最後一次重建 → receipt 首列為 `version 2.2.0` 且 validate rc=0。

三項具體疑問的答案：實作者依現行順序不會在任何時點卡住，因為全部 6 個會改動 runtime 檔的任務都落在 1.1 至 1.6，而 2.1 至 2.5 只改 `SKILL.md`（launcher 對 24 筆 `skill` 記錄僅比對路徑與順序、不比對內容 digest，Reviewer V 另以注入換行實測確認），3.1 至 3.3 與 4.x 皆不改 runtime 檔；任務 1.1 的加註之外還有第二道保險，launcher 在 source layout 下會把修復指令印在錯誤訊息尾端；「每次改動後即重建」與「最後一次在版本提升之後」兩條規則互補而非重疊，因為版本提升本身不改動 runtime 檔、不觸發第一條規則。

V1 移出累積 blocking 集合，集合為空。

### Suggestion

- **F1**（85，`layer`: text，`disposition`: fix-introduced，`introduced_by`: propose-r5 對 V3 的處置）：tasks 4.1 中「先移除 `openspec/specs/`」的括號理由「因為 installer 會建立該目錄」不成立。Reviewer V 在只含 `openspec/config.yaml` 與 `openspec/changes/archive/` 的空 target 上實跑 `--target`，rc=0 且安裝後 `openspec/` 底下仍只有 `changes` 與 `config.yaml`。該目錄實際上是 tasks 4.1 自身要求的 workspace fixture 造出的。MUST 指令本身正確且必要，錯的只是歸因；風險在於實作者查證理由後可能判定該步驟多餘而略過，重新落入 V3 原本要防的假陽性。
- **F2**（70，`layer`: text，`disposition`: fix-introduced，`introduced_by`: propose-r5 對 V1 的處置）：receipt 重建的加註被寫在「依 design 的 C2」的括號內，但 C2 是 search 位置參數解析 contract，管轄該規則的是 C10；依指引回查 C2 的實作者找不到對應敘述。加註直接指名任務 3.4，可執行性不受影響。

兩項皆為文字歸因層面，`severity` 為 Suggestion，不進入累積 blocking 集合。

## Rating

- post-filter 累積 blocking 集合 Critical 數：0
- post-filter 累積 blocking 集合 Warning 數：0
- 非 blocking triaged finding 數：2
- `critical_gap`: false
- `round_type`: micro

理由：唯一的累積 blocking 成員 V1 經 Reviewer V 端到端實跑六個時點驗證後確認解決並移出集合，累積 blocking 集合為空。本輪的兩項 finding 皆為 Suggestion 且僅涉及文字歸因，不影響任何 MUST 指令的正確性與可執行性，依規則不進入 blocking 集合。通過條件成立。

Reviewer V 在其結論中明確聲明該裁決不因本輪為最後一輪而放寬標準，並列出其為此額外查核的前提（`SKILL.md` 改動不觸發 receipt 失效），該前提是第 5 輪未驗證但決定 3.4 覆蓋範圍是否完整的關鍵。

## Fix Actions

本輪修正涉及 1 個檔案：`openspec/changes/align-cli-skill-contracts/tasks.md`。

兩項非 blocking 的 Suggestion 一併修正而非僅記 triage note，因其修正成本為單句、且 F1 若不處理有導致實作者略過必要步驟的具體風險：

- F1：tasks 4.1 該案例的理由改為「該目錄是本測試檔的 workspace fixture 為建立 master spec 而造出的（installer 本身不建立它）」，並依 Reviewer V 的附帶建議把該案例限定在其專屬的臨時 workspace 執行，避免移除動作連帶清掉其他 scope 案例所需的 master spec。
- F2：receipt 重建的加註自「依 design 的 C2」的括號移出，改置於 tasks 1.1 驗收句之後並明文標示「依 design 的 C10」。

**附帶更正**：Reviewer V 觀察到但未列為 finding 的數字精度問題一併處理——tasks 3.4 理由句中的「後續 10 個任務」更正為「任務 1.1 至 3.3 之間的 14 個任務」，經程式化複算確認為 14。

**未再經 reviewer 複核的聲明**：以上三處修正在本輪 reviewer 完成之後才寫入，因此未經任何 reviewer 複核。三者皆為 `layer: text` 的歸因與計數更正，未改動任何 SHALL/MUST 條款、任何 contract 的可觀察行為或介面形狀、任何 spec requirement 或 scenario。修正後 `cash validate align-cli-skill-contracts` 通過、`preflight.status` 為 `clean`、任務計數複算為 14。

**未修復：裁判面保護**：本次 run 六輪中沒有任何 finding 因 grader 保護而被保留不修。`scripts/cash-skills/tests/skill-checks.fish` 雖在保護清單內，但已於 proposal 的 `## Impact` 明文宣告為 affected code，符合 structured scope declaration 的例外條件；`scripts/cash-cli/tests/cli-checks.fish` 經第 1 輪 WA-2 與第 4 輪 Q4 兩次查證確認不需修改，已自宣告移除。

## Decision

passed
