## Context

目前 `.agents/skills/cash-apply/SKILL.md` 與 `.claude/skills/cash-apply/SKILL.md` 都在 project preferences 段落以三個 bullet 定義 TDD，其中一個 bullet 又呼叫 `instructions --skill tdd` 取得 `.cash-skills/lib/cash_cli/resources.py` 的 `DISCIPLINES["tdd"]`。同一個 Red-Green-Refactor 概念因此同時由 skill 與 runtime resource 定義。

task loop 另有兩個擴張：規格 example 被直接映射成第一個 failing test，且即使 `tdd: false` 或 task 只是小型 refactor，仍無條件要求新增或更新測試。這使 config toggle 只控制測試順序的一部分，沒有清楚區分「TDD red phase」與「task 完成前必須有 verification evidence」。

現有 `scripts/cash-cli/tests/test_graph_instructions.py` 只斷言 TDD instruction 含 `Red-Green-Refactor`；`scripts/cash-skills/tests/skill-checks.fish` 斷言 consumer command 存在並執行完整 variant parity，但沒有獨立治理 TDD 的條件載入、單一來源與 task-type 分支。`cash-skills.version` 的 history contract 將 replaceable runtime 與 skill bytes 綁定版本，因此本 change 改動這些 bytes 時必須遞增版本。

## Goals / Non-Goals

### Goals

- 讓 Cash-owned TDD resource 成為完整 TDD 語意的唯一來源，`cash-apply` 只保留 toggle、取得指令與 consumer 義務。
- 以 task 性質及可行驗證邊界決定是否需要 red phase，避免為不適用的 task 製造形式化失敗測試。
- 明確區分 `tdd: false` 與「不驗證」：前者只停用 TDD ordering，task 仍需適合其性質的 verification evidence。
- 要求 red phase 因目標行為尚未存在而失敗，且其證據能區分不相關的較早失敗。
- 維持兩個 `cash-apply` 變體在 invocation prefix 正規化後完整對等，並以具名 regression group 治理。

### Non-Goals

- 不改變 Cash CLI command、JSON shape、`.cash.yaml` schema 或預設值。
- 不建立獨立 TDD skill、sub-agent 或 review loop。
- 不修改 audit、parallel task、blocker triage、Implementation Notes Protocol 或 apply quality gate。
- 不規定特定程式語言、test framework、test file layout 或 coverage threshold。

## Decisions

### D1：完整 TDD 語意只由 Cash-owned resource 定義

`.cash-skills/lib/cash_cli/resources.py` 的 `DISCIPLINES["tdd"]` 擁有完整判準。`cash-apply` 的 project preferences 段落只判斷 `.cash.yaml` 的 `tdd` 值：`true` 時呼叫 `"$cash_cli" instructions --skill tdd` 並遵循回傳的 `instruction`，`false` 時不套用 TDD ordering。兩個 `SKILL.md` 不再複述 Red-Green-Refactor 的步驟或 bug-fix fail-first 規則，且 `Red-Green-Refactor` literal 在每個變體中 MUST 恰好出現零次；consumer invocation 只要求遵循回傳的 canonical `instruction`。

此切分保留按需載入：未啟用 TDD 時不把完整 discipline 加入 task loop；啟用時只載入一份 canonical 文字。

### D2：canonical discipline 使用適用性矩陣

TDD resource 依下列 precedence 將每個 task 分到恰好一種處置：

| Task 類型 | 處置 |
| --- | --- |
| 1. Bug fix，且存在實際可行的自動測試邊界 | 先以能辨識該缺陷的失敗測試重現，再修正並維持 regression evidence |
| 2. 非 bug fix 的可觀察可執行行為變更，且存在實際可行的自動測試邊界 | 執行 Red-Green-Refactor；先證明目標行為尚未存在，再以最小實作轉綠，最後只在綠燈整理 |
| 3. 不改變可觀察行為的純 refactor | 以既有 regression tests 保護；只有既有證據不足時才補 characterization test，不要求刻意製造 red phase |
| 4. 其餘 task，包括文件、metadata、checker-only 與沒有實際可行自動測試邊界的 task | 執行 task 指定的 verification target；有可用自動 checker 時可使用，但不要求 red phase |

前兩列的 red evidence 必須對目標路徑具有辨識力。若測試只是因不相關的較早 guard、既存 suite failure 或相同 exit code 失敗，則 red phase 尚未成立；必須加入能唯一辨識目標行為的 diagnostic、state 或 artifact assertion，或選擇更適合的驗證邊界。分類依表格由上而下判定，命中後不再落入後續分支。

### D3：task loop 只定義共同完成判準

`cash-apply` task loop 將現行無條件「新增或更新測試」改為：每個 task 在 `task done` 前都必須有適合其性質、對應 `tasks.md` 與 Implementation Contract 的 verification evidence。啟用 TDD 時，是否需要 red phase 由 canonical discipline 判定；未啟用時仍執行 task 指名的 test、CLI、analyzer 或 manual assertion。

規格 `##### Example:` 是高保真 acceptance reference。task loop 應在 example 涵蓋 task scope 時將其納入驗證，也可為有具體風險的邊界補充測試；不得把 example table 機械解讀為唯一允許的輸入集合。

### D4：回歸治理分成 resource 與 consumer

