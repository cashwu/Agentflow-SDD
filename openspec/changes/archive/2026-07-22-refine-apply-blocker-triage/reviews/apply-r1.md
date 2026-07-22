# Cash Apply Review — Round 1

## Reviewer Findings

### Critical

- **severity**: Critical
  - **confidence**: 100
  - **layer**: design
  - **location**: `.agents/skills/cash-apply/SKILL.md:226-232`、`.claude/skills/cash-apply/SKILL.md:226-232`
  - **summary**: 新增的繼續分支仍被後方未限縮的通用 `Error or blocker encountered → report and wait for guidance` 涵蓋，同一個機制替換 blocker 同時收到繼續與暫停兩個互斥指令。
  - **recommendation**: 將通用 fallback 限縮為未被 blocker triage 涵蓋的其他錯誤或阻塞，並同步 artifacts 與兩個 skill 變體。
  - **來源**: Reviewer A — Adherence、Reviewer B — Quality（依 `location + summary` 聚合；severity 取較高者）
  - **introduced_by**: `.claude/skills/cash-apply/SKILL.md:228-230`、`.agents/skills/cash-apply/SKILL.md:228-230`

### Warning

- **severity**: Warning
  - **confidence**: 100
  - **layer**: design
  - **location**: `scripts/cash-skills/tests/skill-checks.fish:98,407`
  - **summary**: governed-contract mutation fixture 只保護 `<!-- BLOCKER-TRIAGE -->` marker；保留 marker 但刪除或反轉兩分支處置文字仍可能通過。
  - **recommendation**: 在 `assert_apply_contract` 與 `mutation_specs` 加入分別代表繼續與暫停處置的 invocation-free literals，讓兩個行為分支獨立 fail loud。
  - **來源**: Reviewer B — Quality
  - **introduced_by**: `scripts/cash-skills/tests/skill-checks.fish:98,407` 的本次 diff 只加入 marker，未加入分類行為 literal。

### Suggestion

None.

## Rating

- 累積 blocking Critical 數：1
- 累積 blocking Warning 數：1
- 非 blocking triaged finding 數：0
- `critical_gap`: true
- `round_type`: full
- 理由：unseeded 第一輪的兩個存活 findings 都是 `confidence >= 80`，依規則全部進入 cumulative blocking set；在後續 reviewer 明確驗證修正前，本輪 MUST 為 `next_round`。

## Fix Actions

- 修正 Critical：修改 `.claude/skills/cash-apply/SKILL.md`、`.agents/skills/cash-apply/SKILL.md`，將 catch-all 改為 `Other errors or blockers not covered by the blocker triage above → report and wait for guidance`。
- Fix propagation：修改 `openspec/changes/refine-apply-blocker-triage/proposal.md`、`design.md`、`specs/cash-skill-workflows/spec.md`、`tasks.md`，明定 blocker triage 優先於通用 fallback，並同步 scope、Implementation Contract 與 task wording。
- 修正 Warning：修改 `scripts/cash-skills/tests/skill-checks.fish`，在 `assert_apply_contract` 與 `assert_contract_mutation_fixture` 加入 `然後繼續該 task，不暫停`、`暫停、報告 blocker` 兩個行為 literals；marker 仍保留為 anchor。
- 重跑 `fish scripts/cash-skills/tests/skill-checks.fish`：GREEN。
- 重跑 `spectra validate refine-apply-blocker-triage`：通過；`spectra analyze refine-apply-blocker-triage --json`：四個 dimensions 全部 Clean。
- Post-fix mechanical self-check：spec comment counts 為 0/0、無 stray separator、identifier cross-grep 一致、舊 catch-all 無殘留、兩個行為 literals 同步出現在 artifacts、兩個 variants 與 mutation fixture；所有 open signals 仍無 `check` field。

## Decision

next_round
