# cash-skill-workflows Specification

## Purpose

TBD - created by archiving change 'fork-spectra-skills-to-cash'. Update Purpose after archive.

## Requirements

### Requirement: Cash skill inventory and ownership

The repository SHALL provide exactly these twelve cash workflow skills for both Codex and Claude: `cash-analyze`, `cash-apply`, `cash-archive`, `cash-ask`, `cash-audit`, `cash-commit`, `cash-debug`, `cash-discuss`, `cash-drift`, `cash-ingest`, `cash-propose`, and `cash-verify`. Every cash skill file MUST be a source-controlled canonical file owned by this repository.

#### Scenario: Complete dual-variant inventory

- **WHEN** the cash skill inventory is checked
- **THEN** all twelve skills exist under `.agents/skills/`
- **AND** all twelve skills exist under `.claude/skills/`
- **AND** no listed skill is missing from either variant

#### Scenario: Cash ownership metadata

- **WHEN** a cash skill frontmatter block is inspected
- **THEN** its `name` equals its `cash-*` directory name
- **AND** it does not contain `generatedBy: "Spectra"`
- **AND** it does not contain `spectraPlusVersion`, `spectraPlusUpdated`, or `spectraPlusFingerprint`


<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---
### Requirement: Propose and apply absorb the former plus workflows

The system SHALL expose the full proposal quality-gate workflow through `cash-propose` and the full implementation quality-gate workflow through `cash-apply`. The system MUST NOT provide a weaker cash base tier or any `cash-*-plus` skill.

#### Scenario: Cash proposal is the single proposal tier

- **WHEN** a user invokes `cash-propose`
- **THEN** the workflow creates all artifacts required for apply
- **AND** validates them before its sub-agent quality gate
- **AND** no separate `cash-propose-plus` workflow is required

#### Scenario: Cash apply is the single implementation tier

- **WHEN** a user invokes `cash-apply`
- **THEN** the workflow implements the selected change and runs its quality gate after all tasks complete
- **AND** no separate `cash-apply-plus` workflow is required


<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---
### Requirement: Cash namespace routes workflows while Spectra remains the artifact engine

Cash skills SHALL use the cash namespace for every skill-to-skill transition. Codex instructions MUST use `$cash-*`; Claude instructions MUST use the corresponding `/cash-*` syntax. Artifact operations MUST continue to use the Spectra CLI and the configured `openspec/` paths.

#### Scenario: Internal workflow transition

- **WHEN** `cash-discuss` recommends formalizing a decision
- **THEN** it directs the user to `cash-propose`
- **AND** it does not direct the user to a `spectra-*` or `cash-*-plus` skill

#### Scenario: Artifact command remains Spectra-owned

- **WHEN** a cash skill lists, creates, validates, analyzes, or archives artifacts
- **THEN** it invokes the applicable `spectra` CLI command
- **AND** it reads or writes the configured `openspec/` artifact path
- **AND** it does not introduce a cash CLI adapter


<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---
### Requirement: Cash proposal quality gate

`cash-propose` SHALL create proposal, design, delta specs, and tasks according to the Spectra artifact DAG, run `spectra validate`, and then execute the shared graded review loop once per change. It MUST write non-spec artifacts and review prose in Traditional Chinese, keep spec files in English, leave the change active, and MUST NOT invoke apply or park.

#### Scenario: Validation precedes review

- **WHEN** all artifacts required for apply have been created
- **THEN** `cash-propose` runs `spectra validate "<change>"`
- **AND** fixes validation failures before starting review round 1
- **AND** revalidates before the next round whenever a fix action changes an artifact

#### Scenario: Proposal workflow terminates without apply

- **WHEN** the proposal review loop ends with `passed` or `aborted`
- **THEN** `cash-propose` records the final round and summary
- **AND** leaves the change under `openspec/changes/`
- **AND** does not invoke `cash-apply` or `spectra park`

#### Scenario: Large impact list produces an advisory

- **WHEN** proposal `## Impact` contains 16 affected-code entries after excluding `(none)` placeholders and counting each directory as one entry
- **THEN** `cash-propose` prints a non-blocking split-by-capability advisory
- **WHEN** the same count is 15
- **THEN** `cash-propose` prints no impact-granularity advisory


<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---
### Requirement: Cash apply quality gate

`cash-apply` SHALL implement tasks from the selected change, maintain the implementation-notes contract, and start the shared graded review loop only after every task is complete. Archive guidance MUST remain withheld until the final round records `decision: passed`.

#### Scenario: Review starts after task completion

- **WHEN** every checkbox in `tasks.md` is `[x]`
- **THEN** `cash-apply` starts one per-change review loop
- **AND** it does not start that loop per task

#### Scenario: Archive guidance follows a passed gate

- **WHEN** the apply review loop has not recorded `decision: passed`
- **THEN** `cash-apply` does not recommend archive
- **WHEN** the apply review loop records `decision: passed`
- **THEN** the completion summary can direct the user to `cash-archive`

#### Scenario: Design circuit breaker

- **WHEN** a review-loop fix requires a synchronization primitive, identity or generation type, or state machine not defined in `design.md`
- **THEN** `cash-apply` records `needs-design`
- **AND** records `decision: aborted`
- **AND** directs the user to `cash-ingest`
- **AND** does not implement the missing design inside the fix loop


<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---
### Requirement: Shared graded review convergence

The cash proposal and apply gates SHALL use a maximum of six rounds. A run's first round MUST be a full round with two fresh independent reviewers, the fourth round MUST be a full checkpoint when reached, and every other continued round MUST be a micro verification round with one fresh reviewer. The main agent MUST apply the defined confidence filter and derive decisions from the cumulative blocking set without a rater sub-agent or `quality_score`.

#### Scenario: Full first round

- **WHEN** a new review run starts
- **THEN** it spawns Reviewer A for adherence and Reviewer B for quality as two fresh independent calls
- **AND** records `round_type: full`

#### Scenario: Micro verification round

- **WHEN** a non-passing round is followed by a round whose run position is not 4
- **THEN** the next round spawns one fresh Reviewer V
- **AND** Reviewer V verifies every cumulative blocking member, recorded fixes, and fix-introduced defects
- **AND** the round records `round_type: micro`

#### Scenario: Blocking set reaches zero

- **WHEN** the post-filter cumulative blocking set contains no Critical and no Warning member
- **THEN** the round records `decision: passed`
- **AND** no additional round starts

#### Scenario: Six-round cap

- **WHEN** round 6 retains a blocking member
- **THEN** the round records `decision: aborted`
- **AND** the workflow performs abort triage
- **AND** it does not recommend an unchanged rerun


<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---
### Requirement: Review records use cash provenance

Each cash review round SHALL write one immutable round file under `openspec/changes/<change>/reviews/`. Proposal files MUST use `propose-r<N>.md`; apply files MUST use `apply-r<N>.md`. Round headings and source-skill provenance MUST identify cash workflows, while stable schema field names and decision values remain unchanged.

#### Scenario: Cash proposal round record

- **WHEN** a `cash-propose` round completes
- **THEN** its heading is `# Cash Propose Review — Round <N>`
- **AND** it contains `## Reviewer Findings`, `## Rating`, `## Fix Actions`, and `## Decision` in that order
- **AND** its decision is exactly `passed`, `next_round`, or `aborted`

#### Scenario: Shared ledger

- **WHEN** a cash review round is finalized
- **THEN** exactly one row is appended to `reviews/loop-ledger.tsv`
- **AND** the row retains the seven-field ledger contract
- **AND** the source skill is recorded as `propose` or `apply`


<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---
### Requirement: Cash review gates preserve governed inputs and signals

Cash review gates SHALL preserve accepted-risks consent, grader immutability, deterministic signal checks, confidence filtering, fix propagation, abort triage, and signals write behavior from the migrated quality-gate baseline. Automated fix actions MUST NOT create, modify, or remove a signal `check` field.

#### Scenario: Signal provenance is normalized

- **WHEN** a qualifying Critical or Warning finding is written to a signal
- **THEN** the occurrence identifies `cash-propose` or `cash-apply` as its source skill
- **AND** the signal lifecycle and issue-class matching rules remain unchanged

#### Scenario: Accepted risk requires consent

- **WHEN** a finding is proposed for `accepted-risks.md`
- **THEN** the ledger entry is written only after explicit user consent in the current session
- **AND** no fix action edits that ledger without consent

#### Scenario: Protected grader input

- **WHEN** a fix action or self-check encounters a signal `check` field
- **THEN** it treats the field as immutable grader input
- **AND** it does not alter the field


<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---
### Requirement: Spectra updates do not mutate cash skills

Running `spectra update` or `spectra update --force` SHALL NOT create, modify, rename, or delete any cash skill file.

#### Scenario: Forced update isolation

- **GIVEN** an isolated project contains the complete cash skill inventory
- **WHEN** `spectra update --force` runs in that project
- **THEN** every cash skill checksum remains byte-identical
- **AND** Spectra-managed files remain outside the cash ownership boundary


<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---
### Requirement: Stateless cross-project installer

The repository SHALL provide `install-cash-skills.fish` as the only cash installation and update CLI. It MUST accept exactly one of `--target <project>`, `--register <project>`, `--unregister <project>`, `--list`, or `--all`; `--dry-run` and `--force` MUST be valid only with `--target` or `--all`. In target mode, the installer MUST validate the complete 24-file source inventory, source bundle version, target receipt when present, target directory, every managed destination conflict, and the exact retired plus skill candidates before its first target write. It SHALL remove recognized `.agents` and `.claude` `spectra-propose-plus` and `spectra-apply-plus` directories as part of a successful install, adoption, upgrade, repair, or equal-version cleanup, while preserving every other Spectra skill and unknown legacy content. It SHALL remain stateless with respect to automatic project discovery and scheduling while managing the target-local receipt and explicit user registry required for version and drift decisions. For each completed target-domain decision, it MUST emit exactly one terminal result line for `update`, `current`, `newer`, or `conflict`; conflict MUST exit with code 2, every other domain result MUST exit with code 0, and execution failures MUST exit with code 1 without emitting a domain result.

#### Scenario: Install into a clean target

- **WHEN** the installer receives a valid target with no cash destinations and no receipt
- **THEN** it installs all 24 canonical skill files
- **AND** every installed file is byte-identical to its source
- **AND** it publishes the current receipt
- **AND** it reports `Result: update`
- **AND** it exits with code 0

#### Scenario: Identical legacy target is adopted

- **WHEN** all 24 managed target files are byte-identical to the source and no receipt exists
- **THEN** the installer leaves all skill files unchanged
- **AND** it publishes the current receipt
- **AND** it reports `Result: update`
- **AND** it exits with code 0

#### Scenario: Mixed legacy target conflicts before writes

- **GIVEN** no receipt exists and the managed destinations are mixed, incomplete, or differ from the source
- **WHEN** the installer runs without `--force`
- **THEN** it reports every conflicting destination
- **AND** it reports `Result: conflict`
- **AND** it exits with code 2
- **AND** it does not install, replace, or publish any managed state

#### Scenario: Clean older target upgrades without force

- **GIVEN** a valid receipt records a version lower than the source
- **AND** every managed target file matches its recorded receipt digest
- **WHEN** the installer runs without `--force`
- **THEN** it replaces the 24 managed files with the source bundle
- **AND** it publishes the new receipt
- **AND** it reports `Result: update`
- **AND** it exits with code 0

#### Scenario: Equal target is current

- **GIVEN** a valid receipt records the source version
- **AND** all source and target file digests match the receipt
- **WHEN** the installer runs
- **THEN** it reports `Result: current`
- **AND** it performs no target write
- **AND** it exits with code 0

#### Scenario: Recognized retired plus skills are removed by installation

- **GIVEN** one or more exact retired plus directories contain only a regular `SKILL.md` with a closed frontmatter block containing exactly one matching `name` field for `spectra-propose-plus` or `spectra-apply-plus`
- **WHEN** the installer completes an install, adoption, upgrade, repair, or equal-version cleanup
- **THEN** it removes each recognized plus `SKILL.md` and its now-empty skill directory
- **AND** it preserves every non-plus Spectra skill and every path outside the four exact retired plus directories
- **AND** an otherwise current target reports `Result: update`

#### Scenario: Unsafe retired plus candidate fails before writes

- **GIVEN** an exact retired plus path is a symlink, is not a directory, contains an entry other than `SKILL.md`, or has a missing, symlinked, unreadable, malformed-frontmatter, duplicate-name, conflicting-name, or name-mismatched `SKILL.md`
- **WHEN** the installer performs preflight
- **THEN** it exits with code 1 without a domain result
- **AND** it does not modify cash files, receipt, or any retired plus candidate

#### Scenario: Equal-version source mutation is an integrity failure

- **GIVEN** a valid receipt records the source version
- **AND** at least one current source digest differs from the receipt digest
- **WHEN** the installer runs with or without `--force`
- **THEN** it exits with code 1 without a domain result
- **AND** it performs no target write

#### Scenario: Newer target is preserved

- **GIVEN** a valid receipt records a version greater than the source
- **WHEN** the installer runs with or without `--force`
- **THEN** it reports `Result: newer`
- **AND** it performs no target write
- **AND** it exits with code 0
- **AND** it does not remove retired plus candidates

#### Scenario: Drift conflicts before writes

