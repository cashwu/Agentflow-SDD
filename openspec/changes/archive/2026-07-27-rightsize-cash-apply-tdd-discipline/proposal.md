## Summary

收斂 `cash-apply` 的 TDD 指示：保留由 `.cash.yaml` 條件式啟用、嵌入 task loop、以 Cash-owned resource 為單一來源的 Red-Green-Refactor discipline，但將「每個 task 一律先寫失敗測試」改為依可觀察行為與可行驗證邊界判定，並移除 `SKILL.md` 與 runtime resource 的重複定義。

## Motivation

目前兩個 `cash-apply` 變體在 `tdd: true` 時會呼叫 Cash CLI 取得 TDD discipline，卻同時於 `SKILL.md` 重複列出 fail-first 與 Red-Green-Refactor 規則。重複定義會形成 cross-artifact drift；而「每個 task 都必須先有失敗測試」及「TDD 關閉或小型 refactor 仍必須更新測試」的絕對敘述，對純文件、metadata、僅人工驗證及不改變行為的 refactor 並不成立，也使 `tdd` toggle 的語意不清。

本變更要保留 Cash 對可驗證實作的要求，同時讓 TDD discipline 成為按需載入、低重複、以適用性判準驅動的 workflow contract。Red phase 必須因目標行為尚未存在而失敗，不能由不相關的較早 guard 或既有失敗代替。

## Proposed Solution

- 讓 Cash-owned TDD resource 成為 Red-Green-Refactor 語意的唯一完整定義。
- `cash-apply` 僅在 `tdd: true` 時取得該 resource，並在 task loop 套用；`tdd: false` 時不強迫製造 TDD red phase。
- 對新增或改變可觀察可執行行為、且存在實際可行自動測試邊界的 task，先建立能唯一證明目標行為尚未存在的失敗測試，確認失敗原因後完成最小實作，最後在綠燈狀態整理程式碼。
- Bug fix 在存在實際可行的自動測試邊界時，先以失敗測試重現缺陷。純 refactor 以既有 regression tests 或必要的 characterization tests 保護行為；其餘 task 使用 `tasks.md` 指定的 verification target，有可用 checker 時可採自動驗證，但不為文件、metadata 或沒有可行自動測試邊界的工作製造沒有辨識力的 red phase。
- task 完成條件改為具有適合該 task 性質的 verification evidence，而非無條件新增或更新測試。
- 規格 `##### Example:` 維持高保真驗證參考，但不得排除有明確理由的額外邊界測試。
- 以完整雙變體 parity、每個 `SKILL.md` 中 `Red-Green-Refactor` literal 恰為零次、TDD resource 的八項行為語意、四分支 precedence／boundary assertions 與 instruction framework-neutral assertion 防止語意漂移。

## Non-Goals

- 不移除 TDD、Red-Green-Refactor 或測試要求。
- 不新增獨立的 TDD agent、額外 review loop 或新的設定欄位。
- 不改變 `audit`、`parallel_tasks`、task checkbox、Implementation Notes Protocol、blocker triage 或既有 sub-agent quality gate。
- 不以特定語言、framework 或測試工具綁定 TDD discipline。
- 不要求純文件、metadata、checker-only 或無可行自動測試邊界的 task 製造假 red phase。

## Alternatives Considered

- 保留現行絕對規則：文字最直接，但會讓不適用的 task 產生形式化測試工作，且與 `tdd: false` 及模型判斷空間衝突。
- 將 TDD 完全移出 `cash-apply`：可縮短 skill，但失去每個 task 即時驗證與團隊偏好的自動套用。
- 建立獨立 TDD skill 並由 `cash-apply` chaining：增加一次 workflow 邊界與 context 成本；TDD 本來就只屬於 apply task loop，採 embedded、conditional discipline 較小且清楚。

## Capabilities

### New Capabilities

- (none)

### Modified Capabilities

- `cash-skill-workflows`：定義 `cash-apply` 條件式 TDD 的適用邊界、verification evidence 與雙變體對等要求。
- `cash-cli`：收斂 Cash-owned TDD discipline 的 canonical 語意，使 `instructions --skill tdd` 成為完整 Red-Green-Refactor 判準的單一來源。

## Impact

- Affected specs:
  - `cash-skill-workflows`
  - `cash-cli`
- Affected code:
  - New:
    - (none)
  - Modified:
    - `.agents/skills/cash-apply/SKILL.md`
    - `.claude/skills/cash-apply/SKILL.md`
    - `.cash-skills/lib/cash_cli/resources.py`
    - `scripts/cash-skills/tests/skill-checks.fish`
    - `scripts/cash-cli/tests/test_graph_instructions.py`
    - `cash-skills.version`
  - Removed:
    - (none)
