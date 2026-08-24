# Cash Apply Review — Round 2

## Reviewer Findings

本輪是使用者要求修正 apply-r1 三筆非阻塞 `Suggestion` 後開啟的**新 run 的第一輪** full round（apply-r1 以 `passed` 結束，無 bucket-1 種子，故為 unseeded，不標註 `disposition`）。兩位 reviewer（A — Adherence、B — Quality）以相同 context 平行且獨立執行，未互相傳遞輸出。

### Critical

無。

### Warning

無。兩筆原始 `Warning` 皆因 `confidence` 落於 `[50, 80)` 而依 confidence filter 降級為 `Suggestion`；降級 trace 記於 `## Fix Actions`。

### Suggestion

1. `severity`: Suggestion｜`confidence`: 75｜`layer`: design｜`location`: `scripts/cash-cli/tests/test_graph_instructions.py` 的 `RETIRED_PERMISSIVE_TOKENS` 與 `test_validators_accept_legitimate_phrasings_with_retired_tokens` 的 inventory 迴圈｜`summary`: retired-token non-reinstatement 守衛的比對來源 `RETIRED_PERMISSIVE_TOKENS` 本身無任何斷言錨定，可被靜默削減後守衛失效而 suite 仍全綠｜`recommendation`: 加一行 `assertEqual(set(RETIRED_PERMISSIVE_TOKENS), {"可以不", "不必", "視情況"})`（C1 與 cash-cli spec 已逐字釘死這三個 token，屬 contract 內的 exact-set 斷言），或直接以迴圈中已硬寫的三個 token 驅動 inventory 檢查｜證據：把 tuple 改為 `("可以不",)` → 28 tests OK；再把 `mutation-skippable` 與其 fixture 同步改成 `視情況` → 仍 28 tests OK｜reviewer source: A

2. `severity`: Suggestion｜`confidence`: 70（原始 `severity` 為 `Warning`）｜`layer`: design｜`location`: `scripts/cash-cli/tests/test_graph_instructions.py` 的 `test_no_contradiction_literal_matches_its_legitimate_negation` 與 `EXPECTED_NEGATION_RESTATEMENTS`｜`summary`: negation-containment 守衛的唯一內容斷言是 `assertNotIn(literal, negation)`，restatement inventory 本身既無 artifact 依據也無內容斷言，退化時守衛靜默失效｜`recommendation`: 於同一 subTest 內補上把 restatement 與 literal 綁定的正向斷言（restatement 非空且含 `不` 或 `並非`；append 至對應 canonical 後 `assert_accepted`），並比照 D1 把 13 句 restatement 逐字寫入 `design.md` D5 使其可稽核｜`introduced_by`: `git diff scripts/cash-cli/tests/test_graph_instructions.py` 新增 hunk `@@ -399,11 +389,170 @@`（該 test 整段）與 `@@ -474,15 +627,73 @@`（`EXPECTED_NEGATION_RESTATEMENTS` dict）｜證據：把 dict 的 13 個 value 全換成 `""` → 28 tests OK｜reviewer source: A 與 B 獨立提出同一缺陷機制，依 `location + summary` 合併；`layer` 兩者皆為 `design`

3. `severity`: Suggestion｜`confidence`: 75｜`layer`: design｜`location`: `scripts/cash-cli/tests/test_graph_instructions.py` 的 `assert_markers_intact` 及其三個呼叫點｜`summary`: `assert_markers_intact` 是恆真斷言——mutation 一律是 `canonical + "\n" + contradiction` 的 append，append 不可能移除 marker；把 helper body 換成 `return` 後 suite 仍 28 tests OK，且其唯一可能失敗的情境已由同一 test 開頭的 `assert_accepted` 先行捕捉｜`recommendation`: 移除，或改為對未 mutation 的 canonical 斷言並與 `assert_accepted` 合併，避免在一個以「守衛必須能失敗」為主題的 change 裡留下無法失敗的斷言｜reviewer source: B

