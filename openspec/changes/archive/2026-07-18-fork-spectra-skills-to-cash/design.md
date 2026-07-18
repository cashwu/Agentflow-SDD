## Context

目前專案同時存在兩層 workflow：Spectra 產生並可能在 spectra update --force 時覆寫的 `spectra-*` skills，以及從 `spectra-propose`／`spectra-apply` 經 transformations 生成的 `spectra-*-plus` skills。為了修復更新造成的刪除或漂移，repo 又加入 fingerprint、target registry、`repair-all`、LaunchAgent 與 `spectra-commit` deletion guard。這些機制已把「維護兩個客製 skill」擴張成跨專案背景同步系統。

這次改動將 ownership 邊界改成：Spectra 只管理 `spectra-*` 與 CLI；本 repo 直接管理 `cash-*`。既有 `openspec/` 路徑、Spectra CLI、signals 與 quality-gate artifact 格式繼續共用。Claude 與 Codex 都是正式支援的 variant。

## Goals / Non-Goals

**Goals:**

- 建立 Claude 與 Codex 各十二個 source-controlled canonical `cash-*` skills。
- 把現有 propose-plus 與 apply-plus 的完整 workflow 分別收斂成唯一入口 `cash-propose` 與 `cash-apply`。
- 讓 `cash-*` 在 Spectra 更新後保持 byte-identical。
- 提供明確、無背景狀態的跨專案 installer。
- 提供一次性 cleanup，卸載舊 LaunchAgent 並清除 repair registry/cache。
- 移除 plus generator、automatic repair 與 plus deletion workaround。
- 以唯讀 contract tests 取代週期性修復。

**Non-Goals:**

- 不 fork、替換或修改 Spectra CLI。
- 不改變 `openspec/` artifact schema、signals schema 或 master-spec archive 行為。
- 不自動追蹤未來 Spectra 版本的 skill 內容；上游變更只能透過明確的人工作業導入。
- 不建立 `cash-*-plus`、cash registry、LaunchAgent、daemon 或其他背景同步機制。
- 不在 migration cleanup 中刪除診斷 log。
- 不替使用者自動執行跨專案安裝或本機 LaunchAgent cleanup；本 change 只交付可明確執行的工具。

## Decisions

### Cash skills 採直接 canonical files

`.agents/skills/cash-*/SKILL.md` 與 `.claude/skills/cash-*/SKILL.md` 都是 source-controlled canonical artifacts，不再是由 `spectra-*` 來源即時衍生的輸出。每份 frontmatter 使用 `cash-<name>`，移除 `generatedBy: "Spectra"`、`spectraPlusVersion`、`spectraPlusUpdated` 與 `spectraPlusFingerprint`。

兩個 variant 允許命令語法與工具宣告不同，但共同 workflow contract 必須一致。這種直接 ownership 會產生有限重複，但比保留一套 generator、模板與 freshness 系統更容易理解與修改。

替代方案是把 Spectra skills 複製到新的 source tree，再生成 `cash-*` outputs。否決原因是它仍保留 derived-artifact lifecycle，對十二個以文字為主的 skills 增加不必要的生成層。

### Propose/apply 吸收 plus behavior

`cash-propose` 以目前 `spectra-propose-plus` 為行為 baseline，`cash-apply` 以目前 `spectra-apply-plus` 為行為 baseline。遷移時只允許以下受控變更：

- skill 名稱與 invocation 從 `spectra-*-plus`／`spectra-*` 正規化為 `cash-*`；
- user-facing 的 plus 命名改成 cash 命名；
- Spectra CLI command 與 `openspec/` 路徑保持不變；
- 移除 generated metadata、repair/fingerprint 與 plus deletion guard；
- `cash-commit` 保留 archive-first allowlist，但不保留 plus generated-output deletion exception。

不存在較弱的 base tier，也不存在 `cash-propose-plus` 或 `cash-apply-plus`。所有其他 `cash-*` skills 以同名 `spectra-*` 當下內容為 baseline，再套用相同 invocation ownership 轉換。

替代方案是同時保留 base 與 plus。否決原因是 plus 只是規避 Spectra ownership 的 workaround，不是產品層級。

### Installer is explicit stateless deployer

新增 `install-cash-skills.fish`，唯一 mutating interface 為：

`install-cash-skills.fish --target <project> [--dry-run] [--force]`

installer 從自身 repo 的 24 個 canonical skill files複製到指定 target。它先完成 source inventory、target directory 與全部 destination conflict preflight，再開始寫入：

