## ADDED Requirements

### Requirement: Installer fault-injection hooks 治理

Installer的fault-injection hooks SHALL只在單一顯式開關之下生效。該開關為環境變數`CASH_INSTALL_TEST_HOOKS`，其值恰為`1`時hooks生效。開關未設定或值不為`1`時，installer MUST NOT讀取任何其他`CASH_INSTALL_*`變數，且分類、發布、diagnostic與exit code MUST與這些變數皆不存在時完全相同。該開關是縮小blast radius的機制，MUST NOT被視為authorization boundary：能設定其他hook變數的caller一律也能設定它。

已啟用hooks的設定驗證——hold path形狀、兩個hold path互異、release檔當下不存在、失敗注入序號可解析性——MUST在任何`acquire_lock`呼叫之前的preflight完成，使這些設定錯誤在首次target write之前fail closed；hold的等待點 MUST維持在既有位置。有一類形狀在preflight無法判定：release檔在preflight之後、等待點進入之前才出現，或到等待點才被換成symlink；這類 MUST在該hook的等待點以execution error中止、MUST NOT被當成解除訊號、MUST NOT提交任何transaction operation，但因等待點在`acquire_lock`之後，這類 MUST NOT主張在首次target write之前失敗。Hold協定 MUST受與其他installer寫入相同等級的identity約束：hold path MUST為absolute path，其parent MUST為既存且非symlink的directory；ready檔 MUST以exclusive、no-follow的建立語意產生；release檔的不存在性 MUST在preflight與各hook自身的等待點進入時各驗證一次；等待點進入時已存在的release檔 MUST以execution error中止，MUST NOT被當成解除訊號。release檔 MUST只在其為非symlink的regular file時被視為解除訊號。既存檔案或symlink MUST fail closed，MUST NOT被覆寫、截斷或被跟隨。Hold path MUST NOT被強制收斂到target之內，因為它是caller自有的協調通道，寫入target會把協調狀態帶進被安裝的project。at-most-once的記帳鍵 MUST為hook本身而非hold path：`CASH_INSTALL_HOLD_FILE`與`CASH_INSTALL_PUBLICATION_HOLD_FILE`是兩個獨立的hook，各自記帳互不影響。兩個hook同時啟用時其hold path MUST互異，相同時 MUST在preflight以execution error fail closed；記帳獨立不足以讓兩者共用一條路徑，因為第二個hook進入等待點時必然同時撞上「ready檔已存在」與「release檔在等待點已存在」兩條fail-closed規則。每個hold hook在單一process內 MUST至多等待一次。該hook已等待過之後，同一process內任何後續的installation attempt——包含重新分類造成的重新進入，以及batch mode對後續target的安裝——MUST完全跳過該hook，包含其等待與preflight的全部hold檔存在性檢查；ready檔與release檔皆在免除範圍內，installer MUST NOT因本process前一輪建立或解除的hold檔而失敗。路徑形狀檢查 MUST NOT被免除。失敗注入序號無法解析為integer時 MUST以execution error失敗，MUST NOT以未捕捉例外離開process。`CASH_INSTALL_CRASH_AFTER_COMMIT` MUST自實作移除，且 MUST NOT在實作、測試或使用者文件中作為可生效的environment variable name被讀取或設定；本requirement與change artifacts對該名稱的敘述性引用不在此限。

#### Scenario: 開關關閉時 hooks 完全無效

- **GIVEN**所有其他`CASH_INSTALL_*`變數皆已設定為會改變行為的值
- **WHEN**`CASH_INSTALL_TEST_HOOKS`未設定或其值不為`1`
- **THEN**installer的分類、發布與exit code與這些變數皆不存在時完全相同
- **AND**installer MUST NOT建立任何hold或ready檔

#### Scenario: Preflight 可判定的 hold 設定錯誤 fail closed

- **GIVEN**hooks開關已開啟，且該hold hook在本次process尚未等待過
- **WHEN**hold path不是absolute path、其parent不存在或為symlink、ready檔已存在、release檔在preflight已存在，或兩個hook的hold path相同
- **THEN**installer在首次target write前以execution error失敗
- **AND**既有檔案內容與symlink目標 MUST NOT被寫入或被截斷

#### Scenario: 等待點才可判定的 hold 形狀在等待點中止

