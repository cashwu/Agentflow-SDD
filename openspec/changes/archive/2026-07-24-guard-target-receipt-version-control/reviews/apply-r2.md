# Cash Apply Review — Round 2

## Reviewer Findings

### Critical

（無）

### Warning

（無）

### Suggestion

1. **`core.fsmonitor` 的清除是安全性質，但未反映在任何 artifact**
   - `severity`: Suggestion
   - `confidence`: 55
   - `layer`: design
   - `location`: `openspec/changes/guard-target-receipt-version-control/design.md:56,80` 與 `specs/cash-cli/spec.md:17`
   - `summary`: round 1 的修復讓「唯讀 index 查詢」額外意謂「MUST NOT 執行由 target repository 自身 config 指定的程式」，但此性質只存在於 `installer.py` 與一個測試中；design 的 `### Command interfaces and data shapes` 該列仍只寫 `唯讀 index 查詢；輸出至 stderr，每個 target 一行`，spec 段落也只約束 index-vs-ignore。日後依 artifact 重新實作會再度引入該攻擊面。
   - `recommendation`: 在 spec 的版控狀態偵測段落與 design 對應列各補一句：該查詢 MUST NOT 執行由 target repository 設定的程式。
   - `disposition`: fix-introduced
   - `introduced_by`: `apply-r1.md` `## Fix Actions` 第 2 項——程式碼與測試加上 `-c core.fsmonitor=`，但未同步更新 artifact。
   - reviewer source: Reviewer V

2. **新增的六個 `skill-checks.fish` 文件 literal 中有一個是空洞斷言**
   - `severity`: Suggestion
   - `confidence`: 60
   - `layer`: design（reviewer 原標 `text`；主 agent 依 confidence filter 重新分類，因為該修復會改變 contract test 實際強制的內容，非純同步性文字）
   - `location`: `scripts/cash-skills/tests/skill-checks.fish:199`
   - `summary`: `'.cash-skills/state/'` 在本次變更前就已出現於 `CASH-SKILLS.md`（namespace-scan 段落），因此即使整個 `## Target 版控排除保護` 段落被刪除，該斷言仍會通過。其餘五個 literal 各自唯一屬於新段落，確實能釘住該段落。
   - `recommendation`: 移除該 literal，或改為新段落專屬的措辭。
   - `disposition`: new
   - reviewer source: Reviewer V

## Rating

- post-filter cumulative blocking set Critical count: 0
- post-filter cumulative blocking set Warning count: 0
- 非阻塞 triaged finding count: 0
- `critical_gap`: false
- `round_type`: micro

Rationale：本輪為 micro round，Reviewer V 對累積阻塞集合的三個成員各自給出明確判定，全部為 `resolved`，並附獨立 fixture 證據與 vacuity control（M3 以鏡像倉庫還原抑制後重現 2 次輸出，證明修復為 load-bearing；M2 以 control run 證明未修補的 invocation 確實會執行 hook；M1 以 30 秒硬性 timeout 證明 FIFO 由 ≥8 秒阻塞變為 0.1 秒 execution error 且零寫入）。三個成員依「verified resolution」自累積阻塞集合移除後，集合為空。本輪兩個新 finding 的 confidence 分別為 55 與 60，落在 `[50, 80)` 而降級為 `Suggestion`；`Suggestion` 依定義不進入阻塞集合，`disposition: fix-introduced` 亦不使其成為阻塞。post-filter 累積阻塞集合不含任何阻塞 Critical 或 Warning，故決議為 `passed`。

### 累積阻塞集合的 verified-resolution 移除紀錄

| 成員 | fix reference | 驗證 reviewer |
| --- | --- | --- |
| M1 — FIFO `.gitignore` 阻塞而非 fail closed | `apply-r1.md` `## Fix Actions` 第 1 項（`ensure_regular_gitignore`／`fifo` 形狀測試／`install()` timeout） | Reviewer V（round 2） |
| M2 — `git ls-files` 執行 target repo 設定的 `core.fsmonitor` | `apply-r1.md` `## Fix Actions` 第 2 項（`-c core.fsmonitor=`／hook 不執行測試） | Reviewer V（round 2） |
| M3 — 版控診斷在重新分類重試時重複輸出 | `apply-r1.md` `## Fix Actions` 第 3 項（`announce_tracking`／每 target 一行測試） | Reviewer V（round 2） |

## Fix Actions

None; pass condition met.

（主 agent disposition 重新驗證：本輪兩個 finding 皆非位於 round 1 修復所觸及的缺陷位置以外的誤標。finding 1 的 `fix-introduced` 成立且已保留原標記；finding 2 標記為 `new`，經檢查該 literal 由 task 2.1 引入、未被任何 round 1 修復觸及，維持 `new`。無阻塞至非阻塞的 disposition 更正。無 `未修復：裁判面保護` 記錄。）

## Decision

passed
