## Context

目前 `install-cash-skills.fish` 只處理單一既有專案，將 24 個 canonical `SKILL.md` 做完整 preflight 後複製；來源一旦更新，使用者必須自行記住所有目標並逐一重跑。舊 Spectra Plus 的 registry 與 LaunchAgent 已移除，因此新流程必須只恢復「使用者維護的專案清單」與「明確執行的批次更新」，不能重新引入週期性 repair。

這項變更跨越來源版本、目標安裝狀態、使用者 registry 與批次錯誤彙整，且所有 mutation 都涉及 caller-controlled filesystem paths。實作不得依賴網路、Git working-tree 狀態或新增外部套件。

## Goals / Non-Goals

**Goals:**

- 以一個嚴格且可做任意長度整數比較的 `MAJOR.MINOR.PATCH` bundle 版本代表兩個 variant 共 24 個 cash skill files。
- 讓 installer 能區分首次安裝、安全升級、相同版本、較新目標、目標漂移與執行錯誤。
- 保存足以辨識目標端修改的 receipt，預設不覆寫修改，只有明確 `--force` 才可覆寫。
- 讓使用者維護一份全域專案清單，並用單一明確命令依序更新所有登錄專案。
- 讓 dry-run 使用與真實執行相同的來源、registry、receipt、版本與邊界驗證。
- 在成功安裝 cash bundle 時移除 `.agents`／`.claude` 下可辨識的 `spectra-propose-plus` 與 `spectra-apply-plus` retired outputs，且不觸及其他 Spectra skills 或 legacy 目錄中的未知內容。
- 以 isolated `HOME` 與 isolated targets 覆蓋所有具名分支。

**Non-Goals:**

- 不建立 LaunchAgent、cron、daemon、background process 或定期執行機制。
- 不自動搜尋或自動登錄專案，不從舊 Spectra Plus registry 匯入。
- 不提供 per-skill 版本、遠端下載、Git pull 或跨機同步。
- 不允許降版；`--force` 只處理目標漂移，不覆蓋版本較新的 bundle。
- 不修改 Spectra-managed skills，也不把 registry 當作自動 repair 來源。

## Decisions

### 使用單一來源版本與目標 receipt

新增 `cash-skills.version`，內容只能是一行不含 prerelease/build suffix 的 `MAJOR.MINOR.PATCH`，每段符合 `0|[1-9][0-9]*`，因此禁止 leading zero。版本比較不得轉成 Fish `math`、浮點數或固定寬度整數；先比較 component 字串長度，再做 lexicographic compare，讓任意長度合法 component 都有正確順序。初始版本為 `1.0.0`；之後任何會改變 24 個 canonical skill files 安裝輸出的變更，都必須同時提升此版本。單一 bundle version 比 24 個獨立版本容易理解，也符合這些 files 必須成套保持 variant parity 的既有契約。

repository regression suite 另外治理「內容變更必須 bump」。若目前 version 與 `HEAD` 不同，`HEAD` 是 baseline：目前版本不得較低，且 24-file installed bytes 與 `HEAD` 不同時版本必須嚴格較高。若目前 version 與 `HEAD` 相同，suite 沿 first-parent history 找到這個 version 連續區段的 introduction commit（該 commit 為此 version 的第一個 commit，其 parent 為不同 version 或沒有 version file），並要求目前 24-file installed bytes 與 introduction commit 完全相同；因此任何後續未 bump 的 source change 即使再經過 unrelated commits 仍會 fail。bootstrap history 尚無版本檔時只驗證目前 strict format。runtime installer 不讀 Git，Git 只用於 repository regression governance。

每個成功安裝或接管的目標保存 `.cash-skills/receipt.tsv`。第一列固定為 `version<TAB><version>`，後續 24 列依 canonical inventory 順序保存 `sha256<TAB><lowercase-hex-digest><TAB><project-relative-path>`。receipt 的列數、順序、欄位、路徑集合、digest 與版本格式都必須完整驗證；不接受未知路徑或部分 receipt。receipt 在全部 skill writes 成功後才以同目錄 temporary file 加 atomic rename 發布，因此不會把部分完成的安裝宣告為完整版本。

