## Why

Spectra Plus 的 review loop 已具備機械決策、confidence filter 與 signals 共享層，但對照 AutoResearch loop 與 Bilevel Autoresearch 論文（arXiv:2603.23420）的紀律設計，仍有三個缺口：(1) 沒有明文禁止 fix action 修改「裁判面」（review 模板、rules.yaml、生成的 plus skill、驗證工具）來讓 gate 過關；(2) 每輪決策資料分散在多個 round file，缺少一份緊湊、機器可讀的迴圈軌跡，後續 meta 分析（例如分析 loop 卡點）成本高；(3) signals 的 machine-checkable anti-pattern 檢查目前依賴 agent 的 best-effort 判斷，缺少結構化欄位讓 self-check 成為確定性執行。

## What Changes

- **裁判不可改規則（grader immutability）**：在共享 review-loop 模板中新增明文規則 — review loop 進行中，主 agent（含 fix action 與 mechanical self-check 修復）不得修改裁判面保護路徑集（`scripts/spectra-plus/template/` 下的模板、`scripts/spectra-plus/rules.yaml`、`scripts/spectra-plus/generate.fish`、生成的四個 plus skill 檔案、`.spectra.yaml`、`openspec/specs/` 下的 master spec 檔案），除非該檔案被此 change 的 proposal `## Impact` 或 tasks.md 明文列入範圍（列入目錄視同列入其下所有檔案；列入模板檔視同列入其重生成產物）；任何 signal 的 `check` 欄位一律禁止增改刪，不受範圍例外影響。當某 finding 的修復必須修改範圍外的保護檔案時，fix action 不執行該修改、在 `## Fix Actions` 記錄「未修復：裁判面保護」，該 finding 保持存活參與輪次決策 — 若因此到第 6 輪仍不過，依既有規則 aborted（fail loud），由人另開 change 處理裁判面缺陷；無論最終 decision 為何，workflow 完成摘要必須列出全部「未修復：裁判面保護」記錄。
- **Loop ledger**：review loop 每輪完成後，在 `openspec/changes/<change>/reviews/loop-ledger.tsv` 追加一行緊湊軌跡（skill、round、round_type、surviving Critical/Warning 計數、decision、修改檔案數），跨 propose/apply 迴圈與重跑以事件日誌方式累加；round file 仍是完整權威記錄，ledger 僅為機器可讀的彙總。
- **Signal 確定性檢查欄位**：在 signal frontmatter schema 新增選填欄位 `check`（一條由人工撰寫、經 `sh -c` 執行的唯讀 shell 檢查命令），mechanical self-check 的「Signal-derived checks」對帶有 `check` 欄位的 open signal 改為確定性執行該檢查，無 `check` 欄位者維持現行 best-effort 判斷；自動化寫入者（含 signals write step）不得增改刪 `check` 欄位。

## Capabilities

### New Capabilities

（無）

### Modified Capabilities

- `spectra-plus-skills`: review loop 新增裁判不可改規則（主 agent 的禁改路徑集與違規處理，並為既有 propose-plus / apply-plus quality gate 的「fix findings before next round」場景定義裁判保護例外的優先序）、新增 loop ledger 輸出契約（每輪追加一行 TSV），並將 mechanical self-check 的 Signal-derived checks 升級為對帶 `check` 欄位的 open signal 確定性執行。
- `signals-shared-layer`: signal frontmatter schema 新增選填 `check` 欄位（人工撰寫、唯讀、`sh -c` 執行）與 README 文件義務，並將自動化寫入者的可寫欄位治理擴充為明文排除 `check`。

## Impact

- Affected specs: `spectra-plus-skills`（review loop 規則與輸出契約）、`signals-shared-layer`（schema 與 README）
- Affected code:
  - Modified: scripts/spectra-plus/template/review-loop-block.md（裁判不可改規則、ledger 步驟、signal-derived checks 確定性化）
  - Modified: scripts/spectra-plus/rules.yaml（收斂 Codex variant 的 `/spectra-` substitution，使其只處理 backtick command 形式，避免破壞 generated skill 內的 literal protected paths）
  - Modified: openspec/signals/README.md（記載 `check` 欄位）
  - Modified: scripts/spectra-plus/tests/generator-checks.fish（新增生成內容斷言）
  - Regenerated: .claude/skills/spectra-propose-plus/SKILL.md、.claude/skills/spectra-apply-plus/SKILL.md、.agents/skills/spectra-propose-plus/SKILL.md、.agents/skills/spectra-apply-plus/SKILL.md
  - New: （本 change 不新增檔案；loop-ledger.tsv 由後續 plus loop 執行時產生於各 change 的 reviews/ 目錄，隨 change 目錄歸檔）
