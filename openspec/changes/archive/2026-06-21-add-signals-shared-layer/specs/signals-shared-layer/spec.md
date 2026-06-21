## ADDED Requirements

### Requirement: Signals shared layer location and file schema

The system SHALL store cross-change signals as individual Markdown files under `openspec/signals/`, one file per signal named `openspec/signals/<slug>.md`. The `<slug>` MUST be a short, human-readable ASCII kebab-case identifier that names the issue class (for example `spec-requirement-no-backing-task`), assigned by the writer when a signal is first created. The `<slug>` MUST NOT be a mechanical transformation of the finding's free-text `location + summary`. The `<slug>` MUST match `^[a-z0-9]+(-[a-z0-9]+)*$` so it is always a valid, non-empty filename. Each signal file MUST begin with a YAML frontmatter block containing exactly these fields: `id` (equal to the slug), `type` (one of `friction`, `idea`, `gap`, `recurring-finding`), `status` (one of `open`, `addressed`, `dismissed`), `occurrences` (a non-negative integer), `first_seen` (a `YYYY-MM-DD` date), `last_seen` (a `YYYY-MM-DD` date), and `links` (a list of project-root-relative source paths). After the frontmatter, the file MUST contain a title heading, a description paragraph, and a `## Occurrences` section that records one entry per observation.

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

### Requirement: Signals directory README contract

The system SHALL provide `openspec/signals/README.md` that documents the signals layer. The README MUST describe what belongs in the signals layer, what does not belong, the signal file schema, the rule that a `<slug>` is an assigned issue-class identifier (not a transform of finding text), and the process for adding or updating a signal. The README MUST state that signal `status` transitions to `addressed` or `dismissed` are performed manually by a human and are never applied automatically. The README MUST document that a writer coining a new `<slug>` first lists existing `openspec/signals/*.md` and picks a slug that does not already exist, and that creating a signal never overwrites an existing file. The README MUST note the concurrent full-file-overwrite risk: when two runs write the same `<slug>.md` at once — including two runs independently coining the same natural slug for a new issue class — the losing writer's appended `## Occurrences` entry and `links`, or an entire newly created signal, can be lost; and a reviewer SHALL split a signal whose `## Occurrences` entries describe unrelated issues.

#### Scenario: README documents schema, slug assignment, and human-maintained status

- **WHEN** `openspec/signals/README.md` is read
- **THEN** it describes the inclusion and exclusion rules for signals
- **AND** it documents the frontmatter schema fields
- **AND** it documents that `<slug>` is an assigned issue-class identifier, not a transform of finding text
- **AND** it states that `addressed` and `dismissed` status transitions are manual
- **AND** it notes the concurrent overwrite lost-entry risk and the manual split guidance

### Requirement: Signal status lifecycle is human-maintained

The system SHALL treat signal `status` as human-maintained. Automated writers MAY create a new signal with `status: open` and MAY update an existing `open` signal's `occurrences`, `last_seen`, `links`, and `## Occurrences` entries, but MUST NOT change a signal's `status` value. Transitioning a signal to `addressed` or `dismissed` MUST be a manual human action.

#### Scenario: Automated update preserves status

- **WHEN** an automated writer updates an existing `open` signal because the underlying issue was observed again
- **THEN** the writer increments `occurrences`, updates `last_seen`, appends an `## Occurrences` entry, and appends to `links`
- **AND** the writer does not change the `status` field

#### Scenario: Automated writer does not reopen resolved signals

- **WHEN** a signal already has `status: addressed` or `status: dismissed`
- **THEN** an automated writer does not change its `status` back to `open`
