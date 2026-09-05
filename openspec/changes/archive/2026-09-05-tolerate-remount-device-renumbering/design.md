## Context

`.cash-skills/receipt.tsv` 是 manifest 缺失的 receipt-based target 的啟動信任根。它的兩筆 stable records（`.cash-skills/bin/cash` 與 `.cash-workspace.lock`）各記錄 project-relative path、lowercase SHA-256、four-digit mode，以及 target-specific decimal `st_dev/st_ino`。

兩個驗證點會讀這兩筆 records 並與現地觀察值比對：

- launcher `.cash-skills/bin/cash` 的 `validate_receipt`，在 import 任何 managed library 之前執行；失敗以 `receipt_invalid` 與 exit 1 結束。
- installer 的 `validate_installed_receipt`，在 preflight 內執行，早於 exclusive lock 的取得。它有兩個呼叫點：`install_target`（direct、registry、batch）與 `install_vendored_target`（`--vendor`，也就是全域 shim 的 cash init 預設）。

兩者目前的通過條件都是 digest、mode、`st_dev`、`st_ino` 四項逐項相等。

`st_dev` 是 kernel 在 mount 時配發給 volume 的編號，不是檔案本身的屬性。macOS 的 APFS volume 在重開機或重新掛載後會依掛載順序重新編號，於是一份完全沒有被更動的 target 會在使用者沒有做任何事的情況下同時失去 launcher 與 installer 兩條路徑。2026-08-20 在 `/Users/cash/Github/Tubify` 觀察到的即是此形態：digest、mode、`st_ino` 全數相符，兩筆 stable records 的 device 由 `16777231` 變成 `16777233`。

同一個 process 內以 `fstat` 對 `lstat` 比對 device/inode 的 TOCTOU 檢查（`workspace.py` 與 `installer.py` 中的多數比對）不受影響，因為兩次觀察屬同一個 mount epoch。只有把 device 寫入持久化資料、再於另一次執行讀回比對的地方才會受害。

## Goals / Non-Goals

**Goals**

- 讓未被更動的 receipt-based target 在 volume 重新編號後仍能通過 receipt gate。
- 讓 receipt gate 的失敗診斷能分辨「內容變了」與「同樣的內容換了 identity」，並只對後者、且只在該 gate 能證實整份 receipt 其餘部分完好時，給出可執行的復原指令。
- 復原指令一律帶著它的前提，且該前提在兩個 gate 的全部路徑一致生效。
- 不擴大也不縮小 receipt schema，讓既有 targets 的既有 receipt 仍能被新 bundle 正常解析並走 update 路徑。
- launcher bytes 的變更完整走 `受控 launcher bootstrap migration` 的既有治理路徑，且不把任何既有 target 留在無法升級的狀態。

**Non-Goals**

沿用 proposal `## Non-Goals` 的全部條目，尤其是：不改動 process 內同一 mount epoch 的 identity 比對、不改動 transaction journal 的持久化 identity、不改動 archive legacy import 的 destructive-cleanup identity 檢查、不改變 receipt schema、不讓 launcher 自動觸發 `--init-receipt`、不改動 portable manifest 驗證路徑與 `--init-receipt` 的檢核順序與 error code 集合、不新增任何 gate 對 target 版控狀態的查詢。

## Decisions

### D1：從 stable identity 的比對條件移除 device，保留欄位並補上範圍閘門

比對條件由四項降為三項：digest、mode、`st_ino`。

保留欄位而非刪除欄位，是因為現行契約保證「既有 registry targets 持有前一版本簽發的 receipt，在新版本以 `--all` 部署時以相同 record 集合正常解析並走 update 路徑」。把 stable record 由六欄改成五欄會讓每一份既有 receipt 在新 launcher 與新 installer 下都變成 invalid，使每個 target 都需要人工重新簽發——那正是本變更要消除的失敗經驗。

**必須同時補上範圍閘門。** installer 的 receipt parsing 已經有 `device < 0 or inode <= 0` 的範圍檢核，launcher 沒有：launcher 只做 `int(row[4])`。今天 `-1` 這種值之所以會被擋下來，唯一機制就是即將被移除的等值比對。因此移除比對的同時，launcher MUST 補上與 installer 相同的範圍判準，否則 `st_dev` 會同時失去比對與範圍兩道閘門。範圍以外的字面形式（例如 `int()` 也接受的底線或前後空白）在兩個 gate 都只由 `int()` 解析，本變更維持兩者一致而不另立更嚴的字面判準；其影響限於 provenance 欄位可能非 canonical，已記於 `## Risks / Trade-offs`。

**為何移除比對不損失偵測力。** stable path 由 project root 推導、以 O_NOFOLLOW 開啟，且 digest 與 mode 都逐項比對。device 分量要真正阻擋到什麼，必須同時滿足三件事：該路徑上掛載了另一個 filesystem、新檔案的 inode 號碼恰好等於記錄值、且新檔案的 digest 與 mode 也完全等於記錄值。第三項成立時該檔案的內容本來就與 receipt 記錄的內容等價，前兩項因此不再構成攻擊面。相對地，volume 重新編號是可預期且週期性發生的。

**這個論證對 `.cash-workspace.lock` 較弱，且是既有性質。** lock 依契約恆為 0 bytes，其 digest 是空內容的 SHA-256，任何一個空的 `0644` 檔都滿足它，所以「digest 相符即內容等價」對 lock 而言是免費滿足的。移除 device 後 lock 的 identity 綁定完全由 `st_ino` 承擔。這一點並非本變更造成的退化——digest 對 lock 一直沒有鑑別力——但它是 D3 的指引必須把版控前提寫進文字的原因之一。

