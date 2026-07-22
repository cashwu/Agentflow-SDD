## Summary

在 `cash-apply` 的 task loop（Step 7）補上「阻塞分類」判準，讓 agent 分辨「機制替換（contract 不變）」與「contract／範圍／行為變更」兩種阻塞，前者記一筆 `deviation` 後繼續實作，只有後者才暫停並引導 `cash-ingest`。

## Motivation

現行 `cash-apply` Step 7 的 pause 條件只有一條籠統規則：「Implementation reveals a design issue → suggest updating artifacts」。這使 agent 在遇到任何實作層阻塞時都傾向暫停、要求使用者先跑 `cash-ingest` 再重跑 `cash-apply`，即使該阻塞只是「原做法在目標平台不可行、改用等價手段但要交付的 contract 完全不變」。

實際案例：某 change 的 task 5.2 發現 macOS 不支援 `/dev/fd/<dir-fd>/<basename>` child lookup（回 ENOENT），改用 `chdir($directory_fh)` 後的 FD-bound relative operations。atomic、race-safe publish 的 contract 沒有改變，只是達成手段換掉。這種情況 Implementation Notes Protocol 已經支援以 `deviation` 條目記錄後繼續，但 agent 卻把它升級成 contract 變更、要求 ingest，造成不必要的中斷與 context 重載。

問題不是「讓 apply 自動 ingest」——`cash-ingest` 本身是互動式的（多處 AskUserQuestion），自動串接無法移除人類 gate，只會搬移它；且 ingest 後重跑 apply 會重新驗證改過的 artifacts（preflight／analyze／drift），是刻意的 re-validation。真正的缺口是 task loop 的 pause 判準沒有教 agent 分辨兩類阻塞。

## Proposed Solution

在 `cash-apply` Step 7 的 **Pause if** 段落，把單一籠統規則展開為明確的兩分支阻塞分類：

- **機制替換（mechanism substitution，contract 不變）**：當阻塞只是「原設計的達成手段在目標平台／現實不可行，但要交付的觀察行為、interface／資料形狀、失敗模式與驗收標準都不變」，且替代手段不需要 `design.md` 未定義的同步原語、身分／世代型別或狀態機 —— agent SHALL 依 Implementation Notes Protocol 記一筆 `deviation`（必要時把新機制回填 `design.md`），然後**繼續**該 task，不暫停、不要求 `cash-ingest`。
- **contract／範圍／行為變更**：當阻塞改變了要交付的觀察行為、範圍或取捨，或替代手段需要 `design.md` 未定義的同步原語、身分／世代型別或狀態機，或存在其解答可能改變 contract 或範圍、需要使用者決定的 open question —— agent SHALL 暫停、報告 blocker，並引導使用者前往 `cash-ingest`。當機制替換分支條件全部成立時，「在多個都保留 contract 的替代手段之間選一個」的內部選擇不屬此類，SHALL 以記 `deviation` 解決而不暫停。

第二分支的「替代手段需要 design.md 未定義的同步原語／身分或世代型別／狀態機」判準，刻意重用既有 **Fix-loop design circuit breaker** 的觸發條件，使 task-loop 分類與 review-loop 斷路器對「何謂真正的 design 變更」保持一致的邊界。

兩個分類分支優先於既有通用 error／blocker fallback；該 fallback 僅處理未被 blocker triage 涵蓋的其他錯誤或阻塞，避免符合繼續分支的機制替換又被 catch-all 要求暫停。

同步更新 `.claude` 與 `.agents` 兩個 cash-apply 變體（保持 invocation 正規化後完全相同），並在 governed-contract mutation fixture 加一個 literal 保護新判準不被無聲刪除。因 Cash skill bytes 會改變，依 repository bundle version governance 將 `cash-skills.version` 從 `1.2.0` 提升至 `1.2.1`，使完整 skill checks 可驗證並發布這次 bundle 變更。

## Non-Goals

- 不讓 `cash-apply` 自動呼叫或串接 `cash-ingest`；contract 變更時仍暫停交由使用者。
- 不改動既有的 **Fix-loop design circuit breaker**（review-loop 內的 abort 行為）本身。
- 不改動 Implementation Notes Protocol 的 `deviation` 條目格式或既有語意；只是明確把「機制替換」導向它。
- 不改動 cash-propose 或任何 shared review-loop block。
- 不改動其他 cash skills 的變體或 pause 行為。
- 不改動 Cash bundle version governance 的比較規則或版本格式；只為本次 skill bytes 變更進行必要的 patch bump。

## Alternatives Considered

- **讓 apply 自動 ingest 後續跑**：被否決。`cash-ingest` 互動式設計使自動串接無法移除人類 gate，且會跳過 ingest 後重跑 apply 的 re-validation。
- **完全移除 pause、一律記 deviation 繼續**：被否決。真正的 contract／範圍變更需要人類 gate，這是 SDD「改 contract 與照 contract 實作分屬不同層級」的核心假設。

## Impact

- Affected specs: cash-skill-workflows（新增一條 cash-apply task-loop 阻塞分類 requirement）
- Affected code:
  - Modified:
    - .claude/skills/cash-apply/SKILL.md
    - .agents/skills/cash-apply/SKILL.md
    - scripts/cash-skills/tests/skill-checks.fish
    - cash-skills.version
  - New: (none)
  - Removed: (none)
