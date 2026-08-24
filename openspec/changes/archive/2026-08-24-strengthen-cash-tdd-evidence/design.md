## Context

Cash 目前以 .cash-skills/lib/cash_cli/resources.py 的 DISCIPLINES["tdd"] 擁有 TDD 完整語意，cash-apply 只在 tdd: true 時按需取得；四分支 precedence 已區分 bug fix、observable behavior change、pure refactor 與 remaining task，並拒絕由 earlier guard、pre-existing failure 或相同 exit code 冒充 RED。

實際缺口有三個。第一，canonical instruction 要求測試因目標行為不存在而失敗，但未明說必須在 production edit 前實際執行命名 target、觀察 failure marker，並於修改後重跑同一 target。第二，測試有效性沒有獨立 contract；即使走完 RED/GREEN，mirror assertion、source-text assertion 或只驗證 mock 的測試仍可能是 false green。第三，ARTIFACT_GRAPH 的 tasks template 只提供泛稱驗證，弱於 cash-apply 已要求的 named verification target。另有 cash-debug 在 tdd: false 時仍無條件要求 failing test，與 cash-apply 的 toggle 語意不同。

現有 skill generation 以 .claude/skills 為人工維護來源，.agents/skills 為生成輸出；skill_payload 直接從 DISCIPLINES dictionary 查值，因此加入 test-quality 不需要新增 parser 或 dispatch branch。replaceable runtime／skill bytes 與 bundle version、manifest 綁定，因此首次 managed-byte edit 前必須先 bump version；之後每個修改 managed bytes 的 implementation task 都須在自身 edits 完成後執行 ./install-cash-skills.fish --self 重建 manifest／receipt，最後才可 task done。

## Goals / Non-Goals

### Goals

- 將 RED 與 GREEN 定義成實際執行並觀察的事件，而非只建立測試檔或推測結果。
- 以獨立、按需載入的 canonical test-quality discipline 治理所有新增或修改的測試，不受 tdd toggle 影響。
- 讓 tasks resource 對每個 task 產生可被 cash-apply 直接消費的 delivery、verification、regression、success 與 red 欄位。
- 讓 cash-apply 與 cash-debug 對 tdd: true／false 使用相同 ordering 語意，並共同消費 test-quality。
- 以 deterministic resource／consumer／variant tests 防止語意或生成輸出漂移。

### Non-Goals

- 不移除或重排現有四分支 TDD precedence。
- 不把 TDD 改成無條件啟用，不改 .cash.yaml schema 或預設值。
- 不規定 test framework、coverage threshold、檔案配置或每個 function 都必須有測試。
- 不建立 evidence ledger 或 LLM behavior eval harness。
- 不要求處理與 change 無關的 pre-existing suite failure。

## Decisions

### D1：TDD instruction 加入 executed RED／GREEN gate

DISCIPLINES["tdd"] 保留現有四分支文字與順序。對前兩個需要 red phase 的分支追加 carrier-neutral 共同 gate：在任何 production edit 前執行目前 workflow 命名的 primary verification target，實際觀察 assertion 到達目標路徑，且 failure marker 能辨識目標行為尚未存在；若 target pass、execution error、停在較早 guard，或只有一般 exit code 相同，RED 未成立。production edit 後重跑同一 target 並觀察 success marker，再執行 workflow 命名的 regression target。pure refactor 與 remaining task 不受 red gate 約束，但仍執行各自 verification target。

這裡的 evidence 是當前 task loop 的 tool output 與判定，不新增持久化 schema。cash-apply 的既有 task-done verification gate仍負責最後完成條件。

### D2：Test quality 與 TDD ordering 分離

DISCIPLINES 新增 test-quality key，instructions --skill test-quality 使用既有 skill_payload path 回傳相同三欄 shape。該 discipline 只在 agent 新增或修改測試時載入，不新增 config toggle：

1. 寫 test body 前先命名一個會使測試失敗的 realistic production defect；無法命名時改測 observable contract。
2. expected value 使用 literal 或手工驗證 fixture，MUST NOT由受測程式、其 helper 或同一套邏輯推導。
3. 斷言 consumer-visible output、state、side effect 或 failure mode；不得以 source text、private structure 或 mock 自身存在代替結果，除非該 call shape 本身就是 contract。
4. mock 只切 slow／external boundary，保留測試所依賴的真實 side effects；mock response 必須包含測試路徑實際會消費的完整 contract shape。
5. 完成前對 wrong branch／argument、missing side effect、empty/default return 與必要 validation 做有限 mutation check；只需涵蓋與 task contract 有關的 realistic mutations，不引入 mutation framework。

cash-apply 與 cash-debug 只保留 consumer invocation，不複述上述內容。test-quality 不要求某個 task 一定新增測試；它只治理已決定新增或修改的測試。

