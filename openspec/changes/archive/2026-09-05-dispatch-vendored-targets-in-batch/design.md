## Context

`cash_cli.installer` 目前有兩條完整的 publication 路徑：receipt-based 的 `install_target` 與 portable-manifest-based 的 `install_vendored_target`。兩者都以 `source_inventory` 為單一來源、都在 stable lock 的 exclusive FD 下以 recoverable transaction 發佈，且都回傳同一組分類值 `update`／`current`／`newer`／`conflict`。

registry batch mode（`run()` 中 `options.all` 的迴圈）目前對每個 registry record 一律呼叫 `install_target`。`install_target` 在 `validate_target_prerequisites` 之後、`report_version_controlled_receipt` 之前，以 `path_is_present(target, PORTABLE_MANIFEST_PATH)` 判定 manifest 是否存在，存在即以診斷字串 `target is managed by a portable manifest; use --vendor` raise。`--register` 在寫入 registry 前有同一條檢查。

這條檢查存在的理由是防止 portable manifest target 被隱式降級回 receipt 信任模式。分派到 vendored publication 不是降級：它讓 target 留在 portable manifest 模式，因此原始理由不涵蓋 batch 的分派情境。

`path_is_present` 的實際語意必須先釐清，因為分派邏輯建立在它之上：它先呼叫 `ensure_contained`，而 `ensure_contained` 對 relative 的每一段（含最後一段）檢查 `S_ISLNK` 並以 `symlink managed boundary: <relative>` raise，對非目錄的中間段以 `managed parent is not a directory: <relative>` raise，其 `os.lstat` 只 catch `FileNotFoundError`，因此不可讀的 parent 會讓原生 `PermissionError` 直接逸出而不被包成 `InstallerError`。實測行為是：manifest 或其 parent 為 symlink → raise；manifest 為 directory 或 FIFO → 回傳 `True`；manifest 不存在 → 回傳 `False`。

另一個必須先釐清的事實是：`install_vendored_target` 在 `ensure_regular_shape` 之前，就已於 pre-lock 的 `snapshots(target, target_watch_paths)` 讀取 `.cash-skills/manifest.tsv`（`vendored_planned_paths` 明列該路徑），而 `read_regular` 以 `os.O_RDONLY | os.O_NOFOLLOW` 開檔且不帶 `O_NONBLOCK`。`ensure_regular_shape` 的 docstring 自身就記載了原因：開啟 FIFO 讀取會阻塞到出現 writer 為止。因此 FIFO manifest 若被分派到 vendored 路徑，會在 `ensure_regular_shape` 有機會 fail closed 之前就永久阻塞。

## Goals / Non-Goals

**Goals**

- `--all` 對 registry 中的 vendored target 執行 vendored publication，使 batch 能對全部已登錄 target 收斂，`failed` 計數與非零 exit code 回復其原本的訊號意義。
- `--register` 接受 manifest-present target，使新 vendored 的 repository 能經由 CLI 進入 registry。
- receipt-based target——定義為 `.cash-skills/manifest.tsv` 缺失、或該檔存在但非 regular shape 的 target——其分類、寫入與診斷逐字不變。
- 分派判定是有序且窮盡的分割，任何無法安全判定的輸入都退回今日行為，且 probe 自身不得成為新的 batch 中止來源。
- 任何非 regular shape 的 manifest 都落入 receipt 路徑，以 execution error fail closed、零寫入且不阻塞；regular 但 hard-linked 的 manifest 由 vendored 路徑既有的 single-link 檢查 fail closed。

**Non-Goals**

- 不改變 `--target <project>` 遇到 manifest 時的 fail-closed 行為與診斷文字。
- 不新增旗標、不改變 CLI mode 互斥集合、不改變 registry 檔案格式。
- 不改變 `install_target` 的內部契約。`install_vendored_target` 只擴充一個預設關閉的 batch-only 參數（D5），除此之外其內部契約不變，明示 `--vendor` 的行為逐字不變。
- 不修正 `--all` 既有的「不可讀 target parent 使原生 `OSError` 逸出並中止批次」行為：那是本變更之前就存在的缺陷，修正它需要放寬迴圈的例外子句而改變 receipt-based target 的既有診斷，超出本變更範圍。
- 不為 batch mode 新增 JSON 輸出。
- 不修改 `AGENTS.md`／`CLAUDE.md` 的 managed guidance block：兩者均未敘述 registry batch 或 manifest-presence 分派，不因本變更失真。

