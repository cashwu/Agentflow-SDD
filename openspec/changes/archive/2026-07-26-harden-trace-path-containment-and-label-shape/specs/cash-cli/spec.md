## MODIFIED Requirements

### Requirement: Atomic park、sync 與 archive

`park`與`unpark` SHALL在完整identity與destination preflight後移動整個change directory。`park`、`unpark`與`archive` MUST在移動前確保destination的parent directory存在（必要時以root-contained、non-symlink語意建立），因此尚無`openspec/changes/.parked/`或`openspec/changes/archive/`的workspace首次操作 MUST成功，MUST NOT以缺少目錄的execution error失敗。`sync` SHALL先解析全部delta specs與跨operation identity graph，再依固定phase套用：MODIFIED與REMOVED作用於原identity，ADDED其次，RENAMED最後。相同source的MODIFIED+RENAMED SHALL產生修改內容的新title；REMOVED+RENAMED、duplicate source operation、RENAMED destination與existing/ADDED title collision MUST在publication前失敗。同一份delta中兩個以上RENAMED entry指向相同destination title MUST同樣在publication前以`requirement_collision`失敗，MUST NOT讓後者靜默覆蓋前者而使master spec遺失requirement。`validate` MUST以`operation_collision` finding獨立攔截相同的duplicate destination、destination與ADDED title collision及destination已存在於master spec三種情形，使archive前的validation gate與merge phase形成雙重防線。sync SHALL注入`@trace`：`source`取change name、`updated`取當日、`code`取proposal affected-code paths、`tests`取tasks verification target paths；publication MUST使用exclusive lock、全snapshot revalidation、rollback journal與recovery。sync MUST寫入delta/result digests manifest，相同input/output的repeated sync MUST為no-op，mismatch MUST fail closed。

`archive` MUST總是先執行workspace/config、identity、destination、journal及filesystem safety preflight。預設 MUST再執行完整change validation；`--no-validate`只略過此domain gate，MUST NOT略過delta parse/title identity、sync或safety preflight。`--mark-tasks-complete` MUST在validation後stage所有remaining checkbox，再與sync、manifest及archive move一同commit或rollback。未帶`--skip-specs`時驗證既有sync manifest或執行一次sync，帶`--skip-specs`時 MUST NOT merge；Cash workflows MUST NOT委派`spectra-sync-specs`。成功後 MUST寫入archive identity manifest、移動到`openspec/changes/archive/YYYY-MM-DD-<name>/`並清理Cash state。正常failure MUST回滾checkbox、master specs與change location；rollback failure MUST保留journal並阻斷後續mutation。

`@trace`的兩個路徑欄位 MUST自被治理的artifact形狀抽取，MUST NOT額外要求該形狀未規定的書寫慣例。`code`的抽取範圍 MUST限定為proposal `## Impact`的`- Affected code:`子清單，MUST NOT涵蓋`- Affected specs:`，使抽取範圍與本requirement既有的「`code`取proposal affected-code paths」定義一致。該範圍內 MUST同時接受backtick code span內的路徑與裸路徑token；裸路徑token的字元集 MUST限定為ASCII路徑字元，使以斜線分隔的非ASCII散文 MUST NOT被視為路徑；該字元集 MUST NOT含`,`、`;`、`(`、`)`、`:`、`=`等非路徑標點，使帶指令參數或test-id後綴的token MUST NOT被逐字寫入。同一個路徑以兩種形式出現時 MUST只計一次。`- Affected code:`子清單起點的定位 MUST容忍該標籤列的前後空白（含縮排）與colon之後的行內內容，MUST NOT要求整行與標籤逐字相等；命中的標籤列其colon之後的殘餘內容 MUST以與子清單其餘各行相同的方式收集路徑，使以`- Affected code: <path>`單行形式書寫的宣告 MUST NOT落空。`## Impact`標題列的定位 MUST同樣容忍尾隨空白。子清單的同層終止條件 MUST以與起點相同的正規化判定，使縮排書寫的`- Affected specs:`仍能終止`- Affected code:`的掃描範圍，MUST NOT因只放寬起點而使spec路徑重新進入`code`。粗體或其他markdown強調標記形式、以及全形冒號形式的標籤列 MUST NOT被視為子清單起點，使可容忍的書寫形狀維持可界定。

