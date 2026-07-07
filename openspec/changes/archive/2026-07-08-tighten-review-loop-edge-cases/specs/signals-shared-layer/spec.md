## MODIFIED Requirements

### Requirement: Signals shared layer location and file schema

The system SHALL store cross-change signals as individual Markdown files under `openspec/signals/`, one file per signal named `openspec/signals/<slug>.md`. The `<slug>` MUST be a short, human-readable ASCII kebab-case identifier that names the issue class (for example `spec-requirement-no-backing-task`), assigned by the writer when a signal is first created. The `<slug>` MUST NOT be a mechanical transformation of the finding's free-text `location + summary`. The `<slug>` MUST match `^[a-z0-9]+(-[a-z0-9]+)*$` so it is always a valid, non-empty filename. Each signal file MUST begin with a YAML frontmatter block containing exactly these required fields: `id` (equal to the slug), `type` (one of `friction`, `idea`, `gap`, `recurring-finding`), `status` (one of `open`, `addressed`, `dismissed`), `occurrences` (a non-negative integer), `first_seen` (a `YYYY-MM-DD` date), `last_seen` (a `YYYY-MM-DD` date), and `links` (a list of project-root-relative source paths). The frontmatter is additionally permitted to contain exactly one optional field: `check` — a single-line, human-authored shell command executed from the project root by passing its value as the single command-string argument to `sh -c`, where exit code `0` means the signal's anti-pattern is absent, exit code `1` means the anti-pattern is present, and any other exit code is an execution error rather than a detection result. A `check` command MUST be read-only and MUST NOT modify any file. No frontmatter fields other than the seven required fields and the optional `check` are permitted. After the frontmatter, the file MUST contain a title heading, a description paragraph, and a `## Occurrences` section that records one entry per observation.

#### Scenario: Slug is a valid ASCII issue-class identifier

- **WHEN** a signal file `openspec/signals/<slug>.md` is created
- **THEN** the `<slug>` matches `^[a-z0-9]+(-[a-z0-9]+)*$`
- **AND** the `<slug>` is not produced by mechanically transforming the finding's free-text `location + summary`

##### Example: assigned issue-class slugs

| Issue class | Valid slug |
|-------------|------------|
| A spec SHALL has no backing task | `spec-requirement-no-backing-task` |
| An input boundary does not handle empty input | `unhandled-empty-input` |

#### Scenario: Signal file has required frontmatter and occurrences section

- **WHEN** a signal file `openspec/signals/<slug>.md` is created
- **THEN** its frontmatter contains `id`, `type`, `status`, `occurrences`, `first_seen`, `last_seen`, and `links`
- **AND** `id` equals `<slug>`
- **AND** `type` is one of `friction`, `idea`, `gap`, `recurring-finding`
- **AND** `status` is one of `open`, `addressed`, `dismissed`
- **AND** the body contains a `## Occurrences` section with at least one entry

##### Example: minimal signal file

- **GIVEN** a recurring review finding about exported file handling
- **WHEN** the signal is first created on 2026-06-21
- **THEN** the file frontmatter has `id: export-file-handling`, `type: recurring-finding`, `status: open`, `occurrences: 1`, `first_seen: 2026-06-21`, `last_seen: 2026-06-21`
- **AND** the `## Occurrences` section has one dated entry naming the source change and round file

#### Scenario: Optional check field carries a deterministic detection command

- **WHEN** a signal file's frontmatter contains the optional `check` field
- **THEN** its value is a single-line, human-authored shell command runnable from the project root via `sh -c`
- **AND** exit code `0` means the anti-pattern is absent, exit code `1` means the anti-pattern is present, and any other exit code is an execution error
- **AND** the command is read-only and does not modify any file

##### Example: check command for a dangling annotation anti-pattern

- **GIVEN** a signal about unclosed `@trace` annotation blocks in spec files
- **WHEN** the signal author adds a deterministic detection command
- **THEN** the frontmatter contains a line such as `check: 'out=$(grep -rln ANNOTATION-OPEN-MARKER openspec/specs/ 2>&1); c=$?; if [ $c -eq 0 ]; then printf "%s\n" "$out"; exit 1; elif [ $c -eq 1 ]; then exit 0; else printf "%s\n" "$out" >&2; exit 2; fi'` — run as the single argument to `sh -c`, it prints the matching project-root-relative paths and exits `1` when the anti-pattern is present, exits `0` when it is absent, and exits `2` when grep itself errored (for example a missing path), so execution errors are never misread as detection results

### Requirement: Signals directory README contract

The system SHALL provide `openspec/signals/README.md` that documents the signals layer. The README MUST describe what belongs in the signals layer, what does not belong, the signal file schema, the rule that a `<slug>` is an assigned issue-class identifier (not a transform of finding text), and the process for adding or updating a signal. The README MUST document the optional `check` frontmatter field: its single-line shell command form, its execution by passing the value as the single argument to `sh -c` from the project root, the exit-code convention (`0` means the anti-pattern is absent, `1` means it is present, any other exit code is an execution error), the rule that `check` commands are human-authored, the authoring rules that `check` commands MUST be read-only, fast, offline, and non-interactive, the rule that detection results are reported only as exit `0` or `1` while foreseeable execution errors (such as a missing path) MUST surface as another exit code rather than being collapsed into `0` or `1` by blind negation, and the YAML single-line quoting pitfalls (quotes and `#` truncation) for the field value. The README MUST document that newly authored `check` commands that can identify concrete instances print project-root-relative paths for detected instances, so plus review loops can classify whether a failure lies in the current change's artifacts or modified files. The README MUST document shell error traps for `check` authors: POSIX `sh` does not provide `pipefail`, pipeline status comes from the last command, and tools whose native exit code `1` means an execution error require explicit exit-code remapping so `1` remains reserved for anti-pattern-present results. The README MUST state that signal `status` transitions to `addressed` or `dismissed` are performed manually by a human and are never applied automatically. The README MUST document that a writer coining a new `<slug>` first lists existing `openspec/signals/*.md` and picks a slug that does not already exist, and that creating a signal never overwrites an existing file. The README MUST note the concurrent full-file-overwrite risk: when two runs write the same `<slug>.md` at once — including two runs independently coining the same natural slug for a new issue class — the losing writer's appended `## Occurrences` entry and `links`, or an entire newly created signal, can be lost; and a reviewer SHALL split a signal whose `## Occurrences` entries describe unrelated issues.

#### Scenario: README documents schema, slug assignment, and human-maintained status

- **WHEN** `openspec/signals/README.md` is read
- **THEN** it describes the inclusion and exclusion rules for signals
- **AND** it documents the frontmatter schema fields
- **AND** it documents the optional `check` field, its `sh -c` single-argument execution form, its exit-code convention, the human-authored, read-only, fast, offline, non-interactive authoring rules, the rule that execution errors surface as an exit code other than `0` or `1`, and the YAML quoting pitfalls
- **AND** it documents that newly authored `check` commands that can identify concrete instances print project-root-relative paths for detected instances
- **AND** it documents POSIX `sh` pipeline status behavior and exit-code remapping guidance for tools whose native exit code `1` means execution error
- **AND** it documents that `<slug>` is an assigned issue-class identifier, not a transform of finding text
- **AND** it states that `addressed` and `dismissed` status transitions are manual
- **AND** it notes the concurrent overwrite lost-entry risk and the manual split guidance
