## ADDED Requirements

### Requirement: Archive manifest 保留 touched 檔案清單

`archive` 寫入 `archive-manifest.json` 時 SHALL 額外記錄 `touched_files` 欄位，其值為封存當下 touched state 的 `files` 陣列，內容與順序逐字沿用該陣列，不另行重新排序或去重。沒有任何追蹤來源檔時，`touched_files` MUST 為空陣列而非省略該欄位。既有的 `touched_digest` 其計算輸入與計算方式 MUST 不變，`version`、`change`、`destination`、`specs_synced`、`delta_digests`、`master_digests` 與 `legacy_cleanup` 的值 MUST 不變。

#### Scenario: 有追蹤來源檔時記錄完整清單

- **GIVEN** change `demo-change` 的 touched state 其 `files` 為兩個來源檔路徑
- **WHEN** 執行 `archive demo-change`
- **THEN** 封存目錄下 `archive-manifest.json` 的 `touched_files` 逐字等於該 `files` 陣列
- **AND** `touched_digest` 等於以封存當下 touched 物件計算的既有結果

#### Scenario: 無追蹤來源檔時為空陣列

- **GIVEN** change `demo-change` 沒有任何 touched state
- **WHEN** 執行 `archive demo-change`
- **THEN** 封存目錄下 `archive-manifest.json` 含 `touched_files` 欄位
- **AND** 該欄位的值為空陣列

#### Scenario: 其他 manifest 欄位不受影響

- **WHEN** 執行 `archive demo-change`
- **THEN** `archive-manifest.json` 的 `version`、`change`、`destination`、`specs_synced`、`delta_digests`、`master_digests` 與 `legacy_cleanup` 與新增 `touched_files` 之前的結果相同
