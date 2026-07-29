<!-- cash-apply implementation notes | change: add-repo-vendored-cash-bundle | initialized: 2026-07-29 00:17 | no entries below means no deviations or open questions were recorded -->

## 2026-07-29 00:29 — 延後 portable launcher 的整合驗證勾選
- 類別：deviation
- 任務：3.1
- 內容：`.cash-skills/bin/cash` 的 portable gate 已完成基本 fixture 驗證，但 task 指定的完整 targeted tests 依賴後續 `--vendor` publisher 建立 canonical target；因此先保留 3.1 未勾選並繼續實作 4.1／4.2，待 publisher 可用後回頭執行全部 launcher targeted tests，再標記 3.1 完成。
- 原因：此調整只改變內部驗證與勾選時序，不改變 observable behavior、interface／資料形狀、失敗模式、驗收標準或範圍，也不需要 design.md 未定義的同步、identity／generation type 或 state machine。

## 2026-07-29 09:20 — 結案：3.1 的 launcher targeted tests 已完成
- 類別：deviation
- 任務：3.1
- 內容：`--vendor` publisher（4.1／4.2）完成後已回頭執行全部 launcher targeted tests 並勾選 3.1。涵蓋驗證：`test_installer_runtime.py` 的 portable gate 與 vendor 系列案例（manifest-presence 優先序、stale receipt cutover、pre-open unsafe／executable manifest、portable help／concurrent generation、malicious-but-import-valid `.pyc` 忽略、umask `022`／`002` 與 bytecode 零寫入、manifest drift fail closed）全數通過；後續修正 `install_vendored_target` 的 prelock snapshot 時序（snapshot 移到 `require_vendored_paths_committable` 之前）並將對應測試改為 git-shim deterministic 屏障後，最終結果為 `test_installer_runtime.py` 114/114、`skill-checks.fish` PASS、`test_bundle_version_history.py` 10/10、`test_init_receipt.py` 21/21，關鍵案例 `test_vendor_revalidates_source_and_target_plans_after_lock_wait` 單獨重跑 3 次皆綠。
- 原因：結束 00:29 條目所記的暫緩事項；驗證時序調整不改變 observable behavior、interface／資料形狀、失敗模式、驗收標準或範圍。