**既有保證的鑑別力來源改變。** `Target 版控排除保護` requirement 的機制是「receipt 記錄 target-specific identity，一旦被納入版控，任何 inode 不同的取得方式都會使該 target 的 launcher fail closed」。該機制在本變更後完全由 `st_ino` 承擔，因此該 requirement 的理由句與 installer 對應的 version-control diagnostic 都必須改為只引用 inode，不再把 device 描述成 fail-closed 的成因。

### D2：失敗診斷的分類軸是 digest，不是「digest 或 mode」

兩個驗證點對每筆進入 identity 比對的 stable record 依序判定：

1. digest 與記錄值不符 → **content drift**。診斷指名該 path，且 MUST NOT 出現 `--init-receipt`。理由是重新簽發會以現地 bytes 覆寫 receipt，對真正的內容漂移而言等於把漂移合法化。
2. digest 相符而 mode 或 `st_ino` 與記錄值不符 → **identity drift**。

**mode 漂移屬於 identity drift 而非 content drift。** 把 mode 歸入 content drift 會與既有契約直接矛盾：`--init-receipt` 依 `Target-local receipt 初始化` requirement「bytes 一致但 mode 已漂移時 MUST 走一般簽發路徑重寫並回報 `initialized`」，也就是它本來就是 mode 正規化的授權入口；而 launcher 的 `open_regular` 在進入 receipt gate 之前就以精確 mode 檢查 stable path，mode 漂移在 launcher 端直接是 `bootstrap_invalid`，而既有 guidance 對 `bootstrap_invalid` 的處置正是執行一次 `--init-receipt`。若 installer 把同一個狀態判成「不得重新簽發」的 content drift，同一份 target 會從兩個 gate 拿到相反指引。因此分類軸只用 digest。

判定順序固定為先 digest 後 mode／inode：digest 不符時一律判為 content drift，不論 mode 或 `st_ino` 是否同時不符。

### D3：復原指引有兩個前提，一個靠驗證、一個靠文字

**前提一：該 gate 本來就會對現地檔案驗證的其餘 records 必須完好。** `--init-receipt` 以現地 bytes 重簽整份 inventory（兩筆 stable、全部 runtime、24 個 skills），而且依既有契約只驗證 runtime 的**路徑集合**（`BUNDLE_RUNTIME_PATHS`），不比對 runtime 或 skill bytes。若在 identity drift 時無條件給出指引，一個「launcher bytes 未變但 inode 被換掉、同時 runtime 被竄改」的 target 會照指引重簽，然後把被竄改的 runtime 簽為合法。

前提的範圍必須依 gate 分寫，不能一體適用。launcher 對 24 個 skill records 只做 receipt 內的 path、順序與 mode 檢查，從不對 skill 檔案本身做 digest 比對；把 skill records 納入 launcher 面的前提，等於要求每次啟動多做 24 次檔案雜湊——那是一個沒有被本變更分析過的行為與成本改變。因此 launcher 面的前提只涵蓋每一筆 runtime record；installer 面則涵蓋 runtime 與 skill records，因為 `validate_installed_receipt` 的迴圈本來就走完全部 records。前提不含 runtime generation：launcher 的 generation 重算是以 receipt 自身的 runtime 列進行的內部一致性檢查，installer 的 `receipt.generation != generation` 比的是 target receipt 記載值與 source 的 generation 且只在等版本時執行，兩者都不是現地 record 漂移，把它列入前提會違反「不要求任一 gate 新增它現行未執行的驗證」。

前提不成立時必須給得出下一步，否則本變更會把一個原本有解的狀態換成一個無解且無指引的狀態。因此第三支訊息除了同時指名 stable path 與漂移 record 的 path，還必須指出可行的下一步：把該筆 record 還原成 receipt 記錄的內容後重試，或從可信 source 重新安裝。

延後判定會改變失敗時機，因此有兩個附帶約束。其一，延後期間若命中該 gate 既有的其他 fail-closed 出口，以該既有出口回報，identity drift 不另行輸出。其二，launcher 在 receipt gate 內對 runtime records 逐檔取 digest 時必須以 `receipt_invalid` 回報失敗：該檔案開啟路徑的預設 error code 是 `bootstrap_invalid`，而既有 guidance 對 `bootstrap_invalid` 的處置是無條件執行一次 `--init-receipt`，讓延後判定擴大該出口等於繞過前提閘門。

**前提二：版控前提寫進指引文字，而不是寫成查詢分支。** `Target 版控排除保護` requirement 守護的情境——receipt 被誤納入版控後在別台機器 clone——正好落在 digest 相符、只有 inode 不符的 identity drift，而該 requirement 明白指名的執行面是 launcher。指引若不加限定，就是在該保護唯一要擋的情境上發出邀請。

曾經考慮以 installer 的唯讀 version-control index 查詢作為分支條件，但那條路走不通，理由有三：launcher 無法在不新增每次啟動一次版控查詢的前提下判定該狀態；`report_version_controlled_receipt` 只由 `install_target` 呼叫，`install_vendored_target` 整條路徑不做該查詢，而 `--vendor` 正是 proposal 指名的主要修復路徑；既有契約要求查詢失敗時靜默略過該 diagnostic，與「查詢失敗即比照已被追蹤處置並一併輸出該 diagnostic」在字面上不可同時滿足。

