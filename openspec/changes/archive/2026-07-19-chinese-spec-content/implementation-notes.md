<!-- cash-apply implementation notes | change: chinese-spec-content | initialized: 2026-07-19 12:55 | no entries below means no deviations or open questions were recorded -->

## 2026-07-19 14:20 — 內部標題引用隨標題翻譯（C3 不變量宣告例外）
- 類別：deviation
- 任務：1.6
- 內容：42 個 requirement 標題中文化後，spec 內文 38 處與 SKILL.md 共用 grader-immutability 段 8 處以 backtick 引用舊英文標題的規範性交叉參照斷鏈。apply round 1 審查（Reviewer A/B 合併 finding）判定為 design C3「code-span 位元組不變」不變量與標題中文化的交界矛盾。修復：46 處引用逐一改為對應中文標題，並在 design C3 將「內部 requirement-title 引用隨標題同步翻譯」列為第二個明示允許差異來源。
- 原因：不變量原意是防翻譯漂移，非凍結斷鏈引用；例外採逐一對應驗證（移除英文標題 span 集合 == 新增中文標題 span 集合），維持防護強度。

## 2026-07-19 15:05 — 標題引用第 47 處（縮短形式）補修
- 類別：deviation
- 任務：1.6
- 內容：apply round 2 Reviewer V 發現 spec.md:1393 尚有 1 處 `Confidence-scored findings`（HEAD 既有的縮短引用形式）未列入 46 處枚舉。已替換為完整中文標題 `具信心分數的 findings 與過濾器`，design C3 枚舉自 7+2 擴為 8+2。
- 原因：round 1 枚舉以完整標題字串搜尋，未涵蓋縮短引用形式；本次修復使引用比 HEAD 更精確（HEAD 即為不完整前綴引用）。
