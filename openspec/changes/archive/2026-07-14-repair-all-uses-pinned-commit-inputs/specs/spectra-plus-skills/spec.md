## ADDED Requirements

### Requirement: Repair-all uses pinned commit inputs

The system SHALL resolve one commit from the source checkout at the start of repair-all and SHALL use a snapshot of that commit for every shared input that determines generated target content. The pinned shared inputs MUST include the installer entrypoint, the plus generator, the plus metadata rules, the plus templates, and both `spectra-commit` guard sources. The repair-all parent process MUST obtain metadata validation and every per-target current-state verdict from the pinned snapshot, and every stale target MUST be installed by the same pinned snapshot entrypoint. The source checkout working tree MUST NOT be used as a shared content input and MUST NOT block repair-all because it is dirty.

The pinned current-state interface MUST report current with exit status 0, stale with exit status 10, and inability to determine state with any other non-zero status. Repair-all MUST NOT treat an inability to determine state as stale. Snapshot resolution, creation, archive, extraction, or metadata failure MUST terminate repair-all with a non-zero status before any registered target is processed. Repair-all MUST remove the snapshot it owns after normal completion, dry-run completion, or handled failure.

#### Scenario: Dirty source checkout does not block target repair

- **GIVEN** a registered target is missing a generated plus skill
- **AND** the source checkout has an uncommitted change under a former source-sensitive path
- **WHEN** the user runs `install-spectra-plus.fish --repair-all`
- **THEN** repair-all does not output a dirty-source skip
- **AND** repair-all repairs the registered target from the pinned commit inputs

#### Scenario: Working-tree metadata does not affect repair-all

- **GIVEN** the pinned commit contains valid plus metadata
- **AND** the working-tree `scripts/spectra-plus/rules.yaml` contains invalid uncommitted metadata
- **AND** a registered target is stale
- **WHEN** the user runs `install-spectra-plus.fish --repair-all`
- **THEN** repair-all validates metadata from the pinned snapshot
- **AND** repair-all repairs the target with metadata from the pinned commit
- **AND** repair-all does not report the working-tree metadata as invalid

#### Scenario: Current verdict and installed content converge

- **GIVEN** a registered target is stale
- **WHEN** repair-all checks and installs that target from one pinned commit
- **THEN** the first run repairs the target
- **AND** an immediate second run at the same commit reports the target as already current
- **AND** the second run does not install the target again

#### Scenario: Current-state execution error is not stale

- **GIVEN** the pinned installer cannot execute the `--check-current` contract for a registered target
- **WHEN** the user runs repair-all
- **THEN** repair-all reports that target as failed
- **AND** repair-all does not invoke pinned installation for that target
- **AND** repair-all exits with a non-zero status after processing the remaining registered targets

#### Scenario: Snapshot failure stops before target processing

- **GIVEN** repair-all cannot resolve, create, archive, extract, or validate its pinned snapshot
- **WHEN** the user runs repair-all
- **THEN** repair-all exits with a non-zero status
- **AND** repair-all does not process or modify any registered target
- **AND** repair-all does not create or update repair lock or throttle state
- **AND** no snapshot owned by that run remains after the handled failure

#### Scenario: Dry-run uses pinned current-state checks

- **GIVEN** the source checkout has uncommitted changes to shared input files
- **WHEN** the user runs `install-spectra-plus.fish --repair-all --dry-run`
- **THEN** repair-all obtains each current-state verdict from the pinned snapshot
- **AND** repair-all reports already current, would repair, or failed according to the three-state contract
- **AND** repair-all exits with a non-zero status when any current-state check fails
- **AND** repair-all does not install any target
- **AND** repair-all does not create or update lock, cache, throttle, or registry state
- **AND** no snapshot owned by that run remains

## MODIFIED Requirements

### Requirement: Repair all registered plus skill targets

The system SHALL provide a repair-all operation that restores generated plus skills and `spectra-commit` guard behavior for every registered target. The repair-all operation MUST reuse the same installation and validation behavior as single-target installation while reading shared content inputs from one pinned commit. A dirty source checkout MUST NOT prevent registered target processing.

#### Scenario: Repair multiple reset targets

- **GIVEN** the registry contains two valid project targets
- **AND** each target is missing at least one generated plus skill or required `spectra-commit` guard content
- **WHEN** the user runs repair-all
- **THEN** the system repairs both targets
- **AND** each target contains `spectra-propose-plus`, `spectra-apply-plus`, and the required `spectra-commit` guard after repair-all completes

#### Scenario: Ignore unregistered project targets

- **GIVEN** the registry contains one reset project target
- **AND** another reset project exists on disk but is not listed in the registry
- **WHEN** the user runs repair-all
- **THEN** the system repairs only the registered target
- **AND** does not modify the unregistered project's skill files or guard content

##### Example: registered target only

- **GIVEN** the registry contains `/tmp/registered-project`
- **AND** `/tmp/unregistered-project` is missing `spectra-propose-plus`
- **WHEN** the user runs repair-all
- **THEN** `/tmp/registered-project` is repaired
- **AND** `/tmp/unregistered-project/.agents/skills/spectra-propose-plus/SKILL.md` remains absent

