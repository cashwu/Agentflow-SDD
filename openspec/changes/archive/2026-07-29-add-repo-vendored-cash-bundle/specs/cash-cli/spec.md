## ADDED Requirements

### Requirement: Portable manifest 啟動信任模式

Cash launcher SHALL在 `.cash-skills/manifest.tsv` path存在時提供完全唯讀的portable manifest啟動信任模式，不論machine-local receipt是否同時存在。launcher MUST在任何open前以no-follow `lstat`判斷manifest path presence；path存在（包含broken symlink、FIFO、directory、hard link或其他unsafe shape）時 MUST只走portable gate，驗證失敗 MUST以 `manifest_invalid`與exit 1 fail closed且 MUST NOT fallback到receipt。只有manifest path缺失才可判斷receipt；receipt存在時走既有receipt gate，兩者皆缺失時維持 `bootstrap_invalid`與exit 1。valid manifest是committed trust-mode marker，因此pull後殘留的ignored舊receipt MUST NOT shadow portable mode。

`.cash-skills/manifest.tsv` MUST 是 LF-terminated UTF-8 canonical TSV，依序包含 `format<TAB>cash-portable-manifest-v1`、`bundle_version<TAB><strict-MAJOR.MINOR.PATCH>`、`runtime_generation<TAB><lowercase-sha256>`，再依 receipt canonical inventory順序包含 `<kind><TAB><project-relative-path><TAB><lowercase-sha256><TAB><git-mode>` records。`kind` MUST 僅為 `stable`、`runtime` 或 `skill`；`git-mode` MUST 僅為 `100644` 或 `100755`。records MUST恰含 stable launcher、stable workspace lock、依 UTF-8 path bytes排序的 canonical runtime paths及 canonical 24-skill paths，不得 duplicate、missing、extra、unknown、absolute、dot-segment或 root-escaping path。manifest MUST NOT記錄自身、receipt、`st_dev`或`st_ino`，且 portable manifest的存在 MUST NOT擴充 receipt schema或 record集合。

manifest path只有在no-follow shape判定為single-link regular file後才可open；manifest自身的observed POSIX mode MUST正規化為non-executable Git logical class `100644`，executable class `100755` MUST以 `manifest_invalid`失敗；unsafe-present、unreadable或open後pathname／FD identity不同都 MUST以 `manifest_invalid`失敗，FIFO等shape MUST NOT阻塞。launcher MUST先安全開啟 launcher與 `.cash-workspace.lock`，依 argv取得既有 shared／exclusive flock，再驗證對應信任模式且持有同一 lock FD至 process結束。portable gate MUST將 observed POSIX mode正規化成 Git logical executable class後與 `git-mode` 比較，使常見 umask `022`與`002` clone產生的 `0644`／`0755`或`0664`／`0775`皆可按相同 Git mode通過；它仍 MUST拒絕錯誤 executable class。manifest與每個 inventory path都 MUST為 root-contained、non-symlink、single-link regular file；hash時 MUST比較 opened FD與 pathname的 `st_dev/st_ino`，digest與runtime generation都 MUST相符，且runtime record的exact source bytes MUST保留供import。runtime expected paths MUST取自manifest records並符合受約束namespace與canonical排序，launcher MUST另列舉現地 `.cash-skills/lib/cash_cli/`下的 `.py` paths並拒絕相對expected set的missing或extra；expected set MUST NOT由該現地列舉結果反向產生。launcher MUST在任何managed runtime import前設定 `sys.dont_write_bytecode = True`並提供 `VerifiedSourceLoader`；它可繼承 `SourceFileLoader`以配合 `FileFinder`，但 `get_code` MUST只以portable gate保留的verified bytes呼叫 `source_to_code`，MUST NOT呼叫superclass cache path或寫入cache。launcher在 `sys.path_importer_cache`為project-local library root及每個含manifest runtime record的 `cash_cli` package directory安裝 `FileFinder`／`VerifiedSourceLoader`；此限制 MUST只套用project-local `cash_cli` namespace且 MUST NOT改變stdlib importer。timestamp／hash-valid或sourceless `.pyc` MUST NOT被 `cash_cli` import使用。portable gate與後續read command MUST NOT建立、修改、chmod或刪除任何檔案。

本 requirement 與 `Project-local Cash CLI runtime`、`Cash workflow command surface`、`Bundle 安裝與 runtime receipt`及 `Target-local receipt 初始化`的本文共同定義manifest-present啟動行為：launcher MUST在receipt與portable manifest中恰完成一個gate；manifest缺失時既有receipt-only規則不變。

#### Scenario: Fresh vendored clone 不需初始化

- **GIVEN** 一個 canonical Git clone含完整受管 inventory與 valid `.cash-skills/manifest.tsv`
- **AND** clone不含 `.cash-skills/receipt.tsv`
- **WHEN** 在 umask `022`或`002`產生的任一合法 Git logical mode組合下執行 `.cash-skills/bin/cash list --json`
- **THEN** launcher取得正確 shared lock、通過 portable gate並載入 project-local runtime
- **AND** command成功，且包含ignored files、directories與mtime的完整filesystem snapshot前後相同

#### Scenario: 舊或無效 receipt 不遮蔽 vendored mode

- **GIVEN** target同時有 valid portable manifest與存在但 bytes、mode、identity或 shape無效的 receipt path
- **WHEN** 啟動任一 Cash command
- **THEN** launcher只驗證portable manifest並成功執行
- **AND** launcher不讀取、不修改也不刪除non-authoritative receipt residue

#### Scenario: Manifest drift fail closed

- **WHEN** portable manifest的 schema、version、row order、path set、Git mode、digest或runtime generation無效，或任一受管 path的 bytes、logical executable class或 filesystem shape與 record不符
- **THEN** launcher以 `manifest_invalid`與 exit 1失敗
- **AND** 即使存在valid receipt，command仍不 import managed runtime且不修改 workspace

#### Scenario: Unsafe manifest shape 在 open 前失敗

- **WHEN** manifest path是broken symlink、FIFO、directory、hard link或其他non-regular shape
- **THEN** launcher以 `manifest_invalid`與exit 1失敗
- **AND** 不把path視為missing、不fallback到receipt，也不阻塞在open

#### Scenario: Executable manifest fail closed

- **GIVEN** manifest是root-contained、single-link regular file且bytes canonical，但observed mode正規化為Git logical class `100755`
- **WHEN** 啟動任一Cash command
- **THEN** launcher在managed runtime import前以 `manifest_invalid`與exit 1失敗
- **AND** 不fallback到receipt、不chmod manifest且workspace零寫入

#### Scenario: Portable help 完成 portable gate

- **GIVEN** target有valid portable manifest且receipt缺失或殘留
- **WHEN** 執行 `.cash-skills/bin/cash --help`或 `.cash-skills/bin/cash --help --json`
- **THEN** launcher取得shared lock、完成portable gate後輸出help
- **AND** invalid manifest仍在輸出help前以 `manifest_invalid`失敗

#### Scenario: Portable generation 受同一 stable lock 保護

- **GIVEN** launcher read command與 `--vendor` update對同一target併發
- **WHEN** read command取得shared lock並驗證portable manifest
- **THEN** 它只從manifest驗證過的 `.py` source載入同一generation的runtime，忽略既存且可被一般import接受的不同payload `.pyc`
- **AND** updater取得exclusive lock後才可發布下一個完整generation

#### Scenario: 兩種信任資料皆缺失

- **GIVEN** receipt與portable manifest都缺失
- **WHEN** 啟動任一 Cash command
- **THEN** launcher維持 `bootstrap_invalid`與 exit 1
- **AND** 不自動執行 `--init-receipt`或 installer

#### Scenario: Manifest expected set 不由現地狀態推導

- **WHEN** runtime或skill inventory相對 canonical expected set缺一筆、多一筆或重複一筆
- **THEN** portable gate以 `manifest_invalid`失敗並指出不一致
- **AND** 現地枚舉結果 MUST NOT取代 manifest runtime records、launcher stable／skill constants與受約束 runtime namespace共同定義的 expected set

#### Scenario: Canonical source fresh clone 使用 committed manifest

- **GIVEN** canonical source repository的fresh clone含 valid committed manifest但沒有 machine-local receipt
- **WHEN** 直接執行 project-local Cash launcher
- **THEN** launcher使用 portable mode成功執行
- **AND** 不要求先執行 source-only `--self`

### Requirement: Repo-vendored Cash bundle 發佈

`cash_cli.installer` SHALL新增與 `--target`、`--self`、`--register`、`--unregister`、`--list`、`--all`及 `--init-receipt`互斥的 `--vendor <project>` mode，並允許 `--dry-run`與 `--force`。vendor target MUST是安全、既存、非 canonical source的 Git worktree top-level。preflight MUST對每個planned managed inventory、manifest、config與guidance path驗證其已由Git tracked，或不受repository `.gitignore`、`.git/info/exclude`與global exclude規則排除；任何blocked path MUST在首次target write前一次列出並fail closed，final publication前 MUST以相同path集合重驗。空值、root、symlink、non-Git、Git子目錄、unsafe config／guidance／inventory boundary或blocked planned path MUST fail closed，且 `--force` MUST NOT繞過。

`cash-skill-workflows` capability之 `手動的 cash 專案 registry` requirement已將 `--vendor`明列為非registry的repo-vendored publication；registry資料格式、registry操作模式與既有receipt-based batch語意不變。

