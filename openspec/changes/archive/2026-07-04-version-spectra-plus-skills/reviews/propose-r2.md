# Propose Plus Review — Round 2

## Reviewer Findings

### Critical

None.

### Warning

- severity: Warning
  confidence: 100
  location: `openspec/changes/version-spectra-plus-skills/design.md`; `openspec/changes/version-spectra-plus-skills/tasks.md`
  summary: Design 要求 installer 無法解析 local `scripts/spectra-plus/rules.yaml` expected plus metadata 時 fail loudly，但 tasks 只覆蓋 stale/missing target metadata 與 content review。
  recommendation: 增加明確 task/test，移除或破壞 local `spectraPlusVersion` / `spectraPlusUpdated` 後，驗證 installer/repair-all 清楚失敗、不回報 target current、且不修改 target outputs。
  source: B

### Suggestion

- severity: Suggestion
  confidence: 75
  location: `openspec/changes/version-spectra-plus-skills/design.md`; `openspec/changes/version-spectra-plus-skills/tasks.md`
  summary: Plus-layer version duplicated在兩個 plus skill metadata blocks，但 artifacts 只要求 content review 一致性，未來 bump 可能只更新其中一個 block。
  recommendation: 增加 generator 或 installer validation，要求 `spectra-propose-plus` 與 `spectra-apply-plus` 宣告相同 `spectraPlusVersion` 與 `spectraPlusUpdated`。
  source: B

## Rating

surviving Critical count: 0
surviving Warning count: 1
critical_gap: false

Round 2 的 confidence filter 後仍有 1 個 Warning，因為 design failure mode 沒有對應 task/test coverage。該 finding 直接指向 artifact contract 覆蓋缺口，因此本輪 decision 為 `next_round`。

## Fix Actions

- 更新 `openspec/changes/version-spectra-plus-skills/specs/spectra-plus-skills/spec.md`，新增 `Mismatched plus metadata fails generation` 與 `Local rules metadata parse failure aborts repair` scenarios，並要求 installer/repair-all expected values 來自 local `rules.yaml`。
- 更新 `openspec/changes/version-spectra-plus-skills/design.md`，要求 generator 驗證兩個 plus skill metadata blocks 一致，並要求 installer 在 local rules metadata invalid 或 mismatch 時 fail loudly、不誤判 current、不修改 target outputs。
- 更新 `openspec/changes/version-spectra-plus-skills/tasks.md`，補上 generator mismatched metadata negative test、installer local rules failure handling task、repair-all local rules parse failure fixture，以及 no-modification 驗證。
- 重新執行 `spectra validate "version-spectra-plus-skills"`，結果通過。

## Decision

next_round
