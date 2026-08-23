## 1. Implementation

- [x] 1.0 依 design C5 先調升 bundle version

  交付目標：`cash-skills.version`、`.cash-skills/lib/cash_cli/installer.py`、`.cash-skills/manifest.tsv`

  MUST 排在第一個 `SKILL.md` 修改之前。把 `cash-skills.version` 從 `2.15.0` 調升為 `2.16.0`，只同步 `.cash-skills/lib/cash_cli/installer.py` 的 `BUNDLE_VERSION`，並在專案根執行 `PYTHONPATH=.cash-skills/lib python3 -s -P -B -m cash_cli.installer --self` 重建 manifest。若 `2.16.0` 已被其他 change 占用，改用嚴格高於當前值的最小 patch version並記 `deviation`。

  驗證：三處 `bundle_version` 一致；`cash-skills.version` 維持單行 LF 結尾；除版本常數外不修改 installer 行為。

- [x] 1.1 依 design C1–C4 修改權威 sources、生成 variants 並發布 manifest

  相依：1.0。此 task 是不可分割的 managed-skill publication unit，MUST NOT 與其他 task 平行，且完成下列全部步驟並重建 manifest 前 MUST NOT 呼叫任何 Cash CLI command，包括 `task done`。

  交付目標：`.claude/skills/cash-apply/SKILL.md`、`scripts/cash-skills/blocks/review-gate.md`、`.claude/skills/cash-propose/SKILL.md`、`.agents/skills/cash-apply/SKILL.md`、`.agents/skills/cash-propose/SKILL.md`、`.cash-skills/manifest.tsv`

  在每個 task 的 pre-edit flow 將現有 `Reuse`／`Quality` 等檢查改寫為 ordered minimal-solution ladder，逐字含 `reuse`、`stdlib`、`native`、`installed-dependency`、`custom` 五個 identifiers，並明定 ladder 在重新讀取 task、相關 spec、Implementation Contract 與實際 call flow 後執行。每個 rung 前共用 eligibility gate，完整保留 observable behavior、interface／data shape、failure modes、acceptance criteria、trust-boundary validation、data-loss prevention、security 與 accessibility。

  加入 deterministic tie-break：跨 rung 選較早者；同 rung 成本相當時依 edge-case correctness，再依 existing codebase pattern。scope eligibility 遇到 task／contract conflict 時走既有 unclear-task／blocker triage，MUST NOT 以 YAGNI 靜默略過 pending task。

  擴充 Implementation Notes Protocol entry instructions：只有既有 protocol 已要求的 `deviation` 且替代機制具有非平凡已知 ceiling 時，才在 `原因` 後成對加入 `限制`／`重訪條件`，並要求 trigger 可觀察或可衡量；無 known ceiling、routine implementation 與 `open-question` 維持既有 shape。Reviewer A／V 的既有 notes 評估文字同步涵蓋缺欄、不可觀察 trigger 與侵害目前 contract 的 ceiling。

  在 Reviewer B 既有角色內加入 complexity lens。cash-propose artifacts 與 cash-apply changed diff 的檢查清單逐字涵蓋：`new dependency`、`single-implementation abstraction`、`pass-through wrapper`、`speculative configuration`、`duplicate existing capability`、`stdlib`／`native` replacement opportunity。明定只處理 proposal／diff 引入且未由 contract 或既有 rationale 說明的 complexity，pre-existing、unrelated 與 contract-required mechanisms 不報。

  保留守則：`clarity 永遠優先於 brevity`、Focused Implementation Discipline 的 diff 可追溯性、既有四欄 entry template、blocker triage 互斥分支與逐字片語 `a synchronization primitive, identity/generation type, or state machine not defined in design.md` 兩處 MUST 保持；full round 恰好 Reviewer A 與 Reviewer B、micro round 恰好 Reviewer V；finding schema、severity、confidence、`introduced_by`、false-positive filter、decision 與 cumulative blocking set 不變。不得新增 `one line` rung、LOC gate、source comment ledger、新的 pause branch、第三 reviewer、complexity reviewer、rater、`net: -`、token、cost 或 time gate。

  在專案根執行 `fish scripts/cash-skills/generate.fish`。MUST NOT 直接人工編輯 `.agents` outputs。生成後，`cash-apply` 兩 variant 的 ladder／notes 區段，以及四個 canonical skills 的 shared review block，在 invocation prefix 正規化後 MUST byte-identical。接著、且在任何下一次 Cash CLI invocation 前，立即執行 `PYTHONPATH=.cash-skills/lib python3 -s -P -B -m cash_cli.installer --self` 更新 `.cash-skills/manifest.tsv`。只有 affected records 全部對應工作樹最終 bytes 後才執行 `task done`；generation 或 publication 失敗時 task 維持 pending。

