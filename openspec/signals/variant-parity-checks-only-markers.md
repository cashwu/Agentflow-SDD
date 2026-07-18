---
id: variant-parity-checks-only-markers
type: recurring-finding
status: open
occurrences: 2
first_seen: 2026-07-18
last_seen: 2026-07-18
links:
  - openspec/changes/fork-spectra-skills-to-cash/reviews/propose-r1.md
  - openspec/changes/fork-spectra-skills-to-cash/reviews/apply-r1.md
---

# Variant parity checks only markers

A parity test claims that two maintained variants share one workflow contract but compares only selected markers, allowing unmarked paragraphs or behavioral branches to drift.

## Occurrences

- 2026-07-18 — fork-spectra-skills-to-cash — spectra-propose-plus round 1 — Claude/Codex cash skill parity 初稿只比 semantic markers；修正為 exhaustive per-skill allowlist normalization 後比較完整 governed bodies。
- 2026-07-18 — fork-spectra-skills-to-cash — cash-apply round 1 — parity 雖改比完整 unified diff，卻以 opaque digest 隱藏允許差異；修正為 invocation normalization 後逐行比對 readable exact per-skill manifests，並顯式宣告 tool-capability 差異。
