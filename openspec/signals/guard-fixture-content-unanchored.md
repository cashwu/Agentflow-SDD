---
id: guard-fixture-content-unanchored
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-08-24
last_seen: 2026-08-24
links:
  - openspec/changes/refine-cash-tdd-test-guards/reviews/apply-r3.md
---

# Guard fixture content unanchored

一個守衛以某個 fixture 字串或集合作為比對來源，但沒有任何斷言釘住那個 fixture 的內容。把 fixture 清空、縮減成單一元素、或改寫成無關內容，守衛就靜默變成恆真，而 suite 仍然全綠——被掏空的是守衛的輸入，不是守衛本身，所以 code review 只看守衛的程式碼看不出問題。

這與 [[ungoverned-gate-input]] 的根因不同：那一類談的是「誰有權修改 gate input」的治理缺口，本類談的是「fixture 內容沒有機械錨定」，即使治理正確，一次善意的重構也可能把它掏空。與 [[fixture-order-makes-assertion-vacuous]] 的差別在於失效原因是內容而非順序。

辨識線索：測試裡出現 `for x in SOME_TUPLE`、`if token not in SOME_PROSE`、`assertNotIn(literal, SOME_DICT[key])` 這類以模組層級常數或行內 tuple 為比對來源的斷言，而該常數本身沒有 exact-set 斷言、沒有結構規則、也沒有錨定到任何獨立來源。判定方法是把該常數退化（清空、單元素、單字元、無關字串）後重跑，看 suite 是否仍綠。

修法優先序：(1) 錨定到一個獨立且已被釘死的來源（例如 canonical resource 的逐字 span，或 artifact 中逐字列出的清單）；(2) 以結構規則把 fixture 綁到另一個已被守衛的物件上，避免引入新的自由變數；(3) 若前兩者都不可行，以 exact-set 斷言把常數本身釘死。三者都會產生「這一層的輸入由誰守衛」的遞迴，因此終點必須是一個寫在斷言運算式內部的 literal，或一條具名記錄於 `## Risks / Trade-offs` 的取捨。

## Occurrences

- 2026-08-24 — refine-cash-tdd-test-guards — cash-apply round 3 — 同一個 change 連續三輪各在不同層級命中：round 1 是 `RETIRED_PERMISSIVE_TOKENS` 被削減為單一元素後 retired-token 守衛失效；round 2 是 `EXPECTED_NEGATION_RESTATEMENTS` 十三句全部改為空字串後 negation-containment 守衛失效；round 3 是 fish 側 `LEGITIMATE_PROSE` 清空後合法散文 acceptance case 靜默恆真，而該 fixture 在 detector 與 fixture 同步漂移的情境下是 `en` 半邊僅存的執行期約束。前兩者以 exact-set 斷言與結構規則封閉，第三者以歷史 false-positive token 錨定。教訓是：每加一層守衛就要同時問「這層的比對來源由誰守」，並在該問題的答案是「沒有人」時，當場決定終點並具名記錄。
