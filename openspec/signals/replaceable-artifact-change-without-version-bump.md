---
id: replaceable-artifact-change-without-version-bump
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-25
last_seen: 2026-07-25
links:
  - openspec/changes/guard-post-archive-commit-allowlist/reviews/propose-r1.md
---

# Replaceable artifact change without version bump

A change edits files that a bundle-version history gate treats as replaceable, but neither declares the version file in its affected-code scope nor includes a task that bumps it. The gate compares every replaceable file byte-for-byte against its introduction commit whenever the working version equals HEAD, so the whole regression suite fails at the end of the change rather than at the edit that caused it. The fix is to derive the new version from `HEAD` rather than hardcoding a constant, because a concurrent change may bump the same file first.

## Occurrences

- 2026-07-25 — guard-post-archive-commit-allowlist — cash-propose round 1 — 本變更改動 `.cash-skills/lib/cash_cli/commands/archive.py` 與四個 `SKILL.md`，但 `## Impact` 未宣告 `cash-skills.version`、tasks 也無提升版本的任務，`test_bundle_version_history.py` 的 `check_history` 在 `current == head` 時必然失敗；round 3 另發現補上的任務把目標值寫死為 `2.4.0`，未比對 HEAD，而同一 workspace 另一個進行中的 change 也宣告要提升該檔，最終改為由 `git show HEAD:cash-skills.version` 推導。
