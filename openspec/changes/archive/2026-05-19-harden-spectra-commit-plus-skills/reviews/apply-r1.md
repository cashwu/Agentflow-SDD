# Apply Plus Review — Round 1

## Reviewer Findings

### Critical

- `.agents/skills/spectra-commit/SKILL.md` 與 `.claude/skills/spectra-commit/SKILL.md` 的 protected deletion guard 宣稱 plus skill deletion 只能透過 Customize 納入，但 User confirmation options 仍允許 `Include all dirty files: Add all unrelated files`。這會讓 `.agents/skills/spectra-*-plus/` 與 `.claude/skills/spectra-*-plus/` deletion 仍可能被納入 stage。

### Warning

- `install-spectra-plus.fish` 以 anchors 檢查後整檔 `cp` 覆蓋 target `spectra-commit` skill，可能覆蓋目標專案本地修改。
- `install-spectra-plus.fish` dry-run 遇到已有 marker 的 target 時只輸出 verify，沒有驗證完整 guard 內容。
- `.agents/skills/spectra-commit/SKILL.md` 與 `.claude/skills/spectra-commit/SKILL.md` 的 archive plan 範例仍混用 `docs/specs/...` 與 `openspec/...`。
- `scripts/spectra-plus/tests/installer-commit-guard-checks.fish` 偏向字串存在檢查，未覆蓋 `Include all dirty files` 與 protected deletion 的衝突。

### Suggestion

- installer 測試應加入 local sentinel，確認非 managed 內容不會被覆蓋。
- `generate.fish` marker 更新屬低風險，但應保持 generator regression suite 通過。

## Rating

quality_score: 4

critical_gap: true

rationale: Reviewer 已指出明確 Critical：protected deletion guard 宣稱 plus skill deletion 只能透過 Customize 納入，但 user confirmation options 仍允許 `Include all dirty files`，導致受保護刪除可能被一併 stage，直接違反安全契約與使用者確認邊界。Warnings 也顯示安裝覆蓋、dry-run false positive、文件路徑不一致與測試缺口，代表修正前不只是文字瑕疵，而是安全行為、驗證可信度與文件一致性都有實質風險。因此本輪不能通過，且必須先修 Critical。

## Fix Actions

- 修改 `.agents/skills/spectra-commit/SKILL.md` 與 `.claude/skills/spectra-commit/SKILL.md`，讓 `Include all dirty files` 明確排除 protected generated plus skill deletions，並讓 Customize 明確要求使用者命名 plus deletion path 才能納入。
- 修改兩份 `spectra-commit` archive plan 範例，統一使用 `openspec/changes/<name>/`、`openspec/changes/archive/<date>-<change>/`、`openspec/specs/<spec-name>/spec.md`。
- 修改 `install-spectra-plus.fish`，從 source 抽取 guard block 與 archive section 進行 section patch，不再整檔覆蓋。
- 修改 `scripts/spectra-plus/tests/installer-commit-guard-checks.fish`，加入 local sentinel 與 protected deletion exception 檢查。

## Decision

next_round