`--vendor` MUST以 `source_inventory`作為 receipt與portable manifest共用的 version、runtime generation及受管 record單一來源，並 deterministic產生 canonical manifest。fresh publication MUST在同一 stable lock的 exclusive FD與 recoverable transaction中發佈 launcher、lock、runtime、canonical 24 skills、必要 config／guidance及manifest，MUST NOT建立 receipt；它 MUST沿用 receipt-based target的 `.gitignore` plan以排除 `.cash-skills/receipt.tsv`、`.cash-skills/state/`與 `__pycache__/`，但 MUST NOT排除portable manifest或其他planned publication path。manifest MUST是最後一筆trust-bearing managed bundle publication；唯一可排在它之後的operation是 `receipt_delete` cleanup。journal在manifest前失敗 MUST rollback舊gate，manifest成功後 MUST進入 `portable_cutover` phase並在後續失敗時保留新portable gate、roll forward完成cleanup。既有 vendored baseline的mode比較 MUST使用manifest的 Git logical mode，合法 umask造成的完整POSIX permission差異 MUST NOT構成managed drift。成功後相同 source重跑 MUST回報 `Result: current`且零寫入；有合法較舊bundle或 project-owned managed digest／logical-mode drift時依既有 update／conflict規則分類，`--force`只可收斂 replaceable managed bytes與mode class，不得接受 unsafe shape、version downgrade、invalid baseline manifest或 unapproved launcher drift。`--dry-run` MUST執行相同分類與 revalidation但 target零寫入。

receipt與manifest都缺失時，zero managed inventory MUST分類為fresh並在real run回報 `Result: update`；stable launcher／lock、runtime及canonical skills完整且逐檔符合source digest、Git logical mode與safe shape時 MUST分類為receiptless adoption，在exclusive lock下保留相符bytes並最後發布manifest。partial、unknown或different inventory未帶 `--force`時 MUST conflict；`--force`只可補齊或替換canonical expected path上的missing／different replaceable runtime與skills。unknown extra runtime及unknown stable drift即使帶 `--force`也 MUST fail closed。stable prefix只能是absent、safe empty lock、current launcher或allowlisted old launcher。

manifest absent的receipt-based target只有在既有 receipt完整通過receipt schema、identity、inventory及source版本判定時，才可由明示 `--vendor`轉換。轉換 MUST在同一transaction中發佈新inventory並以manifest publication完成trust-mode cutover，之後刪除receipt作為machine-local cleanup。若crash發生在manifest與cleanup之間，launcher因manifest-first precedence仍 MUST可用，recovery MUST完成cleanup。manifest已存在時，safe regular single-link receipt是non-authoritative residue，`--vendor` MAY不解析其內容而transactionally刪除；unsafe receipt shape仍 MUST fail closed。反向轉換 MUST NOT隱式發生：direct `--target`、`--register`及 `--all`遇到 manifest時 MUST拒絕並指出該 target由 `--vendor`管理。

canonical source的 `.cash-skills/manifest.tsv` MUST逐 byte等於同一 serializer對現行 source inventory的輸出。source-only `--self` SHALL在既有exclusive stable lock transaction中發布該manifest並刪除任何source receipt residue；除了manifest與receipt cleanup外仍 MUST零寫入。real run需要變更時 MUST回報 `Result: bootstrap`，dry-run對同一計畫 MUST回報 `Result: would-bootstrap`且零寫入，canonical manifest且receipt absent時 MUST回報 `Result: current`且零寫入。`Bundle 安裝與 runtime receipt`及 `Installer 與 legacy cleanup filesystem boundaries`的本文同步定義此source-only `--self`行為。`--init-receipt`在一般不含manifest的 receipt-based target維持現行行為；在 vendored target MUST以具名 `init_vendored_bundle`、統一 JSON error shape與 exit 1 fail closed且零內容寫入，canonical source仍優先使用既有 `init_source_repo`；`Target-local receipt 初始化`的具名error code清單已包含 `init_vendored_bundle`。

任何 launcher、runtime、skill、portable manifest schema／record或 Git logical mode改變 MUST在第一個受 guard的 production artifact改動前，將 `cash-skills.version`調升為嚴格較大版本。`.cash-skills/manifest.tsv` MUST受 first-parent bundle history與 canonical serializer contract tests守衛，但 MUST NOT加入 receipt records，使既有 receipt target可用原 record集合正常升級。

#### Scenario: 維護者一次發佈後提交

- **GIVEN** 一個符合 prerequisite且尚無 Cash inventory的團隊 Git repository
- **WHEN** 維護者執行 `--vendor <project>`
- **THEN** installer回報 `Result: update`並發佈完整 vendored inventory與portable manifest，但不建立 receipt
- **AND** 維護者可將受管檔案提交，其他成員clone後符合「Fresh vendored clone 不需初始化」scenario

#### Scenario: Planned path 被任一 Git exclude 阻擋

- **GIVEN** 任一planned publication path未tracked，且被repository、info或global exclude中的 `.cash-skills/`、`*.py`、`.agents/`、`.claude/`或其他pattern匹配
- **WHEN** 執行 `--vendor <project>`或 `--vendor <project> --force`
- **THEN** installer在首次write前列出全部blocked paths並失敗
- **AND** 不發布manifest或任何partial inventory

#### Scenario: Receiptless 完整 inventory 可認養

- **GIVEN** target沒有manifest與receipt，但stable prefix、runtime及canonical skills完整符合source digest、Git logical mode與safe shape
- **WHEN** 執行 `--vendor <project>`
- **THEN** installer保留相符bytes、收斂必要project files並最後發布manifest
- **AND** partial或different inventory未帶 `--force`時conflict，unknown stable drift即使帶 `--force`也fail closed

#### Scenario: Vendored update 與 current

- **GIVEN** target具有 valid較舊或同版本portable manifest及相符的受管 baseline
- **WHEN** 維護者以較新或相同 source執行 `--vendor <project>`
- **THEN** 較舊 target在 transaction內更新並回報 `Result: update`，相同 canonical target回報 `Result: current`且零寫入
- **AND** 較新 target拒絕 downgrade且零寫入

#### Scenario: Vendored managed drift 需要 force

- **GIVEN** valid manifest所記錄的 replaceable runtime或skill在 target已 drift但 filesystem shape仍安全
- **WHEN** 執行 `--vendor <project>`且未帶 `--force`
- **THEN** installer回報 `Result: conflict`且 target零寫入
- **WHEN** 再次明示 `--vendor <project> --force`
- **THEN** installer只收斂受管 replaceable內容並發佈新manifest，project-owned內容維持不變

#### Scenario: Receipt target 明示轉換

- **GIVEN** target沒有manifest且有完整有效 receipt
- **WHEN** 維護者執行 `--vendor <project>`
- **THEN** installer在同一 recoverable transaction完成受管更新，以manifest發佈完成cutover，再清除 receipt
- **AND** manifest發佈後即使cleanup前crash，下一次launcher仍只走portable mode且recovery可完成cleanup

#### Scenario: Invalid receipt 不能被 vendor force 合法化

- **GIVEN** receipt-based target的 receipt或 stable identity無效
- **WHEN** 執行 `--vendor <project>`或 `--vendor <project> --force`
- **THEN** installer在首次 write前以 execution error失敗
- **AND** 不建立manifest、不刪除receipt且不修改受管檔案

#### Scenario: Receipt installer 拒絕 vendored target

- **GIVEN** target有portable manifest，不論 receipt缺失或殘留
- **WHEN** 該 target被傳給 `--target`、`--register`或由 `--all`處理
- **THEN** receipt-based mode拒絕隱式轉換並提供 `--vendor`指引
- **AND** target與registry不因該 target被修改

#### Scenario: Self refresh 維持 canonical manifest

- **GIVEN** canonical source的 versioned inventory已合法調升但manifest或本機receipt尚未同步
- **WHEN** 執行 source-only `--self`
- **THEN** installer在同一exclusive lock transaction發布canonical manifest、清除source receipt residue並回報 `Result: bootstrap`
- **AND** 重複執行回報 `Result: current`且manifest零寫入、receipt維持absent

### Requirement: 受控 launcher bootstrap migration

Cash installer SHALL允許 stable launcher replacement，但僅限 `APPROVED_LAUNCHER_TRANSITIONS`明列的 `(old_digest, new_digest, introduced_version)`組合。target launcher已等於source時為no-op；否則target old digest與source new digest MUST命中同一筆transition，且source version MUST大於等於 `introduced_version`。history gate MUST驗證new launcher bytes恰在 `introduced_version`首次出現；source launcher自該版後未改變時，較高source bundle version MAY跨過中間版本使用同一transition。未知launcher、僅部分digest、wildcard、source digest不同、source version低於introduced version或 `--force`繞過 MUST一律以execution error fail closed。

launcher replacement MUST使用 `InstallTransaction` journal schema v3的專用 `launcher` operation，在既有或monotonic建立的 `.cash-workspace.lock` exclusive FD下執行；journal MUST記錄old launcher bytes、mode與device/inode，新installer MUST仍能讀取及恢復既有schema v2 journal。receipt-based upgrade MUST使用專用dynamic `receipt` operation，在launcher實際cutover後才從pathname重新取得launcher／lock `st_dev/st_ino`並組出新receipt，MUST NOT在transaction planning時把舊launcher inode固化進desired receipt。`.cash-workspace.lock`仍 MUST永久保持同一inode且不得unlink／rename。

