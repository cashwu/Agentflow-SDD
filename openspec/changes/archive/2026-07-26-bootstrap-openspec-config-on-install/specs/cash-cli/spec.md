## MODIFIED Requirements

### Requirement: Bundle 安裝與 runtime receipt

`install-cash-skills.fish` SHALL將stable launcher/lock、replaceable runtime generation、24個Cash skills與`.cash-skills/receipt.tsv`視為同一versioned inventory。`cash-skills.version` MUST恰含一個`MAJOR.MINOR.PATCH`值，三個分量各符合`0|[1-9][0-9]*`，不得含前導零、prerelease或build suffix。版本排序 MUST以每個digit string的長度再以lexical bytes比較任意長度分量，不得轉換為fixed-width integer或float。任何replaceable runtime/skill bytes或contract mode改變 MUST調升bundle version；相同版本 MUST綁定first-parent history中的引入commit，後續相同版本內容漂移 MUST使contract test失敗。Stable bootstrap bytes不得隨一般bundle version改變，source drift MUST為execution error。

preflight MUST在任何target write前驗證Python 3.11+、source version及完整bootstrap/runtime/skill inventory、destination boundaries、legacy full-body digests、mode與config migration。direct、register與batch targets MUST各自是Git worktree top-level；non-Git或Git子目錄target MUST fail closed。target的`openspec/config.yaml`存在時 MUST為安全可讀、schema-valid的regular file；缺檔 MUST NOT fail closed。三種形態的判定順序 MUST為unsafe先於missing、missing先於invalid：symlink、非regular file或hard link MUST以execution error失敗，MUST NOT被視為missing而觸發建立；存在且安全的檔案才進schema驗證，invalid schema MUST在首次target write前以execution error失敗。unsafe與invalid兩種失敗 MUST NOT被`--force`繞過。形狀判定 MUST在任何open之前以no-follow `lstat` metadata完成，因為以read開啟FIFO會阻塞到出現writer為止；FIFO MUST以execution error失敗，MUST NOT阻塞。缺檔在三種target mode的後續處置不同：direct與batch mode MUST由config deployment在同一transaction內建立canonical baseline；`--register`只登錄專案而不執行安裝，因此 MUST接受缺檔的target並完成登錄，且 MUST NOT建立該檔。`runtime_generation` MUST為replaceable runtime records依project-relative UTF-8 path bytes排序後，每筆以`<path>\t<lowercase-sha256>\t<four-digit-mode>\n`構成canonical UTF-8 stream的lowercase SHA-256。receipt MUST先記錄bundle version與runtime generation，再依canonical inventory順序為stable launcher/lock及每個replaceable runtime/skill path恰記一筆project-relative path、lowercase SHA-256及mode；stable records另 MUST記錄target-specific decimal `st_dev/st_ino`。launcher與installer取得stable lock後 MUST以`fstat`比對launcher/lock records、逐檔hash runtime records並重算generation，才可import runtime或分類current。invalid source version、generation或receipt的invalid version、欄位數、digest、mode、device/inode、path、順序、duplicate、missing或unknown record MUST在首次write前以execution error失敗，不得分類為missing、current、newer或conflict。launcher MUST為`0755`，lock與其他新建runtime/skill files MUST為`0644`。可刪除legacy standard skill MUST逐byte匹配`scripts/cash-skills/legacy-spectra-digests.tsv`的已知baseline且mode為`0644`。無法證明為已知baseline者（同名customization、unknown version或mode drift）MUST被保留、MUST NOT被刪除或修改，且 MUST NOT阻斷安裝：installer MUST繼續發布其餘managed inventory，並在該target的輸出逐筆列出被保留的path。只有可能導致刪除逃逸target邊界的形狀——symlink、hard link或目錄含額外內容——MUST在首次write前fail closed。legacy receipt migration只驗證舊schema實際記載的path與digest，MUST NOT以舊schema未記載的mode作為migration gate；managed skill的mode由本次transaction依contract mode正規化。

