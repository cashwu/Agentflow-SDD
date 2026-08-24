# Cash Apply Review — Round 3

## Reviewer Findings

本輪是使用者要求處理 apply-r2 剩餘 `Suggestion` 後開啟的**新 run 的第一輪** full round（apply-r2 以 `passed` 結束，無 bucket-1 種子，故為 unseeded，不標註 `disposition`）。兩位 reviewer（A — Adherence、B — Quality）以相同 context 平行且獨立執行。

### Critical

無。

### Warning（皆為阻塞）

1. `severity`: Warning｜`confidence`: 85｜`layer`: design｜`location`: `scripts/cash-cli/tests/test_graph_instructions.py` 的 `test_no_contradiction_literal_matches_its_legitimate_negation`｜`summary`: task 4.1 新增的 `assert_accepted` 被放在 negation-containment 斷言**之前**，二者為嚴格蘊含關係，使後者永遠不可能成為首先或唯一失敗的斷言——即 D2 明文禁止的「以另一個較早失敗取代目標 guard」，並使 `tasks.md` 3.1 記錄的 red 證據「具名指出 literal 仍是其否定句的子字串」在現行程式碼下不可重現｜`recommendation`: 把 `assertNotIn` 移到 `assert_accepted` 之前，恢復其獨立診斷力與 3.1 的 red 訊息｜reviewer source: A

2. `severity`: Warning｜`confidence`: 85｜`layer`: design｜`location`: `scripts/cash-skills/tests/skill-checks.fish` 的 `LEGITIMATE_PROSE` 與 `leaked` 檢查｜`summary`: C3 的「含一般 `expected value` 的合法 prose MUST通過」與對應 spec scenario，其全部鑑別力寄託在 `LEGITIMATE_PROSE` 這個無錨定字串上；清空後該 acceptance case 靜默恆真而群組仍 `PASS`。reviewer 另證明它是 load-bearing：在 detector／fixture 同步漂移的情境下，它是 `en` 半邊僅存的執行期約束｜`recommendation`: 比照 Python 側，在 `leaked` 檢查前錨定 `LEGITIMATE_PROSE` 仍帶有歷史 false-positive token｜reviewer source: A

3. `severity`: Warning｜`confidence`: 85｜`layer`: design｜`location`: `scripts/cash-cli/tests/test_graph_instructions.py` 的三個 detector inventory；對照 `design.md` §Risks 的「具名的覆蓋缺口」｜`summary`: 本 diff 移除 HEAD 的 11 個 explicit forbidden literal，其中 **10 個** 現已被 validator 接受，但 §Risks 只列出 2 句並明文宣稱「只有這兩種措辭會通過」。C1 允許移除既有 literal 的前提是「與新的 obligation-specific contradiction 完全重複」，實際上 10 個都只被嚴格較窄的新 literal 部分涵蓋；required-marker 機制不補此洞，因為它們都是 additive 句、marker 仍在｜`recommendation`: 把 §Risks 的缺口列表改為完整枚舉這 10 句，使 C1 的「完全重複」前提與實際落差可稽核｜`introduced_by`: `git diff scripts/cash-cli/tests/test_graph_instructions.py` 的三個刪除 hunk 與新增的三個 detector dict｜reviewer source: B

### Suggestion

4. `severity`: Suggestion｜`confidence`: 75（原始 `severity` 為 `Warning`）｜`layer`: design｜`location`: `scripts/cash-cli/tests/test_graph_instructions.py` 的 `canonical_scopes` 與其後的 `assert_accepted`｜`summary`: 4.1 新增的「每句 append 到對應 canonical 後仍被該 validator 接受」，其對照表本身完全無守衛——把 `canonical_scopes` 整個塌縮成單一 TDD scope 仍 28 tests OK，因為跨 validator 的 restatement 一律被接受｜`recommendation`: 讓 mapping 帶自身斷言，或明文列出三個 scope 的 category 並斷言 exact set｜`introduced_by`: `git diff` 新增 hunk 內的 `canonical_scopes` 區塊與 `assert_accepted` 呼叫｜reviewer source: B