publication failure的rollback MAY以atomic write還原old launcher bytes而取得新inode，但完成前 MUST從journal保存的old receipt重建相同old version、runtime generation、record paths、digests與modes，只將stable launcher／lock identity重綁到rollback後現地inode，再原子發布rebound old receipt。該receipt通過完整receipt gate後才算rollback完成；rebind失敗 MUST保留journal供matching-or-newer installer重試。journal在operation實際write前先標示published所造成的crash，也 MUST走相同rebind流程。vendored rollback依manifest gate復原，不需保留launcher inode。fault coverage MUST包含journal advance前後、launcher replace前後、dynamic receipt前後、manifest publication前後及receipt cleanup前後；每個recovery結果都 MUST通過完整舊或新gate。

本 requirement 是 `Project-local Cash CLI runtime`與 `Bundle 安裝與 runtime receipt` 中 stable launcher bytes／inode不得在 upgrade替換規則的唯一例外。bundle history contract MUST繼續永久凍結 `.cash-workspace.lock`；launcher差異只有在 bundle version已嚴格調升且 exact transition已登錄時通過。任何普通 runtime／skill更新不得隱含 launcher migration。

#### Scenario: 既有 receipt target 升級到新 launcher

- **GIVEN** target持有 valid舊receipt且launcher digest是 allowlist中的 exact old值
- **AND** source launcher digest命中同一transition的new digest，source bundle version大於等於introduced version
- **WHEN** 執行 direct或batch installer upgrade
- **THEN** installer在既有 workspace lock inode下 transactionally替換launcher並最後發布新receipt
- **AND** upgrade後 launcher以新 identity通過 receipt gate

#### Scenario: 跨版本沿用已引入的 launcher transition

- **GIVEN** launcher transition在版本V引入，後續版本W未再改變source launcher bytes
- **AND** target仍使用該transition的old launcher，W嚴格高於V
- **WHEN** 以版本W installer升級target
- **THEN** installer依同一old／new digest transition完成migration
- **AND** history gate仍只把V視為new launcher bytes的introduced version

#### Scenario: 未核准 launcher drift fail closed

- **WHEN** target launcher digest不等於source且不命中exact transition，或source new digest不符、source version低於introduced version
- **THEN** installer在首次 target write前失敗
- **AND** `--force`不得改變結果

#### Scenario: Launcher publication failure 可復原

- **GIVEN** fault injection使transaction在journal advance、launcher replacement、dynamic receipt、manifest publication或receipt cleanup任一邊界失敗或 crash
- **WHEN** 同一次rollback完成或下一次 matching-or-newer installer執行recovery
- **THEN** receipt-based rollback以old bundle內容與rebound stable identity通過完整receipt gate，或target完成完整新gate
- **AND** workspace lock inode保持不變，schema v2／v3 journal均依契約恢復並在成功後清除

#### Scenario: History gate拒絕未治理變更

- **WHEN** launcher bytes改變但bundle version未嚴格調升、exact transition缺失或 `.cash-workspace.lock` bytes／Git mode改變
- **THEN** bundle history contract test以非零結束
- **AND** 不把該差異視為一般 replaceable artifact更新


## MODIFIED Requirements

### Requirement: Project-local Cash CLI runtime

系統 SHALL 在 `.cash-skills/bin/cash` 提供 repository-owned CLI launcher，在 `.cash-skills/lib/cash_cli/` 提供其實作，並在既有project root直接安裝空的`0644` `.cash-workspace.lock`。launcher與lock SHALL為stable bootstrap objects：workspace lock在fresh install後不得以unlink或rename替換其inode；launcher只有在 `受控 launcher bootstrap migration` requirement的bundle version、exact digest transition、exclusive lock與recoverable journal條件全部成立時才可替換，其他source bootstrap bytes drift MUST以unsupported migration失敗。launcher MUST在載入receipt或任何managed Python library前no-follow開啟lock，依`argv`將`new/task/in-progress/touched/park/unpark/sync/archive`直接分類為exclusive mutating families，其他已知families為shared reads；取得正確mode後才依manifest-presence優先序完成portable manifest或receipt中恰一個信任gate並import library，並持有同一FD到process結束。Launcher MUST NOT以shared→exclusive conversion啟動mutation；unknown command取得shared lock後失敗。launcher MUST 使用 Python 3.11+ standard library，MUST 以自身位置解析 library，且 MUST NOT 呼叫、載入或 fallback 到 Spectra binary。Canonical skills MUST先以`git rev-parse --show-toplevel`解析並驗證project root，再使用root下launcher的絕對路徑，因此nested cwd MUST在CLI啟動前獲得正確runtime。manifest-present時的gate、零寫入與verified-source import由 `Portable manifest 啟動信任模式` requirement定義；manifest缺失時既有receipt-only行為不變。

#### Scenario: 未安裝 Spectra 仍可執行

- **GIVEN** project 已安裝 Cash bundle且PATH中不存在Spectra binary
- **WHEN** 呼叫 `.cash-skills/bin/cash list --json`
- **THEN** CLI從project-local runtime完成workspace discovery並回傳change清單
- **AND** process不嘗試執行任何Spectra command

#### Scenario: Python prerequisite 不符合

- **GIVEN** runtime解析到的Python版本低於3.11
- **WHEN** 呼叫任一Cash CLI command
- **THEN** command以execution error失敗並指出最低版本
- **AND** command不修改workspace

#### Scenario: Nested cwd 啟動 launcher

- **GIVEN** project root是`/repo`且目前目錄是`/repo/src/module`
- **WHEN** canonical skill執行Cash command
- **THEN** skill呼叫`/repo/.cash-skills/bin/cash`
- **AND** command完成workspace discovery

### Requirement: Cash workflow command surface

CLI SHALL 提供且僅需支援Cash workflows消費的`list`、`status`、`instructions`（含artifact-level、`instructions apply`與`instructions --skill <tdd|audit>`三種mode）、`new change`、`new artifact`、`task done`、`in-progress add`、`touched ensure`、`touched record`、`park`、`unpark`、`validate`（含single-change與`validate --all`）、`analyze`、`drift`、`archive`、`sync`與`search`command families。每個呼叫artifact engine的canonical Cash skill MUST 呼叫`.cash-skills/bin/cash`，MUST NOT包含可執行的`spectra`command或`Requires spectra CLI`相容性宣告。

CLI SHALL 另提供不擴張上述command family集合的help表面。第一個argument為`--help`或`-h`時，CLI MUST在launcher完成既有lock取得與manifest-presence所選信任gate驗證之後、進入command dispatch之前輸出help並以exit 0結束；help MUST NOT繞過launcher的信任gate：manifest存在時必須完成portable gate且invalid manifest以`manifest_invalid`失敗，manifest缺失時receipt缺失或無效仍 MUST維持既有的`bootstrap_invalid`／`receipt_invalid`失敗，而非輸出help。help flag不是command，`Project-local Cash CLI runtime`對unknown command的失敗規定僅適用於進入dispatch的token。第一個argument不是help flag時，CLI的dispatch目標、exit code、`error` code與JSON object結構 MUST與未提供該表面時相同。由top-level command dispatch產生的`missing_command`與`unknown_command` MUST維持既有的code、exit code與`error` object結構，但其`message` MUST指向help flag。該訊息 MUST NOT內嵌command清單——內嵌會使釘住該訊息的golden fixture成為第二份需手動同步的清單，與本requirement消除重複定義的目的相反；指向help的措辭是不隨dispatch table變動的穩定字串。由個別handler產生的其他`unknown_command`（例如未知的new mode或未知的discipline）MUST NOT受此規定影響。command清單 MUST只有help一個輸出處，且 MUST由dispatch table導出，MUST NOT另立靜態副本。`--json`時help MUST輸出單一JSON object，其`commands`欄位為排序後的dispatch table key陣列。

#### Scenario: 支援的 command 被 dispatch

- **WHEN** caller提供上述任一已支援command與有效arguments
- **THEN** CLI dispatch到Cash-owned handler
- **AND** handler不經過外部CLI adapter

##### Example: discovery command dispatch

- **GIVEN** caller位於有效workspace
- **WHEN** caller執行`.cash-skills/bin/cash list --json`
- **THEN** discovery handler回傳單一`changes` JSON object

#### Scenario: 未治理 command 被拒絕

- **WHEN** caller執行`.cash-skills/bin/cash update`
- **THEN** CLI回傳`unknown_command`錯誤
- **AND** CLI不建立Spectra相容pass-through
- **AND** 該dispatch層錯誤訊息指向help flag，且不內嵌command清單

#### Scenario: Help flag 列出全部 command

- **GIVEN** target依manifest-presence優先序具有valid portable manifest或valid receipt，且launcher可取得lock
- **WHEN** caller以`--help`或`-h`作為第一個argument執行CLI
- **THEN** CLI輸出dispatch table全部command並以exit 0結束
- **AND** CLI不進入command dispatch

##### Example: help 的兩種輸出形狀

- **GIVEN** caller位於對應portable manifest或receipt gate有效的workspace
- **WHEN** caller執行`.cash-skills/bin/cash --help --json`
- **THEN** CLI在stdout輸出單一JSON object，其`commands`為排序後的dispatch table key陣列
- **AND** 同一指令去除`--json`時輸出人類可讀文字

#### Scenario: Help 不繞過啟動信任 gate

