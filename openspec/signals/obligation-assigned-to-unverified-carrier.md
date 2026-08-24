---
id: obligation-assigned-to-unverified-carrier
type: recurring-finding
status: open
occurrences: 2
first_seen: 2026-08-22
last_seen: 2026-08-24
links:
  - openspec/changes/default-spec-sync-on-archive/reviews/propose-r1.md
  - openspec/changes/default-spec-sync-on-archive/reviews/propose-r2.md
  - openspec/changes/strengthen-cash-tdd-evidence/reviews/propose-r1.md
---

# Obligation assigned to an unverified carrier

A change adds a normative obligation (a MUST to report, record, or surface something) and assigns it to an entry point without first checking that the entry point has an output surface able to carry it — or it names an existing surface as sufficient without checking that the surface is actually selected under the conditions the obligation covers. The obligation then cannot be satisfied at implementation time, and because the same change usually freezes the surface as MUST NOT change, the implementer has no legal way out. The fix is to inspect the concrete carrier for every entry the obligation names, enumerate the input combinations that reach it, and either scope the obligation per entry or open the minimum edit the carrier needs.

## Occurrences

- 2026-08-22 — default-spec-sync-on-archive — cash-propose rounds 1–2 — round 1：新 requirement 要求「兩者的完成摘要 MUST 回報判定結果」，但 `cash-commit` 的 `**Output On Success**` 只有 Commit／Files／Tasks 三行、沒有任何 spec sync 欄位，而 design 又明文禁止改動模板；修法是依兩個入口既有的輸出面分配義務，並開放一處最小模板追加。round 2：為修前者而寫的「`cash-archive` 三個 Output 模板恰好對應三個判定結果」被查出不成立——模板由「有沒有 warnings」選擇，warnings 模板的 `**Specs:**` 行硬寫為跳過，因此「已同步但有未完成 task」無模板可用。兩次都是先寫下義務、後才查驗承載面。
- 2026-08-24 — strengthen-cash-tdd-evidence — cash-propose round 1 — canonical test-quality 首次載入被指派給尚不存在的 resource，canonical TDD evidence 又被綁在 `cash-debug` 不具備的 `tasks.md`；修法是提供只限自舉 task 的有界 carrier，並讓 `cash-debug` Phase 3 notes承載 primary／regression／success／failure evidence。
