---
id: regression-target-not-path-verified
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-09-05
last_seen: 2026-09-05
links:
  - openspec/changes/dispatch-vendored-targets-in-batch/reviews/propose-r4.md
---

# Regression target chosen without verifying which code path it exercises

task 的 `regression` 欄指向一個既有測試，理由是它的**名稱或表面主題**與本次變更相關，但沒有查證該測試實際執行哪條程式路徑。結果是本次變更若回歸，該測試不會失敗——宣告的回歸防護是空的。名稱與 fixture 的相似度特別容易誤導：同一組輸入條件可以被兩支測試以完全不同的入口驗證（例如一支打 CLI 的安裝路徑、另一支打 target 端 launcher 的 bootstrap gate），兩者的斷言毫無交集。辨識方法是讀該測試實際呼叫的入口函式或子行程，確認它會經過本次變更要修改的那段程式。與 [[assertion-weaker-than-normative-statement]] 不同：那裡的斷言太弱，這裡的斷言根本不在同一條路徑上。

## Occurrences

- 2026-09-05 — dispatch-vendored-targets-in-batch — cash-propose round 4 — 兩位 reviewer 獨立指出，unsafe manifest shape 的 task 把 `test_manifest_present_unsafe_shapes_fail_before_open_without_receipt_fallback` 列為 regression，理由寫「以明示 mode 涵蓋同一組四種 shape」。該測試確實變造同一組四種 shape，但變造後只呼叫 `run_target_cash` 執行 target 端 launcher 並斷言 `"code":"manifest_invalid"`，完全不執行任何 installer mode，因此對本次要改的 `--all` 分派迴圈毫無保護。前一輪的 Fix Action 只驗證了「該測試存在」與「涵蓋同一組 shape」。修法是改指向會實際走過 per-record 分派迴圈的既有 batch 測試，並如實記載原測試涵蓋的是 launcher gate。
