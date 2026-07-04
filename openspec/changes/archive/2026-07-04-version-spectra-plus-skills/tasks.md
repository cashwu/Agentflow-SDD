## 1. Plus metadata generation contract

- [x] 1.1 實作 `Version metadata lives in rules.yaml and is emitted as stable frontmatter fields`：在 `scripts/spectra-plus/rules.yaml` 讓 `spectra-propose-plus` 與 `spectra-apply-plus` 都宣告 current `spectraPlusVersion: 1.1.0` 與 `spectraPlusUpdated: 2026-07-04`，交付 `Generated plus skill version metadata` 的 source-of-truth；驗證：用 yq 或 content review 確認兩個 plus skill metadata block 都含有兩個欄位且值完全一致。
- [x] 1.2 實作 `Generator validates the plus metadata contract`：更新 `scripts/spectra-plus/generate.fish`，讓缺少 `spectraPlusVersion`、缺少 `spectraPlusUpdated`、`spectraPlusUpdated` 不符合 `YYYY-MM-DD`、或兩個 plus skill metadata block 的 `spectraPlusVersion` / `spectraPlusUpdated` 不一致時以 code 2 fail loudly，stderr 必須命名 offending field，且不得 partially overwrite 既有 generated outputs；驗證：`Rules validation requires plus metadata` 的負向情境可由 generator test 覆蓋 exit code、stderr field naming、以及 failing run 前後 generated output checksums/contents 不變。
- [x] 1.3 重新產生四個 plus skill outputs，讓 `.claude/skills/spectra-propose-plus/SKILL.md`、`.claude/skills/spectra-apply-plus/SKILL.md`、`.agents/skills/spectra-propose-plus/SKILL.md`、`.agents/skills/spectra-apply-plus/SKILL.md` 都符合 `Generated plus skill version metadata`；驗證：content review 確認四檔 YAML frontmatter 都含 top-level `spectraPlusVersion: 1.1.0`、`spectraPlusUpdated: 2026-07-04`，且重跑 generator 不產生非預期 diff。

## 2. Installer and repair freshness checks

- [x] 2.1 實作 `Installer current checks use explicit current plus metadata`：更新 `install-spectra-plus.fish` 的 current/validation checks，從 local `scripts/spectra-plus/rules.yaml` 解析 expected `spectraPlusVersion` 與 `spectraPlusUpdated`，要求兩個 plus skill metadata block 一致，並只用 generated `SKILL.md` YAML frontmatter 判斷 target 是否 current；驗證：content review 確認 `plus_outputs_are_current` 與 `validate_plus_outputs_current` 都比對 rules-derived current metadata，且 target 缺少 current version/update metadata 或 metadata mismatch 時會被判定 stale，交付 `Repair checks plus metadata freshness`。
- [x] 2.2 實作 installer local rules metadata failure handling：當 local `scripts/spectra-plus/rules.yaml` 缺少 valid plus metadata 或兩個 plus skill metadata block 不一致時，installer/repair-all 必須 fail loudly、不得把 target 報告為 current、且不得修改 target generated outputs；驗證：repair-all test 建立 corrupt local rules case，確認 non-zero exit、stderr 命名 invalid field、target output checksums/contents 不變。
- [x] 2.3 確認 scope boundary：實作過程不得修改 `install-agentflow-sdd.fish`，並且不得改變 base non-plus Spectra skills 的 version semantics；驗證：git diff review 確認 touched files 不包含 `install-agentflow-sdd.fish`，且 non-plus skill `metadata.version` 未被重新定義。

## 3. Test coverage

- [x] [P] 3.1 更新 `scripts/spectra-plus/tests/generator-checks.fish`，覆蓋 `Generated plus skill version metadata` 與 `Rules validation requires plus metadata`：四個 generated outputs 的 YAML frontmatter 必須含 current metadata，且缺 version、缺 updated date、invalid date、mismatched plus metadata 四類 rules cases 必須 fail with code 2、stderr 命名對應 field、並證明 generated outputs 未被 partially overwritten；驗證：fish scripts/spectra-plus/tests/generator-checks.fish 通過。
- [x] [P] 3.2 更新 `scripts/spectra-plus/tests/repair-all-checks.fish`，覆蓋 `Repair checks plus metadata freshness`：fixture target 具有舊版 `spectraPlusVersion`、舊版 `spectraPlusUpdated`、缺少 plus metadata、只有單一 generated variant stale、或 local rules metadata parse failure 時，repair-all 必須依情境重寫為 rules-derived current metadata或 fail loudly 且不修改 target outputs；驗證：fish scripts/spectra-plus/tests/repair-all-checks.fish 通過。

## 4. Final validation

- [x] 4.1 執行完整驗證，確認 `Tests assert version freshness across all variants` 的契約成立且 Spectra artifacts 可套用；驗證：fish scripts/spectra-plus/tests/generator-checks.fish、fish scripts/spectra-plus/tests/repair-all-checks.fish、spectra validate version-spectra-plus-skills 全部通過。