Fresh、legacy adoption與known-old migration MUST使用monotonic bootstrap。read-only preflight後，installer以`O_CREAT|O_EXCL`建立project-root lock、立即取得exclusive lock，並以`fstat`與pathname no-follow lookup重驗相同device/inode；遇到`EEXIST`的並發installer MUST開啟現存lock、等待exclusive lock、重驗pathname/FD identity後重新分類。Stable lock一旦建立 MUST NOT unlink或rename；stable launcher一旦atomic發佈亦 MUST NOT unlink或rename。failure只回滾replaceable runtime、skills、config、guidance、target版控排除設定與receipt，保留canonical `lock-only`或`lock+launcher` prefix；下一次installer MUST在同一lock inode上恢復。launcher-without-lock、bootstrap drift、unknown partial state或pathname/FD mismatch MUST fail closed。Existing current/upgrade/force/batch MUST持有同一FD到transaction/rollback完成。新receipt MUST最後發佈並從target `fstat`產生stable identity records。Journal recovery會改變target state，因此installer MUST在recovery之後才定案installation inputs的target snapshot、legacy candidate plan與版控排除設定plan；Journal的存在偵測 MUST在read-only preflight內完成且 MUST早於版本比較的`newer` early return；該偵測 MUST為純讀取，MUST NOT持鎖，也 MUST NOT解讀target config，並 MUST以no-follow的`lstat`判定形狀——`JOURNAL_PATH`非regular file（含symlink）時 MUST以execution error fail closed，MUST NOT靜默視為無journal。恢復 MUST緊接在`newer` early return之後，且 MUST早於全部三個提前返回的分類分支：`legacy receipt drift`、`receipt-less Cash skill inventory is partial`與`managed target drift`；未完成journal存在時，installer MUST NOT先以其中任何一個返回而略過恢復，即使半發布bytes落在receipt-managed path亦然，且該恢復 MUST NOT要求`--force`。journal的schema version不被本bundle辨識時 MUST以execution error fail closed，且diagnostic MUST指出需要版本相符或更新的installer；`newer`排除的判準是receipt版本，而receipt是transaction的最後一筆operation，因此較新bundle在publishing階段的崩潰不會被`newer`排除，跨版本journal MUST由此條而非`newer`排除來處理。被分類為`newer`的target MUST維持零寫入返回且 MUST NOT執行recovery，其journal留待版本相符或更新的installer處理。非dry-run、target未分類為`newer`且偵測到journal時，installer MUST先執行既有的launcher-without-lock檢查，再取得既存stable lock後才執行recovery；該次取鎖 MUST NOT建立不存在的lock，journal存在而stable lock不存在 MUST fail closed，MUST NOT以`O_CREAT|O_EXCL`建立新的lock inode。recovery回傳真與回傳偽兩個分支 MUST都關閉lock descriptor，同一process在任一時刻 MUST至多持有一個stable lock descriptor。Journal recovery造成的rollback寫入 MUST NOT被視為違反`current`、`newer`或`conflict`分類的零寫入契約：該零寫入契約自recovery完成後的重新分類起適用，因此recovery之後若仍存在與該journal無關的drift，installer MUST回報`Result: conflict`、exit 2，且自重新分類起零寫入。當recovery實際處理並清除journal時，installer MUST釋放stable lock並依recovery後的state重新分類，MUST NOT因recovery自身造成的target變更而以publication前revalidation不一致為由fail closed；外部併發在取得lock之後修改target時，publication前revalidation的既有fail-closed契約 MUST維持不變。該重新分類 MUST在同一lock inode上恢復，且同一份journal MUST NOT再次觸發重新分類；釋放lock的時間窗內由外部併發產生的另一份journal可再觸發一次重新分類，屬既有併發語意。偵測到未完成journal時，installer MUST在早於`newer` early return的偵測點輸出一句與分類無關的通用diagnostic，僅陳述target存在未完成的journal；該句 MUST在dry-run與real run皆出現，且 MUST與最終分類無關而一律出現，包含`current`與`newer`。分類為`newer`時，installer MUST於`newer` early return之前另外輸出一句newer專屬補充，指出該journal需要版本相符或更新的installer才會恢復；該補充 MUST NOT併入通用句，因為通用句在版本比較之前發出，把newer專屬語意寫進去會對絕大多數會被本次執行恢復的target給出錯誤指引。`--dry-run` MUST NOT執行recovery並 MUST維持零寫入。

Receipt-less legacy adoption MUST在receipt與runtime缺失、stable prefix為absent、`lock-only`或`lock+launcher`，且24個canonical Cash skills全數為root-contained、non-symlink、single-link regular files、bytes與`0644` mode逐筆等於source時成立。installer SHALL保留skill bytes，並由monotonic bootstrap transaction補齊launcher、runtime、config/guidance與新receipt。零個skill是fresh；1至23個、任何byte/mode/identity不同或unknown Cash runtime partial state在未帶`--force`時 MUST conflict。Receipt-less完整新inventory則可在stable lock下依全部bytes/modes相符條件認養。

Known legacy receipt MUST嚴格限定為恰好25個LF-terminated records：第一筆`version<TAB><strict-MAJOR.MINOR.PATCH>`，其後依canonical 24-skill順序各一筆`sha256<TAB><lowercase-64-hex-digest><TAB><project-relative-path>`；它沒有mode、runtime、bootstrap或generation欄位。僅當receipt完整符合此schema、24個target skills逐筆相符且stable prefix absent或canonical recoverable時，installer才 SHALL執行one-time bootstrap migration。failure MUST回滾replaceable publications並還原old receipt，但 MUST保留已發布的stable lock/launcher；下一次direct或batch invocation MUST在相同lock inode恢復。old receipt drift、unknown/incomplete schema或bootstrap drift MUST fail closed。dry-run MUST使用同一判定、零寫入並回報would-update。

