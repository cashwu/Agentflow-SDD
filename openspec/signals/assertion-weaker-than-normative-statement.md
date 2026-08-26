---
id: assertion-weaker-than-normative-statement
type: recurring-finding
status: open
occurrences: 6
first_seen: 2026-07-25
last_seen: 2026-08-27
links:
  - openspec/changes/derive-version-assertion-and-add-cli-help/reviews/propose-r2.md
  - openspec/changes/harden-trace-path-containment-and-label-shape/reviews/propose-r1.md
  - openspec/changes/rightsize-cash-apply-tdd-discipline/reviews/apply-r3.md
  - openspec/changes/default-spec-sync-on-archive/reviews/apply-r3.md
  - openspec/changes/guard-task-state-integrity/reviews/propose-r1.md
  - openspec/changes/per-change-tdd-override/reviews/apply-r1.md
---

# 驗收斷言弱於其對應的 normative 陳述

spec 或 Implementation Contract 訂下一條較強的 MUST（例如排序、逐元素相等），但對應的驗收只斷言較弱的性質（例如集合相等），使違反該 MUST 的實作能通過全部斷言。這與「宣稱檢查、實際不檢查」同型，差別在於落差出現在規範與驗收之間而非規範與實作之間。

## Occurrences

- 2026-07-25 — derive-version-assertion-and-add-cli-help — cash-propose round 2 — spec 與 IC 要求 help 的 `commands` 欄位為排序後的 dispatch table key 陣列，但 IC4 與 tasks 只斷言集合相等；`COMMANDS` 的插入順序與排序後不同，因此 `list(COMMANDS)` 會違反 MUST 卻通過全部斷言。修法為改為逐元素等於排序後序列。
- 2026-07-26 — harden-trace-path-containment-and-label-shape — cash-propose round 1 — design 決策的核心是「MUST 為拒絕而非解析」，但 tasks 的對應 case 只斷言「該原字面值不在結果中」。一個把條件誤讀為「濾掉不合格的路徑段」再重組的實作會產生 `outside/x.py`、`a/b.py` 這類落在 repo 內的合法值，因而通過全部斷言，使該決策完全未被固定。修法是把拒絕類 case 的斷言改為集合相等。
- 2026-07-27 — rightsize-cash-apply-tdd-discipline — cash-apply round 3 — skill 已承載 example table 的完整逐列 verification contract，但測試只鎖定 `every row` 子句，移除每列 input 與 expected output 義務仍會通過；修正為對兩個變體逐字斷言完整 clause。
- 2026-08-22 — default-spec-sync-on-archive — cash-apply round 3 — round 2 把 IC1 第 8 點改為「位置是規範的一部分」（規則 MUST 放在步驟 6 的 bullet list 之外），但配套判準只是無錨點的字面值比對——把整段原樣改寫成 `- **Template selection**: …` 塞回清單內仍 exit 0；修正為補一條 `^   \*\*Template selection\*\*: use the` 錨定行首與內文縮排的判準。reviewer 以 mutation test 證實新判準具鑑別力。
- 2026-08-22 — guard-task-state-integrity — cash-propose rounds 2、3、4 — 本 run 反覆出現：IC 訂下較強的 MUST，配套判準只斷言較弱的性質。實例包含 IC3 的接線義務只有「函式被定義」的判準而無「函式被呼叫」的判準；`task_desc` 不得改寫的守則綁定 `mark_task_done()` 的區域變數名 `existing`，攔不住新函式內的改寫；IC1 第 2 點要求刪除兩行而只有一行有段落判準（reviewer 以 mutation test 證實違規實作通過全部 14 條判準）；IC1／IC3 的縮排義務以 `rg -F` 加前導空格表達，`-F` 是子字串比對只能排除少於該縮排的情形，以 6 空格插入仍會命中。
- 2026-08-27 — per-change-tdd-override — cash-apply round 1 — first-match contract 要求取第一個 `tdd:` 並忽略後續行，但測試只鎖 `first unindented` marker；修正為分別斷言 first-prefix、exact suffix 與 never-scan-later 義務。
