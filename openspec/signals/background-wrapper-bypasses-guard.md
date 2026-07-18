---
id: background-wrapper-bypasses-guard
type: recurring-finding
status: open
occurrences: 2
first_seen: 2026-07-04
last_seen: 2026-07-18
links:
  - openspec/changes/guard-dirty-source-auto-repair/reviews/propose-r2.md
  - openspec/changes/guard-dirty-source-auto-repair/reviews/propose-r5.md
  - openspec/changes/fork-spectra-skills-to-cash/reviews/apply-r1.md
---

# Background wrapper bypasses guard

A background entrypoint wrapper performs dependency checks, state changes, or other work before handing off to the guard that is supposed to protect automatic execution.

## Occurrences

- 2026-07-04 — guard-dirty-source-auto-repair — spectra-propose-plus rounds 2 and 5 — Review found the LaunchAgent entrypoint could fail or perform side effects before the installer dirty-source guard ran.
- 2026-07-18 — fork-spectra-skills-to-cash — cash-apply round 1 — mutating Fish entrypoints 載入使用者 startup functions，讓 `launchctl`、`realpath` 或 `cmp` 覆寫繞過安全判斷；修正為 no-config shebang、command-qualified tools 與 hostile startup direct-executable fixtures。
