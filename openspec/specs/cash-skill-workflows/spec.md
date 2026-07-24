# cash-skill-workflows Specification

## Purpose

TBD - 由封存 change 'fork-spectra-skills-to-cash' 而建立。封存後請更新 Purpose。

## Requirements

### Requirement: Cash skill 清單與所有權

本 repository SHALL 為 Codex 與 Claude 兩者提供恰好以下十二個 cash workflow skills：`cash-analyze`、`cash-apply`、`cash-archive`、`cash-ask`、`cash-audit`、`cash-commit`、`cash-debug`、`cash-discuss`、`cash-drift`、`cash-ingest`、`cash-propose` 與 `cash-verify`。每個 cash skill 檔案 MUST 是由本 repository 擁有、納入版本控制的 canonical 檔案。

#### Scenario: 完整的雙變體清單

- **WHEN** 檢查 cash skill 清單時
- **THEN** 十二個 skills 全部存在於 `.agents/skills/` 之下
- **AND** 十二個 skills 全部存在於 `.claude/skills/` 之下
- **AND** 清單中沒有任何 skill 在任一變體中缺漏

#### Scenario: Cash 所有權中繼資料

- **WHEN** 檢視某個 cash skill 的 frontmatter 區塊時
- **THEN** 其 `name` 等於其 `cash-*` 目錄名稱
- **AND** 其中不包含 `generatedBy: "Spectra"`
- **AND** 其中不包含 `spectraPlusVersion`、`spectraPlusUpdated` 或 `spectraPlusFingerprint`


<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---

### Requirement: Propose 與 apply 吸收原有的 plus workflows

系統 SHALL 透過 `cash-propose` 提供完整的提案品質關卡 workflow，並透過 `cash-apply` 提供完整的實作品質關卡 workflow。系統 MUST NOT 提供較弱的 cash 基礎層級或任何 `cash-*-plus` skill。

#### Scenario: Cash 提案是唯一的提案層級

- **WHEN** 使用者呼叫 `cash-propose`
- **THEN** 該 workflow 建立 apply 所需的全部 artifacts
- **AND** 在其 sub-agent 品質關卡之前先對它們完成驗證
- **AND** 不需要另外的 `cash-propose-plus` workflow

#### Scenario: Cash apply 是唯一的實作層級

- **WHEN** 使用者呼叫 `cash-apply`
- **THEN** 該 workflow 實作所選的 change，並在所有 tasks 完成後執行其品質關卡
- **AND** 不需要另外的 `cash-apply-plus` workflow


<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---

### Requirement: Cash namespace 負責 workflow 路由與 artifact 引擎

Cash skills SHALL 在每一次 skill 之間的轉換使用 cash namespace。Codex 指示 MUST 使用 `$cash-*`；Claude 指示 MUST 使用對應的 `/cash-*` 語法。Artifact 操作 MUST 繼續使用 Cash CLI 與設定的 `openspec/` 路徑。

#### Scenario: 內部 workflow 轉換

- **WHEN** `cash-discuss` 建議將某項決策正式化
- **THEN** 它引導使用者前往 `cash-propose`
- **AND** 它不引導使用者前往任何 `spectra-*` 或 `cash-*-plus` skill

#### Scenario: Artifact 指令由 Cash 擁有

- **WHEN** 某個 cash skill 列出、建立、驗證、分析或封存 artifacts
- **THEN** 它呼叫適用的 `.cash-skills/bin/cash` CLI 指令
- **AND** 它讀取或寫入設定的 `openspec/` artifact 路徑
- **AND** 它不引入 Spectra CLI 轉接層

<!-- @trace
source: replace-spectra-cli-with-cash-cli
updated: 2026-07-24
code:
  - .agents/skills/
  - .agents/skills/spectra-analyze/
  - .agents/skills/spectra-apply/
  - .agents/skills/spectra-archive/
  - .agents/skills/spectra-ask/
  - .agents/skills/spectra-audit/
  - .agents/skills/spectra-commit/
  - .agents/skills/spectra-debug/
  - .agents/skills/spectra-discuss/
  - .agents/skills/spectra-drift/
  - .agents/skills/spectra-ingest/
  - .agents/skills/spectra-propose/
  - .agents/skills/spectra-verify/
  - .cash-skills/bin/cash
  - .cash-skills/lib/cash_cli/
  - .cash-skills/receipt.tsv
  - .cash-skills/state/
  - .cash-skills/state/snapshots/
  - .cash-skills/state/touched/
  - .claude/skills/
  - .claude/skills/spectra-analyze/
  - .claude/skills/spectra-apply/
  - .claude/skills/spectra-archive/
  - .claude/skills/spectra-ask/
  - .claude/skills/spectra-audit/
  - .claude/skills/spectra-commit/
  - .claude/skills/spectra-debug/
  - .claude/skills/spectra-discuss/
  - .claude/skills/spectra-drift/
  - .claude/skills/spectra-ingest/
  - .claude/skills/spectra-propose/
  - .claude/skills/spectra-verify/
  - .spectra/
  - scripts/cash-cli/fixtures/
  - scripts/cash-cli/tests/
  - scripts/cash-skills/legacy-spectra-digests.tsv
  - scripts/cash-skills/tests/skill-checks.fish
tests:
-->

### Requirement: Cash 提案品質關卡

`cash-propose` SHALL 依照 Cash artifact DAG 建立 proposal、design、delta specs 與 tasks，執行 `.cash-skills/bin/cash validate`，然後每個 change 執行一次共用的評分審查迴圈。它 MUST 以繁體中文撰寫非 spec artifacts 與審查文字、spec 檔依 Spec 檔案語言政策撰寫（繁體中文內文、英文結構關鍵字與規範動詞）、讓該 change 保持 active，且 MUST NOT 呼叫 apply 或 park。

#### Scenario: 驗證先於審查

- **WHEN** apply 所需的全部 artifacts 都已建立
- **THEN** `cash-propose` 執行 `.cash-skills/bin/cash validate "<change>"`
- **AND** 在開始審查 round 1 之前修正驗證失敗
- **AND** 每當 fix action 更動任一 artifact 時，在下一輪之前重新驗證

#### Scenario: 提案 workflow 結束時不進入 apply

- **WHEN** 提案審查迴圈以 `passed` 或 `aborted` 結束
- **THEN** `cash-propose` 記錄最終回合與摘要
- **AND** 將該 change 留在 `openspec/changes/` 之下
- **AND** 不呼叫 `cash-apply` 或 `.cash-skills/bin/cash park`

#### Scenario: 大型 impact 清單產生 advisory

- **WHEN** proposal 的 `## Impact` 在排除 `(none)` 佔位項並將每個目錄計為一個項目後，包含 16 個受影響程式碼項目
- **THEN** `cash-propose` 印出一則非阻斷的按能力拆分 advisory
- **WHEN** 相同計數為 15
- **THEN** `cash-propose` 不印出任何 impact-granularity advisory

<!-- @trace
source: replace-spectra-cli-with-cash-cli
updated: 2026-07-24
code:
  - .agents/skills/
  - .agents/skills/spectra-analyze/
  - .agents/skills/spectra-apply/
  - .agents/skills/spectra-archive/
  - .agents/skills/spectra-ask/
  - .agents/skills/spectra-audit/
  - .agents/skills/spectra-commit/
  - .agents/skills/spectra-debug/
  - .agents/skills/spectra-discuss/
  - .agents/skills/spectra-drift/
  - .agents/skills/spectra-ingest/
  - .agents/skills/spectra-propose/
  - .agents/skills/spectra-verify/
  - .cash-skills/bin/cash
  - .cash-skills/lib/cash_cli/
  - .cash-skills/receipt.tsv
  - .cash-skills/state/
  - .cash-skills/state/snapshots/
  - .cash-skills/state/touched/
  - .claude/skills/
  - .claude/skills/spectra-analyze/
  - .claude/skills/spectra-apply/
  - .claude/skills/spectra-archive/
  - .claude/skills/spectra-ask/
  - .claude/skills/spectra-audit/
  - .claude/skills/spectra-commit/
  - .claude/skills/spectra-debug/
  - .claude/skills/spectra-discuss/
  - .claude/skills/spectra-drift/
  - .claude/skills/spectra-ingest/
  - .claude/skills/spectra-propose/
  - .claude/skills/spectra-verify/
  - .spectra/
  - scripts/cash-cli/fixtures/
  - scripts/cash-cli/tests/
  - scripts/cash-skills/legacy-spectra-digests.tsv
  - scripts/cash-skills/tests/skill-checks.fish
tests:
-->

### Requirement: Cash apply 品質關卡

`cash-apply` SHALL 實作所選 change 的 tasks、維護 implementation-notes 契約，並僅在每個 task 都完成後才啟動共用的評分審查迴圈。在最終回合記錄 `decision: passed` 之前，archive 指引 MUST 持續保留不提供。

#### Scenario: 審查在任務完成後啟動

- **WHEN** `tasks.md` 中每個核取方塊皆為 `[x]`
- **THEN** `cash-apply` 啟動一個以 change 為單位的審查迴圈
- **AND** 它不會按 task 逐一啟動該迴圈

#### Scenario: Archive 指引跟隨通過的關卡

- **WHEN** apply 審查迴圈尚未記錄 `decision: passed`
- **THEN** `cash-apply` 不建議 archive
- **WHEN** apply 審查迴圈記錄了 `decision: passed`
- **THEN** 完成摘要可以引導使用者前往 `cash-archive`

#### Scenario: 設計斷路器

- **WHEN** 某個審查迴圈修正需要 `design.md` 未定義的同步原語、身分或世代型別、或狀態機
- **THEN** `cash-apply` 記錄 `needs-design`
- **AND** 記錄 `decision: aborted`
- **AND** 引導使用者前往 `cash-ingest`
- **AND** 不在修正迴圈內實作缺少的設計


<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---

### Requirement: 共用的評分審查收斂

cash 提案與 apply 關卡 SHALL 最多使用六輪。一次執行的第一輪 MUST 是由兩位全新獨立 reviewers 進行的 full 輪，第四輪在到達時 MUST 是 full checkpoint，其餘每個接續輪 MUST 是由一位全新 reviewer 進行的 micro 驗證輪。主 agent MUST 套用既定的信心過濾器，並從累積 blocking 集合推導決策，不使用 rater sub-agent 或 `quality_score`。

#### Scenario: Full 第一輪

- **WHEN** 一次新的審查執行開始
- **THEN** 它以兩個全新獨立呼叫產生負責 adherence 的 Reviewer A 與負責品質的 Reviewer B
- **AND** 記錄 `round_type: full`

#### Scenario: Micro 驗證輪

- **WHEN** 未通過的一輪之後接續一輪，且該輪的執行位置不是 4
- **THEN** 下一輪產生一位全新的 Reviewer V
- **AND** Reviewer V 驗證每個累積 blocking 成員、已記錄的修正，以及修正引入的缺陷
- **AND** 該輪記錄 `round_type: micro`

#### Scenario: Blocking 集合歸零

- **WHEN** 過濾後的累積 blocking 集合不含任何 Critical 成員也不含任何 Warning 成員
- **THEN** 該輪記錄 `decision: passed`
- **AND** 不再開始額外的一輪

#### Scenario: 六輪上限

- **WHEN** round 6 仍保有 blocking 成員
- **THEN** 該輪記錄 `decision: aborted`
- **AND** workflow 執行 abort triage
- **AND** 它不建議在未做任何變更下重跑


<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---

### Requirement: 審查紀錄使用 cash 來源標示

每個 cash 審查輪 SHALL 在 `openspec/changes/<change>/reviews/` 之下寫入一個不可變的 round 檔案。提案檔 MUST 使用 `propose-r<N>.md`；apply 檔 MUST 使用 `apply-r<N>.md`。回合標題與來源 skill 的 provenance MUST 標明 cash workflows，而穩定的 schema 欄位名稱與 decision 值保持不變。

#### Scenario: Cash 提案回合紀錄

- **WHEN** 一個 `cash-propose` 回合完成
- **THEN** 其標題為 `# Cash Propose Review — Round <N>`
- **AND** 它依此順序包含 `## Reviewer Findings`、`## Rating`、`## Fix Actions` 與 `## Decision`
- **AND** 其 decision 恰為 `passed`、`next_round` 或 `aborted`

#### Scenario: 共用 ledger

- **WHEN** 一個 cash 審查回合定案
- **THEN** 恰好一列被附加到 `reviews/loop-ledger.tsv`
- **AND** 該列保留七欄位 ledger 契約
- **AND** 來源 skill 記錄為 `propose` 或 `apply`


<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---

### Requirement: Cash 審查關卡保留受治理的輸入與 signals

Cash 審查關卡 SHALL 保留遷移前品質關卡基線中的 accepted-risks 同意機制、grader 不可變性、確定性 signal 檢查、信心過濾、修正傳播、abort triage 與 signals 寫入行為。自動化 fix actions MUST NOT 建立、修改或移除 signal 的 `check` 欄位。

#### Scenario: Signal 來源標示被正規化

- **WHEN** 符合條件的 Critical 或 Warning finding 被寫入 signal
- **THEN** 該 occurrence 標明 `cash-propose` 或 `cash-apply` 為其來源 skill
- **AND** signal 生命週期與 issue-class 比對規則保持不變

#### Scenario: 接受風險需要同意

- **WHEN** 某個 finding 被提議寫入 `accepted-risks.md`
- **THEN** 只有在目前 session 中取得使用者明確同意後才寫入該 ledger 條目
- **AND** 任何 fix action 都不會在未經同意下編輯該 ledger

#### Scenario: 受保護的 grader 輸入

- **WHEN** fix action 或 self-check 遇到 signal 的 `check` 欄位
- **THEN** 它將該欄位視為不可變的 grader 輸入
- **AND** 它不更動該欄位


<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---

### Requirement: Cash commit 保留 archive-first 允許清單機制

`cash-commit` SHALL 僅收集並提交屬於所選 change 的 artifacts 及其明確的追蹤檔案。當使用者選擇 archive-first 處理時，它 MUST 在 staging 之前先封存、收集封存輸出路徑、排除無關的 dirty 檔案，且 MUST NOT 將已刪除的生成式 plus skills 視為隱含的允許清單例外。

#### Scenario: Archive-first 提交排除無關變更

- **GIVEN** worktree 中含有與所選 change 無關的檔案
- **WHEN** 使用者在 `cash-commit` 中確認 archive-first 處理
- **THEN** `cash-commit` 在 staging 之前先封存所選 change
- **AND** 僅 stage 所選 change 的 artifacts、封存輸出與明確的追蹤檔案
- **AND** 讓無關的 dirty 檔案維持未 staged

#### Scenario: 沒有生成式 plus 刪除例外

- **WHEN** git status 中出現已刪除的 `spectra-*-plus` 路徑
- **THEN** `cash-commit` 不會自動將該路徑歸類為受保護的 change 輸出
- **AND** 由一般的所選 change 允許清單機制決定該路徑是否被 stage


<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---

### Requirement: 一次性的 legacy 修復清理

本 repository SHALL 提供 `uninstall-spectra-plus-repair.fish [--dry-run]`。一次成功的非 dry run MUST 卸載並移除已知的 `com.spectra.plus.repair` 與 `com.agentflow.spectra-plus.repair` LaunchAgents、移除其 plist 檔案、移除 `$HOME/.config/spectra-plus/projects.txt`，並移除 `$HOME/.cache/spectra-plus`。它 MUST 保留 `$HOME/Library/Logs/spectra-plus-repair.log`。

#### Scenario: 已安裝的自動化被移除

- **WHEN** 清理在一個或兩個已知 LaunchAgents 已安裝的情況下執行
- **THEN** 它在移除 legacy 修復 registry 之前，先印出該 registry 中找到的每個 target 路徑
- **AND** 它卸載每個已安裝的已知 label
- **AND** 移除對應的 plist
- **AND** 在卸載成功後移除修復 registry 與 cache
- **AND** 保留診斷 log

#### Scenario: 清理具冪等性

- **WHEN** 已知的 LaunchAgents、plists、registry 或 cache 皆不存在
- **THEN** 清理回報一次成功的 no-op
- **AND** 以 code 0 結束

#### Scenario: 非預期的卸載失敗使清理停止

- **GIVEN** 存在某個已知的 plist
- **WHEN** `launchctl bootout` 因 not-loaded 或 not-found 以外的原因失敗
- **THEN** 清理以非零結束
- **AND** 保留該失敗的 plist、registry 與 cache
- **AND** 將精確的手動清理指令印到 stderr

#### Scenario: Registry 讀取失敗在 launchctl 之前即停止

- **GIVEN** legacy registry 路徑存在，但不是可讀的一般檔案或無法被完整讀取
- **WHEN** 清理執行 preflight
- **THEN** 清理在呼叫 `launchctl` 之前以非零結束
- **AND** 保留 plist、registry、cache 與診斷 log

#### Scenario: 泛用的 not-found 文字不代表服務不存在

- **GIVEN** `launchctl print` 失敗且錯誤訊息含有 `not found`，但未精確指明所查詢的已知服務不存在
- **WHEN** 清理對該結果進行分類
- **THEN** 清理將其視為非預期失敗
- **AND** 保留所有可移除的 legacy 狀態

#### Scenario: 清理的 dry run

- **WHEN** 清理帶 `--dry-run` 執行
- **THEN** 它列出精確的卸載與移除動作
- **AND** 列出 legacy 修復 registry 中找到的每個 target 路徑
- **AND** 它不呼叫 `launchctl bootout`
- **AND** 它不移除任何檔案或目錄


<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---

### Requirement: cash-propose 品質關卡

