10. **Apply-plus response language**

   For `spectra-apply-plus`, ai 的回覆要用中文.

   All user-facing AI responses during this workflow MUST be written in Traditional Chinese unless the user explicitly requests another language.

   This includes:
   - Status updates while tasks are being implemented.
   - Pause messages when a blocker is encountered.
   - Review loop summaries.
   - Final implementation summaries.

   This does not require translating:
   - Shell commands.
   - File paths.
   - Code identifiers.
   - Existing quoted source text.

   If the user explicitly requests another language later, follow the latest user instruction.

   Keep technical names exact even when the surrounding explanation is Chinese.

   Do not mix languages for ordinary prose unless a command, path, symbol, or quoted artifact requires it.

   The goal is predictable Chinese-facing interaction for apply-plus while preserving exact technical references.

   **Artifact modifications during apply-plus**

   When the apply-plus workflow modifies an artifact — during review-loop fix actions, or after `spectra-ingest` updates `tasks.md` / `design.md` / `proposal.md` — the updated artifact content MUST follow the same Chinese language rule as propose-plus:

   - `tasks.md`, `design.md`, `proposal.md`, and other non-spec artifacts under `openspec/changes/<change>/`: Traditional Chinese.
   - Spec files (`openspec/changes/<change>/specs/**/spec.md` and `openspec/specs/**/spec.md`): always English, regardless of any other language rule. Delta specs are merged into master specs and must use normative SHALL/MUST wording.

   Keep CLI commands, file paths, code identifiers, schema field names, artifact IDs, capability slugs, and existing quoted source text verbatim. If the user explicitly requests another language later, follow the latest user instruction.
