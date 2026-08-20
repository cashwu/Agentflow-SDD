## ADDED Requirements

### Requirement: Stable receipt identity 比對條件與 gate 診斷

Receipt-based target的stable records（`.cash-skills/bin/cash`與`.cash-workspace.lock`）SHALL以digest、mode與`st_ino`三項與記錄值逐項相等作為identity比對的通過條件。launcher的receipt gate與installer的installed-receipt驗證 MUST NOT把record的`st_dev`欄位納入任何比對式。理由是`st_dev`是kernel在mount時配發給volume的編號而非檔案屬性：volume重新編號會使一個完全未被更動的target在使用者未做任何事的情況下同時失去launcher與installer兩條路徑，而該分量在stable path由project root推導、以no-follow開啟且digest與mode皆逐項比對的前提下不提供額外偵測力。

Receipt schema MUST不變：stable record MUST仍恰為六欄，非stable record MUST仍不得帶identity欄位。`st_dev`與`st_ino`的欄位形狀 MUST在兩個gate採用相同判準——`st_dev` MUST為非負整數、`st_ino` MUST為正整數，違反者 MUST以既有的invalid-receipt路徑fail closed。此判準在installer的receipt parsing已經成立，launcher MUST同樣套用它；否則`st_dev`同時失去比對與範圍兩道閘門，會使negative device的receipt被接受。Receipt發佈端 MUST仍從現地no-follow `lstat`寫入當下的`st_dev`，使既有targets的receipt維持相同record集合與欄位數而可正常解析並走update路徑。該值自此不作為identity比對輸入，只作為machine-local provenance並受上述形狀閘門約束。

本requirement的診斷分類 SHALL只涵蓋「該筆stable record已存在、形狀合法、且進入identity比對」之後的失敗。至少下列失敗出口 MUST沿用既有fail-closed路徑且 MUST NOT被歸入下列兩類：receipt缺少該筆stable record或其kind不是`stable`；stable record的device／inode欄位形狀不合法；receipt自身的runtime generation不符；stable path本身缺檔；stable path的形狀或mode使launcher在進入receipt gate之前即以`bootstrap_invalid`失敗。本段 MUST NOT被讀為窮舉，也 MUST NOT規定這些出口彼此之間的判定順序——它們各自沿用既有路徑，而各gate的既有執行序不同：launcher對stable path的形狀與mode檢查發生在receipt解析之前，因此缺record在launcher端不可能早於形狀判定。

進入分類的失敗 SHALL分成兩類且 MUST指名該record的project-relative path：

1. record的digest與現地觀察值不符時為content drift。診斷 MUST NOT包含`--init-receipt`，因為重新簽發會以現地bytes覆寫receipt，等同把內容漂移合法化。
2. digest相符而mode或`st_ino`與記錄值不符時為identity drift。此時檔案內容可證明仍是receipt記錄的那份，重新簽發不引入新的信任，診斷 MUST在滿足下一段前提時包含執行`--init-receipt`的完整指令。mode漂移 MUST歸入本類而非content drift：`--init-receipt`依 `Target-local receipt 初始化` requirement本來就是mode正規化的授權入口，把它歸入content drift會與該requirement給出相反指引。

判定順序 MUST為先digest後mode／inode：digest不符時 MUST判為content drift，不論mode或`st_ino`是否同時不符。

identity drift的`--init-receipt`指引 MUST只在同一份receipt中該gate本來就會對現地檔案驗證的其餘records全數相符時附上。此前提 MUST依gate分別界定，MUST NOT要求任一gate新增它現行未執行的驗證：launcher面為每一筆runtime record的digest與mode，MUST NOT把24個skill records的逐檔digest納入前提——launcher現行不對skill bytes做digest比對，把它納入會使每次啟動新增24次檔案雜湊；installer面為每一筆runtime及skill record，因為installed-receipt驗證的迴圈本來就涵蓋這兩類。前提 MUST NOT納入runtime generation：launcher的generation重算是以receipt自身的runtime列進行的receipt內部一致性檢查，installer亦未對target重算generation，兩者都不是現地record漂移。理由是`--init-receipt`以現地bytes重簽整份inventory且不比對runtime或skill bytes，若在其他records已漂移時引導重簽，會把被竄改的內容簽為合法。

