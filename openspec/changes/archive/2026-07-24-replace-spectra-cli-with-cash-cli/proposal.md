## Summary

以 repository-owned 的 Cash CLI 取代現行 cash workflows 對 Spectra CLI 的全部 runtime 依賴，同時保留既有 `openspec/` artifact model 與 Cash workflow contract。

## Motivation

目前十二個 `cash-*` skills 雖由本 repository 直接維護，artifact 建立、狀態、驗證、分析、漂移、封存與搜尋仍呼叫外部 Spectra CLI；只要 Spectra 未安裝或被移除，Cash workflow 就無法完整運作。這個 ownership seam 也讓 Cash 的安裝、版本與相容性無法單獨治理。

Source repository 的 `.cash-skills/receipt.tsv` 必須因 target-specific `st_dev/st_ino` 而忽略版控，但一般 installer 又必須拒絕把 source repository 當成部署 target；若沒有專用 bootstrap 路徑，乾淨 clone 內所有 canonical Cash workflows 會在 launcher 驗證階段永久失敗。

## Proposed Solution

- 新增 repository-owned、可隨 Cash bundle 安裝的 `cash` CLI，接管 active/parked change lifecycle、artifact instructions、task state、validation、analysis、drift、archive、sync、search 與 JSON output contracts。
- 將 `.spectra/touched` 的live source tracking遷移為Cash-owned snapshot/touched state，使apply、commit與archive保留現有source allowlist contract。
- 將Cash-owned touched state定義為versioned per-task schema與resume-safe Git fingerprint state machine；只匯入現行`.spectra/touched`資料，匯入後Cash立即成為唯一權威，歷史`.spectra/snapshots/`不作runtime輸入。
- **BREAKING**：將兩個 variant 的十二個 canonical `cash-*` skills 全部改為只呼叫 Cash CLI，移除 `Requires spectra CLI` 相容性宣告與所有 live `spectra` command literals。
- **BREAKING**：將專案設定從 `.spectra.yaml` 遷移為 `.cash.yaml`，並讓 Cash CLI 與 skills 只讀取 Cash-owned 設定。
- 擴充 `install-cash-skills.fish`，保留strict SemVer、任意長度版本排序、版本bump/history binding與invalid receipt fail-closed治理；以單向發布、rollback不移除的stable launcher/workspace-lock bootstrap同步installer與CLI，承接receipt-less完全相同24-skill target與known-old receipt，再以同一版本、runtime generation、path/digest/mode receipt及recoverable transaction安裝Cash CLI library、`.cash.yaml` baseline、guidance與24個skills，且只依精確已知full-body digest安全清除標準`spectra-*` skill directories。
- 新增明確的 `install-cash-skills.fish --self [--dry-run]` source bootstrap：只驗證 source Git root、canonical inventory、stable launcher/lock identity與config後建立或更新被忽略的 target-specific receipt，不發布或覆寫runtime、skills、config、guidance；一般 `--target`、registry與batch模式仍拒絕source repository。Source launcher在receipt缺失或失效時回報可直接執行的`./install-cash-skills.fish --self`診斷。
- Installer只接受已具有效`openspec/config.yaml`的Git top-level target；既有Cash config保留、legacy config安全遷移、兩者皆無時安裝source canonical baseline。
- 移除本 repository 內兩個 variant 的標準 `spectra-*` skills，以及只驗證 `spectra update` 隔離性的 live regression path。
- 以 deterministic lexical search 取代向量模型依賴；搜尋 unavailable 或無結果時保留明確且可區分的結果，不再要求下載 Spectra model。
- 在 installer 注入 `AGENTS.md` 與 `CLAUDE.md` 的 canonical Cash guidance block 最上方加入一條全域繁體中文回覆規則，使未進入任何 cash skill 的一般對話也預設以繁體中文回覆；此規則獨立於各 skill 的 `Response language` 段落，並比照既有 block 內容維持 byte-for-byte 同步。
- 新增 command-level contract tests、fixture-based artifact lifecycle tests、archive/spec merge tests、failure/atomicity tests，以及完整 namespace residue scan。
- 保留 `openspec/changes/archive/` 歷史內容原文，不回寫過去的 Spectra provenance。

