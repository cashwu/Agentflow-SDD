# 07 — Dev：auto-restore-commit-guard-source

## 實作摘要（TDD）

| 任務 | 狀態 | 內容 |
|------|------|------|
| T1 | ✅ | 新增 `scripts/spectra-plus/tests/auto-restore-checks.fish`（git fixture，5 案例）。實作前執行確認 **red**。 |
| T2 | ✅ | `install-spectra-plus.fish` 新增 `restore_source_guard_if_needed`。 |
| T3 | ✅ | 於 `ensure_commit_guard` 的 source 驗證前接線。 |
| T4 | ✅ | 四組測試全綠 + 語法檢查 + 真實環境 e2e 自癒驗證。 |
| T5 | ✅ | `SPECTRA-PLUS.md` 疑難排解新增自癒說明；master spec 同步 **defer 到 /sdd-wrap**。 |
| T6 | ✅ | 本文件 + `status.yaml` 更新。 |
| T7 | ✅ | 最終比對審查 + 安全 audit（fresh sub-agent）：9.5/10，安全稽核全清，pass。套用 optional 加固（git restore 退出碼檢查）。 |

## 關鍵實作決策

- **dry-run 跳過硬驗證**：發現 `ensure_commit_guard` 在 dry-run 仍會於 source 驗證點 fail-loud。故 `restore_source_guard_if_needed` 在「dry-run 且 HEAD 有效、會還原」時 **return 2**，呼叫端據此跳過 `validate_commit_guard "$source"`；其餘情況 return 0（已驗證/已還原→驗證會過；無法還原→驗證 fail-loud）。
- **重用 `guard_is_current` 作布林述詞**：其斷言與 `validate_commit_guard` 完全相同但不 exit，可同時用於 working-tree source 與 HEAD blob 的有效性判斷。
- **單檔 working-tree 還原**：`git -C <toplevel> restore --source=HEAD -- <relpath>`，不動 index（符合 spec MUST NOT modify index）；relpath 以 realpath 後相對 toplevel 推導，`show` 與 restore 共用。
- **前置四連檢**：guard 已失效 → in-git（`rev-parse --show-toplevel`）→ HEAD blob 取得且 `guard_is_current` → 非 dry-run。任一不成立即不 mutate。

## 驗證證據

- `fish -n install-spectra-plus.fish scripts/spectra-plus/repair-all.fish scripts/spectra-plus/tests/auto-restore-checks.fish` → OK。
- `auto-restore-checks.fish` → PASS（自癒、HEAD 也壞、非 git、dry-run 零變更、單檔限制）。
- 回歸：`installer-commit-guard-checks.fish`、`repair-all-checks.fish`、`generator-checks.fish` → 全 PASS。
- 真實 e2e：剝除本 repo 真實 `.claude/.../spectra-commit/SKILL.md` guard → `--repair-all --force` → 輸出 `restored .claude/skills/spectra-commit/SKILL.md from HEAD` → `[success]` → marker 復原、git status 乾淨。

## 審查

見 `reviews/07-dev-task-*-r*.md`。
