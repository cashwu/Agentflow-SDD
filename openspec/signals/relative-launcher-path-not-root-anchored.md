---
id: relative-launcher-path-not-root-anchored
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-23
last_seen: 2026-07-23
links:
  - openspec/changes/replace-spectra-cli-with-cash-cli/reviews/propose-r1.md
---

# Relative launcher path not root anchored

A project-local workflow invokes its launcher by a repository-relative path without first resolving the project root, so the same canonical command fails or selects the wrong runtime from a nested working directory.

## Occurrences

- 2026-07-23 — replace-spectra-cli-with-cash-cli — cash-propose round 1 — `.cash-skills/bin/cash`最初以相對路徑出現在workflow contract；修正為先取得Git top-level，再呼叫該root下的absolute launcher並加入nested-cwd matrix。