- **GIVEN** target的portable manifest存在但無效，或manifest缺失且receipt缺失或內容無效
- **WHEN** caller以`--help`作為第一個argument執行CLI
- **THEN** CLI依對應gate以`manifest_invalid`、`bootstrap_invalid`或`receipt_invalid`失敗
- **AND** CLI不輸出help

#### Scenario: 缺少 command 時指向 help

- **WHEN** caller不提供任何argument執行CLI
- **THEN** CLI以`missing_command`與既有exit code失敗
- **AND** 錯誤訊息指向help flag，且不內嵌command清單

#### Scenario: Handler 層的 unknown_command 不受影響

- **WHEN** caller執行`.cash-skills/bin/cash new bogus <artifact-id>`或`.cash-skills/bin/cash instructions --skill bogus`
- **THEN** CLI維持既有的`unknown_command` code、exit code與訊息語意
- **AND** 該訊息不包含top-level command清單，也不指向help flag

#### Scenario: Help flag 不改變其他位置的行為

- **WHEN** caller執行`.cash-skills/bin/cash list --help`
- **THEN** CLI將該argument交給`list` handler，dispatch目標與exit code與未提供help表面時相同
- **AND** CLI不輸出help

### Requirement: Bundle 安裝與 runtime receipt

本 requirement的receipt publication與receipt-based direct／registry／batch語意適用於manifest缺失的target；manifest-present launcher、`--vendor`、source-only `--self`及approved launcher replacement分別由 `Portable manifest 啟動信任模式`、`Repo-vendored Cash bundle 發佈`與 `受控 launcher bootstrap migration` requirements治理。這些具名情境以其較窄契約優先，其餘既有receipt schema、inventory與fail-closed行為不變。

`install-cash-skills.fish` SHALL將stable launcher/lock、replaceable runtime generation、24個Cash skills與`.cash-skills/receipt.tsv`視為同一versioned inventory。`cash-skills.version` MUST恰含一個`MAJOR.MINOR.PATCH`值，三個分量各符合`0|[1-9][0-9]*`，不得含前導零、prerelease或build suffix。版本排序 MUST以每個digit string的長度再以lexical bytes比較任意長度分量，不得轉換為fixed-width integer或float。任何replaceable runtime/skill bytes或contract mode改變 MUST調升bundle version；相同版本 MUST綁定first-parent history中的引入commit，後續相同版本內容漂移 MUST使contract test失敗。Stable workspace-lock bytes不得隨bundle version改變；stable launcher bytes只有在bundle version嚴格調升且命中受控migration的exact transition時可改變，其他source drift MUST為execution error。

preflight MUST在任何target write前驗證Python 3.11+、source version及完整bootstrap/runtime/skill inventory、destination boundaries、legacy full-body digests、mode與config migration。direct、register與batch targets MUST各自是Git worktree top-level；non-Git或Git子目錄target MUST fail closed。target的`openspec/config.yaml`存在時 MUST為安全可讀、schema-valid的regular file；缺檔 MUST NOT fail closed。三種形態的判定順序 MUST為unsafe先於missing、missing先於invalid：symlink、非regular file或hard link MUST以execution error失敗，MUST NOT被視為missing而觸發建立；存在且安全的檔案才進schema驗證，invalid schema MUST在首次target write前以execution error失敗。unsafe與invalid兩種失敗 MUST NOT被`--force`繞過。形狀判定 MUST在任何open之前以no-follow `lstat` metadata完成，因為以read開啟FIFO會阻塞到出現writer為止；FIFO MUST以execution error失敗，MUST NOT阻塞。缺檔在三種target mode的後續處置不同：direct與batch mode MUST由config deployment在同一transaction內建立canonical baseline；`--register`只登錄專案而不執行安裝，因此 MUST接受缺檔的target並完成登錄，且 MUST NOT建立該檔。`runtime_generation` MUST為replaceable runtime records依project-relative UTF-8 path bytes排序後，每筆以`<path>\t<lowercase-sha256>\t<four-digit-mode>\n`構成canonical UTF-8 stream的lowercase SHA-256。receipt MUST先記錄bundle version與runtime generation，再依canonical inventory順序為stable launcher/lock及每個replaceable runtime/skill path恰記一筆project-relative path、lowercase SHA-256及mode；stable records另 MUST記錄target-specific decimal `st_dev/st_ino`。launcher與installer取得stable lock後 MUST以`fstat`比對launcher/lock records、逐檔hash runtime records並重算generation，才可import runtime或分類current。invalid source version、generation或receipt的invalid version、欄位數、digest、mode、device/inode、path、順序、duplicate、missing或unknown record MUST在首次write前以execution error失敗，不得分類為missing、current、newer或conflict。launcher MUST為`0755`，lock與其他新建runtime/skill files MUST為`0644`。可刪除legacy standard skill MUST逐byte匹配`scripts/cash-skills/legacy-spectra-digests.tsv`的已知baseline且mode為`0644`。無法證明為已知baseline者（同名customization、unknown version或mode drift）MUST被保留、MUST NOT被刪除或修改，且 MUST NOT阻斷安裝：installer MUST繼續發布其餘managed inventory，並在該target的輸出逐筆列出被保留的path。只有可能導致刪除逃逸target邊界的形狀——symlink、hard link或目錄含額外內容——MUST在首次write前fail closed。legacy receipt migration只驗證舊schema實際記載的path與digest，MUST NOT以舊schema未記載的mode作為migration gate；managed skill的mode由本次transaction依contract mode正規化。

Fresh、legacy adoption與known-old migration MUST使用monotonic bootstrap。read-only preflight後，installer以`O_CREAT|O_EXCL`建立project-root lock、立即取得exclusive lock，並以`fstat`與pathname no-follow lookup重驗相同device/inode；遇到`EEXIST`的並發installer MUST開啟現存lock、等待exclusive lock、重驗pathname/FD identity後重新分類。Stable lock一旦建立 MUST NOT unlink或rename；stable launcher除 `受控 launcher bootstrap migration` requirement明列的transactional replacement外，MUST NOT unlink或rename。一般receipt publication failure只回滾replaceable runtime、skills、config、guidance、target版控排除設定與receipt，保留canonical `lock-only`或`lock+launcher` prefix；受控launcher migration則依專用launcher／dynamic receipt journal與identity rebind契約rollback；下一次installer MUST在同一lock inode上恢復。launcher-without-lock、bootstrap drift、unknown partial state或pathname/FD mismatch MUST fail closed。Existing current/upgrade/force/batch MUST持有同一FD到transaction/rollback完成。新receipt MUST最後發佈並從target `fstat`產生stable identity records。Journal recovery會改變target state，因此installer MUST在recovery之後才定案installation inputs的target snapshot、legacy candidate plan與版控排除設定plan；Journal的存在偵測 MUST在read-only preflight內完成且 MUST早於版本比較的`newer` early return；該偵測 MUST為純讀取，MUST NOT持鎖，也 MUST NOT解讀target config，並 MUST以no-follow的`lstat`判定形狀——`JOURNAL_PATH`非regular file（含symlink）時 MUST以execution error fail closed，MUST NOT靜默視為無journal。恢復 MUST緊接在`newer` early return之後，且 MUST早於全部三個提前返回的分類分支：`legacy receipt drift`、`receipt-less Cash skill inventory is partial`與`managed target drift`；未完成journal存在時，installer MUST NOT先以其中任何一個返回而略過恢復，即使半發布bytes落在receipt-managed path亦然，且該恢復 MUST NOT要求`--force`。journal的schema version不被本bundle辨識時 MUST以execution error fail closed，且diagnostic MUST指出需要版本相符或更新的installer；`newer`排除的判準是receipt版本，而receipt是transaction的最後一筆operation，因此較新bundle在publishing階段的崩潰不會被`newer`排除，跨版本journal MUST由此條而非`newer`排除來處理。被分類為`newer`的target MUST維持零寫入返回且 MUST NOT執行recovery，其journal留待版本相符或更新的installer處理。非dry-run、target未分類為`newer`且偵測到journal時，installer MUST先執行既有的launcher-without-lock檢查，再取得既存stable lock後才執行recovery；該次取鎖 MUST NOT建立不存在的lock，journal存在而stable lock不存在 MUST fail closed，MUST NOT以`O_CREAT|O_EXCL`建立新的lock inode。recovery回傳真與回傳偽兩個分支 MUST都關閉lock descriptor，同一process在任一時刻 MUST至多持有一個stable lock descriptor。Journal recovery造成的rollback寫入 MUST NOT被視為違反`current`、`newer`或`conflict`分類的零寫入契約：該零寫入契約自recovery完成後的重新分類起適用，因此recovery之後若仍存在與該journal無關的drift，installer MUST回報`Result: conflict`、exit 2，且自重新分類起零寫入。當recovery實際處理並清除journal時，installer MUST釋放stable lock並依recovery後的state重新分類，MUST NOT因recovery自身造成的target變更而以publication前revalidation不一致為由fail closed；外部併發在取得lock之後修改target時，publication前revalidation的既有fail-closed契約 MUST維持不變。該重新分類 MUST在同一lock inode上恢復，且同一份journal MUST NOT再次觸發重新分類；釋放lock的時間窗內由外部併發產生的另一份journal可再觸發一次重新分類，屬既有併發語意。偵測到未完成journal時，installer MUST在早於`newer` early return的偵測點輸出一句與分類無關的通用diagnostic，僅陳述target存在未完成的journal；該句 MUST在dry-run與real run皆出現，且 MUST與最終分類無關而一律出現，包含`current`與`newer`。分類為`newer`時，installer MUST於`newer` early return之前另外輸出一句newer專屬補充，指出該journal需要版本相符或更新的installer才會恢復；該補充 MUST NOT併入通用句，因為通用句在版本比較之前發出，把newer專屬語意寫進去會對絕大多數會被本次執行恢復的target給出錯誤指引。`--dry-run` MUST NOT執行recovery並 MUST維持零寫入。

