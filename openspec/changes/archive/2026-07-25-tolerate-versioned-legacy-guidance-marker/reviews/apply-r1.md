# Cash Apply Review — Round 1

## Reviewer Findings

### Critical

（無）

### Warning

- severity: Warning
  confidence: 100
  layer: design
  location: `.cash-skills/lib/cash_cli/installer.py:634-636`
  summary: `marker_matches` 的字尾 pattern 只排除 LF，會接受跨越 CR 行界的 marker，並可能把其後 project-owned bytes 納入 managed span。
  recommendation: 將字尾 class 改為同時排除 `\r` 與 `\n`，並新增 CR-only 邊界 fixture，確認該形狀在首次 target write 前 fail closed。
  reviewer source: Reviewer A — Adherence、Reviewer B — Quality
  introduced_by: `.cash-skills/lib/cash_cli/installer.py:636` 新增的 `rb"(?: [^<>\n]+)? -->"`。

### Suggestion

（無）

## Rating

- cumulative blocking Critical: 0
- cumulative blocking Warning: 1
- non-blocking triaged finding: 0
- critical_gap: false
- round_type: full
- rationale: 本輪有一項 confidence 100 的 Warning，直接違反 IC1 對字尾不得含換行的要求；依 unseeded first round 規則進入 cumulative blocking set，修復後仍須由後續 reviewer 明確驗證才可移除。

## Fix Actions

- 修正 `.cash-skills/lib/cash_cli/installer.py`：將 suffix class 由 `[^<>\n]+` 收斂為 `[^<>\r\n]+`，避免 marker 跨越 CR 或 LF 行界。
- 修正 `scripts/cash-skills/tests/test_installer_runtime.py`：新增 `carriage-return-in-suffix` fixture，先確認修復前 installer 錯誤地 exit 0，再確認修復後在一般與 `--force` 路徑皆於首次 target write 前失敗。
- 重建 `.cash-skills/receipt.tsv`，並重跑 targeted unittest、`.cash-skills/bin/cash validate --all` 與 `fish scripts/cash-skills/tests/skill-checks.fish`，全部通過。
- Post-fix mechanical self-check：spec comment 配對、separator lint、identifier cross-grep 與 `git diff --check` 全部通過，未另發現或修正其他問題。

## Decision

next_round
