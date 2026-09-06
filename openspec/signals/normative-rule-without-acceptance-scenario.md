---
id: normative-rule-without-acceptance-scenario
type: recurring-finding
status: open
occurrences: 2
first_seen: 2026-08-22
last_seen: 2026-09-05
links:
  - openspec/changes/guard-task-state-integrity/reviews/propose-r5.md
  - openspec/changes/add-host-derived-round-lint/reviews/propose-r1.md
  - openspec/changes/add-host-derived-round-lint/reviews/propose-r4.md
  - openspec/changes/add-host-derived-round-lint/reviews/propose-r5.md
---

# Normative rule added to prose without an acceptance scenario

review round 為修復某個 finding 而在 requirement 散文新增一條規則，但沒有同步新增對應的 `#### Scenario:`。當該 change 的測試義務是逐條掛在 scenario 上時（例如「delta spec `## ADDED Requirements` 之下的每一條 scenario MUST 有一個對應測試方法」），只寫進散文的規則因此完全落在測試義務之外——一個違反該規則的實作能同時通過全部判準與逐條 scenario 覆蓋核對。與 [[assertion-weaker-than-normative-statement]] 的差別在於落差的位置：那是 scenario 存在但斷言太弱，這是 scenario 根本不存在。

## Occurrences

- 2026-08-22 — guard-task-state-integrity — cash-propose round 5 — round 4 為修復 legacy 重複 id 的永久卡死而新增「放棄本次對齊並原樣回傳，MUST NOT 失敗」，以及「僅順序改變仍 MUST 視為對齊改變了內容」兩條規則，兩者都只寫進 ADDED requirement 的散文；唯一涉及重複 id 的既有 scenario 其 GIVEN 未帶 legacy 條件，因此一個把 legacy 重複 id 也照 fail closed 實作的版本（即該修復要避免的情形）能通過全部驗收。修正為各補一條 scenario 並收窄既有 scenario 的 GIVEN。

- 2026-09-05 — add-host-derived-round-lint — cash-propose rounds 1、4、5 — 三次同型。round 1：唯讀性 requirement 的三條 MUST 與兩個 scenario 沒有任何 task 承載。round 4：grader immutability requirement 宣告兩個宣告來源（proposal `## Impact` 與 `tasks.md` delivery target），但只有前者有 distinguishing scenario，後者只出現在否定前提中，因此完全忽略 `tasks.md` 的實作能通過每一個 scenario。round 5 最值得記：round 4 才剛把此形狀判為 Warning 並修正，同一輪新增的兩條窄化規則（聯集限 active、parked 不計 active）卻再度沒有 distinguishing scenario，忽略它們的實作能通過當時全部 32 個 scenario。新增窄化規則時最容易漏——因為它讀起來像是既有規則的補述，而非新的可觀察行為。
