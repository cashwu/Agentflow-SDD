---
id: added-assertion-preempts-existing-guard
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-08-24
last_seen: 2026-08-24
links:
  - openspec/changes/refine-cash-tdd-test-guards/reviews/apply-r3.md
---

# Added assertion preempts existing guard

為了強化某個測試而新增的斷言，與既有守衛之間存在邏輯蘊含關係，且被排在既有守衛之前。結果是既有守衛永遠不可能成為首先失敗或唯一失敗的斷言：刪掉它，suite 的 pass/fail 結果完全不變；觸發它要偵測的退化時，出現的是新斷言的訊息而非它自己的具名診斷。強化的動作反而製造出一個 dead guard。

危害有兩層。表層是診斷力：既有守衛的訊息通常比新斷言精確地指出「哪一個不變式被破壞」，被取代後定位成本上升。深層是可稽核性：若某份 artifact 曾把該守衛的具名訊息記錄為驗收或 RED 證據，該證據在現行程式碼下已不可重現，而沒有任何檢查會發現這件事。

辨識線索：一次 fix 在既有斷言附近插入新斷言後，既有斷言的訊息不再出現在任何 mutation 的輸出裡。判定方法是刪除既有斷言後重跑同一組 mutation——若失敗數與失敗訊息都不變，它已被蘊含且被取代。

修法通常只是調換順序，讓被蘊含者排在蘊含者之前，並把該順序寫進 contract；不需要新增斷言。若兩者的蘊含關係是數學必然（例如「子字串」蘊含「被拒絕」），順序即為唯一可用的補救，應同時把該殘餘關係誠實記錄，避免宣稱它們是彼此獨立的守衛。

## Occurrences

- 2026-08-24 — refine-cash-tdd-test-guards — cash-apply round 3 — 為了封住「negation restatement inventory 可被靜默掏空」而新增的 `assert_accepted`，被放在 negation-containment 的 `assertNotIn` 之前。二者為嚴格蘊含（literal 若是 negation 的子字串，則 negation append 到 canonical 後必被 validator 拒絕），因此 `assertNotIn` 永遠不會是首先失敗者；刪除它，乾淨狀態與 mutation 狀態的結果都不變。連帶使 `tasks.md` 記錄的 RED 證據「具名指出 literal 仍是其否定句的子字串」不可重現。修法是把 `assertNotIn` 移到最前並在 Implementation Contract 加入該順序條款；蘊含關係本身無法消除，已誠實記錄為已知殘餘。
