# Propose Plus Review — Round 2

## Reviewer Findings

### Critical

無。

### Warning

- `severity`: Warning
  `confidence`: 100
  `location`: `openspec/changes/auto-repair-spectra-plus-skills/design.md:43`, `openspec/changes/auto-repair-spectra-plus-skills/design.md:54`, `openspec/changes/auto-repair-spectra-plus-skills/specs/spectra-plus-skills/spec.md:57-61`, `openspec/changes/auto-repair-spectra-plus-skills/tasks.md:12`, `openspec/changes/auto-repair-spectra-plus-skills/tasks.md:20`
  `summary`: `--repair-all --dry-run` 的 no-write contract 未涵蓋 lock/throttle/cache state，可能污染 `last-repair-attempt` 或 lock，導致後續真實自動修復被跳過。
  `recommendation`: 在 spec/tasks 補 dry-run repair-all 狀態檔驗證，使用 temporary `HOME`/`TMPDIR` 確認 cache、lock、last-attempt 未建立或未變更。
  Reviewer: A+B

- `severity`: Warning
  `confidence`: 85
  `location`: `openspec/changes/auto-repair-spectra-plus-skills/design.md:25`, `openspec/changes/auto-repair-spectra-plus-skills/design.md:48`, `openspec/changes/auto-repair-spectra-plus-skills/design.md:62`, `openspec/changes/auto-repair-spectra-plus-skills/specs/spectra-plus-skills/spec.md:25-29`, `openspec/changes/auto-repair-spectra-plus-skills/tasks.md:4`, `openspec/changes/auto-repair-spectra-plus-skills/tasks.md:11`
  `summary`: registry 可能含已刪除 target，但 unregister 契約未明確要求可移除 stale registry entry。
  `recommendation`: 明定 `--unregister-target` 不要求目標目錄存在，並新增註冊 target、刪除目錄、unregister 後移除 entry 的測試。
  Reviewer: B

- `severity`: Warning
  `confidence`: 85
  `location`: `openspec/changes/auto-repair-spectra-plus-skills/design.md:52`, `openspec/changes/auto-repair-spectra-plus-skills/design.md:64`, `openspec/changes/auto-repair-spectra-plus-skills/specs/spectra-plus-skills/spec.md:73-78`, `openspec/changes/auto-repair-spectra-plus-skills/tasks.md:17-18`, `openspec/changes/auto-repair-spectra-plus-skills/tasks.md:26`
  `summary`: LaunchAgent sparse PATH 風險只在 Risks 提到，未成為 spec/tasks 的可驗收契約。
  `recommendation`: 將 LaunchAgent 受控執行環境納入 contract，並測試最小 PATH 下 entrypoint 或錯誤 log 行為。
  Reviewer: B

### Suggestion

- `severity`: Suggestion
  `confidence`: 75
  `location`: `openspec/changes/auto-repair-spectra-plus-skills/tasks.md:13`, `openspec/changes/auto-repair-spectra-plus-skills/tasks.md:18`, `openspec/changes/auto-repair-spectra-plus-skills/tasks.md:20-21`
  `summary`: 部分 `[P]` 標記可能跨到相同實作面或依賴 repair-all/LaunchAgent 基礎能力。
  `recommendation`: 在實作前再次確認 `[P]` 任務寫入範圍；若碰同一檔案，移除 `[P]` 或拆分。
  Reviewer: A

- `severity`: Suggestion
  `confidence`: 75
  `location`: `openspec/changes/auto-repair-spectra-plus-skills/design.md:43`, `openspec/changes/auto-repair-spectra-plus-skills/specs/spectra-plus-skills/spec.md:93-97`, `openspec/changes/auto-repair-spectra-plus-skills/tasks.md:20`
  `summary`: lock 未定義 stale lock 復原，repair-all 若被中斷可能永久停止。
  `recommendation`: 明確採用 atomic lock + trap cleanup，並定義 stale lock recovery 或 manual cleanup。
  Reviewer: B

## Rating

`quality_score`: 7.0
`critical_gap`: false

目前沒有 Critical finding，但 dry-run state、stale registry entry 與 LaunchAgent 執行環境仍是會影響可靠性與可驗證性的 Warning，因此尚未達到 pass bar。

## Fix Actions

- 修改 `openspec/changes/auto-repair-spectra-plus-skills/specs/spectra-plus-skills/spec.md`：補強 unregister stale target、repair-all dry-run state no-write、LaunchAgent controlled environment、lock cleanup 與 stale lock recovery scenarios。
- 修改 `openspec/changes/auto-repair-spectra-plus-skills/design.md`：明確 `--unregister-target` 不要求 target 目錄存在，LaunchAgent 使用受控 command path/PATH 與固定 log，repair-all dry-run 不寫 lock/cache/throttle state，lock 使用 atomic create + cleanup/stale recovery。
- 修改 `openspec/changes/auto-repair-spectra-plus-skills/tasks.md`：補 stale unregister、dry-run state、最小 PATH/log、stale lock recovery 的驗證要求。
- 重新執行 `spectra analyze auto-repair-spectra-plus-skills`：Coverage、Consistency、Gaps 皆 clean，僅剩 concrete example suggestions。
- 重新執行 `spectra validate auto-repair-spectra-plus-skills`：通過。

## Decision

next_round
