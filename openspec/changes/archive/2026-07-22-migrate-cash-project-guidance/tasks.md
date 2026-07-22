## 1. Canonical Cash guidance

- [x] 1.1 在 `AGENTS.md` 落實「Canonical Cash guidance 直接取自 source AGENTS.md 與 CLAUDE.md」的 Codex variant：只保留單一 `<!-- CASH:START -->`／`<!-- CASH:END -->` block、Cash-only `$cash-*` routing、Spectra CLI authority與逐字完整的「Cash 指引提供無向量模型替代流程」；以 canonical block內容檢閱驗證。
- [x] 1.2 在 `CLAUDE.md` 落實同一 canonical source決策的 Claude variant：只保留單一 Cash block、`/cash-*` routing與逐字相同的 fallback block；以 canonical block內容檢閱及 Cash/Spectra marker counts驗證。

## 2. Installer guidance migration

- [x] 2.1 在 `install-cash-skills.fish` 實作「Exact marker state machine 保護專案自訂內容」與「Cash project guidance migration」：驗證、分類並轉換 missing／plain／Spectra-only／Cash-only／both states，逐位元組保留 managed spans外內容；以 marker state matrix及 custom sentinel fixtures驗證。
- [x] 2.2 把 source/target guidance regular-file、symlink、read/write、parent與atomic-replace檢查納入「安裝器與清理落實檔案系統邊界」preflight，並在 publication前重新驗證 snapshot bytes與 parent/destination identity；確保 malformed/duplicate/nested markers與 preflight boundary failures在首次 target write前 fail closed，post-preflight edit/symlink/inode swaps不覆蓋新內容或 target外 sentinel，且既有 mode保留、新檔為 `0644`；以 fault-injection、mode、zero-write、hard-link及 `--force` non-bypass fixtures驗證。
- [x] 2.3 落實「Guidance 計畫加入既有 installer 交易」與「無狀態的跨專案安裝器」結果語意：guidance drift使非 `newer`／非 `conflict` target回報 `update`，canonical state回報 `current`，skill conflict與 newer target保持零 guidance writes，所有 publication成功後才發佈 receipt；以單 target current/update/newer/conflict與 runtime publication failure fixtures驗證既有 receipt保留、guidance差異在非 conflict分支由一般重試收斂、有 receipt的 skill drift須 `--force`，以及無 receipt三分法：零個受管 skill目的地走首次安裝、24檔完整全等走 adoption、已有至少一個目的地但未滿足adoption才在一般重試 conflict且零寫入並須 `--force`。另以「零檔首次安裝不被recovery分類攔截」與「24檔全等但receipt publication失敗後由adoption補齊」fixtures驗證兩個非 conflict邊界。
- [x] 2.4 落實「Guidance 不進入 skill receipt 與 bundle 版本」：`.cash-skills/receipt.tsv` 持續恰好 25 records且 `cash-skills.version` 不變，同版本 guidance migration可先 `update`後 `current`；以 receipt schema、version governance及兩次連續安裝 assertions驗證。
- [x] 2.5 維持「Cash-only routing 與 Spectra skill availability 分離」及「Cash 安裝不含修復自動化」：guidance migration不刪除或修改標準 `spectra-*` skills，既有 retired plus cleanup與無 background repair合約不變；以 Spectra skill tree digest、retired-plus matrix及 runtime absence assertions驗證。

## 3. Batch、文件與回歸覆蓋

- [x] 3.1 更新 `CASH-SKILLS.md` 以滿足「現行文件反映 cash 所有權與清理」：說明雙 guidance source、marker migration、project-content保留、標準 Spectra skill保留、receipt/version邊界、target project被 Spectra app重新加入後的明確重跑流程，以及 source repository由版本控制還原的邊界；以 live-documentation literal assertions與人工內容檢閱驗證。
- [x] 3.2 在 `scripts/cash-skills/tests/skill-checks.fish` 建立「向量模型 fallback 保留在兩個 canonical Cash blocks」回歸：擷取並逐 byte比較使用者指定的完整 Markdown block，另驗證 `$cash-*`／`/cash-*` routing variant差異與 source合法 Spectra block不阻斷 target安裝。
- [x] 3.3 擴充 installer branch matrix以覆蓋「專案擁有的 cash 指引在 Spectra 更新後存續」：模擬外部重新加入合法 Spectra block，證明 Cash block仍有效，重跑 installer後只移除 Spectra block且其他 bytes不變。
- [x] 3.4 擴充 registry fixtures以覆蓋「版本感知的 cash skill 批次安裝」：驗證等版本 guidance drift為 `updated`／`would-update`、canonical為 `current`、newer保持零寫入、guidance failure不停止後續 targets，並核對完整 summary counts。

## 4. 驗證

- [x] 4.1 執行 `fish scripts/cash-skills/tests/skill-checks.fish`，確認 guidance、installer、boundary、batch、retired-plus與既有 Cash contracts全部通過。
- [x] 4.2 執行 `spectra validate "migrate-cash-project-guidance"` 並檢閱 proposal、design、delta spec與 tasks的 requirement名稱、decision headings、路徑及行為定義一致性。

