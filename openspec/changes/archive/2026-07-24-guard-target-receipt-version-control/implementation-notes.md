<!-- cash-apply implementation notes | change: guard-target-receipt-version-control | initialized: 2026-07-24 22:31 | no entries below means no deviations or open questions were recorded -->

## 2026-07-24 22:42 — FIFO 形狀的 `.gitignore` 會阻塞而非 fail closed

- 類別：open-question
- 任務：1.1
- 內容：`.gitignore` 的安全性檢查沿用既有的 `optional_snapshot` → `read_regular`，它以 `os.open(O_RDONLY|O_NOFOLLOW)` 開檔。symlink、directory 與 hard link 都能正確 fail closed（實測含 `--force`），但若 `.gitignore` 是 FIFO，`os.open` 會阻塞到有 writer 為止，變成 hang 而不是 execution error。此行為並非本次新增：`.cash.yaml`、`.spectra.yaml`、`openspec/config.yaml` 與 guidance files 走同一條 `read_regular` 路徑，同樣有此性質。本次改動只是讓 `.gitignore` 這個使用者完全掌控的路徑也進入該讀取集合。
- 原因：修正需要改動共用的 `read_regular`（例如加上 `O_NONBLOCK` 後再以 `fstat` 判定 regular file），影響範圍涵蓋本 change 範圍以外的所有 managed 讀取路徑，屬於 `Scope boundaries` 之外，因此依 Surgical Changes 紀律記錄而不逕行修改，交由使用者決定是否另開 change。

## 2026-07-24 22:59 — 上一則 open-question 已於 apply round 1 修復

- 類別：deviation
- 任務：1.1
- 內容：apply review round 1 的 Reviewer A 指出上述 open-question 的「超出範圍」判斷不成立：不必改動共用的 `read_regular`，只要在 `installation_inputs` 開頭對 `GITIGNORE_PATH` 加一次 `ensure_regular_gitignore()`（`os.lstat` 後以 `stat.S_ISREG` 判定）即可在任何 open 之前 fail closed，範圍完全落在本 change 內。已依此修復並在 `test_gitignore_unsafe_shapes_fail_closed_before_any_write` 加入 `fifo` 形狀（含 `--force`）與 60 秒 timeout 斷言。原 open-question 條目保留為歷史記錄，此條為其 resolution，不再阻塞。
- 原因：`spec.md` 的 `Target 版控排除保護` 與 design `### Error contract` 都明文要求非 regular file MUST 在首次 target write 前以 execution error 失敗，因此這是實作既有 contract，而非變更 contract；不觸發 fix-loop design circuit breaker。