`tests`的抽取 MUST掃描驗證子句內每個code span的全部whitespace token，MUST NOT只判定第一個token，因此以直譯器或指令名稱起首的驗證子句 MUST仍能貢獻其中的測試路徑。其token判準 MUST為：canonical check script的裸檔名維持既有映射，且該映射 MUST在任何canonical化之前判定；其餘token MUST先要求全部字元屬於與`code`側相同的ASCII路徑字元集，不符者 MUST NOT進入`tests`，再經canonical化（剝除`./`前綴與結尾的`/`；以`/`起首或剝除後不含斜線的token MUST NOT進入`tests`），最後要求canonical化後的值滿足`/tests/`出現在其路徑中或其檔名以`test_`起首。僅以`.fish`或`.sh`副檔名為由 MUST NOT被視為測試路徑，因為交付腳本與測試腳本共用該副檔名，僅憑副檔名接受會使source交付路徑被記為測試證據。兩個欄位寫入trace的值 MUST皆為剝除`./`前綴後、不以`/`起首且不以`/`結尾的canonical repo-relative形式，且該值以`/`切分後的任一路徑段 MUST NOT為空字串、`.`或`..`，其第一段 MUST NOT以`~`起首。這三類拒絕條件涵蓋以`../`逃逸與以`~`為home-relative起點兩種指向repo之外的形式，以及含非canonical路徑段的形式，使其 MUST NOT進入任一欄位；`~`出現在第一段以外的位置屬合法檔名字元，MUST NOT因此被拒絕。該判定 MUST為拒絕而非解析：含`..`、`.`或空段的值 MUST NOT被解析或正規化為其實際指向的路徑後寫入，因為寫入trace的值 MUST能逐字對回來源artifact的宣告。

#### Scenario: MODIFIED title 不吻合時 sync 失敗

- **GIVEN** delta spec的MODIFIED title不存在於對應master spec
- **WHEN** 執行`sync demo`
- **THEN** command以`requirement_identity_mismatch`失敗
- **AND**所有master specs維持逐byte不變

#### Scenario: 兩個 RENAMED 指向同一 destination 時失敗

- **GIVEN** master spec含`Alpha`與`Beta`兩條requirement
- **AND** 同一份delta將兩者都rename為`Gamma`
- **WHEN** 執行`validate demo`與`sync demo`
- **THEN** `validate`回傳`operation_collision` finding與exit 2
- **AND** `sync`以`requirement_collision`失敗且exit 2
- **AND** master spec維持逐byte不變且仍保有兩條requirement

#### Scenario: 缺少 lifecycle 目的地父目錄時自動建立

- **GIVEN** workspace尚未存在`openspec/changes/archive/`或`openspec/changes/.parked/`
- **WHEN** caller首次執行`archive <name>`或`park <name>`
- **THEN** command建立所需父目錄並完成transaction
- **AND** command MUST NOT以缺少目錄的execution error失敗

#### Scenario: Archive transaction 成功

- **GIVEN** change已通過validation且archive destination不存在
- **WHEN** 執行`archive demo`
- **THEN**全部spec operations成功發布
- **AND**change移至當日date prefix的archive directory
- **AND**active identity不再存在

#### Scenario: Archive destination collision

- **GIVEN**目標archive directory已存在
- **WHEN**執行`archive demo`
- **THEN**command在任何spec publication前失敗
- **AND**active change與master specs均維持不變

#### Scenario: Sync 後 archive 不重複 merge

- **GIVEN**`sync demo`已成功且master digests仍符合sync manifest
- **WHEN**執行`archive demo`
- **THEN**archive驗證manifest後不再次套用delta operations
- **AND**master specs維持與sync後逐byte相同

#### Scenario: Explicit no-sync archive

- **GIVEN**使用者拒絕spec sync
- **WHEN**Cash workflow執行`archive demo --skip-specs`
- **THEN**archive不修改任何master spec
- **AND**change仍被移至archive destination

#### Scenario: Archive flags 共用 transaction

- **GIVEN**change有incomplete tasks且caller同時使用`--mark-tasks-complete --no-validate`
- **WHEN**archive通過不可略過的safety、delta parse及identity preflight
- **THEN**command略過獨立change validation後stage所有task checkboxes
- **AND**checkbox、spec merge、manifest與move在任一步失敗時一起rollback

#### Scenario: Impact 以純文字路徑書寫仍產生 code trace

- **GIVEN** 某個change的proposal `## Impact`的`- Affected code:`子清單以不加backtick的純文字列出路徑
- **WHEN** 執行`sync`或`archive`
- **THEN** 產生的`@trace`的`code`欄位含該子清單列出的路徑
- **AND** 同一路徑同時以backtick與純文字出現時只列一次

#### Scenario: Affected specs 的路徑不進入 code trace

- **GIVEN** 某個change的proposal `## Impact`同時有`- Affected specs:`與`- Affected code:`兩個子清單
- **WHEN** 執行`sync`
- **THEN** `@trace`的`code`欄位只含`- Affected code:`子清單的路徑
- **AND** 只出現在`- Affected specs:`的路徑 MUST NOT出現在該欄位

