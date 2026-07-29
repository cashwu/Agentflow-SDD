# Cash Propose Review — Round 3

## Reviewer Findings

### Cumulative blocking set verdicts（Reviewer V）

- member 3（r2 finding 1，proposal.md init 段未同步）：verdict **resolved**。證據：proposal.md「Proposed Solution」init 子命令段已改寫為固定順序「旗標解析 → source repo 定位與驗證 → 需要時的 git 初始化 → 印出 target → `exec` install-cash-skills.fish」，並含「`--dry-run` 為純預覽、一律不觸發 git 初始化，於非 worktree 目錄 fail closed」，經逐項比對與 design Decisions 4／C4／C5、spec Req「cash init 的 target 解析與 git 初始化」、tasks 4.1 語意一致。自 cumulative blocking set 移除（verified resolution，fix 參照 r2 Fix Actions member 3，驗證者 Reviewer V）。

r2 finding 2 的「必要父目錄」措辭經 fix propagation 檢查三處一致（spec 第 119 行、design Decisions 7、tasks 1.2），無新矛盾；tasks 1.2 缺 illustrative 範例屬風格差異，不構成 finding。

### Suggestion（non-blocking）

1. severity: Suggestion｜confidence: 60｜layer: text｜disposition: fix-introduced｜introduced_by: r2 Fix Actions member 3｜location: proposal.md「Proposed Solution」第 1 點 init 子命令段｜summary: 改寫後的「否則在前述驗證全部通過後……執行一次 git 初始化」把「非 worktree ＋ 驗證通過」寫成充分條件，字面上把 git 目錄內部／bare repo 情況（design C4／spec 明定 fail closed）也涵蓋進「執行初始化」分支｜recommendation: 補上 git 目錄內部 fail closed 的限定

## Rating

- post-filter cumulative blocking set：Critical 0、Warning 0（member 3 verified resolution 移除後為空）
- non-blocking triaged findings：1
- critical_gap: false
- round_type: micro
- rationale: cumulative blocking set 為空，唯一新 finding 為 conf 60 的 non-blocking Suggestion（normative 條款在 spec／design 均正確，proposal 屬 summary 層字面缺口），pass 條件成立。

## Fix Actions

- 非必要修復（finding 1，Suggestion）已於本輪套用：proposal.md init 段補「位於 git 目錄內部（含 bare repo）而不屬於任何 worktree 時 fail closed 不初始化；其餘情況……」，限定語逐字對齊 spec 與 design C4 的既有條款，不新增任何行為。修改檔案：openspec/changes/add-global-cash-shim/proposal.md（1 個檔案，在 change 目錄內，無 touched 記錄需求）。`"$cash_cli" validate add-global-cash-shim` 重跑通過。post-fix mechanical self-check 重跑：annotation 配對 OK、順序與條件敘述四份 artifacts 一致、無數值宣稱漂移。
- blocking 修復：None; pass condition met.

## Decision

passed
