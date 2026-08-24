## Context

`strengthen-cash-tdd-evidence` 已在 `scripts/cash-cli/tests/test_graph_instructions.py` 建立三個 validator，分別治理 TDD executed RED／GREEN、test-quality 與 tasks 五欄 resource；也在 `scripts/cash-skills/tests/skill-checks.fish` 的 `tdd-discipline` 群組治理 `cash-apply`／`cash-debug` 的 canonical consumer 與單一來源。

現有 suite 全綠，但 review 證明三個精準度缺口。resource validators 的顯式 `forbidden` tuples 未被直接 mutation 行使；共用 `PERMISSIVE_CONTRADICTIONS` 以裸 token 判斷，可能拒絕合法的 remaining-task 或 no-test 說明；skill checks 的 `test_quality_gate_literals` 混用過於泛化的 `expected value` 與未對齊 canonical 語意的片語，無法同時保證低誤報與有效去重。

本 change 是 test-only refactor，建立在 `strengthen-cash-tdd-evidence` 已完成的檔案形狀上。實作前應先封存或至少保留該 change 的現行實作，避免兩個 active changes 對相同測試 hunk 產生不必要衝突。

## Goals / Non-Goals

### Goals

- 每個保留的 prohibition 都由一個只加入該矛盾句、保留全部 required markers 的 additive mutation 直接行使。
- validator 拒絕具體的 contract 弱化句，而不是拒絕 `可以不`、`不必`、`視情況` 等裸 token。
- validator tests 明確證明合法近義措辭仍被接受。
- skill 單一來源檢查使用完整、低碰撞的繁中canonical原文與英文equivalent雙語clauses，並以in-memory mutation證明每個clause都有鑑別力。
- 保留 `tdd-discipline`、resource tests、variant parity 與全量 regression 行為。

### Non-Goals

- 不修改任何 canonical discipline、artifact resource 或 skill workflow 本文。
- 不推導任意自然語言等價、不建立 NLP matcher。
- 不新增 dependency、test framework 或 mutation framework。
- 不修改 `.agents`／`.claude` skill 內容、generator、CLI runtime 或 bundle version。

## Decisions

### D1：以 validator-specific additive contradictions 取代裸 token

移除共用的 `PERMISSIVE_CONTRADICTIONS`／`_reject_permissive` 裸 token 機制。每個 validator 擁有下列逐字固定、以 category 命名的 additive contradiction inventory：

- TDD：`carrier-fixed` = `evidence carrier 一定是 tasks.md`；`unexecuted-red` = `推測結果即可視為有效 red evidence`；`red-after-edit` = `primary verification target 可以在 production edit 後再執行`。
- test-quality：`derived-expected` = `expected value 可以由受測程式、其 helper 或同一套邏輯推導`；`non-observable-result` = `結果可以用 source text、private structure 或 mock 自身存在代替`；`unbounded-mock` = `mock 可以切任何 internal boundary`；`framework-required` = `有限 mutation check 必須新增 mutation framework`；`test-for-every-task` = `本 discipline 要求每個 task 都必須新增測試`；`mutation-skippable` = `時間不足時可以略過 mutation check`。
- tasks：`multiple-primary` = `verification 可以命名多個 primary targets`；`mixed-success` = `success 可以一併記錄 regression、publication 或 task completion 結果`；`blank-red` = `red 不適用時可以留空`；`placeholder-fields` = `欄位可以留空或填 TBD／TODO`。

既有 required marker 檢查繼續負責 removal 與 replacement inversion；additive contradiction 集合只負責「正確文字仍在，但又附加互斥例外」的情況。兩者責任不重疊。

每個 literal 都必須滿足 **negation-containment 不變式**：把該 literal 改寫成「強化同一義務」的合法否定句時，literal 不得仍是該否定句的子字串。判準是否定詞（`不`、`並非`）必須落在 literal 的比對範圍**之內**而非之前，因此 literal 不得以 `可以`、`必須`、`每個` 這類 modal 或量詞起始，必須先帶出被規範的主詞（例如 `primary verification target 可以⋯`、`結果可以用⋯`、`有限 mutation check 必須⋯`、`本 discipline 要求每個⋯`）。違反此不變式的 literal 會把「未來為了強化義務而做的 canonical 改寫」誤判為 forbidden，重新引入本 change 要移除的 false-positive class。

