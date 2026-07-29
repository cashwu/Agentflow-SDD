# Cash Apply Review — Round 2

## Reviewer Findings

### Critical

無。

### Warning

1. severity: Warning｜confidence: 98｜layer: design｜location: `scripts/cash-shim/install_shim.py:49-74`（`_open_home`）｜summary: `HOME` 的初始 pathname identity 尚未綁定 held FD；`lstat → resolve → open` 之間若 leaf 被換成外部 symlink，後續 mutation 會安全地綁在錯誤的外部 identity 上｜recommendation: opened FD 的 `fstat` identity 必須與初始 no-follow `lstat(HOME)` identity 相同，不一致即 fail closed；新增 HOME leaf-swap fault injection，斷言外部與被移開的原 HOME 零寫入｜disposition: unresolved-prior｜來源: Reviewer B — Quality；對應 apply-r1 S4

### Suggestion

無。

## Rating

- post-filter cumulative blocking Critical: 0
- post-filter cumulative blocking Warning: 1
- non-blocking triaged finding: 0
- critical_gap: false
- round_type: full
- rationale: 兩位 reviewer 均確認 S1、S2、S3 已解決；S4 的 verdict 不一致時依規則採 `unresolved`，因 `HOME` held FD 建立前仍有同一 filesystem-boundary swap 視窗。此修復使用 design D7／C11 已定義的 directory identity，不觸發 design circuit breaker；完成修復後進入 micro verification。

## Fix Actions

- verified-resolution removal — S1：`tasks.md` 5.3、`design.md` C12 與 deletion fixture 已固化條件式 deletion contract；Reviewer A 與 Reviewer B 均確認 resolved。
- verified-resolution removal — S2：`shim-checks.fish` 已逐列覆蓋兩個 spec Examples 的完整 argv；Reviewer A 與 Reviewer B 均確認 resolved。
- verified-resolution removal — S3：`cash-shim.sh` reserved prefix／pre-assignment `unset` 與 hostile environment fixtures已消除 inherited export 污染；Reviewer A 與 Reviewer B 均確認 resolved。
- 修復 S4：修改 `scripts/cash-shim/install_shim.py`，在 opened HOME FD 後比較 `fstat` 與初始 no-follow `lstat` identity，不一致時關閉 FD 並 fail closed。
- 修復 S4 regression：修改 `scripts/cash-shim/tests/shim-checks.fish`，先取得 RED（舊實作會在外部建立 destination），再加入 HOME leaf-swap fixture，斷言 identity mismatch、外部 sentinel／destination 與被移開的原 HOME 均零變更。
- Fix propagation：修改 `openspec/changes/add-global-cash-shim/design.md` D7／C11、`openspec/changes/add-global-cash-shim/specs/cash-global-shim/spec.md` requirement／scenario，以及 `openspec/changes/add-global-cash-shim/tasks.md` 5.1，使 HOME 初始 identity 綁定與 fault-injection 驗收在 artifacts 間一致。
- Post-fix self-check：`fish scripts/cash-shim/tests/shim-checks.fish`、`cash validate add-global-cash-shim`、`git diff --check`、spec annotation lint、identifier cross-grep 全部通過；open signals 無 `check` frontmatter；apply state 維持 `all_done`（9/9）。
- Touched state：已記錄 `scripts/cash-shim/install_shim.py` 與 `scripts/cash-shim/tests/shim-checks.fish`。

## Decision

next_round