- **GIVEN**hooks開關已開啟、preflight已通過，且該hold hook在本次process尚未等待過
- **WHEN**ready檔在preflight之後、該hook的等待點進入之前才出現，或release檔在preflight當下不存在而於等待點進入之前才出現，或該後出現的release檔為symlink
- **THEN**installer在該hook的等待點以execution error中止，且該release檔 MUST NOT被當成解除訊號
- **AND**該次執行 MUST NOT提交任何transaction operation，既有檔案內容與symlink目標 MUST NOT被寫入或被截斷

#### Scenario: 後續 installation attempt 不因自身 hold 檔而失敗

- **GIVEN**hooks開關已開啟且hold hook已在本次process等待過一次
- **WHEN**installer因重新分類而重新進入，或batch mode繼續安裝下一個已註冊target
- **THEN**installer MUST NOT再次等待該hold
- **AND**MUST NOT因本process前一輪建立的ready檔或解除等待所用的release檔而以execution error失敗

#### Scenario: 兩個 hold hook 各自記帳

- **GIVEN**hooks開關已開啟，兩個hold hook皆已設定且設在互異的hold path
- **WHEN**`CASH_INSTALL_HOLD_FILE`的hook已在本次process等待過一次，而`CASH_INSTALL_PUBLICATION_HOLD_FILE`的hook尚未等待過
- **THEN**publication hook仍正常等待，MUST NOT因另一個hook已等待過而被略過

#### Scenario: 失敗注入序號無法解析

- **GIVEN**hooks開關已開啟
- **WHEN**失敗注入序號不是可解析為integer的值
- **THEN**installer在首次target write前以execution error失敗
- **AND**MUST NOT以未捕捉例外離開process

### Requirement: Installer 進入點 interpreter 解析與 process 邊界

`install-cash-skills.fish` SHALL以自身已解析的absolute path決定source root，並SHALL選用候選清單中第一個通過最低版本探測的interpreter。候選清單 MUST依序為泛用名稱`python3`、`python`，其後才是版本化名稱`python3.14`、`python3.13`、`python3.12`、`python3.11`，使系統預設interpreter版本過舊但已安裝合格版本化interpreter的環境仍可安裝。泛用名稱 MUST排在版本化名稱之前：版本化名稱優先會改變既有可用環境的選擇結果，繞過該環境的toolchain shim，而本requirement只要求在泛用名稱不合格時提供備援。候選清單中沒有任何interpreter通過探測時 MUST以execution error失敗且零寫入。進入點 MUST以`exec`交棒給選定的interpreter，因此installer的Python process MUST NOT保留由該進入點建立的shell parent process，且Python process的exit status MUST直接成為該次invocation的exit status。交棒 MUST停用user site directory，MUST維持既有的library path注入與cwd隔離，且進入點 MUST NOT保留未被讀取的變數。

#### Scenario: 系統預設 interpreter 過舊但存在合格版本化 interpreter

- **GIVEN**泛用名稱`python3`與`python`皆解析到低於3.11的interpreter或不存在，而版本化名稱`python3.12`存在且滿足最低版本
- **WHEN**執行進入點
- **THEN**進入點選用`python3.12`並完成該次invocation
- **AND**MUST NOT以找不到合格interpreter為由失敗

#### Scenario: 泛用名稱合格時選擇結果不改變

- **GIVEN**泛用名稱`python3`解析到滿足最低版本的interpreter，且另有版本更新的版本化名稱可用
- **WHEN**執行進入點
- **THEN**進入點選用`python3`解析到的interpreter
- **AND**MUST NOT因存在版本更新的版本化名稱而改選它

#### Scenario: 無合格 interpreter

- **WHEN**候選清單中沒有任何interpreter通過最低版本探測
- **THEN**進入點以execution error失敗且零寫入

#### Scenario: 交棒不保留 shell parent 且停用 user site

- **WHEN**進入點交棒給選定的interpreter
- **THEN**installer的Python process的parent MUST為啟動該進入點的process，而非進入點自身
- **AND**該Python process MUST以停用user site directory的方式啟動，且既有library path注入 MUST仍然生效

## MODIFIED Requirements

### Requirement: Bundle 安裝與 runtime receipt

