# Cash Propose Review — Round 1

## Reviewer Findings

### Warning（blocking，post-filter）

1. severity: Warning｜confidence: 100｜layer: design｜location: design.md Decisions 4／C4－C5 ＋ specs/cash-global-shim/spec.md「cash init 的 target 解析與 git 初始化」＋ tasks.md 4.1｜summary: `cash init --dry-run` 在非 worktree 目錄仍會先執行真實 git 初始化寫入 `.git/`，與 tasks 4.1 驗收「零寫入」直接矛盾，且 spec 無 `--dry-run` 情境的任何 scenario｜recommendation: 明定 `--dry-run` 為純預覽、一律不觸發 git 初始化，非 worktree 目錄 fail closed；三份 artifacts 同步｜來源: Reviewer A（F3，conf 75）與 Reviewer B（F1，conf 100）獨立提出，合併取 conf 100；兩位 reviewer layer 均為 design
2. severity: Warning｜confidence: 100｜layer: design（由 Reviewer B 原標 text 重分類——修正會改動 normative 條款）｜location: specs/cash-global-shim/spec.md「shim 安裝入口的冪等安裝」｜summary: 「MUST NOT 寫入 `$HOME/.local/bin/cash` 以外的任何路徑」與同 requirement 要求的 temp file 寫入及 `$HOME/.local/bin` 目錄建立字面互斥，逐字實作不可能同時滿足｜recommendation: 改為寫入範圍限定 `$HOME/.local/bin/` 目錄之內（含建立該目錄），temp file 限同目錄且結束前清除｜來源: Reviewer B（F4）

### Suggestion（non-blocking，confidence ∈ [50, 80) 依 filter 降級）

3. confidence: 75｜layer: design｜location: design.md Context ＋ Risks｜summary: `validate_target_prerequisites` 描述不完整——實際範圍 751-777 行，另含 `openspec/config.yaml` 驗證與 `allow_missing_config=True` 放行條件，design 引用 751-766 恰好截掉 config 段｜來源: Reviewer A（F1）
4. confidence: 75｜layer: design｜location: tasks.md 2.1 ↔ design.md Risks｜summary: 「等價前置檢查」若為測試側重新實作，installer 未來收緊時測試不會變紅，design 宣稱的防護目的落空｜來源: Reviewer A（F2）與 Reviewer B（F6）合併
5. confidence: 75｜layer: design｜location: design.md Decisions 4、5 ＋ spec「cash init 的 target 解析與 git 初始化」｜summary: init 操作順序未固定，旗標或 source 驗證失敗可能發生在 git 初始化之後，留下殘留 `.git/`｜來源: Reviewer B（F2）
6. confidence: 75｜layer: design｜location: spec「cash init 的 target 解析與 git 初始化」＋ design C4｜summary: 「不屬於 worktree → 就地 git init」漏掉 git 目錄內部／bare repo 情況，會建立巢狀 `.git` 污染｜來源: Reviewer B（F3）
7. confidence: 75｜layer: design｜location: design C10 ＋ tasks.md 2.1｜summary: install-cash-shim.fish 測試未要求隔離 `HOME`，照字面實作會覆寫開發者機器上真實 shim｜來源: Reviewer B（F5）
8. confidence: 50｜layer: design｜location: spec「shim 與 bundle inventory 的邊界」deletion-test scenario｜summary: deletion test 無任何 backing 測試案例（spec-requirement-no-backing-task）｜來源: Reviewer A（F4）
9. confidence: 50｜layer: design｜location: spec「dispatch 分支的 fail-closed 行為」｜summary: submodule 情境未表態（init 會把 bundle vendor 進 submodule 是否 intended）｜來源: Reviewer B（F7）
10. confidence: 50｜layer: design｜location: design Decisions 7 ＋ spec「shim 安裝入口的冪等安裝」｜summary: PATH 上更前面的同名 `cash` 遮蔽無偵測，安裝回報成功但使用者執行到別的程式｜來源: Reviewer B（F8）

