11. **Implementation Notes Protocol**

   During the apply-plus task loop, maintain a lightweight running log at `openspec/changes/<change>/implementation-notes.md` that captures only two categories of information:

   - **Deviations**: places where the implementation intentionally departs from `spec.md`, `design.md`, or `tasks.md` (because the spec was ambiguous, the codebase reality differs, or a discovered issue forced a different path).
   - **Open questions**: items that need user confirmation or revision before this change can be considered complete.

   Design decisions that match the spec, ordinary tradeoffs, and small judgment calls do NOT belong here — they are already covered by `design.md`, `tasks.md`, and the review-loop round files. Keep this log narrow.

   **File creation rule (eager)**
   - At the start of Step 7 (the task loop), before processing the first task, create `openspec/changes/<change>/implementation-notes.md` if it does not already exist.
   - Initialize the file with a single-line HTML comment header (and nothing else):
     ```
     <!-- apply-plus implementation notes | change: <change-name> | initialized: <YYYY-MM-DD HH:MM> | no entries below means no deviations or open questions were recorded -->
     ```
   - Entries (see below) are appended in order beneath this header.
   - Eager creation makes "no entries" an explicit positive signal (apply-plus ran and found nothing to report), distinct from file-absent which signals a workflow integrity failure.

   **Entry format**

   Each entry MUST be appended (never rewriting earlier entries) using this exact structure:

   ```
   ## <YYYY-MM-DD HH:MM> — <short title>
   - 類別：deviation | open-question
   - 任務：<task-id or "n/a">
   - 內容：<one-paragraph description of what happened or what needs answering>
   - 原因：<why this path was chosen, or why the user needs to weigh in>
   ```

   Prose (`內容`, `原因`, title) is written in Traditional Chinese, matching the apply-plus response-language rule. CLI commands, file paths, code identifiers, capability slugs, and quoted source text remain verbatim in English.

   **When to write an entry**
   - When task-level implementation diverges from `design.md` Implementation Contract, `tasks.md` description, or relevant `spec.md` requirements — write a `deviation` entry before marking the task done.
   - When the task surfaces a question the user must decide (e.g. ambiguous requirement, missing schema field, contested naming) and the agent has to proceed under an assumption — write an `open-question` entry naming the assumption.
   - Do not batch entries to the end of the session; record at the moment the decision is made, while context is fresh.

   **When NOT to write an entry**
   - Routine implementation that matches the artifacts — no entry.
   - Trivial naming or formatting choices — no entry.
   - Anything already documented in `design.md` or the round-`<N>` review files — no entry.

   **Sub-agent reviewer requirement**

   The review-loop reviewer (Section 10) MUST, at the start of each round, read `openspec/changes/<change>/implementation-notes.md`.

   - **File absent**: this is a Critical finding — apply-plus failed to initialize the running log, indicating either an aborted workflow or a skill-integrity failure. The round MUST NOT pass; recommend re-running apply-plus or back-filling the file before the next round.
   - **File present with only the initialization comment and no entries**: treat as confirmed empty — apply-plus reached the task loop and found nothing requiring a `deviation` or `open-question` entry. No finding raised by virtue of emptiness alone.
   - **File present with entries**:
     - `deviation` entries are evaluated for whether the divergence is justified. An unjustified deviation is a Critical finding; a justified-but-undocumented-in-`design.md` deviation is at minimum a Warning recommending the divergence be back-filled into `design.md` during Fix Actions.
     - `open-question` entries are surfaced as Warning findings with a recommended `## Fix Actions` step naming how to obtain user confirmation before the round can pass.

   The rater (Section 10) does not read this file directly; it reads only the reviewer findings, which already incorporate the notes context.

   **Idempotence and ingest interaction**
   - `spectra-ingest` may modify `tasks.md` / `design.md` / `proposal.md`. After ingest resolves an open question, the agent MUST append a follow-up entry noting the resolution (do not delete or rewrite the original `open-question` entry — the historical record is the point).
   - Reviewer treats a resolved `open-question` entry (i.e. one followed by a resolution entry) as no longer blocking.