本 change 建立 DISCIPLINES["test-quality"] 自身時存在一次性 bootstrap：在 resource 尚不存在的首次 test edit 前，implementer MUST直接遵循本 design C2 已定義的五項 gate。完成 bundle version 與 managed resource edits 後，MUST先執行 `./install-cash-skills.fish --self` 重建可信 manifest／receipt，再以 project-local CLI 執行 `instructions --skill test-quality` 並確認回傳 instruction 與已實作 canonical resource 逐字同源；這個 CLI check 是 self-install 後的第一個步驟，且必須在任何後續 test edit 前完成。此例外只適用 strengthen-cash-tdd-evidence 的 resource bootstrap task，不成為一般 workflow fallback。

### D3：Tasks template 使用單行可消費 contract

ARTIFACT_GRAPH 中 tasks 的 description 與 template 改為要求每個 checkbox task 使用下列單行欄位：

- delivery：具體 project-root-relative delivery paths。
- verification：唯一 primary test、CLI、analyzer 或 manual assertion，供需要 red phase 時同一 target RED→GREEN。
- regression：primary 轉綠後執行的零個或多個相關 regression targets；無額外 target 時填 N/A 並說明 primary 已涵蓋完整相關範圍。
- success：僅由 verification 欄位的 primary target 直接觀察到的成功 marker；regression、publication 或 task completion 結果不得混入。
- red：需要 red phase 時的可辨識 failure marker；不適用時填 N/A 並指出所屬 pure-refactor 或 remaining-task 分支理由。

欄位與 checkbox 同列，讓既有 task parser 的 description 可直接承載；不新增 tasks schema、nested parser 或新的 CLI command。這些欄位定義 evidence，不複述 Red-Green-Refactor sequence。

### D4：Cash workflows 的 consumers 對齊

cash-apply 在 project preferences 段維持 tdd toggle；另在進入 task loop前明示新增或修改測試時取得 instructions --skill test-quality。task loop 將 tasks.md 的 verification、regression、success 與 red 分別映射為 canonical TDD 的 primary target、regression targets、success marker 與 failure marker；任一必要欄位缺失，或 tdd: true 且 red 欄位與 canonical 分類矛盾時，依既有 unclear-task branch 暫停，不猜測。

cash-debug 的 Phase 3 在完成 root-cause hypothesis 後、進入 Phase 4 前，於既有 debug notes 中明列 primary verification target、regression targets、success marker，以及需要 red phase 時的 failure marker；不需要 red phase 時記 N/A 與分類理由。Phase 4 先讀 .cash.yaml：tdd: true 時取得 canonical TDD instruction並消費這些 notes；tdd: false 時不強迫 fail-first ordering。兩者都要求 named verification target、最小 root-cause fix、相關 regression target；新增或修改測試時取得 test-quality。既有「Phase 4 always starts with a failing test」絕對句移除，以免重新定義與 canonical resource 互斥的 ordering。

兩個 workflow 的 .claude 檔為 source，.agents 檔由既有 generator 產生；所有新增 consumer command 都必須納入 command matrix 與 variant parity。

### D5：Deterministic governance 與 bundle sequencing

scripts/cash-cli/tests/test_graph_instructions.py 擴充為：

- 驗證 DISCIPLINES key set 恰為 tdd、audit、test-quality。
- 分別斷言 executed RED、same-target GREEN、related regression 與既有四分支／假 RED排除。
- 分別斷言 test-quality 五個 gate，並拒絕 expected value 自我推導、source-text／mock-only assertion 與無邊界 mock。
- 驗證 tasks resource 的五個欄位、primary／regression分型及單行 template。

scripts/cash-cli/tests/test_discovery_contracts.py 驗證三個 discipline payload 的 exact shape。scripts/cash-skills/tests/skill-checks.fish 擴充 tdd-discipline 群組，驗證 cash-apply／cash-debug 的 toggle、test-quality consumer、retired absolute debug rule、command matrix 與兩變體生成對等。測試以正向與移除／反轉 mutation 同時把關，避免只檢查上界或單一 marker。

第一個 implementation task 先新增 resource tests 並依 C2 bootstrap gate 觀察具名 RED；在首次受 version-history 守衛的 managed behavior edit 前，再 bump cash-skills.version 與 installer BUNDLE_VERSION，然後修改 resources。全部 managed resource edits 完成後立即執行 `./install-cash-skills.fish --self` 更新 manifest／receipt；self-install 後第一個步驟是以 project-local CLI 取得並驗證 test-quality instruction，通過後才可進行後續 test edit、same-target GREEN與regression verification。每個修改 managed runtime／skill bytes 的 task 都必須在自身全部 managed edits 完成後執行該次 self-install，之後才呼叫 task done。修改 .claude skill source 的 task 另須先重新生成 .agents variants，再執行該次 self-install，避免任何 task 邊界留下 receipt_invalid。

