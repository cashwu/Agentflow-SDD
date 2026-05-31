# 06 — Ticket：auto-restore-commit-guard-source

## 產出

`tasks.md`：7 個循序任務（無 `[P]`，因 parallel_tasks=false），TDD 排序（先 T1 失敗測試，後實作）。

## 任務概覽

| ID | 任務 | 觀察結果 | 驗證目標 | 依賴 |
|----|------|----------|----------|------|
| T1 | 撰寫失敗測試（git fixture，5 案例） | 紅燈 | 新案例失敗 | — |
| T2 | 實作 `restore_source_guard_if_needed` | 函式存在 | `fish -n` 通過 | T1 |
| T3 | 接線進 `ensure_commit_guard`（:99 前） | 兩份來源涵蓋 | `fish -n` 通過 | T2 |
| T4 | 跑綠燈 + 回歸 + 語法 | 全綠 | 三組測試 + 語法 | T3 |
| T5 | 文件 + master spec 同步 | 自癒說明/新 requirement | 文件/spec 更新 | T4 |
| T6 | Agentflow 文件/review/status 更新 | 軌跡一致 | 一致 | T4 |
| T7 | 最終比對審查 + 安全 audit | 5 scenario 覆蓋 | review round >9 | T5,T6 |

## Handoff 要點

- 每個實作任務（T1–T4、T7）完成前須跑自身 review/rating/fix loop，round 檔 `07-dev-task-<id>-r<round>.md`，fresh sub-agent。
- T5 的 master spec 同步可 defer 到 `/sdd-wrap`，需在該任務明確標註選擇。
- audit=true → T7 含安全稽核。

## 審查

見 `reviews/06-ticket-r*.md`。
