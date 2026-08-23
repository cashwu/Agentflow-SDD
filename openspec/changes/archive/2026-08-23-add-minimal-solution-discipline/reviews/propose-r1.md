# Cash Propose Review — Round 1

## Reviewer Findings

### Critical

- `severity`: `Critical`
  - `confidence`: `100`
  - `layer`: `design`
  - `location`: `tasks.md` tasks 1.1–1.3；`design.md` D5
  - `summary`: managed `SKILL.md` 修改與 manifest publication 分屬不同 tasks，會使中間的 `cash task done` 因 portable manifest digest drift fail closed；平行 tasks 也會共享該壞掉的工作樹狀態。
  - `recommendation`: 將 managed skill source edit、generation 與 `--self` manifest publication 合併成單一不可分割 task，並在 manifest 恢復一致前禁止任何 Cash CLI invocation與平行 dispatch。
  - reviewer：`B`

### Warning

- `severity`: `Warning`
  - `confidence`: `100`
  - `layer`: `design`
  - `location`: `tasks.md` task 1.4；delta spec `cash-apply 實作紀律以判準表述`
  - `summary`: ladder tests 未逐一鑑別較早 rung 不合格時繼續、pending task 不被 YAGNI 略過、同 rung tie-break 次序與 safety eligibility 四組 normative scenarios。
  - `recommendation`: 增加逐 scenario exact clauses 與 mutation cases，讓規則缺失、反轉或次序交換時 checker 非零。
  - reviewer：`A`

- `severity`: `Warning`
  - `confidence`: `100`
  - `layer`: `design`
  - `location`: `tasks.md` task 1.4；delta spec `Reviewer B 檢查變更引入的不必要複雜度`
  - `summary`: complexity lens tests 只釘六類字面值，未鑑別 cash-propose／cash-apply 的不同 scope、changed-diff-only、contract／rationale exclusions 與完整 metric boundary。
  - `recommendation`: 逐字釘住 role-specific scope、完整 exclusions 與 metric-boundary clauses，並為移除或反轉各條件建立 mutation cases。
  - reviewer：`A`

- `severity`: `Warning`
  - `confidence`: `100`
  - `layer`: `design`
  - `location`: `tasks.md` task 1.4；delta spec `cash-apply 記錄已知 ceiling 的 deviation`
  - `summary`: ceiling fixtures 未驗證 contract-invasive ceiling 必須暫停，以及 routine implementation 不得建立 deviation；既有 pause literals 即使未與 ceiling 建立關聯仍可能通過。
  - `recommendation`: 增加 contract-invasive ceiling 與 routine `stdlib` 獨立 mutation cases，並 exact-assert Reviewer A／V 對 fields、trigger、contract envelope 的完整 justification clause。
  - reviewer：`A`

### Suggestion

（無）

## Rating

- 累積 blocking `Critical`: 1
- 累積 blocking `Warning`: 3
- 非 blocking triage: 0
- `critical_gap`: `true`
- `round_type`: `full`
- 理由：未 seed 的第一輪有一項 `Critical` 與三項 `Warning` 在 confidence filter 後存活，全部進入累積 blocking set，因此本輪不能通過。

## Fix Actions

- 修改 `design.md`：D5 將 managed skill source edit、generation 與 manifest publication 定義為單一不可分割 task，禁止在 publication 前呼叫 Cash CLI 或平行 dispatch；C1–C4 acceptance 同步加入逐 scenario exact-clause／mutation coverage。
- 修改 `tasks.md`：合併原 tasks 1.1–1.3 為不可分割 task 1.1；移除 `[P]`；要求在任何 `task done` 前執行 generator 與 `--self`；task 1.2 補上 ladder、role-specific complexity scope／exclusions／metrics、contract-invasive ceiling、routine implementation 與 Reviewer A／V justification 的完整 mutation matrix。
- Fix propagation：跨 `design.md`、`tasks.md`、delta spec 與 proposal grep `changed diff`、`edge-case correctness`、`routine implementation`、`contract-invasive ceiling`、manifest publication 與 reviewer scope 概念；delta spec 已有對應 normative scenarios，proposal 的 solution／Non-Goals 與修正後 contract 一致，無需修改。
- Post-fix mechanical self-check：annotation counts、MODIFIED title identity、identifier／version cross-grep、`git diff --check` 皆通過；open signals 無 `check` frontmatter。
- Post-fix validation：`.cash-skills/bin/cash validate add-minimal-solution-discipline` 通過。

## Decision

next_round
