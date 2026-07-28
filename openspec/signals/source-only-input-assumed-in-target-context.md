---
id: source-only-input-assumed-in-target-context
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-27
last_seen: 2026-07-27
links:
  - openspec/changes/target-receipt-bootstrap/reviews/propose-r1.md
---

# Source-only input assumed in target context

設計讓一段邏輯在新的執行情境（installed target、fresh clone、CI sandbox）執行，卻沿用只存在於原情境（canonical source repo）的輸入——版本檔、設定檔、registry——而未定義該輸入在新情境的來源。設計在原情境測起來完全正常，第一次於真實新情境執行才發現輸入不存在。修法是逐一盤點該邏輯的每個輸入在目標情境的實際存在性，缺者明定替代來源（內嵌常數＋恆等守衛、部署時注入、或明確 fail closed）。

## Occurrences

- 2026-07-27 — target-receipt-bootstrap — cash-propose round 1 — `--init-receipt` 需要 receipt 首行的 `version` 值，但 `cash-skills.version` 是 source-only 檔（且是 `is_source_layout` 判定 marker）、fresh clone 亦無舊 receipt 可讀，原 artifacts 對版本來源零著墨；修正為 installer module 內嵌 `BUNDLE_VERSION` 常數並以 contract test 斷言其恆等於 `cash-skills.version` 內容。
