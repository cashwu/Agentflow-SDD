## Why

apply-plus / propose-plus 的 review loop 在大型高併發 diff 上無法收斂：實測（外部專案 `00-codify-simulcast-review-findings`）13 輪全為 full round，Critical 數 2→4→4→4→5→4(abort)→2→1→3→4→4→3→3 從未趨零。根因是機制設計：(1) pass 條件定義在「整個 change diff 的全面重掃」而非「上輪 delta」，每輪 fresh reviewer 對大 diff 是獨立抽樣、不是漸進逼近；(2) fix 在 loop 內引入新同步原語／狀態機，使受檢面單調擴大（r7 fallback cycle → r8 cycleId → r10 media-bound slot → r12 lease state machine → r13 找到 lease 的新 bug）；(3) micro round 的進入條件（無 Critical 且 Warning 全為 text）在併發 code 上實際不可達，Reviewer V 從未啟動；(4) 缺乏結構化的 accepted-risk／triage 機制，abort 後只能原樣重跑同一迴圈。

## What Changes

- **Delta 收斂（反轉輪型推導）**：run 首輪維持 full round；之後預設為 verification round（`round_type: micro`，Reviewer V 驗證前輪 blocking findings 是否解決、fix propagation 是否完整、修復是否引入新缺陷）。全面重掃只在本 run 第 4 輪 checkpoint 最多再跑一次（若屆時尚未 pass）。移除「micro round 不得連續」限制與「fix 觸及行為即升級 full」的 re-derivation 規則（delta 設計下修復本來就會改行為，該規則會退化回全 full round），並同步改寫 master spec 中三處殘留引用（grader immutability 的例外句、ledger 的時序句、Fresh sub-agent per round 的決策推導句）。
- **Pass 條件改為 delta 語意**：run 首輪之後，reviewer 為每個 Critical/Warning finding 標記 `disposition`（`unresolved-prior`／`fix-introduced`／`new`），主 agent 核對後只有前兩者為 blocking；並維護 cumulative blocking set——成員僅有「下一輪驗證解決」與「經同意的 accepted-risks 接受」兩條出口，re-report 即證明已記錄的 fix 無效（不落入 new 桶）；全數為裁判面保護且無可得同意出口時立即短路 abort。即使本輪 reviewer 未再報告，未離開集合的成員仍計入決策。`new` 的 finding 不擋 pass，改走分流（triage）：寫入 signals，Critical 級建議產生後續 change proposal，並在完成輸出中醒目列出；曾分流的 finding 不回升為 blocking（唯一例外：留痕更正將其歸因於已記錄 fix actions 時，以 fix-introduced 回進集合）。Rating 與 ledger 的 criticals/warnings 計 post-filter cumulative blocking set，Rating 另記分流數；已完成輪次的 round file 於 loop 中不可回改。
- **Accepted-risks ledger**：新增 `openspec/changes/<change>/reviews/accepted-risks.md`。條目的增、修、刪都只能在使用者明確同意下進行，loop 中不得以 fix action 編輯；後續每輪 reviewer context 必附此檔，與某條目「同一 location 且同一機制」（finding 級匹配，非 issue-class 級；行號 advisory）的 finding 一律 confidence ≤ 25，每次降分記錄於 round file 並在完成輸出列出；cumulative blocking set 成員每輪重比對、匹配即移除。此降分與 introduced_by 降分明文優先於「direct artifact violation 必為 100」不變式，introduced_by 降分同樣留痕，且 introduced_by 可引用 fix action 集合以涵蓋多 fix 交互回歸。
- **設計級斷路器（限 apply-plus）**：若修復某 finding 需要引入 design.md 未定義的新同步原語、身份／世代型別或狀態機，不得在 fix loop 內實作——記錄 needs-design、以 `decision: aborted` 結束迴圈，導向 /spectra-ingest 更新 design 後重進；propose-plus 中在自身 design.md 補定義即正常修復，斷路器不觸發。
- **Abort 強制 triage**：任何 aborted（輪次上限、斷路器或全裁判面保護短路）時，必須將未解 findings 分流三桶並同時記錄於最終 round file 與完成輸出：仍屬本 change 義務者（每個未經同意接受的集合成員，留給下次 loop）、從未 blocking 的新發現或設計議題（signals／後續 change 提案）、取捨（經使用者同意進 accepted-risks），不得建議原樣重跑。re-run 的 round file 自最後既有編號續號、不覆寫舊檔，首輪為 full 且 context 必附前一 run 全部 round files（或摘錄）、cumulative blocking set 以前 run bucket-1 findings 為種子、re-run 首輪即採 cumulative set pass 條件（種子成員未被再報告且判定非 resolved 即擋 pass）且首輪 reviewer 回報 per-member 判定；seeded set 全為裁判面保護且無同意出口時於 spawn 前短路 abort（寫一個續號 round file 含 triage），完成輸出導向取得同意或經 /spectra-ingest 擴充 scope；取捨桶在無法取得同意時退回桶 1（留在本 change、seed 進 re-run）並註記待同意——桶 2 絕對不收曾 blocking 的 finding。
- **introduced_by 硬規則（apply-plus）**：Reviewer B 的每個 Critical/Warning finding 必附 `introduced_by` 證據（本 change diff 的 hunk 或本 loop 的 fix action）；缺證據者由主 agent 在 confidence filter 機械降至 ≤ 25。
- **無動作輪禁止**：`decision: next_round` 時，每個 surviving finding 與每個計入決策的 cumulative blocking set 成員在本輪必須有動作。blocking finding／成員限三種：修復、裁判面保護記錄、經同意的 accepted-risks 條目——對 blocking 成員記 triage note 不是合法動作也不改變其身分；non-blocking（new）finding 的動作即其分流 note，僅匹配前輪分流 note 的 re-report 之動作為指向原 note 的一行交叉引用 note（needs-design note 依斷路器規則強制 aborted，與 next_round 互斥）；禁止零修復、零分流記錄就進入下一輪（實測 r10–r12 三輪 `fixed_files=0` 空轉）。
- **Impact 粒度提醒（propose-plus）**：proposal 的 Impact affected-code 檔案數超過 15 時，輸出資訊性警告建議按 capability 拆分（不阻斷流程）。

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `spectra-plus-skills`：修改 review loop 的輪型推導與 pass 條件（Graded convergence、兩個 quality gate requirement）；新增 accepted-risks ledger、設計級斷路器、abort triage、introduced_by 證據與無動作輪禁止的 requirement；新增 propose-plus Impact 粒度提醒 requirement。

## Impact

- Affected specs: `spectra-plus-skills`
- Affected code:
  - Modified:
    - scripts/spectra-plus/template/review-loop-block.md
    - scripts/spectra-plus/rules.yaml
    - scripts/spectra-plus/tests/generator-checks.fish
    - scripts/spectra-plus/tests/repair-all-checks.fish
    - .claude/skills/spectra-propose-plus/SKILL.md
    - .claude/skills/spectra-apply-plus/SKILL.md
    - .agents/skills/spectra-propose-plus/SKILL.md
    - .agents/skills/spectra-apply-plus/SKILL.md
  - New:
    - scripts/spectra-plus/template/impact-granularity-block.md
  - Removed: (none)