#### Scenario: Continue after one target fails

- **GIVEN** the registry contains one invalid target and one valid target
- **WHEN** the user runs repair-all
- **THEN** the system reports the invalid target failure
- **AND** still attempts to repair the valid target
- **AND** exits with a non-zero status after processing all registered targets

#### Scenario: Dry-run repair-all

- **WHEN** the user runs repair-all in dry-run mode
- **THEN** the system uses pinned current-state checks to list the target repair actions it would perform
- **AND** does not modify any registered target project
- **AND** does not create or update lock, cache, throttle, or registry state files

##### Example: dry-run leaves state untouched

- **GIVEN** `HOME=/tmp/home` and `TMPDIR=/tmp/run`
- **WHEN** the user runs repair-all in dry-run mode
- **THEN** `/tmp/home/.cache/spectra-plus/last-repair-attempt` is not created or modified
- **AND** `/tmp/run/spectra-plus-repair.lock` is not created or modified

#### Scenario: Per-target repair summary

- **WHEN** repair-all processes registered targets
- **THEN** the system prints a per-target summary for each success, skipped, and failed target
- **AND** exits with a non-zero status when any target fails after all registered targets have been processed

### Requirement: LaunchAgent-based automatic plus skill repair

The system SHALL provide a macOS LaunchAgent installation flow that runs repair-all for registered targets without modifying `/Applications/Spectra.app`. The LaunchAgent installation MUST be reversible and MUST be safe to run repeatedly. The LaunchAgent execution path MUST use a controlled environment that can locate required commands or report missing commands through predictable logs.

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

- **WHEN** the LaunchAgent invokes repair-all repeatedly
- **THEN** repair-all prevents overlapping executions with a lock
- **AND** repair-all respects a throttle window that is not greater than the LaunchAgent `StartInterval`
- **AND** repair-all cleans up its own lock after normal exit or handled failure

#### Scenario: Throttle after failed repair attempt

- **GIVEN** repair-all processed an invalid registered target and exited with a non-zero status
- **WHEN** repair-all is invoked again within the throttle window without force
- **THEN** the system skips the repeated repair attempt
- **AND** reports the throttle decision without modifying registered target projects

#### Scenario: Stale lock can recover

- **GIVEN** a repair-all lock exists from an earlier interrupted process and is older than the stale lock threshold
- **WHEN** the user runs repair-all
- **THEN** the system treats the stale lock as recoverable
- **AND** proceeds with the repair attempt or reports a clear manual cleanup instruction

### Requirement: Auto-restore stripped commit guard source from git HEAD

The system SHALL allow `install-spectra-plus.fish` to recover automatically when a source `spectra-commit/SKILL.md` file has lost its `SPECTRA-COMMIT-GUARD` block during manual single-target installation. During guard application for `--target`, before failing on an invalid source, the installer MUST attempt to restore that source file from its git `HEAD` version, and MUST do so only under all of these conditions: the working-tree source fails `validate_commit_guard`; the source resides inside a git work tree; and the `HEAD` version of that exact file passes the full `validate_commit_guard` check. Automatic `--repair-all` MUST NOT auto-restore a working-tree guard source as a source input; its delegated installation MUST read guard sources from the pinned snapshot. The restore MUST affect only the single source file path in the working tree, MUST NOT run an unscoped restore, MUST NOT modify the git index, MUST respect `--dry-run` by reporting without mutating, and MUST log the restore action. When any precondition is not met, the installer MUST fall back to the existing fail-loud behavior unchanged. This recovery applies to both the Claude (`.claude/skills/spectra-commit/SKILL.md`) and Codex (`.agents/skills/spectra-commit/SKILL.md`) source files.

#### Scenario: Self-heal stripped source from valid HEAD

- **GIVEN** the working-tree source `spectra-commit/SKILL.md` is missing a valid `SPECTRA-COMMIT-GUARD` block
- **AND** the file resides in a git work tree whose `HEAD` version of that file passes `validate_commit_guard`
- **WHEN** the user runs `install-spectra-plus.fish --target <project>` and the installer applies the commit guard
- **THEN** the installer restores the source file from `HEAD`
- **AND** logs a message naming the restored file and that it was restored from `HEAD`
- **AND** continues guard application so the run reports success
- **AND** the restored source file again contains a valid guard

#### Scenario: Repair-all reads pinned guard sources without restoring the working tree

- **GIVEN** the working-tree source `spectra-commit/SKILL.md` is missing a valid `SPECTRA-COMMIT-GUARD` block
- **AND** the pinned commit contains a valid guard source
- **AND** the source checkout is not a registered target
- **WHEN** the user runs `install-spectra-plus.fish --repair-all`
- **THEN** repair-all uses the pinned guard source for registered target installation
- **AND** repair-all does not restore or modify the working-tree guard source

#### Scenario: HEAD source is also invalid