替代方案是只保存版本，不存 hashes；這無法分辨安全升級與使用者修改。另一方案是保存完整舊 files；它增加不必要的空間與清理負擔，hashes 已足以做 drift detection。

### 版本優先序與首次接管

installer 的單一專案模式保留 `--target <project> [--dry-run] [--force]` 介面，並依下列優先序決策：

1. 先驗證來源 inventory、來源版本、目標、receipt schema、所有 destination boundaries 與必要 read/write 條件；dry-run 不得提早略過。
2. 有合法 receipt 且目標版本高於來源時，回報 `newer` 且不寫入；即使有 `--force` 也不降版。
3. 有合法 receipt 且版本相同時，先將目前 source hashes 與 receipt hashes 比較。source 不符合 receipt 代表同一版本對應不同 bundle，必須回報 execution `failed`，且 `--force` 不得繞過；source 符合 receipt 後，目標符合 receipt 則回報 `current`，目標漂移才是 `conflict`，只有 `--force` 可修復並重寫 receipt。
4. 有合法 receipt 且來源版本較新時，先用 receipt hashes 判斷目標是否漂移。無漂移可直接升級；有漂移則為 `conflict`，只有 `--force` 可升級。
5. 沒有 receipt 時，24 個 destinations 全不存在則首次安裝；全部與目前來源相同則只建立 receipt 完成接管；任何 mixed 或 differing 狀態預設為 `conflict`，`--force` 可安裝／替換明確 inventory 後建立 receipt。

格式錯誤、讀取失敗、缺少 receipt 所宣告的 file、hash command 失敗或邊界錯誤是 `failed`，不得折疊成 `conflict`、`current` 或 `newer`。所有 conflict 與 failed preflight 都在第一次 target write 前結束。這個優先序讓版本較新的目標受到不降版保護，也讓舊式無 receipt 安裝有明確且可預覽的 migration path。

### 以單一 installer 入口承載直接安裝與批次更新

installer 對完成的 domain decision 輸出且只輸出一列 `Result: update`、`Result: current`、`Result: newer` 或 `Result: conflict`。正常執行與 dry-run 共用相同 decision；`update` 在正常模式表示已完成，在 dry-run 表示 would update。exit code `0` 僅用於 `update`、`current`、`newer`，exit code `2` 專供 `conflict`，其他 validation 或 execution error 使用 exit code `1` 且不得偽造 domain result。

`install-cash-skills.fish` 解析 exactly one mode：`--target` 直接執行既有單一專案流程；`--register`、`--unregister`、`--list` 與 `--all` 執行 registry-backed 流程。`--all` 逐一以同一支 `install-cash-skills.fish --target` 重新進入既有單一專案流程，不保留第二支 script，也不複製版本、receipt 或 drift 邏輯；parent invocation 以穩定結果列與 exit code 的組合分類每個專案，矛盾或缺少結果列一律分類為 `failed`。

替代方案是保留 `update-cash-skills.fish` 作為 wrapper；這仍讓使用者必須記住兩個入口，且沒有提供相容性價值，因此移除。另一方案是在 batch mode 重寫同一套 preflight；這會產生兩份安全判斷與長期 drift。

### 使用者 registry 是手動維護的資料，不是排程

registry 固定為 `$HOME/.config/cash-skills/projects.txt`，每列一個 canonical absolute project path；空白列忽略，不支援 commands 或 inline metadata。installer 提供五個互斥模式：

- `--target <project> [--dry-run] [--force]`
- `--register <project>`
- `--unregister <project>`
- `--list`
- `--all [--dry-run] [--force]`