#### Scenario: 以斜線分隔的非 ASCII 散文不進入 code trace

- **GIVEN** 某個change的proposal `- Affected code:`子清單含以純文字（非code span）書寫、以斜線分隔的非ASCII散文片語
- **WHEN** 執行`sync`
- **THEN** 該片語 MUST NOT出現在`@trace`的`code`欄位

#### Scenario: 驗證子句以直譯器起首仍產生 tests trace

- **GIVEN** 某個change的tasks驗證子句寫成直譯器或指令名稱在前、測試路徑在後的形式
- **WHEN** 執行`sync`或`archive`
- **THEN** 產生的`@trace`的`tests`欄位含該測試路徑
- **AND** 同一個code span內不滿足測試判準的其他token MUST NOT出現在該欄位

#### Scenario: 交付腳本不因副檔名被記為測試證據

- **GIVEN** 某個change的驗證子句含位於tests目錄之外、檔名不以`test_`起首、且以`.fish`或`.sh`結尾的交付腳本路徑
- **WHEN** 執行`sync`
- **THEN** 該路徑 MUST NOT出現在`@trace`的`tests`欄位

#### Scenario: 兩個欄位的非 canonical 形式皆被正規化

- **WHEN** 某個change以`./`起首書寫`- Affected code:`的路徑或驗證子句的測試路徑
- **THEN** 寫入`@trace`的值為剝除`./`後的repo-relative形式

- **WHEN** 該路徑以`/`結尾
- **THEN** 寫入`@trace`的值 MUST NOT以`/`結尾

#### Scenario: 指向 repo 之外的路徑不進入任一欄位

- **GIVEN** 某個change的`- Affected code:`子清單含以`../`起首的路徑與以`~/`起首的路徑
- **AND** 其tasks的驗證子句含以`../`起首的測試路徑與以`~/`起首的測試路徑
- **WHEN** 執行`sync`
- **THEN** 該兩個路徑 MUST NOT出現在`@trace`的`code`欄位
- **AND** 該兩個測試路徑 MUST NOT出現在`@trace`的`tests`欄位
- **AND** 同一子清單中第一段不以`~`起首、僅在後續路徑段含`~`的路徑仍出現在`code`欄位

#### Scenario: 含非 canonical 路徑段的值不進入 code

- **GIVEN** 某個change的`- Affected code:`子清單含路徑段為`.`的值或含內部連續斜線的值
- **WHEN** 執行`sync`
- **THEN** 兩者皆 MUST NOT出現在`@trace`的`code`欄位
- **AND** 該值解析或正規化後的形式同樣 MUST NOT出現在該欄位

#### Scenario: Affected code 標籤帶行內內容時仍定位子清單

- **GIVEN** 某個change的proposal把affected code宣告寫成`- Affected code:`後接同一行的路徑
- **WHEN** 執行`sync`
- **THEN** `@trace`的`code`欄位含該行列出的路徑

#### Scenario: Affected code 標籤帶前後空白時仍定位子清單

- **GIVEN** 某個change的proposal的`- Affected code:`標籤列帶尾隨空白或被縮排
- **WHEN** 執行`sync`
- **THEN** `@trace`的`code`欄位含該子清單列出的路徑

#### Scenario: 縮排書寫的兩個標籤仍維持範圍分隔

- **GIVEN** 某個change的proposal把`- Affected code:`與其後的`- Affected specs:`都以縮排書寫
- **WHEN** 執行`sync`
- **THEN** `@trace`的`code`欄位只含`- Affected code:`子清單的路徑
- **AND** 只出現在`- Affected specs:`的路徑 MUST NOT出現在該欄位

#### Scenario: Impact 標題列帶尾隨空白時仍定位子清單

- **GIVEN** 某個change的proposal的`## Impact`標題列帶尾隨空白
- **WHEN** 執行`sync`
- **THEN** `@trace`的`code`欄位含該標題之下`- Affected code:`子清單列出的路徑

#### Scenario: 粗體與全形冒號標籤不被視為子清單起點

- **GIVEN** 某個change的proposal把一個標籤列寫成`- **Affected code:**`、另一個寫成以全形冒號結尾的`- Affected code：`
- **AND** 同一份proposal另有一個以精確形狀書寫的`- Affected code:`子清單，且該子清單位於前述兩個標籤列**之後**
- **WHEN** 執行`sync`
- **THEN** 粗體標籤列與全形冒號標籤列之下所列的路徑 MUST NOT出現在`@trace`的`code`欄位
- **AND** 精確形狀子清單的路徑仍出現在該欄位，使「不容忍該兩種形式」與「整段抽取失效」可被區辨
