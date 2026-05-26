## Context

`install-spectra-plus.fish` 目前負責把 generated plus skills 安裝到單一目標專案，並確保 `spectra-commit` 具備 archive-first allowlist 與 plus deletion guard。實務上，使用者打開 `/Applications/Spectra.app` 後，Spectra 可能重新產生多個專案的 skill 目錄，導致多個 target 同時遺失 plus workflow。單一 target installer 已經 idempotent，但缺少「有哪些 target 要維護」與「何時批次修復」的操作層。

## Goals / Non-Goals

**Goals:**

- 提供一個 project registry，保存需要自動維護 plus skills 的 target project 清單。
- 提供 repair-all 流程，一次修復 registry 中所有有效 target。
- 提供 macOS LaunchAgent 安裝/移除流程，讓 Spectra.app 造成 reset 後能自動補回所有註冊 project。
- 保持現有單一 target installer 行為相容，並沿用既有 generator 與 guard patch 邏輯。

**Non-Goals:**

- 不修改 `/Applications/Spectra.app`、app bundle、code signing 或 Spectra 內部資源。
- 不新增大型 daemon、第三方 dependency 或常駐 GUI helper。
- 不讓 repair-all 自動新增未知專案；只有 registry 中明確註冊的 target 會被處理。
- 不改變 generated plus skill 的內容生成規則。

## Decisions

### Registry stores explicit project targets

使用純文字 registry 檔案保存 target 清單，預設位置為 `$HOME/.config/spectra-plus/projects.txt`。每行一個絕對路徑，空行與 `#` 開頭註解忽略。`install-spectra-plus.fish --register-target <project>` 會驗證 target 存在並正規化為絕對路徑後寫入 registry；重複註冊不得產生重複列。`--unregister-target <project>` 會移除對應正規化路徑。

替代方案是掃描固定父目錄尋找所有 Spectra project。這會誤觸使用者不想維護的 repo，也會在大型 workspace 上增加成本，因此排除。

### Repair-all reuses the single-target installer contract

`--repair-all` 與 `scripts/spectra-plus/repair-all.fish` 讀取 registry 後，對每個 target 呼叫同一套單一 target 安裝/驗證邏輯，而不是複製 generator 或 guard patch 實作。這讓既有 `install-spectra-plus.fish --target <project>` 的 idempotency、錯誤訊息與驗證規則維持單一來源。`--unregister-target` 是 registry cleanup 操作，不要求 target 目錄仍存在；它應以 registry-compatible absolute path normalization 移除 stale entry，避免已刪除 project 永久留在 repair-all failure set。

repair-all 的結果要逐 target 彙整。單一 target 失敗不應中止後續 target；整體 exit code 在任一 target 失敗時為非零，stdout/stderr 必須列出成功、跳過與失敗 target。

### LaunchAgent triggers bounded repair instead of modifying Spectra.app

macOS 自動化使用 LaunchAgent，預設 label 為 `com.agentflow.spectra-plus.repair`，plist 放在 `$HOME/Library/LaunchAgents/com.agentflow.spectra-plus.repair.plist`。LaunchAgent 執行 repair-all，而不是打開 Spectra.app 的 wrapper。這能覆蓋使用者從 Finder、Spotlight、Dock 或 CLI 任意方式打開 Spectra.app 的情境。LaunchAgent 的 `ProgramArguments` 應使用安裝時解析出的 `fish` 絕對路徑執行 repo 內 entrypoint，或由 entrypoint 設定受控 PATH 並明確檢查 `fish` / `yq`；缺少必要 command 時，錯誤必須寫入固定 log path。非 dry-run `--install-launch-agent` 必須在寫入 plist 後用 `launchctl bootstrap gui/$UID <plist>` 或等價方式載入/刷新目前使用者 session 的 agent；若載入失敗，installer 要以非零 exit 回報並輸出可執行的 manual activation instruction。

LaunchAgent 採用 `StartInterval` 週期檢查，預設 60 秒，並由 repair-all 內部 lock/throttle 保護避免重入。throttle window 不得大於 `StartInterval`，避免自動修復延遲超過 LaunchAgent 週期預期。`WatchPaths` 對 app 內部重寫行為不一定穩定，且多 project reset 不一定有共同 watch root，因此不作為主要觸發方式。

### Lock and throttle keep automatic repair quiet

