## Context

Cash 的 24 個 repo-local skill、launcher、workspace lock 與 Python runtime 已可由 installer 發佈，但啟動 gate 只有 machine-local receipt。receipt 的 stable records 綁定 target 的 `st_dev`／`st_ino` 且被 `.gitignore` 排除，因此它適合直接安裝與 registry 更新，卻不能隨 Git clone 攜帶。現行 target guidance 只能要求每位團隊成員在 clone 後主動執行一次 `--init-receipt`。

這項變更新增 repo-vendored 信任模式，不取代 receipt。Git commit／review history 成為 portable manifest 的 provenance；launcher 負責確認 checkout 中受管 executable inventory 與該 manifest 一致。具有寫入整個 working tree 權限的程序仍可同時改寫 manifest 與 inventory，portable mode 不宣稱抵抗此類攻擊。

目前 `.cash-skills/bin/cash` 與 `.cash-workspace.lock` 都被 history gate 視為永久 immutable stable objects。portable gate 必須改動 launcher，因此本變更同時需要一個狹窄、可列舉且可復原的 bootstrap migration；workspace lock 仍永久保留 identity。

## Goals / Non-Goals

### Goals

- 維護者可執行一次 `--vendor <project>` 並提交結果，團隊成員 clone／pull 後不需安裝或初始化即可使用 Cash。
- receipt-based direct、self、registry 與 batch target 保持既有 identity、schema、record inventory 與 fail-closed 行為。
- fresh clone 在常見 umask `022` 與 `002` 下都能唯讀通過 portable gate。
- manifest、launcher migration 與 bundle version 由 deterministic contract tests 綁定。
- vendored 更新與 receipt-to-vendored 轉換使用既有 stable lock 與 journal，失敗可由下一次 installer 恢復。

### Non-Goals

- 不提供使用者全域 plugin、組織 policy、背景更新或遠端下載。
- 不讓 launcher 在首次執行建立 receipt、修正 mode 或修改 working tree。
- 不改變 receipt schema，也不把 portable manifest 加入 receipt record inventory。
- 不把 portable manifest 當成簽章；repository write authority 與 Git provenance 仍是信任根。
- 不允許 direct／registry／batch mode 靜默把 vendored target 轉回 receipt mode。

## Decisions

### 1. 兩種信任模式使用 manifest-presence 優先序

launcher 先以 no-follow `lstat` metadata 判斷 `.cash-skills/manifest.tsv` 是否存在，再開啟 launcher 與 `.cash-workspace.lock`、取得既有 shared／exclusive flock，最後執行對應 gate：

1. manifest path 存在（包含 unsafe shape）時只走 portable gate；驗證失敗回報 `manifest_invalid`，MUST NOT fallback。
2. manifest path 缺失且 receipt path 存在時只走既有 receipt gate；驗證失敗回報既有 `receipt_invalid`／bootstrap 錯誤。
3. 兩者皆缺失時回報 `bootstrap_invalid`。

manifest是被提交的 trust-mode marker；這個優先序讓既有成員 pull 到 vendored commit後，即使 working tree仍留有 ignored的舊 receipt，也能不寫入地切換到portable gate。receipt-only target沒有manifest，因此既有receipt drift仍fail closed。manifest present但invalid時不得以receipt恢復，避免半完成或被竄改的vendored狀態被另一個gate掩蓋。source同時存在manifest與舊receipt時也走portable gate。

manifest presence MUST在任何open前以no-follow `lstat`判定；broken symlink、FIFO、directory、hard link、不可讀或其他unsafe-present shape都屬 `manifest_invalid`，不得當成missing，也不得阻塞在open。這個優先序是既有 `Project-local Cash CLI runtime`、`Cash workflow command surface`、`Bundle 安裝與 runtime receipt` 與 `Target-local receipt 初始化` 中「receipt缺失即失敗」、「help必須receipt-validated」及「只載入receipt-validated generation」規則在manifest-present情境下的唯一優先例外；其他receipt-only情境不變。

### 2. portable manifest 記 Git 邏輯 mode，不記 filesystem identity

`.cash-skills/manifest.tsv` 使用 LF-terminated UTF-8 canonical TSV：

