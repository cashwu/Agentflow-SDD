<!-- cash-apply implementation notes | change: harden-installer-mode-and-recovery | initialized: 2026-07-25 09:03 | no entries below means no deviations or open questions were recorded -->

## 2026-07-25 09:05 — 以直接 checkbox 編輯替代 task done
- 類別：deviation
- 任務：1.1
- 內容：`cash task done --change harden-installer-mode-and-recovery 1.1` 因 tasks 描述後文再次引用 `1.1`，以 `error[task_not_found]: Unknown or duplicate task id: 1.1` 拒絕更新；改以 `apply_patch` 直接將 `tasks.md` 對應 checkbox 改為完成，後續任務亦在相同 CLI 限制下採用此方式。
- 原因：Cash CLI 目前以全文 task-id 匹配，無法區分 checkbox task id 與描述中的引用；替代方式只改變追蹤機制，不改變 tasks.md 作為 single source of truth、任務內容、可觀察行為或驗收標準。

## 2026-07-25 09:16 — 以 shim PID 取代 ps 子行程檢查
- 類別：deviation
- 任務：3.1
- 內容：進入點 process-boundary 測試不再從測試子行程呼叫 `/bin/ps` 列舉 `Popen.pid` 的子行程，改由受控 interpreter shim 在 `exec` Python 前記錄自身 PID，並斷言該值等於 `Popen.pid`。
- 原因：目前 sandbox 對測試子行程執行 `/bin/ps` 回傳 `PermissionError: [Errno 1] Operation not permitted`；PID 等值直接證明 fish 已以 `exec` 交棒、interpreter 未成為其子行程，保留相同 process-boundary contract、失敗模式與驗收目的。

## 2026-07-25 09:21 — 更正 task done 參數語意
- 類別：deviation
- 任務：1.1
- 內容：09:05 條目對 `task done` 失敗原因的判讀不正確；CLI 的 `<task-id>` 實際採 checkbox 出現順序（`1`、`2`、…），不是 tasks.md 顯示標籤（`1.1`、`1.2`、…）。前四項已直接更新的 checkbox 保持不變，後續任務恢復使用正確的 ordinal 呼叫 `cash task done`。
- 原因：保留 append-only Implementation Notes Protocol 並明確更正先前紀錄；直接 checkbox 編輯仍只改變追蹤機制，沒有改變 contract、範圍、行為或驗收標準。

## 2026-07-25 10:12 — hold 檔存在性錯誤加上階段標記
- 類別：deviation
- 任務：1.3
- 內容：`_require_absent_hook_file` 新增 keyword-only 的 `detail` 參數（預設維持 preflight 既有的 `already exists` 措辭），`wait_for_test_hold` 的兩次呼叫改帶 `detail="appeared after preflight"`；`test_hold_hook_revalidates_late_ready_and_release_shapes` 的斷言由通用字串 `invalid installer test hook` 改為階段標記，並加上 `assertNotIn("already exists", stderr)`。
- 原因：preflight 與等待點對同一形狀共用 `_require_absent_hook_file`，錯誤訊息原本逐字相同，該測試唯一決定階段的是 `time.sleep(0.2)`；時序失準時 late 檔會在 preflight 前建立，測試仍通過卻靜默退化成 preflight 案例的重複，使 scenario `等待點才可判定的 hold 形狀在等待點中止` 失去覆蓋。訊息文字不受任何 scenario 拘束（兩個 scenario 只要求各自以 execution error 中止），故屬純機制替換：可觀察的失敗模式、退出碼與驗收標準均不變，僅使兩個階段可被區分。反向驗證確認時序失準時測試改為失敗而非靜默通過。
