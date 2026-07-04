# Apply Plus Review — Round 2

## Reviewer Findings

### Critical

None.

### Warning

- severity: Warning
  confidence: 100
  location: `install-spectra-plus.fish`; `openspec/changes/version-spectra-plus-skills/tasks.md`
  summary: `install_target --dry-run` 沒有驗證 local plus metadata，corrupt `rules.yaml` 可能成功退出；task 2.2 要求 installer/repair-all 對 invalid local plus metadata fail loudly。
  recommendation: 在 `install_target` 的 dry-run branch 前執行 `validate_plus_metadata_source`，並新增 corrupt local rules `--target --dry-run` 測試。
  source: A

### Suggestion

- severity: Suggestion
  confidence: 75
  location: `scripts/spectra-plus/tests/generator-checks.fish`
  summary: Generator tests 會 mutation 真實 `scripts/spectra-plus/rules.yaml`，若 assertion 在 restore 前失敗，工作樹會留下 corrupt rules。
  recommendation: 新增 bad-rules helper，讓測試命令執行後立即 restore `rules.yaml`，再做 assertions。
  source: B

## Rating

surviving Critical count: 0
surviving Warning count: 1
critical_gap: false

Round 2 的 confidence filter 後仍有 1 個 Warning。該 finding 直接對應 task 2.2 的 installer local rules metadata failure handling，因此本輪 decision 為 `next_round`。

## Fix Actions

- 更新 `install-spectra-plus.fish`，在 `install_target` 驗證 generator 與 `rules.yaml` 存在後立即呼叫 `validate_plus_metadata_source`，因此 `--target --dry-run` 也會對 corrupt local plus metadata fail loudly。
- 更新 `scripts/spectra-plus/tests/repair-all-checks.fish`，新增 corrupt local rules `--target --dry-run` case，驗證 non-zero exit、stderr 命名 `spectraPlusVersion`、沒有 dry-run action output、且 target outputs 不變。
- 更新 `scripts/spectra-plus/tests/generator-checks.fish`，新增 `run_with_bad_rules_expect` helper，bad-rules 測試在命令結束後立即 restore `rules.yaml`，避免 assertion failure 留下 corrupt source-of-truth。
- 重新執行 `fish scripts/spectra-plus/tests/generator-checks.fish`、`fish scripts/spectra-plus/tests/repair-all-checks.fish`、`spectra validate "version-spectra-plus-skills"`，結果皆通過。

## Decision

next_round
