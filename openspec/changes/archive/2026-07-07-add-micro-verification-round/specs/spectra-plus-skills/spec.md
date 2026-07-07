## ADDED Requirements

### Requirement: Graded convergence and micro-verification round

The system SHALL grade review-loop convergence by finding layer. Every reviewer finding MUST carry a `layer` field whose value is exactly one of `design` or `text`. A finding MUST be classified `text` only when it concerns cross-artifact consistency (counts, identifier spelling, wording, or section synchronization) AND fixing it does not change any design decision or behavioral statement; every other finding MUST be classified `design`. When a reviewer cannot decide between the two values, it MUST classify the finding as `design`. While applying the confidence filter, the main agent MUST re-check every finding classified `text` and MUST reclassify it to `design` when the fix could touch behavior or a design statement; the main agent MUST NOT reclassify a `design` finding to `text`. When full-round reviewers independently raise the same finding (deduplicated by `location + summary`) with different `layer` values, the merged finding MUST take `layer == design`.

The loop SHALL run two round types: full rounds and micro rounds. Round 1 MUST be a full round. When a round's decision is `next_round`, the main agent MUST derive the next round's type mechanically: the next round is a micro round if and only if the current round is a full round AND zero findings survive the confidence filter with `severity == Critical` AND every surviving `Warning` finding has `layer == text`; otherwise the next round is a full round. The derived type is provisional until the next round's reviewers are spawned: if any artifact modification (or, for apply-plus, any implementation-file modification) made after the decision is recorded — including a fix action, a mechanical self-check fix, or a validation fix — actually modifies behavior or a design statement (rather than only synchronizing text across artifacts), the main agent MUST re-derive the next round as a full round. When the main agent cannot determine whether such a modification only synchronizes text, it MUST treat the modification as behavior-modifying and re-derive a full round. Re-derivation MUST only change a micro round into a full round, never the reverse; when re-derivation happens, the main agent MUST record a one-line re-derivation note (the triggering modification and the reason) at the end of that round file's `## Fix Actions` section. A micro round MUST NOT be followed by another micro round. Micro rounds MUST count toward the 6-round cap and MUST produce a round file like any other round.

A micro round MUST spawn exactly ONE fresh verification reviewer sub-agent (`Reviewer V — Verification`) instead of the two full-round reviewers. Reviewer V MUST receive as context: the artifact paths (and, for apply-plus, the changed-file list), the prior round file's surviving findings and `## Fix Actions` content, and the same relevant `open` signals context that full-round reviewers receive. Reviewer V's scope MUST be limited to: whether each prior-round fix resolved its finding at the fixed location, whether fix propagation is complete (every occurrence of each concept touched by a fix is synchronized across all artifacts and, for apply-plus, the changed files), and whether the fixes introduced new defects. In apply-plus micro rounds, Reviewer V MUST additionally perform the per-round `implementation-notes.md` reading obligation defined for Reviewer A in the Implementation Notes Protocol, including its file-absent and `open-question` severity rules. Reviewer V findings MUST carry the same fields as full-round findings (including `layer` and `confidence`) and MUST pass through the same confidence filter. If no `Critical` or `Warning` finding survives the filter in a micro round, the decision is `passed`; if any survives, the decision is `next_round` and the next round MUST be a full round, subject to the existing 6-round cap (a round 6 that does not meet the pass condition records `decision: aborted`).

#### Scenario: Text-only Warnings trigger a micro round

- **WHEN** a full round completes with zero surviving `Critical` findings and at least one surviving `Warning` finding, all of whose `layer` values are `text`
- **THEN** the round file records `decision: next_round`
- **AND** the next round is derived as a micro round, provisional until the next round's reviewers are spawned

#### Scenario: Design-layer Warning forces a full round

- **WHEN** a full round completes with zero surviving `Critical` findings and at least one surviving `Warning` finding whose `layer` is `design`
- **THEN** the round file records `decision: next_round`
- **AND** the next round is a full round

#### Scenario: Micro round with no surviving findings passes the loop

- **WHEN** a micro round completes and no `Critical` or `Warning` finding survives the confidence filter
- **THEN** the round file records `decision: passed` and `round_type: micro`
- **AND** the loop stops

#### Scenario: Apply-plus micro round reads implementation notes

- **WHEN** an apply-plus micro round begins
- **THEN** Reviewer V reads `openspec/changes/<change>/implementation-notes.md` per the Implementation Notes Protocol
- **AND** a missing file yields a `Critical` finding
- **AND** an unresolved `open-question` entry yields a `Warning` finding

#### Scenario: Micro round findings escalate to a full round