### D2：每個 rejection path 都以 rejection class 驗證

production validator registry 與 test fixture inventory MUST分開定義：tests 使用逐字固定的 `EXPECTED_*_CONTRADICTION_FIXTURES`，不得從受測 registry import、iterate 或轉換產生。tests MUST先斷言兩邊 category key set 等於 D1 的固定集合，再用 fixture inventory 驅動 mutation。

對 required marker removal／replacement mutation，測試 MUST斷言 `missing` rejection；對每個 additive contradiction，測試 MUST把完整 canonical text 保留，只附加一個獨立 fixture 的矛盾句，並斷言 `forbidden` rejection。刪除 detector registry 的單一 guard但保留固定 fixture時，primary target MUST因 mutation 被接受而失敗；不得以同步刪除 fixture或另一個較早失敗取代目標 guard。

同一組 tests 另加入合法措辭 acceptance cases，至少涵蓋：remaining task 不必建立 red phase、未修改測試時可以不取得 test-quality，以及沒有自動測試邊界時視情況採 manual assertion。這些 cases 必須包含先前裸 matcher 會命中的 token，證明 false-positive path 已移除。

### D3：skill 去重檢查採完整低碰撞 clauses

將 Fish 中的泛用 `test_quality_gate_literals` 改為一個小型 in-memory validator。固定五個gate，每個gate各有一個繁中canonical原文與一個低碰撞英文equivalent，共十個逐字clauses：

- `named-defect`：`命名一個會使該測試失敗的 realistic production defect`；`name a realistic production defect that would make the test fail`。
- `independent-expected`：`expected value 以 literal 或手工驗證 fixture 獨立推導`；`derive the expected value independently from a literal or hand-verified fixture`。
- `observable-assertion`：`斷言 consumer-visible output、state、side effect 或 failure mode`；`assert consumer-visible output, state, side effect, or failure mode`。
- `mock-boundary`：`mock 只切 slow 或 external boundary`；`mock only a slow or external boundary`。
- `bounded-mutation`：`執行有限 mutation check`；`perform a bounded mutation check`。

validator 對四份 live `cash-apply`／`cash-debug` skill text執行。production forbidden-clause registry 與固定 mutation fixtures MUST分開定義；fixtures不得從registry推導。tests先斷言五個gate與每個gate的`zh`／`en`key set，再由fixtures把十個clauses逐一append到乾淨skill text，必須被拒絕。刪除registry任一clause但保留fixture時，primary target MUST失敗。

合法 acceptance mutations 至少包含一般 example prose 的 `expected value` 與不重述完整 gate 的 verification 說明，必須被接受。此 checker只防止完整 canonical gate clause 被複述，不宣稱偵測所有自然語言 paraphrase。

### D4：不擴張交付範圍

只修改 `scripts/cash-cli/tests/test_graph_instructions.py` 與 `scripts/cash-skills/tests/skill-checks.fish`。不修改 managed runtime 或 skill bytes，因此不遞增 bundle version、不執行 self-install，也不重建 manifest／receipt。

### D5：精確度不變式的機械覆蓋

D1–D3 建立的三個精確度性質，若只靠「當初寫對了」維繫，就會退化成沒有守衛的點狀修正。三者各自加上機械覆蓋：

