## Summary

把 `st_dev` 從 receipt stable identity 的比對條件中移除——它是 mount 時配發的 volume 編號，不是檔案屬性——同時補上它失去的形狀閘門，並讓 receipt gate 的失敗診斷分辨 content drift 與 identity drift，只在後者、且整份 receipt 的其餘部分都完好時，提供 `--init-receipt` 復原指引。

## Motivation

`.cash-skills/receipt.tsv` 的 stable records 依現行契約記錄 target-specific decimal 的 `st_dev` 與 `st_ino`，launcher 的 `validate_receipt` 與 installer 的 `validate_installed_receipt` 都以 digest、mode、`st_dev`、`st_ino` 四項與現地觀察值逐項相等作為通過條件。

`st_ino` 在同一 filesystem 內是穩定的檔案識別；`st_dev` 不是檔案屬性，而是 kernel 在 mount 時配發的 volume 編號。macOS 的 APFS volume 在重開機或重新掛載後會重新編號，因此一個完全未被更動的 target 會在使用者沒有做任何事的情況下突然無法啟動。

實測案例（2026-08-20，Tubify 專案，一個 manifest 缺失的 receipt-based target）：receipt 的全部 records 逐筆重算後，digest、mode 與 `st_ino` 全部相符，只有兩筆 stable records 的 device 從 `16777231` 變為 `16777233`；`16777231` 在目前的 mount table 上已經是 Preboot volume，而使用者家目錄所在的 Data volume 變成 `16777233`。結果是：

- 該 target 的 `.cash-skills/bin/cash list --json` 以 `receipt_invalid` 失敗，訊息為 stable record drift 並指名 `.cash-skills/bin/cash`
- 從全域 shim 執行 cash init 時，installer preflight 以 stable receipt identity drift 對同一個 path fail closed，連遷移到 portable manifest 的路徑都被擋住

這是誤判而非偵測。而且 `st_dev` 對這個 gate 沒有貢獻任何偵測力：stable path 是由 project root 推導的固定路徑、以 O_NOFOLLOW 開啟、並且 digest 與 mode 都逐項比對。要讓 device 分量發揮作用，必須同時滿足「該路徑掛上了另一個 filesystem」、「新檔案的 inode 號碼恰好與記錄值相同」且「內容 digest 與 mode 也完全相同」——最後一項成立時該檔案本來就與記錄的內容等價，前兩項已無意義。也就是說，`st_dev` 帶來的是可預期的週期性誤判，換不到任何實際保護。

它同時帶來第二個問題：使用者拿到的診斷只說 drift，沒有任何可執行的下一步，而唯一的復原手段 `--init-receipt` 目前只在 `bootstrap_invalid`（receipt 缺失）的情境被引導。

影響面限於 manifest 缺失的 receipt-based targets。Portable manifest 依現行契約不記錄 `st_dev` 或 `st_ino`，manifest-present targets 不受影響。

## Proposed Solution

**一、stable identity 比對移除 device 分量，同時補上形狀閘門。**

receipt gate 的兩個驗證點——launcher `validate_receipt` 與 installer `validate_installed_receipt`——對每筆 stable record 的通過條件改為 digest、mode 與 `st_ino` 三項與記錄值逐項相等。觀察到的 `st_dev` 不再與 receipt 記錄的 device 值比較。

同時必須補上一道現在才顯露的缺口：installer 的 receipt parsing 已經有「device 非負、inode 為正」的範圍檢核，launcher 沒有，它只做 `int()` 解析。今天 launcher 之所以會擋下 `-1` 這種值，唯一機制就是即將被移除的等值比對。因此 launcher 必須補上與 installer 相同的範圍判準，否則 device 欄位會同時失去比對與範圍兩道閘門。