`--dry-run` 與 `--force` 只可搭配 `--target` 或 `--all`。register 要求 existing non-symlink directory，拒絕含 ASCII control characters（包含 tab、CR、LF）的 input，canonicalize 後去重並用 same-directory temporary file + atomic rename 更新 registry。unregister 對既有路徑使用 canonical path；已不存在的 stale target 只接受 registry 中原樣存在、不含 `.`／`..` segments 且不含 ASCII control characters 的 absolute path，以便安全移除。所有四種 registry-backed modes 在使用 existing registry 前都完整驗證 read result，以及以 LF 分隔後每個 record 的 schema、boundary 與仍存在的 control characters，再於記憶體 deduplicate；任何 read error、unsafe `HOME`、symlinked config boundary 或 malformed record 都 fail closed，register/unregister 也不得重寫損壞內容。LF 是格式 delimiter，existing file 中的 LF 不可能再被辨識為 path data；能直接編輯 registry 的使用者本來就具有逐列登錄 target 的同等 authority，安全保證只要求 mutation input 的 LF 不得注入額外 record。

registry 或其 config directory 尚不存在時是明確 empty state：register 可在驗證所有 existing HOME boundaries 後建立 `$HOME/.config/cash-skills` 與 registry；unregister、list、all 都成功處理空清單且不得建立任何 state，其中 all 輸出全零 summary。all 不會自動刪除 missing/failed entries，也不修改 registry。

批次執行逐一處理 deduplicated targets，輸出 `updated`（dry-run 為 `would-update`）、`current`、`newer`、`conflict` 或 `failed` 與 canonical path，最後輸出各狀態 count。單一 target 的 conflict 或 failed 不阻止後續 targets，但只要任一 target 未完成，整體 exit code 非零。這是明確的跨專案非原子行為；每個 target 仍遵守 installer 的 write-before-preflight 禁止規則。

### 所有可寫路徑共用 fail-closed 邊界模型

installer 除既有 24 個 destinations 外，將 `.cash-skills/receipt.tsv` 及 temporary sibling 納入 managed boundary preflight。它拒絕空值、無法解析、`/`、source repository 本身、symlink target、symlinked managed parents/destinations，以及任何解析後不在 canonical target 下的路徑。

installer 的 registry-backed modes 對 `HOME`、`.config`、`cash-skills`、registry 與 temporary sibling 套用同樣原則：`HOME` 必須為 non-empty absolute non-root existing directory，任何 existing boundary 不得為 symlink，所有解析結果必須留在 canonical `HOME` 內。script 使用 no-config Fish shebang 與 command-qualified filesystem/hash tools，避免使用者 startup functions 改寫安全判斷。

替代方案是信任 registry 內容；但它是持久且可被手動編輯的輸入，必須在每次 list/all 前重新驗證。

### 成功安裝會清除可辨識的 retired plus skills

target 模式另外盤點四個精確 legacy 目錄：`.agents/skills/spectra-propose-plus`、`.agents/skills/spectra-apply-plus`、`.claude/skills/spectra-propose-plus`、`.claude/skills/spectra-apply-plus`。不存在時 no-op；存在時只接受 non-symlink directory，內容必須只有一個 non-symlink regular `SKILL.md`。該檔必須以 `---` 開啟且具有 closing `---`，opening block 內只能有一個 `name` field，值必須精確等於對應的 `spectra-*-plus`；缺 closing delimiter、duplicate/conflicting name 或其他 malformed frontmatter 都不是可刪除的 legacy identity。任何其他 shape、額外 entry、name mismatch、read error 或 symlink boundary 都是 execution failure，並在 cash file、receipt 或 legacy removal 的第一次 target mutation 前結束。

