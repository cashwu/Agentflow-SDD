# Apply Plus Review — Round 1

## Reviewer Findings

### Critical

- **C1**（B）
  - severity: Critical
  - confidence: 100
  - layer: design
  - location: `scripts/spectra-plus/template/review-loop-block.md`「Fresh sub-agent calls」
  - summary: 第四輪同時被要求執行完整 A+B 審查，並被「首輪後每輪只能啟動一個 reviewer」的廣泛量詞涵蓋，造成互斥的 reviewer 數量義務。
  - recommendation: 將單 reviewer 義務限縮為 micro round，讓第四輪 full checkpoint 明確只適用 A+B 規則。

### Warning

（無）

### Suggestion

（無）

## Rating

- surviving Critical count: 1
- surviving Warning count: 0
- critical_gap: true
- round_type: full
- rationale: 經信心過濾後僅 C1 成立；它是可直接由模板條文證實的設計衝突，因此本輪必須 `next_round`。依本次 loop 啟動時的 v1.4 規則，存在 surviving Critical 時下一輪為 full。

## Fix Actions

- 排除 Reviewer A 與 Reviewer B 對四個生成輸出仍為 1.4.0 的報告：該結果來自 reviewer 的 stale read-only snapshot；主工作區重新生成並逐檔驗證後，四個輸出均為 1.5.0。
- 修改 `scripts/spectra-plus/tests/generator-checks.fish`：先加入會失敗的回歸斷言，要求生成內容包含 `Each micro round MUST spawn exactly ONE fresh sub-agent`，且不得包含舊的廣泛量詞。
- 修改 `scripts/spectra-plus/template/review-loop-block.md`：將單 reviewer 義務限縮為 micro round，消除第四輪 full checkpoint 的規則重疊。
- 重新生成 `.claude/skills/spectra-propose-plus/SKILL.md`、`.claude/skills/spectra-apply-plus/SKILL.md`、`.agents/skills/spectra-propose-plus/SKILL.md`、`.agents/skills/spectra-apply-plus/SKILL.md`。
- 修正後執行 `fish scripts/spectra-plus/tests/generator-checks.fish`、`git diff --check`、四輸出內容檢查與 `spectra validate converge-plus-review-loop`，全部通過。

## Decision

next_round
