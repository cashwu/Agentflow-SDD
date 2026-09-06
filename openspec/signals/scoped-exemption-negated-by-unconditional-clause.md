---
id: scoped-exemption-negated-by-unconditional-clause
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-09-05
last_seen: 2026-09-05
links:
  - openspec/changes/add-host-derived-round-lint/reviews/propose-r6.md
---

# Scoped exemption negated by an unconditional sibling clause

為了移除一條不可達成的義務，修正在該義務上加了範圍限定（「僅適用於 X 情形」），但同一個 requirement 或同一段落中另有涵蓋同一對象的**無條件**子句未被同時限定，於是豁免被完全抵銷、原本要移除的不可達成 MUST 仍然成立。這種缺陷字串掃描抓不到——被加限定的那句確實改了，殘留的是語意上覆蓋同一對象的另一句，而它的措辭可能完全不同。加入任何範圍限定或豁免時，必須檢查同一 requirement 內是否存在以其他措辭涵蓋同一對象的無條件斷言。

## Occurrences

- 2026-09-05 — add-host-derived-round-lint — cash-propose round 6 — 前一輪把「不寫入 bytecode cache」的義務限定為只適用於 portable-manifest target（receipt-based target 的 bytecode 寫入發生在 import system、早於 handler，command 無從阻止）。但同一句仍無條件保留「排除 `.git/` 的 tracked 與 **untracked** 工作區內容……MUST 逐位元組不變」與「MUST NOT 建立目錄」，而 `__pycache__` 正是工作區內新建的 untracked 目錄——豁免因此不生效。另有一處反向陳述：同一份 design 的另一個 decision 末句仍寫無條件的「不寫 `.pyc`」，因為前一輪的窮舉掃描比對的是已知舊字串而非該同義措辭。