- `format<TAB>cash-portable-manifest-v1`
- `bundle_version<TAB><strict-MAJOR.MINOR.PATCH>`
- `runtime_generation<TAB><lowercase-sha256>`
- 後續每列為 `<kind><TAB><project-relative-path><TAB><lowercase-sha256><TAB><git-mode>`

`kind`、path 集合與順序沿用 receipt inventory：stable launcher、stable lock、依 UTF-8 bytes 排序的 runtime，最後是 canonical variant／skill 順序。`git-mode` 只能是 `100644` 或 `100755`；它表達 executable bit class，不要求 clone 後的完整 permission bits 精確等於 `0644`／`0755`。launcher 將 observed mode 正規化為 Git 邏輯 mode後比較，因此 umask `002` 產生的 `0664`／`0775` 仍合法。所有路徑仍須為 root-contained、non-symlink、single-link regular file，digest 必須一致。

manifest 不記錄自身，也不記 `st_dev`／`st_ino`。它的 format、row count、path set、order、mode class、runtime generation、duplicate／unknown record全部 fail closed。manifest 本身須為 non-executable regular single-link file；launcher 在 hashing 每個 inventory path 時比較 opened FD 與 pathname 的 device/inode，避免驗證另一個 inode。launcher另以 manifest中的 runtime records作為期望集合，列舉 `.cash-skills/lib/cash_cli/`直屬與遞迴的現地 `.py` paths後比較 missing／extra差集；expected set來自manifest，MUST NOT反過來由現地列舉結果產生。source serializer與history contract test負責把manifest runtime records綁定到 `source_inventory`。

portable gate在驗證runtime digest時 MUST保留每個record的exact source bytes供後續import使用。launcher在任何managed runtime import前 MUST設定 `sys.dont_write_bytecode = True`，且不得依賴caller提供 `-B`或 `PYTHONDONTWRITEBYTECODE`。它另 MUST提供 `VerifiedSourceLoader`：此loader可繼承 `SourceFileLoader`以符合 `FileFinder`介面，但 `get_code` MUST只對portable gate保留的verified bytes呼叫 `source_to_code`，MUST NOT呼叫會讀取bytecode cache的superclass `get_code`，也 MUST NOT寫入cache。launcher以 `FileFinder`搭配 `VerifiedSourceLoader`，在 `sys.path_importer_cache`為project-local library root及每個含manifest runtime record的 `cash_cli` package directory安裝finder；`cash_cli` package與submodules不得使用timestamp／hash-valid或sourceless `.pyc`。這個限制只套用project-local `cash_cli` namespace，不改變stdlib importer。portable read scenarios須預先放置header／timestamp／size皆可被一般import接受但payload不同的 `.pyc`，並以包含ignored files、directories與mtime的filesystem snapshot前後比較，驗證執行verified source且零寫入。

### 3. `--vendor` 是獨立且明示的發佈模式

installer parser 新增與既有 modes 互斥的 `--vendor <project>`，允許搭配 `--dry-run` 與 `--force`。target 必須是安全、既存、非 source 的 canonical Git worktree top-level。preflight對每個預計發佈或建立的受管inventory、config、guidance與manifest path逐一查詢Git：path已tracked即可；未tracked時必須不受repository `.gitignore`、`.git/info/exclude`或global excludes排除。blocked paths須在首次write前一次列出並fail closed，final publication前再以同一path集合重驗。它沿用現有 source inventory、target config、`openspec/config.yaml`、guidance、legacy ownership、`.gitignore` receipt／state／`__pycache__`保護、filesystem boundary、snapshot revalidation、stable lock 與 journal 契約。

fresh target 發佈 stable launcher／lock、runtime、skills、config／guidance，並以manifest作為最後一筆trust-bearing managed bundle publication，不建立 receipt。既有 vendored target 先以舊 manifest驗證 digest、Git logical mode與filesystem shape baseline；合法 umask造成的完整POSIX mode差異不得被分類為drift。managed digest或logical-mode drift未帶 `--force` 時為 conflict，`--force` 只可覆寫 replaceable managed content，不能繞過 unsafe shape、版本降級、manifest schema或 unapproved launcher drift。

receipt與manifest都缺失時，zero inventory是fresh；完整stable／runtime／skill inventory逐檔符合source digest與Git logical mode時可在exclusive lock下認養，保留既有bytes並最後新增manifest。partial、unknown或different inventory預設為conflict；`--force`只可補齊或替換canonical expected path上的missing／different replaceable runtime與skills，unknown extra runtime與unknown stable drift即使帶 `--force`仍fail closed。stable prefix只能是absent、safe empty lock、current launcher或allowlisted old launcher。

