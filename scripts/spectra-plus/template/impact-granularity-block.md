
   **Propose-plus impact granularity advisory**
   - After writing the proposal and before creating `design.md`, count the affected-code path entries under proposal `## Impact` across Modified, New, and Removed.
   - Exclude `(none)` placeholder lines. Count a directory entry as one entry, so the result is a lower bound.
   - When there are more than 15 affected-code path entries, print an informational warning containing the count and recommend splitting the change by capability.
   - When the count is 15 or fewer, print nothing.
   - Treat 15 entries as silent and 16 entries as advisory.
   - This advisory MUST NOT block the workflow or require user confirmation.
