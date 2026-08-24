<!-- cash-apply implementation notes | change: refine-cash-tdd-test-guards | initialized: 2026-08-24 16:57 | no entries below means no deviations or open questions were recorded -->

## 2026-08-24 17:52 — 品質關卡通過後補強兩項非阻塞 reviewer 建議
- 類別：deviation
- 任務：1、2
- 內容：Round 1 review loop 已以 `decision: passed` 結束後，使用者要求修正其中兩筆非阻塞 `Suggestion`。因此在兩個既有 delivery path 內各補一項 contract 未明文要求的守衛：(1) `scripts/cash-skills/tests/skill-checks.fish` 的 `assert_test_quality_single_source` 新增 anchor assertion，斷言五個 `zh` clause 仍是 canonical `DISCIPLINES["test-quality"]` 的逐字 span，沿用檔案既有的 `sys.path.insert(0, sys.argv[N])` 模式取得 `cash_cli`，import 或 key 失敗時 fail closed；(2) `scripts/cash-cli/tests/test_graph_instructions.py` 把 `assertIn(token, RETIRED_PERMISSIVE_TOKENS)` 這條套套邏輯斷言換成「三個 retired 裸 token 都不得成為任一 detector inventory 的完整 value」的實質守衛。兩者都以 mutation 證明具獨立鑑別力：detector 與 fixture 的 `zh` clause 同步漂移時只有 anchor 會失敗；把 `視情況` 加回 test-quality inventory 時三個 acceptance case 都攔不到，只有新守衛的 subTest 失敗。
- 原因：D3／C3 只要求十個 clause 逐字固定，未要求錨定 canonical；C1 只要求「移除裸 permissive matcher」而沒有任何機械覆蓋證明它未被重新加入。兩項補強都超出 contract 明文範圍，依 Focused Implementation Discipline 屬刻意 deviate，故記錄於此。第三筆 `Suggestion`（D1 中 `red-after-edit`、`non-observable-result`、`framework-required`、`test-for-every-task` 四個 literal 會被其 `不`／`並非` 前綴的合法反述命中）未處理，因為 C1 已把該 inventory 逐字釘死於 `design.md` D1 與兩份 spec，變更需經 `/cash-ingest`。

## 2026-08-24 18:20 — 前一筆 deviation 已由 cash-ingest 回寫為 contract
- 類別：deviation
- 任務：3.1、3.2
- 內容：使用者要求先 ingest 再修正。`/cash-ingest` 已把上一筆 deviation 記錄的兩項守衛回寫成 contract：canonical anchoring 進入 `design.md` D5 與 C3、retired-token non-reinstatement 進入 D5 與 C1，並在兩份 spec delta 補上對應規範文字與 scenario。同一次 ingest 另把 D1 中 `red-after-edit`、`non-observable-result`、`framework-required`、`test-for-every-task` 四個以 modal 起始的 literal 改為先帶出被規範主詞的形式，並新增 negation-containment 不變式與其機械覆蓋。因此上一筆 deviation 的兩項超出 contract 的守衛，現已全部有 artifact 依據，不再是 deviation。
- 原因：依 Implementation Notes Protocol，justified 但未記錄於 `design.md` 的 deviation 應回寫進 `design.md`。原始 deviation 條目依 protocol 保留不刪改，本條目作為其解決記錄。

## 2026-08-24 19:05 — apply-r2 三筆非阻塞 Suggestion 的修復
- 類別：deviation
- 任務：1、2、3.1、3.2
- 內容：apply-r2 以 `decision: passed` 結束後，使用者要求修復其中不需再 ingest 的三筆 `Suggestion`。三項都落在既有 delivery path 與既有 contract 項目內，未新增 contract，因此不另立 task：(1) `test_validators_accept_legitimate_phrasings_with_retired_tokens` 開頭加 `assertEqual(set(RETIRED_PERMISSIVE_TOKENS), {"可以不", "不必", "視情況"})`，把 C1 與 cash-cli spec 已逐字釘死的三個 token 錨定成 exact set；(2) `assert_test_quality_single_source` 在兩個 key-set 檢查之後加 `if FORBIDDEN_GATE_CLAUSES != EXPECTED_GATE_FIXTURES: record(...)`，使 C3 的「去重 marker MUST逐字等於D3的十個雙語clauses」在 fish 側取得與 Python 側 `assertEqual(detector, fixtures)` 對稱的機械覆蓋；(3) 移除恆真的 `assert_markers_intact` helper 與其三個呼叫點——mutation 一律是 append，不可能移除 marker，其唯一可能失敗的情境已由同一 test 開頭的 `assert_accepted` 捕捉。三項都以 reviewer 原本能全綠的 mutation 反向驗證：tuple 縮成單一元素、detector 單方面縮短 clause，現在都具名失敗；`assert_markers_intact` 已無殘留引用。
- 原因：這三筆是 apply-r2 的非阻塞 `Suggestion`，依 confidence filter 未進入 cumulative blocking set，故不是 loop 內的 fix action；由使用者在 loop 結束後指定修復。(1) 與 (2) 補的是既有 contract 項目缺少的機械形式，(3) 移除的是與本 change「守衛必須能失敗」主題直接衝突的恆真斷言，三者皆不擴張 contract，故未觸發 `/cash-ingest`。apply-r2 仍有四筆未修的 `Suggestion`（negation restatement inventory 缺 artifact 依據與內容斷言、`可以先做`／`可以先進行` 在 TDD 側零覆蓋、`en` 半邊無執行期 anchor、四句 negation 示範力較弱），其修法都需變更 `design.md` 或 spec，留待使用者決定是否另開 `/cash-ingest`。

