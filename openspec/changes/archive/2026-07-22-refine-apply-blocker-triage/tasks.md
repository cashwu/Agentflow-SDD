## 1. 測試先行（RED）

- [x] 1.1 在 `scripts/cash-skills/tests/skill-checks.fish` 為新 governed contract 佈線測試：在 `assert_apply_contract` 加入 `<!-- BLOCKER-TRIAGE -->` marker，以及代表兩分支處置的 invocation-free literals `然後繼續該 task，不暫停`、`暫停、報告 blocker`；並在 `assert_contract_mutation_fixture` 的 `mutation_specs` `apply` 群組逐一 mutation 三者。執行 `fish scripts/cash-skills/tests/skill-checks.fish`，確認 marker 或任一處置 literal 缺失時會由 `cash-apply implementation contract`／`assert_apply_contract` fail loud。

## 2. 實作阻塞分類段落（GREEN）

- [x] 2.1 在 `.claude/skills/cash-apply/SKILL.md` Step 7 的 **Pause if** 段落，把單一規則「Implementation reveals a design issue → suggest updating artifacts」替換為 design D1／D2 定義的兩分支阻塞分類：機制替換（contract 不變、且替代手段不涉及未定義機制）→ 依 Implementation Notes Protocol 記 `deviation` 後繼續；contract／範圍／行為變更、或替代手段需要未定義機制、或有「其解答可能改變 contract／範圍」的 open question → 暫停並引導 `/cash-ingest`。兩分支的「未定義機制」邊界 MUST 逐字內嵌英文片語 `a synchronization primitive, identity/generation type, or state machine not defined in design.md`（勿翻譯成中文），以與 Fix-loop design circuit breaker 保持可稽核一致。加入 design D1 的 precedence 規則，並將通用 error／blocker fallback 限縮為僅處理 blocker triage 未涵蓋的其他錯誤或阻塞；`Task is unclear` 與 `User interrupts` 保持不變。在該分類段落嵌入 `<!-- BLOCKER-TRIAGE -->` marker。
- [x] 2.2 在 `.agents/skills/cash-apply/SKILL.md` 鏡像 2.1 的完全相同變更，invocation 前綴改用 `$cash-`（如 `$cash-ingest`），marker 與其餘文字逐字相同。
- [x] 2.3 依 design `D4：Cash bundle version governance` 將 `cash-skills.version` 從 `1.2.0` 提升至 `1.2.1`，使本次 Cash skill bytes 變更符合 `check_bundle_version_governance`；以 `fish scripts/cash-skills/tests/skill-checks.fish` 驗證不再出現 `cash skill bytes changed without a bundle bump`。
- [x] 2.4 執行 `fish scripts/cash-skills/tests/skill-checks.fish`，確認 `assert_exhaustive_variant_parity`（兩 apply 變體正規化後相同）、`assert_apply_contract`（含新 marker）、`assert_contract_mutation_fixture`（新 literal 受保護）與 bundle version governance 全部 GREEN。

## 3. 驗證與收斂

- [x] 3.1 執行 `spectra validate refine-apply-blocker-triage` 並通過。
- [x] 3.2 對照 `cash-apply 任務迴圈的阻塞分類` requirement 與 design.md Implementation Contract 逐項確認 `D1：兩分支阻塞分類的判準`、`D2：與 Fix-loop design circuit breaker 的一致性邊界`、`D3：變體同步與 governed-contract 保護`、`D4：Cash bundle version governance` 均已交付：兩分支分類存在、circuit breaker 判準一致、變體對等、mutation fixture 保護、`cash-skills.version` 為 `1.2.1`，且未動 shared review-loop block／cash-propose／circuit breaker 本身；以 `git diff` 與完整 `skill-checks.fish` 結果人工核對。
