---
id: fallback-preempts-existing-selection
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-25
last_seen: 2026-07-25
links:
  - openspec/changes/harden-installer-mode-and-recovery/reviews/propose-r1.md
---

# 備援機制反過來奪走既有選擇

為了在既有解析失敗時提供備援而加入的候選項，被排在既有候選之前，於是改變了所有原本就能正常運作的環境的選擇結果，超出「失敗時才備援」的動機範圍。

## Occurrences

- 2026-07-25 — harden-installer-mode-and-recovery — cash-propose round 1 — installer 進入點的 interpreter 候選清單原擬把版本化名稱排在泛用名稱之前，實測會使本機從 mise 管理的 python3 改用 Homebrew 的 python3.14 而繞過 toolchain shim；修正為泛用優先、版本化名稱僅作備援。