## Decisions

**D1 — 分派由 read-only probe 決定，probe 自身不產生診斷、也不 raise。**
新增 module-level 函式 `registry_publication_mode(source: Path, record: str) -> str`，回傳 `"vendor"` 或 `"receipt"`。它只做讀取，不取鎖、不寫入、不解讀 target config。它的**整個函式主體包在單一 try 內**，任何分支拋出的任何 exception——包含 `InstallerError`、以及 `ensure_contained` 未包裝而直接逸出的原生 `OSError`／`PermissionError`——一律落到 catch-all 分支回傳 `"receipt"`，交由 `install_target` 以其既有 fail-closed 契約診斷。這維持了「batch 的診斷文字不因本變更而改變」，也確保 probe 不會成為新的 batch 中止來源。

**D2 — probe 是有序且窮盡的分割，最後一支是涵蓋全部剩餘輸入的 catch-all。**
在 D1 的單一 try 之內依序判定，第一個成立者勝出：

1. resolved path 等於 canonical source → `"receipt"`
2. `path_is_present(resolved, PORTABLE_MANIFEST_PATH)` 為真，且 `ensure_regular_shape(resolved, PORTABLE_MANIFEST_PATH)` 未拋出 → `"vendor"`
3. 其餘全部 remaining record，以及任何分支求值時拋出的任何 exception → `"receipt"`

不逐一列舉要捕捉的 exception 型別：型別列舉本身就是分類缺口的來源，D1 的 catch-all 以「任何 exception」表述。第 1 支必須排在第 2 支之前，因為 canonical source 自身就具有 portable manifest，缺少這一支會讓手動編輯 registry 混入的 source record 失去 receipt 分支既有的 non-source 診斷。刻意不為「record 不是既存目錄」另設一支：那類輸入在第 2 支求值時，`ensure_contained` 對不存在的路徑段以 `FileNotFoundError` 略過而 `path_is_present` 回傳假、對非目錄的路徑段以 `NotADirectoryError` 逸出，兩者都落到第 3 支的 catch-all 而得到相同的 receipt 結果與相同的既有診斷。多一支只會擴大規格面而不改變任何輸入的結果。

**D3 — 只有 regular shape 的 manifest 會被分派到 vendored 路徑，其餘一律 fail closed 於 receipt 路徑。**
vendored 路徑不能安全地承接非 regular 的 manifest：它會在 `ensure_regular_shape` 之前就以 `read_regular` 開檔，FIFO 因此永久阻塞。所以 D2 第 2 支同時要求存在與 regular shape，非 regular 的 shape 一律落入 catch-all 的 receipt 路徑，由只做 `lstat`、不開檔的既有檢查 fail closed：

- manifest 或其 parent boundary 為 symlink → `path_is_present` 以 `symlink managed boundary: .cash-skills/manifest.tsv` raise → 落入第 3 支 → receipt 分支 → `install_target` 自身的同一 `ensure_contained` 以同一診斷 fail closed。
- manifest 為 directory、FIFO 或其他 non-regular 且非 symlink 的 shape → `ensure_regular_shape` 以 `unsafe regular file identity` raise → 落入第 3 支 → receipt 分支 → `install_target` 以 `target is managed by a portable manifest; use --vendor` fail closed。

regular 但 hard-linked 的 manifest 是唯一仍會進入 vendored 路徑的 unsafe shape：`ensure_regular_shape` 只判 `S_ISREG`，因此它通過第 2 支，隨後由 pre-lock `snapshots` 中 `read_regular` 的 `allow_hardlink=False` 檢查以 `unsafe regular file identity` fail closed。開啟 regular file 不會阻塞，所以這條路徑安全，且它同時是 `failed` 帶 ` (vendored)` 後綴的天然載體。

不變式是：present-but-malformed 的 manifest MUST NOT 被當成 absent 而讓任一路徑繼續發佈；它一律以 execution error 結束、零寫入，且因為 receipt 路徑只 `lstat` 不開檔，不會發生 FIFO 阻塞。落入 receipt 路徑的三種 shape 其輸出行不帶 ` (vendored)` 後綴——它們沒有被分派到 vendored 路徑——後綴在非成功 label 上的驗證由 Implementation Contract 10 列出的 `conflict`、`newer` 與 hard-linked manifest 的 `failed` 三種情境承擔。