installer MUST先以incoming parser驗證source config，並在target config interpretation前先驗證target receipt/version/boundary；合法newer target MUST零寫入返回，且 MUST NOT由較舊incoming parser重新解讀target`.cash.yaml`。fresh、known-legacy、adoption、current與older target才使用incoming bundle parser。config deployment MUST採三分支：既有`.cash.yaml`視為project-owned，以該parser及no-follow snapshot驗證allowed keys、duplicates、types與syntax後逐byte保留，invalid existing config MUST在首次write前execution error；只有`.spectra.yaml`時 SHALL只接受uncommented `locale/tdd/audit/parallel_tasks`及optional `spec_dir: openspec`，任何其他active top-level/nested scalar、map、list或non-default`spec_dir` MUST fail closed；兩者皆不存在時 MUST先以同一parser驗證source canonical `.cash.yaml`，再逐byte複製baseline。installer MUST NOT刪除caller-owned`.spectra.yaml`。執行安裝的direct與batch mode在target的`openspec/config.yaml`不存在時，installer MUST以installer bundle內嵌的canonical baseline，在同一transaction內以`0644`建立該檔。該baseline MUST為LF結尾的UTF-8、首行為`schema: spec-driven`，其餘行 MUST只有blank line與full-line `#` comment，因此其parse結果的`context` MUST為空字串、`rules` MUST為空mapping；它 MUST先以同一`openspec/config.yaml` parser驗證通過才可寫入，且 MUST NOT在安裝時取自source repository的同名檔案，以免source專案自身的context或rules進入target。既有的`openspec/config.yaml` MUST逐byte保留並零寫入。缺檔時的建立 MUST優先於`current`分類的零寫入契約：其餘managed inventory一致但該檔缺失時，target MUST分類為`update`並建立該檔，MUST NOT分類為`current`。建立後該檔即為project-owned：後續安裝 MUST NOT覆寫或修復其內容，且它 MUST NOT進入receipt或managed inventory。installer MUST NOT建立`openspec/`下的其他目錄。成功transaction MUST最後才發佈receipt；failure MUST回滾新建config與先前receipt，或維持兩者absent；該回滾 MUST涵蓋新建的`openspec/config.yaml`，為它建立的`openspec/`目錄則可保留。

Installer SHALL提供source-only `--self [--dry-run]`模式。它 MUST從installer所在目錄解析唯一Git top-level，驗證canonical source version、stable launcher/lock、replaceable runtime generation、24個skills、`.cash.yaml`與`openspec/config.yaml`的no-follow identity、bytes及contract modes，並在既有stable lock的exclusive FD下分類或發布receipt。Real run MUST只以held receipt-parent FD與same-directory owned temporary原子建立或替換`.cash-skills/receipt.tsv`；receipt MUST使用一般target相同的version、generation、path/digest/mode與stable `st_dev/st_ino` schema。`--dry-run` MUST零寫入；current self receipt MUST零寫入。`--self` MUST NOT與`--target`、`--all`、`--register`、`--unregister`、`--list`或`--force`組合，MUST NOT發布或修改launcher、lock、runtime、skills、config、guidance或legacy內容。`--self` MUST NOT建立缺失的`openspec/config.yaml`；source repository缺少該檔 MUST以execution error失敗且零寫入。一般direct、registry與batch target modes仍 MUST拒絕source repository。已辨識source layout的launcher在receipt缺失時 MUST回報`bootstrap_invalid`，receipt存在但內容驗證失敗時 MUST回報`receipt_invalid`；兩者皆 MUST以exit 1失敗，JSON與non-JSON diagnostic都 MUST包含`./install-cash-skills.fish --self`，installed target diagnostic MUST NOT建議source-only指令。

#### Scenario: Fresh target 原子安裝

- **GIVEN**安全、是Git top-level、具有有效`openspec/config.yaml`且沒有Cash inventory/config的target
- **WHEN**執行installer
- **THEN**stable launcher/lock、runtime generation、24個skills、source canonical Cash config與receipt在同一transaction完成
- **AND**下一次相同版本安裝回報current且零寫入

#### Scenario: Source repository self bootstrap

- **GIVEN** canonical source repository缺少target-specific receipt，但stable lock、launcher、runtime、24個skills及configs安全且完整
- **WHEN** 執行`install-cash-skills.fish --self`
- **THEN** installer在existing lock inode的exclusive FD下只發布有效receipt並回報`Result: bootstrap`
- **AND** 後續source launcher可執行Cash commands，重複`--self`回報`Result: current`且零寫入

#### Scenario: Source self dry run 與模式互斥

- **WHEN** 執行`--self --dry-run`
- **THEN** installer執行相同preflight並回報`Result: would-bootstrap`或`Result: current`，但零寫入
- **WHEN** `--self`與target、batch、registry、list或force mode任一組合
- **THEN** installer以caller-input error失敗且零寫入

#### Scenario: Source launcher提供可行動診斷

- **GIVEN** 已辨識source layout且receipt缺失或無效
- **WHEN** 以JSON或non-JSON模式啟動launcher
- **THEN** launcher依receipt缺失或內容失效分別以`bootstrap_invalid`或`receipt_invalid`與exit 1失敗
- **AND** diagnostic指出從project root執行`./install-cash-skills.fish --self`

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
- **AND**stable launcher/lock source bytes改變時以unsupported bootstrap migration失敗而非一般version bump

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
- **AND**stable launcher與lock inode不變
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
