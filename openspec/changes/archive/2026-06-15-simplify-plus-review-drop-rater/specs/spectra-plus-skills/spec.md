## MODIFIED Requirements

### Requirement: spectra-propose-plus quality gate

The system SHALL provide a `spectra-propose-plus` skill that mirrors the steps of `spectra-propose` for artifact creation (proposal, design, specs, tasks) but replaces the inline self-review and analyze-fix loop with a sub-agent review/rating/fix loop. The skill MUST run the loop at per-change granularity (after all required artifacts are written, not per artifact). The skill MUST cap the loop at 6 rounds. The skill MUST NOT use a rater sub-agent and MUST NOT produce a `quality_score`; instead the main agent SHALL derive the round decision mechanically from the post-filter findings. A round MUST be treated as passing if and only if, after the confidence filter, no surviving finding has `severity == Critical` and no surviving finding has `severity == Warning` (only `Suggestion` findings remain, or none). The skill MUST NOT execute `spectra park` at the end of its workflow.

#### Scenario: Loop reaches pass condition before max rounds

- **WHEN** a round completes with no surviving `Critical` finding and no surviving `Warning` finding after the confidence filter
- **THEN** the skill writes the corresponding round file with `decision: passed`
- **AND** stops the loop without starting another round
- **AND** continues to `spectra validate`
- **AND** does not execute `spectra park`

#### Scenario: Surviving Warning forces another round

- **WHEN** a round completes with no surviving `Critical` finding but at least one surviving `Warning` finding after the confidence filter
- **THEN** the skill writes the round file with `decision: next_round`
- **AND** fixes the Warning findings before starting the next round

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

The system SHALL provide a `spectra-apply-plus` skill that mirrors `spectra-apply` for task execution and appends a sub-agent review/rating/fix loop after all tasks complete. The skill MUST run the loop at per-change granularity (once, after every task is marked complete in `tasks.md`). The skill MUST cap the loop at 6 rounds. The skill MUST NOT use a rater sub-agent and MUST NOT produce a `quality_score`; instead the main agent SHALL derive the round decision mechanically from the post-filter findings. A round MUST be treated as passing if and only if, after the confidence filter, no surviving finding has `severity == Critical` and no surviving finding has `severity == Warning` (only `Suggestion` findings remain, or none).

#### Scenario: Review loop runs after tasks complete

- **WHEN** every checkbox in `tasks.md` reads `[x]`
- **THEN** `spectra-apply-plus` starts the sub-agent review/rating/fix loop
- **AND** does not start the loop earlier

#### Scenario: Surviving Critical forces another round

- **WHEN** a round completes with at least one surviving `Critical` finding after the confidence filter
- **THEN** the skill writes the round file with `decision: next_round`
- **AND** fixes the Critical findings before starting the next round

#### Scenario: Loop hits 6-round cap

- **WHEN** the loop completes 6 rounds without meeting the pass condition
- **THEN** the skill writes round 6 with `decision: aborted`
- **AND** prints a warning summarising the unresolved findings
- **AND** ends the workflow

### Requirement: Round file output contract

The system SHALL write one round file per loop round to `openspec/changes/<change>/reviews/`. File names MUST follow the pattern `propose-r<N>.md` for `spectra-propose-plus` and `apply-r<N>.md` for `spectra-apply-plus`, where `<N>` is the 1-based round number. Each round file MUST contain exactly four top-level `##` sections, in this fixed order: `## Reviewer Findings`, `## Rating`, `## Fix Actions`, `## Decision`, plus the round heading at the top. The `## Rating` section MUST NOT contain a `quality_score` field; it MUST record the count of surviving `Critical` findings, the count of surviving `Warning` findings, `critical_gap` (boolean), and a rationale paragraph explaining the mechanical decision.

#### Scenario: Round file structure

- **WHEN** any round of a plus skill completes
- **THEN** a file at `openspec/changes/<change>/reviews/<skill>-r<N>.md` exists
- **AND** the file starts with a level-1 heading naming the skill and round
- **AND** the file contains exactly four `##` headings: `Reviewer Findings`, `Rating`, `Fix Actions`, `Decision`, and the leading round summary heading is `#` not `##`

#### Scenario: Rating section omits quality_score

- **WHEN** the `## Rating` section of any round file is written
- **THEN** it contains no `quality_score` field
- **AND** it records the surviving `Critical` count, the surviving `Warning` count, `critical_gap`, and a rationale paragraph

##### Example: required round file outline