## 5. Directory-FD boundary hardening

- [x] 5.1 在 `scripts/cash-skills/tests/skill-checks.fish` 先為「Directory-FD anchored guidance publication 封閉 parent pathname race」建立 RED fixtures：於 temporary create前與atomic rename前分別交換 parent pathname及destination inode/symlink，驗證替代 parent同名 sentinel、receipt與later guidance逐 byte不變；另驗證source/target permission failures零寫入、新建 `AGENTS.md`／`CLAUDE.md` mode固定為`0644`，以及 missing／plain／Spectra-only／Cash-only／both states的managed spans外完整 byte snapshots；以 targeted `assert_guidance_boundary_matrix` invocation確認fixtures在現行 pathname-based publisher上因正確原因失敗。
- [x] 5.2 在 `install-cash-skills.fish` 落實「Directory-FD anchored guidance publication 封閉 parent pathname race」：單一 Perl publisher以no-follow開啟並`fstat`驗證parent directory FD，以`chdir($directory_fh)`綁定working directory並核對`stat(".")` identity，之後只對不含`/`的validated relative basenames完成anchored snapshot read、exclusive temporary create、mode設定、cleanup與atomic rename，且任何失敗都不得以失效parent pathname執行`rm`／`mv`；以5.1 fixtures全綠、`fish -n install-cash-skills.fish`及故障後無`Result:`驗證。
- [x] 5.3 執行`fish scripts/cash-skills/tests/skill-checks.fish`與`spectra validate "migrate-cash-project-guidance"`，確認13個既有完成tasks的contracts未回歸、3個新增tasks全數通過，並重新檢閱proposal、design、delta spec、tasks與`apply-r1.md`的兩個bucket-1 obligations已完整對應；逐項核對Implementation Contract的`Behavior`、`Interface and data shape`、`Failure modes`、`Acceptance criteria`與`Scope boundaries`皆有實作及具名verification evidence。

## 6. Sol review snapshot與驗收修正

- [x] 6.1 在`scripts/cash-skills/tests/skill-checks.fish`依「Immutable guidance snapshots 綁定 metadata、digest 與 render bytes」先建立RED fixtures：同一inode在分離pathname reads間短暫改寫並還原source／target時，snapshot metadata、digest、canonical extraction與render bytes必須一致；另逐列覆蓋Marker狀態分類的`Cash pair=1, Spectra pair=2`與數值版本example四組精確值，並以完整standard Spectra skill trees digest驗證遷移前後byte-identical。
- [x] 6.2 在`install-cash-skills.fish`實作「Immutable guidance snapshots 綁定 metadata、digest 與 render bytes」及「Atomic rename commit window 明確排除非協作 writer」：source與target各由單一Perl`O_NOFOLLOW` handle取得`fstat`、完整bytes、SHA-256與mode，marker extraction/render僅使用該memory snapshot；移除分離的guidance `hash_file`／`path_identity`後pathname重讀，保留最後checkpoint前的destination swap fail-closed與held-parent guarantees，且不以額外`lstat`宣稱inode-conditional atomic replace；以6.1 fixtures、`fish -n install-cash-skills.fish`與現有race matrix驗證。
- [x] 6.3 更新`CASH-SKILLS.md`以滿足「現行文件反映 cash 所有權與清理」：receipt-less adoption明確說明會保留24個skill bytes、收斂兩份guidance並建立receipt；`--dry-run`改述為不建立target temporary files或持久狀態，但允許會在exit清除的system temporary validation/render snapshots；以documentation literal assertions與人工內容檢閱驗證。
- [x] 6.4 執行`fish scripts/cash-skills/tests/skill-checks.fish`、`fish -n install-cash-skills.fish scripts/cash-skills/tests/skill-checks.fish`、`spectra analyze migrate-cash-project-guidance --json`與`spectra validate "migrate-cash-project-guidance"`，確認20/20 tasks、兩個snapshot Critical與五個acceptance/documentation Warning皆有具名verification evidence且既有contracts未回歸。

## 7. Opus review測試覆蓋補強

- [x] 7.1 在`scripts/cash-skills/tests/skill-checks.fish`補齊「Canonical Cash guidance 直接取自 source AGENTS.md 與 CLAUDE.md」、「Exact marker state machine 保護專案自訂內容」與dry-run cleanup的三項具名runtime證據：source guidance含malformed marker時精確code 1、無`Result:`且target tree逐byte不變；成功安裝後直接斷言target `CLAUDE.md`含`/cash-*`且不含`$cash-*`；以test-local `mktemp` shim記錄本次dry-run建立的四個`/tmp/.cash-guidance-source.*`／`/tmp/.cash-guidance-rendered.*` paths，並逐一驗證process exit後皆不存在。
- [x] 7.2 執行`fish scripts/cash-skills/tests/skill-checks.fish`、`fish -n scripts/cash-skills/tests/skill-checks.fish`、`spectra analyze migrate-cash-project-guidance --json`與`spectra validate "migrate-cash-project-guidance"`，確認22/22 tasks、三項Opus review coverage gaps與既有contracts全數通過。
