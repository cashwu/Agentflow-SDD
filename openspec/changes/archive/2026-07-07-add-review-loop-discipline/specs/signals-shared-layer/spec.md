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
- **THEN** the frontmatter contains a line such as `check: "grep -rq ANNOTATION-OPEN-MARKER openspec/specs/; c=$?; if [ $c -eq 0 ]; then exit 1; elif [ $c -eq 1 ]; then exit 0; else exit 2; fi"` — run as the single argument to `sh -c`, it exits `1` when the anti-pattern is present, `0` when it is absent, and `2` when grep itself errored (for example a missing path), so execution errors are never misread as detection results

### Requirement: Signals directory README contract

The system SHALL provide `openspec/signals/README.md` that documents the signals layer. The README MUST describe what belongs in the signals layer, what does not belong, the signal file schema, the rule that a `<slug>` is an assigned issue-class identifier (not a transform of finding text), and the process for adding or updating a signal. The README MUST document the optional `check` frontmatter field: its single-line shell command form, its execution by passing the value as the single argument to `sh -c` from the project root, the exit-code convention (`0` means the anti-pattern is absent, `1` means it is present, any other exit code is an execution error), the rule that `check` commands are human-authored, the authoring rules that `check` commands MUST be read-only, fast, offline, and non-interactive, the rule that detection results are reported only as exit `0` or `1` while foreseeable execution errors (such as a missing path) MUST surface as another exit code rather than being collapsed into `0` or `1` by blind negation, and the YAML single-line quoting pitfalls (quotes and `#` truncation) for the field value. The README MUST state that signal `status` transitions to `addressed` or `dismissed` are performed manually by a human and are never applied automatically. The README MUST document that a writer coining a new `<slug>` first lists existing `openspec/signals/*.md` and picks a slug that does not already exist, and that creating a signal never overwrites an existing file. The README MUST note the concurrent full-file-overwrite risk: when two runs write the same `<slug>.md` at once — including two runs independently coining the same natural slug for a new issue class — the losing writer's appended `## Occurrences` entry and `links`, or an entire newly created signal, can be lost; and a reviewer SHALL split a signal whose `## Occurrences` entries describe unrelated issues.

#### Scenario: README documents schema, slug assignment, and human-maintained status

- **WHEN** `openspec/signals/README.md` is read
- **THEN** it describes the inclusion and exclusion rules for signals
- **AND** it documents the frontmatter schema fields
- **AND** it documents the optional `check` field, its `sh -c` single-argument execution form, its exit-code convention, the human-authored, read-only, fast, offline, non-interactive authoring rules, the rule that execution errors surface as an exit code other than `0` or `1`, and the YAML quoting pitfalls
- **AND** it documents that `<slug>` is an assigned issue-class identifier, not a transform of finding text
- **AND** it states that `addressed` and `dismissed` status transitions are manual
- **AND** it notes the concurrent overwrite lost-entry risk and the manual split guidance

### Requirement: Signal status lifecycle is human-maintained

The system SHALL treat signal `status` and the optional `check` field as human-maintained. Automated writers MAY create a new signal with `status: open` and MAY update an existing `open` signal's `occurrences`, `last_seen`, `links`, and `## Occurrences` entries, but MUST NOT change a signal's `status` value and MUST NOT add, modify, or remove a signal's `check` field. Transitioning a signal to `addressed` or `dismissed`, and authoring or editing a `check` command, MUST be a manual human action.

#### Scenario: Automated update preserves status

- **WHEN** an automated writer updates an existing `open` signal because the underlying issue was observed again
- **THEN** the writer increments `occurrences`, updates `last_seen`, appends an `## Occurrences` entry, and appends to `links`
- **AND** the writer does not change the `status` field

#### Scenario: Automated writer does not reopen resolved signals

- **WHEN** a signal already has `status: addressed` or `status: dismissed`
- **THEN** an automated writer does not change its `status` back to `open`

#### Scenario: Automated writer never authors a check command

- **WHEN** an automated writer creates a new signal or updates an existing one (including the review-loop signals write step)
- **THEN** the written signal contains no `check` field unless a human previously authored it
- **AND** any pre-existing human-authored `check` field is left byte-identical
