# Cash Propose Review — Round 2

## Reviewer Findings

本輪 `round_type` 為 `micro`，由單一 Reviewer V 對第 1 輪的累積 blocking 集合與已記錄的修正做 delta 驗證。

### 累積 blocking 集合裁決

Reviewer V 對 12 個成員逐一回傳裁決，並附修正後 artifact 與 repo 現況的具體證據：

| 成員 | 裁決 | 依據 |
| --- | --- | --- |
| CR-1 | resolved | C7 已移除「不改動 cash-ask」邊界；tasks 2.3 與 2.4 涵蓋四個檔案；spec 的「新產生的合法差異必須登記」段落與 tasks 3.1 已落地 |
| CR-2 | resolved | proposal 與 design 的參照對象已更正為 cash-audit 與 cash-drift；受影響 skill 數已由二改為四 |
| CR-3 | unresolved | 新判準對 cash-propose 第 114 行的雙反引號跳脫仍為偽陽性 |
| CR-4 | resolved | 五個標題字面值的實際出現位置全部被 tasks 2.1 涵蓋；grader sentinel 實測為 507–525 行，448 確在區塊外 |
| CR-5 | resolved | C1 與 spec 的子結構條款與 tasks 1.6、4.3 一致 |
| WA-1 | resolved | cash-drift 兩個變體與其 manifest 已入範圍；新增對應 requirement 與 tasks 2.5 |
| WA-2 | resolved | cli-checks.fish 已自 Impact 移除；Risks 已更正為一個 grader 保護檔 |
| WA-3 | resolved | 新增 D8；C6 驗收已補內容斷言；tasks 2.2 涵蓋四行 |
| WA-4 | resolved | C4 驗收與 spec scenario 已對齊，不再參照「變更前」 |
| WA-5 | resolved | D4 已收窄為只排除封存 `reviews`；三重凍結事實已記錄；Risks 已誠實改寫 |
| WA-6 | resolved | tasks 4.2 已逐字寫成「替換而非新增」 |
| WA-7 | resolved | D4 明訂走訪層剪枝；`workspace.py` 已入 Impact 與 tasks 1.3 |

### Critical

**F1**
- `severity`: Critical
- `confidence`: 100
- `layer`: design
- `location`: `specs/cash-skill-workflows/spec.md` 空 code span 判準與其 Example 表格；`design.md` D9；`tasks.md` 4.4
- `summary`: 第 1 輪採用的判準「一對相鄰反引號，且其前後字元都不是反引號」對 cash-propose 兩個變體第 114 行的合法雙反引號跳脫仍為偽陽性，與同段落自身「MUST NOT 誤判跳脫寫法」的規定直接矛盾。
- `recommendation`: 改用「同一行中長度恰為 2 的反引號 run 出現奇數次」；合法跳脫的開閉分隔符必成對出現而為偶數，fence 的 run 長度為 3 不計入。
- `disposition`: unresolved-prior

### Warning

**F2**
- `severity`: Warning
- `confidence`: 80
- `layer`: design
- `location`: `tasks.md` 4.4 的斷言內容列舉；對照 `design.md` C6 驗收與 `tasks.md` 2.2 驗收
- `summary`: C6 與 tasks 2.2 都要求對 cash-ingest 斷言改寫後的內容，但實際撰寫斷言的 tasks 4.4 窮舉了四項而未含這一項，該驗收在 tasks 層無交付者。
- `recommendation`: 在 tasks 4.4 的列舉補上第五項。`skill-checks.fish` 是 grader 保護檔且只由 4.4 負責改寫，不能靠 2.2 順手補。
- `disposition`: fix-introduced
- `introduced_by`: propose-r1 `## Fix Actions` 的 WA-3 修正（「C6 驗收補上內容字面值斷言」未同步到承載斷言的 tasks 4.4）

### Suggestion

信心落在 50 至 79 而降級，或原即為 Suggestion，皆不進入 blocking 集合：

- **F3**（65，`disposition`: fix-introduced，`introduced_by`: propose-r1 WA-3 修正）：C6 與 tasks 2.2 都寫「含有 D8 所定義的敘述字面值」，但 D8 只定義解析語意而未定義任何可斷言的字串；且 C6 驗收列三行而可觀察行為與 tasks 2.2 列四行。
- **F4**（65，`disposition`: fix-introduced，`introduced_by`: propose-r1 CR-5 修正）：三處宣稱 `drift._impact_paths` 依賴 `## Impact` 子結構，但該函式實際上是對整份 proposal 抽 code span 並篩含 `/` 者，不看任何標題。
- **F5**（55，`disposition`: fix-introduced，`introduced_by`: propose-r1 WA-4 修正）：「`--scope all` 的結果是 `active` 結果的超集合」在 `--limit` 截斷下不普遍成立。
- **F6**（90，`layer`: text，`disposition`: fix-introduced，`introduced_by`: propose-r1 WA-3 修正）：D8 寫「第 29 行既有的範例」，實測該範例位於第 30 行。

## Rating

