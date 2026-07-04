## ADDED Requirements

### Requirement: Repair-all protects registered targets from dirty source checkout

The system SHALL prevent automatic registered-target repair from using uncommitted source-sensitive changes in the source checkout. The source checkout MUST be the git work tree containing `install-spectra-plus.fish`, and source-sensitive path matching MUST be evaluated relative to that work tree root. Source-sensitive paths MUST include `install-spectra-plus.fish`, all files under `scripts/spectra-plus/`, all files under matching `.agents/skills/spectra-*/` directories, and all files under matching `.claude/skills/spectra-*/` directories. Source-sensitive path matching MUST respect path segment boundaries rather than substring matches. Dirty detection MUST treat any `git status --porcelain` entry matching a source-sensitive path as dirty, including git index and working tree status. Dirty files outside the source-sensitive path set MUST NOT block automatic repair. Dirty-source skip output SHOULD name at least one matching source-sensitive path when available. For `--repair-all`, this dirty-source guard MUST run before dependency preflight that is not needed to detect dirty source, lock acquisition, throttle state reads or writes, registry target processing, local plus metadata validation, and `spectra-commit` guard source auto-restore.

#### Scenario: Repair-all skips when source-sensitive files are dirty

- **GIVEN** the registered target list contains one valid target project
- **AND** at least one source-sensitive path in the source checkout is dirty
- **WHEN** the user runs `install-spectra-plus.fish --repair-all`
- **THEN** the command exits with status 0
- **AND** the output reports that repair-all was skipped because the source checkout is dirty
- **AND** the command does not report the target as current or repaired
- **AND** the command does not modify any registered target generated plus skill or `spectra-commit` guard file

#### Scenario: Repair-all skips for non-output spectra skill WIP

- **GIVEN** the registered target list contains one valid target project
- **AND** a `.agents/skills/spectra-*` or `.claude/skills/spectra-*` file that is not directly read by the current plus generator is dirty
- **WHEN** the user runs `install-spectra-plus.fish --repair-all`
- **THEN** the command exits with status 0
- **AND** the output reports that repair-all was skipped because the source checkout is dirty
- **AND** the command does not modify any registered target file

#### Scenario: Repair-all skips when source clean state is unavailable

- **GIVEN** the source checkout clean state cannot be determined
- **WHEN** the user runs `install-spectra-plus.fish --repair-all`
- **THEN** the command exits with status 0
- **AND** the output reports that repair-all was skipped because source clean state is unavailable
- **AND** the command does not process registry targets
- **AND** the command does not modify any registered target file

#### Scenario: Repair-all skips before local metadata validation

- **GIVEN** the registered target list contains one valid target project
- **AND** `scripts/spectra-plus/rules.yaml` is dirty in the source checkout
- **AND** the dirty `rules.yaml` contains invalid plus metadata
- **WHEN** the user runs `install-spectra-plus.fish --repair-all`
- **THEN** the command exits with status 0
- **AND** the output reports that repair-all was skipped because the source checkout is dirty
- **AND** the command does not report a metadata validation failure
- **AND** the command does not modify any registered target file

#### Scenario: Repair-all skips before commit guard source auto-restore

- **GIVEN** the registered target list contains one valid target project
- **AND** a source `spectra-commit/SKILL.md` file is dirty in the source checkout
- **AND** the dirty source `spectra-commit/SKILL.md` is missing a valid `SPECTRA-COMMIT-GUARD` block
- **AND** the `HEAD` version of that source file contains a valid guard
- **WHEN** the user runs `install-spectra-plus.fish --repair-all`
- **THEN** the command exits with status 0
- **AND** the output reports that repair-all was skipped because the source checkout is dirty
- **AND** the command does not restore the dirty source file from `HEAD`
- **AND** the command does not modify any registered target file

#### Scenario: Repair-all skips before registry target processing

- **GIVEN** the registered target list contains an invalid target path
- **AND** at least one source-sensitive path in the source checkout is dirty
- **WHEN** the user runs `install-spectra-plus.fish --repair-all`
- **THEN** the command exits with status 0
- **AND** the output reports that repair-all was skipped because the source checkout is dirty
- **AND** the command does not report the invalid target path as a target failure

#### Scenario: Repair-all skips before lock and throttle state

- **GIVEN** the registered target list contains one valid target project
- **AND** at least one source-sensitive path in the source checkout is dirty
- **WHEN** the user runs `install-spectra-plus.fish --repair-all`
- **THEN** the command exits with status 0
- **AND** the output reports that repair-all was skipped because the source checkout is dirty
- **AND** the command does not create a repair lock
- **AND** the command does not write throttle state