- **WHEN** a micro round that is not round 6 completes with at least one surviving `Critical` or `Warning` finding
- **THEN** the round file records `decision: next_round`
- **AND** the next round is a full round

#### Scenario: Fix that touches behavior escalates the next round to full

- **WHEN** a full round derives the next round as a micro round, and an artifact modification (or, for apply-plus, an implementation-file modification) made after the decision is recorded — including a fix action, a mechanical self-check fix, or a validation fix — actually modifies behavior or a design statement rather than only synchronizing text
- **THEN** the main agent re-derives the next round as a full round
- **AND** records a one-line re-derivation note at the end of that round file's `## Fix Actions` section
- **AND** re-derivation never changes a derived full round into a micro round

#### Scenario: Uncertain fix nature escalates to a full round

- **WHEN** the main agent cannot determine whether a post-decision modification only synchronizes text across artifacts
- **THEN** the main agent treats the modification as behavior-modifying
- **AND** re-derives the next round as a full round

#### Scenario: Divergent layer values merge conservatively

- **WHEN** both full-round reviewers independently raise the same finding (deduplicated by `location + summary`) and their `layer` classifications differ
- **THEN** the merged finding takes `layer: design`

#### Scenario: Uncertain layer defaults to design

- **WHEN** a reviewer cannot decide whether fixing a finding changes a design decision or behavioral statement
- **THEN** the reviewer classifies the finding with `layer: design`

#### Scenario: Main agent reclassification is upgrade-only

- **WHEN** the main agent applies the confidence filter and judges that fixing a finding classified `text` could touch behavior or a design statement
- **THEN** the main agent reclassifies that finding to `design`
- **AND** the main agent never reclassifies a `design` finding to `text`

##### Example: next-round-type derivation

| Current round type | Surviving Critical | Surviving Warnings by layer | Next round type |
| ------------------ | ------------------ | --------------------------- | --------------- |
| full  | 0 | 2× `text`               | micro |
| full  | 0 | 1× `text`, 1× `design`  | full  |
| full  | 1 | 2× `text`               | full  |
| micro | 0 | 1× `text`               | full  |

## MODIFIED Requirements

### Requirement: spectra-propose-plus quality gate

The system SHALL provide a `spectra-propose-plus` skill that mirrors the steps of `spectra-propose` for artifact creation (proposal, design, specs, tasks) but replaces the inline self-review and analyze-fix loop with a sub-agent review/rating/fix loop. The skill MUST run `spectra validate` before entering the sub-agent loop, so validation fixes happen before the quality gate reviews the final artifact state. The skill MUST run the loop at per-change granularity (after all required artifacts are written and validation has passed, not per artifact). The skill MUST cap the loop at 6 rounds. The skill MUST NOT use a rater sub-agent and MUST NOT produce a `quality_score`; instead the main agent SHALL derive the round decision mechanically from the post-filter findings. A round MUST be treated as passing if and only if, after the confidence filter, no surviving finding has `severity == Critical` and no surviving finding has `severity == Warning` (only `Suggestion` findings remain, or none). When a round's decision is `next_round`, the main agent MUST derive the next round's type (full or micro) per the `Graded convergence and micro-verification round` requirement. The skill MUST NOT execute `spectra park` at the end of its workflow.

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
- **AND** fixes the Warning findings before starting the next round
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

The system SHALL provide a `spectra-apply-plus` skill that mirrors `spectra-apply` for task execution and appends a sub-agent review/rating/fix loop after all tasks complete. The skill MUST run the loop at per-change granularity (once, after every task is marked complete in `tasks.md`). The skill MUST cap the loop at 6 rounds. The skill MUST NOT suggest archiving the change before the review loop has ended with `decision: passed`. The skill MUST NOT use a rater sub-agent and MUST NOT produce a `quality_score`; instead the main agent SHALL derive the round decision mechanically from the post-filter findings. A round MUST be treated as passing if and only if, after the confidence filter, no surviving finding has `severity == Critical` and no surviving finding has `severity == Warning` (only `Suggestion` findings remain, or none). When a round's decision is `next_round`, the main agent MUST derive the next round's type (full or micro) per the `Graded convergence and micro-verification round` requirement.

#### Scenario: Review loop runs after tasks complete

- **WHEN** every checkbox in `tasks.md` reads `[x]`
- **THEN** `spectra-apply-plus` starts the sub-agent review/rating/fix loop
- **AND** does not start the loop earlier

#### Scenario: Surviving Critical forces another round

- **WHEN** a round completes with at least one surviving `Critical` finding after the confidence filter
- **THEN** the skill writes the round file with `decision: next_round`
- **AND** fixes the Critical findings before starting the next round
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

