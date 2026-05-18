   **Artifact language for propose-plus**

   All change artifacts produced by `spectra-propose-plus` (`proposal.md`, `design.md`, `tasks.md`, and any other non-spec artifact under `openspec/changes/<change>/`) MUST be written in Traditional Chinese, regardless of whether the CLI provides a `locale` field.

   This applies to artifacts generated in step 5 (proposal) and step 7 (remaining artifacts), and to any artifacts modified during the review loop fix actions.

   **Exception — spec files stay in English:**

   - `openspec/changes/<change>/specs/<capability>/spec.md` (delta spec)
   - `openspec/specs/<capability>/spec.md` (master spec)

   Spec files MUST always be written in English because they use normative SHALL/MUST wording, and delta specs are later merged into master specs — mixing languages would cause merge conflicts and semantic drift. This is consistent with the existing `locale` rule documented above for spec files.

   **Keep the following verbatim (do not translate) even inside Chinese prose:**

   - Shell commands and CLI flags
   - File paths (absolute or repo-relative)
   - Code identifiers (function names, variable names, type names)
   - Schema field names (e.g., `applyRequires`, `outputPath`, `dependencies`)
   - Artifact IDs and capability slugs
   - Quoted source text from existing artifacts

   If the user explicitly requests another language later, follow the latest user instruction.

   The goal is predictable Chinese-facing artifacts for propose-plus while preserving exact technical references and keeping spec deltas compatible with master specs.
