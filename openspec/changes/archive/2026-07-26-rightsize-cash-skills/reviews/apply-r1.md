# Cash Apply Review — Round 1

## Reviewer Findings

### Critical

1. `severity`: Critical
   - `confidence`: 100
   - `layer`: design
   - `location`: `.agents/skills/cash-apply/SKILL.md`、`.claude/skills/cash-apply/SKILL.md` 原 `## Rationalization Table` 刪除區；`implementation-notes.md`
   - `summary`: 刪除非 TDD 模式與小型 refactor 仍須測試的既有規範，且沒有等效保留位置。
   - `recommendation`: 將 task done 前的測試義務整合回 task loop，並更正 implementation note。
   - reviewer source: Reviewer A — Adherence

2. `severity`: Critical
   - `confidence`: 100
   - `layer`: design
   - `location`: `.agents/skills/cash-audit/SKILL.md`、`.claude/skills/cash-audit/SKILL.md` 原 Rationalization Table 的 `Backwards compatibility` 列；`implementation-notes.md`
   - `summary`: 刪除不得 grandfather 不安全預設、須明確 deprecate 並強制 migration 的既有規範，且引用的保留位置不等效。
   - `recommendation`: 在 Dangerous Defaults 流程保留相容性處置規則，並更正 implementation note。
   - reviewer source: Reviewer A — Adherence

3. `severity`: Critical
   - `confidence`: 100
   - `layer`: design
   - `location`: `.agents/skills/cash-ingest/SKILL.md`、`.claude/skills/cash-ingest/SKILL.md` 的 plan source、Internal Consistency、Preservation Check；`implementation-notes.md`
   - `summary`: 刪除 plan 過短時補問、completed tasks 與更新 scope 再核對、requirement 改變時同步 scenario 三項沒有等效保留位置的規範。
   - `recommendation`: 將三項義務分別整合回 source sufficiency、Preservation Check 與 spec consistency，並更正 implementation note。
   - `introduced_by`: 原 Rationalization Table 與 Guardrails 的對應刪除；Reviewer B 以 change diff 驗證。
   - reviewer source: Reviewer A — Adherence、Reviewer B — Quality

### Warning

1. `severity`: Warning
   - `confidence`: 100
   - `layer`: design
   - `location`: `scripts/cash-skills/tests/skill-checks.fish` 的 `fallback_statement_count`
   - `summary`: fallback 斷言硬編碼必須含 `ask`，漏掉合法的 `present the same options` 形式，且缺少固定跨行 fixture。
   - `recommendation`: 同時辨識提出問題與呈現選項的合法措辭，並加入單行、跨行、單軸與重複 fixture。
   - `introduced_by`: `scripts/cash-skills/tests/skill-checks.fish` 新增的 `$block =~ /\bask\b/i` 判定。
   - reviewer source: Reviewer B — Quality

### Suggestion

無。

## Rating

- cumulative blocking Critical: 3
- cumulative blocking Warning: 1
- non-blocking triaged findings: 0
- `critical_gap`: true
- `round_type`: full
- 理由：unseeded first round 的 3 個 Critical 與 1 個 Warning 均通過 confidence filter，依規則全部進入 cumulative blocking set；因此本輪必須修復並進入下一輪驗證。

## Fix Actions

- 修復 `.agents/skills/cash-apply/SKILL.md`、`.claude/skills/cash-apply/SKILL.md`：在 task loop 補回非 TDD 與小型 refactor 的 task done 前測試義務。
- 修復 `.agents/skills/cash-audit/SKILL.md`、`.claude/skills/cash-audit/SKILL.md`：在 Dangerous Defaults 補回不安全預設不得因 backwards compatibility 延續，須 loudly deprecate 並 require migration。
- 修復 `.agents/skills/cash-ingest/SKILL.md`、`.claude/skills/cash-ingest/SKILL.md`：補回 plan 過短補問、completed task scope 再核對、requirement/scenario 同步三項義務。
- 修復 `scripts/cash-skills/tests/skill-checks.fish`：fallback axis (b) 接受 `present`／`show`／`offer` 的 question/options 形式，並新增固定單行、跨行、only-one-axis 與 duplicate fixtures。
- 重新產生 `scripts/cash-skills/variant-parity/cash-ingest.diff`，使用與 `normalized_variant_diff` 相同的 invocation-prefix 正規化與 `diff -U0` 程序。
- 在 `implementation-notes.md` 依 append-only 規則追加三筆 follow-up，修正先前不精確的等效承載位置判斷。
- Fix propagation：對 test、backwards compatibility、plan sufficiency、completed task scope、requirement/scenario 與 fallback parser 概念跨兩變體及測試檔完成 grep；未發現未同步位置。
- Post-fix mechanical self-check：spec annotation 與 separator 檢查通過；identifier cross-grep、`variant-parity`、`codex-command-matrix`、`well-formedness` 與 `fish scripts/cash-skills/tests/skill-checks.fish all` 全部通過。
- 已以 `"$cash_cli" touched ensure "rightsize-cash-skills"` 與 `touched record` 記錄本輪修改的 8 個 change-directory 外檔案。

## Decision

next_round
