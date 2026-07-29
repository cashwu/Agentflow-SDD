---
id: readonly-import-writes-bytecode-cache
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-28
last_seen: 2026-07-28
links:
  - openspec/changes/add-repo-vendored-cash-bundle/reviews/propose-r1.md
---

# Read-only import writes a bytecode cache

一條宣稱零寫入的驗證或執行路徑在檢查完成後載入 Python module，卻未停用 interpreter 的 bytecode cache。即使應用程式沒有顯式寫檔，import 仍可能建立或更新 `__pycache__`，使 `--help`、驗證失敗或 dry-run 等唯讀契約被隱性 side effect 破壞。

修法是在載入任何 project-local module 前設定 process-local no-bytecode 行為，並以檔案系統快照測試驗證成功與失敗路徑都完全零寫入。

## Occurrences

- 2026-07-28 — add-repo-vendored-cash-bundle — cash-propose round 1 — portable launcher 驗證 `.py` 後直接 import runtime，初稿未處理 `.pyc` 寫入；修正為在 import 前設定 `sys.dont_write_bytecode = True` 並加入 zero-write contract tests。