系統 SHALL 提供一個 `cash-propose` skill，保留 proposal、design、specs 與 tasks 的完整 artifact 建立合約（proposal、design、specs、tasks），但以 sub-agent 審查／評分／修正迴圈取代行內自我審查與 analyze-fix 迴圈。該 skill MUST 在進入 sub-agent 迴圈之前執行 `.cash-skills/bin/cash validate`，使驗證修正發生在品質關卡審查最終 artifact 狀態之前。該 skill MUST 以 per-change 粒度執行迴圈（在所有必要 artifacts 寫入且驗證通過之後，而非逐 artifact）。該 skill MUST 將迴圈上限設為 6 輪。該 skill MUST NOT 使用 rater sub-agent 且 MUST NOT 產生 `quality_score`；主 agent SHALL 改為從過濾後的 findings 以機械方式推導該輪決策。當且僅當信心過濾後沒有任何存活 finding 具 `severity == Critical` 也沒有任何存活 finding 具 `severity == Warning` 時，該次執行的第一輪 MUST 被視為通過；在累積 blocking 集合已被 seed 的重跑中，第一輪改依 `分級收斂與 micro 驗證輪` requirement 使用累積 blocking 集合的通過條件。當且僅當信心過濾後累積 blocking 集合不含任何 `Critical` 也不含任何 `Warning` finding 時，該次執行第一輪之後的一輪 MUST 被視為通過，其中 blocking 與累積 blocking 集合由 `分級收斂與 micro 驗證輪` requirement 定義；非 blocking findings 依該 requirement 進入 triage。當某一輪的決策為 `next_round` 時，主 agent MUST 依 `分級收斂與 micro 驗證輪` requirement 推導下一輪的型別（full 或 micro）。本 requirement 中的修正義務受 `審查迴圈的 grader 不可變性` requirement 定義的 grader 保護例外，以及 `接受風險 ledger` 與 `審查輪的行動義務` requirements 定義的經同意接受風險路徑所約束。該 skill MUST NOT 在其 workflow 結尾執行 `.cash-skills/bin/cash park`。

#### Scenario: 迴圈在達到輪數上限前滿足通過條件

- **WHEN** 某一輪完成時，信心過濾後的累積 blocking 集合為空
- **THEN** 該 skill 寫入對應的 round 檔案並記錄 `decision: passed`
- **AND** 停止迴圈且不再開始另一輪
- **AND** 直接進入最終摘要，不執行關卡後的驗證修正
- **AND** 不執行 `.cash-skills/bin/cash park`

#### Scenario: 驗證先於品質關卡

- **WHEN** `cash-propose` 已建立 apply 所需的全部 artifacts
- **THEN** 它執行 `.cash-skills/bin/cash validate "<name>"`
- **AND** 在第一個審查迴圈輪之前修正驗證錯誤
- **AND** 審查迴圈僅在驗證通過後才開始

- **WHEN** 審查迴圈的 Fix Action 修改了 proposal、design、tasks 或 spec artifacts
- **THEN** 它再次執行 `.cash-skills/bin/cash validate "<name>"`
- **AND** 在開始下一個審查迴圈輪之前修正驗證錯誤

#### Scenario: 存活的 blocking Warning 迫使再進行一輪

- **WHEN** 某一輪完成時，信心過濾後的累積 blocking 集合中沒有 blocking `Critical` finding，但至少有一個 blocking `Warning` finding
- **THEN** 該 skill 寫入 round 檔案並記錄 `decision: next_round`
- **AND** 在開始下一輪之前修正這些 blocking Warning findings，但下列除外：依 `審查迴圈的 grader 不可變性` requirement 被保留不修的 finding（記錄為 unfixed-due-to-grader-protection 且維持存活），以及經 `接受風險 ledger` requirement 同意路徑接受的 finding（記錄為 downgrade trace 並自累積 blocking 集合移除）
- **AND** 依 `分級收斂與 micro 驗證輪` requirement 推導下一輪的型別

#### Scenario: 迴圈到達 6 輪上限仍未通過

- **WHEN** 迴圈完成 6 輪仍未滿足通過條件
- **THEN** 該 skill 寫入第六輪並記錄 `decision: aborted`
- **AND** 印出摘要說明未解決 findings 的警告
- **AND** 依 `Abort 後的 triage` requirement 執行 abort triage
- **AND** 結束 workflow 而不 park 該 change

#### Scenario: 永不呼叫 park

- **WHEN** `cash-propose` 在任何結果下結束其 workflow
- **THEN** 該 workflow 永不呼叫 `.cash-skills/bin/cash park`
- **AND** change 目錄仍保留在 `openspec/changes/` 之下（未被 park）

##### Example: workflow 結尾路徑比較

| Skill | 行內自我審查 | Analyze-fix 迴圈 | Sub-agent 迴圈（上限 6） | 結尾 park |
| ----- | ------------------ | ---------------- | ---------------------- | ----------- |
| Legacy baseline（已移除） | 是 | 是（上限 2）  | 否  | 是 |
| cash-propose  | 否  | 否           | 是 | 否  |

<!-- @trace
source: replace-spectra-cli-with-cash-cli
updated: 2026-07-24
code:
  - .agents/skills/
  - .agents/skills/spectra-analyze/
  - .agents/skills/spectra-apply/
  - .agents/skills/spectra-archive/
  - .agents/skills/spectra-ask/
  - .agents/skills/spectra-audit/
  - .agents/skills/spectra-commit/
  - .agents/skills/spectra-debug/
  - .agents/skills/spectra-discuss/
  - .agents/skills/spectra-drift/
  - .agents/skills/spectra-ingest/
  - .agents/skills/spectra-propose/
  - .agents/skills/spectra-verify/
  - .cash-skills/bin/cash
  - .cash-skills/lib/cash_cli/
  - .cash-skills/receipt.tsv
  - .cash-skills/state/
  - .cash-skills/state/snapshots/
  - .cash-skills/state/touched/
  - .claude/skills/
  - .claude/skills/spectra-analyze/
  - .claude/skills/spectra-apply/
  - .claude/skills/spectra-archive/
  - .claude/skills/spectra-ask/
  - .claude/skills/spectra-audit/
  - .claude/skills/spectra-commit/
  - .claude/skills/spectra-debug/
  - .claude/skills/spectra-discuss/
  - .claude/skills/spectra-drift/
  - .claude/skills/spectra-ingest/
  - .claude/skills/spectra-propose/
  - .claude/skills/spectra-verify/
  - .spectra/
  - scripts/cash-cli/fixtures/
  - scripts/cash-cli/tests/
  - scripts/cash-skills/legacy-spectra-digests.tsv
  - scripts/cash-skills/tests/skill-checks.fish
tests:
-->

### Requirement: cash-apply 品質關卡

系統 SHALL 提供一個 `cash-apply` skill，保留完整的任務執行合約，並在所有 tasks 完成後附加一個 sub-agent 審查／評分／修正迴圈。該 skill MUST 以 per-change 粒度執行迴圈（僅一次，在 `tasks.md` 中每個 task 都標記完成之後）。該 skill MUST 將迴圈上限設為 6 輪。該 skill MUST NOT 在審查迴圈以 `decision: passed` 結束之前建議封存該 change。該 skill MUST NOT 使用 rater sub-agent 且 MUST NOT 產生 `quality_score`；主 agent SHALL 改為從過濾後的 findings 以機械方式推導該輪決策。當且僅當信心過濾後沒有任何存活 finding 具 `severity == Critical` 也沒有任何存活 finding 具 `severity == Warning` 時，該次執行的第一輪 MUST 被視為通過；在累積 blocking 集合已被 seed 的重跑中，第一輪改依 `分級收斂與 micro 驗證輪` requirement 使用累積 blocking 集合的通過條件。當且僅當信心過濾後累積 blocking 集合不含任何 `Critical` 也不含任何 `Warning` finding 時，該次執行第一輪之後的一輪 MUST 被視為通過，其中 blocking 與累積 blocking 集合由 `分級收斂與 micro 驗證輪` requirement 定義；非 blocking findings 依該 requirement 進入 triage。當某一輪的決策為 `next_round` 時，主 agent MUST 依 `分級收斂與 micro 驗證輪` requirement 推導下一輪的型別（full 或 micro）。本 requirement 中的修正義務受 `審查迴圈的 grader 不可變性` requirement 定義的 grader 保護例外，以及 `接受風險 ledger` 與 `審查輪的行動義務` requirements 定義的經同意接受風險路徑所約束。

#### Scenario: 審查迴圈在 tasks 完成後執行

- **WHEN** `tasks.md` 中的每個 checkbox 皆為 `[x]`
- **THEN** `cash-apply` 開始 sub-agent 審查／評分／修正迴圈
- **AND** 不會更早開始該迴圈

#### Scenario: 存活的 blocking Critical 迫使再進行一輪

- **WHEN** 某一輪完成時，信心過濾後的累積 blocking 集合中至少有一個 blocking `Critical` finding
- **THEN** 該 skill 寫入 round 檔案並記錄 `decision: next_round`
- **AND** 在開始下一輪之前修正這些 blocking Critical findings，但下列除外：依 `審查迴圈的 grader 不可變性` requirement 被保留不修的 finding（記錄為 unfixed-due-to-grader-protection 且維持存活），以及經 `接受風險 ledger` requirement 同意路徑接受的 finding（記錄為 downgrade trace 並自累積 blocking 集合移除）
- **AND** 依 `分級收斂與 micro 驗證輪` requirement 推導下一輪的型別

#### Scenario: 迴圈到達 6 輪上限

- **WHEN** 迴圈完成 6 輪仍未滿足通過條件
- **THEN** 該 skill 寫入第六輪並記錄 `decision: aborted`
- **AND** 印出摘要說明未解決 findings 的警告
- **AND** 依 `Abort 後的 triage` requirement 執行 abort triage
- **AND** 結束 workflow

#### Scenario: 封存指引等待關卡通過

- **WHEN** 所有 tasks 已完成但審查迴圈尚未通過
- **THEN** `cash-apply` 說明封存指引將延後至 cash 品質關卡通過之後
- **AND** 不指示使用者執行 `.cash-skills/bin/cash archive`、`/cash-archive` 或 `$cash-archive`

- **WHEN** 最終審查迴圈輪為 `decision: passed`
- **THEN** 最終回覆可以建議封存該 change

<!-- @trace
source: replace-spectra-cli-with-cash-cli
updated: 2026-07-24
code:
  - .agents/skills/
  - .agents/skills/spectra-analyze/
  - .agents/skills/spectra-apply/
  - .agents/skills/spectra-archive/
  - .agents/skills/spectra-ask/
  - .agents/skills/spectra-audit/
  - .agents/skills/spectra-commit/
  - .agents/skills/spectra-debug/
  - .agents/skills/spectra-discuss/
  - .agents/skills/spectra-drift/
  - .agents/skills/spectra-ingest/
  - .agents/skills/spectra-propose/
  - .agents/skills/spectra-verify/
  - .cash-skills/bin/cash
  - .cash-skills/lib/cash_cli/
  - .cash-skills/receipt.tsv
  - .cash-skills/state/
  - .cash-skills/state/snapshots/
  - .cash-skills/state/touched/
  - .claude/skills/
  - .claude/skills/spectra-analyze/
  - .claude/skills/spectra-apply/
  - .claude/skills/spectra-archive/
  - .claude/skills/spectra-ask/
  - .claude/skills/spectra-audit/
  - .claude/skills/spectra-commit/
  - .claude/skills/spectra-debug/
  - .claude/skills/spectra-discuss/
  - .claude/skills/spectra-drift/
  - .claude/skills/spectra-ingest/
  - .claude/skills/spectra-propose/
  - .claude/skills/spectra-verify/
  - .spectra/
  - scripts/cash-cli/fixtures/
  - scripts/cash-cli/tests/
  - scripts/cash-skills/legacy-spectra-digests.tsv
  - scripts/cash-skills/tests/skill-checks.fish
tests:
-->

### Requirement: Round 檔案輸出合約

系統 SHALL 為每個迴圈輪在 `openspec/changes/<change>/reviews/` 寫入一個 round 檔案。檔名 MUST 遵循 `cash-propose` 使用 `propose-r<N>.md`、`cash-apply` 使用 `apply-r<N>.md` 的模式，其中 `<N>` 是以 1 起算的輪次編號；abort 之後的重跑依 `Abort 後的 triage` requirement 由最後一個既有 round 檔案接續 `<N>`。每個 round 檔案 MUST 恰好包含四個頂層 `##` 區段，依此固定順序：`## Reviewer Findings`、`## Rating`、`## Fix Actions`、`## Decision`，另加檔案頂端的回合標題。`## Rating` 區段 MUST NOT 含有 `quality_score` 欄位；它 MUST 記錄過濾後累積 blocking 集合的 `Critical` 計數與 `Warning` 計數（在該次執行的第一輪，為存活 findings 的計數，此時它們全部皆為 blocking；在已 seed 重跑的第一輪，為累積 blocking 集合的計數）、非 blocking 已 triage findings 的計數、`critical_gap`（boolean）、`round_type`（恰為 `full` 或 `micro` 之一），以及一段說明機械決策的理由。

#### Scenario: Round 檔案結構

- **WHEN** 任一 cash skill 的任一輪完成
- **THEN** 存在位於 `openspec/changes/<change>/reviews/<skill>-r<N>.md` 的檔案
- **AND** 該檔案以標明 skill 與輪次的 level-1 標題開頭
- **AND** 該檔案恰好包含四個 `##` 標題：`Reviewer Findings`、`Rating`、`Fix Actions`、`Decision`，且開頭的回合摘要標題是 `#` 而非 `##`

#### Scenario: Rating 區段省略 quality_score

- **WHEN** 寫入任一 round 檔案的 `## Rating` 區段
- **THEN** 其中不含 `quality_score` 欄位
- **AND** 它記錄累積 blocking 集合的 `Critical` 計數、累積 blocking 集合的 `Warning` 計數、非 blocking 已 triage 計數、`critical_gap`、`round_type`，以及一段理由說明

##### Example: 必要的 round 檔案大綱

| Section                | 標題層級      | Content                                                                                                            |
| ---------------------- | ------------- | ------------------------------------------------------------------------------------------------------------------ |
| 回合標題               | `#`           | 例如 `Cash Propose Review — Round 2`                                                                               |
| `Reviewer Findings`    | `##`          | 三個子區段：Critical、Warning、Suggestion。每個 finding 列出 `severity`、`confidence`、`layer`、`location`、`summary`、`recommendation`、`disposition`（第一輪之後的各輪，以及已 seed 重跑的第一輪）、`introduced_by`（cash-apply Reviewer B 的 findings，以及任何被標記為 `fix-introduced` 的 finding），與 reviewer 來源（`A`、`B`、`A+B` 或 `V`） |
| `Rating`               | `##`          | 累積 blocking `Critical` 計數、累積 blocking `Warning` 計數、非 blocking 已 triage 計數、`critical_gap`（boolean）、`round_type`（`full` 或 `micro`）、`rationale`（文字） |
| `Fix Actions`          | `##`          | 本輪所做變更的清單，附檔案路徑與理由，另加 triage 註記、downgrade traces 與 disposition 更正紀錄 |
| `Decision`             | `##`          | `passed`、`next_round`、`aborted` 三者之一                                                                         |

#### Scenario: 最終輪的 decision 值

- **WHEN** 迴圈成功結束
- **THEN** 最終 round 檔案為 `Decision: passed`

- **WHEN** 迴圈因到達 6 輪上限而結束
- **THEN** 最終 round 檔案為 `Decision: aborted`




<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---

### Requirement: 每輪使用全新 sub-agent

系統 SHALL 為每個審查步驟產生全新的 sub-agents。該 skill MUST NOT 跨輪重複使用 sub-agent。每個 full 輪 MUST 恰好平行產生兩位 reviewer sub-agents——`Reviewer A`（artifact／實作遵循度）與 `Reviewer B`（bug／品質掃描）。每個 micro 輪 MUST 依 `分級收斂與 micro 驗證輪` requirement 恰好產生一位全新的驗證 reviewer sub-agent——`Reviewer V`（差異驗證）。該 skill MUST NOT 產生 rater sub-agent。該 skill MUST NOT 在主 agent 情境中以行內方式執行審查。依 `Abort 後的 triage` requirement 在產生前即短路的 abort 輪會記錄 `round_type: full` 但不產生任何 reviewer sub-agents；它是雙 reviewer 強制規定的明確例外。在該輪的 reviewer sub-agents 完成後，主 agent SHALL 彙整 findings（以 `location + summary` 去重）、套用信心過濾器（見 `具信心分數的 findings 與過濾器` requirement），並在不再進行任何 sub-agent 呼叫的情況下以機械方式推導該輪決策——在該次執行的第一輪從過濾後的 findings（或在已 seed 重跑的第一輪，從累積 blocking 集合），在其後每一輪則從 `分級收斂與 micro 驗證輪` requirement 定義的累積 blocking 集合。

#### Scenario: 每輪兩位 reviewers 且沒有 rater

- **WHEN** 一個 full 輪開始
- **THEN** 該 skill 以單一訊息派發，對 `Reviewer A` 與 `Reviewer B` 進行兩個平行 sub-agent 呼叫
- **AND** 不進行任何 rater sub-agent 呼叫
- **AND** Reviewer A 與 Reviewer B 看不到彼此的 findings
- **AND** 主 agent 自行從過濾後的 findings 與累積 blocking 集合推導 `decision`

#### Scenario: Micro 輪恰好產生一位驗證 reviewer

- **WHEN** 一個 micro 輪開始
- **THEN** 該 skill 恰好進行一次 `Reviewer V` 的 sub-agent 呼叫
- **AND** 該輪不進行任何 `Reviewer A`、`Reviewer B` 或 rater 的 sub-agent 呼叫
- **AND** 主 agent 自行從過濾後的 findings 與累積 blocking 集合推導 `decision`

#### Scenario: 不跨輪重複使用 sub-agent

- **WHEN** 第 N 輪之後第 N+1 輪開始
- **THEN** 該 skill 為第 N+1 輪產生全新的 reviewer sub-agents（full 輪為 `Reviewer A` 與 `Reviewer B`，micro 輪為 `Reviewer V`）
- **AND** 不把前一輪的 sub-agent 狀態往後傳遞




<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---

### Requirement: 具信心分數的 findings 與過濾器