**D4 — probe 誤判的最差情況等同今日行為。**
probe 誤判為 `"receipt"` 時，`install_target` 中 `path_is_present(target, PORTABLE_MANIFEST_PATH)` 後那條產生 `target is managed by a portable manifest; use --vendor` 的既有拒絕仍會生效，因此隱式反向轉換在任何 probe 結果下都不可能發生。這使 catch-all 分支是安全的預設值，而非需要額外保證的猜測。

**D5 — 分派到 vendored 分支的 record 必須在分類前重新確認 manifest 仍存在。**
probe 的 `lstat` 與 `install_vendored_target` 內部的 manifest 判定是兩次獨立讀取。若 manifest 在這個窗口內消失，`install_vendored_target` 會落入 receipt→portable 轉換或 receiptless adoption 分支，由 `--all` 執行 spec 明文要求「只可由明示 `--vendor` 轉換」的 forward cutover。因此 `install_vendored_target` MUST 取得一個 batch-only 的 keyword 參數（預設為關閉），由 batch 分派時帶入；開啟時它 MUST 在進入分類前重新確認 manifest 仍存在，不存在時以 `InstallerError` fail closed 並計為 `failed`，MUST NOT 執行 receipt→portable 轉換或 receiptless adoption。這是本變更唯一對該函式簽章與內部契約的擴充，Non-Goals 與 Implementation Contract 已據此收窄；明示 `--vendor` 不帶該參數，其既有行為逐字不變。該參數 MUST 在該函式的任何內部 re-entry 上原樣保留，包含 journal recovery 成功後的自我遞迴呼叫——該遞迴以明列 keyword 重新呼叫自身，漏傳會讓重入以關閉狀態重新分類，正是本 Decision 要擋住的路徑。既有的 pre-lock 與 locked snapshot revalidation 不足以涵蓋此窗口：它們比對的是取鎖前後 target inputs 是否一致，而此處要擋的是「取鎖前 manifest 就已不存在」——那對 revalidation 而言是一致的狀態，只是分類結果變成 receipt 轉換或 receiptless adoption。

**D6 — batch 分派到 vendored 路徑的 record，其殘留 receipt 會在同一 transaction 內被刪除。**
`install_vendored_target` 在 transaction 尾端無條件加入 `receipt_delete`（`if receipt_snapshot.exists`），且 manifest 存在時不解析 receipt 內容。這是 `Repo-vendored Cash bundle 發佈` requirement 既有且明文的 machine-local residue cleanup，本變更不改變它——但它的可達性改變了：實作前同時持有 receipt 與 regular manifest 的 target 在 `--all` 下是 `failed` 且零寫入，實作後會被發佈並刪除該 receipt。因此 proposal Non-Goals 與 Goals 中「receipt-based target 逐字不變」的主詞必須明確定義為「manifest 缺失或非 regular shape 的 target」，且此後果必須被明文記載與測試釘住，不能只存在於被繼承的既有契約裡。

**D7 — 兩條分支共用既有的 label 與 summary 格式，vendored 分支加上 mode 後綴。**
`install_vendored_target` 與 `install_target` 回傳值域相同，因此既有的 `would-update`／`updated`／`current`／`newer`／`conflict`／`failed` 對映與 `counts` 字典完全不需改動。vendored 分支的每一行輸出在 record 之後附加 ` (vendored)`，形式為 `<label>: <record> (vendored)`。後綴反映的是被分派到的 mode，因此在該分支以 `failed`、`conflict` 或 `newer` 結束時同樣出現。receipt 分支的輸出逐字不變。加上後綴的理由是 vendored publication 會寫入 target 版控中的檔案，使用者需要在 batch 輸出上直接看見哪些 repository 的工作樹被動到。