因此改採文字限定：指引一律內含版控前提，明白指出 `.cash-skills/receipt.tsv` 是 machine-local identity、被納入版控時必須先解除追蹤再重新簽發；且指引不得把「fresh clone」或任何取得方式陳述為無條件可以重新簽發的理由。這使限定在兩個 gate 的全部路徑一致生效，不新增任何查詢，也不改動既有查詢的唯讀性、靜默略過與不影響分類的契約。

**執行位置：兩個 gate 的措辭不同。** launcher 在 target 內執行，指引指向該專案根即可。installer 是從 source repository 對另一個 target 執行的，使用者當下的 project root 是 source repo，在那裡執行 `--init-receipt` 必然以 `init_source_repo` 失敗。因此 installer 版本的診斷必須指名該 target，而且必須由訊息自己指名。這裡有一個容易誤判的事實：`f"{target}: "` 前綴確實存在於 installer 直接 `print` 的 target-scoped diagnostic（`report_version_controlled_receipt`、journal 通知、保留 legacy skill），但它**不是** `InstallerError` 的形式——`validate_installed_receipt` 的 raise 與同檔其餘 `InstallerError` 都不帶前綴，`--target` 與 `--vendor` 經 `main()` 印為 `Error: <message>`，只有 `--all` 的批次迴圈由呼叫端加上 `f"{record}: "`。因此訊息若自帶前綴，`--all` 會出現重複前綴，而 direct 與 vendor 路徑若不自帶又會完全沒有 target 標示。解法是讓訊息在**指令以外的散文部分**指名該 target 的 resolved 絕對路徑，使指令中的 `in that project` 有明確指涉；指令本身維持不內插任何路徑，含空白或 shell metacharacter 的 target 因此不會產生無法貼上執行的指令。

**source-repository 提示優先。** launcher 既有的 `FAILURE_HINT` 機制用於 source repository 的專屬提示。identity drift 的提示只在 `FAILURE_HINT` 為空字串時設定，source layout 的提示因此保持優先。

### D4：不由 installer 自動 rebind

installer 已有 `rebind_receipt_stable_identity` 可用，技術上可以在偵測到 identity drift 時直接重綁並繼續。此路徑被否決：`Target 版控排除保護` requirement 的全部效果在 device 不再參與比對後就完全建立在 `st_ino` 上，自動 rebind 會靜默地移除該保護。兩個 gate 都只輸出診斷，重新簽發維持為使用者主動的明示動作。

### D5：launcher bytes 變更的治理、transition 集合與排序

本變更修改 stable launcher，因此依 `受控 launcher bootstrap migration`：

- `cash-skills.version` 與 `BUNDLE_VERSION` 由 `2.12.0` 嚴格調升為 `2.13.0`。
- `APPROVED_LAUNCHER_TRANSITIONS` 追加**兩筆**，new digest 均為本次產出的 launcher 的 SHA-256、introduced version 均為 `2.13.0`，old digest 分別為 `76fe6dd649b1df558ef374d055ca2c5fe4c40a9200b32a1da1d41ca631c3d52f`（2.12.0 的 launcher）與 `592345fffa009998d48008857ad903d89b0e5f0986d141a5fec26368b527c8a4`（2.12.0 之前的 launcher）。
- `.cash-skills/manifest.tsv` 由 install-cash-skills.fish 的 --self 模式重新發佈。

**為何需要第二筆。** `launcher_update` 以精確的 (old digest, new digest) 配對授權替換，沒有鏈式推導，`--force` 也不繞過。只登錄一筆的話，任何 launcher 仍為 `592345…`、也就是尚未升級到 2.12.0 的 target，在升到 2.13.0 時會以 `stable launcher drift requires an approved exact bootstrap migration` 永久 fail closed。而本變更修的 bug 本身就會把 target 凍結在原地，受影響族群與「跳過 2.12.0」的族群高度重疊。history gate 的檢查是「由 first-parent history 推導出的那一筆存在於集合中」的成員檢查，重複檢查以完整三元組為單位，因此多登錄一筆 skip transition 相容。

**排序。** 兩件事互相牽制。history gate 由 first-parent history 推導 new launcher bytes 的首次出現版本，因此 launcher 編輯、版本調升與 transition 登錄必須落在同一個 commit。另一方面 `.cash-skills/manifest.tsv` 同時記錄 bundle version、runtime generation 與每一筆 record 的 digest，而 `installer.py` 本身是 runtime record，因此 manifest 重新發佈必須是**全部 bundle bytes 變更完成之後的最後一步**——在中途發佈會在後續編輯時再度失效。本 repo 自身是 manifest-present target，所以從 launcher 第一次被編輯到 manifest 重新發佈之間，本 repo 的 `.cash-skills/bin/cash` 會以 `manifest_invalid` 不可用，期間只能以 install-cash-skills.fish 操作。

### D6：受影響 target 的修復途徑

修好的 installer 位於 source repository。使用者從更新後的 source 對受影響 target 執行 `--target`、`--vendor`（全域 shim 的 cash init 預設）或 `--all` 時，preflight 的 stable record 比對已不含 device，因此直接通過並完成升級或遷移。D5 的第二筆 transition 確保 launcher 停在 2.12.0 之前的 target 也走得通。

已經卡住、且尚未升級 bundle 的 target 仍可用既有手段自救：在專案根執行一次 `--init-receipt` 會以現地 `lstat` 重新簽發，把 device 欄位更新為當下的值。這在本變更之前就成立，本變更只是讓它不再是必要步驟。

## Implementation Contract

