# 02 — Explore：auto-restore-commit-guard-source

## 目標

讓本 repo 的 spectra-plus 自動修復流程，在「來源 `spectra-commit/SKILL.md` 的 SPECTRA-COMMIT-GUARD 區塊被剝除」時能自我修復：若 git HEAD 版本含有合法 guard，則自動從 HEAD 還原來源檔再續行 repair，而非直接 `[failed] repair failed`。

## 既有架構與失敗路徑（已驗證）

### 守衛（guard）資料流

- `validate_commit_guard <path> <desc>`（`install-spectra-plus.fish:75-86`）：對檔案斷言 6 個 MUST-HAVE 字串（含 marker `<!-- SPECTRA-COMMIT-GUARD: ... -->`、兩個 plus skill glob、archive 路徑、兩段防誤納文字）與 2 個 MUST-LACK 字串（`openspec/archived/`、`docs/specs/`）。任一不符即 `fail`（非零退出）。
- `ensure_commit_guard <target> <source> <desc>`（`:88-209`）：
  1. `require_file source`，接著 **`validate_commit_guard "$source"`（:99）** ← **本次失敗點**。
  2. 若 target 已含 marker → 驗證 target 後返回。
  3. 否則從 **source** 用 `awk` 抽出 guard / archive / user 三個區塊，patch 進 target，再驗證。
- `install_target`（:579-618）以 `source = $script_dir/.claude|.agents/skills/spectra-commit/SKILL.md` 呼叫 `ensure_commit_guard`（:614-615）。`$script_dir` = `install-spectra-plus.fish` 所在目錄 = 本 repo。

### repair 觸發路徑

- `repair_all`（:424-477）：逐一處理 registry target。`target_is_current`（:392-397）為真→`[skipped] already current`；否則呼叫 `--target <t>` 走 `install_target`。
- `target_is_current` = `plus_outputs_are_current` AND 兩個 commit skill 的 `guard_is_current`（:348-358，檢查項與 `validate_commit_guard` 同義）。

### 根因（self-referential target）

本 repo 把自己註冊為 target，因此 **source == target == 同一個 working-tree 檔案**。Spectra.app reset 該檔→guard 同時從 source 與 target 消失→`target_is_current` 為 false（正確觸發 repair）→`install_target`→`ensure_commit_guard` 在 `validate_commit_guard "$source"`（:99）失敗→`[failed] repair failed`。本 session log 實證此路徑。正確 guard 版本存在於 **git HEAD**（已 commit），目前僅能手動 `git restore` 復原。

## 風險盤點

| # | 面向 | 風險/發現 | 等級 | 影響去向 |
|---|------|-----------|------|----------|
| R1 | 安全/正確性 | 自動 `git restore` 可能覆蓋使用者「合法的」來源編輯 | 中→**經設計降為低** | spec：**僅當 working-tree source 已 `validate_commit_guard` 失敗時才 restore**。guard 是契約型 artifact，guard 已破損的檔案本就不該保留；guard 完好的檔案永不被觸碰。需明列為 invariant。 |
| R2 | 正確性 | restore 範圍過大（誤用 `git restore .`）會清掉無關改動 | 高（若實作錯） | spec：MUST 只還原該單一檔案路徑；MUST NOT 跑無 pathspec 的 restore。 |
| R3 | 平台/依賴 | 非 git 工作樹、`git` 不存在、檔案未追蹤、無 HEAD（空 repo） | 中 | spec：偵測失敗時**不 restore**，回退到既有 fail-loud。需明確 scenario。 |
| R4 | 正確性 | HEAD 版本「存在但 guard 也被破壞」 | 中 | spec：restore 前 MUST 先驗證 HEAD blob 通過完整 guard 驗證；不通過→不 restore→fail-loud。 |
| R5 | 可觀測性 | 自動改動使用者檔案若無紀錄，難以稽核 | 中 | spec：restore 後 MUST log（含檔案路徑與「restored from HEAD」訊息），寫入既有 repair log。 |
| R6 | 正確性 | `--dry-run` 必須零變更 | 高 | spec：dry-run MUST 只印「would restore … from HEAD」，不得呼叫 git mutation；需 scenario + 測試。 |
| R7 | 邊界 | detached HEAD / 不同 branch | 低 | `git -C <repo> restore --source=HEAD --` 以 commit-ish 解析 HEAD，detached 亦可；以 `--source=HEAD` 而非 branch 名規避。 |
| R8 | 架構 | restore 對象是 source 還是 target？ | — | self-referential 時 source==target，還原 source 即同時修好 target；非自指 target 則修好 source 後照原流程 patch target。故 **hook 點 = 還原 source**，置於 `validate_commit_guard "$source"`（:99）之前。 |
| R9 | 範圍 | Codex（`.agents`）與 Claude（`.claude`）兩份來源都可能被剝 | 中 | spec：兩份來源都要套用同一還原邏輯（`ensure_commit_guard` 被各呼叫一次，hook 在函式內即自然涵蓋兩者）。 |
| R10 | 可測試性 | 需在臨時 git repo 重現「working-tree 破損 + HEAD 完好」 | 中 | ticket：於 `scripts/spectra-plus/tests/` 新增 git fixture 測試；注意與既有測試的暫時狀態隔離（見 SPECTRA-PLUS.md 警告）。 |
| R11 | 互動 | throttle/lock/cache | 低 | restore 發生在單 target install 內，不改 repair_all 的 lock/throttle 語意；dry-run 既有路徑（:428-433）本就不進 install_target，維持不變。 |