`install-cash-skills.fish` SHALL將stable launcher/lock、replaceable runtime generation、24個Cash skills與`.cash-skills/receipt.tsv`視為同一versioned inventory。`cash-skills.version` MUST恰含一個`MAJOR.MINOR.PATCH`值，三個分量各符合`0|[1-9][0-9]*`，不得含前導零、prerelease或build suffix。版本排序 MUST以每個digit string的長度再以lexical bytes比較任意長度分量，不得轉換為fixed-width integer或float。任何replaceable runtime/skill bytes或contract mode改變 MUST調升bundle version；相同版本 MUST綁定first-parent history中的引入commit，後續相同版本內容漂移 MUST使contract test失敗。Stable bootstrap bytes不得隨一般bundle version改變，source drift MUST為execution error。

preflight MUST在任何target write前驗證Python 3.11+、source version及完整bootstrap/runtime/skill inventory、destination boundaries、legacy full-body digests、mode與config migration。direct、register與batch targets MUST各自是Git worktree top-level，且 MUST已有安全可讀、schema-valid的regular `openspec/config.yaml`；non-Git、Git子目錄target或missing/unsafe config MUST fail closed。`runtime_generation` MUST為replaceable runtime records依project-relative UTF-8 path bytes排序後，每筆以`<path>\t<lowercase-sha256>\t<four-digit-mode>\n`構成canonical UTF-8 stream的lowercase SHA-256。receipt MUST先記錄bundle version與runtime generation，再依canonical inventory順序為stable launcher/lock及每個replaceable runtime/skill path恰記一筆project-relative path、lowercase SHA-256及mode；stable records另 MUST記錄target-specific decimal `st_dev/st_ino`。launcher與installer取得stable lock後 MUST以`fstat`比對launcher/lock records、逐檔hash runtime records並重算generation，才可import runtime或分類current。invalid source version、generation或receipt的invalid version、欄位數、digest、mode、device/inode、path、順序、duplicate、missing或unknown record MUST在首次write前以execution error失敗，不得分類為missing、current、newer或conflict。launcher MUST為`0755`，lock與其他新建runtime/skill files MUST為`0644`。可刪除legacy standard skill MUST逐byte匹配`scripts/cash-skills/legacy-spectra-digests.tsv`的已知baseline且mode為`0644`。無法證明為已知baseline者（同名customization、unknown version或mode drift）MUST被保留、MUST NOT被刪除或修改，且 MUST NOT阻斷安裝：installer MUST繼續發布其餘managed inventory，並在該target的輸出逐筆列出被保留的path。只有可能導致刪除逃逸target邊界的形狀——symlink、hard link或目錄含額外內容——MUST在首次write前fail closed。legacy receipt migration只驗證舊schema實際記載的path與digest，MUST NOT以舊schema未記載的mode作為migration gate；managed skill的mode由本次transaction依contract mode正規化。