4. `severity`: Suggestion｜`confidence`: 60｜`layer`: design｜`location`: `scripts/cash-skills/tests/skill-checks.fish` 的 `FORBIDDEN_GATE_CLAUSES`／`EXPECTED_GATE_FIXTURES` 與其 exact-set 檢查｜`summary`: fish checker 只斷言 detector 與 fixture 的 gate exact set 與 `zh`／`en` key set，未斷言兩邊 clause **值**相等（Python 側對應處有 `assertEqual(detector, fixtures)`），detector clause 可被單方面縮短成更高碰撞的片段而群組仍綠｜`recommendation`: 在兩個 exact-set 檢查之後補 `if FORBIDDEN_GATE_CLAUSES != EXPECTED_GATE_FIXTURES: record(...)`；此非 derivation，兩份 inventory 仍各自逐字固定，使 C3 的「逐字等於」在兩側對稱｜證據：只把 detector 的 `bounded-mutation.zh` 由 `執行有限 mutation check` 縮為 `有限 mutation check`（fixture 不動）→ `PASS: tdd-discipline`｜reviewer source: A

5. `severity`: Suggestion｜`confidence`: 60｜`layer`: design｜`location`: `scripts/cash-cli/tests/test_graph_instructions.py` 的 contradiction inventory；對照點為 apply-r1 之前被移除的三個 `assert_rejected`｜`summary`: 三個被刪除的 `assert_rejected` 中有兩句現已被 validator 接受且新 inventory 無對應涵蓋——`但在時間緊迫時，也可以先做 production edit 再補跑該 target。`（TDD）與 `短 task 可以不填 red 欄位。`（tasks）實測皆被接受，即 `可以先做`／`可以先進行` 這一家 additive 弱化句在 TDD 側目前零覆蓋｜`recommendation`: D1 已把 inventory 逐字釘死於 `design.md` 與兩份 spec，擴充需經 `/cash-ingest`；最低成本是於 `design.md` §Risks 具名記下這兩句「舊 suite 曾斷言、新機制刻意不再攔截」的實例，使取捨可稽核｜reviewer source: B

6. `severity`: Suggestion｜`confidence`: 50｜`layer`: design｜`location`: `scripts/cash-skills/tests/skill-checks.fish` 的 anchor 迴圈與十個 clause 中的五個 `en` clause｜`summary`: canonical anchor 只錨定五個 `zh` clause，五個 `en` clause 在 detector 與 fixture 同步漂移時無任何斷言會失敗；而四份 `SKILL.md` 以英文為主，實務上承載去重鑑別力的是 `en` 半邊｜`recommendation`: `en` 無法對繁中 canonical 做逐字 anchor，可改為錨定 spec delta 中已逐字釘死的十個 clause 文字，或於 `design.md` D5 明記「`en` 半邊僅由 spec 文字約束、無執行期 anchor」的殘餘風險｜reviewer source: B

7. `severity`: Suggestion｜`confidence`: 50｜`layer`: design｜`location`: `scripts/cash-cli/tests/test_graph_instructions.py` 的 `EXPECTED_NEGATION_RESTATEMENTS` 中 `red-after-edit`、`non-observable-result`、`framework-required`、`test-for-every-task` 四句｜`summary`: D1 的判準是「否定詞必須落在 literal 的比對範圍之內」，但這四句並非新 literal 的同序否定——兩句省略主詞、兩句把主詞移到句尾——斷言通過的原因是主詞缺席／換序而非否定詞位置，示範力較弱（reviewer 以同序否定重算後不變式仍全部成立，故非斷言錯誤）｜`recommendation`: 改為保留主詞的同序否定使 13 個 category 一致示範 D1 判準；若刻意保留現形式（因其正是 apply-r1 Suggestion 1 指出的原始誤判句），於 D5 說明選用理由｜reviewer source: A

### 兩位 reviewer 獨立完成的驗證（非 finding，記錄為本輪證據）