receipt schema 不變：stable records 仍是六欄，發佈時仍從現地 `lstat` 寫入當下的 `st_dev`。保留欄位是為了避免既有 targets 的 receipt 因欄位數改變而全面失效——現行契約明確保證既有 receipt 以相同 record 集合正常解析並走 update 路徑，而移除欄位會讓每個 registry target 都需要人工重新簽發，正好是本變更要消除的失敗經驗。該欄位自此只作為 machine-local provenance，並受上述形狀閘門約束。

「同一份 bytes 換到別的 inode 就會 fail closed」這個既有保證不受影響，但其鑑別力來源改變了：`Target 版控排除保護` requirement 的效果自此完全由 `st_ino` 承擔，因此該 requirement 的理由句與 installer 對應的 version-control diagnostic 都要改為只引用 inode。

**二、失敗診斷以 digest 為分類軸。**

- digest 與記錄值不符 → content drift。診斷 MUST NOT 建議 `--init-receipt`，以免把真正的內容漂移用重新簽發洗掉。
- digest 相符而 mode 或 `st_ino` 不符 → identity drift。檔案內容可證明仍是 receipt 記錄的那份，診斷附上 `--init-receipt` 指令。

mode 漂移刻意歸在 identity drift 這一側：`--init-receipt` 依既有契約本來就是 mode 正規化的授權入口，而 launcher 對 mode 漂移在進入 receipt gate 之前就以 `bootstrap_invalid` 失敗、既有 guidance 對該碼的處置正是執行一次 `--init-receipt`。把 mode 歸入 content drift 會讓同一份 target 從兩個 gate 拿到相反指引。

**三、`--init-receipt` 指引有兩個前提，一個靠驗證、一個靠文字。**

`--init-receipt` 會以現地 bytes 重簽整份 inventory，而且依既有契約只驗證 runtime 的路徑集合、不比對 runtime 或 skill bytes。因此 identity drift 的指引只在**該 gate 本來就會對現地檔案驗證的**其餘 records 都相符時才附上；否則一個「stable path inode 被換掉、同時 runtime 被竄改」的 target 會照指引把竄改簽成合法。前提的範圍刻意依 gate 分寫：launcher 只涵蓋 runtime records，因為 launcher 從不對 24 個 skill 檔做 digest 比對，把它們納入等於要求每次啟動多做 24 次檔案雜湊；installer 涵蓋 runtime 與 skill records，因為它的驗證迴圈本來就走完全部 records。兩側都不含 runtime generation——launcher 的 generation 重算是 receipt 內部一致性檢查，installer 也未對 target 重算 generation。此分寫留下一個刻意的不對稱：skill bytes 被竄改時 launcher 仍會給指引而 installer 不會，已在 design 的風險段誠實記錄其實際後果。前提不成立時，診斷會同時指名兩個 path 並給出可行的下一步，而不是留下一個無解狀態。

第二個前提是版控。「receipt 被誤納入版控後在別台機器 clone」正好落在 digest 相符、只有 inode 不符的 identity drift，而 `Target 版控排除保護` requirement 明白指名的執行面就是 launcher——指引若不加限定，就是在該保護唯一要擋的情境上發出邀請。曾考慮以 installer 的唯讀 version-control 查詢作為分支條件，但那條路走不通：launcher 無法在不新增每次啟動一次查詢的前提下判定；該查詢只由 direct、registry 與 batch 路徑執行，`--vendor`（也就是 cash init 的預設）整條路徑不做；而既有契約要求查詢失敗時靜默略過該 diagnostic，與「查詢失敗即比照已被追蹤處置並一併輸出」在字面上不可同時滿足。因此改採文字限定：指引一律內含版控前提，並且不得把 fresh clone 或任何取得方式陳述為無條件可以重新簽發的理由。這使限定在兩個 gate 的全部路徑一致生效，且不新增任何查詢。

