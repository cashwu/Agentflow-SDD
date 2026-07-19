# signals-shared-layer Specification

## Purpose

TBD——由封存 change 'add-signals-shared-layer' 而建立。封存後請更新 Purpose。

## Requirements

### Requirement: Signals 共享層的位置與檔案 schema

系統 SHALL 將跨 change 的 signals（訊號）以個別 Markdown 檔案儲存於 `openspec/signals/` 之下，每個 signal 一個檔案，命名為 `openspec/signals/<slug>.md`。`<slug>` MUST 是一個簡短、人類可讀的 ASCII kebab-case 識別碼，用以命名該問題類別（issue class）（例如 `spec-requirement-no-backing-task`），並在 signal 首次建立時由寫入者指定。`<slug>` MUST NOT 是 finding 的自由文字 `location + summary` 的機械式轉換。`<slug>` MUST 符合 `^[a-z0-9]+(-[a-z0-9]+)*$`，因此永遠是有效且非空的檔名。每個 signal 檔案 MUST 以一個 YAML frontmatter 區塊開頭，其中恰好包含以下必要欄位：`id`（等於 slug）、`type`（`friction`、`idea`、`gap`、`recurring-finding` 之一）、`status`（`open`、`addressed`、`dismissed` 之一）、`occurrences`（非負整數）、`first_seen`（`YYYY-MM-DD` 日期）、`last_seen`（`YYYY-MM-DD` 日期），以及 `links`（專案根目錄相對來源路徑的清單）。frontmatter 另外允許恰好一個選用欄位：`check`——一條單行、由人工撰寫的 shell 命令，執行方式是從專案根目錄將其值作為單一命令字串引數傳給 `sh -c`；其中 exit code `0` 表示該 signal 的反模式（anti-pattern）不存在，exit code `1` 表示反模式存在，任何其他 exit code 則是執行錯誤而非偵測結果。`check` 命令 MUST 是唯讀的，且 MUST NOT 修改任何檔案。除了七個必要欄位與選用的 `check` 之外，不允許任何其他 frontmatter 欄位。frontmatter 之後，檔案 MUST 包含一個標題 heading、一段描述文字，以及一個 `## Occurrences` 區段，每次觀察在其中記錄一筆。

#### Scenario: Slug 是有效的 ASCII 問題類別識別碼

- **WHEN** 建立 signal 檔案 `openspec/signals/<slug>.md` 時
- **THEN** `<slug>` 符合 `^[a-z0-9]+(-[a-z0-9]+)*$`
- **AND** `<slug>` 不是由 finding 的自由文字 `location + summary` 機械式轉換而來

##### Example: 被指定的問題類別 slugs

| 問題類別 | 有效的 slug |
|-------------|------------|
| 某條 spec 的 SHALL 沒有對應的 backing task | `spec-requirement-no-backing-task` |
| 某個輸入邊界未處理空輸入 | `unhandled-empty-input` |

#### Scenario: Signal 檔案具有必要的 frontmatter 與 occurrences 區段

- **WHEN** 建立 signal 檔案 `openspec/signals/<slug>.md` 時
- **THEN** 其 frontmatter 包含 `id`、`type`、`status`、`occurrences`、`first_seen`、`last_seen` 與 `links`
- **AND** `id` 等於 `<slug>`
- **AND** `type` 是 `friction`、`idea`、`gap`、`recurring-finding` 之一
- **AND** `status` 是 `open`、`addressed`、`dismissed` 之一
- **AND** 內文包含一個 `## Occurrences` 區段，且至少有一筆記錄

##### Example: 最小 signal 檔案

- **GIVEN** 一個關於匯出檔案處理的重複出現 review finding
- **WHEN** 該 signal 於 2026-06-21 首次建立時
- **THEN** 檔案 frontmatter 具有 `id: export-file-handling`、`type: recurring-finding`、`status: open`、`occurrences: 1`、`first_seen: 2026-06-21`、`last_seen: 2026-06-21`
- **AND** `## Occurrences` 區段有一筆帶日期的記錄，指明來源 change 與 round 檔案

#### Scenario: 選用的 check 欄位承載一條確定性的偵測命令

- **WHEN** signal 檔案的 frontmatter 包含選用的 `check` 欄位時
- **THEN** 其值是一條單行、由人工撰寫的 shell 命令，可從專案根目錄經由 `sh -c` 執行
- **AND** exit code `0` 表示反模式不存在，exit code `1` 表示反模式存在，任何其他 exit code 則是執行錯誤
- **AND** 該命令是唯讀的，且不修改任何檔案

##### Example: 針對懸空註解反模式的 check 命令

- **GIVEN** 一個關於 spec 檔案中未閉合的 `@trace` 註解區塊的 signal
- **WHEN** signal 作者加入一條確定性的偵測命令時
- **THEN** frontmatter 包含一行諸如 `check: 'out=$(grep -rln ANNOTATION-OPEN-MARKER openspec/specs/ 2>&1); c=$?; if [ $c -eq 0 ]; then printf "%s\n" "$out"; exit 1; elif [ $c -eq 1 ]; then exit 0; else printf "%s\n" "$out" >&2; exit 2; fi'`——作為 `sh -c` 的單一引數執行時，它會印出符合的專案根目錄相對路徑並在反模式存在時以 `1` 結束，在反模式不存在時以 `0` 結束，而在 grep 本身出錯（例如路徑不存在）時以 `2` 結束，因此執行錯誤永遠不會被誤讀為偵測結果


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
### Requirement: Signals 目錄的 README 契約