## 設計取向（供 spec 採用）

- 新增函式 `restore_source_guard_if_needed <source_path> <desc>`，在 `ensure_commit_guard` 的 `:99` 驗證**之前**呼叫：
  1. `validate_commit_guard` source 已通過 → 直接返回（不觸碰）。
  2. source 未通過：定位其所在 git repo（`git -C (dirname source) rev-parse --show-toplevel`）；不可得→返回（交回原 fail-loud）。
  3. 取 HEAD blob（`git -C <repo> show HEAD:<relpath>`）寫入 temp，對 temp 跑 `validate_commit_guard`；不通過→返回（fail-loud）。
  4. dry-run→印「would restore <source> from HEAD」並返回（不 mutate）。
  5. 否則 `git -C <repo> restore --source=HEAD -- <relpath>`（或 `checkout HEAD --`），log 還原動作。
- invariant：**永不**對 guard 完好的檔案、或在 dry-run、或在 HEAD 無效時執行 mutation；restore 僅限單一檔案 pathspec。

## Prototype 決策

**不需要 spike**。git 還原機制（`git -C <repo> show HEAD:<path>`、`restore --source=HEAD -- <path>`）為標準且確定性高，detached HEAD 行為已知（R7）。不確定性集中在「驗證次序與 dry-run/邊界處理」，屬 spec 與測試可覆蓋範圍，非實驗性問題。step 3 將正式記錄跳過理由。

## 補充發現（r1 審查吸收）

| # | 面向 | 發現 | 影響去向 |
|---|------|------|----------|
| R12 | 正確性 | `git restore --source=HEAD -- <path>` 只還原 **working tree**，不動 index。若破損版本已被 `git add` staged，restore 後 working tree 修好但 index 仍是破損版（後續 commit 仍會帶錯）。 | spec：明定本變更目標為「修好 working-tree 來源檔以續行 repair」；restore 採 working-tree 語意即足夠（repair 讀的是 working-tree 檔）。若需同時修 index 屬額外範圍，spec 標為 non-goal 或明確處理。 |
| R13 | 平台/邊界 | `git show HEAD:<relpath>` 與 restore pathspec 的 `<relpath>` 必須相對於 **git toplevel** 一致推導；git worktree、symlinked source dir 時 toplevel 與 `$script_dir` 可能不同。 | spec：MUST 以 `git -C (dirname source) rev-parse --show-toplevel` 取得 toplevel，並以 source 相對 toplevel 的路徑同時用於 `show` 與 restore，兩者共用同一 base。 |
| R14 | 範圍邊界 | 本變更只還原 **source**；不改變 target 端（非自指 target）的 anchor 搜尋與 patch 之 fail-loud 行為。 | spec：明列「僅還原 source；target patch 失敗行為不變」為範圍邊界。 |
| R15 | 簡化（advisory） | R3（非 git/未追蹤）與 R4（HEAD 無效）可合併為「`git show HEAD:<relpath>` 取不到內容 → fail-loud」單一判斷，減少分支。 | spec/dev：實作時優先以「取 HEAD blob 是否成功且有效」單點判斷涵蓋多數失敗。 |

## 待 spec 固化的決策

1. hook 點與函式簽章（R8）。
2. 觸發前置條件四連檢（source 失敗 → in-git → HEAD 有效 → 非 dry-run）（R1/R3/R4/R6）。
3. 還原指令與單檔 pathspec 限制（R2）、working-tree vs index 語意（R12）、toplevel-relative relpath（R13）。
4. log 訊息格式（R5）。
5. 測試 fixture 與隔離（R10）。
6. 範圍邊界：僅還原 source，不改 target patch fail-loud（R14）；失敗判斷可合併簡化（R15）。
