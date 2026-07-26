---
id: invariant-encodes-only-one-change-direction
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-26
last_seen: 2026-07-26
links:
  - openspec/changes/harden-trace-path-containment-and-label-shape/reviews/propose-r1.md
---

# Invariant encodes only one direction of a two-way change

一個變更同時包含方向相反的兩個改動（一處收緊、一處放寬），但為它撰寫的迴歸不變式只編碼了其中一個方向——典型形式是斷言新結果為舊結果的子集。該不變式在提出當下的語料上恰好成立，因為觸發另一方向的輸入形狀出現數為 0，於是「偶然成立」被誤讀為「語意的直接編碼」。一旦語料變動，一個完全正確的實作會產生反方向的差異並被判為缺陷，而同一份驗證任務通常同時禁止排除檔案與放寬規則，使實作者沒有合法的脫困路徑。

與 `assertion-weaker-than-normative-statement` 相反：那是斷言太弱而放過錯誤實作，這是斷言方向錯誤而攔下正確實作。修法是分側斷言——為每個方向各自寫出「合乎設計的差異」判準，並且不把列舉宣稱為封閉集合。

## Occurrences

- 2026-07-26 — harden-trace-path-containment-and-label-shape — cash-propose round 1 — 變更同時收緊 `_canonical_path`（只會減少抽取結果）與放寬 `- Affected code:` 標籤形狀（只會增加），但全語料等價性驗證斷言「`new` MUST 為 `old` 的子集且 `new` 減 `old` MUST 為空」並自稱是「本變更語意的直接編碼」。實際上它只編碼了收緊那一半；只要語料新增一份以 `- Affected code: <path>` 行內形式書寫的合法 proposal——正是該 proposal 自己論證最可能出現的變體——斷言即失敗。修法是改為分側不變式，並在後續輪次進一步把列舉降為判定輔助而非封閉集合。