- **GIVEN** a valid older or equal-version receipt and at least one managed target file differs from its trusted comparison content
- **AND** when versions are equal every current source digest matches the receipt
- **WHEN** the installer runs without `--force`
- **THEN** it identifies every conflicting destination
- **AND** it reports `Result: conflict`
- **AND** it exits with code 2
- **AND** it does not install, replace, or publish any managed state

#### Scenario: Force replaces only managed destinations

- **GIVEN** the target version is not newer than the source
- **AND** all source, receipt, and filesystem validation has succeeded
- **WHEN** the installer runs with `--force`
- **THEN** it installs or replaces differing managed cash destinations
- **AND** it publishes a receipt for the resulting 24 files
- **AND** it preserves every file outside the explicit 24-file inventory, receipt, and recognized retired plus entries
- **AND** it removes only recognized entries among the four exact retired plus directories
- **AND** it reports `Result: update`

#### Scenario: Dry run has no persistent effects

- **WHEN** the installer runs with `--dry-run`
- **THEN** it reports the domain result and complete action plan using normal preflight rules
- **AND** it does not create a target directory, target temporary file, receipt, registry, cache, lock, LaunchAgent, or background process
- **AND** it does not remove a retired plus skill


<!-- @trace
source: add-versioned-cash-skill-batch-update
updated: 2026-07-18
code:
  - .agents/skills/spectra-apply/SKILL.md
  - CASH-SKILLS.md
  - cash-skills.version
  - .agents/skills/spectra-analyze/SKILL.md
  - .agents/skills/spectra-verify/SKILL.md
  - install-cash-skills.fish
  - .agents/skills/spectra-propose/SKILL.md
tests:
  - scripts/cash-skills/tests/skill-checks.fish
-->

---
### Requirement: Cash installation has no repair automation

The cash installer MUST NOT compute freshness from Git state, schedule repair, install a LaunchAgent, fork a background process, or modify an active or non-plus Spectra-managed skill. During an explicit target installation it SHALL remove only recognized entries among the four exact retired `spectra-propose-plus` and `spectra-apply-plus` directories and SHALL NOT remove any other Spectra skill. Cash skill maintenance SHALL occur only through explicit source version changes and explicit installer invocations. Target receipts and the user registry SHALL persist only to support those explicit invocations and MUST NOT trigger future work.

#### Scenario: Completed cash installation

- **WHEN** a cash installation succeeds
- **THEN** persistent state consists only of the target cash skill files and target receipt
- **AND** no future process is scheduled
- **AND** a later source change does not propagate until the installer is explicitly invoked again

#### Scenario: Completed registry operation

- **WHEN** a target is registered, unregistered, or listed
- **THEN** no LaunchAgent, daemon, scheduled task, cache, lock, or background process is created
- **AND** the registry does not cause a later source change to propagate by itself


<!-- @trace
source: add-versioned-cash-skill-batch-update
updated: 2026-07-18
code:
  - .agents/skills/spectra-apply/SKILL.md
  - CASH-SKILLS.md
  - cash-skills.version
  - .agents/skills/spectra-analyze/SKILL.md
  - .agents/skills/spectra-verify/SKILL.md
  - install-cash-skills.fish
  - .agents/skills/spectra-propose/SKILL.md
tests:
  - scripts/cash-skills/tests/skill-checks.fish
-->

---
### Requirement: Cash commit preserves archive-first allowlisting

`cash-commit` SHALL collect and commit only artifacts that belong to the selected change and its explicit tracking file. When the user selects archive-first handling, it MUST archive before staging, collect the archive output paths, exclude unrelated dirty files, and MUST NOT treat deleted generated plus skills as an implicit allowlist exception.

#### Scenario: Archive-first commit excludes unrelated changes

- **GIVEN** the worktree contains files unrelated to the selected change
- **WHEN** the user confirms archive-first handling in `cash-commit`
- **THEN** `cash-commit` archives the selected change before staging
- **AND** stages only the selected change artifacts, archive output, and explicit tracking file
- **AND** leaves unrelated dirty files unstaged

#### Scenario: No generated-plus deletion exception

- **WHEN** a deleted `spectra-*-plus` path appears in git status
- **THEN** `cash-commit` does not automatically classify that path as protected change output
- **AND** normal selected-change allowlisting determines whether the path is staged


<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---
### Requirement: One-time legacy repair cleanup

The repository SHALL provide `uninstall-spectra-plus-repair.fish [--dry-run]`. A successful non-dry run MUST unload and remove the known `com.spectra.plus.repair` and `com.agentflow.spectra-plus.repair` LaunchAgents, remove their plist files, remove `$HOME/.config/spectra-plus/projects.txt`, and remove `$HOME/.cache/spectra-plus`. It MUST preserve `$HOME/Library/Logs/spectra-plus-repair.log`.

#### Scenario: Installed automation is removed

- **WHEN** the cleanup runs with one or both known LaunchAgents installed
- **THEN** it prints every target path found in the legacy repair registry before removing that registry
- **AND** it unloads each installed known label
- **AND** removes the corresponding plist
- **AND** removes the repair registry and cache after successful unloads
- **AND** preserves the diagnostic log

#### Scenario: Cleanup is idempotent

- **WHEN** none of the known LaunchAgents, plists, registry, or cache exist
- **THEN** cleanup reports a successful no-op
- **AND** exits with code 0

#### Scenario: Unexpected unload failure stops cleanup

- **GIVEN** a known plist exists
- **WHEN** `launchctl bootout` fails for a reason other than not-loaded or not-found
- **THEN** cleanup exits non-zero
- **AND** preserves the failing plist, registry, and cache
- **AND** prints the exact manual cleanup command to stderr

#### Scenario: Registry read failure stops before launchctl

- **GIVEN** the legacy registry path exists but is not a readable regular file or cannot be read completely
- **WHEN** cleanup performs preflight
- **THEN** cleanup exits non-zero before invoking `launchctl`
- **AND** preserves the plist, registry, cache, and diagnostic log

#### Scenario: Generic not-found text is not service absence

- **GIVEN** `launchctl print` fails with an error containing `not found` that does not exactly identify the queried known service as absent
- **WHEN** cleanup classifies the result
- **THEN** cleanup treats it as an unexpected failure
- **AND** preserves all removable legacy state

#### Scenario: Cleanup dry run

- **WHEN** cleanup runs with `--dry-run`
- **THEN** it lists the exact unload and removal actions
- **AND** lists every target path found in the legacy repair registry
- **AND** it does not invoke `launchctl bootout`
- **AND** it does not remove any file or directory


<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---
### Requirement: Legacy plus implementation is retired

The repository MUST remove the four generated `spectra-propose-plus` and `spectra-apply-plus` outputs, `scripts/spectra-plus/`, and `install-spectra-plus.fish`. It MUST remove active plus deletion-guard dependencies from the project workflow while leaving non-plus Spectra-managed skills untouched.

#### Scenario: Legacy repository paths are absent

- **WHEN** migration implementation is complete
- **THEN** all proposal-listed legacy plus paths are absent
- **AND** the Claude and Codex `spectra-commit` files match their unpatched Spectra-owned baseline without the generated-plus deletion exception
- **AND** all non-plus `spectra-*` skills remain available for Spectra ownership
- **AND** project workflow guidance uses cash skills


<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---
### Requirement: Cash contract regression suite

`scripts/cash-skills/tests/skill-checks.fish` SHALL verify inventory, metadata, namespace routing, quality-gate markers, bundle version governance, receipt schema, direct installer branches, registry branches, batch installer branches, cleanup branches, legacy removal, variant parity, and forced Spectra update isolation. The suite MUST use isolated targets, an isolated `HOME`, an isolated mutable source copy for runtime fixtures, explicit Git histories containing version-introduction and later unrelated commits for version-governance fixtures, and a stubbed `launchctl` for mutating test cases.

#### Scenario: Full regression suite passes

- **WHEN** the cash contract suite runs against a compliant repository
- **THEN** every required installer, version, receipt, registry, batch, cleanup, parity, and isolation branch passes
- **AND** no actual user LaunchAgent, registry, receipt, cache, or external project is modified

#### Scenario: Contract drift fails loudly

- **WHEN** a managed cash file, version, receipt field, command result, installer branch, registry branch, batch branch, cleanup branch, or isolation invariant violates this specification
- **THEN** the suite exits non-zero
- **AND** its diagnostics identify the failed invariant and relevant project-relative fixture or path

#### Scenario: Version fixture inventory remains complete

- **WHEN** the bundle version or any hardcoded version fixture changes
- **THEN** the suite verifies every repository assertion of the prior version was inventoried and updated
- **AND** ordering fixtures cover major, minor, patch, leading-zero, and arbitrary-length component boundaries


<!-- @trace
source: add-versioned-cash-skill-batch-update
updated: 2026-07-18
code:
  - .agents/skills/spectra-apply/SKILL.md
  - CASH-SKILLS.md
  - cash-skills.version
  - .agents/skills/spectra-analyze/SKILL.md
  - .agents/skills/spectra-verify/SKILL.md
  - install-cash-skills.fish
  - .agents/skills/spectra-propose/SKILL.md
tests:
  - scripts/cash-skills/tests/skill-checks.fish
-->

---
### Requirement: cash-propose quality gate

The system SHALL provide a `cash-propose` skill that retains the complete artifact-creation contract for proposal, design, specs, and tasks (proposal, design, specs, tasks) but replaces the inline self-review and analyze-fix loop with a sub-agent review/rating/fix loop. The skill MUST run `spectra validate` before entering the sub-agent loop, so validation fixes happen before the quality gate reviews the final artifact state. The skill MUST run the loop at per-change granularity (after all required artifacts are written and validation has passed, not per artifact). The skill MUST cap the loop at 6 rounds. The skill MUST NOT use a rater sub-agent and MUST NOT produce a `quality_score`; instead the main agent SHALL derive the round decision mechanically from the post-filter findings. The run's first round MUST be treated as passing if and only if, after the confidence filter, no surviving finding has `severity == Critical` and no surviving finding has `severity == Warning`; in a re-run whose cumulative blocking set was seeded, the first round instead uses the cumulative-blocking-set pass condition per the `Graded convergence and micro-verification round` requirement. A round after the run's first round MUST be treated as passing if and only if, after the confidence filter, the cumulative blocking set contains no `Critical` and no `Warning` finding, where blocking and the cumulative blocking set are defined by the `Graded convergence and micro-verification round` requirement; non-blocking findings route to triage per that requirement. When a round's decision is `next_round`, the main agent MUST derive the next round's type (full or micro) per the `Graded convergence and micro-verification round` requirement. Fix obligations in this requirement are subject to the grader-protection exception defined in the `Review loop grader immutability` requirement and to the consented accepted-risks path defined in the `Accepted-risks ledger` and `Review round action obligation` requirements. The skill MUST NOT execute `spectra park` at the end of its workflow.

#### Scenario: Loop reaches pass condition before max rounds

- **WHEN** a round completes with an empty cumulative blocking set after the confidence filter
- **THEN** the skill writes the corresponding round file with `decision: passed`
- **AND** stops the loop without starting another round
- **AND** continues to the final summary without running post-gate validation fixes
- **AND** does not execute `spectra park`

#### Scenario: Validation precedes the quality gate

- **WHEN** `cash-propose` has created all artifacts required for apply
- **THEN** it runs `spectra validate "<name>"`
- **AND** fixes validation errors before the first review-loop round
- **AND** the review loop starts only after validation passes

- **WHEN** a review-loop Fix Action modifies proposal, design, tasks, or spec artifacts
- **THEN** it runs `spectra validate "<name>"` again
- **AND** fixes validation errors before starting the next review-loop round

#### Scenario: Surviving blocking Warning forces another round

- **WHEN** a round completes with no blocking `Critical` finding but at least one blocking `Warning` finding in the cumulative blocking set after the confidence filter
- **THEN** the skill writes the round file with `decision: next_round`
- **AND** fixes the blocking Warning findings before starting the next round, except any finding withheld under the `Review loop grader immutability` requirement (recorded as unfixed-due-to-grader-protection and remaining surviving) and any finding accepted through the consent path of the `Accepted-risks ledger` requirement (recorded as a downgrade trace and removed from the cumulative blocking set)
- **AND** derives the next round's type per the `Graded convergence and micro-verification round` requirement

#### Scenario: Loop hits 6-round cap without passing

- **WHEN** the loop completes 6 rounds without meeting the pass condition
- **THEN** the skill writes the sixth round with `decision: aborted`
- **AND** prints a warning summarising the unresolved findings
- **AND** runs the abort triage per the `Abort triage` requirement
- **AND** ends the workflow without parking the change

#### Scenario: Park is never invoked

- **WHEN** `cash-propose` ends its workflow under any outcome
- **THEN** the workflow never invokes `spectra park`
- **AND** the change directory remains under `openspec/changes/` (not parked)

##### Example: end-of-workflow path comparison

| Skill | Inline self-review | Analyze-fix loop | Sub-agent loop (max 6) | Park at end |
| ----- | ------------------ | ---------------- | ---------------------- | ----------- |
| cash-propose          | yes | yes (max 2)  | no  | yes |
| cash-propose  | no  | no           | yes | no  |




<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---
### Requirement: cash-apply quality gate

