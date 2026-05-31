# 02-explore 獨立審查（Round 2）

- **變更**：auto-restore-commit-guard-source
- **審查步驟 / artifact**：Agentflow step 2（Explore）— `agentflow/changes/auto-restore-commit-guard-source/agentflow/02-explore.md`
- **審查者立場**：獨立 round-2 reviewer。前一輪評 9/10 並提出修正（F1/F2/F4），現已吸收為 R12/R13/R14（R15 對應 F3）。本輪逐條對照實際程式碼獨立驗證，不預設前輪推論正確。

## 輸入檔案（已實際閱讀）

- `agentflow/changes/auto-restore-commit-guard-source/agentflow/02-explore.md`（受審 artifact，含「補充發現（r1 審查吸收）」R12-R15）
- `agentflow/changes/auto-restore-commit-guard-source/agentflow/reviews/02-explore-r1.md`（前輪審查）
- `install-spectra-plus.fish`：`validate_commit_guard` L75-86、`ensure_commit_guard` L88-210、`guard_is_current` L348-358、`plus_outputs_are_current` L360-390、`target_is_current` L392-397、`repair_all` L424-477、`install_target` L579-615
- `scripts/spectra-plus/repair-all.fish`（全檔）

## 程式碼對照驗證結果

| 文件主張 | 驗證方法 | 結論 |
|---|---|---|
| `validate_commit_guard` L75-86，6 MUST-HAVE + 2 MUST-LACK | 讀 L75-86 | **正確**。marker、`.agents/.../spectra-*-plus/`、`.claude/.../spectra-*-plus/`、`openspec/changes/archive/<date>-<change>/`、兩段防誤納文字；MUST-LACK = `openspec/archived/`、`docs/specs/`。 |
| 失敗點在 `ensure_commit_guard` :99 對 source 做 `validate_commit_guard` | 讀 L97-99 | **正確**。L97/98 `require_file` target/source，L99 `validate_commit_guard "$source_path"`，guard 被剝即此處 `fail`。 |
| `install_target` :614-615 以 `$script_dir/.claude\|.agents/.../SKILL.md` 為 source | 讀 L585、L614-615 | **正確**。source 為 installer 所在 repo 下的 commit skill。 |
| `repair_all` :424-477，current→skip，否則 `--target` 走 install，失敗印 `[failed] ... repair failed` | 讀 L455-473 | **正確**。L470 即該字串來源。 |
| `target_is_current` :392-397 = plus outputs current AND 兩 commit guard current | 讀 L392-397 | **正確**。 |
| R14：target 端 anchor/patch fail-loud 不變 | 讀 L112-116 | **正確**。L112-116 對 6 個 anchor 缺失即 `fail`，此路徑與本變更（只還原 source）正交，未被觸碰。 |
| R12：`git restore --source=HEAD -- <path>` 只動 working tree | git restore 語意 | **正確**。預設 `--worktree`，不含 `--staged`；doc 主張「repair 讀 working-tree 檔，worktree 語意即足夠」成立。 |
| R11：dry-run 既有路徑不進 install_target | 讀 L428-433 | **正確**，repair_all 在 dry-run 早返回。**補充**：`install_target` 仍可由 `--target --dry-run` 直接觸發，L99 hook 不分 caller 皆會執行，故 R6（新函式 dry-run 零變更）仍為必要——doc 設計步驟 4 已覆蓋。 |

**全部引用行號與失敗路徑皆與實際程式碼相符，無捏造或錯誤行號。**

## r1 修正吸收驗證

- **F1 → R12（一致性，已吸收）**：R12 明寫 restore 只動 working tree、index 可能殘留破損 staged 版，並把目標定義為「修好 working-tree 來源檔以續行 repair」，需同時修 index 則標為 non-goal/明確處理。語意正確，方向與真實場景（Spectra.app reset 多半未 staged）相符。**已解決。**
- **F2 → R13（已吸收）**：R13 要求以 `git -C (dirname source) rev-parse --show-toplevel` 取 toplevel，並令 `show HEAD:<relpath>` 與 restore pathspec 共用同一 toplevel-relative base，明列 git worktree / symlinked source dir 邊界。**已解決。**
- **F4 → R14（已吸收）**：R14 明列「僅還原 source；target patch 失敗行為不變」為範圍邊界，與 L112-116 實況一致。**已解決。**
- **F3 → R15（建議性，已吸收）**：R15 將 R3+R4 收斂為「`git show HEAD:<relpath>` 取不到/無效 → fail-loud」單點判斷，作為 spec/dev 簡化建議。合理。