- 13 個 detector literal 與 `design.md` D1 逐字一致，且無任一 literal 以 `可以`／`必須`／`每個` 起始。
- negation-containment 不變式對全部 13 個 category 都有鑑別力，非只有本次 reshape 的四個：兩位 reviewer 各自逐一檢查若 literal 退回 modal 起始形式，對應否定句都會含之而觸發失敗；Reviewer B 另逐一算出每個 category「最長的去前綴 literal 仍會被其否定句命中」的邊界。
- `EXPECTED_NEGATION_RESTATEMENTS` 為獨立定義，未從 detector registry 或 contradiction fixture 推導；exact-set 斷言先行且涵蓋 D1 全部 13 個 category。13 句逐一 append 至對應 canonical 後皆被 validator 接受，證明它們是合法句而非會自打嘴巴的 fixture。
- `tasks.md` 3.1 的 `red` 證據真實且可重現：Reviewer A 在 scratch 副本把四個 literal 同步還原為 pre-ingest 形式後，primary target 以 `FAILED (failures=4)` 結束，四個具名 subTest 與訊息與記錄一致。
- D2 的 guard-only deletion 對全部 13 個 category 成立：逐一刪除 detector entry 並保留 fixture，每次都直接觀察到**目標** additive-mutation subTest 失敗。
- `tasks.md` 3.2 的 success 可重現：detector 與 fixture 的 `zh` clause 同步漂移時 injection self-test 仍通過而 anchor 具名失敗；把 `DISCIPLINES["test-quality"]` 改為不存在的 key 或把 lib path 指向不存在目錄，皆 `record()` 具名失敗並 exit 1，fail closed 成立，未靜默跳過。
- retired-token 守衛具備三個 acceptance case 沒有的獨立鑑別力：把 `視情況` 在 detector 與 fixture 同步塞進 test-quality inventory（category set 與 detector==fixtures 皆仍成立、三個 acceptance case 皆攔不到）→ 只有該守衛的 subTest 失敗。
- `implementation-notes.md` 兩筆 `deviation` 準確，且 `/cash-ingest` 的回寫確實發生：canonical anchoring 進入 D5 與 C3、retired-token non-reinstatement 進入 D5 與 C1、negation-containment 進入 D1／D5／C1，兩份 spec 各補上規範段落與對應 scenario。第一筆註記的宣稱經 mutation 實測成立。
- `design.md` code-facing claims 對照通過；C1 保留的 carrier-neutral、framework-neutral、no-formal-test 三項邊界仍為 required marker；C2 三個 acceptance case 各含適用的舊裸 token 且被接受。
- 範圍與 verification：實作 diff 恰為兩個 delivery path；canonical `DISCIPLINES`、tasks artifact resource、四份 `SKILL.md`、manifest 與 bundle version 均未變動。兩份 spec delta 皆無 `##### Example:` 區塊，三條新增 normative rule 都有對應 scenario。
- apply-r1 Suggestion 4（`clean` baseline 取自 live artifact）經 Reviewer B 複驗後不再成立並主動撤回：若該檔真的含有某 clause，live-file 迴圈與全部 injection self-test 會同時 `record` 失敗，無法靜默恆真。Reviewer A 以 `confidence` 45 提列同一項，經 confidence filter 丟棄。

## Rating

- post-filter cumulative blocking set Critical count：0
- post-filter cumulative blocking set Warning count：0
- 非阻塞 triaged finding count：0
- `critical_gap`: false
- `round_type`: full

rationale：本輪為 unseeded run 的第一輪，所有存活的 `Critical` 與 `Warning` 皆為阻塞。兩位 reviewer 合計提出 10 筆 finding，去重後 9 筆；其中兩筆原始 `Warning` 的 `confidence` 分別為 75 與 70、其餘 `Suggestion` 為 75／60／60／55／50／50／45／40，全部落於 `[50, 80)` 或原本即為 `Suggestion`，無任何 finding 達到 `confidence ≥ 80`。因此 post-filter 後無存活的 `Critical` 或 `Warning`，cumulative blocking set 為空，符合 pass 條件。實作面經兩位 reviewer 各自獨立的 guard-deletion、clause-neutering、literal-restore 與 fail-closed mutation 實驗，確認 13 個 contradiction guard、13 個 negation 不變式、10 個雙語 clause、canonical anchor 與 retired-token 守衛都具備個別鑑別力，`tasks.md` 3.1 的 RED 證據可獨立重現，且 primary 與全部 regression targets 全綠。本輪存活的七筆 `Suggestion` 有一個共同主題——守衛的**輸入**（`RETIRED_PERMISSIVE_TOKENS`、`EXPECTED_NEGATION_RESTATEMENTS`、fish 兩份 inventory 的值相等性）本身缺乏錨定——已列於完成輸出交由使用者決定是否另開一輪修正。

