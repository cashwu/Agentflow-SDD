# Cash Propose Review — Round 2

## Reviewer Findings

### Warning

- `severity`: Warning｜`confidence`: 85｜`layer`: design｜`disposition`: fix-introduced｜來源: Reviewer V
  - `introduced_by`: round 1 fix actions「proposal.md：Impact 增列 cash-ingest parity diff（條件式）」與「tasks.md：4.1 納入 cash-ingest parity diff」（design 端未同步更新）
  - `location`: design.md 決策 6 與 C6 第二項
  - `summary`: proposal Impact 與 tasks 4.1 已涵蓋 cash-ingest parity diff，但 design 決策 6 與 C6 未評估 cash-ingest；實查其 hunk（@@ -256）位於編輯點（locale 句，約行 115）之後，是最可能實際觸發重生者，三份 artifact 敘述不一致。
  - `recommendation`: 決策 6 補 cash-ingest 評估；C6 涵蓋兩檔。

### Suggestion（非阻擋）

- V-2（confidence 90，text，fix-introduced，introduced_by: round 1 fix action「C2 標題註明 cash-ingest 不在 self-check 之列」）：C2 標題括注錯位，「位於……Checks 清單」文法上黏在 cash-ingest 後面造成自相矛盾。已順手修復。

## Rating

- post-filter cumulative blocking set：Critical 0、Warning 1（V-1）
- 非阻擋 triaged findings：1（V-2）
- `critical_gap`: false
- `round_type`: micro
- 理由：round 1 的 3 個 blocking 成員經 Reviewer V 逐項實跑驗證全數 resolved 並自集合移除；但修復引入 V-1（design 端 parity 評估未同步，fix-introduced、confidence 85）進入 blocking set，集合非空，須下一輪驗證修復。

## 驗證解除紀錄（cumulative blocking set 移除）

- B1 Critical（governed 字面值）：resolved — 修復參照 round 1 fix action（design 決策 5 間接描述改寫）；驗證者 Reviewer V（rg 全 change 目錄無匹配 + skill-checks.fish PASS exit 0 實跑）。
- A1/B2 Warning（C1 錨點）：resolved — 修復參照 round 1 fix action（C1 逐檔錨點列舉 + 四缺席斷言）；驗證者 Reviewer V（逐錨點對照兩變體實際檔案行號與措辭，斷言覆蓋一一對應）。
- B3 Warning（cash-ingest 缺席）：resolved — 修復參照 round 1 fix action（Impact/C1/tasks 2.1 納入 ingest）；驗證者 Reviewer V（實查 Impact 清單、C1 條目、ingest SKILL.md 行 115 locale 句存在）。

## Fix Actions

- design.md：決策 6 補 cash-ingest parity 評估（divergent、hunk @@ -256 在編輯點之後、最可能觸發重生）；C6 第二項改為涵蓋 cash-propose 與 cash-ingest 兩檔（V-1）。C2 標題括注語序修正（V-2）。
- 修復後驗證：propagation grep（design 內 cash-ingest 指涉 5 處一致）、governed 字面值仍缺席、`spectra validate chinese-spec-content --strict` 通過。
- 修改檔案：design.md。

## Decision

next_round