manifest absent的receipt-based target只有在receipt完整有效時才可由明示 `--vendor`轉換。轉換在同一transaction內更新inventory並以manifest publication完成trust-mode cutover；manifest是最後一筆trust-bearing managed bundle publication，唯一可排在它之後的operation是 `receipt_delete` machine-local cleanup。journal在manifest前失敗 MUST rollback到舊gate；manifest成功後即進入 `portable_cutover` phase，後續失敗 MUST保留新portable gate並roll forward完成cleanup，不得rollback已生效的manifest。manifest已存在時，任何safe regular single-link receipt都只是non-authoritative residue，可不解析內容直接transactionally刪除；unsafe receipt shape仍fail closed。相反方向不自動提供：`--target`、`--register`與`--all`遇到portable manifest時fail closed並引導使用 `--vendor`。

### 4. launcher migration 由 exact transition allowlist 與 journal 管理

`installer.py` 提供 `APPROVED_LAUNCHER_TRANSITIONS`，每筆schema固定為 `(old_digest, new_digest, introduced_version)`。`publish_launcher`只接受target launcher已等於source launcher，或target old digest與source new digest命中同一筆且source version大於等於 `introduced_version`；因此source launcher自引入後未再變更時，可由更高bundle version跨版升級。history gate MUST驗證new launcher bytes恰在 `introduced_version`首次出現，不能把後續version當成新的引入點；若source launcher又改變，必須新增命中新source digest的exact transition。其他drift一律失敗，`--force`不影響此判定。

launcher replacement使用journal schema v3的專用 `launcher` operation，而不是一般 `write`的bytes-only語意；新installer仍 MUST讀取與恢復既有schema v2 journal。專用operation記錄before bytes、mode及device/inode，並在target stable lock的exclusive FD下atomic replace。receipt-based migration另使用專用 `receipt` operation：desired receipt bytes不得在transaction planning時計算，而 MUST在它實際發布時從已切換的launcher／lock pathname重新 `fstat`產生，因此新receipt記錄新launcher inode。

若publication失敗，rollback可用atomic write還原old launcher bytes，即使這會得到另一個inode；rollback完成後 MUST從journal保存的old receipt bytes重建相同old version、generation、record digests與modes，只更新stable launcher／lock的現地device/inode，原子發布為rebound old receipt。rebound receipt通過完整receipt gate才算rollback完成；失敗時保留journal供下一次matching-or-newer installer重試。journal在operation實際write前先推進published計數的crash也走同一rebind流程，因此不依賴判斷舊inode是否曾被replace。vendored target rollback不需rebind receipt，因manifest不記inode。

fault contract涵蓋journal advance前後、launcher atomic replace前後、dynamic receipt publication前後、manifest publication前後及receipt cleanup前後；manifest前的recovery回復舊gate，manifest後 `portable_cutover` recovery保留新gate並只roll forward cleanup。每一點recovery後都 MUST以完整舊或新trust gate成功，而不只比較bytes。`.cash-workspace.lock` 永不unlink／rename，identity在整個migration保持不變。

這是既有 stable launcher 永不 replacement 契約的唯一例外。history test 必須拒絕未列入 exact transition、未調升 bundle version或改動 workspace lock的 commit；普通 runtime／skill 更新不得藉此更換 launcher。

### 5. source manifest 由單一 serializer 產生並受 version history 綁定

installer 新增 `PORTABLE_MANIFEST_PATH`、`portable_manifest_bytes`、`parse_portable_manifest` 與 `install_vendored_target`。serializer 直接使用 `source_inventory` 的 version、generation 與 records，避免另建 inventory 定義。canonical source 的 `.cash-skills/manifest.tsv` 必須逐 byte 等於 serializer 輸出。

`--self` 保持 source-only，但改為在同一exclusive lock transaction更新source manifest，並將既有source receipt視為non-authoritative residue予以刪除；除manifest與receipt cleanup外仍不得修改launcher、lock、runtime、skills、config或guidance。real run需要任一變更時維持既有 `Result: bootstrap`，dry-run回報 `Result: would-bootstrap`，canonical manifest且receipt absent時回報 `Result: current`。fresh source clone沒有receipt時可由committed manifest直接啟動，不再以 `bootstrap_invalid`要求先跑 `--self`。這是既有 `Bundle 安裝與 runtime receipt`及 `Installer 與 legacy cleanup filesystem boundaries`中 `--self`簽發receipt契約的唯一例外。