Receipt-less legacy adoption MUST在receipt與runtime缺失、stable prefix為absent、`lock-only`或`lock+launcher`，且24個canonical Cash skills全數為root-contained、non-symlink、single-link regular files、bytes與`0644` mode逐筆等於source時成立。installer SHALL保留skill bytes，並由monotonic bootstrap transaction補齊launcher、runtime、config/guidance與新receipt。零個skill是fresh；1至23個、任何byte/mode/identity不同或unknown Cash runtime partial state在未帶`--force`時 MUST conflict。Receipt-less完整新inventory則可在stable lock下依全部bytes/modes相符條件認養。

Known legacy receipt MUST嚴格限定為恰好25個LF-terminated records：第一筆`version<TAB><strict-MAJOR.MINOR.PATCH>`，其後依canonical 24-skill順序各一筆`sha256<TAB><lowercase-64-hex-digest><TAB><project-relative-path>`；它沒有mode、runtime、bootstrap或generation欄位。僅當receipt完整符合此schema、24個target skills逐筆相符且stable prefix absent或canonical recoverable時，installer才 SHALL執行one-time bootstrap migration。failure MUST回滾replaceable publications並還原old receipt，但 MUST保留已發布的stable lock/launcher；下一次direct或batch invocation MUST在相同lock inode恢復。old receipt drift、unknown/incomplete schema或bootstrap drift MUST fail closed。dry-run MUST使用同一判定、零寫入並回報would-update。

installer MUST先以incoming parser驗證source config，並在target config interpretation前先驗證target receipt/version/boundary；合法newer target MUST零寫入返回，且 MUST NOT由較舊incoming parser重新解讀target`.cash.yaml`。fresh、known-legacy、adoption、current與older target才使用incoming bundle parser。config deployment MUST採三分支：既有`.cash.yaml`視為project-owned，以該parser及no-follow snapshot驗證allowed keys、duplicates、types與syntax後逐byte保留，invalid existing config MUST在首次write前execution error；只有`.spectra.yaml`時 SHALL只接受uncommented `locale/tdd/audit/parallel_tasks`及optional `spec_dir: openspec`，任何其他active top-level/nested scalar、map、list或non-default`spec_dir` MUST fail closed；兩者皆不存在時 MUST先以同一parser驗證source canonical `.cash.yaml`，再逐byte複製baseline。installer MUST NOT刪除caller-owned`.spectra.yaml`。執行安裝的direct與batch mode在target的`openspec/config.yaml`不存在時，installer MUST以installer bundle內嵌的canonical baseline，在同一transaction內以`0644`建立該檔。該baseline MUST為LF結尾的UTF-8、首行為`schema: spec-driven`，其餘行 MUST只有blank line與full-line `#` comment，因此其parse結果的`context` MUST為空字串、`rules` MUST為空mapping；它 MUST先以同一`openspec/config.yaml` parser驗證通過才可寫入，且 MUST NOT在安裝時取自source repository的同名檔案，以免source專案自身的context或rules進入target。既有的`openspec/config.yaml` MUST逐byte保留並零寫入。缺檔時的建立 MUST優先於`current`分類的零寫入契約：其餘managed inventory一致但該檔缺失時，target MUST分類為`update`並建立該檔，MUST NOT分類為`current`。建立後該檔即為project-owned：後續安裝 MUST NOT覆寫或修復其內容，且它 MUST NOT進入receipt或managed inventory。installer MUST NOT建立`openspec/`下的其他目錄。成功transaction MUST最後才發佈receipt；failure MUST回滾新建config與先前receipt，或維持兩者absent；該回滾 MUST涵蓋新建的`openspec/config.yaml`，為它建立的`openspec/`目錄則可保留。

Installer SHALL提供source-only `--self [--dry-run]`模式。它 MUST從installer所在目錄解析唯一Git top-level，驗證canonical source version、stable launcher/lock、replaceable runtime generation、24個skills、`.cash.yaml`與`openspec/config.yaml`的no-follow identity、bytes及contract modes，並在既有stable lock的exclusive FD下分類或發布canonical portable manifest及清除source receipt residue。Real run需要變更時 MUST在recoverable transaction中發布manifest並刪除receipt residue，回報`Result: bootstrap`；`--dry-run` MUST執行相同preflight與計畫並回報`Result: would-bootstrap`且零寫入；canonical manifest且receipt absent時 MUST回報`Result: current`且零寫入。`--self` MUST NOT與`--target`、`--vendor`、`--all`、`--register`、`--unregister`、`--list`或`--force`組合，MUST NOT發布或修改launcher、lock、runtime、skills、config、guidance或legacy內容。`--self` MUST NOT建立缺失的`openspec/config.yaml`；source repository缺少該檔 MUST以execution error失敗且零寫入。已辨識source layout的launcher在manifest存在時 MUST只走portable gate；manifest缺失且receipt缺失時 MUST回報`bootstrap_invalid`，receipt存在但內容驗證失敗時 MUST回報`receipt_invalid`，invalid manifest MUST回報`manifest_invalid`且不得fallback。所有失敗 MUST以exit 1結束；JSON與non-JSON actionable diagnostic在兩種信任資料皆缺失時 MUST包含`./install-cash-skills.fish --self`，installed target diagnostic MUST NOT建議source-only指令。一般direct、registry與batch target modes仍 MUST拒絕source repository。

#### Scenario: Fresh target 原子安裝

- **GIVEN**安全、是Git top-level、具有有效`openspec/config.yaml`且沒有Cash inventory/config的target
- **WHEN**執行installer
- **THEN**stable launcher/lock、runtime generation、24個skills、source canonical Cash config與receipt在同一transaction完成
- **AND**下一次相同版本安裝回報current且零寫入

#### Scenario: Source repository self bootstrap

- **GIVEN** canonical source repository的portable manifest缺失或未同步，且stable lock、launcher、runtime、24個skills及configs安全且完整
- **WHEN** 執行`install-cash-skills.fish --self`
- **THEN** installer在existing lock inode的exclusive FD下發布canonical manifest、清除source receipt residue並回報`Result: bootstrap`
- **AND** 後續source launcher以portable gate執行Cash commands，重複`--self`回報`Result: current`且零寫入

#### Scenario: Source self dry run 與模式互斥

- **WHEN** 執行`--self --dry-run`
- **THEN** installer執行相同preflight並回報`Result: would-bootstrap`或`Result: current`，但零寫入
- **WHEN** `--self`與target、vendor、batch、registry、list或force mode任一組合
- **THEN** installer以caller-input error失敗且零寫入

#### Scenario: Source launcher提供可行動診斷

- **GIVEN** 已辨識source layout且manifest與receipt皆缺失，或目前選定的manifest／receipt gate無效
- **WHEN** 以JSON或non-JSON模式啟動launcher
- **THEN** launcher依選定gate以`bootstrap_invalid`、`manifest_invalid`或`receipt_invalid`與exit 1失敗
- **AND** 兩種信任資料皆缺失時diagnostic指出從project root執行`./install-cash-skills.fish --self`，invalid manifest則不得fallback到receipt

#### Scenario: Target prerequisite 不足

- **WHEN**direct、registered或batch target不是Git worktree top-level，或其既有`openspec/config.yaml`為unsafe shape或schema-invalid
- **THEN**installer在首次target write前以execution error失敗
- **AND**不發佈runtime、skills、config、guidance或receipt

#### Scenario: Config 三分支

- **WHEN**target已有`.cash.yaml`
- **THEN**installer以Cash runtime同一parser驗證後逐byte保留它
- **AND**unknown key、duplicate、wrong type或malformed內容在首次write前以execution error失敗

- **WHEN**target只有受支援的`.spectra.yaml`
- **THEN**installer建立等價Cash config且不刪除legacy source
- **AND**其他active scalar/map/list、unknown key或non-default`spec_dir`在首次write前失敗

- **WHEN**target兩者皆無
- **THEN**installer逐byte建立source canonical`.cash.yaml`
- **AND**任何後續transaction failure回滾該新檔

#### Scenario: 缺 openspec config 的全新 target 仍完成安裝

- **GIVEN**安全、是Git worktree top-level、沒有`openspec/`目錄也沒有Cash inventory/config的target
- **WHEN**執行installer
- **THEN**installer在同一transaction內以`0644`建立schema-valid的`openspec/config.yaml`
- **AND**stable launcher/lock、runtime generation、24個skills、Cash config與receipt同樣在該transaction完成
- **AND**下一次相同版本安裝回報`current`且該檔零寫入

#### Scenario: 既有 openspec config 逐 byte 保留

- **GIVEN**target已有安全、schema-valid且與installer baseline不同的`openspec/config.yaml`
- **WHEN**執行installer
- **THEN**installer逐byte保留該檔且不寫入它
- **AND**installer不因該檔與baseline不同而失敗