系統 SHALL 要求每個 reviewer finding 帶有 `0` 到 `100` 的 `confidence` 整數。主 agent MUST 在推導該輪決策之前套用信心過濾器。`confidence < 50` 的 findings MUST 被完全捨棄，且 SHALL NOT 出現在 round 檔案的 `## Reviewer Findings` 區段；由 `接受風險 ledger` 與 `cash-apply 的 introduced-by 證據` requirements 強制要求的 downgrade traces 出現在 `## Fix Actions`，是明確的例外。`confidence` 落在 `[50, 80)` 的 findings MUST 被降級為 `Suggestion`，無論 reviewer 原本的嚴重度分類為何。只有 `confidence >= 80` 的 findings MAY 在過濾後的 round 檔案中以 `Critical` 或 `Warning` 出現。當且僅當過濾後的累積 blocking 集合至少含有一個 `Critical` finding 時（在該次執行的第一輪，為至少一個 `confidence >= 80` 的存活 `Critical` finding；已 seed 重跑的第一輪使用累積 blocking 集合），`critical_gap` MUST 為 `true`。直接違反 artifact requirement 的 findings（引用特定 `SHALL`、Implementation Contract 項目或 task 描述行者）MUST 給 `100` 分，使過濾器不會將其降級。`接受風險 ledger` requirement 定義的接受風險降級，與 `cash-apply 的 introduced-by 證據` requirement 定義的 cash-apply `introduced_by` 降級，優先於 100 分不變量：符合某個 accepted-risks 項目的 finding，或沒有可驗證 `introduced_by` 的 cash-apply `Reviewer B` `Critical` 或 `Warning` finding，即使引用了特定 artifact 條文，也 MUST 至多給 `25` 分。

#### Scenario: 過濾器捨棄低信心 findings

- **WHEN** reviewer 回報一個 `confidence == 30` 的 finding
- **THEN** 該 finding 不出現在 round 檔案中
- **AND** 它不參與該輪決策

#### Scenario: 過濾器將中等信心的 Critical 降級為 Suggestion

- **WHEN** reviewer 回報一個 `confidence == 60` 的 `Critical` finding
- **THEN** round 檔案將它列在 `Suggestion` 之下，而非 `Critical`
- **AND** `critical_gap` 不會僅因這個 finding 而被設為 `true`

#### Scenario: 引用 artifact 的 findings 不被降級

- **WHEN** reviewer 引用 artifact 集合或實作未滿足的 `spec.md` 特定 `SHALL` 條文或 `design.md` 合約項目
- **THEN** 該 reviewer 給該 finding `confidence == 100`
- **AND** 該 finding 通過過濾器並可被分類為 `Critical`

#### Scenario: 符合已接受風險凌駕 100 分不變量

- **WHEN** 一個 finding 引用特定 artifact 條文 AND 在相同位置以相同缺陷機制符合某個 accepted-risks 項目
- **THEN** 主 agent 給該 finding 至多 `25` 分
- **AND** 該 finding 不以 `Critical` 或 `Warning` 存活




<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---

### Requirement: Sub-agent 失敗處理

系統 SHALL 在同一輪內對失敗的 sub-agent 呼叫重試一次。若重試也失敗，該 skill MUST 以清楚的錯誤中止整個 cash workflow，且 SHALL NOT 將該輪標記為 `passed` 或繼續進入下一輪。若兩位平行 reviewers 在同一輪內都失敗，該 skill MUST 將其視為單一 reviewer 角色失敗（重試一次），而非兩次個別失敗。

#### Scenario: 單一 sub-agent 失敗可恢復

- **WHEN** 某位 reviewer sub-agent 失敗（無回應或輸出格式錯誤）
- **THEN** 該 skill 以全新呼叫對同一 reviewer 角色重試一次
- **AND** 若重試成功，該輪繼續進行

#### Scenario: 連續兩次 sub-agent 失敗即中止

- **WHEN** 同一 sub-agent 角色在單一輪內失敗兩次
- **THEN** 該 skill 中止 cash workflow
- **AND** 寫入一個含 `decision: aborted` 與失敗描述註記的 round 檔案

#### Scenario: 兩位平行 reviewers 同時失敗計為一次角色失敗

- **WHEN** `Reviewer A` 與 `Reviewer B` 在同一輪內都失敗
- **THEN** 該 skill 將其視為單一 reviewer 角色失敗
- **AND** 對該 reviewer 角色重試一次（兩位 reviewers 平行重新派發）
- **AND** 僅在重試也失敗時才中止




<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---

### Requirement: cash-commit 的 archive-first 允許清單

系統 SHALL 使 `cash-commit` 在 `.cash-skills/bin/cash archive` 完成後，透過明確的允許清單收集 archive-first 提交檔案。archive-first 提交集合 MUST 包含封存前已確認提交集合中的 tracked 來源檔案、屬於所選 change 封存的檔案，以及使用者在封存子流程中明確選擇 spec sync 時來自 `openspec/specs/` 的 spec sync 檔案。archive-first 提交集合 MUST NOT 包含封存後 `git status --porcelain` 掃描發現的無關 dirty 檔案。

#### Scenario: archive-first 提交前已存在無關刪除

- **WHEN** `cash-commit` 在啟用 archive-first 下提交 change `demo-change`
- **AND** 在 `.cash-skills/bin/cash archive demo-change` 執行之前，`git status --porcelain` 已含有 `D .agents/skills/cash-apply/SKILL.md`
- **THEN** 預設提交集合排除 `.agents/skills/cash-apply/SKILL.md`
- **AND** 提交計畫將該刪除顯示在被納入的封存相關檔案之外

#### Scenario: 封存成功後納入封存檔案

- **WHEN** `.cash-skills/bin/cash archive demo-change` 將檔案從 `openspec/changes/demo-change/` 移至 `openspec/changes/archive/2026-05-19-demo-change/`
- **THEN** `cash-commit` 納入 `openspec/changes/demo-change/` 之下的刪除
- **AND** `cash-commit` 納入 `openspec/changes/archive/2026-05-19-demo-change/` 之下的新增或修改
- **AND** `cash-commit` 排除所選 change 封存、tracked 來源檔案與明確選擇的 spec sync 檔案以外的 dirty 檔案

#### Scenario: spec sync 檔案需要明確的 sync 選擇

- **WHEN** 使用者在 `demo-change` 的封存子流程中選擇 spec sync
- **THEN** `cash-commit` 納入 `openspec/specs/` 之下的相應變更
- **AND** 更新後的提交計畫將它們顯示為 Spec Sync Changes

#### Scenario: 封存路徑措辭為現行版本

- **WHEN** `cash-commit` 顯示更新後的 archive-first 提交計畫
- **THEN** 封存檔案區段標明 `openspec/changes/archive/<date>-<change>/`
- **AND** archive-first workflow 文字不提及 `openspec/archived/`

<!-- @trace
source: replace-spectra-cli-with-cash-cli
updated: 2026-07-24
code:
  - .agents/skills/
  - .agents/skills/spectra-analyze/
  - .agents/skills/spectra-apply/
  - .agents/skills/spectra-archive/
  - .agents/skills/spectra-ask/
  - .agents/skills/spectra-audit/
  - .agents/skills/spectra-commit/
  - .agents/skills/spectra-debug/
  - .agents/skills/spectra-discuss/
  - .agents/skills/spectra-drift/
  - .agents/skills/spectra-ingest/
  - .agents/skills/spectra-propose/
  - .agents/skills/spectra-verify/
  - .cash-skills/bin/cash
  - .cash-skills/lib/cash_cli/
  - .cash-skills/receipt.tsv
  - .cash-skills/state/
  - .cash-skills/state/snapshots/
  - .cash-skills/state/touched/
  - .claude/skills/
  - .claude/skills/spectra-analyze/
  - .claude/skills/spectra-apply/
  - .claude/skills/spectra-archive/
  - .claude/skills/spectra-ask/
  - .claude/skills/spectra-audit/
  - .claude/skills/spectra-commit/
  - .claude/skills/spectra-debug/
  - .claude/skills/spectra-discuss/
  - .claude/skills/spectra-drift/
  - .claude/skills/spectra-ingest/
  - .claude/skills/spectra-propose/
  - .claude/skills/spectra-verify/
  - .spectra/
  - scripts/cash-cli/fixtures/
  - scripts/cash-cli/tests/
  - scripts/cash-skills/legacy-spectra-digests.tsv
  - scripts/cash-skills/tests/skill-checks.fish
tests:
-->

### Requirement: Cash 審查迴圈在迴圈結束後寫入 signals

canonical 的 `cash-propose` 與 `cash-apply` skill 檔案 SHALL 各自包含一個受治理的 signal 寫入步驟，以唯一的 sentinel 註解 `<!-- SIGNALS-WRITE-STEP -->` 標記。在審查迴圈結束後（round 檔案的 `decision` 為 `passed` 或 `aborted`），主 agent 為迴圈揭露的過濾後 findings 寫入 signals。此步驟 MUST 僅在迴圈的機械決策已被記錄之後執行、MUST NOT 更改任何 round 檔案的 `decision`，且 MUST 同時適用於 Claude 與 Codex 兩個變體。

寫入目標集合 SHALL 是在當前 change 迴圈的任一單輪中，以 `Critical` 或 `Warning` 通過信心過濾器存活的每個 finding，並依 issue class 去重，使每個 class 只被處理一次。此步驟 MUST 涵蓋任一輪的 findings，而不僅是最終輪，使得在一個整體通過的迴圈中於早期輪被抓到並修正的 finding 仍會產生 signal。被分類為 `Suggestion` 的 findings，以及任何 `confidence < 80` 的 finding，MUST NOT 產生 signal。對每個去重後的 finding class，主 agent SHALL 讀取 `openspec/signals/` 之下的既有 signals，並依此準則判斷 issue class 是否相符：當一個 finding 與既有 signal 共享相同的能力或領域 AND 指向相同的底層規則或反模式時即為相符；僅自由文字措辭不同不構成不同的 class，但根本原因不同則構成。當該 finding 符合既有的 `open` signal 時，主 agent MUST 重用該 signal 的 slug 並就地更新——遞增 `occurrences`、更新 `last_seen`、附加一筆 `## Occurrences` 項目，並將來源 round 檔案路徑附加到 `links`——且不更改其 `status`。當沒有任何 `open` signal 相符時（包括只有 `addressed` 或 `dismissed` signal 相符的情況），主 agent MUST 建立一個 `status: open` 且 `occurrences: 1` 的新 signal。在鑄造新的 `<slug>` 之前，主 agent MUST 列出既有的 `openspec/signals/*.md` 檔案，並選擇一個尚不存在的 `<slug>`（當自然 slug 已被占用時以後綴消歧）。建立新 signal MUST NOT 覆寫任何既有的 signal 檔案，且 MUST NOT 更改任何既有 signal 由人工維護的 `status`。當不確定某個 finding 是否符合既有 signal 時，主 agent MUST 偏好建立新 signal 而非併入既有者。

#### Scenario: 鑄造的 slug 不覆寫無關的既有 signal

- **WHEN** 主 agent 為新 signal 鑄造 `<slug>`，而該 slug 的檔案已存在且屬於不同（不相符）的 issue class
- **THEN** 主 agent 改選一個尚未使用的不同 `<slug>`
- **AND** 既有的 signal 檔案不被覆寫

#### Scenario: 早期輪已修正的 finding 在通過的迴圈中仍建立 signal

- **WHEN** 一個 `Warning` finding 在 round 1 通過信心過濾器存活、被修正，且迴圈之後在最終輪沒有存活的 `Critical` 或 `Warning` 而通過
- **AND** 沒有既有的 `open` signal 符合其 issue class
- **THEN** 迴圈結束後，主 agent 以指派的 `<slug>` 建立一個 `status: open` 且 `occurrences: 1` 的 signal
- **AND** 此步驟不更動 round 檔案的 `decision`

#### Scenario: 符合既有 open signal 的 finding 就地更新該 signal

- **WHEN** 一個過濾後的 `Critical` 或 `Warning` finding 依準則符合既有 `open` signal 的 issue class
- **THEN** 主 agent 重用該 signal 的 slug、遞增其 `occurrences`、更新 `last_seen`、附加一筆 `## Occurrences` 項目，並將 round 檔案路徑附加到 `links`
- **AND** 主 agent 不更改該 signal 的 `status`

#### Scenario: 已處理議題的復發不覆寫已解決狀態

- **WHEN** 過濾後的 finding 僅符合 `addressed` 或 `dismissed` signal 的 issue class
- **THEN** 主 agent 以另外指派的 `<slug>` 建立 `status: open` 的新 signal
- **AND** 主 agent 不更改所符合之已解決 signal 的 `status`

#### Scenario: Suggestion 與低信心 findings 不產生 signal

- **WHEN** 一個 finding 被分類為 `Suggestion`，或任何 finding 在過濾後 `confidence < 80`
- **THEN** 主 agent 不為它建立或更新任何 signal

#### Scenario: Signal 寫入失敗不使 cash workflow 失敗

- **WHEN** 在 `openspec/signals/` 之下寫入 signal 失敗
- **THEN** 主 agent 印出警告
- **AND** cash workflow 不單獨因該 signal 寫入失敗而失敗




<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---

### Requirement: cash-propose 讀取 open signals 以決定優先序

canonical 的 Claude 與 Codex `cash-propose` skill 檔案 SHALL 在既有的「Scan existing specs for relevance」步驟之後讀取 `openspec/signals/` 之下的 `open` signals。該讀取步驟 MUST 以唯一的 sentinel 註解 `<!-- SIGNALS-READ-STEP -->` 標記。該讀取 MUST 是資訊性的：skill SHALL 將相關的 `open` signals 呈現為優先序摘要、MUST NOT 阻擋 workflow、MUST NOT 要求使用者確認，且 MUST NOT 修改任何 signal。當 `openspec/signals/` 不存在或不含任何 `open` signal 時，skill MUST 靜默地繼續。此讀取行為 MUST NOT 加入 `cash-apply`。

#### Scenario: cash-propose 期間呈現相關的 open signals

- **WHEN** `cash-propose` 執行且 `openspec/signals/` 含有與需求相關的 `open` signals
- **THEN** 該 skill 在 spec 掃描步驟後將那些 signals 顯示為資訊性的優先序摘要
- **AND** 該 skill 不修改任何 signal
- **AND** 該 skill 不要求使用者確認即可繼續

#### Scenario: 沒有 open signals 時靜默繼續

- **WHEN** `cash-propose` 執行且 `openspec/signals/` 不存在或沒有任何 `open` signal
- **THEN** 該 skill 繼續執行且不呈現 signals 摘要

#### Scenario: cash-apply 不獲得讀取步驟

- **WHEN** 檢查 canonical 的 `.claude/skills/cash-apply/SKILL.md` 與 `.agents/skills/cash-apply/SKILL.md` 檔案
- **THEN** cash-apply skill 檔案不含 `<!-- SIGNALS-READ-STEP -->` sentinel
- **AND** cash-apply skill 檔案在其受治理的 signal 寫入區段中確實含有 `<!-- SIGNALS-WRITE-STEP -->` sentinel

#### Scenario: cash-propose 同時包含讀取與寫入步驟

- **WHEN** 檢查 canonical 的 `.claude/skills/cash-propose/SKILL.md` 與 `.agents/skills/cash-propose/SKILL.md` 檔案
- **THEN** 兩個 cash-propose skill 檔案皆含有 `<!-- SIGNALS-READ-STEP -->` 與 `<!-- SIGNALS-WRITE-STEP -->` sentinels
- **AND** 兩個檔案皆不帶有生成輸出中繼資料或 do-not-edit 標記



<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---

### Requirement: 分級收斂與 micro 驗證輪

系統 SHALL 依 finding 的 layer 為審查迴圈收斂分級。每個 reviewer finding MUST 帶有 `layer` 欄位，其值恰為 `design` 或 `text` 之一。一個 finding MUST 僅在下列情況才被分類為 `text`：它涉及跨 artifact 一致性（計數、識別字拼寫、措辭或章節同步）AND 修正它不會改變任何設計決策或行為敘述；其他每個 finding MUST 被分類為 `design`。當 reviewer 無法在兩個值之間決定時，它 MUST 將該 finding 分類為 `design`。在套用信心過濾器時，主 agent MUST 重新檢查每個被分類為 `text` 的 finding，且當修正可能觸及行為或設計敘述時 MUST 將其重新分類為 `design`；主 agent MUST NOT 將 `design` finding 重新分類為 `text`。當 full 輪的 reviewers 各自獨立提出同一 finding（以 `location + summary` 去重）但 `layer` 值不同時，合併後的 finding MUST 取 `layer == design`。`layer` 欄位 MUST NOT 參與輪型別推導。

迴圈 SHALL 執行兩種輪型別：full 輪與 micro 輪（差異驗證輪）。一次迴圈執行的第一輪 MUST 是 full 輪。當某一輪的決策為 `next_round` 時，主 agent MUST 僅從下一輪在當前迴圈執行中的位置以機械方式推導其型別：當且僅當下一輪是本次執行的第四輪時，它才是 full 輪；否則下一輪是 micro 輪。連續的 micro 輪是有效的。修改行為的修正動作 MUST NOT 使下一輪的型別升級；第四輪 checkpoint 是本次執行第一輪之後唯一的完整重新掃描。micro 輪 MUST 計入 6 輪上限，且 MUST 如同其他輪一樣產生 round 檔案。

