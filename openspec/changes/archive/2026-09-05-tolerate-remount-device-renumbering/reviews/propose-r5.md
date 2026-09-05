# Cash Propose Review — Round 5

## Reviewer Findings

本輪為 micro round，由單一 Reviewer V 執行 delta verification，重點是驗證第 4 輪「移除一整套機制」是否留下懸空引用。

### Cumulative blocking set 逐筆判定

- Q1（launcher 面的一鍵繞法與 fresh clone 背書，Critical）：`resolved`。Reviewer V 逐處檢視 `fresh clone` 在四份 artifact 的全部 7 次出現，確認全部落在禁止或說明脈絡，無任何背書用法；另指出 master spec 既有的 `Fresh clone 一次初始化後 CLI 可用` scenario 標題屬 receipt 缺失的 init 情境，非背書。IC-6 指定的 launcher hint 文字經逐項核對確實同時滿足三項要求，且與 `fail()` 的 `f"{message}. {FAILURE_HINT}"` 附加機制、JSON 模式相容。已無任何條款要求 gate 依賴版控查詢。
- Q2（`--vendor` 路徑兩條 MUST 互相封死，Warning）：`resolved`。Reviewer V 以真實碼確認 `report_version_controlled_receipt` 僅由 `install_target` 呼叫、`install_vendored_target` 的驗證呼叫點確實不做查詢；並 grep 確認四份 artifact 已無「一併輸出」「查詢失敗保守側處理」「journal recovery 沿用查詢結果」「兩步指引」的任何規範句，互相封死的兩條 MUST 已隨機制消失。反向覆蓋已補（IC-8 明文兩個呼叫點、tasks 2.2 的 `--vendor` 驗收、IC-15 對應列），且確認 `install_vendored_target` 的 `manifest is None and receipt is not None` 分支確實會走到該驗證因而斷言可建構。

兩個成員皆以 verified resolution 離開 cumulative blocking set。

### 機制移除的懸空引用檢查結果

Reviewer V 逐項確認：IC-1 至 IC-15 全部有定義、被引用、無跳號、無孤立引用，且逐條核對每個引用的內容與該 IC 實際規定相符（唯二不符見下方 F6）；13 個 scenario 與 IC-15 對照表逐字 1:1 且同順序；三個 MODIFIED requirement 標題逐 byte 相同。殘留句只有一處（見 F4）。

### Warning

- `severity`: Warning / `confidence`: 85 / `layer`: design / `disposition`: `fix-introduced` / `introduced_by`: 第 4 輪 Fix Action 10 / `location`: `design.md` IC-15 第 9 列；spec delta `#### Scenario: 延後判定期間命中既有出口時以該出口回報` / `summary`: 該列以「把一筆 runtime path 換成 symlink」建構，但 launcher 的 runtime 迴圈是 `if f"{mode:04o}" != mode_text or sha256_file(absolute) != digest:`，左運算元先求值，而 symlink 的 `lstat` mode 在 macOS 為 `0755`（≠ `0644`），因此會短路成既有的 `runtime record drift` 而根本走不到 `sha256_file` 的 `bootstrap_invalid` 出口——今日即以 `receipt_invalid` 結束，是假 red，實作後也不會觸及它要驗的行為 / `recommendation`: 改以 hard link 建構（`st_nlink` 為 2 而 mode 仍為 `0644`，通過 mode 比對後在 `open_regular` 的 `st_nlink != 1` 失敗）

### Suggestion（經 confidence filter 由 Warning 降級，或原即為 Suggestion）