「待 spec 固化決策」第 3、6 條已分別納入 R12/R13、R14/R15，與補充發現對齊一致。

## Rubric 評估

| 面向 | 評語 | 評分 |
|---|---|---|
| 需求保真度 | hook 點（L99 前還原 source）與根因吻合；目標與 CONTEXT 一致。 | 強 |
| 風險覆蓋 | R1-R11 + R12-R15 完整；auto-restore 安全 invariant（僅破損才動、單檔 pathspec、dry-run 零變更、HEAD 須有效、worktree 語意）方向皆正確。 | 強 |
| 證據品質 | 行號逐條可驗；「session log 實證」雖未附 log，但根因可由程式碼 + self-referential registry 獨立推得。 | 強 |
| Prototype 跳過理由 | 合理：git 機制確定性高，不確定性集中於驗證次序/邊界（spec+測試可覆蓋）。 | 強 |
| 可測試性 | R10 指出需 git fixture 重現「worktree 破損 + HEAD 完好」並提醒暫態隔離；可採用。 | 強 |
| 範圍邊界 | R8/R9/R14 清楚界定 hook 在 `ensure_commit_guard` 內、兩來源自然涵蓋、target 端 fail-loud 不變。 | 強 |

## 發現（含嚴重度）

- **F5 — 低嚴重度（精確性，建議性）**：R13 用 `git -C (dirname source)`；當 source 為 symlink 時，`dirname source` 指向 symlink 所在目錄而非 link 目標目錄，理論上可能解析到非預期 repo。doc 已將「symlinked source dir」列為邊界並要求 toplevel-relative 推導，方向正確；spec 階段可補一句「relpath 以實體路徑（`realpath`/`path resolve`）為準再相對 toplevel」以杜絕 symlink 歧義。非阻擋。
- **F6 — 低嚴重度（精確性，建議性）**：R15 的「`git show HEAD:<relpath>` 失敗 → fail-loud」需在 spec 與 R12 的「只還原 worktree」協調：成功取得 blob 後仍須對 blob 內容跑 `validate_commit_guard`（R4 原意），單純取得成功不等於有效。doc 設計步驟 3 已明寫「對 temp 跑 validate_commit_guard，不通過→返回」，故無實質矛盾；僅提醒 spec 收斂分支時別把「取得成功」誤等同「有效」。非阻擋。

無新增實質遺漏；F5/F6 為 spec 可吸收的精確性備註，未推翻任何探索結論或 hook 點。R12/R13/R14 未引入新 gap（已對照 L99 hook、L112-116 target 路徑、restore worktree 語意逐一確認）。

## 必要修正（feeds into spec / step 4）

1.（建議）spec 明訂 relpath 以實體路徑解析後相對 toplevel，杜絕 symlink source 歧義（F5）。
2.（建議）spec 收斂 R15 分支時保留「取得 HEAD blob 成功 ≠ 有效」的二段判斷：取得成功後仍須 `validate_commit_guard` 該 blob（F6）。

（以上皆為建議性精確化，非阻擋；前輪 F1/F2/F4 已由 R12/R13/R14 完整吸收。）

## 剩餘阻擋 / 關鍵缺口

無 critical gap。所有引用經程式碼驗證屬實；根因、hook 點、安全 invariant、範圍邊界皆正確；前輪三項實質修正已落地且未引入新缺口。

## 決策

**pass**（quality_score > 9 且無 critical gap；F5/F6 作為 spec 階段建議性輸入，無需 rerun explore）

## quality_score

**10 / 10**

## 下一步行動

進入 step 3（Prototype）：依文件記錄「跳過」理由即可。step 4（Spec）撰寫時建議納入 F5（symlink relpath 解析）與 F6（blob 取得成功 vs 有效的二段判斷），並沿用 R12/R13/R14 已固化的語意與範圍邊界。
