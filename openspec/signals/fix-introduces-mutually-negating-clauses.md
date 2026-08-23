---
id: fix-introduces-mutually-negating-clauses
type: recurring-finding
status: open
occurrences: 3
first_seen: 2026-07-26
last_seen: 2026-08-22
links:
  - openspec/changes/rightsize-cash-skills/reviews/propose-r2.md
  - openspec/changes/tolerate-remount-device-renumbering/reviews/propose-r7.md
  - openspec/changes/guard-task-state-integrity/reviews/propose-r1.md
---

# Fix introduces mutually negating clauses

A fix adds an exemption or qualifier to a requirement without revisiting the neighbouring normative sentence, leaving two clauses in the same requirement that negate each other — one mandates a condition, the other exempts the very cases that violate it. The requirement becomes unsatisfiable as written, and any assertion derived from it must silently pick a side.

## Occurrences

- 2026-07-26 — rightsize-cash-skills — cash-propose round 2 — 為修正事實敘述而加入「已為單一陳述的 skill MUST NOT 僅因位置不同而被要求改動」的豁免句，卻未回頭處理同段既有的「規則 MUST 出現在首次使用之前」；`cash-archive`（`:34`／`:172`）與 `cash-propose`（`:45`／`:518`）實測正好違反該位置 MUST。修正為把位置降為 SHOULD 級建議。

- 2026-08-20 — tolerate-remount-device-renumbering — cash-propose round 7 — 同一條 Implementation Contract 先把訊息形態逐字釘死（「MUST 為 `<字串>`」），緊接著又要求同一則訊息必須額外包含一句下一步指引——釘死的形式裡沒有任何位置容納它，兩條 MUST 因此互相抵消。兩個子句分別由不同輪次的 fix 加入（釘死在第 2 輪、下一步在第 4 輪），單看任一輪都合理，交互才產生矛盾。同一份文件的姊妹條款只寫了釘死、沒帶到下一步，而 spec 與測試對照表卻對兩個 gate 都要求，於是依該條款實作出來的訊息會直接讓測試失敗。修法是把釘死改為兩段式——釘死前段 + 明文寫出的分隔符 + 釘死的下一步句——使完整字串仍可唯一導出。
- 2026-08-22 — guard-task-state-integrity — cash-propose rounds 2、5 — 兩次出現同型：IC4 第 4 點同一句內舉「回傳 tuple」為實作手段、又禁止改變 `archive.py` 呼叫點的取值形狀，而該呼叫點取值後直接當 dict 使用；以及 legacy 重複 id 的「放棄整次對齊並回傳原樣值」與同契約要求的「就地改寫 `task_id`」互斥——就地改寫之後原樣值已不存在，回傳的物件帶著部分改寫與重複 id，經 `mark_task_done()` 無條件寫入落地後下次讀取即被 `_validate_touched()` 拒絕。
