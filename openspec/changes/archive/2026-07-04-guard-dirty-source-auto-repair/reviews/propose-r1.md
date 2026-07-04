# Propose Plus Review — Round 1

## Reviewer Findings

### Critical

- severity: Critical
  confidence: 92
  location: `design.md` `## Implementation Contract`; `specs/spectra-plus-skills/spec.md` `Repair-all protects registered targets from dirty source checkout`; `openspec/specs/spectra-plus-skills/spec.md` `Local rules metadata parse failure aborts repair`
  summary: dirty-source guard 與既有 local metadata fail-loud 行為的優先順序沒有定義；dirty 且 invalid 的 `scripts/spectra-plus/rules.yaml` 可能同時要求 skip exit 0 與 non-zero abort。
  recommendation: 明確定義 `--repair-all` 的 precedence，並補 scenario/task 覆蓋 dirty invalid `rules.yaml`。
  reviewer: A+B

### Warning

- severity: Warning
  confidence: 88
  location: `design.md` `### Guard repair-all with source-sensitive dirty detection`; `specs/spectra-plus-skills/spec.md` scenarios; `tasks.md` `1.2`
  summary: design 要求 guard 在讀 registry 前執行，但 spec/tasks 沒有驗證 dirty source 時不處理 invalid registry target。
  recommendation: 新增 scenario/task 驗證 dirty source-sensitive paths 時不讀取或處理 registry targets，或降低 design 承諾。
  reviewer: A

- severity: Warning
  confidence: 86
  location: `proposal.md` `## What Changes`; `design.md` `### Guard repair-all with source-sensitive dirty detection`; `specs/spectra-plus-skills/spec.md` requirement text; `tasks.md` `1.1`
  summary: artifacts 說要防止 uncommitted dirty source changes，但沒有明確涵蓋 staged/index-only source-sensitive changes。
  recommendation: 明確要求 git index 與 working tree 狀態都要檢查，並補 staged-only fixture。
  reviewer: A+B

### Suggestion

- severity: Suggestion
  confidence: 68
  location: `design.md` source-sensitive path set; `specs/spectra-plus-skills/spec.md` requirement text; `tasks.md` `1.1`
  summary: `.agents/skills/spectra-*` / `.claude/skills/spectra-*` 對 skill directory 內檔案是否遞迴納入有解讀空間。
  recommendation: 使用 `.agents/skills/spectra-*/**`、`.claude/skills/spectra-*/**` 或明確說明 matching skill directories 底下所有檔案。
  reviewer: A

- severity: Suggestion
  confidence: 80
  location: `design.md` `## Risks / Trade-offs`; `tasks.md` `1.1`
  summary: path filtering 是主要風險，但 task 驗證矩陣不足，可能漏掉 Claude/Codex 任一側或 nested untracked files。
  recommendation: 將 `1.1` 驗證擴成小型 path matrix，包含 installer、rules/template、Codex skill、Claude skill、nested untracked file。
  reviewer: B

## Rating

Critical count: 1
Warning count: 2
critical_gap: true

Round 1 判定為 `next_round`，因為 precedence 衝突是 artifact-level contract gap，且 staged/index-only 與 registry processing 都是會影響實作行為的驗收缺口。Suggestion 不阻擋 decision，但已一起納入 fix，避免 path filtering 測試過窄。

## Fix Actions

- 修改 `proposal.md`：補上 git working tree/index dirty changes，並說明 dirty-source guard 在 `--repair-all` 中優先於 local metadata validation。
- 修改 `design.md`：明確定義 guard 在 registry processing 與 metadata validation 前執行；dirty invalid `rules.yaml` 以 skip exit 0 處理；source-sensitive paths 使用遞迴 skill directory wording；dirty detection 包含 git index 與 working tree。
- 修改 `specs/spectra-plus-skills/spec.md`：新增 dirty invalid `rules.yaml` precedence、invalid registry target precedence、staged-only source-sensitive change scenarios。
- 修改 `tasks.md`：補 path matrix、dirty invalid `rules.yaml`、invalid registry target、staged-only fixture 驗證任務。
- 重新執行 `spectra validate guard-dirty-source-auto-repair`，結果通過。

## Decision

next_round