除了未 seed 執行的第一輪之外，一輪中的每位 reviewer（micro 輪中的 Reviewer V；第四輪 checkpoint 或已 seed 重跑第一輪中的 Reviewer A 與 Reviewer B）MUST 為每個 `Critical` 或 `Warning` finding 標上 `disposition` 欄位，其值恰為下列之一：`unresolved-prior`——該 finding 符合本迴圈先前某輪的 blocking finding（或在重跑中，符合依 `Abort 後的 triage` requirement 自前次執行帶入的 bucket-1 finding），無論是否曾為其記錄修正：再次被回報本身就是任何已記錄修正未解決它的證據；`fix-introduced`——該 finding 經由 finding 中攜帶的明確 fix-action 參照，被歸因於本迴圈（或在已 seed 重跑中，前次執行）`## Fix Actions` 區段所記錄的一項或多項修改；這些輪的每位 reviewer——包括 Reviewer V 與 cash-propose 的 reviewers——在標記 `fix-introduced` 時 MUST 附上該參照；或 `new`——該 finding 不符合任何先前的 blocking finding；僅符合先前非 blocking triage 註記的 finding 也標為 `new` 並維持非 blocking，不產生重複的 triage 註記或 signal；其依 `審查輪的行動義務` requirement 記錄的動作是一行指名原輪 triage 註記的交叉參照註記，該註記既不是重複的 triage 註記也不是新的 signal。disposition 比對以相同 artifact 或檔案加上相同缺陷機制運作；記錄的行號範圍僅供參考，範圍位移不會破壞比對。為了讓 dispositions 可被評估，主 agent MUST 在本次執行第一輪之後每一輪的 reviewer 情境中，提供本迴圈每個先前的 round 檔案（在已 seed 重跑中，包括前次執行的 round 檔案或其摘錄）AND 當前累積 blocking 集合成員清單；當累積的 round 檔案超出實際可用的情境大小時，主 agent MUST 改為提供每輪摘錄，內含各輪的存活 findings 與完整的 `## Fix Actions` 內容，且 MUST 在當前輪的 `## Fix Actions` 記錄一行註記，指名以摘錄提供的輪次。主 agent MUST 對照先前的 round 檔案驗證每個 disposition 標記，且 MUST 更正不成立的標記；對每個標為 `new` 的 finding，主 agent MUST 額外檢查其位置是否曾被本迴圈——以及在已 seed 重跑中，前次執行——記錄的修正動作修改過，且當缺陷源自那些修改時，將標記更正為 `fix-introduced` 並在更正紀錄中提供 fix-action 參照；每次更正 MUST 記錄在該輪檔案的 `## Fix Actions` 中，指名該 finding、reviewer 的原始標記、更正後的標記與證據，且每次將 blocking disposition 改為非 blocking 的更正 MUST 列在完成輸出中。當以 `location + summary` 去重的 findings 帶有分歧的 `disposition` 值時，合併後的 finding MUST 取 blocking 的 disposition（`unresolved-prior` 或 `fix-introduced` 勝過 `new`）。已完成輪的 round 檔案在進行中的迴圈期間不可變：修正紀錄與 triage 註記 MUST 只寫在其發生的那一輪，且主 agent MUST NOT 回頭編輯先前的 round 檔案。

當且僅當一個存活的 `Critical` 或 `Warning` finding 經驗證的 disposition 為 `unresolved-prior` 或 `fix-introduced` 時，它才是 blocking。在本迴圈中最近一次先前狀態為非 blocking triage 註記的 finding 維持非 blocking，且 MUST NOT 重新進入 blocking 集合，僅有一個例外：當後續證據將該 finding 歸因於已記錄的修正動作時，它經由留有紀錄的 disposition 更正以 `fix-introduced` 重新進入。其他每個 disposition 為 `new` 的存活 finding 都是非 blocking：主 agent MUST 將它記錄為該輪檔案 `## Fix Actions` 區段中的 triage 註記、MUST 將它納入 signals 寫入步驟的目標集合，且 MUST 將它列在完成輸出中；對於非 blocking 的 `Critical` finding，完成輸出 MUST 額外建議建立後續的 change 提案。非 blocking findings MUST NOT 導致 `next_round` 決策。

主 agent MUST 額外維護本次執行的累積 blocking 集合：本次執行的每個 blocking finding 在被發現時進入該集合，即使沒有 reviewer 再次回報它，仍計入其後每一輪的決策，且只能經由恰好兩種移除事件之一離開該集合：(a) resolved——已為其記錄解決性修正 AND 後續某輪的 reviewer 驗證了該解決（該 finding 未被再次回報，且該驗證在修正位置確認了修正）；Reviewer V、第四輪 checkpoint 的 reviewers 與已 seed 重跑第一輪的 reviewers MUST 各自對每位成員回傳明確的 resolved/unresolved 裁定，且當裁定分歧時，任何 `unresolved` 裁定都使該成員留在集合中；每次 exit-(a) 移除 MUST 記錄在進行移除那一輪的 `## Fix Actions` 中，指名該成員、解決性修正參照與進行驗證的 reviewer；或 (b) accepted——該 finding 在相同 artifact 或檔案以相同缺陷機制，符合依 `接受風險 ledger` requirement 經同意的 accepted-risks 項目；主 agent MUST 每輪根據 accepted-risks ledger 重新評估該集合，且 MUST 將每次此類移除記錄為該輪檔案 `## Fix Actions` 中的 downgrade trace。受 grader 保護而被保留的成員沒有迴圈內的自主移除路徑——修正是被禁止的，只有經同意的 accepted-risks 出口 (b) 適用於它們。當累積 blocking 集合的每位成員都受 grader 保護而被保留且無法取得經同意的出口時，主 agent MUST NOT 再產生 reviewer 輪，且 MUST 以 `decision: aborted` 與 abort triage 結束迴圈；當此條件在某輪的修正階段、機械決策已推導之後才首次成立時，當前尚未定稿的輪檔案記錄 `decision: aborted` 與 abort triage，覆蓋原推導出的 `next_round`。除了未 seed 執行的第一輪之外，當且僅當信心過濾後累積 blocking 集合不含任何 `Critical` 也不含任何 `Warning` finding 時，一輪才通過。本次執行的第一輪保留未分割的通過條件：第一輪中每個存活的 `Critical` 或 `Warning` finding 都是 blocking。在累積 blocking 集合依 `Abort 後的 triage` requirement 被 seed 的重跑中，該次執行的第一輪 MUST 改用累積 blocking 集合的通過條件，且其 reviewers MUST 對照前次執行的 round 檔案標記 dispositions（最終 round 檔案中的 bucket-1 triage 列舉被 seed 的成員）。

micro 輪 MUST 恰好產生一位全新的驗證 reviewer sub-agent（`Reviewer V — Verification`），以取代兩位 full 輪 reviewers。Reviewer V MUST 收到以下情境：artifact 路徑（cash-apply 另加變更檔案清單）、本迴圈每個先前的 round 檔案（或上文定義的摘錄後備方案）、當前累積 blocking 集合成員清單、存在時的 accepted-risks ledger，以及與 full 輪 reviewers 相同的相關 `open` signals 情境。Reviewer V 的範圍 MUST 限於：累積 blocking 集合的每位成員是否已解決（無論是否曾為其記錄修正）——對每位成員回傳明確的 resolved/unresolved 裁定、修正傳播是否完整（每個被修正觸及的概念的每次出現，皆在所有 artifacts 之間——cash-apply 另含變更檔案——同步），以及修正是否引入了新缺陷。在 cash-apply 的 micro 輪中，Reviewer V MUST 額外執行 Implementation Notes Protocol 為 Reviewer A 定義的每輪 `implementation-notes.md` 閱讀義務，包括其檔案不存在與 `open-question` 嚴重度規則。Reviewer V 的 findings MUST 帶有與 full 輪 findings 相同的欄位（包括 `layer`、`confidence` 與 `disposition`），且 MUST 通過相同的信心過濾器。若 micro 輪過濾後累積 blocking 集合為空，決策為 `passed`；若仍有任何 blocking `Critical` 或 `Warning`，決策為 `next_round`，且下一輪的型別依本 requirement 從其在本次執行中的位置推導，並受既有 6 輪上限約束（未滿足通過條件的第六輪記錄 `decision: aborted`）。

#### Scenario: 第一輪之後的一輪預設為 micro 輪

- **WHEN** 本次執行的第一輪以 `decision: next_round` 完成
- **THEN** 第二輪被推導為 micro 輪
- **AND** 第二輪恰好產生一位 `Reviewer V` sub-agent

#### Scenario: 第四輪 checkpoint 是 full 輪

- **WHEN** 本次執行的第三輪以 `decision: next_round` 完成
- **THEN** 第四輪被推導為 full 輪
- **AND** 第四輪平行產生 `Reviewer A` 與 `Reviewer B`
- **AND** 兩位 reviewers 的情境中都收到本迴圈每個先前的 round 檔案（或既定的摘錄後備方案）與當前累積 blocking 集合成員清單
- **AND** 兩位 reviewers 額外如同 Reviewer V 一樣，對累積 blocking 集合回傳同樣的每成員 resolved/unresolved 裁定，使 exit-(a) 移除在 checkpoint 仍然可用
- **AND** 當兩位 reviewers 對某成員的裁定分歧時，任何 `unresolved` 裁定都使該成員留在集合中

#### Scenario: checkpoint 之後的輪回到 micro

- **WHEN** 本次執行的第四輪以 `decision: next_round` 完成
- **THEN** 第五輪被推導為 micro 輪
- **AND** 連續的 micro 輪（第五與第六輪）是有效的

#### Scenario: 修改行為的修正不使輪型別升級

- **WHEN** 某輪決策之後的修正動作修改了實作行為或設計敘述
- **THEN** 下一輪的型別仍僅從其在本次執行中的位置推導
- **AND** 不會重新推導為 full 輪

#### Scenario: 新 finding 進入 triage 而非 blocking

- **WHEN** 本次執行第一輪之後的一輪浮現一個經驗證 disposition 為 `new` 的存活 `Critical` finding
- **THEN** 主 agent 將它記錄為該輪檔案 `## Fix Actions` 區段中的 triage 註記
- **AND** 它進入 signals 寫入步驟目標集合與完成輸出，並附帶後續 change 提案的建議
- **AND** 它不參與該輪決策

#### Scenario: Fix-introduced 回歸阻擋通過

- **WHEN** 本次執行第一輪之後的一輪浮現一個存活 `Critical` finding，其 `introduced_by` 參照本迴圈先前 `## Fix Actions` 區段記錄的修改
- **THEN** 該 finding 的 disposition 為 `fix-introduced` 且為 blocking
- **AND** 該輪檔案記錄 `decision: next_round`

#### Scenario: 無效的修正使 finding 維持 blocking

- **WHEN** 已為某 blocking finding 記錄解決性修正，而後續一輪在相同位置以相同缺陷機制再次回報同一 finding
- **THEN** 該 finding 的 disposition 為 `unresolved-prior` 且維持 blocking
- **AND** 它不因該已記錄修正而被劃入 `new` bucket

#### Scenario: 累積集合成員僅經驗證的解決或接受而移除

- **WHEN** 已為累積 blocking 集合成員記錄解決性修正，且後續輪的 reviewer 驗證該解決並未再次回報它
- **THEN** 該成員自累積 blocking 集合移除

- **WHEN** 累積 blocking 集合成員在相同檔案以相同缺陷機制符合經同意的 accepted-risks 項目
- **THEN** 該成員自累積 blocking 集合移除
- **AND** 該移除被記錄為該輪檔案 `## Fix Actions` 中的 downgrade trace

#### Scenario: 已 triage 的非 blocking finding 不重新進入 blocking 集合

- **WHEN** 後續一輪在相同位置以相同缺陷機制再次回報一個在本迴圈中最近一次先前狀態為非 blocking triage 註記的 finding，且沒有將其歸因於已記錄修正動作的新證據
- **THEN** 該 finding 維持非 blocking
- **AND** 它不導致 `next_round` 決策

#### Scenario: 被 seed 的成員阻擋重跑的第一輪

- **WHEN** 重跑的第一輪完成，某個被 seed 的 bucket-1 成員未被該輪 reviewers 再次回報，且其每成員裁定為 `unresolved`（或前次執行中未曾為其記錄解決性修正）
- **THEN** 累積 blocking 集合仍包含該成員
- **AND** 該輪的決策不是 `passed`

#### Scenario: 未解決的 blocking finding 無法被靜默放行

- **WHEN** 先前輪的 blocking finding 僅有 grader 保護註記而沒有解決性修正，且當前輪的 reviewer 未再次回報它
- **THEN** 累積 blocking 集合仍包含該 finding
- **AND** 當前輪的決策不是 `passed`

#### Scenario: 完全受 grader 保護的 blocking 集合短路至 abort

- **WHEN** 累積 blocking 集合的每位成員都受 grader 保護而被保留，且無法取得經同意的 accepted-risks 出口
- **THEN** 主 agent 不再產生 reviewer 輪
- **AND** 迴圈立即以 `decision: aborted` 與 abort triage 結束

#### Scenario: 分歧的 dispositions 保守合併

- **WHEN** 以 `location + summary` 去重的 findings 帶有分歧的 `disposition` 值
- **THEN** 合併後的 finding 取 blocking 的 disposition，`unresolved-prior` 或 `fix-introduced` 勝過 `new`

#### Scenario: Disposition 更正留下紀錄

- **WHEN** 主 agent 將某位 reviewer 的 `disposition` 標記從 `fix-introduced` 更正為 `new`
- **THEN** 該輪檔案的 `## Fix Actions` 記錄該 finding、原始標記、更正後標記與證據
- **AND** 完成輸出列出該更正，因為它將 blocking disposition 改為非 blocking

#### Scenario: 已完成的 round 檔案在迴圈期間不可變

- **WHEN** 某個修正動作可藉由將修正紀錄或 triage 註記插入先前輪的檔案來縮小累積 blocking 集合
- **THEN** 主 agent 不編輯先前輪的檔案
- **AND** 修正紀錄與 triage 註記只寫在其發生的那一輪

#### Scenario: 累積 blocking 集合為空的 micro 輪使迴圈通過

- **WHEN** 一個 micro 輪完成，且信心過濾後累積 blocking 集合不含任何 `Critical` 也不含任何 `Warning` finding
- **THEN** 該輪檔案記錄 `decision: passed` 與 `round_type: micro`
- **AND** 迴圈停止

#### Scenario: cash-apply micro 輪閱讀 implementation notes

- **WHEN** 一個 cash-apply micro 輪開始
- **THEN** Reviewer V 依 Implementation Notes Protocol 閱讀 `openspec/changes/<change>/implementation-notes.md`
- **AND** 檔案缺失產生一個 `Critical` finding
- **AND** 未解決的 `open-question` 項目產生一個 `Warning` finding

#### Scenario: 分歧的 layer 值保守合併

- **WHEN** 兩位 full 輪 reviewers 各自獨立提出同一 finding（以 `location + summary` 去重）且其 `layer` 分類不同
- **THEN** 合併後的 finding 取 `layer: design`

#### Scenario: 不確定的 layer 預設為 design

- **WHEN** reviewer 無法判斷修正某 finding 是否會改變設計決策或行為敘述
- **THEN** 該 reviewer 將該 finding 分類為 `layer: design`

#### Scenario: 主 agent 的重新分類僅能升級

- **WHEN** 主 agent 套用信心過濾器並判斷修正某個被分類為 `text` 的 finding 可能觸及行為或設計敘述
- **THEN** 主 agent 將該 finding 重新分類為 `design`
- **AND** 主 agent 從不將 `design` finding 重新分類為 `text`

##### Example: 依本次執行中位置推導下一輪型別

| 目前回合位置 | 下一輪位置 | 下一輪型別 |
| ---------------------- | ------------------- | --------------- |
| 1st (full)  | 2nd | micro |
| 2nd (micro) | 3rd | micro |
| 3rd (micro) | 4th | full  |
| 4th (full)  | 5th | micro |
| 5th (micro) | 6th | micro |




<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---

### Requirement: 審查迴圈的 grader 不可變性

canonical 的 Claude 與 Codex `cash-propose` 與 `cash-apply` skill 檔案 SHALL 各自包含一條以唯一的 sentinel 註解 `<!-- GRADER-IMMUTABILITY -->` 標記的 grader 不可變性規則。在 cash 審查迴圈期間，主 agent MUST NOT 修改——無論是作為修正動作或作為機械自我檢查的修正——受保護 grader 路徑集合中的任何檔案：`.claude/skills/cash-propose/SKILL.md`、`.claude/skills/cash-apply/SKILL.md`、`.agents/skills/cash-propose/SKILL.md`、`.agents/skills/cash-apply/SKILL.md`、`.cash.yaml`、`scripts/cash-skills/tests/skill-checks.fish`、`scripts/cash-cli/tests/cli-checks.fish`，以及 `openspec/specs/` 之下的 master spec 檔案——除非該檔案被當前 change 的結構化範圍宣告明確指名。結構化範圍宣告僅限於 proposal `## Impact` affected-code 條目中的專案根相對路徑，以及 `tasks.md` 中被明確標識為交付目標的專案根相對路徑。僅出現在驗證指令、規則描述、範例、審查 finding、reviewer 情境或其他附帶性文字中的路徑 MUST NOT 計為結構化範圍宣告。在結構化範圍宣告中指名一個目錄路徑即指名其下的所有檔案。已在進行中的迴圈依其開始時的 canonical 指令版本繼續；對 cash skill 的範圍內編輯自下一次迴圈執行起生效。此外，無論宣告範圍為何，主 agent MUST NOT 新增、修改或移除 `openspec/signals/` 之下任何 signal 的 `check` frontmatter 欄位——`check` 欄位是每輪前機械自我檢查的 grader 輸入。當解決一個存活 finding 需要修改該結構化範圍之外的受保護檔案，或觸及 signal 的 `check` 欄位時，修正動作 MUST NOT 執行該修改、MUST 在 `## Fix Actions` 記錄一則 unfixed-due-to-grader-protection 註記並指名該檔案與該 finding，且該 finding 就該輪決策而言維持存活。無論最終決策為何，cash workflow 的完成輸出 MUST 列出迴圈任何一輪所記錄的每則 unfixed-due-to-grader-protection 註記：對 `decision: passed` 的 `cash-propose`，這些註記 MUST 列在最終摘要中；對 `decision: passed` 的 `cash-apply`，這些註記 MUST 列在 gate-complete 最終回應中；對任何 `decision: aborted`，這些註記 MUST 列在未解決 findings 警告中。在結構化範圍例外之下被修改的受保護檔案，視同其他任何修正動作的修改，且不改變下一輪的型別——依 `分級收斂與 micro 驗證輪` requirement，型別僅從其在本次執行中的位置推導。此規則 MUST 適用於兩個變體中的兩個 cash workflows。

#### Scenario: 範圍外的 grader 修改被拒絕

