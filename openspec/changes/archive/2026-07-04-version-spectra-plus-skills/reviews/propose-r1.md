# Propose Plus Review — Round 1

## Reviewer Findings

### Critical

None.

### Warning

- severity: Warning
  confidence: 100
  location: `openspec/changes/version-spectra-plus-skills/specs/spectra-plus-skills/spec.md`; `openspec/changes/version-spectra-plus-skills/tasks.md`
  summary: `tasks.md` 對 generator metadata negative cases 只要求 fail with code 2，但 spec 同時要求 stderr 命名 offending field，且不得 partially overwrite plus skill files。
  recommendation: 更新 generator test task，要求缺少 `spectraPlusVersion`、缺少 `spectraPlusUpdated`、invalid `spectraPlusUpdated` 三種情境都驗證 exit code、stderr field naming，以及 failing run 前後 generated output 未變。
  source: A+B

### Suggestion

- severity: Suggestion
  confidence: 75
  location: `openspec/changes/version-spectra-plus-skills/design.md`; `openspec/changes/version-spectra-plus-skills/tasks.md`
  summary: Installer freshness expected values 若另行 hard-code，未來可能與 `scripts/spectra-plus/rules.yaml` drift。
  recommendation: 要求 installer 從 local `scripts/spectra-plus/rules.yaml` 解析 current `spectraPlusVersion` 與 `spectraPlusUpdated`，或用測試保證 expected values 與 rules 一致。
  source: B

- severity: Suggestion
  confidence: 75
  location: `openspec/changes/version-spectra-plus-skills/design.md`; `openspec/changes/version-spectra-plus-skills/specs/spectra-plus-skills/spec.md`; `openspec/changes/version-spectra-plus-skills/tasks.md`
  summary: Artifacts 要求 top-level frontmatter metadata，但部分 validation/test wording 只說 output contains fields，可能讓欄位出現在 frontmatter 之外也通過。
  recommendation: 明確要求 generator validation、installer checks、tests 都只檢查 YAML frontmatter 的 top-level `spectraPlusVersion` 與 `spectraPlusUpdated`。
  source: B

- severity: Suggestion
  confidence: 50
  location: `openspec/changes/version-spectra-plus-skills/specs/spectra-plus-skills/spec.md`; `openspec/changes/version-spectra-plus-skills/tasks.md`
  summary: Repair-all 測試未明確涵蓋 stale `spectraPlusUpdated` 或只有單一 generated variant stale 的情境。
  recommendation: 補上 stale updated date 與 single-variant stale output cases。
  source: B

## Rating

surviving Critical count: 0
surviving Warning count: 1
critical_gap: false

Round 1 的 confidence filter 後仍有 1 個 Warning，且該 finding 直接對應 spec 對 stderr field naming 與 no partial overwrite 的 SHALL/MUST contract，因此本輪不能通過，decision 為 `next_round`。

## Fix Actions

- 更新 `openspec/changes/version-spectra-plus-skills/specs/spectra-plus-skills/spec.md`，明確要求 metadata 位於 generated `SKILL.md` 的 top-level YAML frontmatter，要求 installer/repair-all 從 local `scripts/spectra-plus/rules.yaml` 取得 current values，並新增 stale updated date 與 single stale generated variant scenarios。
- 更新 `openspec/changes/version-spectra-plus-skills/design.md`，把 installer freshness check 改為 rules-derived expected values，並限定只用 YAML frontmatter 作為 metadata source。
- 更新 `openspec/changes/version-spectra-plus-skills/tasks.md`，要求 generator tests 驗證 exit code、stderr field naming、no partial overwrite，以及 frontmatter-only metadata；repair-all tests 也補 stale version、stale updated date、missing metadata、single stale variant cases。
- 重新執行 `spectra validate "version-spectra-plus-skills"`，結果通過。

## Decision

next_round
