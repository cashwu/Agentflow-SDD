---
id: prohibition-contradicts-required-mechanism
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-29
last_seen: 2026-07-29
links:
  - openspec/changes/add-global-cash-shim/reviews/propose-r1.md
---

# 絕對禁止條款與同一 requirement 要求的機制字面互斥

一條 requirement 同時包含絕對化的禁止條款（MUST NOT 寫入某範圍之外）與必然違反該禁止的必要機制（temp file、建立父目錄、lock 檔），逐字實作不可能同時滿足兩者，實作者被迫靜默選邊。與 fix-introduces-mutually-negating-clauses 不同，這不是修復引入的，而是初次撰寫時禁止範圍未把機制本身的必要寫入納入豁免。撰寫絕對禁止時應逐一盤點該 requirement 要求的機制會產生哪些寫入，並把範圍寫成涵蓋它們的封閉集合。

## Occurrences

- 2026-07-29 — add-global-cash-shim — cash-propose round 1 — spec 要求「MUST NOT 寫入 `$HOME/.local/bin/cash` 以外的任何路徑」，但同 requirement 要求 temp file 寫入與 `$HOME/.local/bin` 目錄建立；後續 r2 又發現父目錄 `$HOME/.local` 的同型殘留縫隙。修正為寫入範圍限定於目錄之內（含建立該目錄與必要父目錄）。
