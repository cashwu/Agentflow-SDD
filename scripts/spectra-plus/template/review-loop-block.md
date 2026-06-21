10. **Sub-Agent Review/Rating/Fix Loop**

   Run this review/rating/fix loop once per change, after the normal workflow has completed its required artifact or task work.

   **Entry conditions**
   - For `spectra-propose-plus`, start this loop only after proposal, design, specs, and tasks artifacts required for apply are complete.
   - For `spectra-apply-plus`, start this loop only after all implementation tasks are complete and `tasks.md 全 [x]`.
   - Do not run this loop per artifact or per task; the granularity is per-change.

   **Round limit and pass condition**
   - Run max 6 rounds.
   - After the confidence filter, the main agent derives the round decision mechanically (no scoring sub-agent): if any surviving finding has `severity == Critical`, the decision is `next_round`; otherwise if any surviving finding has `severity == Warning`, the decision is `next_round`; otherwise (only `Suggestion` findings remain, or none) the decision is `passed`.
   - A round passes only when, after the confidence filter, there is no surviving Critical and no surviving Warning finding.
   - If round 6 still does not meet the pass condition, write `decision: aborted`, print the unresolved findings, and end the plus workflow.
   - If a round passes, write `decision: passed`, stop the loop, and continue to the normal final validation or completion summary.

   **Fresh sub-agent calls**
   - Each round MUST spawn TWO fresh reviewer sub-agents in parallel (single message, two tool calls):
     - **Reviewer A — Adherence**: checks that the artifacts (and for apply-plus, the implementation diff) match the prior artifacts. For propose-plus: proposal ↔ design ↔ spec ↔ tasks internal consistency, scope coverage, and acceptance criteria completeness. For apply-plus: implementation matches `design.md` Implementation Contract, `tasks.md` task descriptions, and `spec.md` requirements; `implementation-notes.md` deviations are justified.
     - **Reviewer B — Quality**: scans for bugs, regressions, missing tests, security sharp edges, and risks NOT directly named in the artifacts. For propose-plus: missing risks, unstated assumptions, scope gaps. For apply-plus: logic bugs, error-handling gaps at real boundaries, untested edge cases from spec `##### Example:` blocks.
   - Both reviewers receive identical context (artifact paths and, for apply-plus, the changed-file list) and return findings independently. Do not pass Reviewer A output into Reviewer B or vice versa.
   - After both reviewers complete, the main agent aggregates findings (deduplicate identical issues by `location + summary`) and applies the confidence filter (see below).
   - The reviewer roles are independent sub-agent calls; do not perform either of them inline in the main agent context.
   - Do not reuse a sub-agent across rounds, and do not pass prior sub-agent state into the next round.
   - After the confidence filter, the main agent derives the round decision mechanically from the filtered findings (see "Round limit and pass condition"); there is no separate scoring sub-agent.

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

   **Confidence filter (applied by main agent before the decision)**
   - Drop any finding with `confidence < 50`. These do not appear in the round file.
   - Downgrade findings with `confidence ∈ [50, 80)` to `Suggestion` regardless of original severity. They appear in the round file under Suggestion for visibility but do NOT count as Critical.
   - Only findings with `confidence ≥ 80` may be classified as Critical or Warning in the final round file.
   - `critical_gap` is `true` only when at least one finding survives filtering with `severity == Critical` AND `confidence ≥ 80`.
   - The filter exists to keep the review loop signal-to-noise high; only the filtered set feeds the mechanical decision.

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
   - If a reviewer returns no response or malformed output, retry once with a fresh sub-agent invocation for the reviewer role.
   - If both parallel reviewers fail in the same round, treat it as a single role failure (the reviewer role); retry once.
   - If the same role fails two consecutive times in a single round, abort the entire plus workflow.
   - On abort from sub-agent failure, write the current round file with `decision: aborted` and include the failure note in `## Decision`.
   - Do not mark a malformed or failed round as passed, and do not continue to the next round after two consecutive failures.

   **Decision record requirements**
   - The main agent records the count of surviving `Critical` findings and the count of surviving `Warning` findings after the confidence filter.
   - The main agent records `critical_gap` as `true` or `false` (`true` only when at least one surviving finding is `Critical`).
   - The main agent records one concise rationale paragraph explaining why the round is `passed`, `next_round`, or `aborted`.
   - The decision MUST follow only from findings that survived the confidence filter; do not re-introduce filtered-out findings, and do not pass a round that has a surviving Critical or Warning finding.

   **Round file path**
   - Create the reviews directory if needed: `openspec/changes/<change>/reviews/`.
   - For `spectra-propose-plus`, write `openspec/changes/<change>/reviews/propose-r<N>.md`.
   - For `spectra-apply-plus`, write `openspec/changes/<change>/reviews/apply-r<N>.md`.
   - Use `<N>` as the 1-based round number.
   - The generic path pattern is `openspec/changes/<change>/reviews/<skill>-r<N>.md`.

   **Round file schema**
   - `# Propose Plus Review — Round <N>` or `# Apply Plus Review — Round <N>`
   - `## Reviewer Findings` — list aggregated, post-filter findings grouped under Critical / Warning / Suggestion. Each entry MUST include `severity`, `confidence`, `location`, `summary`, `recommendation`, and which reviewer raised it (`A` or `B`; `A+B` if both raised it independently).
   - `## Rating` — surviving `Critical` count, surviving `Warning` count, `critical_gap`, rationale paragraph.
   - `## Fix Actions`
   - `## Decision` — value MUST be exactly one of `passed`, `next_round`, or `aborted`.

   **Fix actions**
   - If the decision is `next_round`, fix the concrete findings before starting the next round.
   - Record modified files and the reason for each fix in `## Fix Actions`.
   - Re-run relevant CLI checks or tests before the next round when fixes affect generated artifacts or implementation code.
   - If no fixes are needed because the round passed, write `None; pass condition met.`

   **Round file language**
   - The Round file (`openspec/changes/<change>/reviews/<skill>-r<N>.md`) prose content — Reviewer Findings, Rating rationale, Fix Actions descriptions, and the `## Decision` explanation — MUST be written in Traditional Chinese.
   - **Keep the following verbatim (do not translate):**
     - Section headings: `# Propose Plus Review — Round <N>`, `# Apply Plus Review — Round <N>`, `## Reviewer Findings`, `## Rating`, `## Fix Actions`, `## Decision`.
     - The `decision` value: one of `passed`, `next_round`, `aborted`.
     - Field names and their values: `critical_gap` (`true` / `false`), `severity`, `confidence`, `location`, `summary`, `recommendation`.
     - Direct quotations from spec delta, master spec, or any other English-language artifact.
     - CLI commands, file paths, code identifiers, artifact IDs, capability slugs.
   - This rule applies to both `spectra-propose-plus` and `spectra-apply-plus` round files because they share this review-loop template.
   - If the user explicitly requests another language later, follow the latest user instruction.

   **Signals write step**

   <!-- SIGNALS-WRITE-STEP -->
   - **When it runs**: Run this step only after the review loop has ENDED — that is, the final round file's `decision` is `passed` or `aborted` — and the mechanical decision has already been recorded. This step MUST run only after that decision is recorded, and it MUST NOT change the `decision` of any round file. It applies to both `spectra-propose-plus` and `spectra-apply-plus`, since this template is shared.
   - **Target set**: The target set is every finding that, in ANY single round of THIS change's loop, survived the confidence filter classified as `Critical` or `Warning`. Cover findings from every round, not only the final round — a finding that was caught and fixed in an early round of an otherwise-passing loop still produces a signal. Deduplicate the target set by issue class, so an issue class seen across multiple rounds is processed exactly once. This issue-class deduplication is INDEPENDENT of any per-round `location + summary` aggregation deduplication used elsewhere in the loop. Findings classified `Suggestion`, and any finding with `confidence < 80`, MUST NOT produce a signal.
   - **Matching rubric**: For each deduplicated finding class, read the existing signals under `openspec/signals/` and judge issue-class match by: SAME capability or domain AND SAME underlying rule or anti-pattern. Differing free-text wording alone does NOT make a different class; a different root cause DOES make a different class. When uncertain, PREFER creating a new signal over merging into an existing one.
   - **On match to an existing `open` signal**: Reuse that signal's slug and update it in place — increment `occurrences`, update `last_seen` to today (`YYYY-MM-DD`), append one `## Occurrences` entry (date, change name, source skill + round, and a one-line context), and append the source round file path to `links`. Do NOT change its `status`.
   - **On no `open` match** (including when only an `addressed` or `dismissed` signal matches): Create a NEW signal. Before coining the `<slug>`, list the existing `openspec/signals/*.md` files and choose a `<slug>` that does NOT already exist. The slug is a short semantic ASCII kebab-case issue-class identifier matching `^[a-z0-9]+(-[a-z0-9]+)*$` (e.g. `spec-requirement-no-backing-task`); it is NOT a mechanical transform of `location + summary`. If the natural slug is already taken, disambiguate with a suffix. Creating a signal MUST NOT overwrite any existing signal file and MUST NOT change any existing signal's human-maintained `status`. The new signal has `status: open`, `occurrences: 1`, and `first_seen` = `last_seen` = today.
   - **Signal file schema**: Each signal file has frontmatter with `id` (= slug), `type` (default `recurring-finding` for review-loop-written signals), `status`, `occurrences`, `first_seen`, `last_seen`, and `links`; followed by a title, a description paragraph, and a `## Occurrences` section.
   - **Failure handling**: If writing under `openspec/signals/` fails, print a warning but do NOT fail the plus workflow — signals are an auxiliary layer. If there are no qualifying findings, write nothing.
