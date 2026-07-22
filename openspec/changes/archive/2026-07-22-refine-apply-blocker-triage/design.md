## Context

`cash-apply` 的實作在 Step 7 task loop 逐一完成 tasks。目前的 **Pause if** 段落有四條規則，其中「Implementation reveals a design issue → suggest updating artifacts」過於籠統，導致 agent 把「機制替換（contract 不變）」誤判為需要 `cash-ingest` 的 contract 變更而暫停。

同一份 skill 已存在兩個相關但不同階段的機制：

- **Implementation Notes Protocol**（Step 8）：支援以 `deviation` 條目記錄「因 codebase reality differs 而偏離設計」的情況，記錄後可繼續。
- **Fix-loop design circuit breaker**（review-loop 的 Fix actions 內）：當某個 review finding 的修正需要 `design.md` 未定義的同步原語、身分／世代型別或狀態機時，記 `needs-design`、`decision: aborted`、導向 `cash-ingest`。

本 change 在 task-loop 階段補上明確的兩分支阻塞分類，使這兩個既有機制之間的判準連貫。

實作期間執行完整 `skill-checks.fish` 時，repository bundle version governance 偵測到 Cash skill bytes 已變更但 `cash-skills.version` 仍為 `1.2.0`，因此在 contract assertions 完成前拒絕測試。這是發布 Cash skill 變更的既有必要條件，必須納入本 change 的 scope。

## Goals

- 讓 agent 在 task loop 遇到阻塞時，能機械式地分辨「機制替換（記 deviation 後繼續）」與「contract／範圍／行為變更（暫停並導向 ingest）」。
- 讓 task-loop 分類與既有 Fix-loop design circuit breaker 對「何謂真正的 design 變更」使用一致的邊界條件。
- 保持 `.claude` 與 `.agents` 兩個 cash-apply 變體在 invocation 正規化後完全相同。
- 讓 Cash bundle version 嚴格大於目前 committed version，使本次 skill bytes 變更通過 repository governance。

## Non-Goals

- 不讓 apply 自動串接 ingest（見 proposal Non-Goals）。
- 不改動 circuit breaker 或 Implementation Notes Protocol 既有語意。
- 不改動 bundle version governance 的演算法、SemVer 格式或測試邏輯。

## Decisions

### D1：兩分支阻塞分類的判準

在 Step 7 **Pause if** 段落，把「Implementation reveals a design issue → suggest updating artifacts」這一條，替換為一組明確的分類規則。分類的判準是「觀察到的 contract 是否改變」：

**繼續分支（機制替換，contract 不變）** —— 全部條件成立時走此分支：

1. 原設計指定的達成手段在目標平台或現實不可行（例如平台 API 回 ENOENT）；
2. 要交付的觀察行為、interface／資料形狀、失敗模式與驗收標準都不變；
3. 替代手段**不**需要 `design.md` 未定義的機制，即不涉及 `a synchronization primitive, identity/generation type, or state machine not defined in design.md`（同步原語／身分或世代型別／狀態機）。

處置：依 Implementation Notes Protocol 記一筆 `deviation` 條目（`類別：deviation`），說明原手段為何不可行與替代手段；若替代手段的細節值得長存，回填 `design.md`；然後**繼續**該 task，不暫停、不要求 `cash-ingest`。

**暫停分支（contract／範圍／行為變更）** —— 下列任一成立時走此分支：

1. 阻塞改變了要交付的觀察行為、範圍或使用者可見的取捨；
2. 替代手段需要 `design.md` 未定義的機制，即涉及 `a synchronization primitive, identity/generation type, or state machine not defined in design.md`（同步原語／身分或世代型別／狀態機）；
3. 存在**其解答可能改變 contract 或範圍**、需要使用者決定的 open question。

處置：暫停、報告 blocker、引導使用者前往 `cash-ingest`（比照現行 pause 行為）。

**分支優先（precedence）** —— 兩分支必須互斥，判準如下：當繼續分支的三個條件**全部成立**時，走繼續分支，即使替代手段之間存在需要選擇的問題。此類「在多個都保留 contract 的替代手段之間選一個」的內部選擇，SHALL 以記一筆 `deviation` 解決，**不**觸發暫停分支第 3 條——第 3 條僅指其解答可能改變 contract／範圍的 open question。只要繼續分支的條件 2（contract 不變）成立，選擇繼續就是 contract-safe 的。

原 **Pause if** 中 `Task is unclear` 與 `User interrupts` 兩條維持不變；通用 `Error or blocker encountered` fallback 限縮為只處理未被上述 blocker triage 涵蓋的其他錯誤或阻塞。兩個分類分支優先於該 fallback，因此符合繼續分支的機制替換 MUST NOT 再被 catch-all 要求暫停。