- **WHEN** 某個審查迴圈 finding 的建議需要編輯 `.agents/skills/cash-propose/SKILL.md`，而當前 change 的結構化範圍宣告未指名該檔案
- **THEN** 修正動作不修改 `.agents/skills/cash-propose/SKILL.md`
- **AND** 該輪檔案的 `## Fix Actions` 記錄一則 unfixed-due-to-grader-protection 註記，指名該檔案與該 finding
- **AND** 該 finding 仍計入該輪決策

#### Scenario: 附帶性的受保護路徑文字不解鎖 grader 檔案

- **WHEN** `tasks.md` 僅在描述 grader 保護規則或驗證步驟時提及 `openspec/specs/`
- **THEN** 該提及不計為結構化範圍宣告
- **AND** 主 agent MUST NOT 經由 grader 不可變性例外修改 `openspec/specs/` 之下的檔案

#### Scenario: Signal 的 check 欄位從不被修正動作修改

- **WHEN** 某個每輪前自我檢查的 `check` 指令失敗，且修正動作可藉由弱化或移除該 signal 的 `check` 欄位使其通過
- **THEN** 修正動作不新增、修改也不移除任何 signal 的 `check` 欄位
- **AND** 底層缺陷改在該 change 自身的 artifacts 或檔案中修正

#### Scenario: 已宣告範圍內的 grader 檔案維持可修改

- **WHEN** 當前 change 的結構化範圍宣告明確指名 `.agents/skills/cash-propose/SKILL.md`，且某個修正動作修改該檔案
- **THEN** 該 canonical skill 修改是被允許的
- **AND** 該修改不改變下一輪的型別，型別僅從其在本次執行中的位置推導

#### Scenario: 完成輸出錨定 grader 保護紀錄

- **WHEN** 迴圈的任何一輪記錄了 unfixed-due-to-grader-protection 註記，且迴圈其後以 `cash-propose` 的 `decision: passed` 結束
- **THEN** 最終摘要列出迴圈每一輪的每則此類註記

- **WHEN** 迴圈的任何一輪記錄了 unfixed-due-to-grader-protection 註記，且迴圈其後以 `cash-apply` 的 `decision: passed` 結束
- **THEN** gate-complete 最終回應列出迴圈每一輪的每則此類註記

- **WHEN** 迴圈的任何一輪記錄了 unfixed-due-to-grader-protection 註記，且迴圈以 `decision: aborted` 結束
- **THEN** 未解決 findings 警告列出迴圈每一輪的每則此類註記

#### Scenario: Canonical skills 帶有 grader 不可變性 sentinel

- **WHEN** 檢視四個 canonical 的 cash proposal 與 apply skill 檔案
- **THEN** 每個檔案皆含有 `<!-- GRADER-IMMUTABILITY -->` sentinel 與受保護 grader 路徑集合
- **AND** `scripts/cash-skills/tests/skill-checks.fish` 斷言該 sentinel 的存在

<!-- @trace
source: replace-spectra-cli-with-cash-cli
updated: 2026-07-24
code:
  - .agents/skills/
  - .agents/skills/spectra-analyze/
  - .agents/skills/spectra-apply/
  - .agents/skills/spectra-archive/
  - .agents/skills/spectra-ask/
  - .agents/skills/spectra-audit/
  - .agents/skills/spectra-commit/
  - .agents/skills/spectra-debug/
  - .agents/skills/spectra-discuss/
  - .agents/skills/spectra-drift/
  - .agents/skills/spectra-ingest/
  - .agents/skills/spectra-propose/
  - .agents/skills/spectra-verify/
  - .cash-skills/bin/cash
  - .cash-skills/lib/cash_cli/
  - .cash-skills/receipt.tsv
  - .cash-skills/state/
  - .cash-skills/state/snapshots/
  - .cash-skills/state/touched/
  - .claude/skills/
  - .claude/skills/spectra-analyze/
  - .claude/skills/spectra-apply/
  - .claude/skills/spectra-archive/
  - .claude/skills/spectra-ask/
  - .claude/skills/spectra-audit/
  - .claude/skills/spectra-commit/
  - .claude/skills/spectra-debug/
  - .claude/skills/spectra-discuss/
  - .claude/skills/spectra-drift/
  - .claude/skills/spectra-ingest/
  - .claude/skills/spectra-propose/
  - .claude/skills/spectra-verify/
  - .spectra/
  - scripts/cash-cli/fixtures/
  - scripts/cash-cli/tests/
  - scripts/cash-skills/legacy-spectra-digests.tsv
  - scripts/cash-skills/tests/skill-checks.fish
tests:
-->

### Requirement: 審查迴圈的 ledger 輸出

canonical 的 Claude 與 Codex `cash-propose` 與 `cash-apply` skill 檔案 SHALL 各自包含一個以唯一的 sentinel 註解 `<!-- LOOP-LEDGER-STEP -->` 標記的 ledger 步驟。對每一輪，主 agent MUST 在一個確定性的時間點向 `openspec/changes/<change>/reviews/loop-ledger.tsv` 追加恰好一列：對 `next_round` 輪，緊接在產生下一輪 reviewers 之前——於每個可能寫入該輪檔案 `## Fix Actions` 的動作（包括修正動作、修正後自我檢查紀錄與驗證重跑修正紀錄）都完成之後；對最終輪（`passed` 或 `aborted`），在迴圈結束時、signals 寫入步驟之前。當該檔案不存在時，主 agent MUST 在追加前以單一表頭列建立它；表頭列 MUST 恰好依序包含七個以 tab 分隔的欄名：`skill`、`round`、`round_type`、`criticals`、`warnings`、`decision`、`fixed_files`。每列 MUST 依此順序包含以 tab 分隔的：`skill`（`propose` 或 `apply`）、`round`（與 round 檔案編號相符的 1-based 整數）、`round_type`（`full` 或 `micro`）、`criticals`（過濾後累積 blocking 集合的 Critical 數——本次執行的第一輪中每個存活 Critical 都是 blocking，且已 seed 重跑的第一輪使用累積 blocking 集合；當過濾後累積 blocking 集合為空時為 `0`，包括因 sub-agent 失敗而 abort 的輪）、`warnings`（過濾後累積 blocking 集合的 Warning 數，同樣以 `0` 表示）、`decision`（`passed`、`next_round` 或 `aborted`）與 `fixed_files`（該輪 `## Fix Actions` 中記錄為已修改的相異檔案數，無記錄時為 `0`；fallback、triage、downgrade-trace、disposition 更正或 grader 保護等註記行不計入）。ledger 是 append-only 的事件日誌：propose 迴圈、apply 迴圈與 abort 後任何重跑迴圈的列依時序累積在同一檔案中，且 `(skill, round)` 不是唯一鍵——來自歷史重跑的重複輪編號是有效的。round 檔案仍是權威紀錄；當 round 檔案與 ledger 有任何不一致時，以 round 檔案為準。ledger 寫入失敗 MUST 產生一則印出的警告且 MUST NOT 使 cash workflow 失敗。此行為 MUST 同時適用於兩個變體中的兩個 cash workflows。

#### Scenario: 一次迴圈執行的每個完成輪恰好一列 ledger

- **WHEN** 單次 cash 審查迴圈執行為某個 change 完成了 N 輪
- **THEN** 該次執行向 `openspec/changes/<change>/reviews/loop-ledger.tsv` 追加恰好 N 個資料列
- **AND** 表頭列在檔案頂端恰好存在一次

##### Example: 三輪 propose 迴圈之後接著兩輪 apply 迴圈

| skill | round | round_type | criticals | warnings | decision | fixed_files |
| ----- | ----- | ---------- | --------- | -------- | -------- | ----------- |
| propose | 1 | full | 1 | 2 | next_round | 3 |
| propose | 2 | micro | 0 | 1 | next_round | 1 |
| propose | 3 | micro | 0 | 0 | passed | 0 |
| apply | 1 | full | 0 | 1 | next_round | 2 |
| apply | 2 | micro | 0 | 0 | passed | 0 |

#### Scenario: Ledger 以表頭列建立

- **WHEN** 某迴圈的第 1 輪完成且該 change 不存在 `loop-ledger.tsv`
- **THEN** 主 agent 以一個表頭列與一個資料列建立該檔案

#### Scenario: 帶入的 findings 使 ledger 自我說明

- **WHEN** 某輪的 reviewers 未再回報任何內容，但累積 blocking 集合仍包含一個 `Critical` finding
- **THEN** 該輪的 ledger 列記錄 `criticals` = 1 且 `decision` = `next_round`

#### Scenario: Abort 後的迴圈重跑累積列

- **WHEN** 某迴圈以 `decision: aborted` 結束，且同一 skill 的新迴圈執行其後在同一 change 上執行
- **THEN** 新執行的列被追加在既有列之後
- **AND** 先前執行的列不被修改或刪除

#### Scenario: 因失敗而 abort 的輪記錄零計數

- **WHEN** 某輪因同一 reviewer 角色失敗兩次而 abort、不存在過濾後 findings，且累積 blocking 集合為空
- **THEN** 該輪的 ledger 列記錄 `criticals` = 0 與 `warnings` = 0，且 `decision` = `aborted`

#### Scenario: Ledger 寫入失敗不使 workflow 失敗

- **WHEN** 追加至 `loop-ledger.tsv` 失敗
- **THEN** 主 agent 印出一則警告
- **AND** cash workflow 不變地繼續

#### Scenario: Canonical skills 帶有 ledger sentinel

- **WHEN** 檢視四個 canonical 的 cash proposal 與 apply skill 檔案
- **THEN** 每個檔案皆含有 `<!-- LOOP-LEDGER-STEP -->` sentinel
- **AND** `scripts/cash-skills/tests/skill-checks.fish` 斷言該 sentinel 的存在




<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---

### Requirement: 確定性的 signal 衍生自我檢查

canonical 的 Claude 與 Codex `cash-propose` 與 `cash-apply` skill 檔案 SHALL 各自將每輪前機械自我檢查的「Signal-derived checks」項目定義為消費選用的 signal `check` frontmatter 欄位。對每個 frontmatter 含有 `check` 欄位的 `open` signal——不對這些 signals 套用 best-effort 相關性挑選——主 agent MUST 從專案根執行該指令，方式是將 `check` 值作為單一指令字串引數傳給 `sh -c`（而非將其插入引號括起的 shell 字串）。Exit code `0` 表示檢查通過。Exit code `1` 表示反模式存在。主 agent MUST 在決定是否修正之前分類該失敗的檢查：它 MUST 檢視檢查指令印出的任何專案根相對路徑，並與當前 change 的 artifacts——對 cash-apply 另含修改過的原始碼檔案——比對。若至少一個印出的路徑位於該 artifact／原始碼檔案集合之內，偵測到的實例即在範圍內。若指令未印出可用的專案根相對路徑，或輸出無法可靠地對應到專案根相對路徑，主 agent MUST fail closed 並將偵測到的實例視為在範圍內，除非已讀取的 repository 狀態證明該實例是既存的，或所需的修正位置在該 change 的結構化範圍之外。當偵測到的實例在範圍內，且修正位置未被未涵蓋的受保護 grader 路徑阻擋時，它是一個依既有自我檢查規則、MUST 在產生該輪 reviewers 之前修正的自我檢查失敗。當偵測到的實例是既存的、或其修正位於該 change 的結構化範圍之外、或其修正位於未被結構化範圍例外涵蓋的受保護 grader 路徑之內時，主 agent MUST NOT 修正它、MUST 在寫入該輪 round 檔案時於其 `## Fix Actions` 記錄一行 out-of-scope-check-failure 註記、MUST 將失敗的檢查結果納入該輪 reviewers 的情境，且 MUST 繼續產生 reviewers——既存的反模式從不使迴圈死鎖。任何其他 exit code（例如 `2`、`126`、`127`）屬執行錯誤：主 agent MUST 退回該 signal 既有的 best-effort 判斷，並在寫入該輪 round 檔案時於其 `## Fix Actions` 記錄一行 fallback 註記。（out-of-scope 或 fallback 的）註記行與通過輪的 `None; pass condition met.` 文字並存，且不計入 ledger 的 `fixed_files` 值。對沒有 `check` 欄位的 `open` signals，既有的 best-effort 行為 MUST 維持不變。執行 `check` 指令 MUST NOT 修改任何檔案。

#### Scenario: 帶有 check 欄位的 signal 被確定性地執行

- **WHEN** 每輪前機械自我檢查執行，且某個 `open` signal 的 frontmatter 含有 `check`
- **THEN** 主 agent 從專案根執行該 `check` 指令，方式是將其值作為單一引數傳給 `sh -c`，不受相關性判斷影響
- **AND** exit code `1` 且偵測到的實例位於該 change 自身的 artifacts 或修改檔案之內時，視為須在產生 reviewers 之前修正的自我檢查失敗

#### Scenario: 檢查輸出路徑位於 change 之內即在範圍內

- **WHEN** 某個 `open` signal 的 `check` 指令以 `1` 結束
- **AND** 指令輸出包含 `openspec/changes/<change>/` 之下的專案根相對路徑
- **THEN** 主 agent 將該失敗視為 cash-propose 迴圈的範圍內失敗
- **AND** 在產生 reviewers 之前修正該失敗，除非修正位置被未涵蓋的受保護 grader 路徑阻擋

#### Scenario: 無法定位的檢查失敗 fail closed

- **WHEN** 某個 `open` signal 的 `check` 指令以 `1` 結束
- **AND** 指令輸出不含可用的專案根相對路徑
- **AND** 已讀取的 repository 狀態未證明該實例是既存的，或所需的修正位置在該 change 的結構化範圍之外
- **THEN** 主 agent 將該失敗視為在範圍內
- **AND** 不將其記錄為 out-of-scope-check-failure 註記

#### Scenario: 受保護路徑分支僅在結構化範圍之外適用

- **WHEN** 某個 `open` signal 的 `check` 指令以 `1` 結束
- **AND** 修正偵測到的實例需要編輯 `.agents/skills/cash-propose/SKILL.md`
- **AND** 當前 change 的結構化範圍宣告明確指名 `.agents/skills/cash-propose/SKILL.md`
- **THEN** 該受保護 grader 路徑不觸發 out-of-scope-check-failure 分支
- **AND** 主 agent 在產生 reviewers 之前修正該失敗

#### Scenario: 範圍外的檢查失敗不使迴圈死鎖

- **WHEN** 某個 `open` signal 的 `check` 指令以 `1` 結束，且偵測到的實例是既存的，或其修正位於該 change 的結構化範圍之外，或位於未被結構化範圍例外涵蓋的受保護 grader 路徑之內
- **THEN** 主 agent 不修正它，並在寫入該輪 round 檔案時於其 `## Fix Actions` 記錄一行 out-of-scope-check-failure 註記
- **AND** 將失敗的檢查結果納入該輪 reviewers 的情境並繼續產生 reviewers

#### Scenario: 執行錯誤的 exit codes 退回 best-effort

- **WHEN** 某個 `open` signal 的 `check` 指令以 `0` 或 `1` 以外的 code 結束
- **THEN** 主 agent 對該 signal 套用既有的 best-effort 判斷
- **AND** 在寫入該輪 round 檔案時於其 `## Fix Actions` 記錄一行 fallback 註記
- **AND** 該註記不計入 ledger 的 `fixed_files` 值

#### Scenario: 沒有 check 的 signals 保持 best-effort 行為

- **WHEN** 某個 `open` signal 沒有 `check` 欄位
- **THEN** 該 signal 的 Signal-derived checks 行為與既有的 best-effort 規則相比不變



<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---

### Requirement: 接受風險 ledger

系統 SHALL 支援位於 `openspec/changes/<change>/reviews/accepted-risks.md` 的 accepted-risks ledger。項目 MUST 僅在當前 session 取得明確使用者同意後才能建立、修改或刪除；迴圈 MUST NOT 自主寫入、編輯或移除項目，主 agent MUST NOT 在進行中的迴圈期間以修正動作修改或刪除既有項目，且當無法進行使用者互動時，候選 finding 維持存活且不寫入任何項目。每個項目 MUST 記錄 `severity`、`location`、缺陷機制描述、接受理由與記錄日期。當該檔案存在時，主 agent MUST 將其內容納入每一輪的 reviewer 情境。在信心過濾期間，對符合某項目相同 `location` AND 相同缺陷機制的任何 finding，主 agent MUST 至多給 `25` 分；記錄的行號範圍僅供參考，當相同 artifact 或檔案與相同缺陷機制相符時，即使記錄的範圍已位移，比對仍成立。僅與某項目共享子系統或問題類別的 finding MUST NOT 以此為由被降級。依本 requirement 套用的每次降級 MUST 記錄在該輪檔案的 `## Fix Actions` 區段，指名該 finding 與相符的項目，且完成輸出 MUST 列出迴圈任何一輪套用的每次 accepted-risks 降級。若寫入該檔案失敗，skill MUST 印出警告且 MUST NOT 使 cash workflow 失敗。

#### Scenario: 相符的 finding 被降級並留有紀錄

- **WHEN** reviewer 回報的 finding 其 `location` 與缺陷機制符合某個 accepted-risks 項目
- **THEN** 主 agent 在信心過濾期間對該 finding 至多給 `25` 分
- **AND** 該 finding 不以 `Critical` 或 `Warning` 存活
- **AND** 該輪檔案的 `## Fix Actions` 記錄該降級，指名該 finding 與相符的項目
- **AND** 完成輸出列出該降級

#### Scenario: 相同子系統但不同機制不被降級

- **WHEN** reviewer 回報的 finding 與某個 accepted-risks 項目位於相同子系統，但缺陷機制不同
- **THEN** 該 finding 以 reviewer 給的信心分數通過信心過濾器
- **AND** 不套用任何 accepted-risks 降級

#### Scenario: 位移的行號範圍仍相符

- **WHEN** finding 符合某個 accepted-risks 項目的檔案與缺陷機制，但該項目記錄的行號範圍在其後的編輯之後已不再對應
- **THEN** 比對仍成立且降級適用

#### Scenario: 沒有同意就沒有項目

- **WHEN** 主 agent 識別出候選的接受風險，且無法在當前 session 取得明確使用者同意
- **THEN** 不向 `accepted-risks.md` 寫入任何項目
- **AND** 該 finding 就該輪決策而言維持存活