| Section                | Heading level | Content                                                                                                            |
| ---------------------- | ------------- | ------------------------------------------------------------------------------------------------------------------ |
| Round heading          | `#`           | e.g., `Propose Plus Review — Round 2`                                                                              |
| `Reviewer Findings`    | `##`          | Three subsections: Critical, Warning, Suggestion. Each finding lists `severity`, `confidence`, `location`, `summary`, `recommendation`, and reviewer source (`A`, `B`, or `A+B`) |
| `Rating`               | `##`          | surviving `Critical` count, surviving `Warning` count, `critical_gap` (boolean), `rationale` (text)                |
| `Fix Actions`          | `##`          | List of changes made this round with file paths and rationale                                                      |
| `Decision`             | `##`          | One of `passed`, `next_round`, `aborted`                                                                           |

#### Scenario: Final round decision values

- **WHEN** the loop ends successfully
- **THEN** the final round file has `Decision: passed`

- **WHEN** the loop ends by hitting the 6-round cap
- **THEN** the final round file has `Decision: aborted`

### Requirement: Fresh sub-agent per round

The system SHALL spawn fresh sub-agents for every review step. The skill MUST NOT reuse a sub-agent across rounds. Each round MUST spawn exactly TWO reviewer sub-agents in parallel — `Reviewer A` (artifact/implementation adherence) and `Reviewer B` (bug/quality scan). The skill MUST NOT spawn a rater sub-agent. The skill MUST NOT perform review inline in the main agent context. After both reviewers complete, the main agent SHALL aggregate findings (deduplicate by `location + summary`), apply the confidence filter (see `Confidence-scored findings` requirement), and derive the round decision mechanically from the filtered findings without any further sub-agent call.

#### Scenario: Two reviewers and no rater per round

- **WHEN** a round begins
- **THEN** the skill makes two parallel sub-agent calls for `Reviewer A` and `Reviewer B`, dispatched in a single message
- **AND** makes no rater sub-agent call
- **AND** Reviewer A and Reviewer B do not see each other's findings
- **AND** the main agent derives `decision` from the post-filter findings itself

#### Scenario: No sub-agent reuse across rounds

- **WHEN** round N+1 begins after round N
- **THEN** the skill spawns brand-new `Reviewer A` and `Reviewer B` sub-agents
- **AND** does not pass the prior round's sub-agent state forward

### Requirement: Confidence-scored findings and filter

The system SHALL require every reviewer finding to carry a `confidence` integer from `0` to `100`. The main agent MUST apply a confidence filter before deriving the round decision. Findings with `confidence < 50` MUST be dropped entirely and SHALL NOT appear in the round file. Findings with `confidence` in `[50, 80)` MUST be downgraded to `Suggestion` regardless of the reviewer's original severity classification. Only findings with `confidence >= 80` MAY appear as `Critical` or `Warning` in the post-filter round file. `critical_gap` MUST be `true` if and only if at least one finding survives the filter with `severity == Critical` AND `confidence >= 80`. Direct artifact-requirement violations (citing a specific `SHALL`, Implementation Contract item, or task description line) MUST score `100` so the filter does not demote them.

#### Scenario: Filter drops low-confidence findings

- **WHEN** a reviewer reports a finding with `confidence == 30`
- **THEN** the finding does not appear in the round file
- **AND** it does not contribute to the round decision

#### Scenario: Filter downgrades mid-confidence Critical to Suggestion

- **WHEN** a reviewer reports a `Critical` finding with `confidence == 60`
- **THEN** the round file lists it under `Suggestion`, not `Critical`
- **AND** `critical_gap` is not set to `true` solely on account of this finding

#### Scenario: Artifact-citation findings are not demoted

- **WHEN** a reviewer cites a specific `SHALL` clause from `spec.md` or a contract item from `design.md` that the artifact set or implementation does not satisfy
- **THEN** the reviewer scores the finding `confidence == 100`
- **AND** the finding survives the filter and may be classified `Critical`

### Requirement: Sub-agent failure handling

The system SHALL retry a failed sub-agent call once within the same round. If the retry also fails, the skill MUST abort the entire plus workflow with a clear error and SHALL NOT mark the round as `passed` or continue to the next round. If both parallel reviewers fail within the same round, the skill MUST treat it as a single reviewer-role failure (one retry) rather than two separate failures.

#### Scenario: Single sub-agent failure recovers

- **WHEN** a reviewer sub-agent fails (no response or malformed output)
- **THEN** the skill retries that same reviewer role once with a fresh invocation
- **AND** the round continues if the retry succeeds

#### Scenario: Two consecutive sub-agent failures abort

- **WHEN** the same sub-agent role fails twice in a single round
- **THEN** the skill aborts the plus workflow
- **AND** writes a round file with `decision: aborted` and a note describing the failure

#### Scenario: Both parallel reviewers failing counts as one role failure

- **WHEN** both `Reviewer A` and `Reviewer B` fail in the same round
- **THEN** the skill treats it as a single reviewer-role failure
- **AND** retries the reviewer role once (both reviewers re-dispatched in parallel)
- **AND** only aborts if the retry also fails
