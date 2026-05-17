## Why

現有 spectra-propose 與 spectra-apply 的品質閘是「inline self-review + analyze-fix loop（max 2 iter）」，由主 agent 自查，沒有獨立評審視角。Agentflow-SDD 同類流程採用「fresh sub-agent 每輪做 review/rating/fix，最多 3 round，通過條件 quality_score > 9/10 且 no critical gap」，明顯更嚴格。我們希望在不破壞原 spectra 行為的前提下，提供一個 plus 變體：用 sub-agent 品質閘取代 inline self-review，並把上限提高到 6 round。

## What Changes

- 新增兩支 skill：`spectra-propose-plus`、`spectra-apply-plus`，行為與原版幾乎相同，差別在於品質閘換成 sub-agent review/rating/fix loop（per-change 粒度、max 6 round、quality_score > 9/10 且 no critical gap）。
- 每一 round 都會在 `openspec/changes/<change>/reviews/` 產出對應 md 檔（命名 `propose-r<round>.md`、`apply-r<round>.md`），內容含 findings、rating、fix actions。
- 每一 round 由獨立 sub-agent（reviewer + rater）執行，不在主 agent 內 inline review。
- 兩支 plus skill 不手寫維護，改由 generator 產生：generator 讀現有 spectra-X skill + template + rules，輸出 spectra-X-plus skill。spectra 上游改版時重跑 generator 即可。
- Generator 拆檔架構：主程式只負責讀規則套用、注入段落與評分標準寫在 template、每支 skill 的注入點寫在 rules.yaml。
- `spectra-propose-plus` 流程結束後 **不 park**（原 spectra-propose 會無條件 park）。`spectra-apply-plus` 流程結束行為與原 spectra-apply 相同。
- 第一版只處理 propose 與 apply 兩支；discuss 因不產出 artifact 不納入，其他 spectra-* skill 不納入。

## Non-Goals (optional)

- 不取代原 spectra-propose、spectra-apply：兩者繼續存在，plus 是並行選項。
- 不為 discuss、ingest、archive、ask、analyze、audit、commit、debug、drift、verify 產生 plus 版。
- 不做自動 merge：generator 偵測到上游結構變化、注入點找不到時直接報錯，由人工判斷修 rules 還是改 template。
- 不允許手改已生成的 plus skill；plus 是 derived artifact，每次 regenerate 會覆蓋。

## Capabilities

### New Capabilities

- `spectra-plus-skills`: 提供 propose 與 apply 兩支 plus 變體 skill，以及產生它們的 generator（含 template 與 rules.yaml）。涵蓋 plus skill 的品質閘契約（per-change、max 6 round、quality_score > 9/10、round md 檔輸出）與 generator 的轉換契約（輸入、輸出、失敗模式）。

### Modified Capabilities

(none)

## Impact

- Affected specs: spectra-plus-skills（新增）
- Affected code:
  - New:
    - .claude/skills/spectra-propose-plus/SKILL.md
    - .claude/skills/spectra-apply-plus/SKILL.md
    - scripts/spectra-plus/generate.fish
    - scripts/spectra-plus/rules.yaml
    - scripts/spectra-plus/template/review-loop-block.md
    - scripts/spectra-plus/template/round-file-format.md
  - Modified: (none)
  - Removed: (none)
