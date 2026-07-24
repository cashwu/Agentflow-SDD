## Context

`.cash-skills/receipt.tsv` 是 installer 寫入每個 target 的安裝憑證。它的 stable records 除了 path、digest 與 mode 之外，還記錄 target 上 launcher 與 workspace lock 的 `st_dev` 與 `st_ino`。launcher 在 import 任何 managed library 前會以 `fstat` 比對這些 identity，藉此偵測 stable bootstrap 是否被抽換。

這使 receipt 成為 machine-local artifact：同一份 bytes 在不同 inode 上即失效。實測把已部署 target 的 `.cash-skills` 整份複製到新路徑後，launcher 回報 `receipt_invalid` 與 `stable record drift`，該 target 的所有 command 無法執行。

現行 installer 不會確保 target 排除 receipt 進入版控，也沒有偵測既有 target 是否已把它納入版控。既有 target 普遍已將 receipt 納入版控，因為舊 schema 只有版本與 digest、不含 machine-specific 欄位，當時納入版控是正確做法。

## Goals / Non-Goals

- Goal：installer 的 direct、registry 與 batch 模式確保 target 根目錄 `.gitignore` 含所需排除規則。
- Goal：保留 project-owned 內容，只補齊缺少的規則。
- Goal：既有 target 若已把 receipt 納入版控，以 diagnostic 回報。
- Non-Goal：不修改 stable launcher。installed target 的失效診斷改善需先建立 stable bootstrap migration 契約，屬獨立變更。
- Non-Goal：不涵蓋 source-only `--self`。既有契約要求它只寫 receipt 且 current 時零寫入，且 source bootstrap 無 transaction。
- Non-Goal：不代為修改使用者版控索引，不改變 receipt 的 identity 設計，不改變既有結果分類語意。

## Decisions

### 以逐行補齊取代 marker managed block

`.gitignore` 是 project-owned 檔案，經常由多個工具與使用者共同維護。marker 界定的 managed block 會引入 marker 損毀、巢狀與孤立等失敗模式，且使用者手動搬移規則位置就會產生 drift。

改採逐行補齊：只在缺少時附加所需規則，既有規則不論位置一律視為已滿足，不重排、不去重、不刪除任何既有行。這使 installer 對該檔案的寫入單調且收斂，重跑自然零寫入。

### 判定在 byte 層進行

`.gitignore` 的內容是 pathname bytes，可能含非 UTF-8 的檔名 pattern。若比照 receipt 走 UTF-8 decode，會使原本可安裝的 target 變成 `failed`，等同改變結果分類語意。

因此以 `b"\n"` 切行、逐行比對 bytes，不要求 UTF-8。比對時容忍行尾的 `\r`，使 CRLF 檔案中的既有規則能被正確辨識；附加時沿用檔案既有的行終止符。

判定為逐行精確比對，不做前綴、萬用字元或路徑包含關係推論。等價寫法（例如 `**/__pycache__/` 或前導斜線形式）不視為已滿足，會導致附加一條語意重複但無害的規則；此取捨換得判定可預測，且避免把語意不同的既有規則誤判為已涵蓋。

### 附加前確保行分隔

既有 `.gitignore` 最後一行可能沒有換行。此時直接附加會與使用者最後一條規則黏連，同時毀掉原規則且未真正建立所需規則，而 installer 仍會回報成功。

因此既有內容不以行終止符結尾時，MUST 先補一個行終止符再附加。這是「既有內容逐 byte 保留」的唯一例外，且與既有 guidance render 的處理慣例一致。

### 納入既有 snapshot revalidation

附加在本 codebase 只能以 full-file atomic replace 實作。既有機制以兩件事保護 project-owned 檔案：該路徑列在 installation inputs 中、post-lock 與 publication 前重新驗證後重新規劃，以及 atomic write 的 expected 比對。

`.gitignore` 若不納入該集合，rendered 內容會在 lock 前計算，期間外部工具對該檔的修改會被整段覆寫。因此判定與寫入內容由同一份 no-follow snapshot 導出，且納入既有 revalidation。兩個檢查點的處置不同且沿用既有慣例：post-lock 不一致時重新分類並重跑，publication 前不一致時 fail closed——在持有 exclusive lock 期間對外部寫入者反覆重新分類會有無限重試風險，且既有 guidance 契約亦要求該檢查點 fail closed。兩者皆不覆寫外部修改。

### 排除規則涵蓋三項

需要排除的是 machine-local 或執行期產生的內容：receipt、per-target state 目錄，以及 CLI 執行時在 managed library 旁產生的 Python bytecode 目錄。

bytecode 規則採用慣用的 repo 全域形式 `__pycache__/` 而非限定於 `.cash-skills/lib/`，理由是逐行精確比對之下，已有該慣用寫法的專案會被正確判定為已滿足，不會被附加重複規則。`.cash-workspace.lock` 不納入排除：它必須存在於 target 才能讓 installer 辨識既有 bootstrap prefix。

### 已納入版控的 receipt 只回報不修改

installer 可觀察 target 的 receipt 是否已被納入版控，但修改使用者的版控索引屬破壞性且超出安裝範圍。因此只以 diagnostic 回報並指出建議動作。

