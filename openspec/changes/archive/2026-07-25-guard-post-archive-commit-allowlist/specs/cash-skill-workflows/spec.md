## ADDED Requirements

### Requirement: cash-commit 封存後空允許清單的偵測與復原

`cash-commit` SHALL 在解析 `.cash-skills/state/touched/<change-name>.json` 之後，判定該空允許清單是否來自「change 已被封存」。判定條件為下列三者同時成立：解析後的 `files` 為空陣列、`openspec/changes/<change-name>/` 與 `openspec/changes/.parked/<change-name>/` 皆不存在、且存在符合 `openspec/changes/archive/<date>-<change-name>/` 的目錄。任一條件不成立時 `cash-commit` MUST 維持既有行為。三條件同時成立時，`cash-commit` MUST NOT 把空的 `files` 視為「沒有追蹤來源檔」，並 MUST 改以消歧後封存目錄下 `archive-manifest.json` 的 `touched_files` 作為來源允許清單。當 `touched_files` 缺席或為空、或封存目錄無法消歧時，`cash-commit` MUST 顯示警告並要求使用者從明確的選項集合中選擇後才繼續；`cash-commit` MUST NOT 在未經使用者確認的情況下，以「把該 change 的來源檔全部歸類為 Unrelated」的方式繼續提交。此 requirement 適用於 `cash-commit` 的兩個變體（`.claude` 與 `.agents`）。

#### Scenario: manifest 含 touched_files 時據以復原允許清單

- **GIVEN** change `demo-change` 已被封存至 `openspec/changes/archive/2026-07-25-demo-change/`
- **AND** `openspec/changes/demo-change/` 與 `openspec/changes/.parked/demo-change/` 皆不存在
- **AND** 解析後的 touched state 其 `files` 為空陣列
- **AND** 該封存目錄的 `archive-manifest.json` 含非空的 `touched_files`
- **WHEN** 使用者對 `demo-change` 執行 `cash-commit`
- **THEN** `cash-commit` 以 `touched_files` 的內容作為來源允許清單
- **AND** commit plan 的來源檔區段標明該清單來自 archive manifest
- **AND** commit plan 標明該清單是封存當下的時點快照
- **AND** dirty 但不在該清單內的來源檔仍列於 Unrelated Changes

#### Scenario: manifest 缺 touched_files 時警告並要求使用者從選項中選擇

- **GIVEN** 封存後空允許清單的三條偵測條件同時成立
- **AND** 消歧後封存目錄的 `archive-manifest.json` 沒有 `touched_files` 或其值為空陣列
- **WHEN** 使用者對該 change 執行 `cash-commit`
- **THEN** `cash-commit` 顯示警告並指出消歧後的封存目錄
- **AND** `cash-commit` 提供的選項集合包含「以該封存目錄下 proposal `## Impact` 的 affected-code 路徑作為備援清單」、「手動逐檔選取」與「不提交並停止」
- **AND** 使用者選擇「不提交並停止」時，`cash-commit` 以不提交結束，該結束狀態為合法終止
- **AND** `cash-commit` MUST NOT 在未取得使用者選擇前繼續提交

#### Scenario: change 仍為 active 或 parked 時維持既有行為

- **GIVEN** `openspec/changes/demo-change/` 或 `openspec/changes/.parked/demo-change/` 其中之一存在
- **AND** 解析後的 touched state 其 `files` 為空陣列
- **WHEN** 使用者對 `demo-change` 執行 `cash-commit`
- **THEN** `cash-commit` 依既有行為將空的 `files` 視為沒有追蹤來源檔
- **AND** `cash-commit` 不讀取任何 `archive-manifest.json`

#### Scenario: 多個同名封存目錄先自動消歧

- **GIVEN** 封存後空允許清單的條件 1 與條件 2 成立
- **AND** 存在多於一個符合 `openspec/changes/archive/<date>-<change-name>/` 的目錄
- **WHEN** `cash-commit` 進行封存目錄消歧
- **THEN** `cash-commit` 只保留其 `archive-manifest.json` 的 `change` 等於該 change 名稱且 `destination` 等於該目錄相對路徑的候選
- **AND** 在通過驗證的候選中取日期前綴最新者
- **AND** 僅當通過驗證的候選不唯一、不存在、或其 `archive-manifest.json` 缺席或無法解析時，才要求使用者確認

