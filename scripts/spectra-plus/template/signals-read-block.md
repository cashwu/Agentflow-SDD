**Read open signals for prioritization (propose-plus only)**

<!-- SIGNALS-READ-STEP -->

   After scanning existing specs, read the signals under `openspec/signals/` whose frontmatter `status` is `open`, and use them to inform how you prioritize this change's scope. This step belongs to `spectra-propose-plus` only.

   - Read every signal file under `openspec/signals/` and keep only those whose frontmatter `status` is `open`. Selecting which `open` signals are relevant to the current requirement is best-effort agent judgment.
   - Surface the relevant `open` signals as an INFORMATIONAL prioritization summary — for example, which recurring issue classes or frictions might relate to this change — to help decide what to include in or exclude from scope.
   - This read is purely informational. It MUST NOT block the workflow, MUST NOT require user confirmation to continue, and MUST NOT modify, create, or delete any signal. Read signals only; never write them.
   - If `openspec/signals/` is absent or contains no `open` signal, continue SILENTLY without printing any summary.