任何 launcher、runtime、skill、portable manifest schema／inventory bytes或 Git 邏輯 mode改變都必須先把 `cash-skills.version` 調升為嚴格較大的版本。portable manifest 不進 receipt records，既有 receipt可用相同 record集合升級。

### 6. 文件依 target 的實際信任模式提供指引

`CASH-SKILLS.md` 將 `--vendor` 作為團隊 repo 的建議路徑，並保留 receipt direct／registry 章節。`CASH-INIT-RECEIPT.md`改為 receipt-only direct／legacy target指南，移除「所有clone都要init」、「launcher無條件validate_receipt」與「launcher bytes不變」等已失效敘述，補上portable分流、`init_vendored_bundle`與mode矩陣。`AGENTS.md` 與 `CLAUDE.md` 的 managed guidance先說明：manifest存在時 clone／pull後直接使用，舊receipt不會shadow manifest；只有不含manifest的receipt-based target在 `bootstrap_invalid` 時才執行 `--init-receipt`。Codex 讀取 `.agents/skills/`、Claude 讀取 `.claude/skills/` 的現有 repo ownership不變，團隊成員不需再執行 skill installer。

### 7. 直接改變既有契約時以 MODIFIED 建立雙向可讀的 sync 結果

portable mode雖是新能力，仍直接限定既有receipt gate、help、source `--self`、stable launcher、`--init-receipt`、installer mode集合與文件義務。delta spec MUST保留新增能力的 `ADDED Requirements`，並對每個被直接改變的master requirement使用逐byte相同標題的完整 `MODIFIED Requirements` block；修改後本文須從既有requirement一側指向manifest-present或approved migration情境，避免archive後只從新requirement才能發現例外。這是spec合併表達的修正，不擴張runtime contract。

## Implementation Contract

### `.cash-skills/bin/cash`

- 啟動碼 MUST保留 Python 3.11 prerequisite、argv lock-family分類、同一 lock FD持有至 process結束與 project-root解析。
- manifest path presence判定 MUST在open前只用 no-follow `lstat` metadata；任何unsafe-present manifest MUST走 `manifest_invalid`，MUST NOT進receipt branch。manifest missing時才檢查receipt。
- portable parser MUST採受治理的期望 inventory：stable paths與 skill paths來自 launcher constants；runtime expected paths來自manifest records，且須符合 `.cash-skills/lib/cash_cli/*.py` 邊界、UTF-8 byte排序並至少一筆，再與現地 `.py` listing比較missing／extra；不得由現地 listing反向推導 expected set。
- manifest自身 MUST在open前驗證regular、single-link且Git logical class為non-executable `100644`；所有 manifest inventory檔案 MUST在 hash前驗證 containment、regular、single-link與 Git logical mode，並比較 opened FD／pathname identity。runtime generation演算法 MUST與 receipt相同。
- portable gate MUST保留已通過digest驗證的runtime source bytes；launcher在managed import前設定 `sys.dont_write_bytecode = True`，並以 `FileFinder`／`VerifiedSourceLoader`限制project-local library root及verified `cash_cli` package directories。`VerifiedSourceLoader.get_code` MUST直接compile保留bytes、不得呼叫superclass cache path，使該namespace不讀寫 `.pyc`且不改變stdlib importer。receipt gate與錯誤碼保持相容；portable gate不建立、chmod或更新任何檔案。

### `.cash-skills/lib/cash_cli/installer.py`

