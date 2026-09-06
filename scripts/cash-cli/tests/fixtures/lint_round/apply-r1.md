# Cash Apply Review — Round 1

## Reviewer Findings

### Critical

- severity: Critical
  confidence: 100
  layer: design
  location: `.cash-skills/lib/cash_cli/commands/lint_round.py` 的 single-change declaration union
  summary: single-change mode 原本只收集指定 change 的 structured scope declarations，與 D4 要求的全部未封存且未 parked changes 聯集不一致。
  recommendation: 讓 single-change mode 仍從完整列舉結果建立 declarations，位置參數只限制回報的 change。
  reviewer: Reviewer A

- severity: Critical
  confidence: 95
  layer: design
  location: `.cash-skills/lib/cash_cli/commands/lint_round.py` 的 `_git_changed`
  summary: `git status --porcelain=v1 -z` 的 rename/copy record 原本會對第二個 path 盲目移除前三字元，可能漏掉 renamed-to protected path。
  recommendation: 依 rename/copy record 的雙 path 形狀解析 source 與 destination。
  reviewer: Reviewer B

### Warning

- severity: Warning
  confidence: 100
  layer: design
  location: `.cash-skills/lib/cash_cli/commands/lint_round.py` 的 hook failure output
  summary: hook failure 原本只輸出 `change:id`，未包含 contract 要求的 failure detail；JSON failure 也未保留 stderr diagnostics。
  recommendation: 失敗時在 stderr 輸出 change、gate id 與 detail，同時維持 JSON stdout shape。
  reviewer: Reviewer A + Reviewer B

- severity: Warning
  confidence: 90
  layer: design
  location: `.cash-skills/lib/cash_cli/commands/lint_round.py` 的 round type parsing
  summary: round file 首次讀取失敗後，round type path 又直接讀檔，可能把不可解碼或讀取競態提升成例外，而非回報 `round_type_position: fail`。
  recommendation: 重用首次讀取結果，讓不可讀 round file 保持可觀察的 gate failure。
  reviewer: Reviewer A + Reviewer B

## Rating

- post-filter 累積 blocking 集合 `Critical` 數：2
- post-filter 累積 blocking 集合 `Warning` 數：2
- non-blocking triaged finding count：0
- critical_gap: true
- round_type: full
- rationale：首輪 reviewer findings 都有本次 changed diff 的直接證據，因此全部進入累積 blocking set；修正已完成並有 regression evidence，仍需下一輪 Reviewer V 明確驗證每個成員已解除。

## Fix Actions

- F1：修改 `.cash-skills/lib/cash_cli/commands/lint_round.py`，single-change mode 改從完整 `_enumerate_changes(workspace)` 建立非 parked declaration union；新增 `test_single_change_uses_declarations_from_other_nonparked_change` 驗證 single-change 與 hook 的涵蓋來源一致。
- F2：修改 `.cash-skills/lib/cash_cli/commands/lint_round.py` 的 `_git_changed`，依 `R`／`C` status record 讀取兩個 NUL-separated paths；新增 `test_git_rename_record_keeps_both_paths` 驗證兩個 path 都保留。
- F3：修改 `.cash-skills/lib/cash_cli/commands/lint_round.py`，hook failure 一律將失敗 check 的 `change`、`id` 與 `detail` 寫入 stderr；新增 `test_hook_failure_stderr_contains_gate_detail_even_with_json`。
- F4：修改 `.cash-skills/lib/cash_cli/commands/lint_round.py`，重用 round file 初次讀取結果；新增 `test_unreadable_round_file_is_a_gate_failure_not_an_exception`。
- 本輪實際修改檔案為 `.cash-skills/lib/cash_cli/commands/lint_round.py`、`scripts/cash-cli/tests/test_lint_round.py` 與 `.cash-skills/manifest.tsv`；manifest 由 publication 依 runtime bytes 更新。
- 以上修正後執行 `PYTHONPATH=.cash-skills/lib uv run --with pytest python3 -m pytest scripts/cash-cli/tests/test_lint_round.py`，15 tests 全部通過。
- 產生 managed bundle publication：執行 `./install-cash-skills.fish --self`，成功回報 `Result: bootstrap`。

## Decision

next_round

本輪 blocking findings 已依 Fix Actions 修正；依 review-loop 規則需要 micro round 由 Reviewer V 驗證修正傳播與每個累積成員的 resolved/unresolved verdict。
