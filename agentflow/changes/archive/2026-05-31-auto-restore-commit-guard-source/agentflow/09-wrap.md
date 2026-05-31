# 09 — Wrap：auto-restore-commit-guard-source

## 交付摘要

讓 `install-spectra-plus.fish` 在來源 `spectra-commit/SKILL.md`（Claude + Codex）的 `SPECTRA-COMMIT-GUARD` 被剝除時，自動從 git HEAD 還原來源檔再續行 repair，使 spectra-plus 自動修復能自癒——解決「source == target 同時被剝、auto-repair 無法復原」的結構性脆弱點。

## 變更檔

- `install-spectra-plus.fish`：新增 `restore_source_guard_if_needed`，於 `ensure_commit_guard` source 驗證前接線（dry-run would-restore 以 return 2 跳過硬驗證）。
- `scripts/spectra-plus/tests/auto-restore-checks.fish`：新增 git fixture 測試（5 案例）。
- `SPECTRA-PLUS.md`：疑難排解新增自癒說明。
- `openspec/specs/spectra-plus-skills/spec.md`：併入新 requirement「Auto-restore stripped commit guard source from git HEAD」+ 5 scenario（@trace 指向 `auto-restore-checks.fish`）。

## 品質軌跡（每步皆 fresh sub-agent 審查）

| 步驟 | 結果 |
|------|------|
| 1 Discuss | skipped（需求已釐清） |
| 2 Explore | pass 10/10（r1 9 → r2 10） |
| 3 Prototype | skipped；pass 9.5/10（r1 9 → r2 9.5） |
| 4 Spec | pass 9.4/10（r1） |
| 5 Usage | pass 10/10（r1 8 → r2 10） |
| 6 Ticket | pass 9.5/10（r1） |
| 7 Dev | pass 9.5/10（T7 r1，安全 audit 全清） |
| 8 Review | pass 9.3/10（r1） |
| 9 Wrap | 本文件 |

## 驗證證據

- 四組測試全綠：`auto-restore-checks`、`installer-commit-guard-checks`、`repair-all-checks`、`generator-checks`。
- 語法：`fish -n` installer + repair-all + 測試皆 OK。
- 真實 e2e：剝除本 repo 真實 source guard → `--repair-all --force` → `restored … from HEAD` → `[success]` → marker 復原、git status 乾淨。

## 殘留風險

1. **HEAD 也壞無法自癒（設計內）**：若 git HEAD 版本本身缺合法 guard，仍 fail-loud，需人工把含 guard 版本 commit 到 HEAD。屬刻意邊界，已於 spec scenario「HEAD source is also invalid」與 SPECTRA-PLUS.md 記錄。
2. **依賴 `git restore --source=HEAD`（git ≥ 2.23）**：低風險，macOS Homebrew git 滿足。極舊 git 環境會走 fail-loud 回退（restore 失敗則不印 success log，由 `validate_commit_guard` fail-loud）。
3. **registry 內其他專案**：本變更只還原 source；對非自指 target，來源仍是本 repo 的（完好）檔案，行為不變。確認 repair-all 對其他 3 個註冊專案維持 `already current`。
4. **凍結稽核紀錄殘留舊名**：`reviews/07-dev-task-T7-r1.md` 含實作期暫用函式名 `maybe_restore_source_guard`（已更名為 `restore_source_guard_if_needed`）。屬不可變稽核快照，刻意不改。

## 後續

- 歸檔本 change 至 `agentflow/changes/archive/2026-05-31-auto-restore-commit-guard-source/`。
- 提交：建議以 `/sdd-commit` 或手動將本變更相關檔一起 commit（installer + 測試 + SPECTRA-PLUS.md + master spec + change artifacts）。
