## Summary

修補「先封存、後提交」路徑上的允許清單斷鏈：`cash archive` 會刪除 `.cash-skills/state/touched/<name>.json`，而 `cash-commit` 的 step 2 在該檔缺席時以 `touched ensure` 重建一份空殼，並把它當成唯一的允許清單依據，導致該 change 的所有來源檔被靜默歸類為 Unrelated。本變更同時從三個面向修補：`cash-apply` 的封存指引改為先提交、`cash-commit` 新增封存後空殼的偵測與復原、`archive` 在 manifest 中保留 touched 檔案清單以支撐該復原。

## Motivation

在 `/Users/cash/Github/Whispify` 的 change `fix-mac-thumbnail-codec-fallback` 觀察到具體事故：

1. 使用者依 `cash-apply` 的結尾指引先執行封存，`cash archive` 在 14:31:16 寫出 `archive-manifest.json` 並依 `archive.py` 的清理邏輯刪除 touched、snapshot、sync 三份 state。該 manifest 的 `touched_digest` 為 `1a98b7364dcd4de202dee4fb688ad1307013768739d37f667bacb86e68c0394a`，與空 touched 狀態的 sha256 `86d8b41a2c909d7a43079ee612b5a81154b3d6227f4b9f15c5df0771dbe13f54` 不同，且 `legacy_cleanup` 為 `not_imported`，證明封存當下 touched 內容非空、`task done` 的追蹤機制運作正常。
2. 使用者接著執行 `cash-commit`。step 2 的 `touched ensure` 在 14:31:34 重建出一份 `touched: []`、`files: []` 的空殼。
3. step 2 明文規定 `Cash state is the only allowlist authority after this point`，於是 8 個 `mac/` 來源檔（含 4 個測試 fixture）全被判為 Unrelated。使用者必須手動改以 proposal 的 Impact 段落補齊允許清單，才避免漏掉 fixture 使新測試在其他機器直接失敗。

三個結構性缺口造成這次事故，缺一不可：

- `cash-apply` 在審查迴圈通過後只指引封存，未指引先提交，使「封存先於提交」成為容易踏上的預設路徑。
- `cash-commit` 無法區分「這個 change 本來就沒有追蹤來源檔」與「追蹤狀態已被封存刪除」，兩者都表現為空的 `files` 陣列。
- `archive-manifest.json` 只保留 `touched_digest` 這個雜湊，檔案清單本身在封存當下即被銷毀，事後沒有任何可稽核的復原來源。

事故的後果是靜默的：commit plan 看起來完整，漏掉的來源檔只會在其他機器上以測試紅燈的形式浮現。

## Proposed Solution

**一、`cash-apply` 封存指引改為提交優先**

在審查迴圈以 `decision: passed` 結束後的封存指引中，明確指引使用者先執行 `cash-commit`，或在 `cash-commit` 中選擇「Archive first, then commit together」子流程；同時說明「先單獨封存再提交」會刪除 `cash-commit` 用作允許清單的 touched state。既有的「未通過關卡前不得建議封存」行為不變。

**二、`cash-commit` 偵測並復原封存後的空允許清單**

在 step 2 解析 touched 之後，新增封存後空殼偵測。三個條件同時成立時視為封存後空殼：`files` 為空陣列、`openspec/changes/<name>/` 與 `openspec/changes/.parked/<name>/` 皆不存在、且存在符合 `openspec/changes/archive/<date>-<name>/` 的目錄。成立時：

- 以 manifest 的 `change` 與 `destination` 驗證候選封存目錄並取日期最新者消歧；無法消歧時要求使用者確認。
- 讀取該封存目錄的 `archive-manifest.json`，若含非空的 `touched_files`，以其作為來源允許清單，並在 commit plan 標明清單來源與其「封存當下時點快照」的性質。
- 若該欄位缺席或為空（早於本變更產生的封存），顯示警告並要求使用者從一組明確選項中選擇：以封存目錄下 proposal `## Impact` 的路徑作為備援、手動逐檔選取、或不提交並停止。不得靜默把來源檔全部歸入 Unrelated。
- 同步把 artifact 集合、「無可提交即停止」的判定輸入、archive-first 選項可用性，以及產生 commit message 時讀取 proposal 與 tasks 的路徑，全部改為以封存目錄為準；Unrelated 判定改以 artifact 集合、來源允許清單與 spec sync 集合三者的聯集為排除依據。
- spec sync 檔案只在 manifest 的 `specs_synced` 為 true 時，納入「dirty 且目前 digest 等於 manifest 記錄值」的 `openspec/specs/` 路徑，避免把並行 change 的編輯掃進提交；通過判定的路徑列於 commit plan 的獨立 Spec Sync Changes 區段。