#### Scenario: 項目不可作為修正動作編輯

- **WHEN** 某個修正動作可藉由放寬或刪除既有的 accepted-risks 項目來解決存活 finding
- **THEN** 主 agent 不修改也不刪除該項目
- **AND** 任何項目變更僅經由當前 session 的明確使用者同意發生

#### Scenario: Ledger 進入 reviewer 情境

- **WHEN** 某輪的 reviewers 被產生且 `openspec/changes/<change>/reviews/accepted-risks.md` 存在
- **THEN** 該輪每位 reviewer 都在其情境中收到該檔案內容




<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---

### Requirement: 修正迴圈設計斷路器

在 cash-apply 審查迴圈中，當解決存活 finding 需要引入 `design.md` 未定義的同步原語（例如 mutex、lock 或 semaphore）、身分或世代型別（例如 token、epoch 或 generation id）或狀態機時，主 agent MUST NOT 以修正動作實作該機制。主 agent MUST 在該輪的 `## Fix Actions` 區段記錄一則 needs-design 註記，指名該 finding、所需機制與一行理由；MUST 以 `decision: aborted` 寫入該輪 round 檔案；MUST 依 `Abort 後的 triage` requirement 執行 abort triage；且完成輸出 MUST 指引使用者在重新進入 apply workflow 之前，經由與變體相稱的 `cash-ingest` 呼叫更新 `design.md`。在 cash-propose 輪中，於該 change 自身的 `design.md` 定義所需機制是正常的修正動作，此斷路器 MUST NOT 觸發。`decision` 值集合 MUST 恰好維持為 `passed`、`next_round` 與 `aborted`；本規則不引入額外的 decision 值。

#### Scenario: 需要新狀態機的修正觸發斷路器

- **WHEN** 在 cash-apply 迴圈中解決存活的 `Critical` finding 需要引入 `design.md` 未定義的 lease 狀態機
- **THEN** 主 agent 不以修正動作實作該狀態機
- **AND** 在 `## Fix Actions` 記錄一則 needs-design 註記
- **AND** 以 `decision: aborted` 寫入該輪 round 檔案
- **AND** 完成輸出將使用者指引至與變體相稱的 `cash-ingest` 呼叫

#### Scenario: 設計已定義的機制是正常修正

- **WHEN** 在 cash-apply 迴圈中解決存活 finding 僅使用 `design.md` 已定義的機制
- **THEN** 該修正作為正常修正動作進行
- **AND** 斷路器不觸發

#### Scenario: cash-propose 的設計編輯不觸發斷路器

- **WHEN** 某個 cash-propose finding 藉由在該 change 自身的 `design.md` 定義所需同步機制而解決
- **THEN** 該編輯作為正常修正動作進行
- **AND** 斷路器不觸發




<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---

### Requirement: Abort 後的 triage

當審查迴圈因輪數上限、修正迴圈設計斷路器或完全受 grader 保護的短路而以 `decision: aborted` 結束時，主 agent MUST 將每個未解決的存活 finding 分流至三個 bucket 中恰好一個，並將該 triage 同時記錄在最終 aborted 輪檔案的 `## Fix Actions` 區段與完成輸出中：(1) 仍屬該 change 義務的 findings——每個未經由同意路徑被接受的累積 blocking 集合成員，無論其 disposition 為何或是否缺少 disposition（fix-introduced 回歸與 unresolved-prior findings 是典型情況）；(2) 在本迴圈中從未 blocking 的新發現或設計層級問題——該 finding 被寫入 signals，且對 `Critical` finding，輸出 MUST 建議建立後續的 change 提案；(3) 接受的取捨——該 finding 依 `接受風險 ledger` requirement 的同意規則寫入 accepted-risks ledger；當無法在當前 session 取得同意時，該 finding MUST 改分流至 bucket 1——它仍是該 change 的義務並 seed 重跑——並附註 accepted-risks 記錄已延後等待使用者同意。Bucket 2 MUST NOT 收納任何在本迴圈中曾為 blocking 的 finding。完成輸出 MUST NOT 在缺少此 triage 的情況下建議重跑同一迴圈。abort 後的迴圈重跑 MUST NOT 覆寫先前的 round 檔案：其 round 檔案自該 skill 最後一個既有 round 檔案接續編號，而 6 輪上限與輪型別推導以新執行中的位置運作（其第一輪是 full 輪）。重跑的第一輪 reviewer 情境 MUST 包含前次執行的 round 檔案（或依摘錄後備方案的摘錄），且重跑的累積 blocking 集合 MUST 以前次執行的 bucket-1 findings 進行 seed，使它們以 blocking 身分重新進入審查；重跑的第一輪 reviewers MUST 回傳與 Reviewer V 相同的每成員 resolved/unresolved 裁定，因此解決性修正已記錄於前次執行的 seed 成員可以在重跑的第一輪離開集合。當已 seed 重跑的整個被 seed 集合皆受 grader 保護而被保留且無法取得經同意的出口時，短路在產生重跑第一輪 reviewers 之前評估：該次執行恰好寫入一個承載該 triage 的 round 檔案（接續編號、`round_type: full`、無 reviewer findings、`decision: aborted`）、追加一列帶有相同 `round_type` 的 ledger 列，且其完成輸出 MUST 指引使用者在任何進一步重跑之前，為受保護成員取得同意，或經由與變體相稱的 `cash-ingest` 呼叫擴充該 change 的結構化範圍宣告。由連續 sub-agent 失敗造成的 aborts 保留既有的失敗處理行為並豁免於此 triage；proposal 層級的範圍錯誤 aborts 同樣豁免，因為該 change 預期從頭重新提案而非重跑。

#### Scenario: 輪數上限 abort 產生三個 bucket 的 triage

- **WHEN** 迴圈以 `decision: aborted` 寫入其第六輪且仍有未解決的存活 findings
- **THEN** 最終輪檔案的 `## Fix Actions` 與完成輸出將每個未解決 finding 指派至三個 triage bucket 中恰好一個
- **AND** 輸出不在缺少 triage 的情況下建議重跑同一迴圈

#### Scenario: 無法取得同意時 finding 留在該 change

- **WHEN** aborted 迴圈分流一個 blocking 的取捨 finding，且無法在當前 session 取得明確使用者同意
- **THEN** 該 finding 被分流至 bucket 1，仍是該 change 的義務，並 seed 重跑的累積 blocking 集合
- **AND** 該 triage 記錄 accepted-risks 記錄已延後等待使用者同意

#### Scenario: 完全受保護的已 seed 重跑在產生 reviewers 之前 abort

- **WHEN** 已 seed 重跑開始，且其整個被 seed 的累積 blocking 集合皆受 grader 保護而被保留、無法取得經同意的出口
- **THEN** 該次執行不產生 reviewers，恰好寫入一個接續編號、`round_type: full`、`decision: aborted` 且承載該 triage 的 round 檔案，並追加一列 ledger 列
- **AND** 完成輸出指引使用者在任何進一步重跑之前為受保護成員取得同意，或經由與變體相稱的 `cash-ingest` 呼叫擴充結構化範圍宣告

#### Scenario: 重跑接續輪編號並消化該 triage

- **WHEN** 同一 skill 的迴圈在 abort 後重跑，且前次最後的 round 檔案是 `apply-r6.md`
- **THEN** 重跑的第一個 round 檔案是 `apply-r7.md`，且沒有任何先前 round 檔案被覆寫
- **AND** 重跑的第一輪是 full 輪，其 reviewer 情境包含 `apply-r6.md`
- **AND** 重跑的累積 blocking 集合以前次執行的 bucket-1 findings 進行 seed
- **AND** 重跑的 6 輪上限與輪型別推導從其自身的第一輪起算




<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---

### Requirement: cash-apply 的 introduced-by 證據

在 cash-apply 輪中，來自 `Reviewer B` 的每個 `Critical` 或 `Warning` finding MUST 包含 `introduced_by` 欄位，引用下列之一：本 change diff 中的具體位置（檔案路徑加上引入的行為）、本迴圈的一項或多項 fix-action 紀錄，或——對由多個修正交互作用而浮現的回歸——某個指名輪次的修正動作集合。在信心過濾期間，對 `introduced_by` 缺失或無法對照 change diff 或已記錄修正動作驗證的任何 cash-apply `Reviewer B` `Critical` 或 `Warning` finding，主 agent MUST 至多給 `25` 分；依本規則套用的每次降級 MUST 記錄在該輪檔案的 `## Fix Actions`，指名該 finding 與證據無法驗證的原因，且完成輸出 MUST 列出每次此類降級。本 requirement 不適用於 cash-propose 輪。

#### Scenario: 缺失的 introduced_by 被降級並留有紀錄

- **WHEN** 某個被分類為 `Critical` 的 cash-apply `Reviewer B` finding 未帶 `introduced_by` 欄位
- **THEN** 主 agent 在信心過濾期間對它至多給 `25` 分
- **AND** 它不以 `Critical` 或 `Warning` 存活
- **AND** 該輪檔案的 `## Fix Actions` 記錄該降級與原因
- **AND** 完成輸出列出該降級

#### Scenario: 通過驗證的 introduced_by 通過過濾器

- **WHEN** 某個 cash-apply `Reviewer B` finding 引用的 `introduced_by` 位置經主 agent 對照 change diff 驗證
- **THEN** 該 finding 以 reviewer 給的信心分數通過信心過濾器

#### Scenario: 交互作用回歸引用修正動作集合

- **WHEN** 某個 cash-apply `Reviewer B` finding 將回歸歸因於多個修正的交互作用，並引用某個指名輪次的修正動作集合作為其 `introduced_by`
- **THEN** 該引用是可驗證的證據，且不套用 introduced-by 降級




<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---

### Requirement: 審查輪的行動義務

當某一輪的決策為 `next_round` 時，每個存活的 `Critical` 或 `Warning` finding AND 每個計入該輪決策的累積 blocking 集合成員，MUST 在產生下一輪 reviewers 之前，於該輪的 `## Fix Actions` 區段擁有至少一項已記錄的動作。對 blocking finding 或累積 blocking 集合成員，有效動作恰為：列出修改檔案的修正、grader 保護註記，或依 `接受風險 ledger` requirement 經明確使用者同意記錄的 accepted-risks 項目；為 blocking 成員記錄的非 blocking triage 註記不是有效動作，且對其 blocking 狀態沒有影響。對非 blocking（`new`）finding，有效動作是其非 blocking triage 註記；對符合先前輪非 blocking triage 註記的再回報，有效動作是一行指名原輪 triage 註記的交叉參照註記（既非重複的 triage 註記也非新的 signal）。記錄 needs-design 註記不是 `next_round` 動作：依 `修正迴圈設計斷路器` requirement，它強制 `decision: aborted` 且從不與 `next_round` 決策並存。當任何存活 finding 沒有已記錄的動作時，主 agent MUST NOT 產生下一輪的 reviewers。

#### Scenario: 零動作的輪無法前進

- **WHEN** 某輪的決策為 `next_round`，且至少一個存活 finding 在 `## Fix Actions` 中沒有已記錄的動作
- **THEN** 主 agent 在每個存活 finding 都有已記錄動作之前，不產生下一輪的 reviewers

#### Scenario: 每個存活 finding 都帶有動作紀錄

- **WHEN** 一個 `decision: next_round` 的輪完成其修正階段
- **THEN** 每個存活的 `Critical` 或 `Warning` finding 都對應到 `## Fix Actions` 中的一項修正紀錄、grader 保護註記、非 blocking triage 註記或經同意的 accepted-risks 項目

#### Scenario: needs-design 強制 abort 而非再一輪

- **WHEN** 某輪為存活 finding 記錄了 needs-design 註記
- **THEN** 依 `修正迴圈設計斷路器` requirement，該輪的決策為 `aborted`
- **AND** 該輪不進入 `next_round`




<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---

### Requirement: cash-propose 的 impact 粒度提示

在 proposal artifact 寫入之後，`cash-propose` SHALL 計數 proposal `## Impact` 區段中的 affected-code 條目：計數為 Modified、New 與 Removed 之下列出的路徑條目數，排除 `(none)` 佔位行；目錄條目計為一個條目，因此該計數是下限。當計數超過 15 時，skill MUST 印出一則資訊性警告，述明計數並建議依 capability 拆分該 change。該警告 MUST NOT 阻擋 workflow 且 MUST NOT 要求使用者確認。當計數為 15 或更少時，skill MUST 不為此檢查印出任何內容。

#### Scenario: 過大的 impact 印出提示

- **WHEN** proposal `## Impact` 區段列出 20 個 affected-code 路徑條目
- **THEN** skill 印出一則資訊性警告，述明計數並建議依 capability 拆分
- **AND** workflow 繼續進行而無需確認

#### Scenario: 小的 impact 保持沉默

- **WHEN** proposal `## Impact` 區段列出 10 個 affected-code 路徑條目
- **THEN** skill 不為此檢查印出任何內容

#### Scenario: 佔位行不列入計數

- **WHEN** proposal `## Impact` 區段列出 16 個路徑條目與一行 `- Removed: (none)` 佔位行
- **THEN** 計數為 16 且提示被印出

##### Example: 提示門檻

| Affected-code 路徑條目數 | 是否印出提示 |
| -------------------------- | ---------------- |
| 8  | 否  |
| 15 | 否  |
| 16 | 是 |
| 29 | 是 |


<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---

### Requirement: 清理不依賴 plist 存在即卸載已知 labels

清理 SHALL 以 label 查詢 `gui/<uid>/com.spectra.plus.repair` 與 `gui/<uid>/com.agentflow.spectra-plus.repair` 兩者。已載入的 label 即使其 plist 不存在也 MUST 被 boot out。registry 與 cache 的移除 MUST 僅在兩個 labels 皆確認不存在或成功卸載之後進行。任何非預期的 print 或 bootout 錯誤 MUST fail closed 並保留所有剩餘的 legacy 狀態。

#### Scenario: 無 plist 的已載入服務被移除

- **GIVEN** 某個已知 label 已載入且其 plist 不存在
- **WHEN** 清理執行
- **THEN** 它以 label 發現該服務並將其 boot out
- **AND** 僅在兩個已知 labels 皆不存在或已卸載之後移除 registry 與 cache

#### Scenario: Dry run 從不查詢 launchctl

- **WHEN** 清理以 `--dry-run` 執行
- **THEN** 它列出計畫中的 label 與檔案系統行動
- **AND** 不呼叫 `launchctl print` 也不呼叫 `launchctl bootout`


<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---

### Requirement: 變體對等比較完整的受治理本文

回歸套件 SHALL 僅正規化 `/cash-*` 相對於 `$cash-*` 的呼叫語法，且 SHALL 比較每對配對 skill 的完整檔案。沒有宣告工具差異的 skill 在該正規化之後 MUST 完全相同。每個宣告的差異 MUST 逐行符合其位於 `scripts/cash-skills/variant-parity/` 之下、可讀的精確 unified-diff manifest。每 skill 的 manifests MAY 列舉工具特定的 frontmatter、fork 情境措辭、plan 目錄與 agent 選擇行為，以及工具能力特定的 `cash-audit` workflows（Codex standalone/discipline 相對於 Claude report-only）。不存在於那些 manifests 中的任何差異 MUST 使套件失敗。套件 MUST NOT 以不透明的 digests 或大範圍忽略區域取代可讀的 manifests。

#### Scenario: 未列入的本文漂移使對等失敗

- **GIVEN** 一個變體在沒有明確允許清單條目的情況下省略或更改某個 workflow 段落
- **WHEN** 變體對等執行
- **THEN** 套件以非零結束並指出該 skill 配對

#### Scenario: 工具能力差異維持可審閱

- **GIVEN** 某對配對 skill 因工具能力不同而需要不同的 frontmatter、fork 行為、plan 整合、agent 選擇或 audit 執行
- **WHEN** 變體對等執行
- **THEN** 每個有差異的行都在該 skill 的精確 manifest 中可見
- **AND** 更改任一變體而未更新已審閱的 manifest 會使套件失敗


<!-- @trace
source: fork-spectra-skills-to-cash
updated: 2026-07-18
code:
  - scripts/spectra-plus/template/impact-granularity-block.md
  - .agents/skills/spectra-propose-plus/SKILL.md
  - .agents/skills/cash-archive/SKILL.md
  - .agents/skills/cash-apply/SKILL.md
  - .agents/skills/cash-verify/SKILL.md
  - .agents/skills/cash-ingest/SKILL.md
  - scripts/cash-skills/variant-parity/cash-drift.diff
  - scripts/spectra-plus/template/review-loop-block.md
  - .agents/skills/cash-ask/SKILL.md
  - .agents/skills/cash-debug/SKILL.md
  - .agents/skills/spectra-apply-plus/SKILL.md
  - scripts/spectra-plus/template/apply-response-language-block.md
  - install-cash-skills.fish
  - uninstall-spectra-plus-repair.fish
  - scripts/cash-skills/variant-parity/cash-verify.diff
  - scripts/spectra-plus/template/apply-notes-block.md
  - .agents/skills/spectra-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-propose.diff
  - .agents/skills/cash-propose/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ingest.diff
  - scripts/spectra-plus/template/no-park-end-block.md
  - .agents/skills/cash-discuss/SKILL.md
  - AGENTS.md
  - scripts/cash-skills/variant-parity/cash-audit.diff
  - scripts/spectra-plus/template/artifact-language-block.md
  - CASH-SKILLS.md
  - scripts/spectra-plus/repair-all.fish
  - scripts/spectra-plus/rules.yaml
  - .agents/skills/cash-analyze/SKILL.md
  - SPECTRA-PLUS.md
  - .agents/skills/cash-audit/SKILL.md
  - scripts/spectra-plus/template/signals-read-block.md
  - scripts/spectra-plus/template/surgical-simplicity-block.md
  - .agents/skills/cash-commit/SKILL.md
  - scripts/cash-skills/variant-parity/cash-ask.diff
  - scripts/spectra-plus/generate.fish
  - .agents/skills/cash-drift/SKILL.md
  - install-spectra-plus.fish
  - scripts/cash-skills/variant-parity/cash-analyze.diff