- `confidence`: 72 / `disposition`: `fix-introduced` / `introduced_by`: 第 4 輪 Fix Action 1 / `location`: spec delta `Target-local receipt 初始化` 的 guidance 段與 `#### Scenario: Init 指引隨 guidance 部署到達 target`；`design.md` IC-12／IC-13 / `summary`: IC-12 要求 guidance 載明三件事並加上 fresh-clone 禁止、IC-13 要求各補一條 literal 斷言，但 spec delta 對該區塊只寫了兩件事、scenario 也只覆蓋兩件；第三件（版控時須先解除追蹤）與 fresh-clone 禁止在 requirement 層完全沒有規範，而 guidance 正是 Q1 修法的另一半，缺規範層背書等於 archive 之後不會留在 master spec 裡
- `confidence`: 70 / `layer`: text / `disposition`: `fix-introduced` / `introduced_by`: 第 4 輪 Fix Action 1 / `location`: `proposal.md` `## Proposed Solution` 第四節 / `summary`: 該節仍把 guidance 第三件事描述為「重新簽發的前提（信任根是現地內容，只在能說明檔案為何是目前這個 identity 時才執行）」——這正是第 4 輪判定為對版控情境發出許可而刪除的措辭的同義中文，是機制移除後唯一的殘留句
- `confidence`: 68 / `disposition`: `fix-introduced` / `introduced_by`: 第 4 輪 Fix Actions 10、13 與第 1 輪 Fix Action 13 / `location`: `design.md` IC-4 第 5 句與 IC-5 末句；spec delta 延後出口 scenario / `summary`: `FAILURE_HINT` 是 module-global，一旦設定就會被後續每一次 `fail()` 附加，而 IC-5 只規定「只在為空時設定」與「第三支訊息不附 hint」，沒有規定**設定時機**；若實作在偵測到 identity drift 當下就設定（global 最自然的用法），延後期間命中的其他出口都會帶著無限定的 `--init-receipt` 輸出，而新 scenario 只斷言 error code 抓不到這點
- `confidence`: 62 / `disposition`: `fix-introduced` / `introduced_by`: 第 4 輪 Fix Actions 1、2 / `location`: `design.md` IC-15 第 5 列 vs IC-8／IC-6 / `summary`: 第 5 列對 installer 訊息斷言 `tracked by version control` 與 `machine-local` 兩個 literal，但 IC-6 只把逐字文字釘死在 launcher 面，IC-8 對 installer 只要求「符合 IC-6 三項要求」——三項要求是語意的，實作者用同義措辭即滿足 IC-8 而失敗於該斷言
- `confidence`: 60 / `layer`: text / `disposition`: `fix-introduced` / `introduced_by`: 第 4 輪 Fix Actions 5、12 / `location`: `tasks.md` 4.2、4.3；`design.md` IC-14 / `summary`: 兩個 task 都寫「依 IC-14」，但 IC-14 未規定它們要求的「前提不成立時的下一步」「版控前提」「版控保護的鑑別力由 inode 承擔」；IC 編號正確，內容不足
- `confidence`: 58 / `disposition`: `fix-introduced` / `introduced_by`: 第 4 輪 Fix Action 13 / `location`: spec delta 前提段第一與第二句；`design.md` IC-4 / `summary`: 「延後期間命中該 gate 既有的其他 fail-closed 出口 MUST 以該既有出口回報」與前一句「前提不成立時診斷 MUST 同時指名兩個 path」在 launcher 的 `runtime record drift` 這一個出口上重疊——它既是既有出口、又正是偵測「前提不成立」的機制，兩條 MUST 對同一次失敗要求不同輸出；且「沿用既有出口」與「改寫既有出口的 error code」並置，使 scenario 標題與其 THEN 看起來相反
- `confidence`: 50 / `layer`: text / `disposition`: `fix-introduced` / `introduced_by`: 第 4 輪 Fix Action 8 / `location`: `design.md` IC-15 表頭 / `summary`: 表頭通則寫死「拆成 launcher 與 installer 兩個測試函式」，但第 5 列實際需要三個函式（launcher、installer direct、installer `--vendor`），字面與該列不合

## Rating

- post-filter cumulative blocking set Critical count：0
- post-filter cumulative blocking set Warning count：1
- 非 blocking triaged finding count：7
- `critical_gap`: false
- `round_type`: micro

rationale：Q1 與 Q2 皆判 `resolved` 並離開集合，第 4 輪的機制移除經逐項檢查沒有留下懸空條款或編號錯亂。本輪唯一的 blocking 是一個測試建構的事實錯誤：以 symlink 建構的 fixture 會在 mode 比對就短路，根本走不到它要驗的出口，因此是假 red。該筆與其餘七筆非 blocking 的修法都很局部，全部已在本輪修完。決定 `next_round`，由第 6 輪做最終驗證。

## Fix Actions

修改檔案：`openspec/changes/tolerate-remount-device-renumbering/proposal.md`、`design.md`、`specs/cash-cli/spec.md`、`tasks.md`（共 4 個檔案，全部位於 change 目錄內）。

blocking finding 的處置：