- destination 不存在：安裝；
- destination byte-identical：回報 unchanged；
- destination 不同：預設整體失敗且不寫任何檔案；
- 指定 `--force`：允許替換不同的 `cash-*` destination；
- 指定 `--dry-run`：列出同一組動作與 conflicts，但不修改 target。

installer 必須先以 `realpath` canonicalize 一個已存在的 target，拒絕空值、`/`、無法解析的 target，以及任何 managed destination 或其既有 parent 是 symlink 的狀態。每個解析後 destination 都必須仍位於 canonical target 之下；任一 boundary 檢查失敗時，在第一次寫入前整體 fail closed。

installer 不建立 registry、cache、lock、LaunchAgent 或 background task，不執行 `spectra update`，也不修改任何 `spectra-*` skill。它只管理明確列舉的 `cash-*` destinations，保留 target 內其他檔案。

替代方案是復用舊 installer 並移除 repair flags。否決原因是舊檔的 registry、fingerprint、guard patch 與 LaunchAgent 分支互相耦合，裁剪後仍保留高複雜度與錯誤 ownership。

### Cleanup is one-time idempotent migration

新增 `uninstall-spectra-plus-repair.fish [--dry-run]`，只處理舊 automatic repair 的精確已知狀態：

- LaunchAgent labels `com.spectra.plus.repair` 與 `com.agentflow.spectra-plus.repair`；
- 對應的兩個 plist；
- `$HOME/.config/spectra-plus/projects.txt`；
- `$HOME/.cache/spectra-plus`。

cleanup 不以 plist 是否存在判斷 service 是否 loaded；它對兩個 label 都查詢 `launchctl print gui/<uid>/<label>`，loaded 時直接以 label 執行 `launchctl bootout gui/<uid>/<label>`。只有確認兩個 label 都 absent/unloaded 後，才移除 plist、registry 與 cache。不存在的項目是成功 no-op；重複執行必須成功。只有與查詢中的完整 service identity 相符的已知 `launchctl` absent 訊息可歸類為 not-loaded；包含泛用 `not found` 字樣的其他錯誤仍必須 fail closed。任何 unexpected print 或 bootout 錯誤都使 cleanup 非零退出並停止後續 state removal，讓 operator 能依 stderr 手動恢復。診斷 log `$HOME/Library/Logs/spectra-plus-repair.log` 預設保留。

cleanup 在任何 launchctl 或刪除操作前驗證 `HOME` 為非空、absolute、不是 `/`，並確認四個 cleanup target 是 `HOME` 下的精確已知路徑。若已知 target 或其既有 parent 是 symlink，cleanup 整體 fail closed 且零寫入，避免 path traversal 或移除連結外狀態。

刪除 registry 前，cleanup 必須先證明 registry 是可讀 regular file，完整讀取成功後再把其中每個既有 target path 印到 stdout，讓 operator 能先逐一執行 `install-cash-skills.fish --target <project>`；`--dry-run` 也必須輸出同一份 target 清單。Registry 型態或讀取錯誤必須發生在任何 `launchctl` 或刪除之前並 fail closed。

`--dry-run` 必須列出精確動作且零寫入。cleanup 不刪除任何 target project 中的 skill files；target migration 由 installer 顯式完成。

替代方案是在 apply 過程自動執行 cleanup。否決原因是它會改動 repo 外的使用者 session state，必須由 operator 明確授權與執行。

### Spectra CLI and artifact schema remain shared

所有 `cash-*` workflow 內部轉移使用 `$cash-*`（Claude variant 使用對應 slash syntax），但實際 artifact operations 繼續呼叫 `spectra list`、`spectra status`、`spectra instructions`、`spectra validate`、`spectra archive` 等 CLI。Artifacts、reviews、signals 與 accepted-risks 仍寫入既有 `openspec/` paths。

這個 seam 的 owner 是 skill instruction 本身：skill 決定 workflow 與品質閘門，Spectra CLI 決定 schema、validation 與 archive。兩者之間不新增 adapter。

### Project guidance survives Spectra-managed updates

`AGENTS.md` 中 `<!-- SPECTRA:START -->` 至 `<!-- SPECTRA:END -->` 仍由 Spectra 擁有；cash workflow override 必須放在 `<!-- SPECTRA:END -->` 之後，並明確聲明在本 repo 中 cash invocation 優先於 managed block 的 `spectra-*` 建議。隔離測試執行 `spectra update --force` 後，必須從完整 `AGENTS.md` 驗證有效 workflow 仍是 cash，而非只檢查 cash skill checksums。

### Variant parity uses readable exhaustive manifests

