---
id: service-discovery-coupled-to-plist
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-18
last_seen: 2026-07-18
links:
  - openspec/changes/fork-spectra-skills-to-cash/reviews/propose-r1.md
---

# Service discovery coupled to plist

A scheduled-service cleanup uses an on-disk registration file as the only evidence that a service is active, so it can leave an already loaded service running when that file is missing.

## Occurrences

- 2026-07-18 — fork-spectra-skills-to-cash — spectra-propose-plus round 1 — cleanup 初稿只在 plist 存在時 bootout；修正為逐一 query 兩個 `gui/<uid>/<label>`，即使 plist 遺失也按 label unload，確認兩者 absent 後才刪 state。
