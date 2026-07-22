## Context

`install-cash-skills.fish` 目前只把 24 個 canonical `SKILL.md` 部署到 target，並以 `.cash-skills/receipt.tsv` 管理 skill bundle 版本與漂移。專案指引不在 installer inventory；因此 target 即使已安裝 Cash，`AGENTS.md` 或 `CLAUDE.md` 仍可能只包含 Spectra-managed workflow routing。本 repository 自己也呈現變體不一致：`AGENTS.md` 有 Cash precedence override，而 `CLAUDE.md` 只有 Spectra managed block。

Cash workflow 仍使用 Spectra CLI 與 `openspec/` artifacts，但不使用 `spectra-*` workflow skills。標準 Spectra skills 可能由 Spectra app 重新安裝，因此 skill availability 與 workflow routing 必須分開治理。Installer 已有 source/target preflight、dry-run、單 target/batch 結果、atomic per-file replacement 與 fail-closed filesystem boundary，guidance migration 必須加入同一條交易路徑，而不是建立另一個 updater。

## Goals / Non-Goals

**Goals:**

- 讓每次成功且非 `newer` 的 Cash target 安裝都收斂成 Cash-only project guidance。
- 對 `AGENTS.md` 與 `CLAUDE.md` 提供各自正確的 `$cash-*`／`/cash-*` invocation。
- 安全移除完整且唯一的 Spectra managed block，更新完整且唯一的 Cash managed block，並逐位元組保留其他專案內容。
- 在兩個 Cash blocks 中加入使用者指定的向量模型未下載 fallback，不因語意搜尋不可用而阻斷工作。
- 讓 guidance migration 遵守既有 preflight、`--dry-run`、result protocol、batch aggregation 與重複執行語意。

**Non-Goals:**

- 不移除或修改標準 `spectra-*` skills；既有 retired plus cleanup 維持原合約。
- 不修改 Spectra CLI、Spectra app 或模型下載流程。
- 不把整份 `AGENTS.md`／`CLAUDE.md` 納入 byte-identical 管理。
- 不把 guidance blocks 加入 24 檔 skill receipt，也不因本 change 調升 `cash-skills.version`。
- 不建立 background repair；外部工具重新加入 Spectra block 後，須再次明確執行 installer。

## Decisions

### Canonical Cash guidance 直接取自 source AGENTS.md 與 CLAUDE.md

Repository root 的 committed `AGENTS.md` 與 `CLAUDE.md` 各自包含恰好一個 `<!-- CASH:START -->`／`<!-- CASH:END -->` block，且不包含 Spectra managed block。Installer 在任何 target 寫入前，驗證兩個 source files 是可讀 regular files、不是 symlink、Cash marker 完整且唯一，並擷取包含 markers 的 canonical block。Source file 內由外部 Spectra update 重新加入但不與 Cash block 巢狀的 Spectra block不妨礙 canonical Cash block擷取，避免一個 source guidance drift阻斷所有 target更新；source repository本身仍透過版本控制還原 committed Cash-only狀態。這讓 live repository guidance 與跨專案安裝來源只有一份，不新增 template 目錄或重複大段 literal。

Codex block 使用 `$cash-*`，Claude block 使用 `/cash-*`；兩者其餘語意相同。替代方案是把兩段文字硬編碼在 installer，否決原因是 source project guidance 與 installer literal 會成為兩份容易漂移的真相來源。

### Guidance 計畫加入既有 installer 交易

Installer 保持現有 CLI，不新增 flag。它在 skill、receipt 與 retired-plus 判定之外，對兩個 guidance files 完成 boundary、marker、內容與 write-permission preflight；preflight failure發生在第一次 target mutation前。每個 guidance file以同目錄 temporary file加 per-file atomic replace發佈，所有 publication成功後才最後發佈 receipt。Preflight後的 runtime publication failure可能發生在較早的 per-file publication已完成之後；此時 installer以 code 1結束、不發佈新 receipt、不回滾已發佈的 regular files，並在 target原有有效 receipt時保留它。下一次 invocation不推測不可觀測的 publication歷史，而只依當下 skills、receipt與guidance分類。有有效 receipt且任一 skill相對 receipt漂移時 MUST 回報 `conflict`。無 receipt時採互斥三分法：零個受管 skill目的地存在就走首次安裝；24檔全數存在且與source相同就走 receipt-less adoption；至少一個目的地存在但未滿足完整全等 adoption時 MUST 回報 `conflict`且零寫入，只有帶 `--force`才能完成收斂並發佈新 receipt。Guidance差異在非 conflict分支依一般規則收斂。

