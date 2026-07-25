---
id: enumerated-site-set-factually-wrong
type: recurring-finding
status: open
occurrences: 2
first_seen: 2026-07-25
last_seen: 2026-07-25
links:
  - openspec/changes/harden-installer-mode-and-recovery/reviews/propose-r4.md
  - openspec/changes/harden-installer-mode-and-recovery/reviews/propose-r5.md
  - openspec/changes/harden-installer-mode-and-recovery/reviews/propose-r6.md
  - openspec/changes/harden-installer-mode-and-recovery/reviews/propose-r7.md

---

# 枚舉的受影響位置集合與實際不符

artifact 以枚舉方式列出某項變更需要處理的全部位置（測試、注入點、呼叫端），但該枚舉與實際程式碼不符——漏列、多列或計數與列項自相矛盾——於是依該枚舉施工的實作只會覆蓋一部分，未覆蓋者靜默失效。

## Occurrences

- 2026-07-25 — harden-installer-mode-and-recovery — cash-propose rounds 4–6 — fault-injection hook 測試的注入路徑枚舉連續三輪不正確：先是漏列全部經 `install` helper `TEST_` 轉譯層的兩個測試並宣稱「沒有一個經過該層」，修正後又留下「六個測試分屬四條路徑」但只列出三組的計數矛盾。

- 2026-07-25 — harden-installer-mode-and-recovery — cash-propose round 7（re-run）— recovery 的位置錨定只列舉 `managed target drift` 一個提前返回分支，但 `install_target` 在它之前還有 `legacy receipt drift` 與 `receipt-less Cash skill inventory is partial` 兩個分支；fresh install 在 skills 發布途中崩潰恰恰命中後者，因此本變更的核心修復在最典型情境下仍不成立，而所有既有 fixture 都建在已安裝 target 上、測試不會捕捉。修法為改以「緊接在 `newer` early return 之後、早於全部三個分支」錨定並具名列出。
