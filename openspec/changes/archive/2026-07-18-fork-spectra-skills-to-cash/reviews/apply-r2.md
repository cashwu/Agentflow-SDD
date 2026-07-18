# Cash Apply Review — Round 2

## Reviewer Findings

### Verified Resolutions

- `C1` resolved：Reviewer V 重新建立隔離 fixture、執行 `spectra update --force`，兩份 repo `spectra-commit` 分別與新 baseline `cmp` identical。
- `W1` resolved：七份 readable exact parity manifests 逐行列出允許差異，artifacts 明確宣告 tool-capability 差異，未使用 opaque digest。
- `W2` resolved：registry readable-regular-file 與 `cat` status preflight 位於所有 launchctl 之前，錯誤 fail closed。
- `W3` resolved：classifier 只接受 queried service-specific absent 訊息，generic not-found fixture 非零且保留 state。
- `W4` resolved：兩支 mutating scripts 使用 no-config shebang、關鍵外部命令以 `command` 呼叫，兩個 hostile startup direct-executable fixtures 通過。

### Critical

1. **location:** `scripts/cash-skills/tests/skill-checks.fish` governed mutation matrix
   **summary:** Round 1 新增的 26 個 mutation cases 都只改單一 `.agents` 檔案，可能只因 Claude/Codex parity 被破壞而失敗，沒有證明 governed branch assertion 本身 fail loud。Reviewer V 同步刪改四份 propose/apply canonical files 的 first/full sentence 後，nested suite 仍回傳 0。
   **recommendation:** 每個 shared mutation 同步套用四份 propose/apply canonical files；skill-specific mutation 同步套用兩個 variants；補齊 first/full、seeded、signal matching、run-first verification 與 no-park 的 branch-specific assertions。
   **confidence:** 100
   **layer:** design
   **disposition:** unresolved-prior

### Warning

None.

### Suggestion

None.

## Rating

- verified-resolution removals: `C1`, `W1`, `W2`, `W3`, `W4`
- unresolved-prior: 1 Critical (`C2`)
- fix-introduced: 0
- new: 0
- post-filter cumulative blocking set: 1 Critical, 0 Warning
- `critical_gap: true`
- `round_type: micro`
- rationale: 五個成員已有直接 resolution evidence 並離開 cumulative set；C2 的 parity false-confidence 是原 blocking member 的不完整修正，維持 unresolved-prior 並要求下一位 Reviewer V 驗證。

## Fix Actions

- 修改 `scripts/cash-skills/tests/skill-checks.fish`：mutation spec 改以 `shared`、`propose`、`apply`、`commit` contract groups 表達；shared mutations 同步改四份 canonical files，其他 mutations 同步改兩個 variants，避免 parity 成為唯一失敗原因。
- 修改 `scripts/cash-skills/tests/skill-checks.fish`：branch assertions 新增 exact first/full、seeded rerun、signal issue-class matching、run-first-round verification 與 no-park contracts；mutation 對指定 literal 的所有 occurrences 同步替換，避免其他重複文字掩蓋缺失。
- Post-fix regression：完整 `fish --no-config scripts/cash-skills/tests/skill-checks.fish` 通過；若任一同步 mutation 未被獨立 branch assertion 擋下，outer suite 會因該 mutation unexpectedly returned 0 而失敗。
- Post-fix mechanical self-check：`fish_indent --check` 與 `git diff --check` 通過。
- Post-fix validation：`spectra validate fork-spectra-skills-to-cash` 通過。

## Decision

next_round