- **negation-containment**：tests 持有一份與 detector registry 及 contradiction fixture inventory 都獨立定義、逐字固定的 negation restatement inventory，為 D1 的每個 category 各寫一句強化同一義務的合法否定句；斷言 category key set 與 D1 相等，且每個 literal 都不是其否定句的子字串。這份 inventory 本身是守衛的輸入，因此比照 D1 把 13 句逐字釘在本節，並要求 tests 另加內容斷言，避免 inventory 被靜默弱化（例如全部改為空字串）後守衛失效而 suite 仍全綠：

  - `carrier-fixed`：`evidence carrier 不一定是 tasks.md`
  - `unexecuted-red`：`推測結果並非即可視為有效 red evidence`
  - `red-after-edit`：`primary verification target 不可以在 production edit 後再執行`
  - `derived-expected`：`expected value 不可以由受測程式、其 helper 或同一套邏輯推導`
  - `non-observable-result`：`結果不可以用 source text、private structure 或 mock 自身存在代替`
  - `unbounded-mock`：`mock 不可以切任何 internal boundary`
  - `framework-required`：`有限 mutation check 並非必須新增 mutation framework`
  - `test-for-every-task`：`本 discipline 不要求每個 task 都必須新增測試`
  - `mutation-skippable`：`時間不足時不可以略過 mutation check`
  - `multiple-primary`：`verification 不可以命名多個 primary targets`
  - `mixed-success`：`success 不可以一併記錄 regression、publication 或 task completion 結果`
  - `blank-red`：`red 不適用時不可以留空`
  - `placeholder-fields`：`欄位不可以留空或填 TBD／TODO`

  內容斷言採一條結構規則而非長度或關鍵字門檻：每句 restatement MUST包含「把該 category 的 literal 插入單一個 `不` 或 `並非` 後」所得的字串。這條規則不需要任何門檻常數，也不需要第四份 inventory，因為它直接以已被 D1 釘死的 literal 為基準；它同時封住空字串、單字元、缺否定詞，以及「含否定詞但與該義務無關」四種掏空。每句另 MUST在 append 到對應 canonical 文本後被該 validator 接受，證明它不是一句會自我矛盾的字串；validator 與 category 的對應本身 MUST由「該 category 的 literal append 到同一 canonical 後必須被同一 validator 以具名 `forbidden <label> contradiction: <category>` 拒絕」綁定，避免對照表被靜默錯接。

  13 句一律採「保留主詞的同序否定」，即 literal 原文加一個否定詞，使全部 category 一致示範 D1 的判準，並讓上述結構規則得以成立。
- **canonical anchoring**：`skill-checks.fish` 的 in-memory validator 於 injection 與 acceptance 檢查之後，另行讀取 canonical `DISCIPLINES["test-quality"]`，斷言五個 `zh` clause 仍是其逐字 span。這是 anchor assertion 而非 derivation：十個 clause 仍逐字固定、fixtures 仍不從 registry 推導，只是額外證明兩份文本沒有分岔。取得 canonical 沿用本檔既有的 `sys.path.insert(0, sys.argv[N])` 模式，import 或 key 失敗時 fail closed。
- **retired-token non-reinstatement**：C1 要求移除的裸 permissive matcher，先前只靠「程式碼裡沒有那段」被動成立而無任何斷言守著。tests 改為斷言 `可以不`、`不必`、`視情況` 三個 retired token 都不得成為任一 detector inventory 的完整 value；此守衛涵蓋既有 acceptance cases 攔不到的跨 validator 位置（例如把 `視情況` 加進 test-quality inventory，三個 acceptance case 都不會失敗）。

## Implementation Contract

### C1：Resource validator rejection paths

