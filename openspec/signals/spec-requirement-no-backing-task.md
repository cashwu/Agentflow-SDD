---
id: spec-requirement-no-backing-task
type: recurring-finding
status: open
occurrences: 8
first_seen: 2026-07-04
last_seen: 2026-08-20
links:
  - openspec/changes/version-spectra-plus-skills/reviews/propose-r1.md
  - openspec/changes/version-spectra-plus-skills/reviews/propose-r2.md
  - openspec/changes/guard-dirty-source-auto-repair/reviews/propose-r1.md
  - openspec/changes/guard-dirty-source-auto-repair/reviews/propose-r3.md
  - openspec/changes/add-review-loop-discipline/reviews/propose-r2.md
  - openspec/changes/add-review-loop-discipline/reviews/apply-r3.md
  - openspec/changes/add-review-loop-discipline/reviews/apply-r4.md
  - openspec/changes/add-review-loop-discipline/reviews/apply-r5.md
  - openspec/changes/replace-spectra-cli-with-cash-cli/reviews/propose-r3.md
  - openspec/changes/bootstrap-openspec-config-on-install/reviews/propose-r1.md
  - openspec/changes/harden-trace-path-containment-and-label-shape/reviews/propose-r1.md
  - openspec/changes/tolerate-remount-device-renumbering/reviews/propose-r1.md
---

# Spec requirement with no backing task

A Spectra change artifact introduced a requirement, failure mode, or implementation contract item without a matching task or test expectation that would force it to be implemented and verified.

## Occurrences

- 2026-07-04 — version-spectra-plus-skills — spectra-propose-plus rounds 1-2 — Review found spec/design requirements for generator and installer failure behavior that were not fully backed by tasks or tests.
- 2026-07-04 — guard-dirty-source-auto-repair — spectra-propose-plus rounds 1 and 3 — Review found dirty-source guard scenarios and porcelain status coverage that were not fully backed by task/test expectations.
- 2026-07-07 — add-review-loop-discipline — spectra-propose-plus round 2 — The MODIFIED lifecycle requirement bound the signals write step to preserve `check` fields, but no task delivered that obligation into the SIGNALS-WRITE-STEP template block until task 2.4 was added.
- 2026-07-07 — add-review-loop-discipline — spectra-apply-plus rounds 3-5 — Review found the generator checks did not fully force the literal protected path set to appear inside the `<!-- GRADER-IMMUTABILITY -->` block until bounded-section assertions covered every protected path and anchor order.
- 2026-07-23 — replace-spectra-cli-with-cash-cli — cash-propose rounds 1–5 — archive trace、consumer JSON element shapes、config/parser branches與installer recovery edge cases曾缺少逐欄fixture backing；修正後tasks加入snapshot、fault與migration矩陣，剩餘abort obligations仍需後續task同步。
- 2026-07-26 — bootstrap-openspec-config-on-install — cash-propose round 1 — delta spec 以 MUST 要求「transaction failure 的回滾涵蓋新建的 `openspec/config.yaml`」，但 tasks 宣告的五個測試 case 沒有任何一個觸發 publication failure；實作若改用 `atomic_write` 直寫而非 `transaction.add`，全部 task 仍會綠燈。既有的 `TEST_CASH_INSTALL_FAIL_AFTER_PATH` fault-injection pattern 現成可用，缺的只是把它列進 tasks。
- 2026-07-26 — harden-trace-path-containment-and-label-shape — cash-propose round 1 — delta 對「粗體或其他 markdown 強調標記形式、以及全形冒號形式的標籤列 MUST NOT 被視為子清單起點」並列了一條 MUST，但 tasks 只有粗體的護欄 case、Implementation Contract 的測試清單也只列粗體，全形冒號完全沒有落點；tasks 的 requirement 追溯表卻逐字宣告該條款由該 case 涵蓋，等於為一個不存在的落點背書。

- 2026-08-20 — tolerate-remount-device-renumbering — cash-propose round 1 — 新增 requirement 的八個 scenario 中有四個在 Implementation Contract 與 tasks 裡找不到任何對應驗證，唯一兜底是最後一個 task 的「逐條列出證據」，那是人工敘述而非機械驗證。修法是建立 scenario 對照表並逐條指向具體測試函式名稱，把兜底 task 降為彙整而非唯一證據來源。
