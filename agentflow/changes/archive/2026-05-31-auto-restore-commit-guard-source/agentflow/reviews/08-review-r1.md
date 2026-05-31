# 08 — Review r1：auto-restore-commit-guard-source

## Target

Agentflow SDD step 8（Review）post-development gate，對 change `auto-restore-commit-guard-source` 做整體性、對抗性驗證：artifact 一致性、實作 vs spec/design 漂移、文件同步、測試實證。

## Inputs reviewed

- `proposal.md`、`design.md`、`spec.md`、`tasks.md`、`status.yaml`
- `agentflow/02-explore.md`、`03-prototype.md`、`04-spec.md`、`05-usage.md`、`06-ticket.md`、`07-dev.md`
- `agentflow/reviews/`：02-explore-r1/r2、03-prototype-r1/r2、04-spec-r1、05-usage-r1/r2、06-ticket-r1、07-dev-task-T7-r1
- 實作：`install-spectra-plus.fish`（`restore_source_guard_if_needed` L365–405、呼叫點 `ensure_commit_guard` L100–104、L661–662 兩來源接線、`guard_is_current` L353）
- 測試：`scripts/spectra-plus/tests/auto-restore-checks.fish`
- 文件：`SPECTRA-PLUS.md`（疑難排解）、master spec `openspec/specs/spectra-plus-skills/spec.md`

## Consistency + drift checklist

### A. Artifact 一致性

| 檢查 | 結果 |
|------|------|
| 5 個核心檔（proposal/design/spec/tasks/status）存在 | PASS |
| 6 個 step 檔（02–07）存在 | PASS |
| 9 個指定 review round 檔全部存在 | PASS（02-explore-r1/r2、03-prototype-r1/r2、04-spec-r1、05-usage-r1/r2、06-ticket-r1、07-dev-task-T7-r1） |
| status.yaml 各步 passed 皆有 backing review 檔 | PASS（explore r1/r2、prototype r1/r2、spec r1、usage r1/r2、ticket r1、dev T7 r1 均存在；discuss/prototype 標 skipped 合理且有 prototype 決策檔） |
| 缺漏 review round | 無 |

### B. 實作 vs spec/design 漂移

| 檢查 | 結果 |
|------|------|
| 函式名 `restore_source_guard_if_needed` 與 proposal/design/tasks 一致 | PASS（L365 定義、L100 呼叫；proposal L36/L45、design L64/L66、tasks T2/T3 全用此名） |
| 程式碼/spec 中無 stale `maybe_restore_source_guard` | PASS（live code/spec/proposal/design/tasks 皆無；唯一出現在 `reviews/07-dev-task-T7-r1.md` L11/L13，屬已凍結的歷史審查紀錄，非 live artifact，不需改） |
| 前置四連檢符合 design Implementation Contract | PASS（guard 失效 L372 → in-git `rev-parse --show-toplevel` L375 → HEAD blob 取得且 `guard_is_current` L384/388 → dry-run 判斷 L394） |
| 單檔 working-tree 還原、不碰 index | PASS（`git restore --source=HEAD -- <relpath>` L399；無 unscoped restore、無 index 操作） |
| relpath 以 realpath 後相對 toplevel 推導，show/restore 共用 | PASS（L378–381） |
| dry-run 僅印 `+ would restore … from HEAD` 不 mutate | PASS（L394–397 return 2；呼叫端 L102 據 rc=2 跳過硬驗證——design 未明列此 rc 機制，屬實作期合理加固，已於 07-dev.md「關鍵實作決策」記錄，非漂移） |
| 兩來源（Claude + Codex）皆涵蓋 | PASS（L661/L662 各呼叫 `ensure_commit_guard` 一次） |
| 5 spec scenario 皆有對應測試 | PASS（見下表） |

#### Spec scenario ↔ 測試對應

