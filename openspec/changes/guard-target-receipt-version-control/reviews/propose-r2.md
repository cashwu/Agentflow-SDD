# Cash Propose Review — Round 2

## Reviewer Findings

### Cumulative blocking set 裁決（Round 1 的 5 Critical + 3 Warning）

Reviewer V 對 8 項全部給出 `resolved`，主 agent 已就其中最關鍵者獨立驗證：

- launcher 範圍移除：`tasks.md` 全檔無 task 觸及 `.cash-skills/bin/cash`，反以「逐 byte 未變」為驗收斷言。
- `--self` 範圍移除：delta 明文「source-only `--self`不在本requirement範圍內」，且機器 diff 確認 master 的 `--self` 段落逐字未動。
- 封閉列舉承接：新增 `## MODIFIED Requirements`，機器 diff 確認與 master 僅 4 處相異，正是三處列舉與一處 scenario。
- 無尾端換行、snapshot revalidation、`CASH_INSTALL_FAIL_AFTER` 索引三項皆已入條文與 task。

### Warning

- severity: Warning / confidence: 80 / layer: design / disposition: fix-introduced
  location: `specs/cash-cli/spec.md` snapshot revalidation 條文與對應 Scenario；`tasks.md` 1.2
  summary: Round 1 修正新增的「publication 前不一致時重新分類而非覆寫」與既有實作及既有契約衝突——`installer.py:1291-1301` 在該檢查點為 `raise InstallerError`（fail closed），只有 post-lock（`installer.py:1202-1221`）才 `return install_target(...)` 重新分類；且 master `Cash guidance deployment` 明文要求 post-preflight drift「MUST在publication前fail closed」。同一檢查點無法同時 fail closed 與重新分類。
  recommendation: 條文區分兩個檢查點：post-lock 不一致時重新分類，publication 前不一致時 fail closed，兩者皆不覆寫。
  introduced_by: Round 1 Fix Actions 中新增的 snapshot revalidation 條文
  reviewer: V

### Suggestion

- 行終止符 fallback 未定義（confidence 65，fix-introduced）：「沿用既有行終止符」與「先補一個行終止符」在零終止符與空檔案兩種形狀下無解，使 AC3 的測試期望值不確定。
- AC5（symlink／hard link fail-closed）未列入 task 1.3 的測試列舉，只靠 task 3.1 概括覆蓋。
- 版控狀態 diagnostic 的輸出時機未綁定分類；本 change 後該類 target 第二次起為 `current`，條文未明說該路徑亦需輸出。
- 用語小瑕疵：MODIFIED 文字用「target版控排除設定」，ADDED requirement 名為「Target 版控排除保護」。

## Rating

- cumulative blocking Critical: 0
- cumulative blocking Warning: 1
- non-blocking triaged: 4
- critical_gap: false
- round_type: micro
- rationale: Round 1 的 8 項 blocking 全數經 Reviewer V 裁決為 resolved，其中 launcher、`--self` 與封閉列舉三項由主 agent 以機器 diff 與程式碼查證獨立確認。本輪唯一 blocking 為 fix-introduced 的 revalidation 檢查點衝突，經主 agent 查證 `installer.py:1202-1221` 與 `:1291-1301` 後確認成立，已於本輪修正。

## Fix Actions

- 修改 `specs/cash-cli/spec.md`：revalidation 條文區分 post-lock（重新分類）與 publication 前（execution error fail closed），兩者皆不覆寫；對應 Scenario 改寫為兩個檢查點各一組 GIVEN/WHEN/THEN。
- 修改 `specs/cash-cli/spec.md`：補明行終止符 fallback 為 `\n`、既有內容為空時不補終止符；補明 diagnostic 不依結果分類決定是否輸出。
- 修改 `design.md`：同步 revalidation 兩檢查點處置與理由（持鎖期間反覆重新分類的無限重試風險、既有 guidance 契約）、行終止符 fallback、AC3 補上空檔案條件。
- 修改 `tasks.md`：1.2 改為兩個檢查點各自的測試案例；1.3 測試列舉補上空檔案、無行終止符單行檔案、symlink／非 regular file／hard link 的 fail-closed（含 `--force`）。
- 修正後重跑 `validate` 通過；機械自我檢查確認 MODIFIED 區塊與 master 仍僅 4 行相異、AC 七項與 tasks 宣稱一致。
- fixed_files: 3

## Decision

next_round
