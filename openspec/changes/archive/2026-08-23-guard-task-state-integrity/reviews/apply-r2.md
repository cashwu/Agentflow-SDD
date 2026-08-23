# Cash Apply Review — Round 2

## Reviewer Findings

### Critical

- severity: Critical
  confidence: 100
  layer: design
  location: `proposal.md` Proposed Solution 2／7、`design.md` D8／D12／IC2／IC3、`specs/cash-skill-workflows/spec.md` 的兩條 `touched_invalid` 復原 requirements、`.claude/skills/cash-archive/SKILL.md:102`、`.claude/skills/cash-commit/SKILL.md:52`，以及兩份生成的 `.agents` 變體
  summary: removed-task outlet 寫成 `/cash-ingest <name>`／`$cash-ingest <change-name>`，但 cash-ingest 會把任何 argument 解讀成 plan file；change-name argument 因此不可執行，round 1 的無出口問題仍然存在。
  recommendation: 改用無參數 `/cash-ingest`／`$cash-ingest`，明示把目前的 `touched_invalid` 與 change name 作為 conversation context，讓 cash-ingest 依既有 change selection 流程選取目標。
  disposition: unresolved-prior
  introduced_by: 本輪進場時的 source skill 文字 `.claude/skills/cash-archive/SKILL.md:102`、`.claude/skills/cash-commit/SKILL.md:52` 與其生成的 `.agents` 變體
  reviewer source: Reviewer A — Adherence；Reviewer B — Quality

### Warning

None.

### Suggestion

None.

## Rating

- cumulative blocking Critical: 1
- cumulative blocking Warning: 0
- non-blocking triaged findings: 0
- critical_gap: true
- round_type: full

Round 1 的 seeded Critical 經兩位 reviewer 獨立驗證後皆判定 `unresolved`：ingest 已補入 removed-task 恢復 contract，但指引使用了 cash-ingest 不支援的 change-name argument。此問題屬保留 contract 的 invocation 機制替換，不需要新的 synchronization primitive、identity/generation type 或 state machine；依 blocker triage 記錄 deviation 後修復，並進入下一輪 micro verification。

## Fix Actions

- 將 removed-task 與 label-conflict 指引改成無參數 cash-ingest invocation，並明示目前的 `touched_invalid` 與 change name 是 conversation context、由 cash-ingest 選取既有 change。
- 同步修改 `proposal.md`、`design.md`、`tasks.md`、`specs/cash-skill-workflows/spec.md`、`implementation-notes.md`、`.claude/skills/cash-archive/SKILL.md`、`.claude/skills/cash-commit/SKILL.md`、`.agents/skills/cash-archive/SKILL.md`、`.agents/skills/cash-commit/SKILL.md`、`.cash-skills/manifest.tsv`，共 10 個檔案；`.agents` 兩檔由 generator 產生，manifest 由 installer `--self` 重建。
- 驗證：受治理 artifact／skill 已無帶 change-name argument 的 cash-ingest invocation；Cash strict validation 通過；skill suite 135 tests、generator tests 10 tests、bundle version history 與 live include-root namespace scan 全數通過。
- seeded member 暫留 cumulative blocking set，待下一輪 Reviewer V 對上述 fix reference 給出明確 resolved verdict 後移除。

## Decision

next_round

本輪已完成 contract-preserving 修復，但 seeded blocker 必須由獨立 micro verification 確認後才能通過品質閘門。
