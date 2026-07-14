# Apply Plus Review — Round 2

## Reviewer Findings

### Critical

None.

### Warning

1. reviewer: A
   severity: Warning
   confidence: 100
   layer: design
   location: `install-spectra-plus.fish:65-67`
   summary: fish-exit cleanup 吞掉 stderr；handled failure 後若 owned snapshot cleanup 也失敗，必要診斷會被靜默隱藏。
   recommendation: 保留 exit-handler cleanup 的 stderr，並新增 shared failure 與 cleanup failure 同時發生的組合測試。

2. reviewer: B
   severity: Warning
   confidence: 100
   layer: design
   location: `install-spectra-plus.fish:5,291`
   summary: inherited exported variable 會讓 `set -g` 保留 export attribute，snapshot ownership path 可能被傳給子行程，違反未 export state 契約。
   recommendation: 初始化、指定與清空 ownership state 時明確使用 `--unexport`，並新增 inherited exported variable 回歸測試。

3. reviewer: B
   severity: Warning
   confidence: 100
   layer: text
   location: `SPECTRA-PLUS.md:119`
   summary: 文件宣稱整個 working tree 不會成為 target 內容來源，忽略 target-local base skills 仍由各 target root 讀取，超出 pinned shared-input 契約。
   recommendation: 將敘述限縮為 working-tree shared inputs，並明示 target-local base skills 仍從 target root 讀取。

### Suggestion

None.

## Rating

- Surviving Critical: 0
- Surviving Warning: 3
- critical_gap: false
- round_type: full

Round 1 fixes 已完整，但 Round 2 仍有兩項 design-layer failure/isolation 缺口及一項文件範圍漂移；依機械規則本輪為 `next_round`，且因存在 design-layer Warning，下一輪必須為 full。

## Fix Actions

- `install-spectra-plus.fish`：fish-exit cleanup 保留 stderr，使 shared handled failure 後的 cleanup failure 仍可觀察。
- `install-spectra-plus.fish`：snapshot ownership 與 pinned rules process state 的初始化、指定及清空全部改用 `set --global --unexport`，消除 inherited export attribute。
- `scripts/spectra-plus/tests/repair-all-checks.fish`：新增 inherited exported ownership 隔離案例，以及 tar failure + cleanup failure 組合案例，驗證原始錯誤與 cleanup 錯誤同時可見且不碰 target／lock／throttle。
- `SPECTRA-PLUS.md`：將 working-tree 敘述限縮為 shared inputs，並明示 target-local base skills 仍從各 target root 讀取。
- 驗證：`fish scripts/spectra-plus/tests/repair-all-checks.fish`、`fish scripts/spectra-plus/tests/installer-commit-guard-checks.fish`、`fish scripts/spectra-plus/tests/generator-checks.fish` 全數通過。
- 下一輪維持 `full`：fix actions 修改 cleanup behavior、process-state isolation、tests 與契約文件。

## Decision

next_round