## Fix Actions

None; pass condition met.

- Confidence filter 降級與丟棄 trace（不計入 ledger `fixed_files`）：
  - Reviewer A finding 1（`RETIRED_PERMISSIVE_TOKENS` 未錨定）原始 `severity` 為 `Warning`、`confidence` 為 75，落於 `[50, 80)`，降級為 `Suggestion`。
  - Reviewer B finding 1（negation restatement inventory 可被靜默掏空）原始 `severity` 為 `Warning`、`confidence` 為 70，落於 `[50, 80)`，降級為 `Suggestion`。其 `introduced_by` 證據可驗證（指向具體 change-diff hunk 並附可重現的 mutation 實驗），故不適用 cash-apply introduced-by 的 `≤ 25` 降級。
  - 該筆與 Reviewer A finding 3 為同一缺陷機制（negation restatement inventory 為無人守衛的 guard input），依 `location + summary` 合併為本輪 Suggestion 2；兩者 `layer` 皆為 `design`，合併後取較高的 `confidence` 70。
  - Reviewer A finding 5（injection baseline 取自 live artifact）`confidence` 45，低於 50 而丟棄；Reviewer B 已就同一項主動撤回並提出實測理由。
  - Reviewer A finding 6（C4 的 changed-file inventory 未列入 loop 寫入的 `openspec/signals/`）原始 `layer` 為 `text`，因其修法會變更 C4 的契約敘述而依 confidence filter 重分類為 `design`；`confidence` 40 低於 50 而丟棄。
  - 其餘 findings 原始即為 `Suggestion`，無降級。
- 無 `未修復：裁判面保護` 紀錄：本輪未有任何 finding 的修復需要動到受保護的 grader 路徑。`scripts/cash-skills/tests/skill-checks.fish` 雖屬受保護集合，但其 project-root-relative path 同時出現在 proposal `## Impact` 的 affected-code 條目與 `tasks.md` 的 delivery target，屬 structured scope declaration 涵蓋範圍。
- 無 accepted-risks 降級：`openspec/changes/refine-cash-tdd-test-guards/reviews/accepted-risks.md` 不存在。
- 無 disposition 修正：unseeded run 的第一輪不標註 `disposition`。
- Pre-round mechanical self-check（spawn reviewer 前，main agent inline 執行）結果：兩份 spec delta 的 `<!--`／`-->` 計數皆為 0、無殘留 `---` 分隔線、只有 `## ADDED Requirements` 故 title-identity check 不適用；scenario 計數 6 與 5、tasks 4 個且全為 `[x]`；數量宣稱（13 個 category、五個 gate、十個 clause）與實作實際計數一致；`design.md` D1 的 13 個 category literal 逐字存在且在 delivery file 中 detector 與 fixture 各一份；spec 列出全部 13 個 category 名稱；`EXPECTED_NEGATION_RESTATEMENTS`、`FORBIDDEN_GATE_CLAUSES`、`EXPECTED_GATE_FIXTURES`、`RETIRED_PERMISSIVE_TOKENS`、`DISCIPLINES["test-quality"]` 等 design 定義的識別字在實作中齊備；`negation-containment` 同時出現於 `design.md` 與 cash-cli spec delta。`openspec/signals/` 的 149 個 signal 全為 `status: open` 且無任何 `check` frontmatter 欄位，故 signal-derived check 執行步驟為 no-op，改以既有 best-effort 判斷處理相關 signal issue class（已於 reviewer context 中列出）。自 check 未發現任何需修正的缺陷。

## Decision

passed

本輪 post-filter cumulative blocking set 不含任何阻塞 `Critical` 或阻塞 `Warning`，符合 pass 條件，本次 run 於第一輪結束。七筆存活的 `Suggestion` 皆為非阻塞：其中 Suggestion 1、3、4 可在既有 delivery path 與現行 contract 內修復，Suggestion 2、5、6 需經 `/cash-ingest` 變更 `design.md` 或 spec，Suggestion 7 屬示範力而非正確性。依 Focused Implementation Discipline 不於本輪自行擴張範圍，全部列於完成輸出交由使用者決定。
