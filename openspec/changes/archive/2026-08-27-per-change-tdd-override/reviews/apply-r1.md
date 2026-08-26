# Cash Apply Review — Round 1

## Reviewer Findings

### Critical

- severity: Critical
  confidence: 100
  layer: design
  location: `openspec/changes/per-change-tdd-override/design.md` Context、Non-Goals、C1／C6；`proposal.md` Non-Goals
  summary: artifacts 一方面宣稱「CLI 零修改／不修改任何 CLI 檔案」，另一方面 C6 與實作要求同步 installer `BUNDLE_VERSION`，contract 自相矛盾。
  recommendation: 將邊界收斂為不修改 CLI parser、commands 或可觀察行為，明列 installer 發布 metadata 同步為 C6 唯一例外。
  reviewer source: Reviewer A

### Warning

- severity: Warning
  confidence: 98
  layer: design
  location: `.claude/skills/cash-propose/SKILL.md` Step 4b、`.agents/skills/cash-propose/SKILL.md` Step 4b、`scripts/cash-skills/tests/skill-checks.fish` `assert_tdd_discipline`
  summary: TDD 選擇 append 未保證既有檔案尾端與新 key 之間有 LF，無尾端 LF 時可能黏合並破壞 metadata。
  recommendation: 明定非空檔案缺少尾端 LF 時先補恰好一個 LF separator，再寫入 LF 終止的新行，並以具名斷言治理。
  reviewer source: Reviewer A、Reviewer B（聚合）
  introduced_by: `.claude/skills/cash-propose/SKILL.md` 與 `.agents/skills/cash-propose/SKILL.md` 新增的 append 規則，以及 `scripts/cash-skills/tests/skill-checks.fish` 對該規則的弱 marker 斷言。

- severity: Warning
  confidence: 97
  layer: design
  location: `.claude/skills/cash-apply/SKILL.md` Step 5、`.agents/skills/cash-apply/SKILL.md` Step 5、`scripts/cash-skills/tests/skill-checks.fish` `assert_tdd_discipline`
  summary: 實作文字只尋找 `tdd: `，使 `tdd:true`、tab suffix 等 malformed 第一行被誤當缺行，可能靜默 fallback 或改採後續合法行。
  recommendation: 先定位第一個 unindented `tdd:` 前綴行，再以完整 suffix 嚴格判斷；非法第一行警告後 fallback，且不得掃描後續行。
  reviewer source: Reviewer B
  introduced_by: `.claude/skills/cash-apply/SKILL.md` 與 `.agents/skills/cash-apply/SKILL.md` 的 `tdd: ` 搜尋規則，以及 `scripts/cash-skills/tests/skill-checks.fish` 對同一弱規則的斷言。

- severity: Warning
  confidence: 100
  layer: text
  location: `scripts/cash-skills/tests/skill-checks.fish` `assert_tdd_variant_parity`
  summary: parity 只比較 cash-apply Step 5 與 task-loop，未比較本 change 新增的 cash-propose Step 4b 與 cash-apply Step 12，無法支撐逐行 parity contract。
  recommendation: 將兩個新增 section 納入 invocation-prefix 正規化後的逐行比較。
  reviewer source: Reviewer A

- severity: Warning
  confidence: 100
  layer: text
  location: `scripts/cash-skills/tests/skill-checks.fish` `assert_tdd_discipline`
  summary: first-match 測試只斷言 `first unindented` marker，刪除「忽略後續行」仍會通過。
  recommendation: 同時鎖定第一個 `tdd:` 前綴行與不再掃描後續行的完整義務。
  reviewer source: Reviewer A

### Suggestion

None.

## Rating

- Critical: 1
- Warning: 4
- Non-blocking triaged findings: 0
- critical_gap: true
- round_type: full

本輪為 unseeded first round；五筆通過 confidence filter 的 Critical／Warning 全部進入 cumulative blocking set，因此必須修復並進入下一輪。Reviewer 回報為 `text` 但修正會改變可觀察 instruction contract 的 LF append 與 malformed-prefix 兩筆，主 agent 已依規則重分類為 `design`；parity 與 first-match assertion 兩筆只同步測試治理文字，保留 `text`。

## Fix Actions

- 修復 CLI scope 矛盾：修改 `openspec/changes/per-change-tdd-override/proposal.md` 與 `design.md`，將 Non-Goals／C1 收斂為不修改 parser、commands 或可觀察行為，並明列 C6 installer `BUNDLE_VERSION` 發布 metadata 例外。
- 修復 separator-safe append：修改 `proposal.md`、`design.md`、`specs/cash-skill-workflows/spec.md`、`.claude/skills/cash-propose/SKILL.md` 與 `scripts/cash-skills/tests/skill-checks.fish`，要求非空且無尾端 LF 時先補恰好一個 LF separator，並新增具名斷言。
- 修復 malformed first-line 分類：修改 `design.md`、`specs/cash-skill-workflows/spec.md`、`.claude/skills/cash-apply/SKILL.md` 與 `scripts/cash-skills/tests/skill-checks.fish`，改以第一個 unindented `tdd:` prefix 的完整 suffix 判定，非法時不得掃描後續行。
- 修復新增區段 parity：修改 `scripts/cash-skills/tests/skill-checks.fish`，將 cash-propose Step 4b 與 cash-apply Step 12 納入逐行 prefix-normalized section comparison。
- 強化 first-match 守衛：修改 `scripts/cash-skills/tests/skill-checks.fish`，分別斷言 first-prefix、完整合法 suffix 與永不掃描後續行。
- 執行 `fish scripts/cash-skills/generate.fish` 重生成 `.agents/skills/cash-apply/SKILL.md` 與 `.agents/skills/cash-propose/SKILL.md`，再以 `./install-cash-skills.fish --self` 更新 `.cash-skills/manifest.tsv`。本輪 fix 共修改 9 個 distinct files：`proposal.md`、`design.md`、delta `spec.md`、四個 SKILL.md、`skill-checks.fish`、manifest。
- Post-fix verification：`fish scripts/cash-skills/tests/skill-checks.fish tdd-discipline` 通過；完整 `fish scripts/cash-skills/tests/skill-checks.fish` 通過（135 tests、10 bundle history tests、namespace 與 minimal-solution checks 全綠）；`.cash-skills/bin/cash validate per-change-tdd-override` 通過。
- Post-fix mechanical self-check：delta spec 的 `<!--`／`-->` 為 2／2、無 stray `---`；3 個 requirement、25 個 scenario、7 個 completed task 計數一致；MODIFIED requirement title 與 master spec byte-for-byte 相符；新增識別字在 artifacts 與兩變體同步。未發現帶 `check` 欄位的 open signal。

## Decision

next_round
