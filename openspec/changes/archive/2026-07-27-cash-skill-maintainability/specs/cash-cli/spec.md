## MODIFIED Requirements

### Requirement: Live namespace 與歷史邊界

live scan SHALL只包含`.agents/skills/cash-*/`、`.claude/skills/cash-*/`、`scripts/cash-skills/blocks/`、`scripts/cash-skills/generate.fish`、`scripts/cash-skills/variant-rules.yaml`、`scripts/cash-skills/SKILL-LINT.md`、`CASH-GLOSSARY.md`、`install-cash-skills.fish`、`scripts/cash-skills/tests/`、`.cash-skills/`、`scripts/cash-cli/`、`AGENTS.md`、`CLAUDE.md`、`CASH-SKILLS.md`、`.cash.yaml`與`openspec/specs/`。這些surface SHALL NOT包含可執行的Spectra CLI command、`Requires spectra CLI`或未治理的`.spectra/`runtime read。active migration change/reviews、`openspec/changes/archive/`與signal occurrence history SHALL保留provenance原文。Legacy migration code SHALL只在下列明列paths辨識`SPECTRA` markers、`.spectra.yaml`、`.spectra/touched`、`.spectra/snapshots`與`spectra-*`directories：`install-cash-skills.fish`、`uninstall-spectra-plus-repair.fish`、`scripts/cash-skills/legacy-spectra-digests.tsv`，以及`.cash-skills/lib/cash_cli/`中負責`touched ensure` legacy import的module；`.spectra.yaml`→`.cash.yaml` config migration亦限於`install-cash-skills.fish`。這些paths之外的live surface MUST NOT出現legacy literal，且以上任何path MUST NOT執行Spectra binary或讀取其他Spectra state。

#### Scenario: Live namespace residue scan

- **WHEN**contract test掃描所有non-archive live surfaces
- **THEN**任何可執行的`spectra`command、compatibility declaration或runtime config read使測試失敗
- **AND**明列的legacy detector literals不被誤判為runtime dependency

#### Scenario: 歷史 artifacts 不回寫

- **WHEN**namespace migration完成
- **THEN**`openspec/changes/archive/`內既有files維持逐byte不變
- **AND**signal occurrence中的歷史provenance不被重新命名

#### Scenario: 生成源頭檔納入 scan surface

- **WHEN** `scripts/cash-skills/variant-parity/` 自工作樹移除且生成管線檔案（`scripts/cash-skills/blocks/`、`scripts/cash-skills/generate.fish`、`scripts/cash-skills/variant-rules.yaml`）建立後
- **THEN** live scan 的枚舉不含 `scripts/cash-skills/variant-parity/`
- **AND** 生成管線檔案與 `scripts/cash-skills/SKILL-LINT.md`、`CASH-GLOSSARY.md` 皆在 scan surface 內
