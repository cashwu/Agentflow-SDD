---
id: verified-source-import-bypassed-by-bytecode-cache
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-28
last_seen: 2026-07-28
links:
  - openspec/changes/add-repo-vendored-cash-bundle/reviews/propose-r2.md
---

# Verified source import is bypassed by a bytecode cache

launcher 驗證 source bytes 的 digest 後交給一般 Python import machinery 執行，但有效的既有 `.pyc` 可能讓 interpreter 不再編譯剛驗證的 source。攻擊者或舊環境便能讓「驗證的 bytes」與「實際執行的 code object」分離；停用新的 bytecode 寫入不能阻止讀取既有 cache。

修法是讓 loader 直接以剛驗證的 exact source bytes 建立 code object，並把載入範圍限制在預期的 project-local package；測試必須預先放置時間戳與 header 都有效但內容惡意的 `.pyc`，證明它不會被執行。

## Occurrences

- 2026-07-28 — add-repo-vendored-cash-bundle — cash-propose round 2 — round 1 的 `sys.dont_write_bytecode` 只解決寫入副作用，仍允許讀取既有 `.pyc`；修正為 `VerifiedSourceLoader` 對已驗證 bytes 呼叫 `source_to_code`，不走 cache lookup。