- [x] 1.2 依 design C1–C4 新增逐 scenario skill contract tests

  相依：1.1。

  交付目標：`scripts/cash-skills/tests/skill-checks.fish`

  在既有具名群組新增並納入 `all` 路徑的機械斷言：

  1. 兩個 apply variants 都含五個 rung identifiers，且擷取出的順序為 `reuse` → `stdlib` → `native` → `installed-dependency` → `custom`。
  2. 兩 variants 都含完整 understanding／eligibility clause、較早 rung 未滿足 contract 即排除並繼續、pending task 不得以 YAGNI 略過、同 rung 依 edge-case correctness 再依 existing codebase pattern、完整 safety eligibility、diff 可追溯性與逐字 circuit-breaker 片語兩處；任一 clause 缺失或反向敘述使套件失敗。
  3. shared block 與四個 canonical skills 都含六類 complexity literals，以及兩個完整 role-specific clauses：cash-propose 只檢查 artifacts 引入且未證明為 contract 所需的 complexity；cash-apply 只檢查 changed diff。完整 exclusions clause MUST 同時排除 pre-existing、unrelated、contract-required 與既有 rationale；完整 metric-boundary clause MUST 禁止 LOC、token、cost、time 參與 finding 或 decision。Reviewer A／B／V 拓撲 literals保持。
  4. 兩個 apply variants 都含 conditional `限制`／`重訪條件` contract、成對規則、無 ceiling 維持既有 shape、不可觀察 trigger 的拒絕規則、routine implementation 不建立 note、contract-invasive ceiling 必須暫停並導向 `$cash-ingest`，以及 Reviewer A／V 對 fields／trigger／contract envelope 三項的完整 justification clause。
  5. 負向斷言拒絕 `one line` rung、`net: -`、LOC gate、complexity reviewer、第三 reviewer，以及強迫所有 deviation 填 `none` 的 shape。
  6. 使用暫存 fixture 或同等不修改工作樹的方式逐 scenario 證明：移除任一 rung、交換 rung 順序、移除「較早 rung 不合格即繼續」、把 YAGNI 處置反轉為略過 task、交換同 rung tie-break 次序、移除任一 safety eligibility 項、移除 cash-apply changed-diff restriction、移除 contract-required 或 rationale exemption、把 LOC／token／cost／time 改為 gate input、known-ceiling fixture 缺任一欄、以「之後需要時」作 trigger、允許 contract-invasive ceiling 記錄後繼續、或讓 routine `stdlib` implementation 建立 deviation 時，對應 checker MUST 非零。無 ceiling 的既有四欄 deviation fixture仍通過。

  測試 MUST 獨立於 generator freshness，能在 source 與 generated output 同時帶有相同錯誤時失敗。

- [x] 1.3 重建最終 manifest並確認 structured scope

  相依：1.2。

  交付目標：`.cash-skills/manifest.tsv`

  執行 `PYTHONPATH=.cash-skills/lib python3 -s -P -B -m cash_cli.installer --self`，確認 manifest 的 bundle version、runtime generation 與四個 modified `SKILL.md` records 對應最終工作樹 bytes。在任何後續 Cash CLI command 前完成本步驟。以 `git diff --name-only` 核對 implementation files 只落在 proposal `## Impact` 宣告的 paths；若出現其他路徑，停止並依 Implementation Notes Protocol 分類，不得直接擴張 scope。

## 2. Verification

- [x] 2.1 執行 targeted skill checks

  相依：1.3。

  交付目標：`scripts/cash-skills/tests/skill-checks.fish`

  執行與 minimal-solution discipline、review gate、well-formedness、variant parity 及 installer runtime 相關的具名群組。確認正向 baseline 全通過，且 task 1.2 的每個 mutation fixture 都能鑑別指定缺陷。

- [x] 2.2 執行完整 skill 與 bundle history suites

  相依：2.1。

  交付目標：`scripts/cash-skills/tests/skill-checks.fish`、`cash-skills.version`、`.cash-skills/manifest.tsv`

  在專案根執行 `fish scripts/cash-skills/tests/skill-checks.fish all` 與 `python3 scripts/cash-skills/tests/test_bundle_version_history.py`，兩者 MUST exit 0。不得以部分群組取代 full suite。

- [x] 2.3 執行 change validation 與 Implementation Contract 核對

  相依：2.2。

  逐項重讀 design C1–C5，核對每個 observable behavior、scope／safety／metric boundary、data shape、reviewer semantics、ownership 與 acceptance criteria。執行 `.cash-skills/bin/cash validate add-minimal-solution-discipline` 並確認 exit 0；任何缺失先回到對應 implementation task 修正，不得先標記完成。
