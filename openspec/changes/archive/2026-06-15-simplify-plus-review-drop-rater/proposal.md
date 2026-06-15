## Why

目前 plus skills（`spectra-propose-plus`、`spectra-apply-plus`）的 review loop 每一輪會 spawn 三個 sub-agent：兩個 reviewer（A=Adherence、B=Quality）加一個獨立的 rater 評分。rater 看到的資訊與主 agent 在 confidence filter 之後拿到的「過濾後 findings 清單」完全相同——它不會回頭重讀 artifacts 或程式碼，因此沒有提供新的判斷視角。pass 條件的兩個構成中，`critical_gap` 早在 confidence filter 那步就已機械確定，rater 唯一自由判斷的只有沒有 rubric 的 `quality_score`。這使 rater 成為一個「在同一份資訊上多蓋一個主觀數字」的多餘 round-trip，徒增每輪的序列延遲。

## What Changes

- 從 review loop 移除 rater sub-agent；評分/通過判定改由主 agent 在 confidence filter 之後依機械規則直接得出。
- 以結構化規則取代 `quality_score > 9 AND critical_gap == false` 的 pass 條件：
  - 過濾後存在 `severity == Critical`（confidence ≥ 80）→ `decision: next_round`，修 Critical
  - 否則過濾後存在 `severity == Warning`（confidence ≥ 80）→ `decision: next_round`，修 Warning
  - 否則（僅剩 Suggestion 或無 finding）→ `decision: passed`
- 採「嚴格」政策：存活的 Warning 同樣擋住 pass，使新規則在行為上最接近原本 `> 9` 的高標。
- 從 round file 的 `## Rating` 區塊移除 `quality_score` 欄位；`## Rating` 改為記錄機械判定結果（survived Critical/Warning 計數）與一段 rationale。`critical_gap` 作為機械衍生值保留。
- 保留不動：兩個並行 reviewer、confidence scoring rubric、confidence filter、common false positives、6 輪上限、failure handling、round file 路徑與其餘四個 section、語言規則。
- 一併更新第二個來源 template `scripts/spectra-plus/template/apply-notes-block.md`（其內含對 rater 的引用，會被產生進 apply-plus skill），使 apply-plus 產出不再殘留 rater。
- 同步更新 master spec `spectra-plus-skills` 中所有描述 rater 與 `quality_score > 9` 的 requirements 與 scenarios，包含：`spectra-propose-plus quality gate`、`spectra-apply-plus quality gate`、`Round file output contract`、`Fresh sub-agent per round`、`Confidence-scored findings and filter`（「passing findings to the rater」措辭）、`Sub-agent failure handling`（「a reviewer or the rater fails」scenario）。

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `spectra-plus-skills`: review loop 不再使用 rater sub-agent；pass 條件由 `quality_score > 9 AND critical_gap == false` 改為依過濾後 findings 嚴重度的機械判定；round file `## Rating` 區塊移除 `quality_score` 欄位。

## Impact

- Affected specs: `spectra-plus-skills`
- Affected code:
  - Modified:
    - scripts/spectra-plus/template/review-loop-block.md
    - scripts/spectra-plus/template/apply-notes-block.md
    - scripts/spectra-plus/rules.yaml
    - scripts/spectra-plus/generate.fish
    - scripts/spectra-plus/tests/generator-checks.fish
    - .claude/skills/spectra-propose-plus/SKILL.md
    - .claude/skills/spectra-apply-plus/SKILL.md
    - .agents/skills/spectra-propose-plus/SKILL.md
    - .agents/skills/spectra-apply-plus/SKILL.md
  - New: (none)
  - Removed: (none)
