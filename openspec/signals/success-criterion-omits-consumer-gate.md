---
id: success-criterion-omits-consumer-gate
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-28
last_seen: 2026-07-28
links:
  - openspec/changes/target-receipt-bootstrap/reviews/apply-r1.md
---

# Success criterion omits a gate the consumer enforces

一個 producer 的成功／零寫入判準只比對它自己關心的欄位（bytes、digest、內容），卻漏掉下游 consumer 實際會強制檢核的另一個維度（mode、權限、identity、schema 版本）。兩者在正常流程一致，因此落差只在該維度單獨漂移時才顯現：producer 依字面回報成功並跳過修復，consumer 隨即以自己的閘門 fail closed，使用者拿到「工具說成功、系統仍不可用」的組合。

這個缺陷的特徵是 contract 文字本身就是缺口來源，而非實作偏離 contract——照字面實作反而會產生壞結果。因此它常以「實作多做了一個 spec 沒寫的檢核」的形式被發現，正確處置是修 contract 而不是把實作改回字面。

修法是逐一列出下游 consumer 對該 artifact 實際強制的每個維度，並讓 producer 的等價／成功判準涵蓋同一組維度；任一維度漂移時走一般修復路徑而非回報 no-op。

## Occurrences

- 2026-07-28 — target-receipt-bootstrap — cash-apply round 1 — `--init-receipt` 的 spec 把零寫入條件寫成「既有 receipt 與重算結果逐 byte 等價時 MUST 回報 `current`」，但 launcher 以 `open_regular(receipt_path, 0o644)` 對 receipt 另設 mode 閘門。bytes 相同而 mode 漂移為 `0664` 時，照字面實作會回報 `current` 並跳過寫入，隨後 `cash` 仍以 `bootstrap_invalid` 失敗。實作原本多加了 `snapshot.mode == 0o644` 條件並以 `deviation` 記錄；review 判定實作正確而 contract 有缺口，改為把 spec、design 與 Implementation Contract 的等價條件同步為「bytes 與 contract mode 皆一致」。相關：[[umask-dependent-mode-contract]]。