The system SHALL provide a `cash-apply` skill that retains the complete task-execution contract and appends a sub-agent review/rating/fix loop after all tasks complete. The skill MUST run the loop at per-change granularity (once, after every task is marked complete in `tasks.md`). The skill MUST cap the loop at 6 rounds. The skill MUST NOT suggest archiving the change before the review loop has ended with `decision: passed`. The skill MUST NOT use a rater sub-agent and MUST NOT produce a `quality_score`; instead the main agent SHALL derive the round decision mechanically from the post-filter findings. The run's first round MUST be treated as passing if and only if, after the confidence filter, no surviving finding has `severity == Critical` and no surviving finding has `severity == Warning`; in a re-run whose cumulative blocking set was seeded, the first round instead uses the cumulative-blocking-set pass condition per the `Graded convergence and micro-verification round` requirement. A round after the run's first round MUST be treated as passing if and only if, after the confidence filter, the cumulative blocking set contains no `Critical` and no `Warning` finding, where blocking and the cumulative blocking set are defined by the `Graded convergence and micro-verification round` requirement; non-blocking findings route to triage per that requirement. When a round's decision is `next_round`, the main agent MUST derive the next round's type (full or micro) per the `Graded convergence and micro-verification round` requirement. Fix obligations in this requirement are subject to the grader-protection exception defined in the `Review loop grader immutability` requirement and to the consented accepted-risks path defined in the `Accepted-risks ledger` and `Review round action obligation` requirements.

#### Scenario: Review loop runs after tasks complete

- **WHEN** every checkbox in `tasks.md` reads `[x]`
- **THEN** `cash-apply` starts the sub-agent review/rating/fix loop
- **AND** does not start the loop earlier

#### Scenario: Surviving blocking Critical forces another round

- **WHEN** a round completes with at least one blocking `Critical` finding in the cumulative blocking set after the confidence filter
- **THEN** the skill writes the round file with `decision: next_round`
- **AND** fixes the blocking Critical findings before starting the next round, except any finding withheld under the `Review loop grader immutability` requirement (recorded as unfixed-due-to-grader-protection and remaining surviving) and any finding accepted through the consent path of the `Accepted-risks ledger` requirement (recorded as a downgrade trace and removed from the cumulative blocking set)
- **AND** derives the next round's type per the `Graded convergence and micro-verification round` requirement

#### Scenario: Loop hits 6-round cap

- **WHEN** the loop completes 6 rounds without meeting the pass condition
- **THEN** the skill writes the sixth round with `decision: aborted`
- **AND** prints a warning summarising the unresolved findings
- **AND** runs the abort triage per the `Abort triage` requirement
- **AND** ends the workflow

#### Scenario: Archive guidance waits for gate pass

- **WHEN** all tasks are complete but the review loop has not passed yet
- **THEN** `cash-apply` states that archive guidance is deferred until the cash quality gate passes
- **AND** does not tell the user to run `spectra archive`, `/cash-archive`, or `$cash-archive`

- **WHEN** the final review-loop round has `decision: passed`
- **THEN** the final response may suggest archiving the change




<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---
### Requirement: Round file output contract

The system SHALL write one round file per loop round to `openspec/changes/<change>/reviews/`. File names MUST follow the pattern `propose-r<N>.md` for `cash-propose` and `apply-r<N>.md` for `cash-apply`, where `<N>` is the 1-based round number; a re-run after an abort continues `<N>` from the last existing round file per the `Abort triage` requirement. Each round file MUST contain exactly four top-level `##` sections, in this fixed order: `## Reviewer Findings`, `## Rating`, `## Fix Actions`, `## Decision`, plus the round heading at the top. The `## Rating` section MUST NOT contain a `quality_score` field; it MUST record the `Critical` count and the `Warning` count of the post-filter cumulative blocking set (in the run's first round, of the surviving findings, which are all blocking; in a seeded re-run's first round, of the cumulative blocking set), the count of non-blocking triaged findings, `critical_gap` (boolean), `round_type` (exactly one of `full` or `micro`), and a rationale paragraph explaining the mechanical decision.

#### Scenario: Round file structure

- **WHEN** any round of a cash skill completes
- **THEN** a file at `openspec/changes/<change>/reviews/<skill>-r<N>.md` exists
- **AND** the file starts with a level-1 heading naming the skill and round
- **AND** the file contains exactly four `##` headings: `Reviewer Findings`, `Rating`, `Fix Actions`, `Decision`, and the leading round summary heading is `#` not `##`

#### Scenario: Rating section omits quality_score

- **WHEN** the `## Rating` section of any round file is written
- **THEN** it contains no `quality_score` field
- **AND** it records the cumulative blocking set's `Critical` count, the cumulative blocking set's `Warning` count, the non-blocking triaged count, `critical_gap`, `round_type`, and a rationale paragraph

##### Example: required round file outline

