---
id: integrity-receipt-not-regenerated-after-runtime-change
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-25
last_seen: 2026-07-25
links:
  - openspec/changes/align-cli-skill-contracts/reviews/propose-r1.md
---

# Integrity receipt not regenerated after runtime change

A change edits files whose digests are recorded in an integrity manifest that the launcher verifies on every invocation, but the task list never regenerates the manifest. The first edit disables the very CLI the remaining tasks depend on, including the command the workflow uses to mark its own progress.

## Occurrences

- 2026-07-25 — align-cli-skill-contracts — cash-propose round 4 與 round 5 — 本次改動四個 replaceable runtime 檔卻無重建 receipt 的步驟；補上後又發現排在版本提升之後，實測任務 1.1 落地起 14 個任務期間 cash-apply 的 task done 全部停擺，最終改為每次 runtime 改動後即重建且可重複執行。
