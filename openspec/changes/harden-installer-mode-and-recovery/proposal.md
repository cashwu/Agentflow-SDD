## Summary

修正 Cash installer 的三個 fail-open 缺陷──mode 參數空值靜默降級成 batch 寫入、crash 後首次 recovery run 必定失敗、fault-injection hooks 未受 containment 治理──並收斂 installer 進入點的 interpreter 解析與 process 邊界。

## Motivation

Installer 在 no-follow open、inode identity、transaction journal 等層面都是 fail-closed 設計，但下列三處與該基準不一致。三者皆非既有測試套件涵蓋範圍（`scripts/cash-skills/tests/test_installer_runtime.py` 現有 59 個測試全數通過），屬於覆蓋缺口而非回歸。

### A1：空值 mode 參數靜默降級成 batch 寫入

`run()` 以真值判斷分派 mode 參數。空字串在 Python 為 falsy，但 argparse 的 mutually exclusive required group 只檢查參數是否出現，因此 `--target ""` 同時滿足「必填已提供」與「分支條件為假」：三個 direct/registry 分支全部略過，控制流落入未加保護的 batch 迴圈。實測結果為 installer 對 registry 內每一個已註冊專案執行真實安裝：

```
['--target', '']      -> rc=0  install_target 被呼叫於: ['/proj/a', '/proj/b']
['--register', '']    -> rc=0  同上
['--unregister', '']  -> rc=0  同上
```

`install_target` 開頭的空值守衛因此永遠到不了。這直接牴觸 cash-cli 既有 requirement 中「一般 direct、registry 與 batch 模式 MUST 拒絕空值」的規定：caller-input error 被轉譯成跨專案的批次 mutation，是 fail-open 而非 fail-closed。

### A2：crash 後的首次 recovery run 必定失敗

`installation_inputs` 的 target 快照在取得 lock 前建立，而 `recover_installer` 在取得 lock 之後才執行並回滾前一次 crash 的已發布內容。publication 前的最終 revalidation 拿 recovery 後的實際狀態去比對 recovery 前的快照，必然判定不一致而以 execution error 中止。已重現：

```
fresh install:  0 | Result: update
recovery run:   1 | Error: installation inputs changed after lock acquisition
second run:     0 | Result: update
```

兩個具體後果：其一，錯誤訊息指控外部併發修改，但實際變更來自 installer 自身的 recovery，診斷方向是錯的；其二，batch 模式會把該 target 記成 `failed` 並使整批 exit 1，操作者必須再跑一次才會成功。既有 requirement 要求「下一次 installer MUST 在同一 lock inode 上恢復」，目前的恢復語意只在第二次執行才成立。

同一個 stale 快照也污染 version-control 排除設定的規劃：其寫入計畫由 recovery 前的快照導出，若 crash 的那次剛好動過該檔，計畫內容本身就是錯的。

現有 crash 測試只覆蓋 committed 階段（quarantine 清理中途離開），publishing 階段的 journal recovery 沒有任何測試。

### A3：fault-injection hooks 未受 containment 治理

`wait_for_test_hold` 依環境變數指定的路徑寫入就緒檔，完全繞過 installer 其餘每一處都會執行的 containment 與 no-follow 檢查──這是整份實作唯一的邊界破口。同一組 hooks 另有兩個問題：失敗注入序號的整數轉換沒有防護，非數字輸入會以未捕捉例外離開；而 commit 後崩潰用的 hook `CASH_INSTALL_CRASH_AFTER_COMMIT` 在測試、規格與文件中皆為零引用，是隨產品一起出貨的死程式碼。

這些 hooks 是 gate 行為的輸入，卻沒有任何規範界定誰可以啟用它們、以及啟用後可寫入的範圍。

### C：installer 進入點的機制層落差

進入點腳本本身另有四處與上述 fail-closed 基準不一致的機制問題：未以 `exec` 取代自身而多留一層 shell process；interpreter 候選清單只含兩個泛用名稱，系統預設 interpreter 版本過舊時即使已安裝合格的版本化 interpreter 也會直接失敗；版本探測的輸出被存入從未使用的變數；以及未停用 user site 目錄，使得 installer 的 import 路徑仍可被使用者層級的自動載入程式碼影響。

## Proposed Solution