| Section                | Heading level | Content                                                                                                            |
| ---------------------- | ------------- | ------------------------------------------------------------------------------------------------------------------ |
| Round heading          | `#`           | e.g., `Cash Propose Review — Round 2`                                                                              |
| `Reviewer Findings`    | `##`          | Three subsections: Critical, Warning, Suggestion. Each finding lists `severity`, `confidence`, `layer`, `location`, `summary`, `recommendation`, `disposition` (rounds after the first, and a seeded re-run's first round), `introduced_by` (cash-apply Reviewer B findings, and any finding tagged `fix-introduced`), and reviewer source (`A`, `B`, `A+B`, or `V`) |
| `Rating`               | `##`          | cumulative blocking `Critical` count, cumulative blocking `Warning` count, non-blocking triaged count, `critical_gap` (boolean), `round_type` (`full` or `micro`), `rationale` (text) |
| `Fix Actions`          | `##`          | List of changes made this round with file paths and rationale, plus triage notes, downgrade traces, and disposition-correction records |
| `Decision`             | `##`          | One of `passed`, `next_round`, `aborted`                                                                           |

#### Scenario: Final round decision values

- **WHEN** the loop ends successfully
- **THEN** the final round file has `Decision: passed`

- **WHEN** the loop ends by hitting the 6-round cap
- **THEN** the final round file has `Decision: aborted`




<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---
### Requirement: Fresh sub-agent per round

The system SHALL spawn fresh sub-agents for every review step. The skill MUST NOT reuse a sub-agent across rounds. Each FULL round MUST spawn exactly TWO reviewer sub-agents in parallel — `Reviewer A` (artifact/implementation adherence) and `Reviewer B` (bug/quality scan). Each MICRO round MUST spawn exactly ONE fresh verification reviewer sub-agent — `Reviewer V` (delta verification), per the `Graded convergence and micro-verification round` requirement. The skill MUST NOT spawn a rater sub-agent. The skill MUST NOT perform review inline in the main agent context. A pre-spawn short-circuit abort round per the `Abort triage` requirement records `round_type: full` but spawns no reviewer sub-agents; it is the explicit exception to the two-reviewer mandate. After the round's reviewer sub-agents complete, the main agent SHALL aggregate findings (deduplicate by `location + summary`), apply the confidence filter (see `Confidence-scored findings` requirement), and derive the round decision mechanically without any further sub-agent call — from the filtered findings in the run's first round (or, in a seeded re-run's first round, from the cumulative blocking set), and from the cumulative blocking set defined by the `Graded convergence and micro-verification round` requirement in every later round.

#### Scenario: Two reviewers and no rater per round

- **WHEN** a full round begins
- **THEN** the skill makes two parallel sub-agent calls for `Reviewer A` and `Reviewer B`, dispatched in a single message
- **AND** makes no rater sub-agent call
- **AND** Reviewer A and Reviewer B do not see each other's findings
- **AND** the main agent derives `decision` from the post-filter findings and the cumulative blocking set itself

#### Scenario: Micro round spawns exactly one verification reviewer

- **WHEN** a micro round begins
- **THEN** the skill makes exactly one sub-agent call for `Reviewer V`
- **AND** makes no `Reviewer A`, `Reviewer B`, or rater sub-agent call in that round
- **AND** the main agent derives `decision` from the post-filter findings and the cumulative blocking set itself

#### Scenario: No sub-agent reuse across rounds

- **WHEN** round N+1 begins after round N
- **THEN** the skill spawns brand-new reviewer sub-agents for round N+1 (`Reviewer A` and `Reviewer B` for a full round, `Reviewer V` for a micro round)
- **AND** does not pass the prior round's sub-agent state forward




<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---
### Requirement: Confidence-scored findings and filter

The system SHALL require every reviewer finding to carry a `confidence` integer from `0` to `100`. The main agent MUST apply a confidence filter before deriving the round decision. Findings with `confidence < 50` MUST be dropped entirely and SHALL NOT appear in the round file's `## Reviewer Findings` section; downgrade traces mandated by the `Accepted-risks ledger` and `cash-apply introduced-by evidence` requirements appear in `## Fix Actions` and are the explicit exception. Findings with `confidence` in `[50, 80)` MUST be downgraded to `Suggestion` regardless of the reviewer's original severity classification. Only findings with `confidence >= 80` MAY appear as `Critical` or `Warning` in the post-filter round file. `critical_gap` MUST be `true` if and only if the post-filter cumulative blocking set contains at least one `Critical` finding (in the run's first round, at least one surviving `Critical` finding with `confidence >= 80`; a seeded re-run's first round uses the cumulative blocking set). Direct artifact-requirement violations (citing a specific `SHALL`, Implementation Contract item, or task description line) MUST score `100` so the filter does not demote them. The accepted-risks downgrade defined in the `Accepted-risks ledger` requirement and the cash-apply `introduced_by` downgrade defined in the `cash-apply introduced-by evidence` requirement take precedence over the score-100 invariant: a finding that matches an accepted-risks entry, or an cash-apply `Reviewer B` `Critical` or `Warning` finding without a verifiable `introduced_by`, MUST be scored at most `25` even when it cites a specific artifact clause.

#### Scenario: Filter drops low-confidence findings

- **WHEN** a reviewer reports a finding with `confidence == 30`
- **THEN** the finding does not appear in the round file
- **AND** it does not contribute to the round decision

#### Scenario: Filter downgrades mid-confidence Critical to Suggestion

- **WHEN** a reviewer reports a `Critical` finding with `confidence == 60`
- **THEN** the round file lists it under `Suggestion`, not `Critical`
- **AND** `critical_gap` is not set to `true` solely on account of this finding

#### Scenario: Artifact-citation findings are not demoted

- **WHEN** a reviewer cites a specific `SHALL` clause from `spec.md` or a contract item from `design.md` that the artifact set or implementation does not satisfy
- **THEN** the reviewer scores the finding `confidence == 100`
- **AND** the finding survives the filter and may be classified `Critical`

#### Scenario: Accepted-risk match overrides the score-100 invariant

- **WHEN** a finding cites a specific artifact clause AND matches an accepted-risks entry at the same location with the same defect mechanism
- **THEN** the main agent scores the finding at most `25`
- **AND** the finding does not survive as `Critical` or `Warning`




<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---
### Requirement: Sub-agent failure handling

The system SHALL retry a failed sub-agent call once within the same round. If the retry also fails, the skill MUST abort the entire cash workflow with a clear error and SHALL NOT mark the round as `passed` or continue to the next round. If both parallel reviewers fail within the same round, the skill MUST treat it as a single reviewer-role failure (one retry) rather than two separate failures.

#### Scenario: Single sub-agent failure recovers

- **WHEN** a reviewer sub-agent fails (no response or malformed output)
- **THEN** the skill retries that same reviewer role once with a fresh invocation
- **AND** the round continues if the retry succeeds

#### Scenario: Two consecutive sub-agent failures abort

- **WHEN** the same sub-agent role fails twice in a single round
- **THEN** the skill aborts the cash workflow
- **AND** writes a round file with `decision: aborted` and a note describing the failure

#### Scenario: Both parallel reviewers failing counts as one role failure

- **WHEN** both `Reviewer A` and `Reviewer B` fail in the same round
- **THEN** the skill treats it as a single reviewer-role failure
- **AND** retries the reviewer role once (both reviewers re-dispatched in parallel)
- **AND** only aborts if the retry also fails




<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---
### Requirement: cash-commit archive-first allowlist

The system SHALL make `cash-commit` collect archive-first commit files through an explicit allowlist after `spectra archive` completes. The archive-first commit set MUST include tracked source files from the pre-archive confirmed commit set, files belonging to the selected change archive, and spec sync files from `openspec/specs/` when the user explicitly selected spec sync during the archive sub-flow. The archive-first commit set MUST NOT include unrelated dirty files discovered by the post-archive `git status --porcelain` scan.

#### Scenario: unrelated deletion exists before archive-first commit

- **WHEN** `cash-commit` is committing change `demo-change` with archive-first enabled
- **AND** `git status --porcelain` already contains `D .agents/skills/cash-apply/SKILL.md` before `spectra archive demo-change` runs
- **THEN** the default commit set excludes `.agents/skills/cash-apply/SKILL.md`
- **AND** the commit plan displays that deletion outside the included archive-related files

#### Scenario: archive files are included after archive succeeds

- **WHEN** `spectra archive demo-change` moves files from `openspec/changes/demo-change/` to `openspec/changes/archive/2026-05-19-demo-change/`
- **THEN** `cash-commit` includes deletions under `openspec/changes/demo-change/`
- **AND** `cash-commit` includes additions or modifications under `openspec/changes/archive/2026-05-19-demo-change/`
- **AND** `cash-commit` excludes dirty files outside the selected change archive, tracked source files, and explicitly selected spec sync files

#### Scenario: spec sync files require explicit sync selection

- **WHEN** the user selects spec sync during the archive sub-flow for `demo-change`
- **THEN** `cash-commit` includes resulting changes under `openspec/specs/`
- **AND** the updated commit plan displays them as Spec Sync Changes

#### Scenario: archive path wording is current

- **WHEN** `cash-commit` displays the updated archive-first commit plan
- **THEN** the archived file section names `openspec/changes/archive/<date>-<change>/`
- **AND** the archive-first workflow text does not name `openspec/archived/`




<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---
### Requirement: Cash review loop writes signals after the loop ends

The canonical `cash-propose` and `cash-apply` skill files SHALL each contain a governed signal-writing step marked with the unique sentinel comment `<!-- SIGNALS-WRITE-STEP -->`. After the review loop ends (the round file `decision` is `passed` or `aborted`), the main agent writes signals for the post-filter findings the loop surfaced. This step MUST run only after the loop's mechanical decision is already recorded, MUST NOT change the `decision` of any round file, and MUST apply to both Claude and Codex variants.

The write target set SHALL be every finding that, in any single round of the current change's loop, survived the confidence filter as `Critical` or `Warning`, deduplicated by issue class so each class is processed once. The step MUST cover findings from any round, not only the final round, so that a finding caught and fixed in an early round of an otherwise passing loop still produces a signal. Findings classified `Suggestion`, and any finding with `confidence < 80`, MUST NOT produce a signal. For each deduplicated finding class, the main agent SHALL read existing signals under `openspec/signals/` and judge issue-class match by this rubric: a finding matches an existing signal when both share the same capability or domain AND point to the same underlying rule or anti-pattern; differing free-text wording alone does not make a different class, but a different root cause does. When the finding matches an existing `open` signal, the main agent MUST reuse that signal's slug and update it in place — increment `occurrences`, update `last_seen`, append an `## Occurrences` entry, and append the source round file path to `links` — without changing its `status`. When no `open` signal matches (including when only an `addressed` or `dismissed` signal matches), the main agent MUST create a new signal with `status: open` and `occurrences: 1`. Before coining the new `<slug>`, the main agent MUST list existing `openspec/signals/*.md` files and choose a `<slug>` that does not already exist (disambiguating with a suffix when the natural slug is taken). Creating a new signal MUST NOT overwrite any existing signal file, and MUST NOT change any existing signal's human-maintained `status`. When uncertain whether a finding matches an existing signal, the main agent MUST prefer creating a new signal over merging into an existing one.

#### Scenario: Coined slug does not overwrite an unrelated existing signal

- **WHEN** the main agent coins a `<slug>` for a new signal and a file with that slug already exists for a different (non-matching) issue class
- **THEN** the main agent chooses a different, not-yet-used `<slug>` instead
- **AND** the existing signal file is not overwritten

#### Scenario: Early-round fixed finding still creates a signal in a passing loop

- **WHEN** a `Warning` finding survives the confidence filter in round 1, is fixed, and the loop later passes with no surviving `Critical` or `Warning` in the final round
- **AND** no existing `open` signal matches its issue class
- **THEN** after the loop ends the main agent creates a signal under an assigned `<slug>` with `status: open` and `occurrences: 1`
- **AND** the round file `decision` is unchanged by this step

#### Scenario: Finding matching an existing open signal updates it in place

- **WHEN** a post-filter `Critical` or `Warning` finding matches an existing `open` signal's issue class per the rubric
- **THEN** the main agent reuses that signal's slug, increments its `occurrences`, updates `last_seen`, appends an `## Occurrences` entry, and appends the round file path to `links`
- **AND** the main agent does not change that signal's `status`

#### Scenario: Recurrence of an addressed issue does not overwrite resolved status

- **WHEN** a post-filter finding matches only an `addressed` or `dismissed` signal's issue class
- **THEN** the main agent creates a new signal under a different assigned `<slug>` with `status: open`
- **AND** the main agent does not change the matched resolved signal's `status`

#### Scenario: Suggestion and low-confidence findings produce no signal

- **WHEN** a finding is classified `Suggestion`, or any finding has `confidence < 80` after filtering
- **THEN** the main agent does not create or update any signal for it

#### Scenario: Signal write failure does not fail the cash workflow

- **WHEN** writing a signal under `openspec/signals/` fails
- **THEN** the main agent prints a warning
- **AND** the cash workflow does not fail solely because of the signal write failure




<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---
### Requirement: cash-propose reads open signals for prioritization

The canonical Claude and Codex `cash-propose` skill files SHALL read `open` signals under `openspec/signals/` after the existing "Scan existing specs for relevance" step. The read step MUST be marked with the unique sentinel comment `<!-- SIGNALS-READ-STEP -->`. The read MUST be informational: the skill SHALL surface relevant `open` signals as a prioritization summary, MUST NOT block the workflow, MUST NOT require user confirmation, and MUST NOT modify any signal. When `openspec/signals/` is absent or contains no `open` signal, the skill MUST continue silently. This read behavior MUST NOT be added to `cash-apply`.

#### Scenario: Relevant open signals are surfaced during cash-propose

- **WHEN** `cash-propose` runs and `openspec/signals/` contains `open` signals relevant to the requirement
- **THEN** the skill displays those signals as an informational prioritization summary after the spec scan step
- **AND** the skill does not modify any signal
- **AND** the skill does not require user confirmation to continue

#### Scenario: No open signals continues silently

- **WHEN** `cash-propose` runs and `openspec/signals/` is absent or has no `open` signal
- **THEN** the skill continues without surfacing a signals summary

#### Scenario: cash-apply does not gain the read step

- **WHEN** the canonical `.claude/skills/cash-apply/SKILL.md` and `.agents/skills/cash-apply/SKILL.md` files are inspected
- **THEN** the cash-apply skill files do not contain the `<!-- SIGNALS-READ-STEP -->` sentinel
- **AND** the cash-apply skill files do contain the `<!-- SIGNALS-WRITE-STEP -->` sentinel in their governed signal-writing section

#### Scenario: cash-propose contains both read and write steps

- **WHEN** the canonical `.claude/skills/cash-propose/SKILL.md` and `.agents/skills/cash-propose/SKILL.md` files are inspected
- **THEN** both cash-propose skill files contain the `<!-- SIGNALS-READ-STEP -->` and `<!-- SIGNALS-WRITE-STEP -->` sentinels
- **AND** neither file carries generated-output metadata or a do-not-edit marker



<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---
### Requirement: Graded convergence and micro-verification round

The system SHALL grade review-loop convergence by finding layer. Every reviewer finding MUST carry a `layer` field whose value is exactly one of `design` or `text`. A finding MUST be classified `text` only when it concerns cross-artifact consistency (counts, identifier spelling, wording, or section synchronization) AND fixing it does not change any design decision or behavioral statement; every other finding MUST be classified `design`. When a reviewer cannot decide between the two values, it MUST classify the finding as `design`. While applying the confidence filter, the main agent MUST re-check every finding classified `text` and MUST reclassify it to `design` when the fix could touch behavior or a design statement; the main agent MUST NOT reclassify a `design` finding to `text`. When full-round reviewers independently raise the same finding (deduplicated by `location + summary`) with different `layer` values, the merged finding MUST take `layer == design`. The `layer` field MUST NOT participate in round-type derivation.

The loop SHALL run two round types: full rounds and micro rounds (delta verification rounds). The first round of a loop run MUST be a full round. When a round's decision is `next_round`, the main agent MUST derive the next round's type mechanically from its position within the current loop run alone: the next round is a full round if and only if it is the fourth round of the current run; otherwise the next round is a micro round. Consecutive micro rounds are valid. Fix actions that modify behavior MUST NOT escalate the next round's type; the fourth-round checkpoint is the only full re-scan after the run's first round. Micro rounds MUST count toward the 6-round cap and MUST produce a round file like any other round.

Except in an unseeded run's first round, every reviewer of a round (Reviewer V in micro rounds; Reviewer A and Reviewer B in the fourth-round checkpoint or a seeded re-run's first round) MUST tag each `Critical` or `Warning` finding with a `disposition` field whose value is exactly one of: `unresolved-prior` — the finding matches a blocking finding from a prior round of this loop (or, in a re-run, a bucket-1 finding carried from the prior run per the `Abort triage` requirement), whether or not a fix was recorded for it: a re-report is itself evidence that any recorded fix did not resolve it; `fix-introduced` — the finding is attributed, by an explicit fix-action reference carried in the finding, to one or more modifications recorded in `## Fix Actions` sections of this loop (or, in a seeded re-run, of the prior run); every reviewer of these rounds — including Reviewer V and cash-propose reviewers — MUST attach that reference when tagging `fix-introduced`; or `new` — the finding matches no prior blocking finding; a finding that matches only a prior non-blocking triage note is also tagged `new` and stays non-blocking without producing a duplicate triage note or signal; its recorded action under the `Review round action obligation` requirement is a one-line cross-reference note naming the original round's triage note, which is neither a duplicate triage note nor a new signal. Disposition matching operates on the same artifact or file plus the same defect mechanism; recorded line ranges are advisory and a shifted range does not break a match. To make dispositions evaluable, the main agent MUST provide, in the reviewer context of every round after the run's first round, every prior round file of this loop (in a seeded re-run, including the prior run's round files or their extracts) AND the current cumulative-blocking-set member list; when the accumulated round files exceed practical context size, the main agent MUST instead provide per-round extracts containing each round's surviving findings and complete `## Fix Actions` content, and MUST record a one-line note in the current round's `## Fix Actions` naming the rounds provided as extracts. The main agent MUST verify each disposition tag against the prior round files and MUST correct a tag that does not hold; for every finding tagged `new`, the main agent MUST additionally check whether its location was modified by this loop's — and, in a seeded re-run, the prior run's — recorded fix actions and, when the defect stems from those modifications, correct the tag to `fix-introduced` supplying the fix-action reference in the correction record; every correction MUST be recorded in that round file's `## Fix Actions` naming the finding, the reviewer's original tag, the corrected tag, and the evidence, and every correction that changes a blocking disposition to a non-blocking one MUST be listed in the completion output. When findings deduplicated by `location + summary` carry divergent `disposition` values, the merged finding MUST take the blocking disposition (`unresolved-prior` or `fix-introduced` wins over `new`). Round files of completed rounds are immutable during an active loop: fix records and triage notes MUST be written only in the round in which they occur, and the main agent MUST NOT retroactively edit a prior round file.

A surviving `Critical` or `Warning` finding is blocking if and only if its verified disposition is `unresolved-prior` or `fix-introduced`. A finding whose most recent prior status in this loop is a non-blocking triage note remains non-blocking and MUST NOT re-enter the blocking set, with one exception: when later evidence attributes the finding to recorded fix actions, it re-enters as `fix-introduced` through a traced disposition correction. Every other surviving finding with disposition `new` is non-blocking: the main agent MUST record it as a triage note in that round file's `## Fix Actions` section, MUST include it in the signals write step target set, and MUST list it in the completion output; for a non-blocking `Critical` finding, the completion output MUST additionally recommend creating a follow-up change proposal. Non-blocking findings MUST NOT cause a `next_round` decision.

The main agent MUST additionally maintain the run's cumulative blocking set: every blocking finding of the run enters the set when found, counts toward every subsequent round decision even when no reviewer re-reports it, and leaves the set only through one of exactly two removal events: (a) resolved — a resolving fix was recorded for it AND a subsequent round's reviewer verified the resolution (the finding is not re-reported and the verification confirms the fix at the fixed location); Reviewer V, the fourth-round checkpoint reviewers, and a seeded re-run's first-round reviewers MUST each return an explicit resolved/unresolved verdict per member, and when verdicts diverge any `unresolved` verdict keeps the member in the set; every exit-(a) removal MUST be recorded in the removing round's `## Fix Actions` naming the member, the resolving fix reference, and the verifying reviewer; or (b) accepted — the finding matches, at the same artifact or file with the same defect mechanism, an accepted-risks entry consented per the `Accepted-risks ledger` requirement; the main agent MUST re-evaluate the set against the accepted-risks ledger every round and MUST record each such removal as a downgrade trace in that round file's `## Fix Actions`. Members withheld under grader protection have no autonomous in-loop removal path — a fix is prohibited, and only the consented accepted-risks exit (b) applies to them. When every member of the cumulative blocking set is withheld under grader protection and no consented exit is obtainable, the main agent MUST NOT spawn further reviewer rounds and MUST end the loop with `decision: aborted` and the abort triage; when this condition first holds during a round's fix phase, after the mechanical decision was derived, the current round's not-yet-finalized file records `decision: aborted` with the abort triage, overriding the derived `next_round`. Except in an unseeded run's first round, a round passes if and only if, after the confidence filter, the cumulative blocking set contains no `Critical` and no `Warning` finding. The run's first round retains the undivided pass condition: every surviving `Critical` or `Warning` finding in the first round is blocking. In a re-run whose cumulative blocking set was seeded per the `Abort triage` requirement, the run's first round MUST instead use the cumulative-blocking-set pass condition, and its reviewers MUST tag dispositions against the prior run's round files (the bucket-1 triage in the final round file enumerates the seeded members).

A micro round MUST spawn exactly ONE fresh verification reviewer sub-agent (`Reviewer V — Verification`) instead of the two full-round reviewers. Reviewer V MUST receive as context: the artifact paths (and, for cash-apply, the changed-file list), every prior round file of this loop (or the extract fallback defined above), the current cumulative-blocking-set member list, the accepted-risks ledger when it exists, and the same relevant `open` signals context that full-round reviewers receive. Reviewer V's scope MUST be limited to: whether each member of the cumulative blocking set is resolved (whether or not a fix was recorded for it) — returning an explicit resolved/unresolved verdict per member, whether fix propagation is complete (every occurrence of each concept touched by a fix is synchronized across all artifacts and, for cash-apply, the changed files), and whether the fixes introduced new defects. In cash-apply micro rounds, Reviewer V MUST additionally perform the per-round `implementation-notes.md` reading obligation defined for Reviewer A in the Implementation Notes Protocol, including its file-absent and `open-question` severity rules. Reviewer V findings MUST carry the same fields as full-round findings (including `layer`, `confidence`, and `disposition`) and MUST pass through the same confidence filter. If the cumulative blocking set is empty after the filter in a micro round, the decision is `passed`; if any blocking `Critical` or `Warning` remains, the decision is `next_round` and the next round's type is derived from its position within the run per this requirement, subject to the existing 6-round cap (a sixth round that does not meet the pass condition records `decision: aborted`).

#### Scenario: Round after the first round defaults to a micro round

- **WHEN** the run's first round completes with `decision: next_round`
- **THEN** the second round is derived as a micro round
- **AND** the second round spawns exactly one `Reviewer V` sub-agent

#### Scenario: Fourth round checkpoint is a full round

- **WHEN** the run's third round completes with `decision: next_round`
- **THEN** the fourth round is derived as a full round
- **AND** the fourth round spawns `Reviewer A` and `Reviewer B` in parallel
- **AND** both reviewers receive every prior round file of this loop (or the defined extract fallback) and the current cumulative-blocking-set member list in their context
- **AND** both reviewers additionally return the same per-member resolved/unresolved verdicts over the cumulative blocking set as Reviewer V, so exit-(a) removals stay available at the checkpoint
- **AND** when the two reviewers' verdicts for a member diverge, any `unresolved` verdict keeps the member in the set

#### Scenario: Rounds after the checkpoint return to micro

- **WHEN** the run's fourth round completes with `decision: next_round`
- **THEN** the fifth round is derived as a micro round
- **AND** consecutive micro rounds (fifth and sixth) are valid

#### Scenario: Behavior-modifying fixes do not escalate the round type

- **WHEN** a fix action after a round's decision modifies implementation behavior or a design statement
- **THEN** the next round's type remains derived from its position within the run alone
- **AND** no re-derivation to a full round occurs

#### Scenario: New finding routes to triage instead of blocking

- **WHEN** a round after the run's first round surfaces a surviving `Critical` finding whose verified disposition is `new`
- **THEN** the main agent records it as a triage note in that round file's `## Fix Actions` section
- **AND** it enters the signals write step target set and the completion output with a follow-up change proposal recommendation
- **AND** it does not participate in the round decision

#### Scenario: Fix-introduced regression blocks the pass

- **WHEN** a round after the run's first round surfaces a surviving `Critical` finding whose `introduced_by` references modifications recorded in prior `## Fix Actions` sections of this loop
- **THEN** the finding's disposition is `fix-introduced` and it is blocking
- **AND** the round file records `decision: next_round`

#### Scenario: Ineffective fix keeps the finding blocking

- **WHEN** a resolving fix was recorded for a blocking finding and a later round re-reports the same finding at the same location with the same defect mechanism
- **THEN** the finding's disposition is `unresolved-prior` and it remains blocking
- **AND** it is not routed to the `new` bucket on account of the recorded fix

#### Scenario: Cumulative set member is removed only by verified resolution or acceptance

- **WHEN** a resolving fix is recorded for a cumulative-blocking-set member and the subsequent round's reviewer verifies the resolution without re-reporting it
- **THEN** the member is removed from the cumulative blocking set

- **WHEN** a cumulative-blocking-set member matches a consented accepted-risks entry at the same file with the same defect mechanism
- **THEN** the member is removed from the cumulative blocking set
- **AND** the removal is recorded as a downgrade trace in that round file's `## Fix Actions`

#### Scenario: Triaged non-blocking finding does not re-enter the blocking set

- **WHEN** a later round re-reports a finding whose most recent prior status in this loop is a non-blocking triage note, at the same location with the same defect mechanism, without new evidence attributing it to recorded fix actions
- **THEN** the finding remains non-blocking
- **AND** it does not cause a `next_round` decision

#### Scenario: Seeded member blocks a re-run's first round

- **WHEN** a re-run's first round completes, a seeded bucket-1 member is not re-reported by the round's reviewers, and its per-member verdict is `unresolved` (or no resolving fix was recorded for it in the prior run)
- **THEN** the cumulative blocking set still contains that member
- **AND** the round's decision is not `passed`

#### Scenario: Unresolved blocking finding cannot be silently passed

- **WHEN** a prior round's blocking finding has only a grader-protection note and no resolving fix, and the current round's reviewer does not re-report it
- **THEN** the cumulative blocking set still contains that finding
- **AND** the current round's decision is not `passed`

#### Scenario: Fully grader-protected blocking set short-circuits to abort

- **WHEN** every member of the cumulative blocking set is withheld under grader protection and no consented accepted-risks exit is obtainable
- **THEN** the main agent does not spawn further reviewer rounds
- **AND** the loop ends immediately with `decision: aborted` and the abort triage

#### Scenario: Divergent dispositions merge conservatively

- **WHEN** findings deduplicated by `location + summary` carry divergent `disposition` values
- **THEN** the merged finding takes the blocking disposition, with `unresolved-prior` or `fix-introduced` winning over `new`

#### Scenario: Disposition correction leaves a trace

- **WHEN** the main agent corrects a reviewer's `disposition` tag from `fix-introduced` to `new`
- **THEN** that round file's `## Fix Actions` records the finding, the original tag, the corrected tag, and the evidence
- **AND** the completion output lists the correction because it changed a blocking disposition to a non-blocking one

#### Scenario: Completed round files are immutable during the loop

- **WHEN** a fix action could shrink the cumulative blocking set by inserting a fix record or triage note into a prior round's file
- **THEN** the main agent does not edit the prior round file
- **AND** fix records and triage notes are written only in the round in which they occur

#### Scenario: Micro round with an empty cumulative blocking set passes the loop

- **WHEN** a micro round completes and the cumulative blocking set contains no `Critical` and no `Warning` finding after the confidence filter
- **THEN** the round file records `decision: passed` and `round_type: micro`
- **AND** the loop stops

#### Scenario: cash-apply micro round reads implementation notes

- **WHEN** an cash-apply micro round begins
- **THEN** Reviewer V reads `openspec/changes/<change>/implementation-notes.md` per the Implementation Notes Protocol
- **AND** a missing file yields a `Critical` finding
- **AND** an unresolved `open-question` entry yields a `Warning` finding

#### Scenario: Divergent layer values merge conservatively

- **WHEN** both full-round reviewers independently raise the same finding (deduplicated by `location + summary`) and their `layer` classifications differ
- **THEN** the merged finding takes `layer: design`

#### Scenario: Uncertain layer defaults to design

- **WHEN** a reviewer cannot decide whether fixing a finding changes a design decision or behavioral statement
- **THEN** the reviewer classifies the finding with `layer: design`

#### Scenario: Main agent reclassification is upgrade-only

- **WHEN** the main agent applies the confidence filter and judges that fixing a finding classified `text` could touch behavior or a design statement
- **THEN** the main agent reclassifies that finding to `design`
- **AND** the main agent never reclassifies a `design` finding to `text`

##### Example: next-round-type derivation by position within the run

| Current round position | Next round position | Next round type |
| ---------------------- | ------------------- | --------------- |
| 1st (full)  | 2nd | micro |
| 2nd (micro) | 3rd | micro |
| 3rd (micro) | 4th | full  |
| 4th (full)  | 5th | micro |
| 5th (micro) | 6th | micro |




<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---
### Requirement: Review loop grader immutability

The canonical Claude and Codex `cash-propose` and `cash-apply` skill files SHALL each contain a grader-immutability rule marked by the unique sentinel comment `<!-- GRADER-IMMUTABILITY -->`. During a cash review loop, the main agent MUST NOT modify — whether as a fix action or as a mechanical self-check fix — any file in the protected grader path set: `.claude/skills/cash-propose/SKILL.md`, `.claude/skills/cash-apply/SKILL.md`, `.agents/skills/cash-propose/SKILL.md`, `.agents/skills/cash-apply/SKILL.md`, `.spectra.yaml`, `scripts/cash-skills/tests/skill-checks.fish`, and master spec files under `openspec/specs/` — unless that file is explicitly named by the current change's structured scope declarations. Structured scope declarations are limited to project-root-relative paths in the proposal `## Impact` affected-code entries and project-root-relative paths in `tasks.md` that are explicitly identified as delivery targets. A path that appears only in a verification command, a rule description, an example, a review finding, reviewer context, or other incidental prose MUST NOT count as a structured scope declaration. Naming a directory path in a structured scope declaration names all files under it. A loop already in progress continues under the canonical instruction version it started with; a scoped edit to a cash skill takes effect from the next loop run. In addition, the main agent MUST NOT add, modify, or remove the `check` frontmatter field of any signal under `openspec/signals/`, regardless of declared scope — the `check` field is grader input for the pre-round mechanical self-check. When a surviving finding's resolution would require modifying a protected file outside that structured scope, or touching a signal's `check` field, the fix action MUST NOT perform the modification, MUST record an unfixed-due-to-grader-protection note naming the file and the finding in `## Fix Actions`, and the finding remains surviving for the round decision. The cash workflow's completion output MUST list every unfixed-due-to-grader-protection note recorded in any round of the loop, regardless of the final decision: for `cash-propose` with `decision: passed`, the notes MUST be listed in the final summary; for `cash-apply` with `decision: passed`, the notes MUST be listed in the gate-complete final response; for any `decision: aborted`, the notes MUST be listed in the unresolved-findings warning. A protected file modified under the structured-scope exception is treated like any other fix-action modification and does not change the next round's type, which is derived from its position within the run alone per the `Graded convergence and micro-verification round` requirement. This rule MUST apply to both cash workflows in both variants.

#### Scenario: Out-of-scope grader modification is refused

- **WHEN** a review-loop finding's recommendation requires editing `.agents/skills/cash-propose/SKILL.md` and the current change's structured scope declarations do not name that file
- **THEN** the fix action does not modify `.agents/skills/cash-propose/SKILL.md`
- **AND** the round file's `## Fix Actions` records an unfixed-due-to-grader-protection note naming the file and the finding
- **AND** the finding still counts toward the round decision

#### Scenario: Incidental protected path text does not unlock a grader file

- **WHEN** `tasks.md` mentions `openspec/specs/` only while describing the grader-protection rule or a verification step
- **THEN** that mention does not count as a structured scope declaration
- **AND** the main agent MUST NOT modify files under `openspec/specs/` through the grader-immutability exception

#### Scenario: Signal check field is never modified by a fix action

- **WHEN** a pre-round self-check `check` command fails and a fix action could make it pass by weakening or removing that signal's `check` field
- **THEN** the fix action does not add, modify, or remove any signal's `check` field
- **AND** the underlying defect is fixed in the change's own artifacts or files instead

#### Scenario: Declared-scope grader file stays modifiable

- **WHEN** the current change's structured scope declarations explicitly name `.agents/skills/cash-propose/SKILL.md` and a fix action modifies that file
- **THEN** the canonical skill modification is permitted
- **AND** the modification does not change the next round's type, which is derived from its position within the run alone

#### Scenario: Completion output anchors grader-protection records

- **WHEN** any round of a loop recorded an unfixed-due-to-grader-protection note and the loop later ends with `decision: passed` for `cash-propose`
- **THEN** the final summary lists every such note from every round of the loop

- **WHEN** any round of a loop recorded an unfixed-due-to-grader-protection note and the loop later ends with `decision: passed` for `cash-apply`
- **THEN** the gate-complete final response lists every such note from every round of the loop

- **WHEN** any round of a loop recorded an unfixed-due-to-grader-protection note and the loop ends with `decision: aborted`
- **THEN** the unresolved-findings warning lists every such note from every round of the loop

#### Scenario: Canonical skills carry the grader-immutability sentinel

- **WHEN** the four canonical cash proposal and apply skill files are inspected
- **THEN** each file contains the `<!-- GRADER-IMMUTABILITY -->` sentinel and the protected grader path set
- **AND** `scripts/cash-skills/tests/skill-checks.fish` asserts the sentinel's presence




<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---
### Requirement: Review loop ledger output

The canonical Claude and Codex `cash-propose` and `cash-apply` skill files SHALL each contain a ledger step marked by the unique sentinel comment `<!-- LOOP-LEDGER-STEP -->`. For each round, the main agent MUST append exactly one row to `openspec/changes/<change>/reviews/loop-ledger.tsv` at a deterministic point: for a `next_round` round, immediately before spawning the next round's reviewers — after every action that can write to the round file's `## Fix Actions` has completed, including fix actions, post-fix self-check records, and validation re-run fix records; for the final round (`passed` or `aborted`), at loop end before the signals write step. When the file does not exist, the main agent MUST create it with a single header row before appending; the header row MUST contain exactly the seven column names in order, tab-separated: `skill`, `round`, `round_type`, `criticals`, `warnings`, `decision`, `fixed_files`. Each row MUST contain, tab-separated and in this order: `skill` (`propose` or `apply`), `round` (1-based integer matching the round file number), `round_type` (`full` or `micro`), `criticals` (the post-filter cumulative blocking set's Critical count — in the run's first round every surviving Critical is blocking, and a seeded re-run's first round uses the cumulative blocking set; `0` when the cumulative blocking set is empty after filtering, including rounds aborted by sub-agent failure), `warnings` (the post-filter cumulative blocking set's Warning count, `0` likewise), `decision` (`passed`, `next_round`, or `aborted`), and `fixed_files` (the number of distinct files recorded as modified in that round's `## Fix Actions`, `0` when none are recorded; note lines such as fallback, triage, downgrade-trace, disposition-correction, or grader-protection notes do not count). The ledger is an append-only event log: rows from the propose loop, the apply loop, and any re-run loop after an abort accumulate chronologically in the same file, and `(skill, round)` is NOT a unique key — duplicate round numbers from historical re-runs are valid. Round files remain the authoritative record; on any inconsistency between a round file and the ledger, the round file governs. A ledger write failure MUST produce a printed warning and MUST NOT fail the cash workflow. This behavior MUST apply to both cash workflows in both variants.

#### Scenario: One ledger row per completed round of a loop run

- **WHEN** a single cash review loop run completes N rounds for a change
- **THEN** that run appends exactly N data rows to `openspec/changes/<change>/reviews/loop-ledger.tsv`
- **AND** the header row exists exactly once at the top of the file

##### Example: three-round propose loop followed by a two-round apply loop

| skill | round | round_type | criticals | warnings | decision | fixed_files |
| ----- | ----- | ---------- | --------- | -------- | -------- | ----------- |
| propose | 1 | full | 1 | 2 | next_round | 3 |
| propose | 2 | micro | 0 | 1 | next_round | 1 |
| propose | 3 | micro | 0 | 0 | passed | 0 |
| apply | 1 | full | 0 | 1 | next_round | 2 |
| apply | 2 | micro | 0 | 0 | passed | 0 |

#### Scenario: Ledger is created with a header row

- **WHEN** round 1 of a loop completes and no `loop-ledger.tsv` exists for the change
- **THEN** the main agent creates the file with one header row and one data row

#### Scenario: Carryover findings keep the ledger self-explaining

- **WHEN** a round's reviewers re-report nothing but the cumulative blocking set still contains one `Critical` finding
- **THEN** that round's ledger row records `criticals` = 1 with `decision` = `next_round`

#### Scenario: Re-run after an aborted loop accumulates rows

- **WHEN** a loop ended with `decision: aborted` and a new loop run for the same skill later runs on the same change
- **THEN** the new run's rows are appended after the existing rows
- **AND** the earlier run's rows are not modified or deleted

#### Scenario: Failure-aborted round records zero counts

- **WHEN** a round is aborted because the same reviewer role failed twice, no post-filter findings exist, and the cumulative blocking set is empty
- **THEN** that round's ledger row records `criticals` = 0 and `warnings` = 0 with `decision` = `aborted`

#### Scenario: Ledger write failure does not fail the workflow

- **WHEN** appending to `loop-ledger.tsv` fails
- **THEN** the main agent prints a warning
- **AND** the cash workflow continues unchanged

#### Scenario: Canonical skills carry the ledger sentinel

- **WHEN** the four canonical cash proposal and apply skill files are inspected
- **THEN** each file contains the `<!-- LOOP-LEDGER-STEP -->` sentinel
- **AND** `scripts/cash-skills/tests/skill-checks.fish` asserts the sentinel's presence




<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---
### Requirement: Deterministic signal-derived self-checks

The canonical Claude and Codex `cash-propose` and `cash-apply` skill files SHALL each define the "Signal-derived checks" item of the pre-round mechanical self-check to consume the optional signal `check` frontmatter field. For EVERY `open` signal whose frontmatter contains a `check` field — without applying best-effort relevance selection to these signals — the main agent MUST execute that command from the project root by passing the `check` value as the single command-string argument to `sh -c` (not by interpolating it into a quoted shell string). Exit code `0` means the check passed. Exit code `1` means the anti-pattern is present. The main agent MUST classify the failing check before deciding whether to fix it: it MUST inspect any project-root-relative paths printed by the check command and compare them with the current change's artifacts and, for cash-apply, modified source files. If at least one printed path is inside that artifact/source file set, the detected instance is in scope. If the command prints no usable project-root-relative path, or the output cannot be reliably mapped to a project-root-relative path, the main agent MUST fail closed and treat the detected instance as in scope unless the already-read repository state proves that the instance is pre-existing or that the required fix location is outside the change's structured scope. When the detected instance is in scope and the fix location is not blocked by an uncovered protected grader path, it is a self-check failure that MUST be fixed before spawning that round's reviewers, per the existing self-check rules. When the detected instance is pre-existing, or its fix lies outside the change's structured scope, or its fix lies inside a protected grader path that is not covered by the structured-scope exception, the main agent MUST NOT fix it, MUST record a one-line out-of-scope-check-failure note in that round's `## Fix Actions` when the round file is written, MUST include the failing check result in that round's reviewers' context, and MUST proceed to spawn the reviewers — a pre-existing anti-pattern never deadlocks the loop. Any other exit code (for example `2`, `126`, `127`) is an execution error: the main agent MUST fall back to the existing best-effort judgment for that signal and record a one-line fallback note in that round's `## Fix Actions` when the round file is written. Note lines (out-of-scope or fallback) coexist with the `None; pass condition met.` text on a passing round and do not count toward the ledger `fixed_files` value. For `open` signals without a `check` field, the existing best-effort behavior MUST remain unchanged. Executing a `check` command MUST NOT modify any file.

#### Scenario: Signal with check field is executed deterministically

- **WHEN** the pre-round mechanical self-check runs and an `open` signal's frontmatter contains `check`
- **THEN** the main agent executes the `check` command from the project root by passing its value as the single argument to `sh -c`, regardless of relevance judgment
- **AND** exit code `1` with the detected instance inside the change's own artifacts or modified files is treated as a self-check failure to fix before spawning the reviewers

#### Scenario: Check output path inside the change is in scope

- **WHEN** an `open` signal's `check` command exits `1`
- **AND** the command output contains a project-root-relative path under `openspec/changes/<change>/`
- **THEN** the main agent treats the failure as in scope for a cash-propose loop
- **AND** fixes the failure before spawning reviewers unless the fix location is blocked by an uncovered protected grader path

#### Scenario: Unlocatable check failure fails closed

- **WHEN** an `open` signal's `check` command exits `1`
- **AND** the command output contains no usable project-root-relative path
- **AND** the already-read repository state does not prove that the instance is pre-existing or that the required fix location is outside the change's structured scope
- **THEN** the main agent treats the failure as in scope
- **AND** does not record it as an out-of-scope-check-failure note

#### Scenario: Protected path branch applies only outside structured scope

- **WHEN** an `open` signal's `check` command exits `1`
- **AND** fixing the detected instance requires editing `.agents/skills/cash-propose/SKILL.md`
- **AND** the current change's structured scope declarations explicitly name `.agents/skills/cash-propose/SKILL.md`
- **THEN** the protected grader path does not trigger the out-of-scope-check-failure branch
- **AND** the main agent fixes the failure before spawning reviewers

#### Scenario: Out-of-scope check failure does not deadlock the loop

- **WHEN** an `open` signal's `check` command exits `1` and the detected instance is pre-existing or its fix lies outside the change's structured scope or inside a protected grader path not covered by the structured-scope exception
- **THEN** the main agent does not fix it, records a one-line out-of-scope-check-failure note in that round's `## Fix Actions` when the round file is written
- **AND** includes the failing check result in that round's reviewers' context and proceeds to spawn the reviewers

#### Scenario: Execution-error exit codes fall back to best-effort

- **WHEN** an `open` signal's `check` command exits with a code other than `0` or `1`
- **THEN** the main agent applies the existing best-effort judgment for that signal
- **AND** records a one-line fallback note in that round's `## Fix Actions` when the round file is written
- **AND** the note does not count toward the ledger `fixed_files` value

#### Scenario: Signals without check keep best-effort behavior

- **WHEN** an `open` signal has no `check` field
- **THEN** the Signal-derived checks behavior for that signal is unchanged from the existing best-effort rule



<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---
### Requirement: Accepted-risks ledger

The system SHALL support an accepted-risks ledger at `openspec/changes/<change>/reviews/accepted-risks.md`. An entry MUST be created, modified, or deleted only with explicit user consent obtained in the current session; the loop MUST NOT write, edit, or remove an entry autonomously, the main agent MUST NOT modify or delete an existing entry as a fix action during an active loop, and when user interaction is unavailable the candidate finding remains surviving and no entry is written. Each entry MUST record `severity`, `location`, a defect-mechanism description, an acceptance rationale, and the recording date. When the file exists, the main agent MUST include its content in every round's reviewer context. During the confidence filter, the main agent MUST score at most `25` any finding that matches an entry at the same `location` AND the same defect mechanism; recorded line ranges are advisory, and a match holds when the same artifact or file and the same defect mechanism match even though the recorded range has shifted. A finding that shares only a subsystem or issue class with an entry MUST NOT be downgraded on that basis. Every downgrade applied under this requirement MUST be recorded in that round file's `## Fix Actions` section naming the finding and the matched entry, and the completion output MUST list every accepted-risks downgrade applied in any round of the loop. If writing the file fails, the skill MUST print a warning and MUST NOT fail the cash workflow.

#### Scenario: Matching finding is downgraded with a recorded trace

- **WHEN** a reviewer reports a finding whose `location` and defect mechanism match an accepted-risks entry
- **THEN** the main agent scores the finding at most `25` during the confidence filter
- **AND** the finding does not survive as `Critical` or `Warning`
- **AND** that round file's `## Fix Actions` records the downgrade naming the finding and the matched entry
- **AND** the completion output lists the downgrade

#### Scenario: Same subsystem with a different mechanism is not downgraded

- **WHEN** a reviewer reports a finding in the same subsystem as an accepted-risks entry but with a different defect mechanism
- **THEN** the finding passes through the confidence filter with its reviewer-assigned confidence
- **AND** no accepted-risks downgrade applies

#### Scenario: Shifted line range still matches

- **WHEN** a finding matches an accepted-risks entry's file and defect mechanism but the entry's recorded line range no longer corresponds after later edits
- **THEN** the match holds and the downgrade applies

#### Scenario: No consent means no entry

- **WHEN** the main agent identifies a candidate accepted risk and cannot obtain explicit user consent in the current session
- **THEN** no entry is written to `accepted-risks.md`
- **AND** the finding remains surviving for the round decision

#### Scenario: Entries are not editable as fix actions

- **WHEN** a fix action could resolve a surviving finding by broadening or deleting an existing accepted-risks entry
- **THEN** the main agent does not modify or delete the entry
- **AND** any entry change happens only through explicit user consent in the current session

#### Scenario: Ledger enters reviewer context

- **WHEN** a round's reviewers are spawned and `openspec/changes/<change>/reviews/accepted-risks.md` exists
- **THEN** every reviewer of that round receives the file content in its context




<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---
### Requirement: Fix-loop design circuit breaker

In cash-apply review loops, when resolving a surviving finding requires introducing a synchronization primitive (such as a mutex, lock, or semaphore), an identity or generation type (such as a token, epoch, or generation id), or a state machine that `design.md` does not define, the main agent MUST NOT implement that mechanism as a fix action. The main agent MUST record a needs-design note in that round's `## Fix Actions` section naming the finding, the required mechanism, and a one-line reason; MUST write that round file with `decision: aborted`; MUST run the abort triage per the `Abort triage` requirement; and the completion output MUST direct the user to update `design.md` via the variant-appropriate `cash-ingest` invocation before re-entering an apply workflow. In cash-propose rounds, defining the needed mechanism in the change's own `design.md` is a normal fix action and this circuit breaker MUST NOT trigger. The `decision` value set MUST remain exactly `passed`, `next_round`, and `aborted`; no additional decision value is introduced for this rule.

#### Scenario: Fix requiring a new state machine trips the breaker

- **WHEN** resolving a surviving `Critical` finding in an cash-apply loop requires introducing a lease state machine that `design.md` does not define
- **THEN** the main agent does not implement the state machine as a fix action
- **AND** records a needs-design note in `## Fix Actions`
- **AND** writes the round file with `decision: aborted`
- **AND** the completion output directs the user to the variant-appropriate `cash-ingest` invocation

#### Scenario: Mechanism already defined in design is a normal fix

- **WHEN** resolving a surviving finding in an cash-apply loop uses only mechanisms that `design.md` already defines
- **THEN** the fix proceeds as a normal fix action
- **AND** the circuit breaker does not trigger

#### Scenario: cash-propose design edits do not trip the breaker

- **WHEN** a cash-propose finding is resolved by defining a needed synchronization mechanism in the change's own `design.md`
- **THEN** the edit proceeds as a normal fix action
- **AND** the circuit breaker does not trigger




<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---
### Requirement: Abort triage

When a review loop ends with `decision: aborted` due to the round cap, the fix-loop design circuit breaker, or the fully-grader-protected short-circuit, the main agent MUST triage every unresolved surviving finding into exactly one of three buckets and record the triage both in the final aborted round file's `## Fix Actions` section and in the completion output: (1) findings that remain the change's obligation — every cumulative-blocking-set member not accepted through consent, whatever its disposition or lack of one (fix-introduced regressions and unresolved-prior findings are the typical cases); (2) newly discovered or design-level issue that was never blocking in this loop — the finding is written to signals, and for a `Critical` finding the output MUST recommend creating a follow-up change proposal; (3) accepted trade-off — the finding is written to the accepted-risks ledger under the consent rules of the `Accepted-risks ledger` requirement; when consent cannot be obtained in the current session, the finding MUST be triaged to bucket 1 instead — it remains the change's obligation and seeds a re-run — with a note that accepted-risks recording was deferred pending user consent. Bucket 2 MUST NOT receive any finding that was blocking in this loop. The completion output MUST NOT recommend re-running the same loop without this triage. A loop re-run after an abort MUST NOT overwrite prior round files: its round files continue numbering from the last existing round file for that skill, while the 6-round cap and the round-type derivation operate on positions within the new run (its first round is a full round). The re-run's first-round reviewer context MUST include the prior run's round files (or their extracts per the extract fallback), and the re-run's cumulative blocking set MUST be seeded with the prior run's bucket-1 findings so they re-enter review as blocking; the re-run's first-round reviewers MUST return the same per-member resolved/unresolved verdicts as Reviewer V, so a seed whose resolving fix was recorded in the prior run can leave the set at the re-run's first round. When a seeded re-run's entire seeded set is withheld under grader protection and no consented exit is obtainable, the short-circuit is evaluated before spawning the re-run's first-round reviewers: the run writes exactly one round file (continued numbering, `round_type: full`, no reviewer findings, `decision: aborted`) carrying the triage, appends one ledger row with the same `round_type`, and its completion output MUST direct the user to either obtain consent for the protected members or expand the change's structured scope declarations via the variant-appropriate `cash-ingest` invocation before any further re-run. Aborts caused by consecutive sub-agent failures retain the existing failure-handling behavior and are exempt from this triage; proposal-level scope-error aborts are likewise exempt, because the change is expected to be re-proposed from scratch rather than re-run.

#### Scenario: Round-cap abort produces a three-bucket triage

- **WHEN** the loop writes its sixth round with `decision: aborted` and unresolved surviving findings remain
- **THEN** the final round file's `## Fix Actions` and the completion output assign every unresolved finding to exactly one of the three triage buckets
- **AND** the output does not recommend re-running the same loop without triage

#### Scenario: Unavailable consent keeps the finding with the change

- **WHEN** an aborted loop triages a blocking trade-off finding and explicit user consent cannot be obtained in the current session
- **THEN** the finding is triaged to bucket 1, remains the change's obligation, and seeds a re-run's cumulative blocking set
- **AND** the triage records that accepted-risks recording was deferred pending user consent

#### Scenario: Fully protected seeded re-run aborts before spawning reviewers

- **WHEN** a seeded re-run starts and its entire seeded cumulative blocking set is withheld under grader protection with no consented exit obtainable
- **THEN** the run writes exactly one round file with continued numbering, `round_type: full`, and `decision: aborted` carrying the triage, and appends one ledger row, without spawning reviewers
- **AND** the completion output directs the user to obtain consent for the protected members or expand the structured scope declarations via the variant-appropriate `cash-ingest` invocation before any further re-run

#### Scenario: Re-run continues round numbering and consumes the triage

- **WHEN** a loop for the same skill re-runs after an abort whose last round file is `apply-r6.md`
- **THEN** the re-run's first round file is `apply-r7.md` and no prior round file is overwritten
- **AND** the re-run's first round is a full round whose reviewer context includes `apply-r6.md`
- **AND** the re-run's cumulative blocking set is seeded with the prior run's bucket-1 findings
- **AND** the re-run's 6-round cap and round-type derivation count from its own first round




<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---
### Requirement: cash-apply introduced-by evidence

In cash-apply rounds, every `Critical` or `Warning` finding from `Reviewer B` MUST include an `introduced_by` field citing either a concrete location in this change's diff (file path plus the introduced behavior), one or more fix-action records from this loop, or — for a regression emerging from the interaction of several fixes — the set of fix actions of a named round. During the confidence filter, the main agent MUST score at most `25` any cash-apply `Reviewer B` `Critical` or `Warning` finding whose `introduced_by` is absent or cannot be verified against the change diff or the recorded fix actions; every downgrade applied under this rule MUST be recorded in that round file's `## Fix Actions` naming the finding and the reason the evidence was unverifiable, and the completion output MUST list every such downgrade. This requirement does not apply to cash-propose rounds.

#### Scenario: Missing introduced_by is downgraded with a recorded trace

- **WHEN** an cash-apply `Reviewer B` finding classified `Critical` carries no `introduced_by` field
- **THEN** the main agent scores it at most `25` during the confidence filter
- **AND** it does not survive as `Critical` or `Warning`
- **AND** that round file's `## Fix Actions` records the downgrade and the reason
- **AND** the completion output lists the downgrade

#### Scenario: Verified introduced_by survives the filter

- **WHEN** an cash-apply `Reviewer B` finding cites an `introduced_by` location that the main agent verifies against the change diff
- **THEN** the finding passes through the confidence filter with its reviewer-assigned confidence

#### Scenario: Interaction regression cites a fix-action set

- **WHEN** an cash-apply `Reviewer B` finding attributes a regression to the interaction of several fixes and cites the set of fix actions of a named round as its `introduced_by`
- **THEN** the citation is verifiable evidence and no introduced-by downgrade applies




<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---
### Requirement: Review round action obligation

When a round's decision is `next_round`, every surviving `Critical` or `Warning` finding AND every cumulative-blocking-set member counted in the round decision MUST have at least one recorded action in that round's `## Fix Actions` section before the next round's reviewers are spawned. For a blocking finding or cumulative-blocking-set member, the valid actions are exactly: a fix listing the modified files, a grader-protection note, or an accepted-risks entry recorded with explicit user consent per the `Accepted-risks ledger` requirement; a non-blocking triage note recorded for a blocking member is not a valid action and has no effect on its blocking status. For a non-blocking (`new`) finding, the valid action is its non-blocking triage note; for a re-report that matches a prior round's non-blocking triage note, the valid action is a one-line cross-reference note naming the original round's triage note (neither a duplicate triage note nor a new signal). Recording a needs-design note is not a `next_round` action: per the `Fix-loop design circuit breaker` requirement it forces `decision: aborted` and never coexists with a `next_round` decision. The main agent MUST NOT spawn the next round's reviewers while any surviving finding has no recorded action.

#### Scenario: Zero-action round cannot advance

- **WHEN** a round's decision is `next_round` and at least one surviving finding has no recorded action in `## Fix Actions`
- **THEN** the main agent does not spawn the next round's reviewers until every surviving finding has a recorded action

#### Scenario: Every surviving finding carries an action record

- **WHEN** a round with `decision: next_round` finishes its fix phase
- **THEN** each surviving `Critical` or `Warning` finding maps to a fix record, a grader-protection note, a non-blocking triage note, or a consented accepted-risks entry in `## Fix Actions`

#### Scenario: Needs-design forces abort instead of another round

- **WHEN** a round records a needs-design note for a surviving finding
- **THEN** that round's decision is `aborted` per the `Fix-loop design circuit breaker` requirement
- **AND** the round does not proceed to `next_round`




<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---
### Requirement: cash-propose impact granularity advisory

After the proposal artifact is written, `cash-propose` SHALL count the affected-code entries in the proposal `## Impact` section: the count is the number of listed path entries across Modified, New, and Removed, excluding `(none)` placeholder lines; a directory entry counts as one entry, so the count is a lower bound. When the count exceeds 15, the skill MUST print an informational warning that states the count and recommends splitting the change by capability. The warning MUST NOT block the workflow and MUST NOT require user confirmation. When the count is 15 or fewer, the skill MUST print nothing for this check.

#### Scenario: Oversized impact prints an advisory

- **WHEN** the proposal `## Impact` section lists 20 affected-code path entries
- **THEN** the skill prints an informational warning stating the count and recommending a split by capability
- **AND** the workflow continues without requiring confirmation

#### Scenario: Small impact stays silent

- **WHEN** the proposal `## Impact` section lists 10 affected-code path entries
- **THEN** the skill prints nothing for this check

#### Scenario: Placeholder lines are not counted

- **WHEN** the proposal `## Impact` section lists 16 path entries and a `- Removed: (none)` placeholder line
- **THEN** the count is 16 and the advisory is printed

##### Example: advisory threshold

| Affected-code path entries | Advisory printed |
| -------------------------- | ---------------- |
| 8  | no  |
| 15 | no  |
| 16 | yes |
| 29 | yes |


<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---
### Requirement: Installer and cleanup enforce filesystem boundaries

The installer SHALL canonicalize an existing target and MUST reject an empty target, an unresolved target, `/`, the source repository itself, or a symlink target. Before any target write it MUST reject a managed skill destination, receipt, temporary receipt sibling, recognized retired plus candidate, or existing managed parent that is a symlink and MUST prove that every resolved destination and removal candidate remains below the canonical target. It MUST validate each existing retired plus candidate as an exact one-file legacy shape. Before destructive cleanup it MUST atomic-rename the candidate to a unique same-filesystem quarantine below the same target parent using destination-symlink no-follow semantics, revalidate the quarantined object without following the original candidate path, and remove only a still-recognized `SKILL.md` plus its empty quarantine directory. If revalidation fails it MUST preserve unknown content and MUST NOT use recursive deletion. In registry-backed modes, the installer SHALL validate that `HOME` is non-empty, absolute, existing, and not `/`; SHALL keep registry paths and temporary siblings below canonical `HOME`; and MUST reject symlinked configuration boundaries before registry reads or writes. The cleanup SHALL retain its existing exact-known-path HOME boundary contract. Every boundary failure MUST fail closed with zero writes.

#### Scenario: Installer rejects a symlink escape before writes

- **GIVEN** a managed target parent, skill destination, receipt, or receipt parent is a symlink
- **WHEN** `install-cash-skills.fish` performs preflight
- **THEN** it exits non-zero before creating or replacing any target file
- **AND** it identifies the unsafe project-relative destination

#### Scenario: Installer rejects its source repository

- **WHEN** the installer target resolves to the repository that contains the installer
- **THEN** it exits non-zero before writing a receipt or skill file

#### Scenario: Installer rejects unsafe HOME or registry boundary

- **GIVEN** `HOME` is empty, relative, missing, `/`, or an existing registry boundary is a symlink
- **WHEN** `install-cash-skills.fish` performs any registry-backed operation
- **THEN** it exits non-zero
- **AND** it does not read targets through the unsafe boundary
- **AND** it creates or modifies no registry, temporary file, receipt, or skill file

#### Scenario: Cleanup rejects unsafe HOME or symlink boundary

- **GIVEN** `HOME` is empty, relative, `/`, or an exact cleanup path has a symlinked existing boundary
- **WHEN** `uninstall-spectra-plus-repair.fish` performs preflight
- **THEN** it exits non-zero
- **AND** it does not invoke `launchctl` or remove any file


<!-- @trace
source: add-versioned-cash-skill-batch-update
updated: 2026-07-18
code:
  - .agents/skills/spectra-apply/SKILL.md
  - CASH-SKILLS.md
  - cash-skills.version
  - .agents/skills/spectra-analyze/SKILL.md
  - .agents/skills/spectra-verify/SKILL.md
  - install-cash-skills.fish
  - .agents/skills/spectra-propose/SKILL.md
tests:
  - scripts/cash-skills/tests/skill-checks.fish
-->

---
### Requirement: Cleanup unloads known labels independently of plist presence

The cleanup SHALL query both `gui/<uid>/com.spectra.plus.repair` and `gui/<uid>/com.agentflow.spectra-plus.repair` by label. A loaded label MUST be booted out even when its plist is absent. Registry and cache removal MUST occur only after both labels are confirmed absent or successfully unloaded. Any unexpected print or bootout error MUST fail closed and preserve all remaining legacy state.

#### Scenario: Loaded service without plist is removed

- **GIVEN** a known label is loaded and its plist is absent
- **WHEN** cleanup runs
- **THEN** it discovers the service by label and boots it out
- **AND** removes registry and cache only after both known labels are absent or unloaded

#### Scenario: Dry run never queries launchctl

- **WHEN** cleanup runs with `--dry-run`
- **THEN** it lists planned label and filesystem actions
- **AND** does not invoke `launchctl print` or `launchctl bootout`


<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---
### Requirement: Project-owned cash guidance survives Spectra updates

The repository SHALL place its cash workflow override after `<!-- SPECTRA:END -->` in `AGENTS.md`, outside the Spectra-managed block. The override MUST state that, for this repository, cash workflow invocation takes precedence over managed `spectra-*` workflow guidance while Spectra CLI and artifact schema remain authoritative.

#### Scenario: Forced update preserves effective cash guidance

- **WHEN** `spectra update --force` rewrites the Spectra-managed block in an isolated fixture
- **THEN** the project-owned override remains after `<!-- SPECTRA:END -->`
- **AND** the effective discuss-to-commit workflow still routes through `cash-*`


<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---
### Requirement: Variant parity compares complete governed bodies

The regression suite SHALL normalize only `/cash-*` versus `$cash-*` invocation syntax and SHALL compare the complete file of every paired skill. A skill without a declared tool difference MUST be identical after that normalization. Every declared difference MUST match its readable exact unified-diff manifest under `scripts/cash-skills/variant-parity/` line-for-line. The per-skill manifests MAY enumerate tool-specific frontmatter, fork-context wording, plan-directory and agent-selection behavior, and the tool-capability-specific `cash-audit` workflows (Codex standalone/discipline versus Claude report-only). Any difference not present in those manifests MUST fail the suite. The suite MUST NOT replace the readable manifests with opaque digests or broad ignored regions.

#### Scenario: Unlisted body drift fails parity

- **GIVEN** one variant omits or changes a workflow paragraph without an explicit allowlist entry
- **WHEN** variant parity runs
- **THEN** the suite exits non-zero and identifies the skill pair

#### Scenario: Tool-capability difference remains reviewable

- **GIVEN** a paired skill requires different frontmatter, fork behavior, plan integration, agent selection, or audit execution because the tools have different capabilities
- **WHEN** variant parity runs
- **THEN** every differing line is visible in that skill's exact manifest
- **AND** changing either variant without updating the reviewed manifest fails the suite


<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---
### Requirement: Live documentation reflects cash ownership and cleanup

The repository SHALL provide `CASH-SKILLS.md` as the current cash workflow guide. The guide MUST list the dual-variant inventory; explain direct installation, bundle version, target receipt, registry commands, batch update, dry-run, force, statuses, exit behavior, migration from receipt-less installs, recognized retired plus skill removal, safe rejection of unknown legacy content, and bundle version bump responsibility; preserve the one-time legacy repair-automation cleanup order; and state that cash skills have no periodic repair. `openspec/signals/README.md` MUST continue to describe current writers as cash review loops while preserving historical `## Occurrences` provenance text.

#### Scenario: Current installation and update instructions are complete

- **WHEN** a user reads `CASH-SKILLS.md`
- **THEN** the document provides the single installer entry point and all direct, registry, and batch commands
- **AND** it explains when a target is updated, skipped as current or newer, blocked as conflict, or classified as failed
- **AND** it identifies `cash-skills.version`, `.cash-skills/receipt.tsv`, and `$HOME/.config/cash-skills/projects.txt`
- **AND** it explains that successful target installation removes only recognized `spectra-propose-plus` and `spectra-apply-plus` directories and rejects unknown content

#### Scenario: Migration documentation has no active repair instruction

- **WHEN** a user reads `CASH-SKILLS.md` and `openspec/signals/README.md`
- **THEN** current instructions use `cash-propose`, `cash-apply`, the installer, and the one-time cleanup
- **AND** no current instruction tells the user to generate or periodically repair plus or cash skills
- **AND** historical occurrence entries remain unchanged


<!-- @trace
source: add-versioned-cash-skill-batch-update
updated: 2026-07-18
code:
  - .agents/skills/spectra-apply/SKILL.md
  - CASH-SKILLS.md
  - cash-skills.version
  - .agents/skills/spectra-analyze/SKILL.md
  - .agents/skills/spectra-verify/SKILL.md
  - install-cash-skills.fish
  - .agents/skills/spectra-propose/SKILL.md
tests:
  - scripts/cash-skills/tests/skill-checks.fish
-->

---
### Requirement: Cash skill bundle version and target receipt

The repository SHALL define the complete 24-file cash skill inventory as one bundle. `cash-skills.version` MUST contain exactly one `MAJOR.MINOR.PATCH` value with three non-negative integer components that each match `0|[1-9][0-9]*`, with no leading zero, prerelease, or build suffix. Version ordering MUST compare arbitrary-length components by digit-string length and then lexicographically without fixed-width or floating-point conversion. Every repository change that alters installed bytes in the canonical 24-file inventory MUST increase this bundle version. A successful installation or adoption MUST publish `.cash-skills/receipt.tsv` in the target with the bundle version followed by exactly one SHA-256 record for each canonical project-relative path in inventory order.

#### Scenario: Successful install publishes a complete receipt

- **WHEN** the installer completes an install, upgrade, repair, or adoption
- **THEN** the target receipt records the current source bundle version
- **AND** it records the lowercase SHA-256 digest and project-relative path of all 24 installed files in canonical order
- **AND** every recorded digest matches the installed target file

#### Scenario: Invalid source version fails before target writes

- **WHEN** `cash-skills.version` is missing, unreadable, has extra lines, contains a leading-zero component, or is not a strict three-component version
- **THEN** the installer exits with an execution failure
- **AND** it performs no target write
- **AND** dry-run reports the same failure

#### Scenario: Changed working version is compared with HEAD

- **GIVEN** repository history contains `cash-skills.version`
- **WHEN** the current version differs from `HEAD`
- **THEN** the cash contract suite requires it to be non-decreasing and strictly greater when the canonical installed bytes differ from `HEAD`

#### Scenario: Same version is bound to its introduction commit

- **GIVEN** the current version equals `HEAD`
- **WHEN** the cash contract suite evaluates version governance
- **THEN** the suite finds that version's first commit in its contiguous first-parent history segment
- **AND** it requires the current canonical installed bytes to equal that introduction commit
- **AND** a same-version content change fails even after later unrelated commits

#### Scenario: Arbitrary-length components retain numeric order

- **WHEN** two valid versions contain a component longer than the platform integer or floating-point safe range
- **THEN** comparison orders the longer digit string as greater
- **AND** equal-length components are ordered lexicographically

#### Scenario: Invalid receipt is not treated as an uninstalled target

- **GIVEN** the target receipt has an invalid version, field count, digest, path, path order, duplicate, missing record, or unknown record
- **WHEN** the installer evaluates the target
- **THEN** it exits with an execution failure
- **AND** it does not classify the target as missing, current, newer, or conflict
- **AND** it performs no target write

#### Scenario: Upgrade failure retains the prior receipt

- **GIVEN** the target has a valid prior receipt
- **WHEN** a runtime write fails after preflight while copying a managed skill file
- **THEN** the installer exits non-zero
- **AND** it does not publish the new receipt
- **AND** the next invocation detects any partial write as drift against the prior receipt

#### Scenario: First-install failure remains receipt-less

- **GIVEN** the target has no prior receipt
- **AND** at least one managed destination write persists before the error
- **WHEN** a runtime write fails after preflight while copying a managed skill file
- **THEN** the installer exits non-zero without publishing a receipt
- **AND** the next invocation classifies the mixed or incomplete receipt-less target as conflict

#### Scenario: First-install failure before the first write remains clean

- **GIVEN** the target has no prior receipt
- **WHEN** a runtime error occurs before any managed destination write persists
- **THEN** the installer exits non-zero without publishing a receipt
- **AND** the next invocation follows the clean first-install path


<!-- @trace
source: add-versioned-cash-skill-batch-update
updated: 2026-07-18
code:
  - .agents/skills/spectra-apply/SKILL.md
  - CASH-SKILLS.md
  - cash-skills.version
  - .agents/skills/spectra-analyze/SKILL.md
  - .agents/skills/spectra-verify/SKILL.md
  - install-cash-skills.fish
  - .agents/skills/spectra-propose/SKILL.md
tests:
  - scripts/cash-skills/tests/skill-checks.fish
-->

---
### Requirement: Manual cash project registry

The repository SHALL provide the registry operations through `install-cash-skills.fish`, with exactly one of `--target <project>`, `--register <project>`, `--unregister <project>`, `--list`, or `--all` per invocation. The registry SHALL be `$HOME/.config/cash-skills/projects.txt` with one canonical absolute project path per non-empty line, and paths MUST NOT contain ASCII control characters. Every registry-backed mode MUST fully validate an existing registry before using it. Registry mutations MUST use a same-directory temporary file and atomic rename. The installer MUST NOT schedule or launch a future invocation.

#### Scenario: First register creates safe state

- **GIVEN** the cash-skills config directory and registry do not exist below a safe HOME
- **WHEN** `--register <project>` receives a valid target
- **THEN** the installer creates only the required config directory and atomically published registry

#### Scenario: Missing registry is empty for read and removal modes

- **GIVEN** the cash-skills config directory and registry do not exist below a safe HOME
- **WHEN** `--unregister <project>`, `--list`, or `--all` runs
- **THEN** the installer succeeds against an empty list without creating state
- **AND** `--all` prints a zero-count summary

#### Scenario: Register canonicalizes and deduplicates a target

- **WHEN** `--register <project>` receives an existing non-symlink project directory
- **THEN** the installer stores its canonical absolute path exactly once
- **AND** it leaves every other valid entry unchanged

#### Scenario: Register rejects line-oriented path injection

- **WHEN** a register or unregister input contains tab, CR, LF, or another ASCII control character
- **THEN** the installer exits non-zero
- **AND** it does not create or modify the registry

#### Scenario: Existing registry records reject retained control characters

- **WHEN** an LF-delimited existing registry record contains tab, CR, or another retained ASCII control character
- **THEN** every registry-backed installer mode exits non-zero
- **AND** it does not create or modify the registry or any target

#### Scenario: Unregister removes an existing or stale target

- **WHEN** `--unregister <project>` identifies a canonical existing target or an exact stored absolute stale target without dot segments
- **THEN** the installer removes that entry atomically
- **AND** a missing entry is a successful no-op

#### Scenario: List is read-only

- **WHEN** `--list` receives a valid registry
- **THEN** it prints the deduplicated canonical entries
- **AND** it creates or modifies no registry, target, receipt, skill file, temporary file, or background process

#### Scenario: Invalid registry fails closed

- **WHEN** the registry is unreadable or contains a relative path, root path, dot segment, malformed line, or unsafe boundary
- **THEN** `--register`, `--unregister`, `--list`, and `--all` exit non-zero before processing any target or rewriting the registry
- **AND** no registry or target state is modified


<!-- @trace
source: add-versioned-cash-skill-batch-update
updated: 2026-07-18
code:
  - .agents/skills/spectra-apply/SKILL.md
  - CASH-SKILLS.md
  - cash-skills.version
  - .agents/skills/spectra-analyze/SKILL.md
  - .agents/skills/spectra-verify/SKILL.md
  - install-cash-skills.fish
  - .agents/skills/spectra-propose/SKILL.md
tests:
  - scripts/cash-skills/tests/skill-checks.fish
-->

---
### Requirement: Version-aware cash skill batch installation

`install-cash-skills.fish --all [--dry-run] [--force]` SHALL process every deduplicated registry target by reusing the same installer target workflow as `--target`. It MUST report each target as `updated`, `would-update`, `current`, `newer`, `conflict`, or `failed`, then print counts for every status. A target conflict or failure MUST NOT stop later targets, and the aggregate command MUST exit non-zero when any target is `conflict` or `failed`.

#### Scenario: Only older bundles are updated

- **GIVEN** the registry contains valid clean targets whose receipt versions are older than, equal to, and newer than the source version
- **AND** the equal-version target's current source and target digests all match its receipt
- **WHEN** the installer runs with `--all`
- **THEN** it reports the older target as `updated`
- **AND** it reports the equal target as `current`
- **AND** it reports the newer target as `newer`
- **AND** it does not rewrite the equal or newer target

##### Example: Numeric version ordering

| Source | Target | Expected status |
| ----- | ----- | ----- |
| `1.10.0` | `1.9.9` | `updated` |
| `2.0.0` | `2.0.0` | `current` |
| `2.9.0` | `3.0.0` | `newer` |

#### Scenario: Batch surfaces equal-version source integrity failure

- **GIVEN** a registered target has a valid receipt equal to the source version
- **AND** at least one current source digest differs from that receipt
- **WHEN** the installer runs with `--all` or `--all --force`
- **THEN** it reports the target as `failed`
- **AND** it performs no target write
- **AND** the aggregate command exits non-zero

#### Scenario: Drift is preserved unless force is explicit

- **GIVEN** an older or equal-version target has a managed file whose digest differs from its valid receipt
- **AND** when versions are equal every current source digest matches the receipt
- **WHEN** the installer runs without `--force`
- **THEN** it reports that target as `conflict`
- **AND** it does not modify any managed target state
- **WHEN** the installer runs again with `--force`
- **THEN** it replaces only the explicit managed inventory and receipt
- **AND** it reports the target as `updated`

#### Scenario: Force never downgrades a newer target

- **GIVEN** a valid target receipt version is greater than the source version
- **WHEN** the installer runs with `--all --force`
- **THEN** it reports the target as `newer`
- **AND** it does not modify the target

#### Scenario: Target failure does not stop the batch

- **GIVEN** one registered target fails execution and a later registered target can update
- **WHEN** the installer runs with `--all`
- **THEN** it reports the first target as `failed`
- **AND** it processes and updates the later target
- **AND** the aggregate command exits non-zero

#### Scenario: Batch dry run uses full validation without writes

- **WHEN** the installer runs with `--all --dry-run`
- **THEN** every target receives the same source, receipt, version, hash, registry, and filesystem-boundary validation as a real run
- **AND** planned updates are reported as `would-update`
- **AND** no target, receipt, registry, temporary file, or background state is created or modified

<!-- @trace
source: add-versioned-cash-skill-batch-update
updated: 2026-07-18
code:
  - .agents/skills/spectra-apply/SKILL.md
  - CASH-SKILLS.md
  - cash-skills.version
  - .agents/skills/spectra-analyze/SKILL.md
  - .agents/skills/spectra-verify/SKILL.md
  - install-cash-skills.fish
  - .agents/skills/spectra-propose/SKILL.md
tests:
  - scripts/cash-skills/tests/skill-checks.fish
-->