### Run-first-round claim verification（Reviewer A）

design.md 五項 code-facing claims：四項成立（launcher 582-583 行、command families 無 `init`、installer 拒絕 source 為 target、installer 旗標介面）；一項不完全成立（`validate_target_prerequisites` 描述，即上方 finding 3）。

## Rating

- post-filter cumulative blocking set：Critical 0、Warning 2
- non-blocking triaged findings：8
- critical_gap: false
- round_type: full
- rationale: 首輪（unseeded）全部 surviving Critical/Warning 皆 blocking。兩筆 conf 100 的 Warning 屬 artifacts 內部矛盾（dry-run 與 git init、安裝入口寫入邊界自相矛盾），必須修復後由下一輪驗證，故 next_round。

## Fix Actions

全部 10 筆 findings 於本輪修復完畢：

- finding 1（blocking）：design.md Decisions 4 改為固定操作順序並明定 `--dry-run` 純預覽；C4／C5 增列 `--dry-run` 不觸發 git 初始化與非 worktree fail closed；spec Req「cash init 的 target 解析與 git 初始化」改寫 normative 條款並新增 scenario「dry-run 於非 worktree 目錄不建立 repo」；tasks 4.1 驗收改為 fixture 先 git init 再跑 `cash init --dry-run`，「零寫入」限定為除 `.git/` 外。
- finding 2（blocking）：spec Req「shim 安裝入口的冪等安裝」寫入邊界改為「限定 `$HOME/.local/bin/` 之內（含建立該目錄）」，temp file 限同目錄、結束前清除；design Decisions 7 與 tasks 1.2 同步。
- finding 3：design Context 與 Risks 改寫為 751-777 行、含 `openspec/config.yaml` 驗證與 `allow_missing_config=True` 放行條件。
- finding 4：tasks 2.1 與 design C10、Risks 改為直接呼叫真實 `cash_cli.installer.validate_target_prerequisites`（`PYTHONPATH=.cash-skills/lib`、`allow_missing_config=True`）。
- finding 5：design Decisions 4 與 spec 固定操作順序（旗標解析 → source 驗證 → git 初始化 → 印 target → installer）；spec「未知旗標」「source 驗證失敗」兩個 scenario 補 AND 不執行任何 git 初始化。
- finding 6：design Decisions 4／C4 與 spec 新增 `git rev-parse --is-inside-git-dir` 防護與 scenario「git 目錄內部或 bare repo 內執行 init」。
- finding 7：design C10 與 tasks 2.1 明定 install-cash-shim.fish 測試以覆寫 `HOME` 指向暫存 fixture 執行並斷言真實 shim 未被觸及。
- finding 8：design C10 與 tasks 2.1 新增 deletion test 案例；tasks 4.1 加端到端 deletion 驗證。
- finding 9：design Risks 新增「Submodule 視為獨立專案」條目；tasks 3.1 文件範圍加入 submodule 行為記載（涵蓋點由五點改六點）。
- finding 10：design Decisions 7、spec Req「shim 安裝入口的冪等安裝」、tasks 1.2 新增 `command -v cash` 遮蔽 informational 警告。

處置記錄：finding 2 由 Reviewer B 原標 `layer: text` 重分類為 `design`（修正改動 normative 條款）；首輪 unseeded，無 disposition 欄位義務。修改檔案：openspec/changes/add-global-cash-shim/design.md、openspec/changes/add-global-cash-shim/specs/cash-global-shim/spec.md、openspec/changes/add-global-cash-shim/tasks.md（3 個檔案，均在 change 目錄內，無 touched 記錄需求）。`"$cash_cli" validate add-global-cash-shim` 重跑通過。post-fix mechanical self-check 重跑：annotation 配對 OK、新識別字（`--is-inside-git-dir`、`allow_missing_config`、`command -v cash`）跨 artifact 一致、無數值宣稱漂移，無新增失敗。

## Decision

next_round
