# Apply Plus Review — Round 1

## Reviewer Findings

### Critical

- severity: Critical
  confidence: 100
  location: `scripts/spectra-plus/generate.fish`; `install-spectra-plus.fish`
  summary: `spectraPlusVersion` 只檢查存在與一致性，`null` 或空字串等非有效字串仍可能被接受並輸出到 generated frontmatter。
  recommendation: 在 generator 與 installer metadata-source checks 中驗證 `spectraPlusVersion` 為 non-empty string，並補 generator/repair-all tests 覆蓋 `null` / empty version。
  source: B

### Warning

- severity: Warning
  confidence: 80
  location: `install-spectra-plus.fish`
  summary: `repair_all` 在 `--dry-run` 分支會早於 `validate_plus_metadata_source` return，corrupt local plus metadata 可能 dry-run exit 0。
  recommendation: 將 `validate_plus_metadata_source` 移到 dry-run 分支之前，並補 dry-run bad local rules test。
  source: A+B

### Suggestion

None.

## Rating

surviving Critical count: 1
surviving Warning count: 1
critical_gap: true

Round 1 的 confidence filter 後仍有 1 個 Critical 與 1 個 Warning。Critical 直接違反 metadata validation contract；Warning 直接影響 local rules metadata failure handling 在 dry-run 下的行為，因此本輪 decision 為 `next_round`。

## Fix Actions

- 更新 `scripts/spectra-plus/generate.fish`，新增 `validate_plus_metadata_value`，要求 `spectraPlusVersion` 與 `spectraPlusUpdated` 都是 non-empty string，並沿用 existing `YYYY-MM-DD` 檢查。
- 更新 `install-spectra-plus.fish`，讓 `plus_metadata_value` 要求 expected metadata 為 non-empty string，並將 `validate_plus_metadata_source` 移到 `repair_all` dry-run early return 之前。
- 更新 `scripts/spectra-plus/tests/generator-checks.fish`，新增 `null-version` 與 `empty-version` negative cases，要求 code 2、stderr 命名 `spectraPlusVersion`、且 generated outputs 不被 partially overwritten。
- 更新 `scripts/spectra-plus/tests/repair-all-checks.fish`，新增 bad local rules null version case 與 bad local rules dry-run case，驗證 non-zero exit、stderr field naming、未回報 target current、且 target outputs 不變。
- 重新執行 `fish scripts/spectra-plus/tests/generator-checks.fish`、`fish scripts/spectra-plus/tests/repair-all-checks.fish`、`spectra validate "version-spectra-plus-skills"`，結果皆通過。

## Decision

next_round
