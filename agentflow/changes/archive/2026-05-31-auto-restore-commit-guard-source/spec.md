# spectra-plus-skills Spec Delta：auto-restore-commit-guard-source

本變更於 `openspec/specs/spectra-plus-skills/spec.md` 新增下列 requirement。

---
### Requirement: Auto-restore stripped commit guard source from git HEAD

The system SHALL allow `install-spectra-plus.fish` to recover automatically when a source `spectra-commit/SKILL.md` file has lost its `SPECTRA-COMMIT-GUARD` block. During guard application, before failing on an invalid source, the installer MUST attempt to restore that source file from its git `HEAD` version, and MUST do so only under all of these conditions: the working-tree source fails `validate_commit_guard`; the source resides inside a git work tree; and the `HEAD` version of that exact file passes the full `validate_commit_guard` check. The restore MUST affect only the single source file path (working tree), MUST NOT run an unscoped restore, MUST NOT modify the git index, MUST respect `--dry-run` by reporting without mutating, and MUST log the restore action. When any precondition is not met, the installer MUST fall back to the existing fail-loud behavior unchanged. This recovery applies to both the Claude (`.claude/skills/spectra-commit/SKILL.md`) and Codex (`.agents/skills/spectra-commit/SKILL.md`) source files.

#### Scenario: Self-heal stripped source from valid HEAD

- **GIVEN** the working-tree source `spectra-commit/SKILL.md` is missing a valid `SPECTRA-COMMIT-GUARD` block
- **AND** the file resides in a git work tree whose `HEAD` version of that file passes `validate_commit_guard`
- **WHEN** `install-spectra-plus.fish` applies the commit guard (via `--target` or `--repair-all`)
- **THEN** the installer restores the source file from `HEAD`
- **AND** logs a message naming the restored file and that it was restored from `HEAD`
- **AND** continues guard application so the run reports success
- **AND** the restored source file again contains a valid guard

#### Scenario: HEAD source is also invalid

- **GIVEN** the working-tree source is missing a valid guard
- **AND** the `HEAD` version of that file also fails `validate_commit_guard`
- **WHEN** the installer applies the commit guard
- **THEN** the installer does not restore the file
- **AND** exits with a non-zero status with the existing source guard error

#### Scenario: Source is not in a git work tree

- **GIVEN** the working-tree source is missing a valid guard
- **AND** the source does not reside in a git work tree (no git, untracked, or no `HEAD`)
- **WHEN** the installer applies the commit guard
- **THEN** the installer does not restore the file
- **AND** falls back to the existing fail-loud behavior with a non-zero status

#### Scenario: Dry-run reports restore without mutating

- **GIVEN** the working-tree source is missing a valid guard and `HEAD` is valid
- **WHEN** the user runs the installer with `--dry-run`
- **THEN** the output reports that it would restore the source file from `HEAD`
- **AND** the source file is not modified
- **AND** no git mutation, lock, cache, or throttle state is written

#### Scenario: Restore is limited to the single source file

- **GIVEN** the working-tree source is missing a valid guard and `HEAD` is valid
- **AND** an unrelated dirty file exists in the same git work tree
- **WHEN** the installer restores the source from `HEAD`
- **THEN** only the single `spectra-commit/SKILL.md` source file is restored
- **AND** the unrelated dirty file remains unchanged

<!-- @trace
source: auto-restore-commit-guard-source
updated: 2026-05-31
code:
  - install-spectra-plus.fish
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
-->
