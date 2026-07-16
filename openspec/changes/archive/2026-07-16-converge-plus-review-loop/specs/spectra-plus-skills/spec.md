## MODIFIED Requirements

### Requirement: Graded convergence and micro-verification round

The system SHALL grade review-loop convergence by finding layer. Every reviewer finding MUST carry a `layer` field whose value is exactly one of `design` or `text`. A finding MUST be classified `text` only when it concerns cross-artifact consistency (counts, identifier spelling, wording, or section synchronization) AND fixing it does not change any design decision or behavioral statement; every other finding MUST be classified `design`. When a reviewer cannot decide between the two values, it MUST classify the finding as `design`. While applying the confidence filter, the main agent MUST re-check every finding classified `text` and MUST reclassify it to `design` when the fix could touch behavior or a design statement; the main agent MUST NOT reclassify a `design` finding to `text`. When full-round reviewers independently raise the same finding (deduplicated by `location + summary`) with different `layer` values, the merged finding MUST take `layer == design`. The `layer` field MUST NOT participate in round-type derivation.

The loop SHALL run two round types: full rounds and micro rounds (delta verification rounds). The first round of a loop run MUST be a full round. When a round's decision is `next_round`, the main agent MUST derive the next round's type mechanically from its position within the current loop run alone: the next round is a full round if and only if it is the fourth round of the current run; otherwise the next round is a micro round. Consecutive micro rounds are valid. Fix actions that modify behavior MUST NOT escalate the next round's type; the fourth-round checkpoint is the only full re-scan after the run's first round. Micro rounds MUST count toward the 6-round cap and MUST produce a round file like any other round.

After the run's first round, every reviewer of a round (Reviewer V in micro rounds; Reviewer A and Reviewer B in the fourth-round checkpoint) MUST tag each `Critical` or `Warning` finding with a `disposition` field whose value is exactly one of: `unresolved-prior` — the finding matches a blocking finding from a prior round of this loop (or, in a re-run, a bucket-1 finding carried from the prior run per the `Abort triage` requirement), whether or not a fix was recorded for it: a re-report is itself evidence that any recorded fix did not resolve it; `fix-introduced` — the finding is attributed, by an explicit fix-action reference carried in the finding, to one or more modifications recorded in `## Fix Actions` sections of this loop (or, in a seeded re-run, of the prior run); every reviewer of these rounds — including Reviewer V and propose-plus reviewers — MUST attach that reference when tagging `fix-introduced`; or `new` — the finding matches no prior blocking finding; a finding that matches only a prior non-blocking triage note is also tagged `new` and stays non-blocking without producing a duplicate triage note or signal; its recorded action under the `Review round action obligation` requirement is a one-line cross-reference note naming the original round's triage note, which is neither a duplicate triage note nor a new signal. Disposition matching operates on the same artifact or file plus the same defect mechanism; recorded line ranges are advisory and a shifted range does not break a match. To make dispositions evaluable, the main agent MUST provide, in the reviewer context of every round after the run's first round, every prior round file of this loop (in a seeded re-run, including the prior run's round files or their extracts) AND the current cumulative-blocking-set member list; when the accumulated round files exceed practical context size, the main agent MUST instead provide per-round extracts containing each round's surviving findings and complete `## Fix Actions` content, and MUST record a one-line note in the current round's `## Fix Actions` naming the rounds provided as extracts. The main agent MUST verify each disposition tag against the prior round files and MUST correct a tag that does not hold; for every finding tagged `new`, the main agent MUST additionally check whether its location was modified by this loop's — and, in a seeded re-run, the prior run's — recorded fix actions and, when the defect stems from those modifications, correct the tag to `fix-introduced` supplying the fix-action reference in the correction record; every correction MUST be recorded in that round file's `## Fix Actions` naming the finding, the reviewer's original tag, the corrected tag, and the evidence, and every correction that changes a blocking disposition to a non-blocking one MUST be listed in the completion output. When findings deduplicated by `location + summary` carry divergent `disposition` values, the merged finding MUST take the blocking disposition (`unresolved-prior` or `fix-introduced` wins over `new`). Round files of completed rounds are immutable during an active loop: fix records and triage notes MUST be written only in the round in which they occur, and the main agent MUST NOT retroactively edit a prior round file.

A surviving `Critical` or `Warning` finding is blocking if and only if its verified disposition is `unresolved-prior` or `fix-introduced`. A finding whose most recent prior status in this loop is a non-blocking triage note remains non-blocking and MUST NOT re-enter the blocking set, with one exception: when later evidence attributes the finding to recorded fix actions, it re-enters as `fix-introduced` through a traced disposition correction. Every other surviving finding with disposition `new` is non-blocking: the main agent MUST record it as a triage note in that round file's `## Fix Actions` section, MUST include it in the signals write step target set, and MUST list it in the completion output; for a non-blocking `Critical` finding, the completion output MUST additionally recommend creating a follow-up change proposal. Non-blocking findings MUST NOT cause a `next_round` decision.

The main agent MUST additionally maintain the run's cumulative blocking set: every blocking finding of the run enters the set when found, counts toward every subsequent round decision even when no reviewer re-reports it, and leaves the set only through one of exactly two removal events: (a) resolved — a resolving fix was recorded for it AND a subsequent round's reviewer verified the resolution (the finding is not re-reported and the verification confirms the fix at the fixed location); Reviewer V, the fourth-round checkpoint reviewers, and a seeded re-run's first-round reviewers MUST each return an explicit resolved/unresolved verdict per member, and when verdicts diverge any `unresolved` verdict keeps the member in the set; every exit-(a) removal MUST be recorded in the removing round's `## Fix Actions` naming the member, the resolving fix reference, and the verifying reviewer; or (b) accepted — the finding matches, at the same artifact or file with the same defect mechanism, an accepted-risks entry consented per the `Accepted-risks ledger` requirement; the main agent MUST re-evaluate the set against the accepted-risks ledger every round and MUST record each such removal as a downgrade trace in that round file's `## Fix Actions`. Members withheld under grader protection have no autonomous in-loop removal path — a fix is prohibited, and only the consented accepted-risks exit (b) applies to them. When every member of the cumulative blocking set is withheld under grader protection and no consented exit is obtainable, the main agent MUST NOT spawn further reviewer rounds and MUST end the loop with `decision: aborted` and the abort triage; when this condition first holds during a round's fix phase, after the mechanical decision was derived, the current round's not-yet-finalized file records `decision: aborted` with the abort triage, overriding the derived `next_round`. A round after the run's first round passes if and only if, after the confidence filter, the cumulative blocking set contains no `Critical` and no `Warning` finding. The run's first round retains the undivided pass condition: every surviving `Critical` or `Warning` finding in the first round is blocking. In a re-run whose cumulative blocking set was seeded per the `Abort triage` requirement, the run's first round MUST instead use the cumulative-blocking-set pass condition, and its reviewers MUST tag dispositions against the prior run's round files (the bucket-1 triage in the final round file enumerates the seeded members).

