## Context

plus review loop（`scripts/spectra-plus/template/review-loop-block.md`，經 generate.fish 組進四份生成的 SKILL.md）目前的收斂機制在大型 diff 上失效。實測證據來自外部專案的 `00-codify-simulcast-review-findings`（~27 個 production Kotlin 檔的高併發 change）：13 輪全為 full round、Critical 數從未趨零；r7 之後的六輪 findings 幾乎全是前輪 fix 引入的新原語（fallback cycle → cycleId → media-bound slot → lease state machine）的缺陷；r10–r12 三輪 `fixed_files=0` 空轉；abort 後只能原樣重跑。同時本 repo 自身的歷史 loop（apply 6 輪收斂、propose 2 輪收斂）顯示小 diff 下現有機制可用——問題集中在「每輪全面重掃 + fix 面擴大」的組合。

現行機制關鍵約束：round file / ledger 的 `round_type` 值域為 `full`/`micro`、`decision` 值域為 `passed`/`next_round`/`aborted`，且有既有測試（scripts/spectra-plus/tests/generator-checks.fish）斷言模板字串。

## Goals / Non-Goals

**Goals:**

- 讓 review loop 的每一輪成為對「上輪 delta」的漸進驗證，而非對整個 diff 的獨立重抽樣。
- 阻止 fix loop 內的設計級連鎖（新同步原語／狀態機在迴圈內誕生又被迴圈自己找到 bug）。
- 提供結構化的 accepted-risk 與 abort triage 出口，取代「原樣重跑」。
- 消除零動作輪次（surviving finding 未修復也未分流就進下一輪）。

**Non-Goals:**

- 不加入 Critical refuter 對抗驗證（實測 13 輪的 Critical 絕大多數為真，false positive 膨脹不是本案根因；成本不划算）。
- 不改變 round file 四段結構、`decision` 值域、ledger 七欄格式與 `round_type` 值域（`full`/`micro` 保留，`micro` 語意重定義為 delta 驗證輪）。
- 不改變 6 輪上限、confidence filter 門檻（<50 丟棄、[50,80) 降 Suggestion、≥80 保留）。
- 不修改 spectra CLI 本體；全部改動在模板、rules.yaml、測試與 spec。

## Decisions

### 反轉輪型推導：micro 為預設、full 只在 round 1 與 round 4 checkpoint

現行規則「micro 若且唯若無 Critical 且 Warning 全為 text」在併發 code 上不可達（13/13 full）。反轉後：run 的第 1 輪為 full；之後預設 micro（Reviewer V 驗證輪）；若到達本 run 第 4 輪時尚未 pass，該輪強制為 full（唯一的複掃 checkpoint，捕捉 Reviewer V 窄視野漏掉的 fix 交互回歸）；第 5、6 輪回到 micro。輪型與 6 輪上限以「run 內位置」計，round file 編號則全域遞增（見 abort triage decision）。同時**移除**兩條與新設計矛盾的規則：「micro 不得連續」與「post-decision 修改觸及行為即 re-derive 為 full」——delta 設計下修復本來就會改行為，保留該升級規則會使所有輪次退化回 full，重現非收斂。移除 re-derivation 時，master spec 三處殘留引用必須同步改寫，避免懸空引用：「Review loop grader immutability」的宣告範圍例外句、「Review loop ledger output」的 append 時序句、「Fresh sub-agent per round」的決策推導句（改為引用 cumulative blocking set）與 Reviewer V 描述，以及模板 GRADER-IMMUTABILITY 段的對應句。層級（layer）欄位與其分類規則保留（仍用於 finding 描述），但不再參與輪型推導。

替代方案：維持現行推導、僅放寬 micro 進入條件——被否決，因為只要「有 Critical 就 full」存在，併發 code 仍永遠 full。

### Delta pass 語意與 blocking set 定義