| Spec scenario | 測試案例 | 結果 |
|---------------|----------|------|
| Self-heal stripped source from valid HEAD | Case A / A2（L94–99 斷言 `restored … from HEAD` ×2、退出 0、marker 復原） | PASS |
| HEAD source is also invalid | Case B（L106–113 HEAD 也壞 → exit 1、`缺少必要內容`、無 restore） | PASS |
| Source is not in a git work tree | Case C（L118–125 非 git → exit 1、無 `from HEAD`） | PASS |
| Dry-run reports restore without mutating | Case A / A1（L88–92 印 would restore、diff 確認來源未改） | PASS |
| Restore is limited to the single source file | Case A / A3（L79–83 旁置 dirty `unrelated.txt`，L100–101 還原後仍為 DIRTY） | PASS |

### C. 文件同步

| 檢查 | 結果 |
|------|------|
| SPECTRA-PLUS.md 含 T5 self-heal 疑難排解說明 | PASS（L262–278：自癒輸出、三前置條件、單檔/dry-run 邊界、HEAD 也壞時的手動修復指引） |
| master spec 同步「明確 defer 到 wrap」（非靜默丟棄） | PASS（07-dev.md T5、tasks.md T5、06-ticket.md L22 三處明示 defer-to-wrap；master spec 經 grep 確認尚未含新 requirement，與 deferral 一致——wrap 時需執行 spec sync） |

### D. 測試與語法實證

- `fish scripts/spectra-plus/tests/auto-restore-checks.fish` → `PASS: auto-restore commit guard source checks`，**exit 0**。
- `grep -rn maybe_restore_source_guard . --include='*.fish' --include='*.md'`（排除 .git）→ 僅命中 `07-dev-task-T7-r1.md`（凍結歷史紀錄）；live code/spec/proposal/design/tasks **零命中**。
- `fish -n install-spectra-plus.fish` → exit 0；`fish -n scripts/spectra-plus/repair-all.fish` → exit 0。

## Findings（含 severity）

- **[low] spec.md `@trace` test 路徑與實作不符**：`spec.md` L58 `tests:` 指向 `installer-commit-guard-checks.fish`，但本 change 的實際自癒測試置於新檔 `auto-restore-checks.fish`。T1 明確允許新建該檔（tasks.md L7），但 `@trace` 未隨之更新。這不影響功能或測試結果，但 trace 指向了一個不含本 requirement 測試的檔案，會誤導日後 drift/wrap 追溯。建議將 `@trace` tests 改為（或增列）`scripts/spectra-plus/tests/auto-restore-checks.fish`，並在 wrap 併入 master spec 時一併修正。
- **[info] dry-run 的 rc=2 控制流為實作期新增機制**：design 只描述「dry-run 不 mutate」，未預見 `ensure_commit_guard` 在 dry-run 仍會在 source 驗證點 fail-loud 的問題。實作以 return 2 + 呼叫端跳過硬驗證解決，已於 07-dev.md 記錄並有測試 A1 覆蓋。屬合理收斂，非漂移。
- **[info] stale 名稱僅存於凍結審查檔**：`07-dev-task-T7-r1.md` 提及 `maybe_restore_source_guard` 是該審查當下程式碼的真實狀態快照；review round 檔依慣例不應回填重寫。無需修改。

## Fixes required

- 無 blocker。建議（非阻擋）：於 wrap 同步 master spec 時，順手把 spec.md `@trace` 的 `tests:` 更新為 `auto-restore-checks.fish`（[low]）。

## Blockers / critical gaps

- 無 critical gap。無 blocker。安全 invariant（僅在 source 已失效時觸發、HEAD blob 需通過完整 guard 驗證、單檔 pathspec、不碰 index、dry-run 零變更）皆於程式碼與測試成立。

## Decision

**pass**

quality_score：**9.3 / 10**（扣分點：spec.md `@trace` test 路徑指向錯誤檔案的 low 級一致性瑕疵；功能、漂移、安全、測試全數通過，無 critical gap）

## Next action

進入 step 9（Wrap，`/sdd-wrap`）：
1. 將本 change 新 requirement 併入 master spec `openspec/specs/spectra-plus-skills/spec.md`（履行 deferred-to-wrap）。
2. 併入時修正 `@trace` 的 `tests:` 路徑為 `scripts/spectra-plus/tests/auto-restore-checks.fish`。
3. 歸檔 change 並更新 status.yaml（review → passed、wrap → in-progress）。