tests:
  - scripts/spectra-plus/tests/auto-restore-checks.fish
  - scripts/spectra-plus/tests/repair-all-checks.fish
  - scripts/spectra-plus/tests/installer-commit-guard-checks.fish
  - scripts/spectra-plus/tests/generator-checks.fish
  - scripts/cash-skills/tests/skill-checks.fish
-->

---

### Requirement: 現行文件反映 cash 所有權與清理

本 repository SHALL提供`CASH-SKILLS.md`作為當前的Cash workflow指南。該指南 MUST列出雙變體清單；說明project-local Cash CLI、直接安裝、strict bundle版本、mode-aware target receipt、registry指令、批次更新、dry-run、force、各狀態、結束行為、自無receipt安裝的遷移、Cash guidance migration、marker衝突、精確baseline標準Spectra skill removal、未知legacy內容的安全拒絕，以及bundle版本調升責任；保留一次性legacy修復自動化清理的順序；並述明Cash skills沒有週期性修復。`openspec/signals/README.md` MUST繼續將當前writer描述為Cash審查迴圈，同時保留歷史性的`## Occurrences` provenance文字。

#### Scenario: 當前的安裝與更新說明是完整的

- **WHEN**使用者閱讀`CASH-SKILLS.md`
- **THEN**文件提供單一installer進入點與所有直接、registry及batch commands
- **AND**它說明target何時因runtime、skill、guidance或receipt更新，何時因current或newer略過，何時被阻擋為conflict，何時歸類為failed
- **AND**它指明`cash-skills.version`、`.cash-skills/receipt.tsv`、`.cash-skills/bin/cash`與`$HOME/.config/cash-skills/projects.txt`
- **AND**它說明Cash guidance migration只管理marker spans、逐byte保留其餘內容，並在不合法marker時fail closed
- **AND**它說明成功migration只移除逐byte符合已知baseline的標準`spectra-*` directories，同名customization或未知legacy內容一律保留並fail closed

#### Scenario: 文件不再要求保留標準 Spectra skills

- **WHEN**contract suite掃描`CASH-SKILLS.md`與non-archive master requirements
- **THEN**不存在要求保留標準Spectra skills或只移除`spectra-*-plus`的現行規範
- **AND**合法legacy detector與歷史occurrence文字不被誤判

#### Scenario: 遷移文件沒有現行的修復指示

- **WHEN**使用者閱讀`CASH-SKILLS.md`與`openspec/signals/README.md`
- **THEN**現行指示使用Cash workflows、project-local Cash CLI、installer與一次性cleanup
- **AND**沒有任何現行指示要使用者產生或週期性修復plus或Cash skills
- **AND**歷史性的occurrence項目維持不變

<!-- @trace
source: replace-spectra-cli-with-cash-cli
updated: 2026-07-24
code:
  - .agents/skills/
  - .agents/skills/spectra-analyze/
  - .agents/skills/spectra-apply/
  - .agents/skills/spectra-archive/
  - .agents/skills/spectra-ask/
  - .agents/skills/spectra-audit/
  - .agents/skills/spectra-commit/
  - .agents/skills/spectra-debug/
  - .agents/skills/spectra-discuss/
  - .agents/skills/spectra-drift/
  - .agents/skills/spectra-ingest/
  - .agents/skills/spectra-propose/
  - .agents/skills/spectra-verify/
  - .cash-skills/bin/cash
  - .cash-skills/lib/cash_cli/
  - .cash-skills/receipt.tsv
  - .cash-skills/state/
  - .cash-skills/state/snapshots/
  - .cash-skills/state/touched/
  - .claude/skills/
  - .claude/skills/spectra-analyze/
  - .claude/skills/spectra-apply/
  - .claude/skills/spectra-archive/
  - .claude/skills/spectra-ask/
  - .claude/skills/spectra-audit/
  - .claude/skills/spectra-commit/
  - .claude/skills/spectra-debug/
  - .claude/skills/spectra-discuss/
  - .claude/skills/spectra-drift/
  - .claude/skills/spectra-ingest/
  - .claude/skills/spectra-propose/
  - .claude/skills/spectra-verify/
  - .spectra/
  - scripts/cash-cli/fixtures/
  - scripts/cash-cli/tests/
  - scripts/cash-skills/legacy-spectra-digests.tsv
  - scripts/cash-skills/tests/skill-checks.fish
tests:
-->

### Requirement: 手動的 cash 專案 registry

本 repository SHALL經由`install-cash-skills.fish`提供registry操作，每次呼叫恰好使用`--target <project>`、`--register <project>`、`--unregister <project>`、`--list`或`--all`其中之一。registry SHALL是`$HOME/.config/cash-skills/projects.txt`，每個非空行一個正規化絕對專案路徑，路徑 MUST NOT包含ASCII控制字元。每個registry支援的模式 MUST在使用既有registry前完整驗證它；registry變動 MUST使用同目錄暫存檔與atomic rename，且installer MUST NOT排程或啟動未來呼叫。`--register`的target除了既存non-symlink directory外，還 MUST是canonical Git worktree top-level，並具有安全、可讀、schema-valid的regular `openspec/config.yaml`；它與direct/batch target使用同一prerequisite validator。

#### Scenario: 首次 register 建立安全狀態

- **GIVEN**cash-skills組態目錄與registry在安全HOME之下不存在
- **WHEN**`--register <project>`收到符合全部target prerequisites的target
- **THEN**installer僅建立所需組態目錄與atomic發佈的registry

#### Scenario: 缺失 registry 對讀取與移除模式視為空

- **GIVEN**cash-skills組態目錄與registry在安全HOME之下不存在
- **WHEN**`--unregister <project>`、`--list`或`--all`執行
- **THEN**installer對空清單成功執行且不建立狀態
- **AND**`--all`印出零計數摘要

#### Scenario: Register 正規化、去重並驗證 prerequisite

- **WHEN**`--register <project>`收到既存non-symlink directory
- **THEN**installer先canonicalize並要求該path恰為Git worktree top-level且具有安全有效的`openspec/config.yaml`
- **AND**成功時恰好儲存一次canonical absolute path並保持其他有效項目不變
- **AND**non-Git、Git子目錄、missing/unsafe/invalid config都以非零結束且registry零寫入

#### Scenario: Register 拒絕行導向 path injection

- **WHEN**register或unregister輸入包含tab、CR、LF或其他ASCII控制字元
- **THEN**installer以非零結束
- **AND**它不建立也不修改registry

#### Scenario: 既有 registry 紀錄拒絕殘留控制字元

- **WHEN**以LF分隔的既有registry紀錄包含tab、CR或其他殘留ASCII控制字元
- **THEN**每個registry支援的installer mode以非零結束
- **AND**它不建立也不修改registry或任何target

#### Scenario: Unregister 移除既存或過時 target

- **WHEN**`--unregister <project>`識別出canonical既存target，或不含dot segment且與儲存值完全一致的absolute stale target
- **THEN**installer以atomic方式移除該項目
- **AND**缺失項目是成功no-op

#### Scenario: List 是唯讀的

- **WHEN**`--list`收到有效registry
- **THEN**它印出去重後的canonical項目
- **AND**它不建立也不修改任何registry、target、receipt、skill、temporary file或background process

#### Scenario: 無效 registry fail closed

- **WHEN**registry不可讀，或包含relative path、root path、dot segment、malformed line或unsafe boundary
- **THEN**`--register`、`--unregister`、`--list`與`--all`在處理target或重寫registry前以非零結束
- **AND**沒有任何registry或target state被修改

<!-- @trace
source: replace-spectra-cli-with-cash-cli
updated: 2026-07-24
code:
  - .agents/skills/
  - .agents/skills/spectra-analyze/
  - .agents/skills/spectra-apply/
  - .agents/skills/spectra-archive/
  - .agents/skills/spectra-ask/
  - .agents/skills/spectra-audit/
  - .agents/skills/spectra-commit/
  - .agents/skills/spectra-debug/
  - .agents/skills/spectra-discuss/
  - .agents/skills/spectra-drift/
  - .agents/skills/spectra-ingest/
  - .agents/skills/spectra-propose/
  - .agents/skills/spectra-verify/
  - .cash-skills/bin/cash
  - .cash-skills/lib/cash_cli/
  - .cash-skills/receipt.tsv
  - .cash-skills/state/
  - .cash-skills/state/snapshots/
  - .cash-skills/state/touched/
  - .claude/skills/
  - .claude/skills/spectra-analyze/
  - .claude/skills/spectra-apply/
  - .claude/skills/spectra-archive/
  - .claude/skills/spectra-ask/
  - .claude/skills/spectra-audit/
  - .claude/skills/spectra-commit/
  - .claude/skills/spectra-debug/
  - .claude/skills/spectra-discuss/
  - .claude/skills/spectra-drift/
  - .claude/skills/spectra-ingest/
  - .claude/skills/spectra-propose/
  - .claude/skills/spectra-verify/
  - .spectra/
  - scripts/cash-cli/fixtures/
  - scripts/cash-cli/tests/
  - scripts/cash-skills/legacy-spectra-digests.tsv
  - scripts/cash-skills/tests/skill-checks.fish
tests:
-->

### Requirement: 版本感知的 cash skill 批次安裝

`install-cash-skills.fish --all [--dry-run] [--force]` SHALL重用與`--target`相同的完整installer target workflow，處理每個去重後的registry target。每個target MUST先驗證為Git worktree top-level且具有安全有效的`openspec/config.yaml`，並以stable launcher/lock bootstrap、replaceable runtime generation、24個skills、contract modes、Cash config validation/migration、guidance、receipt與精確baseline legacy removal構成同一managed decision。它 MUST將每個target回報為`updated`、`would-update`、`current`、`newer`、`conflict`或`failed`，然後印出每種狀態的計數。單一target的conflict或failed MUST NOT停止後續targets，且任何target為`conflict`或`failed`時，彙總指令 MUST以非零結束。

#### Scenario: 較舊 bundle 或 managed drift 被更新

- **GIVEN**registry包含有效且乾淨的targets，其receipt版本分別舊於、等於與新於source
- **AND**等版本target的stable launcher/lock與replaceable runtime/skill bytes及modes皆符合receipt
- **AND**其中一個等版本target含可安全遷移的config、guidance或legacy baseline drift，其餘等版本target為canonical
- **WHEN**installer以`--all`執行
- **THEN**較舊target與可安全收斂的等版本target回報`updated`
- **AND**等版本且完整canonical的target回報`current`
- **AND**較新的target回報`newer`
- **AND**current或newer target的stable bootstrap、runtime generation、skills、config、guidance、receipt及legacy candidates皆零寫入

#### Scenario: 批次揭露等版本的 source 完整性失敗

- **GIVEN**某個target具有等於source版本的有效receipt
- **AND**至少一個目前source replaceable runtime/skill digest或contract mode與該版本引入commit不符，或stable bootstrap source不符固定baseline
- **WHEN**installer以`--all`或`--all --force`執行
- **THEN**該target回報`failed`、零target write且彙總非零

#### Scenario: 除非明確 force 否則 managed drift 被保留

- **GIVEN**較舊或等版本target的replaceable runtime/skill bytes或mode相對有效receipt drift
- **WHEN**installer未帶`--force`
- **THEN**target回報`conflict`且所有managed及project-owned state零寫入
- **WHEN**相同target再次帶`--force`
- **THEN**installer持有並保留stable lock/launcher inode，只收斂replaceable runtime/skills/modes、Cash managed guidance spans、receipt及精確baseline legacy candidates
- **AND**project-owned config與其他bytes維持不變，target回報`updated`

#### Scenario: Force 從不降級較新的 target

- **GIVEN**有效target receipt版本高於source
- **WHEN**installer以`--all --force`執行
- **THEN**target回報`newer`
- **AND**stable bootstrap、runtime generation、skills、modes、config、guidance、receipt與legacy candidates全部零寫入

#### Scenario: Target 失敗不停止批次

- **GIVEN**一個registered target因Git/config、receipt、guidance、legacy identity或filesystem validation失敗，且較後target可更新
- **WHEN**installer以`--all`執行
- **THEN**第一個target回報`failed`
- **AND**installer繼續更新較後target並以非零彙總

#### Scenario: 批次 dry run 使用完整驗證且不寫入

- **WHEN**installer以`--all --dry-run`執行
- **THEN**每個target接受與real run相同的Git/config、source inventory/mode、receipt/version、guidance、legacy identity、transaction及filesystem boundary驗證
- **AND**計畫中的任何runtime、skill、config、guidance、receipt或legacy removal更新回報`would-update`
- **AND**target、registry與persistent state零寫入；system temporary validation snapshots在該target invocation結束時清除

<!-- @trace
source: replace-spectra-cli-with-cash-cli
updated: 2026-07-24
code:
  - .agents/skills/
  - .agents/skills/spectra-analyze/
  - .agents/skills/spectra-apply/
  - .agents/skills/spectra-archive/
  - .agents/skills/spectra-ask/
  - .agents/skills/spectra-audit/
  - .agents/skills/spectra-commit/
  - .agents/skills/spectra-debug/
  - .agents/skills/spectra-discuss/
  - .agents/skills/spectra-drift/
  - .agents/skills/spectra-ingest/
  - .agents/skills/spectra-propose/
  - .agents/skills/spectra-verify/
  - .cash-skills/bin/cash
  - .cash-skills/lib/cash_cli/
  - .cash-skills/receipt.tsv
  - .cash-skills/state/
  - .cash-skills/state/snapshots/
  - .cash-skills/state/touched/
  - .claude/skills/
  - .claude/skills/spectra-analyze/
  - .claude/skills/spectra-apply/
  - .claude/skills/spectra-archive/
  - .claude/skills/spectra-ask/
  - .claude/skills/spectra-audit/
  - .claude/skills/spectra-commit/
  - .claude/skills/spectra-debug/
  - .claude/skills/spectra-discuss/
  - .claude/skills/spectra-drift/
  - .claude/skills/spectra-ingest/
  - .claude/skills/spectra-propose/
  - .claude/skills/spectra-verify/
  - .spectra/
  - scripts/cash-cli/fixtures/
  - scripts/cash-cli/tests/
  - scripts/cash-skills/legacy-spectra-digests.tsv
  - scripts/cash-skills/tests/skill-checks.fish
tests:
-->

### Requirement: Spec 檔案語言政策

所有 spec 檔（openspec/changes/<change>/specs/<capability>/spec.md 的 delta spec 與 openspec/specs/<capability>/spec.md 的 master spec）的內文 SHALL 以繁體中文撰寫，包含 Requirement 敘述、Scenario 步驟、Example 說明與 Purpose 段落。下列結構關鍵字 MUST 逐字保留英文：`## ADDED Requirements`、`## MODIFIED Requirements`、`## REMOVED Requirements`、`## RENAMED Requirements`、`### Requirement:`、`#### Scenario:`、`##### Example:`，以及 Scenario 步驟中的 **GIVEN** / **WHEN** / **THEN** / **AND** 標記。規範動詞 SHALL / MUST / SHOULD / MAY MUST 以英文嵌入中文句子使用。程式識別字、檔案路徑、CLI 指令、schema 欄位名，以及自其他文件引用的原文 MUST 逐字保留，不得翻譯。openspec/changes/archive/ 下的歷史 spec 檔為歷史紀錄，不受本政策約束，SHALL NOT 回溯翻譯。

#### Scenario: 新撰寫的 delta spec 使用中文內文與英文結構關鍵字

- **WHEN** cash-propose 為某 capability 產生 delta spec
- **THEN** Requirement 敘述與 Scenario 步驟以繁體中文撰寫
- **AND** 結構關鍵字（如 `### Requirement:`、`#### Scenario:`、**WHEN** / **THEN**）維持英文
- **AND** 規範動詞（SHALL / MUST）以英文嵌入中文句子

##### Example: 符合政策的 requirement 條文

- **GIVEN** 一條關於匯出功能的需求
- **WHEN** 依本政策撰寫其 spec 條文
- **THEN** 條文形如：「系統 SHALL 在使用者觸發匯出時，將結果寫入 `exports/` 目錄，且檔名 MUST 使用 `YYYY-MM-DD` 前綴。」

#### Scenario: 引用原文與識別字不翻譯

- **WHEN** spec 條文需要引用 SKILL.md 或其他英文文件中的字面內容（例如 `None; pass condition met.`）
- **THEN** 該引用逐字保留英文原文
- **AND** 檔案路徑與 CLI 指令（例如 `.cash-skills/bin/cash validate --strict`）逐字保留

<!-- @trace
source: replace-spectra-cli-with-cash-cli
updated: 2026-07-24
code:
  - .agents/skills/
  - .agents/skills/spectra-analyze/
  - .agents/skills/spectra-apply/
  - .agents/skills/spectra-archive/
  - .agents/skills/spectra-ask/
  - .agents/skills/spectra-audit/
  - .agents/skills/spectra-commit/
  - .agents/skills/spectra-debug/
  - .agents/skills/spectra-discuss/
  - .agents/skills/spectra-drift/
  - .agents/skills/spectra-ingest/
  - .agents/skills/spectra-propose/
  - .agents/skills/spectra-verify/
  - .cash-skills/bin/cash
  - .cash-skills/lib/cash_cli/
  - .cash-skills/receipt.tsv
  - .cash-skills/state/
  - .cash-skills/state/snapshots/
  - .cash-skills/state/touched/
  - .claude/skills/
  - .claude/skills/spectra-analyze/
  - .claude/skills/spectra-apply/
  - .claude/skills/spectra-archive/
  - .claude/skills/spectra-ask/
  - .claude/skills/spectra-audit/
  - .claude/skills/spectra-commit/
  - .claude/skills/spectra-debug/
  - .claude/skills/spectra-discuss/
  - .claude/skills/spectra-drift/
  - .claude/skills/spectra-ingest/
  - .claude/skills/spectra-propose/
  - .claude/skills/spectra-verify/
  - .spectra/
  - scripts/cash-cli/fixtures/
  - scripts/cash-cli/tests/
  - scripts/cash-skills/legacy-spectra-digests.tsv
  - scripts/cash-skills/tests/skill-checks.fish
tests:
-->

