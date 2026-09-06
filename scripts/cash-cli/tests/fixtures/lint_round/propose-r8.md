# Cash Propose Review — Round 8

## Reviewer Findings

本輪為本次 seeded re-run 的第二輪，依位置推導為 `micro` 輪，由一位全新的 Reviewer V 進行差異驗證。Reviewer V 另對 Round 7 修正倚賴的 host／launcher 事實逐項核實：`.cash-skills/bin/cash` 的 `fail()` 以 exit 1 並在 stderr 輸出 `error[<code>]`、`python_version` 檢查與三種信任 gate 失敗皆早於 `from cash_cli.main import main`、`discovery.py:151-157` 要求目錄型且名稱符合 `[a-z][a-z0-9-]*`、`Workspace.discover` 在 runtime 內執行故「workspace 解析失敗」屬進入點之後可攔截。全部成立。

### 累積 blocking 集合逐成員裁定

- **N-1** — `resolved`。Reviewer V 逐一引述 design.md D6 第 2、4、5 段、Implementation Contract Stop hook 驗收標準、R7、R8、spec Stop hook requirement 第 1、2 段、三個相關 scenario、tasks 1.6／1.7 與 proposal 第二層段落，確認 fail-open 與有失敗項的重入放行皆改為 exit 1 + stderr、無失敗項為 exit 0 無輸出，並逐字寫入 host exit 語意。語意檢查 (a)：無任何仍規定「fail open 以 exit 0」或「重入 exit 0 + stderr」的無條件子句殘留。修正參照：Round 7 `## Fix Actions` 第 1 項。驗證 reviewer：Reviewer V。
- **N-2** — `resolved`。Reviewer V 引述 D6 第 1 段的兩段語意邊界、R9 一般化後的四類情形、驗收標準末句、spec requirement 對進入點之前失敗的明文排除、改寫後的 scenario GIVEN、tasks 1.6 的排除聲明，並以「不存在或不可執行」全 artifact 掃描確認零殘留。修正參照：Round 7 `## Fix Actions` 第 1 項。驗證 reviewer：Reviewer V。

集合因此清空。七筆非 blocking 修正的 propagation 檢查：A1／S-1、A2／N-3、N-4、N-6／A3、N-7、S-2 六筆完整傳播；N-5／A4 在 proposal 摘要層未同步（見 V-2）。

### Suggestion（非 blocking）

- **V-1**（Suggestion 60，`layer`: text）｜`disposition`: `fix-introduced`｜`introduced_by`: Round 7 `## Fix Actions` 第 1 項｜`location`: design.md Implementation Contract 失敗模式、spec `Grader immutability 以三方比對判定` 第 1 段
  `summary`: 兩處 rationale 仍稱 fail-open 為「靜默不可用」，與 D6「fail open MUST NOT 靜默」相反；不改變 MUST 行為。
- **V-2**（Suggestion 55，`layer`: text）｜`disposition`: `fix-introduced`｜`introduced_by`: Round 7 `## Fix Actions` 第 5 項｜`location`: proposal.md `## Proposed Solution` grader-immutability 段
  `summary`: 聯集條件仍敘述為 `--hook` mode 專屬，與 D4／spec／tasks 的「兩種 mode 都取聯集」未同步。
- **V-3**（Suggestion 55，`layer`: text）｜`disposition`: `fix-introduced`｜`introduced_by`: Round 7 `## Fix Actions` 第 8 項｜`location`: design.md Implementation Contract Stop hook 介面
  `summary`: 「不依賴 host 執行時的 cwd」為過度宣稱；`$CLAUDE_PROJECT_DIR` 只錨定 launcher 定位，workspace 解析仍由 `Workspace.discover` 自 cwd 起算。