有待清除的合法 plus 目錄時，原本 equal/current 的 target 改為 `update`，dry-run 列出 removal plan 但不刪除。正常執行在 cash files 與 receipt 驗證／發布後，先在 candidate parent 產生並驗證 unique same-filesystem quarantine pathname，再以 macOS/BSD `mv -h` 將整個 candidate directory atomic rename 至該 path；`-h` 明確禁止 destination 在 rename 前被換成 directory symlink 時跟隨該 symlink，因此 candidate 不會被搬出 target。installer 必須對 quarantine 內的 directory、唯一 `SKILL.md` 與完整 frontmatter identity 再驗證一次，只有仍符合 exact legacy shape 才以 `rm` 單一 `SKILL.md` 再 `rmdir` 空 quarantine。若 source candidate 在 preflight 後被替換或加入未知內容，installer 不得刪除 quarantine 內的內容，並在原 path 尚未被重新占用時以同樣的 no-follow rename 嘗試 atomic restore；restore 不安全或失敗時保留 quarantine path 並明確報錯，永遠不使用 recursive deletion。older、first install、adoption 與 force update 都套用相同 cleanup。newer 與 conflict 分支仍維持零寫入，因此不會只為清除 plus 而繞過版本或 drift 優先序。`--all` 透過同一 target 流程自然繼承此行為。

替代方案是對四個目錄直接 `rm -rf`；這會在舊路徑被重新利用或含使用者額外內容時造成不可逆資料刪除，因此拒絕。另一方案是繼續要求使用者另外執行 cleanup；這正是本次要消除的遷移負擔。

## Implementation Contract

### 可觀察行為與介面

- `cash-skills.version` 是唯一 source bundle version，格式嚴格為三段無 leading zero 的非負整數 SemVer，並以 component length + lexicographic ordering 比較。
- `install-cash-skills.fish` 是唯一 CLI，接受 exactly one of `--target <project>`、`--register <project>`、`--unregister <project>`、`--list` 或 `--all`；`--dry-run` 與 `--force` 只可搭配 `--target` 或 `--all`。
- `--target` 管理 24 個 skill files、一份 `.cash-skills/receipt.tsv` 與四個 exact retired plus skill 目錄，並依「版本優先序與首次接管」決定 update/current/newer/conflict；`--all` 對 registry 中每個 target 重用相同流程。
- `--force` 可以覆寫 explicit managed inventory 的 drift，但不得降版、刪除四個 exact retired plus 目錄以外的 inventory 外 files，或放寬任何 validation。
- `--dry-run` 完成與真實執行相同的 read-only preflight 與結果分類，不建立目錄、temporary file、receipt 或 registry，也不修改 24 個 skill files 或移除 retired plus skills。
- 沒有任何命令會建立或載入 LaunchAgent、排程未來執行、fork background process，或在來源變更時自動傳播。

### 失敗模式

- installer exit `2` 僅代表已完整辨識的 managed-content conflict；exit `1` 代表 argument、schema、I/O、hash、boundary 或 execution failure；兩者都不得在 preflight 期間留下 target writes。
- installer 的 `--all` 必須區分 conflict 與 failed，繼續處理其餘 targets，最後以非零 exit 回報 aggregate incomplete。
- malformed receipt、malformed existing registry、同版本 source/receipt hash mismatch、無法讀取的輸入與 unexpected child result 都 fail closed，不能當作 missing/current/newer/conflict，且 `--force` 不得繞過。
- retired plus candidate 若不是 exact legacy shape、包含額外 entry、frontmatter boundary/name 不完整或不唯一、不可讀寫或位於 symlink boundary，installer 必須在任何 target mutation 前 exit `1`；實際 destructive phase 必須先 atomic quarantine 並重驗 identity，不得沿原始 caller-controlled candidate path 刪除、遞迴刪除或把不明內容視為 legacy skill。
- registry mutation 使用 atomic replace；更新中斷時保留更新前或更新後的完整清單，不留下被當作正式 registry 的 partial content。
- skill writes 若在已通過 preflight 後中途發生 runtime error，installer 非零退出且不得發布新 receipt；有 prior receipt 時，下一次執行會透過 receipt hash mismatch 顯示 conflict，除非使用者明確 `--force`；首次安裝沒有 prior receipt 且至少一個 managed write 已持久化時，下一次依 mixed/incomplete receipt-less target 規則顯示 conflict；若錯誤發生於第一次持久寫入前，下一次仍是正常 clean install。

