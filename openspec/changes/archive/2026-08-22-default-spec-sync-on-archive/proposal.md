## Summary

把 delta spec 同步從「每次封存前都詢問使用者」改為「預設就同步」。`cash-archive` 與 `cash-commit` 的封存子流程 MUST 以判定規則取代提問：使用者在本次呼叫中明確要求跳過時帶上 `--skip-specs`（此條優先），否則不帶旗標，不論是否存在 delta specs 都適用。

## Motivation

目前兩個封存入口都把「要不要把 delta specs 同步到 master specs」做成一次強制提問：

- `.claude/skills/cash-archive/SKILL.md` 步驟 4「Choose spec sync behavior」
- `.claude/skills/cash-commit/SKILL.md` 步驟 6a-ii「Delta spec sync check」

這個提問的兩個選項在實務上並不對稱。delta specs 存在，代表這個 change 宣告了它要改變的 capability 行為；封存卻不同步，等於把 master spec 留在舊狀態，之後每次 `cash-drift`、`cash-analyze` 與 `Requirement 標題是合併身分鍵` 的比對都建立在過期的 master 上。而沒有 delta specs 的 change 根本走不到這個提問。也就是說：提問只會在「答案幾乎必然是同步」的情境出現。

使用者回報的實際症狀是每次封存都被同一個問題擋一次，而且在對話或專案指示中交代「直接同步」也無效——因為提問是寫死在 skill 步驟裡的指令，不是可被外部偏好覆蓋的預設值。

## Proposed Solution

在兩個封存入口把同步從「使用者選擇」改為「有優先序的判定規則」：

1. `cash-archive` 步驟 4 改寫為判定而非提問。判定規則兩條、有先後：使用者在本次呼叫中明確要求跳過時帶 `--skip-specs`（優先）；否則不帶旗標，不論是否存在 delta specs 都適用，也不發問。對 `cash-archive` 而言，明確要求的形式限於在 invocation 後附上 `--skip-specs`，或在本次 session 中直接說明；MUST NOT 從 change 的性質或其他間接訊號推論。判定結果依序判定：先 `skipped`，再 `synced`，最後 `no delta specs`。`**Input**` 段一併承認 `--skip-specs` 這個 invocation 形式，讓跳過分支有可到達的入口。
2. 同一份檔案裡與該規則矛盾的殘留措辭一併修正：Optional flags 中 `--skip-specs — skip delta spec application (for tooling/doc-only changes)` 是檔內唯一還在以 change 性質描述旗標使用時機的句子，改為指向步驟 4 的判定規則；步驟 5 的 `adding the selected flags` 改為 `adding the resolved flags`。步驟 5 的失敗處置拆為兩段：delta parse 與 `requirement_identity_mismatch` 只能修正 delta specs 後重跑，`validation_failed` 另給 `--no-validate` 這條出路；兩段都明寫 `--skip-specs` 不繞過。
3. `cash-commit` 步驟 6a-ii 套用相同的兩條優先序判定規則（明確要求的形式依入口而異：`cash-commit` 的 archive-first 子流程沒有自己的 invocation 可掛旗標，只有在本次 session 中直接說明一種形式），並把判定結果記為 `synced`、`skipped`、`no delta specs` 三者之一，且依序判定：先 `skipped`，再 `synced`，最後 `no delta specs`。步驟 6a-iii 中 `openspec/specs/` 的納入條件改為「判定結果為 `synced`」——不能改成「封存未帶 `--skip-specs`」，那在沒有 delta specs 時恆真，會把無關的 dirty spec 路徑掃進 archive-first 提交集合。
4. 完成回報依兩個入口既有的輸出面分配：`cash-archive` 已有 `**Specs:**` 欄位，但其 warnings 模板把該欄位硬寫為跳過，因此改為依判定結果填值的佔位形式並在步驟 6 明訂對應字串；`cash-commit` 沒有回報 spec sync 的完成摘要，因此在 archive-first 的 updated commit plan 加一行標明判定結果。
5. `openspec/specs/cash-skill-workflows/spec.md` 的 `cash-commit 的 archive-first 允許清單` requirement 目前以「使用者在封存子流程中明確選擇 spec sync」描述納入條件，與新行為矛盾，一併以 MODIFIED 改寫為以判定結果為準；並新增一條 requirement 定義判定契約與兩個入口的一致性。
6. `.agents/skills/` 下的兩份對應 SKILL.md 是 `scripts/cash-skills/generate.fish` 的生成輸出，MUST 由重新生成產生，MUST NOT 手工編輯。
7. 修改 `SKILL.md` 會觸發既有的 bundle version history contract，因此 `cash-skills.version` MUST 由 `2.13.0` 調升為 `2.14.0`、`.cash-skills/lib/cash_cli/installer.py` 的 `BUNDLE_VERSION` MUST 同步，`.cash-skills/manifest.tsv` MUST 重建。此 bump MUST 排在第一個 `SKILL.md` 編輯之前。

## Non-Goals

- 不改動 Cash CLI。`archive` 的 `--skip-specs` 旗標語意、transaction 行為與 `archive-manifest.json` 的 `specs_synced` 欄位全部維持不變。
- 不移除跳過同步的能力，只改變它的觸發方式：從預設提問改為使用者明確指示。
- 不恢復 `cash-archive` 步驟 4 的 Cancel 出口；常見路徑將不再有互動式確認，殘餘風險記於 design 的 `## Risks / Trade-offs`。
- 不改動 `cash-commit` 步驟 2a 的封存後復原路徑。該路徑以 `archive-manifest.json` 的 `specs_synced` 判定 spec sync 集合，不依賴本次是否發問。
- 不改動 6a-i 的未完成 task 提問。本變更只處理 delta spec 同步這一個提問。
- 不改寫 `openspec/specs/cash-cli/spec.md`。其「使用者拒絕 spec sync」情境描述的是 CLI 收到 `--skip-specs` 時的行為，跳過路徑仍然存在，該情境仍然成立。

## Alternatives Considered

- **保留提問但記住上次選擇**：需要新的持久化狀態，且 skill 無處存放跨呼叫偏好，成本遠高於收益。
- **改由 `.cash.yaml` 提供 `spec_sync_default` 設定**：等於為一個實務上單一答案的決策新增設定面，並讓兩個入口多一條讀設定的分支；違反 surgical simplicity。
- **直接刪除跳過能力，永遠同步**：會讓少數需要保留 master spec 不動的封存（例如 delta 寫錯要先修）失去出口，且與 `openspec/specs/cash-cli/spec.md` 既有的 `--skip-specs` 情境衝突。

## Capabilities

### New Capabilities

（無）

### Modified Capabilities

- `cash-skill-workflows`：新增 `封存前的 delta spec 同步判定` requirement，並修改 `cash-commit` archive-first 允許清單中 spec sync 檔案的納入條件。

## Impact

- Affected specs:
  - cash-skill-workflows
- Affected code:
  - New:
    - (none)
  - Modified:
    - .claude/skills/cash-archive/SKILL.md
    - .claude/skills/cash-commit/SKILL.md
    - .agents/skills/cash-archive/SKILL.md
    - .agents/skills/cash-commit/SKILL.md
    - cash-skills.version
    - .cash-skills/lib/cash_cli/installer.py
    - .cash-skills/manifest.tsv
  - Removed:
    - (none)