前提不成立時，gate MUST改為回報該筆漂移的record，診斷 MUST同時指名出現identity drift的stable path與該筆漂移record的path，MUST NOT附上`--init-receipt`，且 MUST在該訊息尾端接上一句兩個gate共用、逐字相同的下一步句，指出把該筆record還原成receipt記錄的內容後重試、或從可信source重新安裝。該下一步句 MUST是訊息的一部分而非另一則輸出。identity drift被延後判定期間若命中前一句所述record漂移出口以外的既有fail-closed出口（例如receipt自身的generation不符、stable或runtime path的形狀不合法），MUST以該既有出口回報，identity drift不另行輸出，診斷亦 MUST NOT附上`--init-receipt`。identity drift的`--init-receipt`指引 MUST只在最終確定回報identity drift時才設定，MUST NOT在延後判定開始時預先設定，否則延後期間命中的其他出口會帶著無限定的指引輸出。沿用既有出口的唯一例外是error code：launcher在receipt gate內對runtime records逐檔取digest時 MUST以`receipt_invalid`回報失敗，MUST NOT沿用該檔案開啟路徑預設的`bootstrap_invalid`——既有guidance對`bootstrap_invalid`的處置是無條件執行一次`--init-receipt`，讓延後判定擴大該出口會繞過本段的前提閘門。

identity drift的指引 SHALL在兩個gate採用同一組前提陳述，且 MUST NOT依賴任一gate對target版控狀態的查詢。指引 MUST內含版控前提，明白指出`.cash-skills/receipt.tsv`是machine-local identity、它被納入版控時 MUST先解除追蹤再重新簽發。指引 MUST NOT把「fresh clone」或任何取得方式陳述為無條件可以重新簽發的理由。理由有二：`Target 版控排除保護` requirement所守護的情境——receipt被誤納入版控後在別台機器clone——正好落在digest相符而inode不符的identity drift，而該requirement明白指名的執行面是launcher；launcher無法在不新增每次啟動一次版控查詢的前提下判定該狀態，installer亦只有direct、registry與batch路徑執行該查詢，`--vendor`路徑不執行。把限定寫進指引文字而非寫成查詢分支，使該限定在兩個gate的全部路徑一致生效，且不改變任何既有查詢的唯讀性、靜默略過與不影響分類的契約。

兩個gate的指引措辭 MUST各自指向正確的執行位置：launcher在target內執行，指引 MUST指向該專案根；installer從source repository對另一個target執行，其診斷 MUST由訊息自身在指令以外的散文部分指名該target的resolved絕對路徑，使指令中交代執行位置的措辭有明確指涉；指令字串本身 MUST只含project-relative path，MUST NOT內嵌target的絕對路徑，因為內嵌會使含空白或shell metacharacter的路徑產生無法直接貼上執行的指令。該訊息 MUST NOT自加以target路徑起頭的前綴：批次模式已由呼叫端加上該前綴而訊息自帶會重複，direct與vendor模式則不帶任何前綴而必須由訊息散文承擔指名責任。指引 MUST NOT讓使用者誤以為應在目前所在的repository執行。

launcher既有的source-repository提示 MUST優先於identity drift提示；launcher已因偵測到source layout而設定提示時，MUST NOT以identity drift提示覆寫它。

兩個gate MUST NOT在identity drift時自動重新簽發或rebind receipt。`Target 版控排除保護` requirement的鑑別力在device不再參與比對後僅由`st_ino`承擔，自動rebind會靜默移除該保護；重新簽發 MUST維持為使用者主動的明示動作。

本requirement只適用於manifest缺失的receipt-based target。Portable manifest依 `Portable manifest 啟動信任模式` requirement不記錄`st_dev`或`st_ino`，manifest-present target不受本requirement影響。

#### Scenario: Volume 重新編號後 launcher 仍通過 gate

- **GIVEN** 一個manifest缺失的receipt-based target，其receipt的兩筆stable records的digest、mode與`st_ino`皆與現地相符
- **AND** 兩筆records記錄的`st_dev`因volume重新掛載而不等於現地觀察值
- **WHEN** 執行 `.cash-skills/bin/cash list --json`
- **THEN** launcher通過receipt gate並正常執行command
- **AND** launcher不以 `receipt_invalid` 失敗