**IC-1** launcher `.cash-skills/bin/cash` 的 `validate_receipt` 中，stable record 迴圈的比較式 MUST NOT 包含 record 的 device 欄位。通過條件恰為：record digest 等於 `sha256_file(absolute)`、record mode 等於 `stat.S_IMODE(opened.st_mode)`、record inode 等於 `opened.st_ino`。

**IC-2** launcher 的 receipt 解析 MUST 在既有 `int()` 解析之後補上與 installer `parse_receipt` 相同的範圍判準：stable record 的 device 為負數或 inode 非正數時 MUST 以 `receipt_invalid` fail closed，且訊息 MUST 為 launcher 既有的形狀專屬字串 `receipt identity is invalid`，MUST NOT 落入 stable record 的分類訊息。此訊息要求是該行為唯一可觀測的 red 判準——移除等值比對之前，`-1` 是被比對而非被形狀閘門擋下的。

**IC-3** stable record 的失敗分類軸 MUST 只用 digest：digest 不符為 content drift；digest 相符而 mode 或 inode 不符為 identity drift。digest 與 identity 同時不符時 MUST 判為 content drift。此分類同時適用於 launcher 與 installer。

**IC-4** identity drift 的 `--init-receipt` 指引 MUST 只在該 gate 本來就會對現地檔案驗證的其餘 records 全數相符時附上，且 MUST NOT 要求任一 gate 新增它現行未執行的驗證。launcher 面的前提為每一筆 runtime record，MUST NOT 納入 skill records 的逐檔 digest；installer 面的前提為每一筆 runtime 及 skill record。兩側前提皆 MUST NOT 納入 runtime generation。實作上：content drift MUST 維持立即 fail closed；identity drift MUST 延後到該 gate 的其餘 records 驗證完成後才決定回報內容。延後期間命中「前提不成立」以外的既有 fail-closed 出口時 MUST 以該既有出口回報，identity drift 不另行輸出且診斷不附指引。沿用既有出口的唯一例外是 error code：launcher 在 receipt gate 內對 runtime records 取 digest 時 MUST 傳入 `error_code="receipt_invalid"`，MUST NOT 沿用檔案開啟路徑預設的 `bootstrap_invalid`。兩條路徑 MUST 都仍然 fail closed。

**IC-5** launcher 的三支訊息 MUST 為：`stable record content drift: {relative}`、`stable record identity drift: {relative}`、以及 IC-4 前提不成立時的第三支。第三支 MUST 以 `stable record identity drift: {relative}; {other_kind} record drift: {other_path}` 為前段，其後 MUST 接一個 `. ` 與逐字為 `Restore that record to the content the receipt records, or reinstall from a trusted source, then retry` 的下一步句；前段是釘死的，下一步句也是釘死的，兩者合起來才是完整訊息。第三支 MUST NOT 附上 identity drift 的 `--init-receipt` hint（此規定不涉及 `FAILURE_HINT` 的既有內容），並 MUST 同時保留兩個 path。`{other_kind}` 在 launcher 面 MUST 只取 `runtime`；多筆 record 同時漂移時 MUST 取該 gate 既有迭代順序的第一筆，此規則同樣適用於 stable 端——兩筆 stable records 同時 identity drift 時 `{relative}` MUST 取既有迭代順序的第一筆。因為該形態把既有的 `runtime record drift: {path}` 訊息包成子字串，測試 MUST 以 `stable record identity drift:` 前綴而非該子字串區分兩支訊息。identity hint MUST 只在既有的 `FAILURE_HINT` 為空字串時設定；`is_source_layout` 已設定的 source-repository 提示 MUST 保持優先。identity hint MUST 只在最終確定回報 identity drift 時才設定，MUST NOT 在延後判定開始時預先設定——`FAILURE_HINT` 是 module-global 且一旦設定就會被後續每一次 `fail()` 附加，預先設定會使延後期間命中的其他出口帶著無限定的指引輸出。

**IC-6** identity hint 的文字 MUST 同時滿足三件事：包含可執行的 `--init-receipt` 指令、指出 `.cash-skills/receipt.tsv` 是 machine-local identity 且被納入版控時須先解除追蹤再重新簽發、且 MUST NOT 把 fresh clone 或任何取得方式陳述為無條件可以重新簽發的理由。版控前提句 MUST 是一段兩個 gate 共用的 canonical fragment，其文字逐字為 `if .cash-skills/receipt.tsv is tracked by version control, untrack it first because it is machine-local identity`。每個 gate 的 identity hint MUST 恰為「該 gate 的執行位置子句 + `; ` + 該 canonical fragment」：launcher 面為 `Run PYTHONPATH=.cash-skills/lib python3 -s -P -B -m cash_cli.installer --init-receipt from the project root`，installer 面見 IC-8。兩段文字 MUST NOT 依賴任何對 target 版控狀態的查詢。因為 launcher 是零 import 的獨立檔、無法與 `installer.py` 共用常數，該 fragment 只能在兩處各自存在，因此 IC-13 MUST 加一條斷言證明它逐字同時出現在兩個檔案中，使單邊漂移可被機械偵測。

**IC-7** installer `validate_installed_receipt` 的 stable 分支 MUST NOT 比較 `snapshot.device`。通過條件恰為 digest、mode 與 `snapshot.inode` 三項相等。移除 device 比對 MUST NOT 改變函式簽章。非 stable record 的 conflicts 累積行為 MUST 不變：stable 分支今日即在累積 conflicts 之前丟出例外，因此「stable identity drift 與 runtime／skill 漂移並存」今日已是 raise 而非 conflicts，本變更只改變該次 raise 攜帶的訊息。`path != expected.path` 的 `receipt path mismatch` 檢查不變。