A micro round MUST spawn exactly ONE fresh verification reviewer sub-agent (`Reviewer V — Verification`) instead of the two full-round reviewers. Reviewer V MUST receive as context: the artifact paths (and, for apply-plus, the changed-file list), every prior round file of this loop (or the extract fallback defined above), the current cumulative-blocking-set member list, the accepted-risks ledger when it exists, and the same relevant `open` signals context that full-round reviewers receive. Reviewer V's scope MUST be limited to: whether each member of the cumulative blocking set is resolved (whether or not a fix was recorded for it) — returning an explicit resolved/unresolved verdict per member, whether fix propagation is complete (every occurrence of each concept touched by a fix is synchronized across all artifacts and, for apply-plus, the changed files), and whether the fixes introduced new defects. In apply-plus micro rounds, Reviewer V MUST additionally perform the per-round `implementation-notes.md` reading obligation defined for Reviewer A in the Implementation Notes Protocol, including its file-absent and `open-question` severity rules. Reviewer V findings MUST carry the same fields as full-round findings (including `layer`, `confidence`, and `disposition`) and MUST pass through the same confidence filter. If the cumulative blocking set is empty after the filter in a micro round, the decision is `passed`; if any blocking `Critical` or `Warning` remains, the decision is `next_round` and the next round's type is derived from its position within the run per this requirement, subject to the existing 6-round cap (a sixth round that does not meet the pass condition records `decision: aborted`).

#### Scenario: Round after the first round defaults to a micro round

- **WHEN** the run's first round completes with `decision: next_round`
- **THEN** the second round is derived as a micro round
- **AND** the second round spawns exactly one `Reviewer V` sub-agent

#### Scenario: Fourth round checkpoint is a full round

- **WHEN** the run's third round completes with `decision: next_round`
- **THEN** the fourth round is derived as a full round
- **AND** the fourth round spawns `Reviewer A` and `Reviewer B` in parallel
- **AND** both reviewers receive every prior round file of this loop (or the defined extract fallback) and the current cumulative-blocking-set member list in their context
- **AND** both reviewers additionally return the same per-member resolved/unresolved verdicts over the cumulative blocking set as Reviewer V, so exit-(a) removals stay available at the checkpoint
- **AND** when the two reviewers' verdicts for a member diverge, any `unresolved` verdict keeps the member in the set

#### Scenario: Rounds after the checkpoint return to micro

- **WHEN** the run's fourth round completes with `decision: next_round`
- **THEN** the fifth round is derived as a micro round
- **AND** consecutive micro rounds (fifth and sixth) are valid

#### Scenario: Behavior-modifying fixes do not escalate the round type

- **WHEN** a fix action after a round's decision modifies implementation behavior or a design statement
- **THEN** the next round's type remains derived from its position within the run alone
- **AND** no re-derivation to a full round occurs

#### Scenario: New finding routes to triage instead of blocking

- **WHEN** a round after the run's first round surfaces a surviving `Critical` finding whose verified disposition is `new`
- **THEN** the main agent records it as a triage note in that round file's `## Fix Actions` section
- **AND** it enters the signals write step target set and the completion output with a follow-up change proposal recommendation
- **AND** it does not participate in the round decision

#### Scenario: Fix-introduced regression blocks the pass

- **WHEN** a round after the run's first round surfaces a surviving `Critical` finding whose `introduced_by` references modifications recorded in prior `## Fix Actions` sections of this loop
- **THEN** the finding's disposition is `fix-introduced` and it is blocking
- **AND** the round file records `decision: next_round`

#### Scenario: Ineffective fix keeps the finding blocking

- **WHEN** a resolving fix was recorded for a blocking finding and a later round re-reports the same finding at the same location with the same defect mechanism
- **THEN** the finding's disposition is `unresolved-prior` and it remains blocking
- **AND** it is not routed to the `new` bucket on account of the recorded fix

#### Scenario: Cumulative set member is removed only by verified resolution or acceptance

- **WHEN** a resolving fix is recorded for a cumulative-blocking-set member and the subsequent round's reviewer verifies the resolution without re-reporting it
- **THEN** the member is removed from the cumulative blocking set

- **WHEN** a cumulative-blocking-set member matches a consented accepted-risks entry at the same file with the same defect mechanism
- **THEN** the member is removed from the cumulative blocking set
- **AND** the removal is recorded as a downgrade trace in that round file's `## Fix Actions`

#### Scenario: Triaged non-blocking finding does not re-enter the blocking set

- **WHEN** a later round re-reports a finding whose most recent prior status in this loop is a non-blocking triage note, at the same location with the same defect mechanism, without new evidence attributing it to recorded fix actions
- **THEN** the finding remains non-blocking
- **AND** it does not cause a `next_round` decision

#### Scenario: Seeded member blocks a re-run's first round

- **WHEN** a re-run's first round completes, a seeded bucket-1 member is not re-reported by the round's reviewers, and its per-member verdict is `unresolved` (or no resolving fix was recorded for it in the prior run)
- **THEN** the cumulative blocking set still contains that member
- **AND** the round's decision is not `passed`

#### Scenario: Unresolved blocking finding cannot be silently passed

- **WHEN** a prior round's blocking finding has only a grader-protection note and no resolving fix, and the current round's reviewer does not re-report it
- **THEN** the cumulative blocking set still contains that finding
- **AND** the current round's decision is not `passed`

#### Scenario: Fully grader-protected blocking set short-circuits to abort

- **WHEN** every member of the cumulative blocking set is withheld under grader protection and no consented accepted-risks exit is obtainable
- **THEN** the main agent does not spawn further reviewer rounds
- **AND** the loop ends immediately with `decision: aborted` and the abort triage

#### Scenario: Divergent dispositions merge conservatively

