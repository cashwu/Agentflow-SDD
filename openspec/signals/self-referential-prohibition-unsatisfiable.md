---
id: self-referential-prohibition-unsatisfiable
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-25
last_seen: 2026-07-25
links:
  - openspec/changes/harden-installer-mode-and-recovery/reviews/propose-r4.md
---

# 自我指涉的禁止條款不可能被滿足

一條規範禁止某識別字出現在某個範圍內，而該規範本身就落在那個範圍內並逐字含有該識別字；archive 或發布之後該條款永久自我違反，依其字面設計的驗收步驟必定失敗。

## Occurrences

- 2026-07-25 — harden-installer-mode-and-recovery — cash-propose round 4 — requirement 寫「`CASH_INSTALL_CRASH_AFTER_COMMIT` MUST NOT 在測試、規格或文件留有引用」，但該句本身即為規格文字且含該識別字；修正為把範圍收斂到「作為可生效的 environment variable name 被讀取或設定」並豁免敘述性引用。