## 2026-08-24 19:40 — negation restatement inventory 的錨定與 spec 過度宣稱的自我修正
- 類別：deviation
- 任務：4.1、4.2
- 內容：使用者要求處理 apply-r2 剩餘四筆 `Suggestion` 中唯一有實質鑑別力缺口的一筆。`/cash-ingest` 把 13 句 negation restatement 逐字釘入 `design.md` D5、把三項錨定寫進 C1／C3、並在 Risks 具名記下三項殘餘風險；實作面為 negation inventory 加上兩項內容斷言（每句非空且含 `不` 或 `並非`；每句 append 到對應 canonical 後仍被該 validator 接受）。撰寫 spec 時我一度寫成「inventory 退化成空字串或**任意字串**時該不變式非零結束」，隨後以反例實測推翻——把 `framework-required` 改為 `這句話與該義務無關但含有不字` 後 suite 仍 28 tests OK——因此把 `design.md` D5 與 cash-cli spec 的敘述改為只宣稱封住「空字串、缺否定詞、restatement 本身即為 contradiction」三種退化，並在該 requirement 明文 `MUST NOT` 宣稱能辨識「含否定詞但與該義務無關」的改寫。
- 原因：D5 的兩項內容斷言在機制上只能觸及上述三種退化；要涵蓋語意正確性需為每個 category 再釘一個 obligation core 片語，等於再產生一份需要被守衛的 inventory。本 change 選擇停在此層並把邊界寫成 artifact 的具名取捨，避免 `stated-criterion-diverges-from-applied-criterion` 形狀的過度宣稱。apply-r2 另三筆 `Suggestion`（`可以先做` 家族零覆蓋、`en` 半邊無執行期 anchor、四句 negation 示範力）已於同一次 ingest 分別寫入 `design.md` Risks 與 D5 作為具名取捨，不再有未處理的 apply-r2 finding。

## 2026-08-24 20:30 — apply-r3 fix actions 取代了前一筆的免責條款
- 類別：deviation
- 任務：4.1
- 內容：apply-r3 的 Reviewer B 證明前一筆記錄的免責條款所依據的判準過弱——把 13 句 restatement 全部改為單一字元 `不` 時 suite 仍 28 tests OK，`assertNotIn` 對任何 literal 恆真。fix actions 把「非空且含否定詞」升級為結構規則：每句 restatement MUST 包含「把該 category 的 literal 插入單一個 `不` 或 `並非` 後」所得的字串。新規則連帶攔下前一筆宣告攔不到的「含否定詞但與該義務無關」改寫，因此 `design.md` D5 與 cash-cli spec 的該免責條款已改寫為實際能力，殘餘邊界重述為「不保證插入位置在中文語法上真的構成否定，且不禁止 restatement 附加其他文字」。實作代價是五句 restatement 改為純插入形式的同序否定，D5 的 13 句清單同步更新；此變更連帶解決 apply-r2 的 Suggestion 7。
- 原因：前一筆的免責條款在寫下時是誠實的，但其判準本身可被掏空，使該免責的保護寬度只有一個字元——這一點當時未被發現。依 Implementation Notes Protocol 保留原條目不刪改，以本條目記錄其被取代。完整的 finding、修法與反向驗證記於 `openspec/changes/refine-cash-tdd-test-guards/reviews/apply-r3.md` 的 `## Fix Actions`。

## 2026-08-24 21:10 — fish 側 legitimate-prose 錨定為超出 contract 明文的守衛
- 類別：deviation
- 任務：2.1
- 內容：apply-r3 Finding 2 的修復在 `scripts/cash-skills/tests/skill-checks.fish` 的 `assert_test_quality_single_source` 加入一項執行期斷言：`LEGITIMATE_PROSE` 必須仍含有 `expected value` 與 `verification target` 兩個歷史 false-positive token，否則 `record()` 具名失敗。此守衛未寫入 `design.md` C3／D5，也未寫入 `cash-skill-workflows` spec delta——與同一 delivery path 的另兩項 fish 側守衛（canonical anchor、detector↔fixture 值相等）不同，那兩項都有 contract 與 spec 依據。反向驗證：清空 `LEGITIMATE_PROSE` → 兩筆具名 record 失敗；只移除其中一個 token → 對應的單筆具名失敗。
- 原因：C3 已要求「含一般 `expected value` 的合法 prose MUST通過」，該守衛只是為這條既有 contract 項目補上「其 fixture 不得被靜默掏空」的機械形式，不擴張 contract 的行為面，因此未觸發 `/cash-ingest`。依 Implementation Notes Protocol 記為 `deviation`；若後續要把它提升為 contract，應於 C3 與 `cash-skill-workflows` spec 各補一條，與既有兩項 fish 側錨定對稱。此為 Reviewer V 於 round 4 提出的兩個處理選項中的第二項。

## 2026-08-25 07:03 — legitimate-prose token exact-set 守衛已回寫為 contract
- 類別：deviation
- 任務：5.1
- 內容：使用者要求修正 apply-r4 留下的非阻塞 suggestion；`cash-ingest` 已在 proposal、design C3、`cash-skill-workflows` spec 與新增 task 5.1 明訂具名 `LEGITIMATE_PROSE_TOKENS` inventory 及 inline fixed-set exact-set 斷言，使 token inventory 與 `LEGITIMATE_PROSE` 同步削減時仍非零失敗。
- 原因：前一筆 deviation 只錨定 fixture 內容，尚未錨定該守衛自身的比對來源；本次回寫把使用者確認的額外守衛納入 durable contract，後續實作不再屬未記錄的偏離。
