# Apply Plus Review — Round 2

## Reviewer Findings

### Critical

（無）

### Warning

- **W1**（A）
  - severity: Warning
  - confidence: 95
  - layer: design
  - disposition: new
  - location: `scripts/spectra-plus/template/review-loop-block.md`「Abort triage」
  - summary: fully protected seeded re-run 的短路分支未要求完成輸出明確導向透過 `/spectra-ingest` 擴充 structured scope declarations。
  - recommendation: 在短路規則補上「取得同意或透過 `/spectra-ingest` 擴充 scope 後才能再執行」的完成輸出義務，並以生成器測試鎖定。
- **W2**（B）
  - severity: Warning
  - confidence: 100
  - layer: design
  - disposition: new
  - introduced_by: 本 change 在 `scripts/spectra-plus/tests/generator-checks.fish` 新增的 impact granularity 測試只鎖定標題與 `more than 15`，未鎖定 spec 的 15/16 與 `(none)` 邊界。
  - location: `scripts/spectra-plus/tests/generator-checks.fish` impact granularity assertions；`openspec/changes/converge-plus-review-loop/specs/spectra-plus-skills/spec.md`「Propose-plus impact granularity advisory」
  - summary: impact granularity advisory 的測試未鎖住 15 靜默、16 警告與 `(none)` 不計數等 scenario/example 邊界。
  - recommendation: 增加生成內容斷言，明確涵蓋 `(none)` 排除與 15/16 邊界語意。

### Suggestion

（無）

## Rating

- surviving Critical count: 0
- surviving Warning count: 2
- critical_gap: false
- round_type: full
- rationale: C1 已由 Reviewer A 確認修復，但兩個新的 design-layer Warning 經信心過濾後成立。依本次 loop 啟動時的 v1.4 規則，任何 surviving Warning 都要求 `next_round`，且 design-layer Warning 使下一輪維持 full。

## Fix Actions

- Reviewer A 已確認 apply-r1 C1 的量詞衝突完成修復：單 reviewer 義務只適用 micro round，第四輪 full checkpoint 保持 A+B。
- 修改 `scripts/spectra-plus/tests/generator-checks.fish`：先加入會失敗的斷言，鎖定 fully protected seeded re-run 的 `/spectra-ingest` 指引、`(none)` 排除，以及 15/16 advisory 邊界。
- 修改 `scripts/spectra-plus/template/review-loop-block.md`：在 fully protected seeded re-run 短路分支補上完成輸出必須導向取得同意或透過 `/spectra-ingest` 擴充 structured scope declarations。
- 修改 `scripts/spectra-plus/template/impact-granularity-block.md`：明確加入 15 靜默、16 警告的邊界句。
- 重新生成 `.claude/skills/spectra-propose-plus/SKILL.md`、`.claude/skills/spectra-apply-plus/SKILL.md`、`.agents/skills/spectra-propose-plus/SKILL.md`、`.agents/skills/spectra-apply-plus/SKILL.md`。
- 修正後執行 `fish scripts/spectra-plus/tests/generator-checks.fish`、`git diff --check`、生成輸出內容檢查與 `spectra validate converge-plus-review-loop`，全部通過。

## Decision

next_round