run 首輪之後的任何輪次，以 per-finding `disposition` 欄位機械判定 blocking。該輪每個 reviewer（micro 輪的 V；第 4 輪 checkpoint 的 A、B）必須為每個 Critical/Warning finding 標記 disposition 三值之一：`unresolved-prior`（匹配本 loop 任一前輪的 blocking finding，無論是否曾記錄修復；re-run 時含前一 run 的 bucket-1 種子）、`fix-introduced`（finding 內附明確的 fix action 引用，指向本 loop——seeded re-run 時含前一 run——`## Fix Actions` 記錄的一筆或多筆修改；V 與 propose-plus reviewer 標此值時同樣必附引用，不依賴 apply-plus 專屬的 introduced_by 欄位義務）、`new`（不匹配任何前輪 blocking finding 者；僅匹配前輪分流 note 的 re-report 也標 new，維持 non-blocking 且不重複產生分流 note 與 signal）。跨輪 finding 身分匹配規則與 accepted-risks 相同粒度：同一 artifact／檔案＋同一缺陷機制，行號範圍僅供參考（advisory）。為使 disposition 可驗證，首輪之後每輪 reviewer context 必附本 loop 全部 prior round files 與當前 cumulative blocking set 成員清單；主 agent 必須逐一核對 disposition 標記並更正不成立者；對每個標 `new` 的 finding，必須額外檢查其 location 是否被本 loop——seeded re-run 時含前一 run——的 fix actions 改過，缺陷源自該修改時更正為 `fix-introduced` 並在更正記錄附上引用——防止 reviewer 漏附引用使 fix 回歸流進 new 桶。`unresolved-prior` 的定義不看 fix 記錄——只要匹配前輪 blocking finding 即成立，re-report 本身就是「已記錄的 fix 未解決問題」的證據；`new` 桶排除任何匹配前輪 blocking finding 者——防止「記錄一個無效 fix」把未解決的 blocking finding 洗進 new 桶再永久分流；僅匹配前輪分流 note 的 re-report 標 new 但不重複產生分流 note 與 signal。blocking ⇔ disposition 為 `unresolved-prior` 或 `fix-introduced`；「最近一次狀態為 non-blocking 分流」的 finding 再次被報告時維持 non-blocking，不得回升（防止分流即失效）；唯一例外：後續證據將其歸因於已記錄的 fix actions 時，經留痕的 disposition 更正以 `fix-introduced` 回進集合。dedupe 後 disposition 分歧時取 blocking 值（unresolved-prior/fix-introduced 勝過 new）；主 agent 更正 reviewer 的 disposition 必須留痕（原標記、更正後標記、證據，記於 `## Fix Actions`），blocking→non-blocking 的更正並列入完成輸出——不留痕的更正通道等同漂白。`new` 的 finding 為 non-blocking：記入該輪 round file 的 `## Fix Actions` 分流小節（triage note），走 signals write step，Critical 級在完成輸出中建議產生後續 change proposal。此外主 agent 必須維護 run 的 cumulative blocking set：成員只有兩條明定出口——(a) 已記錄修復且下一輪 reviewer 驗證解決（未再報告＋確認修復位置有效；V 與第 4 輪 checkpoint 的 A/B 都須對每個成員回報 resolved/unresolved 判定，checkpoint 因此同樣可觸發出口 (a)，兩位 reviewer 判定分歧時任一 unresolved 即保留成員；每次移除留痕於該輪 `## Fix Actions`：成員＋修復引用＋驗證 reviewer）；(b) 匹配經同意的 accepted-risks 條目（每輪重新比對 ledger，移除時留 downgrade trace）。裁判面保護的成員無自主迴圈內出口（禁止修復，僅同意接受的出口 (b) 適用）；當全部成員都是裁判面保護且無可得的同意出口時（needs-design 情形已由斷路器直接 abort，不經此路徑），主 agent 必須以 aborted 短路結束並執行 triage，不再空轉 spawn reviewer——條件在 fix 階段（決策已推導後）才成立時，該輪尚未定稿的 round file 直接記 aborted，覆寫已推導的 next_round。即使本輪 reviewer 未再報告，未離開集合的成員仍計入決策——防止 blocking finding 因 reviewer 視野而靜默漏出。已完成輪次的 round file 在 loop 進行中不可回改（fix 記錄與 triage note 只能寫在事件發生的那一輪），round files 是 disposition 判定與集合成員資格的 gate input，回改即可竄改集合。首輪之後每輪 reviewer context 必附全部 prior round files；累積量超過實際可用 context 時，改附每輪摘錄（surviving findings＋完整 `## Fix Actions`），並在當輪 `## Fix Actions` 留一行註記使用了摘錄與涵蓋輪次。pass 條件＝cumulative blocking set 於 filter 後無 Critical/Warning。Rating 與 ledger 的 criticals/warnings 計數改計 post-filter cumulative blocking set（決策依據本身，carryover 輪次因此自我可解釋），Rating 另記 non-blocking 分流數；`critical_gap` 重定義為「post-filter cumulative blocking set 含 Critical」（首輪為 surviving Critical；seeded re-run 首輪同樣用 cumulative set，此 carve-out 同步寫進 Fresh sub-agent per round、Round file output contract、ledger 的首輪括號句），與計數同基準，carryover 輪次不會出現 criticals=1 卻 critical_gap=false 的自相矛盾；`critical_gap: true` 搭配 `decision: passed` 因此不再可能，non-blocking Critical 存在時仍可 pass、資訊由分流數與完成輸出承載。loop 的 done 語意由「整個 diff 無缺陷」改為「本 change 已提出的 findings 已解決且修復未引入回歸」；完成輸出必須醒目列出全部 non-blocking triage findings，避免弱化後的 gate 靜默吞掉真缺陷。

