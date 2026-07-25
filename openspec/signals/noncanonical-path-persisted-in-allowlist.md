---
id: noncanonical-path-persisted-in-allowlist
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-25
last_seen: 2026-07-25
links:
  - openspec/changes/track-review-loop-outputs-in-allowlist/reviews/apply-r1.md
---

# 非 canonical 路徑被持久化到 allowlist

路徑驗證若以 canonical filesystem lookup 成功，卻把呼叫端的 alias 原字串寫入 allowlist，會形成「驗證成功但無法匹配實際 dirty path」的靜默失效；驗證、政策判定與持久化必須使用同一個 canonical project-root-relative 值。

## Occurrences

- 2026-07-25 — track-review-loop-outputs-in-allowlist — cash-apply round 1 — `touched record` 曾接受 `./openspec/signals/demo.md` 與重複 `/` alias，`path_kind()` 能找到檔案但 state 保留原字串，導致 `cash-commit` 無法匹配 git path；修正為統一使用 `Path(path).as_posix()` 並加入 alias regression test。
