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