### Accepted-risks ledger 採 finding 級匹配

新增 `openspec/changes/<change>/reviews/accepted-risks.md`。條目的新增、修改、刪除都僅能在使用者明確同意下進行（互動環境用 AskUserQuestion；無法互動時不得自動寫入）；loop 進行中主 agent 不得以 fix action 名義修改或刪除既有條目——此檔是 confidence filter 的輸入（gate input），寫入面必須受治理。每輪 reviewer context 必附此檔；與某條目「同一 location 且同一缺陷機制」的 finding，主 agent 在 confidence filter 時一律降至 ≤ 25，行號範圍僅供參考（位移不破壞匹配，避免後續修改使既有 accepted risk 靜默失效）；cumulative blocking set 成員每輪重新比對此 ledger，匹配即移除（經同意的接受因此是集合的正式出口，不會把 loop 逼到 cap-abort）。每次套用降分必須記錄於該輪 round file 的 `## Fix Actions`（finding＋匹配條目），完成輸出列出全部套用記錄——降分不留痕即是漂白通道。此降分與 introduced_by 降分對「direct artifact violation 必為 100」的既有不變式有明示優先權（於 Confidence-scored findings and filter 的 MODIFIED delta 中宣告）。匹配粒度刻意收窄到 finding 級而非 issue-class 級：實測中 r6 的 C4 殘留（documented intentional）與 r7 的新 Critical 屬同一 subsystem 但為不同真實缺陷，issue-class 級匹配會誤殺 r7 那種真 bug。

### 設計級斷路器走 aborted，不新增 decision 值

斷路器限定 apply-plus loop：若修復某 surviving finding 需要引入 design.md 未定義的新同步原語（mutex/lock/semaphore）、身份或世代型別（token/epoch/generation id）、或狀態機，主 agent 不得在 fix loop 內實作：在 `## Fix Actions` 記錄 needs-design note（finding、所需新機制、一句理由），該輪以 `decision: aborted` 結束並執行 abort triage，指引使用者走 /spectra-ingest 更新 design 後重進 apply。propose-plus 明確排除——propose 階段在自己的 design.md 補上機制定義本來就是正常修復動作，斷路器在該情境觸發會變成自我指涉（模板共用，必須明文限定）。不新增第四個 decision 值（如 needs_design）——避免破壞 round file contract、ledger 欄位值域與下游 grep；needs-design 資訊由 Fix Actions note 與完成輸出承載。needs-design note 與 `decision: next_round` 互斥：記錄該 note 的輪次一律 aborted。

### Abort 強制 triage 三桶分流