- `scripts/cash-cli/tests/test_graph_instructions.py` MUST移除以裸 `可以不`／`不必`／`視情況` 判斷的共用 permissive matcher。
- TDD、test-quality、tasks 三個 validators 的category與literal inventory MUST逐字等於D1；其中明確保留carrier-neutral、framework-neutral與no-formal-test三項既有邊界。
- 每個保留的 explicit contradiction MUST有一個 canonical-required-markers 全部仍存在、且不從detector registry推導的 additive mutation case。
- additive mutation MUST以 `forbidden` rejection 被捕捉；required marker removal／replacement MUST以 `missing` rejection 被捕捉。
- 若某個既有 explicit `forbidden` literal 與新的 obligation-specific contradiction 完全重複，SHALL只保留一份 source-of-truth。
- 每個 contradiction literal MUST滿足 D1 的 negation-containment 不變式；tests MUST以一份獨立定義、逐字固定的 negation restatement inventory 逐一驗證，並先斷言其 category key set 等於 D1 的固定集合。
- tests MUST斷言 `可以不`、`不必`、`視情況` 三個 retired 裸 token 都不是任一 detector inventory 的完整 value，且 MUST以 exact set 斷言錨定這三個 token 本身。
- negation restatement inventory 的 13 句 MUST逐字等於 D5 所列；tests MUST斷言每句包含「把該 category 的 literal 插入單一個 `不` 或 `並非` 後」所得的字串，MUST以 exact set 斷言錨定這兩個否定詞，MUST斷言每句 append 到對應 canonical 文本後仍被該 validator 接受，並 MUST以「該 category 的 literal append 到同一 canonical 後被同一 validator 以具名 `forbidden <label> contradiction: <category>` 拒絕」綁定 validator 與 category 的對應。negation-containment 斷言 MUST排在上述斷言之前，使 literal 退化時它是首先失敗且具名的診斷。

### C2：合法措辭不誤判

- Resource tests MUST加入至少三個 acceptance cases，分別覆蓋 TDD remaining-task、test-quality no-test scope 與 tasks manual verification。
- acceptance text MUST實際包含 `可以不`、`不必` 或 `視情況` 中適用的舊裸 token，且 validator MUST接受。
- acceptance cases MUST保持 canonical required markers 不變，避免以不執行 validator 的方式取得假通過。

### C3：Skill test-quality 單一來源檢查

- `scripts/cash-skills/tests/skill-checks.fish` MUST不再以單獨的 `expected value` 或與 canonical 語言不對齊的短片語作為去重失敗條件。
- 去重 marker MUST逐字等於D3的十個雙語clauses，分別對應 named defect、independent expected、observable assertion、mock boundary 與 bounded mutation check。
- checker MUST對 `.agents` 與 `.claude` 的 `cash-apply`／`cash-debug` 四份 skill 執行。
- 每個 forbidden clause MUST有由獨立固定fixture驅動的append-injection mutation證明checker會失敗；detector與fixture的五個gate及`zh`／`en`key sets MUST逐項相等；含一般 `expected value` 的合法 prose MUST通過。
- checker MUST斷言五個 `zh` clause 仍是 canonical `DISCIPLINES["test-quality"]` 的逐字 span；取得 canonical 失敗時 MUST fail closed，MUST NOT 靜默跳過該斷言。此 anchor 只涵蓋 `zh` 半邊。
- checker MUST斷言 detector 與 fixture 兩份 inventory 的 clause 值逐字相等，使 C3 的「逐字等於 D3」在 fish 側取得與 Python 側對稱的機械覆蓋。
- checker MUST以具名 `LEGITIMATE_PROSE_TOKENS` inventory 固定 `expected value` 與 `verification target` 兩個 acceptance fixture token，並以 inline fixed set 對該 inventory 執行 exact-set 斷言；fixture 與 token inventory 任一者單獨或同步削減時，`tdd-discipline` MUST非零結束。

### C4：Verification

- Primary resource target 為 `PYTHONPATH=.cash-skills/lib python3 scripts/cash-cli/tests/test_graph_instructions.py`，須直接觀察全部 validator mutation／acceptance tests 通過。
- Primary skill target 為 `fish scripts/cash-skills/tests/skill-checks.fish tdd-discipline`，須直接觀察四份skill、十個雙語注入mutations、合法prose與variant parity全部通過。
- Regressions 為 `fish scripts/cash-skills/tests/skill-checks.fish` 與 `fish scripts/cash-cli/tests/cli-checks.fish`。
- 實作不得修改 canonical resource、skill bytes、manifest 或 bundle version。每個task在完成前 MUST檢查自身change-scoped edit inventory只含該task的`delivery` path；cash-apply最終review的changed-file inventory MUST只含兩個affected-code test paths與本change artifacts／reviews，不得以整個dirty worktree相對HEAD的diff作為判準。

## Risks / Trade-offs

