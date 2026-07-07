10. **Sub-Agent Review/Rating/Fix Loop**

   Run this review/rating/fix loop once per change, after the normal workflow has completed its required artifact or task work.

   **Entry conditions**
   - For `spectra-propose-plus`, start this loop only after proposal, design, specs, and tasks artifacts required for apply are complete AND `spectra validate "<name>"` has passed. If validation fixes are required, complete them before entering this loop.
   - For `spectra-apply-plus`, start this loop only after all implementation tasks are complete and `tasks.md 全 [x]`.
   - Do not run this loop per artifact or per task; the granularity is per-change.

   **Pre-round mechanical self-check (main agent, inline)**

   <!-- MECHANICAL-SELF-CHECK -->
   - Run this self-check inline (grep/read, no sub-agent) before spawning round 1's reviewers, and again whenever a round's fix actions modified any artifact (or, for apply-plus, any implementation file) — before spawning the next round's reviewers. Reviewer rounds are expensive; these defects are machine-catchable and MUST be caught here, not by reviewers.
   - Checks:
     - **Comment/annotation lint**: in every spec delta file, `<!--` and `-->` counts MUST match; no unclosed annotation block (e.g. a dangling `<!-- @trace` line) and no stray `---` separator may remain inside a requirement or scenario section.
     - **Count-consistency scan**: every numeric claim one artifact makes about another (e.g. proposal or design stating a scenario, requirement, or task count) MUST match the actual count in the referenced artifact. Recount at the source and update stale numbers.
     - **Identifier cross-grep**: for each function name, entry point, file path, flag, or artifact ID that `design.md` defines, grep ALL artifacts (and for apply-plus, the changed files) and verify every occurrence is consistent in spelling and meaning.
     - **Signal-derived checks**:
       1. For EVERY `open` signal whose frontmatter contains a `check` field, execute the `check` value from the project root by passing it as the single command-string argument to `sh -c`, without applying relevance filtering. Executing a `check` command MUST NOT modify any file. Exit `0` means the check passed. Exit `1` means the anti-pattern is present: inspect any project-root-relative paths printed by the `check` command and compare them with this change's artifacts and, for apply-plus, changed files. If at least one printed path is in that artifact/source file set, treat the failure as in scope. If the `check` command prints no usable project-root-relative path, or the output cannot be reliably mapped to a project-root-relative path, fail closed and treat the detected instance as in scope unless the already-read repository state proves the instance is pre-existing or the required fix location is outside the structured scope declarations. If the detected instance is in scope and the fix location is not a protected grader path that is not covered by the structured-scope exception, fix it before spawning reviewers. If the detected instance is pre-existing, or its fix lies outside this change's structured scope declarations, or its fix lies inside a protected grader path that is not covered by the structured-scope exception, do not fix it, record one `範圍外 check 失敗` note in that round file's `## Fix Actions`, include the failing check result in the reviewers' context, and proceed to spawn reviewers. Any other exit code is an execution error: fall back to the existing best-effort judgment for that signal and record one fallback note in `## Fix Actions`. These note lines coexist with `None; pass condition met.` and do not count toward ledger `fixed_files`.
       2. For `open` signals without a `check` field, or signals whose `check` execution fell back because of an execution error, keep the existing best-effort behavior: if any relevant signal (see "Signals in reviewer context" below) describes a machine-checkable anti-pattern, run a corresponding check for it.
   - Fix every failure before spawning the reviewers. When the self-check runs after a round's fix actions, record what it caught and fixed in that round's `## Fix Actions`; self-check results are NOT reviewer findings and never feed the round decision.

   **Round limit and pass condition**
   - Run max 6 rounds.
   - Round 1 MUST be a full round. Micro rounds MUST count toward the 6-round cap and MUST NOT be followed by another micro round.
   - After the confidence filter, the main agent derives the round decision mechanically (no scoring sub-agent): if any surviving finding has `severity == Critical`, the decision is `next_round`; otherwise if any surviving finding has `severity == Warning`, the decision is `next_round`; otherwise (only `Suggestion` findings remain, or none) the decision is `passed`.
   - A round passes only when, after the confidence filter, there is no surviving Critical and no surviving Warning finding.
   - When the decision is `next_round`, derive the next round type mechanically: the next round is `micro` if and only if the current round is `full`, no Critical findings survive, and every surviving Warning has `layer == text`; otherwise the next round is `full`.
   - The derived next round type is provisional until the next round's reviewers are spawned. If any artifact modification (or, for apply-plus, any implementation-file modification) after the decision is recorded — including a fix action, a mechanical self-check fix, or a validation fix — actually changes behavior or a design statement, the main agent MUST re-derive the next round as `full`.
   - If the main agent cannot determine whether a post-decision modification only synchronizes text, it MUST treat the modification as behavior-modifying and re-derive the next round as `full`.
   - Re-derivation MUST only change `micro` to `full`; it MUST NOT change `full` to `micro`. When re-derivation happens, append a one-line re-derivation note naming the triggering modification and reason at the end of that round file's `## Fix Actions` section.
   - If round 6 still does not meet the pass condition, write `decision: aborted`, print the unresolved findings, and end the plus workflow.
   - If a round passes, write `decision: passed`, stop the loop, and continue to the completion summary.

   **Fresh sub-agent calls**
   - Each full round MUST spawn exactly TWO fresh reviewer sub-agents in parallel (single message, two tool calls):
     - **Reviewer A — Adherence**: checks that the artifacts (and for apply-plus, the implementation diff) match the prior artifacts. For propose-plus: proposal ↔ design ↔ spec ↔ tasks internal consistency, scope coverage, and acceptance criteria completeness. For apply-plus: implementation matches `design.md` Implementation Contract, `tasks.md` task descriptions, and `spec.md` requirements; `implementation-notes.md` deviations are justified.
     - **Reviewer B — Quality**: scans for bugs, regressions, missing tests, security sharp edges, and risks NOT directly named in the artifacts. For propose-plus: missing risks, unstated assumptions, scope gaps. For apply-plus: logic bugs, error-handling gaps at real boundaries, untested edge cases from spec `##### Example:` blocks.
   - Each micro round MUST spawn exactly ONE fresh reviewer sub-agent:
     - **Reviewer V — Verification**: verifies only the prior round's fixes. Reviewer V receives the artifact paths (and, for apply-plus, the changed-file list), the prior round file's surviving findings and `## Fix Actions` content, and relevant `open` signals. Reviewer V's scope is limited to whether each fix resolved its finding at the fixed location, whether fix propagation is complete, and whether the fixes introduced new defects.
   - Full-round reviewers receive identical context (artifact paths and, for apply-plus, the changed-file list) and return findings independently. Do not pass Reviewer A output into Reviewer B or vice versa.
   - **Signals in reviewer context**: before spawning a round's reviewer(s), the main agent reads the signals under `openspec/signals/` whose frontmatter `status` is `open`, selects those relevant to this change (best-effort judgment), and includes their issue-class descriptions in all of that round's reviewers' context so recurring issue classes are checked deliberately instead of rediscovered. This read is informational only: it MUST NOT modify any signal, and if `openspec/signals/` is absent or has no `open` signal, continue silently. It is distinct from the propose-plus scope-scan signals read and from the post-loop signals write step.
   - **Round-1 claim verification (Reviewer A)**: in round 1, Reviewer A MUST verify the code-facing claims in `design.md` against the actual codebase before its other checks — for each claim of the form "X is called by Y", "X currently behaves as Z", or a stated data source or entry point, grep the call sites and read the relevant code to confirm it. A claim that does not hold is a finding; do not take design claims on faith.
   - After the round's reviewer(s) complete, the main agent aggregates findings (deduplicate identical issues by `location + summary`) and applies the confidence filter (see below). When full-round reviewers independently raise the same finding with different `layer` values, the merged finding MUST take `layer == design`.
   - The reviewer roles are independent sub-agent calls; do not perform either of them inline in the main agent context.
   - Do not reuse a sub-agent across rounds, and do not pass prior sub-agent state into the next round.
   - After the confidence filter, the main agent derives the round decision mechanically from the filtered findings (see "Round limit and pass condition"); there is no separate scoring sub-agent.

   **Reviewer output requirements**
   - All of a round's reviewers MUST classify each finding into Critical, Warning, or Suggestion.
   - Every finding MUST include the following fields:
     - `severity`: one of `Critical`, `Warning`, `Suggestion` (before filtering)
     - `confidence`: integer `0`–`100`, using the rubric below
     - `layer`: one of `design` or `text`
     - `location`: artifact + section, or file path + line range
     - `summary`: one-line description of the issue
     - `recommendation`: concrete action to resolve
   - Classify a finding as `text` only when it concerns cross-artifact consistency (counts, identifier spelling, wording, or section synchronization) and fixing it does not change any design decision or behavioral statement. Classify every other finding as `design`.
   - When a reviewer cannot decide between `design` and `text`, it MUST classify the finding as `design`.
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
   - While applying the confidence filter, re-check every finding classified as `text`; if its fix could touch behavior or a design statement, reclassify it to `design`. The main agent MUST NOT reclassify a `design` finding to `text`.
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
   - If both full-round parallel reviewers fail in the same round, treat it as a single role failure (the reviewer role); retry once.
   - If the same role fails two consecutive times in a single round, abort the entire plus workflow.
   - On abort from sub-agent failure, write the current round file with `decision: aborted` and include the failure note in `## Decision`.
   - Do not mark a malformed or failed round as passed, and do not continue to the next round after two consecutive failures.

   **Decision record requirements**
   - The main agent records the count of surviving `Critical` findings and the count of surviving `Warning` findings after the confidence filter.
   - The main agent records `critical_gap` as `true` or `false` (`true` only when at least one surviving finding is `Critical`).
   - The main agent records `round_type` as exactly `full` or `micro`.
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
   - `## Reviewer Findings` — list aggregated, post-filter findings grouped under Critical / Warning / Suggestion. Each entry MUST include `severity`, `confidence`, `layer`, `location`, `summary`, `recommendation`, and which reviewer raised it (`A` or `B`; `A+B` if both raised it independently; `V` for Reviewer V).
   - `## Rating` — surviving `Critical` count, surviving `Warning` count, `critical_gap`, `round_type`, rationale paragraph.
   - `## Fix Actions`
   - `## Decision` — value MUST be exactly one of `passed`, `next_round`, or `aborted`.

   **Fix actions**
   - If the decision is `next_round`, fix the concrete findings before starting the next round.
   - **Fix propagation**: fixes are the primary source of new defects. For EVERY concept a fix touches (an identifier, a count, a heading, a rule), grep that concept across ALL artifacts (and for apply-plus, the changed files) and synchronize every occurrence in the same fix pass — never fix only the flagged location.
   - After completing all fix actions, re-run the pre-round mechanical self-check and fix any failures before spawning the next round's reviewers.
   - Record modified files and the reason for each fix in `## Fix Actions`.
   - Re-run relevant CLI checks or tests before the next round when fixes affect generated artifacts or implementation code.
   - For `spectra-propose-plus`, if any fix action modifies proposal, design, tasks, or spec artifacts, run `spectra validate "<name>"` again and fix validation errors before starting the next round.
   - If no fixes are needed because the round passed, write `None; pass condition met.`

   <!-- GRADER-IMMUTABILITY -->
   **Grader immutability**
   - During an active plus review loop, the main agent MUST NOT modify, whether as a fix action or as a mechanical self-check fix, any file in this protected grader path set unless that file is explicitly named in the current change's proposal `## Impact` section or in its `tasks.md`:
     - `scripts/spectra-plus/template/`
     - `scripts/spectra-plus/rules.yaml`
     - `scripts/spectra-plus/generate.fish`
     - `.claude/skills/spectra-propose-plus/SKILL.md`
     - `.claude/skills/spectra-apply-plus/SKILL.md`
     - `.agents/skills/spectra-propose-plus/SKILL.md`
     - `.agents/skills/spectra-apply-plus/SKILL.md`
     - `.spectra.yaml`
     - `openspec/specs/`
   - **Structured scope declarations**: A file counts as explicitly named only when its project-root-relative path appears in a structured scope declaration: an affected-code entry in proposal `## Impact`, or a `tasks.md` path that is explicitly identified as a delivery target. A path that appears only in a verification command, a rule description, an example, a review finding, reviewer context, or other incidental prose MUST NOT count as a structured scope declaration. Naming a directory path in a structured scope declaration names every file under it. Naming a file under `scripts/spectra-plus/template/` also names the four regenerated plus skill outputs, so required regeneration is not blocked.
   - A loop already in progress continues under the instruction version it started with; regenerated instructions take effect only from the next loop run.
   - The main agent MUST NOT add, modify, or remove the `check` frontmatter field of any signal under `openspec/signals/`, regardless of declared scope. The `check` field is grader input for the pre-round mechanical self-check.
   - If fixing a surviving finding would require modifying a protected file outside the structured scope declarations, or touching any signal's `check` field, do not make that modification. Record `未修復：裁判面保護` (an unfixed-due-to-grader-protection note) in `## Fix Actions`, naming the protected file and finding. The finding remains surviving for the round decision. This is the explicit exception to the obligations to fix Critical/Warning findings before the next round in the `spectra-propose-plus quality gate` and `spectra-apply-plus quality gate` requirements: fixes are required except any finding withheld under the grader-immutability rule.
   - A protected file modified under the declared-scope exception remains subject to the existing re-derivation rules. If the loop reaches round 6 without passing because protected findings remain, write `decision: aborted` under the existing round-limit rule.
   - The plus workflow completion output MUST list every `未修復：裁判面保護` record from every round, even if a later round passes: for `spectra-propose-plus` with `decision: passed`, list the records in the final summary; for `spectra-apply-plus` with `decision: passed`, list the records in the gate-complete final response; for any `decision: aborted`, list the records in the unresolved-findings warning.

   <!-- LOOP-LEDGER-STEP -->
   **Loop ledger step**
   - After each round file is finalized, append exactly one row to `openspec/changes/<change>/reviews/loop-ledger.tsv`. For a `next_round` round, append immediately before spawning the next round's reviewers, after all fix actions, post-fix self-check records, validation re-run fix records, and any re-derivation note have been written to the round file. For a final `passed` or `aborted` round, append at loop end before the signals write step.
   - If `loop-ledger.tsv` does not exist, create it first with this exact tab-separated header row: `skill	round	round_type	criticals	warnings	decision	fixed_files`.
   - Append data rows with exactly seven tab-separated fields in this order:
     - `skill`: `propose` or `apply`
     - `round`: 1-based round number
     - `round_type`: `full` or `micro`
     - `criticals`: surviving Critical count after filtering, or `0` when no post-filter findings exist, including failure-aborted rounds
     - `warnings`: surviving Warning count after filtering, or `0` when no post-filter findings exist, including failure-aborted rounds
     - `decision`: `passed`, `next_round`, or `aborted`
     - `fixed_files`: number of distinct files recorded as modified in that round's `## Fix Actions`; use `0` when none are recorded, and do not count note lines such as fallback, out-of-scope check failure, or grader-protection notes
   - The ledger is an append-only event log. Rows from propose loops, apply loops, and later re-runs after an abort accumulate chronologically in the same file. `(skill, round)` is not a unique key; duplicate round numbers from re-runs are valid.
   - Round files remain authoritative. If a round file and ledger disagree, trust the round file.
   - If writing the ledger fails, print a warning and continue the plus workflow unchanged.

   **Round file language**
   - The Round file (`openspec/changes/<change>/reviews/<skill>-r<N>.md`) prose content — Reviewer Findings, Rating rationale, Fix Actions descriptions, and the `## Decision` explanation — MUST be written in Traditional Chinese.
   - **Keep the following verbatim (do not translate):**
     - Section headings: `# Propose Plus Review — Round <N>`, `# Apply Plus Review — Round <N>`, `## Reviewer Findings`, `## Rating`, `## Fix Actions`, `## Decision`.
     - The `decision` value: one of `passed`, `next_round`, `aborted`.
     - Field names and their values: `critical_gap` (`true` / `false`), `round_type` (`full` / `micro`), `severity`, `confidence`, `layer` (`design` / `text`), `location`, `summary`, `recommendation`.
     - Direct quotations from spec delta, master spec, or any other English-language artifact.
     - CLI commands, file paths, code identifiers, artifact IDs, capability slugs.
   - This rule applies to both `spectra-propose-plus` and `spectra-apply-plus` round files because they share this review-loop template.
   - If the user explicitly requests another language later, follow the latest user instruction.

   **Signals write step**

   <!-- SIGNALS-WRITE-STEP -->
   - **When it runs**: Run this step only after the review loop has ENDED — that is, the final round file's `decision` is `passed` or `aborted` — and the mechanical decision has already been recorded. This step MUST run only after that decision is recorded, and it MUST NOT change the `decision` of any round file. It applies to both `spectra-propose-plus` and `spectra-apply-plus`, since this template is shared.
   - **Target set**: The target set is every finding that, in ANY single round of THIS change's loop, survived the confidence filter classified as `Critical` or `Warning`. Cover findings from every round, not only the final round — a finding that was caught and fixed in an early round of an otherwise-passing loop still produces a signal. Deduplicate the target set by issue class, so an issue class seen across multiple rounds is processed exactly once. This issue-class deduplication is INDEPENDENT of any per-round `location + summary` aggregation deduplication used elsewhere in the loop. Findings classified `Suggestion`, and any finding with `confidence < 80`, MUST NOT produce a signal.
   - **Matching rubric**: For each deduplicated finding class, read the existing signals under `openspec/signals/` and judge issue-class match by: SAME capability or domain AND SAME underlying rule or anti-pattern. Differing free-text wording alone does NOT make a different class; a different root cause DOES make a different class. When uncertain, PREFER creating a new signal over merging into an existing one.
   - **On match to an existing `open` signal**: Reuse that signal's slug and update it in place — increment `occurrences`, update `last_seen` to today (`YYYY-MM-DD`), append one `## Occurrences` entry (date, change name, source skill + round, and a one-line context), and append the source round file path to `links`. Do NOT change its `status`. Do NOT add, modify, or remove its `check` field; preserve any existing human-authored `check` byte-for-byte.
   - **On no `open` match** (including when only an `addressed` or `dismissed` signal matches): Create a NEW signal. Before coining the `<slug>`, list the existing `openspec/signals/*.md` files and choose a `<slug>` that does NOT already exist. The slug is a short semantic ASCII kebab-case issue-class identifier matching `^[a-z0-9]+(-[a-z0-9]+)*$` (e.g. `spec-requirement-no-backing-task`); it is NOT a mechanical transform of `location + summary`. If the natural slug is already taken, disambiguate with a suffix. Creating a signal MUST NOT overwrite any existing signal file and MUST NOT change any existing signal's human-maintained `status`. The new signal has `status: open`, `occurrences: 1`, and `first_seen` = `last_seen` = today.
   - **Signal file schema**: Each signal file has frontmatter with `id` (= slug), `type` (default `recurring-finding` for review-loop-written signals), `status`, `occurrences`, `first_seen`, `last_seen`, `links`, and optional human-authored `check`; followed by a title, a description paragraph, and a `## Occurrences` section. New signals created by this step MUST NOT contain an automatically authored `check`.
   - **Failure handling**: If writing under `openspec/signals/` fails, print a warning but do NOT fail the plus workflow — signals are an auxiliary layer. If there are no qualifying findings, write nothing.