#### Scenario: Volume 重新編號後 installer preflight 仍通過

- **GIVEN** 同一個target與同一份receipt
- **WHEN** 從source repository對該target執行installer的direct或vendor模式
- **THEN** preflight不以stable receipt drift失敗
- **AND** 安裝或遷移依既有分類正常完成

#### Scenario: Content drift 不被引導重新簽發

- **GIVEN** target的 `.cash-skills/bin/cash` bytes與receipt記錄的digest不符
- **WHEN** 執行任一Cash command或installer preflight
- **THEN** gate以content drift失敗並指名該path
- **AND** 診斷不包含`--init-receipt`

#### Scenario: Identity drift 提供可執行復原指令

- **GIVEN** target的兩筆stable records digest與mode皆相符，但其中一筆的`st_ino`與記錄值不符
- **AND** 該receipt在該gate前提範圍內的其餘records皆相符
- **WHEN** 執行任一Cash command或installer preflight
- **THEN** gate以identity drift失敗並指名該path
- **AND** 診斷包含執行`--init-receipt`的完整指令

#### Scenario: 指引一律內含版控前提且不背書任何取得方式

- **GIVEN** 任一gate、任一路徑輸出identity drift的`--init-receipt`指引
- **WHEN** 檢視該指引文字
- **THEN** 文字指出`.cash-skills/receipt.tsv`是machine-local identity、被納入版控時須先解除追蹤再重新簽發
- **AND** 文字不把fresh clone或任何取得方式陳述為無條件可以重新簽發的理由
- **AND** 該文字不依賴任何對target版控狀態的查詢，因此在`--vendor`路徑上與direct路徑上一致

#### Scenario: Mode 漂移歸入 identity drift

- **GIVEN** target的某筆stable path其bytes與receipt記錄的digest相符，但mode與記錄值不符
- **WHEN** installer評估該target
- **THEN** gate判為identity drift而非content drift
- **AND** 診斷指引與 `Target-local receipt 初始化` requirement的mode正規化行為一致

#### Scenario: Content 與 identity 同時漂移時判為 content drift

- **GIVEN** 同一筆stable record的digest與`st_ino`都與記錄值不符
- **WHEN** 執行任一Cash command或installer preflight
- **THEN** gate判為content drift
- **AND** 診斷不包含`--init-receipt`

#### Scenario: 其餘 records 同時漂移時改報該漂移並給出下一步

- **GIVEN** target的某筆stable record出現identity drift
- **AND** 同一份receipt的某筆runtime record的digest與現地不符
- **WHEN** 執行任一Cash command或installer preflight
- **THEN** gate回報該runtime漂移
- **AND** 診斷同時指名該stable path與該runtime path
- **AND** 診斷不包含`--init-receipt`，並指出可行的下一步是還原該record或從可信source重新安裝

#### Scenario: 延後判定期間命中既有出口時以該出口回報

- **GIVEN** target的某筆stable record出現identity drift
- **AND** 同一份receipt的某筆runtime record所在路徑為hard link，其mode仍為`0644`因而通過mode比對後才在開檔階段失敗
- **WHEN** launcher執行receipt gate
- **THEN** launcher以`receipt_invalid`回報該runtime record的失敗
- **AND** launcher不因延後判定而改以`bootstrap_invalid`結束
- **AND** 診斷不包含`--init-receipt`

#### Scenario: Installer 的指引指向目標專案而非來源專案

- **GIVEN** 從source repository對另一個target執行installer且該target出現identity drift
- **WHEN** installer輸出診斷
- **THEN** 診斷在指令以外的散文部分指名該target的resolved絕對路徑
- **AND** 指令字串本身不含該絕對路徑
- **AND** 診斷不自加以target路徑起頭的前綴
- **AND** 指引不指示使用者在source repository執行`--init-receipt`

#### Scenario: Source repository 提示優先於 identity drift 提示

- **GIVEN** launcher在canonical source repository執行且已偵測到source layout
- **WHEN** stable record出現identity drift
- **THEN** 診斷保留source-repository專屬提示
- **AND** 診斷不以identity drift提示覆寫它

