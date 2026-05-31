# 02-explore 獨立審查（Round 1）

- **變更**：auto-restore-commit-guard-source
- **審查步驟 / artifact**：Agentflow step 2（Explore）— `agentflow/changes/auto-restore-commit-guard-source/agentflow/02-explore.md`
- **審查者立場**：獨立 reviewer，不預設作者推論正確，逐條對照實際程式碼驗證。

## 輸入檔案（已實際閱讀）

- `agentflow/changes/auto-restore-commit-guard-source/agentflow/02-explore.md`（受審 artifact）
- `install-spectra-plus.fish`（全檔，含 `validate_commit_guard` L75-86、`ensure_commit_guard` L88-210、`guard_is_current` L348-358、`plus_outputs_are_current` L360-390、`target_is_current` L392-397、`repair_all` L424-477、`install_target` L579-674）
- `scripts/spectra-plus/repair-all.fish`（全檔）
- 實機驗證：`~/.config/spectra-plus/projects.txt`、`git rev-parse --show-toplevel`、`git ls-files`、`git show HEAD:...:SKILL.md`

## 程式碼對照驗證結果

| 文件主張 | 驗證方法 | 結論 |
|---|---|---|
| `validate_commit_guard` 在 L75-86，斷言 6 個 MUST-HAVE + 2 個 MUST-LACK | 讀 L75-86 | **正確**。6 個 `assert_contains`（marker、兩個 plus glob、archive 路徑、兩段防誤納文字）+ 2 個 `assert_not_contains`（`openspec/archived/`、`docs/specs/`）。 |
| `ensure_commit_guard` 在 :88 起，:99 對 source 做 `validate_commit_guard` 即失敗點 | 讀 L88-99 | **正確**。L97-98 先 `require_file` target/source，L99 `validate_commit_guard "$source_path"`，guard 被剝時於此 `fail`（exit 1）。 |
| `install_target` 於 :614-615 以 `$script_dir/.claude\|.agents/.../SKILL.md` 為 source 呼叫 | 讀 L614-615、L585 | **正確**。source 即 `$script_dir`（installer 所在 repo）下的 commit skill。 |
| `repair_all` :424-477，`target_is_current` 真→`[skipped]`，否則 `--target` 走 `install_target` | 讀 L455-473 | **正確**。並補確認 L470 即文件所稱 `[failed] repair failed` 字串來源。 |
| `target_is_current` :392-397 = plus outputs current AND 兩個 commit guard current | 讀 L392-397 | **正確**。 |
| `guard_is_current` :348-358 檢查項與 `validate_commit_guard` 同義 | 對照 L348-358 vs L75-86 | **正確**，檢查字串完全一致（前者用 `file_has`/`file_lacks`，回 1 而非 fail）。 |
| 本 repo 自我註冊為 target（source==target==同一 working-tree 檔） | `cat projects.txt` + `rev-parse --show-toplevel` | **正確**。registry 唯一條目 = `/Users/cash/Github/Agentflow-SDD`，等於 `$script_dir` toplevel。 |
| 正確 guard 版本存在於 git HEAD | `git show HEAD:.claude/.../SKILL.md \| rg -c marker` → 1 | **正確**。HEAD blob 含合法 guard，兩來源檔均 git-tracked。 |
| dry-run 既有路徑（:428-433）不進 `install_target` | 讀 L428-433 | **正確**。`repair_all` 在 dry-run 早返回；R11「dry-run 不變」成立。 |

**全部引用行號與失敗路徑皆與實際程式碼相符，無錯誤行號或捏造主張。**

## Rubric 評估

| 面向 | 評語 | 評分 |
|---|---|---|
| 需求保真度（requirement fidelity） | 目標與 CONTEXT 一致：guard 被剝時從 HEAD 自我修復而非 fail-loud。hook 點（:99 前）與根因吻合。 | 強 |
| 風險覆蓋（尤其 auto restore 安全性） | R1（僅破損才 restore）、R2（單檔 pathspec）、R3（非 git/無 HEAD/未追蹤）、R4（HEAD 也破損）、R6（dry-run 零變更）、R7（detached HEAD）皆覆蓋且方向正確。**有缺口**：見 F1/F2。 | 中-強 |
| 證據品質 | 引用具體行號且可逐條驗證；「本 session log 實證」未附 log 連結但根因可由程式碼+registry 獨立推出。 | 強 |
| Prototype 跳過理由 | 合理。git 機制確定性高，不確定性集中在驗證次序/邊界，屬 spec+測試範圍。 | 強 |
| 可測試性 | R10 指出需 git fixture 重現「working-tree 破損 + HEAD 完好」，並提醒與既有測試暫態隔離。可採用。 | 強 |
| 範圍邊界 | R8/R9 釐清 hook 在 `ensure_commit_guard` 內、兩來源（Claude/Codex）自然涵蓋；不動 lock/throttle。清楚。 | 強 |