雙變體 parity 不只檢查少量 marker。測試只先正規化 Claude 的 `/cash-*` 與 Codex 的 `$cash-*` invocation，接著對每一對 skill 的完整檔案產生 exact unified diff；沒有合法 tool 差異的 skills 必須 byte-equal，合法差異則必須逐行等於 `scripts/cash-skills/variant-parity/cash-<skill>.diff` 的可讀 per-skill manifest。Manifest 明列 tool-specific frontmatter、fork-context wording、plan-directory／agent selection，以及 `cash-audit` 因執行能力不同而採用的 Codex standalone/discipline workflow 與 Claude report-only workflow。未列入 manifest 的任何差異都使測試失敗；不得使用 digest、忽略任意段落或寬鬆 whitespace/content regex 隱藏內容差異。

### Live documentation and signals move with ownership

`SPECTRA-PLUS.md` 退役並由 `CASH-SKILLS.md` 取代；新文件列出 12×2 inventory、stateless installer、cleanup dry-run、先安裝 registry 中每個 target 再清除排程的順序，以及「無定期 repair」原則。`openspec/signals/README.md` 的現行流程與 writer 名稱改為 cash，但歷史 `## Occurrences` 條目保持原文，避免改寫 provenance。

### Contract tests replace repair automation

新增 `scripts/cash-skills/tests/skill-checks.fish`，只讀驗證：

- Claude/Codex 各十二個 skill 的完整 inventory、frontmatter name 與 ownership metadata；
- `cash-propose`／`cash-apply` 保留 quality gate、signals、ledger、language 與 termination markers；
- 所有 user-facing workflow invocation 使用 cash namespace，Spectra CLI literals 不被誤改；
- 不存在 `cash-*-plus`、四個舊 plus outputs、generator／repair／LaunchAgent 安裝入口；
- installer 的 absent、identical、conflict、force 與 dry-run branches；
- cleanup 的 installed、not-loaded、absent、unexpected bootout failure 與 repeated-run branches；
- 在 isolated fixture 執行 spectra update --force 前後，所有 `cash-*` files byte-identical；
- Claude/Codex variant 的 invocation syntax 正規化後，完整檔案差異逐行等於 readable exhaustive per-skill manifests。
- `AGENTS.md` 的 project-owned cash override 位於 Spectra managed block 之外，且 forced update 後仍具有效 precedence。
- live docs 與 signals README 不再指引使用 generator、repair 或 plus writer。

測試是 fail-loud verification，不自動改檔。任何失敗都由使用者明確修正與重新執行。

## Implementation Contract

### Skill inventory and observable workflow

交付後，本 repo 與 installer target 都能發現下列十二個 workflow 名稱：`cash-analyze`、`cash-apply`、`cash-archive`、`cash-ask`、`cash-audit`、`cash-commit`、`cash-debug`、`cash-discuss`、`cash-drift`、`cash-ingest`、`cash-propose`、`cash-verify`。Claude 與 Codex variant 各自完整，不得出現 cash plus tier。

`cash-propose` 建立 implementation-ready artifacts、執行 `spectra validate`，再完成 sub-agent quality gate；它不得自動 apply 或 park。`cash-apply` 依 artifacts 實作，完成 tasks 後執行相同的收斂式 quality gate，只有 passed 才能提供 archive guidance。Round files、ledger、signals、accepted-risks、implementation notes 與 grader-protection 行為保留現行 plus contract，但 source skill 名稱與 user-facing vocabulary 使用 cash namespace。

### Installer interface and failure behavior

呼叫 `install-cash-skills.fish --target <project>` 後，成功結果必須是 target 的 24 個 managed destinations 全部存在且與 source 對應檔 byte-identical。Preflight error、缺少 source、無效 target 或未授權 conflict 必須回傳非零，stderr 指明 path，且 target 不得出現部分更新。成功與 dry-run 輸出必須按 destination 顯示 install、unchanged 或 replace，最後顯示計數摘要。

`--force` 只授權替換 managed `cash-*` destinations；它不授權刪除未列舉檔案。`--dry-run` 不得建立目錄、暫存檔於 target、registry 或任何持久 state。

target 必須已存在並成功 canonicalize，且不得是 `/`。任一 managed destination 或其既有 parent 是 symlink、或解析後 path 逸出 canonical target，皆為 preflight error；所有這類錯誤都發生在零 target write 的階段。

### Cleanup interface and failure behavior

