---
id: field-value-extraction-rule-undefined
type: recurring-finding
status: open
occurrences: 6
first_seen: 2026-09-05
last_seen: 2026-09-06
links:
  - openspec/changes/add-host-derived-round-lint/reviews/propose-r4.md
  - openspec/changes/add-host-derived-round-lint/reviews/apply-r5.md
  - openspec/changes/add-host-derived-round-lint/reviews/apply-r7.md
  - openspec/changes/add-host-derived-round-lint/reviews/apply-r8.md
  - openspec/changes/add-host-derived-round-lint/reviews/apply-r10.md
  - openspec/changes/add-host-derived-round-lint/reviews/apply-r11.md
---

# Field value extraction rule undefined

一個 gate 或斷言以「某欄位／某 section 的**值**恰為 X」表述比對條件，卻沒有定義如何從實際的 artifact 文字中擷取那個「值」。合規的來源文件通常帶有格式修飾——backtick 包裹、bullet 前綴、全形冒號、值之後緊接的說明段落——而依「值恰為」的字面實作會把整段內容當成值，於是**全部合規的輸入都判為失敗**。這比漏判更危險：當該 gate 是阻擋型且每次互動都執行時，缺口在啟用當天就對所有無關工作生效。凡以「值」為比對單位的 normative 條款，都必須在同一處寫死擷取規則。

## Occurrences

- 2026-09-05 — add-host-derived-round-lint — cash-propose round 4 — `decision_value` 與 `round_type_position` 兩個 gate 都寫「`## Decision` 的值恰為……」「`## Rating` 所記 `round_type`」，但沒有任何 artifact 定義擷取方式。實際 round file 的形狀是 `## Decision` 之下一行 backtick 包裹的值、再接一整段既有契約本就要求的 rationale 段落；`## Rating` 的形狀是 `` - `round_type`：`micro` ``（backtick 加全形冒號）。依字面實作會使該 change 自己已產出的四份合規 round file 全部判 `fail`。修法是在 design 與 spec 同時寫死兩條擷取規則（取 section 第一個非空行去 backtick；取含該欄位的 bullet、取半形或全形冒號之後去 backtick 的 token），並把該迴圈自身產出的 round file 列為必須判 `pass` 的 fixture。
- 2026-09-06 — add-host-derived-round-lint — cash-apply round 5 — scope extraction initially treated fenced examples and nested Verification text containing `Affected code:` as declarations；改為只解析真正的 list-item、追蹤 fenced block，並明確排除 Verification 子樹。
- 2026-09-06 — add-host-derived-round-lint — cash-apply round 7 — `Example:` 本身雖被略過，但其子樹仍可被當成 affected-code 路徑；同時 task `delivery:` 的欄位擷取規則過窄，漏掉描述文字後的實際格式。修正為遞迴排除 Example 子樹，並從真正 task bullet 的欄位邊界擷取 delivery。
- 2026-09-06 — add-host-derived-round-lint — cash-apply round 8 — same-line `Affected code:` 尚未套用與子項相同的白名單，附帶 `Notes:` 文字仍可貢獻路徑；改為所有 affected-code 宣告共用 explicit path／label parser。
- 2026-09-06 — add-host-derived-round-lint — cash-apply round 10 — 非宣告 `Notes:` 本行雖已排除，但其縮排子樹仍可被逐行解析；改為保存非宣告父節點的縮排並排除整棵子樹。
- 2026-09-06 — add-host-derived-round-lint — cash-apply round 11 — 英文 label 偵測仍無法涵蓋繁中冒號與無冒號散文父節點；改為只允許明確路徑及三種合法容器，其餘一律排除整棵子樹。