### Requirement: Round file output contract

The system SHALL write one round file per loop round to `openspec/changes/<change>/reviews/`. File names MUST follow the pattern `propose-r<N>.md` for `spectra-propose-plus` and `apply-r<N>.md` for `spectra-apply-plus`, where `<N>` is the 1-based round number. Each round file MUST contain exactly four top-level `##` sections, in this fixed order: `## Reviewer Findings`, `## Rating`, `## Fix Actions`, `## Decision`, plus the round heading at the top. The `## Rating` section MUST NOT contain a `quality_score` field; it MUST record the count of surviving `Critical` findings, the count of surviving `Warning` findings, `critical_gap` (boolean), `round_type` (exactly one of `full` or `micro`), and a rationale paragraph explaining the mechanical decision.

#### Scenario: Round file structure

- **WHEN** any round of a plus skill completes
- **THEN** a file at `openspec/changes/<change>/reviews/<skill>-r<N>.md` exists
- **AND** the file starts with a level-1 heading naming the skill and round
- **AND** the file contains exactly four `##` headings: `Reviewer Findings`, `Rating`, `Fix Actions`, `Decision`, and the leading round summary heading is `#` not `##`

#### Scenario: Rating section omits quality_score

- **WHEN** the `## Rating` section of any round file is written
- **THEN** it contains no `quality_score` field
- **AND** it records the surviving `Critical` count, the surviving `Warning` count, `critical_gap`, `round_type`, and a rationale paragraph

##### Example: required round file outline

| Section                | Heading level | Content                                                                                                            |
| ---------------------- | ------------- | ------------------------------------------------------------------------------------------------------------------ |
| Round heading          | `#`           | e.g., `Propose Plus Review — Round 2`                                                                              |
| `Reviewer Findings`    | `##`          | Three subsections: Critical, Warning, Suggestion. Each finding lists `severity`, `confidence`, `layer`, `location`, `summary`, `recommendation`, and reviewer source (`A`, `B`, `A+B`, or `V`) |
| `Rating`               | `##`          | surviving `Critical` count, surviving `Warning` count, `critical_gap` (boolean), `round_type` (`full` or `micro`), `rationale` (text) |
| `Fix Actions`          | `##`          | List of changes made this round with file paths and rationale                                                      |
| `Decision`             | `##`          | One of `passed`, `next_round`, `aborted`                                                                           |

#### Scenario: Final round decision values

- **WHEN** the loop ends successfully
- **THEN** the final round file has `Decision: passed`

- **WHEN** the loop ends by hitting the 6-round cap
- **THEN** the final round file has `Decision: aborted`

### Requirement: Fresh sub-agent per round

The system SHALL spawn fresh sub-agents for every review step. The skill MUST NOT reuse a sub-agent across rounds. Each FULL round MUST spawn exactly TWO reviewer sub-agents in parallel — `Reviewer A` (artifact/implementation adherence) and `Reviewer B` (bug/quality scan). Each MICRO round MUST spawn exactly ONE fresh verification reviewer sub-agent — `Reviewer V` (fix verification), per the `Graded convergence and micro-verification round` requirement. The skill MUST NOT spawn a rater sub-agent. The skill MUST NOT perform review inline in the main agent context. After the round's reviewer sub-agents complete, the main agent SHALL aggregate findings (deduplicate by `location + summary`), apply the confidence filter (see `Confidence-scored findings` requirement), and derive the round decision mechanically from the filtered findings without any further sub-agent call.

#### Scenario: Two reviewers and no rater per round

- **WHEN** a full round begins
- **THEN** the skill makes two parallel sub-agent calls for `Reviewer A` and `Reviewer B`, dispatched in a single message
- **AND** makes no rater sub-agent call
- **AND** Reviewer A and Reviewer B do not see each other's findings
- **AND** the main agent derives `decision` from the post-filter findings itself

#### Scenario: Micro round spawns exactly one verification reviewer

- **WHEN** a micro round begins
- **THEN** the skill makes exactly one sub-agent call for `Reviewer V`
- **AND** makes no `Reviewer A`, `Reviewer B`, or rater sub-agent call in that round
- **AND** the main agent derives `decision` from the post-filter findings itself

#### Scenario: No sub-agent reuse across rounds

- **WHEN** round N+1 begins after round N
- **THEN** the skill spawns brand-new reviewer sub-agents for round N+1 (`Reviewer A` and `Reviewer B` for a full round, `Reviewer V` for a micro round)
- **AND** does not pass the prior round's sub-agent state forward

### Requirement: Generated plus skill version metadata