#### Scenario: Repair-all dry-run skips when source-sensitive files are dirty

- **GIVEN** the registered target list contains one valid target project
- **AND** at least one source-sensitive path in the source checkout is dirty
- **WHEN** the user runs `install-spectra-plus.fish --repair-all --dry-run`
- **THEN** the command exits with status 0
- **AND** the output reports that repair-all was skipped because the source checkout is dirty
- **AND** the output does not list per-target repair commands
- **AND** the command does not modify any registered target file

#### Scenario: Staged source-sensitive changes block repair-all

- **GIVEN** the registered target list contains one valid target project
- **AND** a source-sensitive path has a staged modification in the git index
- **AND** the source-sensitive path has no unstaged working tree modification
- **WHEN** the user runs `install-spectra-plus.fish --repair-all`
- **THEN** the command exits with status 0
- **AND** the output reports that repair-all was skipped because the source checkout is dirty
- **AND** the command does not modify any registered target file

#### Scenario: Staged added source-sensitive files block repair-all

- **GIVEN** the registered target list contains one valid target project
- **AND** a new source-sensitive path is staged in the git index
- **AND** the new source-sensitive path has no unstaged working tree modification
- **WHEN** the user runs `install-spectra-plus.fish --repair-all`
- **THEN** the command exits with status 0
- **AND** the output reports that repair-all was skipped because the source checkout is dirty
- **AND** the command does not modify any registered target file

#### Scenario: Renamed or deleted source-sensitive paths block repair-all

- **GIVEN** the registered target list contains one valid target project
- **AND** `git status --porcelain` reports a deleted or renamed source-sensitive path relative to the source checkout root
- **WHEN** the user runs `install-spectra-plus.fish --repair-all`
- **THEN** the command exits with status 0
- **AND** the output reports that repair-all was skipped because the source checkout is dirty
- **AND** the command does not modify any registered target file

#### Scenario: Unmerged source-sensitive paths block repair-all

- **GIVEN** the registered target list contains one valid target project
- **AND** `git status --porcelain` reports an unmerged source-sensitive path relative to the source checkout root
- **WHEN** the user runs `install-spectra-plus.fish --repair-all`
- **THEN** the command exits with status 0
- **AND** the output reports that repair-all was skipped because the source checkout is dirty
- **AND** the command does not modify any registered target file

#### Scenario: Directory boundary prevents false source-sensitive matches

- **GIVEN** the registered target list contains one valid target project
- **AND** the source checkout has dirty files only at paths that share a prefix with source-sensitive paths but are outside the source-sensitive directories
- **WHEN** the user runs `install-spectra-plus.fish --repair-all`
- **THEN** the command does not report a dirty-source skip for those prefix-only paths
- **AND** repair-all processes the registered target according to the existing current-state and repair behavior

#### Scenario: LaunchAgent entrypoint allows dirty-source skip before yq preflight

- **GIVEN** at least one source-sensitive path in the source checkout is dirty
- **AND** `yq` is not available in the LaunchAgent entrypoint environment
- **WHEN** the LaunchAgent entrypoint runs repair-all
- **THEN** the command exits with status 0
- **AND** the output reports that repair-all was skipped because the source checkout is dirty
- **AND** the output does not report missing `yq`

#### Scenario: Parseable dirty repair-all entrypoint hands off to dirty-source guard

- **GIVEN** `scripts/spectra-plus/repair-all.fish` is dirty in the source checkout
- **AND** the dirty entrypoint is parseable by `fish`
- **WHEN** the LaunchAgent entrypoint runs repair-all
- **THEN** the command exits with status 0
- **AND** the output reports that repair-all was skipped because the source checkout is dirty
- **AND** the entrypoint does not read registry targets
- **AND** the entrypoint does not create a repair lock
- **AND** the entrypoint does not write throttle state
- **AND** the command does not modify any registered target file

#### Scenario: Manual target install remains available with dirty source-sensitive files

- **GIVEN** a valid target project exists
- **AND** at least one source-sensitive path in the source checkout is dirty
- **WHEN** the user runs `install-spectra-plus.fish --target <project>`
- **THEN** the dirty-source automatic repair guard does not block the command
- **AND** the command follows the existing single-target installation and validation behavior

#### Scenario: Unrelated dirty files do not block repair-all

