# Cash Propose Review — Round 2

## Reviewer Findings

### Cumulative blocking set verdicts（Reviewer V）

- member 1（r1 finding 1，`--dry-run` 與 git 初始化矛盾）：verdict **resolved**。證據：design Decisions 4／C4／C5、spec normative 條款與新 scenario、tasks 4.1 已同步為「`--dry-run` 純預覽、非 worktree fail closed」；並經 code 查證 tasks 4.1 的 `Result: update` 與 dry-run 零寫入宣稱屬實（installer.py 2547-2548、1122-1123 行）。自 cumulative blocking set 移除（verified resolution，fix 參照 r1 Fix Actions finding 1，驗證者 Reviewer V）。
- member 2（r1 finding 2，安裝入口寫入邊界自相矛盾）：verdict **resolved**。證據：spec／design Decisions 7／tasks 1.2 三處同步為「寫入限定 `$HOME/.local/bin/` 之內、同目錄 temp file、結束前清除」。自 cumulative blocking set 移除（verified resolution，fix 參照 r1 Fix Actions finding 2，驗證者 Reviewer V）。

### Warning（blocking）

1. severity: Warning｜confidence: 90｜layer: text｜disposition: fix-introduced｜introduced_by: r1 Fix Actions finding 1 與 finding 5（兩筆均只同步 design／spec／tasks，漏掉 proposal.md）｜location: proposal.md「Proposed Solution」第 1 點 init 子命令段｜summary: proposal 仍以修復前敘述描述 init 流程——git 初始化在 source 定位／驗證之前、`--dry-run` 無純預覽限制，與 design D4 及 spec 固定順序直接矛盾｜recommendation: 改寫為固定順序並補 `--dry-run` 純預覽、非 worktree fail closed

### Suggestion（non-blocking）

2. confidence: 60（Reviewer V 原標 severity「Minor」，非法值，以最接近的 Suggestion 歸類；conf ∈ [50, 80) 依 filter 亦為 Suggestion）｜layer: text｜disposition: fix-introduced｜introduced_by: r1 Fix Actions finding 2｜location: spec「shim 安裝入口的冪等安裝」＋ design Decisions 7 ＋ tasks 1.2｜summary: 寫入邊界「含建立該目錄本身」未涵蓋 `$HOME/.local` 父目錄的必要建立，留字面縫隙｜recommendation: 三處同步為「含建立該目錄與其必要父目錄」

### Fix propagation 檢查

r1 十筆 fix actions 的其餘概念（`--is-inside-git-dir` 防護、`HOME` 隔離、deletion test、`command -v cash` 警告、`validate_target_prerequisites` 真實呼叫、submodule 記載）經 Reviewer V 逐項比對四份 artifacts，均一致無漏改。

## Rating

- post-filter cumulative blocking set：Critical 0、Warning 1（本輪新進 member 3；member 1、2 verified resolution 移除）
- non-blocking triaged findings：1
- critical_gap: false
- round_type: micro
- rationale: 兩個原 blocking member 經 Reviewer V 驗證 resolved 並移除，但 r1 修復漏同步 proposal.md，構成一筆 fix-introduced blocking Warning（conf 90 ≥ 80），cumulative set 非空，故 next_round。

## Fix Actions

- member 3（blocking，finding 1）：改寫 proposal.md「Proposed Solution」init 子命令段為固定順序（旗標解析 → source repo 定位與驗證 → 需要時的 git 初始化 → 印出 target → exec installer），明列 worktree 分支不執行 git 初始化、非 worktree 分支在驗證全部通過後才初始化，並補「`--dry-run` 為純預覽、一律不觸發 git 初始化，於非 worktree 目錄 fail closed」。
- finding 2（Suggestion）：spec Req「shim 安裝入口的冪等安裝」、design Decisions 7、tasks 1.2 三處寫入邊界同步為「含建立該目錄與其必要父目錄（如 `$HOME/.local`）」。

修改檔案：openspec/changes/add-global-cash-shim/proposal.md、openspec/changes/add-global-cash-shim/design.md、openspec/changes/add-global-cash-shim/specs/cash-global-shim/spec.md、openspec/changes/add-global-cash-shim/tasks.md（4 個檔案，均在 change 目錄內，無 touched 記錄需求）。`"$cash_cli" validate add-global-cash-shim` 重跑通過。post-fix mechanical self-check 重跑：annotation 配對 OK；「必要父目錄」措辭三處一致；proposal 的順序敘述與 design D4／spec normative 條款語意一致；無數值宣稱漂移；無新增失敗。

## Decision

next_round
