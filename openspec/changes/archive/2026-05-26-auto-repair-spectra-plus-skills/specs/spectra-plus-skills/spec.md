## ADDED Requirements

### Requirement: Multi-project plus skill target registry

The system SHALL provide a registry of project targets whose Spectra plus skills are maintained automatically. The registry MUST store explicit user-registered project paths and MUST NOT discover or modify projects outside the registry.

#### Scenario: Register target project

- **WHEN** the user registers a target project path
- **THEN** the system stores the target as a normalized absolute path in the registry
- **AND** registering the same target again leaves the registry with one entry for that target

##### Example: duplicate registration

- **GIVEN** the registry already contains `/Users/cash.wu/github/Agentflow-SDD`
- **WHEN** the user registers `/Users/cash.wu/github/Agentflow-SDD` again
- **THEN** the registry still contains exactly one `/Users/cash.wu/github/Agentflow-SDD` entry

#### Scenario: Reject invalid target registration

- **WHEN** the user registers a target project path that does not exist or is not a directory
- **THEN** the system exits with a non-zero status
- **AND** reports that the target project directory is invalid
- **AND** does not create, remove, or modify the registry file

##### Example: nonexistent target

- **GIVEN** the registry contains `/Users/cash.wu/github/Agentflow-SDD`
- **WHEN** the user registers `/tmp/missing-spectra-project`
- **THEN** registration fails
- **AND** the registry still contains only `/Users/cash.wu/github/Agentflow-SDD`

#### Scenario: Dry-run registry update

- **WHEN** the user registers or unregisters a target project in dry-run mode
- **THEN** the system prints the registry update it would perform
- **AND** does not create, remove, or modify the registry file

#### Scenario: Unregister target project

- **WHEN** the user unregisters a target project path
- **THEN** the system removes the normalized absolute path from the registry
- **AND** unregistering a path that is not present succeeds without modifying other entries
- **AND** the target project path is not required to exist on disk

##### Example: remove stale target

- **GIVEN** the registry contains `/tmp/deleted-spectra-project`
- **AND** `/tmp/deleted-spectra-project` no longer exists on disk
- **WHEN** the user unregisters `/tmp/deleted-spectra-project`
- **THEN** the registry no longer contains `/tmp/deleted-spectra-project`

#### Scenario: List registered targets

- **WHEN** the user lists registered targets
- **THEN** the system prints registry entries as normalized absolute paths
- **AND** ignores blank lines and comment lines in the registry file

### Requirement: Repair all registered plus skill targets

The system SHALL provide a repair-all operation that restores generated plus skills and `spectra-commit` guard behavior for every registered target. The repair-all operation MUST reuse the same installation and validation behavior as single-target installation.

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
- **THEN** the system lists the target repair actions it would perform
- **AND** does not modify any registered target project
- **AND** does not create or update lock, cache, or throttle state files

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