Target 領域結果整合如下：

- `current`：skills、receipt 與 source version 全部 current，沒有 retired plus cleanup，兩個 target Cash blocks 都與 source canonical blocks相同，且沒有 Spectra block。
- `update`：target 不屬於 `newer` 或 `conflict`，且 skill、retired plus 或任一 guidance file 需要 action。
- `newer`：沿用既有保護，完全不寫 target；舊 installer 不嘗試變更較新 target 的 guidance。
- `conflict`：沿用既有 skill/receipt drift 規則；guidance action 不會繞過 conflict。
- execution failure：source/target guidance 型態、marker、boundary、讀取或 permission 驗證失敗時以 code 1 結束且不輸出 `Result:`。

`--force` 仍只解決 managed skill conflict，包括相對有效 receipt的 drift，以及無 receipt時已有至少一個受管 skill目的地但未滿足24檔完整全等 adoption的 state；零檔 receipt-less state走首次安裝，24檔完整全等 state走 adoption，兩者都不需要 `--force`。`--force`不繞過 malformed/duplicate guidance markers或 filesystem boundary。`--dry-run` 執行與真實安裝相同的 validation 與分類，列出 guidance actions但零寫入。Batch modes直接沿用單 target的 `update`／`current`／`newer`／`conflict`／`failed`分類。

### Exact marker state machine 保護專案自訂內容

每個 target guidance file 分別解析兩種 block：Cash start/end 必須是精確的獨立 marker 行；Spectra start 必須是精確的 `<!-- SPECTRA:START -->` 或帶三段數字版本的 `<!-- SPECTRA:START vMAJOR.MINOR.PATCH -->` 獨立行，end 必須是精確的 `<!-- SPECTRA:END -->` 獨立行。每種類型只允許零或一個完整、順序正確且不互相巢狀的 block；孤立、反序、重複或巢狀 markers 都是 execution failure。Preflight記錄既有 guidance完整 bytes與 parent/destination identity；建立 temporary file前與 atomic publish前都重新驗證 parent仍是同一個 target內 directory、destination仍有相同型態與 snapshot bytes且不是 symlink。任何 post-preflight edit或 identity swap都停止目前 file的 publication，不覆蓋新內容，也不接觸 target外 sentinel；較早已完成的 per-file publication依既有 runtime failure規則保留。

合法 target 的轉換規則：

1. Cash 與 Spectra blocks 都不存在時，在檔尾以最少必要換行附加 canonical Cash block。
2. 只有 Spectra block 時，在相同 span 以 canonical Cash block 取代。
3. 只有 Cash block 時，在原位置以 canonical block 更新。
4. 兩者都存在時，保留 Cash block 位置並更新其內容，同時移除 Spectra block。
5. File 不存在時建立只含 canonical Cash block 的新 regular file。

除了被辨識的完整 block spans 與插入所需的邊界換行外，轉換 MUST 保留所有其他 bytes。既有 guidance file的 POSIX mode bits MUST 在 atomic replace後維持不變；新建的 `AGENTS.md`／`CLAUDE.md` 使用固定 `0644` mode。ACL與 extended attributes不在本 change範圍。Cash markers 明示該區段由 Cash 管理，因此合法但內容漂移的 Cash block可直接更新，不需要 `--force`；marker 外內容永不因 `--force` 被覆蓋。替代方案是整份文件 copy，否決原因是會抹除 project-owned instructions。

### Directory-FD anchored guidance publication 封閉 parent pathname race

