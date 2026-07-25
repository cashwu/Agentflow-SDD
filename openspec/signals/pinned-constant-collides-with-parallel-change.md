---
id: pinned-constant-collides-with-parallel-change
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-25
last_seen: 2026-07-25
links:
  - openspec/changes/tolerate-versioned-legacy-guidance-marker/reviews/propose-r8.md
---

# Pinned constant collides with parallel change

A task hard-codes a value it must advance (a version, a counter, a sequence number) as a literal derived from the state at authoring time. Another in-flight change in the same workspace advances the same value first, so the literal is stale by the time the task runs. The danger is asymmetric: if the sibling has already committed, the guard fails loudly and is caught; if the sibling has only touched the working tree, the guard compares against HEAD and passes, silently reverting the sibling's work. The fix is to state a derivation rule rather than a constant — pinning the corrected constant only defers the same collision to the next parallel change.

## Occurrences

- 2026-07-25 — tolerate-versioned-legacy-guidance-marker — cash-propose round 8 與 round 9 —— tasks 2.5 與 IC7 寫死「`cash-skills.version` 由 `2.3.1` 調升為 `2.3.2`」，而 sibling change `guard-post-archive-commit-allowlist` 已於工作樹升至 `2.4.0`。主 agent 在此前回答使用者「兩個 change 誰先做」時就明確指出過這個碰撞並提醒後做者必須調整，卻沒有把該認知寫進自己的 artifact——知道風險與防範風險是兩件事。修法是改為推導規則（讀當下工作樹值與 `git show HEAD:` 值、取嚴格大於兩者的下一個版本，MUST NOT 寫死常數），而非把常數改成 `2.4.1`。round 9 另發現 IC7 對後果的描述也錯：`check_history` 只比對工作樹與 HEAD，故 sibling 未提交時寫死值會靜默通過並覆寫，而非拋錯。sibling 的對應 task 用的正是推導式寫法，且其正文逐字點名本 change 提出警告。