`scripts/cash-cli/tests/test_graph_instructions.py` 驗證 canonical TDD resource 含八項可觀察語意：executable behavior、目標失敗原因、unrelated failure 排除、minimal green、green refactor、bug reproduction、pure-refactor evidence與remaining-task verification。測試另以獨立 assertions 驗證四分支由上而下的 precedence、沒有可行自動測試邊界的 bug fix 與具有 checker 的文件／metadata task 都落入 remaining-task 分支，以及 canonical instruction 不要求任何特定程式語言或 test framework。

`scripts/cash-skills/tests/skill-checks.fish` 新增 `tdd-discipline` 具名群組並納入 `all`：

- 兩個 `cash-apply` 變體都保留 `tdd: true` gate 與唯一一次 `instructions --skill tdd` consumer invocation。
- 兩檔都不再包含舊的絕對 fail-first 或「TDD 關閉仍必須更新測試」字面值，且 `Red-Green-Refactor` literal 在每檔恰好出現零次。
- 兩檔都含共同的 verification-evidence task-done gate 與 example-as-reference 判準。
- 既有完整 variant parity 繼續驗證正規化後逐行對等，而非只比 markers。

### D5：bundle version 與 source receipt

修改 replaceable runtime/skill bytes 的同一個 task MUST同時遞增 `cash-skills.version`並維持單行 LF。該 task 完成全部 managed-byte 修改後、呼叫自身的 `task done` 前，MUST從 project root 執行 `./install-cash-skills.fish --self` 重建 source receipt；版本與 receipt 是既有治理機制，本 change 不改變其 schema。version-history 與 receipt 驗證可以留在後續 verification task，但不得把 version bump 或首次 receipt 重建延後到下一個 task。

## Implementation Contract

### C1：條件式 consumer 與單一來源

- 觀察行為：`tdd: true` 時，`cash-apply` 取得並遵循 `instructions --skill tdd` 的 `instruction`；`tdd: false` 時不套用 TDD ordering。
- 單一來源：兩個 `cash-apply/SKILL.md` 不複述 Red-Green-Refactor sequence、bug-fix fail-first 或 task-type 適用性矩陣，且每檔的 `Red-Green-Refactor` literal count 必須為零；完整語意只存在於 `DISCIPLINES["tdd"]`。
- 不變項：不論 toggle 值，每個 task 在 `task done` 前仍必須通過其 verification target 並提供適當 evidence。

### C2：有效 red phase

- 觀察行為：對適用 TDD 的行為 task，初始測試因目標行為尚未存在而失敗，且 assertion 能區分目標路徑與不相關的較早失敗。
- 驗收：canonical instruction 明示 unrelated earlier guard、pre-existing failure 或只有相同 exit code 不構成有效 red；resource test 分別斷言「目標原因」與「不可由不相關失敗代替」兩個語意。

### C3：非行為 task 不製造假 red

- 觀察行為：純 refactor 使用既有 regression tests，必要時補 characterization test；其餘 task 使用命名的 verification target，有自動 checker 時可使用。兩類都不被要求先建立刻意失敗的自動測試。
- 驗收：resource test 對 pure refactor 與 remaining-task 兩個分支各有獨立 assertion；skill contract test 拒絕舊的 per-task absolute fail-first literal。

### C4：Example 與額外邊界

- 觀察行為：task scope 內的 `##### Example:` 會成為 verification reference；有具體理由時可以增加其他輸入或邊界 case。
- 驗收：兩個 skill 變體含 reference 與 reasoned-extra-case 判準，且不再把 table row 宣告為唯一允許的 test set。

### C5：雙變體、測試群組與版本

- 觀察行為：兩個 `cash-apply` 變體在 invocation prefix 正規化後逐行一致；`tdd-discipline` 群組可獨立執行且包含在 `all`；CLI resource tests 與完整 Cash suites 通過；`cash-skills.version` 已遞增。
- 驗收：執行 `fish scripts/cash-skills/tests/skill-checks.fish tdd-discipline`、`fish scripts/cash-skills/tests/skill-checks.fish variant-parity`、`PYTHONPATH=.cash-skills/lib python3 scripts/cash-cli/tests/test_graph_instructions.py`、`python3 scripts/cash-skills/tests/test_bundle_version_history.py`、`fish scripts/cash-skills/tests/skill-checks.fish` 與 `fish scripts/cash-cli/tests/cli-checks.fish` 全部通過。

## Risks / Trade-offs

- **判準過於抽象**：模型可能把 behavior task 錯分到 remaining-task 分支。緩解方式是 canonical discipline 明列帶 precedence 的四類處置，task 並必須先有命名 verification target。
- **假 red 仍可能出現**：只看 exit code 無法證明執行到目標路徑。緩解方式是要求 diagnostic、state 或 artifact assertion 對目標原因具有辨識力，並以獨立 resource assertion 鎖定。
- **單一來源被重新複製**：後續修改可能再次在 `SKILL.md` 加回完整 sequence。緩解方式是 skill test 要求每檔 `Red-Green-Refactor` literal count 恰為零並對舊 literals fail loud，resource test 單獨治理語意。
- **過度放寬造成漏測**：取消「每個 task 必須更新測試」可能被誤讀為可跳過驗證。緩解方式是保留更強且適用於所有 task 的 verification-evidence gate，並逐項對照 `tasks.md`、Implementation Contract 與命名 verification target。
- **bundle bytes 與版本漂移**：修改 resource 或 skill 後若未 bump 版本，history contract 會失敗；若未在同一 task 的 `task done` 前重建 receipt，該 command 會以 `receipt_invalid` 失敗。managed-byte implementation task 因此同時擁有 version bump 與首次 `--self`，後續 verification task只驗證 history 與 receipt。
