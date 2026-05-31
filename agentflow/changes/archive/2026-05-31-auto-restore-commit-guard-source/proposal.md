# Proposal：auto-restore-commit-guard-source

## 背景

`install-spectra-plus.fish` 的 spectra-plus 自動修復，在套用 `spectra-commit` guard 時會**從來源 `spectra-commit/SKILL.md` 抽出 guard 區塊再 patch 進 target**，因此來源必須先含合法 SPECTRA-COMMIT-GUARD。當本 repo 把自己註冊為修復 target 時，source 與 target 是同一個 working-tree 檔案；一旦 Spectra.app reset 該檔、剝掉 guard，source 與 target 同時失去 guard，`ensure_commit_guard` 在 `validate_commit_guard "$source"` 失敗，repair 回報 `[failed] repair failed` 且無法自我修復。正確 guard 版本存在於 git HEAD，目前僅能手動 `git restore` 復原（本 session 已實證）。

## 目標（Goals）

- 當來源 `spectra-commit/SKILL.md`（`.claude` 與 `.agents` 兩份）的 guard 被剝除、但 git HEAD 版本含合法 guard 時，repair 能**自動從 HEAD 還原來源檔再續行**，使自動修復可自癒。
- 還原行為必須**安全且可觀測**：僅在明確條件下 mutate、尊重 `--dry-run`、留下 log。

## 非目標（Non-goals）

- 不修復 git index（staged 內容）；還原採 working-tree 語意即足夠（repair 讀 working-tree 檔）。
- 不改變非自指 target 端的 anchor 搜尋與 patch fail-loud 行為。
- 不新增「從非 git 來源（如打包快取）還原」的能力；僅依賴 git HEAD。
- 不改動 `/Applications/Spectra.app`、LaunchAgent 排程語意、lock/throttle 機制。

## 假設（Assumptions）

- 來源 `spectra-commit/SKILL.md` 為 git-tracked，且 HEAD 通常保有正確 guard 版本（本 repo 慣例）。
- 使用者不會把「移除 guard」當成合法編輯保留——guard 是契約型 artifact。

## 驗收範例（Acceptance examples）

1. **自癒**：working-tree 來源 guard 被剝、HEAD 完好 → 跑 `--repair-all --force` → 自動還原來源 → repair `[success]`，且來源檔重新含 guard。
2. **HEAD 也壞**：working-tree 與 HEAD 來源皆無合法 guard → 不還原 → fail-loud（同今日）。
3. **dry-run**：上述情境 1 加 `--dry-run` → 只印「would restore … from HEAD」→ 來源檔、lock/cache 皆零變更。
4. **非 git**：來源不在 git 工作樹 → 不還原 → fail-loud。
5. **單檔限制**：還原只動該一個 `spectra-commit/SKILL.md`，working tree 其他改動不受影響。

## Explore 重點（詳見 02-explore.md）

- 失敗點：`ensure_commit_guard` 之 `validate_commit_guard "$source"`（install-spectra-plus.fish:99）。
- hook 點：該驗證之前插入 `restore_source_guard_if_needed`。
- 風險 R1（誤蓋合法編輯）經設計降為低：僅在 working-tree source 已驗證失敗時觸發；guard 完好的檔案永不被觸碰。
- 邊界：R3 非 git / R4 HEAD 無效 / R6 dry-run / R12 working-tree 語意 / R13 toplevel-relative relpath / R14 僅還原 source。

## Prototype 決策（詳見 03-prototype.md）

跳過 spike。git 機制確定性高，手動 `git restore` 已作為事實上的端到端 baseline，剩餘不確定性屬 spec+測試可覆蓋的控制流/邊界。

## 範圍邊界

- 變更檔：`install-spectra-plus.fish`（新增 `restore_source_guard_if_needed`，於 `ensure_commit_guard` 內呼叫）。
- 測試：`scripts/spectra-plus/tests/`（git fixture）。
- 規格：`openspec/specs/spectra-plus-skills/spec.md` 新增一條 requirement。
- thin entrypoint `scripts/spectra-plus/repair-all.fish` 預期無需修改（行為由 install 路徑承載）。

## 工作流偏好

- TDD：是 · 平行任務：否 · Audit：是
