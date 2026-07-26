## Summary

讓 installer 在 target 缺少 `openspec/config.yaml` 時，於同一個安裝 transaction 內建立一份預設的 schema-valid config，使從未被 spectra／openspec 初始化過的全新 Git repository 也能直接完成安裝。

## Motivation

目前 installer 的 preflight 要求 target 必須已有安全可讀、schema-valid 的 regular `openspec/config.yaml`，缺檔一律 fail closed。這個前置條件只有被舊 spectra／openspec 工具初始化過的專案才會滿足，因此對一個全新的 Git repository 執行安裝會在第一步就失敗：

```
Error: cannot open regular file openspec/config.yaml: [Errno 2] No such file or directory: '/Users/cash/Github/iphoneLocationMove/openspec/config.yaml'
```

診斷本身也沒有指出要建立什麼檔案。使用者必須先手動猜出一份合法 config 才能安裝，這讓 Cash bundle 事實上無法獨立部署到新專案。`.cash.yaml` 已經有「兩者皆無時逐 byte 建立 source canonical baseline」的三分支處理，`openspec/config.yaml` 缺少對等待遇是不一致的缺口，而非有意的安全邊界：缺檔不會造成刪除逃逸或身分混淆，真正的安全風險只在既有檔案的 unsafe shape 與 invalid 內容。

## Proposed Solution

把 target 的 `openspec/config.yaml` 從「必須已存在」改為「缺檔即 bootstrap」：

1. preflight 允許 target 缺少 `openspec/config.yaml`，但既有檔案仍以 no-follow 方式驗證 shape 與 schema；symlink、hard link、非 regular file 與 schema-invalid 內容維持在首次 target write 前 fail closed，`--force` 不繞過。形狀判定在任何 open 之前先以 `lstat` 完成，因此 FIFO 以 execution error 失敗而非阻塞等待 writer。
2. 缺檔時，installer 以內建的 canonical 預設內容（`schema: spec-driven` 加註解）在同一個 monotonic bootstrap transaction 內以 `0644` 建立 `openspec/config.yaml`；transaction failure 一併回滾這個新檔。
3. 這個 plan 沿用既有的 installation inputs snapshot 機制：preflight 與取得 stable lock 後各解析一次，兩次不一致時重新分類，避免 lock 前後的競態把既有檔案覆蓋掉。
4. 既有且合法的 config 逐 byte 保留、零寫入；因此第二次安裝仍回報 `Result: current`。反之，其餘 inventory 一致但該檔缺失的 target 分類為 `update` 並建立該檔——建立優先於 `current` 的零寫入契約。
5. `--dry-run` 維持零寫入，並在 target 缺檔時把它算進「會變更」（`--target` 模式輸出 `Result: update`，batch 模式輸出 `would-update`），但不建立該檔。
6. `--self` 的 source-only 模式維持嚴格契約：source repository 缺少 `openspec/config.yaml` 仍是 execution error，不會被 bootstrap。

`--target` 與 `--all` batch 兩種安裝 mode 會建立該檔。`--register` 只登錄專案、不執行安裝，因此它同樣接受缺檔的 target（否則全新專案無法登錄），但不建立該檔；實際建立發生在後續 batch 安裝。

## Non-Goals

- 不建立 openspec 之下的 spec 目錄與 change 目錄；Cash CLI 既有的 on-demand 目錄建立已涵蓋，`list_directory` 對缺目錄回傳空集合。
- 不改變 target 必須是 Git worktree top-level 的要求。
- 不把 `openspec/config.yaml` 納入 receipt 管理或 managed inventory；建立後即為 project-owned，後續 upgrade 不覆寫、不修復內容。
- 不改變 `.cash.yaml` 與 `.spectra.yaml` 的既有三分支邏輯。
- 不新增 CLI flag 或 installer 選項。

## Alternatives Considered

- **維持 fail closed，只改善診斷訊息**：使用者仍要手動建立檔案才能安裝，沒有解決「全新 repo 無法直接安裝」的核心問題。
- **以 `--init` flag 顯式啟用 bootstrap**：安全性沒有實質提升——建立缺失檔案不具破壞性——卻讓最常見的首次安裝多一個必須記住的步驟。
- **從 source repository 複製 `openspec/config.yaml`**：會把 source 專案自身的 context 與 rules 洩漏到 target，且讓輸出取決於 source 的可變狀態；內建常數更可預測。
- **同時建立整棵 `openspec/` 骨架**：超出解除阻塞所需，且與 CLI 既有的 on-demand 目錄建立重複。

## Capabilities

### New Capabilities

（無）

### Modified Capabilities

- `cash-cli`：installer preflight 的 target 前置條件，以及 config deployment 的涵蓋範圍。

## Impact

- Affected specs:
  - openspec/specs/cash-cli/spec.md
- Affected code:
  - New:
    - （無）
  - Modified:
    - .cash-skills/lib/cash_cli/installer.py
    - cash-skills.version
    - scripts/cash-skills/tests/test_installer_runtime.py
    - CASH-SKILLS.md
  - Removed:
    - （無）