### D2：與 Fix-loop design circuit breaker 的一致性邊界

暫停分支第 2 條與繼續分支第 3 條共用的「未定義機制」邊界，在 Step 7 的中文 prose 中 MUST 逐字（verbatim）內嵌既有 **Fix-loop design circuit breaker** 觸發條件的英文片語 `a synchronization primitive, identity/generation type, or state machine not defined in design.md`，比照本 repo 既有把英文 normative 動詞（SHALL／MUST）與 quoted source text 逐字嵌入中文 prose 的慣例。逐字內嵌的目的：讓兩個階段的邊界字串可被 Reviewer A 稽核為一致，而非各自翻譯後無聲漂移——因此不以中文翻譯替代該英文片語。

理由：這兩個機制是同一個判斷在不同階段的體現——task loop 判「發現阻塞當下」，circuit breaker 判「review finding 的修正當下」。使用相同的邊界條件，避免同一種阻塞在兩個階段得到相反處置。動機案例（`/dev/fd/<dir-fd>/<basename>` → `chdir($directory_fh)`）不涉及新的同步原語／身分型別／狀態機，因此落在繼續分支，驗證了判準與案例一致。

### D3：變體同步與 governed-contract 保護

- 兩個 cash-apply 變體（`.claude/skills/cash-apply/SKILL.md` 與 `.agents/skills/cash-apply/SKILL.md`）以相同文字新增分類段落，僅 invocation 前綴（`/cash-` vs `$cash-`）依變體不同。`assert_exhaustive_variant_parity` 會驗證兩者在正規化後完全相同。
- 新分類段落是 apply 專屬的 task-loop 內容，**不**位於 cash-propose／cash-apply 共用的 review-loop block，因此 shared-block hash 檢查不受影響，cash-propose 不需改動。
- 在新分類段落嵌入一個穩定、不含 cash- invocation 的 HTML 註解 marker `<!-- BLOCKER-TRIAGE -->`（比照既有 `<!-- MECHANICAL-SELF-CHECK -->` 等 marker）。在 `scripts/cash-skills/tests/skill-checks.fish` 的 `assert_apply_contract` 加入該 marker，以及代表兩分支處置的 invocation-free literals `然後繼續該 task，不暫停`、`暫停、報告 blocker`；`assert_contract_mutation_fixture` 的 `mutation_specs` `apply` 群組逐一 mutation 這三個 literals，使 marker、繼續處置與暫停處置都成為受回歸保護的 governed contract。三個 literals 必須同時存在於兩個 apply 變體。

### D4：Cash bundle version governance

`cash-skills.version` 目前為 `1.2.0`。兩個 cash-apply canonical skill 的 bytes 改變後，`check_bundle_version_governance` 要求 working version 嚴格大於 committed version；因此本 change 將版本提升至最小合法 patch version `1.2.1`。不改動版本比較、inventory digest 或 history fixture 邏輯。完成條件是 `fish scripts/cash-skills/tests/skill-checks.fish` 不再回報 `cash skill bytes changed without a bundle bump`，並繼續通過完整 suite。

## Implementation Contract

- **觀察行為**：`cash-apply` Step 7 的 **Pause if** 段落包含明確的兩分支阻塞分類；機制替換分支導向 Implementation Notes Protocol 的 `deviation` 並繼續，contract/範圍/行為變更分支暫停並導向 `cash-ingest`。
- **fallback precedence**：兩個 blocker triage 分支優先於通用 error／blocker fallback；fallback 只處理分類未涵蓋的其他錯誤或阻塞。
- **一致性**：暫停分支重用 Fix-loop design circuit breaker 的「同步原語／身分或世代型別／狀態機」判準文字。
- **變體對等**：兩個 cash-apply 變體在 invocation 正規化後 byte-identical（`assert_exhaustive_variant_parity` 通過）。
- **回歸保護**：`skill-checks.fish` 的 `apply` 群組 mutation fixture 含 marker、繼續處置與暫停處置三個 literals，且三者都存在於兩個變體。
- **bundle 發布條件**：`cash-skills.version` 從 `1.2.0` 提升至 `1.2.1`，使變更後的 Cash skill bytes 通過 `check_bundle_version_governance`。
- **範圍邊界（in scope）**：兩個 cash-apply 變體的 Step 7 段落、`skill-checks.fish` 的 mutation fixture、`cash-skills.version` patch bump、spec delta。
- **範圍邊界（out of scope）**：shared review-loop block、cash-propose、circuit breaker 本身、Implementation Notes Protocol 條目格式、其他 cash skills。
- **驗收目標**：`scripts/cash-skills/tests/skill-checks.fish` 全通過（含 variant parity 與 mutation fixture）；`spectra validate refine-apply-blocker-triage` 通過。