#### Scenario: Negative device 的 receipt 在兩個 gate 皆 fail closed

- **GIVEN** receipt的某筆stable record其`st_dev`為負整數，其餘欄位與現地相符
- **WHEN** 執行任一Cash command或installer preflight
- **THEN** 兩個gate都以既有的invalid-receipt路徑fail closed
- **AND** 該record不因`st_dev`已不參與identity比對而被接受

#### Scenario: 未修復的 target 不因 identity drift 被自動改寫

- **GIVEN** target出現stable record identity drift
- **AND** target沒有未完成的installer journal
- **WHEN** installer評估該target
- **THEN** installer在為本次安裝取得exclusive lock之前即以identity drift失敗
- **AND** 該target的receipt bytes不被本次執行改寫

## MODIFIED Requirements

### Requirement: Bundle 安裝與 runtime receipt

本 requirement的receipt publication與receipt-based direct／registry／batch語意適用於manifest缺失的target；manifest-present launcher、`--vendor`、source-only `--self`及approved launcher replacement分別由 `Portable manifest 啟動信任模式`、`Repo-vendored Cash bundle 發佈`與 `受控 launcher bootstrap migration` requirements治理。這些具名情境以其較窄契約優先，其餘既有receipt schema、inventory與fail-closed行為不變。Stable record的identity比對條件與其失敗診斷另由 `Stable receipt identity 比對條件與 gate 診斷` requirement治理，並以其較窄契約優先。

`install-cash-skills.fish` SHALL將stable launcher/lock、replaceable runtime generation、24個Cash skills與`.cash-skills/receipt.tsv`視為同一versioned inventory。`cash-skills.version` MUST恰含一個`MAJOR.MINOR.PATCH`值，三個分量各符合`0|[1-9][0-9]*`，不得含前導零、prerelease或build suffix。版本排序 MUST以每個digit string的長度再以lexical bytes比較任意長度分量，不得轉換為fixed-width integer或float。任何replaceable runtime/skill bytes或contract mode改變 MUST調升bundle version；相同版本 MUST綁定first-parent history中的引入commit，後續相同版本內容漂移 MUST使contract test失敗。Stable workspace-lock bytes不得隨bundle version改變；stable launcher bytes只有在bundle version嚴格調升且命中受控migration的exact transition時可改變，其他source drift MUST為execution error。

preflight MUST在任何target write前驗證Python 3.11+、source version及完整bootstrap/runtime/skill inventory、destination boundaries、legacy full-body digests、mode與config migration。direct、register與batch targets MUST各自是Git worktree top-level；non-Git或Git子目錄target MUST fail closed。target的`openspec/config.yaml`存在時 MUST為安全可讀、schema-valid的regular file；缺檔 MUST NOT fail closed。三種形態的判定順序 MUST為unsafe先於missing、missing先於invalid：symlink、非regular file或hard link MUST以execution error失敗，MUST NOT被視為missing而觸發建立；存在且安全的檔案才進schema驗證，invalid schema MUST在首次target write前以execution error失敗。unsafe與invalid兩種失敗 MUST NOT被`--force`繞過。形狀判定 MUST在任何open之前以no-follow `lstat` metadata完成，因為以read開啟FIFO會阻塞到出現writer為止；FIFO MUST以execution error失敗，MUST NOT阻塞。缺檔在三種target mode的後續處置不同：direct與batch mode MUST由config deployment在同一transaction內建立canonical baseline；`--register`只登錄專案而不執行安裝，因此 MUST接受缺檔的target並完成登錄，且 MUST NOT建立該檔。`runtime_generation` MUST為replaceable runtime records依project-relative UTF-8 path bytes排序後，每筆以`<path>\t<lowercase-sha256>\t<four-digit-mode>\n`構成canonical UTF-8 stream的lowercase SHA-256。receipt MUST先記錄bundle version與runtime generation，再依canonical inventory順序為stable launcher/lock及每個replaceable runtime/skill path恰記一筆project-relative path、lowercase SHA-256及mode；stable records另 MUST記錄target-specific decimal `st_dev/st_ino`。launcher與installer取得stable lock後 MUST以`fstat`依 `Stable receipt identity 比對條件與 gate 診斷` requirement定義的條件比對launcher/lock records、逐檔hash runtime records並重算generation，才可import runtime或分類current。invalid source version、generation或receipt的invalid version、欄位數、digest、mode、device/inode欄位形狀、identity比對不符、path、順序、duplicate、missing或unknown record MUST在首次write前以execution error失敗，不得分類為missing、current、newer或conflict。launcher MUST為`0755`，lock與其他新建runtime/skill files MUST為`0644`。可刪除legacy standard skill MUST逐byte匹配`scripts/cash-skills/legacy-spectra-digests.tsv`的已知baseline且mode為`0644`。無法證明為已知baseline者（同名customization、unknown version或mode drift）MUST被保留、MUST NOT被刪除或修改，且 MUST NOT阻斷安裝：installer MUST繼續發布其餘managed inventory，並在該target的輸出逐筆列出被保留的path。只有可能導致刪除逃逸target邊界的形狀——symlink、hard link或目錄含額外內容——MUST在首次write前fail closed。legacy receipt migration只驗證舊schema實際記載的path與digest，MUST NOT以舊schema未記載的mode作為migration gate；managed skill的mode由本次transaction依contract mode正規化。

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

