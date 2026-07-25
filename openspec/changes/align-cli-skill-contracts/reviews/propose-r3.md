# Cash Propose Review — Round 3

## Reviewer Findings

本輪 `round_type` 為 `micro`，由單一 Reviewer V 對第 2 輪留下的兩個累積 blocking 成員與已記錄的修正做 delta 驗證。

### 累積 blocking 集合裁決

| 成員 | 裁決 | 依據 |
| --- | --- | --- |
| F1 | resolved | Reviewer V 對 24 個 canonical `SKILL.md` 實跑新判準，命中集合恰為 `.agents/skills/cash-ingest/SKILL.md` 第 40、53、267 三行，cash-propose 兩變體第 114 行的合法跳脫 run 次數為 2 不在命中集合內；判準措辭在 design D9、spec 判準句與 scenario 與 Example 表格、tasks 4.4 三處一致 |
| F2 | resolved | `tasks.md` 4.4 的斷言列舉實為五項，第五項與 design C6 驗收表述逐字一致 |

兩個成員皆經驗證解決並移出累積 blocking 集合。

### Warning

**N1**
- `severity`: Warning
- `confidence`: 95
- `layer`: design
- `location`: `proposal.md` `## Proposed Solution` A1；對照 `design.md` D1
- `summary`: 第 2 輪 F4 的更正只同步到 design D1、C1 與 cash-cli spec 三處，`proposal.md` 的 A1 仍宣稱「drift 的 impact 路徑擷取、spec 合併的 trace 產生與 impact 粒度提示三處都依賴該形狀」，其中 drift 一項已被 design D1 明文註記為不屬於此依賴，形成同一 change 內 proposal 與 design 的直接矛盾。
- `recommendation`: 把該句改為與 design D1 相同的兩層敘述，並移除對 drift impact 路徑擷取的宣稱。
- `disposition`: fix-introduced
- `introduced_by`: propose-r2 `## Fix Actions` 的 F4 修正（明列同步三處而未涵蓋 `proposal.md`，該輪並自述「`proposal.md` 本輪未修改」）

### Suggestion

信心落在 50 至 79 而降級，或原即為 Suggestion，皆不進入 blocking 集合：

- **N2**（60，`disposition`: fix-introduced，`introduced_by`: propose-r2 F5 修正）：`tasks.md` 1.4 的驗收仍是未加限定的「`all` 為 `active` 的超集合」，即 F5 判定在排名截斷下不普遍成立的原始表述；F5 只同步了 design C4 與 cash-cli spec。
- **N3**（90，`layer`: text，`disposition`: fix-introduced，`introduced_by`: propose-r2 F6 修正）：`tasks.md` 2.2 仍寫「與第 29 行既有的範例一致」，該檔第 29 行為空行。
- **N4**（55，`disposition`: fix-introduced，`introduced_by`: propose-r2 `## Fix Actions` 的 SC-1 修正）：規範側四處都保留了「每個標籤後接冒號」的文字說明因此模板仍被精確指定，但撰寫斷言的 `tasks.md` 4.3 與對應 scenario 只列裸標籤名，依此寫出的測試對缺冒號的模板也會通過。
- **N5**（50，`disposition`: new）：奇偶判準的固有偽陰性——同一行出現偶數個空 code span 時會被判為合法。實測既有殘骸皆為一行一處。

## Rating

- post-filter 累積 blocking 集合 Critical 數：0
- post-filter 累積 blocking 集合 Warning 數：1
- 非 blocking triaged finding 數：4
- `critical_gap`: false
- `round_type`: micro

理由：第 2 輪的兩個 blocking 成員經 Reviewer V 實跑判準與逐項比對後皆確認解決並移出累積集合，本輪無新的 Critical。累積 blocking 集合僅餘 N1 一個 Warning，為第 2 輪修正未傳播到 `proposal.md` 所致。集合非空，因此不通過。

## Fix Actions

本輪修正涉及 4 個檔案：`openspec/changes/align-cli-skill-contracts/proposal.md`、`design.md`、`tasks.md`、`specs/cash-cli/spec.md`。

**逐項修正**

- N1（blocking Warning）：`proposal.md` A1 的依賴理由改為與 design D1 一致的兩層敘述——`## Impact` 標題是 spec 合併產生 trace 時界定區段的依據，三個標籤列是 impact 粒度提示計數 affected-code 條目的依據——並移除對 drift impact 路徑擷取的宣稱。
- N2（非 blocking，一併修正）：`tasks.md` 1.4 的驗收改為走訪層命題，補上「差集恰為封存 `reviews` 目錄下的檔案（走訪層命題，不受 `--limit` 排名截斷影響）」，與 design C4 及 cash-cli spec scenario 對齊。
- N3（非 blocking，一併修正）：`tasks.md` 2.2 移除行號引用，改為「與該檔 `**Input**` 段落中不含目錄前綴的既有引數範例一致」，與 D8 採同一種內容引用方式。
- N4（非 blocking，一併修正）：`tasks.md` 4.3 的斷言描述補上「斷言須含每個標籤後接冒號的形狀」；`specs/cash-cli/spec.md` 的「模板承載下游依賴的子結構」scenario 對應 AND 句補上「每個標籤後接冒號」，使斷言真正凍結下游依賴的字面形狀。
- N5（非 blocking，一併處理）：`design.md` D9 明文記錄該偽陰性為刻意接受的取捨，並說明接受理由——實測既有殘骸皆為一行一處，且此形狀來自變體字面值替換而非人工撰寫，同行成對出現的機率極低，以此換取零偽陽性與可用單一 regex 表達的簡單性。

**修正後的機械自我檢查**

四項檢查與 signal 衍生檢查全部通過。`cash validate align-cli-skill-contracts` 通過；`instructions apply --json` 的 `preflight.status` 為 `clean` 且 `missingFiles` 與 `driftedFiles` 皆為空。全域搜尋確認：對 drift impact 路徑擷取的錯誤依賴宣稱在全部 artifact 中已無殘留（僅 design D9 與 D1 保留作為「不屬於此依賴」的否定式註記）；以行號指涉 cash-ingest 範例的表述已無殘留。

**Reviewer V 於本輪額外確認的事項**

- 標籤 code span 改寫（第 2 輪 SC-1）後，規範側 design D1、C1、cash-cli spec 與 tasks 1.6 四處都以文字補上「每個標籤後接冒號」，實作者依 tasks 1.6 不會寫出錯誤的 `resources.py` 模板；缺口僅在斷言側，已由 N4 修正。
- `specs/cash-skill-workflows/spec.md` 全檔不出現三個標籤名，無同步對象，不需比照改寫。
- D8 否定式在 D8、C6 驗收、tasks 2.2、tasks 4.4 四處齊備且表述一致。

## Decision

next_round