任何 aborted 結束（6 輪上限、斷路器、全裁判面保護短路；sub-agent 連續失敗與 proposal-level scope-error abort 除外——前者維持現行行為，後者預期重新提案而非 re-run），必須將未解 surviving findings 分流三桶並「同時」記錄於最終 aborted round file 的 `## Fix Actions` 與完成輸出——完成輸出是暫態的，round file 才是持久載體：(1) 仍屬本 change 義務者——每個未經同意接受的 cumulative blocking set 成員，無論有無 disposition（fix 回歸與 unresolved-prior 為典型）→ 留在本 change；(2) 本 loop 中從未 blocking 的新發現或設計議題 → 寫 signals，Critical 級建議後續 change proposal——桶 2 不收未解決的 blocking finding，否則成為無需同意的第三出口；(3) 取捨 → 經使用者同意寫入 accepted-risks.md；無法取得同意時退回 bucket 1（仍屬本 change 義務、seed 進 re-run）並註記「accepted-risks 記錄待使用者同意」——blocking finding 不得經無同意路徑離開 change 義務，桶 2 絕對不收曾 blocking 的 finding。輸出不得建議「直接重跑同一迴圈」。abort 後 re-run 的規則：round file 編號自該 skill 最後一個既有 round file 續號（不覆寫任何舊檔，與實測 r7–r13 的實務一致）；re-run 首輪為 full，其 reviewer context 必附前一 run 的全部 round files（或摘錄），且 re-run 的 cumulative blocking set 以前一 run 的 bucket-1 findings 為種子、re-run 首輪即採 cumulative set pass 條件、對前 run 全部 round files（最終檔的 bucket-1 triage 列舉種子成員）標 disposition 並回報 per-member resolved/unresolved 判定（前 run 已記錄修復的種子因此可在首輪走出口 (a)）——bucket-1 以 blocking 身分重進審查，種子成員未被再報告且判定非 resolved 即擋 pass（前 run 已記錄修復、首輪判定 resolved 者走出口 (a)），不依賴首輪 reviewer 抽樣重新發現；6 輪上限與輪型推導以 re-run 自身的輪次位置起算。seeded set 全為裁判面保護且無同意出口時，短路於 spawn 首輪 reviewer 前判定：該 run 寫恰好一個續號 round file（round_type: full、無 reviewer findings、decision: aborted、含 triage——full 輪必 spawn 兩 reviewer 的規則對此輪有明文 carve-out）＋一列 ledger（同 round_type），完成輸出必須導向「取得成員同意」或「經 /spectra-ingest 擴充 structured scope declarations」再 re-run——否則每次 re-run 都注定立即 abort。

### introduced_by 證據硬規則（僅 apply-plus）

apply-plus 的 Reviewer B 每個 Critical/Warning finding 必附 `introduced_by` 欄位：本 change diff 的具體位置（檔案＋行為描述）或本 loop 某輪 fix action 的引用。主 agent 在 confidence filter 時，對缺少可驗證 introduced_by 的 Critical/Warning 一律降至 ≤ 25（等同 pre-existing 處理），且每次降分留痕於 `## Fix Actions`（finding＋不可驗證原因）並列入完成輸出。introduced_by 允許引用單一 diff 位置、一或多筆 fix action 記錄、或「某輪 fix actions 全集」——多個 fix 交互產生的回歸（第 4 輪 checkpoint 的核心獵物）因此有可驗證的引用形式，不會被降分規則吞掉。現行「pre-existing 應 ≤ 25」從 false-positive 清單的勸告升級為主 agent 的機械過濾規則。propose-plus 不適用（artifact 全為本 change 新增，introduced_by 無鑑別力）。

### 無動作輪禁止

`decision: next_round` 的輪次，每個 surviving Critical/Warning——以及每個計入本輪決策的 cumulative blocking set 成員（含未被再報告的 carryover）——必須在該輪 `## Fix Actions` 對應到動作記錄。blocking finding／集合成員的合法動作僅三種：已修復（列出修改檔案）、`未修復：裁判面保護`、經使用者同意記錄的 accepted-risks 條目——對 blocking 成員記 triage note 不是合法動作、也不改變其 blocking 身分（否則空轉輪以 note 換過關，重現 r10–r12）；non-blocking（new）finding 的合法動作即其分流 note；僅匹配前輪分流 note 的 re-report，其合法動作為指向原 note 的一行交叉引用 note（非重複 note、不產生新 signal），避免「不得重複記 note」與動作義務死鎖。needs-design note 不在此清單——依斷路器規則它強制 `decision: aborted`，與 next_round 互斥。任一 surviving finding 無動作記錄時，不得 spawn 下一輪 reviewer。