每個需要變更的 guidance file由單一 Perl publisher process完成 publication。Publisher以 no-follow語意開啟 preflight驗證過的 parent directory並持有 directory FD，先以 `fstat` 核對該 directory object的 device/inode與 preflight identity，再以 parent pathname的 no-follow `lstat`確認目前名稱仍指向同一 identity。Publisher隨即以 Perl `chdir($directory_fh)` 將該單一 process的working directory綁定到held directory object，並以 `stat(".")` 再次核對device/inode；destination與temporary basenames必須符合固定allowlist或不可預測的 `.cash-guidance.<random>` 格式，且一律不含 `/`、`.`或`..` path components。Temporary create、destination snapshot read、mode設定、cleanup與atomic rename全部只對這些相對basenames操作；任何失敗 cleanup MUST NOT 重新解析原始 parent pathname。Publisher在首次target mutation前驗證平台支援directory-handle `chdir`及綁定後的relative child lookup，不支援時fail closed。此機制不使用macOS不支援child traversal的`/dev/fd/<dir-fd>/<basename>`，也不引入platform-specific syscall numbers。

Publisher在 temporary create前與atomic rename前各執行一次 anchored destination snapshot驗證：既有 destination必須仍是相同 device/inode、完整 bytes與regular-file型態；missing destination必須仍不存在且不是 dangling symlink。Parent pathname identity在兩個 checkpoint皆必須與 held directory object相同。若 checkpoint後 parent pathname被替換，所有後續操作仍固定落在已授權的 directory object，不得觸及替代 pathname內的同名 sentinel。替代方案是先檢查 pathname再以 `mktemp`／`rm`／`mv` 操作相同 pathname；否決原因是檢查與使用之間仍存在可重新導向 target外路徑的 race。

### Immutable guidance snapshots 綁定 metadata、digest 與 render bytes

Source與既有target guidance各由單一Perl snapshot operation以`O_NOFOLLOW`開啟一次file handle，從同一handle取得`fstat` identity與mode、讀取完整bytes並計算SHA-256。Canonical Cash block extraction與target marker state rendering只可使用該次讀得的memory bytes，不得在記錄digest後再透過pathname重開檔案。Snapshot helper在讀取前後核對同一handle的identity與regular-file型態，並將與rendered output相同來源的digest、identity與mode回傳給Fish preflight；publisher後續只接受這組metadata與bytes digest。替代方案是保留分離的`hash_file`、`path_identity`及pathname parser calls，否決原因是同一inode可在這些calls間短暫變更並恢復，使revalidation通過但發布未被記錄的中間bytes。

### Atomic rename commit window 明確排除非協作 writer

Publisher在temporary寫入完成後執行最後一次anchored destination identity與完整bytes checkpoint，成功後立即以held-directory relative basenames執行atomic rename。一般POSIX rename沒有「destination仍為預期inode時才replace」的compare-and-swap條件；再加一次`lstat`只會移動而不會消除race。因此本change保證拒絕最後checkpoint前已可觀察到的content、inode或symlink replacement，並保證parent pathname replacement不能重新導向operation；最後checkpoint成功後至rename syscall之間，未遵守同一協作同步機制的concurrent destination writer明確排除。替代方案是用額外pathname check宣稱封閉race，否決原因是該宣稱在技術上不成立；另一替代方案是新增daemon或lock service，超出單機installer的scope。

### Cash-only routing 與 Spectra skill availability 分離

Canonical Cash block 不再描述 precedence override，而是直接聲明本專案只使用 Cash workflow，列出 discuss → propose → apply ⇄ ingest → archive → commit 的 Cash invocations，並保留「Spectra CLI 與 `openspec/` artifact schema 仍具權威」的邊界。Installer 不刪除標準 Spectra skills；Spectra app 可重建它們，但存在於 disk 不代表 agent 應路由至它們。既有只針對 `spectra-propose-plus`／`spectra-apply-plus` 的 retired cleanup 不變。

### 向量模型 fallback 保留在兩個 canonical Cash blocks

兩個 blocks 都逐字包含使用者指定的完整 Markdown，不得摘要、重排或省略：

```markdown
## 向量模型未下載時的替代方式

Spectra 的語意搜尋依賴本機向量模型。若模型尚未下載，不需要中斷或要求先下載，直接改用路徑與檔案讀取：

- 使用者直接給 change 名稱 → 直接讀 `openspec/changes/<name>/` 底下的 artifacts（找不到時用 `spectra list --parked` 確認是否被 parked）
- 問程式碼或需求相關的問題 → 直接用 Grep／Read 搜尋 `openspec/specs/` 與程式碼來回答
```

這是 agent fallback policy，不是 installer runtime 的模型偵測；installer 不執行語意搜尋、不檢查模型狀態，也不下載模型。

### Guidance 不進入 skill receipt 與 bundle 版本

