# Tasks：auto-restore-commit-guard-source

偏好：TDD=true · parallel_tasks=false · audit=true
任務循序執行（無 `[P]`）；每個實作任務需通過自身 review/rating/fix loop（quality_score > 9，無 critical gap，fresh sub-agent，round 檔置於 `agentflow/reviews/07-dev-task-<id>-r<round>.md`）後才可標記完成。

## T1 — 撰寫失敗測試（git fixture）
- [x] 在 `scripts/spectra-plus/tests/installer-commit-guard-checks.fish` 新增 self-heal 測試群組（或新檔 `auto-restore-checks.fish`，沿用既有測試風格與沙箱慣例）。
- 涵蓋 5 案例，對應 spec scenario：
  1. 自癒成功：臨時 git repo，commit 含合法 guard 的 `spectra-commit/SKILL.md`（Claude+Codex），working tree 覆寫為剝除 guard 版 → 跑 install/repair → 斷言印出 `restored <relpath> from HEAD`、退出成功、檔案重新含 guard。
  2. HEAD 也壞：HEAD 版本也無合法 guard → 斷言不還原、fail-loud（含 `缺少必要內容`）、非 0。
  3. 非 git：來源不在 git 工作樹 → 斷言不還原、fail-loud、非 0。
  4. dry-run：情境 1 加 `--dry-run` → 斷言印 `+ would restore <relpath> from HEAD`、檔案/lock/cache/throttle 未變。
  5. 單檔限制：同 git repo 放一個無關 dirty 檔 → 還原後斷言該無關檔未被動到。
- 沙箱：獨立 `HOME`/`TMPDIR`；勿與會改寫 `rules.yaml` 的 generator 測試並行（見 SPECTRA-PLUS.md）。
- **觀察結果**：在尚未實作前執行，測試應**失敗**（紅燈）。
- 驗證目標：`fish scripts/spectra-plus/tests/installer-commit-guard-checks.fish` 顯示新案例失敗。

## T2 — 實作 `restore_source_guard_if_needed`
- [x] 在 `install-spectra-plus.fish` 新增函式，依 design Implementation Contract：
  - 輸入：source 絕對路徑、description。
  - 前置四連檢：working-tree source 未通過 `validate_commit_guard` → source 在 git 工作樹（`git -C (dirname source) rev-parse --show-toplevel` 成功）→ `git -C <toplevel> show HEAD:<relpath>` 取得內容寫入 temp 且通過 `validate_commit_guard` → 非 dry-run。
  - relpath 相對 toplevel 推導（必要時 realpath 解 symlink），`show` 與 restore 共用。
  - dry-run：印 `+ would restore <relpath> from HEAD`，不 mutate。
  - 執行：`git -C <toplevel> restore --source=HEAD -- <relpath>`（單檔，working tree），印 `restored <relpath> from HEAD`（stdout）。
  - 任一前置不成立：直接返回，不 mutate、不報錯。
- 依賴：T1。
- 驗證目標：`fish -n install-spectra-plus.fish` 語法通過。

## T3 — 接線進 `ensure_commit_guard`
- [x] 在 `ensure_commit_guard` 內、`validate_commit_guard "$source_path"`（套用 guard 前的 source 驗證語句）**之前**呼叫 `restore_source_guard_if_needed "$source_path" "$description source"`。
- 確認 Claude 與 Codex 兩份來源都因 `install_target` 各呼叫一次而涵蓋。
- 依賴：T2。
- 驗證目標：`fish -n install-spectra-plus.fish` 通過。

## T4 — 跑綠燈與既有回歸
- [x] 執行並使 T1 全綠：`fish scripts/spectra-plus/tests/installer-commit-guard-checks.fish`。
- [x] 回歸：`fish scripts/spectra-plus/tests/repair-all-checks.fish`、`fish scripts/spectra-plus/tests/generator-checks.fish`（不與前者並行）。
- [x] 語法：`fish -n install-spectra-plus.fish scripts/spectra-plus/repair-all.fish`。
- 依賴：T3。
- 驗證目標：三組測試與語法檢查皆通過。

## T5 — 文件與規格同步
- [x] `SPECTRA-PLUS.md`：在疑難排解新增「來源 commit skill guard 被剝 → repair 自動從 HEAD 還原；HEAD 也壞才需手動修」說明。
- [x] master spec `openspec/specs/spectra-plus-skills/spec.md`：併入本 change 的新 requirement（亦可由 `/sdd-wrap` 的 spec sync 執行；若於 wrap 同步則此子項標註 deferred-to-wrap）。
- 依賴：T4。
- 驗證目標：文件含自癒說明；spec 含新 requirement 或 wrap 已排定同步。

## T6 — Agentflow 文件 / review 紀錄更新
- [x] 若實作期決策偏離 design，更新對應 step 文件與 `agentflow/reviews/` 紀錄。
- [x] 更新 `status.yaml` 步驟狀態。
- 依賴：T4。
- 驗證目標：決策軌跡與實作一致。

## T7 — 最終比對審查（pre-wrap）
- [x] fresh sub-agent 比對實作 vs spec scenario、design 契約、測試與驗證目標；確認 5 scenario 皆有測試覆蓋、安全 invariant 成立。
- [x] 因 audit=true，加做安全稽核（自動 git mutation 的誤蓋/dry-run/單檔/HEAD 驗證邊界）。
- 依賴：T5、T6。
- 驗證目標：審查 round 檔 `agentflow/reviews/07-dev-task-T7-r<round>.md`，quality_score > 9，無 critical gap。
