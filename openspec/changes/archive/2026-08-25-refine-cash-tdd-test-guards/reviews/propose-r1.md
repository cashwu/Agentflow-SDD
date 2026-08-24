# Cash Propose Review — Round 1

## Reviewer Findings

### Critical

無。

### Warning

1. `severity`: Warning
   `confidence`: 100
   `layer`: design
   `location`: `proposal.md` Motivation／Proposed Solution、`design.md` D3／C3、`specs/cash-skill-workflows/spec.md`
   `summary`: proposal 要修正繁中 canonical 複述漏檢，但 design、spec 與 task 只要求五個英文 clauses，繁中原文貼入 skill 仍會通過。
   `recommendation`: 每個 test-quality gate 同時固定繁中 canonical 原文與低碰撞英文 equivalent，兩類都在四份 skill 上執行並各有 append mutation。
   reviewer source: Reviewer A、Reviewer B

2. `severity`: Warning
   `confidence`: 100
   `layer`: design
   `location`: `design.md` D1／C1、`specs/cash-cli/spec.md`、`tasks.md` 1.1
   `summary`: 新 contradiction inventory 漏掉 carrier 固定為 `tasks.md`、強制新增 mutation framework、每個 task 都必須新增測試等既有 additive 邊界，照原設計移除 guards 會降低鑑別力。
   `recommendation`: 逐字固定完整 obligation-specific category inventory，涵蓋 carrier-neutral、framework-neutral、no-formal-test 與現有 resource 邊界，並為每項加入獨立 additive fixture。
   reviewer source: Reviewer A、Reviewer B

3. `severity`: Warning
   `confidence`: 100
   `layer`: design
   `location`: `design.md` D2／D3／C1／C3、兩份 delta specs、`tasks.md` 1.1／2.1
   `summary`: artifacts 要求刪除 guard 時 suite 失敗，卻未禁止 detector registry 同時產生 mutation cases；刪除同一清單元素會一起刪除 guard 與 test fixture，suite 仍可能假綠。
   `recommendation`: detector registry 與固定 expected mutation corpus 分開定義，斷言 exact category／language key sets，並要求只移除 detector guard、保留 fixture 的差分 mutation 非零失敗。
   reviewer source: Reviewer A、Reviewer B

4. `severity`: Warning
   `confidence`: 100
   `layer`: design
   `location`: `design.md` C4、兩份 delta specs 的 scope scenarios、`tasks.md` 1.1／2.1
   `summary`: artifacts 要求 canonical resources、skill bytes、manifest 與 bundle version 不變，但 tasks 沒有 change-scoped verification 承載這項 acceptance criterion。
   `recommendation`: 每個 task 加入 change-scoped edit inventory manual assertion，並讓最終 cash-apply review 檢查 changed-file inventory；不得以整個 dirty worktree 相對 HEAD 的 diff 判定。
   reviewer source: Reviewer A

### Suggestion

無。

## Rating

- post-filter cumulative blocking set Critical count: 0
- post-filter cumulative blocking set Warning count: 4
- 非阻塞 triaged finding count: 0
- `critical_gap`: false
- `round_type`: full

第一輪四筆 Warning 皆為 confidence 100 的 design finding，且直接影響 proposal 宣稱的跨語言偵測、mutation oracle 獨立性、既有 guard 保留與 scope acceptance evidence；依 unseeded first-round 規則全部進入 cumulative blocking set，因此本輪為 `next_round`。

## Fix Actions

- 修改 `proposal.md`：把 skill 去重方案改為五個 gate 的繁中原文／英文 equivalent 雙語 clauses，並明訂 detector 與 mutation fixtures 獨立、每個 task 執行 change-scoped diff assertion。
- 修改 `design.md`：D1 逐字固定 TDD 三類、test-quality 六類與 tasks 四類 contradiction inventory，補回 carrier-neutral、framework-neutral、no-formal-test 邊界；D2 要求 `EXPECTED_*_CONTRADICTION_FIXTURES` 不得從受測 registry 派生；D3 固定五個 gate、每個 gate `zh`／`en` 各一個 clause，共十個 literals；C4 改以 task change-scoped edit inventory 與 cash-apply review changed-file inventory驗證零範圍漂移。
- 修改 `specs/cash-cli/spec.md`：加入三組 exact category sets、detector／fixture 獨立定義、guard-only deletion 必須非零失敗的 normative contract與scenario。
- 修改 `specs/cash-skill-workflows/spec.md`：逐字固定十個雙語 clauses，要求 detector／fixture gate與language exact sets，並新增 fixtures 不從 registry 派生的 acceptance條件。
- 修改 `tasks.md`：task 1.1 明列三／六／四類 resource inventory與獨立 fixtures；task 2.1 明列五 gate、十個雙語 clauses與獨立 fixtures；兩項 regression 均新增自身 change-scoped edit inventory manual assertion。
- Fix propagation：已 grep `五個`、`十個`、`英文 canonical-equivalent`、category names、`zh`／`en` 與 `change-scoped` across 全部 artifacts；mechanical self-check 發現並修正 `design.md` Goals／C4 與 workflow scenario 殘留的舊五-clause計數。
- Post-fix validation：`cash validate refine-cash-tdd-test-guards` 通過；spec annotation／separator lint、count consistency、identifier cross-grep與 `git diff --check` 通過。兩份 delta 只有 ADDED requirements，無 MODIFIED／REMOVED title identity需要核對；open signals沒有 `check` frontmatter command需執行。
- 本輪修改檔案共 5 個，全部位於 change directory，無需 `touched record`。

## Decision

next_round