#### Scenario: 缺 openspec config 的 dry run 零寫入

- **GIVEN**缺`openspec/config.yaml`但其餘前置條件成立的target
- **WHEN**執行`--dry-run`
- **THEN**installer以既有dry-run分類回報（`--target`模式輸出`Result: update`，batch模式輸出`would-update`）
- **AND**installer不建立`openspec/config.yaml`，亦不建立`openspec/`目錄

#### Scenario: 缺 openspec config 的安裝失敗回滾該檔

- **GIVEN**缺`openspec/config.yaml`的target，且installer在建立該檔之後的某個publication失敗
- **WHEN**transaction回滾
- **THEN**該檔被移除且target不留下installer產生的`openspec/config.yaml`
- **AND**receipt維持absent，`openspec/`目錄可保留

#### Scenario: openspec config 的 unsafe shape 不被視為缺檔

- **WHEN**target的`openspec/config.yaml`是symlink、hard link、目錄或FIFO等非regular file
- **THEN**installer在首次target write前以execution error失敗，且不阻塞等待writer
- **AND**installer不建立或替換該檔，`--force`亦不繞過

#### Scenario: 缺 openspec config 的 target 可被登錄

- **GIVEN**是Git worktree top-level但缺`openspec/config.yaml`的target
- **WHEN**執行`--register`
- **THEN**installer完成登錄並以exit 0結束
- **AND**installer不建立`openspec/config.yaml`
- **WHEN**同一target的`openspec/config.yaml`為unsafe shape或schema-invalid
- **THEN**`--register`以execution error失敗且registry不變

#### Scenario: --self 不建立缺失的 openspec config

- **GIVEN**source repository缺少`openspec/config.yaml`
- **WHEN**執行`--self`或`--self --dry-run`
- **THEN**installer以execution error失敗且零寫入

#### Scenario: Newer target 不由舊 parser 重解

- **GIVEN**target有合法較新receipt及該版本合法、但incoming舊parser不認得的Cash config
- **WHEN**較舊installer評估target
- **THEN**installer在解析target config前回報newer且零寫入

#### Scenario: Known legacy receipt 建立 bootstrap

- **GIVEN**target具有嚴格舊schema receipt與逐筆相符的24個Cash skills，且沒有launcher與workspace lock
- **WHEN**real run或dry-run評估target
- **THEN**real run以exclusive新lock transaction建立stable bootstrap、runtime與新receipt，dry-run回報would-update且零寫入
- **AND**publication failure保留canonical stable prefix並回滾replaceable state，下一次在同一lock inode恢復
- **AND**並發安裝、old receipt drift與bootstrap collision依上述migration contract收斂或fail closed

#### Scenario: Receipt-less 24-skill legacy target 被認養

- **GIVEN**target沒有receipt/runtime，stable prefix為absent或canonical recoverable，且24個Cash skills的regular-file identity、bytes與`0644` mode全數等於source
- **WHEN**installer執行
- **THEN**installer保留skill bytes並以monotonic bootstrap transaction發佈launcher、runtime、config/guidance與新receipt
- **AND**partial、different或unsafe legacy inventory在未帶`--force`時為conflict且零寫入

#### Scenario: 未知 legacy skill 被保留且不阻斷安裝

- **GIVEN** target的某個`spectra-*` directory只含regular `SKILL.md`，但其bytes或mode不符已知baseline
- **WHEN** installer執行
- **THEN** 該directory與其內容維持逐byte與逐mode不變
- **AND** installer仍完成runtime、skills、config、guidance與receipt的發布
- **AND** 輸出逐筆列出被保留的legacy path

#### Scenario: 邊界不安全形狀仍 fail closed

- **WHEN** legacy candidate是symlink、其`SKILL.md`為hard link，或該directory含額外檔案
- **THEN** installer在首次target write前失敗
- **AND** `--force`不繞過此失敗

#### Scenario: Legacy receipt migration 不以 mode 為 gate

- **GIVEN** target具有舊schema receipt，其24個skill digest全部相符但檔案mode為`0600`
- **WHEN** installer評估該target
- **THEN** migration MUST NOT因mode不符而失敗
- **AND** 本次transaction把managed skills正規化為contract mode

#### Scenario: Legacy standard skills 安全移除

- **GIVEN**target內每個Cash替代範圍中的`spectra-*` directory只含identity相符的regular `SKILL.md`
- **WHEN**installer完成全部preflight並提交upgrade
- **THEN**這些legacy directories在同一transaction被移除
- **AND**未知內容、symlink或額外檔案會使整體transaction在首次write前失敗

#### Scenario: Installed launcher mode 可執行

- **WHEN**fresh、upgrade或force installation成功
- **THEN**target `.cash-skills/bin/cash` mode為`0755`
- **AND**contract test直接執行target launcher成功

#### Scenario: Strict SemVer 與任意長度排序

- **WHEN**source version缺失、多行、含前導零、prerelease、build suffix或不是三個分量
- **THEN**installer與dry-run皆在首次target write前以execution error失敗

- **WHEN**比較含有超過平台integer範圍的有效版本分量
- **THEN**installer依digit length與lexical bytes得到正確數值順序
- **AND**不發生overflow或floating-point rounding

#### Scenario: Invalid receipt fail closed

- **GIVEN**target receipt包含invalid version、欄位數、digest、mode、device/inode、generation、path、順序、duplicate、missing或unknown record
- **WHEN**installer評估target
- **THEN**installer以execution error失敗且零target write
- **AND**target不被分類為missing、current、newer或conflict

#### Scenario: Bundle 版本綁定內容

- **GIVEN**repository history包含`cash-skills.version`
- **WHEN**replaceable runtime/skill bytes或contract mode相對版本引入commit改變
- **THEN**contract suite要求目前版本嚴格遞增
- **AND**相同版本的內容或mode漂移使測試失敗
- **AND**stable workspace-lock source bytes改變時一律失敗；stable launcher source bytes改變時只接受bundle version已調升且exact transition已登錄的受控migration

#### Scenario: Receipt-less 完整新 inventory 被認養

- **GIVEN**target沒有receipt且stable launcher/lock與全部replaceable runtime/24個skills逐byte及mode等於source
- **WHEN**installer執行
- **THEN**installer先鎖定existing lock inode、保留stable bootstrap與managed bytes並發佈含runtime generation的receipt
- **AND**回報`Result: update`

#### Scenario: Current、newer 與 conflict 分類

- **WHEN**版本、全部receipt records、modes、guidance、target版控排除設定與legacy state都一致，且`openspec/config.yaml`存在
- **THEN**installer回報`Result: current`且零寫入

- **WHEN**target receipt版本高於source
- **THEN**installer回報`Result: newer`且零寫入

- **WHEN**target managed path相對有效receipt drift且未授權`--force`
- **THEN**installer回報`Result: conflict`、exit 2且零寫入

#### Scenario: Upgrade 與 force 只收斂 managed inventory

- **GIVEN**target版本不高於source且所有preflight通過
- **WHEN**clean upgrade或授權`--force`執行
- **THEN**installer持有existing lock inode，只更新replaceable runtime generation、24個skills、Cash guidance、target版控排除設定、receipt與精確baseline legacy removals
- **AND**stable lock inode不變；stable launcher除approved exact transition migration外維持bytes與inode不變
- **AND**除target版控排除設定依`Target 版控排除保護`附加的行以外，其他project-owned bytes維持不變

#### Scenario: Dry run 與 background-free registry

- **WHEN**installer以`--dry-run`、`--list`、`--register`、`--unregister`或`--all`執行
- **THEN**dry-run不產生target或persistent writes，registry modes只執行明確要求的state change
- **AND**不建立daemon、LaunchAgent、scheduled repair、watcher或background process

#### Scenario: Publication failure 可恢復

- **GIVEN**全部preflight成功且第N個publication失敗
- **WHEN**installer進入failure handling
- **THEN**它依transaction journal回滾已發布managed paths
- **AND**rollback失敗時保留journal、回報exit 1並阻斷下一次mutation直到recovery完成

#### Scenario: Crash 後首次執行即完成恢復

- **GIVEN**前一次installer在publishing階段中止，target留有未完成的transaction journal且部分managed paths帶有已發布bytes
- **WHEN**下一次非dry-run installer在同一lock inode上執行
- **THEN**installer完成journal rollback、依recovery後的target state重新分類，並在同一次執行內完成該安裝
- **AND**它 MUST NOT以installation inputs在取得lock後改變為由失敗，亦 MUST NOT要求第二次執行才能完成恢復
- **AND**無並發installer介入、且recovery之後不存在與該journal無關的drift時，該次執行回報`update`而非`conflict`，且半發布bytes落在receipt-managed path時亦不需`--force`

#### Scenario: Receipt-less 與 legacy 崩潰同樣先恢復

- **GIVEN**target留有未完成的transaction journal，且其狀態會命中`receipt-less Cash skill inventory is partial`或`legacy receipt drift`其中一個提前返回分支
- **WHEN**下一次非dry-run installer評估該target
- **THEN**installer先完成journal recovery再重新分類，MUST NOT先以該分支返回而略過恢復
- **AND**恢復後的分類依recovery之後的target state決定

#### Scenario: Newer target 帶未完成 journal 仍零寫入

