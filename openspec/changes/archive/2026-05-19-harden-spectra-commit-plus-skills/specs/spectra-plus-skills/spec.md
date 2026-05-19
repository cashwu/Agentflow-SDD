## ADDED Requirements

### Requirement: spectra-commit archive-first allowlist

The system SHALL make `spectra-commit` collect archive-first commit files through an explicit allowlist after `spectra archive` completes. The archive-first commit set MUST include tracked source files from the pre-archive confirmed commit set, files belonging to the selected change archive, and spec sync files from `openspec/specs/` when the user explicitly selected spec sync during the archive sub-flow. The archive-first commit set MUST NOT include unrelated dirty files discovered by the post-archive `git status --porcelain` scan.

#### Scenario: unrelated deletion exists before archive-first commit

- **WHEN** `spectra-commit` is committing change `demo-change` with archive-first enabled
- **AND** `git status --porcelain` already contains `D .agents/skills/spectra-apply-plus/SKILL.md` before `spectra archive demo-change` runs
- **THEN** the default commit set excludes `.agents/skills/spectra-apply-plus/SKILL.md`
- **AND** the commit plan displays that deletion outside the included archive-related files

#### Scenario: archive files are included after archive succeeds

- **WHEN** `spectra archive demo-change` moves files from `openspec/changes/demo-change/` to `openspec/changes/archive/2026-05-19-demo-change/`
- **THEN** `spectra-commit` includes deletions under `openspec/changes/demo-change/`
- **AND** `spectra-commit` includes additions or modifications under `openspec/changes/archive/2026-05-19-demo-change/`
- **AND** `spectra-commit` excludes dirty files outside the selected change archive, tracked source files, and explicitly selected spec sync files

#### Scenario: spec sync files require explicit sync selection

- **WHEN** the user selects spec sync during the archive sub-flow for `demo-change`
- **THEN** `spectra-commit` includes resulting changes under `openspec/specs/`
- **AND** the updated commit plan displays them as Spec Sync Changes

#### Scenario: archive path wording is current

- **WHEN** `spectra-commit` displays the updated archive-first commit plan
- **THEN** the archived file section names `openspec/changes/archive/<date>-<change>/`
- **AND** the archive-first workflow text does not name `openspec/archived/`

### Requirement: plus generated skill deletion guard

The system SHALL protect generated plus skill files from accidental deletion during `spectra-commit`. Deletions under `.agents/skills/spectra-*-plus/` and `.claude/skills/spectra-*-plus/` MUST be excluded from the default commit set. The system MUST allow those deletions only when the user explicitly adds them through the Customize flow.

#### Scenario: protected Codex plus skill deletion

- **WHEN** `git status --porcelain` contains `D .agents/skills/spectra-propose-plus/SKILL.md`
- **AND** the user chooses Commit as shown or Archive first, then commit together
- **THEN** `spectra-commit` excludes `.agents/skills/spectra-propose-plus/SKILL.md` from staged files
- **AND** the commit plan displays the deletion as excluded or protected

#### Scenario: protected Claude plus skill deletion

- **WHEN** `git status --porcelain` contains `D .claude/skills/spectra-apply-plus/SKILL.md`
- **AND** the user chooses Commit as shown or Archive first, then commit together
- **THEN** `spectra-commit` excludes `.claude/skills/spectra-apply-plus/SKILL.md` from staged files
- **AND** the commit plan displays the deletion as excluded or protected

#### Scenario: user explicitly includes protected deletion

- **WHEN** `git status --porcelain` contains `D .agents/skills/spectra-apply-plus/SKILL.md`
- **AND** the user chooses Customize
- **AND** the user explicitly adds `.agents/skills/spectra-apply-plus/SKILL.md` to the commit set
- **THEN** `spectra-commit` includes that deletion in the confirmed commit set

### Requirement: plus installer updates spectra-commit guard

The system SHALL make `install-spectra-plus.fish` install or verify the `spectra-commit` archive-first allowlist and plus generated skill deletion guard in both Codex and Claude skill roots. The installer MUST fail with a clear error when the target project lacks a required `spectra-commit` skill file or when the target skill shape cannot be updated safely.

#### Scenario: installer verifies guarded target skills

- **WHEN** the user runs `./install-spectra-plus.fish --target <project>`
- **THEN** the installer verifies `.agents/skills/spectra-commit/SKILL.md` contains the archive-first allowlist guard
- **AND** the installer verifies `.agents/skills/spectra-commit/SKILL.md` contains the plus generated skill deletion patterns
- **AND** the installer verifies `.claude/skills/spectra-commit/SKILL.md` contains the same guard and patterns

#### Scenario: installer updates unguarded target skills

- **WHEN** the target project contains `.agents/skills/spectra-commit/SKILL.md` and `.claude/skills/spectra-commit/SKILL.md` without the archive-first allowlist guard
- **AND** the user runs `./install-spectra-plus.fish --target <project>`
- **THEN** the installer updates both `spectra-commit` skill files with the guard
- **AND** a second installer run leaves each guard block present exactly once

#### Scenario: unsupported commit skill shape fails installation

- **WHEN** the target project's `spectra-commit` skill file lacks the section required for a safe guard update
- **AND** the user runs `./install-spectra-plus.fish --target <project>`
- **THEN** `install-spectra-plus.fish` exits with a non-zero status
- **AND** stderr states that the `spectra-commit` guard could not be applied safely

#### Scenario: dry-run reports commit guard work

- **WHEN** the user runs `./install-spectra-plus.fish --target <project> --dry-run`
- **THEN** the output lists the planned `spectra-commit` guard check or update
- **AND** the installer does not modify target files

#### Scenario: missing Codex commit skill fails installation

- **WHEN** the target project lacks `.agents/skills/spectra-commit/SKILL.md`
- **THEN** `install-spectra-plus.fish` exits with a non-zero status
- **AND** stderr names `.agents/skills/spectra-commit/SKILL.md` as the missing requirement

#### Scenario: missing Claude commit skill fails installation

- **WHEN** the target project lacks `.claude/skills/spectra-commit/SKILL.md`
- **THEN** `install-spectra-plus.fish` exits with a non-zero status
- **AND** stderr names `.claude/skills/spectra-commit/SKILL.md` as the missing requirement