**IC-8** installer 的三支訊息的**分類前綴** MUST 分別為 `stable receipt content drift:`、`stable receipt identity drift:`、以及 IC-4 前提不成立時同樣以 `stable receipt identity drift:` 起頭的第三支；三支的完整形式由本條後文各自釘死，本句只列舉分類前綴，MUST NOT 被讀為完整字串的釘死。`{other_kind}` 在 installer 面 MUST 取 `runtime` 或 `skill`；該 `{other_kind} record drift:` 在 installer 是本變更新增的字串，而非沿用 launcher 的既有訊息。第三支 MUST 比照 IC-5 由釘死前段加釘死的下一步句組成，其下一步句與 IC-5 逐字相同；其前段 MUST 為 `stable receipt identity drift: <record path> in <resolved target path>; {other_kind} record drift: {other_path}`，同樣在指令與指示之外的散文部分指名該 target——第三支雖不含 `--init-receipt`，仍帶有「還原該 record 或從可信 source 重新安裝」這類可執行指示，在 `--target` 與 `--vendor` 路徑上訊息印為 `Error: <message>` 而不帶前綴，若不指名 target 會落入 D3 要避免的「誤以為應在目前所在 repository 操作」。content 訊息 MUST NOT 包含 `--init-receipt`；identity 訊息 MUST 在指令以外的散文部分指名該 target 的 resolved 絕對路徑，形式為 `stable receipt identity drift: <record path> in <resolved target path>`，使指令中的 `in that project` 有明確指涉。其指令文字 MUST 為 `Run PYTHONPATH=.cash-skills/lib python3 -s -P -B -m cash_cli.installer --init-receipt in that project; if .cash-skills/receipt.tsv is tracked by version control, untrack it first because it is machine-local identity`，也就是 IC-6 定義的「執行位置子句 + canonical fragment」形式。該指令 MUST NOT 內嵌 target 的絕對路徑，也 MUST NOT 使用 launcher 版本的「from the project root」措辭。identity 訊息本身 MUST NOT 自加 `<target>: ` 前綴：`--all` 的批次迴圈已由呼叫端加上該前綴，訊息自帶會產生重複前綴；而 `--target` 與 `--vendor` 經 `main()` 印為 `Error: <message>` 本來就不帶前綴，因此指名 target 的責任 MUST 由訊息散文承擔。此契約 MUST 同時適用於 `validate_installed_receipt` 的兩個呼叫點——`install_target` 與 `install_vendored_target`——且 MUST NOT 依賴任一路徑的版控查詢結果。

**IC-9** installer 的 version-control diagnostic 字串 MUST 改為只以 inode 描述 fail-closed 的成因，MUST NOT 再把 device 描述成該保護的一部分。該 diagnostic 的既有唯讀性、查詢失敗時靜默略過、不改變分類與 exit code 的契約 MUST 不變，且 MUST NOT 成為 identity 指引的前置條件。

**IC-10** 未受影響的面 MUST 維持不變：stable record 仍恰六欄、非 stable record 仍不得帶 identity 欄位；installer 的 receipt 發佈仍從現地 no-follow `lstat` 寫入當下的 st_dev；`rebind_receipt_stable_identity` 的行為與呼叫點不變。

**IC-11** `cash-skills.version` 的內容 MUST 為 `2.13.0`，`installer.py` 的 `BUNDLE_VERSION` MUST 等於該檔內容；`APPROVED_LAUNCHER_TRANSITIONS` MUST 保留既有那一筆並追加 D5 描述的兩筆；`.cash-skills/manifest.tsv` MUST 由 install-cash-skills.fish 的 --self 模式在全部 bundle bytes 變更完成之後重新發佈。

**IC-12** `AGENTS.md` 與 `CLAUDE.md` 的 CASH 受管區塊 MUST 逐 byte 相同，且 MUST 在既有 `bootstrap_invalid` 引導之外載明三件事：manifest 缺失的 receipt-based target 出現 stable record identity drift 的 `receipt_invalid` 時同樣可由 `--init-receipt` 復原；content drift 不得以重新簽發處理；`.cash-skills/receipt.tsv` 被納入版控時 MUST 先解除追蹤再重新簽發。該區塊 MUST NOT 把 fresh clone 或任何取得方式陳述為無條件可以重新簽發的理由。該區塊 MUST 另載明第四件事：identity drift 這個入口只在診斷「僅」指名該 stable record 時適用；診斷同時指名 `runtime` 或 `skill` record drift 時 MUST 改為指示還原該 record 或從可信 source 重新安裝，MUST NOT 指示重新簽發。此款不可省略，理由是 IC-5 與 IC-8 的第三支訊息逐字以 identity drift 的分類字串起頭（launcher 為 `stable record identity drift: `，installer 為 `stable receipt identity drift: `），因此只以分類字串比對套用該分流的讀者，會在 IC-4 的前提閘門正要擋下的情境執行 `--init-receipt`，把已漂移的 runtime 或 skill 內容簽為合法。既有被 `scripts/cash-skills/tests/skill-checks.fish` 斷言的 literal MUST 全數保留。

