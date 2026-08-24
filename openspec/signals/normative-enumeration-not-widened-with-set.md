---
id: normative-enumeration-not-widened-with-set
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-08-24
last_seen: 2026-08-24
links:
  - openspec/changes/strengthen-cash-tdd-evidence/reviews/apply-r1.md
---

# Normative enumeration not widened with the set it names

A change adds a member to a set (a skill name, a mode, a command, an error code) and updates the one requirement that most obviously owns that set, but another requirement elsewhere in the same master spec still enumerates the old membership — often behind a closed-world phrase such as「僅需支援」or "exactly these". The delta merges cleanly because titles match, yet the archived spec then carries two contradictory normative enumerations, and the closed-world phrasing reads the new member as unsupported. Unlike a removal-driven residue, nothing is deleted, so a grep for the removed concept finds nothing; the stale text is the *old enumeration itself*. The fix is to grep the master spec for every literal enumeration of the set — not just the requirement being edited — before finalizing the delta, and to add each stale one as a MODIFIED requirement with the title copied byte-for-byte.

## Occurrences

- 2026-08-24 — strengthen-cash-tdd-evidence — cash-apply round 1 — delta 把 `instructions --skill` 擴為 `<tdd|test-quality|audit>` 並 MODIFY 了擁有 shape contract 的「Artifact graph 與 instructions 使用單一來源」，但同一份 `openspec/specs/cash-cli/spec.md` 的「Cash workflow command surface」仍逐字寫 `<tdd|audit>` 且句首為「CLI SHALL 提供且僅需支援」，未被納入 delta；兩位 reviewer 各自獨立發現。修正為把該 requirement 逐字複製進 `## MODIFIED Requirements`，僅改動該列舉。
