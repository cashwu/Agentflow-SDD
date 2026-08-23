---
id: normative-rule-without-acceptance-scenario
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-08-22
last_seen: 2026-08-22
links:
  - openspec/changes/guard-task-state-integrity/reviews/propose-r5.md
---

# Normative rule added to prose without an acceptance scenario

review round 為修復某個 finding 而在 requirement 散文新增一條規則，但沒有同步新增對應的 `#### Scenario:`。當該 change 的測試義務是逐條掛在 scenario 上時（例如「delta spec `## ADDED Requirements` 之下的每一條 scenario MUST 有一個對應測試方法」），只寫進散文的規則因此完全落在測試義務之外——一個違反該規則的實作能同時通過全部判準與逐條 scenario 覆蓋核對。與 [[assertion-weaker-than-normative-statement]] 的差別在於落差的位置：那是 scenario 存在但斷言太弱，這是 scenario 根本不存在。

## Occurrences

- 2026-08-22 — guard-task-state-integrity — cash-propose round 5 — round 4 為修復 legacy 重複 id 的永久卡死而新增「放棄本次對齊並原樣回傳，MUST NOT 失敗」，以及「僅順序改變仍 MUST 視為對齊改變了內容」兩條規則，兩者都只寫進 ADDED requirement 的散文；唯一涉及重複 id 的既有 scenario 其 GIVEN 未帶 legacy 條件，因此一個把 legacy 重複 id 也照 fail closed 實作的版本（即該修復要避免的情形）能通過全部驗收。修正為各補一條 scenario 並收窄既有 scenario 的 GIVEN。