- **GIVEN**target receipt包含invalid version、欄位數、digest、mode、device/inode欄位形狀、generation、path、順序、duplicate、missing或unknown record
- **AND**stable record的device值與現地觀察值不符不屬於本scenario
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

### Requirement: Target-local receipt 初始化

`cash_cli.installer` SHALL 提供 target-side 的 `--init-receipt` 模式，與 `--self`、`--target`、`--vendor`、`--register`、`--unregister`、`--list`、`--all`、`--force` 互斥，以在 target 專案根執行 `PYTHONPATH=.cash-skills/lib python3 -s -P -B -m cash_cli.installer --init-receipt` 的形式使用。此模式 MUST NOT 新增任何檔案到 bundle inventory、MUST NOT 改變 receipt 的 record 集合或 schema、MUST NOT 修改 `.cash-skills/bin/cash` 的任何 bytes。

`--init-receipt` MUST 依序：於 import 完成後檢查 Python 3.11+；驗證執行目錄為 canonical Git worktree top-level；以 launcher 的 source layout marker 集合（source-only 檔案、runtime core、24 個 canonical skill 的存在與 regular-file 形狀，加上可解析的 `cash-skills.version`）拒絕 canonical source repository 並在診斷中指向 `./install-cash-skills.fish --self`，該判定 MUST NOT 以 contract mode 相等為條件，因為這些 marker 都不在 mode 正規化涵蓋的 managed inventory 內，mode 相等的判定會使 umask 偏移的 source clone 被誤判為一般 target；source判定完成後以no-follow `lstat`檢查portable manifest path，非source target只要該path存在（包含unsafe shape）就 MUST以`init_vendored_bundle`fail closed且不得讀取或修改receipt；驗證 `openspec/config.yaml` 安全可讀且 schema-valid（缺檔、unsafe 或 invalid 皆 fail closed，MUST NOT 建立任何檔案）；確認 `.cash-workspace.lock` 為既存且為空的 regular file（缺失或非空皆 fail closed，MUST NOT 建立或修復 stable 檔案）並取得 exclusive flock 全程持有；取得exclusive flock後 MUST再次以no-follow `lstat`重驗portable manifest path仍缺失，若它由missing變為任何present shape，MUST在mode正規化、inventory open或receipt publication前以`init_vendored_bundle`fail closed；檢核 runtime inventory 完整性；再以 no-follow `lstat` 確認 managed inventory 逐檔為 regular file 後，將其 mode 正規化為 contract modes（launcher `0755`、其餘 `0644`），非 regular file 形狀 MUST fail closed 且不 chmod。runtime 完整性檢核 MUST 先於 mode 正規化，使 runtime 集合不符時零 `chmod`。任一檢核失敗 MUST 以具名 error code（`init_python_version`、`init_outside_worktree`、`init_source_repo`、`init_vendored_bundle`、`init_config_invalid`、`init_inventory_invalid`、`init_write_failed`）與統一 JSON 錯誤 shape 輸出到 stdout 並以 exit 1 結束，且零檔案內容寫入；mode 正規化的 `chmod` 是唯一允許的 metadata 修改。持有 exclusive flock 之後對 target 檔案的每一次開檔 MUST 先以 `lstat` 判定形狀，`.cash-skills/receipt.tsv` 本身為 FIFO 等非 regular file 時 MUST 以 `init_write_failed` fail closed 而非阻塞在開檔。

