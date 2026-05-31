# 04 — Spec：auto-restore-commit-guard-source

## 產出

- `proposal.md`：背景、Goals/Non-goals/Assumptions、5 個驗收範例、範圍邊界。
- `design.md`：Explore/Prototype findings、Working Backwards usage contract、Implementation Contract（`restore_source_guard_if_needed` + relpath 推導）、測試策略。
- `spec.md`（change delta）：新增 requirement「Auto-restore stripped commit guard source from git HEAD」+ 5 個 scenario。
- `status.yaml`：preferences（tdd=true / parallel_tasks=false / audit=true）與步驟狀態。

## 偏好（互動確認）

| 偏好 | 值 |
|------|----|
| tdd | true |
| parallel_tasks | false |
| audit | true |

## 規格重點

- 單一新 requirement，規範自動還原的**前置四連檢**（source 已壞 → in-git → HEAD 有效 → 非 dry-run）、單檔 pathspec、不動 index、dry-run 零變更、log、以及失敗回退 fail-loud。
- 涵蓋 Claude 與 Codex 兩份來源。
- 對應 5 個 scenario：自癒成功、HEAD 也壞、非 git、dry-run、單檔限制——與 proposal 驗收範例一一對應。

## 待 usage 階段細化

- log/dry-run 訊息精確字串與 stderr/stdout 去向。
- 與既有 `--target` / `--repair-all` 輸出的整合呈現。

## 審查

見 `reviews/04-spec-r*.md`。
