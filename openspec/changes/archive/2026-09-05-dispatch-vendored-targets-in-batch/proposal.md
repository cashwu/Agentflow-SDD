## Summary

讓 `install-cash-skills.fish` 的 registry batch mode（`--all`）依每個 target 實際的 publication mode 分派：target 已有 portable manifest 時走 vendored publication，否則維持既有 receipt-based publication。同時讓 `--register` 接受 manifest-present target，使 vendored repository 能正常進入 registry。明示的 `--target` 維持既有 fail-closed 指引不變。

## Motivation

現況下 registry batch mode 對每個 registry record 一律呼叫 receipt-based 的 `install_target`，而該函式在 target 存在 `.cash-skills/manifest.tsv` 時無條件以 execution error 失敗並指引 `--vendor`。這條 fail-closed 規則的原始動機是「反向轉換 MUST NOT 隱式發生」——避免 portable manifest target 被靜默降級回 receipt 信任模式。

但這條規則被套用在 batch mode 上時，攔截的不是反向轉換，而是「這個 target 該用哪一種 publication 執行」這個純粹的分派問題。實際後果是：一旦 registry 中任何 target 被轉成 vendored，`--all` 就永久對它回報 `failed`、summary 永遠帶著非零 `failed=` 計數、整個 batch 以 exit 1 結束，而其餘 receipt-based target 是否成功也被這個結束碼掩蓋。使用者必須記住哪幾個 target 是 vendored，每次 batch 之後手動補跑 `--vendor`；漏跑的 target 會停在舊 bundle version 而外表看起來只是「那兩行照例會失敗」。

`--register` 有同一條拒絕規則，形成第二個缺口：新 vendored 的 repository 無法用 CLI 登錄，只能手動編輯 `$HOME/.config/cash-skills/projects.txt` 才可能被 batch 涵蓋。

分派到 vendored publication 並不違反原始動機：它讓 target 留在 portable manifest 模式，是 forward publication，而非被禁止的反向轉換。

## Proposed Solution

在 batch mode 的每個 registry record 上，先以純讀取的 publication-mode probe 判定該 target 的模式，再分派到對應的既有 publication 函式：

1. probe 觀察到 target 的 `.cash-skills/manifest.tsv` 存在且為 regular file 時，該 record 走 `install_vendored_target`；依該路徑既有的 machine-local residue cleanup，該 target 的殘留 `.cash-skills/receipt.tsv` 會在同一 transaction 內被刪除。
2. 其餘全部 record——含 manifest 缺失、manifest 存在但非 regular shape，以及 probe 無法安全判定的情形——走既有 `install_target`。

probe MUST 是 read-only、MUST NOT 自行產生新的 diagnostic，也 MUST NOT 在任何輸入上拋出例外：任何 shape、存在性或權限問題都落入 catch-all 分支，交給被分派到的 publication 函式以其既有 fail-closed 契約診斷。probe 無法判定時退回 receipt 分支，最差情況等同今日行為——若 manifest 確實存在，`install_target` 自身的既有檢查仍會拒絕，不會發生隱式反向轉換。非 regular shape 的 manifest 一律落入 receipt 分支並以 execution error fail closed、零寫入，不會被當成 absent 而讓任一路徑繼續發佈，也不會落入 vendored publication 開檔讀取 manifest 而對 FIFO 阻塞的路徑。

被分派到 vendored publication 的 target 沿用 `--vendor` 的完整契約：Git-committable planned path preflight、manifest-last publication、`--force` 只收斂 replaceable managed bytes、`--dry-run` 零寫入。batch 分派另以一個預設關閉的 batch-only 參數要求該路徑在分類前重新確認 manifest 仍存在，使只可由明示 `--vendor` 進行的 receipt 轉換與 receiptless adoption 不會在 batch 上下文發生；明示 `--vendor` 不帶該參數，行為逐字不變。兩條分支回傳同一組分類值（`update`／`current`／`newer`／`conflict`），因此既有 label 與 summary 計數格式不變；vendored 分支的 label 行加上 ` (vendored)` 後綴，讓使用者知道該 target 是以會進版控的 vendored bundle 發佈，該後綴與最終 label 無關。