**D8 — probe 呼叫置於 per-record `try` 之內。**
即使 D1 已保證 probe 不 raise，`options.all` 迴圈仍 MUST 把 probe 呼叫放在每個 record 既有的 `try` 之內，後綴以 probe 結果決定、probe 未產生結果時以 receipt 為預設。這保證的範圍精確地是：**probe 自身不成為新的批次中止來源**。它不保證所有例外都會被計為 `failed`——迴圈的例外子句是 `except InstallerError`，而 `ensure_contained` 的 `os.lstat` 只捕捉 `FileNotFoundError`，因此不可讀的 `.cash-skills` parent 會讓原生 `PermissionError` 從 `install_target` 逸出並中止批次。那是今日 `--all` 既有的行為，本變更不改變它，也不擴大它：probe 吞掉該例外後分派到 receipt，結果與今日逐字相同。

**D9 — `--register` 只移除 manifest 拒絕，其餘驗證不動。**
`run()` 中 `options.register` 分支移除 `path_is_present(Path(project), PORTABLE_MANIFEST_PATH)` 的拒絕。`canonical_target`、`Path(project) == source` 的 non-source 檢查、`validate_target_prerequisites`、去重與 atomic registry 寫入全部保留。`--register` 仍不執行任何安裝，也仍不建立 target 的 `openspec/config.yaml`。

**D10 — `--target` 的拒絕保留。**
`install_target` 中 `target is managed by a portable manifest; use --vendor` 的檢查與其診斷文字不動。它同時是 D4 的安全網：即使 batch probe 誤判，隱式反向轉換仍被擋住。

**D11 — `--all --force` 逐字繼承 vendored force 語意。**
迴圈把 `force=options.force` 原樣傳入被分派到的路徑，因此 `--all --force` 會在所有已登錄的 vendored repository 同時收斂受管 drift。這個作用面是本變更新開的：今日 `--all --force` 對 vendored target 一律 `failed`。契約上不為它加入額外閘門，但 MUST 明文記錄其邊界——只收斂 replaceable managed bytes 與 mode class，對 unsafe shape、version downgrade、invalid baseline manifest 或未核准的 launcher drift 仍 fail closed——並以契約測試釘住。

**D12 — bundle version bump 必須是第一個實作動作。**
`.cash-skills/lib/cash_cli/installer.py` 是 replaceable runtime record，受 first-parent bundle history gate 守衛。`cash-skills.version` 與 `installer.py` 的 `BUNDLE_VERSION` 常數必須同步調升為 `2.21.0`（新增可觀察的 batch 行為，屬 minor），且 bump 必須排在第一個受守衛檔案被修改之前，否則 history gate 會以 `changed without a strictly greater cash-skills.version` 失敗。反過來說，bump 完成到 D13 的 manifest 重新發佈之間，`scripts/cash-skills/tests/test_bundle_version_history.py` 的 `__main__` 必然以 `portable manifest is not canonical` 失敗——`check_history` 要求 `.cash-skills/manifest.tsv` 逐 byte 等於由工作樹版本與 `installer.py` digest 導出的 canonical bytes。因此該腳本只能在 manifest 重新發佈之後才有意義，bump task 自身必須改用該時點可判定的斷言。

**D13 — 收尾必須重新發佈 canonical portable manifest。**
`installer.py` 屬受管 runtime，內容改變後 `.cash-skills/manifest.tsv` 的 `runtime_generation` 與 record digest 隨之改變，launcher 的 manifest gate 會立即以 `manifest_invalid` fail closed。因此每個修改 `installer.py` 的 task 都必須在其後的第一個 Cash CLI 指令之前於本 repository 執行 `./install-cash-skills.fish --self`，收尾再執行一次確認 canonical。本變更未修改任何 skill，因此不需要執行 `scripts/cash-skills/generate.fish`。

**D14 — 使用者文件必須與新行為同步。**
`CASH-SKILLS.md` 有四處、`CASH-INIT-RECEIPT.md` 有三處敘述會因本變更變成事實錯誤或不完整（後者包含 mode 對照表的 `--register` 與 `--all` 兩列，以及 `--init-receipt` 段落的職責分配句），且 `scripts/cash-skills/tests/skill-checks.fish` 對這兩份文件的正向 `assert_contains` 不會對過時敘述失敗，其對 `CASH-INIT-RECEIPT.md` 既有的三個 `assert_absent` 也都不涵蓋本次要改寫的敘述。兩者都不是 `GUIDANCE_PATHS`、也不是 bundle inventory record，因此其修改不受 bundle history gate 約束。但文件 task 仍必須排在 D13 的 manifest 重新發佈之後：它唯一合適的 regression 是 `skill-checks.fish`，而該腳本包含 bundle history gate，gate 要求 manifest 已是 canonical。