簽發時，`--init-receipt` MUST 從現地 bytes 計算 digests、以本機 no-follow `lstat` 產生 stable identity，組出與 installer 安裝路徑相同 schema 的 receipt：`version` 值取自 installer module 內嵌的 `BUNDLE_VERSION` 常數，record 集合與現行 inventory 完全相同。寫入 MUST 沿用 same-directory owned temporary 與 atomic rename，`.cash-skills` 非 regular directory 時 MUST fail closed。既有 receipt 的 bytes 與 contract mode `0644` 都與重算結果一致時 MUST 回報 `current` 且零寫入；bytes 一致但 mode 已漂移時 MUST 走一般簽發路徑重寫並回報 `initialized`，因為 launcher 對 receipt 有 `0644` 的 mode 閘門，回報 `current` 會留下「成功卻不可用」的狀態。成功簽發回報 `initialized`，兩者皆輸出單行到 stdout 並以 exit 0 結束。簽發的信任根是 git clone 的現地內容：`--init-receipt` 是使用者主動的明示動作，launcher MUST NOT 在 receipt 缺失或無效時自動觸發它。

inventory 完整性檢核 MUST 以獨立於現地觀察狀態的期望集合進行。stable 與 24 個 canonical skill 的期望路徑為常數推導；runtime 的期望路徑 MUST 取自 installer module 內嵌的 `BUNDLE_RUNTIME_PATHS` 常數，MUST NOT 以現地 `rglob` 枚舉結果作為自身的期望集合——那會使比對恆真、缺檔與多檔皆不被偵測，並簽發一份自洽但錯的 receipt。現地 runtime 集合與 `BUNDLE_RUNTIME_PATHS` 不相等時 MUST 以 `init_inventory_invalid` fail closed，診斷 MUST 同時列出 missing 與 extra 兩個差集。

`cash_cli.installer` 的 import-time 相依（`installer.py` 自身、它的 `from .config import`，以及 `cash_cli/__init__.py` → `main.py` → `errors.py` 的匯入鏈，共 4 個；`cash_cli/__init__.py` 本身因 PEP 420 namespace package fallback 不屬此類）缺席時，`-m` 載入在任何檢核之前就以未捕捉的 `ModuleNotFoundError` 失敗，因此 MUST NOT 期待具名 error code；此限制與舊直譯器的 `SyntaxError` 屬同一類（import 先於任何檢查），已於 proposal Non-Goals 載明。`CASH-INIT-RECEIPT.md` MUST 明載哪些模組屬此類，且 MUST NOT 把它們列為 `init_inventory_invalid` 對照表的適用對象。

`BUNDLE_VERSION` 常數 MUST 由 contract test 斷言恆等於 `cash-skills.version` 的檔案內容；`BUNDLE_RUNTIME_PATHS` 常數 MUST 由 contract test 斷言恆等於 source 端 `source_inventory` 推導出的 runtime 路徑集合。