#### Scenario: 封存後的 artifact 與 commit message 來源取自封存目錄

- **GIVEN** 封存後空允許清單的三條偵測條件同時成立
- **WHEN** `cash-commit` 組出 commit plan 並產生 commit message
- **THEN** artifact 集合包含 `openspec/changes/<change-name>/` 之下的刪除
- **AND** artifact 集合包含消歧後封存目錄之下的新增或修改
- **AND** 「沒有 artifact 也沒有追蹤來源檔即停止」只在 artifact 集合、來源允許清單的 dirty 子集與 spec sync 集合三者的 dirty 內容全部為空時成立
- **AND** `cash-commit` 不提供 `Archive first, then commit together` 選項
- **AND** commit message 的 proposal 與 tasks 讀取路徑為消歧後封存目錄下的同名檔案

#### Scenario: spec sync 檔案以 manifest digest 判定歸屬

- **GIVEN** 封存後空允許清單的三條偵測條件同時成立
- **AND** 消歧後封存目錄的 `archive-manifest.json` 其 `specs_synced` 為 true
- **WHEN** `cash-commit` 決定要納入哪些 `openspec/specs/` 路徑
- **THEN** `cash-commit` 只納入同時是 dirty 且其目前 digest 等於 manifest `master_digests` 中該路徑記錄值的路徑
- **AND** 被納入的路徑列於 commit plan 的獨立 Spec Sync Changes 區段，不列於 Unrelated Changes
- **AND** 被納入的路徑屬於提交集合，在使用者未於確認步驟移除時會被 stage
- **AND** digest 不符的路徑留在 Unrelated Changes 並提示可能有第三方編輯

#### Scenario: specs_synced 為 false 時不納入任何 spec 路徑

- **GIVEN** 封存後空允許清單的三條偵測條件同時成立
- **AND** 消歧後封存目錄的 `archive-manifest.json` 其 `specs_synced` 為 false
- **WHEN** `cash-commit` 決定要納入哪些 `openspec/specs/` 路徑
- **THEN** `cash-commit` 不納入任何 `openspec/specs/` 路徑
- **AND** 所有 dirty 的 `openspec/specs/` 路徑留在 Unrelated Changes

#### Scenario: 兩個變體保持對等

- **WHEN** 比較 `.claude/skills/cash-commit/SKILL.md` 與 `.agents/skills/cash-commit/SKILL.md` 的封存後空允許清單偵測段落
- **THEN** 兩者在 invocation 前綴（`/cash-` 與 `$cash-`）正規化後 MUST 完全相同

### Requirement: cash-apply 封存指引須指引提交優先

當 `cash-apply` 的審查迴圈以 `decision: passed` 結束且最終回覆建議封存該 change 時，該回覆 SHALL 同時指引使用者先執行 `cash-commit`，或改以 `cash-commit` 的 `Archive first, then commit together` 子流程完成封存，並 MUST 說明單獨先執行封存會刪除 `cash-commit` 用作來源允許清單的 touched state。`decision: aborted` 時不建議封存的既有行為 MUST 不變。此 requirement 適用於 `cash-apply` 的兩個變體（`.claude` 與 `.agents`）。

#### Scenario: 通過關卡後的封存指引附帶提交順序

- **WHEN** 最終審查迴圈輪為 `decision: passed` 且最終回覆建議封存該 change
- **THEN** 該回覆指引使用者先執行 `cash-commit`，或改用 `cash-commit` 的 `Archive first, then commit together` 子流程
- **AND** 該回覆說明單獨先封存會刪除 `cash-commit` 用作來源允許清單的 touched state

#### Scenario: abort 時的既有行為不變

- **WHEN** 最終審查迴圈輪為 `decision: aborted`
- **THEN** `cash-apply` 不建議封存該 change

#### Scenario: 兩個變體保持對等

- **WHEN** 比較 `.claude/skills/cash-apply/SKILL.md` 與 `.agents/skills/cash-apply/SKILL.md` 的封存指引段落
- **THEN** 兩者在 invocation 前綴（`/cash-` 與 `$cash-`）正規化後 MUST 完全相同
