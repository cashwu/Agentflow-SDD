10. **Sub-Agent Review/Rating/Fix Loop**

   Run this review/rating/fix loop once per change, after the normal workflow has completed its required artifact or task work.

   **Entry conditions**
   - For `spectra-propose-plus`, start this loop only after proposal, design, specs, and tasks artifacts required for apply are complete.
   - For `spectra-apply-plus`, start this loop only after all implementation tasks are complete and `tasks.md 全 [x]`.
   - Do not run this loop per artifact or per task; the granularity is per-change.

   **Round limit and pass condition**
   - Run max 6 rounds.
   - A round passes only when `quality_score > 9` and `critical_gap == false`.
   - If round 6 still does not meet the pass condition, write `decision: aborted`, print the unresolved findings, and end the plus workflow.
   - If a round passes, write `decision: passed`, stop the loop, and continue to the normal final validation or completion summary.

   **Fresh sub-agent calls**
   - Each round MUST spawn TWO fresh reviewer sub-agents in parallel (single message, two tool calls):
     - **Reviewer A — Adherence**: checks that the artifacts (and for apply-plus, the implementation diff) match the prior artifacts. For propose-plus: proposal ↔ design ↔ spec ↔ tasks internal consistency, scope coverage, and acceptance criteria completeness. For apply-plus: implementation matches `design.md` Implementation Contract, `tasks.md` task descriptions, and `spec.md` requirements; `implementation-notes.md` deviations are justified.
     - **Reviewer B — Quality**: scans for bugs, regressions, missing tests, security sharp edges, and risks NOT directly named in the artifacts. For propose-plus: missing risks, unstated assumptions, scope gaps. For apply-plus: logic bugs, error-handling gaps at real boundaries, untested edge cases from spec `##### Example:` blocks.
   - Both reviewers receive identical context (artifact paths and, for apply-plus, the changed-file list) and return findings independently. Do not pass Reviewer A output into Reviewer B or vice versa.
   - After both reviewers complete, the main agent aggregates findings (deduplicate identical issues by `location + summary`) and applies the confidence filter (see below) before passing the filtered set to the rater.
   - Each round MUST spawn a separate fresh sub-agent for the rater role.
   - The reviewer roles and the rater are independent sub-agent calls; do not perform any of them inline in the main agent context.
   - Do not reuse a sub-agent across rounds, and do not pass prior sub-agent state into the next round.
   - The rater receives the filtered, aggregated reviewer findings as input, then independently returns `quality_score`, `critical_gap`, and rationale.

   **Reviewer output requirements**
   - Both reviewers MUST classify each finding into Critical, Warning, or Suggestion.
   - Every finding MUST include the following fields:
     - `severity`: one of `Critical`, `Warning`, `Suggestion` (before filtering)
     - `confidence`: integer `0`–`100`, using the rubric below
     - `location`: artifact + section, or file path + line range
     - `summary`: one-line description of the issue
     - `recommendation`: concrete action to resolve
   - Every finding names the artifact, section, source path, or changed file it applies to.
   - Scope errors at proposal level (e.g., the proposal targets the wrong capability) may set `decision: aborted` instead of continuing fixes.

   **Confidence scoring rubric (per finding)**
   - `0` — Not confident at all. False positive or pre-existing issue. SHOULD NOT be reported.
   - `25` — Somewhat confident. Could be a real issue but the reviewer was unable to verify against artifacts or code.
   - `50` — Moderately confident. Verified to be real, but minor / unlikely to hit in practice / outside the changed scope.
   - `75` — Highly confident. Verified to be real and will hit in practice. Use this when judgment-based impact assessment supports the finding but no direct artifact citation exists.
   - `100` — Certain. Evidence directly confirms the issue, OR the finding cites a specific artifact clause (a `SHALL` in `spec.md`, an Implementation Contract item in `design.md`, a task description line in `tasks.md`, a non-goal in `proposal.md`) that the artifact set or implementation provably does not satisfy.
   - **Direct artifact-requirement violations MUST score `100`.** If a reviewer can name the exact SHALL / contract item / task line being violated, the finding is objectively verifiable and SHALL NOT be downgraded below `100`. This invariant guarantees the confidence filter never demotes an artifact violation to Suggestion.

   **Confidence filter (applied by main agent before rater)**
   - Drop any finding with `confidence < 50`. These do not appear in the round file.
   - Downgrade findings with `confidence ∈ [50, 80)` to `Suggestion` regardless of original severity. They appear in the round file under Suggestion for visibility but do NOT count as Critical.
   - Only findings with `confidence ≥ 80` may be classified as Critical or Warning in the final round file.
   - `critical_gap` is `true` only when at least one finding survives filtering with `severity == Critical` AND `confidence ≥ 80`.
   - The filter exists to keep the review loop signal-to-noise high; the rater sees only the filtered set.

   **Common false positives — do NOT flag**
   The following SHOULD NOT be reported, or if reported MUST be scored ≤ 25:
   - Pre-existing issues on lines not modified by this change (apply-plus) or content not introduced by this proposal (propose-plus).
   - Issues a linter, typechecker, formatter, or compiler would catch (missing imports, type errors, formatting, broken syntax). CI will fail separately; the review loop is not the right channel.
   - Pedantic style nitpicks that a senior engineer would not call out in review.
   - "Missing test coverage" complaints unless `tasks.md` or `design.md` explicitly required the test, or a spec `##### Example:` block is not exercised.
   - Issues already documented as intentional in `design.md`, `implementation-notes.md`, the proposal's Non-Goals section, or `## Alternatives Considered`.
   - Intentional behavior changes that align with the proposal's `## What Changes` or `## Proposed Solution`.
   - Suggestions to add abstractions, configurability, or defensive error handling that the spec/contract did not require — these conflict with Simplicity First.
   - Suggestions to refactor unrelated code touched only incidentally — these conflict with Surgical Changes.

   **Failure handling**
   - If a reviewer or the rater returns no response or malformed output, retry once with a fresh sub-agent invocation for the same role.
   - If both parallel reviewers fail in the same round, treat it as a single role failure (the reviewer role); retry once.
   - If the same role fails two consecutive times in a single round, abort the entire plus workflow.
   - On abort from sub-agent failure, write the current round file with `decision: aborted` and include the failure note in `## Decision`.
   - Do not mark a malformed or failed round as passed, and do not continue to the next round after two consecutive failures.

   **Rater output requirements**
   - The rater writes `quality_score` as a number from 0 to 10.
   - The rater writes `critical_gap` as `true` or `false`.
   - The rater writes one concise rationale paragraph.
   - The rater must not override missing reviewer evidence by optimism alone.
   - The rater SHALL only consider findings that survived the confidence filter; do not re-introduce filtered-out findings.

   **Round file path**
   - Create the reviews directory if needed: `openspec/changes/<change>/reviews/`.
   - For `spectra-propose-plus`, write `openspec/changes/<change>/reviews/propose-r<N>.md`.
   - For `spectra-apply-plus`, write `openspec/changes/<change>/reviews/apply-r<N>.md`.
   - Use `<N>` as the 1-based round number.
   - The generic path pattern is `openspec/changes/<change>/reviews/<skill>-r<N>.md`.

   **Round file schema**
   - `# Propose Plus Review — Round <N>` or `# Apply Plus Review — Round <N>`
   - `## Reviewer Findings` — list aggregated, post-filter findings grouped under Critical / Warning / Suggestion. Each entry MUST include `severity`, `confidence`, `location`, `summary`, `recommendation`, and which reviewer raised it (`A` or `B`; `A+B` if both raised it independently).
   - `## Rating` — `quality_score`, `critical_gap`, rationale paragraph.
   - `## Fix Actions`
   - `## Decision` — value MUST be exactly one of `passed`, `next_round`, or `aborted`.

   **Fix actions**
   - If the decision is `next_round`, fix the concrete findings before starting the next round.
   - Record modified files and the reason for each fix in `## Fix Actions`.
   - Re-run relevant CLI checks or tests before the next round when fixes affect generated artifacts or implementation code.
   - If no fixes are needed because the round passed, write `None; pass condition met.`

   **Round file language**
   - The Round file (`openspec/changes/<change>/reviews/<skill>-r<N>.md`) prose content — Reviewer Findings, Rater rationale, Fix Actions descriptions, and the `## Decision` explanation — MUST be written in Traditional Chinese.
   - **Keep the following verbatim (do not translate):**
     - Section headings: `# Propose Plus Review — Round <N>`, `# Apply Plus Review — Round <N>`, `## Reviewer Findings`, `## Rating`, `## Fix Actions`, `## Decision`.
     - The `decision` value: one of `passed`, `next_round`, `aborted`.
     - Field names and their values: `quality_score` (number 0–10), `critical_gap` (`true` / `false`), `severity`, `confidence`, `location`, `summary`, `recommendation`.
     - Direct quotations from spec delta, master spec, or any other English-language artifact.
     - CLI commands, file paths, code identifiers, artifact IDs, capability slugs.
   - This rule applies to both `spectra-propose-plus` and `spectra-apply-plus` round files because they share this review-loop template.
   - If the user explicitly requests another language later, follow the latest user instruction.
