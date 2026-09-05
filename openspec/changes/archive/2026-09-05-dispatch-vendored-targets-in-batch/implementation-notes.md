<!-- cash-apply implementation notes | change: dispatch-vendored-targets-in-batch | initialized: 2026-09-05 10:42 | no entries below means no deviations or open questions were recorded -->

## 2026-09-05 10:44 — manifest 發佈時序改為增量，4.1 的 `bootstrap` marker 改為接受 `current`
- 類別：deviation
- 任務：1.1
- 內容：design D13 與 Implementation Contract 12 把 `./install-cash-skills.fish --self` 的重新發佈安排在收尾（task 4.1），並以 `Result: bootstrap` 為驗收 marker。實作時發現 cash-apply 的 Managed bundle publication 協定要求「改動受管 runtime 後、在下一個 Cash command（含 `task done`）之前」完成發佈，且環境本身也強制如此——把 `BUNDLE_VERSION` 由 `2.20.3` 改為 `2.21.0` 之後，`.cash-skills/bin/cash` 立即以 `{"error":{"code":"manifest_invalid","message":"portable manifest digest drift: .cash-skills/lib/cash_cli/installer.py"}}` fail closed，任何 Cash command 都無法執行。因此發佈改為在每個修改 `installer.py` 的 task 結束時各執行一次；到 task 4.1 時 manifest 已是 canonical，該指令會回報 `Result: current` 而非 `Result: bootstrap`。已據此把 tasks.md 4.1 的 success marker 與 design Implementation Contract 12 改為接受兩者之一，並保留「manifest 為 canonical 且反映最終 `installer.py`」這個實質驗收條件不變。
- 原因：交付物本身不變——收尾狀態同樣是 canonical manifest 且 `runtime_generation` 與 record digest 反映最終的 `installer.py`；改變的只是達成該狀態的時序，以及因此而不同的指令回報值。替代手段不需要任何 `a synchronization primitive, identity/generation type, or state machine not defined in design.md`，也不改變範圍或使用者可見的取捨，因此依 blocker triage 的機制替換分支繼續，不暫停。原設計把發佈排在收尾是唯一可行選項的假設，在 launcher 的 manifest gate 之下不成立。

## 2026-09-05 10:50 — 2.3／2.4／2.6 的 red marker 在其自身位置不可觀察
- 類別：deviation
- 任務：2.3
- 內容：tasks.md 把分派實作放在 2.1，而 2.3、2.4、2.6 是 delivery 只有 `scripts/cash-skills/tests/test_installer_runtime.py` 的 test-only task，且它們宣告的 red 全都描述 2.1 實作之前的基線（2.3：「該 target 被回報為 `failed` 而非 `would-update`」；2.4：「hard link 情境仍由 receipt 路徑以 `use --vendor` 拒絕、stdout 行不含 `(vendored)`」；2.6：「該 target 兩次都被回報為 `failed`」）。由於 2.1 已依文件順序先完成，這三個 red marker 在各自的位置上已不可能觀察到——新增的測試一寫完就是綠燈。實際觀察到的 red 是 2.1 的 `target is managed by a portable manifest; use --vendor` 與非零結束碼（該次 red 一併涵蓋了這三個 task 所釘住的分派行為），以及 2.2 的 `TypeError`。這三個 task 因此以 TDD precedence 第 3 支（不改變可觀察行為的 characterization／contract pin）執行：測試仍逐條斷言 design 與 spec 要求的可觀察行為，只是不重跑 red phase。
- 原因：交付物與驗收實質不變——三個 task 要求的測試全部寫入且通過，所釘住的可觀察行為與 Implementation Contract 10 逐項相符。改變的只是 red 證據的取得位置：它在 2.1 一次取得，而非在每個 test-only task 各取得一次。要讓每個 red 在自身位置可觀察，必須把四個測試全部前移到 2.1 的 production edit 之前，那會改變 tasks.md 的任務切分與順序，屬 contract 之外的重排；而本次交付的行為、interface、失敗模式與驗收標準都不因此改變，替代手段也不需要任何 `a synchronization primitive, identity/generation type, or state machine not defined in design.md`，故依 blocker triage 的機制替換分支繼續，不暫停。

## 2026-09-05 11:31 — 已完成 task 的描述不得改寫，兩處措辭更正改由本記錄承載
- 類別：deviation
- 任務：n/a
- 內容：apply review round 1 有兩筆 Suggestion 要求改寫已完成 task 的描述文字——task 1.1 的理由句「從本 task 完成到 4.1 的 `--self` 之間」在增量發佈之下於 task 邊界上不再成立，以及 task 2.2 應註明 spec scenario「分派後 manifest 消失則 fail closed」的「計為 `failed`」子句由迴圈通用行為承擔。實際改寫後 `cash touched ensure` 以 `error[touched_invalid]: Touched task description is absent from tasks.md` 失敗：`.cash-skills/state/touched/<change>.json` 逐字保存每個已完成 task 的 `task_desc`，並以它與 tasks.md 的比對維持「哪些檔案屬於哪個 task」的稽核軌跡。改寫已完成 task 的描述會使該軌跡失效，進而使 `cash-commit` 失去來源允許清單。因此兩處改寫已還原為原文，更正內容改記於此：(1) 該腳本實際的失敗窗口是「從 `BUNDLE_VERSION` 被改動到該 task 自身的 `--self` 發佈之間」，權威敘述在 design D12；(2) 「計為 `failed`」子句刻意由 `--all` 迴圈既有的「任何 `InstallerError` → `failed`」通用行為承擔，並由 2.5 的 batch 測試釘住，因為該競態在 `--all` 層無法確定性重現。
- 原因：兩筆都是 confidence 50 的非 blocking Suggestion，而執行它們會破壞一個具體且可觀察的狀態不變式；權衡下保留稽核軌跡、把更正放進本記錄，是成本較低且不損失資訊的一邊。交付物、可觀察行為與驗收標準都不因此改變，也不需要任何 `a synchronization primitive, identity/generation type, or state machine not defined in design.md`，故依 blocker triage 的機制替換分支繼續，不暫停。
