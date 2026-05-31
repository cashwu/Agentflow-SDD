# 03 — Prototype：auto-restore-commit-guard-source

## 決策：跳過（不需 throwaway spike）

### 判斷

本變更不含實驗性未知，**不需要 prototype/spike**。理由：

1. **機制確定性高**：核心是標準 git 操作——
   - `git -C <repo> rev-parse --show-toplevel`（定位 toplevel）
   - `git -C <repo> show HEAD:<relpath>`（取 HEAD blob 內容）
   - `git -C <repo> restore --source=HEAD -- <relpath>`（單檔還原 working tree）

   皆為成熟、確定性指令，行為（含 detached HEAD、worktree-only 還原語意）已知且文件化，無需實驗驗證。

2. **不確定性集中在「控制流與邊界」而非「技術可行性」**：真正要釐清的是驗證次序（source 失敗→in-git→HEAD blob 有效→非 dry-run）、單檔 pathspec 限制、dry-run 零變更、log 格式。這些屬規格與測試可完全覆蓋的決策，不是「先寫個拋棄式程式才知道行不行」的實驗問題。

3. **已有實證 baseline**：本 session 已手動以 `git restore .claude/skills/spectra-commit/SKILL.md .agents/skills/spectra-commit/SKILL.md` 成功復原並讓 `--repair-all` 轉為 `already current`，等同證明「從 HEAD 還原來源檔即可修好 repair」的端到端可行性。自動化只是把此手動步驟條件化、安全化。

### 風險與替代

- 不做 spike 的風險：低。若實作期發現 git 邊界行為意外，屬 `/sdd-dev` 階段以測試捕捉的範疇（已於 explore R10 規劃 git fixture 測試）。
- 替代方案：直接進 `/sdd-spec` 將 explore 的設計取向固化為可測規格。

## 從 explore 帶入 spec 的前置

- hook 點：`ensure_commit_guard` 內、`validate_commit_guard "$source"`（install-spectra-plus.fish:99）之前。
- 安全 invariant：僅當 working-tree source 已驗證失敗、且 HEAD blob 通過完整 guard 驗證、且非 dry-run 時才 mutate；restore 僅限單一檔案 pathspec；toplevel-relative relpath 同時用於 `show` 與 restore。
- 觀測：restore 後 log「restored <source> from HEAD」。
- 範圍邊界（自 explore R12/R14 帶入）：
  - restore 採 **working-tree 語意**即足夠（repair 讀 working-tree 檔）；修復 index 為 **non-goal**。
  - 本變更**僅還原 source**；非自指 target 的 anchor 搜尋與 patch fail-loud 行為**不變**。
- 簡化提示（R15，advisory）：實作可將「非 git / 未追蹤 / HEAD 無效」收斂為「取得 HEAD blob 成功**且**通過 `validate_commit_guard`」單一前置——注意「取得成功」≠「有效」，blob 仍須通過完整 guard 驗證。

## 結論

Prototype 階段以「明確跳過 + 記錄理由」結案。下一步：`/sdd-spec`。