**IC-13** `scripts/cash-skills/tests/skill-checks.fish` MUST 為 IC-12 新增的四件事各補一條 `assert_contains` literal 斷言，與既有 literal 清單並列；MUST 另補一條斷言，證明 IC-6 的 canonical 版控前提 fragment 逐字同時出現於 `.cash-skills/bin/cash` 與 `.cash-skills/lib/cash_cli/installer.py`，使兩處釘死文字的單邊漂移可被機械偵測。該檔的 `assert_contains` 以 `rg -Fq` 做**逐行**比對，因此這條斷言反推出一個實作約束：該 fragment 在兩個檔案中 MUST 各自完整位於單一原始碼行，可在 `; ` 邊界拆行但 MUST NOT 在 fragment 內部拆——fragment 長 112 字元，而兩個檔案現行最長行皆為 106 字元，依既有行寬習慣以隱式串接拆行會使斷言失敗，且失敗訊息只會說 missing literal 而不指出真正成因；canonical Cash guidance baseline SHA-256 MUST 在 guidance 文字定案之後才重新計算並更新，任何後續對該區塊的文字調整（含 IC-12 第四款）MUST 重算一次。只更新 baseline digest 不構成契約驗證，因為任何寫錯內容的區塊只要重算 digest 就會通過。

**IC-14** `CASH-SKILLS.md` 與 `CASH-INIT-RECEIPT.md` MUST 說明 device 欄位不參與 identity 比對、只作為 provenance 並受形狀閘門約束。兩份文件 MUST 皆說明 identity 比對條件為 digest、mode 與 `st_ino` 三項。`CASH-SKILLS.md` MUST 另說明版控保護的鑑別力自此由 `st_ino` 承擔，並把既有的「對已 drift 的 receipt-only target 重跑 init 會把該 drift 合法化」限定為 content drift。`CASH-INIT-RECEIPT.md` MUST 另載明 stable record identity drift 是初始化入口、content drift 不適用、IC-4 前提不成立時的下一步（還原該 record 或從可信 source 重新安裝），以及 IC-6 的版控前提。`CASH-SKILLS.md` 既有的「對已 drift 的 receipt-only target 重跑 init 會把該 drift 合法化」MUST 限定為 content drift，並指出 identity drift 是允許重新簽發的入口。兩份文件 MUST 保留 `skill-checks.fish` 對它們既有斷言的全部 literal。

**IC-15** `scripts/cash-skills/tests/test_installer_runtime.py` MUST 為 spec delta 新增 requirement 的十三個 scenario 各提供對應驗證，順序與 spec delta 一致，對照如下。標記為 red 的案例在本變更實作之前 MUST 失敗；標記為 guard 的案例在實作之前即已通過，它們的角色是 regression guard 而非 red phase evidence。跨兩個 gate 的案例 MUST 至少拆成 launcher 與 installer 兩個測試函式，使 task 2.1 與 2.2 各自的完成時點都有可達的驗收；同一 gate 的多條路徑（例如 installer 的 direct 與 `--vendor`）各自可再拆為獨立函式。

