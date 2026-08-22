---
id: mitigation-cites-gate-inactive-on-risk-path
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-08-22
last_seen: 2026-08-22
links:
  - openspec/changes/default-spec-sync-on-archive/reviews/propose-r1.md
---

# Mitigation cites a gate that is inactive on the at-risk path

A risk is written off by pointing at existing confirmations, validations, or preflights, without checking whether those gates actually fire on the path the risk describes. Typically the cited gates are conditional — they trigger only on the failure path — while the risk lives on the clean path where none of them run. A related form is the circular mitigation: the escape hatch offered as the remedy can only be reached by a user who already knows about the problem the removed gate was the only chance to notice. The fix is to name the exact precondition of every cited gate, evaluate it against the risk path, and rewrite the entry as a residual risk when no gate holds.

## Occurrences

- 2026-08-22 — default-spec-sync-on-archive — cash-propose round 1 — 移除 `cash-archive` 步驟 4 的 Cancel 出口後，Risks 以「步驟 2、步驟 3 的確認仍在」作為緩解，但那兩處只在 artifact 或 task 未完成時觸發；在「全部完成且直接指定 change 名稱」的常見路徑上，從呼叫到不可逆 mutation 之間零確認，而其中刪除 `.cash-skills/state/` 的部分被 `.gitignore` 忽略、無法由 git 還原。第二條風險的緩解「使用者可明確要求跳過」則是循環論證：使用者要先知道 delta 寫錯才會提出要求，而移除的提問正是唯一會讓他停下來看一眼的時機。修法是全段改寫為事實敘述並註明未提供緩解。
