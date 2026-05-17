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
   - Each round MUST spawn a fresh sub-agent for the reviewer role.
   - Each round MUST spawn a separate fresh sub-agent for the rater role.
   - The reviewer and rater are two independent calls; do not perform either job inline in the main agent context.
   - Do not reuse a sub-agent across rounds, and do not pass prior sub-agent state into the next round.
   - The rater receives the reviewer findings as input, then independently returns `quality_score`, `critical_gap`, and rationale.

   **Failure handling**
   - If the reviewer or rater returns no response or malformed output, retry once with a fresh sub-agent invocation for the same role.
   - If the same role fails two consecutive times in a single round, abort the entire plus workflow.
   - On abort from sub-agent failure, write the current round file with `decision: aborted` and include the failure note in `## Decision`.
   - Do not mark a malformed or failed round as passed, and do not continue to the next round after two consecutive failures.

   **Round file path**
   - Create the reviews directory if needed: `openspec/changes/<change>/reviews/`.
   - For `spectra-propose-plus`, write `openspec/changes/<change>/reviews/propose-r<N>.md`.
   - For `spectra-apply-plus`, write `openspec/changes/<change>/reviews/apply-r<N>.md`.
   - Use `<N>` as the 1-based round number.
   - The generic path pattern is `openspec/changes/<change>/reviews/<skill>-r<N>.md`.

   **Round file schema**
   - `# Propose Plus Review — Round <N>` or `# Apply Plus Review — Round <N>`
   - `## Reviewer Findings`
   - `## Rating`
   - `## Fix Actions`
   - `## Decision`
   - The `## Decision` value MUST be exactly one of `passed`, `next_round`, or `aborted`.

   **Reviewer output requirements**
   - Findings are grouped under Critical, Warning, and Suggestion.
   - Every finding names the artifact, section, source path, or changed file it applies to.
   - Critical findings are blockers for `passed`.
   - Scope errors at proposal level may set `decision: aborted` instead of continuing fixes.

   **Rater output requirements**
   - The rater writes `quality_score` as a number from 0 to 10.
   - The rater writes `critical_gap` as `true` or `false`.
   - The rater writes one concise rationale paragraph.
   - The rater must not override missing reviewer evidence by optimism alone.

   **Fix actions**
   - If the decision is `next_round`, fix the concrete findings before starting the next round.
   - Record modified files and the reason for each fix in `## Fix Actions`.
   - Re-run relevant CLI checks or tests before the next round when fixes affect generated artifacts or implementation code.
   - If no fixes are needed because the round passed, write `None; pass condition met.`
