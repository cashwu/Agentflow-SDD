## ADDED Requirements

### Requirement: Review loop grader immutability

The system SHALL extend the shared review-loop template `scripts/spectra-plus/template/review-loop-block.md` with a grader-immutability rule marked by the unique sentinel comment `<!-- GRADER-IMMUTABILITY -->`. During a plus review loop, the main agent MUST NOT modify — whether as a fix action or as a mechanical self-check fix — any file in the protected grader path set: files under `scripts/spectra-plus/template/`, `scripts/spectra-plus/rules.yaml`, `scripts/spectra-plus/generate.fish`, the generated plus skill files (`.claude/skills/spectra-propose-plus/SKILL.md`, `.claude/skills/spectra-apply-plus/SKILL.md`, `.agents/skills/spectra-propose-plus/SKILL.md`, `.agents/skills/spectra-apply-plus/SKILL.md`), `.spectra.yaml`, and the master spec files under `openspec/specs/` — unless that file is explicitly named in the current change's proposal `## Impact` section or in its `tasks.md`. A file counts as explicitly named only when its project-root-relative path appears verbatim; naming a directory path names all files under it. When a file under `scripts/spectra-plus/template/` is named in the declared scope, its regenerated outputs (the four generated plus skill files) count as named as well, so the mandatory regeneration step is never blocked by this rule; a loop already in progress continues under the instruction version it started with, and regenerated instructions take effect from the next loop run. In addition, the main agent MUST NOT add, modify, or remove the `check` frontmatter field of any signal under `openspec/signals/`, regardless of declared scope — the `check` field is grader input for the pre-round mechanical self-check. When a surviving finding's resolution would require modifying a protected file outside that declared scope (or touching a signal's `check` field), the fix action MUST NOT perform the modification, MUST record an unfixed-due-to-grader-protection note naming the file and the finding in `## Fix Actions`, and the finding remains surviving for the round decision. The plus workflow's completion summary MUST list every unfixed-due-to-grader-protection note recorded in any round of the loop, regardless of the final decision. A protected file modified under the declared-scope exception remains subject to the existing next-round re-derivation rules. Because both `spectra-propose-plus` and `spectra-apply-plus` consume this template, this rule MUST apply to both generated plus skills.

#### Scenario: Out-of-scope grader modification is refused

- **WHEN** a review-loop finding's recommendation requires editing `scripts/spectra-plus/rules.yaml` and the current change's proposal `## Impact` and `tasks.md` do not name that file
- **THEN** the fix action does not modify `scripts/spectra-plus/rules.yaml`
- **AND** the round file's `## Fix Actions` records an unfixed-due-to-grader-protection note naming the file and the finding
- **AND** the finding still counts toward the round decision

#### Scenario: Signal check field is never modified by a fix action

- **WHEN** a pre-round self-check `check` command fails and a fix action could make it pass by weakening or removing that signal's `check` field
- **THEN** the fix action does not add, modify, or remove any signal's `check` field
- **AND** the underlying defect is fixed in the change's own artifacts or files instead

#### Scenario: Declared-scope grader file stays modifiable

- **WHEN** the current change's proposal `## Impact` explicitly names `scripts/spectra-plus/template/review-loop-block.md` and a fix action modifies that file
- **THEN** the modification is permitted, and regenerating the four plus skill files is also permitted
- **AND** the existing re-derivation rules treat the modification like any other fix-action modification

#### Scenario: Completion summary surfaces withheld findings even on pass

- **WHEN** any round of a loop recorded an unfixed-due-to-grader-protection note and the loop later ends with `decision: passed`
- **THEN** the plus workflow's completion summary lists every such note from every round of the loop

#### Scenario: Generated skills carry the grader-immutability sentinel

- **WHEN** the generator produces the four plus skill files
- **THEN** each generated file contains the `<!-- GRADER-IMMUTABILITY -->` sentinel and the protected grader path set
- **AND** `scripts/spectra-plus/tests/generator-checks.fish` asserts the sentinel's presence

### Requirement: Review loop ledger output

The system SHALL extend the shared review-loop template with a ledger step marked by the unique sentinel comment `<!-- LOOP-LEDGER-STEP -->`. For each round, the main agent MUST append exactly one row to `openspec/changes/<change>/reviews/loop-ledger.tsv` at a deterministic point: for a `next_round` round, immediately before spawning the next round's reviewers — after every action that can write to the round file's `## Fix Actions` has completed, including fix actions, post-fix self-check records, validation re-run fix records, and any re-derivation note; for the final round (`passed` or `aborted`), at loop end before the signals write step. When the file does not exist, the main agent MUST create it with a single header row before appending; the header row MUST contain exactly the seven column names in order, tab-separated: `skill`, `round`, `round_type`, `criticals`, `warnings`, `decision`, `fixed_files`. Each row MUST contain, tab-separated and in this order: `skill` (`propose` or `apply`), `round` (1-based integer), `round_type` (`full` or `micro`), `criticals` (surviving Critical count, `0` when no post-filter findings exist, including rounds aborted by sub-agent failure), `warnings` (surviving Warning count, `0` likewise), `decision` (`passed`, `next_round`, or `aborted`), and `fixed_files` (the number of distinct files recorded as modified in that round's `## Fix Actions`, `0` when none are recorded; note lines such as fallback or grader-protection notes do not count). The ledger is an append-only event log: rows from the propose loop, the apply loop, and any re-run loop after an abort accumulate chronologically in the same file, and `(skill, round)` is NOT a unique key — duplicate round numbers from re-runs are valid. Round files remain the authoritative record; on any inconsistency between a round file and the ledger, the round file governs. A ledger write failure MUST produce a printed warning and MUST NOT fail the plus workflow. Because both plus skills consume this template, this behavior MUST apply to both.

#### Scenario: One ledger row per completed round of a loop run

- **WHEN** a single plus review loop run completes N rounds for a change
- **THEN** that run appends exactly N data rows to `openspec/changes/<change>/reviews/loop-ledger.tsv`
- **AND** the header row exists exactly once at the top of the file

##### Example: three-round propose loop followed by a two-round apply loop

| skill | round | round_type | criticals | warnings | decision | fixed_files |
| ----- | ----- | ---------- | --------- | -------- | -------- | ----------- |
| propose | 1 | full | 1 | 2 | next_round | 3 |
| propose | 2 | full | 0 | 1 | next_round | 1 |
| propose | 3 | micro | 0 | 0 | passed | 0 |
| apply | 1 | full | 0 | 1 | next_round | 2 |
| apply | 2 | micro | 0 | 0 | passed | 0 |

#### Scenario: Ledger is created with a header row

- **WHEN** round 1 of a loop completes and no `loop-ledger.tsv` exists for the change
- **THEN** the main agent creates the file with one header row and one data row

#### Scenario: Re-run after an aborted loop accumulates rows

- **WHEN** a loop ended with `decision: aborted` and a new loop run for the same skill later runs on the same change
- **THEN** the new run's rows are appended after the existing rows
- **AND** the earlier run's rows are not modified or deleted

#### Scenario: Failure-aborted round records zero counts

- **WHEN** a round is aborted because the same reviewer role failed twice and no post-filter findings exist
- **THEN** that round's ledger row records `criticals` = 0 and `warnings` = 0 with `decision` = `aborted`

#### Scenario: Ledger write failure does not fail the workflow

- **WHEN** appending to `loop-ledger.tsv` fails
- **THEN** the main agent prints a warning
- **AND** the plus workflow continues unchanged

#### Scenario: Generated skills carry the ledger sentinel

- **WHEN** the generator produces the four plus skill files
- **THEN** each generated file contains the `<!-- LOOP-LEDGER-STEP -->` sentinel
- **AND** `scripts/spectra-plus/tests/generator-checks.fish` asserts the sentinel's presence

### Requirement: Deterministic signal-derived self-checks

The system SHALL upgrade the "Signal-derived checks" item of the pre-round mechanical self-check in the shared review-loop template to consume the optional signal `check` frontmatter field. For EVERY `open` signal whose frontmatter contains a `check` field — without applying best-effort relevance selection to these signals — the main agent MUST execute that command from the project root by passing the `check` value as the single command-string argument to `sh -c` (not by interpolating it into a quoted shell string). Exit code `0` means the check passed. Exit code `1` means the anti-pattern is present: when the detected instance lies within the current change's own artifacts or modified files, it is a self-check failure that MUST be fixed before spawning that round's reviewers, per the existing self-check rules; when the detected instance is pre-existing, or its fix lies outside the change's declared scope or inside a grader-protected path, the main agent MUST NOT fix it, MUST record a one-line out-of-scope-check-failure note in that round's `## Fix Actions` when the round file is written, MUST include the failing check result in that round's reviewers' context, and MUST proceed to spawn the reviewers — a pre-existing anti-pattern never deadlocks the loop. Any other exit code (for example `2`, `126`, `127`) is an execution error: the main agent MUST fall back to the existing best-effort judgment for that signal and record a one-line fallback note in that round's `## Fix Actions` when the round file is written. Note lines (out-of-scope or fallback) coexist with the `None; pass condition met.` text on a passing round and do not count toward the ledger `fixed_files` value. For `open` signals without a `check` field, the existing best-effort behavior MUST remain unchanged. Executing a `check` command MUST NOT modify any file.

#### Scenario: Signal with check field is executed deterministically

- **WHEN** the pre-round mechanical self-check runs and an `open` signal's frontmatter contains `check`
- **THEN** the main agent executes the `check` command from the project root by passing its value as the single argument to `sh -c`, regardless of relevance judgment
- **AND** exit code `1` with the detected instance inside the change's own artifacts or modified files is treated as a self-check failure to fix before spawning the reviewers

#### Scenario: Out-of-scope check failure does not deadlock the loop

- **WHEN** an `open` signal's `check` command exits `1` and the detected instance is pre-existing or its fix lies outside the change's declared scope or inside a grader-protected path
- **THEN** the main agent does not fix it, records a one-line out-of-scope-check-failure note in that round's `## Fix Actions` when the round file is written
- **AND** includes the failing check result in that round's reviewers' context and proceeds to spawn the reviewers

#### Scenario: Execution-error exit codes fall back to best-effort

- **WHEN** an `open` signal's `check` command exits with a code other than `0` or `1`
- **THEN** the main agent applies the existing best-effort judgment for that signal
- **AND** records a one-line fallback note in that round's `## Fix Actions` when the round file is written
- **AND** the note does not count toward the ledger `fixed_files` value

#### Scenario: Signals without check keep best-effort behavior

- **WHEN** an `open` signal has no `check` field
- **THEN** the Signal-derived checks behavior for that signal is unchanged from the existing best-effort rule

## MODIFIED Requirements

### Requirement: spectra-propose-plus quality gate

The system SHALL provide a `spectra-propose-plus` skill that mirrors the steps of `spectra-propose` for artifact creation (proposal, design, specs, tasks) but replaces the inline self-review and analyze-fix loop with a sub-agent review/rating/fix loop. The skill MUST run `spectra validate` before entering the sub-agent loop, so validation fixes happen before the quality gate reviews the final artifact state. The skill MUST run the loop at per-change granularity (after all required artifacts are written and validation has passed, not per artifact). The skill MUST cap the loop at 6 rounds. The skill MUST NOT use a rater sub-agent and MUST NOT produce a `quality_score`; instead the main agent SHALL derive the round decision mechanically from the post-filter findings. A round MUST be treated as passing if and only if, after the confidence filter, no surviving finding has `severity == Critical` and no surviving finding has `severity == Warning` (only `Suggestion` findings remain, or none). When a round's decision is `next_round`, the main agent MUST derive the next round's type (full or micro) per the `Graded convergence and micro-verification round` requirement. Fix obligations in this requirement are subject to the grader-protection exception defined in the `Review loop grader immutability` requirement. The skill MUST NOT execute `spectra park` at the end of its workflow.

#### Scenario: Loop reaches pass condition before max rounds

- **WHEN** a round completes with no surviving `Critical` finding and no surviving `Warning` finding after the confidence filter
- **THEN** the skill writes the corresponding round file with `decision: passed`
- **AND** stops the loop without starting another round
- **AND** continues to the final summary without running post-gate validation fixes
- **AND** does not execute `spectra park`

#### Scenario: Validation precedes the quality gate

- **WHEN** `spectra-propose-plus` has created all artifacts required for apply
- **THEN** it runs `spectra validate "<name>"`
- **AND** fixes validation errors before the first review-loop round
- **AND** the review loop starts only after validation passes

- **WHEN** a review-loop Fix Action modifies proposal, design, tasks, or spec artifacts
- **THEN** it runs `spectra validate "<name>"` again
- **AND** fixes validation errors before starting the next review-loop round

#### Scenario: Surviving Warning forces another round

- **WHEN** a round completes with no surviving `Critical` finding but at least one surviving `Warning` finding after the confidence filter
- **THEN** the skill writes the round file with `decision: next_round`
- **AND** fixes the Warning findings before starting the next round, except any finding withheld under the `Review loop grader immutability` requirement, which is recorded as unfixed-due-to-grader-protection and remains surviving
- **AND** derives the next round's type per the `Graded convergence and micro-verification round` requirement

#### Scenario: Loop hits 6-round cap without passing

- **WHEN** the loop completes 6 rounds without meeting the pass condition
- **THEN** the skill writes round 6 with `decision: aborted`
- **AND** prints a warning summarising the unresolved findings
- **AND** ends the workflow without parking the change

#### Scenario: Park is never invoked

- **WHEN** `spectra-propose-plus` ends its workflow under any outcome
- **THEN** the workflow never invokes `spectra park`
- **AND** the change directory remains under `openspec/changes/` (not parked)

##### Example: end-of-workflow path comparison

| Skill | Inline self-review | Analyze-fix loop | Sub-agent loop (max 6) | Park at end |
| ----- | ------------------ | ---------------- | ---------------------- | ----------- |
| spectra-propose       | yes | yes (max 2)  | no  | yes |
| spectra-propose-plus  | no  | no           | yes | no  |

### Requirement: spectra-apply-plus quality gate

The system SHALL provide a `spectra-apply-plus` skill that mirrors `spectra-apply` for task execution and appends a sub-agent review/rating/fix loop after all tasks complete. The skill MUST run the loop at per-change granularity (once, after every task is marked complete in `tasks.md`). The skill MUST cap the loop at 6 rounds. The skill MUST NOT suggest archiving the change before the review loop has ended with `decision: passed`. The skill MUST NOT use a rater sub-agent and MUST NOT produce a `quality_score`; instead the main agent SHALL derive the round decision mechanically from the post-filter findings. A round MUST be treated as passing if and only if, after the confidence filter, no surviving finding has `severity == Critical` and no surviving finding has `severity == Warning` (only `Suggestion` findings remain, or none). When a round's decision is `next_round`, the main agent MUST derive the next round's type (full or micro) per the `Graded convergence and micro-verification round` requirement. Fix obligations in this requirement are subject to the grader-protection exception defined in the `Review loop grader immutability` requirement.

#### Scenario: Review loop runs after tasks complete

- **WHEN** every checkbox in `tasks.md` reads `[x]`
- **THEN** `spectra-apply-plus` starts the sub-agent review/rating/fix loop
- **AND** does not start the loop earlier

#### Scenario: Surviving Critical forces another round

- **WHEN** a round completes with at least one surviving `Critical` finding after the confidence filter
- **THEN** the skill writes the round file with `decision: next_round`
- **AND** fixes the Critical findings before starting the next round, except any finding withheld under the `Review loop grader immutability` requirement, which is recorded as unfixed-due-to-grader-protection and remains surviving
- **AND** the next round is a full round

#### Scenario: Loop hits 6-round cap

- **WHEN** the loop completes 6 rounds without meeting the pass condition
- **THEN** the skill writes round 6 with `decision: aborted`
- **AND** prints a warning summarising the unresolved findings
- **AND** ends the workflow

#### Scenario: Archive guidance waits for gate pass

- **WHEN** all tasks are complete but the review loop has not passed yet
- **THEN** `spectra-apply-plus` states that archive guidance is deferred until the plus quality gate passes
- **AND** does not tell the user to run `spectra archive`, `/spectra-archive`, or `$spectra-archive`

- **WHEN** the final review-loop round has `decision: passed`
- **THEN** the final response may suggest archiving the change