`.cash-skills/receipt.tsv` 繼續只記錄版本加 24 個 canonical skill digests。Guidance files 包含使用者自訂 bytes，不能以整檔 digest 管理；Cash block則可在每次明確 installer invocation 時直接與 source canonical block比較。只有 24 個 installed skill bytes 改變才要求調升 `cash-skills.version`，所以本 change 不修改版本檔。這也允許同版本 target 因 guidance migration 回報 `update`，下一次則穩定回報 `current`。

## Implementation Contract

### Behavior

- 成功的首次安裝、receipt-less adoption、upgrade、forced repair 或同版本 guidance cleanup，在非 `newer`／非 `conflict` target 上產生 canonical `AGENTS.md` 與 `CLAUDE.md` Cash blocks並移除合法 Spectra blocks。
- 所有標準 Spectra skills 保留；只有既有 retired plus contract 允許的四個精確 legacy directories 仍可被移除。
- 已 canonicalized target 再次安裝不修改 bytes並回報 `Result: current`。
- Spectra app 重新加入合法 Spectra block 後，再次執行 installer 會移除該 block、保留 Cash block與其他 bytes並回報 `Result: update`。

### Interface and data shape

- CLI interface 保持 `install-cash-skills.fish --target <project> [--dry-run] [--force]`、registry commands 與 `--all` 不變。
- Managed markers 固定為 `<!-- CASH:START -->`、`<!-- CASH:END -->` 與既有 Spectra markers。
- Receipt format 維持 25 records：一筆 version 加 24 筆 skill SHA-256 records。
- Plan output 對每個 guidance file使用既有 action vocabulary 的明確 guidance action；domain terminal result仍恰好是一行 `Result: update|current|newer|conflict`。

### Failure modes

- Source canonical guidance 缺失、symlink、不可讀或 Cash marker不唯一：code 1、無 `Result:`、零 target writes。Source內合法且不巢狀的 Spectra block不影響 Cash block擷取。
- Target guidance 是 symlink、非 regular file、不可讀、preflight無法證明 atomic replace條件，或含 malformed/duplicate/nested markers：code 1、無 `Result:`、零 target writes。
- Preflight後 destination bytes/identity或 parent identity改變，或 runtime atomic publication失敗：code 1、無 `Result:`、不發佈新 receipt；目前 file與較後 files不再 publication，較早已完成的 per-file publications保留，既有有效 receipt亦保留。下一次 invocation依可觀測 state分類：有有效 receipt的 skill drift回報 `conflict`；無 receipt時零個受管 skill目的地存在走首次安裝，24檔完整全等source走 adoption，其餘已有至少一個目的地的 state回報 `conflict`且零寫入並須使用 `--force`；guidance差異在非 conflict分支一般收斂。
- Guidance publisher無法開啟或驗證 no-follow parent directory FD、無法以`chdir($directory_fh)`綁定working directory、綁定後的`stat(".")` identity不符、relative child lookup不受支援、relative basename不合法、anchored snapshot不符，或relative temporary create／chmod／cleanup／rename失敗：code 1、無 `Result:`、不發佈新 receipt；cleanup僅能在綁定的held directory object內移除本次建立的temporary basename，MUST NOT 對失效的parent pathname執行`rm`。
- Skill conflict仍是 code 2 與 `Result: conflict`，且 guidance 零寫入。
- `newer` 保持 code 0 與 `Result: newer`，且 guidance 零寫入。
- `--dry-run` 不弱化任何 source、marker、filesystem 或 permission validation。
- `--dry-run`可在system temporary directory建立並於exit清除只供validation與render使用的ephemeral snapshots，但不得在target、registry或其他持久位置建立temporary file或持久狀態。

### Acceptance criteria