## 發現（含嚴重度）

- **F1 — 中嚴重度（遺漏風險）：staged/index 與 worktree 不一致的還原語意未討論。**
  文件設計步驟 5 用 `git restore --source=HEAD -- <relpath>`。`restore` 預設只還原 **working tree**，不動 index。若使用者已把「破損版」`git add` 進 index，restore 後 working-tree 修好但 index 仍持破損版，後續 `git status`/commit 行為可能令人意外。需在 spec 釐清：是否需 `--staged --worktree`，或明確只還原 worktree 並接受 index 可能分歧。此情境在「Spectra.app reset 檔案」的真實場景多半不會 staged，但屬應明列的邊界。

- **F2 — 低-中嚴重度（遺漏風險）：git worktree / submodule 與「source 不在其自身 repo」之 relpath 計算。**
  設計步驟 2 用 `git -C (dirname source) rev-parse --show-toplevel` 取得 repo，步驟 3/5 需把 source 絕對路徑轉成 toplevel 相對的 `<relpath>`。文件未明寫「如何計算 relpath」（須以 toplevel 為基準，例如 `git -C <repo> rev-parse --show-prefix` 或路徑相減）。在 linked worktree 或 source 為符號連結時，`show HEAD:<relpath>` 與 `restore` 的 pathspec 基準必須一致，否則會靜默 no-op 或 restore 到錯路徑。spec 應明列 relpath 推導方式並涵蓋 worktree 案例。

- **F3 — 低嚴重度（精確性）：R3「無 HEAD（空 repo）」與 R4「HEAD 存在但 guard 破損」可合併為單一前置條件，但表述為兩條更清楚；無誤，僅備註實作上「`git show HEAD:<relpath>` 失敗」同時涵蓋 unborn HEAD、檔案未在 HEAD、非 git 三種情形，spec 可用單一「取 blob 失敗即 fail-loud」收斂，降低分支數。**（建議性，非阻擋）

- **F4 — 低嚴重度（一致性）：`ensure_commit_guard` 內 source 與 target 用同一 `validate_commit_guard`，但本變更只擬還原 source。**
  自指 target 時 source==target，還原 source 同時修好 target（R8 正確）。但**非自指** target 時，若 target 自身 guard 破損且 marker 缺失，現行流程會走 L112 anchor 檢查並從（已修復的）source patch 回 target——此路徑仍依賴 target 的 anchor sections 存在。文件 R8 已暗示此分流，但未點明「還原只治 source、target 仍走既有 patch/anchor 失敗路徑」這項剩餘暴露面。spec 應明述本變更**不**改變 target 端的 fail-loud 行為。

以上 F1/F2 為實質遺漏；F3/F4 為精確性/邊界澄清。皆屬「spec 可吸收」層級，無一推翻探索結論或 hook 點設計。

## 必要修正（feeds into spec / step 4）

1. 在 spec 明列 **index vs worktree** 還原語意決策（F1）：建議只還原 worktree，並在 scenario 註明 staged 破損版的接受/處理方式。
2. 在 spec 明寫 **relpath 推導方式**（以 toplevel 為基準）並列出 **git worktree / symlink source** 邊界（F2）。
3. 在「待 spec 固化決策」補一條：本變更**僅**還原 source，**不**改變 target 端既有 anchor/patch 之 fail-loud 行為（F4）。
4.（建議）將 R3+R4 在 spec 收斂為「`git show HEAD:<relpath>` 失敗 → fail-loud」單一檢查，減少分支（F3）。

## 剩餘阻擋 / 關鍵缺口

無 critical gap。所有引用經程式碼驗證屬實，根因與 hook 點正確，安全 invariant（僅破損才動、單檔、dry-run 零變更、HEAD 須有效）方向正確。F1/F2 為應在 spec 補齊的邊界，非探索階段阻擋。

## 決策

**pass**（建議將 F1-F4 作為 spec 階段必納輸入，無需 rerun explore）

## 下一步行動

進入 step 4（Spec）。spec 撰寫時 MUST 吸收 F1（index/worktree 語意）、F2（relpath + worktree 邊界）、F4（target 端 fail-loud 不變）三項，並可採 F3 收斂分支。step 3（Prototype）依文件記錄「跳過」即可。