系統 SHALL 提供 `openspec/signals/README.md` 來記載 signals 層。README MUST 描述哪些內容屬於 signals 層、哪些不屬於、signal 檔案 schema、「`<slug>` 是被指定的問題類別識別碼（而非 finding 文字的轉換）」這條規則，以及新增或更新 signal 的流程。README MUST 記載選用的 `check` frontmatter 欄位：其單行 shell 命令的形式、其執行方式（從專案根目錄將值作為單一引數傳給 `sh -c`）、exit code 慣例（`0` 表示反模式不存在，`1` 表示反模式存在，任何其他 exit code 則是執行錯誤）、`check` 命令由人工撰寫這條規則、`check` 命令 MUST 唯讀、快速、離線且非互動的撰寫規則、「偵測結果僅以 exit `0` 或 `1` 回報，而可預見的執行錯誤（例如路徑不存在）MUST 以另一個 exit code 浮現，不得被盲目取反壓縮成 `0` 或 `1`」這條規則，以及該欄位值的 YAML 單行引號陷阱（引號與 `#` 截斷）。README MUST 記載新撰寫且能指認具體實例的 `check` 命令會為偵測到的實例印出專案根目錄相對路徑，讓 cash review loop 能分類失敗是出在目前 change 的 artifacts 還是被修改的檔案。README MUST 記載給 `check` 作者的 shell 錯誤陷阱：POSIX `sh` 不提供 `pipefail`、管線狀態來自最後一個命令，且原生 exit code `1` 即代表執行錯誤的工具需要明確的 exit code 重新映射，使 `1` 保留給反模式存在的結果。README MUST 說明 signal `status` 轉換至 `addressed` 或 `dismissed` 是由人工手動執行，永遠不會自動套用。README MUST 記載打算創造新 `<slug>` 的寫入者要先列出既有的 `openspec/signals/*.md` 並挑選一個尚不存在的 slug，且建立 signal 永遠不會覆寫既有檔案。README MUST 註明並行整檔覆寫的風險：當兩次執行同時寫入同一個 `<slug>.md` 時——包括兩次執行各自為新問題類別獨立想出相同的自然 slug——落敗寫入者所附加的 `## Occurrences` 記錄與 `links`，或一整個新建立的 signal，都可能遺失；且 reviewer SHALL 拆分 `## Occurrences` 記錄描述互不相關問題的 signal。

#### Scenario: README 記載 schema、slug 指定規則與人工維護的 status

- **WHEN** 讀取 `openspec/signals/README.md` 時
- **THEN** 它描述 signals 的納入與排除規則
- **AND** 它記載 frontmatter schema 欄位
- **AND** 它記載選用的 `check` 欄位、其 `sh -c` 單一引數執行形式、其 exit code 慣例、由人工撰寫且唯讀、快速、離線、非互動的撰寫規則、「執行錯誤以 `0` 或 `1` 以外的 exit code 浮現」這條規則，以及 YAML 引號陷阱
- **AND** 它記載新撰寫且能指認具體實例的 `check` 命令會為偵測到的實例印出專案根目錄相對路徑
- **AND** 它記載 POSIX `sh` 的管線狀態行為，以及針對原生 exit code `1` 即代表執行錯誤的工具的 exit code 重新映射指引
- **AND** 它記載 `<slug>` 是被指定的問題類別識別碼，而非 finding 文字的轉換
- **AND** 它說明轉換至 `addressed` 與 `dismissed` 的 status 轉換是手動操作
- **AND** 它註明並行覆寫導致記錄遺失的風險與手動拆分指引


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
### Requirement: Signal status 生命週期由人工維護

系統 SHALL 將 signal 的 `status` 與選用的 `check` 欄位視為由人工維護。自動化寫入者 MAY 以 `status: open` 建立新 signal，也 MAY 更新既有 `open` signal 的 `occurrences`、`last_seen`、`links` 與 `## Occurrences` 記錄，但 MUST NOT 更改 signal 的 `status` 值，且 MUST NOT 新增、修改或移除 signal 的 `check` 欄位。將 signal 轉換為 `addressed` 或 `dismissed`，以及撰寫或編輯 `check` 命令，MUST 是人工手動操作。

#### Scenario: 自動化更新保留 status

- **WHEN** 自動化寫入者因底層問題再次被觀察到而更新既有的 `open` signal 時
- **THEN** 該寫入者遞增 `occurrences`、更新 `last_seen`、附加一筆 `## Occurrences` 記錄，並附加至 `links`
- **AND** 該寫入者不更改 `status` 欄位

#### Scenario: 自動化寫入者不重新開啟已解決的 signals

- **WHEN** 一個 signal 已是 `status: addressed` 或 `status: dismissed` 時
- **THEN** 自動化寫入者不會將其 `status` 改回 `open`

#### Scenario: 自動化寫入者永不撰寫 check 命令

- **WHEN** 自動化寫入者建立新 signal 或更新既有 signal 時（包括 review-loop 的 signals 寫入步驟）
- **THEN** 寫入的 signal 不包含 `check` 欄位，除非先前已有人工撰寫
- **AND** 任何既存的人工撰寫 `check` 欄位保持位元組不變

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