- **GIVEN** the working-tree source is missing a valid guard
- **AND** the `HEAD` version of that file also fails `validate_commit_guard`
- **WHEN** the user runs `install-spectra-plus.fish --target <project>` and the installer applies the commit guard
- **THEN** the installer does not restore the file
- **AND** exits with a non-zero status with the existing source guard error

#### Scenario: Source is not in a git work tree

- **GIVEN** the working-tree source is missing a valid guard
- **AND** the source does not reside in a git work tree with a tracked `HEAD`
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

### Requirement: Repair checks plus metadata freshness

The installer and repair-all current-state checks SHALL treat plus skill metadata as part of the generated output freshness contract. For direct single-target installation, the current `spectraPlusVersion` and `spectraPlusUpdated` values SHALL be read from the working-tree `scripts/spectra-plus/rules.yaml` adjacent to the executing installer. For repair-all, those values and every content assertion used to determine current state MUST be read by the pinned snapshot installer. A target project SHALL be current only when every generated plus skill output top-level YAML frontmatter contains the pinned `spectraPlusVersion` and `spectraPlusUpdated` values. Scenarios and examples in this specification MUST reference the values declared in `scripts/spectra-plus/rules.yaml` instead of hard-coding version or date literals; regression tests MUST pin the currently declared values as synchronized literals, updated on each bump.

#### Scenario: Target missing plus metadata is stale

- **GIVEN** a registered target project has generated plus skill outputs without `spectraPlusVersion`
- **WHEN** the user runs repair-all
- **THEN** the target is treated as stale
- **AND** repair-all rewrites the generated plus skill outputs with pinned current metadata

#### Scenario: Target with old plus metadata is stale

- **GIVEN** a registered target project has generated plus skill outputs containing a `spectraPlusVersion` different from the value declared in the pinned `scripts/spectra-plus/rules.yaml`
- **WHEN** the user runs repair-all
- **THEN** the target is treated as stale
- **AND** repair-all rewrites the generated plus skill outputs with the `spectraPlusVersion` declared in the pinned `scripts/spectra-plus/rules.yaml`
- **AND** repair-all rewrites the generated plus skill outputs with the `spectraPlusUpdated` declared in the pinned `scripts/spectra-plus/rules.yaml`

#### Scenario: Target with old updated date metadata is stale

- **GIVEN** a registered target project has generated plus skill outputs containing a `spectraPlusUpdated` different from the value declared in the pinned `scripts/spectra-plus/rules.yaml`
- **WHEN** the user runs repair-all
- **THEN** the target is treated as stale
- **AND** repair-all rewrites the generated plus skill outputs with the `spectraPlusUpdated` declared in the pinned `scripts/spectra-plus/rules.yaml`

#### Scenario: Target with one stale generated variant is stale

- **GIVEN** a registered target project has one generated plus skill output with stale plus metadata
- **AND** the other generated plus skill outputs contain pinned current plus metadata
- **WHEN** the user runs repair-all
- **THEN** the target is treated as stale
- **AND** repair-all rewrites every generated plus skill output with pinned current plus metadata

#### Scenario: Pinned rules metadata parse failure aborts repair

- **GIVEN** the pinned `scripts/spectra-plus/rules.yaml` lacks a valid `spectraPlusVersion` or `spectraPlusUpdated`
- **WHEN** the user runs repair-all
- **THEN** repair-all exits with a non-zero status
- **AND** stderr names the invalid plus metadata field
- **AND** repair-all does not report any target as current
- **AND** repair-all does not modify target generated plus skill outputs

#### Scenario: Target with current plus metadata is skipped

- **GIVEN** a registered target project has generated plus skill outputs containing pinned current plus metadata
- **AND** the target also satisfies the generated plus skill and `spectra-commit` guard checks from the pinned installer
- **WHEN** the user runs repair-all
- **THEN** the target is reported as already current

#### Scenario: Uncommitted working-tree rules do not change repair-all freshness

- **GIVEN** the working-tree `scripts/spectra-plus/rules.yaml` differs from the pinned commit
- **AND** the pinned rules contain valid plus metadata
- **WHEN** the user runs repair-all
- **THEN** metadata validation and target freshness use the pinned rules
- **AND** the working-tree rules do not cause metadata failure or repeated target installation

## REMOVED Requirements

### Requirement: Repair-all protects registered targets from dirty source checkout

**Reason**: The dirty-source guard is the cause of an unbounded repair deadlock. Shared inputs are now read directly from a pinned commit, so working-tree cleanliness is neither required nor a valid reason to skip registered targets.

**Migration**: No caller action is required. `--repair-all` no longer inspects source-sensitive working-tree paths or emits `[skipped] dirty source checkout`. Uncommitted shared-input changes do not affect repair-all until they are committed. Direct `--target` behavior remains unchanged.

#### Scenario: Dirty working tree no longer triggers the removed guard

- **GIVEN** the source checkout contains uncommitted changes
- **WHEN** the user runs `install-spectra-plus.fish --repair-all`
- **THEN** repair-all does not invoke the removed dirty-source guard
- **AND** repair-all processes registered targets from pinned commit inputs