### Impact 粒度提醒（propose-plus，資訊性）

新增模板 scripts/spectra-plus/template/impact-granularity-block.md，經 rules.yaml 掛在 propose-plus 的 proposal 撰寫步驟之後：proposal `## Impact` affected-code 條目數（Modified + New + Removed）超過 15 時，輸出一段資訊性警告，建議按 capability 拆成多條 change；不阻斷流程、不要求確認。門檻 15 取自實測：非收斂案例 ~29 個 production 檔，本 repo 歷史收斂案例均 <15。

### 版本與再生成

rules.yaml 兩個 skill 的 spectraPlusVersion 由 1.4.0 bump 至 1.5.0、spectraPlusUpdated 更新為實作日；以 scripts/spectra-plus/generate.fish 再生成四份 SKILL.md。進行中的 loop 依既有 grader-immutability 規則沿用啟動時的指令版本。

## Implementation Contract

- **行為（review loop）**：run 首輪之後、第 4 輪之外的輪次 spawn 恰好一個 Reviewer V；第 4 輪（未 pass 時）spawn A+B 兩個 full reviewer；首輪之後每輪 reviewer context 必附本 loop 全部 prior round files（超量時附每輪摘錄）與當前 cumulative blocking set 成員清單；reviewer 為每個 Critical/Warning 標 `disposition`（`unresolved-prior`/`fix-introduced`/`new`），主 agent 核對（更正留痕）後以 cumulative blocking set 判定 pass，集合出口僅「驗證解決」與「同意接受」兩條，全裁判面保護時立即短路 abort；non-blocking findings 出現在 round file `## Fix Actions` 的 triage note 與完成輸出清單。斷路器觸發時該輪 `decision: aborted` 且三桶 triage 同時寫入最終 round file 與完成輸出。
- **行為（accepted-risks）**：`openspec/changes/<change>/reviews/accepted-risks.md` 存在時，每輪 reviewer context 必附；匹配條目（同檔＋同機制，行號 advisory）的 finding 於 filter 後 confidence ≤ 25，且每次套用記錄於 `## Fix Actions` 並在完成輸出列出；條目增修刪一律需使用者明確同意，loop 中不得以 fix action 編輯。檔案格式：每條目含 severity、location、機制描述、accepted 理由、記錄日期。
- **行為（propose-plus 粒度提醒）**：Impact affected-code 條目 > 15 時，proposal 寫入後、design 之前輸出一段含條目數與拆分建議的警告文字；≤ 15 時無輸出。
- **介面／資料形狀**：round file 四段結構、`decision` 值域、ledger 表頭與七欄格式、`round_type` 值域（`full`/`micro`）均不變；Rating 增記 non-blocking 分流數，criticals/warnings（Rating 與 ledger）計 post-filter cumulative blocking set；Round file language 的 keep-verbatim 清單加入 `disposition`（含三值）與 `introduced_by`（跨輪機械匹配依賴原文）；模板「Decision record requirements」的 pass 禁令改為 blocking 版本（不得 pass 仍有 surviving blocking Critical/Warning 的輪次）。首輪之後的 finding 增 `disposition` 欄位；Reviewer B（apply-plus）finding 增 `introduced_by` 欄位。abort 後 re-run 的 round file 自最後既有編號續號。
- **失敗模式**：accepted-risks.md 寫入失敗→警告並繼續（同 signals）；無法互動取得使用者同意→不寫入 accepted-risks，finding 維持 surviving。
- **驗收標準**：scripts/spectra-plus/tests/generator-checks.fish 全綠——移除六條與舊機制綁定的斷言（micro 進入條件、micro 不連續、re-derivation 單向規則、post-decision 文字同步不確定性、re-derivation note 格式、'(or, for apply-plus, any implementation-file modification)' 這條僅存在於被刪 re-derivation 句的斷言），檢查並按 blocking 措辭更新 'surviving Critical'/'surviving Warning' 兩條字串斷言，並更新 generator-checks.fish 與 repair-all-checks.fish 兩檔內的 plus_version/plus_updated 變數（repair-all-checks.fish 以共用變數 plus_version/plus_updated 供 frontmatter 斷言與 staleness fixture 兩處取用，更新變數即可）；同步將模板「Round-1 claim verification」措辭改為 run 首輪並更新對應斷言；新增斷言涵蓋：第 4 輪 checkpoint 字串、disposition/blocking 定義、cumulative blocking set、per-member resolved/unresolved 判定（V 與 checkpoint A/B）、round file 不可回改、摘錄 fallback 註記、seeded re-run 首輪 cumulative set pass 條件與續號、全保護短路（含 fix 階段 aborted 覆寫）、accepted-risks context 與降分記錄規則、introduced_by 降分規則、無動作輪禁止（blocking 成員動作限三種）、Decision record requirements 的 blocking 版 pass 禁令、impact-granularity-block 掛載（僅 propose-plus 輸出含、apply-plus 輸出不含）；generate.fish 再生成後四份 SKILL.md frontmatter 含 spectraPlusVersion: 1.5.0；spectra validate 通過。
- **範圍邊界**：in scope＝review-loop-block.md、impact-granularity-block.md（新）、rules.yaml、generator-checks.fish、repair-all-checks.fish（版本變數）、四份生成 SKILL.md、spec delta；out of scope＝spectra CLI、signals write step 邏輯（僅 triage findings 沿用既有 signal 產生路徑）、其他模板 block、refuter 機制。

