---
id: self-invalidated-code-reference
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-28
last_seen: 2026-07-28
links:
  - openspec/changes/target-receipt-bootstrap/reviews/apply-r3.md
---

# Self-invalidated code reference

design 或 proposal 以行號指向既有程式碼作為決策前提，撰寫當下逐條實檔驗證過，但**該 change 自己的實作就修改了同一個檔案**，插入的行數使全部行號整體位移。artifact 因此在自己被實作的過程中把自己的引用作廢，卻仍保留「皆已實檔驗證」這類斷言。

與 [[design-claim-unverified-against-code]] 的差別在根因：那一個是 claim 從未對照程式碼、憑記憶或推論寫出；這一個是 claim 當初確實成立，因本 change 的編輯而失效。前者靠「寫之前去讀程式碼」解決，後者靠「不要用會被自己作廢的指標」解決——review 時若只查「claim 是否成立」，兩者看起來一樣，但修法不同。

實質內容通常仍然正確（凍結條款、判定式、常數值都還在），失效的只有指標，所以它很少造成執行期缺陷，危害是誤導後續 change：維護者照行號跳過去看到不相干的程式碼，可能誤判約束已不存在。

修法是引用穩定的識別子而非位置——函式名、常數名、錯誤訊息字面值、或「A 在 B 之前呼叫」這類關係敘述。只有當被引用檔案在本 change 中逐 byte 凍結（例如受 stable freeze 條款保護的 launcher）時，行號才是安全的引用形式。

## Occurrences

- 2026-07-28 — target-receipt-bootstrap — cash-apply round 3 — `design.md` 的 Context 與 D5 共 5 處 `installer.py:` 行號引用（`:985` `publish_launcher`、`:498-507` `parse_receipt`、`:1384-1393` 版本比較前的 receipt 解析、`:1915` `__main__` 進入點、`:42` `GUIDANCE_PATHS`）全部指向修改前的檔案，實檔對照後無一成立（實際為 994／507／1393-1402／2223／43），而 Context 明寫「三重凍結約束（皆已實檔驗證）」。偏差正是本 change 自己插入的 `BUNDLE_VERSION`、`InitError` 與全部 `init_*` 函式所致。凍結約束的實質內容逐條實測皆成立。修法為改引函式名／常數名；同一份 design 中對 `.cash-skills/bin/cash` 的行號引用予以保留，因為 launcher 在本 change 中逐 byte 凍結。
