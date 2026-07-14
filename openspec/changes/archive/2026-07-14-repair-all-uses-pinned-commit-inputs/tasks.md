## 1. 先建立核心回歸測試

- [x] 1.1 依 `Repair-all uses pinned commit inputs`、`Repair checks plus metadata freshness` 與設計「從單一 commit 具現化最小共用輸入」，在 `scripts/spectra-plus/tests/repair-all-checks.fish` 建立可控制 `HEAD` 與 dirty working tree 的 fixture；新增先失敗的案例，證明工作區 installer、rules、template 或 guard source 有未提交變更時，repair-all 仍使用 commit 內容修復 stale target。以執行 `fish scripts/spectra-plus/tests/repair-all-checks.fish` 時新案例在既有實作上失敗、且失敗原因是 dirty skip 或工作區輸入被讀取來驗證。

- [x] 1.2 依 `Repair all registered plus skill targets`、設計「由 snapshot 同時判定 current state 與執行安裝」及 Implementation Contract 的「Behavior」與「Interface / data shape」，新增三態 current-state 與收斂案例：0 回報 already current、10 才委派安裝、其他狀態回報 failed 且不委派；成功修復後第二次執行不得再次安裝。以測試能分別證偽「所有非零都當 stale」與「父行程用工作區斷言判定」的實作來驗證。

- [x] 1.3 依設計「將 snapshot 清理限定為本次執行擁有的路徑」及 Implementation Contract 的「Failure modes」，新增 snapshot 建立、archive、extract、metadata 驗證與 current-state error 的失敗案例；共用 snapshot failure 須在 target processing 前非零結束、不修改 target、不建立或更新 lock／throttle，且不留下本次 snapshot；per-target current-state error 須不修改該 target、繼續其他 target、釋放 lock，並保留既有 throttle 語意。以每個 failure injection 都能單獨觸發並檢查資源狀態來驗證。

## 2. 實作 pinned snapshot 核心

- [x] 2.1 依設計「從單一 commit 具現化最小共用輸入」，在 `install-spectra-plus.fish` 實作 source-top 與 `HEAD^{commit}` 解析、唯一 snapshot 建立、指定共用輸入的 `git archive` 與解壓縮；每個 git 呼叫以 source top 錨定，archive 與 extract 分別檢查狀態。以 task 1.1 的 pinned-input 測試與 task 1.3 的硬失敗測試通過來驗證。

- [x] 2.2 依設計「將 snapshot 清理限定為本次執行擁有的路徑」，加入未 export 的 snapshot ownership state、只刪除該唯一目錄的 fish exit cleanup，以及正常與 dry-run 的顯式 cleanup；不得加入 stale reaper 或修改 lock ownership。以 task 1.3 全部清理案例通過，並以兩個以上 stale target 證明 snapshot 子行程不會提前刪除父 snapshot。

- [x] 2.3 依設計「由 snapshot 同時判定 current state 與執行安裝」，新增唯讀的 `--check-current <target>` 介面與固定 exit contract 0／10／其他 error；repair-all 父行程不得直接呼叫工作區的 `target_is_current`。以 task 1.2 三態、唯讀性與版本落差案例通過來驗證。

- [x] 2.4 整合一般與 dry-run repair flow，使 metadata validation、current-state verdict 與 stale target installation 都來自同一 snapshot；依設計「保留既有 lock、throttle 與 per-target failure 語意」，snapshot 共用失敗在取得 lock 前終止，per-target error 則繼續下一個 target。以既有 lock／throttle／continue-after-failure 測試保持通過，並以 task 1.1 至 1.3 的新測試全綠驗證。

## 3. 移除阻斷行為並維持相鄰契約

- [x] 3.1 依 removed requirement `Repair-all protects registered targets from dirty source checkout` 與設計「移除 dirty-source guard 且不加入替代 gate」，刪除 dirty-path helper、repair-all dirty skip 與舊測試的 skip 預期；不得加入 advisory 或 rebase／bisect／merge 類 gate。以 `rg` 確認 production code 不再含 `source_dirty_paths`、`source_sensitive_path_matches`、`porcelain_entry_paths` 或 `dirty source checkout`，並以 dirty source 回歸案例實際修復 target 來驗證。

- [x] 3.2 依 `LaunchAgent-based automatic plus skill repair`，改寫原本依賴 dirty skip precedence 的 LaunchAgent 測試，使缺少必要 dependency 時清楚非零失敗，而 dirty source 本身不再掩蓋 dependency、lock、throttle 或 registry 行為；不得修改 LaunchAgent plist、lock stale recovery 或 throttle window。以 LaunchAgent entrypoint 相關案例與既有 lock／throttle 案例全數通過來驗證。

- [x] 3.3 依 `Auto-restore stripped commit guard source from git HEAD`，保留直接 `--target` 的既有 auto-restore，並驗證 repair-all 從 snapshot 讀 guard source、不以 source-input recovery 改寫未註冊的 source checkout。以 `fish scripts/spectra-plus/tests/installer-commit-guard-checks.fish` 全綠，以及 source checkout 未註冊時 guard 工作區檔案 byte-for-byte 不變來驗證。

- [x] [P] 3.4 更新 `SPECTRA-PLUS.md`，只記錄 repair-all 使用 pinned commit 共用輸入、dirty working tree 不阻擋、三態檢查失敗會大聲回報，以及直接 `--target` 不變；不得加入 advisory、lock redesign 或 Git operation gate。以人工檢查文件符合 Implementation Contract 的「Acceptance criteria」與「Scope boundaries」，且沒有聲稱 repair-all 會治理工作區來驗證。

## 4. 完整驗證與範圍稽核

- [x] 4.1 執行 `fish scripts/spectra-plus/tests/repair-all-checks.fish`、`fish scripts/spectra-plus/tests/installer-commit-guard-checks.fish` 與 `fish scripts/spectra-plus/tests/generator-checks.fish`；三個 suite 必須全綠，且 repair-all 核心案例須證明 dirty source 可修復、pinned metadata 生效、第二輪 already current、current error 不委派、handled failure 無 snapshot 殘留。

- [x] 4.2 檢查最終 diff 僅包含 proposal Impact 所列 production／test／documentation 路徑與本 change artifacts；確認沒有 lock reclamation、ownership token、stale reaper、advisory、Git operation gate、base-skill recovery 或直接 `--target` 行為變更。以 `spectra validate repair-all-uses-pinned-commit-inputs` 通過及逐項對照 Implementation Contract 的「Scope boundaries」完成驗證。
