## ADDED Requirements

### Requirement: Target 版控排除保護

Installer 的direct、registry與batch模式 SHALL在preflight通過後、於同一transaction內確保target根目錄的`.gitignore`含有`.cash-skills/receipt.tsv`、`.cash-skills/state/`與`__pycache__/`三項規則。此保護存在的理由是receipt依既有contract記錄target-specific `st_dev/st_ino`，一旦被納入版控，任何inode不同的取得方式都會使該target的launcher以`receipt_invalid` fail closed。source-only `--self`不在本requirement範圍內。

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

## MODIFIED Requirements

### Requirement: Bundle 安裝與 runtime receipt

`install-cash-skills.fish` SHALL將stable launcher/lock、replaceable runtime generation、24個Cash skills與`.cash-skills/receipt.tsv`視為同一versioned inventory。`cash-skills.version` MUST恰含一個`MAJOR.MINOR.PATCH`值，三個分量各符合`0|[1-9][0-9]*`，不得含前導零、prerelease或build suffix。版本排序 MUST以每個digit string的長度再以lexical bytes比較任意長度分量，不得轉換為fixed-width integer或float。任何replaceable runtime/skill bytes或contract mode改變 MUST調升bundle version；相同版本 MUST綁定first-parent history中的引入commit，後續相同版本內容漂移 MUST使contract test失敗。Stable bootstrap bytes不得隨一般bundle version改變，source drift MUST為execution error。

preflight MUST在任何target write前驗證Python 3.11+、source version及完整bootstrap/runtime/skill inventory、destination boundaries、legacy full-body digests、mode與config migration。direct、register與batch targets MUST各自是Git worktree top-level，且 MUST已有安全可讀、schema-valid的regular `openspec/config.yaml`；non-Git、Git子目錄target或missing/unsafe config MUST fail closed。`runtime_generation` MUST為replaceable runtime records依project-relative UTF-8 path bytes排序後，每筆以`<path>\t<lowercase-sha256>\t<four-digit-mode>\n`構成canonical UTF-8 stream的lowercase SHA-256。receipt MUST先記錄bundle version與runtime generation，再依canonical inventory順序為stable launcher/lock及每個replaceable runtime/skill path恰記一筆project-relative path、lowercase SHA-256及mode；stable records另 MUST記錄target-specific decimal `st_dev/st_ino`。launcher與installer取得stable lock後 MUST以`fstat`比對launcher/lock records、逐檔hash runtime records並重算generation，才可import runtime或分類current。invalid source version、generation或receipt的invalid version、欄位數、digest、mode、device/inode、path、順序、duplicate、missing或unknown record MUST在首次write前以execution error失敗，不得分類為missing、current、newer或conflict。launcher MUST為`0755`，lock與其他新建runtime/skill files MUST為`0644`。可刪除legacy standard skill MUST逐byte匹配`scripts/cash-skills/legacy-spectra-digests.tsv`的已知baseline且mode為`0644`。無法證明為已知baseline者（同名customization、unknown version或mode drift）MUST被保留、MUST NOT被刪除或修改，且 MUST NOT阻斷安裝：installer MUST繼續發布其餘managed inventory，並在該target的輸出逐筆列出被保留的path。只有可能導致刪除逃逸target邊界的形狀——symlink、hard link或目錄含額外內容——MUST在首次write前fail closed。legacy receipt migration只驗證舊schema實際記載的path與digest，MUST NOT以舊schema未記載的mode作為migration gate；managed skill的mode由本次transaction依contract mode正規化。

Fresh、legacy adoption與known-old migration MUST使用monotonic bootstrap。read-only preflight後，installer以`O_CREAT|O_EXCL`建立project-root lock、立即取得exclusive lock，並以`fstat`與pathname no-follow lookup重驗相同device/inode；遇到`EEXIST`的並發installer MUST開啟現存lock、等待exclusive lock、重驗pathname/FD identity後重新分類。Stable lock一旦建立 MUST NOT unlink或rename；stable launcher一旦atomic發佈亦 MUST NOT unlink或rename。failure只回滾replaceable runtime、skills、config、guidance、target版控排除設定與receipt，保留canonical `lock-only`或`lock+launcher` prefix；下一次installer MUST在同一lock inode上恢復。launcher-without-lock、bootstrap drift、unknown partial state或pathname/FD mismatch MUST fail closed。Existing current/upgrade/force/batch MUST持有同一FD到transaction/rollback完成。新receipt MUST最後發佈並從target `fstat`產生stable identity records。

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

#### Scenario: Install 與 launch 共用 stable lock

- **GIVEN**existing target正在執行Cash CLI並持有stable lock的shared FD
- **WHEN**installer嘗試upgrade runtime generation
- **THEN**installer在取得同一inode的exclusive lock前不得snapshot或publish managed destinations
- **AND**CLI process不載入mixed runtime generation

- **GIVEN**installer持有exclusive lock並正在publish多檔runtime generation
- **WHEN**新launcher process啟動
- **THEN**launcher在import library前等待同一lock
- **AND**取得shared lock後只載入receipt驗證過的完整generation

<!-- @trace
source: replace-spectra-cli-with-cash-cli
updated: 2026-07-24
code:
  - .agents/skills/
  - .agents/skills/spectra-analyze/
  - .agents/skills/spectra-apply/
  - .agents/skills/spectra-archive/
  - .agents/skills/spectra-ask/
  - .agents/skills/spectra-audit/
  - .agents/skills/spectra-commit/
  - .agents/skills/spectra-debug/
  - .agents/skills/spectra-discuss/
  - .agents/skills/spectra-drift/
  - .agents/skills/spectra-ingest/
  - .agents/skills/spectra-propose/
  - .agents/skills/spectra-verify/
  - .cash-skills/bin/cash
  - .cash-skills/lib/cash_cli/
  - .cash-skills/receipt.tsv
  - .cash-skills/state/
  - .cash-skills/state/snapshots/
  - .cash-skills/state/touched/
  - .claude/skills/
  - .claude/skills/spectra-analyze/
  - .claude/skills/spectra-apply/
  - .claude/skills/spectra-archive/
  - .claude/skills/spectra-ask/
  - .claude/skills/spectra-audit/
  - .claude/skills/spectra-commit/
  - .claude/skills/spectra-debug/
  - .claude/skills/spectra-discuss/
  - .claude/skills/spectra-drift/
  - .claude/skills/spectra-ingest/
  - .claude/skills/spectra-propose/
  - .claude/skills/spectra-verify/
  - .spectra/
  - scripts/cash-cli/fixtures/
  - scripts/cash-cli/tests/
  - scripts/cash-skills/legacy-spectra-digests.tsv
  - scripts/cash-skills/tests/skill-checks.fish
tests:
-->