- **GIVEN**target的receipt版本高於incoming bundle，且留有未完成的transaction journal
- **WHEN**較舊的installer評估該target
- **THEN**installer回報`newer`且零寫入
- **AND**MUST NOT對該journal執行recovery，MUST NOT因其schema不被本bundle辨識而失敗
- **AND**通用diagnostic指出該target存在未完成的journal，且另有一句newer專屬補充指出需版本相符或更新的installer才會恢復

#### Scenario: Journal 存在而 stable lock 不存在則 fail closed

- **GIVEN**target留有未完成的transaction journal，但`.cash-workspace.lock`不存在
- **WHEN**installer執行恢復前置階段
- **THEN**installer以execution error fail closed
- **AND**MUST NOT以`O_CREAT|O_EXCL`建立新的lock inode而靜默修復該狀態

#### Scenario: Dry run 遇未完成 journal 不恢復但明示

- **GIVEN**target留有未完成的transaction journal
- **WHEN**installer以`--dry-run`評估該target
- **THEN**installer維持零寫入且不執行recovery
- **AND**diagnostic指出該target存在未完成的journal

#### Scenario: 版控排除設定 plan 取自 recovery 之後

- **GIVEN**中止的transaction其published operations包含target的版控排除設定寫入
- **WHEN**下一次installer完成journal recovery
- **THEN**版控排除設定的寫入plan由recovery之後的no-follow snapshot導出
- **AND**installer MUST NOT以recovery之前的snapshot內容覆寫該檔

#### Scenario: Install 與 launch 共用 stable lock

- **GIVEN**existing target正在執行Cash CLI並持有stable lock的shared FD
- **WHEN**installer嘗試upgrade runtime generation
- **THEN**installer在取得同一inode的exclusive lock前不得snapshot或publish managed destinations
- **AND**CLI process不載入mixed runtime generation

- **GIVEN**installer持有exclusive lock並正在publish多檔runtime generation
- **WHEN**新launcher process啟動
- **THEN**launcher在import library前等待同一lock
- **AND**取得shared lock後只載入receipt驗證過的完整generation

### Requirement: Installer 與 legacy cleanup filesystem boundaries

Installer SHALL canonicalize既有target；一般direct、registry與batch模式 MUST拒絕空值、`/`、source repository、symlink target、root外destination及symlink/hard-link ownership不明的managed boundary。唯一source repository例外是明確`--self`模式，且該模式只能在已驗證source root內發布canonical portable manifest並清除source receipt residue；它不得簽發新的source receipt。Publisher MUST以held no-follow parent directory handle、exclusive relative temporary basename、snapshot revalidation、明確mode與transaction journal完成publication/cleanup。Registry與`uninstall-spectra-plus-repair.fish` MUST保留既有HOME absolute/non-root、symlink及service identity fail-closed contract。Mode參數的分派 MUST依「該參數是否被提供」判定，MUST NOT依參數值的truthiness判定；空字串的`--target`、`--register`或`--unregister` MUST被視為該mode的invalid value並以caller-input error失敗，MUST NOT被重新解讀為batch mode或任何其他mode。該空值拒絕 MUST早於registry的讀取，也 MUST早於與mode相依的`--dry-run`及`--force`相容性檢查：空字串mode參數 MUST NOT讀取registry、MUST NOT對任何已註冊project執行安裝；即使registry或HOME本身不合法，diagnostic MUST指出mode參數值無效而非registry或HOME錯誤；空字串mode參數與`--dry-run`或`--force`併用時，diagnostic MUST指出該值無效而非指出缺少mode參數。與mode相依的`--dry-run`及`--force`相容性檢查本身 MUST對帶值mode參數使用同一存在性判準，對`store_true`的boolean mode flag則 MUST維持既有判準，使既有的caller-input守衛不因此失效。

#### Scenario: Target 與 HOME boundary fail closed

- **WHEN**target、managed parent、destination、receipt、config、guidance或HOME/registry boundary不安全
- **THEN**installer或cleanup在首次write與`launchctl`前失敗
- **AND**不讀寫root外target

#### Scenario: 空字串 mode 參數不得被重新解讀

- **GIVEN**registry至少已註冊一個project
- **WHEN**installer以`--target`、`--register`或`--unregister`接收空字串
- **THEN**installer以caller-input error失敗且零寫入
- **AND**它 MUST NOT讀取registry，也 MUST NOT對任何已註冊project執行安裝

#### Scenario: 空字串 mode 參數的診斷優先於 registry 錯誤

- **GIVEN**registry本身不合法而無法通過canonical檢查
- **WHEN**installer以`--register`或`--unregister`接收空字串
- **THEN**diagnostic指出mode參數值無效
- **AND**diagnostic MUST NOT指出registry或HOME錯誤

#### Scenario: 空字串 mode 參數與相容性 flag 併用的診斷

- **WHEN**installer以`--target`、`--register`或`--unregister`接收空字串，並同時帶`--dry-run`或`--force`
- **THEN**三者在兩種flag下的diagnostic皆指出該mode參數值無效
- **AND**diagnostic MUST NOT指出缺少mode參數，即使該mode參數不在該flag相容性檢查的運算元之列

#### Scenario: Boolean mode flag 的相容性守衛不受影響

- **WHEN**installer以`--list --dry-run`或以`--register <project> --force`執行
- **THEN**installer維持既有的caller-input error失敗且零寫入
- **AND**MUST NOT因mode分派改用存在性判準而改為接受該組合

#### Scenario: Temporary ownership 與 mode preservation

- **GIVEN**publisher持有已驗證parent handle
- **WHEN**建立temporary entry並publish
- **THEN**temporary basename以exclusive create證明本次ownership
- **AND**publication設定contract mode並只清理本次owned entry

#### Scenario: Parent swap 與 rollback failure

- **WHEN**parent/destination在preflight後被替換，或rollback再次失敗
- **THEN**publisher不透過失效pathname執行cleanup或write
- **AND**保留transaction journal與可恢復diagnostic

### Requirement: Target-local receipt 初始化

`cash_cli.installer` SHALL 提供 target-side 的 `--init-receipt` 模式，與 `--self`、`--target`、`--vendor`、`--register`、`--unregister`、`--list`、`--all`、`--force` 互斥，以在 target 專案根執行 `PYTHONPATH=.cash-skills/lib python3 -s -P -B -m cash_cli.installer --init-receipt` 的形式使用。此模式 MUST NOT 新增任何檔案到 bundle inventory、MUST NOT 改變 receipt 的 record 集合或 schema、MUST NOT 修改 `.cash-skills/bin/cash` 的任何 bytes。

`--init-receipt` MUST 依序：於 import 完成後檢查 Python 3.11+；驗證執行目錄為 canonical Git worktree top-level；以 launcher 的 source layout marker 集合（source-only 檔案、runtime core、24 個 canonical skill 的存在與 regular-file 形狀，加上可解析的 `cash-skills.version`）拒絕 canonical source repository 並在診斷中指向 `./install-cash-skills.fish --self`，該判定 MUST NOT 以 contract mode 相等為條件，因為這些 marker 都不在 mode 正規化涵蓋的 managed inventory 內，mode 相等的判定會使 umask 偏移的 source clone 被誤判為一般 target；source判定完成後以no-follow `lstat`檢查portable manifest path，非source target只要該path存在（包含unsafe shape）就 MUST以`init_vendored_bundle`fail closed且不得讀取或修改receipt；驗證 `openspec/config.yaml` 安全可讀且 schema-valid（缺檔、unsafe 或 invalid 皆 fail closed，MUST NOT 建立任何檔案）；確認 `.cash-workspace.lock` 為既存且為空的 regular file（缺失或非空皆 fail closed，MUST NOT 建立或修復 stable 檔案）並取得 exclusive flock 全程持有；取得exclusive flock後 MUST再次以no-follow `lstat`重驗portable manifest path仍缺失，若它由missing變為任何present shape，MUST在mode正規化、inventory open或receipt publication前以`init_vendored_bundle`fail closed；檢核 runtime inventory 完整性；再以 no-follow `lstat` 確認 managed inventory 逐檔為 regular file 後，將其 mode 正規化為 contract modes（launcher `0755`、其餘 `0644`），非 regular file 形狀 MUST fail closed 且不 chmod。runtime 完整性檢核 MUST 先於 mode 正規化，使 runtime 集合不符時零 `chmod`。任一檢核失敗 MUST 以具名 error code（`init_python_version`、`init_outside_worktree`、`init_source_repo`、`init_vendored_bundle`、`init_config_invalid`、`init_inventory_invalid`、`init_write_failed`）與統一 JSON 錯誤 shape 輸出到 stdout 並以 exit 1 結束，且零檔案內容寫入；mode 正規化的 `chmod` 是唯一允許的 metadata 修改。持有 exclusive flock 之後對 target 檔案的每一次開檔 MUST 先以 `lstat` 判定形狀，`.cash-skills/receipt.tsv` 本身為 FIFO 等非 regular file 時 MUST 以 `init_write_failed` fail closed 而非阻塞在開檔。