- **V-4**（Suggestion 50，`layer`: text）｜`disposition`: `new`｜`location`: spec Stop hook requirement 第 1 段、design D6 第 1 段、Implementation Contract
  `summary`: 「判定失敗時 MUST 以 exit `2` 結束」無條件句未加「`stop_hook_active` 為真時除外」限定，與第 2 段重入規則並列；scenario 已明文 exit 1 而非 exit 2，實作語意可判定。自 Round 2 F3 起即存在，非 Round 7 引入。
- **V-5**（Suggestion 50，`layer`: design）｜`disposition`: `new`｜`location`: design.md R4、tasks.md 1.5
  `summary`: A2／N-3 對 round file fixture 要求靜態化，但同機制的另一 live 來源（本 change 的 proposal／tasks／design 作為 D4 解析器雙向 fixture）未加同樣限定。

### Reviewer V 的整體判斷

N-1 與 N-2 已在 Round 7 列出的全部位置解決，exit 0／1／2 語意在五份 artifact 間單一且一致，兩項語意檢查未發現否定修正的無條件子句或反向同義陳述，修正倚賴的 host／launcher 事實均經程式碼核實。累積 blocking 集合清空、無 Critical、無 Safety exception，artifact 集合已達通過條件。

## Rating

- post-filter 累積 blocking 集合 `Critical` 數：0
- post-filter 累積 blocking 集合 `Warning` 數：0
- 非 blocking triaged finding 數：5
- `critical_gap`：`false`
- `round_type`：`micro`

理由：N-1、N-2 經 Reviewer V 以現行 artifact 原文驗證解決並移出集合，集合清空。本輪五筆新發現皆為 `Suggestion`，信心過濾只降級不升級，故非 blocking，不影響通過條件。本次 run 的收斂軌跡為 2（seeded）→ 2 → 0。

## Fix Actions

通過條件已成立。五筆 Suggestion 皆為局部改字或與 A2／N-3 同機制的補限定，為避免下一次 loop 再以同機制殘留出現，順手同步，修改檔案 4 個：`proposal.md`、`design.md`、`tasks.md`、`specs/cash-round-gate/spec.md`。

1. **V-1**：design.md 失敗模式與 spec grader-immutability 第 1 段的「靜默不可用」改為「都以 `gate_unavailable` fail open 而不可用」。
2. **V-2**：proposal.md grader-immutability 段改為「涵蓋判定在 single-change 與 `--hook` 兩種 mode 都取全部 active 被列舉 change 宣告的聯集，single-change 的位置參數只決定回報對象」。
3. **V-3**：design.md Stop hook 介面理由句改為「錨定 launcher 的定位使其不依賴 host 執行時的 cwd；workspace 解析仍依既有 `Workspace.discover` 自 cwd 起算，其失敗屬 D6 進入點之後的 fail-open 分支」。
4. **V-4**：design.md D6 第 1 段與 spec Stop hook requirement 第 1 段的「判定失敗時以 exit 2 結束」補「（`stop_hook_active` 為真時除外）」。
5. **V-5**：design.md R4 與 tasks.md 1.5 補「MUST 複製為 `scripts/cash-cli/tests/fixtures/lint_round/` 下的靜態 fixture，MUST NOT 讀取 live 路徑」。

修正後 `.cash-skills/bin/cash validate add-host-derived-round-lint --json` 回報 `valid: true`；「靜默不可用」全 artifact 零殘留；`## Impact` 與 tasks delivery 集合仍為 10↔10。

### 其他紀錄

本輪無 `未修復：裁判面保護` 紀錄，無 accepted-risks 降級，無 disposition 更正——V-1、V-2、V-3 的 `introduced_by` 經比對 Round 7 `## Fix Actions` 第 1、5、8 項成立。無 finding 觸發 Safety exception。fix actions 未修改 change 目錄以外的檔案，不執行 `touched` 記錄。

## Decision

`passed`

累積 blocking 集合經 Reviewer V 逐成員驗證後清空，post-filter 集合不含 `Critical` 亦不含 `Warning`，符合通過條件。artifacts 完整且 `validate` 通過，change 保持 active，可進入 `cash-apply`。