- **WHEN** findings deduplicated by `location + summary` carry divergent `disposition` values
- **THEN** the merged finding takes the blocking disposition, with `unresolved-prior` or `fix-introduced` winning over `new`

#### Scenario: Disposition correction leaves a trace

- **WHEN** the main agent corrects a reviewer's `disposition` tag from `fix-introduced` to `new`
- **THEN** that round file's `## Fix Actions` records the finding, the original tag, the corrected tag, and the evidence
- **AND** the completion output lists the correction because it changed a blocking disposition to a non-blocking one

#### Scenario: Completed round files are immutable during the loop

- **WHEN** a fix action could shrink the cumulative blocking set by inserting a fix record or triage note into a prior round's file
- **THEN** the main agent does not edit the prior round file
- **AND** fix records and triage notes are written only in the round in which they occur

#### Scenario: Micro round with an empty cumulative blocking set passes the loop

- **WHEN** a micro round completes and the cumulative blocking set contains no `Critical` and no `Warning` finding after the confidence filter
- **THEN** the round file records `decision: passed` and `round_type: micro`
- **AND** the loop stops

#### Scenario: Apply-plus micro round reads implementation notes

- **WHEN** an apply-plus micro round begins
- **THEN** Reviewer V reads `openspec/changes/<change>/implementation-notes.md` per the Implementation Notes Protocol
- **AND** a missing file yields a `Critical` finding
- **AND** an unresolved `open-question` entry yields a `Warning` finding

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

##### Example: next-round-type derivation by position within the run

| Current round position | Next round position | Next round type |
| ---------------------- | ------------------- | --------------- |
| 1st (full)  | 2nd | micro |
| 2nd (micro) | 3rd | micro |
| 3rd (micro) | 4th | full  |
| 4th (full)  | 5th | micro |
| 5th (micro) | 6th | micro |

### Requirement: Fresh sub-agent per round