### Requirement: Requirement 標題是合併身分鍵

delta spec 中 `## MODIFIED Requirements` 與 `## REMOVED Requirements` 區段下的每個 `### Requirement:` 標題、以及 `## RENAMED Requirements` 區段中的 FROM 標題，MUST 從對應 master spec 現行內容逐字（byte-for-byte）複製，不得重打、改寫或翻譯。cash-propose 與 cash-apply 的 pre-round mechanical self-check MUST 對上述每個標題執行存在性檢查（**Spec delta title-identity check**）：標題必須逐字存在於對應 master spec `openspec/specs/<capability>/spec.md` 的 `### Requirement:` 標題集合中；master spec 尚不存在的 capability SHALL 跳過此檢查。任何不吻合 MUST 視為 self-check 失敗，並且 MUST 在 spawn reviewers 之前以「從 master spec 逐字複製標題」的方式修復。

#### Scenario: 標題逐字存在時檢查通過

- **GIVEN** master spec 含標題 `### Requirement: 匯出檔案處理`
- **WHEN** delta spec 在 `## MODIFIED Requirements` 下使用逐字相同的標題
- **THEN** self-check 的標題身分鍵檢查通過

#### Scenario: 標題不吻合時必須在 review 前修復

- **GIVEN** delta spec 的 MODIFIED 標題在對應 master spec 中不存在（例如被重打或翻譯過）
- **WHEN** pre-round mechanical self-check 執行
- **THEN** 該標題被判定為 self-check 失敗
- **AND** 失敗 MUST 在 spawn reviewers 之前修復，因為 `.cash-skills/bin/cash validate` 與 `.cash-skills/bin/cash sync` MUST 拒絕不吻合的標題

#### Scenario: 尚無 master spec 的新 capability 跳過檢查

- **WHEN** delta spec 的 capability 在 openspec/specs/ 下尚無 master spec
- **THEN** 標題身分鍵檢查對該 capability 跳過
- **AND** 該 delta 的 `## ADDED Requirements` 不受標題比對約束

<!-- @trace
source: replace-spectra-cli-with-cash-cli
updated: 2026-07-24
code:
  - .agents/skills/
  - .agents/skills/spectra-analyze/
  - .agents/skills/spectra-apply/
  - .agents/skills/spectra-archive/
  - .agents/skills/spectra-ask/
  - .agents/skills/spectra-audit/
  - .agents/skills/spectra-commit/
  - .agents/skills/spectra-debug/
  - .agents/skills/spectra-discuss/
  - .agents/skills/spectra-drift/
  - .agents/skills/spectra-ingest/
  - .agents/skills/spectra-propose/
  - .agents/skills/spectra-verify/
  - .cash-skills/bin/cash
  - .cash-skills/lib/cash_cli/
  - .cash-skills/receipt.tsv
  - .cash-skills/state/
  - .cash-skills/state/snapshots/
  - .cash-skills/state/touched/
  - .claude/skills/
  - .claude/skills/spectra-analyze/
  - .claude/skills/spectra-apply/
  - .claude/skills/spectra-archive/
  - .claude/skills/spectra-ask/
  - .claude/skills/spectra-audit/
  - .claude/skills/spectra-commit/
  - .claude/skills/spectra-debug/
  - .claude/skills/spectra-discuss/
  - .claude/skills/spectra-drift/
  - .claude/skills/spectra-ingest/
  - .claude/skills/spectra-propose/
  - .claude/skills/spectra-verify/
  - .spectra/
  - scripts/cash-cli/fixtures/
  - scripts/cash-cli/tests/
  - scripts/cash-skills/legacy-spectra-digests.tsv
  - scripts/cash-skills/tests/skill-checks.fish
tests:
-->

### Requirement: Cash 指引提供無向量模型替代流程

`AGENTS.md` 與 `CLAUDE.md` 的 canonical Cash blocks MUST逐byte包含下列完整Markdown block，不得摘要、重排或省略。此block最上方 MUST為全域繁體中文回覆規則，使未進入任何cash skill的一般對話也預設以繁體中文回覆；該規則獨立於各skill的`Response language`段落。Installer MUST NOT偵測vector model狀態、執行semantic search或下載model；所有lifecycle fallback MUST使用project-local Cash CLI。

#### Scenario: Canonical guidance block 完整輸出

- **WHEN**installer擷取或render canonical Cash guidance
- **THEN**下列Markdown block逐byte出現在對應variant
- **AND**全域繁體中文回覆規則、code fence、阻塞分類與Cash-owned fallback皆完整

#### Scenario: 全域回覆語言規則位於 block 最上方

- **WHEN**檢視任一variant的canonical Cash block
- **THEN**block最上方逐byte包含`本專案所有面向使用者的回覆一律以繁體中文撰寫，除非使用者明確要求其他語言。`起始的回覆語言規則
- **AND**該規則出現在阻塞分類requirement與Cash-owned fallback之前

```markdown

本專案所有面向使用者的回覆一律以繁體中文撰寫，除非使用者明確要求其他語言。shell 指令、檔案路徑、程式識別字、schema 欄位名與引用原文逐字保留。

---

<!-- @trace
source: replace-spectra-cli-with-cash-cli
updated: 2026-07-24
code:
  - .agents/skills/
  - .agents/skills/spectra-analyze/
  - .agents/skills/spectra-apply/
  - .agents/skills/spectra-archive/
  - .agents/skills/spectra-ask/
  - .agents/skills/spectra-audit/
  - .agents/skills/spectra-commit/
  - .agents/skills/spectra-debug/
  - .agents/skills/spectra-discuss/
  - .agents/skills/spectra-drift/
  - .agents/skills/spectra-ingest/
  - .agents/skills/spectra-propose/
  - .agents/skills/spectra-verify/
  - .cash-skills/bin/cash
  - .cash-skills/lib/cash_cli/
  - .cash-skills/receipt.tsv
  - .cash-skills/state/
  - .cash-skills/state/snapshots/
  - .cash-skills/state/touched/
  - .claude/skills/
  - .claude/skills/spectra-analyze/
  - .claude/skills/spectra-apply/
  - .claude/skills/spectra-archive/
  - .claude/skills/spectra-ask/
  - .claude/skills/spectra-audit/
  - .claude/skills/spectra-commit/
  - .claude/skills/spectra-debug/
  - .claude/skills/spectra-discuss/
  - .claude/skills/spectra-drift/
  - .claude/skills/spectra-ingest/
  - .claude/skills/spectra-propose/
  - .claude/skills/spectra-verify/
  - .spectra/
  - scripts/cash-cli/fixtures/
  - scripts/cash-cli/tests/
  - scripts/cash-skills/legacy-spectra-digests.tsv
  - scripts/cash-skills/tests/skill-checks.fish
tests:
-->

### Requirement: cash-apply 任務迴圈的阻塞分類

`cash-apply` 在 task loop 遇到實作阻塞時，SHALL 依「觀察到的 contract 是否改變」把阻塞分類為兩類並採取對應處置：機制替換（contract 不變）記一筆 Implementation Notes Protocol 的 `deviation` 條目後繼續，contract／範圍／行為變更則暫停並引導使用者前往 `cash-ingest`。此分類的暫停判準 MUST 逐字內嵌 Fix-loop design circuit breaker 觸發條件的英文片語 `a synchronization primitive, identity/generation type, or state machine not defined in design.md`，使 task-loop 與 review-loop 對「何謂真正的 design 變更」使用同一個可稽核的邊界字串。兩分支 MUST 互斥：當機制替換分支的條件全部成立時走機制替換分支，「在多個都保留 contract 的替代手段之間選一個」的內部選擇 SHALL 以記 `deviation` 解決，不觸發暫停分支。兩個分類分支 MUST 優先於通用 error／blocker fallback；該 fallback MUST 僅處理未被 blocker triage 涵蓋的其他錯誤或阻塞。此 requirement 適用於 `cash-apply` 的兩個變體（`.claude` 與 `.agents`）。

#### Scenario: 機制替換且 contract 不變則記 deviation 後繼續

- **WHEN** 某個 task 的阻塞是「原設計指定的達成手段在目標平台或現實不可行」
- **AND** 要交付的觀察行為、interface／資料形狀、失敗模式與驗收標準都不變
- **AND** 替代手段不需要 `a synchronization primitive, identity/generation type, or state machine not defined in design.md`
- **THEN** `cash-apply` 依 Implementation Notes Protocol 記一筆 `類別：deviation` 條目
- **AND** 繼續實作該 task，不暫停，也不要求 `cash-ingest`

#### Scenario: contract、範圍或行為變更則暫停並導向 ingest

- **WHEN** 某個 task 的阻塞改變了要交付的觀察行為、範圍或使用者可見的取捨
- **THEN** `cash-apply` 暫停並報告該 blocker
- **AND** 引導使用者前往 `cash-ingest`

#### Scenario: 解答可能改變 contract 的 open question 則暫停

- **WHEN** 某個 task 存在其解答可能改變 contract 或範圍、需要使用者決定的 open question
- **THEN** `cash-apply` 暫停並引導使用者前往 `cash-ingest`

#### Scenario: 替代手段需要未定義的設計機制則暫停

- **WHEN** 某個 task 的替代手段需要 `a synchronization primitive, identity/generation type, or state machine not defined in design.md`
- **THEN** `cash-apply` 走暫停分支而非繼續分支
- **AND** 引導使用者前往 `cash-ingest`

#### Scenario: 保留 contract 的內部手段選擇不觸發暫停

- **WHEN** 機制替換分支的全部條件成立
- **AND** 在多個都保留 contract 的替代手段之間存在需要選擇的內部問題
- **THEN** `cash-apply` 走機制替換分支，以記 `deviation` 解決該選擇
- **AND** 不因該內部選擇而暫停

#### Scenario: 兩個變體保持對等

- **WHEN** 比較 `.claude/skills/cash-apply/SKILL.md` 與 `.agents/skills/cash-apply/SKILL.md` 的阻塞分類段落
- **THEN** 兩者在 invocation 前綴（`/cash-` 與 `$cash-`）正規化後 MUST 完全相同

## Cash-owned artifact fallback

- 使用者直接給 change 名稱 → 直接讀 `openspec/changes/<name>/` 底下的 artifacts；找不到時，先以 `git rev-parse --show-toplevel` 解析root，再執行該root下 `.cash-skills/bin/cash list --parked --json`
- 問程式碼或需求相關的問題 → 先使用 `.cash-skills/bin/cash search "<query>" --limit 10 --json`，合法zero-result再以 Grep／Read 搜尋 `openspec/specs/` 與程式碼
```

#### Scenario: 已知 change名稱時使用 Cash lifecycle

- **WHEN** 使用者直接提供 change名稱
- **THEN** agent直接讀取 `openspec/changes/<name>/` 下的 artifacts
- **AND** 找不到active change時使用project-local Cash CLI確認parked狀態
- **AND** agent不要求model或index

#### Scenario: 程式碼或需求問題使用 lexical fallback

- **WHEN** 使用者詢問程式碼或需求相關問題
- **THEN** agent先使用Cash lexical search
- **AND** 合法zero-result時再使用Grep／Read
- **AND** execution error MUST明確回報而不偽裝成zero-result

<!-- @trace
source: replace-spectra-cli-with-cash-cli
updated: 2026-07-24
code:
  - .agents/skills/
  - .agents/skills/spectra-analyze/
  - .agents/skills/spectra-apply/
  - .agents/skills/spectra-archive/
  - .agents/skills/spectra-ask/
  - .agents/skills/spectra-audit/
  - .agents/skills/spectra-commit/
  - .agents/skills/spectra-debug/
  - .agents/skills/spectra-discuss/
  - .agents/skills/spectra-drift/
  - .agents/skills/spectra-ingest/
  - .agents/skills/spectra-propose/
  - .agents/skills/spectra-verify/
  - .cash-skills/bin/cash
  - .cash-skills/lib/cash_cli/
  - .cash-skills/receipt.tsv
  - .cash-skills/state/
  - .cash-skills/state/snapshots/
  - .cash-skills/state/touched/
  - .claude/skills/
  - .claude/skills/spectra-analyze/
  - .claude/skills/spectra-apply/
  - .claude/skills/spectra-archive/
  - .claude/skills/spectra-ask/
  - .claude/skills/spectra-audit/
  - .claude/skills/spectra-commit/
  - .claude/skills/spectra-debug/
  - .claude/skills/spectra-discuss/
  - .claude/skills/spectra-drift/
  - .claude/skills/spectra-ingest/
  - .claude/skills/spectra-propose/
  - .claude/skills/spectra-verify/
  - .spectra/
  - scripts/cash-cli/fixtures/
  - scripts/cash-cli/tests/
  - scripts/cash-skills/legacy-spectra-digests.tsv
  - scripts/cash-skills/tests/skill-checks.fish
tests:
-->

### Requirement: Cash CLI cutover 覆蓋全部 live workflow surfaces

兩個variant的十二個canonical Cash skills SHALL將所有artifact engine操作路由到`.cash-skills/bin/cash`，並 MUST移除`Requires spectra CLI`與任何Spectra binary fallback。installer、guidance、live docs與contract tests MUST使用同一project-local command namespace；標準`spectra-*` skills MUST從canonical inventory與安全辨識的installer targets移除。`openspec/changes/archive/`與signal occurrence history SHALL保持原文。

#### Scenario: Spectra binary 不存在時完整 workflow 可用

- **GIVEN**PATH中不存在Spectra binary且Cash bundle已完整安裝
- **WHEN**依序執行Cash propose、apply、verify與archive workflows所需的全部artifact operations
- **THEN**每個operation由project-local Cash CLI完成
- **AND**沒有workflow因缺少Spectra binary而停止

#### Scenario: Live residue scan 封鎖遺漏

- **WHEN**contract suite掃描canonical skills、guidance、live docs、installer與non-archive specs
- **THEN**任何可執行的Spectra command或`Requires spectra CLI`使測試失敗
- **AND**明列的legacy migration detector與歷史archive不被改寫

<!-- @trace
source: replace-spectra-cli-with-cash-cli
updated: 2026-07-24
code:
  - .agents/skills/
  - .agents/skills/spectra-analyze/
  - .agents/skills/spectra-apply/
  - .agents/skills/spectra-archive/
  - .agents/skills/spectra-ask/
  - .agents/skills/spectra-audit/
  - .agents/skills/spectra-commit/
  - .agents/skills/spectra-debug/
  - .agents/skills/spectra-discuss/
  - .agents/skills/spectra-drift/
  - .agents/skills/spectra-ingest/
  - .agents/skills/spectra-propose/
  - .agents/skills/spectra-verify/
  - .cash-skills/bin/cash
  - .cash-skills/lib/cash_cli/
  - .cash-skills/receipt.tsv
  - .cash-skills/state/
  - .cash-skills/state/snapshots/
  - .cash-skills/state/touched/
  - .claude/skills/
  - .claude/skills/spectra-analyze/
  - .claude/skills/spectra-apply/
  - .claude/skills/spectra-archive/
  - .claude/skills/spectra-ask/
  - .claude/skills/spectra-audit/
  - .claude/skills/spectra-commit/
  - .claude/skills/spectra-debug/
  - .claude/skills/spectra-discuss/
  - .claude/skills/spectra-drift/
  - .claude/skills/spectra-ingest/
  - .claude/skills/spectra-propose/
  - .claude/skills/spectra-verify/
  - .spectra/
  - scripts/cash-cli/fixtures/
  - scripts/cash-cli/tests/
  - scripts/cash-skills/legacy-spectra-digests.tsv
  - scripts/cash-skills/tests/skill-checks.fish
tests:
-->

### Requirement: Cash-owned 設定與無向量模型 fallback

Cash workflows SHALL只讀取`.cash.yaml`runtime設定。`cash-ask` MUST使用Cash lexical search；合法zero-result SHALL回傳empty result且不中斷，execution error MUST明確失敗。guidance在已知change name時 SHALL直接讀取active artifacts並以`.cash-skills/bin/cash list --parked --json`確認parked狀態，且 MUST NOT要求vector model或index。

#### Scenario: 已知 change名稱時不依賴向量模型

- **GIVEN**使用者直接提供change名稱
- **WHEN**active path不存在
- **THEN**agent使用Cash CLI確認parked identity
- **AND**agent不要求下載model或建立index

#### Scenario: Lexical search execution error 不被當成無結果

- **WHEN**Cash lexical search遇到unreadable artifact或invalid query
- **THEN**`cash-ask`回報execution error
- **AND**不輸出zero-result訊息

<!-- @trace
source: replace-spectra-cli-with-cash-cli
updated: 2026-07-24
code:
  - .agents/skills/
  - .agents/skills/spectra-analyze/
  - .agents/skills/spectra-apply/
  - .agents/skills/spectra-archive/
  - .agents/skills/spectra-ask/
  - .agents/skills/spectra-audit/
  - .agents/skills/spectra-commit/
  - .agents/skills/spectra-debug/
  - .agents/skills/spectra-discuss/
  - .agents/skills/spectra-drift/
  - .agents/skills/spectra-ingest/
  - .agents/skills/spectra-propose/
  - .agents/skills/spectra-verify/
  - .cash-skills/bin/cash
  - .cash-skills/lib/cash_cli/
  - .cash-skills/receipt.tsv
  - .cash-skills/state/
  - .cash-skills/state/snapshots/
  - .cash-skills/state/touched/
  - .claude/skills/
  - .claude/skills/spectra-analyze/
  - .claude/skills/spectra-apply/
  - .claude/skills/spectra-archive/
  - .claude/skills/spectra-ask/
  - .claude/skills/spectra-audit/
  - .claude/skills/spectra-commit/
  - .claude/skills/spectra-debug/
  - .claude/skills/spectra-discuss/
  - .claude/skills/spectra-drift/
  - .claude/skills/spectra-ingest/
  - .claude/skills/spectra-propose/
  - .claude/skills/spectra-verify/
  - .spectra/
  - scripts/cash-cli/fixtures/
  - scripts/cash-cli/tests/
  - scripts/cash-skills/legacy-spectra-digests.tsv
  - scripts/cash-skills/tests/skill-checks.fish
tests:
-->
