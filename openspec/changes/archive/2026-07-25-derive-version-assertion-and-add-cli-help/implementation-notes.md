<!-- cash-apply implementation notes | change: derive-version-assertion-and-add-cli-help | initialized: 2026-07-25 12:42 | no entries below means no deviations or open questions were recorded -->

## 2026-07-25 13:02 — receipt 缺失走的是 bootstrap_invalid 而非 receipt_invalid

- 類別：deviation
- 任務：1.2
- 內容：`design.md` 原記載 fresh clone 執行 `cash --help` 會得到 `receipt_invalid`。實作 task 1.2 的 characterization test 時量測發現，`.cash-skills/receipt.tsv` **缺失**時 launcher 回報的是 `bootstrap_invalid`，只有 receipt **存在但內容無效**時才是 `receipt_invalid`。因此把 `design.md` 該句的 code 更正為 `bootstrap_invalid`，並把原本規劃的單一測試拆成兩個——`test_help_does_not_bypass_missing_receipt`（斷言 `bootstrap_invalid`）與 `test_help_does_not_bypass_invalid_receipt`（斷言 `receipt_invalid`）——分別鎖住兩條路徑。
- 原因：delta spec 的 `#### Scenario: Help 不繞過 receipt gate` 本來就寫「維持既有的 `bootstrap_invalid` 或 `receipt_invalid` 失敗」，涵蓋兩個 code；落單的是 `design.md` 的敘述。要交付的觀察行為（help 不繞過 receipt gate、不輸出 help、exit code 1）完全不變，屬 contract 不變的事實更正，故依機制替換分支記 `deviation` 後繼續，未暫停。拆成兩個測試是因為只鎖其中一個 code 會讓另一條路徑無人看守。