Fresh、legacy adoption與known-old migration MUST使用monotonic bootstrap。read-only preflight後，installer以`O_CREAT|O_EXCL`建立project-root lock、立即取得exclusive lock，並以`fstat`與pathname no-follow lookup重驗相同device/inode；遇到`EEXIST`的並發installer MUST開啟現存lock、等待exclusive lock、重驗pathname/FD identity後重新分類。Stable lock一旦建立 MUST NOT unlink或rename；stable launcher一旦atomic發佈亦 MUST NOT unlink或rename。failure只回滾replaceable runtime、skills、config、guidance、target版控排除設定與receipt，保留canonical `lock-only`或`lock+launcher` prefix；下一次installer MUST在同一lock inode上恢復。launcher-without-lock、bootstrap drift、unknown partial state或pathname/FD mismatch MUST fail closed。Existing current/upgrade/force/batch MUST持有同一FD到transaction/rollback完成。新receipt MUST最後發佈並從target `fstat`產生stable identity records。Journal recovery會改變target state，因此installer MUST在recovery之後才定案installation inputs的target snapshot、legacy candidate plan與版控排除設定plan；Journal的存在偵測 MUST在read-only preflight內完成且 MUST早於版本比較的`newer` early return；該偵測 MUST為純讀取，MUST NOT持鎖，也 MUST NOT解讀target config，並 MUST以no-follow的`lstat`判定形狀——`JOURNAL_PATH`非regular file（含symlink）時 MUST以execution error fail closed，MUST NOT靜默視為無journal。恢復 MUST緊接在`newer` early return之後，且 MUST早於全部三個提前返回的分類分支：`legacy receipt drift`、`receipt-less Cash skill inventory is partial`與`managed target drift`；未完成journal存在時，installer MUST NOT先以其中任何一個返回而略過恢復，即使半發布bytes落在receipt-managed path亦然，且該恢復 MUST NOT要求`--force`。journal的schema version不被本bundle辨識時 MUST以execution error fail closed，且diagnostic MUST指出需要版本相符或更新的installer；`newer`排除的判準是receipt版本，而receipt是transaction的最後一筆operation，因此較新bundle在publishing階段的崩潰不會被`newer`排除，跨版本journal MUST由此條而非`newer`排除來處理。被分類為`newer`的target MUST維持零寫入返回且 MUST NOT執行recovery，其journal留待版本相符或更新的installer處理。非dry-run、target未分類為`newer`且偵測到journal時，installer MUST先執行既有的launcher-without-lock檢查，再取得既存stable lock後才執行recovery；該次取鎖 MUST NOT建立不存在的lock，journal存在而stable lock不存在 MUST fail closed，MUST NOT以`O_CREAT|O_EXCL`建立新的lock inode。recovery回傳真與回傳偽兩個分支 MUST都關閉lock descriptor，同一process在任一時刻 MUST至多持有一個stable lock descriptor。Journal recovery造成的rollback寫入 MUST NOT被視為違反`current`、`newer`或`conflict`分類的零寫入契約：該零寫入契約自recovery完成後的重新分類起適用，因此recovery之後若仍存在與該journal無關的drift，installer MUST回報`Result: conflict`、exit 2，且自重新分類起零寫入。當recovery實際處理並清除journal時，installer MUST釋放stable lock並依recovery後的state重新分類，MUST NOT因recovery自身造成的target變更而以publication前revalidation不一致為由fail closed；外部併發在取得lock之後修改target時，publication前revalidation的既有fail-closed契約 MUST維持不變。該重新分類 MUST在同一lock inode上恢復，且同一份journal MUST NOT再次觸發重新分類；釋放lock的時間窗內由外部併發產生的另一份journal可再觸發一次重新分類，屬既有併發語意。偵測到未完成journal時，installer MUST在早於`newer` early return的偵測點輸出一句與分類無關的通用diagnostic，僅陳述target存在未完成的journal；該句 MUST在dry-run與real run皆出現，且 MUST與最終分類無關而一律出現，包含`current`與`newer`。分類為`newer`時，installer MUST於`newer` early return之前另外輸出一句newer專屬補充，指出該journal需要版本相符或更新的installer才會恢復；該補充 MUST NOT併入通用句，因為通用句在版本比較之前發出，把newer專屬語意寫進去會對絕大多數會被本次執行恢復的target給出錯誤指引。`--dry-run` MUST NOT執行recovery並 MUST維持零寫入。

Receipt-less legacy adoption MUST在receipt與runtime缺失、stable prefix為absent、`lock-only`或`lock+launcher`，且24個canonical Cash skills全數為root-contained、non-symlink、single-link regular files、bytes與`0644` mode逐筆等於source時成立。installer SHALL保留skill bytes，並由monotonic bootstrap transaction補齊launcher、runtime、config/guidance與新receipt。零個skill是fresh；1至23個、任何byte/mode/identity不同或unknown Cash runtime partial state在未帶`--force`時 MUST conflict。Receipt-less完整新inventory則可在stable lock下依全部bytes/modes相符條件認養。

Known legacy receipt MUST嚴格限定為恰好25個LF-terminated records：第一筆`version<TAB><strict-MAJOR.MINOR.PATCH>`，其後依canonical 24-skill順序各一筆`sha256<TAB><lowercase-64-hex-digest><TAB><project-relative-path>`；它沒有mode、runtime、bootstrap或generation欄位。僅當receipt完整符合此schema、24個target skills逐筆相符且stable prefix absent或canonical recoverable時，installer才 SHALL執行one-time bootstrap migration。failure MUST回滾replaceable publications並還原old receipt，但 MUST保留已發布的stable lock/launcher；下一次direct或batch invocation MUST在相同lock inode恢復。old receipt drift、unknown/incomplete schema或bootstrap drift MUST fail closed。dry-run MUST使用同一判定、零寫入並回報would-update。