5. `severity`: Suggestion｜`confidence`: 65（原始 `severity` 為 `Warning`）｜`layer`: design｜`location`: `scripts/cash-cli/tests/test_graph_instructions.py` 的 particle tuple 與 `EXPECTED_NEGATION_RESTATEMENTS`｜`summary`: 另一項內容斷言的比對來源 `("不", "並非")` 為行內 tuple、無 exact-set 錨定，與同批修復對 `RETIRED_PERMISSIVE_TOKENS` 補上錨定的做法不對稱；更低成本的掏空連 tuple 都不必動——把 13 句全部改為單一字元 `不` 即 28 tests OK，`assertNotIn` 對任何 literal 恆真，不變式完全失效｜`recommendation`: 加 particle exact-set 斷言，並把「非空」升級為對 restatement 的最小結構要求；若不做，至少在 §Risks 把「單字元 restatement 可使不變式恆真」具名記錄｜`introduced_by`: `git diff` 新增 hunk 內的 particle 斷言與 `EXPECTED_NEGATION_RESTATEMENTS`｜reviewer source: B

6. `severity`: Suggestion｜`confidence`: 70｜`layer`: design｜`location`: `scripts/cash-skills/tests/skill-checks.fish` 的 canonical anchor 迴圈與新增的值相等斷言｜`summary`: canonical anchor 的判準是「clause 是 canonical 的逐字 span」，未要求最小長度或完整性；新增的值相等斷言只擋單方面漂移，擋不住 detector 與 fixture **同步縮短**。實測把兩份的 `bounded-mutation.zh` 同步縮為 `有限`（仍是 canonical 逐字 span）→ 六道檢查全部放行、`PASS: tdd-discipline`，結果是一個兩字元的高碰撞 matcher｜`recommendation`: 補下界，或在 §Risks 具名記下「anchor 只保證是 span，不保證是完整 gate 語意」｜`introduced_by`: `git diff scripts/cash-skills/tests/skill-checks.fish` 新增的 anchor 區塊與值相等斷言｜reviewer source: B

7. `severity`: Suggestion｜`confidence`: 50｜`layer`: design｜`location`: `design.md` §D5 的 13 句清單對照 `EXPECTED_NEGATION_RESTATEMENTS`｜`summary`: 13 句目前逐字相符，但兩份清單之間沒有任何機械綁定；程式碼側改寫後 D5 會靜默過時而 suite 仍全綠。D1 的 13 個 literal 與 D3 的十個 clause 有相同狀態｜`recommendation`: 於 §Risks 具名記錄此邊界，或另開 `/cash-ingest` 加入 artifact anchor｜reviewer source: A

### 兩位 reviewer 獨立完成的驗證（非 finding，記錄為本輪證據）

- **D5 免責條款的誠實性經雙向驗證**：宣稱封住的三種退化（13 句全改空字串、單句去掉否定詞、restatement 本身即為 contradiction）實測全部失敗；明文不宣稱涵蓋的「含否定詞但與該義務無關」實測全綠。免責與程式行為一致，非藉口。
- **§Risks 兩項具名缺口的敘述經實測**：`可以先做`／`可以先進行` 家族與 `短 task 可以不填 red 欄位。` 確實 ACCEPTED；`en` 半邊同步改寫確實 `PASS`，anchor 迴圈只取 `.get("zh")`，敘述無誇大。
- **C1 exact-set anchor 與 C3 值相等斷言皆能失敗且互不遮蔽**：`RETIRED_PERMISSIVE_TOKENS` 縮為單一元素、`視情況` 同步塞入 detector 與 fixture、fish 單方面縮短 detector clause，三者都具名失敗；fish 以 `record()` 累積而非提早 raise，不存在遮蔽。
- **移除 `assert_markers_intact` 未失去覆蓋**：該 helper 不存在於 HEAD，僅為本次工作的中間狀態；其唯一可能失敗的情境由 `assert_accepted`、`assert_rejected` 的 `startswith` 比對與 append 的結構性質三者合起來完整覆蓋。
- **逐字一致性**：D1 的 13 個 literal、D5 的 13 句 restatement 與程式碼三方逐字相符；`detector == fixtures` 成立。
- **complexity lens 無 finding**：未引入 dependency；`dict.fromkeys` 為 stdlib；三份平行 inventory 由 D2／D5 規定為獨立定義；`_reject_contradictions` 有三個呼叫點。
- **verification targets**：28 tests OK、`PASS: tdd-discipline`、`cli-checks.fish PASS: all`；兩份 spec delta 皆無 `##### Example:` 區塊；repo 狀態與 reviewer 接手時逐行相同。