- **GIVEN** the registered target list contains one valid target project
- **AND** the source checkout has dirty files only outside the source-sensitive path set
- **WHEN** the user runs `install-spectra-plus.fish --repair-all`
- **THEN** repair-all processes the registered target according to the existing current-state and repair behavior
- **AND** the command does not report a dirty-source skip

## MODIFIED Requirements

### Requirement: Repair all registered plus skill targets

The system SHALL provide a repair-all operation that restores generated plus skills and `spectra-commit` guard behavior for every registered target. The repair-all operation MUST reuse the same installation and validation behavior as single-target installation when source-sensitive paths are clean. When source-sensitive paths are dirty, the dirty-source guard MUST skip repair-all before target processing.

#### Scenario: Repair multiple reset targets

- **GIVEN** source-sensitive paths are clean
- **AND** the registry contains two valid project targets
- **AND** each target is missing at least one generated plus skill or required `spectra-commit` guard content
- **WHEN** the user runs repair-all
- **THEN** the system repairs both targets
- **AND** each target contains `spectra-propose-plus`, `spectra-apply-plus`, and the required `spectra-commit` guard after repair-all completes

#### Scenario: Ignore unregistered project targets

- **GIVEN** source-sensitive paths are clean
- **AND** the registry contains one reset project target
- **AND** another reset project exists on disk but is not listed in the registry
- **WHEN** the user runs repair-all
- **THEN** the system repairs only the registered target
- **AND** does not modify the unregistered project's skill files or guard content

##### Example: registered target only

- **GIVEN** source-sensitive paths are clean
- **AND** the registry contains `/tmp/registered-project`
- **AND** `/tmp/unregistered-project` is missing `spectra-propose-plus`
- **WHEN** the user runs repair-all
- **THEN** `/tmp/registered-project` is repaired
- **AND** `/tmp/unregistered-project/.agents/skills/spectra-propose-plus/SKILL.md` remains absent

#### Scenario: Continue after one target fails

- **GIVEN** source-sensitive paths are clean
- **AND** the registry contains one invalid target and one valid target
- **WHEN** the user runs repair-all
- **THEN** the system reports the invalid target failure
- **AND** still attempts to repair the valid target
- **AND** exits with a non-zero status after processing all registered targets

#### Scenario: Dry-run repair-all

- **GIVEN** source-sensitive paths are clean
- **WHEN** the user runs repair-all in dry-run mode
- **THEN** the system lists the target repair actions it would perform
- **AND** does not modify any registered target project
- **AND** does not create or update lock, cache, or throttle state files

##### Example: dry-run leaves state untouched

- **GIVEN** source-sensitive paths are clean
- **AND** `HOME=/tmp/home` and `TMPDIR=/tmp/run`
- **WHEN** the user runs repair-all in dry-run mode
- **THEN** `/tmp/home/.cache/spectra-plus/last-repair-attempt` is not created or modified
- **AND** `/tmp/run/spectra-plus-repair.lock` is not created or modified

#### Scenario: Per-target repair summary

- **GIVEN** source-sensitive paths are clean
- **WHEN** repair-all processes registered targets
- **THEN** the system prints a per-target summary for each success, skipped, and failed target
- **AND** exits with a non-zero status when any target fails after all registered targets have been processed

### Requirement: LaunchAgent-based automatic plus skill repair

The system SHALL provide a macOS LaunchAgent installation flow that runs repair-all for registered targets without modifying `/Applications/Spectra.app`. The LaunchAgent installation MUST be reversible and MUST be safe to run repeatedly. The LaunchAgent execution path MUST use a controlled environment that can locate required commands or report missing commands through predictable logs, except that dirty-source skip MUST run before dependency checks that are not needed to detect dirty source.

#### Scenario: Install LaunchAgent

- **WHEN** the user installs the plus skill repair LaunchAgent
- **THEN** the system writes a LaunchAgent plist for the repair-all operation
- **AND** the plist uses the configured registered target repair entrypoint
- **AND** the plist or entrypoint provides a controlled execution environment for required commands
- **AND** the system loads or refreshes the LaunchAgent for the current user session
- **AND** running the installation again updates or verifies the same LaunchAgent without creating duplicate agents

#### Scenario: LaunchAgent activation failure

- **WHEN** the user installs the plus skill repair LaunchAgent and the agent cannot be loaded
- **THEN** the system exits with a non-zero status
- **AND** prints the failing activation command or a clear manual activation instruction

#### Scenario: Dry-run LaunchAgent update

