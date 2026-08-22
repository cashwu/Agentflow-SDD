## ADDED Requirements

### Requirement: 封存前的 delta spec 同步判定

Cash 的兩個封存入口——`cash-archive` 的 spec sync 步驟與 `cash-commit` archive-first 子流程的 delta spec sync 步驟——SHALL 以判定規則決定是否對 `.cash-skills/bin/cash archive` 帶上 `--skip-specs`，MUST NOT 為這個決定向使用者發問。判定規則由兩條有先後的條件組成：當使用者在本次呼叫中明確要求跳過 delta spec 同步時，兩者 MUST 帶上 `--skip-specs`，此條優先；否則兩者 MUST NOT 帶上 `--skip-specs`，且不論 `openspec/changes/<name>/specs/` 是否存在 delta specs 都適用。明確要求的形式依入口而異：對 `cash-archive` 限於在 invocation 後附上 `--skip-specs`，或在本次 session 中直接說明這次封存不要同步 specs；對 `cash-commit` 的 archive-first 子流程限於後者。兩者 MUST NOT 從 change 看起來只影響 tooling 或文件、從先前的封存或任何其他間接訊號推論出該要求。`cash-archive` 的 `**Input**` 段 MUST 承認 `--skip-specs` 這個 invocation 形式。兩者 MUST 把判定結果記為 `synced`、`skipped`、`no delta specs` 三者之一，且 MUST 依序判定：先 `skipped`（帶了旗標），再 `synced`（存在 delta specs 且未帶旗標），最後 `no delta specs`（沒有 delta specs 且未帶旗標）。`cash-archive` 的完成摘要 MUST 回報該判定結果，跳過時 MUST 標明該跳過出於使用者的明確要求；`cash-commit` MUST 在 archive-first 的 updated commit plan 中標明該判定結果。此 requirement 適用於 `.claude` 與 `.agents` 兩個變體，正規化 invocation 前綴後兩者的相關段落 MUST 完全相同。

#### Scenario: 有 delta specs 且未要求跳過時直接同步且不發問

- **GIVEN** change `demo-change` 的 `openspec/changes/demo-change/specs/` 存在 delta specs
- **AND** 使用者在本次呼叫中沒有要求跳過 delta spec 同步
- **WHEN** `cash-archive` 抵達 spec sync 步驟
- **THEN** `cash-archive` 不向使用者詢問是否同步
- **AND** 以不帶 `--skip-specs` 的方式執行 `.cash-skills/bin/cash archive demo-change`
- **AND** 將判定結果記為 `synced`

#### Scenario: 使用者以 invocation 明確要求跳過

- **GIVEN** change `demo-change` 的 `openspec/changes/demo-change/specs/` 存在 delta specs
- **WHEN** 使用者在 invocation 後附上 `--skip-specs`
- **THEN** `cash-archive` 以帶 `--skip-specs` 的方式執行封存
- **AND** 將判定結果記為 `skipped`
- **AND** 完成摘要標明本次跳過同步且該跳過出於使用者的明確要求

#### Scenario: 沒有 delta specs 且未要求跳過時不發問也不帶旗標

- **GIVEN** change `demo-change` 沒有 `openspec/changes/demo-change/specs/` 或該目錄為空
- **AND** 使用者在本次呼叫中沒有要求跳過 delta spec 同步
- **WHEN** `cash-archive` 抵達 spec sync 步驟
- **THEN** `cash-archive` 不向使用者詢問是否同步
- **AND** 執行封存時不帶 `--skip-specs`
- **AND** 將判定結果記為 `no delta specs`

#### Scenario: 明確要求跳過優先於沒有 delta specs 的預設

- **GIVEN** change `demo-change` 沒有 delta specs
- **AND** 使用者在本次呼叫中明確要求跳過 delta spec 同步
- **WHEN** `cash-archive` 抵達 spec sync 步驟
- **THEN** `cash-archive` 以帶 `--skip-specs` 的方式執行封存
- **AND** 依判定順序將結果記為 `skipped` 而非 `no delta specs`
- **AND** 完成摘要標明本次跳過同步且該跳過出於使用者的明確要求

#### Scenario: 不從間接訊號推論跳過

- **GIVEN** change `demo-change` 存在 delta specs
- **AND** 使用者在本次呼叫中沒有要求跳過 delta spec 同步
- **WHEN** 該 change 的內容看起來只影響 tooling 或文件
- **THEN** `cash-archive` 仍以不帶 `--skip-specs` 的方式執行封存
- **AND** 將判定結果記為 `synced`