## Rating

- post-filter cumulative blocking set Critical count：0
- post-filter cumulative blocking set Warning count：3
- 非阻塞 triaged finding count：0
- `critical_gap`: false
- `round_type`: full

rationale：本輪為 unseeded run 的第一輪，所有存活的 `Critical` 與 `Warning` 皆為阻塞。兩位 reviewer 合計提出 7 筆 finding，其中三筆 `confidence` 85 的 `Warning` 通過 confidence filter 而構成阻塞：negation-containment 斷言被自身修復的 `assert_accepted` 蘊含而失去獨立診斷力（違反 D2 明文條款且使 3.1 的 red 證據不可重現）、`LEGITIMATE_PROSE` 這個 load-bearing fixture 無錨定可被靜默掏空、以及 §Risks 對覆蓋缺口的敘述與實際落差（宣稱 2 句、實為 10 句）。三者都是本 change 主題「守衛必須能失敗」的反例，且全部由本次 diff 引入，因此不得 pass。另四筆 `Warning`／`Suggestion` 的 `confidence` 為 75／65／70／50，落於 `[50, 80)` 或原本即為 `Suggestion`，經 filter 後非阻塞。

## Fix Actions

本輪為 `next_round`，三筆阻塞 `Warning` 全部以「修復並命名修改檔案」處理，四筆非阻塞 finding 亦一併修復或以具名 Risks 記錄，無任何 finding 僅以 triage note 帶過。

修改的檔案：`scripts/cash-cli/tests/test_graph_instructions.py`、`scripts/cash-skills/tests/skill-checks.fish`、`openspec/changes/refine-cash-tdd-test-guards/design.md`、`openspec/changes/refine-cash-tdd-test-guards/specs/cash-cli/spec.md`。