- **WHEN** the user installs or uninstalls the plus skill repair LaunchAgent in dry-run mode
- **THEN** the system prints the LaunchAgent action it would perform
- **AND** does not write or remove the plist
- **AND** does not call `launchctl`

#### Scenario: Uninstall LaunchAgent

- **WHEN** the user uninstalls the plus skill repair LaunchAgent
- **THEN** the system unloads and removes the LaunchAgent plist if present
- **AND** uninstalling when the LaunchAgent is absent succeeds without error

#### Scenario: Automatic repair is bounded

- **GIVEN** source-sensitive paths are clean
- **WHEN** the LaunchAgent invokes repair-all repeatedly
- **THEN** repair-all prevents overlapping executions with a lock
- **AND** repair-all respects a throttle window that is not greater than the LaunchAgent `StartInterval`
- **AND** repair-all cleans up its own lock after normal exit or handled failure

#### Scenario: Throttle after failed repair attempt

- **GIVEN** source-sensitive paths are clean
- **AND** repair-all processed an invalid registered target and exited with a non-zero status
- **WHEN** repair-all is invoked again within the throttle window without force
- **THEN** the system skips the repeated repair attempt
- **AND** reports the throttle decision without modifying registered target projects

#### Scenario: Dirty-source skip takes precedence over throttle

- **GIVEN** throttle state exists from an earlier repair attempt
- **AND** at least one source-sensitive path in the source checkout is dirty
- **WHEN** repair-all is invoked within the throttle window without force
- **THEN** the command exits with status 0
- **AND** the output reports that repair-all was skipped because the source checkout is dirty
- **AND** the output does not report a throttle decision
- **AND** the throttle state is not modified

#### Scenario: Stale lock can recover

- **GIVEN** source-sensitive paths are clean
- **AND** a repair-all lock exists from an earlier interrupted process and is older than the stale lock threshold
- **WHEN** the user runs repair-all
- **THEN** the system treats the stale lock as recoverable
- **AND** proceeds with the repair attempt or reports a clear manual cleanup instruction

### Requirement: Repair checks plus metadata freshness

The installer and repair-all current-state checks SHALL treat plus skill metadata as part of the generated output freshness contract. The current `spectraPlusVersion` and `spectraPlusUpdated` values SHALL be read from the local `scripts/spectra-plus/rules.yaml` source of truth. A target project SHALL be current only when every generated plus skill output top-level YAML frontmatter contains the current `spectraPlusVersion` and `spectraPlusUpdated` values. For repair-all, local metadata parsing MUST run only after source-sensitive paths are known to be clean.

#### Scenario: Target missing plus metadata is stale

- **GIVEN** source-sensitive paths are clean
- **AND** a registered target project has generated plus skill outputs without `spectraPlusVersion`
- **WHEN** the user runs repair-all
- **THEN** the target is treated as stale
- **AND** repair-all rewrites the generated plus skill outputs with current metadata

#### Scenario: Target with old plus metadata is stale

- **GIVEN** source-sensitive paths are clean
- **AND** a registered target project has generated plus skill outputs containing `spectraPlusVersion: 1.0.0`
- **WHEN** the user runs repair-all
- **THEN** the target is treated as stale
- **AND** repair-all rewrites the generated plus skill outputs with `spectraPlusVersion: 1.1.0`
- **AND** repair-all rewrites the generated plus skill outputs with `spectraPlusUpdated: 2026-07-04`

#### Scenario: Target with old updated date metadata is stale

- **GIVEN** source-sensitive paths are clean
- **AND** a registered target project has generated plus skill outputs containing `spectraPlusUpdated: 2026-01-01`
- **WHEN** the user runs repair-all
- **THEN** the target is treated as stale
- **AND** repair-all rewrites the generated plus skill outputs with `spectraPlusUpdated: 2026-07-04`

#### Scenario: Target with one stale generated variant is stale

- **GIVEN** source-sensitive paths are clean
- **AND** a registered target project has one generated plus skill output with stale plus metadata
- **AND** the other generated plus skill outputs contain current plus metadata
- **WHEN** the user runs repair-all
- **THEN** the target is treated as stale
- **AND** repair-all rewrites every generated plus skill output with current plus metadata

#### Scenario: Local rules metadata parse failure aborts repair

- **GIVEN** source-sensitive paths are clean
- **AND** local `scripts/spectra-plus/rules.yaml` lacks a valid `spectraPlusVersion` or `spectraPlusUpdated`
- **WHEN** the user runs repair-all
- **THEN** repair-all exits with a non-zero status
- **AND** stderr names the invalid plus metadata field
- **AND** repair-all does not report the target as current
- **AND** repair-all does not modify the target generated plus skill outputs