source repository 的 `AGENTS.md` 與 `CLAUDE.md` Cash guidance 區塊 MUST 各含信任模式分流：manifest存在時直接使用portable mode且不得執行`--init-receipt`；只有manifest缺失的receipt-based target在receipt缺失出現`bootstrap_invalid`、或在stable record identity drift出現`receipt_invalid`時才提供完整初始化指令，且該分流 MUST同時載明stable record content drift不得以重新簽發處理、以及`.cash-skills/receipt.tsv`被納入版控時 MUST先解除追蹤再重新簽發。該分流 MUST NOT把fresh clone或任何取得方式陳述為無條件可以重新簽發的理由。該分流 MUST進一步限定identity drift這個入口只在診斷「僅」指名該stable record時適用；診斷同時指名`runtime`或`skill` record drift時 MUST改為指示還原該record或從可信source重新安裝，MUST NOT指示重新簽發。此限定不可省略，理由是前提不成立時的診斷逐字以identity drift的分類字串起頭，因此以字串比對套用該分流的讀者會在 `Stable receipt identity 比對條件與 gate 診斷` requirement的前提閘門正要擋下的情境執行重新簽發，把已漂移的runtime或skill內容簽為合法。既有guidance部署 MUST把該分流帶到每個target的managed block；target端的發現管道由此承擔，MUST NOT依賴source-only檔案（如`CASH-SKILLS.md`）作為target端引導。

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
- **AND** manifest-present target不被要求初始化，manifest缺失的receipt-based target在 `bootstrap_invalid` 與stable record identity drift的 `receipt_invalid` 兩個情境下都可由該指引得知初始化指令
- **AND** 該指引載明stable record content drift不得以重新簽發處理
- **AND** 該指引載明receipt被納入版控時須先解除追蹤再重新簽發，且不把任何取得方式陳述為無條件可以重新簽發的理由

#### Scenario: 前提不成立的診斷不被指引為重新簽發

- **GIVEN** 一個manifest缺失的receipt-based target，其某筆stable record出現identity drift
- **AND** 同一份receipt的某筆runtime或skill record同時漂移，因此gate輸出的是前提不成立的第三支診斷
- **WHEN** 讀者依 `AGENTS.md` 或 `CLAUDE.md` managed guidance block的信任模式分流判斷下一步
- **THEN** 該分流指出identity drift的初始化入口只在診斷僅指名該stable record時適用
- **AND** 該分流對同時指名`runtime`或`skill` record drift的診斷指示還原該record或從可信source重新安裝
- **AND** 該分流不指示對該診斷執行`--init-receipt`

#### Scenario: Inventory 未擴充使既有 targets 正常升級

- **GIVEN** 既有 registry targets 持有前一版本簽發的 receipt
- **WHEN** 新版本以 `--all` 部署
- **THEN** 每個 target 的既有 receipt 以相同 record 集合正常解析並走 update 路徑
- **AND** 沒有 target 因 record 集合不符而以 execution error 失敗

### Requirement: Target 版控排除保護

Installer 的direct、registry與batch模式 SHALL在preflight通過後、於同一transaction內確保target根目錄的`.gitignore`含有`.cash-skills/receipt.tsv`、`.cash-skills/state/`與`__pycache__/`三項規則。此保護存在的理由是receipt依既有contract記錄target-specific `st_ino`，一旦被納入版控，任何inode不同的取得方式都會使該target的launcher以`receipt_invalid` fail closed。receipt同時記錄的`st_dev`依 `Stable receipt identity 比對條件與 gate 診斷` requirement不參與比對，因此本保護的鑑別力 MUST僅由`st_ino`承擔，該requirement的識別與診斷契約以其較窄契約優先。installer為此輸出的version-control diagnostic MUST NOT把device描述為fail-closed的成因。source-only `--self`不在本requirement範圍內。

判定 MUST在byte層進行：以`b"\n"`切行並逐行比對bytes，MUST NOT要求UTF-8。比對 MUST容忍行尾的`\r`，使CRLF檔案中的既有規則被正確辨識。判定 MUST為逐行精確比對，MUST NOT以前綴、萬用字元或路徑包含關係推論既有規則已涵蓋。

缺少的規則 MUST只附加至檔案尾端，附加時 MUST沿用檔案既有的行終止符；既有內容不含任何行終止符時 MUST使用`\n`；既有內容 MUST逐byte保留，MUST NOT重排、去重或刪除任何既有行。既有內容非空且未以行終止符結尾時 MUST先補一個行終止符再附加，此為逐byte保留的唯一例外；既有內容為空時 MUST NOT補行終止符。

`.gitignore`不存在時 MUST以`0644`建立並納入同一transaction；既有檔案的mode MUST保留。既有檔案為symlink、非regular file、hard link或無法安全讀取時 MUST在首次target write前以execution error失敗，且`--force` MUST NOT繞過。

`.gitignore` MUST納入installer的installation inputs：判定與寫入內容 MUST由同一份no-follow snapshot導出，該snapshot MUST納入post-lock與publication前的revalidation。post-lock revalidation不一致時 MUST重新分類；publication前revalidation不一致時 MUST以execution error fail closed。兩者皆 MUST NOT覆寫外部修改。