repair-all 必須使用 lock file 防止重入，並支援 throttle window 避免短時間內重複執行造成不必要的 mtime/git noise。預設 lock 可放在 `$TMPDIR/spectra-plus-repair.lock` 或 `$HOME/.cache/spectra-plus/repair.lock`；最近執行嘗試時間可放在 `$HOME/.cache/spectra-plus/last-repair-attempt`。throttle 以「repair-all 嘗試」為單位更新，不以整體成功為前提；即使 registry 含 invalid target 並導致非零 exit，下一次 LaunchAgent 觸發仍會在 throttle window 內被跳過。手動 `--repair-all --force` 可略過 throttle，但仍遵守 lock。lock 應使用 atomic create + exit/trap cleanup；若偵測到 older-than-threshold stale lock，repair-all 必須清楚復原或提示 manual cleanup，避免自動修復永久停止。

## Implementation Contract

- `install-spectra-plus.fish --register-target <project>`：驗證 `<project>` 是目錄，寫入正規化絕對路徑到 `$HOME/.config/spectra-plus/projects.txt`，重跑不得重複新增同一路徑。
- `install-spectra-plus.fish --unregister-target <project>`：從 registry 移除正規化絕對路徑；路徑不存在於 registry 時仍成功並輸出 no-op 訊息；`<project>` 不需要仍存在於 filesystem。
- `install-spectra-plus.fish --list-targets`：列出 registry 中有效的 target 路徑，不包含空行與註解。
- `install-spectra-plus.fish --repair-all`：讀取 registry，對每個 target 執行既有單一 target installer 行為，並輸出 per-target summary；summary 至少區分 success、skipped 與 failed，任一 target 修復失敗時整體 exit code 非零；dry-run 不得建立或更新 lock、cache、throttle state。
- `scripts/spectra-plus/repair-all.fish`：提供 LaunchAgent 可直接呼叫的 thin entrypoint，行為等同 `install-spectra-plus.fish --repair-all`。
- `install-spectra-plus.fish --install-launch-agent`：建立或更新 LaunchAgent plist，確保 ProgramArguments 指向 repo 內的 repair-all entrypoint，使用目前 registry 預設路徑，提供可找到 `fish` / `yq` 或可記錄缺失錯誤的受控執行環境，並載入/刷新目前使用者 session 的 LaunchAgent。
- `install-spectra-plus.fish --uninstall-launch-agent`：卸載並移除該 LaunchAgent plist；未安裝時仍成功。
- `--dry-run` 搭配 register/unregister/repair-all/install-launch-agent/uninstall-launch-agent 時不得寫檔或呼叫 `launchctl`，但必須列出會做的操作。
- 自動修復不得修改 `/Applications/Spectra.app`，也不得掃描並修復 registry 外的 project。
- repair-all 的 target set 只能來自 registry；即使其他 Spectra project 位於同一父目錄或同時被 Spectra.app reset，也不得掃描、推斷或修改未註冊 project。

驗證方式：新增 repair-all 測試建立兩個 temporary target，先移除 plus skill outputs 或 guard，再確認 `--repair-all` 一次補回兩個 target；測試 registry 去重、unregister no-op、stale target unregister、缺失 target 的非零 exit、per-target success/skipped/failed summary 與 dry-run 不改 registry/project/lock/cache/throttle state；測試 LaunchAgent dry-run/plist 內容可預期且 dry-run 不呼叫 `launchctl`；測試非 dry-run install 會透過 stub `launchctl` 載入/刷新 agent，載入失敗會非零 exit 並輸出 manual activation instruction；測試最小 PATH 下 LaunchAgent entrypoint 行為與 log；測試 invalid target 造成非零 exit 後仍會更新 throttle attempt，避免 LaunchAgent 在 throttle window 內重複觸碰 valid targets；測試預設 throttle window 不大於 `StartInterval`；測試 stale lock recovery 或 manual cleanup 訊息。

## Risks / Trade-offs

- [Risk] `StartInterval` 不是即時觸發，Spectra reset 後可能最多延遲一個 interval 才修復。→ Mitigation：預設 60 秒，預設 throttle window 不大於 interval，並保留手動 `--repair-all --force`。
- [Risk] registry 中有已刪除或不可讀 project。→ Mitigation：repair-all 對該 target 記錄失敗或 skipped，繼續處理其他 target，最後用非零 exit 讓自動化 log 可觀察。
- [Risk] 自動修復可能在使用者手動編輯 skill 時覆寫 generated plus files。→ Mitigation：plus skills 本來就是 derived artifacts；僅 registry 中明確註冊 target 會被修復。
- [Risk] LaunchAgent 環境 PATH 較少，可能找不到 fish/yq。→ Mitigation：plist 使用絕對路徑或 repair-all entrypoint 內解析必要 command，錯誤寫入 log 檔。
