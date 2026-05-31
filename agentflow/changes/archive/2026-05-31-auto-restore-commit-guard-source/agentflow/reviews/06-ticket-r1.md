# 06 — Ticket Review r1：auto-restore-commit-guard-source

- **角色**：獨立審查 sub-agent（Agentflow step 6 / Ticket）
- **日期**：2026-05-31
- **決策**：pass

## 審查目標（target）

驗證 `tasks.md` 與 `agentflow/06-ticket.md` 是否符合 `config.yaml` `rules.tasks` 規則，並與上游 spec / design / 既有測試風格一致。

## 審查輸入（inputs reviewed）

- `tasks.md`（T1–T7）
- `agentflow/06-ticket.md`（任務概覽、handoff）
- `spec.md`（5 個 scenario）
- `design.md`（Implementation Contract、測試策略、:99 呼叫點）
- `config.yaml`（`rules.tasks`、preferences：tdd=true / parallel_tasks=false / audit=true）
- 既有測試 `scripts/spectra-plus/tests/installer-commit-guard-checks.fish`（風格與沙箱慣例）
- 實際程式碼 `install-spectra-plus.fish`：`validate_commit_guard`(L75)、`ensure_commit_guard`(L88)、source 驗證語句(L99)、Claude/Codex 兩呼叫點(L614/615)
- `SPECTRA-PLUS.md`（測試隔離警告 L217、lock/cache 路徑）

## Rubric Checklist（逐項查證）

| Rubric 規則 | 結果 | 佐證 |
|------|------|------|
| 每個任務具可觀測結果 + 具體驗證目標 | PASS | T1 紅燈/具體斷言、T2/T3 `fish -n`、T4 三組測試、T7 review round >9。所有任務均有「驗證目標」行。 |
| 任務夠小、單一 focused pass | PASS | T1 撰測、T2 單函式、T3 接線、T4 跑測、T5 文件、T6 軌跡、T7 審查，切分合理。 |
| 無模糊「handle edge cases」 | PASS | 邊界以具名 scenario 描述（dry-run/非 git/HEAD 壞/單檔），無空泛措辭。 |
| `[P]` 僅標真正獨立任務（此處 parallel_tasks=false 應為無） | PASS | 全任務循序、無 `[P]`；標頭明示「無 `[P]`」。 |
| 含更新 Agentflow step 文件任務 | PASS | T6 涵蓋 step 文件與 `status.yaml`。 |
| 含更新 review round 文件任務 | PASS | T6 含 `agentflow/reviews/` 更新；標頭與 06-ticket.md 均載 round 檔命名 `07-dev-task-<id>-r<round>.md`。 |
| 最終比對審查任務（vs spec/design/tests/verification） | PASS | T7 明確比對 spec scenario、design 契約、測試與驗證目標。 |
| TDD 排序（tdd=true：失敗測試先於實作） | PASS | T1 失敗測試 → T2/T3 實作 → T4 綠燈，順序正確。 |
| audit=true 偏好落實 | PASS | T7 含安全稽核（誤蓋/dry-run/單檔/HEAD 邊界）。 |

## 指定查核點

1. **5 測試案例 ↔ 5 spec scenario 1:1**：PASS。case1↔Self-heal、case2↔HEAD invalid、case3↔not in git work tree、case4↔Dry-run、case5↔single file。完全對齊，無遺漏或多餘。
2. **TDD 排序正確**：PASS。T1 明示「尚未實作前執行應失敗（紅燈）」，先於 T2/T3 實作，T4 再使其全綠。
3. **每任務驗證目標具體可執行**：PASS。`fish scripts/.../installer-commit-guard-checks.fish`、`fish -n install-spectra-plus.fish`、`repair-all-checks.fish`、`generator-checks.fish` 均經查證為真實存在的可執行目標。
4. **依賴正確且無環**：PASS。T1→T2→T3→T4→{T5,T6}→T7，DAG 無環；T7 依賴 T5+T6 合理。
5. **T7 滿足最終審查規則與 audit=true**：PASS。fresh sub-agent、比對全上游、含安全稽核、round 檔 >9 門檻。
6. **遺漏項**：未發現缺漏。回歸測試（T4）、語法檢查（T2/T3/T4 `fish -n`）、文件/spec 同步（T5）、status 更新（T6）皆已涵蓋。

## 一致性交叉驗證（與實際程式碼）

- design 的 `:99` 呼叫點錨點 `validate_commit_guard "$source_path"` 經查證確為 L99；T3「在該語句之前呼叫」正確且未行號耦合（以語句為錨）。
- Claude(L614)/Codex(L615) 經由各自 `ensure_commit_guard` 呼叫一次，T2/T3「兩份來源各涵蓋一次」描述屬實。
- dry-run `+ would restore` 前綴與既有 `+`-prefix 慣例（L104/L119）一致。
- T1 case2 斷言 `缺少必要內容` 對應 installer L65 實際錯誤字串。
- T1/T4 測試隔離警告對應 SPECTRA-PLUS.md L217（generator 改寫 rules.yaml，勿與 repair-all 並行），準確。
- T1 case4 dry-run 零變更涵蓋 lock/cache/throttle，對應實際路徑 `$TMPDIR/spectra-plus-repair.lock`、`$HOME/.cache/spectra-plus/last-repair-attempt`。

## Findings（含 severity）

- **[low]** T5 master spec 同步允許 defer 到 `/sdd-wrap`；任務已要求「若 defer 則標註 deferred-to-wrap」，責任邊界清楚。為觀察，非缺陷。
- **[info]** T1 允許新建 `auto-restore-checks.fish` 或併入既有檔；兩者皆沿用既有沙箱慣例，彈性合理。
- **[info]** T6 的「若偏離 design 才更新 step 文件」為條件式；`status.yaml` 更新為無條件，符合規則。

## Fixes Required

無（none）。

## Blockers / Critical Gaps

無（none）。

## Quality Score

**9.5 / 10**

## Decision

**pass**（quality_score > 9 且無 critical gap）

## Next Action

進入 step 7（`/sdd-dev`），自 T1 開始；每個實作任務（T1–T4、T7）跑自身 review/rating/fix loop，round 檔置於 `agentflow/reviews/07-dev-task-<id>-r<round>.md`。