- Contract tests涵蓋兩個 source variants、五種合法 target state（missing file、無 managed block、Spectra-only、Cash-only、兩者皆有）、source與target marker failure matrix、symlink/permission boundary、post-preflight content/parent/destination swaps、runtime publication failure、mode preservation、外部 sentinel bytes、dry-run、force、current/update/newer/conflict、batch aggregation與重複執行；target `CLAUDE.md`必須直接斷言`/cash-*` variant，dry-run必須以runtime fixture證明system temporary validation/render snapshots於process exit後無遺留。
- Snapshot tests以同一inode短暫改寫並還原source與target pathname，證明canonical extraction、digest、identity、mode與rendered bytes全都來自同一份no-follow handle snapshot。
- Boundary tests在 temporary create前與atomic rename前分別注入 parent pathname swap及destination inode/symlink swap，並逐 byte證明替代 parent內同名 sentinel、既有 receipt、later guidance與managed spans外內容未被 publication或cleanup修改；另獨立驗證source/target read/write failure與新檔固定 `0644`。
- Tests證明 source blocks包含正確 invocation syntax、Cash-only routing、Spectra CLI authority，並逐 byte比較完整向量模型 fallback block。
- Tests證明標準 Spectra skill trees在 guidance migration 前後 byte-identical，並保留既有 retired plus cleanup assertions。
- `spectra validate "migrate-cash-project-guidance"` 與 `fish scripts/cash-skills/tests/skill-checks.fish` 通過。

### Scope boundaries

Implementation只修改 `install-cash-skills.fish`、`AGENTS.md`、`CLAUDE.md`、`CASH-SKILLS.md` 與 `scripts/cash-skills/tests/skill-checks.fish`。不修改 Cash/Spectra skill bodies、`cash-skills.version`、Spectra CLI、app或模型。

Directory-FD publisher實作仍位於 `install-cash-skills.fish` 內並沿用已存在的 Perl runtime；不新增 compiled helper、第三方 dependency、platform-specific syscall number、daemon、lock service或跨檔 rollback。`chdir($directory_fh)`只改變該單一publisher process的working directory，不影響installer parent process。Held directory object是該次 publication的授權邊界；本 change不試圖阻止其他 process rename directory，而是保證pathname replacement不能重新導向publication或cleanup。

本change不宣稱對最後destination checkpoint與atomic rename syscall之間的非協作concurrent writer提供inode-conditional replace；tests MUST NOT把test hook置於該排除區間後再要求保留replacement destination。Target外sentinel、parent replacement與最後checkpoint前的destination mutation仍在完整保護範圍內。

## Risks / Trade-offs

- [Spectra app 日後可能重新加入 Spectra block] → Target project的 Cash block在外部工具更新期間仍明示 Cash-only routing，operator再次明確執行 installer即可清理；source repository若被改動則先由版本控制還原 committed Cash-only guidance，而合法 source Spectra block不阻斷其他 targets的 installer operation。
- [Marker parser 過寬會刪除 user content] → 只接受獨立行、完整、唯一、非巢狀且具精確 identity 的 marker pairs，其餘 fail closed。
- [Marker parser 過窄會拒絕未來 Spectra 格式] → 支援目前無版本與三段數字版本格式；未知格式不猜測刪除，由 operator升級 installer。
- [Guidance與 skill writes無法形成跨檔原子交易] → 完整 preflight先行、publish前 snapshot/identity revalidation、每檔 atomic replace、全部 publication成功後才發佈 receipt；執行期部分失敗保留既有有效 receipt，重試依可觀測 state而非歷史分類。無 receipt時零檔走首次安裝、24檔完整全等走 adoption、已有至少一檔但未滿足adoption才是 conflict；receipt drift與該 receipt-less conflict由 `--force`重試收斂。
- [Parent pathname在revalidation後被替換] → 單一 publisher持有已驗證 directory FD，所有 child operations與cleanup皆使用 FD anchored namespace；pathname checkpoint失敗時停止，checkpoint後替換也只能使名稱脫離held object，不能將操作導向替代 parent。
- [同一inode在分離的hash與render reads間被短暫修改] → metadata、digest、marker parsing與render全部只使用單一no-follow handle讀得的memory snapshot，publisher再以該snapshot digest重驗source與destination。
- [非協作writer在最後destination checkpoint後搶先replace同名basename] → POSIX rename缺少預期inode conditional replace；明確排除此commit window並要求operator避免同時改寫，不用額外`lstat`製造虛假的race-free保證。
- [Atomic replace無法自然保留全部 filesystem metadata] → 既有檔案保留 POSIX mode bits，新檔固定 `0644`；ACL與 extended attributes明確排除。
- [Guidance 不受 bundle version pinning] → 只管理明確 Cash block並在每次 invocation直接比對 canonical source；receipt繼續專注可 byte-identical 管理的 24 個 skills。