- post-filter 累積 blocking 集合 Critical 數：1
- post-filter 累積 blocking 集合 Warning 數：1
- 非 blocking triaged finding 數：4
- `critical_gap`: true
- `round_type`: micro

理由：第 1 輪的 12 個 blocking 成員經 Reviewer V 逐一驗證後有 11 個確認解決並移出累積集合，CR-3 因判準本身仍有偽陽性而維持 unresolved 並以 F1 重新報告。F2 為第 1 輪修正未完整傳播所引入。累積 blocking 集合仍含一個 Critical，因此不通過。

## Fix Actions

本輪修正涉及 4 個檔案：`openspec/changes/align-cli-skill-contracts/design.md`、`tasks.md`、`specs/cash-cli/spec.md`、`specs/cash-skill-workflows/spec.md`。`proposal.md` 本輪未修改。

**驗證資訊的獨立確認**：主 agent 未直接採信 Reviewer V 對判準的建議，而是對 24 個 canonical `SKILL.md` 實際執行兩個判準比對。判準「前後字元都不是反引號」命中 7 行，其中 4 行是 cash-propose 兩個變體第 114 行的合法跳脫（每行命中兩次），確認為偽陽性；判準「同一行中長度恰為 2 的 run 出現奇數次」恰好命中 `.agents/skills/cash-ingest/SKILL.md` 的第 40、53、267 行，零偽陽性。F1 的 `unresolved-prior` 裁決與建議判準均成立。

**逐項修正**

- F1（blocking Critical）：`specs/cash-skill-workflows/spec.md` 的判準句改為 run 計數形式，「空 code span 使套件失敗」scenario 的 GIVEN 同步改寫，Example 表格三列由「前後字元」欄改為「該行長度為 2 的 run 次數」欄並更正第二列先前錯誤的描述；`design.md` D9 記錄舊判準失敗的具體原因與新判準的實測結果；`tasks.md` 4.4 的判準文字同步。
- F2（blocking Warning）：`tasks.md` 4.4 的斷言內容列舉由四項改為五項，補上對 `.agents/skills/cash-ingest/SKILL.md` 的檢查。
- F3（非 blocking，一併修正）：`design.md` D8 改為提供可斷言的否定式（該四行 MUST NOT 含空 code span，且 MUST NOT 含 `~/.claude/plans/` 或任何其他目錄前綴字面值），並明文要求斷言以內容匹配而非行號定位，因為 tasks 2.2 另要求合併語句會使行號失準；C6 驗收與 tasks 2.2、4.4 同步採用該否定式。
- F4（非 blocking，一併修正）：`design.md` D1 與 C1、`specs/cash-cli/spec.md` 的理由敘述改為只列實際成立的兩層依賴——`## Impact` 標題為 `spec_merge._paths_in_section` 界定區段的依據，三個標籤列為 impact 粒度提示計數的依據——並明文註記 `drift._impact_paths` 不屬於此依賴，`## Capabilities` 的兩個子標題無程式碼消費者而是可讀性慣例。
- F5（非 blocking，一併修正）：`design.md` C4 改為走訪層命題（`all` 走訪集合是 `active` 走訪集合的嚴格超集合，差集恰為封存 `reviews` 下的檔案，不受排名截斷影響）；`specs/cash-cli/spec.md` 對應 scenario 補上「以足以涵蓋全部命中文件的 `--limit` 執行」前提。
- F6（非 blocking，一併修正）：`design.md` D8 移除錯誤行號，改以內容引用該範例。

**主 agent 機械自我檢查於本輪新發現的缺陷**

- SC-1：artifact 內文引用 `` `Modified:` `` 這個字面值時，`discovery.py` 的 `_EXISTING_PATH` 會匹配 `Modified:` 後緊接的反引號並把其後的標點擷取為檔案路徑，使 preflight 對本 change 回報 `status: critical` 與 3 個幻影 missing file（`、` 一個、`／` 兩個，來源為 design.md 與 tasks.md）。此為 artifact 自身觸發 CLI 解析陷阱，與 cash-propose 既有的「勿在 artifact 內文用反引號包 shell 指令」警告同類。修正方式為把三個標籤的 code span 改為不含冒號並在文字中說明冒號，於 `design.md`、`tasks.md`、`specs/cash-cli/spec.md` 三處同步。修正後 preflight 回報 `status: clean` 且 `missingFiles` 為 0。自我檢查結果不是 reviewer finding，不計入本輪決策。

**修正後的機械自我檢查**

四項檢查與 signal 衍生檢查全部通過：delta spec 的 `<!--` 與 `-->` 計數皆為 0 且無殘留 `---`；affected-code 實際 25 筆與 design 宣稱一致；MODIFIED requirement 標題與 master spec 逐位元組相符；新判準措辭在 design、spec、tasks 三處一致，僅 D9 中作為「舊判準為何失敗」的解釋性引用保留舊措辭，propose-r1.md 為已完成輪次的不可變檔案不予修改。preflight 為 `clean`。`cash validate align-cli-skill-contracts` 通過。

## Decision

next_round