## Implementation Contract

1. `cash-skills.version` 內容為 `2.21.0`，`installer.py` 的 `BUNDLE_VERSION` 常數為 `"2.21.0"`，兩者相等。
2. `cash_cli.installer` 提供 module-level 函式 `registry_publication_mode(source: Path, record: str) -> str`，回傳值恰為 `"vendor"` 或 `"receipt"`，依 D2 的三支有序分割判定；第 2 支同時要求 manifest 存在與 regular shape，其整個函式主體包在單一 try 內，任何 exception 一律回傳 `"receipt"`，因此在任何輸入上都不 raise。
3. `run()` 的 `options.all` 迴圈對每個 record 在該 record 既有的 `try` 之內呼叫 `registry_publication_mode`，`"vendor"` 分派到 `install_vendored_target`，`"receipt"` 分派到 `install_target`；兩者都以現有的 `source`、`dry_run=options.dry_run`、`force=options.force` 呼叫。
4. `install_vendored_target` 取得一個預設關閉的 batch-only keyword 參數；batch 分派時帶入，開啟時在進入分類前重新確認 `.cash-skills/manifest.tsv` 仍存在，不存在時以 `InstallerError` fail closed 且不得執行 receipt→portable 轉換或 receiptless adoption。明示 `--vendor` 不帶該參數，行為不變；該參數在該函式的任何內部 re-entry（含 journal recovery 後的自我遞迴）上原樣保留。
5. `options.all` 迴圈的 label 對映、`counts` 字典鍵集合、summary 行格式與 `return 1 if counts["conflict"] or counts["failed"] else 0` 的結束碼規則不變；單一 record 的失敗不停止後續 record，summary 仍輸出。
6. `options.all` 迴圈對 `"vendor"` 分派的 record 印出 `<label>: <record> (vendored)`，對 `"receipt"` 分派的 record 印出 `<label>: <record>`；後綴與最終 label 無關，`failed`、`conflict`、`newer` 行同樣帶後綴。stderr 的錯誤行格式 `<record>: <error>` 兩者共用且不變；但 vendored 路徑的 `conflict` 以回傳值而非 `InstallerError` 結束，因此不產生該 stderr 行，這個不對稱是既有兩條路徑本來就有的差異，本變更不消除它。
7. `run()` 的 `options.register` 分支不再包含 portable manifest 的拒絕；`canonical_target`、non-source 檢查、`validate_target_prerequisites`、registry 去重與 atomic 寫入行為不變。
8. `install_target` 中 portable manifest 的拒絕與其診斷字串 `target is managed by a portable manifest; use --vendor` 保持不變。
9. batch 分派到 vendored 路徑的 record，其殘留 `.cash-skills/receipt.tsv` 在同一 transaction 內被刪除，此為既有 residue cleanup 的既有行為。除第 4 項的 batch-only 參數外，`install_vendored_target` 的既有行為不變；`bootstrap_source`、`--init-receipt` 與 registry 檔案 schema 的既有行為不變。
10. `scripts/cash-skills/tests/test_installer_runtime.py` 涵蓋：混合 registry（一個 receipt target、一個 vendored target）的 `--all` 回報 `updated=2`、`failed=0` 且 exit 0，vendored target 的行帶 `(vendored)` 後綴；`--all --dry-run` 對 vendored target 回報 `would-update` 且該 target 零寫入；symlink 與 FIFO／directory 兩種 unsafe manifest shape 都落入 receipt 路徑並以各自的既有診斷 fail closed、零寫入且不阻塞；probe 產生的 `InstallerError` 不中止 batch，其餘 record 仍被處理且 summary 仍輸出；`--all` 與 `--all --force` 對 drifted vendored target 分別回報帶後綴的 `conflict` 與只收斂 replaceable managed bytes，版本較新的 vendored target 回報帶後綴的 `newer`，hard-linked manifest 的 vendored target 回報帶後綴的 `failed` 並以 `unsafe regular file identity` fail closed；batch-only 參數在 manifest 缺失時以 `InstallerError` fail closed；`--register` 接受 manifest-present target 並寫入 registry；`--target` 對同一 vendored target 仍以 exit 1 與 `--vendor` 指引失敗。
11. `CASH-SKILLS.md` 的四處與 `CASH-INIT-RECEIPT.md` 的三處敘述與新行為一致，涵蓋 batch 分派、`(vendored)` 後綴、`--register` 的接受條件，以及 mode 對照表中 `--register` 與 `--all` 兩列的適用範圍。
12. `.cash-skills/manifest.tsv` 由 `./install-cash-skills.fish --self` 重新發佈為 canonical 且反映最終的 `installer.py`。該指令在尚有未發佈的受管改動時回報 `Result: bootstrap`、在受管改動已增量發佈完畢時回報 `Result: current`，兩者皆滿足本項。