簽發時，`--init-receipt` MUST 從現地 bytes 計算 digests、以本機 no-follow `lstat` 產生 stable identity，組出與 installer 安裝路徑相同 schema 的 receipt：`version` 值取自 installer module 內嵌的 `BUNDLE_VERSION` 常數，record 集合與現行 inventory 完全相同。寫入 MUST 沿用 same-directory owned temporary 與 atomic rename，`.cash-skills` 非 regular directory 時 MUST fail closed。既有 receipt 的 bytes 與 contract mode `0644` 都與重算結果一致時 MUST 回報 `current` 且零寫入；bytes 一致但 mode 已漂移時 MUST 走一般簽發路徑重寫並回報 `initialized`，因為 launcher 對 receipt 有 `0644` 的 mode 閘門，回報 `current` 會留下「成功卻不可用」的狀態。成功簽發回報 `initialized`，兩者皆輸出單行到 stdout 並以 exit 0 結束。簽發的信任根是 git clone 的現地內容：`--init-receipt` 是使用者主動的明示動作，launcher MUST NOT 在 receipt 缺失或無效時自動觸發它。

inventory 完整性檢核 MUST 以獨立於現地觀察狀態的期望集合進行。stable 與 24 個 canonical skill 的期望路徑為常數推導；runtime 的期望路徑 MUST 取自 installer module 內嵌的 `BUNDLE_RUNTIME_PATHS` 常數，MUST NOT 以現地 `rglob` 枚舉結果作為自身的期望集合——那會使比對恆真、缺檔與多檔皆不被偵測，並簽發一份自洽但錯的 receipt。現地 runtime 集合與 `BUNDLE_RUNTIME_PATHS` 不相等時 MUST 以 `init_inventory_invalid` fail closed，診斷 MUST 同時列出 missing 與 extra 兩個差集。

`cash_cli.installer` 的 import-time 相依（`installer.py` 自身、它的 `from .config import`，以及 `cash_cli/__init__.py` → `main.py` → `errors.py` 的匯入鏈，共 4 個；`cash_cli/__init__.py` 本身因 PEP 420 namespace package fallback 不屬此類）缺席時，`-m` 載入在任何檢核之前就以未捕捉的 `ModuleNotFoundError` 失敗，因此 MUST NOT 期待具名 error code；此限制與舊直譯器的 `SyntaxError` 屬同一類（import 先於任何檢查），已於 proposal Non-Goals 載明。`CASH-INIT-RECEIPT.md` MUST 明載哪些模組屬此類，且 MUST NOT 把它們列為 `init_inventory_invalid` 對照表的適用對象。

`BUNDLE_VERSION` 常數 MUST 由 contract test 斷言恆等於 `cash-skills.version` 的檔案內容；`BUNDLE_RUNTIME_PATHS` 常數 MUST 由 contract test 斷言恆等於 source 端 `source_inventory` 推導出的 runtime 路徑集合。

source repository 的 `AGENTS.md` 與 `CLAUDE.md` Cash guidance 區塊 MUST 各含信任模式分流：manifest存在時直接使用portable mode且不得執行`--init-receipt`；只有manifest缺失的receipt-based target在receipt缺失出現`bootstrap_invalid`時才提供完整初始化指令。既有guidance部署 MUST把該分流帶到每個target的managed block；target端的發現管道由此承擔，MUST NOT依賴source-only檔案（如`CASH-SKILLS.md`）作為target端引導。

#### Scenario: Fresh clone 一次初始化後 CLI 可用

- **GIVEN** 一個由 git clone 取得、含完整版控 inventory、沒有portable manifest且沒有 `.cash-skills/receipt.tsv` 的receipt-based installed target
- **WHEN** 在專案根執行 `PYTHONPATH=.cash-skills/lib python3 -s -P -B -m cash_cli.installer --init-receipt`
- **THEN** 模式回報 `initialized` 並簽發逐項通過 launcher `validate_receipt` 的 receipt
- **AND** 後續 `.cash-skills/bin/cash list --json` 成功執行，不以 `bootstrap_invalid` 或 `receipt_invalid` 失敗

#### Scenario: 有效 receipt 時零寫入

- **GIVEN** target 的 receipt 與現地內容重算結果逐 byte 等價且其 mode 為 `0644`
- **WHEN** 再次執行 `--init-receipt`
- **THEN** 模式回報 `current`
- **AND** `.cash-skills/receipt.tsv` 的 bytes 不變且無 temporary 檔殘留

#### Scenario: Umask 差異被 mode 正規化吸收

- **GIVEN** 一個在 umask `002` 環境 clone 的 installed target，其 launcher checkout 為 `0775`、其餘檔案為 `0664`
- **WHEN** 執行 `--init-receipt`
- **THEN** managed inventory 的 mode 被正規化為 contract modes（launcher `0755`、其餘 `0644`）
- **AND** 簽發的 receipt 通過 launcher `validate_receipt`

#### Scenario: 失敗路徑零內容寫入

- **WHEN** `--init-receipt` 在非 worktree top-level執行、或非source target存在portable manifest、或 `openspec/config.yaml` 缺失或invalid、或 `.cash-workspace.lock` 或任一**非 import-time 相依**的inventory檔案缺失、或 `.cash-workspace.lock` 非空、或任一managed路徑非regular file、或 `.cash-skills/receipt.tsv` 本身非regular file
- **THEN** 模式以對應的具名 error code 與統一 JSON 錯誤 shape 失敗（exit 1）
- **AND** 沒有任何檔案內容被建立或修改
- **AND** 模式不阻塞在任何開檔上

#### Scenario: Canonical source repository 被拒絕

- **WHEN** 在 canonical source repository 執行 `--init-receipt`
- **AND** 該 repository 的檔案 mode 為 umask `022` 或 umask `002` clone 產生的任一組
- **THEN** 模式以 `init_source_repo` 失敗
- **AND** 診斷包含 `./install-cash-skills.fish --self`
- **AND** `.cash-skills/bin/cash` 的 bytes 不因本 requirement 的任何行為而改變

#### Scenario: Vendored target 拒絕初始化 receipt

- **GIVEN** 非source target的portable manifest path存在，不論manifest valid或unsafe
- **WHEN** 執行`--init-receipt`
- **THEN** 模式以`init_vendored_bundle`與exit 1失敗
- **AND** 不讀取、不建立、不修改也不刪除receipt或任何bundle檔案

#### Scenario: Runtime inventory 缺檔時 fail closed

- **GIVEN** 一個沒有 receipt 的 installed target，其 `.cash-skills/lib/cash_cli/` 少了一個 canonical runtime 模組
- **AND** 該模組不是 `cash_cli.installer` 的 import-time 相依
- **WHEN** 執行 `--init-receipt`
- **THEN** 模式以 `init_inventory_invalid` 失敗（exit 1）且診斷含該缺檔路徑
- **AND** 沒有 receipt 被建立
- **AND** 後續 `.cash-skills/bin/cash list --json` MUST NOT 因 receipt 通過驗證而以未捕捉的 `ModuleNotFoundError` 失敗

#### Scenario: Runtime inventory 多檔時 fail closed

- **GIVEN** 一個沒有 receipt 的 installed target，其 `.cash-skills/lib/cash_cli/` 多了一個不屬於 canonical 集合的 `.py`
- **WHEN** 執行 `--init-receipt`
- **THEN** 模式以 `init_inventory_invalid` 失敗（exit 1）且診斷含該多餘路徑
- **AND** 沒有 receipt 被建立，該 target 的後續 `install-cash-skills.fish --target` MUST NOT 因 record 數不符而永久失敗

#### Scenario: 版本常數受 contract test 守衛

- **WHEN** `BUNDLE_VERSION` 與 `cash-skills.version` 的內容不相等
- **THEN** contract test 以非零結束並指出兩個值
- **AND** 當 `BUNDLE_RUNTIME_PATHS` 與 source 端 `source_inventory` 推導出的 runtime 路徑集合不相等時，contract test 同樣以非零結束並指出差集

#### Scenario: 併發下以 stable lock 序列化

- **WHEN** `--init-receipt` 與 launcher 或 installer 同時對同一 target 執行
- **THEN** `--init-receipt` 在取得 `.cash-workspace.lock` 的 exclusive flock並重驗manifest仍缺失後，才進行 mode 正規化、檢核與簽發
- **AND** receipt 的發佈維持 atomic，任何併發讀取者只會看到舊或新完整內容

#### Scenario: Manifest 在 preflight 後出現時拒絕簽發 receipt

- **GIVEN** `--init-receipt`首次檢查時portable manifest path缺失
- **AND** 併發 `--vendor`在它取得exclusive flock前發布manifest
- **WHEN** `--init-receipt`取得同一stable lock的exclusive flock
- **THEN** 它重驗manifest path、以`init_vendored_bundle`與exit 1失敗
- **AND** 不執行mode正規化、不讀寫receipt，也不留下temporary檔

#### Scenario: Init 指引隨 guidance 部署到達 target

- **GIVEN** source repository 的 `AGENTS.md` 與 `CLAUDE.md` Cash guidance 區塊含portable／receipt分流與 `--init-receipt` 指引段
- **WHEN** installer 對任一 target 完成安裝或更新
- **THEN** 該 target 的 `AGENTS.md` 與 `CLAUDE.md` managed guidance block 含同一信任模式分流
- **AND** manifest-present target不被要求初始化，manifest缺失的receipt-based target在 `bootstrap_invalid` 情境下可由該指引得知初始化指令

#### Scenario: Inventory 未擴充使既有 targets 正常升級

- **GIVEN** 既有 registry targets 持有前一版本簽發的 receipt
- **WHEN** 新版本以 `--all` 部署
- **THEN** 每個 target 的既有 receipt 以相同 record 集合正常解析並走 update 路徑
- **AND** 沒有 target 因 record 集合不符而以 execution error 失敗