## Risks / Trade-offs

- [Delta 語意弱化 gate：首輪之後的新發現真缺陷不再擋 pass] → 第 4 輪強制 full checkpoint 補網；non-blocking findings 一律進 signals 與完成輸出醒目清單，Critical 級附後續 change 建議，資訊不遺失。
- [Reviewer V 視野窄，fix 交互回歸可能漏檢] → 第 4 輪 checkpoint 全面複掃一次；V 的 scope 明含「修復是否引入新缺陷」；cumulative blocking set 保證已知 blocking finding 不因 V 未再報告而漏出。
- [disposition 誤標讓 blocking finding 被歸為 new 而分流] → `new` 桶定義排除任何匹配前輪 blocking finding 者（無效 fix 不能洗白）；主 agent 逐一核對 disposition、更正一律留痕且 blocking→non-blocking 更正列入完成輸出；dedupe 分歧取 blocking 值。
- [reviewer context 隨輪次累積成長（全部 prior round files）] → 超過實際可用量時改附每輪摘錄（surviving findings＋完整 Fix Actions），摘錄即 disposition 判定所需的最小資訊。
- [裁判面保護的 blocking finding 使結局註定卻繼續燒 reviewer 輪次] → 全保護集合立即短路 abort＋triage，不空轉。
- [accepted-risks 被濫用為漂白通道] → 增修刪都需使用者明確同意、loop 中禁止以 fix action 編輯；每次降分留痕於 round file 與完成輸出；匹配為 finding 級（location＋機制），同 subsystem 的不同缺陷不會被吞。
- [introduced_by 硬規則誤降 fix 引入的真回歸] → introduced_by 允許引用本 loop fix action 記錄，fix 引入的回歸有明確證據來源，不受影響。
- [micro 語意重定義使跨版本 ledger 的 round_type 統計不可直接比較] → ledger 格式不變、round file 權威；歷史資料判讀以 round file 為準，接受此統計斷層。

## Migration Plan

1. 修改模板與 rules.yaml、新增 impact-granularity-block.md，更新 generator-checks.fish 斷言。
2. 執行 generate.fish 再生成四份 SKILL.md，跑測試。
3. 進行中的舊 loop 依 grader-immutability 既有規則沿用舊指令版本至該 loop 結束；新 loop 自動採用新版。無資料遷移；回滾＝revert 後重新 generate。

## Open Questions

(none)