## Implementation Contract

### C1：Executed RED／GREEN

- 對 canonical TDD 前兩分支，agent MUST在任何 production edit 前實際執行目前 workflow 命名的 primary verification target。
- 有效 RED MUST到達目標 assertion，並觀察到 workflow 命名的 failure marker；pass、execution error、較早 guard、pre-existing failure 或僅相同 exit code皆不成立。
- production edit 後 MUST重跑同一 target並觀察命名的 success marker，再執行 workflow 命名的 regression targets。
- pure refactor 與 remaining task 維持現有無 red phase 路徑。

### C2：Canonical test-quality

- instructions --skill test-quality MUST逐字回傳 DISCIPLINES["test-quality"]，payload 恰含 skill、locale、instruction。
- 每次 cash-apply 或 cash-debug 新增／修改測試前 MUST取得並遵循該 instruction；未修改測試時 MUST NOT為形式而新增測試。
- instruction MUST包含 named defect、independent expected、observable assertion、mock boundary 與 bounded mutation check五項，且不要求特定 framework或新增 dependency。
- 僅在本 change 建立該 resource 的首次 test edit 前，MUST以本 C2 五項 gate自舉；完成 managed resource edits 後 MUST先self-install，並以CLI取得與驗證逐字同源作為發布後第一個步驟，通過後才可進行後續test edit，不得保留一般fallback。

### C3：Tasks resource contract

- tasks resource 的 description 與 template MUST要求每個 checkbox task 同列 delivery、verification、regression、success、red 五欄，其中 verification 恰為 primary target。
- regression無額外target時 MUST為 N/A並說明primary已涵蓋完整相關範圍；不得把多個未分型commands全部塞入verification。
- success MUST只描述verification欄位的primary target可直接觀察的成功marker；相關suite、manifest／receipt、publication或其他completion evidence屬於regression或task delivery，不得混入success。
- red 不適用時 MUST為 N/A並附 pure-refactor 或 remaining-task 分類理由；不得留空或以 TBD／TODO 代替。
- cash-apply MUST將verification／regression／success／red映射到canonical discipline的primary target／regression targets／success marker／failure marker；遇到缺欄或欄位與 Implementation Contract／canonical TDD classification 矛盾時，MUST走既有 unclear-task branch，不得寫 production code或 task done。

### C4：cash-debug toggle parity

- tdd: true 時 cash-debug Phase 4 MUST取得並遵循 instructions --skill tdd；tdd: false 時 MUST NOT強迫 fail-first ordering。
- cash-debug MUST在Phase 3 notes中先命名primary verification target、regression targets、success marker與failure marker或N/A理由，供carrier-neutral instruction消費。
- 兩個 toggle 值都 MUST保留 named verification、minimal root-cause fix與相關 regression verification。
- cash-debug MUST移除無條件 failing-test與 Phase-4-always-failing-test絕對句；新增／修改測試時仍 MUST遵循 test-quality。

### C5：Variant、tests 與 bundle

- .claude 與 .agents 的 cash-apply／cash-debug 在 invocation prefix 正規化後相關 consumer段落逐行相同，.agents 由 generator 重新產生而非手改。
- tdd-discipline 具名群組與全量 skill checks MUST同時涵蓋 cash-apply、cash-debug、test-quality consumer、retired literals、task五欄、cash-debug無tasks.md carrier與 command matrix。
- CLI resource與discovery tests MUST涵蓋三個 discipline exact set、payload shape、所有新增語意與反向 mutation。
- cash-skills.version、installer BUNDLE_VERSION與 manifest bundle_version MUST一致遞增；managed bytes更新後在同一 task內以 ./install-cash-skills.fish --self 重建完整 manifest／receipt。

## Risks / Trade-offs

- test-quality instruction 增加 task loop context。以按需載入且只在新增／修改測試時執行，避免每個 task無條件載入。
- tasks 單行五欄可能使長 task 可讀性下降。欄位只承載短 target與evidence，複雜驗證細節仍放 design Implementation Contract；保持單行是為了沿用既有 parser並避免新增 schema。
- red failure marker 若寫得過度具體，可能釘住非 contract 文案。規則要求 marker 辨識目標路徑，但允許 diagnostic、state、artifact 或等價 assertion；優先使用穩定 observable state，只有診斷本身屬 contract 才逐字釘住。
- mutation check 可能被誤解為全面 mutation testing。contract 明訂 bounded、mental或局部fixture即可，且只涵蓋 task 的 realistic mutations，不新增工具或 coverage threshold。
- cash-debug 在 tdd: false 時不再強制 fail-first，降低單一 workflow 的局部嚴格度，但換得全域 toggle一致性；verification與regression gate仍不變。
- 真實 agent 行為是否遵守仍未由 deterministic tests直接證明。本次刻意不建立非決定性 harness，待 canonical contract穩定後另案評估。
