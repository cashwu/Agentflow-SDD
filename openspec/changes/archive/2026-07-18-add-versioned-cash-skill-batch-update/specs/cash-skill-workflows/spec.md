## ADDED Requirements

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

## MODIFIED Requirements

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