`--register` 移除 manifest-present 的拒絕，其餘 target prerequisite 驗證、正規化、去重與 atomic registry 寫入完全不變。

`--vendor` 與 registry 操作在 CLI flag 層仍互斥；本變更不新增旗標，也不讓 vendored publication 讀取或修改 registry——讀 registry 的是 `--all` 自己。

## Non-Goals

- 不改變明示 `--target <project>` 的行為：它是使用者明示選定的 publication mode，靜默改以另一種模式執行會失去現有的可行動診斷，因此維持 fail closed 並指引 `--vendor`。
- 不新增任何旗標來開關此分派；分派由 target 的實際狀態決定，不由 caller 選擇。
- 不改變 receipt-based target 的任何分類、寫入或診斷行為。此處的 receipt-based target 定義為 `.cash-skills/manifest.tsv` 缺失、或該檔存在但非 regular shape 的 target；同時持有殘留 receipt 與 regular manifest 的 target 不屬此列，它會被分派到 vendored 路徑並依既有 cleanup 刪除該 receipt。
- 不改變 `--vendor`、`--self`、`--init-receipt` 三個 mode 各自的既有行為，也不改變 registry 檔案格式與 registry 操作集合。`install_vendored_target` 只擴充一個預設關閉、僅由 batch 分派帶入的參數，明示 `--vendor` 不受影響。
- 不修正 `--all` 既有的「不可讀 target parent 使原生 `OSError` 逸出並中止批次」缺陷，也不修正明示 `--vendor` 對 FIFO manifest 會阻塞的既有缺陷；兩者都先於本變更存在，修正它們各需獨立的範圍。
- 不修改 `AGENTS.md`／`CLAUDE.md` 的 managed guidance block：兩者均未敘述 registry batch 或 manifest-presence 分派，不因本變更失真。
- 不為 `--all --force` 另設有別於 `--vendor --force` 的閘門；它逐字沿用 vendored force 的收斂邊界。
- 不新增 batch mode 的 JSON 輸出。

## Alternatives Considered

- **維持現狀，靠使用者手動補跑 `--vendor`**：不需改動，但每次 `--all` 都以 exit 1 結束，使非零結束碼失去訊號價值，且漏跑會讓 vendored target 靜默落後 bundle version。
- **讓 `--target` 也自動分派**：一致性最高，但會讓明示的單一 target 指令靜默切換 publication mode。現有的 fail-closed 診斷成本極低（使用者改打 `--vendor` 即可），保留它比一致性更有價值。
- **新增 `--all --vendor` 之類的組合旗標**：需要打破既有 mode 互斥契約，且仍要求使用者記住哪些 target 是 vendored——正是本變更要消除的負擔。
- **在 batch 中把 vendored target 標為 skipped 而非失敗**：能讓 exit code 恢復乾淨，但 target 仍不會被更新，只是把可見的失敗換成不可見的落後。

## Capabilities

### New Capabilities

（無）

### Modified Capabilities

- `cash-cli`：registry batch mode 依 target publication mode 分派；`--register` 接受 manifest-present target；被推翻的既有拒絕條文與 scenario 一併修正。
- `cash-skill-workflows`：`手動的 cash 專案 registry` 的 registry 操作契約補上「batch 可用 vendored publication 發佈已登錄 target」與 `--register` 接受條件；`版本感知的 cash skill 批次安裝` 的 receipt-based workflow 與 receipt publication 收窄為適用於 manifest 缺失的 record，並宣告 manifest-present record 由 `Repo-vendored Cash bundle 發佈` 以較窄契約優先治理。

## Impact

- Affected specs: cash-cli, cash-skill-workflows
- Affected code:
  - New:
    - (none)
  - Modified:
    - cash-skills.version
    - .cash-skills/lib/cash_cli/installer.py
    - .cash-skills/manifest.tsv
    - scripts/cash-skills/tests/test_installer_runtime.py
    - CASH-SKILLS.md
    - CASH-INIT-RECEIPT.md
  - Removed:
    - (none)
