---
id: expected-set-derived-from-observed-state
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-28
last_seen: 2026-07-28
links:
  - openspec/changes/target-receipt-bootstrap/reviews/apply-r3.md
---

# Expected set derived from observed state

一個契約宣稱要做「完整性檢核」，實作卻以現地觀察到的狀態就地推導出期望集合（`glob`、目錄枚舉、掃描結果），再拿它跟自己比對。比對恆真，檢核因此是空談：缺項不會被發現，多項也不會被發現，而輸出的 artifact 是「自洽但錯的」——它內部一致，所以下游的完整性驗證器也會放行。

危害的形狀通常是「工具宣告成功、系統隨即以非契約的方式壞掉」：簽發者回報成功並 exit `0`，消費者卻在執行期以未捕捉的例外或 traceback 失敗，使用者拿不到任何具名錯誤。反向（集合多出項目）則常使另一個以固定期望集合嚴格比對的路徑永久卡死。

辨識線索：契約文字出現「任一⋯⋯缺失即 fail closed」，而實作中該類別的期望集合來自 `rglob`／`scandir`／`listdir`。同一份 inventory 裡若有些類別用常數推導、有些用枚舉推導，測試又只挑常數推導的路徑做 fail-closed 案例，就會形成 false-green——測試名稱看起來覆蓋了完整性，實際避開了唯一會靜默縮水的部分。

修法是為該類別建立一個獨立於觀察狀態的期望集合（內嵌常數、簽章清單、或由可信來源注入），比對差集後 fail closed 並在診斷列出差異；並讓該期望集合本身受 contract test 守衛，避免變成第二個會漂移的真相來源。若期望集合必須內嵌，需明確權衡它對 payload 擴充的約束（見 [[trust-root-inventory-blocks-payload-extension]]）。

## Occurrences

- 2026-07-28 — target-receipt-bootstrap — cash-apply round 3 — `--init-receipt` 的 D3 inventory 完整性檢核一步宣稱「inventory 完整性檢核：任何檔案缺失以 `init_inventory_invalid` 失敗」，但 `init_inventory` 的 runtime 條目來自 `library.rglob("*.py")` 的就地枚舉，只有 stable 與 24 個 skill 用常數推導。實測：target 少一個 `.cash-skills/lib/cash_cli/spec_merge.py` 時 init 回報 `initialized`、exit `0`、receipt 只有 18 筆 runtime record（正常 19 筆），launcher 的 `validate_receipt` 通過（它只驗證 receipt 已列出的 record，從不枚舉目錄），隨後 CLI 以 `ModuleNotFoundError: No module named 'cash_cli.spec_merge'` traceback 死亡——直接違反 Implementation Contract 第 1 項。反向：多一個 `.py` 時 init 同樣成功，但該 target 的 `install-cash-skills.fish --target`／`--all` 自此永久以 `receipt has an invalid record count` 失敗且 `--force` 不可繞過。名為 `test_missing_inventory_fails_closed` 的測試三個 case 全落在常數推導路徑上，剛好避開唯一會靜默縮水的部分。修法需引入 design 未定義的 runtime payload identity，觸發 Fix-loop design circuit breaker 並導向 `/cash-ingest`。相關：[[fixture-order-makes-assertion-vacuous]]、[[success-criterion-omits-consumer-gate]]。
