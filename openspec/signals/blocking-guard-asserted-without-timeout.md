---
id: blocking-guard-asserted-without-timeout
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-09-05
last_seen: 2026-09-05
links:
  - openspec/changes/dispatch-vendored-targets-in-batch/reviews/apply-r1.md
---

# A guard against unbounded blocking is asserted without a bounded wait

某個 guard 的存在理由就是防止無界阻塞（開啟 FIFO、等待鎖、等待外部回應），而釘住它的測試卻以不帶 timeout 的方式呼叫受測入口。結果是這條驗收在兩個方向都失效：guard 正常時測試通過但沒有驗證任何時間性質；guard 退化時測試不是失敗，而是**連同整個套件一起掛死**——CI 上呈現為逾時的 job 而非可讀的失敗，且本地執行者會以為是自己的環境問題。特別容易發生在同一個測試檔裡有多個 subprocess helper、其中部分有 `timeout` 參數而另一部分沒有的時候：作者挑了語意最貼近的 helper，卻沒注意到它正好是缺 timeout 的那一個。辨識方法是對每個宣稱「不阻塞」「不掛死」「在時限內完成」的驗收，回頭確認其呼叫路徑上真的存在有界等待；修法是為該 helper 補上 timeout 參數並傳入明確上限，再以 mutation check 確認移除 guard 後測試確實以 timeout 失敗而非掛死。與 [[assertion-weaker-than-normative-statement]] 不同：那裡的斷言檢查了較弱的性質，這裡的斷言在該性質上完全不存在，且失敗模式是掛死而非假綠。

## Occurrences

- 2026-09-05 — dispatch-vendored-targets-in-batch — cash-apply round 1 — 兩位 reviewer 獨立提出。Implementation Contract 與 delta spec scenario 都要求 unsafe manifest shape 的「不阻塞」被釘住，task success marker 更逐字宣稱「該測試在其自身的 subprocess timeout 內完成」，但該測試唯一使用的 `run_installer` helper 的 `subprocess.run(...)` 不帶 `timeout`——同檔的 `install`／`vendor`／`run_target_cash` 三個 helper 都有。若分派守衛退化、FIFO manifest 落到 vendored 路徑，`read_regular` 會以 `O_RDONLY | O_NOFOLLOW` 且不帶 `O_NONBLOCK` 開檔而永久阻塞。修法是為 `run_installer` 補上 `timeout` 參數並在該測試傳入 60 秒，並以 mutation check 驗證：移除 probe 的 `ensure_regular_shape` 後，FIFO 子情境確實以 `subprocess.TimeoutExpired ... after 60 seconds` 失敗。