The system SHALL emit stable plus-layer freshness metadata into the top-level YAML frontmatter of every generated `spectra-propose-plus` and `spectra-apply-plus` skill file. The metadata MUST be controlled by `scripts/spectra-plus/rules.yaml` and MUST be emitted into all configured generated variants. The generated metadata MUST include `spectraPlusVersion` and `spectraPlusUpdated`. The generated metadata MUST NOT use a per-generation timestamp. The existing nested `metadata.version` field MUST NOT be used as the plus-layer freshness signal. Scenarios and examples in this specification MUST reference the `spectraPlusVersion` and `spectraPlusUpdated` values declared in `scripts/spectra-plus/rules.yaml` instead of hard-coding version or date literals. Regression tests MUST pin the currently declared values as synchronized literals, updated on each bump, so an unintended or missed bump fails the tests.

#### Scenario: Full regeneration emits current metadata

- **WHEN** the user runs `scripts/spectra-plus/generate.fish` with no arguments
- **THEN** each generated plus skill file top-level YAML frontmatter contains a `spectraPlusVersion` equal to the `spectraPlusVersion` declared in `scripts/spectra-plus/rules.yaml`
- **AND** each generated plus skill file top-level YAML frontmatter contains a `spectraPlusUpdated` equal to the `spectraPlusUpdated` declared in `scripts/spectra-plus/rules.yaml`
- **AND** each generated plus skill file retains the generated-file marker

##### Example: generated output set

| Output Path | Required Version | Required Updated Date |
| ----- | ----- | ----- |
| `.claude/skills/spectra-propose-plus/SKILL.md` | `spectraPlusVersion` declared in `rules.yaml` | `spectraPlusUpdated` declared in `rules.yaml` |
| `.claude/skills/spectra-apply-plus/SKILL.md` | `spectraPlusVersion` declared in `rules.yaml` | `spectraPlusUpdated` declared in `rules.yaml` |
| `.agents/skills/spectra-propose-plus/SKILL.md` | `spectraPlusVersion` declared in `rules.yaml` | `spectraPlusUpdated` declared in `rules.yaml` |
| `.agents/skills/spectra-apply-plus/SKILL.md` | `spectraPlusVersion` declared in `rules.yaml` | `spectraPlusUpdated` declared in `rules.yaml` |

#### Scenario: Regeneration remains idempotent

- **WHEN** the generator is run twice in a row with no source, rules, or template changes between runs
- **THEN** both runs produce byte-identical plus skill files
- **AND** the metadata values do not change between the two runs

### Requirement: Repair checks plus metadata freshness

The installer and repair-all current-state checks SHALL treat plus skill metadata as part of the generated output freshness contract. The current `spectraPlusVersion` and `spectraPlusUpdated` values SHALL be read from the local `scripts/spectra-plus/rules.yaml` source of truth. A target project SHALL be current only when every generated plus skill output top-level YAML frontmatter contains the current `spectraPlusVersion` and `spectraPlusUpdated` values. For repair-all, local metadata parsing MUST run only after source-sensitive paths are known to be clean. Scenarios and examples in this specification MUST reference the values declared in `scripts/spectra-plus/rules.yaml` instead of hard-coding version or date literals; regression tests MUST pin the currently declared values as synchronized literals, updated on each bump.

#### Scenario: Target missing plus metadata is stale

- **GIVEN** source-sensitive paths are clean
- **AND** a registered target project has generated plus skill outputs without `spectraPlusVersion`
- **WHEN** the user runs repair-all
- **THEN** the target is treated as stale
- **AND** repair-all rewrites the generated plus skill outputs with current metadata

#### Scenario: Target with old plus metadata is stale

- **GIVEN** source-sensitive paths are clean
- **AND** a registered target project has generated plus skill outputs containing a `spectraPlusVersion` different from the value declared in `scripts/spectra-plus/rules.yaml`
- **WHEN** the user runs repair-all
- **THEN** the target is treated as stale
- **AND** repair-all rewrites the generated plus skill outputs with the `spectraPlusVersion` declared in `scripts/spectra-plus/rules.yaml`
- **AND** repair-all rewrites the generated plus skill outputs with the `spectraPlusUpdated` declared in `scripts/spectra-plus/rules.yaml`

#### Scenario: Target with old updated date metadata is stale

- **GIVEN** source-sensitive paths are clean
- **AND** a registered target project has generated plus skill outputs containing a `spectraPlusUpdated` different from the value declared in `scripts/spectra-plus/rules.yaml`
- **WHEN** the user runs repair-all
- **THEN** the target is treated as stale
- **AND** repair-all rewrites the generated plus skill outputs with the `spectraPlusUpdated` declared in `scripts/spectra-plus/rules.yaml`

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