installer MUST先以incoming parser驗證source config，並在target config interpretation前先驗證target receipt/version/boundary；合法newer target MUST零寫入返回，且 MUST NOT由較舊incoming parser重新解讀target`.cash.yaml`。fresh、known-legacy、adoption、current與older target才使用incoming bundle parser。config deployment MUST採三分支：既有`.cash.yaml`視為project-owned，以該parser及no-follow snapshot驗證allowed keys、duplicates、types與syntax後逐byte保留，invalid existing config MUST在首次write前execution error；只有`.spectra.yaml`時 SHALL只接受uncommented `locale/tdd/audit/parallel_tasks`及optional `spec_dir: openspec`，任何其他active top-level/nested scalar、map、list或non-default`spec_dir` MUST fail closed；兩者皆不存在時 MUST先以同一parser驗證source canonical `.cash.yaml`，再逐byte複製baseline。installer MUST NOT刪除caller-owned`.spectra.yaml`。成功transaction MUST最後才發佈receipt；failure MUST回滾新建config與先前receipt，或維持兩者absent。

Installer SHALL提供source-only `--self [--dry-run]`模式。它 MUST從installer所在目錄解析唯一Git top-level，驗證canonical source version、stable launcher/lock、replaceable runtime generation、24個skills、`.cash.yaml`與`openspec/config.yaml`的no-follow identity、bytes及contract modes，並在既有stable lock的exclusive FD下分類或發布receipt。Real run MUST只以held receipt-parent FD與same-directory owned temporary原子建立或替換`.cash-skills/receipt.tsv`；receipt MUST使用一般target相同的version、generation、path/digest/mode與stable `st_dev/st_ino` schema。`--dry-run` MUST零寫入；current self receipt MUST零寫入。`--self` MUST NOT與`--target`、`--all`、`--register`、`--unregister`、`--list`或`--force`組合，MUST NOT發布或修改launcher、lock、runtime、skills、config、guidance或legacy內容。一般direct、registry與batch target modes仍 MUST拒絕source repository。已辨識source layout的launcher在receipt缺失時 MUST回報`bootstrap_invalid`，receipt存在但內容驗證失敗時 MUST回報`receipt_invalid`；兩者皆 MUST以exit 1失敗，JSON與non-JSON diagnostic都 MUST包含`./install-cash-skills.fish --self`，installed target diagnostic MUST NOT建議source-only指令。

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

- **WHEN**direct、registered或batch target不是Git worktree top-level，或缺少安全有效的`openspec/config.yaml`
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

- **WHEN**版本、全部receipt records、modes、guidance、target版控排除設定與legacy state都一致
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

### Requirement: Installer 與 legacy cleanup filesystem boundaries

Installer SHALL canonicalize既有target；一般direct、registry與batch模式 MUST拒絕空值、`/`、source repository、symlink target、root外destination及symlink/hard-link ownership不明的managed boundary。唯一source repository例外是明確`--self`模式，且該模式只能在已驗證source root內發布receipt。Publisher MUST以held no-follow parent directory handle、exclusive relative temporary basename、snapshot revalidation、明確mode與transaction journal完成publication/cleanup。Registry與`uninstall-spectra-plus-repair.fish` MUST保留既有HOME absolute/non-root、symlink及service identity fail-closed contract。Mode參數的分派 MUST依「該參數是否被提供」判定，MUST NOT依參數值的truthiness判定；空字串的`--target`、`--register`或`--unregister` MUST被視為該mode的invalid value並以caller-input error失敗，MUST NOT被重新解讀為batch mode或任何其他mode。該空值拒絕 MUST早於registry的讀取，也 MUST早於與mode相依的`--dry-run`及`--force`相容性檢查：空字串mode參數 MUST NOT讀取registry、MUST NOT對任何已註冊project執行安裝；即使registry或HOME本身不合法，diagnostic MUST指出mode參數值無效而非registry或HOME錯誤；空字串mode參數與`--dry-run`或`--force`併用時，diagnostic MUST指出該值無效而非指出缺少mode參數。與mode相依的`--dry-run`及`--force`相容性檢查本身 MUST對帶值mode參數使用同一存在性判準，對`store_true`的boolean mode flag則 MUST維持既有判準，使既有的caller-input守衛不因此失效。

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