1. **假 red 的 symlink 建構**（Warning／85）：IC-15 第 9 列的建構改為「對一筆 runtime path 建立 hard link（使其 `st_nlink` 為 2 而 mode 仍為 `0644`）」，並在該列明寫「MUST NOT 以 plain symlink 建構」及其理由（symlink 的 `lstat` mode 為 `0755`，會在 `sha256_file` 之前短路成既有的 `runtime record drift`，該路徑今日即以 `receipt_invalid` 結束因而不構成 red）。spec delta 對應 scenario 的 GIVEN 同步改為 hard link 並說明「其 mode 仍為 `0644` 因而通過 mode 比對後才在開檔階段失敗」。已在本機以 `os.lstat` 實測驗證 symlink 為 mode `0755`／`st_nlink` 1、hard link 為 mode `0644`／`st_nlink` 2，確認新建構會落在預期出口。

非 blocking triaged findings 的處置，七筆全部修正：

2. guidance 規範層只有兩件事（72）：spec delta 的 guidance 段補上第三件事（`.cash-skills/receipt.tsv` 被納入版控時 MUST 先解除追蹤再重新簽發）與 fresh-clone 禁止；`#### Scenario: Init 指引隨 guidance 部署到達 target` 補一條對應 AND。
3. proposal 第四節的殘留句（70）：改為與 IC-12／task 4.1 一致的三件事，並移除 identity 自我說明式的前提描述。
4. identity hint 的設定時機未規定（68）：IC-5 補「identity hint MUST 只在最終確定回報 identity drift 時才設定，MUST NOT 在延後判定開始時預先設定」並寫出 `FAILURE_HINT` 為 module-global 的理由；spec delta 前提段同步；`#### Scenario: 延後判定期間命中既有出口時以該出口回報` 補一條 AND「診斷不包含 `--init-receipt`」；task 2.1 同步。
5. installer 訊息 literal 無規範背書（62）：IC-6 補第四句「兩個 gate 的 identity hint 文字 MUST 各自包含 `tracked by version control` 與 `machine-local` 兩個子字串，使該限定可被機械斷言而不受同義措辭影響」。
6. IC-14 內容不足（60）：IC-14 補上三項——`CASH-SKILLS.md` 說明版控保護的鑑別力由 `st_ino` 承擔，`CASH-INIT-RECEIPT.md` 說明前提不成立時的下一步與版控前提；task 4.2 的措辭同步為 `st_ino`。
7. 兩條 MUST 在同一出口重疊（58）：spec delta 與 IC-4 的該句限定為「前一句所述 record 漂移出口以外的既有 fail-closed 出口」，並舉例（generation 不符、path 形狀不合法）；同時明寫「沿用既有出口的唯一例外是 error code」，使 error code 改寫與沿用出口兩件事不再看似矛盾。
8. IC-15 表頭的拆分通則字面過窄（50）：改為「MUST 至少拆成 launcher 與 installer 兩個測試函式……同一 gate 的多條路徑（例如 installer 的 direct 與 `--vendor`）各自可再拆為獨立函式」。

fix 傳播：guidance 三件事這個概念已在 IC-12、IC-13、spec delta 的 guidance 段與其 scenario、proposal 第四節、tasks 4.1／4.4 全部同步；hint 設定時機已在 IC-5、spec delta 前提段、延後出口 scenario 與 task 2.1 同步；hard link 建構已在 IC-15 第 9 列與 spec delta 對應 scenario 同步。

post-fix mechanical self-check：spec delta 的 `<!--`／`-->` 計數皆為 0 且無殘留 `@trace`；13 個 scenario 與 IC-15 對照表逐字 1:1 且同順序；三個 MODIFIED requirement 的 title 逐 byte 存在於 master spec；IC-1 至 IC-15 全部有定義且被引用、無跳號；`fresh clone` 在四份 artifact 的全部出現處仍都在禁止或說明脈絡；spec delta 中僅存的 `symlink` 出現處皆位於自 master spec 逐字帶入的 MODIFIED requirement 內文，本 change 新增的 scenario 已無 symlink 建構。無 signal 具有 `check` frontmatter 欄位，故 signal-derived check 無可執行項。

fix 後已重新執行 `validate`，結果為 Validation passed。本輪 Fix Actions 修改的檔案全部位於 `openspec/changes/` 之下，依 touched 記錄規則濾除後為空，因此未呼叫 Cash CLI 的 touched 指令，亦無警告。

## Decision

next_round

唯一的 blocking finding 已修正，需由下一輪 reviewer 給出明確的 resolved 判定才能離開 cumulative blocking set。下一輪為本 run 的第 6 輪，依位置推導為 `micro`，同時也是本 run 的最後一輪。