#### Scenario: Target with current plus metadata can be skipped

- **GIVEN** source-sensitive paths are clean
- **AND** a registered target project has generated plus skill outputs containing current plus metadata
- **AND** the target also satisfies the existing generated plus skill and `spectra-commit` guard checks
- **WHEN** the user runs repair-all
- **THEN** the target can be reported as already current

### Requirement: Auto-restore stripped commit guard source from git HEAD

The system SHALL allow `install-spectra-plus.fish` to recover automatically when a source `spectra-commit/SKILL.md` file has lost its `SPECTRA-COMMIT-GUARD` block during manual single-target installation. During guard application for `--target`, before failing on an invalid source, the installer MUST attempt to restore that source file from its git `HEAD` version, and MUST do so only under all of these conditions: the working-tree source fails `validate_commit_guard`; the source resides inside a git work tree; and the `HEAD` version of that exact file passes the full `validate_commit_guard` check. Automatic `--repair-all` MUST NOT auto-restore stripped source guard files; it MUST use the dirty-source guard and skip before auto-restore when the stripped source file is dirty. The restore MUST affect only the single source file path (working tree), MUST NOT run an unscoped restore, MUST NOT modify the git index, MUST respect `--dry-run` by reporting without mutating, and MUST log the restore action. When any precondition is not met, the installer MUST fall back to the existing fail-loud behavior unchanged. This recovery applies to both the Claude (`.claude/skills/spectra-commit/SKILL.md`) and Codex (`.agents/skills/spectra-commit/SKILL.md`) source files.

#### Scenario: Self-heal stripped source from valid HEAD

- **GIVEN** the working-tree source `spectra-commit/SKILL.md` is missing a valid `SPECTRA-COMMIT-GUARD` block
- **AND** the file resides in a git work tree whose `HEAD` version of that file passes `validate_commit_guard`
- **WHEN** the user runs `install-spectra-plus.fish --target <project>` and the installer applies the commit guard
- **THEN** the installer restores the source file from `HEAD`
- **AND** logs a message naming the restored file and that it was restored from `HEAD`
- **AND** continues guard application so the run reports success
- **AND** the restored source file again contains a valid guard

#### Scenario: Repair-all skips stripped source instead of restoring

- **GIVEN** the working-tree source `spectra-commit/SKILL.md` is missing a valid `SPECTRA-COMMIT-GUARD` block
- **AND** the file resides in a git work tree whose `HEAD` version of that file passes `validate_commit_guard`
- **WHEN** the user runs `install-spectra-plus.fish --repair-all`
- **THEN** the command exits with status 0
- **AND** the output reports that repair-all was skipped because the source checkout is dirty
- **AND** the installer does not restore the source file from `HEAD`

#### Scenario: HEAD source is also invalid

- **GIVEN** the working-tree source is missing a valid guard
- **AND** the `HEAD` version of that file also fails `validate_commit_guard`
- **WHEN** the user runs `install-spectra-plus.fish --target <project>` and the installer applies the commit guard
- **THEN** the installer does not restore the file
- **AND** exits with a non-zero status with the existing source guard error

#### Scenario: Source is not in a git work tree

- **GIVEN** the working-tree source is missing a valid guard
- **AND** the source does not reside in a git work tree (no git, untracked, or no `HEAD`)
- **WHEN** the user runs `install-spectra-plus.fish --target <project>` and the installer applies the commit guard
- **THEN** the installer does not restore the file
- **AND** falls back to the existing fail-loud behavior with a non-zero status

#### Scenario: Dry-run reports restore without mutating

- **GIVEN** the working-tree source is missing a valid guard and `HEAD` is valid
- **WHEN** the user runs `install-spectra-plus.fish --target <project> --dry-run`
- **THEN** the output reports that it would restore the source file from `HEAD`
- **AND** the source file is not modified
- **AND** no git mutation, lock, cache, or throttle state is written

#### Scenario: Restore is limited to the single source file

- **GIVEN** the working-tree source is missing a valid guard and `HEAD` is valid
- **AND** an unrelated dirty file exists in the same git work tree
- **WHEN** the installer restores the source from `HEAD`
- **THEN** only the single `spectra-commit/SKILL.md` source file is restored
- **AND** the unrelated dirty file remains unchanged