分類為`newer`或`conflict`的target MUST維持既有零寫入契約，本保護 MUST NOT對其寫入。三項規則皆已存在時該項目 MUST零寫入。`--dry-run` MUST執行相同判定與驗證並零寫入。transaction失敗時，新建或附加的`.gitignore` MUST依既有rollback契約還原。

Installer MUST以唯讀version-control index查詢偵測target的`.cash-skills/receipt.tsv`是否已被納入版控，MUST NOT以ignore查詢判定——本requirement生效後所有target的`.gitignore`都會命中該規則，ignore查詢對已追蹤檔案會給出相反答案。為真時 MUST輸出指出該狀態與建議動作的diagnostic至stderr，且 MUST NOT依target的結果分類決定是否輸出。查詢失敗時 MUST靜默略過該diagnostic。此diagnostic MUST NOT修改使用者的版控索引，且 MUST NOT改變target的結果分類或exit code。

#### Scenario: 全新 target 取得三項排除規則

- **GIVEN** target沒有`.gitignore`
- **WHEN** installer完成部署
- **THEN** `.gitignore`以`0644`建立且含`.cash-skills/receipt.tsv`、`.cash-skills/state/`與`__pycache__/`
- **AND** receipt不會被版控收錄

#### Scenario: 既有內容逐 byte 保留

- **GIVEN** target的`.gitignore`含使用者自訂規則且缺少其中一項所需規則
- **WHEN** installer完成部署
- **THEN** 既有內容逐byte不變且mode保留
- **AND** 只在檔案尾端多出缺少的那一項規則

#### Scenario: 既有內容無尾端行終止符

- **GIVEN** target的`.gitignore`以`node_modules`結尾且該行沒有行終止符
- **WHEN** installer附加缺少的規則
- **THEN** `node_modules`仍為完整且獨立的一行
- **AND** 附加的規則各自成行，不與既有內容黏連

#### Scenario: 規則齊備時零寫入

- **GIVEN** target的`.gitignore`已含全部三項規則且其餘managed inventory無變更
- **WHEN** installer執行
- **THEN** `.gitignore`零寫入
- **AND** target回報`current`

#### Scenario: 不安全的 .gitignore fail closed

- **WHEN** target的`.gitignore`為symlink、非regular file、hard link或無法安全讀取
- **THEN** installer在首次target write前以execution error失敗
- **AND** 帶`--force`同樣失敗且零寫入

#### Scenario: 編碼與行終止符不影響分類

- **GIVEN** target的`.gitignore`為CRLF或含非UTF-8的pathname bytes
- **WHEN** installer執行
- **THEN** 既有規則被正確判定
- **AND** target不因編碼或行終止符被分類為`failed`

#### Scenario: 兩個檢查點的外部修改處置

- **GIVEN** installer取得lock後、組裝transaction前有外部程序修改了target的`.gitignore`
- **WHEN** post-lock revalidation執行
- **THEN** installer重新分類該target
- **AND** 外部修改不被覆寫

- **GIVEN** installer組裝transaction後、publication前有外部程序修改了target的`.gitignore`
- **WHEN** publication前revalidation執行
- **THEN** installer以execution error fail closed
- **AND** 外部修改不被覆寫

#### Scenario: 已納入版控的 receipt 只回報不修改

- **GIVEN** target的`.cash-skills/receipt.tsv`已被納入版控
- **WHEN** installer執行
- **THEN** stderr輸出指出該狀態與建議動作的diagnostic
- **AND** 該diagnostic以inode而非device描述fail-closed的成因
- **AND** 使用者的版控索引維持不變
- **AND** target的結果分類與exit code不因此改變

##### Example: 規則判定

| 既有行 | 對`.cash-skills/state/`的判定 |
| --- | --- |
| `.cash-skills/state/` | 已滿足 |
| `.cash-skills/state/` 後接 `\r` | 已滿足 |
| `.cash-skills/` | 不視為已滿足 |
| `.cash-skills/state` | 不視為已滿足 |
| `/.cash-skills/state/` | 不視為已滿足 |
| `*.tsv` | 不視為已滿足 |