| Scenario | 類型 | 驗證方式 |
| --- | --- | --- |
| Volume 重新編號後 launcher 仍通過 gate | red | receipt stable device 改為與現地不同的合法非負整數，launcher 正常執行 |
| Volume 重新編號後 installer preflight 仍通過 | red | 同一份 receipt，三項各一個測試函式：direct（`--target`）dry-run 不以 stable receipt drift 失敗；`--vendor` dry-run 同樣不失敗；以及一次 `--vendor` real run 完成遷移並回報既有分類。該 scenario 有兩條 THEN，第二條「安裝或遷移依既有分類正常完成」是 real-run 斷言，dry-run 通過 preflight 不足以覆蓋它。real run 取 `--vendor` 是因為它同時是全域 shim 的 cash init 預設修復入口、也是端狀態變動較大的一條（receipt-based 切換為 manifest-based）|
| Content drift 不被引導重新簽發 | red | 拆成 launcher 與 installer 兩個函式：stable path bytes 漂移，各自失敗且訊息含 content drift、**含該 stable record 的 project-relative path**、不含 `--init-receipt`。path 斷言對應 scenario THEN 的「並指名該 path」，該義務在 spec 正文也是獨立的 MUST |
| Identity drift 提供可執行復原指令 | red | 拆成 launcher 與 installer 兩個函式：receipt stable inode 改值，各自失敗且訊息含 identity drift、**含該 stable record 的 project-relative path**、並含**逐字完整**的指令——launcher 側斷言 IC-6 釘死的字串、installer 側斷言 IC-8 釘死的字串。只斷言 `--init-receipt` 子字串不足：一個只吐出 `see --init-receipt` 的實作會通過。scenario 的 AND 寫的是「完整指令」 |
| 指引一律內含版控前提且不背書任何取得方式 | red | 對 launcher 與 installer 的 identity 訊息斷言含 `tracked by version control` 與 `machine-local`，且不含 `fresh clone`；另以 `--vendor` 路徑重跑同一斷言 |
| Mode 漂移歸入 identity drift | red | stable path mode 漂移，installer 失敗且訊息含 identity drift 並含 `--init-receipt`；現行實作雖已輸出 identity drift 字樣，但不含指令，故斷言 MUST 同時涵蓋指令 |
| Content 與 identity 同時漂移時判為 content drift | red | 拆成 launcher 與 installer 兩個函式：同時改 bytes 與 receipt inode 值，各自斷言訊息為 content drift 且不含 `--init-receipt` |
| 其餘 records 同時漂移時改報該漂移並給出下一步 | red | 拆成 launcher 與 installer 兩個函式：receipt inode 改值並同時改一筆 runtime bytes，各自斷言訊息同時指名 stable path 與該 runtime path、不含 `--init-receipt`、且含還原或重新安裝的下一步；installer 側另斷言前段含該 target 的 resolved 路徑 |
| 延後判定期間命中既有出口時以該出口回報 | red | receipt inode 改值並對一筆 runtime path 建立 hard link（使其 `st_nlink` 為 2 而 mode 仍為 `0644`），斷言 launcher 以 `receipt_invalid` 而非 `bootstrap_invalid` 結束、訊息**指名該 runtime path**、且不含 `--init-receipt`。「指名該 runtime path」是本列唯一可鑑別的 red 判準：stable record 迴圈在 runtime 迴圈之前執行，因此今日這個 fixture 會在 stable 迴圈就以 `stable record drift` 結束，訊息只指名 stable path；另外兩條斷言今日即成立，不構成 red。MUST NOT 以 plain symlink 建構：symlink 的 `lstat` mode 為 `0755`，會在 `sha256_file` 之前就短路成既有的 `runtime record drift`，該路徑今日即以 `receipt_invalid` 結束因而不構成 red |
| Installer 的指引指向目標專案而非來源專案 | red | 斷言訊息在 `Run ` 之前的散文部分含該 target 的路徑、`Run ` 之後的指令字串不含該路徑、訊息不以 `<target>: ` 起頭、且不含 `from the project root`。比對 MUST 以 `Path(target).resolve()` 為準——`install_target` 對 target input 做 `resolve()`，macOS 上 `/var/folders/…` 會變成 `/private/var/folders/…`，以未 resolve 的 fixture 路徑比對會因與待測行為無關的理由失敗。不需要含空白的路徑：指令是不內插任何路徑的釘死字串，空白對這四條斷言的可鑑別性零貢獻 |
| Source repository 提示優先於 identity drift 提示 | guard | 以 `make_self_source` fixture 建構 source layout 後移除 manifest，並以測試 helper 合成一份合法 receipt（`make_self_source` 會同時移除 receipt 與 manifest，故此 helper 為本 task 的新增項），觸發 identity drift 後斷言診斷含 `./install-cash-skills.fish --self` |
| Negative device 的 receipt 在兩個 gate 皆 fail closed | launcher 為 red、installer 為 guard | receipt stable device 改為 `-1`。launcher 側 MUST 斷言失敗訊息為形狀專屬的 `receipt identity is invalid` 而非 `stable record drift`——僅斷言 `receipt_invalid` 不構成 red，因為今天 `-1` 是被即將移除的等值比對擋下的；installer 側斷言 `receipt stable identity is invalid`，因 `parse_receipt` 已有範圍檢核而在實作前即通過 |
| 未修復的 target 不因 identity drift 被自動改寫 | guard | 在沒有未完成 journal 的前提下觸發 identity drift，斷言三件事：receipt bytes 逐 byte 不變；訊息含 identity drift 分類字串；以及失敗發生在取得 exclusive lock 之前。三項在實作前皆已成立，角色是 regression guard，MUST NOT 當成 red evidence；本 change 新增的 identity 訊息與完整指令另由前述 red scenarios 覆蓋。時序驗證 MUST 使用不帶 `--dry-run` 的 direct real run，並同時設定 `CASH_INSTALL_TEST_HOOKS=1` 與 `CASH_INSTALL_HOLD_FILE=<hold>`；只設定後者不足，因為 `test_hooks()` 在 exact enable switch 缺失時會忽略全部 hold 設定而造成 false green，而 dry-run 即使取得 lock 也不會呼叫 `wait_for_test_hold`。測試 MUST 以 `Popen` 啟動 installer，在有限 deadline 內同時監控 process 與 `<hold>.ready`：正常實作應先以 identity drift 結束且 `.ready` 從未出現；若 `.ready` 出現，測試 MUST 立即建立 `<hold>.release`，讓錯誤實作離開 hold，再以「已越過取鎖邊界」的明確斷言失敗。完整 child lifecycle MUST 由 `try/finally` 管理：任何正常、deadline 到期、assertion 中途失敗或 `communicate(timeout=...)` 逾時的退出路徑都 MUST 嘗試建立尚未存在的 `.release`，以有限 timeout `communicate`；仍未結束時依序 `terminate`、有限等待、最後 `kill` 並再次 `communicate`，MUST NOT 留下 child process 或持有中的 workspace lock。cleanup failure MUST 保留原本「越過取鎖邊界」或「deadline 內未結束」的主要失敗原因，MUST NOT 以次生 cleanup error 遮蔽它。測試 MUST NOT 等待 `wait_for_test_hold` 自身的 10 秒 timeout。`wait_for_test_hold` 在 `acquire_lock` 之後才執行並建立 `.ready`，因此這個協定可機械證明失敗時序且在錯誤實作下也能有限時間回收。只斷言 receipt bytes 不變不足以覆蓋 scenario 的 THEN：一份什麼都沒寫的 target 也能通過該斷言 |

## Risks / Trade-offs

