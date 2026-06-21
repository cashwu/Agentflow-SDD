## ADDED Requirements

### Requirement: Plus review loop writes signals after the loop ends

The system SHALL extend the shared review-loop template `scripts/spectra-plus/template/review-loop-block.md` so that, after the review loop ends (the round file `decision` is `passed` or `aborted`), the main agent writes signals for the post-filter findings the loop surfaced. The signal-writing step MUST be marked in the template with the unique sentinel comment `<!-- SIGNALS-WRITE-STEP -->`. This step MUST run only after the loop's mechanical decision is already recorded, and MUST NOT change the `decision` of any round file. Because both `spectra-propose-plus` and `spectra-apply-plus` consume this template, this behavior MUST apply to both generated plus skills.

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

#### Scenario: Signal write failure does not fail the plus workflow

- **WHEN** writing a signal under `openspec/signals/` fails
- **THEN** the main agent prints a warning
- **AND** the plus workflow does not fail solely because of the signal write failure

### Requirement: spectra-propose-plus reads open signals for prioritization

The system SHALL add a propose-plus-specific transformation in `scripts/spectra-plus/rules.yaml` and a template `scripts/spectra-plus/template/signals-read-block.md` so that `spectra-propose-plus` reads `open` signals under `openspec/signals/` after the existing "Scan existing specs for relevance" step. The read step MUST be marked in the template with the unique sentinel comment `<!-- SIGNALS-READ-STEP -->`. The read MUST be informational: the skill SHALL surface relevant `open` signals as a prioritization summary, MUST NOT block the workflow, MUST NOT require user confirmation, and MUST NOT modify any signal. When `openspec/signals/` is absent or contains no `open` signal, the skill MUST continue silently. This read behavior MUST NOT be added to `spectra-apply-plus`.

#### Scenario: Relevant open signals are surfaced during propose-plus

- **WHEN** `spectra-propose-plus` runs and `openspec/signals/` contains `open` signals relevant to the requirement
- **THEN** the skill displays those signals as an informational prioritization summary after the spec scan step
- **AND** the skill does not modify any signal
- **AND** the skill does not require user confirmation to continue

#### Scenario: No open signals continues silently

- **WHEN** `spectra-propose-plus` runs and `openspec/signals/` is absent or has no `open` signal
- **THEN** the skill continues without surfacing a signals summary

#### Scenario: apply-plus does not gain the read step

- **WHEN** the generator produces `.claude/skills/spectra-apply-plus/SKILL.md` and `.agents/skills/spectra-apply-plus/SKILL.md`
- **THEN** the apply-plus skill files do not contain the `<!-- SIGNALS-READ-STEP -->` sentinel
- **AND** the apply-plus skill files do contain the `<!-- SIGNALS-WRITE-STEP -->` sentinel from the shared review-loop template

#### Scenario: propose-plus contains both read and write steps

- **WHEN** the generator produces `.claude/skills/spectra-propose-plus/SKILL.md` and `.agents/skills/spectra-propose-plus/SKILL.md`
- **THEN** the propose-plus skill files contain both the `<!-- SIGNALS-READ-STEP -->` and `<!-- SIGNALS-WRITE-STEP -->` sentinels
- **AND** each file retains the top-of-file `<!-- Generated by scripts/spectra-plus/generate.fish — DO NOT EDIT MANUALLY -->` marker
