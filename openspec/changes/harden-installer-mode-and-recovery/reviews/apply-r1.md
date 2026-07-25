# Cash Apply Review — Round 1

## Reviewer Findings

### Critical

None.

### Warning

- severity: Warning
  confidence: 100
  layer: design
  location: `.cash-skills/lib/cash_cli/installer.py` — `test_hooks`
  summary: 兩個 hold path 以原始字串判重，等價 alias path 可避開 preflight 並延後到 target write 後才失敗。
  recommendation: 正規化 absolute path 後判重，並新增 alias-path regression test。
  reviewer source: Reviewer A
- severity: Warning
  confidence: 100
  layer: design
  location: `scripts/cash-skills/tests/test_installer_runtime.py` — journal classification matrix
  summary: `current` 與 `update` fixture 相同且未斷言 `Result:`，也未覆蓋 real-run 四分類 diagnostic。
  recommendation: 建立可觀察且互異的四分類 fixture，對 dry-run 與 real-run 逐一斷言結果與 diagnostic。
  reviewer source: Reviewer A
- severity: Warning
  confidence: 100
  layer: design
  location: `install-cash-skills.fish` — interpreter version probe
  summary: version probe 未套用 `-s -P` 且未丟棄 stdout，user site 可在安全 handoff 前執行並污染輸出。
  recommendation: probe 同樣使用 `-s -P`，並明確丟棄 stdout/stderr。
  reviewer source: Reviewer B
  introduced_by: initial implementation diff in `install-cash-skills.fish`
- severity: Warning
  confidence: 100
  layer: design
  location: `scripts/cash-skills/tests/test_installer_runtime.py` — entrypoint user-site fixture
  summary: fixture 假設固定 user-site 路徑且 shim 繞過真實 probe，無法偵測 probe 載入 user site。
  recommendation: 由受測 interpreter 的 `site.getusersitepackages()` 建立 fixture，並讓合格 shim 真正執行 probe。
  reviewer source: Reviewer B
  introduced_by: initial implementation diff in `scripts/cash-skills/tests/test_installer_runtime.py`

### Suggestion

None.

## Rating

- cumulative blocking Critical: 0
- cumulative blocking Warning: 4
- non-blocking triaged findings: 0
- critical_gap: false
- round_type: full
- rationale: 第一輪四項高信心 Warning 均直接影響明定 contract 或其必要驗證，因此全部進入 blocking set；已完成修正，需由下一輪 fresh verifier 明確確認 resolved/unresolved。

## Fix Actions

- `.cash-skills/lib/cash_cli/installer.py`：以 `Path.resolve()` 正規化已啟用 hold paths 後判重。
- `scripts/cash-skills/tests/test_installer_runtime.py`：新增等價 alias hold-path preflight 案例；重寫 journal matrix，對 dry-run／real-run 的 `current`、`update`、`newer`、`conflict` 逐一斷言 `Result:`、diagnostic 與 recovery 狀態。
- `install-cash-skills.fish`：version probe 改用 `-s -P` 並將 stdout/stderr 導向 `/dev/null`。
- `scripts/cash-skills/tests/test_installer_runtime.py`：由真實 interpreter 的 `site.getusersitepackages()` 建立 `usercustomize.py` fixture，合格 shim 真正執行 probe，並驗證無 side effect／stdout 汙染。
- 依 runtime receipt discipline 執行 `./install-cash-skills.fish --self`，再執行相關 4 個 regression tests、`.cash-skills/bin/cash validate --all` 與 `git diff --check`，全部通過。
- Post-fix mechanical self-check：delta annotation counts 平衡（0/0）；ADDED／MODIFIED requirement 分區與 master title identities 無衝突；identifier cross-grep 已檢查 hooks、journal、interpreter 與 failure-injection 名稱；未發現需修正的 count drift 或 open signal `check`。

## Decision

next_round
