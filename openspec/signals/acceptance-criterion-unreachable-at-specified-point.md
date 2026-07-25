---
id: acceptance-criterion-unreachable-at-specified-point
type: recurring-finding
status: open
occurrences: 2
first_seen: 2026-07-25
last_seen: 2026-07-25
links:
  - openspec/changes/harden-installer-mode-and-recovery/reviews/propose-r1.md
  - openspec/changes/harden-installer-mode-and-recovery/reviews/propose-r7.md

---

# 驗收條件在指定位置不可能成立

scenario 的 THEN 指定了一個時間點（例如「首次 write 之前」），但被驗收的機制在程式碼中的位置晚於該時間點，使該條件在字面上無法成立；由於測試只斷言較弱的部分，測試仍會通過而落差不被發現。

## Occurrences

- 2026-07-25 — harden-installer-mode-and-recovery — cash-propose round 1 — hold path 形狀的 scenario 要求「在首次 target write 前 fail closed」，但兩個 hold 等待點都在 `acquire_lock` 建立 workspace lock 與 launcher 發布之後；修正為把 hook 設定驗證前移到任何取鎖之前的 preflight。

- 2026-07-25 — harden-installer-mode-and-recovery — cash-propose round 7（re-run）— 同一 requirement 內兩條 MUST 互斥而使 scenario 子句無任何實作可滿足：(1) 兩個 hold hook 指向同一路徑時「publication hook 仍正常等待」與 ready 檔 exclusive 建立、release 檔在等待點不得預先存在互斥；(2) 只在等待點可判定的 release 形狀被塞進「首次 target write 之前 fail closed」的 THEN，而等待點在 `acquire_lock` 之後。修法分別為 preflight 要求兩個 hold path 互異，以及把 scenario 依可判定時機拆為兩個。