#### Scenario: cash-commit 的封存子流程套用同一判定並記錄結果

- **GIVEN** 使用者在 `cash-commit` 中選擇 archive-first 處理 change `demo-change`
- **AND** `openspec/changes/demo-change/specs/` 存在 delta specs
- **AND** 使用者在本次呼叫中沒有要求跳過 delta spec 同步
- **WHEN** archive-first 子流程抵達 delta spec sync 步驟
- **THEN** 該步驟不向使用者詢問是否同步
- **AND** 執行封存時不帶 `--skip-specs`
- **AND** 將判定結果記為 `synced` 供後續的檔案收集步驟使用
- **AND** updated commit plan 標明該判定結果

#### Scenario: 兩個變體保持對等

- **WHEN** 比較 `.claude/skills/cash-archive/SKILL.md` 與 `.agents/skills/cash-archive/SKILL.md` 的 spec sync 步驟
- **AND** 比較 `.claude/skills/cash-commit/SKILL.md` 與 `.agents/skills/cash-commit/SKILL.md` 的 delta spec sync 步驟
- **THEN** 兩組在 invocation 前綴（`/cash-` 與 `$cash-`）正規化後 MUST 完全相同

## MODIFIED Requirements

### Requirement: cash-commit 的 archive-first 允許清單

系統 SHALL 使 `cash-commit` 在 `.cash-skills/bin/cash archive` 完成後，透過明確的允許清單收集 archive-first 提交檔案。archive-first 提交集合 MUST 包含封存前已確認提交集合中的 tracked 來源檔案、屬於所選 change 封存的檔案，以及封存子流程的 delta spec sync 判定結果為 `synced` 時來自 `openspec/specs/` 的 spec sync 檔案。判定結果為 `skipped` 或 `no delta specs` 時，archive-first 提交集合 MUST NOT 包含任何 `openspec/specs/` 路徑。archive-first 提交集合 MUST NOT 包含封存後 `git status --porcelain` 掃描發現的無關 dirty 檔案。

#### Scenario: archive-first 提交前已存在無關刪除

- **WHEN** `cash-commit` 在啟用 archive-first 下提交 change `demo-change`
- **AND** 在 `.cash-skills/bin/cash archive demo-change` 執行之前，`git status --porcelain` 已含有 `D .agents/skills/cash-apply/SKILL.md`
- **THEN** 預設提交集合排除 `.agents/skills/cash-apply/SKILL.md`
- **AND** 提交計畫將該刪除顯示在被納入的封存相關檔案之外

#### Scenario: 封存成功後納入封存檔案

- **WHEN** `.cash-skills/bin/cash archive demo-change` 將檔案從 `openspec/changes/demo-change/` 移至 `openspec/changes/archive/2026-05-19-demo-change/`
- **THEN** `cash-commit` 納入 `openspec/changes/demo-change/` 之下的刪除
- **AND** `cash-commit` 納入 `openspec/changes/archive/2026-05-19-demo-change/` 之下的新增或修改
- **AND** `cash-commit` 排除所選 change 封存、tracked 來源檔案與判定結果為 `synced` 時的 spec sync 檔案以外的 dirty 檔案

#### Scenario: 判定結果為 synced 時納入 spec 變更

- **WHEN** `demo-change` 的封存子流程把 delta spec sync 判定結果記為 `synced`
- **THEN** `cash-commit` 納入 `openspec/specs/` 之下的相應變更
- **AND** 更新後的提交計畫將它們顯示為 Spec Sync Changes

#### Scenario: 判定結果不是 synced 時不納入任何 spec 路徑

- **WHEN** `demo-change` 的封存子流程把 delta spec sync 判定結果記為 `skipped` 或 `no delta specs`
- **THEN** `cash-commit` 不將 `openspec/specs/` 之下的任何路徑納入 archive-first 提交集合
- **AND** 該情形下仍然 dirty 的 `openspec/specs/` 路徑留在 Unrelated Changes

#### Scenario: 封存路徑措辭為現行版本

- **WHEN** `cash-commit` 顯示更新後的 archive-first 提交計畫
- **THEN** 封存檔案區段標明 `openspec/changes/archive/<date>-<change>/`
- **AND** archive-first workflow 文字不提及 `openspec/archived/`