`uninstall-spectra-plus-repair.fish` 成功後，兩個已知 LaunchAgent label 都經查詢確認 absent/unloaded，兩個 plist、repair registry 與 cache 都不存在，且診斷 log 保留。即使 plist 不存在但 label 仍 loaded，也必須按 label bootout。若初始狀態已清除，輸出 no-op summary 並回傳 0。Registry 必須在 launchctl 前完成 readable-regular-file preflight；任何 registry read、unexpected print/bootout failure 必須回傳非零、保留 plist與 registry/cache，並在 launchctl failure 時輸出可執行的 manual cleanup command。兩個 mutating Fish scripts 都以 `fish --no-config` 啟動，且關鍵外部命令不受使用者 startup functions 取代。

若 registry 存在，cleanup 的正常與 dry-run 輸出都必須在刪除前列出全部 registered target paths，作為顯式 installer migration inventory。

`uninstall-spectra-plus-repair.fish --dry-run` 不得執行任何 `launchctl` 或刪除任何 state。`HOME` 與 symlink boundary preflight 失敗時也不得執行 `launchctl` 或寫入。

### Acceptance criteria

- `spectra validate fork-spectra-skills-to-cash` 通過。
- `scripts/cash-skills/tests/skill-checks.fish` 通過。
- 測試 fixture 中 spectra update --force 不改動任何 `cash-*` checksum。
- 全 repo 搜尋不再找到 active `cash-*-plus` invocation、plus auto-repair entrypoint 或對 generated plus deletion exception 的依賴。
- installer 測試證明 conflict preflight 不會造成 partial update。
- cleanup 測試使用隔離的 HOME 與 stubbed `launchctl`，不得觸碰實際使用者 LaunchAgent。
- `AGENTS.md` 的 project-owned override 位於 managed block 之外；forced update 後有效 workflow 與 skill transition仍指向 `cash-*`。
- `CASH-SKILLS.md`、signals README 與 live code/docs 搜尋不再提供 plus generator/repair 操作入口。

### Scope boundaries

Implementation 只修改 proposal `## Impact` 中列出的 repo paths。實作測試不執行真實跨專案安裝或真實 LaunchAgent cleanup；外部 state migration 由使用者在 artifacts 完成後自行執行。除 proposal 明列為一次性恢復 Spectra baseline 的兩份 `spectra-commit` 外，Spectra-managed 的非 plus `spectra-*` skills、`.spectra.yaml`、signals 的 `check` 欄位與既有 master specs 不在 implementation mutation scope。兩份 `spectra-commit` 完成 baseline restore 後即回到 Spectra ownership，不再由 cash tooling patch。

## Risks / Trade-offs

- [Risk] 24 個 canonical files 可能產生 Claude/Codex 漂移 → 以 inventory、semantic marker 與 syntax-normalized parity tests fail-loud，不加入背景同步。
- [Risk] 從 plus 改名時可能殘留舊 invocation 或 protected-path literal → 對 `spectra-`、`plus`、round headings、signals source 與 commit guard 做 bounded cross-grep，並區分必須保留的 Spectra CLI command。
- [Risk] installer 的 `--force` 可能覆蓋 target 自有修改 → 預設 conflict fail-closed，只有 caller 明確提供 `--force` 才替換 managed destinations。
- [Risk] cleanup 遇到正在執行或無法 unload 的 LaunchAgent → unexpected bootout failure 時停止，不刪 plist、registry 或 cache，stderr 提供手動命令。
- [Risk] 移除舊 master requirements 時遺漏 replacement contract → delta spec 明確 REMOVED 全部 legacy requirements，新 capability 對仍保留的 workflow、review、signals 與 migration 行為建立 backing tasks 與 tests。
- [Trade-off] 不再自動吸收 Spectra upstream skill 更新 → ownership 穩定性優先；未來升級必須另開 change，顯式比較與導入。
- [Trade-off] 保留 Spectra CLI 依賴 → 避免 fork schema/validator，cash skills 只擁有 orchestration layer。

## Migration Plan

1. 建立並驗證 24 個 `cash-*` canonical files，先保留舊 plus 系統以便比較。
2. 建立 installer、cleanup 與隔離測試；在 fixture 驗證 Spectra update isolation。
3. 更新 `AGENTS.md`，將專案 workflow 切換到 cash namespace。
4. 移除四個 plus outputs、`scripts/spectra-plus/` 與 `install-spectra-plus.fish`，再執行全套 contract tests。
5. Operator 先執行 `uninstall-spectra-plus-repair.fish --dry-run`，依舊 registry 顯示的 target 分別執行 installer，確認後再執行 cleanup。
6. Rollback 時從版本控制恢復舊 plus files/scripts；只有需要恢復 background repair 時才明確重裝舊 LaunchAgent。已安裝的 `cash-*` 可保留，因其 namespace 不衝突。

## Open Questions

無。
