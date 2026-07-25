---
id: declared-scope-over-declares-unchanged-file
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-25
last_seen: 2026-07-25
links:
  - openspec/changes/align-cli-skill-contracts/reviews/propose-r1.md
---

# Declared scope over-declares unchanged file

A proposal lists a file as affected because it sits near the change, without checking whether the planned edits actually alter it. Over-declaration inflates the reviewed surface, and when the file is grader-protected it manufactures a scope exception that was never needed.

## Occurrences

- 2026-07-25 — align-cli-skill-contracts — cash-propose round 1 與 round 4 — cli-checks.fish 被宣告為 Modified 但其既有測試群組已涵蓋全部異動檔案；variant-parity 的 cash-drift manifest 亦被列入重新產生清單，經模擬重跑證明逐位元組不變。