## Alternatives Considered

- 讓 skills 直接操作檔案：會把 schema、validation、archive 與錯誤處理複製到十二個 workflows，責任分散且難以一致測試。
- fork 或包裝 Spectra CLI：仍保留被移除的 runtime dependency，無法達成獨立 ownership。
- 同時替換 `openspec/` schema：把執行引擎遷移與資料模型重寫綁在一起，風險與驗證面不必要地擴大。
- Source launcher自動採digest-only模式：會讓source與installed target走不同的完整性模型，且無法保留stable launcher/lock的target-specific identity驗證；改用明確`--self`產生相同receipt schema。

## Capabilities

### New Capabilities

- `cash-cli`: 定義 repository-owned Cash CLI 的 workspace discovery、command surface、artifact lifecycle、validation、archive、search、錯誤與安裝契約。

### Modified Capabilities

- `cash-skill-workflows`: 將所有 live workflow command、設定、安裝、文件與回歸契約從 Spectra runtime 轉為 Cash ownership。

## Impact

- Affected specs: `cash-cli`、`cash-skill-workflows`
- Affected code:
  - New:
    - `.cash-skills/bin/cash`
    - `.cash-skills/lib/cash_cli/`
    - `.cash-workspace.lock`
    - `.cash.yaml`
    - `scripts/cash-skills/legacy-spectra-digests.tsv`
    - `scripts/cash-cli/tests/`
    - `scripts/cash-cli/fixtures/`
  - Modified:
    - `.agents/skills/`
    - `.claude/skills/`
    - `install-cash-skills.fish`
    - `scripts/cash-skills/tests/skill-checks.fish`
    - `cash-skills.version`
    - `CASH-SKILLS.md`
    - `AGENTS.md`
    - `CLAUDE.md`
    - `.gitignore`（新增忽略 `.cash-skills/receipt.tsv` 與 `.cash-skills/state/`）
  - Generated（runtime/install 產生，不進版控）:
    - `.cash-skills/receipt.tsv`：記錄 target-specific `st_dev`/`st_ino`，若被 commit 會使 clone 端 inode 不符而讓 launcher 與 installer fail closed，故 MUST git-ignore。
    - `.cash-skills/state/snapshots/`、`.cash-skills/state/touched/`：per-target source-tracking state，比照既有被忽略的 `.spectra/`，MUST NOT 進版控。
  - Removed:
    - `.spectra.yaml`
    - `.agents/skills/spectra-analyze/`
    - `.agents/skills/spectra-apply/`
    - `.agents/skills/spectra-archive/`
    - `.agents/skills/spectra-ask/`
    - `.agents/skills/spectra-audit/`
    - `.agents/skills/spectra-commit/`
    - `.agents/skills/spectra-debug/`
    - `.agents/skills/spectra-discuss/`
    - `.agents/skills/spectra-drift/`
    - `.agents/skills/spectra-ingest/`
    - `.agents/skills/spectra-propose/`
    - `.agents/skills/spectra-verify/`
    - `.claude/skills/spectra-analyze/`
    - `.claude/skills/spectra-apply/`
    - `.claude/skills/spectra-archive/`
    - `.claude/skills/spectra-ask/`
    - `.claude/skills/spectra-audit/`
    - `.claude/skills/spectra-commit/`
    - `.claude/skills/spectra-debug/`
    - `.claude/skills/spectra-discuss/`
    - `.claude/skills/spectra-drift/`
    - `.claude/skills/spectra-ingest/`
    - `.claude/skills/spectra-propose/`
    - `.claude/skills/spectra-verify/`
