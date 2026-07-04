## ADDED Requirements

### Requirement: Generated plus skill version metadata

The system SHALL emit stable plus-layer freshness metadata into the top-level YAML frontmatter of every generated `spectra-propose-plus` and `spectra-apply-plus` skill file. The metadata MUST be controlled by `scripts/spectra-plus/rules.yaml` and MUST be emitted into all configured generated variants. The generated metadata MUST include `spectraPlusVersion` and `spectraPlusUpdated`. The generated metadata MUST NOT use a per-generation timestamp. The existing nested `metadata.version` field MUST NOT be used as the plus-layer freshness signal.

#### Scenario: Full regeneration emits current metadata

- **WHEN** the user runs `scripts/spectra-plus/generate.fish` with no arguments
- **THEN** each generated plus skill file top-level YAML frontmatter contains `spectraPlusVersion: 1.1.0`
- **AND** each generated plus skill file top-level YAML frontmatter contains `spectraPlusUpdated: 2026-07-04`
- **AND** each generated plus skill file retains the generated-file marker

##### Example: generated output set

| Output Path | Required Version | Required Updated Date |
| ----- | ----- | ----- |
| `.claude/skills/spectra-propose-plus/SKILL.md` | `spectraPlusVersion: 1.1.0` | `spectraPlusUpdated: 2026-07-04` |
| `.claude/skills/spectra-apply-plus/SKILL.md` | `spectraPlusVersion: 1.1.0` | `spectraPlusUpdated: 2026-07-04` |
| `.agents/skills/spectra-propose-plus/SKILL.md` | `spectraPlusVersion: 1.1.0` | `spectraPlusUpdated: 2026-07-04` |
| `.agents/skills/spectra-apply-plus/SKILL.md` | `spectraPlusVersion: 1.1.0` | `spectraPlusUpdated: 2026-07-04` |

#### Scenario: Regeneration remains idempotent

- **WHEN** the generator is run twice in a row with no source, rules, or template changes between runs
- **THEN** both runs produce byte-identical plus skill files
- **AND** the metadata values do not change between the two runs

### Requirement: Rules validation requires plus metadata

The generator SHALL validate the plus-layer metadata contract before writing generated plus skill outputs. Each plus skill entry under `scripts/spectra-plus/rules.yaml` MUST include `spectraPlusVersion` and `spectraPlusUpdated` in its metadata block. `spectraPlusUpdated` MUST match the stable date format `YYYY-MM-DD`. The `spectra-propose-plus` and `spectra-apply-plus` metadata blocks MUST declare identical `spectraPlusVersion` values and identical `spectraPlusUpdated` values.

#### Scenario: Missing version metadata fails generation

- **WHEN** a plus skill entry in `rules.yaml` lacks `spectraPlusVersion`
- **THEN** `scripts/spectra-plus/generate.fish` exits with code 2
- **AND** stderr names the missing `spectraPlusVersion` field
- **AND** no plus skill file is partially overwritten

#### Scenario: Missing updated date metadata fails generation

- **WHEN** a plus skill entry in `rules.yaml` lacks `spectraPlusUpdated`
- **THEN** `scripts/spectra-plus/generate.fish` exits with code 2
- **AND** stderr names the missing `spectraPlusUpdated` field
- **AND** no plus skill file is partially overwritten

#### Scenario: Invalid updated date metadata fails generation

- **WHEN** `spectraPlusUpdated` does not match `YYYY-MM-DD`
- **THEN** `scripts/spectra-plus/generate.fish` exits with code 2
- **AND** stderr names `spectraPlusUpdated`
- **AND** no plus skill file is partially overwritten

#### Scenario: Mismatched plus metadata fails generation

- **WHEN** `spectra-propose-plus` and `spectra-apply-plus` declare different `spectraPlusVersion` or `spectraPlusUpdated` values
- **THEN** `scripts/spectra-plus/generate.fish` exits with code 2
- **AND** stderr names the mismatched plus metadata field
- **AND** no plus skill file is partially overwritten

### Requirement: Repair checks plus metadata freshness

The installer and repair-all current-state checks SHALL treat plus skill metadata as part of the generated output freshness contract. The current `spectraPlusVersion` and `spectraPlusUpdated` values SHALL be read from the local `scripts/spectra-plus/rules.yaml` source of truth. A target project SHALL be current only when every generated plus skill output top-level YAML frontmatter contains the current `spectraPlusVersion` and `spectraPlusUpdated` values.

#### Scenario: Target missing plus metadata is stale

- **GIVEN** a registered target project has generated plus skill outputs without `spectraPlusVersion`
- **WHEN** the user runs repair-all
- **THEN** the target is treated as stale
- **AND** repair-all rewrites the generated plus skill outputs with current metadata

#### Scenario: Target with old plus metadata is stale

- **GIVEN** a registered target project has generated plus skill outputs containing `spectraPlusVersion: 1.0.0`
- **WHEN** the user runs repair-all
- **THEN** the target is treated as stale
- **AND** repair-all rewrites the generated plus skill outputs with `spectraPlusVersion: 1.1.0`
- **AND** repair-all rewrites the generated plus skill outputs with `spectraPlusUpdated: 2026-07-04`

#### Scenario: Target with old updated date metadata is stale

- **GIVEN** a registered target project has generated plus skill outputs containing `spectraPlusUpdated: 2026-01-01`
- **WHEN** the user runs repair-all
- **THEN** the target is treated as stale
- **AND** repair-all rewrites the generated plus skill outputs with `spectraPlusUpdated: 2026-07-04`

#### Scenario: Target with one stale generated variant is stale

- **GIVEN** a registered target project has one generated plus skill output with stale plus metadata
- **AND** the other generated plus skill outputs contain current plus metadata
- **WHEN** the user runs repair-all
- **THEN** the target is treated as stale
- **AND** repair-all rewrites every generated plus skill output with current plus metadata

#### Scenario: Local rules metadata parse failure aborts repair

- **GIVEN** local `scripts/spectra-plus/rules.yaml` lacks a valid `spectraPlusVersion` or `spectraPlusUpdated`
- **WHEN** the user runs repair-all
- **THEN** repair-all exits with a non-zero status
- **AND** stderr names the invalid plus metadata field
- **AND** repair-all does not report the target as current
- **AND** repair-all does not modify the target generated plus skill outputs

#### Scenario: Target with current plus metadata can be skipped

- **GIVEN** a registered target project has generated plus skill outputs containing current plus metadata
- **AND** the target also satisfies the existing generated plus skill and `spectra-commit` guard checks
- **WHEN** the user runs repair-all
- **THEN** the target can be reported as already current