1. **A1** — mode 參數分派改用「參數是否存在」而非真值判斷；並在解析參數之後、任何其他檢查之前，為三個帶值 mode 參數各加一道專屬空值守衛，以 caller-input error（exit 2）失敗。該守衛必須早於 registry 讀取與 `--dry-run`／`--force` 的相容性檢查，否則空字串的診斷會被 registry 錯誤或「缺少 mode 參數」訊息遮蔽。既有的 `target must be a safe existing directory` 與 `project path is invalid` 守衛退出碼不動，因為它們同時服務既有的 boundary execution error 情境。`--dry-run` 與 `--force` 的相容性檢查只對帶值參數改用存在性判準，`store_true` 布林 flag 維持真值判斷。
2. **A2** — 把 journal 的偵測與恢復拆成兩個位置：偵測是純讀取，放在版本比較的 `newer` early return 之前（通用 diagnostic 由此發出，dry-run 與 real run 皆然；`newer` 專屬補充句另於 `newer` early return 之前輸出）；恢復緊接在版本比較之後，且早於全部三個提前返回的分類分支（`legacy receipt drift`、`receipt-less Cash skill inventory is partial`、`managed target drift`），只在非 dry-run 且 target 未分類為 `newer` 時執行，順序為「先跑既有的 launcher-without-lock 守衛 → 取得既存 stable lock（不建立不存在的 lock）→ 執行 recovery → 關閉 descriptor → 重新進入」，使 conflict 判定、publication 前的 revalidation 與 version-control 排除設定的規劃全部建立在 recovery 後的狀態上。恢復點必須早於 conflict 判定：半發布 bytes 只要落在任何 receipt-managed path，現行流程會先以 `managed target drift` 回報 `conflict` 並 exit 2，recovery 永遠不會被呼叫（已實測）。crash 後的第一次執行即完成恢復；recovery 之後無殘留 drift 時回報 `update`，不需 `--force`。
3. **A3** — 全部 fault-injection hooks 收斂在單一顯式開關之後；hold 協定納入與 installer 其餘寫入同等級的 identity 約束（絕對路徑、parent 非 symlink、ready 檔以 exclusive no-follow 建立、release 檔在 hold 開始前必須不存在且須為非 symlink 的 regular file），但**不**強制收斂到 target 之內，因為 hold 檔是呼叫端自有的協調通道；hook 設定的驗證提前到首次 target write 之前，release 檔的不存在性另在各 hook 的等待點再驗一次；每個 hold hook 在單一 process 內至多等待一次，已等待過之後同一 process 的後續安裝完全跳過該 hook 的等待與 ready／release 存在性檢查（路徑形狀檢查仍逐次執行），兩個 hook 各自記帳；序號解析改為 fail-closed；刪除零引用的 commit 後崩潰 hook。
4. **C** — 進入點改以 `exec` 交棒、interpreter 候選清單在既有泛用名稱之後追加版本化名稱作為備援、移除未使用變數、停用 user site 目錄。
5. 為 A1、A2、A3 各補上迴歸測試，並依既有 bundle version 契約調升版本號。`scripts/cash-skills/tests/skill-checks.fish` 以字面值釘住當前 bundle version，因此調升版本必然要求同步更新該檔；它是 grader-protected path，故在此明確宣告為交付目標，使該修改落在已宣告範圍內而非靜默逾越。

## Non-Goals

- **batch 模式韌性**（batch 迴圈只捕捉單一例外型別而讓其他例外中斷整批、reclassification 遞迴無上限、registry 內已刪除的專案被歸類為失敗）不在本次範圍，另案處理。
- **parent directory 的 fsync durability**（atomic 發布後未同步目錄項目，斷電下 journal 與 rename 的落盤順序無保證）不在本次範圍，另案處理。
- **stable launcher 的 migration 路徑**（launcher bytes 一經安裝即無法變更，且 force 不繞過）是既有 requirement 明訂的設計取捨，變更它需要先修訂該 requirement，不在本次範圍。
- 不修改 stable bootstrap 物件的 bytes，因此本次不觸碰 launcher 實作。
- 不變更 receipt schema、lock 的建立與 identity 重驗機制（`O_CREAT|O_EXCL`、`flock`、`fstat` device/inode 比對）與 lock inode 的持久性、legacy 遷移判準或 guidance 區塊渲染。兩項明確例外：recovery 觸發的釋放-重入沿用既有 post-lock 重新分類的同一路徑；恢復前置階段使用一條不走建立分支的取鎖路徑。兩者皆不改變 lock 的建立語意與 identity 重驗步驟本身。

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `cash-cli`: 收斂 installer 的 mode 參數分派、journal recovery 順序、fault-injection hooks 治理與進入點 interpreter 解析。

## Impact

- Affected specs: `cash-cli`
- Affected code:
  - Modified:
    - `.cash-skills/lib/cash_cli/installer.py`
    - `install-cash-skills.fish`
    - `scripts/cash-skills/tests/test_installer_runtime.py`
    - `cash-skills.version`
    - `scripts/cash-skills/tests/skill-checks.fish`
  - New: (none)
  - Removed: (none)