- `source_inventory` 仍是 receipt與manifest的 inventory單一來源；receipt serializer／parser及 record集合不得改變。
- `portable_manifest_bytes` 的輸出 MUST deterministic；`parse_portable_manifest` MUST拒絕任何非 canonical表示。
- `--vendor`、`--vendor --dry-run`、`--vendor --force` 的輸入檢核、classification與輸出沿用 direct模式的 `Result: current`、`Result: update`、`Result: conflict`及 execution error慣例；zero inventory的`fresh` classification在real run明確映射為 `Result: update`。
- `InstallTransaction` MUST以schema v3專用 `launcher`、dynamic `receipt`、manifest cutover與 `receipt_delete` operations實作上述rebind protocol，並保持schema v2 recovery；manifest是最後一筆trust-bearing managed bundle publication，`receipt_delete`是唯一允許的post-cutover operation。journal MUST區分pre-cutover rollback與 `portable_cutover` roll-forward cleanup。
- final pre-publication revalidation MUST涵蓋 source inventory、target inventory、舊 receipt／manifest identity、guidance／config inputs與全部planned publication paths的Git tracked／exclude判定；觀察改變時不得使用先前 snapshot繼續發布。
- receiptless完整inventory adoption、partial／different conflict、force replaceable邊界與stable prefix限制 MUST依決策3分類，不得由implementer自行選擇。
- `--init-receipt` 在一般 receipt-based target保持原行為；vendored target執行它 MUST以具名 `init_vendored_bundle` fail closed且零內容寫入。canonical source仍優先回報 `init_source_repo`。非source target首次確認manifest缺失後，MUST在取得exclusive stable lock後再次以no-follow `lstat`重驗仍缺失，才可進行mode正規化、inventory open或receipt publication。
- `--self`更新manifest並清除source receipt residue時 MUST在同一 stable lock和transaction完成；dry-run零寫入，逐 byte current且receipt absent則零寫入。

### Version 與 migration guard

- `cash-skills.version` MUST在第一個受 version guard 的 production artifact改動前先調升。
- `test_bundle_version_history.py` MUST把 `.cash-workspace.lock` 維持永久 immutable，並只依 `APPROVED_LAUNCHER_TRANSITIONS` 接受 launcher變更。
- history gate MUST把 `.cash-skills/manifest.tsv` 納入 version-bound inventory，並驗證 current manifest逐 byte等於 installer serializer的 canonical輸出。
- transition allowlist的 old digest MUST取自本變更前 HEAD launcher，new digest MUST取自完成後 launcher，`introduced_version` MUST等於new bytes首次出現的bundle version；不得使用 wildcard、prefix或僅以 version判斷。

### Verification

- `test_installer_runtime.py` 覆蓋 manifest-first precedence、stale receipt cutover、manifest pre-open unsafe shapes與executable manifest、help／concurrent generation、malicious-but-import-valid `.pyc`被忽略、fresh clone兩種 umask、bytecode零寫入、全planned paths Git excludes、receiptless adoption、fresh-to-update映射、managed drift、vendor current／update／force、receipt conversion、skipped-version launcher migration、schema v2／v3 recovery與pre／post-cutover phase faults。
- `test_init_receipt.py` 覆蓋 vendored target拒絕、manifest在初次preflight後且exclusive lock前由併發publisher出現時的post-lock拒絕、source self manifest refresh／receipt cleanup與 receipt-only模式回歸。
- `test_bundle_version_history.py` 覆蓋 version bump、manifest canonicality、launcher transition與 lock immutability。
- `skill-checks.fish` 覆蓋文件指引、manifest inventory沒有進 receipt、雙 variant清單與現行 receipt流程仍存在。

## Risks / Trade-offs

- **portable trust較 receipt弱**：能同時改寫 manifest與受管檔案的本機寫入者可建立新的自洽狀態。此模式明確把 authenticity交給 Git commit provenance；需要 machine-local post-install identity時仍使用 receipt模式。
- **launcher migration擴大 bootstrap複雜度**：exact transition、exclusive lock、journal與 history gate把例外限制在可稽核路徑；workspace lock仍不遷移。
- **Git mode不是完整 POSIX mode**：接受 umask造成的 group-write差異換取 clone零初始化；regular/single-link、digest與動態 identity仍必須通過。
- **兩種模式增加操作認知**：manifest-presence優先序、direct模式拒絕manifest，以及文件中的用途分流避免隱性轉換；vendored working tree內的receipt只是不具權威的local residue。
- **更新需要維護者提交**：這是刻意的 reviewable delivery模型；團隊成員不會取得未提交的自動更新。
- **MODIFIED blocks增加delta體積**：Cash sync以完整requirement取代master block，因此本變更須複製受影響requirement的既有scenarios；代價是較大的review面積，收益是apply期間與archive後都沒有單向precedence或舊本文殘留。