另外 installer 是從 source repository 對別的 target 執行的，使用者當下的 project root 是 source repo，在那裡執行必然得到 `init_source_repo`。因此診斷必須指名該 target，而且由訊息自己在**指令以外的散文部分**指名——不是靠訊息前綴。原因是 `f"{target}: "` 前綴只存在於 installer 直接 print 的 diagnostic，不存在於 raise 出來的錯誤：direct 與 vendor 路徑印成 `Error: <message>` 完全不帶前綴，而批次模式的前綴是呼叫端加的，訊息自帶會重複。指令本身則只含 project-relative path 並以散文交代位置——而不是把絕對路徑內嵌進指令，那會讓含空白或 shell metacharacter 的路徑產生無法直接貼上執行的指令。

**四、guidance 與文件同步。**

source repository 的 `AGENTS.md` 與 `CLAUDE.md` Cash guidance 區塊補上四件事：identity drift 這個入口、content drift 的排除、`.cash-skills/receipt.tsv` 被納入版控時須先解除追蹤再重新簽發，以及 identity drift 入口只適用於診斷僅指名 stable record 的情境；診斷同時指名 runtime 或 skill record drift 時改為還原該 record 或從可信 source 重新安裝，不得重新簽發，且不得把 fresh clone 或任何取得方式陳述為無條件可以重新簽發的理由。這些由既有 guidance deployment 帶到每個 target。這四件事各補至少一條 literal 斷言到 `scripts/cash-skills/tests/skill-checks.fish`，而不是只更新該檔的 guidance baseline digest——digest 只能偵測漂移，無法驗證條款存在。`CASH-SKILLS.md` 與 `CASH-INIT-RECEIPT.md` 同步說明 device 欄位的新地位。

**五、launcher bytes 變更走既有治理路徑，並登錄兩筆 transition。**

本變更修改 stable launcher，依現行契約需要 bundle version 由 `2.12.0` 嚴格調升為 `2.13.0`，並在 `APPROVED_LAUNCHER_TRANSITIONS` 登錄 exact transition。必須登錄**兩筆**：`launcher_update` 以精確的 (old, new) 配對授權替換、沒有鏈式推導，只登錄 `76fe6dd649b1df558ef374d055ca2c5fe4c40a9200b32a1da1d41ca631c3d52f`（2.12.0 的 launcher）會讓任何仍停在 `592345fffa009998d48008857ad903d89b0e5f0986d141a5fec26368b527c8a4` 的 target 永久無法升級——而本變更修的 bug 本身就會把 target 凍結在原地，那正是受影響族群。

## Non-Goals

- **不改動 process 內同一 mount epoch 的 TOCTOU identity 比對。** `workspace.py` 與 `installer.py` 中大量的 `fstat` 對 `lstat` device/inode 比對，兩次觀察都發生在同一次執行內，對 remount 重新編號免疫，不在本變更範圍。
- **不改動 transaction journal 的持久化 identity。** `InstallTransaction` journal 的 parent 與 published identity、以及 launcher operation 保存的 old device/inode 同樣會被寫入磁碟並可能在後續執行的 recovery 中比對，屬同一缺陷類別。必須說明的是，這個排除不是因為風險低：留下 journal 的事件（kernel panic、斷電、強制重開）與 volume 重新編號的事件（重開機）本來就是同一件事，因此這是相關性最高的組合；而 rollback 的 identity 比對不符會保留 journal 並鎖住該 target，`--init-receipt` 不處理 journal、`--force` 也不繞過，後果不是 fail-safe。排除的理由純粹是範圍：改動它會把整個 transaction 與 recovery fault matrix 拉進來。建議以高優先另開 change。
- **不改動 archive 的 legacy import destructive-cleanup identity 檢查。** Cash 的 per-change touched state 檔案，其 legacy import 記錄 `st_dev` 與 `st_ino`，archive 以它決定是否刪除來源檔；device 重新編號會使它記為 `legacy_cleanup: preserved_drift` 並保留原檔。該行為是 fail-safe，且它守護的是一個破壞性刪除，放寬其判準需要獨立的風險評估。附帶說明：本變更落地後，這會是 device 重新編號在使用者面前唯一殘留的症狀，而 `preserved_drift` 這個狀態字串並不區分「內容真的變了」與「volume 重新編號」——也就是本變更為 receipt 建立的 content／identity 區分尚未套用到那裡。後續 change 應一併帶過去。
- **不改變 receipt 的 record 集合、欄位數或 schema。**
- **不讓 launcher 自動觸發 `--init-receipt`，也不讓 installer 自動 rebind stable identity。** 重新簽發維持為使用者主動的明示動作。
- **不改動 portable manifest 的驗證路徑，也不改動 `--init-receipt` 的檢核順序、error code 集合與簽發邏輯。**
- **不統一 launcher `is_source_layout` 與 `--init-receipt` 的 source 判定。** 兩者判準不同（前者要求 contract mode 相等，後者依既有 requirement 明確不得以 mode 相等為條件），不一致時使用者會多繞一步並得到具名且可執行的 `init_source_repo`。統一它們會把 launcher 的 source 偵測拉進範圍。
- **不改動 shim 的 dispatch 與旗標映射。**