### 驗收條件

- regression suite 以 isolated `HOME`、source copy 與 target fixtures 驗證 leading-zero rejection、任意長度三段 ordering、version-introduction history governance、合法 receipt、receipt schema corruption、same-version source integrity failure、missing receipt migration、clean upgrade、same version、newer target、drift conflict、force、no downgrade、dry-run parity、recognized plus cleanup、current-with-plus update、missing/SKILL-symlink/dangling-candidate-symlink/malformed-frontmatter/extra/candidate-symlink plus candidate 零寫入、preflight 後 source candidate swap 的 quarantine revalidation、quarantine destination symlink no-follow、managed destination parent 權限 parity、prior-receipt partial write、first-install persisted partial write、first-install zero-write retry、symlink/containment rejection與 hash/read/child execution error。
- registry fixtures 驗證 absent config/registry 的四種模式、register dedupe、unregister existing/stale、list、所有 mutation modes 的 malformed/unreadable input 零寫入、mutation input LF/control-character rejection、persisted record control-character rejection、unsafe HOME、symlink boundary、atomic mutation、missing target、duplicate target，以及 all 的 updated/current/newer/conflict/failed counts與 fail-and-continue。
- 測試必須證明 hostile Fish startup overrides 無法改寫關鍵 commands，且 isolated 執行不接觸真實 registry、外部專案或排程服務。
- 文件列出完整命令、版本提升責任、receipt/registry 位置、migration、retired plus cleanup、安全拒絕條件、status/exit semantics、`--force` 風險與無背景排程保證。
- `fish scripts/cash-skills/tests/skill-checks.fish` 與 `spectra validate add-versioned-cash-skill-batch-update` 都通過。

### 範圍邊界

實作只建立 proposal 所列一個新 repository file，並修改所列三個既有 files；`update-cash-skills.fish` 不屬於交付內容。runtime 生成的 registry 與 receipt 只存在於使用者 `HOME` 或明確 target 內。不得修改 repository source 中任何 `spectra-*` skill、舊 cleanup 行為、signals、LaunchAgent 或真實 repository 外專案內容；runtime installer 只可在使用者明確指定或登錄的 target 內移除四個 exact retired plus skill 目錄，測試則只使用 isolated temporary fixtures。

## Risks / Trade-offs

- [Risk] 使用者忘記提升 bundle version，會讓內容變更不被既有 targets 視為新版本 → repository regression suite 對 version 不同的 working state 比較 `HEAD`，對 version 相同的狀態回溯該 version 的 introduction commit；內容改變而未提升版本時即使隔著 unrelated commits 仍會 fail，runtime 另拒絕 equal-version source/receipt mismatch。
- [Risk] 目標在 preflight 後、copy 完成前被外部程序修改 → receipt 最後發布；任何中途錯誤或後續修改都會在下一次比對形成 drift，不宣告錯誤版本完成。
- [Risk] `--force` 可能覆寫使用者有意修改 → 預設永遠 conflict，文件與輸出明確警示，且 force 只能觸及 24 個 files 與 receipt。
- [Risk] registry 內一個壞路徑造成部分成功 → 批次行為明確為 fail-and-continue 並回傳 aggregate non-zero；逐 target diagnostics 與 summary 保留可重試資訊。
- [Risk] simple TSV 不能表達任意 metadata → schema 故意固定且完整驗證；目前只需要版本、hash 與 canonical inventory，避免引入 JSON parser。
- [Trade-off] 不支援降版，rollback 必須以修正內容搭配更高 bundle version 發布；這避免舊 source 意外覆蓋較新安裝。