偵測 MUST 使用唯讀 index 查詢而非 ignore 查詢：本 change 之後所有 target 的 `.gitignore` 都會命中該規則，ignore 查詢會對確實已追蹤的 target 給出相反答案（gitignore 對已追蹤檔案無效）。查詢失敗時靜默略過 diagnostic，不影響結果分類或 exit code。

## Implementation Contract

### Behavior

- installer 的 direct、registry 與 batch 模式，在 preflight 通過後、於同一 transaction 內確保 target 根目錄 `.gitignore` 含 `.cash-skills/receipt.tsv`、`.cash-skills/state/` 與 `__pycache__/`。
- 判定在 byte 層以行為單位精確比對，容忍行尾 `\r`；缺少者附加至檔案尾端並沿用既有行終止符（不含任何行終止符時使用 `\n`），既有內容逐 byte 保留。既有內容非空且未以行終止符結尾時先補一個行終止符；既有內容為空時不補。
- `.gitignore` 不存在時以 `0644` 建立。既有檔案 mode 保留。
- 既有檔案為 symlink、非 regular file、hard link 或不可安全讀取時，在首次 target write 前以 execution error 失敗，`--force` 不繞過。
- `.gitignore` 納入 installation inputs 與 post-lock／publication 前的 revalidation；判定與寫入內容由同一份 snapshot 導出。post-lock 不一致時重新分類，publication 前不一致時以 execution error fail closed，兩者皆不覆寫外部修改。
- 三項規則皆已存在時該項目零寫入；其餘 managed inventory 亦無變更時 target 回報 `current`。
- `--dry-run` 執行相同判定與驗證並零寫入。transaction 失敗時新建或附加的 `.gitignore` 依既有 rollback 契約還原。
- 以唯讀 index 查詢偵測 receipt 是否已被納入版控；為真時輸出 diagnostic 至 stderr 指出狀態與建議動作。查詢失敗靜默略過。diagnostic 不改變結果分類或 exit code，也不修改版控索引。

### Command interfaces and data shapes

| 面向 | 形狀 |
| --- | --- |
| 目標檔案 | target 根目錄的 `.gitignore` |
| 規則 | 三行精確 bytes：`.cash-skills/receipt.tsv`、`.cash-skills/state/`、`__pycache__/` |
| 判定 | 以 `b"\n"` 切行、逐行 bytes 精確比對，容忍行尾 `\r`；不做前綴或萬用字元推論 |
| 寫入 | 只附加缺少的行至尾端；既有 bytes 與 mode 保留；缺行終止符時先補一個；新建為 `0644` |
| revalidation | `.gitignore` 納入 installation inputs；判定與寫入由同一 snapshot 導出並於 post-lock 與 publication 前重驗 |
| 版控狀態偵測 | 唯讀 index 查詢；輸出至 stderr，每個 target 一行 |

### Error contract

- 不安全的 `.gitignore` 在首次 target write 前以 execution error 失敗，`--force` 不繞過。
- snapshot 於 post-lock revalidation 不一致時重新分類；於 publication 前不一致時以 execution error fail closed。兩者皆不覆寫外部修改。
- 版控狀態查詢失敗時靜默略過 diagnostic，不改變結果分類或 exit code。
- transaction 失敗時 `.gitignore` 依既有 rollback 契約還原。

### Acceptance criteria

- 全新 target 安裝後 `.gitignore` 含三項規則且以 `0644` 建立，receipt 不被版控收錄。
- 既有 `.gitignore` 含自訂內容時，安裝後既有內容逐 byte 不變，只在尾端多出缺少的規則。
- 既有 `.gitignore` 無尾端換行時，附加後使用者最後一條規則完整保留且新規則自成一行；空檔案不產生開頭空行。
- 三項規則齊備的 target 重跑安裝回報 `current` 且該檔案零寫入。
- 既有 `.gitignore` 為 symlink、非 regular file 或 hard link 時，安裝在首次 target write 前失敗且零寫入，`--force` 亦然。
- CRLF 與非 UTF-8 的 `.gitignore` 可正確判定且不使 target 變成 `failed`。
- receipt 已被納入版控的 target 於安裝時輸出 stderr diagnostic，版控索引未被修改，結果分類未改變。

### Scope boundaries

- 涵蓋 installer 的 direct、registry、batch 模式與對應 contract tests。
- 不涵蓋 stable launcher、`--self`、既有 target 的版控清理與 receipt schema 變更。

## Risks / Trade-offs

- [Risk] 逐行精確比對無法辨識等價寫法，可能附加語意重複的規則 → 以三條固定 bytes 為準，於 spec Example 明示等價寫法不視為已滿足，並在文件說明判定規則。
- [Risk] 附加行為改動 project-owned 檔案，可能與使用者的排序或分組習慣衝突 → 只附加至尾端且永不重排或刪除，使影響可預期且可由使用者自行搬移。
- [Risk] 新增 transaction operation 會位移既有失敗注入測試的硬編索引，使 rollback 測試不再落在原本階段而仍通過 → 於實作時重新校準該索引或改以 operation path 注入，並固定排除設定在 operation 序列中的位置。
- [Risk] 既有 target 的 receipt 仍在版控中，diagnostic 可能被忽略 → 文件說明一次性清理步驟，並讓 diagnostic 於每次安裝重複出現。
- [Trade-off] 不自動取消追蹤留下手動步驟，但避免 installer 觸碰使用者版控索引，符合既有不猜測 ownership 的原則。
