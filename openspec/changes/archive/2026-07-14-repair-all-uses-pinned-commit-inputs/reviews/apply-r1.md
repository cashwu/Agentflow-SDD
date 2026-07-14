# Apply Plus Review — Round 1

## Reviewer Findings

### Critical

1. reviewer: A+B
   severity: Critical
   confidence: 100
   layer: design
   location: `install-spectra-plus.fish:400-415,571-692,1048-1053`
   summary: `--check-current` 將 current-state assertion 的執行或讀取錯誤壓成 stale exit 10，可能錯誤委派安裝，違反三態契約。
   recommendation: 讓 current predicate 保留 stale 與 execution error 的差異，CLI 只把明確 stale 映射為 10，並新增內部 assertion error 不得委派的測試。

### Warning

1. reviewer: A+B
   severity: Warning
   confidence: 100
   layer: design
   location: `install-spectra-plus.fish:49-64,749,756,766,804`
   summary: snapshot 顯式清理失敗會回傳非零，但沒有依 design 回報清理錯誤，形成 silent failure。
   recommendation: explicit cleanup 失敗時向 stderr 回報 owned snapshot 路徑並維持非零，補 cleanup failure injection 測試。

2. reviewer: B
   severity: Warning
   confidence: 100
   layer: design
   location: `install-spectra-plus.fish:981-1031,1048-1053`
   summary: `--check-current` 未限制 absolute existing directory、單一參數或 mode exclusivity；額外 positional argument 可把唯讀 mode 改回 install。
   recommendation: 嚴格驗證唯一 absolute existing target，拒絕額外 positional 與混合 mode，並新增參數錯誤測試。

3. reviewer: A+B
   severity: Warning
   confidence: 100
   layer: design
   location: `scripts/spectra-plus/tests/repair-all-checks.fish:391-410`; `tasks.md` task 1.3
   summary: current-state error fixture 只有一個 target，未驗證 task 1.3 明定的 fail-and-continue。
   recommendation: 同次註冊 error target 與可成功處理 target，驗證後者仍被處理、最終非零及資源清理。

4. reviewer: B
   severity: Warning
   confidence: 100
   layer: design
   location: `scripts/spectra-plus/tests/repair-all-checks.fish:625-635`; dry-run current-state contract
   summary: 沒有驗證 dry-run current-check error 必須非零且不得安裝或寫入 state。
   recommendation: 以 dry-run 執行 current／stale／error 組合，驗證 summary、非零、無 installation 與 lock/cache/throttle/registry/snapshot 不變。

### Suggestion

None.

## Rating

- Surviving Critical: 1
- Surviving Warning: 4
- critical_gap: true
- round_type: full

兩位 reviewer 獨立確認一項核心三態契約違反，另有四項可重現的 failure reporting、CLI 唯讀邊界與明文測試缺口；依機械規則本輪不得通過，下一輪必須為 full。

## Fix Actions

- `install-spectra-plus.fish`：讓 current-state assertion 保留 execution error status，只有明確內容不符回傳 stale，`--check-current` 只將 stale 映射為 exit 10。
- `install-spectra-plus.fish`：將 `--check-current` 收斂成獨立嚴格介面，只接受單一 existing absolute target directory，拒絕額外 positional 與混合 mode。
- `install-spectra-plus.fish`：explicit snapshot cleanup 失敗時向 stderr 回報 owned snapshot 路徑並保留非零結果。
- `scripts/spectra-plus/tests/repair-all-checks.fish`：新增內部 assertion error、strict CLI、cleanup failure、normal fail-and-continue 及 dry-run 三態唯讀案例。
- 驗證：`fish scripts/spectra-plus/tests/repair-all-checks.fish`、`fish scripts/spectra-plus/tests/installer-commit-guard-checks.fish`、`fish scripts/spectra-plus/tests/generator-checks.fish` 全數通過。
- 下一輪維持 `full`：fix actions 修改 production behavior 與 implementation tests。

## Decision

next_round
