# Cash Skills

本 repository 自行維護 cash workflow skills，不由 Spectra 產生，也沒有 base／plus 兩層。`.claude/skills/` 的十二個 `SKILL.md` 與 `scripts/cash-skills/blocks/review-gate.md` 是人工維護的權威源頭；`.agents/skills/` 的十二個 `SKILL.md` 是由 `scripts/cash-skills/generate.fish` 產生的輸出。兩側都納入版本控制，詳見[生成模型](#生成模型)。

## Inventory

兩個 variant 都提供同一組十二個 workflow：

- `cash-analyze`
- `cash-apply`
- `cash-archive`
- `cash-ask`
- `cash-audit`
- `cash-commit`
- `cash-debug`
- `cash-discuss`
- `cash-drift`
- `cash-ingest`
- `cash-propose`
- `cash-verify`

Codex files 位於 `.agents/skills/`，Claude files 位於 `.claude/skills/`。Codex 以 `$cash-*` 呼叫，Claude 以 `/cash-*` 呼叫；兩者的 artifact operations 都由專案內 `.cash-skills/bin/cash` 執行，資料仍位於 `openspec/`。

## 全域 cash shim

在 source repository 執行下列命令，會以 Python 3.11+ safe-path helper 將 POSIX sh shim 安裝到 `$HOME/.local/bin/cash`；Python 3.11+ 不可用時會在任何 filesystem write 前 fail closed。若該目錄不在 `PATH`，installer 會顯示不影響 exit code 的警告：

```fish
./install-cash-shim.fish
```

安裝後，在已安裝 Cash bundle 的 Git worktree 內執行 `cash <指令>`，shim 會把全部引數原樣交給該 worktree top-level 的 `.cash-skills/bin/cash`。在未安裝的 worktree 或非 Git 目錄執行一般指令會 fail closed，並提示使用 `cash init`。

`cash init` 會以目前 worktree top-level 為 target；若目前目錄尚非 worktree，則先在目前目錄執行一次 `git init`。預設委派為 `install-cash-skills.fish --vendor <target>`，也可使用 `cash init --target` 選擇 receipt-based 安裝，並可搭配 `--force`。`cash init --dry-run` 不會執行 git 初始化，因此只能在既有 worktree 內預覽。位於 `.git/` 內部或 bare repository 時，init 會 fail closed。

shim 以 `CASH_SOURCE_ROOT` 定位 source repository；未設定時預設為 `$HOME/Github/Agentflow-SDD`。若 checkout 位於其他位置，先在該次呼叫設定：

```fish
CASH_SOURCE_ROOT=/path/to/Agentflow-SDD cash init
```

shim 是 machine-local 便利層，不是 trust-bearing runtime：它不進 portable manifest 或 receipt 的 managed inventory，不改變 project-local launcher 的驗證，也不觸發 `cash-skills.version` 調升。shim 無獨立版本、自我更新或背景同步；source repository 更新後，必須明確重跑 `install-cash-shim.fish` 才會更新本機 shim，bundle 更新仍由 `cash init` 所委派的既有 installer 語意決定。

Git submodule 依 Git 本身的 top-level 解析視為獨立專案：在 submodule 內 dispatch 會使用 submodule 自己的 launcher；未安裝時執行 `cash init`，bundle 也會安裝到該 submodule，而非外層 repository。

## 生成模型

Cash skill 內容有兩個單一源頭，其餘檔案都是生成輸出：

- **變體源頭**：`.claude/skills/cash-*/SKILL.md`。`.agents/skills/cash-*/SKILL.md` 由 `scripts/cash-skills/generate.fish` 依 `scripts/cash-skills/variant-rules.yaml` 生成，MUST NOT 以直接人工編輯維護。
- **Review gate 源頭**：`scripts/cash-skills/blocks/review-gate.md`。`cash-propose` 與 `cash-apply` 兩個 skill 的 sub-agent review gate 區段由同一份 block 注入，區段邊界以 `<!-- REVIEW-GATE:BEGIN -->`／`<!-- REVIEW-GATE:END -->` 成對錨點標定，每個檔案恰一對。

```fish
fish scripts/cash-skills/generate.fish
```

生成器冪等：對已生成一致的工作樹連續執行兩次不產生任何檔案變更。它接受選用的 target-root 參數（預設 repository root），供回歸套件在暫存目錄重跑管線。

`variant-rules.yaml` 宣告兩層規則。通用轉換套用於全部十二個 skill：invocation 前綴 `/cash-` 置換為 `$cash-`（帶 token 邊界，使路徑字面值不受影響）、移除 Claude Code 專屬的 `context`／`agent`／`disallowedTools` frontmatter、移除 fork 情境段落。通用規則之外的每個差異都在該檔以人可讀的具名 per-skill entry 宣告，目前有 `cash-audit`、`cash-ingest` 與 `cash-propose` 三個 entry。

漂移防護是重新生成的 freshness 檢查而非事後 diff 比對：`scripts/cash-skills/tests/skill-checks.fish` 的 `generated-fresh` 群組把完整生成輸入集複製到暫存 root、重跑管線，再與工作樹中 committed 的目標檔案逐檔 byte-compare，任何差異都使套件以非零結束並指出該檔案。

修訂 skill 內容時，以 [`CASH-GLOSSARY.md`](CASH-GLOSSARY.md) 的詞彙為準，並依 [`scripts/cash-skills/SKILL-LINT.md`](scripts/cash-skills/SKILL-LINT.md) 逐條走過六種失效模式；後者是人工檢核維度，不是阻斷性的自動化檢查。

## Bundle 版本與單一 installer 入口

`cash-skills.version` 是 repository 內唯一的 bundle 版本。任何 24 個 canonical `SKILL.md` 內容異動，都由維護者在同一版變更中提升這個版本；版本只能往前，格式為三段無 leading zero 的數字，例如 `1.0.0`。

`install-cash-skills.fish` 是唯一操作入口。團隊 repository 的建議路徑是由維護者執行一次 `--vendor <project>`、檢查並提交受管 diff；團隊成員 clone 或 pull 該 commit 後直接使用，不需各自安裝或初始化：

```fish
./install-cash-skills.fish --vendor /path/to/project
./install-cash-skills.fish --vendor /path/to/project --dry-run
./install-cash-skills.fish --vendor /path/to/project --force
```

`--vendor --dry-run` 執行完整 preflight 並預覽 publication，但不寫入 target；`--vendor --force` 只覆寫 canonical planned paths 中可安全替換的 managed runtime 與 skills，不能繞過 unsafe shape、版本降級、invalid manifest、未知 stable drift 或未核准的 launcher migration。target 必須是既存、非 source 的 canonical Git worktree top-level。

vendored publication 會發佈 `.agents/skills/cash-*/SKILL.md`、`.claude/skills/cash-*/SKILL.md`、project-local runtime、stable launcher／lock、config／guidance 與 `.cash-skills/manifest.tsv`，且不建立 `.cash-skills/receipt.tsv`。manifest 是最後一筆 trust-bearing managed bundle publication。維護者必須檢查 installer 產生的 diff、執行 contract tests，再把所有受管變更提交；團隊成員只有在 pull 到該 commit 後才取得更新，installer 不會背景下載、自動修復或替成員提交。

### Portable manifest 信任邊界

portable mode 以 Git commit provenance 為 authenticity 的信任根；manifest 驗證受管 inventory 的 digest、filesystem shape 與 Git logical mode，但不宣稱抵抗可同時改寫 `.cash-skills/manifest.tsv` 與受管 inventory 的 repository writer。需要 machine-local post-install identity 時，仍應使用下方的 receipt-based direct／registry／batch workflow。

launcher 使用 manifest-presence 優先序：只要 `.cash-skills/manifest.tsv` path 存在（包括 unsafe shape），就只走 portable gate；invalid manifest 以 `manifest_invalid` fail closed，不會 fallback 到 receipt。只有 manifest 缺失時才檢查 `.cash-skills/receipt.tsv`。因此舊 checkout 中殘留的 ignored receipt 不會遮蔽 pull 後的 valid manifest，也不需由團隊成員刪除或重簽。

portable manifest 與 inventory 比對 Git logical mode，而不是完整 POSIX mode：non-executable files 必須是 `100644` logical class，launcher 等 executable files 必須是 `100755` logical class。合法 umask 導致的 group-write 差異不算 drift；regular／single-link shape、digest、containment 與 opened FD／pathname identity 仍須通過。portable gate 完全唯讀，不建立、chmod、更新檔案或讀寫 managed runtime 的 `.pyc`。

### Vendored publication、認養與轉換

`--vendor` 在首次 write 前及 final publication 前，都會檢查全部 planned paths：已 tracked 的 path 可發佈；未 tracked 的 path 必須不受 repository `.gitignore`、`.git/info/exclude` 或 global excludes 排除。任何 planned path excludes 都會一次列出並 fail closed，維護者必須先修正 Git exclude 狀態，不能用 `--force` 繞過。

target 的分類與處置如下：

- receipt 與 manifest 都缺失且 managed inventory 為零時是 fresh；real run 明確回報 `Result: update`。
- receiptless target 若 stable／runtime／skills 的完整 inventory 逐檔符合 source digest 與 Git logical mode，可在 exclusive lock 下認養既有 bytes，最後發佈 manifest。
- receiptless inventory 若 partial、unknown 或 different，預設回報 `Result: conflict`；`--force` 只可補齊或替換 canonical expected path 上可替換的 missing／different runtime 與 skills，未知 extra runtime 或未知 stable drift仍 fail closed。
- valid receipt-based target 可由明示的 `--vendor` 在同一 transaction 轉換；manifest publication 完成 portable cutover後，receipt 只是不具權威的 machine-local residue並會安全清除。direct `--target`、`--register` 與 `--all` 不會反向把 vendored target轉回 receipt mode。
- 已有 valid manifest 且內容相同時回報 `Result: current`；較新 source 更新 managed inventory與manifest時回報 `Result: update`；managed digest／logical-mode drift未帶 `--force` 時回報 `Result: conflict`。

受控 launcher migration 只接受 installer 內 `APPROVED_LAUNCHER_TRANSITIONS` 登錄的 exact old digest、new digest與 introduced bundle version。receipt-based migration 會在 launcher replacement 後動態簽發綁定新 inode 的 receipt；失敗 rollback時執行 launcher rebind，依還原後的 launcher／lock identity 重建舊 receipt。vendored migration 由 manifest cutover控制：cutover前失敗回復舊 gate，cutover後只 roll forward cleanup；`.cash-workspace.lock` identity 永不替換。普通 runtime／skill 更新不能藉此改寫 launcher。

### Receipt-based direct 安裝

不需要把 bundle 提交給團隊 repository 的單一專案部署，使用 `--target`：

```fish
./install-cash-skills.fish --target /path/to/project
./install-cash-skills.fish --target /path/to/project --dry-run
./install-cash-skills.fish --target /path/to/project --force
```

成功安裝後，target 會保存 `.cash-skills/receipt.tsv`，以 strict versioned record stream 記錄 bundle 版本、runtime generation、stable launcher/lock 的 target `st_dev`／`st_ino`、runtime 與 24 個 canonical skill 的 path、SHA-256 與 mode。這些 target-specific identity records 不進版控。stable record 的 identity 比對條件只有 digest、mode 與 `st_ino` 三項；`st_dev` 是 kernel 在 mount 時配發給 volume 的編號而非檔案屬性，因此不參與比對，只作為 machine-local provenance 保留，並受「device 為非負整數、inode 為正整數」的形狀閘門約束。installer 先用 receipt 判斷版本、mode 與 target drift，再決定結果：

- `Result: update`：完成首次安裝、接管或升級；exit `0`。
- `Result: current`：target 已是相同版本且內容一致，不寫入；exit `0`。
- `Result: newer`：target 比目前 source 新，不降版、不寫入；exit `0`。
- `Result: conflict`：target 有 drift 或無 receipt 的內容不完整／不同；exit `2`。
- argument、schema、I/O、hash 或 integrity error 不輸出 domain result；exit `1`。

Target 缺少 `openspec/config.yaml` 時，installer 會在同一個 transaction 內建立 schema-valid 的預設檔，因此該 target 分類為 `update` 而非 `current`。既有檔案逐 byte 保留；symlink、hard link、FIFO 等 unsafe shape 或 invalid schema 仍在首次 target write 前 fail closed，`--force` 不會繞過。`--register` 接受缺少該檔的 target，但只更新 registry，不建立 `openspec/config.yaml`。

canonical source repository 使用 source-only `./install-cash-skills.fish --self` 維護 committed portable manifest，並在同一 exclusive lock transaction 清除 source receipt residue；它不修改 launcher、lock、runtime、skills、config或guidance。需要變更時回報 `Result: bootstrap`，`--self --dry-run` 回報 `Result: would-bootstrap`，manifest逐 byte current且receipt缺失時回報 `Result: current`。

## Target 版控排除保護

receipt 記錄 target 上 launcher 與 workspace lock 的 `st_dev`／`st_ino`，其中只有 `st_ino` 參與 identity 比對，因此本保護的鑑別力完全由 `st_ino` 承擔：同一份 bytes 換到別的 inode 就會使 launcher 以 `receipt_invalid` fail closed。因此每次 `--target`、registry 與 `--all` 安裝都會在同一個 transaction 內確保 target 根目錄的 `.gitignore` 含這三項規則：

```
.cash-skills/receipt.tsv
.cash-skills/state/
__pycache__/
```

判定在 byte 層以行為單位進行：以 `\n` 切行、逐行 bytes 精確比對，容忍行尾的 `\r`，不要求 UTF-8，所以 CRLF 或含非 UTF-8 pathname pattern 的 `.gitignore` 不會讓 target 變成 `failed`。判定不做前綴、萬用字元或路徑包含關係推論——`.cash-skills/`、`.cash-skills/state`、`/.cash-skills/state/` 與 `*.tsv` 這類等價或較寬的寫法**不視為已滿足**，結果是 installer 追加一條語意重複但無害的規則；這個取捨換得判定可預測，也避免把語意不同的既有規則誤判為已涵蓋。

`.gitignore` 是 project-owned 檔案，因此只附加、不重排：缺少的規則一律加在檔案尾端，既有內容逐 byte 保留、既有 mode 保留，不去重也不刪除任何既有行。既有內容非空且沒有尾端換行時會先補一個行終止符，這是逐 byte 保留的唯一例外。檔案不存在時以 `0644` 建立；三項規則齊備時該檔案零寫入，其餘 managed inventory 亦無變更時 target 才回報 `Result: current`。`.gitignore` 為 symlink、非 regular file、hard link 或無法安全讀取時，在首次 target write 前 fail closed，`--force` 也不繞過。source-only `--self` 不在此保護範圍內，source repository 的 `.gitignore` 由該 repository 自行維護。

既有 target 若已把 `.cash-skills/receipt.tsv` 納入版控，installer 每次執行都會在 stderr 輸出診斷。installer 不會代為修改版控索引，一次性清理由你在該專案執行：

```fish
git rm --cached .cash-skills/receipt.tsv
```

## Receipt-only target 初始化

repo-vendored target 含 committed `.cash-skills/manifest.tsv`，團隊成員 clone／pull 後直接使用，**不得**執行 `--init-receipt`；即使存在舊 receipt，manifest仍優先且 receipt不具權威。對 vendored target執行 `--init-receipt`會以 `init_vendored_bundle` fail closed且零內容寫入。

只有不含 portable manifest 的 receipt-based direct／legacy target，在 clone 或其他原因導致 `.cash-skills/receipt.tsv` 缺席、launcher 以 `bootstrap_invalid` fail closed時，才在該專案根執行一次：

```fish
PYTHONPATH=.cash-skills/lib python3 -s -P -B -m cash_cli.installer --init-receipt
```

前提是 Python 3.11+；更舊的直譯器在 `-m` 載入期就會失敗，不會產生具名錯誤。模式回報 `initialized`（已簽發）或 `current`（既有 receipt 已等價，零寫入），失敗時以 `init_python_version`、`init_outside_worktree`、`init_source_repo`、`init_vendored_bundle`、`init_config_invalid`、`init_inventory_invalid` 或 `init_write_failed` 輸出 JSON 錯誤並 exit `1`，且不寫入任何檔案內容。它必須在 Git worktree top-level 執行，不會建立缺少的 stable 檔案，也不會擴充 bundle inventory；managed inventory 的 mode 會被正規化為 contract modes（launcher `0755`、其餘 `0644`），因此不同 umask 的 receipt-only clone 都能一次成功。

receipt 簽發的是 target-local launcher／lock inode identity與 inventory狀態，不可提交或跨 clone 共用；它在簽發後偵測本機 drift 與竄改。launcher 不會在 receipt 缺失或無效時自動觸發初始化，對已出現 content drift 的 receipt-only target重跑 init 會把該 drift 合法化——digest 不符代表內容本身已改變，此時應還原該筆 record 或從可信 source 重新安裝。stable record identity drift（digest 相符、只有 mode 或 `st_ino` 不符）則相反，是允許重新簽發的入口。本 repository 是 canonical source repository，`--init-receipt` 會以 `init_source_repo` 拒絕它，改用 `./install-cash-skills.fish --self`。

## Cash project guidance migration

Repository root 的 `AGENTS.md` 與 `CLAUDE.md` 是兩個 canonical guidance sources：前者使用 `$cash-*`，後者使用 `/cash-*`。每份 source 都恰好包含一個 `<!-- CASH:START -->`／`<!-- CASH:END -->` managed block；installer 從這兩份 live files 擷取對應 block，不另外維護 template。Source 的 Cash start 與 end marker 都不得帶字尾；任一側帶字尾時會在首次 target write 前 fail closed，且不會把該字尾寫入任何 target。Source guidance 的任何位置也不得出現形似 legacy marker 的文字，包括散文中的舉例，否則 canonical guidance 擷取會在首次 target write 前 fail closed，並阻擋全部 registered targets。

每次非 `newer`、非 `conflict` 的 target 安裝都會檢查同名 guidance files。Installer 會更新既有 Cash block、以 Cash block取代一個合法的 `<!-- SPECTRA:START ... -->`／`<!-- SPECTRA:END -->` block，或在沒有 managed block 時附加 Cash block。Marker 名稱與結尾符號之間的字尾會被容忍並略過，不會被解析。Installer 只改動已辨識的 block spans與必要邊界換行，逐位元組保留 managed spans 以外的 project-owned內容與既有 mode。Symlink、duplicate、orphan、reversed、nested 或非獨立行 marker都會在首次 target write前 fail closed，`--force` 也不會繞過。

標準 `spectra-*` skills 不屬於新的 canonical inventory。Installer 只會依 `scripts/cash-skills/legacy-spectra-digests.tsv` 的已知版本與 full-body digest baseline 移除可證明為標準發行內容的目錄。無法證明 ownership 的目錄（同名 customization、未知版本或 mode drift）會被**保留、不修改、也不阻斷安裝**，installer 會在該 target 的輸出逐筆列出被保留的路徑，你可以自行確認後手動移除。只有可能讓刪除逃出 target 邊界的形狀——symlink、hard link 或目錄含額外檔案——才會在首次 write 前 fail closed，不會猜測 ownership。舊 schema receipt 的 migration 只驗證它實際記載的 path 與 digest；舊 schema 沒有 mode 欄位，因此 mode 不會成為 migration 的門檻，managed skills 的 mode 由該次 transaction 正規化。guidance 不會加入 `.cash-skills/receipt.tsv`，因此只遷移 guidance 不需要調升 `cash-skills.version`；同版本 target 可先因 guidance drift 回報 `Result: update`，下一次則穩定回報 `Result: current`。

若外部工具在 target project重新加入合法的 legacy managed block，Cash block仍有效；再次明確執行 installer即可移除該 legacy block並保留其他內容。若外部工具改動 source repository 的 committed guidance，先用版本控制還原 Cash-only `AGENTS.md`／`CLAUDE.md`；只要 canonical Cash block仍完整唯一，額外且不巢狀的合法 legacy block不會阻斷其他 targets安裝。

每次成功的 target 安裝也會清除由 exact baseline 證明 ownership 的標準 `spectra-*` skill 目錄，包括歷史 retired plus 目錄。Installer 逐一刪除已辨識的 regular files 再移除空目錄，不使用 recursive deletion；任何同名 customization 或未知 legacy 內容都會保留，並在 transaction 首次 write 前 fail closed。

如果 cash bundle 原本已是 `current` 但仍有可辨識的標準 legacy skill，本次執行會列出 `remove:` plan、完成清除並回報 `Result: update`。`--dry-run` 只預覽、不移除；`newer` 與未使用 `--force` 的 `conflict` 分支保持零寫入，也不會先清除 legacy skills。

`--dry-run` 執行相同的完整 preflight，但不建立 target temporary files或持久狀態，也不修改或移除 runtime、skill files、config、guidance、receipt或registry；只供驗證與render使用的system temporary validation/render snapshots會在 exit 時清除。預計更新仍輸出 `Result: update`。`--force` 只可在 source 版本不低於 target 且所有 validation 通過時修復 managed runtime、24 個 `SKILL.md` 與 receipt，並清除上述 exact-baseline legacy 目錄；不會碰其他 inventory 外檔案，也不能繞過同版本 source integrity failure。

舊 target 沒有 receipt 時，24 個 files 全不存在會首次安裝；24 個 files 全部與 source 相同時，adoption會保留既有 24 個 skill bytes、收斂 `AGENTS.md` 與 `CLAUDE.md` guidance，並建立 receipt；mixed、缺檔或內容不同則先回報 conflict，必須確認後才使用 `--force`。

## 手動專案清單與批次更新

專案清單固定在 `$HOME/.config/cash-skills/projects.txt`。它只是使用者明確維護的 canonical path 清單，不是 watcher、排程或自動 repair。registry 與 batch 仍使用同一支 installer：

```fish
./install-cash-skills.fish --register /path/to/project
./install-cash-skills.fish --unregister /path/to/project
./install-cash-skills.fish --list
./install-cash-skills.fish --all
```

`--register` 只接受既有 non-symlink directory 並去重；`--unregister` 也能移除清單中已不存在的 stale path；`--list` 完全唯讀。清單不存在時，`--list`、`--unregister` 與 `--all` 都視為空清單且不建立狀態。

批次更新必須由使用者明確執行，也支援完整預覽與修復 drift：

```fish
./install-cash-skills.fish --all --dry-run
./install-cash-skills.fish --all --force
```

每個 target 都會列為 `updated`、`would-update`、`current`、`newer`、`conflict` 或 `failed`，最後輸出各狀態計數。單一 conflict/failed 不會阻止後續 targets，但只要任一 target 是 conflict 或 failed，整體 exit code 就是非零。批次命令不會自動移除 missing/failed entries，也不會修改 registry。

Cash skills 沒有定期 repair、fingerprint freshness、LaunchAgent、daemon 或背景同步。source 更新後，必須再次明確執行 installer 才會傳到其他專案；registry 本身不會觸發任何工作。

## Live namespace 與歷史邊界

精確 live scan 只涵蓋 canonical Cash skills、`scripts/cash-skills/blocks/`、`scripts/cash-skills/generate.fish`、`scripts/cash-skills/variant-rules.yaml`、`scripts/cash-skills/SKILL-LINT.md`、`CASH-GLOSSARY.md`、installer、Cash runtime source、CLI/skill contract tests、`AGENTS.md`、`CLAUDE.md`、本文件、`.cash.yaml` 與 `openspec/specs/` master specs。Gitignored、target-specific 的 `.cash-skills/state/` 是 source tracking provenance，不是 source namespace；它另由 state schema與allowlist tests治理。source scan會拒絕任何可執行的 legacy CLI command、compatibility declaration、canonical legacy skill directory或未治理的 legacy runtime state read。

Apply 階段 master spec 尚未合併 active delta 是預期狀態。Scanner只對 active delta 中明確列於 `MODIFIED`、`REMOVED` 或 `RENAMED FROM` 的同 capability requirement title套用暫時覆蓋；未被精確 title涵蓋的 master residue仍會失敗。這不是全 change 或全 non-archive 豁免，archive完成後對應舊 requirement自然消失。

Migration detector 僅限 installer、`scripts/cash-skills/legacy-spectra-digests.tsv`、touched-state importer及其精確 fixtures；這些 literals 只辨識既有輸入，不得執行外部 binary。`openspec/changes/archive/`、active migration artifacts/reviews 與 signal occurrence history保留原始 provenance，不納入 runtime namespace 判斷，也不被回寫。

## 移除舊 Spectra Plus 排程

如果過去曾啟用 Spectra Plus 自動修復，安全順序是：先對 legacy registry 中每個專案安裝 cash skills，視需要用 `install-cash-skills.fish --register` 加入新的手動清單，再移除舊排程。`install-cash-skills.fish` 只清除 target 內可由 baseline 證明 ownership 的 legacy skill；`uninstall-spectra-plus-repair.fish` 則處理使用者層級的 LaunchAgent、legacy registry 與 cache。cleanup 會先列出 legacy registry 內的 targets，方便逐一完成安裝。

先預覽，不呼叫 `launchctl`、不刪除狀態：

```fish
./uninstall-spectra-plus-repair.fish --dry-run
```

確認每個 target 都已安裝後再執行：

```fish
./uninstall-spectra-plus-repair.fish
```

cleanup 會卸載已知的兩個 legacy labels，移除其 plists、registry 與 cache，並保留 `$HOME/Library/Logs/spectra-plus-repair.log`。它可重複執行；狀態已不存在時會成功 no-op。

## Signals

`cash-propose` 與 `cash-apply` 的 review loop 會依 `openspec/signals/README.md` 讀寫共享 signals。`status` 與選填的 `check` 都由人維護；自動 writer 不會變更它們。

## 驗證

```fish
fish scripts/cash-skills/tests/skill-checks.fish
fish scripts/cash-skills/tests/skill-checks.fish namespace-scan
fish scripts/cash-cli/tests/cli-checks.fish
.cash-skills/bin/cash validate --all
```