- 精確句型無法捕捉所有自然語言 paraphrase。這是刻意邊界：deterministic checker只治理明確列出的 canonical-equivalent clauses，避免通用 token matcher 的誤報。
- negation restatement 的殘餘邊界：D5 的結構規則要求 restatement 含「literal 插入單一否定詞」的結果，因此空字串、單字元、缺否定詞與無關字串四種掏空皆被攔下（皆經實測）。它不保證插入位置在中文語法上真的構成否定——例如把否定詞插在詞中的無意義位置仍會滿足規則——也不禁止 restatement 在該必要子字串之外附加其他文字。這一層由 D5 的 13 句逐字清單與 code review 保證。
- 具名的覆蓋缺口：舊 suite 曾以裸 token 攔下的 `但在時間緊迫時，也可以先做 production edit 再補跑該 target。`（TDD）與 `短 task 可以不填 red 欄位。`（tasks）兩句，在 D1 的 inventory 下不再被拒絕，即 `可以先做`／`可以先進行` 這一家 additive 弱化句在 TDD 側目前零覆蓋。這是以「移除裸 token 誤報」換取的已知代價。更完整地說：HEAD 的 11 個 explicit forbidden literal 中，只有 `red 不適用時可以留空`（即 `blank-red`）逐字保留，其餘 10 個都被 D1 窄化為帶主詞的 obligation-specific 句型，因此以舊措辭書寫的 additive 弱化句一律不再攔截——實測 `tasks.md`、`推測結果即可`、`可以在 production edit 後`、`expected value 可由受測程式`、`可以用 mock 自身存在代替結果`、`必須新增 mutation framework`、`每個 task 都必須新增測試`、`verification 可以命名多個 target`、`success 可以一併記錄 regression`、`欄位可以留空或填 TBD` 這 10 句 append 到對應 canonical 後全部被接受。C1 允許移除既有 literal 的前提是「與新的 obligation-specific contradiction 完全重複」，實際上這 10 句只被嚴格較窄的新 literal 部分涵蓋；required marker 機制不補這個洞，因為它們都是 additive 句、marker 仍在。若日後出現實際誤用，應經 `/cash-ingest` 把對應句型以符合 negation-containment 不變式的形式加入 D1 的 inventory，而非恢復裸 token。
- `en` 半邊無執行期 anchor：D5 的 canonical anchoring 只能錨定五個 `zh` clause，因為 canonical `DISCIPLINES["test-quality"]` 是繁體中文。五個 `en` clause 僅由 spec delta 的逐字文字約束，若 detector 與 fixture 同步漂移則無執行期斷言會失敗——detector 與 fixture 的值相等斷言只保證兩份一致，不保證仍對應 canonical 語意。四份 `SKILL.md` 以英文為主，因此這是承載較多實務鑑別力的一側；接受此殘餘風險而不引入翻譯對照表，是為了不讓 checker 依賴任何非逐字的語意推導。
- D5 的 13 句與 `EXPECTED_NEGATION_RESTATEMENTS` 之間沒有執行期綁定：程式碼側改寫後本節會靜默過時而 suite 仍全綠，逐字一致性由 code review 保證。D1 的 13 個 literal 與 D3 的十個 clause 有相同狀態；其中只有 D3 的五個 `zh` clause 另有 canonical anchor。
- canonical anchor 只保證是 span，不保證是完整 gate 語意：detector 與 fixture 若**同步**把某個 `zh` clause 縮短成仍屬 canonical 逐字 span 的短片語（例如把 `執行有限 mutation check` 縮為 `有限`），key set 檢查、值相等斷言、canonical anchor、injection self-test 與合法散文 acceptance 五道都會放行，結果是一個高碰撞的短 matcher。加下界需引入長度門檻或唯一性規則等額外判準；本 change 選擇具名記錄此邊界而不引入門檻常數。
- 移除重複 prohibition 可能看似降低 guard 數量；以 additive mutation逐一證明保留 guard 的實際鑑別力，比未被行使的分支更強。
- 新 change 與 `strengthen-cash-tdd-evidence` 修改相同測試區域。應先封存前者或在實作時以最新檔案為 baseline，避免 active change 間 hunk drift。
