# Apply Plus Review — Round 2

## Reviewer Findings

### Critical

- `install-spectra-plus.fish` 只 patch `SPECTRA-COMMIT-GUARD` block 與 `6a-iii` archive section，沒有 patch target 的 Step 6 `Include all dirty files` / `Customize` 文案。真正舊版 target 仍可能讓 protected plus deletion 透過 Include all dirty files 被納入，而且 installer 可能在部分改檔後 validate 失敗。

### Warning

- `scripts/spectra-plus/tests/installer-commit-guard-checks.fish` 的 older target fixture 是從已修正 source 移除 guard，仍保留 Step 6 exception，抓不到舊版 target 問題。
- `install-spectra-plus.fish` 先 `mv` target 再 validate，失敗時會留下半套用狀態。

### Suggestion

- `validate_commit_guard` 對整份 target 全域禁止 `openspec/archived/` 與 `docs/specs/`，可能對本地自訂說明偏嚴。

## Rating

quality_score: 5

critical_gap: true

rationale: Round 2 修正前仍存在實質阻斷問題：`install-spectra-plus.fish` 沒有修補 Step 6 的 `Include all dirty files` / `Customize` 文案與行為，導致舊版 target 仍可能把 protected plus deletion 納入提交範圍，核心防護目標未完整落地；同時 installer 會先修改 target 再 validate，失敗時留下半套用狀態，增加使用者環境被污染的風險。測試 fixture 又是從已修正 source 反向移除 guard，沒有覆蓋真正舊版 target 的缺口，因此目前驗證不足以證明修正有效。Given Critical 存在，不能視為 pass。

## Fix Actions

- 修改 `install-spectra-plus.fish`，讓 installer 從 source 抽取並套用三段內容：`SPECTRA-COMMIT-GUARD` block、`6. **User confirmation**` section、`6a-iii` archive section。
- 修改 `install-spectra-plus.fish`，先產生 patched temp file 並通過 `validate_commit_guard`，再 `mv` 到 target，避免單一檔案半套用。
- 修改 `scripts/spectra-plus/tests/installer-commit-guard-checks.fish`，讓 fixture 真正模擬舊 target：移除 guard、把 `Include all dirty files` 還原成舊文案、移除 Customize protected line、把 archive section 路徑改成舊 `docs/specs`。
- 重新執行 `fish scripts/spectra-plus/tests/installer-commit-guard-checks.fish`、`fish scripts/spectra-plus/tests/generator-checks.fish`、`spectra validate harden-spectra-commit-plus-skills`、`spectra analyze harden-spectra-commit-plus-skills --json`，結果通過或 clean。

## Decision

next_round