## Risks / Trade-offs

- **batch 會寫入多個 repository 的版控檔案。** vendored publication 依設計就會產生待提交的變更，`--all` 現在會一次在多個 repository 產生它們。緩解是 D7 的 `(vendored)` 後綴讓每個受影響的 target 在輸出中可辨識；`--dry-run` 仍可先預覽。
- **`--all --force` 的作用面明顯放大。** 依 D11，它會在所有已登錄 vendored repository 的工作樹同時收斂受管 drift，且 batch 沒有逐 target 確認。這是刻意接受的取捨：`--force` 本來就是明示的收斂指令，為 batch 另設閘門會使兩條路徑的 force 語意分歧。邊界由契約測試釘住。
- **vendored 分支帶來 receipt 分支沒有的失敗模式。** Git-committable planned path preflight 會在 target 的 `.gitignore` 排除受管路徑時 fail closed，因此某些 target 可能從「因模式不符而 failed」變成「因 exclude 規則而 failed」。這是真實且應該被看見的設定問題，非本變更引入的退化；診斷來自 `--vendor` 既有契約，會一次列出全部 blocked paths。
- **probe 與 `install_target` 內部檢查重複判定 manifest。** 這是刻意的冗餘（D4），代價是同一個 `lstat` 在 receipt 分支被執行兩次。以正確性換取一次 syscall 是划算的。
- **unsafe manifest shape 的診斷來源依 shape 而異。** 依 D3，symlink 得到 `symlink managed boundary`，其他 non-regular shape 得到 `target is managed by a portable manifest; use --vendor`。兩者都由 receipt 路徑 fail closed 且零寫入，但錯誤訊息不同，排查時需知道這個分野；後者的訊息對 FIFO manifest 而言是誤導性的（它指向 `--vendor`，而 `--vendor` 對該 shape 會阻塞），但統一診斷需要在 probe 內重寫 boundary 判定並改動 `install_target`，超出本變更範圍。
- **`--vendor` 對 FIFO manifest 會阻塞的既有缺陷不在本變更範圍內。** D3 的設計確保 batch 永遠不會踩到它，但明示的 `--vendor <project>` 仍會。修正它需要把 `ensure_regular_shape` 提前到 `install_vendored_target` 的 pre-lock snapshot 之前，屬該函式自身的缺陷，應以獨立 change 處理。
- **分派鍵是 target 工作樹中一個未經認證的檔案。** portable manifest 不是簽章；能寫入某個已登錄 repository 工作樹的人，放進一份自洽且版本較高的 manifest，就能讓該 record 被判定為 vendored 並在 `newer` 早期返回上零寫入通過，而 `newer` 不計入非零結束碼，於是該 target 從 batch 的錯誤訊號上消失。實作前同一 target 是 `failed` 且 exit 1。首次進入 vendored 模式不需要任何明示操作也不產生公告，這是接受 D1「probe 不產生新診斷」所換來的代價。
- **vendored 路徑的 `conflict` 不附 stderr 診斷。** receipt 路徑的 conflict 以 `InstallerError` 結束因而必定伴隨一行說明 drift 路徑的 stderr，vendored 路徑則以回傳值結束、只有一行 `conflict: <path> (vendored)`。同一份 summary 因此會混有可行動與不可行動的 conflict，使用者需另跑 `--vendor <project>` 取得細節。這是兩條既有路徑本來就有的差異，本變更把它暴露在同一份輸出裡。
- **`--register` 放寬後，registry 可容納兩種模式的 target。** registry 檔案本身不記錄模式，模式永遠由 target 當下的狀態決定；target 被轉換模式後不需要重新登錄。代價是 registry 內容不再能單看檔案就推斷 batch 會走哪條路徑。