The system SHALL spawn fresh sub-agents for every review step. The skill MUST NOT reuse a sub-agent across rounds. Each FULL round MUST spawn exactly TWO reviewer sub-agents in parallel — `Reviewer A` (artifact/implementation adherence) and `Reviewer B` (bug/quality scan). Each MICRO round MUST spawn exactly ONE fresh verification reviewer sub-agent — `Reviewer V` (delta verification), per the `Graded convergence and micro-verification round` requirement. The skill MUST NOT spawn a rater sub-agent. The skill MUST NOT perform review inline in the main agent context. A pre-spawn short-circuit abort round per the `Abort triage` requirement records `round_type: full` but spawns no reviewer sub-agents; it is the explicit exception to the two-reviewer mandate. After the round's reviewer sub-agents complete, the main agent SHALL aggregate findings (deduplicate by `location + summary`), apply the confidence filter (see `Confidence-scored findings` requirement), and derive the round decision mechanically without any further sub-agent call — from the filtered findings in the run's first round (or, in a seeded re-run's first round, from the cumulative blocking set), and from the cumulative blocking set defined by the `Graded convergence and micro-verification round` requirement in every later round.

#### Scenario: Two reviewers and no rater per round

- **WHEN** a full round begins
- **THEN** the skill makes two parallel sub-agent calls for `Reviewer A` and `Reviewer B`, dispatched in a single message
- **AND** makes no rater sub-agent call
- **AND** Reviewer A and Reviewer B do not see each other's findings
- **AND** the main agent derives `decision` from the post-filter findings and the cumulative blocking set itself

#### Scenario: Micro round spawns exactly one verification reviewer

- **WHEN** a micro round begins
- **THEN** the skill makes exactly one sub-agent call for `Reviewer V`
- **AND** makes no `Reviewer A`, `Reviewer B`, or rater sub-agent call in that round
- **AND** the main agent derives `decision` from the post-filter findings and the cumulative blocking set itself

#### Scenario: No sub-agent reuse across rounds

- **WHEN** round N+1 begins after round N
- **THEN** the skill spawns brand-new reviewer sub-agents for round N+1 (`Reviewer A` and `Reviewer B` for a full round, `Reviewer V` for a micro round)
- **AND** does not pass the prior round's sub-agent state forward

### Requirement: spectra-propose-plus quality gate

The system SHALL provide a `spectra-propose-plus` skill that mirrors the steps of `spectra-propose` for artifact creation (proposal, design, specs, tasks) but replaces the inline self-review and analyze-fix loop with a sub-agent review/rating/fix loop. The skill MUST run `spectra validate` before entering the sub-agent loop, so validation fixes happen before the quality gate reviews the final artifact state. The skill MUST run the loop at per-change granularity (after all required artifacts are written and validation has passed, not per artifact). The skill MUST cap the loop at 6 rounds. The skill MUST NOT use a rater sub-agent and MUST NOT produce a `quality_score`; instead the main agent SHALL derive the round decision mechanically from the post-filter findings. The run's first round MUST be treated as passing if and only if, after the confidence filter, no surviving finding has `severity == Critical` and no surviving finding has `severity == Warning`; in a re-run whose cumulative blocking set was seeded, the first round instead uses the cumulative-blocking-set pass condition per the `Graded convergence and micro-verification round` requirement. A round after the run's first round MUST be treated as passing if and only if, after the confidence filter, the cumulative blocking set contains no `Critical` and no `Warning` finding, where blocking and the cumulative blocking set are defined by the `Graded convergence and micro-verification round` requirement; non-blocking findings route to triage per that requirement. When a round's decision is `next_round`, the main agent MUST derive the next round's type (full or micro) per the `Graded convergence and micro-verification round` requirement. Fix obligations in this requirement are subject to the grader-protection exception defined in the `Review loop grader immutability` requirement and to the consented accepted-risks path defined in the `Accepted-risks ledger` and `Review round action obligation` requirements. The skill MUST NOT execute `spectra park` at the end of its workflow.

#### Scenario: Loop reaches pass condition before max rounds

- **WHEN** a round completes with an empty cumulative blocking set after the confidence filter
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

#### Scenario: Surviving blocking Warning forces another round

- **WHEN** a round completes with no blocking `Critical` finding but at least one blocking `Warning` finding in the cumulative blocking set after the confidence filter
- **THEN** the skill writes the round file with `decision: next_round`
- **AND** fixes the blocking Warning findings before starting the next round, except any finding withheld under the `Review loop grader immutability` requirement (recorded as unfixed-due-to-grader-protection and remaining surviving) and any finding accepted through the consent path of the `Accepted-risks ledger` requirement (recorded as a downgrade trace and removed from the cumulative blocking set)
- **AND** derives the next round's type per the `Graded convergence and micro-verification round` requirement

#### Scenario: Loop hits 6-round cap without passing

- **WHEN** the loop completes 6 rounds without meeting the pass condition
- **THEN** the skill writes the sixth round with `decision: aborted`
- **AND** prints a warning summarising the unresolved findings
- **AND** runs the abort triage per the `Abort triage` requirement
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

The system SHALL provide a `spectra-apply-plus` skill that mirrors `spectra-apply` for task execution and appends a sub-agent review/rating/fix loop after all tasks complete. The skill MUST run the loop at per-change granularity (once, after every task is marked complete in `tasks.md`). The skill MUST cap the loop at 6 rounds. The skill MUST NOT suggest archiving the change before the review loop has ended with `decision: passed`. The skill MUST NOT use a rater sub-agent and MUST NOT produce a `quality_score`; instead the main agent SHALL derive the round decision mechanically from the post-filter findings. The run's first round MUST be treated as passing if and only if, after the confidence filter, no surviving finding has `severity == Critical` and no surviving finding has `severity == Warning`; in a re-run whose cumulative blocking set was seeded, the first round instead uses the cumulative-blocking-set pass condition per the `Graded convergence and micro-verification round` requirement. A round after the run's first round MUST be treated as passing if and only if, after the confidence filter, the cumulative blocking set contains no `Critical` and no `Warning` finding, where blocking and the cumulative blocking set are defined by the `Graded convergence and micro-verification round` requirement; non-blocking findings route to triage per that requirement. When a round's decision is `next_round`, the main agent MUST derive the next round's type (full or micro) per the `Graded convergence and micro-verification round` requirement. Fix obligations in this requirement are subject to the grader-protection exception defined in the `Review loop grader immutability` requirement and to the consented accepted-risks path defined in the `Accepted-risks ledger` and `Review round action obligation` requirements.

#### Scenario: Review loop runs after tasks complete

- **WHEN** every checkbox in `tasks.md` reads `[x]`
- **THEN** `spectra-apply-plus` starts the sub-agent review/rating/fix loop
- **AND** does not start the loop earlier

#### Scenario: Surviving blocking Critical forces another round

- **WHEN** a round completes with at least one blocking `Critical` finding in the cumulative blocking set after the confidence filter
- **THEN** the skill writes the round file with `decision: next_round`
- **AND** fixes the blocking Critical findings before starting the next round, except any finding withheld under the `Review loop grader immutability` requirement (recorded as unfixed-due-to-grader-protection and remaining surviving) and any finding accepted through the consent path of the `Accepted-risks ledger` requirement (recorded as a downgrade trace and removed from the cumulative blocking set)
- **AND** derives the next round's type per the `Graded convergence and micro-verification round` requirement

#### Scenario: Loop hits 6-round cap

- **WHEN** the loop completes 6 rounds without meeting the pass condition
- **THEN** the skill writes the sixth round with `decision: aborted`
- **AND** prints a warning summarising the unresolved findings
- **AND** runs the abort triage per the `Abort triage` requirement
- **AND** ends the workflow

#### Scenario: Archive guidance waits for gate pass

- **WHEN** all tasks are complete but the review loop has not passed yet
- **THEN** `spectra-apply-plus` states that archive guidance is deferred until the plus quality gate passes
- **AND** does not tell the user to run `spectra archive`, `/spectra-archive`, or `$spectra-archive`

- **WHEN** the final review-loop round has `decision: passed`
- **THEN** the final response may suggest archiving the change

### Requirement: Confidence-scored findings and filter

The system SHALL require every reviewer finding to carry a `confidence` integer from `0` to `100`. The main agent MUST apply a confidence filter before deriving the round decision. Findings with `confidence < 50` MUST be dropped entirely and SHALL NOT appear in the round file's `## Reviewer Findings` section; downgrade traces mandated by the `Accepted-risks ledger` and `Apply-plus introduced-by evidence` requirements appear in `## Fix Actions` and are the explicit exception. Findings with `confidence` in `[50, 80)` MUST be downgraded to `Suggestion` regardless of the reviewer's original severity classification. Only findings with `confidence >= 80` MAY appear as `Critical` or `Warning` in the post-filter round file. `critical_gap` MUST be `true` if and only if the post-filter cumulative blocking set contains at least one `Critical` finding (in the run's first round, at least one surviving `Critical` finding with `confidence >= 80`; a seeded re-run's first round uses the cumulative blocking set). Direct artifact-requirement violations (citing a specific `SHALL`, Implementation Contract item, or task description line) MUST score `100` so the filter does not demote them. The accepted-risks downgrade defined in the `Accepted-risks ledger` requirement and the apply-plus `introduced_by` downgrade defined in the `Apply-plus introduced-by evidence` requirement take precedence over the score-100 invariant: a finding that matches an accepted-risks entry, or an apply-plus `Reviewer B` `Critical` or `Warning` finding without a verifiable `introduced_by`, MUST be scored at most `25` even when it cites a specific artifact clause.

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

#### Scenario: Accepted-risk match overrides the score-100 invariant

- **WHEN** a finding cites a specific artifact clause AND matches an accepted-risks entry at the same location with the same defect mechanism
- **THEN** the main agent scores the finding at most `25`
- **AND** the finding does not survive as `Critical` or `Warning`

### Requirement: Round file output contract

The system SHALL write one round file per loop round to `openspec/changes/<change>/reviews/`. File names MUST follow the pattern `propose-r<N>.md` for `spectra-propose-plus` and `apply-r<N>.md` for `spectra-apply-plus`, where `<N>` is the 1-based round number; a re-run after an abort continues `<N>` from the last existing round file per the `Abort triage` requirement. Each round file MUST contain exactly four top-level `##` sections, in this fixed order: `## Reviewer Findings`, `## Rating`, `## Fix Actions`, `## Decision`, plus the round heading at the top. The `## Rating` section MUST NOT contain a `quality_score` field; it MUST record the `Critical` count and the `Warning` count of the post-filter cumulative blocking set (in the run's first round, of the surviving findings, which are all blocking; in a seeded re-run's first round, of the cumulative blocking set), the count of non-blocking triaged findings, `critical_gap` (boolean), `round_type` (exactly one of `full` or `micro`), and a rationale paragraph explaining the mechanical decision.

#### Scenario: Round file structure

- **WHEN** any round of a plus skill completes
- **THEN** a file at `openspec/changes/<change>/reviews/<skill>-r<N>.md` exists
- **AND** the file starts with a level-1 heading naming the skill and round
- **AND** the file contains exactly four `##` headings: `Reviewer Findings`, `Rating`, `Fix Actions`, `Decision`, and the leading round summary heading is `#` not `##`

#### Scenario: Rating section omits quality_score

- **WHEN** the `## Rating` section of any round file is written
- **THEN** it contains no `quality_score` field
- **AND** it records the cumulative blocking set's `Critical` count, the cumulative blocking set's `Warning` count, the non-blocking triaged count, `critical_gap`, `round_type`, and a rationale paragraph

##### Example: required round file outline

| Section                | Heading level | Content                                                                                                            |
| ---------------------- | ------------- | ------------------------------------------------------------------------------------------------------------------ |
| Round heading          | `#`           | e.g., `Propose Plus Review — Round 2`                                                                              |
| `Reviewer Findings`    | `##`          | Three subsections: Critical, Warning, Suggestion. Each finding lists `severity`, `confidence`, `layer`, `location`, `summary`, `recommendation`, `disposition` (rounds after the first, and a seeded re-run's first round), `introduced_by` (apply-plus Reviewer B findings, and any finding tagged `fix-introduced`), and reviewer source (`A`, `B`, `A+B`, or `V`) |
| `Rating`               | `##`          | cumulative blocking `Critical` count, cumulative blocking `Warning` count, non-blocking triaged count, `critical_gap` (boolean), `round_type` (`full` or `micro`), `rationale` (text) |
| `Fix Actions`          | `##`          | List of changes made this round with file paths and rationale, plus triage notes, downgrade traces, and disposition-correction records |
| `Decision`             | `##`          | One of `passed`, `next_round`, `aborted`                                                                           |

#### Scenario: Final round decision values

- **WHEN** the loop ends successfully
- **THEN** the final round file has `Decision: passed`

- **WHEN** the loop ends by hitting the 6-round cap
- **THEN** the final round file has `Decision: aborted`

### Requirement: Review loop grader immutability

The system SHALL extend the shared review-loop template `scripts/spectra-plus/template/review-loop-block.md` with a grader-immutability rule marked by the unique sentinel comment `<!-- GRADER-IMMUTABILITY -->`. During a plus review loop, the main agent MUST NOT modify — whether as a fix action or as a mechanical self-check fix — any file in the protected grader path set: files under `scripts/spectra-plus/template/`, `scripts/spectra-plus/rules.yaml`, `scripts/spectra-plus/generate.fish`, the generated plus skill files (`.claude/skills/spectra-propose-plus/SKILL.md`, `.claude/skills/spectra-apply-plus/SKILL.md`, `.agents/skills/spectra-propose-plus/SKILL.md`, `.agents/skills/spectra-apply-plus/SKILL.md`), `.spectra.yaml`, and the master spec files under `openspec/specs/` — unless that file is explicitly named by the current change's structured scope declarations. Structured scope declarations are limited to project-root-relative paths in the proposal `## Impact` affected-code entries and project-root-relative paths in `tasks.md` that are explicitly identified as delivery targets. A path that appears only in a verification command, a rule description, an example, a review finding, reviewer context, or other incidental prose MUST NOT count as a structured scope declaration. Naming a directory path in a structured scope declaration names all files under it. When a file under `scripts/spectra-plus/template/` is named in the structured scope declarations, its regenerated outputs (the four generated plus skill files) count as named as well, so the mandatory regeneration step is never blocked by this rule; a loop already in progress continues under the instruction version it started with, and regenerated instructions take effect from the next loop run. In addition, the main agent MUST NOT add, modify, or remove the `check` frontmatter field of any signal under `openspec/signals/`, regardless of declared scope — the `check` field is grader input for the pre-round mechanical self-check. When a surviving finding's resolution would require modifying a protected file outside that structured scope, or touching a signal's `check` field, the fix action MUST NOT perform the modification, MUST record an unfixed-due-to-grader-protection note naming the file and the finding in `## Fix Actions`, and the finding remains surviving for the round decision. The plus workflow's completion output MUST list every unfixed-due-to-grader-protection note recorded in any round of the loop, regardless of the final decision: for `spectra-propose-plus` with `decision: passed`, the notes MUST be listed in the final summary; for `spectra-apply-plus` with `decision: passed`, the notes MUST be listed in the gate-complete final response; for any `decision: aborted`, the notes MUST be listed in the unresolved-findings warning. A protected file modified under the structured-scope exception is treated like any other fix-action modification and does not change the next round's type, which is derived from its position within the run alone per the `Graded convergence and micro-verification round` requirement. Because both `spectra-propose-plus` and `spectra-apply-plus` consume this template, this rule MUST apply to both generated plus skills.

#### Scenario: Out-of-scope grader modification is refused

- **WHEN** a review-loop finding's recommendation requires editing `scripts/spectra-plus/rules.yaml` and the current change's structured scope declarations do not name that file
- **THEN** the fix action does not modify `scripts/spectra-plus/rules.yaml`
- **AND** the round file's `## Fix Actions` records an unfixed-due-to-grader-protection note naming the file and the finding
- **AND** the finding still counts toward the round decision

#### Scenario: Incidental protected path text does not unlock a grader file

- **WHEN** `tasks.md` mentions `openspec/specs/` only while describing the grader-protection rule or a verification step
- **THEN** that mention does not count as a structured scope declaration
- **AND** the main agent MUST NOT modify files under `openspec/specs/` through the grader-immutability exception

#### Scenario: Signal check field is never modified by a fix action

- **WHEN** a pre-round self-check `check` command fails and a fix action could make it pass by weakening or removing that signal's `check` field
- **THEN** the fix action does not add, modify, or remove any signal's `check` field
- **AND** the underlying defect is fixed in the change's own artifacts or files instead

#### Scenario: Declared-scope grader file stays modifiable

- **WHEN** the current change's structured scope declarations explicitly name `scripts/spectra-plus/template/review-loop-block.md` and a fix action modifies that file
- **THEN** the modification is permitted, and regenerating the four plus skill files is also permitted
- **AND** the modification does not change the next round's type, which is derived from its position within the run alone

#### Scenario: Completion output anchors grader-protection records

- **WHEN** any round of a loop recorded an unfixed-due-to-grader-protection note and the loop later ends with `decision: passed` for `spectra-propose-plus`
- **THEN** the final summary lists every such note from every round of the loop

- **WHEN** any round of a loop recorded an unfixed-due-to-grader-protection note and the loop later ends with `decision: passed` for `spectra-apply-plus`
- **THEN** the gate-complete final response lists every such note from every round of the loop

- **WHEN** any round of a loop recorded an unfixed-due-to-grader-protection note and the loop ends with `decision: aborted`
- **THEN** the unresolved-findings warning lists every such note from every round of the loop

#### Scenario: Generated skills carry the grader-immutability sentinel

- **WHEN** the generator produces the four plus skill files
- **THEN** each generated file contains the `<!-- GRADER-IMMUTABILITY -->` sentinel and the protected grader path set
- **AND** `scripts/spectra-plus/tests/generator-checks.fish` asserts the sentinel's presence

### Requirement: Review loop ledger output

The system SHALL extend the shared review-loop template with a ledger step marked by the unique sentinel comment `<!-- LOOP-LEDGER-STEP -->`. For each round, the main agent MUST append exactly one row to `openspec/changes/<change>/reviews/loop-ledger.tsv` at a deterministic point: for a `next_round` round, immediately before spawning the next round's reviewers — after every action that can write to the round file's `## Fix Actions` has completed, including fix actions, post-fix self-check records, and validation re-run fix records; for the final round (`passed` or `aborted`), at loop end before the signals write step. When the file does not exist, the main agent MUST create it with a single header row before appending; the header row MUST contain exactly the seven column names in order, tab-separated: `skill`, `round`, `round_type`, `criticals`, `warnings`, `decision`, `fixed_files`. Each row MUST contain, tab-separated and in this order: `skill` (`propose` or `apply`), `round` (1-based integer matching the round file number), `round_type` (`full` or `micro`), `criticals` (the post-filter cumulative blocking set's Critical count — in the run's first round every surviving Critical is blocking, and a seeded re-run's first round uses the cumulative blocking set; `0` when the cumulative blocking set is empty after filtering, including rounds aborted by sub-agent failure), `warnings` (the post-filter cumulative blocking set's Warning count, `0` likewise), `decision` (`passed`, `next_round`, or `aborted`), and `fixed_files` (the number of distinct files recorded as modified in that round's `## Fix Actions`, `0` when none are recorded; note lines such as fallback, triage, downgrade-trace, disposition-correction, or grader-protection notes do not count). The ledger is an append-only event log: rows from the propose loop, the apply loop, and any re-run loop after an abort accumulate chronologically in the same file, and `(skill, round)` is NOT a unique key — duplicate round numbers from historical re-runs are valid. Round files remain the authoritative record; on any inconsistency between a round file and the ledger, the round file governs. A ledger write failure MUST produce a printed warning and MUST NOT fail the plus workflow. Because both plus skills consume this template, this behavior MUST apply to both.

#### Scenario: One ledger row per completed round of a loop run

- **WHEN** a single plus review loop run completes N rounds for a change
- **THEN** that run appends exactly N data rows to `openspec/changes/<change>/reviews/loop-ledger.tsv`
- **AND** the header row exists exactly once at the top of the file

##### Example: three-round propose loop followed by a two-round apply loop

| skill | round | round_type | criticals | warnings | decision | fixed_files |
| ----- | ----- | ---------- | --------- | -------- | -------- | ----------- |
| propose | 1 | full | 1 | 2 | next_round | 3 |
| propose | 2 | micro | 0 | 1 | next_round | 1 |
| propose | 3 | micro | 0 | 0 | passed | 0 |
| apply | 1 | full | 0 | 1 | next_round | 2 |
| apply | 2 | micro | 0 | 0 | passed | 0 |

#### Scenario: Ledger is created with a header row

- **WHEN** round 1 of a loop completes and no `loop-ledger.tsv` exists for the change
- **THEN** the main agent creates the file with one header row and one data row

#### Scenario: Carryover findings keep the ledger self-explaining

- **WHEN** a round's reviewers re-report nothing but the cumulative blocking set still contains one `Critical` finding
- **THEN** that round's ledger row records `criticals` = 1 with `decision` = `next_round`

#### Scenario: Re-run after an aborted loop accumulates rows

- **WHEN** a loop ended with `decision: aborted` and a new loop run for the same skill later runs on the same change
- **THEN** the new run's rows are appended after the existing rows
- **AND** the earlier run's rows are not modified or deleted

#### Scenario: Failure-aborted round records zero counts

- **WHEN** a round is aborted because the same reviewer role failed twice, no post-filter findings exist, and the cumulative blocking set is empty
- **THEN** that round's ledger row records `criticals` = 0 and `warnings` = 0 with `decision` = `aborted`

#### Scenario: Ledger write failure does not fail the workflow

- **WHEN** appending to `loop-ledger.tsv` fails
- **THEN** the main agent prints a warning
- **AND** the plus workflow continues unchanged

#### Scenario: Generated skills carry the ledger sentinel

- **WHEN** the generator produces the four plus skill files
- **THEN** each generated file contains the `<!-- LOOP-LEDGER-STEP -->` sentinel
- **AND** `scripts/spectra-plus/tests/generator-checks.fish` asserts the sentinel's presence

## ADDED Requirements

### Requirement: Accepted-risks ledger

The system SHALL support an accepted-risks ledger at `openspec/changes/<change>/reviews/accepted-risks.md`. An entry MUST be created, modified, or deleted only with explicit user consent obtained in the current session; the loop MUST NOT write, edit, or remove an entry autonomously, the main agent MUST NOT modify or delete an existing entry as a fix action during an active loop, and when user interaction is unavailable the candidate finding remains surviving and no entry is written. Each entry MUST record `severity`, `location`, a defect-mechanism description, an acceptance rationale, and the recording date. When the file exists, the main agent MUST include its content in every round's reviewer context. During the confidence filter, the main agent MUST score at most `25` any finding that matches an entry at the same `location` AND the same defect mechanism; recorded line ranges are advisory, and a match holds when the same artifact or file and the same defect mechanism match even though the recorded range has shifted. A finding that shares only a subsystem or issue class with an entry MUST NOT be downgraded on that basis. Every downgrade applied under this requirement MUST be recorded in that round file's `## Fix Actions` section naming the finding and the matched entry, and the completion output MUST list every accepted-risks downgrade applied in any round of the loop. If writing the file fails, the skill MUST print a warning and MUST NOT fail the plus workflow.

#### Scenario: Matching finding is downgraded with a recorded trace

- **WHEN** a reviewer reports a finding whose `location` and defect mechanism match an accepted-risks entry
- **THEN** the main agent scores the finding at most `25` during the confidence filter
- **AND** the finding does not survive as `Critical` or `Warning`
- **AND** that round file's `## Fix Actions` records the downgrade naming the finding and the matched entry
- **AND** the completion output lists the downgrade

#### Scenario: Same subsystem with a different mechanism is not downgraded

- **WHEN** a reviewer reports a finding in the same subsystem as an accepted-risks entry but with a different defect mechanism
- **THEN** the finding passes through the confidence filter with its reviewer-assigned confidence
- **AND** no accepted-risks downgrade applies

#### Scenario: Shifted line range still matches

- **WHEN** a finding matches an accepted-risks entry's file and defect mechanism but the entry's recorded line range no longer corresponds after later edits
- **THEN** the match holds and the downgrade applies

#### Scenario: No consent means no entry

- **WHEN** the main agent identifies a candidate accepted risk and cannot obtain explicit user consent in the current session
- **THEN** no entry is written to `accepted-risks.md`
- **AND** the finding remains surviving for the round decision

#### Scenario: Entries are not editable as fix actions

- **WHEN** a fix action could resolve a surviving finding by broadening or deleting an existing accepted-risks entry
- **THEN** the main agent does not modify or delete the entry
- **AND** any entry change happens only through explicit user consent in the current session

#### Scenario: Ledger enters reviewer context

- **WHEN** a round's reviewers are spawned and `openspec/changes/<change>/reviews/accepted-risks.md` exists
- **THEN** every reviewer of that round receives the file content in its context

### Requirement: Fix-loop design circuit breaker

In apply-plus review loops, when resolving a surviving finding requires introducing a synchronization primitive (such as a mutex, lock, or semaphore), an identity or generation type (such as a token, epoch, or generation id), or a state machine that `design.md` does not define, the main agent MUST NOT implement that mechanism as a fix action. The main agent MUST record a needs-design note in that round's `## Fix Actions` section naming the finding, the required mechanism, and a one-line reason; MUST write that round file with `decision: aborted`; MUST run the abort triage per the `Abort triage` requirement; and the completion output MUST direct the user to update `design.md` via `/spectra-ingest` before re-entering an apply workflow. In propose-plus rounds, defining the needed mechanism in the change's own `design.md` is a normal fix action and this circuit breaker MUST NOT trigger. The `decision` value set MUST remain exactly `passed`, `next_round`, and `aborted`; no additional decision value is introduced for this rule.

#### Scenario: Fix requiring a new state machine trips the breaker

- **WHEN** resolving a surviving `Critical` finding in an apply-plus loop requires introducing a lease state machine that `design.md` does not define
- **THEN** the main agent does not implement the state machine as a fix action
- **AND** records a needs-design note in `## Fix Actions`
- **AND** writes the round file with `decision: aborted`
- **AND** the completion output directs the user to `/spectra-ingest`

#### Scenario: Mechanism already defined in design is a normal fix

- **WHEN** resolving a surviving finding in an apply-plus loop uses only mechanisms that `design.md` already defines
- **THEN** the fix proceeds as a normal fix action
- **AND** the circuit breaker does not trigger

#### Scenario: Propose-plus design edits do not trip the breaker

- **WHEN** a propose-plus finding is resolved by defining a needed synchronization mechanism in the change's own `design.md`
- **THEN** the edit proceeds as a normal fix action
- **AND** the circuit breaker does not trigger

### Requirement: Abort triage

When a review loop ends with `decision: aborted` due to the round cap, the fix-loop design circuit breaker, or the fully-grader-protected short-circuit, the main agent MUST triage every unresolved surviving finding into exactly one of three buckets and record the triage both in the final aborted round file's `## Fix Actions` section and in the completion output: (1) findings that remain the change's obligation — every cumulative-blocking-set member not accepted through consent, whatever its disposition or lack of one (fix-introduced regressions and unresolved-prior findings are the typical cases); (2) newly discovered or design-level issue that was never blocking in this loop — the finding is written to signals, and for a `Critical` finding the output MUST recommend creating a follow-up change proposal; (3) accepted trade-off — the finding is written to the accepted-risks ledger under the consent rules of the `Accepted-risks ledger` requirement; when consent cannot be obtained in the current session, the finding MUST be triaged to bucket 1 instead — it remains the change's obligation and seeds a re-run — with a note that accepted-risks recording was deferred pending user consent. Bucket 2 MUST NOT receive any finding that was blocking in this loop. The completion output MUST NOT recommend re-running the same loop without this triage. A loop re-run after an abort MUST NOT overwrite prior round files: its round files continue numbering from the last existing round file for that skill, while the 6-round cap and the round-type derivation operate on positions within the new run (its first round is a full round). The re-run's first-round reviewer context MUST include the prior run's round files (or their extracts per the extract fallback), and the re-run's cumulative blocking set MUST be seeded with the prior run's bucket-1 findings so they re-enter review as blocking; the re-run's first-round reviewers MUST return the same per-member resolved/unresolved verdicts as Reviewer V, so a seed whose resolving fix was recorded in the prior run can leave the set at the re-run's first round. When a seeded re-run's entire seeded set is withheld under grader protection and no consented exit is obtainable, the short-circuit is evaluated before spawning the re-run's first-round reviewers: the run writes exactly one round file (continued numbering, `round_type: full`, no reviewer findings, `decision: aborted`) carrying the triage, appends one ledger row with the same `round_type`, and its completion output MUST direct the user to either obtain consent for the protected members or expand the change's structured scope declarations via `/spectra-ingest` before any further re-run. Aborts caused by consecutive sub-agent failures retain the existing failure-handling behavior and are exempt from this triage; proposal-level scope-error aborts are likewise exempt, because the change is expected to be re-proposed from scratch rather than re-run.

#### Scenario: Round-cap abort produces a three-bucket triage

- **WHEN** the loop writes its sixth round with `decision: aborted` and unresolved surviving findings remain
- **THEN** the final round file's `## Fix Actions` and the completion output assign every unresolved finding to exactly one of the three triage buckets
- **AND** the output does not recommend re-running the same loop without triage

#### Scenario: Unavailable consent keeps the finding with the change

- **WHEN** an aborted loop triages a blocking trade-off finding and explicit user consent cannot be obtained in the current session
- **THEN** the finding is triaged to bucket 1, remains the change's obligation, and seeds a re-run's cumulative blocking set
- **AND** the triage records that accepted-risks recording was deferred pending user consent

#### Scenario: Fully protected seeded re-run aborts before spawning reviewers

- **WHEN** a seeded re-run starts and its entire seeded cumulative blocking set is withheld under grader protection with no consented exit obtainable
- **THEN** the run writes exactly one round file with continued numbering, `round_type: full`, and `decision: aborted` carrying the triage, and appends one ledger row, without spawning reviewers
- **AND** the completion output directs the user to obtain consent for the protected members or expand the structured scope declarations via `/spectra-ingest` before any further re-run

#### Scenario: Re-run continues round numbering and consumes the triage

- **WHEN** a loop for the same skill re-runs after an abort whose last round file is `apply-r6.md`
- **THEN** the re-run's first round file is `apply-r7.md` and no prior round file is overwritten
- **AND** the re-run's first round is a full round whose reviewer context includes `apply-r6.md`
- **AND** the re-run's cumulative blocking set is seeded with the prior run's bucket-1 findings
- **AND** the re-run's 6-round cap and round-type derivation count from its own first round

### Requirement: Apply-plus introduced-by evidence

In apply-plus rounds, every `Critical` or `Warning` finding from `Reviewer B` MUST include an `introduced_by` field citing either a concrete location in this change's diff (file path plus the introduced behavior), one or more fix-action records from this loop, or — for a regression emerging from the interaction of several fixes — the set of fix actions of a named round. During the confidence filter, the main agent MUST score at most `25` any apply-plus `Reviewer B` `Critical` or `Warning` finding whose `introduced_by` is absent or cannot be verified against the change diff or the recorded fix actions; every downgrade applied under this rule MUST be recorded in that round file's `## Fix Actions` naming the finding and the reason the evidence was unverifiable, and the completion output MUST list every such downgrade. This requirement does not apply to propose-plus rounds.

#### Scenario: Missing introduced_by is downgraded with a recorded trace

- **WHEN** an apply-plus `Reviewer B` finding classified `Critical` carries no `introduced_by` field
- **THEN** the main agent scores it at most `25` during the confidence filter
- **AND** it does not survive as `Critical` or `Warning`
- **AND** that round file's `## Fix Actions` records the downgrade and the reason
- **AND** the completion output lists the downgrade

#### Scenario: Verified introduced_by survives the filter

- **WHEN** an apply-plus `Reviewer B` finding cites an `introduced_by` location that the main agent verifies against the change diff
- **THEN** the finding passes through the confidence filter with its reviewer-assigned confidence

#### Scenario: Interaction regression cites a fix-action set

- **WHEN** an apply-plus `Reviewer B` finding attributes a regression to the interaction of several fixes and cites the set of fix actions of a named round as its `introduced_by`
- **THEN** the citation is verifiable evidence and no introduced-by downgrade applies

### Requirement: Review round action obligation

When a round's decision is `next_round`, every surviving `Critical` or `Warning` finding AND every cumulative-blocking-set member counted in the round decision MUST have at least one recorded action in that round's `## Fix Actions` section before the next round's reviewers are spawned. For a blocking finding or cumulative-blocking-set member, the valid actions are exactly: a fix listing the modified files, a grader-protection note, or an accepted-risks entry recorded with explicit user consent per the `Accepted-risks ledger` requirement; a non-blocking triage note recorded for a blocking member is not a valid action and has no effect on its blocking status. For a non-blocking (`new`) finding, the valid action is its non-blocking triage note; for a re-report that matches a prior round's non-blocking triage note, the valid action is a one-line cross-reference note naming the original round's triage note (neither a duplicate triage note nor a new signal). Recording a needs-design note is not a `next_round` action: per the `Fix-loop design circuit breaker` requirement it forces `decision: aborted` and never coexists with a `next_round` decision. The main agent MUST NOT spawn the next round's reviewers while any surviving finding has no recorded action.

#### Scenario: Zero-action round cannot advance

- **WHEN** a round's decision is `next_round` and at least one surviving finding has no recorded action in `## Fix Actions`
- **THEN** the main agent does not spawn the next round's reviewers until every surviving finding has a recorded action

#### Scenario: Every surviving finding carries an action record

- **WHEN** a round with `decision: next_round` finishes its fix phase
- **THEN** each surviving `Critical` or `Warning` finding maps to a fix record, a grader-protection note, a non-blocking triage note, or a consented accepted-risks entry in `## Fix Actions`

#### Scenario: Needs-design forces abort instead of another round

- **WHEN** a round records a needs-design note for a surviving finding
- **THEN** that round's decision is `aborted` per the `Fix-loop design circuit breaker` requirement
- **AND** the round does not proceed to `next_round`

### Requirement: Propose-plus impact granularity advisory

After the proposal artifact is written, `spectra-propose-plus` SHALL count the affected-code entries in the proposal `## Impact` section: the count is the number of listed path entries across Modified, New, and Removed, excluding `(none)` placeholder lines; a directory entry counts as one entry, so the count is a lower bound. When the count exceeds 15, the skill MUST print an informational warning that states the count and recommends splitting the change by capability. The warning MUST NOT block the workflow and MUST NOT require user confirmation. When the count is 15 or fewer, the skill MUST print nothing for this check.

#### Scenario: Oversized impact prints an advisory

- **WHEN** the proposal `## Impact` section lists 20 affected-code path entries
- **THEN** the skill prints an informational warning stating the count and recommending a split by capability
- **AND** the workflow continues without requiring confirmation

#### Scenario: Small impact stays silent

- **WHEN** the proposal `## Impact` section lists 10 affected-code path entries
- **THEN** the skill prints nothing for this check

#### Scenario: Placeholder lines are not counted

- **WHEN** the proposal `## Impact` section lists 16 path entries and a `- Removed: (none)` placeholder line
- **THEN** the count is 16 and the advisory is printed

##### Example: advisory threshold

| Affected-code path entries | Advisory printed |
| -------------------------- | ---------------- |
| 8  | no  |
| 15 | no  |
| 16 | yes |
| 29 | yes |