## Alternatives Considered

- **從 stable record 移除 device 欄位（六欄改五欄）。** 語意上最乾淨，但會使所有既有 targets 的 receipt 在新 bundle 下無法解析，違反「既有 receipt 以相同 record 集合正常解析並走 update 路徑」的既有保證，讓每個 registry target 都需要人工重新簽發。捨棄。
- **把 device 判準改為「必須等於 target project root 現地的 device」。** 保留了一個 filesystem containment 的性質，但該性質已由固定路徑推導、O_NOFOLLOW 與 digest 比對覆蓋，額外偵測力為零；同時它會讓 `.cash-skills/` 位於獨立 mount 的 target 從此 fail closed，等於用一個新的誤判類別換掉舊的；而且 launcher 是獨立 process，測試 harness 無法在不建立第二個 filesystem 的情況下驗證該分支。捨棄。
- **維持逐值比對，只在偵測到 device-only 分歧時輸出 `--init-receipt` 指引。** 修好了診斷但沒有修好誤判：使用者每次重開機後仍要對每個 receipt-based target 重新簽發一次才能繼續用 cash CLI。捨棄。
- **由 installer 在偵測到 identity drift 時於 transaction 內自動 rebind stable identity。** installer 持有 exclusive lock 且已有 rebind 能力，技術上可行；但 device 不再參與比對後，`Target 版控排除保護` 的全部效果就建立在 inode 上，自動 rebind 會直接抹除它。捨棄，只提供診斷。
- **把 `.cash-workspace.lock` 排除在 identity drift 指引之外。** lock 的 digest 是空內容的 SHA-256、沒有鑑別力，因此它的 identity 完全由 inode 承擔，而重簽會把被替換的 lock inode 洗白。但「receipt 被誤納入版控後在別台機器 clone」這個合法情境同樣會讓兩筆 records 的 inode 都改變，排除 lock 會讓該情境失去指引。改以在 guidance 明寫重新簽發的前提來緩解。

## Capabilities

### New Capabilities

（無）

### Modified Capabilities

- `cash-cli`：receipt stable identity 的比對條件、identity 欄位形狀閘門與 receipt gate 失敗診斷。

## Impact

- Affected specs: cash-cli
- Affected code:
  - New:
    - （無）
  - Modified:
    - `.cash-skills/bin/cash`
    - `.cash-skills/lib/cash_cli/installer.py`
    - `.cash-skills/manifest.tsv`
    - `cash-skills.version`
    - `AGENTS.md`
    - `CLAUDE.md`
    - `CASH-SKILLS.md`
    - `CASH-INIT-RECEIPT.md`
    - `scripts/cash-skills/tests/skill-checks.fish`
    - `scripts/cash-skills/tests/test_installer_runtime.py`
  - Removed:
    - （無）
