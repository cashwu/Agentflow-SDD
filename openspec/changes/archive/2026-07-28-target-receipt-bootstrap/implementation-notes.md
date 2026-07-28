<!-- cash-apply implementation notes | change: target-receipt-bootstrap | initialized: 2026-07-27 23:11 | no entries below means no deviations or open questions were recorded -->

## 2026-07-27 23:26 — `current` 零寫入的等價判定納入 receipt mode

- 類別：deviation
- 任務：2.1
- 內容：spec 與 design D3-9 的字面條件是「既有 receipt 與重算結果逐 byte 等價時回報 `current` 零寫入」。實作在 `init_publish_receipt` 的等價條件額外要求 `snapshot.mode == 0o644`：bytes 相同但 mode 漂移（例如被 umask 002 的複製動作改成 `0664`）時，走一般簽發路徑重寫 receipt 並回報 `initialized`，而不是回報 `current`。
- 原因：launcher 的 `open_regular(receipt_path, 0o644)` 對 receipt 有 mode 閘門，bytes 相同但 mode 非 `0644` 的 receipt 仍會使 CLI 以 `bootstrap_invalid` 失敗。若照字面只比對 bytes 就回報 `current`，會產生「模式回報成功但 CLI 依然不可用」的結果，直接違反 Implementation Contract 第 1 項（init 後 `.cash-skills/bin/cash list --json` 成功執行）。spec 未涵蓋此 corner，取偏向可用性的解讀；spec 的零寫入 scenario 前提是由 init 剛簽發的 receipt，該情形 mode 必為 `0644`，行為不變。

## 2026-07-27 23:42 — 上述 deviation 已由 artifact 修訂吸收

- 類別：deviation
- 任務：2.1
- 內容：Round 1 的 Reviewer A 指出，`current` 等價判定納入 `snapshot.mode == 0o644` 屬可觀察行為與 spec 字面不符，正確處置是修 artifact 而非僅記 `deviation`。已於 Round 1 fix actions 將 spec delta 的等價條件、design D3-9 與 Implementation Contract 第 2 項同步為「bytes 與 contract mode `0644` 皆一致才回報 `current`；bytes 一致但 mode 漂移時走一般簽發路徑」。實作未變更，前一筆條目保留為歷史紀錄，該分歧自本次修訂起不再是 deviation。
- 原因：實作行為經查證為正確（launcher 以 `open_regular(receipt_path, 0o644)` 對 receipt 設 mode 閘門），需要調整的是 artifact 對該 corner 的敘述；此修訂不需要 design 未定義的機制，屬 review loop 的一般 fix action，不觸發 design circuit breaker。