- **偵測面收斂。** device 分量被移除後，「另一個 filesystem 上 inode 號碼相同、且 digest 與 mode 也完全相同的檔案」不再被額外攔截。如 D1 所述，該情境下檔案內容與記錄內容等價，實質偵測力為零。此取捨為刻意且已在 proposal `## Alternatives Considered` 記錄。
- **`.cash-workspace.lock` 的 identity 完全由 inode 承擔。** lock 的 digest 是空內容的 SHA-256，對它沒有鑑別力，因此本變更後 lock 的「同一 inode」契約只剩 `st_ino` 這一道。`--init-receipt` 只要求 lock 是既存且為空的 regular file，所以在 lock identity drift 後照指引重簽會把新的 lock inode 簽為合法。之所以不把 lock 排除在指引之外，是因為「receipt 被誤納入版控後在別台機器 clone」這個情境同樣會使兩筆 records 的 inode 都改變，而該情境的既定復原手段就是先解除追蹤再重新簽發。緩解方式是 IC-6 與 IC-12 要求指引與 guidance 都內含版控前提。
- **launcher 對 skill bytes 本來就零偵測力，本變更不改變也不惡化該面，但指引不對稱可能造成誤解。** launcher 從不對 24 個 skill 檔做 digest 比對，因此「stable inode 被換掉、同時 skill 檔被竄改」的 target 會從 launcher 拿到重新簽發指引，而 installer 對同一 target 會因 skill conflict 不給指引。必須誠實說明的是：IC-6 與 IC-12 的版控前提是 identity provenance 的限定，並不能偵測 skill bytes 的完整性，因此對本風險沒有緩解作用。實際殘留風險是「使用者可能以為 launcher 通過即代表 skills 完好」，而非「把竄改簽為合法」——重簽後同版本的 installer 會以 `equal-version source integrity drift` 硬性攔下，不同版本的 installer 則會直接覆寫修復。消除該不對稱需要讓 launcher 每次啟動多做 24 次檔案雜湊，本變更不採納。
- **`st_dev` 欄位的字面形式仍不是 canonical。** 兩個 gate 都以 `int()` 解析該欄位，因此底線或前後空白等 `int()` 接受的字面形式不會被拒絕。本變更只補上與 installer 一致的範圍判準，不另立更嚴的字面判準，以免兩個 gate 的判準再度分歧。因為該欄位已不參與 identity 比對，其影響限於 provenance 欄位可能非 canonical。
- **版控前提以文字而非查詢實作，因此不會被機器強制。** 使用者仍可以忽略指引中的前提而在 receipt 已被追蹤時重新簽發。改以查詢分支實作的路走不通，理由已記於 D3；installer 既有的 version-control diagnostic 在 direct、registry 與 batch 路徑上仍會獨立輸出，構成第二層提醒，但 `--vendor` 路徑沒有該提醒。
- **launcher 變更的排序風險，以及 source repo 自身 CLI 的中斷窗口。** launcher 編輯、版本調升與 transition 登錄必須同屬一個 commit，否則 bundle history contract test 會在中間狀態失敗；而 manifest 重新發佈必須是全部 bundle bytes 變更完成之後的最後一步，中途發佈會在後續編輯時再度失效。本 repo 自身是 manifest-present target，因此從 launcher 第一次被編輯到 manifest 重新發佈之間，本 repo 的 cash CLI 會以 `manifest_invalid` 不可用，期間只能以 install-cash-skills.fish 操作。
- **第二筆 catch-up transition 是一次性補救，不是通則。** D5 追加的 `(592345fff…, 新 launcher, 2.13.0)` 只解決本次的落後族群；spec delta 沒有為它建立規範位置，master 的 `受控 launcher bootstrap migration` 也沒有任何條款要求未來的 launcher 變更登錄 catch-up entry。因此 archive 之後這個判斷只存在於程式碼裡的一筆 tuple，下一次改 launcher 的 change 依現行 requirement 只登錄一筆仍然完全合規，同樣的 stranding 會原地復發。之所以不在本 change 把它寫成通則，是因為那會把本 change 的範圍從「修 st_dev 誤判」擴張到「治理未來所有 launcher 變更」。復發防護目前由 `openspec/signals/exact-transition-allowlist-strands-lagging-targets.md` 承擔；要讓它成為契約需要另開 change。
- **guidance baseline digest 的排序風險。** `skill-checks.fish` 的 baseline SHA-256 只有在 guidance 文字完全定案後計算才會正確；任何後續文字微調都必須重算。
- **source layout 判定與 `--init-receipt` 的 source 判定不同源。** launcher 的 `is_source_layout` 以 mode 精確相等為條件，而 `--init-receipt` 的 source 判定依既有 requirement 明確不得以 contract mode 相等為條件。兩者不一致時（例如 umask 偏移的 source clone），launcher 會給出 identity hint，而使用者照做會得到 `init_source_repo`。該失敗是具名且可執行的——它本身就指向 `./install-cash-skills.fish --self`——因此是一步繞路而非死路。本變更不統一兩個判定，以免把 launcher 的 source 偵測納入範圍。
- **transaction journal 的同類缺陷在本變更範圍外，且風險高於原先評估。** journal 會把 device 寫入磁碟並在後續執行的 recovery 中比對。留下 journal 的事件（kernel panic、斷電、強制重開）與 APFS volume 重新編號的事件（重開機）是同一件事，因此這是相關性最高的組合而非罕見窗口；後果也不是 fail-safe：rollback 的 identity 比對不符會丟出例外並保留 journal，target 被鎖住直到 recovery 完成，`--init-receipt` 不處理 journal，`--force` 也不繞過。本變更不處理它是為了不把整個 transaction 與 recovery fault matrix 拉進範圍，但 proposal 建議的後續 change 應以高優先處理。
- **archive 的 legacy import cleanup 是 device 重新編號在本變更後唯一殘留的使用者可見症狀。** 它以 `legacy_cleanup: preserved_drift` 保留使用者檔案，屬 fail-safe，但該狀態字串不區分「內容真的變了」與「volume 重新編號」——也就是本變更為 receipt 建立的 content／identity 區分尚未套用到那裡。後續 change 應一併帶過去。
