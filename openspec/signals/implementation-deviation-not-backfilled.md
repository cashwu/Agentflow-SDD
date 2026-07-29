---
id: implementation-deviation-not-backfilled
type: recurring-finding
status: open
occurrences: 2
first_seen: 2026-07-26
last_seen: 2026-07-29
links:
  - openspec/changes/rightsize-cash-apply-tdd-discipline/reviews/apply-r1.md
  - openspec/changes/add-global-cash-shim/reviews/apply-r1.md
---

# Implementation deviation not backfilled

實作以保留 contract 的替代機制完成並在 implementation notes 留下 deviation，但 design、tasks 或其他 durable artifacts 仍指向已證實不可行的原機制，使後續驗證或接手者重複遇到同一失敗。

## Occurrences

- 2026-07-26 — rightsize-cash-apply-tdd-discipline — cash-apply round 1 — Python 測試實際需要 `PYTHONPATH=.cash-skills/lib` 才能載入 in-repo package，implementation notes 已記錄替代命令，但 design 與已完成 task 仍保留不可直接執行的命令；修正後把已驗證命令回填至兩份 durable artifacts，並保留歷史 deviation 紀錄。
- 2026-07-29 — add-global-cash-shim — cash-apply round 1 — deletion test 因真實 `$HOME/.local/bin/cash` 原本不存在而改用隔離 `HOME` fixture，implementation notes 已記錄合理 deviation，但 task 4.1 仍只寫真實 shim 的暫移／還原路徑，未回填等價的條件式驗證契約。