- **Finding 1（阻塞）**：把 `assertNotIn` 移到 `assert_rejected`／`assert_accepted` 之前。反向驗證：把 `red-after-edit` 的 literal 同步還原為 modal 起始形式後，具名訊息 `contradiction literal is still a substring of a legitimate negated restatement of the same obligation` 重新成為首先失敗的診斷。同時在 C1 加入「negation-containment 斷言 MUST排在上述斷言之前」的契約項目。**已知殘餘**：該斷言與 `assert_accepted` 仍為嚴格蘊含關係（literal 若為 negation 的子字串，則 negation append 到 canonical 後必被拒），這是數學上的必然而非缺陷；修復達成的是 reviewer 指明的目標——恢復首先失敗的具名診斷與 3.1 的 red 證據可重現性，滿足 D2「不得以另一個較早失敗取代目標 guard」。
- **Finding 2（阻塞）**：在 `leaked` 檢查前加入對 `LEGITIMATE_PROSE` 的錨定，斷言它仍帶有 `expected value` 與 `verification target` 兩個歷史 false-positive token。反向驗證：清空 `LEGITIMATE_PROSE` → 兩筆具名 `record` 失敗、群組非零結束。
- **Finding 3（阻塞）**：`design.md` §Risks 的「具名的覆蓋缺口」改為完整枚舉——明確記載 HEAD 的 11 個 explicit literal 中只有 `blank-red` 逐字保留、其餘 10 個被窄化，並逐句列出實測仍被接受的 10 句，同時說明 C1 的「完全重複」前提與實際落差、以及 required marker 機制為何不補此洞。
- **Finding 4（非阻塞，已修復）**：`canonical_scopes` 加入 `label` 欄位，並對每個 category 新增 `assert_rejected(validator, canonical + 該 category 的 literal, because=f"forbidden {label} contradiction: {category}")`，把 validator、canonical、label 與 category 四者綁定。反向驗證：把 test-quality scope 塌縮成 TDD scope → `FAILED (failures=6)`。C1 同步加入此契約項目。
- **Finding 5（非阻塞，已修復並升級判準）**：`("不", "並非")` 抽為具名常數 `NEGATION_PARTICLES` 並加 exact-set 斷言；「非空且含否定詞」升級為結構規則——每句 restatement MUST包含「把該 category 的 literal 插入單一個 `不` 或 `並非` 後」所得的字串。此規則不需門檻常數也不需第四份 inventory，因為基準是已被 D1 釘死的 literal。代價是五句 restatement 改為純插入形式的同序否定（`unexecuted-red`、`red-after-edit`、`non-observable-result`、`framework-required`、`test-for-every-task`），D5 的 13 句清單同步更新。反向驗證：三種掏空（全部空字串、全部單字元 `不`、全部無關但含否定詞）由原本的 `OK`／部分 `OK` 全部變為 `FAILED (failures=13)`。此修復連帶解決 apply-r2 的 Suggestion 7（四句示範力較弱），13 句現一致採同序否定。
- **免責條款同步更正**：由於結構規則現已攔下「含否定詞但與該義務無關」的改寫，`design.md` D5 與 cash-cli spec 中宣稱攔不到該情形的免責條款已不成立，一併改寫為實際能力，並把殘餘邊界重述為「不保證否定詞的插入位置在中文語法上真的構成否定，且不禁止 restatement 附加其他文字」。留著已不成立的免責條款本身即為不準確敘述，故視同 Finding 3 同類問題處理。
- **Finding 6（非阻塞，以具名 Risks 記錄）**：於 §Risks 加入「canonical anchor 只保證是 span，不保證是完整 gate 語意」條目，具名記載 detector 與 fixture 同步縮短至仍屬 span 的短片語（例如 `執行有限 mutation check` → `有限`）會被六道檢查全部放行。採 reviewer 提出的最低成本方案，不引入長度門檻常數。
- **Finding 7（非阻塞，以具名 Risks 記錄）**：於 §Risks 加入「D5 的 13 句與 `EXPECTED_NEGATION_RESTATEMENTS` 之間沒有執行期綁定」條目，並註明 D1 的 13 個 literal 與 D3 的十個 clause 有相同狀態、其中只有 D3 的五個 `zh` clause 另有 canonical anchor。
- **Confidence filter 降級 trace（不計入 ledger `fixed_files`）**：Reviewer B finding 2（`canonical_scopes` 無守衛）原始 `severity` 為 `Warning`、`confidence` 75；Reviewer B finding 3（particle tuple 無錨定）原始 `severity` 為 `Warning`、`confidence` 65。兩者皆落於 `[50, 80)` 而降級為 `Suggestion`；兩者的 `introduced_by` 證據皆可驗證（指向具體 change-diff hunk 並附可重現的 mutation 實驗），故不適用 cash-apply introduced-by 的 `≤ 25` 降級。無 `confidence < 50` 的 finding 被丟棄。
- 無 `未修復：裁判面保護` 紀錄。無 accepted-risks 降級（該檔不存在）。無 disposition 修正（unseeded run 第一輪不標註）。
- **Post-fix 重跑的 pre-round mechanical self-check**：D1 的 13 個 literal 與 D5 的 13 句 restatement 皆與程式碼逐字相符；`NEGATION_PARTICLES`、fish 的 `LEGITIMATE_PROSE` 錨定與值相等斷言等識別字齊備；D5 無殘留舊 restatement 文字；兩份 spec delta 的註解計數為 0、無殘留 `---`、只有 `## ADDED Requirements`。`"$cash_cli" analyze` 為 0 Critical/Warning、`"$cash_cli" validate` 通過。verification 重跑：`PYTHONPATH=.cash-skills/lib python3 scripts/cash-cli/tests/test_graph_instructions.py` → 28 tests OK；`fish scripts/cash-skills/tests/skill-checks.fish tdd-discipline` → `PASS: tdd-discipline`；`fish scripts/cash-cli/tests/cli-checks.fish` → `PASS: all`；全量 `fish scripts/cash-skills/tests/skill-checks.fish` → `PASS: all`，exit 0。

## Decision

next_round