三個條件未同時成立時，維持現行行為不變。

**三、`archive` 在 manifest 保留 touched 檔案清單**

`cash archive` 寫入 `archive-manifest.json` 時，新增 `touched_files` 欄位，內容為封存當下 touched 狀態的 `files` 聯集陣列，順序與 touched state 一致。既有的 `touched_digest` 語意與計算方式不變，其餘欄位不變。

**四、bundle 關卡**

`archive.py` 與四個 `SKILL.md` 都是 bundle 的 replaceable 檔案，因此本變更必須提升 `cash-skills.version`，並在每次改動 `archive.py` 之後重建 `.cash-skills/receipt.tsv`。

`.claude` 與 `.agents` 兩個 skill 變體以逐字對等的方式修改，維持既有的 variant parity 檢查。

## Non-Goals

- 不改變 `cash archive` 刪除 touched、snapshot、sync 三份 state 的既有行為。
- 不改變 `touched ensure` 在檔案缺席時建立空殼的 CLI 行為，也不新增「change 已封存」的錯誤碼；復原邏輯放在 skill 層，避免使 `cash-commit` 因 ensure 失敗而整個停止。
- 不改變 `touched_digest` 的計算輸入或值。
- 不處理 `openspec/signals/` 之下由審查迴圈寫出的 signal 檔未被任何允許清單追蹤的問題；該缺口在未封存路徑同樣存在，屬既有缺口，建議另開變更。
- 不改變 `cash-commit` 內建 archive-first 子流程（step 6a）本身的文字語意。

## Alternatives Considered

- **讓 `touched ensure` 對已封存的 change 失敗**：可以讓問題不再靜默，但 `cash-commit` step 2 明文規定 ensure 失敗即 STOP，結果是使用者完全無法提交已封存的 change，比現況更糟。
- **由 `cash-commit` 自行從 git 歷史或 proposal Impact 推導允許清單**：Impact 段落是宣告而非實測結果，與實際改動可能有落差；把它當作預設來源會把宣告漂移變成提交漏檔。本方案只在 manifest 無 `touched_files` 時把它當作需使用者確認的備援。
- **讓 `archive` 不刪除 touched state**：會讓封存後殘留的 state 無限累積，並破壞既有的「封存後清理 Cash state」契約與其 CLI spec 敘述。
- **只修 `cash-apply` 指引**：指引無法防止使用者手動先執行封存，缺口仍在。
- **偵測成立時直接把所有 dirty 來源檔納入提交**：等於用另一個方向的靜默取代原本的靜默，且會把並行 change 的改動一起提交。

## Capabilities

### New Capabilities

（無）

### Modified Capabilities

- `cash-skill-workflows`：新增 `cash-commit` 封存後空允許清單的偵測與復原契約，以及 `cash-apply` 封存指引須指引提交優先的契約。
- `cash-cli`：新增 archive manifest 保留 touched 檔案清單的契約。

## Impact

- Affected specs:
  - openspec/specs/cash-skill-workflows/spec.md
  - openspec/specs/cash-cli/spec.md
- Affected code:
  - New:
    - (none)
  - Modified:
    - .claude/skills/cash-apply/SKILL.md
    - .agents/skills/cash-apply/SKILL.md
    - .claude/skills/cash-commit/SKILL.md
    - .agents/skills/cash-commit/SKILL.md
    - .cash-skills/lib/cash_cli/commands/archive.py
    - cash-skills.version
    - scripts/cash-cli/tests/test_sync_archive_transaction.py
    - scripts/cash-skills/tests/skill-checks.fish
  - Removed:
    - (none)
